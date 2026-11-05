import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/backup.dart';

// Launched only by process_recovery_test.dart; parent deliberately terminates
// this process while the actual AppStore transaction is open.
void main() {
  test('restore crash worker', () async {
    sqfliteFfiInit();
    final env = Platform.environment;
    final store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: env['DP_DB_PATH']!,
    );
    final snapshot = BackupSnapshot.decode(
      await File(env['DP_BACKUP_PATH']!).readAsBytes(),
    );
    Future<void> pause(String phase) async {
      if (phase == env['DP_FAULT_PHASE']) {
        await File(env['DP_MARKER']!).writeAsString('$pid', flush: true);
        await Completer<void>().future;
      }
    }

    await store.restoreSnapshot(snapshot, fault: pause);
    await pause('after_commit');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
