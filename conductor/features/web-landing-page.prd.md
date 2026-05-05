# PRD — web-landing-page

## Contexto

O app Reserva Aqui possui uma homepage voltada para usuários já logados, focada em busca e listagem de quartos. Com a entrega web (Fase 10 — MVP), o produto passa a ser acessível via browser desktop, onde é comum que o primeiro contato do visitante seja com uma página institucional — antes mesmo de criar conta. A landing page preenche esse espaço: apresenta o produto, gera interesse e direciona o visitante para as rotas internas do app.

## Problema

Visitantes que chegam ao app via browser não têm contexto sobre o que é o Reserva Aqui, quais diferenciais ele oferece (incluindo o atendimento por IA via WhatsApp) ou por onde começar. A homepage atual pressupõe um usuário já engajado. Sem uma landing page, o produto perde conversão de novos usuários no canal web.

## Público-alvo

- **Visitantes não autenticados** que chegam ao produto pela primeira vez via browser desktop ou tablet
- **Usuários em potencial** que querem entender o produto antes de se cadastrar
- **Anfitriões em potencial** que avaliam se vale cadastrar seus espaços

## Requisitos Funcionais

1. A landing page deve estar disponível na rota `/landing` — a rota `/` (home do app) não é alterada
2. A página deve exibir uma seção **Hero** com headline principal, subtítulo descritivo e dois CTAs: "Explorar quartos" (→ home do app) e "Cadastre-se" (→ cadastro)
3. A página deve exibir uma seção **Como funciona** com passo a passo visual (ícone + título + descrição curta) do fluxo de reserva: Buscar → Escolher → Reservar → Check-in; e do fluxo por parte do anfitrião: Cadastrar Hotel → Ganho de Visibilidade → Acompanhamento de Métricas (etc, é só um exemplo)
4. A página deve exibir uma seção **Quartos em Destaque** com cards de quartos consumindo os dados reais da API com fotos e comodidades de destaque (ex: quartos com mais visualizações ou melhor avaliação)
5. A página deve exibir uma seção **IA no WhatsApp** apresentando o bot de IA "Bene" assistente como diferencial: descrição do que ele faz, screenshot ou mockup ilustrativo e CTA para testar
6. A página deve exibir uma seção **Depoimentos** com reviews reais de usuários cadastrados (nome, foto de perfil, texto e nota)
7. A página deve exibir um **menu sanduíche** (hamburger) no header fixo que, ao abrir, exibe links para as seguintes rotas internas do app: Home, Busca, Login e Cadastro
8. O header deve exibir a logo do Reserva Aqui à esquerda e o ícone de menu sanduíche à direita; em desktop (≥1024px) o menu pode expandir para links horizontais no header sem o ícone sanduíche
9. A página deve ter um **footer** com links institucionais básicos: Sessões da Landing Page, Sobre e Contato
10. Toda a identidade visual deve seguir o design system do app: mesma paleta de cores, tipografia, bordas arredondadas e estilo dos cards existentes
11. A página deve ter um ícone de chatbot do lado direito onde o usuário pode conversar com o Bene, assistente do ReservAqui, assim como tem essa funcionalidade no app mobile e no whatsapp

## Requisitos Não-Funcionais

- [ ] Performance: seção de Quartos em Destaque deve usar paginação ou limite (máx. 6 cards) para não sobrecarregar a requisição inicial; imagens devem usar lazy loading
- [ ] Segurança: a rota `/landing` deve ser pública (sem autenticação); dados exibidos são somente-leitura da API existente
- [ ] Acessibilidade: menu sanduíche deve ser operável via teclado e ter atributos ARIA (`aria-expanded`, `aria-label`); seções devem ter landmarks semânticos (`<section>`, `role`)
- [ ] Responsividade: a landing page deve funcionar em mobile (375px), tablet (768px) e desktop (1280px); layout de uma coluna em mobile, duas ou três colunas em desktop

## Critérios de Aceitação

- Dado que um visitante acessa `/landing` em browser desktop, quando a página carregar, então as seções Hero, Como Funciona, Quartos em Destaque, Bene, Assistente de IA, Depoimentos e footer devem estar visíveis sem scroll horizontal
- Dado que o visitante está em mobile (375px), quando acessar `/landing`, deve ser redirecionado para a Homepage mobile `/`
- Dado que o visitante clica no ícone de menu sanduíche, quando o menu abrir, então os links Home, Busca, Bene, Login e Cadastro devem ser exibidos e funcionais (redirecionam para as rotas corretas do app)
- Dado que o visitante clica em "Explorar quartos" no Hero, quando o redirecionamento ocorrer, então deve ser levado para a rota de search `/search`
- Dado que o visitante clica em "Cadastre-se" no Hero, quando o redirecionamento ocorrer, então deve abrir um modal que funciona como a tela de cadastro
- Dado que a seção de Quartos em Destaque carrega, quando a API responder, então deve exibir no máximo 6 cards usando os componentes visuais existentes do app (mesmas cores, bordas e tipografia)
- Dado que a rota `/` é acessada, quando o app carregar, então o comportamento atual da homepage não deve ser alterado
- Dado que um usuário autenticado acessa `/landing`, quando a página carregar, então a página deve funcionar normalmente (landing é pública e não exige nem rejeita autenticação) mas deve mudar o link de Login e Cadastro para "Perfil"

## Fora de Escopo

- Alteração da rota `/` ou da homepage atual do app mobile
- Criação de painel administrativo para editar o conteúdo da landing page (conteúdo estático ou via API existente)
- Animações complexas (parallax, scroll-triggered animations) — micro-interações simples são permitidas
- Internacionalização (i18n) — conteúdo em português apenas
- SEO / Server-Side Rendering — o app é Flutter web (SPA); meta tags básicas são suficientes
- Integração com ferramentas de analytics ou pixels de conversão
- Formulário de contato ou chat ao vivo na landing page
