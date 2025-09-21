import 'package:geolocator/geolocator.dart';

class GpsRepository {
  Future<bool> ensurePermissions() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Stream<Position> watch() => Geolocator.getPositionStream();
}
