import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock path provider for testing
class MockPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final tempDir = Directory.systemTemp;
    final appSupportDir = Directory('${tempDir.path}/app_support');
    if (!appSupportDir.existsSync()) {
      appSupportDir.createSync(recursive: true);
    }
    return appSupportDir.path;
  }

  @override
  Future<String?> getLibraryPath() async {
    final tempDir = Directory.systemTemp;
    final libraryDir = Directory('${tempDir.path}/library');
    if (!libraryDir.existsSync()) {
      libraryDir.createSync(recursive: true);
    }
    return libraryDir.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final tempDir = Directory.systemTemp;
    final documentsDir = Directory('${tempDir.path}/documents');
    if (!documentsDir.existsSync()) {
      documentsDir.createSync(recursive: true);
    }
    return documentsDir.path;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return null; // Not available on all platforms
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return null; // Not available on all platforms
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return null; // Not available on all platforms
  }

  @override
  Future<String?> getDownloadsPath() async {
    final tempDir = Directory.systemTemp;
    final downloadsDir = Directory('${tempDir.path}/downloads');
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }
    return downloadsDir.path;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    final tempDir = Directory.systemTemp;
    final cacheDir = Directory('${tempDir.path}/cache');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    return cacheDir.path;
  }
}