# Plano: Alinhamento do Registro de Usuário (Frontend ↔ Backend)

## Contexto

O registro de usuário está quebrado porque frontend e backend divergiram em três pontos:
1. **Nomes de campos** — o frontend envia `nome` e `telefone`; o backend espera `nome_completo` e `numero_celular`.
2. **Campo obrigatório ausente** — o backend exige `data_nascimento` (NOT NULL no banco), mas o formulário não tem o campo.
3. **Regras de senha incompatíveis** — o backend exige `@` na senha; o frontend só exige 8 caracteres.

Além disso, o feedback de erro para o usuário é genérico ("Dados inválidos"), dificultando diagnóstico. Os botões de Google e Apple devem ser removidos por não estarem implementados.

---

## Gaps Host (mapeamento front × back)

O formulário de host (`host_signup_page.dart`) já envia todos os campos obrigatórios e opcionais que o backend espera — **nenhum gap** encontrado. A mesma correção de senha se aplica aqui (@ → caractere especial). O host **não tem** e **não precisa** de campo `data_nascimento`.

---

## Escopo das Mudanças

### Backend — 2 arquivos

#### 1. `Backend/src/entities/Usuario.ts`
- Trocar o validador `validateSenha`: remover exigência de `@`, adicionar exigência de 1 caractere especial (`/[^A-Za-z0-9]/`).
- Nova mensagem: `'Senha fraca: requer maiúscula, minúscula, número e caractere especial'`

#### 2. `Backend/src/entities/Anfitriao.ts`
- Mesma alteração de `validateSenha` para manter consistência entre os dois fluxos de registro.

> O `data_nascimento` já é `DATE NOT NULL` no PostgreSQL. O backend recebe no formato `dd/mm/aaaa` e passa direto para o pg (o driver converte). Nenhuma mudança necessária no banco.

---

### Frontend — 4 arquivos

#### 1. `Frontend/lib/features/auth/data/models/register_request.dart`
- Renomear `nome` → `nome_completo` no `toJson()`.
- Renomear `telefone` → `numero_celular` no `toJson()`.
- Adicionar campo `dataNascimento` (String) ao modelo — será enviada já formatada como `dd/mm/aaaa`.

#### 2. `Frontend/lib/features/auth/presentation/pages/user_signup_page.dart`
- Adicionar `TextEditingController` para data de nascimento.
- Criar widget `DatePickerField` (novo arquivo em `core/widgets/`) que combina dois comportamentos:
  - **Digitação com máscara automática**: ao digitar números, insere `/` automaticamente → `dd/mm/aaaa`
  - **Seleção por calendário**: ícone de calendário abre `showDatePicker`; data selecionada é formatada e preenchida no campo
- Validador do campo: verificar formato `^\d{2}/\d{2}/\d{4}$` + data válida (dia/mês dentro do range).
- Atualizar validador de senha: exigir maiúscula + minúscula + número + caractere especial, com mensagem explícita por regra faltando.
- Remover os botões "Continue with Google" e "Continue with Apple" e o `Divider` "ou" entre eles.
- Passar `dataNascimento` no `RegisterRequest`.

#### 3. `Frontend/lib/features/auth/presentation/pages/host_signup_page.dart`
- Atualizar validador de senha: trocar exigência de `@` por caractere especial, com mensagem explícita por regra faltando.

#### 4. `Frontend/lib/features/auth/presentation/pages/user_signup_page.dart` (tratamento de erro)
- Substituir a mensagem genérica do `catch` 400 por leitura do campo `error` da resposta do backend:
  ```dart
  final serverMsg = (e.response?.data as Map?)?['error'] as String?;
  final msg = switch (status) {
    409 => 'Este e-mail já está cadastrado.',
    400 => serverMsg ?? 'Dados inválidos. Verifique os campos.',
    _   => 'Erro no servidor. Tente novamente mais tarde.',
  };
  ```
  Isso exibe a mensagem real do backend (ex: "Senha fraca: requer maiúscula, minúscula, número e caractere especial") ao invés do genérico.

---

## Ordem de Execução

1. **Backend** — `Usuario.ts` e `Anfitriao.ts` (validador de senha)
2. **Frontend model** — `register_request.dart` (campos + data_nascimento)
3. **Frontend page usuário** — `user_signup_page.dart` (campo data, validadores, remoção botões sociais, erro explícito)
4. **Frontend page host** — `host_signup_page.dart` (só validador de senha)

---

## Verificação

1. Tentar registrar com `Momentomori12` → erro explícito "requer caractere especial"
2. Tentar registrar com `Momento@mori12` → deve passar validação e criar conta
3. Tentar registrar sem data de nascimento → campo obrigatório no formulário impede submit
4. Verificar no banco que `data_nascimento` foi salvo corretamente
5. Testar registro de host com senha sem caractere especial → erro explícito
6. Confirmar que botões Google/Apple sumiram da tela de cadastro de usuário
