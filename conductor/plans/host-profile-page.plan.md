# Plan — Host Profile Page

> Derivado de: conductor/specs/host-profile-page.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

Sem tasks — sem dependências novas, sem variáveis de ambiente, sem migrations.

---

## Backend [CONCLUÍDO]

Sem tasks — endpoints já existem e estão funcionais.

---

## Frontend [CONCLUÍDO]

- [x] Criar `HostProfileNotifier` + provider em `lib/features/profile/presentation/providers/host_profile_provider.dart`
- [x] Converter `HostProfilePage` de `StatelessWidget` para `ConsumerWidget`
- [x] Integrar `GET /hotel/me` via `HotelService.getAutenticado` no notifier
- [x] Integrar `GET /uploads/hotels/:hotel_id/cover` no notifier (sequencial, após obter `hotel_id`)
- [x] Mapear dados do hotel para os widgets (`ProfileHeader` com `nome_hotel` e `email`)
- [x] Exibir primeira foto de capa disponível no `ProfileHeader`
- [x] Tratar estado de loading
- [x] Tratar estado de erro
- [x] Tratar lista de fotos vazia (exibir avatar padrão)

---

## Validação [PENDENTE]

- [ ] Verificar que nome e email reais do hotel aparecem na tela após login
- [ ] Verificar loading exibido durante a chamada
- [ ] Verificar mensagem de erro ao simular falha de rede
- [ ] Verificar exibição do avatar padrão quando hotel não tem fotos
- [ ] Verificar navegação para editar perfil, meus quartos e configurações
- [ ] Verificar funcionamento em mobile e web
