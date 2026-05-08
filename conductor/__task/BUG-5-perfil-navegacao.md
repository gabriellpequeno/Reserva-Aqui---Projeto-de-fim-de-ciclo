# BUG-5 — profile_pages - Foto de Perfil, Botão Voltar e Foto de Capa do Host

## Telas
`lib/features/profile/presentation/pages/user_profile_page.dart`
`lib/features/profile/presentation/pages/edit_profile_page.dart`
`lib/features/profile/presentation/pages/host_profile_page.dart`
`lib/features/profile/presentation/pages/edit_host_profile_page.dart`
`lib/features/settings/presentation/pages/settings_page.dart` (termos, privacidade, sobre)

## Prioridade
**Média** — usabilidade e fluxo de navegação

## Branch sugerida
`fix/profile-navigation-fixes`

---

## Bugs

### 1. Foto de Perfil (User e Host)

- [ ] **Adicionar foto de perfil ao usuário** — na tela de perfil e edição do user:
  - Exibir avatar circular com foto atual do usuário (se houver) ou initials fallback
  - Na tela de edição de perfil, adicionar campo para trocar a foto (seletor de galeria/câmera)
  - Upload via endpoint adequado (verificar se existe `POST /uploads/usuarios/:id/avatar` ou equivalente)
  - Se o endpoint não existir, documentar como EXT e exibir apenas o avatar estático por ora

- [ ] **Adicionar foto de perfil ao Host** — o mesmo se aplica ao host:
  - Exibir avatar circular na tela de perfil do host
  - Na tela de edição de perfil do host, adicionar campo para trocar a foto
  - **A foto de perfil do host também é usada como foto de perfil na `hotel_details_page`** — ao salvar, a mesma imagem deve aparecer nos detalhes do hotel
  - Upload via `POST /uploads/hotels/:hotel_id/avatar` (ou equivalente — verificar endpoint correto)

### 2. Botão Voltar — Telas secundárias com botão duplicado

O segundo botão de voltar **não está na tela de perfil principal**, mas sim em telas derivadas acessadas pelo caminho `Perfil > Configurações > [tela]`:

- [ ] **Termos de uso** — remover segundo botão de voltar; o botão restante deve voltar para Configurações
- [ ] **Privacidade** — remover segundo botão de voltar; o botão restante deve voltar para Configurações
- [ ] **Sobre o App** — remover segundo botão de voltar; o botão restante deve voltar para Configurações

> A **tela de editar perfil** não tem segundo botão de voltar (OK) — não mexer.

### 3. Botão Voltar — Navegação correta nas telas de perfil

Garantir que todas as telas do fluxo de perfil usam `context.push()` (não `context.go()`) para preservar o stack:

- [ ] Confirmar que `edit_profile_page` volta para perfil, não para home
- [ ] Confirmar que Termos, Privacidade e Sobre voltam para Configurações
- [ ] Verificar se alguma dessas telas usa `context.go()` em botão de voltar customizado — substituir por `context.pop()`

> Ver também BUG-9 (botão voltar global) para o padrão aplicado a todo o app.

### 4. Foto de Capa do Hotel (Host)

- [ ] **Adicionar campo de foto de capa na edição de perfil do Host** — ao editar o perfil como host, deve haver um campo para fazer upload da foto de capa que aparece na `hotel_details_page`
  - Upload via `POST /uploads/hotels/:hotel_id/cover` (endpoint já mapeado em P4-C)
  - Exibir preview da foto atual de capa com opção de trocar
  - Após upload bem-sucedido, a `hotel_details_page` deve buscar a nova imagem

---

## Endpoints usados

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| POST | `/uploads/usuarios/:id/avatar` | ✅ | Upload foto de perfil (verificar se existe) |
| POST | `/uploads/hotels/:hotel_id/cover` | ✅ | Upload foto de capa do hotel |

---

## Dependências
- BUG-8 (botão voltar global) trata o padrão geral; esta task trata os casos específicos das telas de perfil
- Upload de imagem requer endpoint disponível — verificar antes de implementar o front
