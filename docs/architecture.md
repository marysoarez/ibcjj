# Arquitetura e autenticação

## Responsabilidades

- `app/bootstrap.dart`: inicializa Firebase uma vez antes de abrir a aplicação,
  monta os repositórios e retorna uma tela de erro se a inicialização falhar.
  Nenhum widget chama `Firebase.initializeApp()`.
- `app/app.dart`: mantém Provider, injeta repositórios e coordena a navegação por
  sessão. A troca de UID ou o logout descarta as rotas da conta anterior.
- `features/*/data/*_repository.dart`: contratos sem tipos Firebase.
  Implementações `firebase_*` concentram Auth, Firestore, Storage e seleção de imagens.
- `features/*/presentation/`: view models coordenam ações e estado; telas exibem
  os dados e encaminham interações. Não há SDK Firebase nas telas ou view models.
- `features/profile/models/user_model.dart`: conversão canônica do perfil.
- `core/errors/`: mensagens de erro sem expor detalhes internos do Firebase.

As interfaces de repositório permitem testar a aplicação com dados em memória.
Firebase é configurado apenas no ponto de composição; view models não constroem
serviços globais.

## Sessão

`AuthViewModel` acompanha `AuthRepository.sessionChanges` e expõe os estados
`loading`, `authenticated`, `disconnected` e `error`. O motivo do erro distingue
autenticação, leitura de perfil, gravação parcial de cadastro, sessão e logout.

- Login inválido: erro de autenticação, sem perfil autenticado.
- Login válido com falha de leitura: sessão preservada, erro de perfil com nova tentativa.
- Documento inexistente: recuperação oferece completar o cadastro.
- Cadastro bem-sucedido: a conta já está conectada; nenhum segundo login é executado.
- Conta criada e perfil não salvo: sessão preservada; nova tentativa salva somente
  o perfil, sem recriar a conta. O formulário pendente é mantido em memória, sem senha.
- Após reiniciar o app, se não houver documento, o usuário completa os dados novamente.
- A gravação do cadastro usa transação: se o documento já existir, retorna os dados
  existentes. Isso evita redefinir ativação após uma resposta perdida.
- Logout bem-sucedido remove sessão, perfil, formulário pendente e rotas protegidas.
  Falha no logout mantém a sessão e informa que a saída não foi concluída.
- Respostas antigas de perfil são descartadas após logout, troca de conta ou
  descarte do view model. A assinatura do fluxo de sessão é cancelada no descarte.
- Erros do SDK Auth são traduzidos em mensagens conhecidas, preservando a stack
  trace. Demais erros propagados pelos repositórios mantêm sua exceção original.

## Perfil e certificados

`ProfileViewModel` coordena foto e estado de erro/carregamento.
`CertificatesViewModel` coordena listagem, seleção/upload e exclusão para um UID
fixado quando a tela é aberta. Os arquivos continuam nos caminhos existentes.

A tentativa de envio via WhatsApp era um protótipo com token incompleto e mensagem
de teste. Foi removida; o botão está desabilitado e explica a indisponibilidade.
Nenhum serviço real de ativação foi criado nesta etapa.

## Código removido

Foram removidos `FirebaseAuthService`, a tela `SignUpPage` sem navegação de entrada,
o `PhotoViewModel` inteiramente comentado e métodos de cadastro/reset duplicados
na antiga tela de login. O comportamento ativo fica nas funcionalidades acima.
O histórico Git mantém as versões anteriores.

## Verificação

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Os testes cobrem contratos de dados, adapters dos repositórios, estados e corridas
de sessão, recuperação de cadastro, perfil/certificados e inicialização/navegação.
O teste de contador do template foi substituído. Um teste de arquitetura impede
imports Firebase nas camadas de apresentação/modelos e nos contratos.

Nenhum pacote foi atualizado. Os testes usam doubles locais; regras do Firebase,
concorrência real das transações e permissões nativas ainda exigem teste em
emuladores/dispositivo. Não foram acessados nem migrados dados de produção.

O bloqueio Android do carregamento legado de plugins e a ausência do keystore
continuam pendentes. A regra antiga de validade da carteirinha (2025/vitalício)
foi preservada; atualizar essa regra é uma mudança de negócio separada.
