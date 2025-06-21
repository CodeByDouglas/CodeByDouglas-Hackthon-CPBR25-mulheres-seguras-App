# Guia de Integração - Endpoints de Emergência

Este documento descreve o funcionamento detalhado dos endpoints de emergência para integração com aplicativos móveis e sistemas externos.

## Endpoints Documentados

1. **POST /emergency/update-location** - Atualização de localização durante chamado ativo
2. **GET /emergency/nfc/auto/<token>** - Criação automática de emergência via token NFC

---

## 1. POST /emergency/update-location

### Descrição
Atualiza a localização do usuário durante um chamado de emergência ativo. Este endpoint é fundamental para o rastreamento em tempo real da vítima.

### URL Base
```
POST /emergency/update-location
```

### Headers
```
Content-Type: application/json
```

### Parâmetros do Corpo (JSON)

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `token_nfc` | string | ✅ | Token NFC único do usuário |
| `latitude` | float | ✅ | Latitude da localização atual |
| `longitude` | float | ✅ | Longitude da localização atual |

### Exemplo de Requisição

```json
{
  "token_nfc": "abc123def456",
  "latitude": -23.5505,
  "longitude": -46.6333
}
```

### Resposta de Sucesso (200)

```json
{
  "message": "Localização atualizada com sucesso",
  "call_id": 123,
  "route_length": 5,
  "current_location": {
    "lat": -23.5505,
    "lng": -46.6333
  }
}
```

### Campos da Resposta

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `message` | string | Mensagem de confirmação |
| `call_id` | integer | ID do chamado de emergência ativo |
| `route_length` | integer | Número total de pontos no histórico de localização |
| `current_location` | object | Coordenadas da localização atualizada |

### Códigos de Erro

#### 400 - Dados Inválidos
```json
{
  "error": "Token NFC, latitude e longitude são obrigatórios"
}
```

#### 400 - Coordenadas Inválidas
```json
{
  "error": "Latitude e longitude devem ser números"
}
```

#### 404 - Usuário Não Encontrado
```json
{
  "error": "Usuário não encontrado"
}
```

#### 400 - Sem Chamado Ativo
```json
{
  "error": "Não há chamado ativo para este usuário"
}
```

#### 500 - Erro Interno
```json
{
  "error": "Erro ao atualizar localização: [detalhes do erro]"
}
```

### Comportamento Específico

- **Histórico de Rota**: O sistema mantém um histórico de todas as localizações durante o chamado
- **Deduplicação**: Localizações idênticas consecutivas não são duplicadas no histórico
- **Validação**: Coordenadas são validadas como números válidos
- **Persistência**: Localização atual é sempre atualizada, mesmo se for idêntica à anterior

---

## 2. GET /emergency/nfc/auto/<token>

### Descrição
Cria automaticamente um chamado de emergência ao receber um token NFC válido. Opcionalmente aceita coordenadas iniciais e envia SMS para todos os contatos de emergência cadastrados.

### URL Base
```
GET /emergency/nfc/auto/{token}
```

### Parâmetros de Query (Opcionais)

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `lat` | float | ❌ | Latitude da localização inicial |
| `lng` | float | ❌ | Longitude da localização inicial |

### Exemplos de URL

#### Sem coordenadas
```
GET /emergency/nfc/auto/abc123def456
```

#### Com coordenadas
```
GET /emergency/nfc/auto/abc123def456?lat=-23.5505&lng=-46.6333
```

### Resposta de Sucesso (201)

```json
{
  "success": true,
  "call_id": 124,
  "message": "Chamado de emergência criado e SMS enviados com sucesso"
}
```

### Resposta com Erros de SMS (201)

```json
{
  "success": false,
  "call_id": 124,
  "message": "Chamado criado mas houve erros no envio de SMS",
  "sms_errors": [
    "Erro ao enviar SMS para +5511999999999: [detalhes do erro]"
  ]
}
```

### Campos da Resposta

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `success` | boolean | Indica se a operação foi bem-sucedida |
| `call_id` | integer | ID do chamado de emergência criado |
| `message` | string | Mensagem descritiva do resultado |
| `sms_errors` | array | Lista de erros no envio de SMS (apenas se houver falhas) |

### Códigos de Erro

#### 404 - Token Inválido
```json
{
  "success": false,
  "error": "Token NFC inválido"
}
```

#### 400 - Chamado Já Ativo
```json
{
  "success": false,
  "error": "Já existe um chamado ativo para este usuário"
}
```

#### 400 - Coordenadas Inválidas
```json
{
  "error": "Latitude e longitude devem ser números válidos"
}
```

#### 500 - Erro Interno
```json
{
  "success": false,
  "error": "Erro ao criar chamado: [detalhes do erro]"
}
```

### Funcionalidades Automáticas

1. **Criação do Chamado**: Cria automaticamente um chamado com status "Ativo"
2. **Localização Inicial**: Salva as coordenadas fornecidas como ponto inicial da rota
3. **Envio de SMS**: Envia notificação para todos os contatos de emergência cadastrados
4. **Link de Acompanhamento**: Cada SMS contém um link único para acompanhar o chamado

### Formato do SMS Enviado

```
ALERTA! [Nome do Usuário] precisa de ajuda. Acesse: https://8b18-190-103-168-170.ngrok-free.app/{token}/{call_id}
```

---

## Exemplos de Integração

### JavaScript/Node.js

```javascript
// Atualizar localização
async function updateLocation(tokenNfc, latitude, longitude) {
  const response = await fetch('/emergency/update-location', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      token_nfc: tokenNfc,
      latitude: latitude,
      longitude: longitude
    })
  });
  
  return await response.json();
}

// Criar emergência automática
async function createAutoEmergency(tokenNfc, latitude = null, longitude = null) {
  let url = `/emergency/nfc/auto/${tokenNfc}`;
  if (latitude && longitude) {
    url += `?lat=${latitude}&lng=${longitude}`;
  }
  
  const response = await fetch(url, {
    method: 'GET'
  });
  
  return await response.json();
}
```

### Python

```python
import requests
import json

def update_location(token_nfc, latitude, longitude):
    url = "/emergency/update-location"
    data = {
        "token_nfc": token_nfc,
        "latitude": latitude,
        "longitude": longitude
    }
    
    response = requests.post(url, json=data)
    return response.json()

def create_auto_emergency(token_nfc, latitude=None, longitude=None):
    url = f"/emergency/nfc/auto/{token_nfc}"
    params = {}
    
    if latitude and longitude:
        params = {"lat": latitude, "lng": longitude}
    
    response = requests.get(url, params=params)
    return response.json()
```

### cURL

```bash
# Atualizar localização
curl -X POST /emergency/update-location \
  -H "Content-Type: application/json" \
  -d '{
    "token_nfc": "abc123def456",
    "latitude": -23.5505,
    "longitude": -46.6333
  }'

# Criar emergência automática
curl -X GET "/emergency/nfc/auto/abc123def456?lat=-23.5505&lng=-46.6333"
```

---

## Considerações de Segurança

1. **Tokens NFC**: São únicos por usuário e devem ser mantidos seguros
2. **Validação de Coordenadas**: Sempre valide as coordenadas antes do envio
3. **Rate Limiting**: Considere implementar limites de requisição para evitar spam
4. **HTTPS**: Sempre use HTTPS em produção para proteger os dados

## Tratamento de Erros

### Estratégias Recomendadas

1. **Retry Logic**: Implemente retry automático para erros 5xx
2. **Fallback**: Tenha um plano alternativo caso os endpoints não estejam disponíveis
3. **Logging**: Registre todos os erros para debugging
4. **User Feedback**: Informe o usuário sobre o status das operações

### Exemplo de Tratamento de Erro

```javascript
async function safeUpdateLocation(tokenNfc, latitude, longitude) {
  try {
    const result = await updateLocation(tokenNfc, latitude, longitude);
    
    if (result.error) {
      console.error('Erro na atualização:', result.error);
      // Implementar lógica de retry ou fallback
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Erro de rede:', error);
    // Implementar retry logic
    return false;
  }
}
```

---

## Suporte

Para dúvidas sobre integração ou problemas técnicos, consulte a documentação completa da API ou entre em contato com a equipe de desenvolvimento. 