import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/legacy_import.dart';
import 'package:daypanel/domain/models.dart';

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
    final bytes = await File(env['DP_BACKUP_PATH']!).readAsBytes();
    Future<void> pause(String phase) async {
      if (phase == env['DP_FAULT_PHASE']) {
        await File(env['DP_MARKER']!).writeAsString('$pid', flush: true);
        await Completer<void>().future;
      }
    }

    if (env['DP_LEGACY'] == 'yes') {
      final day = Day.parse('2026-11-06');
      final source = LegacyImport.decode(
        (jsonDecode(utf8.decode(bytes)) as Map).cast<Object?, Object?>(),
        today: day,
      );
      await store.importLegacy(
        source,
        {
          for (final h in source.habits)
            h.id: const LegacySchedule(ScheduleKind.weekdays),
        },
        today: day,
        chinese: false,
        fault: pause,
      );
    } else {
      await store.restoreSnapshot(BackupSnapshot.decode(bytes), fault: pause);
    }
    await pause('after_commit');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
