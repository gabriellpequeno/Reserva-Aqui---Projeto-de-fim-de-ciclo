# Spec — CEP Autofill

## Referência
- **PRD:** `conductor/features/cep-autofill.prd.md`
- **Arquivo principal:** `Frontend/lib/features/auth/presentation/pages/host_signup_page.dart`
- **Branch:** `feat/cep-autofill` (ou branch de trabalho ativa)

---

## Abordagem Técnica

Criar um `CepService` (Provider Riverpod) com uma instância de `Dio` dedicada e sem interceptor de autenticação, que consulta `https://viacep.com.br/ws/{cep}/json/` quando o campo CEP atinge exatamente 8 dígitos.

A lógica de disparo fica no `_HostSignUpPageState` via `onChanged` no `TextFormField` do CEP. Ao receber a resposta com sucesso, o estado local é atualizado via `setState` populando os 4 controllers/dropdown. O loading local `_isCepLoading` controla um `suffixIcon` de loading no campo CEP.

Nenhum `StateNotifier` dedicado é criado — o estado é efêmero e local à página, seguindo o padrão já estabelecido em `HostSignUpPage`.

---

## Componentes Afetados

### Backend
- Nenhum. A feature consome apenas a API pública ViaCEP — nenhum endpoint interno é criado ou modificado.

### Frontend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Novo** | `lib/features/auth/data/models/cep_response.dart` | DTO da resposta ViaCEP com `fromJson()` e campo `erro` |
| **Novo** | `lib/features/auth/data/services/cep_service.dart` | `CepService.lookup(cep)` + `cepServiceProvider` |
| **Modificado** | `lib/features/auth/presentation/pages/host_signup_page.dart` | Adicionar `_isCepLoading`, `onChanged` no CEP, método `_onCepChanged`, popular controllers no sucesso |
| **Modificado** | `lib/features/auth/presentation/widgets/auth_text_field.dart` | Adicionar parâmetros `suffixIcon` e `onChanged` ao widget |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Dio separado no `CepService` (sem interceptor de auth) | O interceptor do app injeta `Authorization: Bearer <token>` em todas as requests — a ViaCEP é pública e rejeitaria o header extra; usar instância isolada evita vazamento de token |
| Trigger por `onChanged` (8 dígitos) em vez de `onEditingComplete` | O PRD especifica disparo sem precisar sair do campo; `onChanged` detecta os 8 dígitos durante a digitação, sem exigir ação adicional do usuário |
| Debounce não implementado | Com exatamente 8 dígitos como condição, a consulta só dispara uma vez por sequência de digitação normal — debounce seria prematuro |
| `_isCepLoading` como booleano local em vez de `StateProvider` | Estado efêmero, restrito a este único campo; sem necessidade de compartilhamento entre widgets |
| Adicionar `suffixIcon` e `onChanged` ao `AuthTextField` | O widget não expõe esses parâmetros; a modificação é mínima, backward-compatible (ambos opcionais com default `null`) e evita duplicar o estilo do campo |
| Campos auto-preenchidos permanecem editáveis | `TextEditingController.text = valor` popula mas não bloqueia o campo — nenhuma mudança de `readOnly` necessária |
| Falha de rede silenciosa (sem erro fatal) | Conforme RNF do PRD: campos ficam em branco, usuário preenche manualmente — não interrompe o fluxo de cadastro |

---

## Contratos de API

| Método | Rota | Auth | Response (CEP válido) | Response (CEP inválido) |
|--------|------|------|----------------------|------------------------|
| GET | `https://viacep.com.br/ws/{cep}/json/` | ❌ | `{ cep, logradouro, complemento, bairro, localidade, uf, ibge, gia, ddd, siafi }` | `{ "erro": "true" }` |

> `{cep}` deve conter apenas os 8 dígitos numéricos (sem hífen).

---

## Modelos de Dados

```dart
// lib/features/auth/data/models/cep_response.dart
class CepResponse {
  final String? logradouro;   // → _ruaController
  final String? bairro;        // → _bairroController
  final String? localidade;    // → _cidadeController
  final String? uf;            // → _selectedUf
  final bool erro;             // true quando CEP não encontrado

  const CepResponse({
    this.logradouro,
    this.bairro,
    this.localidade,
    this.uf,
    this.erro = false,
  });

  factory CepResponse.fromJson(Map<String, dynamic> json) => CepResponse(
    logradouro: json['logradouro'] as String?,
    bairro:     json['bairro']     as String?,
    localidade: json['localidade'] as String?,
    uf:         json['uf']         as String?,
    erro:       json['erro'] == true || json['erro'] == 'true',
  );
}
```

---

## Novo arquivo: `cep_service.dart`

```dart
// lib/features/auth/data/services/cep_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cep_response.dart';

class CepService {
  final Dio _dio;

  CepService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://viacep.com.br/ws/',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));

  /// Retorna [CepResponse] para o CEP informado (somente dígitos, 8 chars).
  /// Retorna [CepResponse(erro: true)] se o CEP não for encontrado.
  /// Lança [DioException] em caso de falha de rede.
  Future<CepResponse> lookup(String cep) async {
    final response = await _dio.get<Map<String, dynamic>>('$cep/json/');
    return CepResponse.fromJson(response.data!);
  }
}

final cepServiceProvider = Provider<CepService>((ref) => CepService());
```

---

## Modificações em `auth_text_field.dart`

Adicionar dois parâmetros opcionais para uso pelo campo CEP (e potencialmente outros campos no futuro):

```dart
// Parâmetros novos (ambos opcionais, null por default):
final Widget? suffixIcon;
final void Function(String)? onChanged;
```

O `suffixIcon` é passado para o `InputDecoration` e `onChanged` para o `TextFormField`.

---

## Modificações em `host_signup_page.dart`

### Estado novo
```dart
bool _isCepLoading = false;
```

### Método `_onCepChanged`
```dart
void _onCepChanged(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 8) return;

  setState(() => _isCepLoading = true);

  ref.read(cepServiceProvider).lookup(digits).then((result) {
    if (!mounted) return;
    if (result.erro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CEP não encontrado. Verifique e preencha manualmente.'),
        ),
      );
      return;
    }
    setState(() {
      _ruaController.text    = result.logradouro ?? '';
      _bairroController.text = result.bairro     ?? '';
      _cidadeController.text = result.localidade ?? '';
      if (result.uf != null && _estados.contains(result.uf)) {
        _selectedUf = result.uf;
      }
    });
  }).catchError((_) {
    // Falha de rede: silenciosa — campos ficam em branco
  }).whenComplete(() {
    if (mounted) setState(() => _isCepLoading = false);
  });
}
```

### Sufixo de loading no campo CEP
O `AuthTextField` do CEP recebe:
```dart
suffixIcon: _isCepLoading
    ? const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      )
    : null,
onChanged: _onCepChanged,
```

---

## Fluxo de Execução (CEP Autofill)

```
[Anfitrião digita no campo CEP]
        │
        ▼
[onChanged dispara a cada caractere]
        │
[digits.length == 8?] ──NÃO──► nenhuma ação
        │ SIM
        ▼
[_isCepLoading = true] → CircularProgressIndicator no suffix do campo
        │
        ▼
[CepService.lookup(digits)]  ← GET viacep.com.br/ws/{cep}/json/
        │
        ├─ ERRO de rede (DioException) ──► catchError: silencioso
        │                                  _isCepLoading = false
        │
        ├─ result.erro == true ──► SnackBar "CEP não encontrado..."
        │                          _isCepLoading = false
        │
        └─ CEP VÁLIDO
               ▼
        setState:
          _ruaController.text    = result.logradouro
          _bairroController.text = result.bairro
          _cidadeController.text = result.localidade
          _selectedUf            = result.uf (se presente em _estados)
          _isCepLoading          = false
```

---

## Dependências

**Bibliotecas (já no projeto):**
- [x] `dio` — instância dedicada no `CepService`
- [x] `flutter_riverpod` — `Provider` para `cepServiceProvider`

**Serviços externos:**
- [ ] ViaCEP (`viacep.com.br`) — API pública, sem autenticação, sem rate limit documentado

**Outras features:**
- [x] `host-signup-page` — controllers `_ruaController`, `_bairroController`, `_cidadeController`, `_selectedUf` e `_estados` já existem na página

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| ViaCEP fora do ar ou lenta (> 5s) | Timeout de 5s configurado; `catchError` silencioso mantém o formulário funcional sem erro fatal |
| `_selectedUf` recebe valor de UF não presente em `_estados` | Verificar `if (_estados.contains(result.uf))` antes de atribuir; se ausente, dropdown permanece como estava |
| `onChanged` dispara múltiplas consultas se usuário digitar e apagar rapidamente | A condição `digits.length != 8` filtra todos os disparos exceto quando há exatamente 8 dígitos — na prática, uma única consulta por sequência válida |
| Widget desmontado durante a consulta assíncrona | `if (!mounted) return` no `.then()` e `.whenComplete()` |
| CEP retorna `logradouro` vazio (ex: CEPs de cidade) | Campo `_ruaController` recebe string vazia; permanece editável e o validator obrigatório alertará o usuário no submit |
| `AuthTextField` não expõe `suffixIcon` nem `onChanged` | Modificação mínima e backward-compatible: ambos os parâmetros são opcionais com default `null` |
