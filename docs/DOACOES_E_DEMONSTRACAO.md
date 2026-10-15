# Apresentação Eu Atleta

A página pública usa os mesmos fluxos de login e cadastro. Os prints em
`assets/images/demo_*.png` são demonstrações identificadas, geradas com dados
isolados em `tool/demo/dados_demo_eu_atleta.dart`. Esse arquivo não é importado
pelo aplicativo de produção, não chama o backend e não preenche contas reais.

Para abrir a demonstração separada:

```
flutter run -d web-server --web-port 8092 -t tool/demo/main.dart
```

O servidor de demonstração usa armazenamento em memória. Não expor seu endereço
como acesso a uma conta real. As capturas são assets estáticos na apresentação.

## Doações

O Pix público foi fornecido pelo responsável pelo projeto em 15/10/2026.
Está em `lib/data/constants/doacao_config.dart`, com validação de CRC. A imagem original do Inter enviada pelo responsável
é exibida em assets/images/doacao_pix_inter.png; seu conteúdo foi decodificado
e conferido contra o Pix Copia e Cola. Overrides válidos geram QR localmente. Não usamos QR Code de exemplo nem serviço externo gerador.
É possível substituir o código no build com `DONATION_PIX_CODE`.

No Inter: **Pix → Receber → selecionar chave → Compartilhar**. Para permitir
doações de qualquer valor, compartilhar o QR Code sem valor definido ou o
Pix Copia e Cola. QR estático pode receber vários pagamentos.

Fontes oficiais:
- https://ajuda.inter.co/pix/como-recebo-um-pix-na-minha-conta-pfmei/
- https://ajuda.inter.co/pix/como-faco-para-gerar-um-qr-code-do-pix/

Doar é opcional. Nenhuma transferência é iniciada pelo site: a pessoa copia ou
escaneia o código e confirma no próprio banco. Serviços eventualmente contratados
com profissionais são independentes da gratuidade do aplicativo.
