# Avaliação e Versão Corrigida do Modelo de Dados

## 1. Resumo do modelo atual

Entidades principais presentes no diagrama:

- **hotel**: dados cadastrais do hotel (endereço, CNPJ, saldo, avaliação, etc.).
- **room**: quartos do hotel, com tipo, disponibilidade, preço e capacidade.
- **user**: usuários/hóspedes.
- **reserve**: reservas ligando usuário, quarto e hotel, com datas e status.
- **Avaliation**: avaliações de hotel feitas pelos usuários.
- **comodation**: informações de comodidades associadas ao quarto.

Relacionamentos principais:

- `room.hotel_uuid` → `hotel.uuid_hotel` (1:N entre hotel e quartos).
- `reserve.hotel_uuid`, `reserve.room_uuid`, `reserve.user_uuid` → ligam reserva a hotel, quarto e usuário.
- `Avaliation.hotel_uuid` e `Avaliation.user_uuid` → ligam avaliação a hotel e usuário.
- `comodation.room_uuid` → `room.uuid_room`.

No geral, o modelo atende ao caso de uso básico de reservas em um hotel.

---

## 2. Pontos positivos

- **Separação das entidades principais** está adequada: hotel, quarto, usuário e reserva, como em modelos clássicos de sistemas de reserva de hotel.
- **Relacionamentos essenciais** estão mapeados, permitindo:
  - Consultar quartos de um hotel.
  - Consultar reservas por usuário, hotel ou quarto.
  - Registrar avaliações por usuário e hotel.
- Estrutura suficientemente simples para o escopo de um projeto acadêmico focado também em Flutter e IA.

---

## 3. Problemas e riscos identificados

### 3.1. Autenticação misturada com dados de domínio

- Tabelas `hotel` e `user` têm campo `password` diretamente, junto com dados de negócio.
- Isso mistura responsabilidades (autenticação x domínio) e pode dificultar evolução futura.
- Do ponto de vista de segurança, senhas devem ser sempre armazenadas como **hash** (decisão de implementação, mas vale registrar).

### 3.2. Tipagem e nomenclatura

- Colunas `uuid_*` estão como `integer`:
  - Se forem IDs sequenciais, o nome mais claro seria `id_hotel`, `id_room`, etc.
  - Se a intenção é usar UUID real, o tipo ideal é `uuid` ou `varchar(36)`.
- Campos com nomes pouco claros ou com typos:
  - `adress` → deveria ser `address`.
  - `avaliation` → deveria ser `rating` (ou `score`).
  - `tourism` (bool) não deixa claro o significado; se não for usado, pode ser removido ou renomeado.
- Campos numéricos que poderiam ser texto:
  - `cnpj` e `cep` como `integer` podem perder zeros à esquerda; geralmente são armazenados como `varchar`.

### 3.3. Status da reserva

- `reserve.status` como `bool` é muito limitado (pode significar apenas ativo/inativo).
- Em sistemas de reserva, é comum ter estados como: `PENDING`, `CONFIRMED`, `CANCELLED`, `COMPLETED`.
- Usar `status` como string ou pequeno enum torna o modelo mais expressivo.

### 3.4. Redundância de dados em reserva

- `reserve.room_number` é redundante, pois o número do quarto deveria estar na tabela `room`.
- Redundâncias podem causar inconsistências (por exemplo, trocar o número do quarto em `room` e esquecer de atualizar em `reserve`).

### 3.5. Tabela de avaliações (`Avaliation`)

- Nome da tabela e coluna `avaliation` fogem do padrão inglês e podem ser renomeados para `review` / `rating`.
- Não há chave primária explícita; uma combinação natural seria `(hotel_uuid, user_uuid)` se for permitido apenas uma avaliação por usuário por hotel.

### 3.6. Tabela de comodidades (`comodation`)

- Estrutura atual: `room_uuid`, `number_comodations`.
- Isso parece mais um contador do que uma verdadeira relação entre **quarto** e **amenidades**.
- Se for necessário controlar tipos de comodidade (Wi‑Fi, Piscina, Café da manhã, etc.), o ideal é um modelo de muitos‑para‑muitos com tabelas `amenity` e `room_amenity`.

### 3.7. Faltam entidades importantes para o app e para IA

- **Mensagens do chat**:
  - Não há tabela para historizar mensagens entre hóspede, bot e staff.
  - Isso é essencial para montar as telas de chat nos apps Flutter.
- **Roteiros gerados pela IA**:
  - Não há tabela para armazenar o JSON do itinerário gerado.
  - Guardar isso facilita exibir histórico de roteiros e depurar a IA.
- **Campos de auditoria** (`created_at`, `updated_at`) não aparecem, mas são úteis para ordenação e análise.

---

## 4. Versão sugerida do modelo (corrigida e estendida)

Abaixo, uma proposta de modelo ajustado. Sinta-se livre para simplificar ou adaptar conforme o que o time já implementou.

### 4.1. Tabela `hotel`

```text
hotel
-----
id_hotel          (PK, integer ou uuid)
name              (varchar)
cnpj              (varchar(14))
address           (varchar)
cep               (varchar(8))
uf                (varchar(2))
city              (varchar)
neighborhood      (varchar)
street_number     (integer ou varchar)
complement        (varchar, nullable)
phone             (varchar, opcional)
description       (text)
average_rating    (numeric, opcional, pode ser derivado de reviews)
created_at        (timestamp)
updated_at        (timestamp)
```

> Observação: campos como `saldo` e `tourism` podem ser retirados se não forem usados no app, para simplificar o modelo.

### 4.2. Tabela `user`

```text
user
----
id_user           (PK, integer ou uuid)
name              (varchar)
birth_date        (date)
email             (varchar, único)
phone             (varchar)
cpf               (varchar(11))
role              (varchar)  -- 'GUEST', 'STAFF', 'ADMIN', etc.
created_at        (timestamp)
updated_at        (timestamp)
```

> Autenticação: o campo de senha pode ficar aqui (como `password_hash`) ou em uma tabela separada de `auth`. Para o projeto acadêmico, manter em `user` com hash já é aceitável.

### 4.3. Tabela `room`

```text
room
----
id_room           (PK, integer ou uuid)
hotel_id          (FK → hotel.id_hotel)
room_number       (varchar)
room_type         (varchar)   -- ex.: 'STANDARD', 'SUITE'
capacity          (integer)   -- número de pessoas
is_available      (boolean)
price_per_night   (numeric)
created_at        (timestamp)
updated_at        (timestamp)
```

> Campos como `limit_ocp` e `places` podem ser consolidados em `capacity`.

### 4.4. Tabela `reservation`

```text
reservation
-----------
id_reservation    (PK, integer ou uuid)
hotel_id          (FK → hotel.id_hotel)
room_id           (FK → room.id_room)
user_id           (FK → user.id_user)
checkin_date      (date)
checkout_date     (date)
price_total       (numeric)
status            (varchar)   -- 'PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'
created_at        (timestamp)
updated_at        (timestamp)
```

> `room_number` não é necessário aqui, pois pode ser obtido via join com `room`.

### 4.5. Tabela `review` (avaliation)

```text
review
------
id_review         (PK, integer ou uuid)
hotel_id          (FK → hotel.id_hotel)
user_id           (FK → user.id_user)
rating            (integer)   -- ex.: 1 a 5
comment           (text)
created_at        (timestamp)
```

> Se quiser garantir uma avaliação por usuário por hotel, pode restringir com índice único `(hotel_id, user_id)`.

### 4.6. Tabelas de amenidades

```text
amenity
-------
id_amenity        (PK, integer)
name              (varchar)   -- 'Wi-Fi', 'Piscina', 'Café da manhã', etc.

room_amenity
------------
room_id           (FK → room.id_room)
amenity_id        (FK → amenity.id_amenity)
PRIMARY KEY (room_id, amenity_id)
```

> Se não quiser esse nível de detalhe agora, pode manter apenas um campo `amenities_text` em `room` descrevendo as comodidades em texto livre.

### 4.7. Tabela de mensagens de chat

```text
message
-------
id_message        (PK, integer ou uuid)
conversation_id   (uuid ou integer)  -- agrupa mensagens de uma mesma conversa
user_id           (FK → user.id_user, nullable se for só staff)
hotel_id          (FK → hotel.id_hotel)
sender_type       (varchar)   -- 'GUEST', 'BOT', 'STAFF'
source            (varchar)   -- 'WHATSAPP', 'APP'
text              (text)
created_at        (timestamp)
```

> Essa tabela é fundamental para o histórico de chat no app do cliente e no dashboard do fornecedor.

### 4.8. Tabela de roteiros gerados pela IA

```text
itinerary
---------
id_itinerary      (PK, integer ou uuid)
user_id           (FK → user.id_user)
hotel_id          (FK → hotel.id_hotel, opcional)
json_data         (jsonb ou text)  -- estrutura do roteiro (dias, atividades)
created_at        (timestamp)
```

> O `json_data` pode guardar diretamente a resposta estruturada do modelo de IA. O app Flutter lê e renderiza.

---

## 5. O que é essencial x opcional para o MVP

### Essencial para o MVP

- Tabelas:
  - `hotel`
  - `room`
  - `user`
  - `reservation`
  - `message`
  - `itinerary`
- Ajustes importantes:
  - `reservation.status` como texto/enumerado em vez de booleano.
  - Remover `room_number` de `reservation` (deixar só em `room`).
  - Garantir que `cnpj`, `cep`, `cpf` sejam armazenados como texto.

### Opcional / Nice to Have

- Tabelas de amenidades (`amenity`, `room_amenity`).
- Índices únicos em `review` (`hotel_id`, `user_id`).
- Campos de auditoria em todas as tabelas (`created_at`, `updated_at`).
- Tabela separada para autenticação (se o time quiser evoluir segurança).

---

## 6. Como isso ajuda o front e a IA

- O **app Flutter Cliente** consegue:
  - Listar hotéis e quartos com informações consistentes.
  - Exibir reservas, histórico de mensagens e roteiros.
- O **app Flutter Fornecedor** consegue:
  - Ver reservas por status, acompanhar conversas e entender o contexto do hóspede.
- A **IA** (LangChain/RAG):
  - Usa tabelas `message` e `itinerary` para ter contexto de conversa e histórico de roteiros.
  - Consulta `hotel`, `room` e `reservation` via tools quando precisar checar disponibilidade ou criar reservas.

Esse modelo equilibra simplicidade (importante para 1 mês de projeto) com uma base suficiente para integrar IA, WhatsApp e os dois apps Flutter de forma organizada.
