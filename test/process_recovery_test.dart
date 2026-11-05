import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';

void main() {
  sqfliteFfiInit();
  for (final phase in ['cleared', 'inserted', 'after_commit']) {
    test(
      'actual process death at $phase preserves an entire dataset',
      () async {
        final temp = await Directory.systemTemp.createTemp('daypanel-crash-');
        final path = p.join(temp.path, 'db.sqlite');
        final backup = p.join(temp.path, 'snapshot.json');
        final marker = p.join(temp.path, 'ready');
        AppStore? store;
        Process? runner;
        int? childPid;
        final output = StringBuffer();
        try {
          store = await AppStore.open(factory: databaseFactoryFfi, path: path);
          final day = Day.parse('2026-11-05');
          await store.saveTask(
            SmallTask(id: 'a', title: 'Backup', dueDay: day),
            create: true,
          );
          final original = await store.exportSnapshot();
          await File(backup).writeAsBytes(original.encode(), flush: true);
          await store.saveTask(
            SmallTask(id: 'a', title: 'Current', dueDay: day),
          );
          await store.saveNote(
            Note(id: 'n', body: 'Keep if rollback', day: day),
            create: true,
          );
          final before = await store.exportSnapshot();
          await store.close();
          store = null;
          final config = File('.dart_tool/package_config.json').absolute;
          final json =
              jsonDecode(await config.readAsString()) as Map<String, dynamic>;
          final flutter =
              (json['packages'] as List).firstWhere(
                    (m) => m['name'] == 'flutter',
                  )
                  as Map;
          final packagePath = Directory.fromUri(
            config.uri.resolve(flutter['rootUri'] as String),
          ).path;
          final sdk = p.normalize(p.join(packagePath, '..', '..'));
          final dart = p.join(
            sdk,
            'bin',
            'cache',
            'dart-sdk',
            'bin',
            Platform.isWindows ? 'dart.exe' : 'dart',
          );
          runner = await Process.start(
            dart,
            [
              p.join(sdk, 'bin', 'cache', 'flutter_tools.snapshot'),
              '--suppress-analytics',
              'test',
              '--no-pub',
              'test/support/restore_worker.dart',
            ],
            environment: {
              'DP_DB_PATH': path,
              'DP_BACKUP_PATH': backup,
              'DP_MARKER': marker,
              'DP_FAULT_PHASE': phase,
            },
          );
          runner.stdout.transform(utf8.decoder).listen(output.write);
          runner.stderr.transform(utf8.decoder).listen(output.write);
          final deadline = DateTime.now().add(const Duration(seconds: 40));
          while (!await File(marker).exists() &&
              DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          expect(
            await File(marker).exists(),
            isTrue,
            reason: output.toString(),
          );
          childPid = int.parse(await File(marker).readAsString());
          expect(Process.killPid(childPid, ProcessSignal.sigkill), isTrue);
          childPid = null;
          await runner.exitCode.timeout(const Duration(seconds: 15));
          runner = null;
          store = await AppStore.open(factory: databaseFactoryFfi, path: path);
          expect(
            (await store.exportSnapshot()).tables,
            phase == 'after_commit' ? original.tables : before.tables,
          );
          expect(await store.generation(), phase == 'after_commit' ? 1 : 0);
          if (phase == 'after_commit') {
            expect((await store.recoverySnapshot())!.tables, before.tables);
          } else {
            expect(await store.recoverySnapshot(), isNull);
          }
        } finally {
          if (childPid != null) {
            Process.killPid(childPid, ProcessSignal.sigkill);
          }
          runner?.kill();
          await store?.close();
          await temp.delete(recursive: true);
        }
      },
      timeout: const Timeout(Duration(seconds: 75)),
    );
  }
}
