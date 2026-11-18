import 'package:flutter/services.dart';

abstract class NoteMediaPlatform {
  Future<List<String>> pickImages({required int maxCount});
  Future<String?> getImagePath(String fileName);
  Future<void> deleteImage(String fileName);
}

class AndroidNoteMediaPlatform implements NoteMediaPlatform {
  AndroidNoteMediaPlatform({MethodChannel? channel})
    : channel = channel ?? const MethodChannel('app.daypanel.next/note-images');

  final MethodChannel channel;

  @override
  Future<List<String>> pickImages({required int maxCount}) async {
    try {
      final res = await channel.invokeMethod<List<dynamic>>('pick', {
        'max': maxCount,
      });
      return res?.map((e) => e.toString()).toList() ?? const [];
    } on PlatformException catch (_) {
      return const [];
    }
  }

  @override
  Future<String?> getImagePath(String fileName) async {
    try {
      return await channel.invokeMethod<String>('getPath', {'name': fileName});
    } on PlatformException catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteImage(String fileName) async {
    try {
      await channel.invokeMethod<void>('delete', {'name': fileName});
    } on PlatformException catch (_) {
      // Ignore cleanup error.
    }
  }
}

class MemoryNoteMediaPlatform implements NoteMediaPlatform {
  final Set<String> images = {};
  int _counter = 1;
  int pickBatchSize = 1;

  @override
  Future<List<String>> pickImages({required int maxCount}) async {
    final count = pickBatchSize.clamp(1, maxCount);
    final picked = <String>[];
    for (var i = 0; i < count; i++) {
      final name = 'memory_image_${_counter++}.jpg';
      images.add(name);
      picked.add(name);
    }
    return picked;
  }

  @override
  Future<String?> getImagePath(String fileName) async => '/fake_path/$fileName';

  @override
  Future<void> deleteImage(String fileName) async {
    images.remove(fileName);
  }
}
