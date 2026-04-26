# PRD — cep-autofill

## Contexto

A tela de cadastro de hotel (`lib/features/auth/presentation/pages/host_signup_page.dart`) exige que o anfitrião preencha manualmente cidade, estado (UF), bairro e rua após digitar o CEP. Esses dados já estão disponíveis publicamente via API ViaCEP e podem ser inferidos automaticamente a partir do CEP, eliminando fricção e reduzindo erros de digitação.

## Problema

O formulário de cadastro de hotel exige 4 campos que podem ser preenchidos automaticamente após o CEP:

1. O anfitrião precisa preencher manualmente cidade, UF, bairro e rua — dados já disponíveis no CEP.
2. Sem busca automática, erros de digitação nos campos de endereço podem causar falha no backend.
3. A UF é um dropdown — difícil de usar em sequência com digitação rápida.

## Público-alvo

Anfitriões no processo de cadastro de hotel (`host_signup_page.dart`).

## Requisitos Funcionais

1. Ao detectar exatamente 8 dígitos no campo CEP via `onChanged`, o app deve disparar consulta à API ViaCEP sem precisar sair do campo.
2. Se o CEP for válido, preencher automaticamente os seguintes campos:
   | Campo ViaCEP  | Controller Flutter     |
   |---------------|------------------------|
   | `logradouro`  | `_ruaController`       |
   | `bairro`      | `_bairroController`    |
   | `localidade`  | `_cidadeController`    |
   | `uf`          | `_selectedUf` (dropdown state) |
3. Exibir indicador de loading no campo CEP durante a consulta.
4. Se CEP não encontrado (resposta `{ "erro": "true" }`), exibir SnackBar: `"CEP não encontrado. Verifique e preencha manualmente."`.
5. Todos os campos preenchidos automaticamente devem permanecer editáveis pelo usuário após o preenchimento.
6. Os campos `numero` e `complemento` nunca são preenchidos automaticamente.

## Requisitos Não-Funcionais

- Timeout da consulta ViaCEP: 5 segundos — a UI não deve travar aguardando resposta.
- Falha de rede: campos permanecem em branco e nenhum erro fatal é exibido ao usuário.
- O Dio utilizado pelo `CepService` deve ser uma instância separada, sem o interceptor de bearer token do app.

## Critérios de Aceitação

- Dado que o anfitrião digitou um CEP válido (ex: `01310100`) no campo CEP, então rua, bairro, cidade e UF são preenchidos automaticamente nos respectivos campos.
- Dado que o CEP é inválido ou não encontrado, então SnackBar de aviso é exibido e os campos de endereço ficam editáveis e em branco.
- Dado que o usuário edita um campo após o auto-preenchimento, então o valor editado é preservado e enviado no submit.
- Dado que a conexão falha durante a busca do CEP, então nenhum erro fatal é exibido e o formulário permanece funcional.
- Dado que o CEP possui menos de 8 dígitos, então nenhuma consulta é disparada.

## Fora de Escopo

- `user_signup_page.dart` — não possui campos de endereço.
- Preenchimento automático de `numero` e `complemento`.
- Máscara de CEP (99999-999) — não faz parte desta feature.
- Validação de CNPJ ou outros campos via API externa.
- Qualquer alteração na tela de cadastro de usuário hóspede.

## Contrato de API

| Método | Rota                              | Auth | Descrição                       | Resposta CEP válido                                   | Resposta CEP inválido         |
|--------|-----------------------------------|------|---------------------------------|-------------------------------------------------------|-------------------------------|
| GET    | `https://viacep.com.br/ws/{cep}/json/` | ❌   | Consulta endereço pelo CEP | `{ cep, logradouro, bairro, localidade, uf, ... }` | `{ "erro": "true" }` |

## Arquivos a Criar / Modificar

| Ação      | Arquivo                                                                          | Descrição                                                        |
|-----------|----------------------------------------------------------------------------------|------------------------------------------------------------------|
| Criar     | `lib/features/auth/data/models/cep_response.dart`                               | DTO da resposta ViaCEP com `fromJson()` e campo `erro`          |
| Criar     | `lib/features/auth/data/services/cep_service.dart`                              | Método `lookup(cep)` via Dio sem auth + Provider                |
| Modificar | `lib/features/auth/presentation/pages/host_signup_page.dart`                   | Chamar `CepService` no `onChanged` do campo CEP e popular controllers |

## Dependências

- **Requer:** host-signup-page (campos de endereço já existem com controllers)
- **Bloqueia:** nenhuma feature conhecida
