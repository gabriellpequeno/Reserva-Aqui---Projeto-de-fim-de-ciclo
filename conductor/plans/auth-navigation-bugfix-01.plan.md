# Plan — Auth Navigation Bugfix 01

> Arquivo: bugfix sobre navegação no fluxo de autenticação
> Status geral: [CONCLUÍDO]

---

## Contexto

Dois problemas no fluxo login → cadastro → voltar:

1. **Back button quebrado:** `LoginPage` usa `context.go('/auth')` para o botão "cadastre-se agora". O `go` substitui o stack de navegação inteiro, então ao abrir `UserOrHostPage` não há tela anterior no stack — o botão de voltar some ou não funciona.

2. **Seção de login redundante em `UserOrHostPage`:** o plan anterior adicionou um bloco "Entrar" com dois `PrimaryButton` ("Entrar como Hóspede" / "Entrar como Anfitrião"). O design correto é ter apenas um `TextButton` simples "Já tem conta? acesse agora" que retorna para a `LoginPage`.

---

## Bug 1 — `context.go` → `context.push` em `login_page.dart` [CONCLUÍDO]

**Arquivo:** `lib/features/auth/presentation/pages/login_page.dart`

**Causa:** `context.go('/auth')` descarta o stack — `UserOrHostPage` abre sem histórico, impossibilitando o back.

**Correção:** trocar por `context.push('/auth')` — empilha `UserOrHostPage` sobre `LoginPage`, back funciona naturalmente.

- [x] Substituir `context.go('/auth')` por `context.push('/auth')` no `onPressed` do botão "cadastre-se agora" (linha ~149)

---

## Bug 2 — Simplificar seção de login em `user_or_host_page.dart` [CONCLUÍDO]

**Arquivo:** `lib/features/auth/presentation/pages/user_or_host_page.dart`

**Causa:** o plan anterior adicionou título "Entrar" + dois `PrimaryButton` de login. O design esperado é só um link de texto discreto abaixo dos botões de cadastro.

**Correção:** remover os três widgets adicionados (título + 2 botões) e substituir pelo `TextButton` original com `RichText` "Já tem conta? **acesse agora**". O `onPressed` deve chamar `context.pop()` — retorna para `LoginPage` que foi empilhada via `push`.

- [x] Remover o `Align` com texto "Entrar" (título da seção de login)
- [x] Remover o `SizedBox(height: 24)` após o título
- [x] Remover o `PrimaryButton` "Entrar como Hóspede"
- [x] Remover o `SizedBox(height: 16)` entre os botões de login
- [x] Remover o `PrimaryButton` "Entrar como Anfitrião"
- [x] Adicionar `SizedBox(height: 48)` após o botão "Sou Anfitrião" (espaçamento antes do link)
- [x] Adicionar `TextButton` "Já tem conta? **acesse agora**" com `context.pop()`

```dart
TextButton(
  onPressed: () => context.pop(),
  child: RichText(
    text: const TextSpan(
      text: 'Já tem conta? ',
      style: TextStyle(color: AppColors.primary, fontSize: 16),
      children: [
        TextSpan(
          text: 'acesse agora',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),
```

---

## Validação [CONCLUÍDO]

- [x] `flutter analyze lib/` — zero erros novos
- [x] **Fluxo completo:** navbar (não autenticado) → `LoginPage` → "cadastre-se agora" → `UserOrHostPage` → botão voltar do dispositivo → `LoginPage` ✓
- [x] **Link "acesse agora":** na `UserOrHostPage`, tocar "Já tem conta? acesse agora" → retorna para `LoginPage` ✓
- [x] **Botões de login removidos:** "Entrar como Hóspede" e "Entrar como Anfitrião" não aparecem em `UserOrHostPage`
- [x] **Título "Entrar" removido:** seção de login antiga não aparece em `UserOrHostPage`
- [x] **Signup ainda funciona:** "Sou Hóspede" → `UserSignUpPage`; "Sou Anfitrião" → `HostSignUpPage`; back de ambos → `UserOrHostPage`

---

## Regra de Atualização de Status

- Todas `[ ]` → `[CONCLUÍDO]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`
