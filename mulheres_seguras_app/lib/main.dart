import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/nfc_service.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';
import 'services/emergency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientação para portrait apenas
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar serviços
  final nfcService = NfcService();
  final notificationService = NotificationService();
  final locationService = LocationService();
  final emergencyService = EmergencyService();

  // Inicializar serviços
  await nfcService.initialize();
  await notificationService.initialize();
  await locationService.initialize();

  // Iniciar monitoramento NFC em background
  await nfcService.startBackgroundMonitoring(
    notificationService: notificationService,
    locationService: locationService,
    emergencyService: emergencyService,
  );

  // Rodar app minimalista (apenas para manter o processo ativo)
  runApp(const BackgroundApp());
}

class BackgroundApp extends StatelessWidget {
  const BackgroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E.L.A Background',
      theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
      home: const BackgroundScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BackgroundScreen extends StatelessWidget {
  const BackgroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'E.L.A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monitoramento Ativo',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Text(
              'O app está rodando em background\nAproxime uma tag NFC para ativar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
