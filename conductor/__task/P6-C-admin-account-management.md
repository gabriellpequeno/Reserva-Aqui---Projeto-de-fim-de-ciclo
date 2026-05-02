# P6-C — admin-account-management
> Derivada de: Admin Profile Page (existente) — item "Clientes" sem destino + necessidade de gestão de cadastros

## Objetivo
Implementar a tela de gerenciamento de contas do admin, acessível via "Clientes" na `AdminProfilePage`. O admin deve conseguir visualizar, buscar e ajustar cadastros de usuários (hóspedes) e hotéis (hosts) em uma única tela — design semelhante à `MyRoomsPage` mas com cards de usuários e hotéis.

## Prioridade
**Média** — necessária para demonstrar o papel do admin na apresentação.

---

## Pré-condições (o que já existe, não refazer)

- `admin_profile_page.dart` — menu "Clientes" com `onTap: () {}` (sem destino)
- `my_rooms_page.dart` — referência de design (lista com busca + cards com status)
- Rota `/admin/dashboard` já registrada no `app_router.dart`
- Rota `/admin/accounts` **não existe** — será criada nesta task

---

## O que precisa ser feito

### 1. Criar a página `admin_account_management_page.dart`
Caminho: `lib/features/profile/presentation/pages/admin_account_management_page.dart`

#### Layout (inspirado em `MyRoomsPage`)
- [ ] `AppBar` com título "Gerenciamento de Contas" e botão voltar
- [ ] Campo de busca no topo (filtra por nome ou e-mail)
- [ ] `TabBar` com duas abas: **Usuários** | **Hotéis**
- [ ] Lista de cards por aba

#### Card de Usuário
- [ ] Avatar / foto de perfil (ou initials fallback)
- [ ] Nome completo
- [ ] E-mail
- [ ] Status (ativo / suspenso) — chip colorido
- [ ] Botão de ação: "Editar" → abre bottom sheet ou navega para edição

#### Card de Hotel
- [ ] Imagem de capa (thumbnail)
- [ ] Nome do hotel
- [ ] E-mail / responsável
- [ ] Status (ativo / inativo) — chip colorido
- [ ] Botão de ação: "Editar"

### 2. Conectar à `AdminProfilePage`
- [ ] Substituir `onTap: () {}` do item "Clientes" por `context.push('/admin/accounts')`

### 3. Registrar rota no `app_router.dart`
- [ ] Adicionar `GoRoute` para `/admin/accounts` apontando para `AdminAccountManagementPage`

### 4. Integração com backend (se endpoint disponível)
- [ ] `GET /admin/users` — lista de hóspedes
- [ ] `GET /admin/hotels` — lista de hotéis
- [ ] `PATCH /admin/users/:id` — ajustar status do usuário
- [ ] `PATCH /admin/hotels/:id` — ajustar status do hotel
- [ ] Se endpoints não estiverem prontos: usar dados mock para a demonstração

### 5. Validação
- [ ] Busca filtra em tempo real por nome e e-mail
- [ ] Troca de aba mantém estado da busca
- [ ] Loading e estado vazio tratados
- [ ] Dark Mode aplicado (tokens semânticos)

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `lib/features/profile/presentation/pages/admin_account_management_page.dart` | **Criar** |
| `lib/core/router/app_router.dart` | Adicionar rota `/admin/accounts` |
| `lib/features/profile/presentation/pages/admin_profile_page.dart` | Conectar `onTap` do item "Clientes" |

---

## Referência de design
- `my_rooms_page.dart` — estrutura de busca + lista de cards com status e ações

## Dependências
- **Desbloqueia:** visualização completa do fluxo admin na demonstração
- **Depende de:** endpoints admin (parcialmente — pode usar mock se não estiver pronto)
