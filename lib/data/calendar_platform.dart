import 'package:flutter/services.dart';

class CalendarPlatform {
  static const channel = MethodChannel('app.daypanel.next/calendar');
  Future<bool> add(String habitId, int generation, int minute) async =>
      await channel.invokeMethod<bool>('add', {
        'id': habitId,
        'generation': generation,
        'minute': minute,
      }) ??
      false;
}
