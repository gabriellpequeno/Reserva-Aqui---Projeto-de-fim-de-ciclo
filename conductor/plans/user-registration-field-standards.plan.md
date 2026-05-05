# Plan — user-registration-field-standards

> Derivado de: `conductor/specs/user-registration-field-standards.spec.md`
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Confirmar que `AppColors.secondary` está definido em `lib/core/theme/app_colors.dart`
- [x] Confirmar que `flutter/gestures.dart` está disponível (nativo Flutter — sem instalação)
- [x] Confirmar que não há novas dependências de pacote a adicionar no `pubspec.yaml`

---

## Backend [N/A]

Nenhuma alteração de backend nesta entrega.

---

## Frontend [CONCLUÍDO]

### `auth_text_field.dart`
- [x] Converter `AuthTextField` de `StatelessWidget` para `StatefulWidget`
- [x] Adicionar params opcionais `label` (`String?`) e `icon` (`IconData?`)
- [x] Inicializar `_obscureText` com `widget.isPassword` no `initState`
- [x] Adicionar `suffixIcon` condicional: ícone de olho quando `isPassword == true`, caso contrário usar `widget.suffixIcon`
- [x] Atualizar `InputDecoration`: `labelText`, `prefixIcon`, `labelStyle`, `errorBorder`, `focusedErrorBorder`, `errorMaxLines: 5`
- [x] Mudar `focusedBorder` de `colorScheme.primary` para `AppColors.secondary` (width 2)

### `date_picker_field.dart`
- [x] Adicionar param opcional `lastDate` (`DateTime?`)
- [x] Em `_openCalendar`: definir `effectiveLastDate = widget.lastDate ?? DateTime.now()` e usá-lo em `showDatePicker`
- [x] Corrigir `initialDate` para não ultrapassar `effectiveLastDate`
- [x] Atualizar `InputDecoration` para o padrão visual: `labelText`, `prefixIcon`, `errorBorder`, `focusedErrorBorder`, `focusedBorder` com `AppColors.secondary` (via reutilização de `AuthTextField`)

### `terms_modal.dart` (novo)
- [x] Criar `lib/features/auth/presentation/widgets/terms_modal.dart`
- [x] Implementar função `showTermsModal(BuildContext context)` com `showModalBottomSheet` + `constraints` para limitar altura a 80% da área útil
- [x] Adicionar `const String _kTermsText` com texto mockado genérico de Termos e Condições de aplicação de reservas

### `user_signup_page.dart`
- [x] Corrigir `_validateData`: verificar overflow de data (ex: 30/02) e adicionar cheque de idade ≥ 18 anos
- [x] Reformatar `_validateSenha`: adicionar validação de comprimento mínimo (8 chars) e listar cada condição não satisfeita com `\n•`
- [x] Declarar `_termsAccepted = false` e `_termsError` como estado local; declarar e descartar `_termsRecognizer` no `dispose()`
- [x] Passar `label` e `icon` para todos os 6 `AuthTextField` da tela (nome, CPF, telefone, email, senha, confirmar senha)
- [x] Passar `lastDate: DateTime(now.year - 18, now.month, now.day)` ao `DatePickerField`
- [x] Adicionar widget de `Checkbox` + `RichText` com link para `showTermsModal` acima do botão de submit
- [x] Em `_submit()`: validar `_termsAccepted` antes de disparar o request; exibir `_termsError` se falso
- [x] Corrigir capitalização do título: `'cadastre-se'` → `'Cadastre-Se'`
- [x] Sanitizar `numeroCelular` (remover máscara antes de enviar)
- [x] Aplicar `maxLength` nos campos de texto livre (nome: 100, e-mail: 254, senha: 128)
- [x] Remover exposição de `serverMsg` raw no status 400

### `login_page.dart`
- [x] Corrigir capitalização do título (role guest): `'Acesse agora'` → `'Acesse Agora'`
- [x] Corrigir capitalização do botão: `'cadastre-se agora'` → `'Cadastre-Se Agora'`

### Extras (fora do plan original, em escopo de capitalização)
- [x] `user_or_host_page.dart`: `'acesse agora'` → `'Acesse Agora'`
- [x] `profile_header.dart`: `'Editar perfil'` → `'Editar Perfil'`
- [x] `app_colors.dart`: adicionar `greyText` e `strokeLight` (constantes ausentes referenciadas em widgets de perfil)

---

## Validação [PENDENTE]

- [ ] Informar data de nascimento com idade < 18 → campo exibe "Você deve ter pelo menos 18 anos para se cadastrar"
- [ ] Abrir o `DatePicker` de nascimento → datas após `hoje - 18 anos` estão desabilitadas
- [ ] Digitar senha com condições faltando → cada condição aparece em linha própria (`\n•`) sem truncamento
- [ ] Tocar no ícone de olho nos campos "Senha" e "Confirmar Senha" → texto alterna entre visível e oculto
- [ ] Submeter formulário sem marcar Termos → exibe "Você deve aceitar os Termos e Condições para continuar"
- [ ] Tocar em "Termos e Condições" → bottom sheet abre com texto scrollável
- [ ] Verificar visual em light mode e dark mode: label flutuante, ícone prefix em `AppColors.secondary`, borda de foco em `AppColors.secondary`, borda de erro em `colorScheme.error`
- [ ] Verificar que `host_signup_page.dart` não regrediu (campos sem label/icon continuam funcionando)
- [ ] Verificar títulos e botão: `'Cadastre-Se'`, `'Acesse Agora'`, `'Cadastre-Se Agora'`
- [ ] Preencher formulário completamente válido (idade ≥ 18, senha válida, termos aceitos) → cadastro conclui sem erros
