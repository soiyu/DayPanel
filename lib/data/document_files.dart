import 'package:flutter/services.dart';

abstract class DocumentFiles {
  Future<bool> save(Uint8List bytes, String name);
  Future<Uint8List?> pick();
}

class AndroidDocumentFiles implements DocumentFiles {
  static const channel = MethodChannel('app.daypanel.next/documents');
  @override
  Future<bool> save(Uint8List bytes, String name) async =>
      await channel.invokeMethod<bool>('save', {
        'bytes': bytes,
        'name': name,
      }) ??
      false;
  @override
  Future<Uint8List?> pick() => channel.invokeMethod<Uint8List>('pick');
}
