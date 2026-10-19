import 'dart:async';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:app/services/image_service/image_service.dart';

class FakeImageService implements ImageService {
  final script = <Object>[];
  final pending = <StreamController<FileResponse>>[];
  var calls = 0;
  var holdOpen = false;

  late final _ScriptedCacheManager _cache = _ScriptedCacheManager(this);

  @override
  BaseCacheManager get cacheManager => _cache;

  Future<void> dispose() async {
    for (final controller in pending) {
      await controller.close();
    }
  }
}

class _ScriptedCacheManager implements BaseCacheManager {
  final FakeImageService _service;

  _ScriptedCacheManager(this._service);

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    _service.calls += 1;
    if (_service.holdOpen) {
      final controller = StreamController<FileResponse>();
      _service.pending.add(controller);
      controller.add(DownloadProgress(url, 100, 0));
      return controller.stream;
    }
    return _next(url);
  }

  @override
  Future<FileInfo> downloadFile(String url, {String? key, Map<String, String>? authHeaders, bool force = false}) =>
      throw UnimplementedError();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Stream<FileInfo> getFile(String url, {String? key, Map<String, String>? headers}) => throw UnimplementedError();

  @override
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false}) async => null;

  @override
  Future<FileInfo?> getFileFromMemory(String key) async => null;

  @override
  Future<File> getSingleFile(String url, {String key = '', Map<String, String> headers = const <String, String>{}}) =>
      throw UnimplementedError();

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => throw UnimplementedError();

  @override
  Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => throw UnimplementedError();

  @override
  Future<void> removeFile(String key) async {}

  Stream<FileResponse> _next(String url) async* {
    final next = _service.script.removeAt(0);
    if (next is Uint8List) {
      final file = MemoryFileSystem().file('/image.png')..writeAsBytesSync(next);
      yield FileInfo(file, FileSource.Online, DateTime.now().add(const Duration(days: 1)), url);
      return;
    }
    throw next;
  }
}
