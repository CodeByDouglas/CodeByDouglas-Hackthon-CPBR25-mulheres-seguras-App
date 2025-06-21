# Estrutura do Projeto: E.L.A. Background

## 1. Visão Geral

Este documento descreve a estrutura de arquivos e a arquitetura do aplicativo "E.L.A. Background". O projeto foi desenvolvido em Flutter/Dart, com foco na plataforma Android.

## 2. Estrutura de Diretórios

A organização do projeto segue as convenções do Flutter, com uma separação clara de responsabilidades na pasta `lib/`.

```
mulheres_seguras_app/
├── android/              # Configurações específicas da plataforma Android
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml  # Permissões e configuração do app
│   │   │   └── res/
│   │   │       └── mipmap-*         # Ícones do aplicativo
│   │   └── build.gradle.kts       # Configuração de build do Android
├── assets/
│   └── icons/
│       └── logo_app.png      # Logo utilizado no projeto
├── lib/
│   ├── main.dart             # Ponto de entrada da aplicação
│   ├── models/
│   │   └── emergency_response.dart # Modelo de dados para a resposta da API
│   ├── providers/
│   │   └── emergency_provider.dart # (Atualmente não utilizado)
│   ├── screens/
│   │   └── home_screen.dart    # UI principal do aplicativo
│   └── services/
│       ├── emergency_service.dart # Comunicação com a API de backend
│       ├── location_service.dart  # Gerencia a obtenção de localização
│       ├── nfc_service.dart       # Lida com a leitura de tags NFC
│       └── notification_service.dart # Controla as notificações
├── pubspec.yaml            # Definição de dependências e assets
└── README.md               # Documentação geral do projeto
```

## 3. Componentes Principais

### `main.dart`
É o ponto de entrada do aplicativo. Suas principais responsabilidades são:
- Inicializar os serviços essenciais, como `NotificationService` e `NfcService`.
- Configurar a estrutura da aplicação, definindo a `HomeScreen` como a tela inicial.
- Definir o `WidgetsFlutterBinding` para garantir que os plugins estejam prontos antes da inicialização.

### `screens/home_screen.dart`
Contém a interface de usuário (UI) do aplicativo. Nela, o usuário pode:
- Visualizar o status do monitoramento NFC.
- Conceder as permissões necessárias para o funcionamento do app (Localização e Notificações).

### `services/`
A pasta `services` contém o núcleo da lógica de negócios do aplicativo, separada em módulos de responsabilidade única.

*   **`nfc_service.dart`**: Inicializa e gerencia o `nfc_manager`. É responsável por iniciar o monitoramento em background para detectar tags NFC que contenham o token `tokendouser123`.
*   **`notification_service.dart`**: Lida com a criação e o gerenciamento da notificação interativa de emergência. Controla o contador regressivo, os botões "Confirmar" e "Cancelar" e a lógica de timeout.
*   **`location_service.dart`**: Abstrai a complexidade de obter a localização do dispositivo usando o pacote `geolocator`. Gerencia a solicitação de permissões e o compartilhamento contínuo da localização durante uma emergência ativa.
*   **`emergency_service.dart`**: É o único componente que se comunica com o backend. Contém a URL base da API e os métodos para criar um chamado (`/emergency/nfc/auto`) e atualizar a localização (`/emergency/update-location`).

## 4. Dependências (`pubspec.yaml`)

As principais dependências do projeto são:

```yaml
dependencies:
  flutter:
    sdk: flutter
  nfc_manager: ^3.4.0
  flutter_local_notifications: ^17.1.2
  geolocator: ^12.0.0
  http: ^1.2.1
  permission_handler: ^11.3.1
```

## 5. Status do Projeto

-   **Funcionalidades Principais**: Todas as funcionalidades (leitura NFC, notificação, localização, comunicação com backend) estão implementadas e funcionando.
-   **Build**: O aplicativo compila e roda em dispositivos Android.
-   **Documentação**: A documentação na pasta `Docs/` foi atualizada para refletir o estado atual do projeto.
-   **Próximos Passos**: Refinamento da UI, testes extensivos em diferentes dispositivos e cenários, e preparação para publicação. 