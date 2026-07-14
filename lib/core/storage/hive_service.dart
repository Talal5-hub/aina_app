import 'package:hive_flutter/hive_flutter.dart';
import 'package:aina/core/constants/app_constants.dart';
import 'package:aina/core/network/api_exception.dart';
import 'package:aina/core/utils/logger.dart';

/// Wraps Hive box access for the three offline-first concerns defined in
/// Phase 1: favorites, search history, and a short-lived salon list
/// cache. Box opening happens once at app startup (`initialize()`,
/// called from `main_*.dart`); everything else assumes boxes are ready.
class HiveService {
  const HiveService._();

  static late Box<dynamic> favoritesBox;
  static late Box<dynamic> searchHistoryBox;
  static late Box<dynamic> cachedSalonsBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();

    try {
      favoritesBox = await Hive.openBox(AppConstants.favoritesBoxName);
      searchHistoryBox = await Hive.openBox(AppConstants.searchHistoryBoxName);
      cachedSalonsBox = await Hive.openBox(AppConstants.cachedSalonsBoxName);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to open Hive boxes', e, stackTrace);
      throw CacheException('Failed to initialize local storage');
    }
  }

  static Future<void> put(Box box, String key, dynamic value) async {
    try {
      await box.put(key, value);
    } catch (e, stackTrace) {
      AppLogger.error('Hive put failed for key $key', e, stackTrace);
      throw CacheException('Failed to save data locally');
    }
  }

  static T? get<T>(Box box, String key) {
    try {
      return box.get(key) as T?;
    } catch (e, stackTrace) {
      AppLogger.error('Hive get failed for key $key', e, stackTrace);
      return null;
    }
  }

  static Future<void> delete(Box box, String key) async {
    try {
      await box.delete(key);
    } catch (e, stackTrace) {
      AppLogger.error('Hive delete failed for key $key', e, stackTrace);
    }
  }

  static Future<void> clearAll() async {
    await favoritesBox.clear();
    await searchHistoryBox.clear();
    await cachedSalonsBox.clear();
  }
}
