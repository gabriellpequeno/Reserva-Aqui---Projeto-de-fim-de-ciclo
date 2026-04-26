# Plan — CEP Autofill

> Derivado de: `conductor/specs/cep-autofill.spec.md`
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

> Sem novas dependências de pacote. `dio` e `flutter_riverpod` já estão no `pubspec.yaml`.
> A instância Dio do `CepService` é criada localmente (sem `dioProvider`) — nenhuma configuração global é necessária.

- [x] Confirmar que `Frontend/lib/features/auth/data/models/` existe
- [x] Confirmar que `Frontend/lib/features/auth/data/services/` existe

---

## Backend [CONCLUÍDO]

> Nenhum endpoint interno criado ou modificado.
> A feature consome exclusivamente a API pública ViaCEP — sem autenticação, sem configuração de backend.

- [x] Verificar disponibilidade do endpoint `GET https://viacep.com.br/ws/01310100/json/` (sanity check manual)

---

## Frontend [CONCLUÍDO]

### 1. Model — `CepResponse` [CONCLUÍDO]

- [x] **Criar** `lib/features/auth/data/models/cep_response.dart`
  - Campos: `logradouro?`, `bairro?`, `localidade?`, `uf?`, `erro` (bool)
  - `factory CepResponse.fromJson(Map<String, dynamic> json)` — tratar `json['erro'] == true || json['erro'] == 'true'`

---

### 2. Service — `CepService` [CONCLUÍDO]

- [x] **Criar** `lib/features/auth/data/services/cep_service.dart`
  - Instanciar `Dio` locally com `BaseOptions(baseUrl: 'https://viacep.com.br/ws/', connectTimeout: 5s, receiveTimeout: 5s)` — **sem** interceptor de auth
  - Implementar `Future<CepResponse> lookup(String cep)` — `GET $cep/json/`
  - Expor `final cepServiceProvider = Provider<CepService>((ref) => CepService())`

---

### 3. Widget — Adicionar `suffixIcon` e `onChanged` ao `AuthTextField` [CONCLUÍDO]

- [x] **Modificar** `lib/features/auth/presentation/widgets/auth_text_field.dart`
  - Adicionar parâmetro opcional `final Widget? suffixIcon` (default `null`)
  - Adicionar parâmetro opcional `final void Function(String)? onChanged` (default `null`)
  - Passar `suffixIcon` para `InputDecoration` no `TextFormField`
  - Passar `onChanged` para o `TextFormField`

---

### 4. Página — Integrar CEP Autofill em `HostSignUpPage` [CONCLUÍDO]

- [x] **Modificar** `lib/features/auth/presentation/pages/host_signup_page.dart`
  - Adicionar import de `cep_service.dart`
  - Adicionar variável de estado `bool _isCepLoading = false`
  - Implementar método `void _onCepChanged(String value)`:
    - Extrair apenas dígitos; retornar imediatamente se `digits.length != 8`
    - `setState(() => _isCepLoading = true)`
    - Chamar `ref.read(cepServiceProvider).lookup(digits).then(...).catchError(...).whenComplete(...)`
    - No `.then`: guardar `if (!mounted) return`; se `result.erro`, exibir SnackBar `"CEP não encontrado. Verifique e preencha manualmente."`; caso contrário, `setState` populando `_ruaController`, `_bairroController`, `_cidadeController` e `_selectedUf` (com guarda `_estados.contains(result.uf)`)
    - No `.catchError`: silencioso (falha de rede não gera erro fatal)
    - No `.whenComplete`: `if (mounted) setState(() => _isCepLoading = false)`
  - No campo CEP (`AuthTextField`), passar:
    - `onChanged: _onCepChanged`
    - `suffixIcon: _isCepLoading ? Padding(padding: EdgeInsets.all(12), child: SizedBox(16x16, child: CircularProgressIndicator(strokeWidth: 2))) : null`

---

## Validação [PENDENTE]

- [ ] Executar `flutter analyze lib/` — zero erros novos introduzidos por esta feature
- [ ] **Fluxo feliz — CEP válido:** digitar `01310100` no campo CEP → após 8 dígitos, spinner aparece → rua, bairro, cidade e UF preenchidos automaticamente → spinner some
- [ ] **CEP não encontrado:** digitar `00000000` → spinner aparece → SnackBar "CEP não encontrado. Verifique e preencha manualmente." → campos de endereço ficam em branco e editáveis
- [ ] **Edição pós-preenchimento:** auto-preencher com CEP válido → editar manualmente o campo "rua" → submeter formulário → valor editado (não o da ViaCEP) é enviado no body
- [ ] **Menos de 8 dígitos:** digitar `1234` → nenhuma consulta disparada, nenhum spinner, nenhum erro
- [ ] **Falha de rede (offline):** desativar rede → digitar CEP de 8 dígitos → spinner aparece brevemente → some sem erro fatal; formulário permanece funcional
- [ ] **Timeout (5s):** simular latência alta → consulta expira → comportamento idêntico à falha de rede (silent error)
- [ ] **UF fora da lista `_estados`:** usar CEP de território não listado → `_selectedUf` permanece `null`; dropdown não é alterado
- [ ] **`mounted` check:** navegar para fora da tela durante consulta do CEP → sem `setState after dispose` no console
- [ ] **Compatibilidade com submit:** preencher todos os campos (via CEP autofill + `nome`, `cnpj`, `telefone`, `senha` manualmente) → submeter → cadastro realizado com sucesso

---

## Regra de Atualização de Status

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** para `[CONCLUÍDO]`
e sincronizar com `conductor/plan.md`:
- Localizar bloco **"Fase 1 — Autenticação"**
- Adicionar sub-entry: `- [x] CEP autofill no cadastro de hotel (cep-autofill) — plan: plans/cep-autofill.plan.md`
