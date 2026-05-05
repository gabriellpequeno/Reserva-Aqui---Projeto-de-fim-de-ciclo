# PRD do Produto — ReservAqui

> Documento de referência de produto. Lista todas as features do sistema, separadas em MVP e Nice to Have, com critérios de aceite globais e fluxo de demonstração.
>
> **Fonte de verdade para priorização.** Em caso de conflito com outros documentos, este prevalece.

---

## Visão Geral

**ReservAqui** é uma plataforma multi-tenant de gestão hoteleira que conecta hóspedes e hotéis através de WhatsApp, apps mobile (Flutter) e inteligência artificial.

O diferencial central é eliminar a fricção da reserva: o hóspede pode reservar, tirar dúvidas e pedir um roteiro turístico diretamente pelo WhatsApp — sem precisar baixar um app ou criar uma conta. O app mobile complementa com histórico, notificações e uma experiência mais completa para usuários recorrentes.

**Contexto:** Projeto acadêmico de fim de ciclo — MVP funcional para apresentação em 08/05/2026.
**Time:** 5 pessoas (2 front, 1 back, 1 IA, 1 infra/DevOps).

---

## Personas

### 1. Hóspede (Guest / User)
Classe média e média-alta que viaja a lazer, negócios ou eventos. Busca praticidade, custo-benefício e personalização. Sua principal dor é a fricção do processo atual: baixar app → criar conta → fazer reserva. Usa WhatsApp diariamente e quer que o processo seja tão simples quanto mandar uma mensagem.

Dor secundária: agências de turismo são caras e não oferecem roteiros flexíveis.

### 2. Fornecedor (Host)
Hotel de médio ou grande porte que quer aumentar a base de clientes e automatizar o atendimento. Perde reservas por não conseguir responder a demanda em tempo real. Quer ter controle sobre o status das reservas e visibilidade das métricas do seu estabelecimento.

### 3. Admin da Plataforma
Responsável pela gestão global da plataforma. Tem visão de todos os hotéis e usuários. Para o MVP, o papel de admin é operacional (gestão de dados), sem painel analítico avançado.
   
---

## Plataformas e Canais

| Canal | Obrigatório |
|-------|-------------|
| App mobile — iOS/Android (celular + tablet) | MVP |
| App mobile — Web (browser) | MVP |
| Responsividade portrait + landscape | MVP |
| Layout dedicado para tablet | Nice to Have |
| WhatsApp (via WhatsApp Cloud API) | MVP |1

**Tema:** Light e Dark mode obrigatórios em todas as plataformas.

---

## Autenticação

| Feature | Prioridade |
|---------|-----------|
| Login com e-mail e senha | MVP |
| Login com Google (OAuth) | MVP |
| Cadastro de novo usuário | MVP |
| Esqueci minha senha | MVP |
| JWT com refresh token | MVP |
| Modo Guest via WhatsApp (identificado por número de telefone) | MVP |
| Vinculação automática: número de telefone = conta existente → histórico unificado | MVP |

**Regra do Guest:** Se o número de telefone do WhatsApp não corresponde a nenhuma conta cadastrada, o usuário é tratado como guest. Reservas e histórico ficam vinculados ao número. Se posteriormente ele criar uma conta com esse número, o histórico é unificado.

---

## Features MVP

### Canal WhatsApp

| Feature | Critério de Aceite |
|---------|-------------------|
| Hóspede consulta disponibilidade de quartos | Bot retorna opções disponíveis para as datas informadas |
| Hóspede faz perguntas sobre o hotel | RAG responde com base no FAQ/políticas do hotel em até 10s |
| Bot interpreta intenção do usuário | Distingue: dúvida / reserva / roteiro / outro |
| Hóspede cria reserva via conversa | Fluxo completo: escolha de quarto → datas → pagamento → confirmação |
| Integração com InfinitePay para pagamento | Pagamento processado dentro do fluxo do WhatsApp |
| Confirmação da reserva via WhatsApp | Hóspede recebe mensagem de confirmação + PDF do ticket |
| Hóspede pede roteiro turístico | Bot gera sugestões baseadas no destino e período da hospedagem |
| Bot recebe e interpreta áudio | Usuário pode mandar áudio; bot processa e responde em texto |
| Bot recebe e interpreta imagem | Usuário pode mandar imagem; bot processa e responde em texto |

> **Nota:** O bot NÃO envia áudio nem imagem — apenas recebe, interpreta e responde em texto.

---

### App Mobile — Hóspede

#### Autenticação e Perfil
| Feature | Prioridade |
|---------|-----------|
| Tela de login (e-mail/senha + Google) | MVP |
| Tela de cadastro | MVP |
| Tela de esqueci minha senha | MVP |
| Tela de perfil do usuário | MVP |

#### Explorar e Reservar
| Feature | Prioridade |
|---------|-----------|
| Lista de hotéis/quartos com filtros (datas, capacidade) | MVP |
| Tela de detalhes do quarto (fotos, descrição, comodidades) | MVP |
| Avaliações de outros hóspedes na tela de detalhes | MVP |
| Fluxo de reserva: escolher datas → confirmar → pagamento | MVP |
| Integração com InfinitePay no app | MVP |

#### Minhas Reservas
| Feature | Prioridade |
|---------|-----------|
| Lista de reservas com status (pendente, confirmada, em andamento, concluída, cancelada) | MVP |
| Detalhe da reserva (datas, quarto, número de confirmação) | MVP |
| Solicitar cancelamento de reserva | MVP |

#### Chat e IA
| Feature | Prioridade |
|---------|-----------|
| Chat com o bot no app (mesmo comportamento do WhatsApp) | MVP |
| Chat in-app com staff humano do hotel | Nice to Have |

#### Notificações
| Gatilho | Prioridade |
|---------|-----------|
| Reserva confirmada pelo hotel | MVP |
| Reserva cancelada | MVP |
| Lembrete de check-in se aproximando | MVP |
| Nova mensagem no chat | MVP |
| Solicitação de avaliação após check-out | MVP |
| Roteiro turístico gerado | Nice to Have |

#### Avaliações
| Feature | Prioridade |
|---------|-----------|
| Hóspede visualiza avaliações na tela de detalhes do hotel | MVP |
| Hóspede submete avaliação após hospedagem concluída | MVP |

---

### App Mobile — Fornecedor (Host)

O fornecedor não possui um dashboard separado. Toda a gestão acontece a partir do **perfil do fornecedor**, organizado em seções.

| Feature | Prioridade |
|---------|-----------|
| Login/Cadastro do fornecedor | MVP |
| Perfil hub com métricas (reservas recebidas, quartos cadastrados, etc.) | MVP |
| Seção: lista de reservas com histórico e filtros | MVP |
| Alterar status de reserva: confirmar / cancelar / iniciar hospedagem / finalizar | MVP |
| Busca avançada de reservas (por nome, telefone ou e-mail) | MVP |
| Seção: gerenciar quartos (cadastrar, editar) | MVP |
| Seção: inbox de conversas com hóspedes | Nice to Have |
| Responder hóspede manualmente pelo painel | Nice to Have |
| Visualizar e responder avaliações | Nice to Have |

---

### App Mobile — Admin da Plataforma

| Feature | Prioridade |
|---------|-----------|
| Login do admin | MVP |
| Visão geral da plataforma (hotéis, usuários, reservas) | MVP |
| Gestão de usuários e hotéis | MVP |

---

### Inteligência Artificial

| Feature | Prioridade |
|---------|-----------|
| RAG: responder perguntas com base nos documentos do hotel | MVP |
| Classificação de intenção (dúvida / reserva / roteiro) | MVP |
| Geração de roteiro turístico com base no destino e período da hospedagem | MVP |
| Criação de reserva via conversa (aciona ferramentas do backend) | MVP |
| Recepção e interpretação de áudio e imagem | MVP |
| Refinamento iterativo do roteiro ("regenerar dia", "ajustar orçamento") | Nice to Have |
| RAG para roteiros (base de pontos turísticos locais) | Nice to Have |

---

## Features Nice to Have

> Entram apenas se houver tempo disponível após o MVP completo e testado.

| Feature | Área |
|---------|------|
| Tela de roteiro turístico com aba dedicada (cards por dia) | App — Hóspede |
| Chat in-app com staff humano do hotel | App — Hóspede |
| Notificação quando roteiro é gerado | App — Hóspede |
| Inbox de conversas no perfil do fornecedor | App — Fornecedor |
| Resposta manual do fornecedor pelo painel | App — Fornecedor |
| Visualização e resposta de avaliações pelo hotel | App — Fornecedor |
| Refinamento iterativo do roteiro | IA |
| RAG para roteiros com base de pontos turísticos | IA |
| Histórico de versões de roteiro | Backend |
| Exportação de dados (Excel, PDF) | Backend |
| Envio do roteiro como PDF | Backend / WhatsApp |
| Multi-idioma (EN/ES) | App |
| Layout dedicado para tablet | App |
| Triggers automáticos do hotel (lembrete pré-check-in via WhatsApp) | Backend / IA |

---

## Fora de Escopo

> Itens que **não serão implementados**, nem como nice to have.

- Sistema de fidelidade ou pontos por reserva
- Integração com canais além do WhatsApp (Instagram, Telegram, etc.)
- Bot enviar áudio ou imagem (só recebe e interpreta)
- Multi-tenant em produção real (MVP usa dados simulados via seed)
- Relatórios analíticos avançados com gráficos (métricas simples no perfil do host são MVP)
- Pagamentos parcelados ou múltiplos métodos além do InfinitePay

---

## Seed de Demonstração

Para que a apresentação funcione sem dados reais, o banco será pré-populado com:

| Dado | Quantidade |
|------|-----------|
| Hotéis fictícios | 5 |
| Quartos por hotel | 5 |
| Hóspedes pré-cadastrados (com avaliações) | 6 |
| Fornecedores pré-cadastrados (1 por hotel) | 5 |
| Admin | 1 |
| Reservas por hóspede (1 para cada status) | 5 status × seeds |
| Avaliações (mínimo 1 por hóspede) | 6 |
| Documentos RAG por hotel (FAQ + políticas) | 1 por hotel |

---

## Fluxo Principal de Demonstração

Este é o fluxo que será mostrado na apresentação final. Deve funcionar de ponta a ponta sem falhas.

```
1. Hóspede abre WhatsApp → manda mensagem para o número do hotel

2. Bot responde (RAG) → hóspede pergunta sobre disponibilidade e faz reserva

3. Bot confirma disponibilidade → inicia fluxo de reserva
   → InfinitePay processa pagamento
   → Reserva criada no sistema com status "pendente"

4. Reserva aparece no perfil do fornecedor

5. Fornecedor confirma reserva → status muda para "confirmada"
   → Hóspede recebe notificação no app (se tiver conta)
   → Hóspede recebe confirmação + PDF do ticket via WhatsApp

6. Hóspede pede roteiro turístico via WhatsApp
   → Bot gera sugestões com base nos dias da hospedagem
   (ex: 3 dias em Fortaleza → Dia 1: Beach Park, Dia 2: Praia do Futuro, Dia 3: Jericoacoara)

7. Hóspede abre app → vê reserva confirmada

8. Fornecedor marca hospedagem como finalizada (check-out)
   → Sistema dispara notificação ao hóspede solicitando avaliação
   → Hóspede submete avaliação
```

---

## Critérios de Aceite Globais

- [ ] Fluxo completo WhatsApp → reserva → dashboard funciona em menos de 5 segundos
- [ ] Bot responde perguntas sobre o hotel usando RAG em até 10 segundos
- [ ] Bot identifica corretamente a intenção do usuário (dúvida / reserva / roteiro)
- [ ] Reservas criadas via WhatsApp aparecem no perfil do fornecedor em tempo real
- [ ] App funciona em mobile (iOS/Android), web e tablet (portrait + landscape)
- [ ] Light mode e Dark mode funcionam em todas as telas
- [ ] Notificações in-app são disparadas nos gatilhos definidos
- [ ] Autenticação via e-mail/senha e Google funciona corretamente
- [ ] Usuário guest do WhatsApp tem histórico vinculado ao número
- [ ] Seed popula o banco com todos os dados necessários para a demo
