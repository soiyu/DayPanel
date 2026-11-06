import 'package:flutter/services.dart';

abstract class CompletionFeedback {
  Future<void> play({required bool sound, required bool haptics});
}

class AndroidCompletionFeedback implements CompletionFeedback {
  static const channel = MethodChannel('app.daypanel.next/feedback');
  @override
  Future<void> play({required bool sound, required bool haptics}) =>
      channel.invokeMethod('complete', {'sound': sound, 'haptics': haptics});
}
