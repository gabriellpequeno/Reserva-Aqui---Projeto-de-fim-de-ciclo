# DOT_AGENTS_MANUAL.md

## 1. Visão Geral

Este documento serve como a documentação central e unificada para todo o ecossistema operando na pasta `.agent/`. Ele detalha em profundidade o limite de atuação, os propósitos, dependências e modos de uso de todos os agentes especialistas, skills de módulos de conhecimento, workflows operacionais e scripts validadores presentes no Antigravity Kit instanciado neste projeto.

## 2. Estrutura de Diretórios

A pasta do assistente possui as seguintes áreas principais, além do diretório de contexto persistente na raiz do projeto:

```
.agent/
├── agents/                  # Contém as definições e comportamento de 20 Agentes Especialistas (Personas de IA).
├── skills/                  # Contém 39 Módulos de Conhecimento Específico (Skills) carregáveis em tempo de contexto pela IA.
├── workflows/               # Contém 12 Comandos Slash (Workflows) interativos.
├── rules/                   # Scripts com ordens críticas em tier-0 de arquitetura do núcleo.
├── scripts/                 # Scripts Python e utilitários que checam qualidade com pipeline unificada.
└── ARCHITECTURE.md          # Resumo macro inicial e listagem estática em formato tabela da plataforma.

.context/                    # (raiz do projeto) Memória persistente por skill. Criado automaticamente
└── <skill-name>_context.md  # após cada sessão de implementação. Restaurado pela skill no início da próxima. (A Skill usada deve usar o arquivo de contexto se ele existir, e deve criar o arquivo de contexto se ele não existir)
```

### 2.1 Uso no Cursor (`.cursor/`)

No editor Cursor, o repositório também expõe:

- **Regras:** `.cursor/rules/*.mdc` — núcleo (`architecture-core`, `assistant-policy`), engenharia por domínio e atalhos `agent-*.mdc` que apontam para `.agent/agents/*.md`.
- **Skills (resumo):** `.cursor/skills/<nome>/SKILL.md` — alinhadas às pastas homônimas em `.agent/skills/` (versão completa e scripts permanecem na `.agent`).
- **Playbooks:** `.cursor/playbooks/*.md` — fluxos operacionais equivalentes aos workflows slash documentados abaixo.
- **Índice:** `.cursor/AGENTS.md` — mapa rápido entre `.cursor` e `.agent`.

A pasta `.agent/` continua sendo a fonte detalhada de personas, anexos e scripts; veja `MIGRATION_AGENT_TO_CURSOR.md` para o histórico de migração.

## 3. Descrição dos Agentes, Skills e Workflows

### 3.1 Agentes (Lote 1)

#### Orchestrator
- **Localização**: `.agent/agents/orchestrator.md`
- **Propósito**: Coordenação ativa de múltiplos agentes especializados e tarefas de decomposição. Deve atuar quando uma requisição exigir diferentes domínios e análise paralela. 
- **Responsabilidades**: Validar planilhas de requisições, delegar tarefas inter-agentes (roteamento), evitar evasão de limite (evitar que agentes modifiquem arquivos fora do próprio escopo) e sintetizar descobertas.
- **Dependências**: Requer as skills: `clean-code`, `parallel-agents`, `behavioral-modes`, `plan-writing`, `brainstorming`, `architecture`, `lint-and-validate`, `powershell-windows`, `bash-linux`. 
- **Como usar**: Acionado geralmente de forma nativa pela Engine ao instanciar solicitações compostas (via Native Agent Tool). Caso sinta falta de coerência ou de um documento `PLAN.md`, este agente paralisará a orquestração e solicitará que o *Project Planner* atue.
- **Arquivos importantes**: Foco total na verificação, leitura e avanço de documentos com a nomenclatura `{task-slug}.md` antes do avanço.

#### Project Planner
- **Localização**: `.agent/agents/project-planner.md`
- **Propósito**: Especialista em planejamento de projeto ("Smart Project Planning"). Evita que alterações complexas e irresponsáveis ocorram diretamente na base de código sem o prévio planejamento (4-Phase Workflow).
- **Responsabilidades**: Quebrar requisições complexas em tarefas pequenas e focadas, nomear arquivos de forma dinâmica (`{task-slug}.md`), definir taxonomia dos componentes, garantir grafo de dependência e designar o melhor agente executor pós-planejamento. Ele não escreve código do sistema!
- **Dependências**: Requer skills: `clean-code`, `app-builder`, `plan-writing`, `brainstorming`.
- **Como usar**: Invocado automaticamente caso a iteração entre no "Planning Mode" para criar novos ecossistemas ou features complexas ativando o portal Socrático (Brainstorming).
- **Arquivos importantes**: Baseia-se fortemente em gerir arquivos `.md` na raiz do projeto contendo um breakdown de componentes. Ex: `./auth-feature.md`.

#### Frontend Specialist
- **Localização**: `.agent/agents/frontend-specialist.md`
- **Propósito**: Arquiteto Sênior de UI focado em desenhar e construir sistemas escaláveis (Next.js/React), focados em performance e acessibilidade. Foge veementemente de layouts previsíveis de templates AI e da chamada "SaaS Safe Harbor".
- **Responsabilidades**: Realizar "Deep Design Thinking" antes do layout, desenhar layouts ousados e disruptivos, gerir estado eficiente, impor *mobile first* e verificar componentes HTML semanticamente e com acessibilidade robusta.
- **Dependências**: Skills ligadas: `clean-code`, `nextjs-react-expert`, `web-design-guidelines`, `tailwind-patterns`, `frontend-design`, `lint-and-validate`. Contém diretrizes imperativas, como a "Purple Ban" (restrição de cor).
- **Como usar**: Evocará questionamentos profundos em relação ao UX antes de ser autorizado a criar `.tsx/html`. Deve ser demandado sempre com instruções de emoções para mapear no frontend.
- **Arquivos importantes**: Referencia `typography-system.md`, `animation-guide.md` e diretrizes de psicologia de cor via skills acopladas. Responsável pelos arquivos em `**/components/**` e rotas UI.

#### Backend Specialist
- **Localização**: `.agent/agents/backend-specialist.md`
- **Propósito**: Arquiteto focado em serverless/edge systems, APIs modernas (Node.js/Python), integridade escalável e modelo de camadas.
- **Responsabilidades**: Validar dados rigidamente nas bordas de endpoint, criar lógica assíncrona orientada a I/O, separar em arquitetura limpa (Controller → Service → Repository), prevenir injection, lidar com auth e autorização e prevenir N+1 nativo no servidor.
- **Dependências**: Depende de `clean-code`, `nodejs-best-practices`, `python-patterns`, `api-patterns`, `database-design`, `mcp-builder`, `lint-and-validate`, `powershell-windows`, `bash-linux`.
- **Como usar**: Acionado diretamente ao modelar segurança, infra e rotas no backend, em frameworks que abranjam desde Fastify/Hono a FastAPI.
- **Arquivos importantes**: Mantêm dominância arquitetural em arquivos globais do servidor, rotas `/api/**`, `**/server/**` não inferindo em componentes React, exceto lógicas do servidor estritamente atreladas aos handlers.

#### Database Architect
- **Localização**: `.agent/agents/database-architect.md`
- **Propósito**: Especialista em Data Design que projeta sistemas atrelados a banco de dados com altíssima integridade (como Neon, Turso e Supabase).
- **Responsabilidades**: Mapear modelagem de entidades com restrições e constraints ativas no servidor de dados. Realizar `EXPLAIN ANALYZE` antecipado e formular "migrations" zero-downtime, além de criar estratégias focadas em vetores (IA) e performace extrema.
- **Dependências**: Emprega `clean-code` e `database-design`.
- **Como usar**: Solicite se o modelo exigir mudança de relacionamentos complexos, ou sempre que uma tabela nova sofrer criação. Atua em conjunto com O Backend Specialist limitando falhas de N+1.
### 3.2 Agentes (Lote 2)

#### Mobile Developer
- **Localização**: `.agent/agents/mobile-developer.md`
- **Propósito**: Especialista em criação e portabilidade Cross-Platform (React Native e Flutter) para ambiente móvel.
- **Responsabilidades**: Exigir touch targets responsivos (mínimo de 44-48px), priorizar performance de bateria (offline handling), vetar listas problemáticas (bloqueando `ScrollView` a favor de `FlatList` nativo), garantir 60fps constantes em renderizações complexas e **somente finalizar scripts se o compilador real não emitir erros de Build do App**.
- **Dependências**: `clean-code`, `mobile-design`.
- **Como usar**: Qualquer assunto que respingue em React Native, SDK Expo ou Native APIs móveis cai neste escopo, banindo o acesso do "Frontend Specialist". É mandatório informá-lo o framework alvo via prompt se não documentado na raiz.
- **Arquivos importantes**: Arquivos lógicos como `mobile-design-thinking.md` e regras nativas via `platform-ios.md` ou `platform-android.md`.

#### Game Developer
- **Localização**: `.agent/agents/game-developer.md`
- **Propósito**: Focado em desenvolvimento criativo 2D/3D interativo nos engines da atualidade (Godot, Unity, Phaser).
- **Responsabilidades**: Prever controle orçamentário de frames (frame budget ~16ms). Organizar e definir patterns essenciais de games (State Machine, Object Pooling). Desenvolver código performático que previna render calls repetitivos sobre a CPU ou Main loop, focando sempre em prototipar a jogabilidade preterindo o design no começo.
- **Dependências**: Skills: `clean-code`, `game-development` e todos os seus sub-ramificamentos (mobile, pc, vr, web).
- **Como usar**: Invoque explicitamente a engine desejada. Serve exímio ao desenhar lógica estrita de canvas num App Web (ex. via Pixi.js/Three.js).
- **Arquivos importantes**: Opera independente de templates DOM comuns, alterando diretamente loops e C#/GDScript etc.

#### DevOps Engineer
- **Localização**: `.agent/agents/devops-engineer.md`
- **Propósito**: Operador de infraestrutura Sênior e mestre na orquestração de deploy constante via Containers ou Cloud bare-metal.
- **Responsabilidades**: Configurar pipeline CI/CD mantendo a diretiva do rollback ("Se rodar em ambiente produtivo, o plano em caso de falha tem que existir"). Monitorar logs de serviço para horizontal-scaling e verificar portas vulneráveis ou injeção de keys seguras env vars. Aplicar as 5 Fases de Deploy (Prepare, Backup, Deploy, Verify, Rollback).
- **Dependências**: `clean-code`, `deployment-procedures`, `server-management`, `powershell-windows`, `bash-linux`.
- **Como usar**: Encarregado de mexer em instâncias PM2, docker-compose ou arquivos Actions do repositório, com altíssimo rigor. Deve ser avisado antes se há processos correndo na CLI.
- **Arquivos importantes**: Lida com `.env`, `docker-compose.yml`, configurações nginx/apache e Github Actions.

#### Security Auditor
- **Localização**: `.agent/agents/security-auditor.md`
- **Propósito**: Cyber Security Expert sob contexto Defensivo. Pratica as heurísticas em cima dos guias do OWASP 2025. Trabalha com "Zero Trust Architecture".
- **Responsabilidades**: Varreduras de dependências (Supply chain risks A03), blindar SSRF e SQL Injections através de validador unificado, apontar gaps perigosos no design lógico da aplicação e validar endpoints sensíveis (CORS error-catching).
- **Dependências**: Skills: `clean-code`, `vulnerability-scanner`, `red-team-tactics`, `api-patterns`.
- **Como usar**: O projeto ou Orchestrator pode chamá-lo de forma implícita durante a Fase final da 4-Phase Implementation de qualquer agente de sistema. 
- **Arquivos importantes**: Encarregado de rodar ativamente a lib `scripts/security_scan.py` sob todo projeto para selar commits.

#### Penetration Tester
- **Localização**: `.agent/agents/penetration-tester.md`
- **Propósito**: Red Team especializado. Ao contrário do Security Auditor, ele "ataca" para validar os gates, modelar as ameaças reais usando métodos destrutivos.
- **Responsabilidades**: Seguir as filosofias do PTES. Evitar derrubar a máquina sem consentimento formal do usuário (!). Traçar rotas lógicas de fuzzing não focando apenas em erros do compilador mas no conceito do negócio (venda ilegal, escalada horizontal de permissionamento por APIs bypass).
- **Dependências**: Semelhante ao Security (`clean-code`, `vulnerability-scanner`, `red-team-tactics`, `api-patterns`).
- **Como usar**: Usado de extrema forma proativa. O humano pede permissão real se a aplicação deve sofrer testes invasivos e fuzzing nos handlers HTTP localmente antes do deploy da AWS/Vercel.
- **Arquivos importantes**: Relatórios em markdown gerados pelo fuzzing com provas ativas e screenshots com logs.

### 3.3 Agentes (Lote 3)

#### Test Engineer
- **Localização**: `.agent/agents/test-engineer.md`
- **Propósito**: Analista de Qualidade focado estritamente na Pirâmide de testes e adoção absoluta de "Test behavior, not implementation" em TDD.
- **Responsabilidades**: Seguir o padrão TDD rigorosamente (🔴 RED → 🟢 GREEN → 🔵 REFACTOR). Aplicar testes pautados na estrutura AAA (Arrange, Act, Assert). Evitar mockagem errônea de dependências que mascarem fluxos de exceção.
- **Dependências**: Usa amplamente `clean-code`, `testing-patterns`, `tdd-workflow`, `webapp-testing`, `code-review-checklist`, `lint-and-validate`.
- **Como usar**: Convoque nas fases de "Verification" que fecham os épicos, ou em casos de refatorações de lógicas complexas e sensíveis em `utils`.
- **Arquivos importantes**: O agente retém monopólio soberano dos arquivos padrão de validação, tais como `**/*.test.{ts,tsx,js}` e a zona do `**/__tests__/**`.

#### Debugger
- **Localização**: `.agent/agents/debugger.md`
- **Propósito**: Investigador Cênico super especialista em Root Cause Analysis, Performance Bottlenecks mortos e falhas em memória (Heisenbugs). Seu modelo tem altíssimo foco lógico.
- **Responsabilidades**: Executar invariavelmente a regra dos "5 Whys" (perguntas para destrinchar raízes secundárias da falha e alcançar a causa motora). Traçar processos 4-Phase (Reproduce, Isolate, Understand, Fix/Verify). Exigir evidências de reprodutividade.
- **Dependências**: Acopla o `clean-code` e `systematic-debugging`.
- **Como usar**: Deve ser recrutado sempre que o sistema exibe vulnerabilidade no stacktrace não-reconhecida, ou quando o desenvolvedor humano alega "Works on my machine". Acionamento em casos complexos; não desperdice em lint simples.
- **Arquivos importantes**: Agente fluído; foca seu escopo em ler instâncias de logs gravados e rodar debuggers node/navegador usando bissect de Git.

#### Performance Optimizer
- **Localização**: `.agent/agents/performance-optimizer.md`
- **Propósito**: Arquiteto dedicado integralmente contra regressões de Lighthouse. "Measure first, optimize second".
- **Responsabilidades**: Liquidar gargalos vitais (Core Web Vitals): LCP (>2.5s), INP e Layout Thrashing ou vazamento de CLS. Otimizar renderizações perdidas pelo "React", implementando memoização inteligente (somente onde o profiling justifica) e fragmentação e enxugamento pesado no peso em JavaScript embarcado.
- **Dependências**: Usa as flags de `clean-code` e `performance-profiling`.
- **Como usar**: Invoque assim que a fundação front-end do projeto estiver sólida, exigindo refinagem sob simulação pesada dos scripts internos que calculam as métricas de Vitals.
- **Arquivos importantes**: Impacta a modelagem inteira de empacotamento, importações dinâmicas de hooks em frameworks.

#### SEO Specialist
- **Localização**: `.agent/agents/seo-specialist.md`
- **Propósito**: Perito na fundação técnica de Otimização Semântica clássica do Google E Otimização de Inteligência Generativa (GEO).
- **Responsabilidades**: Preparar a base do sistema seguindo o E-E-A-T. Estruturar "dados para máquinas, mas conteúdos para humanos" garantindo features propensas para citações orgânicas de LLMs (Claude, Perplexity, etc). Implementar Schema Markups profundos e rastreabilidade robusta.
- **Dependências**: Utiliza regras extraídas dinamicamente de `clean-code`, `seo-fundamentals` e `geo-fundamentals`.
- **Como usar**: Se o App/WebSite depender profundamente da vitrine passiva web de Indexação. Acionado no fim da jornada para estruturação do código das Páginas sem comprometer a regra do Frontend.
- **Arquivos importantes**: Opera arquivos críticos estruturais (`robots.txt`, sitemaps, head metadata) e gerencia a emissão do artefato vital moderno `llms.txt`.

#### Documentation Writer
- **Localização**: `.agent/agents/documentation-writer.md`
- **Propósito**: Engenheiro técnico com linguagem direcionada totalmente à construção de cenários e explicações lógicas na base do código para audiências estritas (`ADRs`, `JSDoc`, etc).
- **Responsabilidades**: Resumir, versionar lógicas de uso, criar guias simplistas "como rodar isso em 5 min". Vetar rigorosamente atuar até ser solicitado de forma inegável. Não descrever coisas óbvias do stack para justificar comentários.
- **Dependências**: Emprega `clean-code` e descrições do `documentation-templates`.
- **Como usar**: Deixe em estado de espera no runtime (`PENDING`). Use APENAS QUANDO e se requerer de fato guias arquiteturais, comentários massivos para entendimento, ou re-escrever Readmes para os membros mortais do repositório. Nunca utilize para geração automatizada natural.
- **Arquivos importantes**: É o governante do `README.md`, da pasta de relatórios/logs do diretório, dos `CHANGELOG.md` e do próprio `DOT_AGENTS_MANUAL.md`.


### 3.4 Agentes (Lote 4)

#### Product Manager
- **Localização**: `.agent/agents/product-manager.md`
- **Propósito**: Profissional estratégico focado na inteligência de negócio ("build the right thing"). Converte ideias abstratas em requisitos limpos, blindando a equipe técnica contra oscilações de escopo.
- **Responsabilidades**: Extrair Personas, aplicar método MoSCoW (MUST, SHOULD, COULD, WON'T), definir o Custo/Benefício, elaborar o modelo MVP, escrever e exigir "Acceptance Criteria" no formato Gherkin behavior-driven, avaliando o "Caminho Infeliz" das tasks.
- **Dependências**: Usa amplamente `plan-writing`, `brainstorming`, `clean-code`.
- **Como usar**: Utilize na Fase de Discovery, imediatamente após receber solicitações vagas do usuário (Ex: "Eu quero um relatório de vendas"), antes da equipe ser autorizada a desenhar sistemas.
- **Arquivos importantes**: O agente administra PRDs (*Product Requirement Documents*) e a estruturação dos Readmes de feature para as fábricas de hand-off.

#### Product Owner
- **Localização**: `.agent/agents/product-owner.md`
- **Propósito**: Facilitador estratégico contínuo que atua perfeitamente como "Ponte" entre necessidade do negócio de alto nível e execução de TI através da gestão agressiva de Backlog.
- **Responsabilidades**: Transformar os PRDs em User Stories consumíveis. Priorização através do formato inteligente RICE/MoSCoW. Alertar estapafúrdios cruzamentos de dependências. Recomendar intencionalmente não apenas a tarefa, mas "Qual agente e qual skill será melhor para efetuá-la" (Orquestração passiva de prioridade).
- **Dependências**: Skills: `plan-writing`, `brainstorming`, `clean-code`.
- **Como usar**: Nas reavaliações do ciclo de vida, gerindo backlog técnico ou refinando débitos de código não resolvidos dentro dos frameworks. Operação fortemente focada na análise de valor.
- **Arquivos importantes**: O próprio repositório `.md` global de documentações e grafos de dependência do projeto.

#### QA Automation Engineer
- **Localização**: `.agent/agents/qa-automation-engineer.md`
- **Propósito**: Engenheiro End-to-End focado não em testar acertos, mas sim em quebrar a plataforma pela raíz com testes destrutivos.
- **Responsabilidades**: Orquestrar a "Smoke Suite" e "Regression Suite" via Cypress/Playwright em infraestruturas CI/CD. Modelar padrões Page Object Model (POM) repudiando query selectors acoplados sujos. Produzir caos via mock de quedas de backend (Latency scripts).
- **Dependências**: Emprega rigidamente `webapp-testing`, `testing-patterns`, `web-design-guidelines`, `clean-code`, `lint-and-validate`.
- **Como usar**: Pós-finalização de páginas inteiras para garantir testes que asseverem o fluxo visual e percurso do usuário de ponta-a-ponta, prevenindo flakiness e double-clicks predatórios.
- **Arquivos importantes**: Controla ambientes em Actions (`.github`) e testes E2E (`*.spec.ts/js`).

#### Code Archaeologist
- **Localização**: `.agent/agents/code-archaeologist.md`
- **Propósito**: Historiador dedicado a bases massivas legadas "Brownfield" operando sob as vias de refatoração reversa guiada na segurança da "Chesterton's Fence".
- **Responsabilidades**: Gerar relatórios forenses (Mapeamento de mutações). EXIGIR testes do tipo "Golden Master" nas classes desorganizadas ANTES do toque real. Aplicar agressivamente o Strangler Fig Pattern no lugar de reescritas imediatas da base de código.
- **Dependências**: Focado em `clean-code`, `refactoring-patterns`, `code-review-checklist`.
- **Como usar**: Passe funções quilométricas (500-linhas) de códigos Python/JS herdados que ninguém quer encostar, migração do jQuery para Hooks complexos ou em caso prático onde lógicas espaguetes precisam clarear sem quebrar funcionalidade do "core".
- **Arquivos importantes**: Analisa os arquivos "sujos" alvo e devolve relatórios descritivos "Artifact Analysis" isolados para o desenvolvedor gerenciar.

#### Explorer Agent
- **Localização**: `.agent/agents/explorer-agent.md`
- **Propósito**: Olhos, ouvidos e radar avançado da Engine que lê arquiteturas massivas passivas aplicando o Protocolo de Descoberta Socrática. Agente espião e varredor estrutural.
- **Responsabilidades**: Criar árvore de dependências analíticas. Detectar boilerplate e patterns. Ativação restrita ao "Audit Mode", "Mapping Mode" ou "Feasibility Mode". Impede que o avanço prossiga se o rastreio indicar ausência de bibliotecas cruciais ou falta de conformidade sistêmica, pausando via questionamentos humanos.
- **Dependências**: Usa a base de `clean-code`, `architecture`, `plan-writing`, `brainstorming`, `systematic-debugging`. Acesso contínuo as ferramentas de CLI para procurar diretórios em grande escala.
- **Como usar**: No limiar de todo novo projeto gigante para traçar um "Health Report", ou verificar integridade da API via plugins paralelos para informar estritamente o `orchestrator` sobre onde e como o terreno está minado ou habitado.
- **Arquivos importantes**: Modos estritais de somente-leitura nas raízes de configurações (ex: `package.json`, `index.*`).

---

## ⚡ PARTE 2: SKILLS (Habilidades do Sistema)
> A partir desta etapa, documentamos as "Skills". Ao contrário dos agentes (identidades), as skills são pacotes de contexto e regras injetáveis para ampliar o escopo analítico dos agentes sem diluir sua essência.

### 3.5 Skills (Lote 1)

#### AI Engineer
- **Localização**: `.agent/skills/ai-engineer/SKILL.md`
- **Propósito/Regras Mestra**: Engenheiro de IA focado em Aplicações LLM preparadas para ambiente produtivo (Production-grade), sistemas RAG avançados e arquitetura de agentes autônomos.
- **Restrições Ocultas**: Oprime arquiteturas levianas ("provas de conceito") em prol da confiabilidade e segurança. Exige salvaguardas explícitas ("guardrails") contra vazamento de PII ou Prompt Injection antes da execução. Repudia agressivamente implantações desprovidas de controle de custos, demandando sempre sólida observabilidade (Tracing) dos modelos.

#### API Patterns
- **Localização**: `.agent/skills/api-patterns/SKILL.md`
- **Propósito/Regras Mestra**: Ensina a "Pensar, não copiar" formatos REST/GraphQL/tRPC atuais.
- **Restrições Ocultas**: Proíbe categoricamente verbos em endpoints REST (`/getUsers`), exposição de erros de servidor e impõe a reflexão sobre consumidores da API *antes* do desenho, cobrando rate-limiting por padrão.

#### App Builder
- **Localização**: `.agent/skills/app-builder/SKILL.md`
- **Propósito/Regras Mestra**: Orquestrador lógico dos 13 templates estritos (ex: Next.js + Prisma, Nuxt 3, FastAPI Python, Chrome MV3).
- **Restrições Ocultas**: Ativa todo pipeline inicial de App lendo diretrizes exclusivas do contexto pedido e definindo estrutura de pastas primárias, designando tarefas aos agentes especializados em fila coordenada.

#### Architecture
- **Localização**: `.agent/skills/architecture/SKILL.md`
- **Propósito/Regras Mestra**: Framework de decisão baseada fortemente na frase "A Simplicidade é a extrema sofisticação". Focado em lidar com trade-offs.
- **Restrições Ocultas**: Nega aumento de complexidade não justificado a nível arquitetural e obriga o desenvolvedor AI a escrever **ADRs (Architecture Decision Records)** para fundamentar documentadamente a justificativa e renúncias em código.

#### Bash Linux
- **Localização**: `.agent/skills/bash-linux/SKILL.md`
- **Propósito/Regras Mestra**: Confiabilidade nas linhas de comando POSIX. Tratamentos de cadeia, loop e encadeamento em shells `sh`/`bash`.
- **Restrições Ocultas**: Exige rotinas defensivas como `set -euo pipefail` (para travar crash local e encadeamentos perigosos) em todo Script recém formatado pela AI em ambientes Linux.

#### Behavioral Modes
- **Localização**: `.agent/skills/behavioral-modes/SKILL.md`
- **Propósito/Regras Mestra**: Ativa modulações de personalidade autônoma da AI baseado nos gatilhos da escrita (BRAINSTORM, IMPLEMENT, DEBUG, REVIEW, TEACH, SHIP).
- **Restrições Ocultas**: Ao ouvir "What if/ideas" a AI entra no formidável modo BRAINSTORM que impõe recusa a codificar antes de prover 3 saídas ao usuário. Oposto a isso, ao ativar "Build", o modo IMPLEMENT elimina falas longas, tutoriais densos e vai apenas gerar código conciso focado na entrega. Introduz o conceito de MENTAL MODEL SYNC e colaboração multi-agente mista.

#### Brainstorming
- **Localização**: `.agent/skills/brainstorming/SKILL.md`
- **Propósito/Regras Mestra**: Gateway impenetrável de segurança para lógicas vagas. Detém e abriga o poderoso **Socratic Gate**.
- **Restrições Ocultas**: Encontrou uma request genérica como "Faça um novo layout"? Ativa o muro do `STOP-ASK-WAIT`. Ele submete a Engine a disparar dinamicamente 3 perguntas focadas em eliminar gargalos e caminhos incertos arquiteturais, com total obrigatoriedade, antes de rodar o sub-agent respectivo, repudiando adivinhação técnica.

### 3.6 Skills (Lote 2)

#### Clean Code
- **Localização**: `.agent/skills/clean-code/SKILL.md`
- **Propósito/Regras Mestra**: Skill de classificação `CRITICAL`. Controla o pragmatismo da codificação. Exige soluções diretas sem excesso de engenharia.
- **Restrições Ocultas**: Modula todo o comportamento sintático do projeto (Guards ao invés de IFs profundos, Early Returns). Abriga a tabela base para o uso dos Scripts Verificadores Python. Bloqueia severamente os agentes de corrigirem seus próprios "fails" de script sem apresentar ao usuário um quadro sintético `❌ Errors, ⚠️ Warnings` e solicitar bênção presencial.

#### Code Review Checklist
- **Localização**: `.agent/skills/code-review-checklist/SKILL.md`
- **Propósito/Regras Mestra**: Framework severo de auditoria focado não apenas em códigos humanos, mas em Padrões Geração Mista LLM (2025).
- **Restrições Ocultas**: Ensina o agente a aplicar revisões com "Chain of Though" em vulnerabilidades invisíveis ("Prompt Injections" ou "State management bugs" em edge cases de rede). Institui o uso de semáforos com emojis de severidade (🔴 BLOCKING, 🟡 SUGGESTION).

#### Database Design
- **Localização**: `.agent/skills/database-design/SKILL.md`
- **Propósito/Regras Mestra**: A "Arte de avaliar" contextos de arquiteturas de data-layers e Schema Design. Foco no "Stop Defaulting to Postgres".
- **Restrições Ocultas**: Exige que as engines não assumam relatórios de BD e avaliem alternativas como SQLite e Turso/Neon para Vercel. Proíbe ferozmente o uso de "SELECT *", falta de indexações, e o famigerado Querying via "N+1" nativo no Prisma/Drizzle.

#### Deployment Procedures
- **Localização**: `.agent/skills/deployment-procedures/SKILL.md`
- **Propósito/Regras Mestra**: Aplicação implacável da rotina de 5 fases para evitar catástrofes pro-ativas (The 5-Phase Process: Prepare, Backup, Deploy, Verify, Confirm/Rollback).
- **Restrições Ocultas**: Não se trata de decorar `.yaml`, mas princípios. Proíbe deploys sem Rollback Plan atestado, não aceita push de sextas-feiras e obriga o "Watch it happen" (O monitoramento orgânico de 15 a 60 minutos pelo devops após a subida na main pipeline).

#### Documentation Templates
- **Localização**: `.agent/skills/documentation-templates/SKILL.md`
- **Propósito/Regras Mestra**: Formato institucional obrigatório para construção de README.md, CHANGELOG e Code Strings (TSDoc).
- **Restrições Ocultas**: Força a padronização não só ao olho humano, mas dita a criação vitalícia de metadados focados em AI Crawling modernizados, gerando o `llms.txt`. O agente é proibido de tecer comentários focados no "O Quê" e focar apenas no negócio ("O Porquê").

#### Firebase
- **Localização**: `.agent/skills/firebase/SKILL.md`
- **Propósito/Regras Mestra**: Profissional veterano focado no ecossistema de infraestrutura Firebase. Domina tanto seu poder de velocidade como os severos perigos e "arestas cortantes".
- **Restrições Ocultas**: Bane ativamente a terrível prática das "Lack of Security Rules" desde o primeiro commit. Trava implementações ingênuas de Listeners globais acoplados a enormes coleções a fim de isolar prejuízos contábeis, bloqueando toda e qualquer operação administrativa que passe levianamente do lado do Front-end (Client-Side).

#### Flutter Expert
- **Localização**: `.agent/skills/flutter-expert/SKILL.md`
- **Propósito/Regras Mestra**: Especialista de Elite multi-plataforma trabalhando estritamente com Dart 3.x+ e Flutter Masterys para construir sistemas com máxima fluidez computacional.
- **Restrições Ocultas**: Obriga brutalmente a priorização de Composição em vez de Herança de entidades. Exige "const constructors" sob pressão tática, impõe otimização nativa forçada (Impeller/Skia) e condena rigorosamente o build de interfaces que menosprezem Padrões de Acessibilidade nativa e proteções de Type-Null Safety absoluto.

#### Frontend Design
- **Localização**: `.agent/skills/frontend-design/SKILL.md`
- **Propósito/Regras Mestra**: Epicentro de UX visual do Framework pautado pela Filosofia de Psico-Telas (Fitts' Law, Miller's Law). Combate árduo contra templates enlatados da geração LLM pregressa.
- **Restrições Ocultas**: A skill hospeda dezenas de "Anti-Padrões IA", incluindo as famosas proibições ativas **Purple Ban** (uso excessivo de luzes neons violetas e cores fáceis de IA), **Bento-Grid Ban** (Uso injustificado do Grid), e os infames Mesh-Gradients em background. Pede que o designer AI "Assuma e Tome Riscos" usando contrastes agressivos e Golden Ratios.

### 3.7 Skills (Lote 3)

#### Game Development
- **Localização**: `.agent/skills/game-development/SKILL.md`
- **Propósito/Regras Mestra**: Orquestrador especializado em desenvolvimento de jogos (2D, 3D, Web, PC) contendo sub-roters de engine (Unity, Godot) baseados num poderoso balanço matemático de colisão e rendering (The Game Loop).
- **Restrições Ocultas**: Impõe restrições de "Performance Budget" severas (ex: Renderização deve consumir ≤5ms, e o frame completo travar em 16.67ms para 60 FPS). Proíbe os agentes de tentarem alocar objetos brutos na RAM (exige `Object Pooling` de munição, por ex) e desliga a renderização suja priorizando Eventos no lugar de atualizações de Loop a cada tick frame.

#### GEO Fundamentals
- **Localização**: `.agent/skills/geo-fundamentals/SKILL.md`
- **Propósito/Regras Mestra**: Base tática para Otimização em Motores Gerativos (GEO = Generative Engine Optimization). Atualiza a métrica arcaica do "SEO tradicional do google" para engajamento dos Scrapers IAs (Perplexity, ChatGPT, Claude).
- **Restrições Ocultas**: Bloqueia conteúdos desprovidos de datas/autoridade para aumentar o ganho "Citacional". Um layout que preza pelo GEO tem que exibir originalidade em Data-Tables, tabelas de FAQ com marcações Semânticas profundas para não ser bloqueada pelo RAG de empresas colossais.

#### i18n Localization
- **Localização**: `.agent/skills/i18n-localization/SKILL.md`
- **Propósito/Regras Mestra**: Manipulação avançada do espaço físico de componentes devido a mudança de Idioma (L10n) e layout reverso RTL (Ex: Árabe, Hebraico).
- **Restrições Ocultas**: Impede o "Hardcode" descuidado de textos cruciais inseridos diretamente no TSX/HTML. Proíbe a construção insegura da conversão forçada alertando a engine que linguagens não possuem o mesmo tamanho em box-model, exigindo design defensivo `margin-inline-start/end` sempre, repudiando uso primário de `left/right` nativos.

#### Intelligent Routing
- **Localização**: `.agent/skills/intelligent-routing/SKILL.md`
- **Propósito/Regras Mestra**: Engine analítica de background "Ghost" não visual (Project Manager silencioso) cujo fim é ler keywords do usuário mapeando o Agente Mestre perfeito para interagir sem precisar ser explicitamente marcado pelo `@`.
- **Restrições Ocultas**: Evita conflitos baseados num quadro de Complexidade e Disputa. Caso o usuário envie "Faça Login Responsivo" (Backend + UI/UX), ele automaticamente nega a execução singular e sobe para o orquestrador iniciar de forma cooperativa. A ferramenta é muda para meta-comentários maçantes ("Estou pensando..."), focando puramente no output veloz.

#### MCP Builder
- **Localização**: `.agent/skills/mcp-builder/SKILL.md`
- **Propósito/Regras Mestra**: Princípios para a criação de rotas Stdio/WebSocket focadas em conexões de Model Context Protocol para IAs conversarem com recursos (Tools).
- **Restrições Ocultas**: Impõe regras severas sobre restrição de ferramentas: Toda tool deve ser singular, exibir descriptions precisos e validados com schema, nunca devendo retornar arrays ou metadados de credenciais visíveis caso a IA em teste acabe explodindo erros sensíveis no logger.

#### Mobile Design
- **Localização**: `.agent/skills/mobile-design/SKILL.md`
- **Propósito/Regras Mestra**: Um guia avassalador de uso estrito pautado pela filosofia "Mobile IS NOT a small desktop". 
- **Restrições Ocultas**: Uma das disciplinas mais complexas. Proíbe ferozmente RenderItems inlines e Scrollviews nas `FlatLists` do React Native. Exige `Thumb Zones` (Ações na órbita base do celular). E talvez o mais expressivo requisito da arquitetura: Força formalmente a IA a preencher de forma oral um manifesto-checkpoint **"🧠 CHECKPOINT"**, assumindo as anti-patterns juraradas que evitará *ANTES DE TOCAR na UI*.

### 3.8 Skills (Lote 4)

#### NextJS React Expert
- **Localização**: `.agent/skills/nextjs-react-expert/SKILL.md`
- **Propósito/Regras Mestra**: Otimização avançada e profunda nos motores do React e Next.js com foco primário em Vercel Engineering (57 regras mapeadas por prioridade).
- **Restrições Ocultas**: A skill elege os famosos "Waterfalls de requisição" e "Barrell Imports inflados" como os inimigos globais da UI. É proibido usar `await` sequenciais independentes e deve-se usar `Promise.all()`. Força memorizações nos laços quentes, proíbe Client Components desnecessários quando Server Components servem e obriga virtualização de dom para grandes tabelas.

#### NodeJS Best Practices
- **Localização**: `.agent/skills/nodejs-best-practices/SKILL.md`
- **Propósito/Regras Mestra**: O guia sobre as engrenagens de arquitetura em 2025 para instâncias de servidor, priorizando performance máxima.
- **Restrições Ocultas**: Proíbe usar de forma reflexa o Express. Dependendo do ambiente, ordena uso de Fastify ou Hono (Serverless EDGE). Introduz o `Layered Structure Concept` impedindo que a Business Logic contamine os Routes Controllers. Veda código síncrono bloqueante no Node (`fs.readFileSync` no meio do Request) paralisando o event-loop.

#### Parallel Agents
- **Localização**: `.agent/skills/parallel-agents/SKILL.md`
- **Propósito/Regras Mestra**: A coordenação base do sistema restrita a Antigravity Native Orchestration. A espinha dorsal das chamadas mútuas do Mestre.
- **Restrições Ocultas**: A skill não opera lógicas estáticas curtas (para isso chama subagents de escopo). Opera sob a filosofia de Cadeias de Passagem (PEC: Plan -> Execute -> Critic). Proíbe encerramento da sub-atuação caso o prompt não gere de forma limpa a formatação "Orchestration Synthesis", mesclando as descobertas cruzadas dos 3 cérebros ativados.

#### Performance Profiling
- **Localização**: `.agent/skills/performance-profiling/SKILL.md`
- **Propósito/Regras Mestra**: Avaliação mecânica focada nas Core Web Vitals visando derrubar INP, CLS e LCP com lighthouse scripts em pipelines de CI/CD.
- **Restrições Ocultas**: Bloqueia de imediato qualquer tentativa do designer AI de usar compressões microscópicas ("micro-optimization") quando as questões mastodônticas como rotas pesando +200kb de Chunk sem Tree-Shaking estão afetando a LCP. Enaltece a regra principal: "A métrica de otimização em que a lentidão se baseia na resposta render blocked do JS."

#### Plan Writing
- **Localização**: `.agent/skills/plan-writing/SKILL.md`
- **Propósito/Regras Mestra**: O manifesto da organização visual de tarefas isoladas em markdown, rejeitando massas textuais e forçando bullet points atômicos e rápidos (2-5 mins por item no mundo físico real).
- **Restrições Ocultas**: O arquivo bane qualquer plano que exceda o tamanho literário de "1 página", alegando o erro grave em sub-sub-tasking ilusório. Todo ticket exige critério de "Verification", impedindo itens superficiais do tipo "Checar se o componente funciona". Tudo que estiver planejado roda num slug específico do projeto como `.md` extra.

#### Powershell Windows
- **Localização**: `.agent/skills/powershell-windows/SKILL.md`
- **Propósito/Regras Mestra**: Diretrizes de segurança cruzada para scripts de linha de comando num ecossistema não-Linux. Evitando crashes sintáticos exclusivos da Microsoft.
- **Restrições Ocultas**: Devido ao UTF-8 nativo falho do Powershell tradicional, bane completamente Emojis na tela preta (usar ASCII ex: `[OK]`, `[FAIL]`). Obriga os "Check-Nulls" extensivos não necessários em bash, assim como força a IA a parênteses isolados envolta de lógicas duplas `if ((A) -and (B))` para combater erros de engine do sistema.

### 3.9 Skills (Lote 5)

#### Python Patterns
- **Localização**: `.agent/skills/python-patterns/SKILL.md`
- **Propósito/Regras Mestra**: Estrutura analítica para eleição contextual de frameworks web do ecossistema Python (FastAPI, Django, Flask).
- **Restrições Ocultas**: A skill decreta o fim das suposições de design no "Assíncrono". Impõe a regra mestre: `I/O-Bound -> usar async` vs `CPU-Bound -> usar sync`. Tenta impedir que os agentes misturem abordagens, orientando a integração forte entre FastAPI e Modelos Pydantic.

#### Red Team Tactics
- **Localização**: `.agent/skills/red-team-tactics/SKILL.md`
- **Propósito/Regras Mestra**: Base ideológica e tática fundamentada no MITRE ATT&CK Framework para Pentest ativo e Simulação de Ameaças.
- **Restrições Ocultas**: Proíbe severamente danos reais na infraestrutura de produção ou "Denial of Service" não escopados. Direciona os agentes a ocultar pegadas digitais usando "Timestomping" e focar em progressão de intrusão tática `(Recon -> Access -> Extracted Data)`, jamais pulando "Direct to Root" por milagres fantasiosos.

#### SEO Fundamentals
- **Localização**: `.agent/skills/seo-fundamentals/SKILL.md`
- **Propósito/Regras Mestra**: Guia base da engrenagem do "Rankeamento de Buscas", aderindo forte à métrica "E-E-A-T" do Google.
- **Restrições Ocultas**: Enquanto a Skill de *GEO* ensina para bots IAs, esta skill mira algoritmos base como os do Google priorizando os limites das "Core Web Vitals". Possui um gatilho de auto-restrição contra textos vazios gerados por IA, condenando o "Keyword Stuffing" (Encher a página de palavras chaves sem sentido) em nome de qualidade linguística humana.

#### Server Management
- **Localização**: `.agent/skills/server-management/SKILL.md`
- **Propósito/Regras Mestra**: Manual administrativo Linux de persistência base com as doutrinas de orquestração local de rede e memória sobre PM2 e Containers.
- **Restrições Ocultas**: Bane explicitamente atitudes passivas em crash-cases (exige scripts de Auto-Recover). Decreta a morte do "Restarts Manuais" com permissões abertas do Root, operando atrás do controle rígido de chaves SSH e um firewall isolado de Troubleshooting: `Process -> Logs -> Resources -> Network`.

#### Skill Creator
- **Localização**: `.agent/skills/skill-creator/SKILL.md`
- **Propósito/Regras Mestra**: Motor construtor e avaliador contínuo do próprio ecossistema. Permite fabricar novas skills e otimizar descrições almejando melhorar a precisão de gatilhos da Inteligência.
- **Restrições Ocultas**: Bane veementemente a prática letal de otimizações "cegas". Força a prova real, obrigando a IA a gerar execuções pareadas concorrentes (Baseline vs With-Skill) e invocar mandatoriamente a interface visual analítica (`generate_review.py`) antes de arriscar a alterar as lógicas. Restringe a criação de arquivos de regra a estritas <500 linhas, repelindo comandos "MUSTs" robóticos inflexíveis.

#### Systematic Debugging
- **Localização**: `.agent/skills/systematic-debugging/SKILL.md`
- **Propósito/Regras Mestra**: Método empírico de 4 passos fundamentais desenhados para extirpar a pior mania de IAs primitivas: *Modificações aleatórias sem sentido na esperança da cura visual*.
- **Restrições Ocultas**: As 4 fases são intocáveis: (1. Reproduzir -> 2. Isolar -> 3. Compreender Causa Raiz ("5 Whys") -> 4. Fixar/Verificar). O agente está proibido de enviar códigos re-escritos de solução até reproduzir com certeza matemática que deparou-se com 100% ou 50% de taxa de acerto causal do bug em questão no passo 1.

#### Tailwind Patterns
- **Localização**: `.agent/skills/tailwind-patterns/SKILL.md`
- **Propósito/Regras Mestra**: Regras adaptadas à recém chegada revolução do TailwindCSS v4 no Engine Oxide (2025+).
- **Restrições Ocultas**: Rompe historicamente com o famoso arquivo config Javascript `tailwind.config.js`, forçando de forma letal a conversão total e exclusiva da configuração do Design via tokens CSS `--*` na tag `@theme`. Também decreta a morte de Grids visualmente chatos 3x-simétricos, prescrevendo designs complexos desiguais como os novos Padrões Bento.

### 3.10 Skills (Lote 6 - Final)

#### TDD Workflow
- **Localização**: `.agent/skills/tdd-workflow/SKILL.md`
- **Propósito/Regras Mestra**: Disciplina base da Programação Orientada a Testes, regendo os ciclos (RED -> GREEN -> REFACTOR).
- **Restrições Ocultas**: Instala nas IAs as famigeradas "Três Leis do TDD". Condenando qualquer código produtivo que for implementado *sem que um teste prévio tenha sido escrito primeiro para falhar*. Também proibe otimização precoce e complexidade na fase `GREEN` de aprovação.

#### Testing Patterns
- **Localização**: `.agent/skills/testing-patterns/SKILL.md`
- **Propósito/Regras Mestra**: Abordagem da "Pirâmide de Testes" (Unit > Int > E2E) e as estratégias maduras de uso de stubs e mocks.
- **Restrições Ocultas**: Rejeita brutalmente testes unitários que não sejam rápidos (Exige execução real inferior a `<50ms`). Proíbe testes de serem criados sob a lente da "Implementação", ordenando que abordem os efeitos de "Comportamento" baseados na Tríade **AAA** (Arrange -> Act -> Assert).

#### Vulnerability Scanner
- **Localização**: `.agent/skills/vulnerability-scanner/SKILL.md`
- **Propósito/Regras Mestra**: Cólera defensiva baseada no OWASP 2025 focado estritamente nas camadas obscuras de "Supply Chain Security".
- **Restrições Ocultas**: Proíbe as IAs de engolir a falha em "Modo Silencioso" e liberar acesso para evitar crash (O repúdio absoluto ao `Fail-Open`), demandando `Fail-Secure`. Impede também de olhar friamente apenas o score CVSS sem avaliar o Contexto do Ativo Financeiro (Asset Value).

#### Web Design Guidelines
- **Localização**: `.agent/skills/web-design-guidelines/SKILL.md`
- **Propósito/Regras Mestra**: Operação de varredura visual corretiva operando no fim da fila ("Após o Code") visando aprimorar o UX final.
- **Restrições Ocultas**: Diferentemente das demais, essa Skill é "Server-Side Fetch". Suas regras não existem hardcoded localmente. Proíbe inspeção sem antes buscar via HTTP a guideline mais limpa remotamente nos repositórios Vercel-Labs, cuspindo mensagens densas num padrão militar de log exato: `file:line`.

#### WebApp Testing
- **Localização**: `.agent/skills/webapp-testing/SKILL.md`
- **Propósito/Regras Mestra**: Metodologias práticas e pesadas para varreduras Deep Audit e E2E via automação browser Playwright (Chromium).
- **Restrições Ocultas**: Impossibilita as IAs de dependerem falsamente de atrasos brutos instáveis de timers como `waitForTimeout(5000)`, exigindo escrutínio às métricas automáticas do auto-waiter embutido do Playwright. Exige preferencialmente escaneamento das interações focadas em rótulos estáveis como `data-testid` em vez de CSS nativo sensível à re-estilização.

### 3.11 Skills (Lote 7 — Skills de Domínio do Projeto)

> Skills desta seção são especializadas no domínio de negócio do ReservAqui e criadas pelo `skill-creator` conforme o projeto evolui.

#### Auth Flow
- **Localização**: `.agent/skills/auth-flow/SKILL.md`
- **Propósito/Regras Mestra**: Especialista no fluxo de login e cadastro do backend ReservAqui. Cobre `usuario` (hóspede global, master DB), `anfitriao` (hotel/host, master DB + provisionamento tenant) e `hospede` (hóspede local por hotel, tenant DB). Garante arquitetura de 3 camadas estrita: Entity (validação) → Service (bcrypt + queries) → Controller (HTTP mapping).
- **Restrições Ocultas**: Impõe **Step 0 obrigatório** antes de qualquer código: Track A confirma regras de negócio com o usuário via `regras de negócio.txt`; Track B pesquisa boas práticas OWASP 2025 e apresenta opções de hashing (bcrypt/Argon2id) e sessão (JWT/cookie/server-side) aguardando decisão explícita. Proíbe implementar estratégia de token/sessão sem aprovação do usuário. Exige Context Load no início (restaura `.context/auth-flow_context.md` se existir) e Context Storage ao fim (persiste o que foi implementado).

#### Secure Storage
- **Localização**: `.agent/skills/secure-storage/SKILL.md`
- **Propósito/Regras Mestra**: Especialista em implementação segura e otimizada de sistemas de armazenamento de arquivos (object storage, CDN, uploads). Antes de qualquer implementação, conduz obrigatoriamente uma **Fase de Discovery** (5 perguntas sobre tipo de dado, controle de acesso, infraestrutura, volume e compliance) e apresenta um **Proposal formal** aguardando aprovação. Suporta Firebase Storage, AWS S3, GCS, Supabase Storage, MinIO e disco local, cada um com reference file dedicado em `references/`.
- **Restrições Ocultas**: Proíbe absolutamente iniciar código sem aprovação do Proposal. Bane URLs públicas permanentes para arquivos privados (exige signed/expiring URLs). Veda armazenar credenciais de storage no client. Impõe validação de MIME por magic bytes (não apenas header do request) e sanitização de filenames com UUID. Exige cleanup de ficheiros temporários e rate limiting nos endpoints de upload. Consulta arquivos de referência por provider (`firebase-storage.md`, `s3-patterns.md`, `self-hosted.md`) em vez de embutir toda a lógica no SKILL.md.

#### CRUD API
- **Localização**: `.agent/skills/crud-api/SKILL.md`
- **Propósito/Regras Mestra**: Especialista em implementar operações CRUD no backend ReservAqui respeitando a arquitetura em 4 camadas do projeto: Entity (validação pura) → Service (lógica + DB) → Controller (HTTP mapping) → Routes (middleware chain). Conduz uma **Fase de Discovery obrigatória** (7 perguntas de regras de negócio + análise do schema SQL) antes de qualquer código, e apresenta uma **proposta de arquitetura** para aprovação. Suporta tanto o master DB (dados globais) quanto os schemas tenant (dados por hotel via `withTenant()`).
- **Restrições Ocultas**: Impõe o **Wrapper Pattern** intransigentemente: funções exportadas são apenas wrappers que chamam as implementações privadas `_functionName()` — proibido exportar diretamente a implementação completa. Bane interpolação de strings em SQL (exige queries parametrizadas). Exige guard correto em cada endpoint (`authGuard` para usuário, `hotelGuard` para hotel). Proíbe retornar campos sensíveis (senha, hash) no output. Impõe `withTenant()` para toda operação em schema tenant, nunca acessando diretamente. Checklist de segurança e escalabilidade obrigatório antes de entregar a implementação.

---

## ⚡ PARTE 3: WORKFLOWS

Workflows (`.md`) são gatilhos executáveis chamados através de "Slash Commands" (Ex: `/deploy`). Eles configuram protocolos transacionais de atuação em que múltiplos agentes e skills atuarão sob um trilho orquestrado.

### 4.1 Workflows (Lote 1)

#### /brainstorm
- **Localização**: `.agent/workflows/brainstorm.md`
- **Propósito**: Comando de exploração sem código. Modela arquiteturas antes da implementação finalizando com uma recomendação embasada.
- **Protocolo de Saída**: O script condena as IAs a estruturar obrigatoriamente 3 ou mais cenários (Opção A, B e C), enumerando Prós, Contras, Peso do Esforço, e só então concluir um veredito sugerido ao usuário. 

#### /create
- **Localização**: `.agent/workflows/create.md`
- **Propósito**: Orquestrador interativo de fundação para novos Projetos a partir do zero.
- **Protocolo de Saída**: Gatilha imediatamente a skill `app-builder`. O fluxo passa pela triagem rígida chamando sequencialmente os agentes (Database Architect -> Backend Specialist -> Frontend Specialist). Ele se recusa a iniciar se houverem furos nos requisitos levantados no prompt nativo.

#### /create-feature
- **Localização**: `.agent/workflows/create-feature.md`
- **Propósito**: Micro-comando que delega rapidamente e ativamente o desenvolvimento de uma feature específica lendo um prompt centralizador (`documentation/prompts/create-feature-prompt.md`).

#### /auth_create-edit
- **Localização**: `.agent/workflows/auth_create-edit.md`
- **Propósito**: Orquestrador interativo especializado no ciclo de vida do sistema de autenticação (login, registro, sessão, middlewares). Diferente do `/create`, não escreve código diretamente — guia o desenvolvedor pelas decisões de segurança e delega a implementação à skill `auth-flow`.
- **Protocolo de Saída**: Executa 4 fases sequenciais com gate obrigatório. **Fase 1** restaura contexto (`.context/auth-flow_context.md`) ou lê arquivos de referência. **Fase 2** apresenta dois tracks paralelos: Track A (confirmação das regras de negócio via `regras de negócio.txt`) e Track B (tabelas de decisão de segurança — hash de senha, estratégia de sessão, proteções adicionais). **Fase 3** mostra resumo das decisões para aprovação final. **Fase 4** delega para a skill `auth-flow` com todas as decisões já resolvidas, evitando que a skill precise re-perguntar ao usuário.

#### /debug
- **Localização**: `.agent/workflows/debug.md`
- **Propósito**: Investigação policial sistêmica sobre falhas em produção ou local.
- **Protocolo de Saída**: Extirpa a "Suposição cega". Exige que o agente preencha um grid listando o *Symptom*, monte ativamente *Hypotheses*, teste ativamente (passo 4), relate a *Causa Raiz* real, apresente a linha quebrada e forneça uma medida profilática de *Prevention*.

#### /deploy
- **Localização**: `.agent/workflows/deploy.md`
- **Propósito**: Interface mestre de transição do ambiente de desenvolvimento local para a produção na rede mundial.
- **Protocolo de Saída**: Ativa a temida "Pre-Deploy Checklist". Trava lançamentos caso esbarre em erros lógicos acionando `tsc`, validadores de Node `eslint` e scripts de teste corporativo `npm test`. O robô encerra retornando uma grade limpa com *Summary, URLs, API Check*.

#### /enhance
- **Localização**: `.agent/workflows/enhance.md`
- **Propósito**: Atualizações iterativas e refatoração escalada sem romper ecossistemas pré-existentes.
- **Protocolo de Saída**: Obriga a IA a consumir o ambiente via Python `session_manager.py info`. Se o robô identificar que a alteração fará estragos estruturais graves, ele é forçado a reter a atualização da tela comunicando os danos ao humano e implorando por aprovação ("*I'll modify X files, takes ~10 min. Should I start?*").

### 4.2 Workflows (Lote 2 - Final)

#### /orchestrate
- **Localização**: `.agent/workflows/orchestrate.md`
- **Propósito**: Ativa a mente hiper-multitarefa com execução paralela de Agentes sob um mestre coordenador.
- **Protocolo de Saída**: Possui o bloqueio existencial rigoroso ("*Orchestration = Minimum 3 Different Agents*"). Fomenta 2 fases de execução intransponíveis: (Fase 1: O Agente Mestre chama o Planner solitariamente gerando o PLAN.md e pausa -> Fase 2: O usuário aprova e os agentes Frontend/Backend/Database são invocados todos simultaneamente repassando obrigatoriamente a "Bolsa de Contexto").

#### /plan
- **Localização**: `.agent/workflows/plan.md`
- **Propósito**: Invoca arquitetura sem código para construir a documentação preliminar de base `PLAN.md`.
- **Protocolo de Saída**: Impõe a "Socratic Gate" (interrogatório investigativo preventivo) antes de escrever uma única linha. Possui a Regra Ouro `NO CODE WRITING`. O arquivo gerado ganha uma sigla dinâmica de escopo focada estritamente no objetivo (ex: `PLAN-ecommerce-cart.md`).

#### /preview
- **Localização**: `.agent/workflows/preview.md`
- **Propósito**: Gerenciador isolado das amarras do Node para gerir servidores locais, ativando `auto_preview.py`.
- **Protocolo de Saída**: Lida com conflitos de IP Local interceptando choques se a porta (ex: `3000`) já estiver tomada.

#### /status
- **Localização**: `.agent/workflows/status.md`
- **Propósito**: Tela de Radar. Painel tático reportando o progresso transacional da IA atual.
- **Protocolo de Saída**: Lê o esqueleto do projeto usando o script Python local e pinta a tela do Terminal logando `Arquivos Criados`, `Arquivos Modificados`, a pilha tecnológica e o grau de completude percentual das tarefas alocadas de um Agente orquestrado (Ex: `Frontend Specialist -> 60%`).

#### /test
- **Localização**: `.agent/workflows/test.md`
- **Propósito**: Operação ativada para gerar, gerenciar e varrer suites de testes, criando códigos ou analisando painéis de cobertura de "test frameworks".
- **Protocolo de Saída**: Na geração, preenche um Diagrama "Test Plan" com a regra AAA (Arrange-Act-Assert). Segue o principio do comportamento em vez da lógica empacotada providenciando o script pronto para colar ou via comando explícito no terminal do usuário.

#### /ui-ux-pro-max
- **Localização**: `.agent/workflows/ui-ux-pro-max.md`
- **Propósito**: Base de Design Inteligente alimentada por um script Python dedicado gerando um framework hierárquico `MASTER.md -> OVERRIDE.md`.
- **Protocolo de Saída**: Combina buscas complexas na estrutura `.shared/ui-ux-pro-max`. A IA obedece às penalidades rigorosas contra estéticas datadas de Bootstrap (Proibição agressiva no uso de *Emojis no lugar de Ícones SVGs*, bane cursores nativos ao interagir com hover states e previne "Waterfalls layouts").

## ⚡ PARTE 4: ARQUIVOS COMPARTILHADOS

### Shared Scripts Master
- **Localização**: `.agent/scripts/`
- **Propósito**: Executar validações unificadas do código ou invocar varreduras especialistas da camada skill inferior.
- **Arquivos**:
  - `checklist.py`: Usado geralmente no desenvolvimento (como pre-commit). Executa auditorias cruciais (Segurança, Lint, Schema, Teste Base e Validações).
  - `verify_all.py`: Extensão do checklist antes de uma subida em Release ou Deploy, validando LightHouse de UI, performance e acessibilidade móvel usando endpoints.

## 5. Convenções de Nomenclatura

- **Agentes**: Armazenados em `.agent/agents/[nome-do-agente].md`. Utiliza kebab-case em língua inglesa representando o papel do agente (ex: `frontend-specialist.md`).
- **Skills**: Estruturadas em diretórios (`.agent/skills/[nome-da-skill]/`). O script mandatório de instruções internas se denomina obrigatoriamente `SKILL.md` em caixa alta.
- **Workflows**: Armazenado em `.agent/workflows/[comando].md`. Representa um nome de ação ou imperativo comumente digitado com "slash" (ex: `/brainstorm` ou `/plan`).

## 6. Padrões de Design

A IA operando dentro da estrutura preza por padrões rígidos de arquitetura descritos em suas regras Tier-0:
- **Intelligent Routing**: Reconhecimento semântico do tema para puxar as skills corretas;
- **Deep Design Thinking**: Agentes de frontend não pulam diretamente para o código nem validam templates UI genéricos de "SaaS" antes de entender os contrastes topológicos do projeto.
- **Gateway Socrático:** Agentes que criam features sempre interagem através da habilidade `brainstorming`, sondando e questionando o usuário antes de avançar perigosamente no código.

## 7. Como Contribuir

Para expandir as diretrizes, basta observar como as personas são compostas por Frontmatter em YAML:
1. Para adicionar uma ferramenta técnica ausente, crie em `.agent/skills/nova-tecnologia/SKILL.md`.
2. Para adicionar um novo perfil (Ex: Um analista de marketing), crie o perfil `.agent/agents/marketing-analyst.md`.
3. Garanta que as áreas recém-criadas apontem responsabilidades claras para não confundirem o sistema de Roteamento (Routing) Automático.
4. Ao adicionar ou remover uma feature do projeto, referencie o manual explicitamente abaixo.

## 8. Exemplos de Uso

A IA deste projeto age passivamente, lendo o projeto a seu dispor. Algumas chamadas explícitas podem agilizar interações:

*   **Evocar Workflow Específico:** `Usaremos o workflow de /ui-ux-pro-max e não o convencional`
*   **Rodando scripts na máquina (Testes):** `python .agent/scripts/checklist.py .` para validar arquivos tocados na raiz.

## 9. Solução de Problemas

- O Agente "alucinou" com uma regra corporativa e utilizou cores violetas? -> Confira se a regra "Purple Ban" (exclusamente encontrada no `frontend-specialist`) foi ativada adequadamente pela skill de Frontend.
- Falha na validação de scripts `.py`: Verifique se os interpretadores virtuais (Venv) foram acoplados antes de iniciar a revisão final.

## 10. Histórico de Versões

- **1.0.0**: Criação Inicial Automatizada por GenAI. Levantamento dos 67 ativos.
- **1.1.0**: Adicionada skill `auth-flow` (Lote 7 — Skills de Domínio). Contagem de skills atualizada para 37.
- **1.2.0**: Workflow `/auth_create-edit` reescrito como orquestrador de segurança especializado. Agora guia o dev pelas decisões (hash, sessão, proteções) antes de delegar à skill `auth-flow`. Contagem de workflows atualizada para 12.
- **1.3.0**: Adicionada skill `secure-storage` (Lote 7 — Skills de Domínio). Skill com methodology security-first: Discovery → Proposal → Implementation. Suporta Firebase, S3, GCS, Supabase, MinIO e disco local. Contagem de skills atualizada para 38.
- **1.4.0**: Adicionada skill `crud-api` (Lote 7 — Skills de Domínio). Skill especializada na arquitetura 4-camadas do ReservAqui (Entity → Service → Controller → Routes). Obriga Discovery de negócio + análise de schema SQL antes de implementar. Impõe Wrapper Pattern nos services e checklist de segurança/escalabilidade. Contagem de skills atualizada para 39.

## 11. Manual de Prompt

Este manual dita a **estrutura ideal de prompts** para maximizar a previsibilidade, precisão e qualidade da interação com a IA neste repositório. Para extrair o melhor do ecossistema Antigravity, as solicitações não devem ser genéricas; devem sempre prover contexto e evocar ativamente Personas (Agentes) e Módulos de Conhecimento (Skills) documentadas nas dependências.

### A Estrutura Ideal de um Prompt

Um prompt perfeitamente otimizado neste ecossistema obedece à seguinte hierarquia estrutural:

1. **Gatilho de Ação (Workflow)**: Caso seja uma tarefa roteirizada e macro, inicie estritamente com o Comando Slash (ex: `/create`, `/deploy`).
2. **Definição de Identidade (Agente Alvo)**: Usar a tag `@[nome-do-agente]` invoca explicitamente o especialista sem depender exclusivamente da interpretação orgânica do "Intelligent Routing".
3. **Injeção de Skill (Módulo de Restrição)**: Adicionar o comando `@[nome-da-skill]` no seu prompt instrui a IA a puxar e ler regras proibitivas ou arquiteturais vitais *antes* de pensar no Output.
4. **Contexto e Base Tecnológica**: Dizer claramente em qual ambiente estamos (Stack) e explicar o caso de negócio.
5. **Restrições de Gatilho (Opcional)**: Evitar desvios lembrando-a expressamente de alguma restrição clássica de uma skill (ex: "*Atenção, lembre-se da regra do Purple Ban*").

---

### Exemplos Práticos de Engenharia de Prompt

Abaixo, analise como os formatos de ordem se transformam dependendo da ferramenta estrutural desejada, passando de Workflows orquestrados a comandos de agente unitário:

#### Exemplo 1: Invocando um Workflow (Comandos Base / Ações Globais)
Workflows executam rotinas completas e pré-programadas em que IAs fazem "chain-of-thought" com ferramentas externas de sistema, não se limitando só a bater texto na tela. Deve-se providenciar estritamente os **Argumentos**.

> **Prompt Modelo:**
> `/ui-ux-pro-max` Preciso de um Design System totalmente focado e desenhado para ser uma interface analítica de saúde B2B. Gere os relatórios usando como base os artefatos de "Dark Mode MinimalTech" garantindo que os quadros sintéticos sigam regras universais e acessíveis. Não use gradientes agressivos.

#### Exemplo 2: Evocando Diretamente um Agente Especifico (Operação Singular)
Muitas vezes a tarefa depende única e exclusivamente de uma mentalidade (Backend, Frontend). Nesse caso, elimine a redundância invocando o profissional correto e guiando o escopo a apenas aquilo que lhe é de responsabilidade.

> **Prompt Modelo:**
> Usando o seu conhecimento nativo de `@[database-architect]`, eu quero injetar uma tabela polimórfica de Comentários no meu Schema `.sql` atual focado no App Principal. Valide estritamente as Constraints e certifique-se de que estamos evitando queries de alto processamento de forma relacional. Desenvolva uma query de Migration isolada para eu ler.

#### Exemplo 3: Unindo Agentes e Múltiplas Skills (Escopo Ultra-Restrito)
Esse é o Padrão Ouro de uso dentro do sistema. Força não apenas o Agente certo trabalhar, como amarra suas mãos utilizando skills injetadas em ambiente real. Traz alta previsibilidade anti-alucinação.

> **Prompt Modelo:**
> `@[frontend-specialist]`, peço que crie a estrutura DOM do Menu Sanduíche Principal (Sidebar Nav). Assuma que seu design deve obrigatoriamente fundir e ler as restrições proibitivas dispostas nativamente na skill `@[tailwind-patterns]`, eliminando redundâncias arbitrárias de `tailwind.config` usando CSS First. Use também a base mental descrita na skill `@[clean-code]`. Construa a funcionalidade e encerre sem explicar o óbvio!

#### Exemplo 4: Orquestrando Múltiplos Especialistas em Cascata (/orchestrate)
Imprescindível ao lançar "Épicos" inteiros em vez de apenas ajustar um script. Este prompt não permite atalhos fracos. O Multi-agente assume controle simultâneo dos fluxos, desenhando visões de mundo independentes sem ferir o código uns dos outros.

> **Prompt Modelo:**
> `/orchestrate` Vamos precisar refatorar a mecânica pesada do Carrinho de Compras, e isso transcende front e back. Por favor, ative a malha multi-agentes e inter-conecte a lógica do nosso Arquiteto Back-end `@[backend-specialist]` (para refatorar o endpoint POST com rate-limit) para dialogar estruturalmente com o front-end modernizado por parte de um `@[frontend-specialist]`. Submeta ambos outputs à peneira implacável final do `@[security-auditor]`. Aguardo o relatório da operação!


## 12. Anatomia de Criação

Este tópico descreve a anatomia estrutural fundamental para instanciar novos arquivos dentro do ecossistema `.agent/`. Para garantir uniformidade e previsibilidade nas respostas da IA, qualquer novo componente criado para a arquitetura deve obedecer aos esqueletos abaixo.

### 12.1 Criação de Agente (`.agent/agents/<agent>.md`)

Todo agente atua como uma Identidade (Persona). Ele deve restringir vigorosamente o próprio escopo e guiar explicitamente a atitude defensiva e criativa da LLM.

#### Corpo Padrão do Agente
```markdown
---
description: [Uma frase rápida prestando o resumo da função da persona]
skills:
  - [skill_dependencia_1]
  - [skill_dependencia_2]
---
# 🤖 [Nome do Agente]

## 1. Persona & Propósito
[Quem você é, O que defende e Qual seu Tom de voz]

## 2. Paradigmas e Regras
[Regras absolutas ditando as atitudes do agente e os limites invioláveis do seu poder]

## 3. Workflow Autônomo
[Como o agente raciocina passo-a-passo (chain of thought) ao receber um pedido dessa disciplina]
```

#### Perguntas a serem preenchidas na criação
Ao modelar um Agente do zero, faça-se estas perguntas cruciais:
1. **Nome e Ocupação Ouro:** Qual o cargo e autoridade dessa IA? (ex: `security-auditor`, não apenas `tester`).
2. **Mentalidade Sistêmica:** Ele foca em velocidade (hack), resiliência estrutural de longo prazo (arch), ou estabilidade defensiva final (qa)?
3. **Restrição Geocêntrica (Blindagem):** O que esse agente está expressamente **PROIBIDO** de tocar? Ele precisa transferir o problema ao invés de atuar em uma área que fere sua especialidade?
4. **Carga de Contexto (Skills):** Ele requer fundamentos puros externos para agir bem sem alucinar? (Declarar as habilidades de `SKILL.md` no painel YAML Frontmatter).

---

### 12.2 Criação de Skill (`.agent/skills/<skill>/SKILL.md`)

Ao contrário dos agentes, uma Skill **não possui personalidade**. Ela é um "Pendrive de Conhecimento" rígido voltado para aplicar restrições universais e padrões arquiteturais estáticos na máquina.

#### Corpo Padrão da Skill
```markdown
---
description: [Macro resumo do conjunto prático que esta skill transporta para a memória]
---
# 🧠 Skill: [Nome da Skill]

## 1. Princípios de Fundação
[Lista das premissas absolutas e heurísticas intocáveis da skill formatando "como" o agente age]

## 2. Anti-Patterns e Penalidades
[Padrões de mercado datados, ingênuos ou perigosos que o robô deve sumariamente repudiar nesta área]

## 3. Diretrizes de Injeção / Snippets
[Padrões sintáticos de checagem. Pode conter scripts que a skill exija que a IA chame para si antes da resposta local]
```

#### Perguntas a serem preenchidas na criação
Ao fundir um novo bloco de conhecimento, o autor baseia-se em:
1. **Mecanismo de Foco:** Esta matriz documenta "O que escrever" ou restringe severamente "Como codar com modernidade"? (Skills preferem governar os meios e bloqueios).
2. **Mapeamento de Alucinações:** Quais falhas generalistas de respostas das "IAs Clássicas da Internet" costumam matar o código nesta demanda e devem ser ativamente bloqueadas nesta base?
3. **Escopo Neutro:** Esta Skill é asséptica o suficiente de forma que possa ser importada por dezenas de agentes (Front + Mobile) simultaneamente sem entrar em conflito de personas?

---

### 12.3 Criação de Workflow (`.agent/workflows/<workflow>.md`)

Os Workflows são Trilhos Operacionais de Transações ("Slash-Commands"). Atuam para substituir interações lógicas passivas, ordenando rigorosamente o que deve ocorrer sequencialmente durante uma Pipeline.

#### Corpo Padrão do Workflow
```markdown
---
description: [Macro objetivo e gatilho a ser alvejado com a invocação do comando]
---
# ⚙️ Workflow: /[Nome do Comando Base]

## 1. Escopo de Entrada
[O contexto invocado pelo usuário escrevendo `/nome` bem como os modificadores de ação vindos de `/$ARGUMENTS`]

## 2. Ordem de Marcha Operacional
[A fila sequencial que bloqueia sub-tarefas. Fase 1: Execute X e Espere. Fase 2: Ative Script Python Y]

## 3. Portal Retentor de Danos (Blocking Gates)
[Disposição de regras sobre quando, onde e sob quais suspeições a máquina deve cruzar os braços, parar de compilar e inquirir autorização do humano].
```

#### Perguntas a serem preenchidas na criação
Todo comando slash a ser estruturado exige as seguintes formulações:
1. **Janela de Atuação:** Este pipeline age prematuramente num pre-código (como `/brainstorm`) ou age brutalmente pós-código (como `/deploy`)?
2. **Integração Física via Bash:** Durante as Fases, existirá a necessidade fundamental da Inteligência interagir fisicamente na CLI executando validações em arquivos Python para conseguir transitar de Fase?
3. **Check-out Point:** Qual o critério global de encerramento do script? Quais `Flags` exibidas graficamente vão acalmar o usuário, indicando a conclusão segura dos preceitos em tela?
