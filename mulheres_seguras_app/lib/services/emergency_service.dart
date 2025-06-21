import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

class EmergencyService {
  // URL correta do servidor em produção
  static const String _baseUrl = 'https://dcff-74-249-85-192.ngrok-free.app';
  static const String _createEmergencyEndpoint = '/emergency/nfc/auto';
  static const String _updateLocationEndpoint = '/emergency/update-location';

  // Platform channel para comunicação com serviço Kotlin
  static const MethodChannel _channel = MethodChannel(
    'emergency_service_channel',
  );

  final LocationService _locationService = LocationService();
  Timer? _locationUpdateTimer;
  bool _isLocationSharing = false;
  String? _currentToken;
  int? _currentCallId;

  // Configurações
  static const Duration _locationUpdateInterval = Duration(seconds: 30);

  EmergencyService() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentToken = prefs.getString('user_token');
    _currentCallId = prefs.getInt('current_call_id');
  }

  Future<void> _saveStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentToken != null) {
      await prefs.setString('user_token', _currentToken!);
    }
    if (_currentCallId != null) {
      await prefs.setInt('current_call_id', _currentCallId!);
    }
  }

  // Iniciar serviço Kotlin de localização em background
  Future<void> startKotlinService() async {
    try {
      await _channel.invokeMethod('startEmergencyService');
      debugPrint('Emergency Service: Serviço Kotlin iniciado');
    } catch (e) {
      debugPrint('Emergency Service: Erro ao iniciar serviço Kotlin: $e');
    }
  }

  // Parar serviço Kotlin
  Future<void> stopKotlinService() async {
    try {
      await _channel.invokeMethod('stopEmergencyService');
      debugPrint('Emergency Service: Serviço Kotlin parado');
    } catch (e) {
      debugPrint('Emergency Service: Erro ao parar serviço Kotlin: $e');
    }
  }

  // Verificar se o serviço Kotlin está rodando
  Future<bool> isKotlinServiceRunning() async {
    try {
      final isRunning = await _channel.invokeMethod(
        'isEmergencyServiceRunning',
      );
      return isRunning ?? false;
    } catch (e) {
      debugPrint('Emergency Service: Erro ao verificar serviço Kotlin: $e');
      return false;
    }
  }

  // Criar chamado de emergência
  Future<int?> createEmergencyCall(
    String token,
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('Emergency Service: Criando chamado de emergência');
      String url =
          '$_baseUrl$_createEmergencyEndpoint/$token?lat=$latitude&lng=$longitude';
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
      debugPrint(
        'Emergency Service: Resposta do servidor - \\${response.statusCode}',
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _currentCallId = data['call_id'];
        _currentToken = token;
        await _saveStoredData();
        return _currentCallId;
      } else {
        debugPrint(
          'Emergency Service: Erro ao criar chamado - \\${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Emergency Service: Erro ao criar chamado: $e');
      return null;
    }
  }

  // Atualizar localização
  Future<void> updateLocation(
    String token,
    double latitude,
    double longitude,
  ) async {
    try {
      final data = {
        'token_nfc': token,
        'latitude': latitude,
        'longitude': longitude,
      };
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_updateLocationEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        debugPrint('Emergency Service: Localização atualizada com sucesso');
      } else {
        debugPrint(
          'Emergency Service: Erro ao atualizar localização - \\${response.statusCode}',
        );
        if (response.statusCode == 400) {
          stopLocationSharing();
        }
      }
    } catch (e) {
      debugPrint('Emergency Service: Erro ao atualizar localização: $e');
    }
  }

  // Iniciar compartilhamento de localização
  Future<void> startLocationSharing() async {
    if (_isLocationSharing) return;

    _isLocationSharing = true;
    debugPrint('Emergency Service: Iniciando compartilhamento de localização');

    // Inicializar serviço de localização se necessário
    if (!_locationService.isInitialized) {
      await _locationService.initialize();
    }

    // Iniciar timer para envio periódico
    _locationUpdateTimer = Timer.periodic(_locationUpdateInterval, (timer) {
      _sendLocationUpdate();
    });

    // Enviar primeira localização imediatamente
    await _sendLocationUpdate();
  }

  // Parar compartilhamento de localização
  void stopLocationSharing() {
    _isLocationSharing = false;
    _locationUpdateTimer?.cancel();
    debugPrint('Emergency Service: Compartilhamento de localização parado');
  }

  // Enviar atualização de localização
  Future<void> sendLocationUpdate() async {
    await _sendLocationUpdate();
  }

  Future<void> _sendLocationUpdate() async {
    if (!_isLocationSharing ||
        _currentToken == null ||
        _currentCallId == null) {
      return;
    }

    try {
      // Obter localização atual
      Position? position = await _locationService.getCurrentLocation();
      if (position == null) {
        debugPrint('Emergency Service: Não foi possível obter localização');
        return;
      }

      // Preparar dados
      final data = {
        'token_nfc': _currentToken,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      // Fazer requisição
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_updateLocationEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'Emergency Service: Localização enviada - ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint(
          'Emergency Service: Localização atualizada - Call ID: ${responseData['call_id']}',
        );
      } else if (response.statusCode == 400) {
        debugPrint(
          'Emergency Service: Erro 400 - Parando compartilhamento de localização',
        );
        stopLocationSharing();

        // Limpar dados do chamado
        _currentCallId = null;
        await _saveStoredData();
      } else {
        debugPrint(
          'Emergency Service: Erro ao enviar localização: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Emergency Service: Erro ao enviar localização: $e');
    }
  }

  // Cancelar emergência
  Future<void> cancelEmergency() async {
    debugPrint('Emergency Service: Cancelando emergência');

    stopLocationSharing();
    await stopKotlinService();

    _currentCallId = null;
    await _saveStoredData();
  }

  // Verificar status do chamado
  Future<bool> isEmergencyActive() {
    return Future.value(_currentCallId != null && _isLocationSharing);
  }

  // Obter ID do chamado atual
  int? get currentCallId => _currentCallId;

  // Obter token atual
  String? get currentToken => _currentToken;

  // Configurar token do usuário
  Future<void> setUserToken(String token) async {
    _currentToken = token;
    await _saveStoredData();
    debugPrint('Emergency Service: Token configurado: $token');
  }

  // Testar conectividade com o servidor
  Future<bool> testServerConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Emergency Service: Erro ao testar conexão: $e');
      return false;
    }
  }

  // Método estático para uso em background
  static EmergencyService get instance => EmergencyService();

  void dispose() {
    stopLocationSharing();
    _locationUpdateTimer?.cancel();
  }
}
