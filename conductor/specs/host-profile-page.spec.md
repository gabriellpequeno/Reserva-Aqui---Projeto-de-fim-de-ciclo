# Spec — Host Profile Page

## Referência
- **PRD:** conductor/features/host-profile-page.prd.md

## Abordagem Técnica
Feature exclusivamente de frontend. Nenhum endpoint novo precisa ser criado — o backend já expõe `GET /hotel/me` e `GET /uploads/hotels/:hotel_id/cover`. A implementação consiste em criar um `HostProfileNotifier` (Riverpod `AsyncNotifier`) que orquestra as duas chamadas em sequência, e converter `HostProfilePage` de `StatelessWidget` para `ConsumerWidget` para consumir o estado.

## Componentes Afetados

### Backend
Nenhum. Os endpoints já existem e estão funcionais.

### Frontend
- **Novo:** `HostProfileNotifier` + provider — `lib/features/profile/presentation/providers/host_profile_provider.dart`
- **Modificado:** `HostProfilePage` — converter de `StatelessWidget` para `ConsumerWidget`, remover dados hardcoded, consumir o notifier

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| `AsyncNotifier` em vez de `Notifier` | A busca de dados é assíncrona; `AsyncNotifier` lida nativamente com os estados loading/error/data |
| Duas chamadas sequenciais no notifier | `GET /hotel/me` precisa retornar o `hotel_id` antes de chamar `GET /uploads/hotels/:hotel_id/cover` |
| Sem modelo tipado | Seguir o padrão existente no projeto (`Map<String, dynamic>`) para manter consistência com `HotelService` |
| Falha de fotos não-fatal | Se o segundo endpoint falhar, exibir o perfil sem foto em vez de bloquear a tela com erro |

## Contratos de API

| Método | Rota | Auth | Response |
|--------|------|------|----------|
| GET | `/hotel/me` | ✅ Bearer | `{ data: { hotel_id, nome_hotel, email, telefone, descricao, ... } }` |
| GET | `/uploads/hotels/:hotel_id/cover` | ❌ | `{ fotos: [{ id, orientacao, url, criado_em }] }` |

## Modelos de Dados
Nenhuma tabela criada ou alterada. Os dados trafegam como `Map<String, dynamic>` seguindo o padrão do projeto. O estado do notifier guarda:

```
HostProfileState {
  hotel: Map<String, dynamic>        // resposta de GET /hotel/me
  fotos: List<Map<String, dynamic>>  // resposta de GET /uploads/.../cover
}
```

## Dependências

**Bibliotecas:**
- [x] `flutter_riverpod` — já no projeto, gerenciamento de estado
- [x] `dio` — já no projeto, via `dioProvider`

**Outras features:**
- [x] P0 — `dioProvider` com interceptor Bearer (concluído)
- [x] P2-A — login do host com persistência de token no `authProvider` (concluído, disponível na main)

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| `GET /hotel/me` retorna 401 (token expirado) | O `dioProvider` já faz refresh automático — tratado pela infra existente |
| Hotel sem fotos de capa cadastradas | Tratar lista vazia e exibir avatar padrão (já suportado pelo `ProfileHeader`) |
| Falha no `GET /uploads/.../cover` após sucesso do `GET /hotel/me` | Tratar como não-fatal — exibir perfil sem foto em vez de tela de erro |
