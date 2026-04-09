# Contexto de Implementação: manual-updater

## Descrição da Skill
A skill `manual-updater` tem o foco exclusivo de sincronizar e manter atualizado o arquivo estrutural do sistema `DOT_AGENTS_MANUAL.md`. 
Ela analisa o conteúdo das pastas `.agent/skills`, `.agent/agents` e `.agent/workflows` comparando-os com o texto listado no arquivo do manual, identificando discrepâncias (itens sobressalentes ou itens ausentes no manual).

## Arquivos Associados e Responsabilidades
- **`.agent/skills/manual-updater/SKILL.md`**: Define as diretivas de verificação proativa. Introduz um *gatekeeper* condicional onde se os parâmetros não forem passados, a skill pergunta diretamente ao usuário *quais itens deseja atualizar* ou se deseja uma verificação em branco (completa).
- **`.agent/skills/manual-updater/scripts/sync_manual.py`**: O script nativo desta skill acessado para listar todas as rotas de agents, skills e workflows e procurar suas strings dentro do arquivo `DOT_AGENTS_MANUAL.md`. Serve para prevenir estouro do contexto do LLM durante verificações totais do repósitório em comparação ao manual.

## Histórico de Implementação
- **2026-04-08**: A skill foi criada e desenhada sob a requisição do usuário de automatizar o processo de indexação no manifesto central. O script sync acoplado serve para não depender dos limites do agente de ler dezenas de pastas e arquivos de uma vez só manualmente. 
