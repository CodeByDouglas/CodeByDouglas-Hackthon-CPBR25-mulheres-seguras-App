import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/emergency_service.dart';

class NfcService {
  bool _isInitialized = false;
  bool _isMonitoring = false;

  // Serviços para integração
  NotificationService? _notificationService;
  LocationService? _locationService;
  EmergencyService? _emergencyService;

  // Para desenvolvimento - simular detecção
  Timer? _simulationTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verificar se NFC está disponível
      bool isAvailable = await NfcManager.instance.isAvailable();

      if (isAvailable) {
        _isInitialized = true;
        debugPrint('NFC Service: Inicializado com sucesso');
      } else {
        debugPrint('NFC Service: NFC não disponível neste dispositivo');
      }
    } catch (e) {
      debugPrint('NFC Service: Erro na inicialização: $e');
    }
  }

  // Iniciar monitoramento em background
  Future<void> startBackgroundMonitoring({
    required NotificationService notificationService,
    required LocationService locationService,
    required EmergencyService emergencyService,
  }) async {
    if (!_isInitialized || _isMonitoring) return;

    _notificationService = notificationService;
    _locationService = locationService;
    _emergencyService = emergencyService;

    _isMonitoring = true;
    debugPrint('NFC Service: Iniciando monitoramento NFC em background');

    // Para desenvolvimento, simular detecção periódica
    if (kDebugMode) {
      _startSimulation();
    }

    // Monitoramento real NFC
    _startRealNfcMonitoring();
  }

  void stopBackgroundMonitoring() {
    _isMonitoring = false;
    _simulationTimer?.cancel();
    debugPrint('NFC Service: Monitoramento NFC em background parado');
  }

  void _startRealNfcMonitoring() {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        await _handleNfcTag(tag);
      },
    );
  }

  Future<void> _handleNfcTag(NfcTag tag) async {
    try {
      debugPrint('NFC Service: Tag detectada');

      // Tentar ler dados NDEF
      Ndef? ndef = Ndef.from(tag);
      if (ndef == null) {
        debugPrint('NFC Service: Tag não é NDEF');
        return;
      }

      // Verificar se a tag é legível
      if (!ndef.isWritable) {
        debugPrint('NFC Service: Tag não é legível');
        return;
      }

      // Ler mensagens NDEF
      NdefMessage message = await ndef.read();
      List<NdefRecord> records = message.records;

      for (NdefRecord record in records) {
        // Verificar se é um record de texto
        if (record.type.length == 1 && record.type[0] == 0x54) {
          // 'T' record

          String payload = String.fromCharCodes(record.payload);
          debugPrint('NFC Service: Payload encontrado: $payload');

          // Extrair token usando regex
          final tokenMatch = RegExp(
            r'token_nfc\s*=\s*([\w\d]+)',
          ).firstMatch(payload);
          if (tokenMatch != null) {
            final token = tokenMatch.group(1)!;
            debugPrint('NFC Service: Token de emergência detectado: $token');
            await _triggerEmergencyFlow(token);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('NFC Service: Erro ao processar tag: $e');
    }
  }

  Future<void> _triggerEmergencyFlow(String token) async {
    if (_notificationService == null ||
        _locationService == null ||
        _emergencyService == null) {
      debugPrint('NFC Service: Serviços não inicializados');
      return;
    }

    try {
      // Obter localização atual
      final position = await _locationService!.getCurrentLocation();

      // Criar chamado de emergência no backend
      final callId = await _emergencyService!.createEmergencyCall(
        token,
        position?.latitude ?? -23.5505,
        position?.longitude ?? -46.6333,
      );

      if (callId != null) {
        // Mostrar notificação interativa com contador
        await _notificationService!.showEmergencyNotificationWithTimer(
          callId: callId,
          token: token,
          locationService: _locationService!,
          emergencyService: _emergencyService!,
        );
      } else {
        debugPrint('NFC Service: Erro ao criar chamado de emergência');
      }
    } catch (e) {
      debugPrint('NFC Service: Erro no fluxo de emergência: $e');
    }
  }

  // Método para simulação (apenas desenvolvimento)
  void simulateNfcDetection() {
    if (!kDebugMode) return;

    debugPrint('NFC Service: Simulando detecção de NFC');
    _triggerEmergencyFlow('tokendouser123');
  }

  void _startSimulation() {
    if (!kDebugMode) return;

    // Simular detecção a cada 30 segundos para teste
    _simulationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isMonitoring) {
        debugPrint('NFC Service: Simulação periódica - NFC detectado');
        _triggerEmergencyFlow('tokendouser123');
      }
    });
  }

  // Verificar status do NFC
  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NFC Service: Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  // Método para parar sessão NFC
  Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
      debugPrint('NFC Service: Sessão NFC parada');
    } catch (e) {
      debugPrint('NFC Service: Erro ao parar sessão: $e');
    }
  }

  void dispose() {
    stopBackgroundMonitoring();
    _simulationTimer?.cancel();
  }
}
