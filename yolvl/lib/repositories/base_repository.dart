import 'package:hive/hive.dart';

/// Base repository class providing common CRUD operations
abstract class BaseRepository<T extends HiveObject> {
  final String boxName;
  
  BaseRepository(this.boxName);

  /// Get the Hive box for this repository
  Box<T> get box {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open');
    }
    return Hive.box<T>(boxName);
  }

  /// Save an entity to the box
  Future<void> save(T entity) async {
    try {
      await entity.save();
    } catch (e) {
      throw RepositoryException('Failed to save entity: $e');
    }
  }

  /// Save multiple entities to the box
  Future<void> saveAll(List<T> entities) async {
    try {
      for (final entity in entities) {
        await entity.save();
      }
    } catch (e) {
      throw RepositoryException('Failed to save entities: $e');
    }
  }

  /// Find entity by key
  T? findByKey(dynamic key) {
    try {
      return box.get(key);
    } catch (e) {
      throw RepositoryException('Failed to find entity by key $key: $e');
    }
  }

  /// Find all entities
  List<T> findAll() {
    try {
      return box.values.toList();
    } catch (e) {
      throw RepositoryException('Failed to find all entities: $e');
    }
  }

  /// Delete entity by key
  Future<void> deleteByKey(dynamic key) async {
    try {
      await box.delete(key);
    } catch (e) {
      throw RepositoryException('Failed to delete entity by key $key: $e');
    }
  }

  /// Delete entity
  Future<void> delete(T entity) async {
    try {
      await entity.delete();
    } catch (e) {
      throw RepositoryException('Failed to delete entity: $e');
    }
  }

  /// Delete all entities
  Future<void> deleteAll() async {
    try {
      await box.clear();
    } catch (e) {
      throw RepositoryException('Failed to delete all entities: $e');
    }
  }

  /// Count total entities
  int count() {
    try {
      return box.length;
    } catch (e) {
      throw RepositoryException('Failed to count entities: $e');
    }
  }

  /// Check if entity exists by key
  bool existsByKey(dynamic key) {
    try {
      return box.containsKey(key);
    } catch (e) {
      throw RepositoryException('Failed to check if entity exists by key $key: $e');
    }
  }

  /// Get all keys
  Iterable<dynamic> getAllKeys() {
    try {
      return box.keys;
    } catch (e) {
      throw RepositoryException('Failed to get all keys: $e');
    }
  }

  /// Validate entity before save (override in subclasses)
  bool validateEntity(T entity) {
    return true;
  }

  /// Save with validation
  Future<void> saveWithValidation(T entity) async {
    if (!validateEntity(entity)) {
      throw RepositoryException('Entity validation failed');
    }
    await save(entity);
  }
}

/// Custom exception for repository operations
class RepositoryException implements Exception {
  final String message;
  
  RepositoryException(this.message);
  
  @override
  String toString() => 'RepositoryException: $message';
}