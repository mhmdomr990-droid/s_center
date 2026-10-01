import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../providers/api_client.dart';
import '../providers/media_provider.dart';

bool get _offlineSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class DownloadRecord {
  final int lectureId;
  final String file;
  final DateTime downloadedAt;
  final DateTime expiresAt;
  final String? title;
  final String? courseName;
  final String? lectureType;
  final int? sizeBytes;

  DownloadRecord({
    required this.lectureId,
    required this.file,
    required this.downloadedAt,
    required this.expiresAt,
    this.title,
    this.courseName,
    this.lectureType,
    this.sizeBytes,
  });

  factory DownloadRecord.fromJson(Map<String, dynamic> json) {
    return DownloadRecord(
      lectureId: json['lecture_id'] as int,
      file: json['file'] as String,
      downloadedAt: DateTime.parse(json['downloaded_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      title: json['title'] as String?,
      courseName: json['course_name'] as String?,
      lectureType: json['lecture_type'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lecture_id': lectureId,
      'file': file,
      'downloaded_at': downloadedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'title': title,
      'course_name': courseName,
      'lecture_type': lectureType,
      'size_bytes': sizeBytes,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DownloadManager extends GetxController {
  static const _prefsKeyLegacy = 'lecture_downloads_v1';
  static const _prefsKeyPrefix = 'lecture_downloads_v1__u';
  static const _keyStorageKey = 'lecture_aes_key_v1';
  static const _chunkSize = 64 * 1024;
  static const _headerMagic = [0x53, 0x43, 0x56, 0x31]; // SCV1

  final MediaProvider _media;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  DownloadManager() : this.from(Get.find<ApiClient>());

  DownloadManager.from(ApiClient api) : _media = MediaProvider(api);

  final records = <int, DownloadRecord>{}.obs;
  final progress = <int, double>{}.obs;
  final Set<int> downloadingIds = <int>{}.obs;
  final RxBool ready = false.obs;

  /// مالك التنزيلات الحالي — لا قراءة ولا كتابة بلا نطاق نشط،
  /// فتبقى تنزيلات كل حساب منفصلة تماماً.
  int? _userId;

  String? get _scopedKey => _userId == null ? null : '$_prefsKeyPrefix$_userId';

  final Dio _mediaDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 300),
  ));

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  /// ضبط نطاق المستخدم: تفريغ ذاكرة الحساب السابق + تنظيف ملفات
  /// التشغيل المؤقتة (plaintext) + ترحيل السجلات القديمة (إن وُجدت) +
  /// تحميل سجل هذا المستخدم.
  Future<void> scopeToUser(int userId) async {
    if (_userId == userId) return;
    _userId = userId;
    records.clear();
    await _clearTempPlaintext();
    await _migrateLegacyScope();
    await _load();
  }

  /// إنهاء النطاق (خروج من الحساب) — تُفرَّغ الذاكرة ويُمنع أي وصول.
  Future<void> clearScope() async {
    _userId = null;
    records.clear();
    await _clearTempPlaintext();
  }

  /// مرة واحدة عند أول دخول بعد التحديث: اعتماد المفتاح العالمي القديم
  /// كسجلات هذا المستخدم ونقل ملفاته إلى مجلده ثم حذف المفتاح القديم.
  Future<void> _migrateLegacyScope() async {
    try {
      final scoped = _scopedKey;
      if (scoped == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(scoped)) return;
      final raw = prefs.getString(_prefsKeyLegacy);
      if (raw == null || raw.isEmpty) return;

      // نقل ملفات المجلد القديم المشترك إلى مجلد المستخدم
      final legacyDir = await _legacyDownloadsDir();
      if (await legacyDir.exists()) {
        final userDir = await _downloadsDir();
        await for (final entity in legacyDir.list()) {
          if (entity is! File) continue;
          try {
            final target =
                File('${userDir.path}/${entity.uri.pathSegments.last}');
            if (!await target.exists()) {
              await entity.rename(target.path);
            }
          } catch (_) {
            // فشل نقل ملف واحد لا يُسقط ترحيل السجل
          }
        }
      }

      await prefs.setString(scoped, raw);
      await prefs.remove(_prefsKeyLegacy);
    } catch (e) {
      debugPrint('DOWNLOADS_MIGRATE_ERR $e');
    }
  }

  /// حذف ملفات التشغيل المؤقتة المفكوكة (قد تكون نسخة مفتوحة من حساب
  /// سابق) — تُحذف عند كل تغيير نطاق أو خروج.
  Future<void> _clearTempPlaintext() async {
    try {
      final support = await getApplicationSupportDirectory();
      final tmp = Directory('${support.path}/tmp');
      if (!await tmp.exists()) return;
      await for (final entity in tmp.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('play_') ||
            name.startsWith('stream_') ||
            name.startsWith('raw_')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final key = _scopedKey;
      if (key == null) {
        records.clear();
        return;
      }
      await cleanupExpired();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        final parsed = <int, DownloadRecord>{};
        for (final item in list) {
          try {
            final rec = DownloadRecord.fromJson(
                Map<String, dynamic>.from(item as Map));
            if (!rec.isExpired) {
              parsed[rec.lectureId] = rec;
            }
          } catch (_) {
            // سجل واحد تالف لا يُسقط البقية — يتخطى ويُبلَّغ فقط
            debugPrint('DOWNLOAD_REC_BAD $item');
          }
        }
        records
          ..clear()
          ..addAll(parsed);
      } else {
        records.clear();
      }
    } catch (e) {
      // لا نمسح الذاكرة عند فشل القراءة — والملف لا يُعاد كتابته إلا
      // بعد عملية صريحة (تحميل/حذف)، فلا يضيع سجل سليم بسبب خطأ قراءة
      debugPrint('DOWNLOADS_LOAD_ERR $e');
    } finally {
      ready.value = true;
    }
  }

  Future<void> _save() async {
    final key = _scopedKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final list = records.values.map((r) => r.toJson()).toList();
    await prefs.setString(key, jsonEncode(list));
  }

  DownloadRecord? recordFor(int lectureId) {
    final rec = records[lectureId];
    if (rec == null || rec.isExpired) return null;
    return rec;
  }

  bool isDownloaded(int lectureId) => recordFor(lectureId) != null;

  Future<void> cleanupExpired() async {
    final key = _scopedKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;

    List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }

    final dir = await _downloadsDir();
    final keep = <Map<String, dynamic>>[];
    for (final item in list) {
      try {
        final rec = DownloadRecord.fromJson(
            Map<String, dynamic>.from(item as Map));
        if (rec.isExpired) {
          try {
            final f = File('${dir.path}/${rec.file}');
            if (await f.exists()) await f.delete();
          } catch (_) {}
        } else {
          keep.add(rec.toJson());
        }
      } catch (_) {
        // سجل غير قابل للقراءة — نُبقيه كما هو بدل حذفه
        keep.add(Map<String, dynamic>.from(item as Map));
      }
    }
    await prefs.setString(key, jsonEncode(keep));
  }

  Future<Directory> _downloadsDir() async {
    final support = await getApplicationSupportDirectory();
    // مجلد لكل مستخدم — يمنع تصادم اسم ملف لنفس المحاضرة بين حسابين
    // ويُبقي حذف أحدهما لا يكسر الآخر. المسار القديم المشترك يُستخدم
    // حصراً أثناء الترحيل.
    final dir = _userId == null
        ? Directory('${support.path}/downloads')
        : Directory('${support.path}/downloads/u$_userId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _legacyDownloadsDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/downloads');
  }

  Future<Directory> _tempDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/tmp');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<enc.Key> _aesKey() async {
    // The key lives in SharedPreferences — the SAME file as the download
    // records — so their lifetimes can never diverge (a key loss would
    // otherwise make every stored download permanently undecryptable).
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyStorageKey);
    if (stored != null && stored.isNotEmpty) {
      final bytes = base64Decode(stored);
      if (bytes.length == 32) return enc.Key(Uint8List.fromList(bytes));
    }

    // Migrate from flutter_secure_storage (its storage format has changed
    // across plugin versions, which orphaned previously stored values).
    String? legacy;
    try {
      legacy = await _secure.read(key: _keyStorageKey);
    } catch (_) {
      legacy = null;
    }
    if (legacy != null && legacy.isNotEmpty) {
      final bytes = base64Decode(legacy);
      if (bytes.length == 32) {
        await prefs.setString(_keyStorageKey, legacy);
        return enc.Key(Uint8List.fromList(bytes));
      }
    }

    final key = enc.Key.fromSecureRandom(32);
    await prefs.setString(_keyStorageKey, base64Encode(key.bytes));
    return key;
  }

  Future<void> downloadLecture(int lectureId,
      {String? title, String? courseName, String? type}) async {
    if (!_offlineSupported) {
      throw UnsupportedError('التحميل متاح على تطبيق أندرويد فقط');
    }
    if (_userId == null) {
      throw StateError('لا يوجد حساب نشط');
    }
    if (downloadingIds.contains(lectureId)) return;
    downloadingIds.add(lectureId);
    progress[lectureId] = 0;

    File? rawFile;
    File? encFile;
    try {
      final resp = await _media.getDownloadUrl(lectureId);
      final data = resp.data['data'] as Map<String, dynamic>;
      final path = data['url'] as String;
      final ttlDays = (data['download_ttl_days'] as num?)?.toInt() ?? 90;

      final dir = await _downloadsDir();
      final tmp = await _tempDir();
      final rawPath = '${tmp.path}/raw_$lectureId.bin';
      final encPath = '${dir.path}/$lectureId.enc';
      rawFile = File(rawPath);
      encFile = File(encPath);

      final url = MediaProvider.absolute(path);
      await _mediaDio.download(
        url,
        rawPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            progress[lectureId] = (received / total).clamp(0.0, 1.0);
          }
        },
      );

      progress[lectureId] = 0.9;
      await _encryptFile(rawFile, encFile);
      if (await rawFile.exists()) await rawFile.delete();

      final now = DateTime.now();
      int? sizeBytes;
      try {
        sizeBytes = await encFile.length();
      } catch (_) {
        sizeBytes = null;
      }
      final rec = DownloadRecord(
        lectureId: lectureId,
        file: '$lectureId.enc',
        downloadedAt: now,
        expiresAt: now.add(Duration(days: ttlDays)),
        title: title,
        courseName: courseName,
        lectureType: type,
        sizeBytes: sizeBytes,
      );
      records[lectureId] = rec;
      await _save();
      progress[lectureId] = 1;
    } catch (e) {
      try {
        if (encFile != null && await encFile.exists()) await encFile.delete();
      } catch (_) {}
      rethrow;
    } finally {
      try {
        if (rawFile != null && await rawFile.exists()) await rawFile.delete();
      } catch (_) {}
      downloadingIds.remove(lectureId);
      Future.delayed(const Duration(milliseconds: 400), () {
        progress.remove(lectureId);
      });
    }
  }

  Future<void> removeDownload(int lectureId) async {
    final rec = records[lectureId];
    records.remove(lectureId);
    await _save();
    if (rec != null) {
      try {
        final dir = await _downloadsDir();
        final f = File('${dir.path}/${rec.file}');
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<File> decryptToTemp(int lectureId, {String ext = 'mp4'}) async {
    if (!_offlineSupported) {
      throw UnsupportedError('غير مدعوم على هذه المنصة');
    }
    final rec = recordFor(lectureId);
    if (rec == null) {
      throw StateError('not_downloaded');
    }
    final dir = await _downloadsDir();
    final encFile = File('${dir.path}/${rec.file}');
    if (!await encFile.exists()) {
      records.remove(lectureId);
      await _save();
      throw StateError('missing_file');
    }
    final tmp = await _tempDir();
    final out = File('${tmp.path}/play_$lectureId.$ext');
    await _decryptFile(encFile, out);
    return out;
  }

  Future<void> deleteTempPlayFile(int lectureId, {String ext = 'mp4'}) async {
    try {
      final tmp = await _tempDir();
      final f = File('${tmp.path}/play_$lectureId.$ext');
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // جلب ملف محاضرة مضيف (مثل PDF) إلى ملف مؤقت لعرضه — بلا حفظ دائم.
  Future<File> fetchToTemp(int lectureId, {String ext = 'pdf'}) async {
    if (!_offlineSupported) {
      throw UnsupportedError('غير مدعوم على هذه المنصة');
    }
    final resp = await _media.getStreamUrl(lectureId);
    final path = resp.data['data']['url'] as String;
    final tmp = await _tempDir();
    final out = File('${tmp.path}/stream_$lectureId.$ext');
    await _mediaDio.download(MediaProvider.absolute(path), out.path);
    return out;
  }

  Future<void> deleteTempPath(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> _encryptFile(File src, File dst) async {
    final key = await _aesKey();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final raf = await src.open();
    final out = await dst.open(mode: FileMode.write);
    try {
      await out.writeFrom(Uint8List.fromList(_headerMagic));
      while (true) {
        final chunk = await raf.read(_chunkSize);
        if (chunk.isEmpty) break;
        final iv = enc.IV.fromSecureRandom(16);
        final encrypted = encrypter.encryptBytes(chunk, iv: iv);
        final plainLen = ByteData(4)..setUint32(0, chunk.length);
        final ctLen = ByteData(4)..setUint32(0, encrypted.bytes.length);
        await out.writeFrom(plainLen.buffer.asUint8List());
        await out.writeFrom(ctLen.buffer.asUint8List());
        await out.writeFrom(iv.bytes);
        await out.writeFrom(encrypted.bytes);
      }
    } finally {
      await raf.close();
      await out.close();
    }
  }

  Future<void> _decryptFile(File src, File dst) async {
    final key = await _aesKey();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final raf = await src.open();
    final out = await dst.open(mode: FileMode.write);
    try {
      final magic = await raf.read(4);
      if (magic.length != 4 ||
          magic[0] != _headerMagic[0] ||
          magic[1] != _headerMagic[1] ||
          magic[2] != _headerMagic[2] ||
          magic[3] != _headerMagic[3]) {
        throw const FormatException('bad header');
      }
      while (true) {
        final plainLenBytes = await raf.read(4);
        if (plainLenBytes.isEmpty) break;
        if (plainLenBytes.length != 4) throw const FormatException('truncated');
        final ctLenBytes = await raf.read(4);
        if (ctLenBytes.length != 4) throw const FormatException('truncated');
        final ivBytes = await raf.read(16);
        if (ivBytes.length != 16) throw const FormatException('truncated');
        final plainLen = ByteData.sublistView(plainLenBytes).getUint32(0);
        final ctLen = ByteData.sublistView(ctLenBytes).getUint32(0);
        if (ctLen == 0 || ctLen > _chunkSize + 32) {
          throw const FormatException('bad chunk');
        }
        final ct = await raf.read(ctLen);
        if (ct.length != ctLen) throw const FormatException('truncated');
        final decrypted = Uint8List.fromList(encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(ct)),
          iv: enc.IV(Uint8List.fromList(ivBytes)),
        ));
        final end = min(plainLen, decrypted.length);
        await out.writeFrom(decrypted.sublist(0, end));
      }
    } finally {
      await raf.close();
      await out.close();
    }
  }

  String? debugStatus(int lectureId) {
    final rec = records[lectureId];
    if (rec == null) return null;
    return 'expires ${rec.expiresAt.toIso8601String()}';
  }
}
