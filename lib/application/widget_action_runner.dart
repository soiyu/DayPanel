import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../data/app_store.dart';
import '../domain/models.dart';

/// No runApp / Activity: Android's queued job only hosts the shared Dart writer.
@pragma('vm:entry-point')
void widgetActionMain() {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.daypanel.next/widget-actions');
  channel.setMethodCallHandler((call) async {
    if (call.method != 'execute') throw MissingPluginException();
    final data = Map<String, Object?>.from(call.arguments as Map);
    AppStore? store;
    try {
      if (data['completed'] is! bool) return 'stale';
      store = await AppStore.open();
      final saved = await store.applyWidgetValue(
        kind: data['kind'] as String,
        id: data['id'] as String,
        day: Day.parse(data['day'] as String),
        generation: (data['generation'] as num).toInt(),
        revision: (data['revision'] as num).toInt(),
        expectedValue: data['expectedValue'],
        itemRevision: data['itemRevision'] as int?,
        completed: data['completed'] as bool,
        bindingStillValid: () async =>
            await channel.invokeMethod<bool>('binding', data) == true,
      );
      return saved ? 'saved' : 'stale';
    } on StateError {
      return 'stale';
    } on ArgumentError {
      return 'stale';
    } catch (_) {
      return 'failed';
    } finally {
      await store?.close();
    }
  });
  channel.invokeMethod<void>('ready');
}
