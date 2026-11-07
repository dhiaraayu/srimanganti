import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double targetLat = -7.8053;
  static const double targetLng = 110.3642;

  /// Ambil posisi user saat ini. Return null kalau gagal / permission ditolak.
  static Future<({Position? position, String? error})>
  getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          position: null,
          error: 'GPS tidak aktif. Aktifkan lokasi di HP.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return (position: null, error: 'Permission lokasi ditolak.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return (position: null, error: 'Permission lokasi diblokir permanen.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return (position: position, error: null);
    } catch (e) {
      return (position: null, error: 'Gagal mengambil lokasi: $e');
    }
  }

  static double distanceToBangsal(Position pos) {
    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      targetLat,
      targetLng,
    );
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
}
