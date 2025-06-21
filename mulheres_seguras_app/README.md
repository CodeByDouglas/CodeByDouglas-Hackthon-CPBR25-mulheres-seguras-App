# Mulheres Seguras - App de Emergência

## Descrição

O **Mulheres Seguras** é um aplicativo Flutter desenvolvido para fornecer segurança e proteção para mulheres através de monitoramento NFC e alertas de emergência. O app funciona em background, monitorando tags NFC e disparando alertas quando necessário.

## Funcionalidades Principais

### 🔒 Monitoramento NFC em Background
- Monitora tags NFC mesmo com a tela bloqueada
- Detecta tags específicas com o token "token_nfc = tokendouser123"
- Funciona em segundo plano continuamente

### 🚨 Sistema de Alertas de Emergência
- Notificação interativa com botões "Confirmar" e "Cancelar"
- Timeout automático de 1 minuto (confirma automaticamente se não houver resposta)
- Integração com backend para criação de chamados de emergência

### 📍 Compartilhamento de Localização
- Envio automático de localização em tempo real
- Atualização a cada 30 segundos durante emergência
- Para automaticamente quando recebe erro 400 do servidor

### 🔄 Serviços em Background
- WorkManager para tarefas periódicas
- Serviços de localização em primeiro plano
- Notificações com prioridade máxima

## Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada do app
├── models/
│   └── emergency_response.dart  # Modelo de resposta da API
├── providers/
│   └── emergency_provider.dart  # Gerenciamento de estado
├── screens/
│   └── home_screen.dart      # Tela principal
├── services/
│   ├── emergency_service.dart   # Integração com backend
│   ├── nfc_service.dart         # Monitoramento NFC
│   ├── notification_service.dart # Notificações locais
│   └── location_service.dart    # Serviços de localização
└── utils/                    # Utilitários (futuro)
```

## Configuração do Ambiente

### Pré-requisitos
- Flutter SDK 3.8.1 ou superior
- Android SDK 34
- Android Studio ou VS Code
- Dispositivo Android com NFC

### Instalação

1. **Clone o repositório**
   ```bash
   git clone <url-do-repositorio>
   cd mulheres_seguras_app
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Configure o Android**
   - Certifique-se de que o Android SDK está configurado
   - Verifique se o dispositivo tem NFC habilitado

4. **Compile e execute**
   ```bash
   flutter run
   ```

## Configuração do Backend

O app está configurado para se comunicar com os seguintes endpoints:

### Endpoints Utilizados
- `GET /nfc/auto/{token}` - Criar chamado de emergência
- `POST /update-location` - Atualizar localização
- URL Base: `https://8b18-190-103-168-170.ngrok-free.app`

### Configuração do Token
- Token padrão: `tokendouser123`
- Configurável através do `EmergencyService.setUserToken()`

## Permissões Necessárias

O app solicita automaticamente as seguintes permissões:

### Android
- `android.permission.NFC` - Leitura de tags NFC
- `android.permission.ACCESS_FINE_LOCATION` - Localização precisa
- `android.permission.ACCESS_BACKGROUND_LOCATION` - Localização em background
- `android.permission.FOREGROUND_SERVICE` - Serviços em primeiro plano
- `android.permission.POST_NOTIFICATIONS` - Notificações (Android 13+)
- `android.permission.INTERNET` - Comunicação com servidor

## Fluxo de Funcionamento

1. **Inicialização**
   - App solicita permissões necessárias
   - Inicializa serviços (NFC, Localização, Notificações)
   - Inicia monitoramento NFC em background

2. **Detecção de NFC**
   - Quando uma tag NFC é detectada
   - Verifica se contém o token de emergência
   - Dispara notificação interativa

3. **Resposta do Usuário**
   - **Confirmar**: Cria chamado de emergência e inicia compartilhamento de localização
   - **Cancelar**: Limpa notificação e retoma monitoramento
   - **Timeout**: Confirma automaticamente após 1 minuto

4. **Emergência Ativa**
   - Envia localização a cada 30 segundos
   - Para quando recebe erro 400 do servidor
   - Interface mostra status de emergência ativa

## Desenvolvimento

### Modo Debug
- Botão "Testar NFC (Dev)" para simular detecção
- Logs detalhados no console
- Simulação automática a cada 30 segundos

### Estrutura de Serviços
- **NfcService**: Monitoramento e leitura de tags NFC
- **NotificationService**: Notificações locais com ações
- **LocationService**: Obtenção e compartilhamento de localização
- **EmergencyService**: Integração com backend

### Provider Pattern
- **EmergencyProvider**: Gerencia estado global da aplicação
- Notifica mudanças de status em tempo real
- Persiste dados localmente

## Compilação

### Debug
```bash
flutter build apk --debug
```

### Release
```bash
flutter build apk --release
```

### Problemas Comuns

Se encontrar problemas de compilação:

1. **Limpe o cache**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Verifique as dependências**
   ```bash
   flutter doctor
   ```

3. **Atualize o Flutter**
   ```bash
   flutter upgrade
   ```

## Testes

### Testes Unitários
```bash
flutter test
```

### Testes de Widget
```bash
flutter test test/widget_test.dart
```

## Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## Suporte

Para dúvidas ou problemas:
- Abra uma issue no GitHub
- Consulte a documentação da API
- Entre em contato com a equipe de desenvolvimento

## Roadmap

- [ ] Interface de configuração de contatos de emergência
- [ ] Histórico de emergências
- [ ] Modo silencioso
- [ ] Integração com serviços de emergência locais
- [ ] Suporte a múltiplos idiomas
- [ ] Modo offline com cache local
