import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';
import '../models/device_location.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationException extends AppException {
  const LocationException(this.failure, super.message);

  final LocationFailure failure;

  bool get canOpenSettings =>
      failure == LocationFailure.serviceDisabled ||
      failure == LocationFailure.permissionDeniedForever;
}

class LocationService {
  const LocationService();

  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );
  static const _timeout = Duration(seconds: 20);

  Future<DeviceLocation> getCurrentLocation() async {
    await _ensurePermission();
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      ).timeout(_timeout);
      return _toDeviceLocation(position);
    } on TimeoutException {
      throw const LocationException(
        LocationFailure.unavailable,
        'Unable to get your location. Please try again.',
      );
    } on LocationServiceDisabledException {
      throw _serviceDisabled;
    }
  }

  Stream<DeviceLocation> watchLocation() {
    return Geolocator.getPositionStream(
      locationSettings: _settings,
    ).map(_toDeviceLocation);
  }

  Future<bool> openSettings(LocationFailure failure) {
    return failure == LocationFailure.serviceDisabled
        ? Geolocator.openLocationSettings()
        : Geolocator.openAppSettings();
  }

  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw _serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(
          LocationFailure.permissionDenied,
          'Location permission was denied.',
        );
      case LocationPermission.deniedForever:
        throw const LocationException(
          LocationFailure.permissionDeniedForever,
          'Location permission is blocked. Enable it in app settings.',
        );
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        return;
    }
  }

  static const _serviceDisabled = LocationException(
    LocationFailure.serviceDisabled,
    'Location services are turned off.',
  );

  static DeviceLocation _toDeviceLocation(Position position) => DeviceLocation(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
  );
}
