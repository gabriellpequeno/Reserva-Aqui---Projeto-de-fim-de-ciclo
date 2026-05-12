# Plano de Testes Unitários — ReservAqui

> Status: planejamento • Escopo: Backend (Node/TS) + Frontend (Flutter) • Profundidade alvo: quick wins + core flows

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

### Fase 4 — Limpeza
14. Rodar `npm run test:coverage` (backend) e `flutter test --coverage` (frontend); registrar números no `README.md` ou em `coverage.md`.
15. Adicionar 1 ou 2 casos de regressão se aparecerem bugs durante a escrita dos testes.

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

- [ ] `npm test` passa no backend com os novos arquivos.
- [ ] `flutter test` passa no frontend com os novos arquivos.
- [ ] Cada item de §3 tem ao menos 1 teste de caminho feliz + 1 de erro/borda.
- [ ] Nenhuma chamada real a banco, rede ou Firebase nos testes (verificável por inspeção dos mocks).
- [ ] Cobertura ≥ 70% nas funções listadas em §3 (medida pelos relatórios de cobertura).
