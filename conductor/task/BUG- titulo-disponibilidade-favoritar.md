# BUG-3 — room_details_page - Título, Disponibilidade e Favoritar

## **Tela**

`lib/features/rooms/presentation/pages/room_details_page.dart`

## **Prioridade**

**Alta** — bug de disponibilidade bloqueia o fluxo de reserva

## **Branch sugerida**

`fix/room-details-fixes`

---

## **Bugs**

### **1. Título da tela**

- Estrutura do título — o header da tela deve exibir:

  ```
  Nome do Hotel         (maior, peso normal ou bold)
  Categoria do quarto   (menor, peso leve ou secondary color)
  
  ```
  * Usar `Column` no título do `AppBar` ou no topo do scroll
  * "Categoria do quarto" deve ser visualmente menor que o nome do hotel

**Status**: ✅ Implementado (room_details_page.dart:109-133)

**Validação manualneeded**: Verificar hierarquia visual real no dispositivo/emulador

### **2. Lógica de disponibilidade**

- Tema: disponibilidade inconsistente entre details e checkout
- Regra: um quarto é **disponível** apenas se **pelo menos 1 unidade** estiver disponível em **todos os dias** do intervalo

**Status**: ✅ Implementado (ambos usam endpoint GET /hotel/:hotelId/disponibilidade)

**Validação manualneeded**: Verificar se há inconsistency entre as duas telas

**Checklist**:
- [x] Endpoint correto chamado
- [x] Payload (datas) enviado corretamente
- [ ] Backend considera unidades individuais (não apenas categoria)
- [ ] Front interpreta resposta corretamente
- [ ] Details e checkout em sincronia

### **3. Botão de favoritar**

- Botão posicionado no canto superior direito (lado oposto ao voltar)
- Ao carregar: verificar se hotel já está favoritado
- Ícone: `Icons.favorite` (filled) vs `Icons.favorite_border` (vazio)
- Ao tocar: POST (adicionar) ou DELETE (remover) + optimistic update
- Usuário não autenticado → redirecionar para login

**Status**: ✅ Implementado (room_details_page.dart:235-243, 366-396)

**Validação manualneeded**: Testar fluxo completo

---

## **Endpoints usados**

| Método | Rota | Auth | Descrição |
| -- | -- | -- | -- |
| GET | `/:hotel_id/disponibilidade` | ❌ | Verificar disponibilidade por datas |
| POST | `/usuarios/favoritos` | ✅ | Adicionar favorito |
| DELETE | `/usuarios/favoritos/:hotel_id` | ✅ | Remover favorito |

---

## **Dependências**

* Bug de disponibilidade pode ter origem no backend — se a lógica de unidades estiver errada no endpoint, abrir task EXT antes de corrigir apenas o frontend
* Botão de favoritar segue o mesmo padrão já mapeado na task P4-D (verificar se já foi implementado parcialmente)

## **Observações**

* Testar o fluxo completo: detalhes do quarto → reservar → confirmar que disponibilidade é consistente nas duas telas
* O botão favoritar deve funcionar offline visualmente (optimistic), mas só persistir com conexão

---

## **Validação Manual**

### Teste 1 — Título da Tela
1. Navegar até `room_details_page` de um hotel
2. Verificar se título exibe: Hotel (maior, bold) + Categoria (menor, w300, secondary color)
3. ✅ Passou / ❌ Falhou

### Teste 2 — Disponibilidade
1. Em details: selecionar check-in/checkout → "Verificar disponibilidade"
2. Anotar resultado (Disponível/Indisponível)
3. Tocar "Reservar" → ir para checkout
4. Selecionar as mesmas datas
5. Comparar status nas duas telas
6. ✅ Consistente / ❌ Inconsistente

### Teste 3 — Favoritar
1. **Sem login**: tocar coração → deve redirecionar para /login
2. **Com login + não favoritado**: tocar coração → ícone muda para filled (vermelho)
3. Recarregar página → favorito persiste
4. **Com login + favoritado**: tocar coração → ícone muda para border
5. Recarregar → favorito removido
6. ✅ Passou / ❌ Falhou
