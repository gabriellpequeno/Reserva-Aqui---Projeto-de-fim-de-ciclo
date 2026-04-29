# Spec — Settings Page

## Referência
- **PRD:** conductor/features/settings-page.prd.md

## Abordagem Técnica
Integração puramente front-end em dois eixos:
- **Tema:** criar `ThemeNotifier` (`ChangeNotifier` + `shared_preferences`) e conectá-lo ao `MaterialApp` no `main.dart`
- **Notificações:** toggle persiste preferência local via `shared_preferences` — integração FCM adiada para quando Firebase Messaging for adicionado ao projeto
- **Legal:** navegação simples via `Navigator.push` para telas estáticas

## Componentes Afetados

### Backend
Nenhum — apenas consumo de endpoints existentes (FCM adiado).

### Frontend
- **Novo:** `ThemeNotifier` (`lib/core/theme/theme_notifier.dart`)
- **Modificado:** `main.dart` — conectar `ThemeNotifier` ao `MaterialApp`
- **Modificado:** `settings_page.dart` — conectar toggles ao `ThemeNotifier` e `shared_preferences`
- **Novo (opcional):** telas estáticas legais em `lib/features/profile/presentation/pages/` (`terms_page.dart`, `privacy_page.dart`, `about_page.dart`)

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| `ThemeNotifier` como `ChangeNotifier` | Consistente com o padrão já usado no projeto; `StateNotifier` adicionaria overhead desnecessário para um toggle simples |
| Preferência de notificação apenas local | Firebase Messaging não está no projeto; forçar integração FCM agora bloquearia a entrega |
| Telas legais estáticas | Conteúdo não muda com frequência; WebView é overkill para esta entrega |

## Contratos de API

Nenhum endpoint consumido nesta entrega.

> **Adiado — FCM:** quando `firebase_messaging` for integrado ao projeto, usar:
>
> | Método | Rota | Body | Response |
> |--------|------|------|----------|
> | POST | `/dispositivos-fcm/usuario` | `{ token: string }` | 200 OK |
> | DELETE | `/dispositivos-fcm/usuario` | `{ token: string }` | 200 OK |
> | POST | `/dispositivos-fcm/hotel` | `{ token: string }` | 200 OK |
> | DELETE | `/dispositivos-fcm/hotel` | `{ token: string }` | 200 OK |

## Modelos de Dados

Sem novos schemas de banco. Apenas chaves em `shared_preferences`:

```
theme_mode: string   ('light' | 'dark' | 'system')
notifications_enabled: bool
```

## Dependências

**Bibliotecas:**
- [x] `shared_preferences ^2.5.5` — já no pubspec

**Serviços externos:**
- nenhum nesta entrega

**Outras features:**
- [x] `AuthNotifier` (P0) — já implementado; necessário para detectar role guest/host na futura integração FCM

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `ThemeNotifier` não existia no projeto | Criar do zero seguindo padrão `ChangeNotifier`; risco baixo |
| Preferência de tema não propagar globalmente | Elevar `ThemeNotifier` ao `MaterialApp` via `ChangeNotifierProvider` antes de qualquer outra coisa |

## Questões Abertas

### ⚠️ Integração FCM — adiada
Quando `firebase_messaging` for adicionado ao projeto, o toggle de Notificações deve ser atualizado para:
1. Obter o FCM token via `FirebaseMessaging.instance.getToken()`
2. Registrar (`POST`) ou remover (`DELETE`) o token no endpoint correto conforme role (`AuthNotifier`)
3. Tratar token expirado/indisponível com fallback gracioso

### ⚠️ Desativação de conta — adiada
Ver `conductor/features/settings-page.prd.md` — bloqueada por comportamento indefinido da API em relação a reservas ativas.
