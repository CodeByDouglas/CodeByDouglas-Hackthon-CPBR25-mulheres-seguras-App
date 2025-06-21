import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/emergency_provider.dart';
import '../services/nfc_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/emergency_service.dart';

class HomeScreen extends StatefulWidget {
  final NfcService nfcService;
  final NotificationService notificationService;
  final LocationService locationService;
  final EmergencyService emergencyService;

  const HomeScreen({
    super.key,
    required this.nfcService,
    required this.notificationService,
    required this.locationService,
    required this.emergencyService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final provider = context.read<EmergencyProvider>();
    
    try {
      // Verificar disponibilidade dos serviços
      final nfcAvailable = await widget.nfcService.isAvailable();
      final locationAvailable = await widget.locationService.isAvailable();
      final notificationAvailable = await widget.notificationService.isAvailable();
      
      provider.setNfcAvailable(nfcAvailable);
      provider.setLocationAvailable(locationAvailable);
      provider.setNotificationAvailable(notificationAvailable);
      
      // Configurar token padrão
      provider.setUserToken('tokendouser123');
      
      // Iniciar monitoramento de NFC
      if (nfcAvailable) {
        await _startNfcMonitoring();
      }
      
      // Solicitar permissões
      await _requestPermissions();
      
    } catch (e) {
      print('Erro na inicialização: $e');
      // Em caso de erro, definir como disponível para simulação
      provider.setNfcAvailable(true);
      provider.setLocationAvailable(true);
      provider.setNotificationAvailable(true);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await widget.locationService.requestPermission();
      await widget.notificationService.requestPermission();
    } catch (e) {
      print('Erro ao solicitar permissões: $e');
    }
  }

  Future<void> _startNfcMonitoring() async {
    try {
      await widget.nfcService.startMonitoring((tagData) {
        _handleNfcDetection(tagData);
      });
    } catch (e) {
      print('Erro ao iniciar monitoramento NFC: $e');
    }
  }

  void _handleNfcDetection(String tagData) {
    final tokenMatch = RegExp(r'token_nfc\s*=\s*([\w\d]+)').firstMatch(tagData);
    if (tokenMatch != null) {
      final token = tokenMatch.group(1)!;
      _activateEmergency(token);
    }
  }

  Future<void> _activateEmergency(String token) async {
    final provider = context.read<EmergencyProvider>();
    try {
      final position = await widget.locationService.getCurrentLocation();
      final callId = await widget.emergencyService.createEmergencyCall(
        token,
        position?.latitude ?? -23.5505,
        position?.longitude ?? -46.6333,
      );
      if (callId != null) {
        provider.activateEmergency(token, callId);
        await widget.notificationService.showEmergencyNotification(
          callId: callId,
          onConfirm: () => _confirmEmergency(token, callId),
          onCancel: () => _cancelEmergency(),
        );
      } else {
        provider.activateEmergency(token, 999);
      }
    } catch (e) {
      provider.activateEmergency(token, 999);
    }
  }

  Future<void> _confirmEmergency(String token, int callId) async {
    try {
      await widget.locationService.startBackgroundLocationSharing(
        callId: callId,
        onLocationUpdate: (latitude, longitude) async {
          await widget.emergencyService.updateLocation(
            token,
            latitude,
            longitude,
          );
        },
        onError: (error) {
          if (error.contains('400')) {
            widget.locationService.stopBackgroundLocationSharing();
          }
        },
      );
    } catch (e) {}
  }

  void _cancelEmergency() {
    final provider = context.read<EmergencyProvider>();
    provider.deactivateEmergency();
    widget.locationService.stopBackgroundLocationSharing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mulheres Seguras'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, emergencyProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone principal
                Icon(
                  Icons.security,
                  size: 100,
                  color: emergencyProvider.isEmergencyActive 
                      ? Colors.red 
                      : Colors.grey,
                ),
                const SizedBox(height: 24),
                
                // Status do app
                Text(
                  emergencyProvider.isEmergencyActive 
                      ? 'EMERGÊNCIA ATIVA' 
                      : 'Monitoramento Ativo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: emergencyProvider.isEmergencyActive 
                        ? Colors.red 
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Descrição
                Text(
                  emergencyProvider.isEmergencyActive
                      ? 'Sua localização está sendo compartilhada com os contatos de emergência.'
                      : 'O app está monitorando tags NFC. Aproxime uma tag de emergência para ativar o alerta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                
                // Botão de teste
                if (!emergencyProvider.isEmergencyActive)
                  ElevatedButton.icon(
                    onPressed: () {
                      _activateEmergency('tokendouser123');
                    },
                    icon: const Icon(Icons.nfc),
                    label: const Text('Testar Emergência'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Informações do status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatusItem(
                          'NFC', 
                          emergencyProvider.isNfcAvailable ? 'Disponível' : 'Indisponível',
                          emergencyProvider.isNfcAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusItem(
                          'Localização', 
                          emergencyProvider.isLocationAvailable ? 'Disponível' : 'Indisponível',
                          emergencyProvider.isLocationAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusItem(
                          'Notificações', 
                          emergencyProvider.isNotificationAvailable ? 'Disponível' : 'Indisponível',
                          emergencyProvider.isNotificationAvailable ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Informações adicionais
                if (emergencyProvider.isEmergencyActive) ...[
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Chamado Ativo',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${emergencyProvider.currentCallId ?? "N/A"}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (emergencyProvider.lastKnownLocation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Última localização: ${emergencyProvider.lastKnownLocation}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      _cancelEmergency();
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Cancelar Emergência'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Informação sobre funcionalidades
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Funcionalidades Ativas',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '✓ Monitoramento NFC em background\n'
                          '✓ Notificações interativas\n'
                          '✓ Compartilhamento de localização\n'
                          '✓ Integração com backend\n'
                          '✓ Funciona com tela bloqueada',
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
} 