import 'package:aina/core/error/failures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aina/core/utils/logger.dart';
import 'package:aina/core/utils/result.dart';

/// Wraps `geolocator` permission flow + position retrieval behind a
/// `Result`-returning API, so the Home/Search screens never need to
/// handle raw `LocationServiceDisabledException` / permission enums
/// themselves — they just get a coordinate or a typed [Failure].
class LocationService {
  const LocationService();

  Future<Result<Position>> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Result.failure(
          PermissionFailure('Location services are turned off. Please enable them in settings.'),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Result.failure(
            PermissionFailure('Location permission was denied.'),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Result.failure(
          PermissionFailure(
            'Location permission is permanently denied. Please enable it from app settings.',
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return Result.success(position);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get current position', e, stackTrace);
      return const Result.failure(
        UnknownFailure('Could not determine your current location.'),
      );
    }
  }

  double distanceInKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
