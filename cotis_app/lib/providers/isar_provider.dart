import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/membre.dart';
import '../models/culte.dart';
import '../models/cotisation.dart';
import '../models/sync_operation.dart';
import '../models/corbeille_item.dart';

part 'isar_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) async {
  if (Isar.instanceNames.isNotEmpty) {
    return Future.value(Isar.getInstance()!);
  }

  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [
      MembreSchema,
      CulteSchema,
      CotisationSchema,
      SyncOperationSchema,
      CorbeilleItemSchema,
    ],
    directory: dir.path,
    name: 'kased_isar',
    inspector: !const bool.fromEnvironment('dart.vm.product'),
  );

  ref.onDispose(() async {
    if (isar.isOpen) {
      await isar.close();
    }
  });

  return isar;
}
