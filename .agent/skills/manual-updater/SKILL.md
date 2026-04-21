---
name: manual-updater
description: "Skill for updating, adding, or removing entries in ./Documantation/dot-agents-manual.md based on new or modified agents, skills, and workflows."
---

# `manual-updater` Skill

> 🤖 **Goal:** Automatizar a manutenção e atualização do arquivo `./Documantation/dot-agents-manual.md` para garantir que a documentação de Agents, Skills e Workflows esteja sempre síncrona com o código.

## 📥 Fluxo de Execução Obrigatório

Sempre que esta skill for invocada pela instrução do usuário, siga **ESTRITAMENTE** as etapas abaixo.

### 1. Validação da Entrada
Ao ser ativado, a primeira coisa que o Agente deve verificar internamente é se foram fornecidos nomes de componentes específicos a serem atualizados (ex: "atualize a skill app-builder", "verifique os agents xyz e abc").

### 2. O Gatekeeper (Se NULO)
Se o usuário **não** fornecer quais skills/agents/metodos atualizar na chamada:
- **PARE IMEDIATAMENTE** e responda a seguinte pergunta:
  > `"Qual ou quais skills/metodo/agents devo atualizar?"`
Aguarde a resposta do usuário antes de continuar.

### 3. Operação Direcionada (Se nomes passados)
Caso a resposta contenha um ou mais nomes separados por linha ou vírgula:
1. Separe os nomes listados pelo usuário.
2. Para cada nome, faça uma varredura nas pastas `.agent/skills/`, `.agent/agents/` ou `.agent/workflows/` utilizando ferramentas de listagem de arquivos ou busca para encontrar suas respectivas configurações (ex.: `.md`).
3. Leia o estado atual de `./Documantation/dot-agents-manual.md`.
4. **Análises & Ações:**
   - **Atualizar/Adicionar:** Se o arquivo referenciado existir no sistema, atualize sua referência no `./Documantation/dot-agents-manual.md` para refletir sua descrição precisa, adicionando a categoria correspondente.
   - **Remover:** Caso o nome fornecido exista em `./Documantation/dot-agents-manual.md` mas não exista na pasta `.agent/` (ou seja, o próprio arquivo foi apagado no sistema), **remova-o** da documentação do manual.

### 4. Operação de "Iteração Total" (Se a resposta ao Gatekeeper for VAZIA/Nenhuma)
Se a resposta à pergunta for expressamente "nenhuma", "todas", "vazia" (se ele der enter sem parâmetros extras) ou intencionalmente quiser um *resync* global:
1. Invoque o script nativo desta skill `python .agent/skills/manual-updater/scripts/sync_manual.py`. Isso evitará problemas de contexto muito longo (estouro de token limite ao ler todos os arquivos ao mesmo tempo).
2. O script vai analisar todos os diretórios em `.agent/` e cruzá-los com as entradas do `./Documantation/dot-agents-manual.md`. Ele imprimirá no terminal o que existe no repositório que falta no manual, e o que está no manual que já não está no repositório.
3. Leia o terminal contendo essa saída.
4. Adicione e remova as referências conforme o painel gerado pelo script em `./Documantation/dot-agents-manual.md`.

## 📌 Regras Extritas
- **Não minta no manual.** Baseie qualquer explicação no arquivo real (`SKILL.md`, arquivo do agent etc), ou a partir do resumo do script.
- **Estruturação.** Mantenha a formatação visual, os links baseados ou blocos markdown fiéis ao formato em que `./Documantation/dot-agents-manual.md` é mantido.
