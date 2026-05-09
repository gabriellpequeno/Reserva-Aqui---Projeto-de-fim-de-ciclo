# PRD — Image Fallback Flow

## Contexto

A aplicação Reserva Aqui exibe imagens de hotéis e quartos em vários pontos: cards de quartos recomendados na home, página de detalhes do hotel, página de detalhes do quarto, página de busca e página de favoritos. Hoje, todas essas superfícies acabam exibindo a mesma imagem mockada (ou nem isso, em alguns casos), independentemente de o host ter feito upload de fotos reais. Há também um bug em que mesmo as imagens mockadas deixaram de carregar nos cards de recomendados, devido a inconsistências entre os caminhos físicos no disco (`Backend/storage/`) e os `storage_path` registrados no banco para os hotéis ativos.

A aplicação já possui o subsistema de upload (`POST /api/v1/uploads/hotels/:id/cover`, `POST /api/v1/uploads/hotels/:id/rooms/:quarto_id`) e tabelas correspondentes (`foto_hotel`, `quarto_foto`), mas o fluxo de leitura/exibição não está aproveitando essas imagens reais de forma consistente.

## Problema

Imagens mockadas estão sendo exibidas indistintamente para todos os hotéis e quartos, ignorando uploads reais feitos por hosts. Além disso, em alguns pontos (notadamente cards de recomendados), nem o mock carrega — o front recebe `{"error":"Arquivo não encontrado no servidor"}` ao tentar `Image.network`. O resultado é uma experiência visualmente quebrada e que não reflete o conteúdo real cadastrado pelos hosts.

## Público-alvo

- **Hóspedes**: usuários finais que navegam pelo app (home, busca, favoritos, detalhes do hotel/quarto) e esperam ver fotos representativas dos estabelecimentos.
- **Hosts**: anfitriões que fazem upload de fotos de capa e fotos de quartos e esperam que essas imagens apareçam no app dos hóspedes em vez de mocks genéricos.

## Requisitos Funcionais

1. **Fallback em recommended rooms (home)**: o card de quarto recomendado deve tentar carregar a foto real do `quarto_foto`; se o registro não existir ou o arquivo físico não estiver disponível, deve cair em um mock determinístico baseado no `quartoId`.
2. **Fallback em hotel details (capa)**: a página de detalhes do hotel deve usar fotos reais de `foto_hotel`; se a lista vier vazia ou todos os arquivos estiverem ausentes em disco, deve exibir mock determinístico baseado no `hotelId`.
3. **Fallback em room details (galeria)**: a página de detalhes do quarto deve montar a galeria a partir de `quarto_foto`; se vazio ou inexistente em disco, exibir mock(s) determinístico(s) baseado no `quartoId`.
4. **Fallback em search e favorites**: as páginas de busca e favoritos devem seguir o mesmo fluxo BD-first com fallback determinístico, sem regredir para mocks fixos.

## Requisitos Não-Funcionais

- [ ] **Performance**: 1 round-trip por imagem — o backend deve resolver o `foto_id` antes de retornar a estrutura da listagem (recomendados, search, favoritos), evitando chamadas extras do front para `listHotelCovers`/`listRoomPhotos` apenas para resolver IDs.
- [ ] **Robustez**: endpoints de listagem (`listHotelCovers`, `listRoomPhotos`) e endpoints que devolvem `imageUrl` (recomendados, search) devem fazer `fs.existsSync(path.resolve(UPLOAD_DIR, storage_path))` antes de incluir a URL na resposta. Registros órfãos não devem gerar URLs visíveis ao cliente.
- [ ] **Determinismo do mock**: o mesmo `hotelId`/`quartoId` deve sempre cair no mesmo mock (hash do id módulo tamanho da lista de mocks), evitando que a imagem "troque" entre renders ou navegações.
- [ ] **Acessibilidade**: o `errorBuilder` do `Image.network` deve renderizar um placeholder com cor da marca (`AppColors.primary` com alpha) e ícone temático (`Icons.hotel` / `Icons.bed`), evitando layout quebrado e provendo affordance visual.

## Critérios de Aceitação

- Dado um host que fez upload de foto de capa e foto do quarto, quando o hóspede abrir o card recomendado / página do hotel / página do quarto, então a foto real é exibida (não o mock).
- Dado um host sem foto cadastrada, quando o hóspede abrir qualquer superfície que normalmente mostra essa foto, então é exibido um mock determinístico baseado no id do recurso (mesmo id sempre o mesmo mock).
- Dado um registro em `foto_hotel` ou `quarto_foto` cujo arquivo físico não existe em disco, quando o front tentar carregar a imagem, então o sistema cai no mock sem expor o erro `{"error":"Arquivo não encontrado no servidor"}` ao usuário.
- Dado o endpoint de listagem (`GET /uploads/hotels/:id/cover`, `GET /uploads/hotels/:id/rooms/:quarto_id`), quando ele responder, então nenhuma URL retornada aponta para um arquivo inexistente em disco.

## Fora de Escopo

- **CDN e otimização de imagens**: compressão, redimensionamento automático e distribuição via CDN não fazem parte desta entrega.
- **Sincronização de imagens órfãs no BD**: limpeza/migração de registros em `foto_hotel` e `quarto_foto` que apontam para arquivos sumidos em disco será tratada em outra iniciativa.
- **Upload e edição de imagens pelo host**: os fluxos de upload, crop e delete já existem e não são alterados por esta feature.
- **Reseed dos arquivos físicos em produção**: copiar/migrar arquivos físicos no servidor de produção para alinhar com os IDs ativos do BD não é responsabilidade desta entrega.
