# Guia de Integração - Endpoints de Emergência

Este documento descreve o funcionamento detalhado dos endpoints de emergência para integração com o aplicativo **E.L.A. Background**.

## URL Base do Servidor

Todas as rotas descritas abaixo são relativas à seguinte URL base:

**`https://dcff-74-249-85-192.ngrok-free.app`**

---

## Endpoints Documentados

1. **POST /emergency/nfc/auto** - Criação de emergência via token NFC.
2. **POST /emergency/update-location** - Atualização de localização durante chamado ativo.

---

## 1. POST /emergency/nfc/auto

### Descrição
Cria um chamado de emergência. Este é o primeiro endpoint a ser chamado quando uma tag NFC é lida pelo aplicativo.

### URL
`POST /emergency/nfc/auto`

### Headers
`Content-Type: application/json`

### Parâmetros do Corpo (JSON)

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `token_nfc` | string | ✅ | Token NFC único do usuário, lido da tag. |
| `latitude` | float | ✅ | Latitude da localização inicial. |
| `longitude` | float | ✅ | Longitude da localização inicial. |

### Exemplo de Requisição
```json
{
  "token_nfc": "tokendouser123",
  "latitude": -23.5505,
  "longitude": -46.6333
}
```

### Resposta de Sucesso (201)
```json
{
  "success": true,
  "call_id": 124,
  "message": "Chamado de emergência criado e SMS enviados com sucesso"
}
```

---

## 2. POST /emergency/update-location

### Descrição
Atualiza a localização do usuário durante um chamado de emergência ativo. Este endpoint é chamado repetidamente pelo aplicativo para o rastreamento em tempo real.

### URL
`POST /emergency/update-location`

### Headers
`Content-Type: application/json`

### Parâmetros do Corpo (JSON)

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `token_nfc` | string | ✅ | Token NFC único do usuário. |
| `latitude` | float | ✅ | Latitude da localização atual. |
| `longitude` | float | ✅ | Longitude da localização atual. |

### Exemplo de Requisição
```json
{
  "token_nfc": "tokendouser123",
  "latitude": -23.5505,
  "longitude": -46.6333
}
```

### Resposta de Sucesso (200)
```json
{
  "message": "Localização atualizada com sucesso"
}
```

### Resposta de Erro (400)
Se o backend retornar um status 400, significa que o chamado de emergência foi encerrado ou não existe mais. O aplicativo interpreta esta resposta como um sinal para **parar o compartilhamento de localização**.
```json
{
  "error": "Não há chamado ativo para este usuário"
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