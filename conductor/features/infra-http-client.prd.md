# PRD — infra-http-client

## Contexto

O app ReservAqui possui um cliente HTTP (`lib/utils/Usuario.dart`) e um roteador (`lib/core/router/app_router.dart`) que foram scaffoldados mas nunca conectados ao backend real. A base URL aponta para um caminho incorreto, os tokens de autenticação não são persistidos entre sessões e o roteamento depende de um mock hardcoded (`MockAuth`) que ignora o estado real do usuário.

Esta feature estabelece a camada de infraestrutura que todas as demais features do app dependem.

## Problema

O app não consegue fazer chamadas autenticadas reais ao backend porque:

1. A `baseUrl` está em `http://localhost:3000/api`, mas o backend serve todos os endpoints sob `/api/v1`.
2. Os tokens (`accessToken`, `refreshToken`) são armazenados apenas em memória — ao reiniciar o app, o usuário perde a sessão.
3. O interceptor de auto-refresh não distingue entre role `guest` (usa `POST /usuarios/refresh`) e role `host` (usa `POST /hotel/refresh`), resultando em falha de refresh para anfitriões.
4. O `app_router.dart` usa `MockAuth.isLoggedIn` e `MockAuth.currentUserRole` hardcoded —  qualquer proteção de rota ou redirect por perfil é fictícia.
5. O `main.dart` ainda é o app counter padrão do Flutter — o ProviderScope (Riverpod) e o GoRouter não estão conectados.

## Público-alvo

Todos os usuários do ReservAqui (hóspedes e anfitriões) — indiretamente, pois esta é uma feature de infraestrutura que habilita todas as demais. Diretamente, afeta a experiência de login persistente e de session management.

## Requisitos Funcionais

1. O app deve inicializar com `ProviderScope` e rotear via `GoRouter` usando o `routerProvider`.
2. Ao fazer login como hóspede ou anfitrião, os tokens devem ser salvos com `shared_preferences`.
3. Ao reiniciar o app, a sessão deve ser restaurada automaticamente se tokens válidos existirem.
4. O cliente HTTP deve injetar `Authorization: Bearer <token>` em todas as requisições autenticadas.
5. Ao receber 401, o app deve executar o refresh no endpoint correto (`/usuarios/refresh` para hóspede, `/hotel/refresh` para anfitrião).
6. Requisições pendentes durante o refresh devem ser enfileiradas e reexecutadas com o novo token.
7. Se o refresh falhar, todos os tokens devem ser limpos e o usuário redirecionado para `/auth/login`.
8. O roteador deve proteger rotas autenticadas e redirecionar usuários não autenticados para `/auth`.
9. Após login, o redirect deve ser para `/home` (tanto hóspede quanto anfitrião).

## Requisitos Não-Funcionais

- [x] Segurança: tokens nunca expostos em logs; `shared_preferences` usa chave segura.
- [x] Resiliência: falha de rede no refresh não crashar o app — exibir estado de sessão expirada.
- [x] Responsividade: funcionar em mobile (iOS/Android) e web (comportamento de shared_preferences difere em web, mas a API é a mesma).
- [x] Sem acoplamento circular: `AuthNotifier` não pode importar `DioClient`; `DioClient` depende de `AuthNotifier`.

## Critérios de Aceitação

- Dado que o usuário faz login com sucesso, quando o app é reiniciado, então o usuário continua autenticado sem precisar fazer login novamente.
- Dado que o usuário está autenticado e o accessToken expira, quando uma chamada retorna 401, então o app executa refresh automaticamente e reexecuta a chamada original sem intervenção do usuário.
- Dado que o refresh falha (refreshToken expirado), quando o app recebe erro no refresh, então todos os tokens são limpos e o usuário é redirecionado para `/auth/login`.
- Dado que o usuário não está autenticado, quando tenta acessar uma rota protegida, então é redirecionado para `/auth`.
- Dado que um anfitrião está autenticado, quando o accessToken expira, então o refresh usa `POST /hotel/refresh` (não `/usuarios/refresh`).

## Fora de Escopo

- Integração real com os endpoints de login/signup nas páginas (isso é P1+).
- Google OAuth (fase futura).
- Implementação de telas de login ou signup (já existem como stubs).
- Endpoints além de auth/refresh/logout no cliente HTTP.
