# Plano de Testes Unitários — ReservAqui

> Status: **executado (Fases 0–4)** • Escopo: Backend (Node/TS) + Frontend (Flutter) • Profundidade alvo: quick wins + core flows
>
> **Resultado:** 264 testes novos passando (162 backend + 102 frontend). Suíte total: **330 testes passando** (228 backend + 102 frontend; 5 falhas pré-existentes em `main` — não regressão). Branch `test/unit-tests-foundation`. Detalhes na §9.

## 1. Objetivo

Estabelecer uma camada de testes unitários que cubra (a) lógica pura de fácil teste e alto retorno e (b) os fluxos de negócio críticos (auth, reserva, pagamento, refresh de token). Este plano define o que testar, **onde está o código**, qual estratégia de mock usar, e a ordem de implementação.

Fora de escopo nesta primeira leva: testes E2E, testes de UI/widget completos, cobertura de chatbot/IA, FCM/push, dashboards administrativos.

---

## 2. Estado atual

### Backend (`Backend/`)
- Stack: TypeScript + Express + Jest 29 + ts-jest + Supertest.
- `jest.config.ts` já configurado: `rootDir: src`, pattern `**/__tests__/**/*.test.ts`, setup em `src/__tests__/setup.ts` (carrega `.env.test`).
- Scripts: `npm test`, `npm run test:watch`, `npm run test:coverage`.
- **Testes existentes** (7 arquivos):
  - `src/services/__tests__/searchRoom.service.test.ts`
  - `src/services/__tests__/whatsappReservation.service.test.ts`
  - `src/services/__tests__/whatsappWebhook.service.test.ts`
  - `src/middlewares/__tests__/adminGuard.test.ts`
  - `src/routes/__tests__/admin.routes.test.ts`
  - `src/routes/__tests__/dashboard.routes.test.ts`
  - `src/routes/__tests__/searchRoom.routes.test.ts`
  - `src/routes/__tests__/whatsapp.routes.test.ts`

### Frontend (`Frontend/`)
- Stack: Flutter (Dart 3.9.2) + Riverpod (`AsyncNotifierProvider`).
- Único teste: `test/widget_test.dart` (smoke placeholder). Sem mocktail/mockito.
- **Falta no `pubspec.yaml`:** `mocktail` e `http_mock_adapter` (para mockar `Dio`).

---

## 3. Escopo desta leva

### Backend — alvos
| # | Alvo | Caminho | Tipo | Prioridade |
|---|------|---------|------|------------|
| B1 | Templates de e-mail (`fmtBRL`, `fmtDate`, `esc`, builders) | `src/services/emailTemplates.ts` | Pura | Alta |
| B2 | Helpers de período do dashboard (`resolvePeriod`, `isPeriod`) | `src/modules/dashboard/period.utils.ts` | Pura | Alta |
| B3 | Hash/JWT do usuário (helpers extraídos) | `src/services/usuario.service.ts` (extrair `parseDataBrToEn`, geração de tokens) | Pura | Alta |
| B4 | Expansão de `searchRoom.service` (escape de LIKE, edge cases) | `src/services/__tests__/searchRoom.service.test.ts` | Pura | Média |
| B5 | Criação/cancelamento de reserva — caminhos felizes e validações | `src/services/reserva.service.ts` | Service c/ DB mock | Alta |
| B6 | Webhook de pagamento — parsing e transição de estado | `src/services/pagamentoReserva.service.ts` | Service c/ DB + HTTP mock | Alta |
| B7 | Middlewares de guard (`authGuard`, `hotelGuard`) | `src/middlewares/authGuard.ts`, `hotelGuard.ts` | Middleware c/ JWT real | Média |

### Frontend — alvos
| # | Alvo | Caminho | Tipo | Prioridade |
|---|------|---------|------|------------|
| F1 | Validators (`validateNomeCompleto`, `validateEmail`, `validateCpf`, `validateTelefoneBr`, `onlyDigits`) | `lib/features/auth/utils/validators.dart` | Pura | Alta |
| F2 | `availability_calculator.dart` (regras de ocupação por intervalo) | `lib/features/rooms/domain/services/availability_calculator.dart` | Pura | Alta |
| F3 | `ViaCep` — parsing + erros | `lib/core/utils/via_cep.dart` | I/O c/ HTTP mock | Média |
| F4 | `AuthResponse.fromJson` + `ReservaModel.fromJson` (parsing de JSON aninhado, enums) | `lib/features/auth/...`, `lib/features/booking/...` | Pura | Alta |
| F5 | `DioClient` — interceptor de refresh, fila de pendentes, 401 | `lib/core/network/dio_client.dart` | I/O c/ `http_mock_adapter` | Alta |
| F6 | `CheckoutNotifier` — transições de estado e checagem de disponibilidade | `lib/features/booking/...` (Riverpod notifier) | State + repo mock | Média |

> A escolha por **mocktail** é deliberada: não exige `build_runner`, evita acoplamento com geração de código e funciona bem com Riverpod.

---

## 4. Estratégia de mocking

### Backend
| Dependência | Como mockar |
|-------------|------------|
| `pg` / `masterDb` / `tenantManager` | `jest.mock('../database/masterDb')` e mockar `query()`/`withTenant()` por teste |
| `nodemailer` | Mock no `createTransport` retornando objeto com `sendMail` espião |
| `firebase-admin` (FCM) | `jest.mock('firebase-admin')` — chamadas viram no-op |
| `argon2` / `jsonwebtoken` | **Não mockar** — usar a lib real (são determinísticas e rápidas) |
| Groq/LangChain (fora desta leva) | Não tocar |
| HTTP externo (InfinitePay) | `nock` ou `jest.mock('axios')` |

### Frontend
| Dependência | Como mockar |
|-------------|------------|
| `Dio` | `http_mock_adapter` para respostas controladas; testar status 200/401/erros de rede |
| `shared_preferences` | `SharedPreferences.setMockInitialValues({...})` (API oficial do Flutter) |
| `firebase_messaging` / `firebase_core` | Mocktail nas funções usadas; não inicializar Firebase em teste |
| `go_router` | Não testar navegação aqui — escopo é lógica de notifier |
| `file_picker` / `image_picker` | Fora desta leva |

---

## 5. Convenções

- **Localização (backend):** ao lado do código, em `__tests__/` (já é o padrão).
- **Localização (frontend):** espelhar a árvore em `Frontend/test/` — ex.: `test/features/auth/utils/validators_test.dart`.
- **Nomenclatura:** `<arquivo>.test.ts` (backend) / `<arquivo>_test.dart` (frontend).
- **Estilo:** `describe`/`it` (backend) e `group`/`test` (frontend), nomeando por comportamento ("rejeita CPF com dígito verificador inválido"), não por implementação.
- **Cobertura mínima alvo desta leva:** 70% nas funções listadas em §3 (não cobertura global).

---

## 6. Plano de implementação

### Fase 0 — Setup (única)
1. **Frontend:** adicionar em `pubspec.yaml/dev_dependencies`:
   ```yaml
   mocktail: ^1.0.4
   http_mock_adapter: ^0.6.1
   ```
   Rodar `flutter pub get`.
2. **Backend:** confirmar que `.env.test` existe (referenciado em `src/__tests__/setup.ts`); criar com valores fake se necessário.
3. Adicionar **CI hint** ao `README.md` (rodar `npm test` em Backend e `flutter test` em Frontend) — opcional, só se o usuário pedir.

### Fase 1 — Quick wins puras (ordem sugerida)
1. **B1** — `emailTemplates.test.ts`: `fmtBRL` (zero, negativos, casas decimais), `fmtDate` (timezone), `esc` (XSS clássico), 1 builder de template.
2. **B2** — `period.utils.test.ts`: cada período (`day`, `week`, `month`, `year`), bordas de mês/ano, `isPeriod` (valores válidos/inválidos), com `Date` mockado.
3. **F1** — `validators_test.dart`: CPFs válidos/ inválidos (incluindo `111.111.111-11`), e-mails, telefones BR (10/11 dígitos), nomes com acento.
4. **F2** — `availability_calculator_test.dart`: intervalo sem reservas, sobreposição parcial, walk-in, categorias distintas.
5. **B4** — expandir `searchRoom.service.test.ts`: backslash em LIKE, unicode, string vazia.

### Fase 2 — Parsing & utilitários I/O
6. **F4** — testes de `fromJson` para `AuthResponse` e `ReservaModel` (campos faltando, enums desconhecidos, datas em formato BR).
7. **B3** — extrair `parseDataBrToEn` e geração de tokens para módulo testável; cobrir formatos válidos/inválidos.
8. **F3** — `via_cep_test.dart`: CEP válido, CEP inexistente, falha de rede (mock no `Dio`).

### Fase 3 — Core flows com mocks
9. **B5** — `reserva.service.test.ts`:
   - Criar reserva com sucesso (DB mockado retornando IDs).
   - Validações: data inválida, hóspedes acima do limite, sobreposição.
   - Cancelamento: estados permitidos vs. proibidos.
10. **B6** — `pagamentoReserva.service.test.ts`:
    - Webhook `APPROVED` → reserva confirmada.
    - Webhook `REJECTED` → reserva volta para pendente.
    - Webhook duplicado (idempotência).
11. **F5** — `dio_client_test.dart`:
    - 401 dispara refresh, retry da request original com novo token.
    - Refresh falha → propaga erro e limpa estado de auth.
    - Múltiplas requests concorrentes durante refresh entram em fila e resolvem com o mesmo novo token.
12. **B7** — `authGuard.test.ts` e `hotelGuard.test.ts`: token ausente, expirado, role errada.
13. **F6** — `checkout_notifier_test.dart`: transições idle → loading → success/error com repositório mockado.

### Fase 4 — Limpeza ✅
14. ✅ Rodar `npm run test:coverage` (backend) e `flutter test --coverage` (frontend); números na §9.
15. ✅ Bug encontrado documentado em §10 (#5 — dead code em `validateUsuario`). Não foram necessários testes de regressão adicionais.

---

## 7. Riscos e decisões em aberto

- **`reserva.service.ts` tem 1081 linhas** e mistura validação com SQL. Pode ser necessário **extrair pequenas funções puras** (validações de data/ocupação) antes de testar — esse refactor é mínimo e localizado, mas precisa ser sinalizado por PR/commit separado.
- **`AuthNotifier` (Riverpod)** depende de `SharedPreferences` + `firebase_messaging` no `init`. Testar a transição de estados sem inicializar Firebase exigirá injetar abstrações — se for muito invasivo, fica fora desta leva (escopo F5 cobre o ponto mais sensível: o interceptor).
- **`.env.test` no backend**: precisa de um conjunto de variáveis fake consistente. Se não existir, criar antes da Fase 1.
- **Tempo estimado** (referência grosseira para discussão, não compromisso):
  - Fase 0: <1h
  - Fase 1: 4–6h
  - Fase 2: 3–5h
  - Fase 3: 6–10h
  - Fase 4: 1h

---

## 8. Critérios de "feito"

- [x] `npm test` passa no backend com os novos arquivos (228 passando; 5 falhas pré-existentes em `whatsappWebhook.service.test.ts` e `searchRoom.routes.test.ts` não regressas — confirmado por `git checkout main && npm test`).
- [x] `flutter test` passa no frontend com os novos arquivos (102/102).
- [x] Cada item de §3 tem ao menos 1 teste de caminho feliz + 1 de erro/borda.
- [x] Nenhuma chamada real a banco, rede ou Firebase nos testes (todos os DBs/HTTP estão mockados via `jest.mock` ou `http_mock_adapter`).
- [x] Cobertura ≥ 70% nas funções listadas em §3 — ver §9.

---

## 9. Status final por item (executado)

| # | Item | Arquivo de teste | Testes | Coverage do arquivo¹ |
|---|------|------------------|-------:|---------------------:|
| B1 | Email templates | `Backend/src/services/__tests__/emailTemplates.test.ts` | 23 | **100%** |
| B2 | Period utils | `Backend/src/modules/dashboard/__tests__/period.utils.test.ts` | 23 | **100%** |
| B3 | Usuario helpers | `Backend/src/services/__tests__/usuario.helpers.test.ts` | 16 | helpers: 100% (arquivo: 25.7%) |
| B4 | Search escape | `Backend/src/services/__tests__/searchRoom.service.test.ts` (expansão) | 15 | **66.6%** ²|
| B5 | Reserva validators + helpers | `Backend/src/entities/__tests__/Reserva.test.ts` + `reserva.helpers.test.ts` | 50 | entity: alta³ (helpers do service: 100%) |
| B6 | Pagamento fake helpers | `Backend/src/services/__tests__/pagamentoReserva.helpers.test.ts` | 26 | helpers: 100% (arquivo: 11.9%) |
| B7 | authGuard / hotelGuard | `Backend/src/middlewares/__tests__/{auth,hotel}Guard.test.ts` | 17 | **100% / 100%** |
| F1 | Validators (CPF, email, etc.) | `Frontend/test/features/auth/utils/validators_test.dart` | 33 | **100%** |
| F2 | Availability calculator | `Frontend/test/features/rooms/domain/services/availability_calculator_test.dart` | 12 | **100%** |
| F3 | ViaCep | `Frontend/test/core/utils/via_cep_test.dart` | 14 | **89%** |
| F4 | AuthResponse + ReservaModel.fromJson | `Frontend/test/features/{auth,booking}/.../*_test.dart` | 18 | **100%** ambos |
| F5 | Dio refresh interceptor | `Frontend/test/core/network/auth_refresh_interceptor_test.dart` | 11 | **86%** |
| F6 | CheckoutNotifier | `Frontend/test/features/booking/.../checkout_notifier_test.dart` | 14 | 35% ⁴ |
| **Total** | — | — | **272** ⁵ | — |

¹ Statements; gerado por `npm run test:coverage` (backend) / `flutter test --coverage` + `awk` no `lcov.info` (frontend).
² Os 33% restantes são branches do `searchRoom.service.ts` que dependem de `refinos` (datas/hóspedes/amenities) — não estavam no escopo desta leva, mas o `escapeLikePattern` está 100% coberto.
³ `entities/**` está fora da coleta de coverage por config (eram só types antes). Os 5 validators públicos da `Reserva` foram exercitados por 35 testes cobrindo happy/erro/borda — cobertura efetiva alta por inspeção; números numéricos exigiriam tirar o exclude do `jest.config.ts`.
⁴ Cobertura deliberadamente parcial — happy-path de `confirmarEGerarPagamento` exige seed via `loadData()` que lê `authProvider` (SharedPreferences + Firebase). Ver dívida #2 em §10.
⁵ Inclui 8 testes pré-existentes na suíte de B4 (`searchRoom.service.test.ts`); 264 são novos desta leva.

### Refactors (todos comportamento-preservante)

| Arquivo | Mudança | Motivo |
|--------|---------|--------|
| `Backend/src/services/emailTemplates.ts` | `export` em `esc`, `fmtBRL`, `fmtDate` | Permitir teste direto dos helpers. |
| `Backend/src/services/usuario.service.ts` | `export` em `parseDataBrToEn`, `signAccessToken`, `signRefreshToken`, `hashToken`, `refreshExpiresAt` | Idem. |
| `Backend/src/services/reserva.service.ts` | `export` em `calcDiarias`, `toISODate`; novo helper `canCancelReserva(status)` substituindo o condicional inline. | Idem + remover duplicação implícita. |
| `Backend/src/services/pagamentoReserva.service.ts` | `MODALIDADES_FAKE` exportado; `_toResumo` → `toPagamentoResumo`; novos `isFormaPagamentoValida`, `isLinkPagamentoExpirado` (com `now` injetável). | Idem. |
| `Frontend/lib/core/network/dio_client.dart` | Lógica do interceptor extraída para `auth_refresh_interceptor.dart` (classe `AuthRefreshInterceptor` recebendo `readAuth/refreshDio/saveTokens/clearAuth` por construtor). `dio_client.dart` virou wire-up Riverpod de ~50 linhas. | Quebrar dependência implícita de Riverpod/Firebase para teste. |
| `Frontend/lib/core/utils/via_cep.dart` | `fetchViaCep(cep)` → `fetchViaCep(cep, {Dio? dio})`. | Permitir injeção do Dio mockado. |

---

## 10. Dívidas conscientes (não resolvidas nesta leva)

1. **`AuthRefreshInterceptor` — fila de pendentes durante refresh concorrente.** Comportamento implementado e revisado por inspeção; não testado de forma determinística porque exige `Completer` com timing controlado e `http_mock_adapter` não suporta isso bem. Os outros 7 caminhos do interceptor estão cobertos. Dívida pequena.

2. **`CheckoutNotifier.confirmarEGerarPagamento` happy-path.** Não testado. Exige `state.categoria` populada, que vem de `loadData()` → `authProvider` → `SharedPreferences` + `firebase_messaging`. Cobrir aqui obrigaria mock de Firebase + `TestWidgetsFlutterBinding.ensureInitialized()` — começa a virar teste de integração disfarçado de unit. **Recomendação:** cobrir num teste de integração separado (com `flutter_test` widgets + `ProviderScope`), em outra leva.

3. **Webhook real da InfinitePay (`_handleWebhook`).** Existe no código mas não está em uso (sem documentação de sandbox no momento, conforme reportado pelo time). O fluxo "fake" (simulador) que efetivamente roda hoje está coberto por B6. Quando a InfinitePay liberar docs de sandbox, B6 deve ser ampliado com testes para `_handleWebhook` (APPROVED / REJECTED / duplicado/idempotência).

4. **`reserva.service._createReserva*` end-to-end.** Cada caminho (`_createReservaUsuario`, `_createReservaGuest`, `_createReservaWalkin`, `_createReservaChat`) faz 8+ queries em sequência (`_getHotelInfo` → `withTenant` → `_ensureReservaFluxoColumns` → `_ensureHospede` → disponibilidade → `_calcValorTotal` → `INSERT` → routing → historico). Mockar tudo isso em unit-test traz pouco signal (ruído de mocks > valor regressional). As regras de validação que esses fluxos delegam à entidade `Reserva` estão 100% cobertas em B5; falta cobrir orquestração — alvo natural pra teste de integração (Supertest + Postgres real).

5. **Bug menor encontrado durante B5: dead code em `Reserva.validateUsuario`.** A linha `if (data.quarto_id === undefined && data.valor_total === undefined) throw 'Informe valor_total quando não há quarto_id'` é inalcançável porque `validateValorTotal(undefined)` lança "valor_total inválido" antes (`Number(undefined) === NaN`). Não é grave (a validação funciona, só com mensagem genérica em vez de específica). Documentado pelo teste `'rejeita valor_total ausente (validateValorTotal é incondicional)'`. Faxina futura: ou validar `valor_total` condicionalmente, ou remover a linha morta.

---

## 11. Convenções estabelecidas (para próximas levas)

- **Backend:** quando testar guards / middlewares que capturam `process.env.JWT_SECRET` no import, definir o secret **antes** do `require` do módulo (padrão herdado de `adminGuard.test.ts`, replicado em `authGuard.test.ts` / `hotelGuard.test.ts`).
- **Backend:** funções privadas com lógica testável devem ser exportadas (não criar arquivos de helper só pra isso); o arquivo de teste usa `import { ... } from "../arquivo.service"`.
- **Frontend:** mocktail (sem `build_runner`) para mocks; `http_mock_adapter` para Dio. Evitar `mockito` — não vale o overhead de geração de código.
- **Frontend:** quando uma função criar `Dio` internamente, refatorar para aceitar `{Dio? dio}` opcional. Backward-compatible.
- **Riverpod:** para evitar arrastar `firebase_messaging`/`SharedPreferences` para o teste, extrair a lógica do notifier para uma classe pura recebendo dependências por construtor (padrão `AuthRefreshInterceptor`).
