import 'package:flutter/services.dart';

abstract class WidgetPlatform {
  Future<void> refresh();
  Future<Map<String, Object?>?> launch();
  Future<bool> validate(Map<String, Object?> request);
  Future<void> configure(int widgetId, String id, int generation);
  Future<void> close();
  Future<void> openApp();
}

abstract class WidgetUpdates {
  void onChanged(void Function() callback);
}

abstract class WidgetPinning {
  Future<bool> canPin();
  Future<bool> hasWidgets();
  Future<bool> pin(String kind, String id, int generation);
}

class AndroidWidgets implements WidgetPlatform, WidgetUpdates, WidgetPinning {
  static const channel = MethodChannel('app.daypanel.next/widgets');
  @override
  Future<bool> canPin() async =>
      await channel.invokeMethod<bool>('canPin') ?? false;
  @override
  Future<bool> hasWidgets() async =>
      await channel.invokeMethod<bool>('hasWidgets') ?? false;
  @override
  Future<bool> pin(String kind, String id, int generation) async =>
      await channel.invokeMethod<bool>('pin', {
        'kind': kind,
        'id': id,
        'generation': generation,
      }) ??
      false;
  @override
  void onChanged(void Function() callback) =>
      channel.setMethodCallHandler((call) async {
        if (call.method == 'dataChanged') callback();
      });
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
