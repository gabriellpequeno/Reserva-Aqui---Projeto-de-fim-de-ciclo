# Workflow — ReservAqui

## Pipeline de Desenvolvimento

Todo trabalho no projeto segue este fluxo em ordem. Não pule etapas.

```
product.md → prd.md → features/*.prd.md → specs/*.spec.md → plan.md → código → commit → PR
```

| Etapa | Arquivo | Quando criar |
|-------|---------|-------------|
| Project Brief | `conductor/product.md` | Dia zero — já existe |
| PRD do Produto | `conductor/prd.md` | Antes de qualquer implementação — já existe |
| PRD de Feature | `conductor/features/{feature}.prd.md` | Ao decidir implementar uma feature grande |
| Spec Técnica | `conductor/specs/{feature}.spec.md` | Após PRD de Feature aprovado |
| Plan | `conductor/plan.md` | Após primeira Spec — atualizado continuamente |
| Implement | código-fonte | Ao pegar uma task `[ ]` do plan |
| Commit | git | Ao concluir uma task |
| PR | GitHub | Ao concluir uma fase do plan |

---

## Quando criar um PRD de Feature?

Crie sempre que a feature envolver:
- Mais de 3 arquivos de código
- Interação com serviço externo (Meta, Gemini, InfinitePay, etc.)
- Mudança no banco de dados
- Nova tela no app

**Não precisa** para: correção de bug, refatoração, ajuste visual simples.

---

## Ciclo de uma Task

```
1. Abra plan.md → escolha a próxima task [ ] em ordem
2. Mude para [~] (em progresso)
3. Leia a spec da feature antes de codar
4. Implemente o mínimo necessário para completar a task
5. Teste manualmente o fluxo afetado
6. Mude para [x] + hash do commit
7. Faça o commit
```

---

## Comandos do Projeto

### Frontend (Flutter)
```bash
# Instalar dependências
flutter pub get

# Rodar no Chrome (web)
flutter run -d chrome

# Rodar no emulador/dispositivo
flutter run

# Build web
flutter build web

# Analisar código
flutter analyze

# Formatar código
dart format .
```

### Backend (Node.js)
```bash
# Instalar dependências
npm install

# Rodar em desenvolvimento (com hot reload)
npm run dev

# Build TypeScript
npm run build

# Rodar em produção
npm start

# Lint
npm run lint

# Testes
npm test
```

### Infraestrutura (Docker)
```bash
# Subir todos os serviços
docker-compose up -d

# Subir e rebuildar
docker-compose up -d --build

# Ver logs
docker-compose logs -f

# Parar tudo
docker-compose down
```

---

## Commit Guidelines

### Formato
```
<tipo>(<escopo>): <descrição curta>

[corpo opcional — o que e por que]
```

### Tipos

| Tipo | Quando usar | Exemplo |
|------|-------------|---------|
| `feat` | Feature nova | `feat(auth): implementar login com Google` |
| `fix` | Correção de bug | `fix(whatsapp): corrigir timeout no webhook POST` |
| `docs` | Só documentação | `docs(prd): atualizar features de notificação` |
| `refactor` | Melhoria sem mudar comportamento | `refactor(rag): extrair RagService para módulo próprio` |
| `chore` | Infra, configs, deps | `chore(docker): adicionar Qdrant ao compose` |
| `test` | Só testes | `test(reservas): adicionar teste de cancelamento` |
| `conductor` | Atualização do plan | `conductor(plan): marcar fase auth como concluída` |

### Exemplos reais do projeto
```bash
git commit -m "feat(whatsapp): implementar webhook de recebimento de mensagens"
git commit -m "feat(rag): criar RagService com LangChain e Gemini Flash"
git commit -m "feat(reservas): fluxo de criação de reserva via conversa no WhatsApp"
git commit -m "fix(router): corrigir botão voltar sem fallback em NotificationsPage"
git commit -m "conductor(plan): marcar Fase 1 — Infraestrutura como concluída"
```

---

## Quality Gates

Antes de marcar qualquer task como `[x]`, verifique:

- [ ] O fluxo afetado funciona manualmente (teste você mesmo)
- [ ] Não quebrou nenhuma tela ou rota existente
- [ ] Código segue o style guide da linguagem (`code_styleguides/`)
- [ ] Sem `any` em TypeScript; sem `dynamic` desnecessário em Dart
- [ ] Sem segredos hardcoded (chaves de API, senhas)
- [ ] Funciona em mobile E web (se for Flutter)

---

## Definition of Done

Uma task está concluída quando:

1. Implementada conforme a spec da feature
2. Testada manualmente no fluxo principal
3. Código formatado e sem erros de lint
4. Commit feito com mensagem no formato correto
5. `plan.md` atualizado com `[x]` e hash do commit

---

## PR (Pull Request)

Abra um PR ao concluir uma fase completa do `plan.md`.

### Template
```markdown
## O que essa PR entrega
<2-3 frases>

## Arquivos alterados
| Arquivo | Tipo | O que faz |
|---------|------|-----------|
| `src/services/rag.service.ts` | NEW | Serviço RAG com LangChain |

## Como testar
1. `docker-compose up --build`
2. <passos específicos>
3. Resultado esperado: <o que deve acontecer>

## Checklist
- [ ] Fluxo principal funciona
- [ ] Sem erros de lint
- [ ] plan.md atualizado
- [ ] Spec seguida fielmente
```

---

## Regras de Ouro

1. **O `prd.md` é a fonte de verdade do produto.** Em caso de dúvida sobre o que implementar, consulte-o.
2. **O `plan.md` é a fonte de verdade do progresso.** Nunca trabalhe em algo que não está no plan.
3. **Mudança de tech stack?** Documente em `tech-stack.md` antes de implementar.
4. **Feature nova surgiu durante o desenvolvimento?** Crie o PRD de Feature antes de codar.
5. **Nunca commite diretamente na `main`.** Sempre via PR de branch de feature.
