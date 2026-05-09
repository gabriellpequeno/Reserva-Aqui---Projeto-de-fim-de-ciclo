# Plan — room-details-fixes

> Derivado de: conductor/specs/room-details-fixes.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Criar branch `fix/room-details-fixes` a partir de `main` — pulado a pedido do usuário; trabalhado direto na main
- [x] Confirmar que `favoritesProvider` está acessível globalmente — `ProviderScope` envolve a app em `main.dart:22`

---

## Backend [EM ANDAMENTO]

- [x] Auditar a resposta do endpoint `GET /hotel/{hotelId}/disponibilidade` — frontend parseia corretamente em ambas as telas; se inconsistência existir, origem é no backend (lógica de unidades por dia)
- [ ] Se o backend retornar lógica incorreta de unidades, abrir task separada antes de prosseguir com o frontend

---

## Frontend [CONCLUÍDO]

### 1. Título hierárquico

- [x] Em `room_details_page.dart`, localizar o início do conteúdo scrollável (após o carrossel de imagens)
- [x] Adicionar `Column` com dois `Text`: nome do hotel (24px bold) e categoria do quarto (`room!.title`, 14px w300, `onSurfaceVariant`)

### 2. Lógica de disponibilidade

- [x] Em `availability_checker.dart`, auditar o parsing: `_isAvailable = disponivel` — sem inversão, correto
- [x] Confirmar que `onDatesChanged` propaga datas corretas ao parent — ✓ callback disparado após cada `setState`
- [x] Em `checkout_page.dart`, auditar `verificarDisponibilidade()`: usa `booking_service.fetchDisponibilidade()` com parsing idêntico — sem divergência
- [x] Nenhuma extração necessária — lógica já consistente entre as duas telas

### 3. Botão de favoritar

- [x] `room_details_page.dart` já era `ConsumerStatefulWidget` — sem conversão necessária
- [x] Adicionar `ref.watch(favoritesProvider)` no `build`
- [x] `_buildCircularButton` atualizado com parâmetro `iconColor` opcional
- [x] Botão adicionado no Stack (`top: 50, right: 20`) com ícone condicional `favorite`/`favorite_border` + cor `redAccent`/branco
- [x] `_toggleFavorite()` implementado: guard de auth → optimistic update via `_favoriteOptimistic` → rollback em catch → SnackBar de erro

---

## Validação [CONCLUÍDO]

- [x] Testar fluxo: selecionar datas indisponíveis na tela de detalhes → confirmar que "Indisponível" é exibido → navegar ao checkout → confirmar que checkout também exibe indisponível
- [x] Testar fluxo: selecionar datas disponíveis na tela de detalhes → confirmar que "Disponível" é exibido → navegar ao checkout → confirmar que checkout também exibe disponível e habilita "Finalizar Reserva"
- [x] Verificar header: nome do hotel visualmente maior que a categoria do quarto
- [x] Testar favoritar: usuário autenticado toca no botão → ícone muda imediatamente → API é chamada
- [x] Testar desfavoritar: usuário autenticado toca novamente → ícone reverte → API de remoção é chamada
- [x] Testar rollback: simular falha na API de favoritar → confirmar que o ícone reverte para o estado anterior
- [x] Testar acesso sem autenticação: tocar no botão de favoritar como guest → confirmar redirecionamento para login — bug encontrado e corrigido (rota `/auth/login` + `context.go`)
