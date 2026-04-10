# Playbook: criar app novo (ex-`/create`)

## Objetivo

Iniciar um **novo** aplicativo do zero com stack e escopo alinhados ao pedido.

## Entrada

- Tipo de produto, funcionalidades minimas, usuarios-alvo (se souber).

## Passos

1. **Clarificar**
   - Se o pedido for vago, usar skill `brainstorming` antes de definir stack.

2. **Planejar**
   - Quebrar em entregas; definir stack e estrutura de pastas esperada.
   - Gerar plano em `docs/PLAN-<slug>.md` (ver playbook `plan.md`).

3. **Construir (apos alinhamento)**
   - Ordem tipica: dados/modelo -> API/backend -> UI -> testes essenciais.
   - Seguir convencoes do repositorio; se repo vazio, seguir melhor pratica da stack escolhida.

4. **Preview**
   - Subir servidor local conforme framework; informar URL e comando usado.

## Regras

- Nao codar antes de requisitos minimos e stack estarem aceitos (ou explicitamente assumidos e registrados).
- Documentar comandos para rodar e testar no README se o projeto for novo.

## Saida esperada

- Esqueleto ou app funcional minimo; plano ou checklist de proximos passos.
