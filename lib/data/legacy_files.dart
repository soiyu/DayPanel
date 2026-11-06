import 'document_files.dart';

abstract class LegacyFiles {
  Future<Map<Object?, Object?>?> pick();
}

class AndroidLegacyFiles implements LegacyFiles {
  @override
  Future<Map<Object?, Object?>?> pick() async {
    final bytes = await AndroidDocumentFiles().pick();
    if (bytes == null) return null;
    return AndroidDocumentFiles.channel.invokeMapMethod<Object?, Object?>(
      'readLegacy',
      {'bytes': bytes},
    );
  }
}
