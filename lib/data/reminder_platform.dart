import 'package:flutter/services.dart';

class ReminderStatus {
  const ReminderStatus({
    this.available = true,
    this.notifications = false,
    this.exact = false,
    this.pending = 0,
  });
  final bool available, notifications, exact;
  final int pending;
  factory ReminderStatus.fromMap(Map m) => ReminderStatus(
    notifications: m['notifications'] == true,
    exact: m['exact'] == true,
    pending: m['pending'] as int? ?? 0,
  );
}

abstract class ReminderPlatform {
  Future<ReminderStatus> sync();
  Future<ReminderStatus> requestPermission();
  Future<void> openSettings({bool exact = false});
  Future<Map<String, Object?>?> takeOpenRequest();
  void onOpen(void Function() callback);
}

class AndroidReminders implements ReminderPlatform {
  static const channel = MethodChannel('app.daypanel.next/reminders');
  @override
  Future<ReminderStatus> sync() async => ReminderStatus.fromMap(
    await channel.invokeMapMethod<String, Object?>('sync') ?? {},
  );
  @override
  Future<ReminderStatus> requestPermission() async => ReminderStatus.fromMap(
    await channel.invokeMapMethod<String, Object?>('permission') ?? {},
  );
  @override
  Future<void> openSettings({bool exact = false}) =>
      channel.invokeMethod('settings', {'exact': exact});
  @override
  Future<Map<String, Object?>?> takeOpenRequest() =>
      channel.invokeMapMethod<String, Object?>('takeOpen');
  @override
  void onOpen(void Function() callback) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'opened') callback();
    });
  }
}
