# PRD — Suporte Email Redirect

## Contexto
A página de suporte do app ReservAqui oferece uma opção de contato por email, porém o redirecionamento para o app de email do dispositivo não está implementado. O usuário precisa copiar o endereço manualmente e iniciar o contato por conta própria.

## Problema
A ausência do redirecionamento via `mailto:` gera fricção desnecessária no fluxo de suporte. Sem assunto e corpo pré-preenchidos, o usuário não sabe quais informações fornecer, e o suporte recebe contatos incompletos.

## Público-alvo
Usuários finais (hóspedes) que precisam contatar o suporte diretamente pelo app.

## Requisitos Funcionais
1. Ao tocar na opção de suporte por email, abrir o app de email nativo com `mailto:` pré-configurado (destinatário, assunto e corpo)
2. O email de suporte deve ser uma constante centralizada — não hardcodar em múltiplos lugares
3. Caso o dispositivo não tenha app de email configurado, exibir `SnackBar` com o endereço `suporte@reservaqui.com` para o usuário copiar manualmente

## Requisitos Não-Funcionais
- [ ] Segurança: email de destino fixo via constante, sem input do usuário
- [ ] Compatibilidade iOS: adicionar `mailto` em `LSApplicationQueriesSchemes` no `Info.plist`
- [ ] Responsividade: funcionar em Android e iOS

## Critérios de Aceitação
- Dado que o usuário está na página de suporte, quando tocar no botão de email, então o app de email abre com destinatário `suporte@reservaqui.com`, assunto `Suporte ReservAqui` e corpo inicial pré-preenchido
- Dado que o dispositivo não tem app de email configurado, quando tocar no botão, então um SnackBar exibe o endereço `suporte@reservaqui.com` para cópia manual

## Fora de Escopo
- Envio de email direto pelo app (sem app externo)
- Suporte via chat ou WhatsApp
- Histórico de contatos enviados pelo app
