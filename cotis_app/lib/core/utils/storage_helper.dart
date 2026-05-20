import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageHelper {
  /// Demande la permission de stockage de manière appropriée selon la version d'Android.
  /// Renvoie `true` si la permission est accordée (ou non nécessaire), `false` sinon.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.storage.status;
      if (status.isGranted) {
        return true;
      }
      
      final result = await Permission.storage.request();
      return result.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Détermine le dossier d'exportation optimal.
  /// Tente d'écrire dans /storage/emulated/0/Download/Kased, et utilise un fallback robuste en cas d'erreur.
  static Future<Directory> getExportDirectory() async {
    if (Platform.isAndroid) {
      // 1. Tenter d'utiliser le dossier public Download/Kased
      try {
        final hasPermission = await requestStoragePermission();
        if (hasPermission) {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            final kasedDir = Directory('${downloadDir.path}/Kased');
            if (!await kasedDir.exists()) {
              await kasedDir.create(recursive: true);
            }
            
            // Effectuer un test d'écriture rapide pour s'assurer que Scoped Storage n'interdit pas l'écriture directe
            final testFile = File('${kasedDir.path}/.test_write');
            await testFile.writeAsString('test');
            await testFile.delete();
            
            return kasedDir;
          }
        }
      } catch (e) {
        // En cas de FileSystemException (ex: Scoped Storage strict ou permission refusée),
        // on passe silencieusement aux fallbacks
      }

      // 2. Fallback: getExternalStorageDirectory()
      // Ce répertoire est public mais propre à l'application (ex: /Android/data/[package_name]/files)
      // Il ne nécessite aucune permission d'écriture sur toutes les versions d'Android.
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final kasedDir = Directory('${extDir.path}/Kased');
          if (!await kasedDir.exists()) {
            await kasedDir.create(recursive: true);
          }
          return kasedDir;
        }
      } catch (_) {}
    }

    // 3. Fallback universel (sur iOS ou si échecs complets) : Dossier temporaire/cache
    try {
      final tempDir = await getTemporaryDirectory();
      final kasedDir = Directory('${tempDir.path}/Kased');
      if (!await kasedDir.exists()) {
        await kasedDir.create(recursive: true);
      }
      return kasedDir;
    } catch (_) {
      return await getTemporaryDirectory();
    }
  }

  /// Enregistre les octets du PDF dans le dossier d'export choisi et renvoie le fichier créé.
  static Future<File> saveFileToStorage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final exportDir = await getExportDirectory();
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Version pour chaîne de caractères (pour CSV par exemple)
  static Future<File> saveStringFileToStorage({
    required String content,
    required String fileName,
  }) async {
    final exportDir = await getExportDirectory();
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }
}
