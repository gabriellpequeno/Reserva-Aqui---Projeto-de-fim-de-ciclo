# BUG-12 — suporte - Direcionador para Email com Campo Pré-preenchido

## Tela
`lib/features/support/presentation/pages/support_page.dart` (ou onde o suporte está implementado)

## Prioridade
**Baixa** — melhoria de UX, não bloqueia nenhum fluxo crítico

## Branch sugerida
`fix/support-email-redirect`

---

## Melhoria

### Botão de contato via email

- [ ] **Implementar redirecionamento para app de email** ao tocar no botão/opção de suporte
  - Usar `url_launcher` com esquema `mailto:` pré-configurado:
    ```
    mailto:suporte@reservaqui.com?subject=Suporte%20ReservAqui&body=Olá%2C%20preciso%20de%20ajuda%20com...
    ```
  - O `to` (email de destino do suporte) deve estar configurado como constante — não hardcodar espalhado pelo código
  - O `subject` deve ser pré-preenchido com algo como "Suporte ReservAqui"
  - O `body` pode ter um texto inicial opcional para guiar o usuário

- [ ] Verificar se o pacote `url_launcher` já está nas dependências (`pubspec.yaml`) — se não, adicionar
- [ ] Tratar o caso em que o dispositivo não tem app de email configurado: exibir um `SnackBar` com o endereço de email para o usuário copiar manualmente

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `support_page.dart` | Implementar lançamento do `mailto:` |
| `pubspec.yaml` | Adicionar `url_launcher` se não existir |
| Arquivo de constantes (ex: `app_constants.dart`) | Adicionar email de suporte como constante |

---

## Observações
- Confirmar o endereço de email de suporte antes de implementar
- No iOS, é necessário adicionar o scheme `mailto` ao `Info.plist` em `LSApplicationQueriesSchemes` para que `canLaunchUrl` funcione — verificar se já está configurado
