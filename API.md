# ReservAqui — Documentação da API

> **Versão:** APICruds · **Base path padrão:** configurado via `API_PREFIX` no `.env` (ex: `/api/v1`)

---

## Sumário

1. [Configuração no Flutter](#1-configuração-no-flutter)
2. [Convenções Gerais](#2-convenções-gerais)
3. [Autenticação — Hóspede (`/usuarios`)](#3-autenticação--hóspede)
4. [Autenticação — Hotel (`/hotel`)](#4-autenticação--hotel)
5. [Perfil do Hóspede](#5-perfil-do-hóspede)
6. [Perfil do Hotel](#6-perfil-do-hotel)
7. [Favoritos](#7-favoritos)
8. [Configuração do Hotel](#8-configuração-do-hotel)
9. [Catálogo do Hotel](#9-catálogo-do-hotel)
10. [Categorias de Quarto](#10-categorias-de-quarto)
11. [Quartos](#11-quartos)
12. [Reservas — Hotel](#12-reservas--hotel)
13. [Reservas — Hóspede](#13-reservas--hóspede)
14. [Reservas — Público](#14-reservas--público)
15. [Avaliações](#15-avaliações)
16. [Pagamentos](#16-pagamentos)
17. [Notificações do Hotel](#17-notificações-do-hotel)
18. [Dispositivos FCM (Push Notifications)](#18-dispositivos-fcm-push-notifications)
19. [Fotos do Hotel (Capa)](#19-fotos-do-hotel-capa)
20. [Fotos do Quarto](#20-fotos-do-quarto)

---

## 1. Configuração no Flutter

### `.env` do Flutter

```env
API_BASE_URL=https://api.reservaqui.com/api/v1
```

> O valor de `API_PREFIX` no `.env` do backend (default `/api/v1`) deve corresponder ao sufixo de `API_BASE_URL` no Flutter.

### Setup recomendado (`flutter_dotenv` + cliente centralizado)

```dart
// lib/core/api_client.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  // Tokens mantidos em memória (ou SecureStorage em produção)
  static String? _accessToken;
  static String? _refreshToken;

  static void setTokens(String access, String refresh) {
    _accessToken  = access;
    _refreshToken = refresh;
  }

  static void clearTokens() {
    _accessToken  = null;
    _refreshToken = null;
  }

  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  static Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
  };

  // ── Métodos auxiliares ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: auth ? _authHeaders : _publicHeaders,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: auth ? _authHeaders : _publicHeaders,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: auth ? _authHeaders : _publicHeaders,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<void> delete(String path, {bool auth = true}) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: auth ? _authHeaders : _publicHeaders,
    );
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(body['error'] ?? 'Erro desconhecido', res.statusCode);
    }
  }

  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(body['error'] ?? 'Erro desconhecido', res.statusCode);
    }
    return body;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
```

---

## 2. Convenções Gerais

### Autenticação

Todos os endpoints **protegidos** exigem o header:

```
Authorization: Bearer <accessToken>
```

Existem dois contextos de token — **nunca intercambiáveis**:

| Contexto | Quem usa | Obtido em |
|----------|----------|-----------|
| `authGuard` | App do hóspede | `POST /usuarios/login` |
| `hotelGuard` | Dashboard do hotel | `POST /hotel/login` |

### Formato de Respostas

**Sucesso com dados:**
```json
{ "data": { ... } }
```

**Sucesso sem dados (204):** corpo vazio.

**Erro:**
```json
{ "error": "Mensagem humanizada em português" }
```

### Códigos HTTP

| Código | Significado |
|--------|-------------|
| `200` | OK |
| `201` | Criado com sucesso |
| `204` | Operação concluída (sem corpo) |
| `400` | Dados inválidos ou campo ausente |
| `401` | Token ausente, inválido ou expirado |
| `403` | Acesso negado (recurso não pertence ao autenticado) |
| `404` | Recurso não encontrado |
| `409` | Conflito (duplicata) |
| `422` | Regra de negócio violada |
| `500` | Erro interno do servidor |

### Tipos de Dados

- **UUID:** string no formato `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **Data:** string `YYYY-MM-DD` (ex: `"2025-12-31"`)
- **Hora:** string `HH:MM` (ex: `"14:00"`)
- **DECIMAL:** retornado como **string** pelo driver PostgreSQL (ex: `"299.90"`)

---

## 3. Autenticação — Hóspede

### `POST /usuarios/register`

Cria uma nova conta de hóspede. Público.

**Body:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `nome_completo` | string | ✅ | Qualquer texto |
| `email` | string | ✅ | Deve conter `@` e `.com` |
| `senha` | string | ✅ | Mínimo: 1 maiúscula, 1 minúscula, 1 número, 1 `@` |
| `cpf` | string | ✅ | 11 dígitos (com ou sem máscara) |
| `data_nascimento` | string | ✅ | Formato `dd/mm/aaaa` |
| `numero_celular` | string | ❌ | Formato `(xx) xxxxx-xxxx` ou `(xx) xxxx-xxxx` |

**Resposta `201`:**
```json
{
  "data": {
    "user_id": "uuid",
    "nome_completo": "João Silva",
    "email": "joao@email.com",
    "cpf": "12345678901",
    "numero_celular": null,
    "data_nascimento": "1990-05-20",
    "criado_em": "2025-04-16T10:00:00Z",
    "ativo": true
  }
}
```

**Flutter:**
```dart
final body = await ApiClient.post('/usuarios/register', {
  'nome_completo': 'João Silva',
  'email': 'joao@email.com',
  'senha': 'Senha@123',
  'cpf': '123.456.789-01',
  'data_nascimento': '20/05/1990',
  'numero_celular': '(11) 91234-5678', // opcional
}, auth: false);

final usuario = body['data'];
```

---

### `POST /usuarios/login`

Autentica um hóspede e retorna tokens JWT. Público. **Rate-limited.**

**Body:**

| Campo | Tipo | Obrigatório |
|-------|------|:-----------:|
| `email` | string | ✅ |
| `senha` | string | ✅ |

**Resposta `200`:**
```json
{
  "data": { /* objeto usuario (sem senha) */ },
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

**Flutter:**
```dart
final body = await ApiClient.post('/usuarios/login', {
  'email': 'joao@email.com',
  'senha': 'Senha@123',
}, auth: false);

final tokens = body['tokens'] as Map<String, dynamic>;
ApiClient.setTokens(tokens['accessToken'], tokens['refreshToken']);
```

---

### `POST /usuarios/refresh`

Renova o `accessToken` usando o `refreshToken`. O token antigo é invalidado (rotação). Público.

**Body:**

| Campo | Tipo | Obrigatório |
|-------|------|:-----------:|
| `refreshToken` | string | ✅ |

**Resposta `200`:**
```json
{
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

**Flutter:**
```dart
// Chamar quando o accessToken expirar (401)
final body = await ApiClient.post('/usuarios/refresh', {
  'refreshToken': meuRefreshToken,
}, auth: false);

final tokens = body['tokens'] as Map<String, dynamic>;
ApiClient.setTokens(tokens['accessToken'], tokens['refreshToken']);
```

---

### `POST /usuarios/logout`

Revoga o `refreshToken` no servidor. **Requer `authGuard`.**

**Body:**

| Campo | Tipo | Obrigatório |
|-------|------|:-----------:|
| `refreshToken` | string | ✅ |

**Resposta `200`:**
```json
{ "message": "Logout realizado com sucesso" }
```

**Flutter:**
```dart
await ApiClient.post('/usuarios/logout', {
  'refreshToken': meuRefreshToken,
});
ApiClient.clearTokens();
```

---

## 4. Autenticação — Hotel

Os mesmos 4 endpoints de auth existem para o hotel, em `/hotel`:

### `POST /hotel/register` · `POST /hotel/login` · `POST /hotel/refresh` · `POST /hotel/logout`

O `/hotel/register` e `/hotel/login` são públicos; `/hotel/refresh` é público; `/hotel/logout` requer **`hotelGuard`**.

**Body do `/hotel/register`:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `nome_hotel` | string | ✅ | Máx 100 chars |
| `cnpj` | string | ✅ | 14 dígitos (com ou sem máscara) |
| `telefone` | string | ✅ | Qualquer formato |
| `email` | string | ✅ | Deve conter `@` e `.com` |
| `senha` | string | ✅ | Mínimo: 1 maiúscula, 1 minúscula, 1 número, 1 `@` |
| `cep` | string | ✅ | 8 dígitos |
| `uf` | string | ✅ | 2 letras (ex: `SP`) |
| `cidade` | string | ✅ | — |
| `bairro` | string | ✅ | — |
| `rua` | string | ✅ | — |
| `numero` | string | ✅ | — |
| `complemento` | string | ❌ | — |
| `descricao` | string | ❌ | Máx 1000 chars |

**Resposta `201` do register / `200` do login:**
```json
{
  "data": {
    "hotel_id": "uuid",
    "nome_hotel": "Hotel Exemplo",
    "cnpj": "12345678000199",
    "telefone": "(11) 3000-0000",
    "email": "contato@hotel.com",
    "cep": "01310100",
    "uf": "SP",
    "cidade": "São Paulo",
    "bairro": "Bela Vista",
    "rua": "Av. Paulista",
    "numero": "1000",
    "complemento": null,
    "saldo": "0.00",
    "descricao": null,
    "schema_name": "hotel_12345678000199",
    "criado_em": "2025-04-16T10:00:00Z",
    "ativo": true
  },
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

> O `/hotel/register` retorna só `{ "data": { ... } }` sem tokens. O `/hotel/login` retorna ambos.

**Flutter (login):**
```dart
final body = await ApiClient.post('/hotel/login', {
  'email': 'contato@hotel.com',
  'senha': 'Senha@123',
}, auth: false);

final tokens = body['tokens'] as Map<String, dynamic>;
ApiClient.setTokens(tokens['accessToken'], tokens['refreshToken']);
```

---

## 5. Perfil do Hóspede

### `GET /usuarios/me`

Retorna os dados do hóspede autenticado. **`authGuard`.**

**Resposta `200`:**
```json
{ "data": { /* objeto usuario */ } }
```

---

### `PATCH /usuarios/me`

Atualiza dados do hóspede. **`authGuard`.** Todos os campos são opcionais.

**Body (campos atualizáveis):**

| Campo | Tipo | Regras |
|-------|------|--------|
| `nome_completo` | string | — |
| `email` | string | Deve conter `@` e `.com` |
| `numero_celular` | string | Formato `(xx) xxxxx-xxxx` |
| `data_nascimento` | string | Formato `dd/mm/aaaa` |

**Resposta `200`:**
```json
{ "data": { /* objeto usuario atualizado */ } }
```

**Flutter:**
```dart
final body = await ApiClient.patch('/usuarios/me', {
  'nome_completo': 'João da Silva',
  'numero_celular': '(11) 91234-5678',
});
```

---

### `POST /usuarios/change-password`

Troca a senha do hóspede. Invalida todos os refresh tokens ativos. **`authGuard`.**

**Body:**

| Campo | Tipo | Obrigatório |
|-------|------|:-----------:|
| `senhaAtual` | string | ✅ |
| `novaSenha` | string | ✅ |

**Resposta `200`:**
```json
{ "message": "Senha alterada com sucesso. Faça login novamente." }
```

---

### `DELETE /usuarios/me`

Desativa a conta do hóspede (soft delete). **`authGuard`.**

**Resposta `200`:**
```json
{ "message": "Conta desativada com sucesso" }
```

---

## 6. Perfil do Hotel

Mesmos padrões do hóspede, em rotas `/hotel`:

### `GET /hotel/me` · **`hotelGuard`**

### `PATCH /hotel/me` · **`hotelGuard`**

**Campos atualizáveis:** `nome_hotel`, `telefone`, `email`, `descricao`, `cep`, `uf`, `cidade`, `bairro`, `rua`, `numero`, `complemento`.

> `cnpj` e `schema_name` são imutáveis após o cadastro.

### `POST /hotel/change-password` · **`hotelGuard`**

Body: `{ "senhaAtual": "...", "novaSenha": "..." }`

### `DELETE /hotel/me` · **`hotelGuard`**

Desativa o hotel (soft delete). Invalida todos os tokens ativos.

---

## 7. Favoritos

### `GET /usuarios/favoritos`

Lista todos os hotéis favoritados pelo hóspede. **`authGuard`.**

**Resposta `200`:**
```json
{
  "data": [
    {
      "id": "uuid-do-favorito",
      "hotel_id": "uuid",
      "nome_hotel": "Hotel Exemplo",
      "cidade": "São Paulo",
      "uf": "SP",
      "descricao": "...",
      "criado_em": "2025-04-16T10:00:00Z"
    }
  ]
}
```

**Flutter:**
```dart
final body = await ApiClient.get('/usuarios/favoritos');
final favoritos = body['data'] as List;
```

---

### `POST /usuarios/favoritos`

Adiciona um hotel aos favoritos. **`authGuard`.**

**Body:**

| Campo | Tipo | Obrigatório |
|-------|------|:-----------:|
| `hotel_id` | UUID | ✅ |

**Resposta `201`:**
```json
{
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "hotel_id": "uuid",
    "criado_em": "2025-04-16T10:00:00Z"
  }
}
```

---

### `DELETE /usuarios/favoritos/:hotel_id`

Remove um hotel dos favoritos. **`authGuard`.**

**Resposta `204`:** sem corpo.

**Flutter:**
```dart
await ApiClient.delete('/usuarios/favoritos/$hotelId');
```

---

## 8. Configuração do Hotel

### `GET /hotel/:hotel_id/configuracao`

Retorna as configurações operacionais do hotel. **Público.**

**Parâmetros de rota:**
- `:hotel_id` — UUID do hotel

**Resposta `200`:**
```json
{
  "data": {
    "hotel_id": "uuid",
    "horario_checkin": "14:00",
    "horario_checkout": "12:00",
    "max_dias_reserva": 30,
    "politica_cancelamento": "Cancelamento gratuito até 48h antes.",
    "aceita_animais": false,
    "idiomas_atendimento": "Português, Inglês"
  }
}
```

**Flutter:**
```dart
final body = await ApiClient.get(
  '/hotel/$hotelId/configuracao',
  auth: false,
);
final config = body['data'];
```

---

### `POST /hotel/configuracao`

Cria a configuração inicial do hotel. **`hotelGuard`.** Deve ser chamado logo após o primeiro login.

**Body:** todos os campos são opcionais (o banco aplica defaults).

| Campo | Tipo | Default | Regras |
|-------|------|---------|--------|
| `horario_checkin` | string | `"14:00"` | Formato `HH:MM` |
| `horario_checkout` | string | `"12:00"` | Formato `HH:MM` |
| `max_dias_reserva` | number | `30` | Inteiro > 0 |
| `politica_cancelamento` | string \| null | `null` | Texto livre |
| `aceita_animais` | boolean | `false` | `true` ou `false` |
| `idiomas_atendimento` | string | `"Português"` | Máx 200 chars |

**Resposta `201`:**
```json
{ "data": { /* ConfiguracaoHotelSafe */ } }
```

---

### `PATCH /hotel/configuracao`

Atualiza parcialmente a configuração. **`hotelGuard`.** Ao menos um campo obrigatório.

> Para remover a política de cancelamento: envie `"politica_cancelamento": null`.

**Resposta `200`:**
```json
{ "data": { /* ConfiguracaoHotelSafe atualizado */ } }
```

---

## 9. Catálogo do Hotel

O catálogo é a lista de itens (cômodos, comodidades, lazer) que o hotel oferece. Esses itens são depois vinculados a categorias de quarto e quartos individuais.

**Categorias válidas:** `"COMODO"` | `"COMODIDADE"` | `"LAZER"`

### `GET /hotel/:hotel_id/catalogo`

Lista todos os itens ativos do catálogo. **Público.**

**Query params opcionais:**
- `?categoria=COMODIDADE` — filtra por categoria

**Resposta `200`:**
```json
{
  "data": [
    { "id": 1, "nome": "Ar-condicionado", "categoria": "COMODIDADE" },
    { "id": 2, "nome": "Suíte Master",    "categoria": "COMODO" }
  ]
}
```

**Flutter:**
```dart
final body = await ApiClient.get(
  '/hotel/$hotelId/catalogo',
  auth: false,
);
final itens = body['data'] as List;
```

---

### `POST /hotel/catalogo`

Cria um novo item no catálogo. **`hotelGuard`.**

**Body:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `nome` | string | ✅ | Único por categoria |
| `categoria` | string | ✅ | `COMODO`, `COMODIDADE` ou `LAZER` |

**Resposta `201`:**
```json
{ "data": { "id": 3, "nome": "Piscina", "categoria": "LAZER" } }
```

---

### `PATCH /hotel/catalogo/:id`

Renomeia um item. **`hotelGuard`.** A categoria é **imutável** após a criação.

**Body:**

| Campo | Tipo | Obrigatório |
|-------|------|:-----------:|
| `nome` | string | ✅ |

**Resposta `200`:**
```json
{ "data": { "id": 3, "nome": "Piscina Adulto", "categoria": "LAZER" } }
```

---

### `DELETE /hotel/catalogo/:id`

Soft delete do item (oculto nas listagens, mas não apaga fisicamente para preservar referências). **`hotelGuard`.**

**Resposta `204`:** sem corpo.

---

## 10. Categorias de Quarto

Categorias são os "tipos" de quarto (ex: Standard, Luxo, Suíte). Cada categoria define preço base, capacidade e itens padrão.

### `GET /hotel/:hotel_id/categorias`

Lista todas as categorias ativas com seus itens. **Público.**

**Resposta `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "nome": "Standard",
      "preco_base": "199.90",
      "capacidade_pessoas": 2,
      "itens": [
        { "catalogo_id": 1, "nome": "Ar-condicionado", "categoria": "COMODIDADE", "quantidade": 1 },
        { "catalogo_id": 2, "nome": "Cama de Casal",   "categoria": "COMODO",     "quantidade": 1 }
      ]
    }
  ]
}
```

---

### `GET /hotel/:hotel_id/categorias/:id`

Retorna uma categoria específica com seus itens. **Público.**

**Resposta `200`:**
```json
{ "data": { /* CategoriaQuartoSafe */ } }
```

---

### `POST /hotel/categorias`

Cria uma nova categoria de quarto. **`hotelGuard`.**

**Body:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `nome` | string | ✅ | Máx 50 chars |
| `preco_base` | number | ✅ | Maior que 0 |
| `capacidade_pessoas` | number | ✅ | Inteiro > 0 |

**Resposta `201`:**
```json
{ "data": { "id": 1, "nome": "Standard", "preco_base": "199.90", "capacidade_pessoas": 2, "itens": [] } }
```

---

### `PATCH /hotel/categorias/:id`

Atualiza nome, preço ou capacidade. **`hotelGuard`.** Ao menos um campo.

**Body:** `nome?`, `preco_base?`, `capacidade_pessoas?`

**Resposta `200`:** objeto categoria atualizado.

---

### `DELETE /hotel/categorias/:id`

Soft delete da categoria. **`hotelGuard`.** Retorna `409` se existirem quartos ativos vinculados.

**Resposta `204`:** sem corpo.

---

### `POST /hotel/categorias/:id/itens`

Vincula um item do catálogo à categoria. **`hotelGuard`.**

**Body:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `catalogo_id` | number | ✅ | Inteiro > 0 |
| `quantidade` | number | ❌ | Default `1`, inteiro > 0 |

**Resposta `201`:**
```json
{ "data": { "catalogo_id": 1, "nome": "Ar-condicionado", "categoria": "COMODIDADE", "quantidade": 1 } }
```

---

### `DELETE /hotel/categorias/:id/itens/:catalogo_id`

Remove o vínculo de um item à categoria. **`hotelGuard`.**

**Resposta `204`:** sem corpo.

---

## 11. Quartos

Quartos são as unidades físicas do hotel. Cada quarto pertence a uma categoria.

### `GET /hotel/quartos`

Lista todos os quartos ativos do hotel. **`hotelGuard`.**

**Resposta `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "numero": "101",
      "categoria_quarto_id": 1,
      "disponivel": true,
      "descricao": "Vista para o mar",
      "valor_override": null,
      "itens": [
        { "catalogo_id": 1, "nome": "Ar-condicionado", "categoria": "COMODIDADE", "quantidade": 1 }
      ]
    }
  ]
}
```

---

### `GET /hotel/quartos/:id`

Retorna um quarto específico. **`hotelGuard`.**

**Resposta `200`:**
```json
{ "data": { /* QuartoSafe */ } }
```

---

### `POST /hotel/quartos`

Cria um novo quarto. **`hotelGuard`.**

**Body:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `numero` | string | ✅ | Único no hotel, máx 10 chars |
| `categoria_quarto_id` | number | ✅ | ID de categoria existente |
| `descricao` | string \| null | ❌ | Máx 500 chars |
| `valor_override` | number \| null | ❌ | Substitui o `preco_base` da categoria; > 0 |
| `disponivel` | boolean | ❌ | Default `true` |
| `itens` | array | ❌ | Lista de `{ catalogo_id, quantidade }` |

**Resposta `201`:**
```json
{ "data": { /* QuartoSafe */ } }
```

**Flutter:**
```dart
final body = await ApiClient.post('/hotel/quartos', {
  'numero': '101',
  'categoria_quarto_id': 1,
  'descricao': 'Vista para o jardim',
  'itens': [
    { 'catalogo_id': 1, 'quantidade': 1 },
    { 'catalogo_id': 3, 'quantidade': 2 },
  ],
});
```

---

### `PATCH /hotel/quartos/:id`

Atualiza dados do quarto. **`hotelGuard`.** Ao menos um campo.

> `itens` no PATCH **substitui todos** os itens existentes do quarto. Para remover todos os itens, envie `"itens": []`.
>
> `valor_override: null` remove o preço customizado e volta a usar `preco_base` da categoria.

**Body:** mesmos campos do POST, todos opcionais.

**Resposta `200`:**
```json
{ "data": { /* QuartoSafe atualizado */ } }
```

---

### `DELETE /hotel/quartos/:id`

Soft delete do quarto. **`hotelGuard`.**

**Resposta `204`:** sem corpo.

---

## 12. Reservas — Hotel

Prefixo: `/hotel/reservas`

### `GET /hotel/reservas`

Lista reservas do hotel com filtros opcionais. **`hotelGuard`.**

**Query params (todos opcionais):**

| Param | Tipo | Descrição |
|-------|------|-----------|
| `status` | string | `SOLICITADA` \| `AGUARDANDO_PAGAMENTO` \| `APROVADA` \| `CANCELADA` \| `CONCLUIDA` |
| `data_checkin_from` | string | Data mínima de checkin (`YYYY-MM-DD`) |
| `data_checkin_to` | string | Data máxima de checkin |
| `data_checkout_from` | string | Data mínima de checkout |
| `data_checkout_to` | string | Data máxima de checkout |
| `nome_hospede` | string | Busca parcial por nome (walk-ins) |
| `cpf_hospede` | string | Busca exata por CPF (walk-ins) |

**Resposta `200`:**
```json
{ "data": [ /* array de ReservaSafe */ ] }
```

**Flutter:**
```dart
final body = await ApiClient.get(
  '/hotel/reservas?status=SOLICITADA&data_checkin_from=2025-06-01',
);
final reservas = body['data'] as List;
```

---

### `GET /hotel/reservas/:id`

Retorna uma reserva específica pelo ID interno. **`hotelGuard`.**

**Resposta `200`:**
```json
{
  "data": {
    "id": 1,
    "codigo_publico": "uuid",
    "user_id": "uuid-ou-null",
    "nome_hospede": null,
    "cpf_hospede": null,
    "telefone_contato": null,
    "canal_origem": "APP",
    "sessao_chat_id": null,
    "quarto_id": 1,
    "tipo_quarto": null,
    "num_hospedes": 2,
    "data_checkin": "2025-06-10",
    "data_checkout": "2025-06-12",
    "hora_checkin_real": null,
    "hora_checkout_real": null,
    "valor_total": "399.80",
    "observacoes": null,
    "p_turisticos": null,
    "status": "SOLICITADA",
    "criado_em": "2025-04-16T10:00:00Z"
  }
}
```

---

### `POST /hotel/reservas`

Cria uma reserva **walk-in** (balcão, WhatsApp). Status inicial: `APROVADA`. **`hotelGuard`.**

**Body:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `num_hospedes` | number | ✅ | Inteiro > 0 |
| `data_checkin` | string | ✅ | `YYYY-MM-DD` |
| `data_checkout` | string | ✅ | `YYYY-MM-DD`, após checkin |
| `valor_total` | number | ✅ | > 0 |
| `user_id` | UUID | ❌ | Hóspede registrado (se disponível) |
| `nome_hospede` | string | ❌* | Nome do walk-in |
| `cpf_hospede` | string | ❌* | CPF do walk-in |
| `telefone_contato` | string | ❌* | Telefone do walk-in |
| `quarto_id` | number | ❌** | ID físico do quarto |
| `tipo_quarto` | string | ❌** | Nome textual do tipo |
| `observacoes` | string \| null | ❌ | Observações |
| `sessao_chat_id` | UUID \| null | ❌ | ID da sessão WhatsApp de origem |

> \* Para walk-in sem `user_id`: obrigatório `nome_hospede` + (`cpf_hospede` OU `telefone_contato`).
> \*\* Obrigatório informar `quarto_id` OU `tipo_quarto`.

**Resposta `201`:**
```json
{ "data": { /* ReservaSafe */ } }
```

---

### `PATCH /hotel/reservas/:id/status`

Atualiza o status de uma reserva. **`hotelGuard`.**

**Body:**

| Campo | Tipo | Valores válidos |
|-------|------|----------------|
| `status` | string | `SOLICITADA` \| `AGUARDANDO_PAGAMENTO` \| `APROVADA` \| `CANCELADA` \| `CONCLUIDA` |

> Transições que alteram disponibilidade do quarto: `APROVADA` (bloqueia), `CANCELADA` e `CONCLUIDA` (libera).

**Resposta `200`:**
```json
{ "data": { /* ReservaSafe atualizado */ } }
```

---

### `PATCH /hotel/reservas/:id/quarto`

Atribui um quarto físico a uma reserva. **`hotelGuard`.**

**Body:**

| Campo | Tipo | Obrigatório |
|-------|------|:-----------:|
| `quarto_id` | number | ✅ |

**Resposta `200`:**
```json
{ "data": { /* ReservaSafe com quarto_id atualizado */ } }
```

---

### `PATCH /hotel/reservas/:id/checkin`

Registra o check-in físico (preenche `hora_checkin_real`). **`hotelGuard`.** Sem body.

**Resposta `200`:**
```json
{ "data": { /* ReservaSafe com hora_checkin_real preenchido */ } }
```

---

### `PATCH /hotel/reservas/:id/checkout`

Registra o check-out físico. Muda status para `CONCLUIDA` e libera o quarto. **`hotelGuard`.** Sem body.

**Resposta `200`:**
```json
{ "data": { /* ReservaSafe com hora_checkout_real preenchido e status CONCLUIDA */ } }
```

---

## 13. Reservas — Hóspede

Prefixo: `/usuarios/reservas`

### `GET /usuarios/reservas`

Lista o histórico de reservas do hóspede (lido do `historico_reserva_global` — não itera pelos tenants). **`authGuard`.**

**Resposta `200`:**
```json
{
  "data": [
    {
      "id": "uuid",
      "hotel_id": "uuid",
      "nome_hotel": "Hotel Exemplo",
      "tipo_quarto": "Standard",
      "data_checkin": "2025-06-10",
      "data_checkout": "2025-06-12",
      "valor_total": "399.80",
      "status": "APROVADA",
      "criado_em": "2025-04-16T10:00:00Z",
      "atualizado_em": "2025-04-16T12:00:00Z"
    }
  ]
}
```

---

### `POST /usuarios/reservas`

Cria uma reserva via app. Status inicial: `SOLICITADA`. **`authGuard`.**

**Body:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `hotel_id` | UUID | ✅ | Hotel de destino |
| `num_hospedes` | number | ✅ | Inteiro > 0 |
| `data_checkin` | string | ✅ | `YYYY-MM-DD` |
| `data_checkout` | string | ✅ | `YYYY-MM-DD`, após checkin |
| `valor_total` | number | ✅ | > 0 |
| `quarto_id` | number | ❌* | ID do quarto desejado |
| `tipo_quarto` | string | ❌* | Nome do tipo desejado |
| `observacoes` | string \| null | ❌ | — |
| `p_turisticos` | any | ❌ | Dados de pontos turísticos (JSONB) |

> \* Obrigatório informar `quarto_id` OU `tipo_quarto`.

**Resposta `201`:**
```json
{ "data": { /* ReservaSafe */ } }
```

**Flutter:**
```dart
final body = await ApiClient.post('/usuarios/reservas', {
  'hotel_id': 'uuid-do-hotel',
  'num_hospedes': 2,
  'data_checkin': '2025-06-10',
  'data_checkout': '2025-06-12',
  'valor_total': 399.80,
  'tipo_quarto': 'Standard',
});
final reserva = body['data'];
final codigoPublico = reserva['codigo_publico'];
```

---

### `PATCH /usuarios/reservas/:codigo_publico/cancelar`

Cancela uma reserva do hóspede pelo `codigo_publico`. **`authGuard`.** Walk-ins não podem usar este endpoint.

**Resposta `204`:** sem corpo.

**Flutter:**
```dart
await ApiClient.patch(
  '/usuarios/reservas/$codigoPublico/cancelar',
  {},
);
```

---

## 14. Reservas — Público

### `GET /reservas/:codigo_publico`

Retorna os dados de uma reserva pelo código público (link de ticket). **Público** — sem autenticação.

> Usado para hóspedes walk-in consultarem sua reserva via link gerado no balcão ou WhatsApp.

**Resposta `200`:**
```json
{ "data": { /* ReservaSafe */ } }
```

**Flutter:**
```dart
final body = await ApiClient.get(
  '/reservas/$codigoPublico',
  auth: false,
);
```

---

## 15. Avaliações

Avaliações só podem ser criadas após uma reserva com status `CONCLUIDA`.

### `POST /usuarios/avaliacoes`

Cria uma avaliação. **`authGuard`.** A `nota_total` é calculada automaticamente (média das 5 notas arredondada).

**Body:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `codigo_publico` | UUID | ✅ | Código da reserva concluída |
| `nota_limpeza` | number | ✅ | Inteiro de 1 a 5 |
| `nota_atendimento` | number | ✅ | Inteiro de 1 a 5 |
| `nota_conforto` | number | ✅ | Inteiro de 1 a 5 |
| `nota_organizacao` | number | ✅ | Inteiro de 1 a 5 |
| `nota_localizacao` | number | ✅ | Inteiro de 1 a 5 |
| `comentario` | string \| null | ❌ | Texto livre |

**Resposta `201`:**
```json
{
  "data": {
    "id": 1,
    "user_id": "uuid",
    "reserva_id": 1,
    "nota_limpeza": 5,
    "nota_atendimento": 4,
    "nota_conforto": 5,
    "nota_organizacao": 4,
    "nota_localizacao": 5,
    "nota_total": 5,
    "comentario": "Excelente estadia!",
    "criado_em": "2025-04-16T10:00:00Z"
  }
}
```

**Flutter:**
```dart
final body = await ApiClient.post('/usuarios/avaliacoes', {
  'codigo_publico': codigoPublico,
  'nota_limpeza': 5,
  'nota_atendimento': 4,
  'nota_conforto': 5,
  'nota_organizacao': 4,
  'nota_localizacao': 5,
  'comentario': 'Ótimo hotel!',
});
```

---

### `PATCH /usuarios/avaliacoes/:codigo_publico`

Edita uma avaliação existente. **`authGuard`.** Ao menos um campo obrigatório. A `nota_total` é recalculada automaticamente.

**Body:** mesmos campos do POST, todos opcionais (exceto `codigo_publico` que está na rota).

**Resposta `200`:**
```json
{ "data": { /* AvaliacaoSafe atualizado */ } }
```

---

### `GET /hotel/:hotel_id/avaliacoes`

Lista todas as avaliações do hotel. **Público.**

**Resposta `200`:**
```json
{ "data": [ /* array de AvaliacaoSafe */ ] }
```

**Flutter:**
```dart
final body = await ApiClient.get(
  '/hotel/$hotelId/avaliacoes',
  auth: false,
);
```

---

## 16. Pagamentos

Prefixo: `/hotel/reservas/:reserva_id/pagamentos`

### `POST /hotel/reservas/:reserva_id/pagamentos`

Gera um link de pagamento InfinitePay para a reserva. **`hotelGuard`.**

> Muda o status da reserva para `AGUARDANDO_PAGAMENTO` e registra o `checkout_url`.

**Body:** sem campos obrigatórios (os dados são lidos da reserva).

**Resposta `201`:**
```json
{
  "data": {
    "id": 1,
    "reserva_id": 1,
    "valor_pago": "399.80",
    "forma_pagamento": "PIX",
    "status": "PENDENTE",
    "checkout_url": "https://infinitepay.io/pay/abc123",
    "infinite_invoice_slug": "abc123",
    "transaction_nsu": null,
    "metodo_captura": null,
    "recibo_url": null,
    "data_pagamento": "2025-04-16T10:00:00Z"
  }
}
```

**Flutter:**
```dart
final body = await ApiClient.post(
  '/hotel/reservas/$reservaId/pagamentos',
  {},
);
final checkoutUrl = body['data']['checkout_url'];
// Abrir checkoutUrl no navegador/WebView para o hóspede pagar
```

---

### `GET /hotel/reservas/:reserva_id/pagamentos`

Lista todos os pagamentos de uma reserva. **`hotelGuard`.**

**Resposta `200`:**
```json
{ "data": [ /* array de PagamentoReservaSafe */ ] }
```

---

### `POST /pagamentos/webhook/infinitepay`

Recebe confirmação de pagamento da InfinitePay. **Público** (sem auth — a InfinitePay não envia token).

> Idempotente via `invoice_slug`. Ao confirmar, muda o status da reserva para `APROVADA`.

**Body (enviado pela InfinitePay):**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `invoice_slug` | string | Código único da fatura |
| `amount` | number | Valor em centavos |
| `paid_amount` | number | Valor pago (pode incluir juros) |
| `installments` | number | Número de parcelas |
| `capture_method` | string | `"credit_card"` ou `"pix"` |
| `transaction_nsu` | string | NSU da transação |
| `order_nsu` | string | `codigo_publico` da reserva |
| `receipt_url` | string | URL do recibo |

> Este endpoint **não deve ser chamado pelo Flutter** — é acionado automaticamente pela InfinitePay.

---

## 17. Notificações do Hotel

Prefixo: `/hotel/notificacoes`

### `GET /hotel/notificacoes`

Lista notificações do hotel. **`hotelGuard`.**

**Query params opcionais:**
- `?nao_lidas=true` — retorna apenas notificações não lidas

**Resposta `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "titulo": "Nova reserva recebida",
      "mensagem": "João Silva solicitou reserva para 10/06.",
      "tipo": "NOVA_RESERVA",
      "lida_em": null,
      "acao_requerida": "GERAR_PAGAMENTO_INFINITEPAY",
      "acao_concluida": false,
      "payload": { "reserva_id": 42 },
      "criado_em": "2025-04-16T10:00:00Z"
    }
  ]
}
```

**Flutter:**
```dart
// Somente não lidas
final body = await ApiClient.get('/hotel/notificacoes?nao_lidas=true');
final notificacoes = body['data'] as List;
```

---

### `PATCH /hotel/notificacoes/:id/lida`

Marca uma notificação específica como lida. **`hotelGuard`.** Sem body.

**Resposta `200`:**
```json
{ "data": { /* notificação com lida_em preenchido */ } }
```

---

### `PATCH /hotel/notificacoes/lida-todas`

Marca **todas** as notificações não lidas como lidas. **`hotelGuard`.** Sem body.

**Resposta `200`:**
```json
{ "message": "Todas as notificações marcadas como lidas" }
```

---

## 18. Dispositivos FCM (Push Notifications)

Prefixo: `/dispositivos-fcm`

### `POST /dispositivos-fcm/usuario`

Registra o token FCM do dispositivo do hóspede. **`authGuard`.** Chamar após o login.

**Body:**

| Campo | Tipo | Obrigatório | Valores |
|-------|------|:-----------:|---------|
| `fcm_token` | string | ✅ | Token gerado pelo Firebase |
| `origem` | string | ❌ | `APP_IOS` \| `APP_ANDROID` \| `DASHBOARD_WEB` |

**Resposta `201`:**
```json
{ "data": { "id": "uuid", "fcm_token": "...", "origem": "APP_ANDROID", "criado_em": "..." } }
```

**Flutter:**
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

final fcmToken = await FirebaseMessaging.instance.getToken();

await ApiClient.post('/dispositivos-fcm/usuario', {
  'fcm_token': fcmToken,
  'origem': 'APP_ANDROID', // ou APP_IOS
});
```

---

### `POST /dispositivos-fcm/hotel`

Registra o token FCM do dispositivo do hotel (dashboard). **`hotelGuard`.**

**Body:** mesmo formato do endpoint de usuário.

**Resposta `201`:** mesmo formato.

---

### `DELETE /dispositivos-fcm/usuario`

Remove o token FCM do hóspede (chamar no logout). **`authGuard`.**

**Body:**

| Campo | Tipo | Obrigatório |
|-------|------|:-----------:|
| `fcm_token` | string | ✅ |

**Resposta `204`:** sem corpo.

**Flutter:**
```dart
await ApiClient.delete('/dispositivos-fcm/usuario');
// Nota: enviar o body no DELETE requer customização:
await http.delete(
  Uri.parse('${ApiClient.baseUrl}/dispositivos-fcm/usuario'),
  headers: { 'Authorization': 'Bearer $token', 'Content-Type': 'application/json' },
  body: jsonEncode({ 'fcm_token': fcmToken }),
);
```

---

### `DELETE /dispositivos-fcm/hotel`

Remove o token FCM do hotel (chamar no logout). **`hotelGuard`.**

**Body:** `{ "fcm_token": "..." }`

**Resposta `204`:** sem corpo.

---

## 19. Fotos do Hotel (Capa)

Prefixo: `/uploads`

Fotos de capa são categorizadas por orientação (`portrait` / `landscape`). O Flutter seleciona a orientação correta para cada tela.

**Limite por orientação:** controlado por `UPLOAD_MAX_HOTEL_COVER` no `.env` (default: `5`). Ou seja, 5 portrait + 5 landscape = 10 fotos no total.

### `GET /uploads/hotels/:hotel_id/cover`

Lista metadados das fotos de capa. **Público.**

**Query params opcionais:**
- `?orientacao=portrait` ou `?orientacao=landscape`

**Resposta `200`:**
```json
{
  "fotos": [
    {
      "id": "uuid",
      "orientacao": "portrait",
      "criado_em": "2025-04-16T10:00:00Z",
      "url": "/api/v1/uploads/hotels/uuid/cover/uuid-foto"
    }
  ]
}
```

**Flutter:**
```dart
final body = await ApiClient.get(
  '/uploads/hotels/$hotelId/cover?orientacao=portrait',
  auth: false,
);
final fotos = body['fotos'] as List;

// Para exibir a imagem:
Image.network('${ApiClient.baseUrl}${foto['url']}')
```

---

### `GET /uploads/hotels/:hotel_id/cover/:foto_id`

Serve o arquivo de imagem diretamente. **Público.**

> Use esta URL direto em `Image.network()` no Flutter — não é um JSON, é a imagem em si.

**Flutter:**
```dart
Image.network(
  '${ApiClient.baseUrl}/uploads/hotels/$hotelId/cover/$fotoId',
)
```

---

### `POST /uploads/hotels/:hotel_id/cover`

Faz upload de uma foto de capa. **`hotelGuard`.** Multipart form-data.

**Form fields:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `foto` | arquivo | ✅ | JPEG, PNG ou WebP — máx `UPLOAD_MAX_SIZE_MB` MB |
| `orientacao` | string | ✅ | `portrait` ou `landscape` |

**Resposta `201`:**
```json
{
  "message": "Foto de capa enviada com sucesso",
  "foto": {
    "id": "uuid",
    "storage_path": "hotels/uuid/cover/uuid.jpg",
    "orientacao": "portrait",
    "criado_em": "2025-04-16T10:00:00Z"
  }
}
```

**Flutter (com `http` multipart):**
```dart
import 'package:http/http.dart' as http;

final request = http.MultipartRequest(
  'POST',
  Uri.parse('${ApiClient.baseUrl}/uploads/hotels/$hotelId/cover'),
);
request.headers['Authorization'] = 'Bearer $hotelAccessToken';
request.fields['orientacao'] = 'portrait';
request.files.add(await http.MultipartFile.fromPath('foto', imagePath));

final response = await request.send();
```

---

### `DELETE /uploads/hotels/:hotel_id/cover/:foto_id`

Remove uma foto de capa. **`hotelGuard`.**

**Resposta `200`:**
```json
{ "message": "Foto removida com sucesso" }
```

---

## 20. Fotos do Quarto

**Limite total por quarto:** controlado por `UPLOAD_MAX_ROOM_PHOTOS` no `.env` (default: `10`). Sem distinção de orientação.

### `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`

Lista metadados das fotos do quarto. **Público.**

**Resposta `200`:**
```json
{
  "fotos": [
    {
      "id": "uuid",
      "ordem": 0,
      "criado_em": "2025-04-16T10:00:00Z",
      "url": "/api/v1/uploads/hotels/uuid/rooms/1/uuid-foto"
    }
  ]
}
```

---

### `GET /uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id`

Serve o arquivo de imagem do quarto diretamente. **Público.**

**Flutter:**
```dart
Image.network(
  '${ApiClient.baseUrl}/uploads/hotels/$hotelId/rooms/$quartoId/$fotoId',
)
```

---

### `POST /uploads/hotels/:hotel_id/rooms/:quarto_id`

Faz upload de uma foto do quarto. **`hotelGuard`.** Multipart form-data.

**Form fields:**

| Campo | Tipo | Obrigatório | Regras |
|-------|------|:-----------:|--------|
| `foto` | arquivo | ✅ | JPEG, PNG ou WebP — máx `UPLOAD_MAX_SIZE_MB` MB |

**Resposta `201`:**
```json
{
  "message": "Foto do quarto enviada com sucesso",
  "foto": {
    "id": "uuid",
    "storage_path": "hotels/uuid/rooms/1/uuid.jpg",
    "ordem": 0,
    "criado_em": "2025-04-16T10:00:00Z"
  }
}
```

**Flutter:**
```dart
final request = http.MultipartRequest(
  'POST',
  Uri.parse('${ApiClient.baseUrl}/uploads/hotels/$hotelId/rooms/$quartoId'),
);
request.headers['Authorization'] = 'Bearer $hotelAccessToken';
request.files.add(await http.MultipartFile.fromPath('foto', imagePath));

final response = await request.send();
```

---

### `DELETE /uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id`

Remove uma foto do quarto. **`hotelGuard`.**

**Resposta `200`:**
```json
{ "message": "Foto removida com sucesso" }
```

---

## Referência Rápida

### Todos os Endpoints

| Método | Caminho | Auth | Descrição |
|--------|---------|------|-----------|
| `POST` | `/usuarios/register` | Público | Cadastrar hóspede |
| `POST` | `/usuarios/login` | Público | Login hóspede |
| `POST` | `/usuarios/refresh` | Público | Renovar token hóspede |
| `POST` | `/usuarios/logout` | authGuard | Logout hóspede |
| `GET` | `/usuarios/me` | authGuard | Perfil do hóspede |
| `PATCH` | `/usuarios/me` | authGuard | Atualizar perfil |
| `POST` | `/usuarios/change-password` | authGuard | Trocar senha |
| `DELETE` | `/usuarios/me` | authGuard | Desativar conta |
| `GET` | `/usuarios/favoritos` | authGuard | Listar favoritos |
| `POST` | `/usuarios/favoritos` | authGuard | Favoritar hotel |
| `DELETE` | `/usuarios/favoritos/:hotel_id` | authGuard | Desfavoritar hotel |
| `GET` | `/usuarios/reservas` | authGuard | Histórico de reservas |
| `POST` | `/usuarios/reservas` | authGuard | Criar reserva (app) |
| `PATCH` | `/usuarios/reservas/:codigo_publico/cancelar` | authGuard | Cancelar reserva |
| `POST` | `/usuarios/avaliacoes` | authGuard | Criar avaliação |
| `PATCH` | `/usuarios/avaliacoes/:codigo_publico` | authGuard | Editar avaliação |
| `POST` | `/dispositivos-fcm/usuario` | authGuard | Registrar token FCM |
| `DELETE` | `/dispositivos-fcm/usuario` | authGuard | Remover token FCM |
| `POST` | `/hotel/register` | Público | Cadastrar hotel |
| `POST` | `/hotel/login` | Público | Login hotel |
| `POST` | `/hotel/refresh` | Público | Renovar token hotel |
| `POST` | `/hotel/logout` | hotelGuard | Logout hotel |
| `GET` | `/hotel/me` | hotelGuard | Perfil do hotel |
| `PATCH` | `/hotel/me` | hotelGuard | Atualizar perfil |
| `POST` | `/hotel/change-password` | hotelGuard | Trocar senha |
| `DELETE` | `/hotel/me` | hotelGuard | Desativar hotel |
| `POST` | `/hotel/configuracao` | hotelGuard | Criar configuração |
| `PATCH` | `/hotel/configuracao` | hotelGuard | Atualizar configuração |
| `GET` | `/hotel/:hotel_id/configuracao` | Público | Ver configuração |
| `GET` | `/hotel/quartos` | hotelGuard | Listar quartos |
| `GET` | `/hotel/quartos/:id` | hotelGuard | Ver quarto |
| `POST` | `/hotel/quartos` | hotelGuard | Criar quarto |
| `PATCH` | `/hotel/quartos/:id` | hotelGuard | Atualizar quarto |
| `DELETE` | `/hotel/quartos/:id` | hotelGuard | Remover quarto |
| `GET` | `/hotel/:hotel_id/categorias` | Público | Listar categorias |
| `GET` | `/hotel/:hotel_id/categorias/:id` | Público | Ver categoria |
| `POST` | `/hotel/categorias` | hotelGuard | Criar categoria |
| `PATCH` | `/hotel/categorias/:id` | hotelGuard | Atualizar categoria |
| `DELETE` | `/hotel/categorias/:id` | hotelGuard | Remover categoria |
| `POST` | `/hotel/categorias/:id/itens` | hotelGuard | Adicionar item à categoria |
| `DELETE` | `/hotel/categorias/:id/itens/:catalogo_id` | hotelGuard | Remover item da categoria |
| `GET` | `/hotel/:hotel_id/catalogo` | Público | Listar catálogo |
| `POST` | `/hotel/catalogo` | hotelGuard | Criar item no catálogo |
| `PATCH` | `/hotel/catalogo/:id` | hotelGuard | Renomear item |
| `DELETE` | `/hotel/catalogo/:id` | hotelGuard | Remover item |
| `GET` | `/hotel/reservas` | hotelGuard | Listar reservas |
| `GET` | `/hotel/reservas/:id` | hotelGuard | Ver reserva |
| `POST` | `/hotel/reservas` | hotelGuard | Criar reserva walk-in |
| `PATCH` | `/hotel/reservas/:id/status` | hotelGuard | Atualizar status |
| `PATCH` | `/hotel/reservas/:id/quarto` | hotelGuard | Atribuir quarto |
| `PATCH` | `/hotel/reservas/:id/checkin` | hotelGuard | Registrar check-in |
| `PATCH` | `/hotel/reservas/:id/checkout` | hotelGuard | Registrar check-out |
| `POST` | `/hotel/reservas/:id/pagamentos` | hotelGuard | Gerar link de pagamento |
| `GET` | `/hotel/reservas/:id/pagamentos` | hotelGuard | Listar pagamentos |
| `GET` | `/hotel/notificacoes` | hotelGuard | Listar notificações |
| `PATCH` | `/hotel/notificacoes/:id/lida` | hotelGuard | Marcar notificação como lida |
| `PATCH` | `/hotel/notificacoes/lida-todas` | hotelGuard | Marcar todas como lidas |
| `POST` | `/dispositivos-fcm/hotel` | hotelGuard | Registrar token FCM |
| `DELETE` | `/dispositivos-fcm/hotel` | hotelGuard | Remover token FCM |
| `GET` | `/hotel/:hotel_id/avaliacoes` | Público | Listar avaliações |
| `GET` | `/reservas/:codigo_publico` | Público | Ver reserva (link público) |
| `POST` | `/pagamentos/webhook/infinitepay` | Público | Webhook InfinitePay |
| `GET` | `/uploads/hotels/:hotel_id/cover` | Público | Listar fotos de capa |
| `GET` | `/uploads/hotels/:hotel_id/cover/:foto_id` | Público | Servir foto de capa |
| `POST` | `/uploads/hotels/:hotel_id/cover` | hotelGuard | Upload foto de capa |
| `DELETE` | `/uploads/hotels/:hotel_id/cover/:foto_id` | hotelGuard | Remover foto de capa |
| `GET` | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | Público | Listar fotos do quarto |
| `GET` | `/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id` | Público | Servir foto do quarto |
| `POST` | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | hotelGuard | Upload foto do quarto |
| `DELETE` | `/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id` | hotelGuard | Remover foto do quarto |
