import 'package:flutter/services.dart';

abstract class CardImageFiles {
  Future<bool> save(Uint8List png, String name);
  Future<void> share(Uint8List png, String name);
}

class AndroidCardImageFiles implements CardImageFiles {
  static const channel = MethodChannel('app.daypanel.next/card-image');
  @override
  Future<bool> save(Uint8List png, String name) async =>
      await const MethodChannel(
        'app.daypanel.next/documents',
      ).invokeMethod<bool>('save', {
        'bytes': png,
        'name': name,
        'mime': 'image/png',
      }) ??
      false;
  @override
  Future<void> share(Uint8List png, String name) =>
      channel.invokeMethod('share', {'bytes': png, 'name': name});
}
