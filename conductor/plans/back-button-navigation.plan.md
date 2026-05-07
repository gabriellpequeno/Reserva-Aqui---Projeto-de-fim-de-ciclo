# Plan — Back Button Navigation

> Derivado de: conductor/specs/back-button-navigation.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Executar `grep -r "context.go" lib/` e listar todos os usos — separar os que devem virar `context.push()` dos que devem ser mantidos como `context.go()`

---

## Backend [PENDENTE]

N/A

---

## Frontend [EM ANDAMENTO]

- [x] Adicionar parâmetro opcional `fallbackRoute: String?` ao `CustomAppBar` (`lib/core/widgets/custom_app_bar.dart`) e ajustar o `onPressed` para usar `fallbackRoute` quando `canPop = false`
- [x] Corrigir `context.go('/auth/login')` → `context.push('/auth/login')` em `hotel_details_page.dart`
- [x] Aplicar `CustomAppBar(fallbackRoute: '/home')` na `login_page.dart`
- [x] Aplicar `CustomAppBar` na `settings_page.dart`
- [x] Aplicar `CustomAppBar` na `about_page.dart` (substituiu AppBar genérico)
- [x] Aplicar `CustomAppBar` na `privacy_page.dart` (substituiu AppBar genérico)
- [x] Aplicar `CustomAppBar` na `terms_page.dart` (substituiu AppBar genérico)
- [x] Aplicar `CustomAppBar` na `edit_user_profile_page.dart`
- [x] Aplicar `CustomAppBar` na `edit_host_profile_page.dart`
- [x] Aplicar `CustomAppBar` na `edit_admin_profile_page.dart`
- [x] Aplicar `CustomAppBar` na `ticket_details_page.dart` (removeu _buildHeader e _headerButton)

---

## Validação [PENDENTE]

- [ ] Testar fluxo: Home → Busca → Login → ← → Busca
- [ ] Testar fluxo: Home → Hotel Details → Room Details → Checkout → ← × 3
- [ ] Testar fluxo: Perfil → Settings → Termos → ← × 2
- [ ] Testar tela de login sem histórico na pilha: botão voltar deve ir para Home
- [ ] Verificar que redirects de autenticação (pós-login → Home, pós-logout → Login) não foram afetados
- [ ] Verificar visual das telas que receberam `CustomAppBar`: layout, padding e dark mode
