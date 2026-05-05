# PRD — user-registration-field-standards

## Contexto
A tela de cadastro de usuário (`user_signup_page.dart`) usa o widget `AuthTextField`, cujo estilo difere do padrão visual adotado na tela de edição de perfil (`edit_user_profile_page.dart`). Além disso, o campo de data de nascimento valida apenas o formato, sem verificar a idade mínima; os campos de senha não têm toggle de visibilidade nem feedback granular de erros; e os textos de ação nas telas de cadastro e login estão fora do padrão de capitalização definido pelo produto.

## Problema
1. **Validação de idade ausente:** `_validateData` checa formato e intervalo de ano, mas não calcula se o usuário tem 18 anos ou mais. Usuários menores de idade conseguem se cadastrar sem impedimento.
2. **Inconsistência visual dos campos:** `AuthTextField` não possui `labelText`, `prefixIcon` nem `errorBorder`, e usa `colorScheme.primary` no `focusedBorder`; enquanto `_buildTextField` em `edit_user_profile_page.dart` usa `labelText`, `prefixIcon` com `AppColors.secondary`, `errorBorder` explícito e `focusedBorder` com `AppColors.secondary` (width 2).
3. **Campos de senha sem toggle de visibilidade:** Os campos "senha" e "confirmar senha" no cadastro não têm o ícone de olho para revelar/ocultar o texto.
4. **Mensagem de erro de senha cortada:** A mensagem de validação de senha (`_validateSenha`) pode ser longa e está sendo cortada dentro do campo. Não há feedback granular — apenas uma mensagem concatenada.
5. **Ausência de aceite de termos:** O formulário de cadastro não exige que o usuário concorde com os Termos e Condições antes de se cadastrar.
6. **Capitalização inconsistente nos textos de ação:**
   - `user_signup_page.dart`: título `'cadastre-se'` deve ser `'Cadastre-Se'`
   - `login_page.dart`: título `'Acesse agora'` deve ser `'Acesse Agora'`; botão `'cadastre-se agora'` deve ser `'Cadastre-Se Agora'`

## Público-alvo
Novos usuários que se cadastram na plataforma como hóspedes.

## Requisitos Funcionais

### Validação de Idade
1. O campo de data de nascimento deve calcular a idade a partir da data informada e recusar valores que resultem em idade inferior a 18 anos.
2. Ao detectar idade < 18, exibir: *"Você deve ter pelo menos 18 anos para se cadastrar"*.
3. O `DatePickerField` deve configurar `lastDate` como `hoje - 18 anos`, bloqueando datas inválidas diretamente no seletor.

### Padronização Visual dos Campos
4. O widget `AuthTextField` deve ser atualizado para incluir `labelText`, `prefixIcon`, `errorBorder`, `focusedErrorBorder` e `focusedBorder` com `AppColors.secondary` (width 2).
5. A tela `user_signup_page.dart` deve passar `label` e `icon` para cada campo.

### Toggle de Visibilidade da Senha
6. Os campos "Senha" e "Confirmar Senha" no cadastro devem exibir um ícone de olho (`Icons.visibility_outlined` / `Icons.visibility_off_outlined`) que alterna entre texto visível e oculto — igual ao padrão já adotado em `edit_user_profile_page.dart`.

### Feedback Granular de Erro de Senha
7. Ao submeter ou sair do campo de senha, as condições não satisfeitas devem ser listadas de forma clara e individual — não concatenadas em uma linha única que pode ser truncada pelo campo. A mensagem de erro deve ser exibida fora do campo (no espaço de `errorText` do `InputDecoration`), sem corte de texto.
8. Condições mínimas a validar: letra maiúscula, letra minúscula, número, caractere especial, comprimento mínimo de 8 caracteres.

### Termos e Condições
9. Adicionar ao formulário de cadastro uma caixa de marcação (`Checkbox`) com o texto: *"Eu concordo com os [Termos e Condições]"*, onde `Termos e Condições` é um link clicável.
10. Ao clicar no link, abrir um `showModalBottomSheet` (ou `AlertDialog`) com texto mockado genérico de Termos e Condições de uma aplicação de reservas.
11. O formulário não deve permitir submissão se a caixa não estiver marcada; exibir mensagem de erro inline: *"Você deve aceitar os Termos e Condições para continuar"*.

### Capitalização de Textos
12. `user_signup_page.dart` — título: `'Cadastre-se'`
13. `login_page.dart` — título (role guest): `'Acesse Agora'`
14. `login_page.dart` — botão de cadastro: `'Cadastre-se Agora'`

## Requisitos Não-Funcionais
- [ ] A validação de idade deve ocorrer no `validator` do campo, não apenas no submit
- [ ] O erro de senha não deve ser truncado — garantir que o widget de erro tenha espaço suficiente para exibir todas as condições
- [ ] Cores e estilos devem usar tokens semânticos do tema (`colorScheme.*`) e `AppColors` — sem hardcode de hex
- [ ] Os campos padronizados devem herdar corretamente os tokens de dark mode
- [ ] O modal de Termos e Condições deve ser scrollável para textos longos

## Critérios de Aceitação
- Dado que o usuário informa uma data que resulta em idade < 18, quando o campo perde foco ou o formulário é submetido, então deve exibir *"Você deve ter pelo menos 18 anos para se cadastrar"*
- Dado que o usuário abre o `DatePicker`, então datas após `hoje - 18 anos` devem estar desabilitadas
- Dado que o usuário digita uma senha que não satisfaz todas as condições, quando o campo perde foco ou o formulário é submetido, então cada condição não satisfeita deve aparecer listada, sem corte de texto
- Dado que o usuário toca no ícone de olho nos campos de senha, então o texto deve alternar entre visível e oculto
- Dado que o usuário toca em "Termos e Condições", então um modal com o texto dos termos deve abrir
- Dado que o formulário é submetido sem marcar a caixa de aceite dos termos, então deve exibir *"Você deve aceitar os Termos e Condições para continuar"*
- Dado que a tela de cadastro é aberta em light mode e dark mode, quando comparada visualmente com a tela de edição de perfil, então os campos devem ter a mesma aparência: label flutuante, ícone prefix em `AppColors.secondary`, borda de foco em `AppColors.secondary`, borda de erro em `colorScheme.error`
- Dado que os textos `'Cadastre-Se'`, `'Acesse Agora'` e `'Cadastre-Se Agora'` são exibidos, então cada palavra deve ter a primeira letra maiúscula
- Dado que o formulário é preenchido corretamente (idade ≥ 18, senha válida, termos aceitos), quando submetido, então o fluxo de registro deve prosseguir normalmente sem regressões

## Fora de Escopo
- Validação de idade no backend (segunda linha de defesa — task separada)
- Alteração do fluxo de cadastro de host (`host_signup_page.dart`)
- Implementação real de página de Termos e Condições (texto mockado é suficiente para esta entrega)
- Criação de um widget `AppTextField` global compartilhado (melhoria futura; esta task atualiza o `AuthTextField` existente)
