# ReservaQui — Bug Report & Especificações de Correção

> **Contexto:** Este documento descreve os bugs identificados no app ReservaQui, organizados por categoria e perfil de usuário. Serve como base para criação do PRD e implementação das correções.

---

## 1. Dark Mode

Os itens abaixo representam telas que **não estão respeitando o dark mode** do sistema. A correção padrão é garantir que todas as cores de fundo, texto, ícones e componentes utilizem os tokens de tema (`theme.colorScheme`, `ThemeData`, ou equivalente no framework) — evitando valores de cor hardcoded.

### 1.1 Sem Login (Usuário não autenticado)

| Tela | Descrição do problema |
|------|----------------------|
| **Assistente** | A página inteira não reflete o dark mode; cores fixas (hardcoded) sendo usadas |
| **Check-in** | Página sem login não aplica o tema escuro |
| **Reserva Confirmada** | Não aplica dark mode; adicionalmente, falta o logotipo/símbolo do ReservaQui nesta tela |
| **Minha Reserva** | Página sem login não aplica o tema escuro |

**Correção esperada:** Substituir todas as cores fixas por tokens de tema. Incluir o símbolo do ReservaQui na tela de Reserva Confirmada (mesmo quando não autenticado).

---

### 1.2 Logado — Perfil User

| Tela | Componente afetado | Descrição do problema |
|------|-------------------|----------------------|
| **Hotel** | Botão/ícone de favoritar (hover) | O feedback visual ao passar o mouse sobre o ícone de favoritar não respeita o dark mode |
| **Quarto** | Toast / snackbar "link copiado" | O aviso de cópia de link para a área de transferência não aplica o tema escuro |
| **Reservar** | Página inteira | A tela de reserva não aplica o dark mode corretamente |
| **Reservar** | Seletor de tipo de pagamento | O hover sobre as opções de tipo de pagamento não respeita o dark mode |

**Correção esperada:** Revisar todos os componentes listados para usar cores do tema ativo. Especial atenção aos estados de hover e aos toasts/snackbars, que frequentemente têm estilos inline ou cores fixas.

---

### 1.3 Logado — Perfil Hotel

| Tela | Descrição do problema |
|------|----------------------|
| **Dashboard** | Toda a tela não aplica o dark mode |
| **Detalhes do Agendamento** | Tela não aplica o dark mode |

---

### 1.4 Logado — Perfil Admin

| Tela | Descrição do problema |
|------|----------------------|
| **Dashboard** | Toda a tela não aplica o dark mode |

---

## 2. Bugs Visuais

### 2.1 Tela de Criação de Conta — Perfil Hotel

**Problema 1 — Ícones nos inputs:**
- O formulário do lado do **User** já possui ícones nos campos de input.
- O formulário do lado do **Hotel** não tem ícones, ficando visualmente despadronizado.
- **Correção:** Adicionar ícones nos inputs do formulário de cadastro do Hotel, seguindo o mesmo padrão visual já existente no lado do User.

**Problema 2 — Termos e Condições:**
- Do lado do **User**, os Termos e Condições aparecem com uma animação de baixo para cima (bottom sheet / modal deslizante).
- Do lado do **Hotel**, os Termos e Condições estão implementados como um hover/overlay na página inteira, comportamento diferente e esteticamente inferior.
- **Correção:** Reimplementar os Termos e Condições do lado Hotel para usar o mesmo componente de bottom sheet utilizado no lado User (animação de baixo para cima).

---

### 2.2 Seção Perfil → "Legal" (User, Hotel, Admin)

**Problema:** Os textos de **Termos de Uso**, **Privacidade** e **Sobre o App** estão com conteúdo genérico (placeholders ou textos de exemplo).

**Correção:** Substituir os textos genéricos pelo conteúdo real e definitivo do aplicativo. Aplicável aos três perfis: User, Hotel e Admin.

---

### 2.3 Tela de Quarto (User e Admin)

**Problema:** O feedback visual do ícone de favoritar não está funcionando no estado de hover.

**Correção:** Implementar corretamente o estado hover do ícone de favoritar (ex: mudança de cor, preenchimento do ícone, animação de escala). Verificar se o problema é no listener de evento ou no estilo CSS/widget do ícone.

> *Nota: este bug também afeta o dark mode — ver item 1.2.*

---

### 2.4 Tela Reservar

**Problema 1 — Posição do botão "Finalizar Reserva":**
- O botão está aparecendo em uma posição que não é o final da página.
- **Correção:** O botão "Finalizar Reserva" deve ser o último elemento da tela, posicionado após todas as informações e seleções do fluxo de reserva.

**Problema 2 — Ausência de feedback pós-pagamento:**
- Após o usuário selecionar o método de pagamento e confirmar, não há nenhum feedback visual indicando que a reserva foi realizada e está aguardando confirmação.
- **Correção:** Implementar uma tela/estado de feedback (ex: tela de sucesso com animação, bottom sheet ou modal) que informe: *"Reserva realizada — aguardando confirmação do hotel."*

---

### 2.5 Tela Search

**Problema:** As notas (avaliações/estrelas) dos hotéis não estão sendo carregadas/exibidas nos cards de resultado da busca.

**Correção:** Investigar se o problema é na chamada à API (os dados não estão sendo retornados), no parsing da resposta, ou na renderização do widget de rating. Garantir que a nota apareça corretamente em todos os cards.

---

### 2.6 Capitalização dos Nomes no Perfil

**Problema:** Em todos os perfis (User, Hotel, Admin), os textos na tela de Perfil não estão com a primeira letra de cada palavra em maiúscula (Title Case).

**Correção:** Aplicar formatação Title Case nos campos de nome/texto relevantes da tela de Perfil nos três perfis. Isso pode ser feito via:
- Transformação na camada de UI ao renderizar o texto, ou
- Normalização dos dados na camada de domínio/repositório.

> Aplicável a: **Perfil (User)**, **Perfil (Hotel)**, **Perfil (Admin)**.

---

### 2.7 Tela de Agendamentos (Perfil Hotel)

**Problema 1 — Filtros horizontais ocultos:**
- Quando há mais filtros do que cabem na tela horizontalmente, não está claro para o usuário que existem mais opções além da área visível (ausência de indicador de scroll horizontal).
- **Correção:** Adicionar indicador visual de scroll horizontal (ex: gradiente nas bordas, seta indicativa, ou truncamento parcial do último item visível) para sinalizar que existem mais filtros.

**Problema 2 — Calendário sem destaque nos dias com agendamentos:**
- Os dias que possuem agendamentos não estão sendo destacados com cor diferente no calendário.
- **Correção:** Implementar a lógica de colorização dos dias no calendário com base nos agendamentos existentes. Verificar se os dados estão sendo passados corretamente para o widget de calendário.

**Problema 3 — Header "Agendamentos" despadronizado:**
- A palavra "Agendamentos" no topo da tela não segue o mesmo estilo visual (fonte, tamanho, peso ou cor) dos demais headers do app.
- **Correção:** Aplicar o estilo de header padrão do app à palavra "Agendamentos".

---

### 2.8 Tela de Criação de Quarto (Perfil Hotel)

**Problema 1 — Re-render ao clicar em comodidades:**
- Ao clicar em um filtro de comodidade (amenities), a página parece recarregar completamente (flickering ou perda de scroll position).
- **Correção:** Investigar se o `setState` está sendo chamado em um nível acima do necessário, causando rebuild desnecessário da árvore de widgets. Isolar o estado dos filtros de comodidade em um widget ou provider dedicado para evitar rebuilds globais.

**Problema 2 — Header "Novo Quarto" despadronizado:**
- O texto "Novo Quarto" no topo da tela não segue o mesmo estilo dos demais headers do app.
- **Correção:** Aplicar o estilo de header padrão do app.

**Problema 3 — Ícone de notificações inadequado e despadronizado:**
- O ícone de notificações exibido nessa tela não é adequado ao contexto e difere visualmente dos ícones de notificação usados em outras telas.
- **Correção:** Substituir pelo ícone de notificações padrão utilizado no restante do app. Avaliar se faz sentido exibir notificações nessa tela específica ou se o ícone deve ser removido.

---

### 2.9 Tela de Clientes (Perfil Admin)

**Problema:** As fotos de perfil dos usuários (User) e dos hotéis não estão sendo carregadas na listagem de clientes.

**Correção:** Verificar o fluxo de carregamento das imagens de perfil:
1. A URL da imagem está sendo retornada corretamente pela API?
2. O widget de imagem está tratando o caso de URL nula ou inválida (fallback para avatar padrão)?
3. Há problema de permissão/CORS no carregamento das imagens remotas?

---

## Resumo Rápido por Prioridade Sugerida

| Prioridade | Bug | Motivo |
|-----------|-----|--------|
| 🔴 Alta | Dark mode generalizado (todas as telas) | Afeta experiência em ambiente com pouca luz; múltiplas telas |
| 🔴 Alta | Tela Search — notas não carregam | Afeta decisão de compra do usuário |
| 🔴 Alta | Tela Clientes (Admin) — fotos não carregam | Funcionalidade administrativa quebrada |
| 🟡 Média | Tela Reservar — botão e feedback pós-pagamento | Fluxo principal do app comprometido |
| 🟡 Média | Criação de Quarto — re-render ao clicar em comodidades | UX degradada para o perfil Hotel |
| 🟡 Média | Calendário de Agendamentos — dias sem destaque | Funcionalidade core do perfil Hotel |
| 🟢 Baixa | Capitalização nos Perfis | Polimento visual |
| 🟢 Baixa | Padronização de headers e ícones | Consistência visual |
| 🟢 Baixa | Textos genéricos em "Legal" | Conteúdo de compliance |

