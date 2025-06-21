import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/location_service.dart';
import '../services/emergency_service.dart';

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  // Esta função precisa existir, mas a lógica será tratada dentro do serviço
  // usando uma abordagem diferente para evitar problemas de contexto.
}

class NotificationService {
  static const String _channelId = 'emergency_channel';
  static const String _channelName = 'Emergências';
  static const String _channelDescription =
      'Canal para notificações de emergência';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  int _currentCountdown = 60;
  bool _actionTaken = false; // <-- Variável de bloqueio

  // Variáveis para armazenar contexto
  int? _currentCallId;
  String? _currentToken;
  LocationService? _locationService;
  EmergencyService? _emergencyService;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            onDidReceiveBackgroundNotificationResponse,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification Service: Erro na inicialização: $e');
    }
  }

  // Verificar se o serviço está disponível
  Future<bool> isAvailable() async {
    try {
      // Verificar se as notificações estão habilitadas
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final areNotificationsEnabled = await androidPlugin
            .areNotificationsEnabled();
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

      // Armazenar contexto para uso posterior
      _currentCallId = callId;
      _currentToken = token;
      _locationService = locationService;
      _emergencyService = emergencyService;
      _actionTaken = false; // Resetar o bloqueio
      _currentCountdown = 60;

      await _updateNotificationWithCountdown();
      _startTimers();

      debugPrint(
        'Notification Service: Notificação de emergência com contador exibida',
      );
    } catch (e) {
      debugPrint('Notification Service: Erro ao mostrar notificação: $e');
    }
  }

  Future<void> _updateNotificationWithCountdown() async {
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
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          actions: [
            const AndroidNotificationAction(
              'ACTION_CONFIRM',
              'Confirmar',
              showsUserInterface: false,
              cancelNotification: true, // Deixar a biblioteca tentar fechar
            ),
            const AndroidNotificationAction(
              'ACTION_CANCEL',
              'Cancelar',
              showsUserInterface: false,
              cancelNotification: true, // Deixar a biblioteca tentar fechar
            ),
          ],
          ongoing: true,
          autoCancel: false,
        ),
      ),
      payload: 'emergency_alert',
    );
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCountdown > 0) {
        _currentCountdown--;
        _updateNotificationWithCountdown();
      } else {
        handleAction('ACTION_CONFIRM');
      }
    });

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      handleAction('ACTION_CONFIRM');
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    handleAction(response.actionId);
  }

  Future<void> handleAction(String? actionId) async {
    if (_actionTaken) return; // Se a ação já foi tomada, ignora.
    _actionTaken = true; // Trava para evitar execuções múltiplas.

    _countdownTimer?.cancel();
    _timeoutTimer?.cancel();
    await _notifications.cancel(0); // Força o fechamento da notificação

    switch (actionId) {
      case 'ACTION_CONFIRM':
        await _confirmEmergency();
        break;
      case 'ACTION_CANCEL':
        await _cancelEmergency();
        break;
      default:
        // Se o usuário tocar no corpo da notificação, a trava _actionTaken
        // será ativada, mas nenhuma ação será executada. O timeout continuará.
        // Para corrigir isso, resetamos a trava se a ação for desconhecida.
        _actionTaken = false;
        break;
    }
  }

  Future<void> _confirmEmergency() async {
    if (_currentCallId == null || _currentToken == null || _locationService == null || _emergencyService == null) {
      return;
    }
    
    try {
      await _locationService!.startBackgroundLocationSharing(
        callId: _currentCallId!,
        onLocationUpdate: (latitude, longitude) async {
          await _emergencyService!.updateLocation(
            _currentToken!,
            latitude,
            longitude,
          );
        },
        onError: (error) {
          if (error.contains('400')) {
            _locationService!.stopBackgroundLocationSharing();
          }
        },
      );
    } catch (e) {
      debugPrint('Notification Service: Erro ao confirmar emergência: $e');
    }
  }

  Future<void> _cancelEmergency() async {
    debugPrint('Notification Service: Emergência cancelada pelo usuário.');
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
