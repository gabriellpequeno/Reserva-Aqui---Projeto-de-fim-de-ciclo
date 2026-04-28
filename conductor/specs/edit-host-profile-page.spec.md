# Spec — edit-host-profile-page

## Referência
- **PRD:** conductor/features/edit-host-profile-page.prd.md

## Abordagem Técnica
Feature exclusivamente de frontend. Todos os endpoints necessários já existem no backend (`PATCH /hotel/me`, `POST /hotel/change-password`). A implementação estende o `HostProfileNotifier` criado na P3-B com dois novos métodos mutativos (`updateProfile`, `changePassword`) e converte a `EditHostProfilePage` de `StatefulWidget` com dados hardcoded para `ConsumerStatefulWidget` que consome o notifier para pré-população e delega o submit aos métodos do notifier. O endereço — hoje representado na UI como campo único multiline — é decomposto em 7 campos separados (`cep`, `uf`, `cidade`, `bairro`, `rua`, `numero`, `complemento`) para alinhar com o contrato real do backend, e o campo CEP integra com ViaCEP para auto-preencher os demais campos de endereço.

> **Nota de divergência de documentação:** o `swagger.yaml` lista `HotelUpdateRequest` sem o campo `email`, porém o service real (`Backend/src/services/anfitriao.service.ts:27-39`) aceita `email` como campo opcional no update, normaliza via `toLowerCase()` e retorna 409 em duplicata. Esta spec segue o comportamento real do service. Uma tarefa paralela deve atualizar o swagger.

## Componentes Afetados

### Backend
Nenhum. Todos os endpoints já existem e estão funcionais: `PATCH /hotel/me`, `POST /hotel/change-password`.

### Frontend
- **Modificado:** `HostProfileNotifier` (`lib/features/profile/presentation/providers/host_profile_provider.dart`) — adicionar métodos `updateProfile(Map<String, dynamic> diff)` e `changePassword(String senhaAtual, String novaSenha)`
- **Modificado:** `EditHostProfilePage` (`lib/features/profile/presentation/pages/edit_host_profile_page.dart`) — converter para `ConsumerStatefulWidget`, remover dados hardcoded do `initState`, pré-popular via `HostProfileNotifier`, delegar submit ao notifier, substituir campo único de endereço por 7 campos
- **Modificado (se ausentes):** `HotelService` (`lib/features/.../services/hotel_service.dart`) — adicionar métodos `updateMe(Map)` e `changePassword(...)` seguindo o padrão `getAutenticado`
- **Novo (helper):** lookup ViaCEP — função utilitária (ou método no notifier) que consome `https://viacep.com.br/ws/{cep}/json/` para preencher os demais campos de endereço

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| Estender o `HostProfileNotifier` existente em vez de criar um novo | O notifier já guarda o estado do hotel; atualizá-lo após o `PATCH` evita reload manual na `HostProfilePage` |
| Endereço decomposto em 7 campos (cep/uf/cidade/bairro/rua/numero/complemento) | Alinhar com o contrato real do backend; permite validação por campo e integração com ViaCEP |
| Integração com ViaCEP | Reduz fricção no preenchimento e diminui erros de digitação em UF/cidade |
| `changePassword` como método separado no notifier | Operação independente (endpoint, feedback, efeito colateral de invalidar tokens) — não deve ser acoplada ao update de dados |
| Submit unificado na UI com dispatch em sequência | Primeiro `PATCH /hotel/me`; só se OK, chama `POST /hotel/change-password`. Feedback separado evita confundir erros de cada operação |
| Enviar apenas campos alterados no `PATCH /hotel/me` | Usa diff contra o estado inicial — reduz payload e respeita a validação "Nenhum campo para atualizar" do service |
| Após `change-password`, forçar logout + redirect | Backend invalida todos os tokens após troca de senha (ver `Backend/database/scripts/init_master.sql:27`) — manter sessão ativa quebraria as próximas chamadas |
| CEP com máscara na UI, sem máscara no payload | O service faz `cep.replace(/\D/g, '')`; enviar já normalizado mantém consistência |
| Spec segue o service real, não o swagger | Swagger está desatualizado quanto ao campo `email` no update |

## Contratos de API

| Método | Rota | Auth | Body | Response |
|--------|------|------|------|----------|
| PATCH | `/hotel/me` | ✅ HotelBearer | `{ nome_hotel?, email?, telefone?, descricao?, cep?, uf?, cidade?, bairro?, rua?, numero?, complemento? }` — enviar somente campos alterados | `{ data: HotelPublico }` |
| POST | `/hotel/change-password` | ✅ HotelBearer | `{ senhaAtual, novaSenha }` | `{ message: "Senha alterada com sucesso. Faça login novamente." }` |
| GET | `https://viacep.com.br/ws/{cep}/json/` | ❌ público | — | `{ cep, logradouro, bairro, localidade, uf, ... }` ou `{ erro: true }` |

**Mapeamento de erros dos endpoints internos:**
- 400 — dados inválidos / senha fraca / "Nenhum campo para atualizar"
- 401 — senha atual incorreta (no change-password) / token inválido
- 404 — hotel não encontrado / inativo
- 409 — email já cadastrado em outro hotel

## Modelos de Dados

Nenhuma tabela criada ou alterada. A entidade `anfitriao` já contém todos os campos necessários. O estado do `HostProfileNotifier` é reaproveitado — apenas novos métodos mutativos:

```
HostProfileNotifier {
  state: HostProfileState { hotel: Map, fotos: List<Map> }

  // novos métodos
  updateProfile(Map<String, dynamic> diff): Future<void>
    // PATCH /hotel/me apenas com campos alterados
    // sucesso: state = state.copyWith(hotel: response.data)

  changePassword(String senhaAtual, String novaSenha): Future<void>
    // POST /hotel/change-password
    // sucesso: UI dispara logout + redirect
}
```

**Campos editáveis na UI** (alinhados com `UpdateAnfitriaoInput`):
- Dados gerais: `nome_hotel`, `email`, `telefone`, `descricao`
- Endereço decomposto: `cep`, `uf`, `cidade`, `bairro`, `rua`, `numero`, `complemento`

## Dependências

**Bibliotecas:**
- [x] `flutter_riverpod` — já no projeto, gerenciamento de estado
- [x] `dio` — já no projeto, via `dioProvider` com interceptor Bearer
- [ ] `http` ou reuso do `dio` — chamada pública ao ViaCEP (sem auth)

**Serviços externos:**
- [ ] `viacep.com.br` — lookup de endereço por CEP (gratuito, público)

**Outras features:**
- [x] P0 — `dioProvider` com interceptor Bearer (concluído)
- [x] P2-A — login do host com persistência de token no `authProvider` (concluído)
- [x] P3-B — `HostProfileNotifier` carregando dados do hotel (concluído — esta feature estende o notifier existente)

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Swagger desatualizado vs. comportamento real (ex: `email` no update) | Spec segue o service real; criar tarefa paralela para atualizar `swagger.yaml` |
| Email duplicado (409) ao trocar email | Tratar resposta e exibir "Este email já está em uso" sem limpar o campo |
| Senha atual incorreta (401 em `/hotel/change-password`) | Mensagem específica na seção de segurança, mantendo campos preenchidos |
| ViaCEP fora do ar ou CEP inválido | Fallback manual — usuário preenche os 6 campos diretamente; exibir "CEP não encontrado" sem bloquear o submit |
| ViaCEP com rate limit ou latência alta | Debounce ~500ms no input de CEP; timeout de 3s; não bloquear UI |
| Após `change-password` bem-sucedido, backend invalida todos os tokens | Fazer logout automático e redirecionar para login com snackbar informativo |
| Host envia payload sem nenhum campo alterado | Frontend faz diff contra estado inicial — se vazio, não chama API e exibe "Nenhuma alteração a salvar" |
| Usuário clica Salvar múltiplas vezes durante loading | Botão desabilitado + flag `isSubmitting` no state do widget |
| Update parcial OK + change-password falha (ou vice-versa) | Sequência: primeiro `PATCH /hotel/me`; só se OK, chama `POST /hotel/change-password`. Feedback separado para cada |
| CEP armazenado sem máscara no backend | UI exibe com máscara (00000-000), mas envia sem máscara alinhado ao normalizador do service |
