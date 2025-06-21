# E.L.A. Background - Aplicativo de Segurança Pessoal

## 📱 Sobre o Projeto

### Arquitetura Atual
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   E.L.A.        │    │   E.L.A.         │    │   Servidor      │
│   Background    │◄──►│   Frontend       │◄──►│   na Nuvem      │
│   (Flutter)     │    │   (Kotlin)       │    │   (Backend)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
   Detecção NFC           Interface do           ✅ Processamento
   Rastreamento           Usuário               ✅ Páginas Tracking
   Localização            Contatos              ✅ Mapa de Calor
                         Histórico              ✅ SMS Automático
```



O **E.L.A. Background** é um aplicativo de segurança pessoal desenvolvido em Flutter para a plataforma Android. Ele permite que usuários em situação de risco acionem rapidamente um pedido de ajuda através de uma Tag NFC, operando de forma discreta em segundo plano.

### 🏆 Contexto do Hackathon

**E.L.A. Background** é **metade do aplicativo E.L.A. (Emergência, Localização e Apoio)**. Para acelerar a prototipação durante o hackathon, decidimos dividir o desenvolvimento em dois APKs diferentes:

- **E.L.A. Background** (este repositório): Focado na detecção NFC e rastreamento de localização
- **[E.L.A. Frontend](https://github.com/EduFrancaDev/Projeto-ELA)**: Interface principal com cadastro de perfil, contatos de emergência e histórico

**⚠️ Importante**: O produto final será um **único aplicativo** integrando ambas as funcionalidades.

### 🎯 Principais Características

- **Monitoramento NFC em Background**: Detecta tags NFC mesmo com a tela bloqueada
- **Notificação Interativa**: Sistema de confirmação com timeout automático
- **Rastreamento em Tempo Real**: Compartilhamento contínuo de localização
- **Integração com Backend**: Comunicação automática com central de monitoramento
- **Interface Simples**: Design minimalista focado na usabilidade

## 🚀 Funcionalidades

### 🔒 Detecção NFC
- Monitoramento contínuo de tags NFC em segundo plano
- Detecção automática do token de segurança: `tokendouser123`
- Funcionamento mesmo com a tela bloqueada

### 🚨 Sistema de Emergência
- **Notificação Interativa**: Botões "Confirmar" e "Cancelar"
- **Timeout Automático**: 60 segundos para confirmação automática
- **Criação de Chamado**: Integração automática com backend

### 📍 Rastreamento de Localização
- **Localização Inicial**: Captura coordenadas no momento da detecção
- **Atualizações Contínuas**: Envio a cada 30 segundos durante emergência
- **Parada Automática**: Interrompe quando recebe resposta de erro do servidor

### ☁️ Integração com Servidor na Nuvem
- **Servidor Remoto**: Comunicação em tempo real com backend hospedado na nuvem
- **Envio de Emergências**: Processamento automático de chamados de emergência
- **Páginas de Tracking**: Geração automática de páginas web para acompanhamento
- **Mapa de Calor**: Visualização geográfica de incidentes e padrões de segurança
- **SMS Automático**: Notificação automática para contatos de emergência
- **Histórico Centralizado**: Armazenamento seguro de todos os eventos

## 🏗️ Arquitetura do Projeto

```
lib/
├── main.dart                    # Ponto de entrada da aplicação
├── models/
│   └── emergency_response.dart  # Modelo de dados da API
├── providers/
│   └── emergency_provider.dart  # Gerenciamento de estado (não utilizado)
├── screens/
│   └── home_screen.dart         # Interface principal do usuário
└── services/
    ├── emergency_service.dart   # Comunicação com backend
    ├── location_service.dart    # Gerenciamento de localização
    ├── nfc_service.dart         # Monitoramento NFC
    └── notification_service.dart # Sistema de notificações
```

## 📋 Pré-requisitos

### Desenvolvimento
- **Flutter SDK**: 3.8.1 ou superior
- **Android SDK**: API 21 ou superior
- **IDE**: Android Studio ou VS Code
- **Git**: Para controle de versão

### Dispositivo de Teste
- **Android**: Versão 5.0 (API 21) ou superior
- **NFC**: Hardware NFC habilitado
- **Localização**: GPS ativo
- **Internet**: Conexão para comunicação com backend

## ⚙️ Instalação e Configuração

### 1. Clone o Repositório
```bash
git clone <url-do-repositorio>
cd mulheres_seguras_app
```

### 2. Instale as Dependências
```bash
flutter pub get
```

### 3. Configure o Ambiente Android
```bash
flutter doctor
```
Certifique-se de que todas as verificações passem.

### 4. Execute o Aplicativo
```bash
flutter run
```

## 🔧 Configuração do Backend

### URL Base Servidor Nuvem
```
https://dcff-74-249-85-192.ngrok-free.app
```

### Endpoints Utilizados
- **POST** `/emergency/nfc/auto` - Criação de chamado de emergência
- **POST** `/emergency/update-location` - Atualização de localização

### Funcionalidades do Servidor na Nuvem
O backend hospedado na nuvem oferece funcionalidades avançadas **já implementadas e funcionando**:

- **🆘 Processamento de Emergências**: Recebe e processa chamados automaticamente
- **📱 Envio de SMS**: Notifica contatos de emergência via SMS
- **🌐 Páginas de Tracking**: Gera URLs únicas para acompanhamento em tempo real
- **🗺️ Mapa de Calor**: Visualiza padrões geográficos de incidentes
- **📊 Histórico Centralizado**: Armazena todos os eventos para análise
- **🔒 Segurança**: Autenticação e criptografia de dados sensíveis

**✅ Status**: Todas as funcionalidades estão ativas e integradas com o aplicativo.

### Token de Segurança
- **Padrão**: `tokendouser123`
- **Configuração**: Definido no código do `NfcService`

## 🔐 Permissões Necessárias

O aplicativo solicita automaticamente as seguintes permissões:

| Permissão | Descrição | Quando Solicitada |
|-----------|-----------|-------------------|
| `NFC` | Leitura de tags NFC | Primeira execução |
| `ACCESS_FINE_LOCATION` | Localização precisa | Primeira execução |
| `ACCESS_BACKGROUND_LOCATION` | Localização em background | Primeira execução |
| `POST_NOTIFICATIONS` | Notificações (Android 13+) | Primeira execução |
| `INTERNET` | Comunicação com servidor | Instalação |

## 🔄 Fluxo de Funcionamento

### 1. Inicialização
- Solicitação de permissões necessárias
- Inicialização dos serviços (NFC, Localização, Notificações)
- Início do monitoramento NFC em background

### 2. Detecção de Emergência
- **Leitura da Tag NFC**: Aproximação da tag com token válido
- **Validação**: Verificação do token `tokendouser123`
- **Criação do Chamado**: Comunicação com backend para registrar emergência

### 3. Notificação de Confirmação
- **Exibição**: Notificação de alta prioridade na tela
- **Opções**: Botões "Confirmar" e "Cancelar"
- **Timer**: Contador regressivo de 60 segundos

### 4. Ação do Usuário
- **Confirmar**: Inicia imediatamente o rastreamento de localização
- **Cancelar**: Finaliza o processo e retoma monitoramento
- **Timeout**: Confirma automaticamente após 60 segundos

### 5. Rastreamento Ativo
- **Envio de Localização**: Coordenadas enviadas a cada 30 segundos
- **Monitoramento**: Continua até resposta de erro do servidor
- **Finalização**: Para automaticamente quando recebe status 400

## 🛠️ Desenvolvimento

### Estrutura de Serviços

#### NfcService
- Inicialização e gerenciamento do `nfc_manager`
- Monitoramento contínuo de tags NFC
- Detecção do token de segurança específico

#### NotificationService
- Criação de notificações interativas
- Gerenciamento do contador regressivo
- Tratamento de ações do usuário

#### LocationService
- Obtenção de localização via `geolocator`
- Gerenciamento de permissões de localização
- Compartilhamento contínuo durante emergência

#### EmergencyService
- Comunicação HTTP com backend
- Gerenciamento de endpoints da API
- Tratamento de respostas e erros

### Modo de Desenvolvimento
- **Logs Detalhados**: Console com informações de debug
- **Simulação NFC**: Botão para testar funcionalidade
- **Monitoramento**: Status em tempo real dos serviços

## 📦 Dependências Principais

```yaml
dependencies:
  flutter:
    sdk: flutter
  nfc_manager: ^3.4.0          # Monitoramento NFC
  flutter_local_notifications: ^17.1.2  # Notificações locais
  geolocator: ^12.0.0          # Localização do dispositivo
  http: ^1.2.1                 # Comunicação HTTP
  permission_handler: ^11.3.1  # Gerenciamento de permissões
```

## 🚀 Compilação

### Build de Desenvolvimento
```bash
flutter build apk --debug
```

### Build de Produção
```bash
flutter build apk --release
```

### Limpeza de Cache
```bash
flutter clean
flutter pub get
```

## 🧪 Testes

### Executar Testes
```bash
flutter test
```

### Verificar Qualidade do Código
```bash
flutter analyze
```

## 📚 Documentação Adicional

- **`Docs/cotexto_app.md`**: Documentação detalhada do fluxo e arquitetura
- **`Docs/endpoints_integracao.md`**: Especificação completa da API
- **`Docs/ESTRUTURA_PROJETO.md`**: Estrutura de arquivos e componentes


### Integrações Atuais ✅
- **Servidor na Nuvem**: Já integrado e funcionando
- **Páginas de Tracking**: Geradas automaticamente
- **Mapa de Calor**: Visualização em tempo real
- **SMS Automático**: Envio de notificações
- **API REST**: Comunicação bidirecional

### 🗺️ Roadmap de Integração Futura
- [ ] Unificação dos dois APKs em um único aplicativo
- [ ] Integração completa entre frontend e backend
- [ ] Interface unificada com todas as funcionalidades
- [ ] Testes de integração end-to-end
- [ ] **Dashboard unificado com mapa de calor**



**Desenvolvido com ❤️ para promover a segurança para mulhures*

*Projeto desenvolvido durante o Hackathon CPBR25 - Mulheres Seguras*


