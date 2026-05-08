# BUG-3 — room_details_page - Título, Disponibilidade e Favoritar

## Tela
`lib/features/rooms/presentation/pages/room_details_page.dart`

## Prioridade
**Alta** — bug de disponibilidade bloqueia o fluxo de reserva

## Branch sugerida
`fix/room-details-fixes`

---

## Bugs

### 1. Título da tela

- [ ] **Estrutura do título** — o header da tela deve exibir:
  ```
  Nome do Hotel         (maior, peso normal ou bold)
  Categoria do quarto   (menor, peso leve ou secondary color)
  ```
  - Usar `Column` no título do `AppBar` ou no topo do scroll
  - "Categoria do quarto" deve ser visualmente menor que o nome do hotel

### 2. Lógica de disponibilidade

**Comportamento atual (incorreto):**
- Tela de detalhes do quarto marca o quarto como disponível
- Ao tentar reservar, a tela de reserva retorna indisponível

**Regra correta:**
- Um quarto deve ser marcado como **disponível** apenas se **pelo menos 1 unidade** desse quarto estiver disponível em **todos os dias** do intervalo de datas selecionado
- Se em **qualquer dia** dentro do intervalo todas as unidades do quarto estiverem ocupadas → retornar indisponível
- Se nenhuma unidade estiver livre em algum dia do período → exibir como indisponível desde a tela de detalhes

**O que verificar:**
- [ ] Confirmar qual endpoint é chamado para verificar disponibilidade na tela de detalhes (`GET /:hotel_id/disponibilidade` ou equivalente)
- [ ] Confirmar o payload enviado — datas de checkin/checkout estão sendo passadas corretamente?
- [ ] Confirmar que a resposta considera unidades individuais (não apenas a categoria)
- [ ] Se a lógica no backend estiver correta, verificar se o front está interpretando a resposta errada (ex: tratando `disponivel: false` como `true`)
- [ ] Verificar a mesma lógica na `checkout_page` — se estiver duplicada, unificar em um único ponto de verificação
- [ ] Após corrigir, garantir que a tela de detalhes e a tela de reserva estão em sincronia: se está disponível em um, está disponível no outro

### 3. Botão de favoritar

- [ ] **Adicionar botão de favoritar** no lado oposto ao botão de voltar (ex: botão voltar no canto superior esquerdo, favoritar no canto superior direito)
- [ ] **Lógica do botão:**
  - Ao carregar a tela, verificar se o quarto/hotel já está favoritado pelo usuário autenticado
  - Ícone preenchido (`Icons.favorite`) se favoritado, vazio (`Icons.favorite_border`) se não
  - Ao tocar: chamar `POST /usuarios/favoritos` (adicionar) ou `DELETE /usuarios/favoritos/:hotel_id` (remover)
  - Atualizar estado local imediatamente (optimistic update) e tratar erro revertendo
  - Se usuário não estiver autenticado, redirecionar para login antes de favoritar

---

## Endpoints usados

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/:hotel_id/disponibilidade` | ❌ | Verificar disponibilidade por datas |
| POST | `/usuarios/favoritos` | ✅ | Adicionar favorito |
| DELETE | `/usuarios/favoritos/:hotel_id` | ✅ | Remover favorito |

---

## Dependências
- Bug de disponibilidade pode ter origem no backend — se a lógica de unidades estiver errada no endpoint, abrir task EXT antes de corrigir apenas o frontend
- Botão de favoritar segue o mesmo padrão já mapeado na task P4-D (verificar se já foi implementado parcialmente)

## Observações
- Testar o fluxo completo: detalhes do quarto → reservar → confirmar que disponibilidade é consistente nas duas telas
- O botão favoritar deve funcionar offline visualmente (optimistic), mas só persistir com conexão
