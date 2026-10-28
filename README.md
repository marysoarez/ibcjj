# final_ibcjj

## Integração REST

A integração de leitura com a API Node é opcional e configurada no build com
`--dart-define=API_BASE_URL=https://<host-da-api>`. O aplicativo acrescenta
`/api/v1` ao endereço configurado; ambientes não locais precisam usar HTTPS.
Para desenvolvimento local, use explicitamente `http://10.0.2.2:<porta>` no
emulador Android ou `http://localhost:<porta>` em execução no computador.

Com a URL configurada, o app envia o Firebase ID token da sessão no cabeçalho
`Authorization` para carregar `/me` e `/me/card-access?app=ibcjj`. Se a API
estiver indisponível, a tela preserva o perfil e a autorização locais do
Firestore. Fotos, certificados, cadastro e edição de perfil continuam usando
os fluxos existentes.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
