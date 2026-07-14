import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aina/core/utils/logger.dart';

/// Wraps `flutter_secure_storage` for the one thing that must never sit
/// in plain SharedPreferences: the Supabase session/refresh token.
/// (Supabase's own client already persists sessions via its configured
/// `LocalStorage`; this service exists for any *additional* secrets a
/// future phase needs — e.g. a cached payment token.)
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(
        key: key,
        value: value,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Secure storage write failed for key $key', e, stackTrace);
      rethrow;
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key, aOptions: _androidOptions, iOptions: _iosOptions);
    } catch (e, stackTrace) {
      AppLogger.error('Secure storage read failed for key $key', e, stackTrace);
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key, aOptions: _androidOptions, iOptions: _iosOptions);
    } catch (e, stackTrace) {
      AppLogger.error('Secure storage delete failed for key $key', e, stackTrace);
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll(aOptions: _androidOptions, iOptions: _iosOptions);
    } catch (e, stackTrace) {
      AppLogger.error('Secure storage deleteAll failed', e, stackTrace);
    }
  }
}
