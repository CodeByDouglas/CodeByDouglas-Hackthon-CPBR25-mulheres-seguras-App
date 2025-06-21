import 'package:flutter/foundation.dart';

class EmergencyProvider extends ChangeNotifier {
  bool _isEmergencyActive = false;
  bool _isNfcAvailable = false;
  bool _isLocationAvailable = false;
  bool _isNotificationAvailable = false;
  String? _userToken;
  int? _currentCallId;
  String? _lastKnownLocation;

  // Getters
  bool get isEmergencyActive => _isEmergencyActive;
  bool get isNfcAvailable => _isNfcAvailable;
  bool get isLocationAvailable => _isLocationAvailable;
  bool get isNotificationAvailable => _isNotificationAvailable;
  String? get userToken => _userToken;
  int? get currentCallId => _currentCallId;
  String? get lastKnownLocation => _lastKnownLocation;

  // Setters
  void setNfcAvailable(bool available) {
    _isNfcAvailable = available;
    notifyListeners();
  }

  void setLocationAvailable(bool available) {
    _isLocationAvailable = available;
    notifyListeners();
  }

  void setNotificationAvailable(bool available) {
    _isNotificationAvailable = available;
    notifyListeners();
  }

  void setUserToken(String token) {
    _userToken = token;
    notifyListeners();
  }

  void setCurrentCallId(int callId) {
    _currentCallId = callId;
    notifyListeners();
  }

  void setLastKnownLocation(String location) {
    _lastKnownLocation = location;
    notifyListeners();
  }

  // Métodos de emergência
  void activateEmergency(String token, int callId) {
    _isEmergencyActive = true;
    _userToken = token;
    _currentCallId = callId;
    _lastKnownLocation = 'Simulada: -23.5505, -46.6333';
    notifyListeners();
  }

  void deactivateEmergency() {
    _isEmergencyActive = false;
    _currentCallId = null;
    _lastKnownLocation = null;
    notifyListeners();
  }

  // Simular envio de localização
  Future<bool> sendLocationUpdate() async {
    if (!_isEmergencyActive) return false;

    // Simular delay de rede
    await Future.delayed(const Duration(seconds: 1));

    // Simular sucesso
    return true;
  }
}
