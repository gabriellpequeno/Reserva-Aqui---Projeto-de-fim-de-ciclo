# BUG-10 — cadastro_user + editar_perfil - Validação de Idade e Padronização de Fields

## Telas
`lib/features/auth/presentation/pages/register_page.dart` (ou equivalente cadastro user)
`lib/features/profile/presentation/pages/edit_profile_page.dart`

## Prioridade
**Média** — validação de negócio obrigatória + inconsistência visual

## Branch sugerida
`fix/user-registration-and-fields`

---

## Bugs

### 1. Validação de Idade no Cadastro

- [ ] **Adicionar validação de idade mínima** no formulário de cadastro do usuário
  - O campo de data de nascimento deve calcular a idade a partir da data informada
  - Regra: usuário deve ter **18 anos ou mais** para se cadastrar (confirmar a idade mínima com o requisito do projeto)
  - Se menor de idade: exibir mensagem de erro no campo — ex: "Você deve ter pelo menos 18 anos para se cadastrar"
  - A validação deve ocorrer no `validator` do campo de data, não apenas no submit
  - No backend, replicar a validação como segunda linha de defesa (se ainda não existir)

### 2. Padronização Visual dos Fields — Cadastro e Edição de Perfil

**Problema:** os campos do formulário de cadastro têm estética diferente dos campos da tela de edição de perfil.

- [ ] **Identificar o estilo de referência** — os campos da tela de edição de perfil (`edit_profile_page.dart`) são o padrão a seguir
- [ ] **Aplicar o mesmo estilo ao cadastro** — garantir que `InputDecoration`, `border`, `borderRadius`, `labelStyle`, `hintStyle` e espaçamentos sejam idênticos nas duas telas
- [ ] Verificar se existe um widget compartilhado (ex: `AppTextField`) — se existir, usar em ambas as telas; se não existir, criar e refatorar os dois formulários para usá-lo
- [ ] Testar em dark mode: os fields padronizados devem herdar os tokens semânticos corretamente (ver BUG-4)

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `register_page.dart` | Adicionar validação de idade; padronizar estilo dos fields |
| `edit_profile_page.dart` | Referência de estilo (não alterar o estilo, apenas garantir que é o padrão) |
| `app_text_field.dart` (a criar se não existir) | Widget compartilhado de campo de texto padronizado |
| Backend — validação de idade | Adicionar se não existir |

---

## Observações
- Confirmar a idade mínima exigida pelo projeto antes de hardcodar `18` anos
- Se o campo de data de nascimento for um `DatePicker`, a validação de idade já pode ser feita desabilitando datas futuras ao dia `hoje - 18 anos` no seletor
