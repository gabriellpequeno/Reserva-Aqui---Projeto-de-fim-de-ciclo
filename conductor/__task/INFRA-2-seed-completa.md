# INFRA-2 — seed-completa

## Objetivo
Criar uma seed completa com dados realistas para popular o banco em ambiente de desenvolvimento e apresentação do projeto.

## Prioridade
**Bloqueador de demonstração** — sem a seed, o app sobe vazio e não é possível demonstrar fluxos de reserva, avaliação ou chatbot.

## Branch sugerida
`infra/seed-completa`

---

## O que precisa ser feito

### Dados obrigatórios
- [ ] 1 admin (via SQL direto, mesmo padrão do `seed.admin.ts`)
- [ ] Ao menos 6 usuários (hóspedes) com dados completos, criados via `registerUsuario()`
- [ ] Ao menos 5 hotéis em 5 cidades/estados diferentes, criados via `registerAnfitriao()`
- [ ] Ao menos 5 categorias de quarto por hotel via `createCategoriaQuarto()`
- [ ] Ao menos 2 quartos por categoria via `createQuarto()`
- [ ] Itens de comodidade por categoria via `addCategoriaItem()`
- [ ] Configuração de check-in/check-out por hotel via `configurarHotel()`
- [ ] Fotos mockadas para hotéis e quartos (DELETE + INSERT — sem `ON CONFLICT`)
- [ ] Reservas para cada usuário em hotéis distintos
- [ ] Ao menos 6 avaliações por hotel com comentários realistas

### Regras de implementação
- [ ] `data_nascimento` dos usuários no formato `dd/mm/aaaa` (exigido por `Usuario.validate()`)
- [ ] Fotos inseridas com padrão DELETE + INSERT (tabelas `quarto_foto` e `foto_hotel` não têm `UNIQUE` em `storage_path`)
- [ ] Avaliações com `ON CONFLICT DO NOTHING` (tabela `avaliacao` tem `UNIQUE(user_id, reserva_id)`)
- [ ] Seed deve ser idempotente — pode ser executada múltiplas vezes sem duplicar dados
- [ ] Registrar a seed no orquestrador `index.ts`

### Imagens mock
- [ ] Inserir paths no padrão `hotels/{hotel_id}/cover/portrait/seed-cover-portrait.jpg`
- [ ] Documentar no README aonde colocar imagens reais para substituir os mocks

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `Backend/src/database/seeds/seed.completo.ts` | **Criar** — seed completa |
| `Backend/src/database/seeds/index.ts` | Adicionar entrada `completo` no array `SEEDS` |

---

## Dependências
- **Requer:** Banco rodando (`npm run db:reset` ou Docker)
- **Não depende de** nenhuma outra task de código

## Bloqueia
- Demonstração dos fluxos completos do app (reserva, avaliação, chatbot)
- Testes manuais de qualquer funcionalidade que dependa de dados pré-existentes

---

## Observações
- Admin: usar SQL direto (`ON CONFLICT DO NOTHING` no email) — não passar por `registerUsuario()`
- Usuários regulares: obrigatório usar `registerUsuario()` — faz validate + hash argon2id + parseDataBrToEn
- Hotéis: obrigatório usar `registerAnfitriao()` — provisiona o schema tenant automaticamente
- Storage path relativo ao `UPLOAD_DIR` (`Backend/storage/`) é o que vai para o banco — não o caminho absoluto
- Após criar cada hotel, chamar `DynamicIngestionService.ingestHotelData()` para indexar no RAG (pgvector)
