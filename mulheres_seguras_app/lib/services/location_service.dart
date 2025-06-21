import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  StreamSubscription<Position>? _locationSubscription;
  bool _isInitialized = false;
  bool _isLocationSharing = false;
  Position? _lastKnownPosition;

  // Configurações de localização
  static const LocationAccuracy _accuracy = LocationAccuracy.high;
  static const Duration _updateInterval = Duration(seconds: 10);
  static const int _minDistance = 5; // 5 metros

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verificar permissões
      bool hasPermission = await _checkLocationPermission();

      if (hasPermission) {
        _isInitialized = true;
        debugPrint('Location Service: Inicializado com sucesso');

        // Obter localização inicial
        await _getCurrentLocation();
      } else {
        debugPrint('Location Service: Permissões de localização negadas');
      }
    } catch (e) {
      debugPrint('Location Service: Erro na inicialização: $e');
    }
  }

  Future<bool> _checkLocationPermission() async {
    // Verificar se localização está habilitada
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location Service: Serviços de localização desabilitados');
      return false;
    }

    // Verificar permissões
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location Service: Permissões de localização negadas');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'Location Service: Permissões de localização negadas permanentemente',
      );
      return false;
    }

    // Solicitar permissão de localização em background (Android)
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _getCurrentLocation();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location Service: Serviço de localização desabilitado.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location Service: Permissão de localização negada.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location Service: Permissão de localização negada permanentemente.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
    } catch (e) {
      debugPrint('Location Service: Erro ao obter localização: $e');
      return null;
    }
  }

  Future<void> startLocationSharing() async {
    if (!_isInitialized || _isLocationSharing) return;

    try {
      _isLocationSharing = true;
      debugPrint('Location Service: Iniciando compartilhamento de localização');

      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: _accuracy,
              distanceFilter: _minDistance,
              timeLimit: _updateInterval,
            ),
          ).listen(
            (Position position) {
              _onLocationUpdate(position);
            },
            onError: (error) {
              debugPrint(
                'Location Service: Erro no stream de localização: $error',
              );
            },
          );
    } catch (e) {
      debugPrint('Location Service: Erro ao iniciar compartilhamento: $e');
      _isLocationSharing = false;
    }
  }

  void stopLocationSharing() {
    _isLocationSharing = false;
    _locationSubscription?.cancel();
    debugPrint('Location Service: Compartilhamento de localização parado');
  }

  void _onLocationUpdate(Position position) {
    _lastKnownPosition = position;
    debugPrint(
      'Location Service: Nova localização - ${position.latitude}, ${position.longitude}',
    );

    // Aqui você pode implementar o envio da localização para o backend
    // Por exemplo, chamar EmergencyService().sendLocationUpdate(position);
  }

  // Obter última localização conhecida
  Position? get lastKnownPosition => _lastKnownPosition;

  // Verificar se está compartilhando localização
  bool get isLocationSharing => _isLocationSharing;

  // Verificar se o serviço está inicializado
  bool get isInitialized => _isInitialized;

  // Calcular distância entre duas posições
  double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  // Verificar se a localização mudou significativamente
  bool hasLocationChangedSignificantly(Position newPosition) {
    if (_lastKnownPosition == null) return true;

    double distance = calculateDistance(_lastKnownPosition!, newPosition);
    return distance > _minDistance;
  }

  // Verificar se o serviço está disponível
  Future<bool> isAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      return serviceEnabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (e) {
      debugPrint('Location Service: Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  // Solicitar permissão de localização
  Future<void> requestPermission() async {
    try {
      await _checkLocationPermission();
    } catch (e) {
      debugPrint('Location Service: Erro ao solicitar permissão: $e');
    }
  }

  // Iniciar compartilhamento de localização em background
  Future<void> startBackgroundLocationSharing({
    required int callId,
    required Function(double, double) onLocationUpdate,
    required Function(String) onError,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isLocationSharing) {
      stopLocationSharing();
    }

    try {
      _isLocationSharing = true;
      debugPrint('Location Service: Iniciando compartilhamento em background');

      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: _accuracy,
              distanceFilter: _minDistance,
              timeLimit: _updateInterval,
            ),
          ).listen(
            (Position position) {
              _lastKnownPosition = position;
              onLocationUpdate(position.latitude, position.longitude);
            },
            onError: (error) {
              debugPrint(
                'Location Service: Erro no stream de localização: $error',
              );
              onError(error.toString());
            },
          );
    } catch (e) {
      debugPrint(
        'Location Service: Erro ao iniciar compartilhamento em background: $e',
      );
      _isLocationSharing = false;
      onError(e.toString());
    }
  }

  // Parar compartilhamento de localização em background
  void stopBackgroundLocationSharing() {
    stopLocationSharing();
  }

  // Verificar se o GPS está ativo
  Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Abrir configurações de localização
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Abrir configurações de permissões
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  void dispose() {
    stopLocationSharing();
    _locationSubscription?.cancel();
  }
}
