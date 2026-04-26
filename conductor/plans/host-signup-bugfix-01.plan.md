# Plan — host-signup-page bugfix-01

> Arquivo: `Frontend/lib/features/auth/presentation/pages/host_signup_page.dart`
> Status geral: [PENDENTE]

---

## Bug 1 — Telefone aceita letras misturadas com dígitos [PENDENTE]

**Causa:** O validator só confere `digits.length < 10` após remover não-dígitos com `replaceAll(RegExp(r'\D'), '')`.
`"123456789asd"` passa porque os dígitos extraídos somam 9 → falha. Mas `"1234567890asd"` extrai 10 dígitos e passa mesmo contendo letras.

**Correção:** Adicionar verificação de caracteres permitidos **antes** de contar os dígitos.
Permitir apenas dígitos, espaços, hífen, parênteses e `+` (padrões comuns de formato de telefone).

**Linha atual (175):**
```dart
validator: (value) {
  if (value == null || value.isEmpty) return 'Informe o telefone';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) return 'Telefone inválido';
  return null;
},
```

**Linha corrigida:**
```dart
validator: (value) {
  if (value == null || value.isEmpty) return 'Informe o telefone';
  if (!RegExp(r'^[\d\s\-\(\)\+]+$').hasMatch(value)) return 'Telefone inválido';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) return 'Telefone inválido';
  return null;
},
```

> **Nota:** esta correção já foi aplicada (linha 175 do arquivo atual contém o `RegExp` de caracteres permitidos).
> Verificar que está presente antes de marcar como concluído.

- [ ] Confirmar que linha 175 contém `if (!RegExp(r'^[\d\s\-\(\)\+]+$').hasMatch(value)) return 'Telefone inválido';`

---

## Bug 2 — Dropdown UF fica por baixo do conteúdo acima [PENDENTE]

**Causa:** O `DropdownButtonFormField` está envolvido por um `Container` com `BoxDecoration` (linhas 222–252).
Esse `Container` com `borderRadius` cria um clipping context que interfere no overlay do menu dropdown, fazendo com que o painel de itens seja renderizado atrás de outros widgets da tela.

**Correção:** Remover o `Container` decorado e transferir o estilo visual (borda, cor de fundo, radius, padding) para a `InputDecoration` do próprio `DropdownButtonFormField`.
O `DropdownButtonFormField` usa um `Overlay` para renderizar o menu — quando seu widget raiz não tem clipping externo, o overlay é posicionado corretamente sobre toda a tela (limitado apenas pela `Scaffold`/navbar).

**Trecho atual (linhas 220–253):**
```dart
Expanded(
  flex: 2,
  child: Container(
    height: 56,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.strokeLight),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        initialValue: _selectedUf,
        hint: const Text('UF', style: TextStyle(color: AppColors.greyText)),
        items: _estados.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() { _selectedUf = newValue; });
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        validator: (value) => value == null ? 'Obrigatório' : null,
      ),
    ),
  ),
),
```

**Trecho corrigido:**
```dart
Expanded(
  flex: 2,
  child: DropdownButtonFormField<String>(
    value: _selectedUf,
    hint: const Text('UF', style: TextStyle(color: AppColors.greyText, fontSize: 14)),
    isExpanded: true,
    items: _estados.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList(),
    onChanged: (newValue) {
      setState(() { _selectedUf = newValue; });
    },
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.strokeLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.strokeLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.strokeLight),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    ),
    validator: (value) => value == null ? 'Obrigatório' : null,
  ),
),
```

- [ ] Remover o `Container` com `BoxDecoration` e `DropdownButtonHideUnderline` (linhas 222–252)
- [ ] Substituir pelo `DropdownButtonFormField` com `InputDecoration` estilizada conforme acima
- [ ] Verificar visualmente que o menu abre por cima de todos os campos e fica abaixo apenas da navbar/SafeArea

---

## Bug 3 — Campo `complemento` aparece antes de `bairro` [PENDENTE]

**Causa:** No `Column` do formulário, o `AuthTextField` de `complemento` (linha 286) está inserido antes do `AuthTextField` de `bairro` (linha 291).
A ordem correta de endereço é: rua + número → bairro → complemento.

**Trecho atual (linhas 285–298):**
```dart
// ❌ ordem errada
AuthTextField(hintText: 'complemento', controller: _complementoController),
const SizedBox(height: 16),
AuthTextField(
  hintText: 'bairro',
  controller: _bairroController,
  validator: (value) {
    if (value == null || value.trim().isEmpty) return 'Informe o bairro';
    return null;
  },
),
```

**Trecho corrigido:**
```dart
// ✓ ordem correta
AuthTextField(
  hintText: 'bairro',
  controller: _bairroController,
  validator: (value) {
    if (value == null || value.trim().isEmpty) return 'Informe o bairro';
    return null;
  },
),
const SizedBox(height: 16),
AuthTextField(hintText: 'complemento', controller: _complementoController),
```

- [ ] Inverter a ordem dos dois blocos: mover `bairro` para antes de `complemento` (linhas 285–298)

---

## Validação [PENDENTE]

- [ ] **Bug 1:** digitar `"1234567890asd"` no campo telefone → validator retorna `'Telefone inválido'`
- [ ] **Bug 1:** digitar `"(11) 98765-4321"` → validator passa (formato válido com não-dígitos permitidos)
- [ ] **Bug 2:** tocar no dropdown UF → menu aparece sobrepondo os campos abaixo; não fica atrás do título nem de nenhum outro widget
- [ ] **Bug 2:** borda e visual do dropdown UF consistentes com os demais campos `AuthTextField`
- [ ] **Bug 3:** ordem dos campos exibida ao rolar o formulário: `rua | n°` → `bairro` → `complemento`
- [ ] `flutter analyze lib/` — zero erros novos introduzidos

---

## Regra de Atualização de Status

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`
