import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/cotisation.dart';

class IsarService {
  static Isar? _instance;
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'isar_encryption_key';

  static Future<Isar> getInstance() async {
    if (_instance != null && _instance!.isOpen) return _instance!;
    
    final dir = await getApplicationDocumentsDirectory();
    
    // Récupération ou génération de la clé de chiffrement
    String? keyString = await _storage.read(key: _keyName);
    Uint8List? encryptionKey;
    
    if (keyString == null) {
      final secureRandom = Random.secure();
      encryptionKey = Uint8List.fromList(
        List.generate(32, (_) => secureRandom.nextInt(256)),
      );
      await _storage.write(key: _keyName, value: base64Encode(encryptionKey));
    } else {
      encryptionKey = base64Decode(keyString);
    }

    _instance = await Isar.open(
      [MembreSchema, CulteSchema, CotisationSchema],
      directory: dir.path,
      name: 'cotisapp_db',
      // encryptionKey n'est plus supporté nativement dans Isar v3.x version communautaire
    );
    return _instance!;
  }
}

