# Escopo do Projeto – Plataforma de Gestão de Hotéis com IA

Documento de recorte de escopo priorizado para desenvolvimento em ~1 mês.

---

## Visão Geral

Objetivo: plataforma onde o hóspede inicia atendimento via WhatsApp, dados são processados por uma API com IA (LangChain + RAG) e sincronizados em tempo quase real com apps Flutter para Cliente e Fornecedor.

Foco do MVP:
- Fluxo básico de reserva.
- Chatbot respondendo dúvidas frequentes (RAG em poucos documentos).
- Geração de roteiro turístico simples via IA.
- Sincronização WhatsApp ↔ Backend ↔ Apps Flutter.

Nice to have: recursos adicionais de UX, automações e relatórios se sobrar tempo.

---

## Frontend – App Cliente (Flutter)

### MVP (obrigatório)

1. **Autenticação simples**
   - Tela de login/cadastro básico.
   - Armazenar sessão/token localmente.

2. **Explorar hotéis/quartos**
   - Lista de hotéis/quartos com filtros simples (data de entrada/saída, capacidade).
   - Tela de detalhes do quarto (fotos, descrição resumida, comodidades principais).
   - Botão "Reservar" que abre fluxo de criação de reserva.

3. **Minhas reservas**
   - Lista de reservas do usuário (status: pendente, confirmada, concluída/cancelada).
   - Detalhe da reserva com datas, tipo de quarto e número de confirmação.

4. **Chat com o hotel / assistente**
   - Tela de chat exibindo mensagens em formato de conversa (user vs hotel/bot).
   - Integração com backend para listar histórico e enviar novas mensagens.
   - Indicar visualmente quando a mensagem veio do WhatsApp ou do app (discreto).

5. **Roteiro turístico gerado por IA**
   - Tela para o usuário informar: destino, datas, interesses (ex.: gastronomia, natureza, cultura) e orçamento aproximado.
   - Chamada a um endpoint `/itinerario` e exibição do resultado em formato:
     - Lista por dia (Dia 1, Dia 2, ...).
     - Em cada dia, cards de atividades com título, descrição breve e horário aproximado.

### Nice to Have (se sobrar tempo)

1. **Tema claro/escuro**
   - Suporte a light/dark mode baseado no sistema, inspirado em templates de booking.

2. **Refino do roteiro**
   - Ações do tipo "regenerar dia", "trocar atividade", ou "ajustar para orçamento menor".

3. **Notificações in-app**
   - Avisos simples dentro do app quando a reserva for confirmada ou houver atualização no roteiro.

---

## Frontend – App Fornecedor / Dashboard (Flutter)

### MVP (obrigatório)

1. **Login do fornecedor**
   - Perfil específico para staff/hotel.

2. **Visão de reservas**
   - Lista de reservas do dia e/ou por período.
   - Filtros simples (data, status).
   - Ação básica: atualizar status da reserva (pendente → confirmada → concluída/cancelada).

3. **Inbox de conversas**
   - Lista de conversas (1 por hóspede).
   - Tela de chat exibindo mensagens do hóspede e respostas enviadas (seja via WhatsApp, seja via painel).
   - Campo para responder manualmente (além do chatbot).

4. **Visualização de roteiros**
   - Para cada hóspede, visualizar o roteiro gerado pela IA (somente leitura), para o staff ter contexto.

### Nice to Have

1. **Indicadores simples de operação**
   - Pequenos cards com: ocupação de hoje (%), número de hóspedes, número de reservas pendentes.

2. **Filtro avançado e busca**
   - Buscar reservas por nome, telefone ou e-mail.

3. **Ações rápidas na inbox**
   - Botões de atalho por mensagem (ex.: "marcar serviço", "enviar link de avaliação"), chamando endpoints específicos do backend.

---

## Backend – API / Orquestração (FastAPI ou Node)

### MVP (obrigatório)

1. **Camada REST básica**
   - Endpoints para:
     - Autenticação (login/cadastro).
     - CRUD de hotéis/quartos (pode ser mínimo, suficientes para demo).
     - CRUD de reservas.
     - Listar e enviar mensagens (chat).
     - Gerar roteiro (`POST /itinerario`).

2. **Integração WhatsApp Cloud API (mínima)**
   - Endpoint webhook `/whatsapp/webhook` para receber mensagens.
   - Lógica para:
     - Identificar usuário (por telefone).
     - Registrar mensagem no banco.
     - Encaminhar texto para pipeline de IA.
     - Enviar resposta de volta via WhatsApp.

3. **Pipeline de IA com LangChain/LangGraph**
   - Componentes mínimos:
     - LLM (Gemini ou outro com free tier).
     - RAG simples para perguntas frequentes.
     - Tool de geração de roteiro.
   - Fluxo:
     - Se mensagem for sobre roteiros (detectar por palavra-chave ou intenção simples), chamar função de geração de itinerário.
     - Caso contrário, usar RAG com base de conhecimento do hotel.

4. **Tools para operações de negócio (simples)**
   - Funções expostas para o agente:
     - `buscar_disponibilidade_quarto(data_in, data_out, tipo_quarto)`.
     - `criar_reserva(id_cliente, id_quarto, data_in, data_out)`.
     - `registrar_servico(id_cliente, tipo_servico, data)` (opcional).
   - No MVP, podem ser implementadas como funções normais da API, chamadas diretamente pela aplicação, sem necessidade de agente complexo tomando decisões encadeadas.

5. **Sincronização com apps Flutter**
   - Os mesmos endpoints de chat e reservas usados pelo WhatsApp alimentam o app.
   - Atualizações em tempo quase real via consultas periódicas (polling) ou, se houver tempo, websockets.

### Nice to Have

1. **Agente mais inteligente com uso de tools**
   - Permitir que o LLM decida quando chamar `buscar_disponibilidade_quarto` e `criar_reserva` com base em mensagens naturais, usando o padrão Agent + Tools.

2. **Triggers automáticos (journey do hóspede)**
   - Jobs simples (cron) para enviar mensagens automáticas:
     - Lembrete de check-in.
     - Mensagem de boas-vindas.
     - Pedido de feedback ao final da estadia.

3. **Camada de autorização mais refinada**
   - Regras de acesso mais detalhadas por papel (ex.: recepção, gerente, etc.).

---

## Banco de Dados / Dados

### MVP (obrigatório)

1. **Banco relacional ou NoSQL**
   - PostgreSQL ou MongoDB com coleções/tabelas básicas:
     - `usuarios` (cliente x fornecedor, dados de login).
     - `hoteis` / `quartos`.
     - `reservas`.
     - `mensagens` (chat, com origem: WhatsApp/app, e remetente: cliente/bot/staff).
     - `roteiros` (JSON do itinerário gerado para cada usuário).

2. **Mínima modelagem para integridade**
   - Chaves estrangeiras entre reservas, usuários e quartos.
   - Índices simples nas colunas de busca (telefone, id_usuario, data).

### Nice to Have

1. **Histórico de versões de roteiros**
   - Permitir guardar múltiplas versões do roteiro de um mesmo usuário.

2. **Logs de uso da IA**
   - Tabela simples de logs para analisar chamadas à IA, tokens, tempo de resposta (útil para tuning e apresentação).

---

## IA, RAG e Itinerários

### MVP (obrigatório)

1. **LLM em nuvem (free tier)**
   - Usar Gemini (modelo Flash ou equivalente) via API, configurado via variáveis de ambiente.
   - Chamadas feitas através de LangChain/LangGraph.

2. **RAG simples para o hotel**
   - Ingestão de poucos documentos-chave:
     - Políticas do hotel.
     - Tipos de quarto e serviços.
     - Regras de cancelamento / check-in / check-out.
   - Vector DB pequeno (Qdrant ou similar) rodando em Docker.
   - Pipeline: busca top-k trechos + prompt para o LLM responder com base nesses trechos.

3. **Geração de roteiro turístico**
   - Função dedicada que recebe: destino, datas, orçamento, interesses.
   - Prompt que pede resposta em JSON estruturado, com campos como:
     - `dias`: lista de dias, cada um com atividades.
     - `atividades`: título, descrição, horário aproximado, tipo (passeio, refeição, etc.).
   - Backend valida e envia esse JSON para o app Flutter.

### Nice to Have

1. **Refino iterativo do roteiro**
   - Permitir que o usuário peça ajustes (menos caminhadas, foco em gastronomia, etc.), reaproveitando o roteiro anterior como contexto.

2. **RAG também para roteiros**
   - Adicionar uma base de pontos turísticos locais para enriquecer as sugestões.

---

## Infraestrutura e DevOps

### MVP (obrigatório)

1. **Containers leves (Docker)**
   - 1 container para API (FastAPI/Node).
   - 1 container para banco (Postgres/MongoDB).
   - 1 container para vector DB (Qdrant), se utilizado.

2. **Configuração por ambiente**
   - Variáveis de ambiente para chaves de API (LLM, WhatsApp), URLs de banco, etc.
   - Arquivos de configuração simples (ex.: `docker-compose.yml`) para subir tudo no servidor do professor.

3. **Log básico e monitoramento simples**
   - Logs de requisições e erros em arquivo ou stdout.

### Nice to Have

1. **Ambiente de desenvolvimento x produção**
   - Separar configs (ex.: usar banco local no dev e remoto no servidor do professor).

2. **Scripts de inicialização da base de conhecimento (RAG)**
   - Script que lê PDFs/arquivos de regras e reindexa no vector DB.

---

## Resumo do que focar primeiro

1. **Definir modelos de dados básicos** (usuário, quarto, reserva, mensagem, roteiro).
2. **Subir API simples** com endpoints de reservas, chat e itinerário.
3. **Integrar o LLM em nuvem** para:
   - Responder perguntas frequentes com RAG.
   - Gerar um roteiro inicial.
4. **Criar apps Flutter** com foco em:
   - Fluxos principais (listar quartos, reservar, ver reservas, ver roteiro, chat).
   - Dashboard simples para o fornecedor (reservas + inbox).
5. **Somente depois**, se houver tempo, adicionar nice to haves:
   - Tema dark/light, refinamento de roteiro, indicadores analíticos, automações extras.
