# App Flutter Android: NFC em Background e Alerta de Emergência

Perfeito! Vou montar a estrutura inicial de um app Flutter focado em Android, com integração em Kotlin para leitura contínua de NFC em background (inclusive com a tela bloqueada), notificações interativas e envio de localização para endpoints do backend em Flask.

Vou considerar:

* Uso exclusivo do VS Code
* Integração de Flutter com código nativo Kotlin via platform channels
* Monitoramento de NFC e background execution
* Notificação com botões (Confirmar/Cancelar) e timeout de 1 minuto
* Compartilhamento da localização até resposta 400

Já volto com a estrutura recomendada e exemplos de implementação.

---

## Configuração Inicial do Projeto Flutter (Android Only)

Para começar, crie um novo projeto Flutter focado apenas no Android (pode usar o comando `flutter create --platforms=android nome_do_app`). Certifique-se de escolher **Kotlin** como linguagem nativa (Flutter já usa Kotlin por padrão nas versões recentes). Toda a estrutura será gerenciada no VS Code, editando diretamente os arquivos de configuração Android dentro da pasta `android/`. Os principais pontos iniciais incluem:

* **AndroidManifest.xml**: Adicione as permissões necessárias no `<manifest>`:

  ```xml
  <!-- NFC e funcionalidades do hardware NFC -->
  <uses-permission android:name="android.permission.NFC" />
  <uses-feature android:name="android.hardware.nfc" android:required="true"/>

  <!-- Permissões de localização -->
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

  <!-- Permissão para executar serviço em primeiro plano -->
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <!-- Necessária no Android 14+ para serviço de localização em primeiro plano -->
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

  <!-- Permissão de Internet para chamadas HTTP -->
  <uses-permission android:name="android.permission.INTERNET" />

  <!-- (Opcional) Permissão para notificações no Android 13+ -->
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  ```

  Essas permissões cobrem o acesso ao NFC, localização (inclusive em segundo plano), execução de serviço em foreground e acesso à internet. Note que a partir do Android 13 é necessário pedir permissão de notificação em tempo de execução se quiser exibir notificações interativas.

* **minSdkVersion**: Defina o *minSdkVersion* do app para **19 ou superior** no `android/app/build.gradle`, pois bibliotecas de NFC requerem pelo menos API 19. Por exemplo:

  ```gradle
  defaultConfig {
      applicationId "com.seuorg.seuapp"
      minSdkVersion 19
      targetSdkVersion 33 // ou 34, conforme necessidade
      // ...
  }
  ```

* **Dependências do Gradle (Android)**: No arquivo `android/app/build.gradle`, inclua a dependência dos serviços de localização do Google Play, já que usaremos o provedor de localização fusionada (Fused Location Provider) no serviço Kotlin:

  ```gradle
  dependencies {
      implementation 'com.google.android.gms:play-services-location:21.3.0'
      // ... outras dependências
  }
  ```

* **Pacotes Flutter (pubspec.yaml)**: Adicione os pacotes recomendados para as funcionalidades:

  * `flutter_nfc_reader`: Plugin para ler tags NFC em background.
  * `flutter_local_notifications`: Para exibir notificação local com botões de ação.
  * `permission_handler` (opcional): Para solicitar permissões em tempo de execução.

  Use `flutter pub add <pacote>` ou edite o `pubspec.yaml` e rode `flutter pub get`.

* **Executando no VS Code**: Abra e edite todos os arquivos no VS Code. Para rodar e depurar, use `flutter run` ou *launch configurations*. Conecte um dispositivo físico Android para testes NFC.

---

## Integração Flutter + Kotlin (Platform Channels)

No `MainActivity.kt`, registre um `MethodChannel` em `configureFlutterEngine` para iniciar/parar o serviço de localização:

```kotlin
class MainActivity: FlutterActivity() {
    private val CHANNEL = "emergency_service_channel"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when(call.method) {
                "startEmergencyService" -> {
                    val serviceIntent = Intent(this, EmergencyLocationService::class.java)
                    ContextCompat.startForegroundService(this, serviceIntent)
                    result.success("Service Started")
                }
                "stopEmergencyService" -> {
                    stopService(Intent(this, EmergencyLocationService::class.java))
                    result.success("Service Stopped")
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

Registre o serviço no `AndroidManifest.xml`:

```xml
<application>
  <service
      android:name=".EmergencyLocationService"
      android:foregroundServiceType="location"
      android:exported="false"/>
</application>
```

---

## Leitura de NFC em Segundo Plano (Flutter)

Use o plugin `flutter_nfc_reader`:

```dart
FlutterNfcReader.onTagDiscovered().listen((NfcData data) {
  if (data.status == NFCStatus.read && data.content.contains("token_nfc = tokendouser123")) {
    dispararAlertaEmergencia();
  }
});
```

Programe as tags NFC com registro do seu app (Android Application Record) para acordar o app com tela bloqueada.

---

## Notificações Interativas (Confirmar/Cancelar)

### Inicialização

```dart
FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
await notifications.initialize(
  InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  onDidReceiveNotificationResponse: _tratarAcaoNotificacao,
  onDidReceiveBackgroundNotificationResponse: _tratarAcaoNotificacaoBackground
);

await notifications
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(
      AndroidNotificationChannel('emergency_channel','Emergências', importance: Importance.max)
    );
```

### Exibição da Notificação

```dart
await notifications.show(
  0,
  "🚨 Você está abrindo um alerta de emergência",
  "Confirme para enviar ajuda ou cancele se for alarme falso.",
  NotificationDetails(
    android: AndroidNotificationDetails(
      'emergency_channel','Emergências',
      fullScreenIntent: true,
      timeoutAfter: 60000,
      actions: [
        AndroidNotificationAction('ACTION_CONFIRM','Confirmar', showsUserInterface: false),
        AndroidNotificationAction('ACTION_CANCEL','Cancelar', showsUserInterface: false)
      ]
    )
  ),
  payload: 'emergency'
);
```

### Tratamento de Ações

```dart
void _tratarAcaoNotificacao(NotificationResponse resp) {...}
static @pragma('vm:entry-point')
void _tratarAcaoNotificacaoBackground(NotificationResponse resp) {...}
```

Implemente um `Timer(Duration(minutes:1), ...)` para timeout automático.

---

## Serviço de Localização em Background (Kotlin)

```kotlin
class EmergencyLocationService: Service() {
  override fun onCreate() {
    startForeground(1, createNotification())
    fusedClient = LocationServices.getFusedLocationProviderClient(this)
  }
  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    Executors.newSingleThreadExecutor().execute { postEmergency() }
    requestLocationUpdates()
    return START_STICKY
  }
  override fun onDestroy() {
    fusedClient?.removeLocationUpdates(locationCallback!!)
  }
}
```

Registre o canal e implemente `sendLocationUpdate(lat, lng)` que para o serviço se receber 400.

---

## Desenvolvimento e Execução via VS Code

1. Edite código nativo e Dart no VS Code.
2. Use `flutter pub get` e `flutter run`.
3. Teste NFC, notificações e serviço conforme passo a passo:

   1. Conceda permissões
   2. Bloqueie a tela e aproxime a tag NFC
   3. Teste Confirmar, Cancelar e Timeout
   4. Verifique envios de localização e parada com 400

**Referências**:

* `flutter_nfc_reader` plugin docs
* `flutter_local_notifications` plugin docs
* Android Foreground Service guidelines
* Android Notification Actions usage
