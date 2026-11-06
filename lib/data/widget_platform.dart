import 'package:flutter/services.dart';

abstract class WidgetPlatform {
  Future<void> refresh();
  Future<Map<String, Object?>?> launch();
  Future<bool> validate(Map<String, Object?> request);
  Future<void> configure(int widgetId, String id, int generation);
  Future<void> close();
  Future<void> openApp();
}

class AndroidWidgets implements WidgetPlatform {
  static const channel = MethodChannel('app.daypanel.next/widgets');
  @override
  Future<void> refresh() => channel.invokeMethod('refresh');
  @override
  Future<Map<String, Object?>?> launch() =>
      channel.invokeMapMethod<String, Object?>('launch');
  @override
  Future<bool> validate(Map<String, Object?> request) async =>
      await channel.invokeMethod<bool>('validate', request) ?? false;
  @override
  Future<void> configure(int widgetId, String id, int generation) =>
      channel.invokeMethod('configure', {
        'widgetId': widgetId,
        'id': id,
        'generation': generation,
      });
  @override
  Future<void> close() => channel.invokeMethod('close');
  @override
  Future<void> openApp() => channel.invokeMethod('openApp');
}
