# INFRA-3 — readme

## Objetivo
Reescrever o README do projeto com informações completas: como executar o projeto, stack tecnológica, scripts disponíveis, variáveis de ambiente e colaboradores.

## Prioridade
**Documentação do projeto** — necessário para qualquer novo colaborador ou avaliador conseguir subir o projeto do zero.

## Branch sugerida
`infra/readme`

---

## O que precisa ser feito

- [ ] Escrever seção **Visão Geral** descrevendo o produto e seus módulos (Backend, Frontend, IA, Notificações, Pagamentos, WhatsApp)
- [ ] Escrever seção **Stack Tecnológica** em formato de tabela
- [ ] Escrever seção **Pré-requisitos** (Node.js 20+, Docker, Flutter SDK ^3.9.2)
- [ ] Escrever seção **Configuração do Ambiente** — passo a passo do `.env.example` → `.env` com variáveis obrigatórias destacadas
- [ ] Escrever seção **Executando o Backend**:
  - [ ] Opção A: com Docker (`docker compose up --build`)
  - [ ] Opção B: sem Docker (`npm install` + `npm run dev`)
- [ ] Escrever seção **Executando o Frontend** (`flutter pub get` + `flutter run`)
- [ ] Escrever seção **Seeds** com tabelas de credenciais de acesso (admin, usuários, hotéis)
- [ ] Escrever seção **Scripts Disponíveis** — tabela com todos os `npm run ...`
- [ ] Escrever seção **Estrutura do Projeto** — árvore de diretórios
- [ ] Escrever seção **Variáveis de Ambiente** — resumo das obrigatórias
- [ ] Escrever seção **Colaboradores** — apenas os colaboradores ativos (não incluir Noah-Shicksal)

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `README.md` | **Reescrever** — atualmente contém apenas 3 linhas sem conteúdo útil |

---

## Dependências
- **Requer:** INFRA-2 (seed completa) — para incluir as credenciais corretas na seção Seeds
- **Requer:** `Backend/.env.example` atualizado — para listar variáveis de ambiente corretamente

## Bloqueia
- Onboarding de novos colaboradores
- Avaliação do projeto por terceiros

---

## Observações
- Não incluir **Noah-Shicksal** na lista de colaboradores
- Credenciais da seção Seeds devem ser exatamente as mesmas geradas pela `seed.completo.ts`
- Instrução de onde colocar imagens reais (para substituir os mocks da seed) deve aparecer na seção Seeds
- Para emulador Android, mencionar que a base URL da API deve ser `http://10.0.2.2:3000`
