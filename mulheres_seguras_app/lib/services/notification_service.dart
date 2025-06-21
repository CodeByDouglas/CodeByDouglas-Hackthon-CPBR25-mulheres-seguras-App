import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/location_service.dart';
import '../services/emergency_service.dart';

class NotificationService {
  static const String _channelId = 'emergency_channel';
  static const String _channelName = 'Emergências';
  static const String _channelDescription = 'Canal para notificações de emergência';
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  int _currentCountdown = 60;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuração para Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      // Inicializar plugin
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
      );

      // Criar canal de notificação para Android
      await _createNotificationChannel();

      _isInitialized = true;
      debugPrint('Notification Service: Inicializado com sucesso');
    } catch (e) {
      debugPrint('Notification Service: Erro na inicialização: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Verificar se o serviço está disponível
  Future<bool> isAvailable() async {
    try {
      // Verificar se as notificações estão habilitadas
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
        return areNotificationsEnabled ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Notification Service: Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  // Solicitar permissão de notificação
  Future<void> requestPermission() async {
    try {
      await Permission.notification.request();
    } catch (e) {
      debugPrint('Notification Service: Erro ao solicitar permissão: $e');
    }
  }

  // Mostrar notificação de emergência com contador
  Future<void> showEmergencyNotificationWithTimer({
    required int callId,
    required String token,
    required LocationService locationService,
    required EmergencyService emergencyService,
  }) async {
    if (!_isInitialized) {
      debugPrint('Notification Service: Não inicializado');
      return;
    }

    try {
      // Cancelar notificação anterior se existir
      await _notifications.cancel(0);

      // Armazenar contexto da emergência atual
      _currentCallId = callId;
      _currentToken = token;
      _currentLocationService = locationService;
      _currentEmergencyService = emergencyService;

      // Resetar contador
      _currentCountdown = 60;

      // Mostrar notificação inicial
      await _updateNotificationWithCountdown(callId);

      // Iniciar contador
      _startCountdownTimer(callId, token, locationService, emergencyService);

      // Iniciar timer de timeout (60 segundos)
      _startTimeoutTimer(callId, token, locationService, emergencyService);

      debugPrint('Notification Service: Notificação de emergência com contador exibida');
    } catch (e) {
      debugPrint('Notification Service: Erro ao mostrar notificação: $e');
    }
  }

  Future<void> _updateNotificationWithCountdown(int callId) async {
    await _notifications.show(
      0, // ID da notificação
      '🚨 EMERGÊNCIA - ${_currentCountdown}s',
      'Confirme para enviar ajuda ou cancele se for alarme falso.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true, // Mostrar mesmo com tela bloqueada
          category: AndroidNotificationCategory.alarm,
          actions: [
            const AndroidNotificationAction(
              'ACTION_CONFIRM',
              'Confirmar',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'ACTION_CANCEL',
              'Cancelar',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
          ongoing: true, // Não pode ser removida pelo usuário
          autoCancel: false,
        ),
      ),
      payload: 'emergency_alert',
    );
  }

  void _startCountdownTimer(int callId, String token, LocationService locationService, EmergencyService emergencyService) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentCountdown--;
      
      if (_currentCountdown > 0) {
        // Atualizar notificação com novo contador
        _updateNotificationWithCountdown(callId);
      } else {
        // Contador chegou a zero - confirmar automaticamente
        timer.cancel();
        _confirmEmergency(callId, token, locationService, emergencyService);
      }
    });
  }

  void _startTimeoutTimer(int callId, String token, LocationService locationService, EmergencyService emergencyService) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      debugPrint('Notification Service: Timeout - confirmando emergência automaticamente');
      _confirmEmergency(callId, token, locationService, emergencyService);
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    _handleNotificationAction(response.actionId);
  }

  // Callback para notificações em background
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Em background, sempre confirmar a emergência
    debugPrint('Notification Service: Notificação em background - confirmando emergência');
  }

  void _handleNotificationAction(String? actionId) {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();

    switch (actionId) {
      case 'ACTION_CONFIRM':
        debugPrint('Notification Service: Usuário confirmou emergência');
        _confirmEmergency(_currentCallId!, _currentToken!, _currentLocationService!, _currentEmergencyService!);
        break;
      case 'ACTION_CANCEL':
        debugPrint('Notification Service: Usuário cancelou emergência');
        _cancelEmergency();
        break;
      default:
        // Se não há ação específica, tratar como confirmação
        debugPrint('Notification Service: Ação não reconhecida - confirmando emergência');
        _confirmEmergency(_currentCallId!, _currentToken!, _currentLocationService!, _currentEmergencyService!);
        break;
    }
  }

  // Variáveis para armazenar contexto da emergência atual
  int? _currentCallId;
  String? _currentToken;
  LocationService? _currentLocationService;
  EmergencyService? _currentEmergencyService;

  Future<void> _confirmEmergency(int callId, String token, LocationService locationService, EmergencyService emergencyService) async {
    try {
      debugPrint('Notification Service: Confirmando emergência - Call ID: $callId');
      
      // Iniciar compartilhamento de localização em background
      await locationService.startBackgroundLocationSharing(
        callId: callId,
        onLocationUpdate: (latitude, longitude) async {
          await emergencyService.updateLocation(
            token,
            latitude,
            longitude,
          );
        },
        onError: (error) {
          if (error.contains('400')) {
            // Parar compartilhamento se receber erro 400
            locationService.stopBackgroundLocationSharing();
            debugPrint('Notification Service: Parando compartilhamento devido a erro 400');
          }
        },
      );
      
      debugPrint('Notification Service: Emergência confirmada e localização iniciada');
    } catch (e) {
      debugPrint('Notification Service: Erro ao confirmar emergência: $e');
    }
  }

  void _cancelEmergency() {
    debugPrint('Notification Service: Emergência cancelada pelo usuário');
    // Limpar notificação
    _notifications.cancel(0);
  }

  // Mostrar notificação de status
  Future<void> showStatusNotification(String title, String body) async {
    if (!_isInitialized) return;

    await _notifications.show(
      1, // ID diferente da emergência
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  void dispose() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
  }
} 