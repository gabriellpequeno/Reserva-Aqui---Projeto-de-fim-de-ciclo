# Spec — user-registration-field-standards

## Referência
- **PRD:** `conductor/features/user-registration-field-standards.prd.md`

---

## Abordagem Técnica

Task 100% frontend (Flutter). Nenhuma alteração de backend nesta entrega.

Estratégia por área:
- **Padronização visual + toggle de senha:** Converter `AuthTextField` de `StatelessWidget` para `StatefulWidget`, adicionando params opcionais `label` e `icon` e gerenciando `_obscureText` internamente — elimina a necessidade de o pai controlar o estado de visibilidade da senha.
- **Erro de senha não truncado:** Adicionar `errorMaxLines: 5` ao `InputDecoration` de `AuthTextField` e reformatar a mensagem de `_validateSenha` usando `\n• ` para listar cada condição em linha própria.
- **Validação de idade:** Estender `_validateData` em `user_signup_page.dart` para calcular idade com `DateTime` e rejeitar < 18 anos; passar `lastDate: DateTime(now.year - 18, now.month, now.day)` para `DatePickerField`.
- **Termos e Condições:** Novo widget `TermsModal` (bottom sheet scrollável) + row de Checkbox com `RichText` linkável no formulário de cadastro.
- **Capitalização:** Ajuste direto nas strings de texto das telas afetadas.

---

## Componentes Afetados

### Backend
Nenhuma alteração.

### Frontend

| Arquivo | Tipo | O que muda |
|---------|------|-----------|
| `lib/features/auth/presentation/widgets/auth_text_field.dart` | Modificado | Virar `StatefulWidget`; adicionar params `label`, `icon`; gerenciar `_obscureText` + toggle interno; adicionar `errorBorder`, `focusedErrorBorder`, `errorMaxLines: 5`; mudar `focusedBorder` para `AppColors.secondary` |
| `lib/core/widgets/date_picker_field.dart` | Modificado | Adicionar param opcional `lastDate`; usar `lastDate` no `showDatePicker`; atualizar `initialDate` para não ultrapassar `lastDate`; atualizar estilo (`labelText`, `prefixIcon`, `errorBorder`, `focusedBorder` → `AppColors.secondary`) |
| `lib/features/auth/presentation/pages/user_signup_page.dart` | Modificado | Corrigir `_validateData` com cheque de 18 anos; reformatar `_validateSenha` com bullet points; passar `label`/`icon` para todos os `AuthTextField`; passar `lastDate` ao `DatePickerField`; adicionar `_termsAccepted` + validação no submit; adicionar widget de Checkbox + `TermsModal`; corrigir capitalização do título |
| `lib/features/auth/presentation/pages/login_page.dart` | Modificado | Corrigir capitalização: título `'Acesse Agora'`, botão `'Cadastre-Se Agora'` |
| `lib/features/auth/presentation/widgets/terms_modal.dart` | Novo | Bottom sheet scrollável com texto mockado de Termos e Condições |

> `host_signup_page.dart` **não é alterado**. Como `label` e `icon` são opcionais em `AuthTextField`, os 13 campos do host continuam funcionando sem mudanças — herdarão apenas o novo estilo de bordas e `errorMaxLines`.

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| `AuthTextField` vira `StatefulWidget` | O toggle de visibilidade da senha precisa de estado local (`_obscureText`). Alternativa seria exigir que o pai passasse o estado — mais boilerplate sem ganho real |
| `errorMaxLines: 5` no `InputDecoration` | Resolve o truncamento da mensagem de senha sem criar widget extra; o `TextFormField` já expõe essa propriedade nativamente |
| Mensagem de senha com `\n•` (bullet points) | Lista as condições de forma legível sem precisar de nenhum widget adicional; compatível com `errorMaxLines` |
| `label` e `icon` opcionais em `AuthTextField` | Garante retrocompatibilidade com `host_signup_page.dart` (13 usos sem label/icon) e `login_page.dart` — sem regressões |
| `TermsModal` como widget separado | Isola a lógica do modal; facilita futura substituição do texto mockado por conteúdo real sem alterar `user_signup_page.dart` |
| `showModalBottomSheet` para os Termos | Mais natural em mobile do que `AlertDialog`; permite scroll nativo em telas pequenas |
| `_termsAccepted` como estado local em `user_signup_page.dart` | Dado efêmero de UI — não precisa de provider |
| `DatePickerField.lastDate` opcional | Mantém o widget genérico e reutilizável; o chamador define a restrição |

---

## Contratos de API

Nenhum endpoint novo ou modificado nesta entrega.

---

## Modelos de Dados

Nenhum modelo novo. Único estado novo é local:

```
// user_signup_page.dart — estado local adicionado
bool _termsAccepted = false;
```

---

## Detalhamento de Implementação

### 1. `AuthTextField` — StatefulWidget + toggle + estilo

```dart
// Novos params opcionais
final String? label;
final IconData? icon;

// Estado interno
bool _obscureText = false; // inicializado com widget.isPassword no initState

// InputDecoration atualizada
labelText: widget.label,
prefixIcon: widget.icon != null ? Icon(widget.icon, color: AppColors.secondary) : null,
labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
errorMaxLines: 5,
focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.secondary, width: 2), ...),
errorBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.error), ...),
focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.error, width: 2), ...),

// Toggle (só renderiza se isPassword == true)
suffixIcon: widget.isPassword
  ? IconButton(
      icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                 color: AppColors.secondary),
      onPressed: () => setState(() => _obscureText = !_obscureText),
    )
  : widget.suffixIcon,
```

### 2. `_validateSenha` reformatada — `user_signup_page.dart`

```dart
String? _validateSenha(String? value) {
  if (value == null || value.isEmpty) return 'Informe a senha';
  final erros = <String>[];
  if (value.length < 8) erros.add('mínimo de 8 caracteres');
  if (!RegExp(r'[A-Z]').hasMatch(value)) erros.add('uma letra maiúscula');
  if (!RegExp(r'[a-z]').hasMatch(value)) erros.add('uma letra minúscula');
  if (!RegExp(r'[0-9]').hasMatch(value)) erros.add('um número');
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) erros.add('um caractere especial');
  if (erros.isEmpty) return null;
  return 'A senha precisa ter:\n${erros.map((e) => '• $e').join('\n')}';
}
```

### 3. `_validateData` com cheque de idade — `user_signup_page.dart`

```dart
// Após validar formato e valores de dia/mês/ano:
final birthDate = DateTime(year, month, day);
// Detectar overflow de data (ex: 30/02)
if (birthDate.day != day || birthDate.month != month) return 'Data inválida';

final today = DateTime.now();
final minBirthDate = DateTime(today.year - 18, today.month, today.day);
if (birthDate.isAfter(minBirthDate)) {
  return 'Você deve ter pelo menos 18 anos para se cadastrar';
}
```

### 4. `DatePickerField` — param `lastDate`

```dart
// Novo param
final DateTime? lastDate;

// Em _openCalendar:
final effectiveLastDate = widget.lastDate ?? DateTime.now();
final picked = await showDatePicker(
  lastDate: effectiveLastDate,
  initialDate: initial.isAfter(effectiveLastDate) ? effectiveLastDate : initial,
  ...
);
```

### 5. `TermsModal` — novo widget

```dart
// lib/features/auth/presentation/widgets/terms_modal.dart
void showTermsModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('Termos e Condições', style: ...),
          const SizedBox(height: 16),
          const Text(_kTermsText), // const string mockada no mesmo arquivo
        ]),
      ),
    ),
  );
}
```

### 6. Checkbox de Termos — `user_signup_page.dart`

```dart
// Estado
bool _termsAccepted = false;
String? _termsError;

// Widget (acima do botão Cadastrar)
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Checkbox(
      value: _termsAccepted,
      onChanged: (v) => setState(() { _termsAccepted = v ?? false; _termsError = null; }),
    ),
    Expanded(
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: 'Eu concordo com os ', style: TextStyle(color: colorScheme.onSurface)),
          TextSpan(
            text: 'Termos e Condições',
            style: TextStyle(color: AppColors.secondary, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () => showTermsModal(context),
          ),
        ]),
      ),
    ),
  ],
),
if (_termsError != null)
  Padding(
    padding: const EdgeInsets.only(left: 12, top: 4),
    child: Text(_termsError!, style: TextStyle(color: colorScheme.error, fontSize: 12)),
  ),

// Em _submit(), antes do request:
if (!_termsAccepted) {
  setState(() => _termsError = 'Você deve aceitar os Termos e Condições para continuar');
  return;
}
```

---

## Dependências

**Bibliotecas (já presentes no projeto):**
- [x] `flutter/gestures.dart` — `TapGestureRecognizer` para o link dos Termos (import nativo do Flutter)
- [x] `mask_text_input_formatter` — já em uso
- [x] `flutter_riverpod` — já em uso

**Novas dependências de pacote:** nenhuma.

**Outras features:**
- Nenhuma dependência de feature externa.

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Mudança de `StatelessWidget` para `StatefulWidget` em `AuthTextField` pode causar regressão visual em `host_signup_page.dart` | `label` e `icon` são opcionais — campos sem eles mantêm comportamento atual; apenas bordas e `errorMaxLines` mudam globalmente (melhoria) |
| `TapGestureRecognizer` vaza memória se não for descartado | Instanciar dentro do `build` ou usar `_recognizer` com `dispose()` em `StatefulWidget` — como `user_signup_page.dart` já é stateful, adicionar ao `dispose()` |
| `DraggableScrollableSheet` com `isScrollControlled: true` pode cobrir a tela inteira em iPhones com notch | `maxChildSize: 0.95` limita a 95% da tela; padding top garante espaço para o safe area |
| Reformatação da mensagem de senha (`\n•`) quebra snapshot tests | Não há testes de snapshot identificados no projeto — risco baixo |
