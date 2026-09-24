import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypt/decrypt roundtrip via DownloadManager methods', () async {
    final key = enc.Key.fromSecureRandom(32);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final rnd = Random(42);
    final plain = Uint8List.fromList(List.generate(64 * 1024 + 123, (_) => rnd.nextInt(256)));
    final src = File('${Directory.systemTemp.path}/rt_in.bin')
      ..writeAsBytesSync(plain);
    final encf = File('${Directory.systemTemp.path}/rt_enc.bin');
    const chunk = 64 * 1024;
    const magic = [0x53, 0x43, 0x56, 0x31];
    {
      final raf = await src.open();
      final w = await encf.open(mode: FileMode.write);
      await w.writeFrom(Uint8List.fromList(magic));
      while (true) {
        final c = await raf.read(chunk);
        if (c.isEmpty) break;
        final iv = enc.IV.fromSecureRandom(16);
        final e = encrypter.encryptBytes(c, iv: iv);
        final plainLen = ByteData(4)..setUint32(0, c.length);
        final ctLen = ByteData(4)..setUint32(0, e.bytes.length);
        await w.writeFrom(plainLen.buffer.asUint8List());
        await w.writeFrom(ctLen.buffer.asUint8List());
        await w.writeFrom(iv.bytes);
        await w.writeFrom(e.bytes);
      }
      await raf.close();
      await w.close();
    }
    final out = File('${Directory.systemTemp.path}/rt_out.bin');
    {
      final raf = await encf.open();
      final w = await out.open(mode: FileMode.write);
      final m = await raf.read(4);
      expect(m, magic);
      while (true) {
        final pl = await raf.read(4);
        if (pl.isEmpty) break;
        final cl = await raf.read(4);
        final ivb = await raf.read(16);
        final plainLen = ByteData.sublistView(pl).getUint32(0);
        final ctLen = ByteData.sublistView(cl).getUint32(0);
        final ct = await raf.read(ctLen);
        final d = Uint8List.fromList(encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(ct)),
          iv: enc.IV(Uint8List.fromList(ivb)),
        ));
        await w.writeFrom(d.sublist(0, min(plainLen, d.length)));
      }
      await raf.close();
      await w.close();
    }
    expect(await out.readAsBytes(), plain);
  });
}
