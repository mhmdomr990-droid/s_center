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

  DownloadRecord({
    required this.lectureId,
    required this.file,
    required this.downloadedAt,
    required this.expiresAt,
  });

  factory DownloadRecord.fromJson(Map<String, dynamic> json) {
    return DownloadRecord(
      lectureId: json['lecture_id'] as int,
      file: json['file'] as String,
      downloadedAt: DateTime.parse(json['downloaded_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lecture_id': lectureId,
      'file': file,
      'downloaded_at': downloadedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DownloadManager extends GetxController {
  static const _prefsKey = 'lecture_downloads_v1';
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

  final Dio _mediaDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 300),
  ));

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      await cleanupExpired();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        records.clear();
        for (final item in list) {
          final rec = DownloadRecord.fromJson(Map<String, dynamic>.from(item as Map));
          if (!rec.isExpired) {
            records[rec.lectureId] = rec;
          }
        }
      }
    } catch (_) {
      records.clear();
    } finally {
      ready.value = true;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = records.values.map((r) => r.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  DownloadRecord? recordFor(int lectureId) {
    final rec = records[lectureId];
    if (rec == null || rec.isExpired) return null;
    return rec;
  }

  bool isDownloaded(int lectureId) => recordFor(lectureId) != null;

  Future<void> cleanupExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
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
      final rec = DownloadRecord.fromJson(Map<String, dynamic>.from(item as Map));
      if (rec.isExpired) {
        try {
          final f = File('${dir.path}/${rec.file}');
          if (await f.exists()) await f.delete();
        } catch (_) {}
      } else {
        keep.add(rec.toJson());
      }
    }
    await prefs.setString(_prefsKey, jsonEncode(keep));
  }

  Future<Directory> _downloadsDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
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
    final existing = await _secure.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      final bytes = base64Decode(existing);
      if (bytes.length == 32) return enc.Key(Uint8List.fromList(bytes));
    }
    final key = enc.Key.fromSecureRandom(32);
    await _secure.write(key: _keyStorageKey, value: base64Encode(key.bytes));
    return key;
  }

  Future<void> downloadLecture(int lectureId) async {
    if (!_offlineSupported) {
      throw UnsupportedError('التحميل متاح على تطبيق أندرويد فقط');
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
      final rec = DownloadRecord(
        lectureId: lectureId,
        file: '$lectureId.enc',
        downloadedAt: now,
        expiresAt: now.add(Duration(days: ttlDays)),
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

  Future<File> decryptToTemp(int lectureId) async {
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
    final out = File('${tmp.path}/play_$lectureId.mp4');
    await _decryptFile(encFile, out);
    return out;
  }

  Future<void> deleteTempPlayFile(int lectureId) async {
    try {
      final tmp = await _tempDir();
      final f = File('${tmp.path}/play_$lectureId.mp4');
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
