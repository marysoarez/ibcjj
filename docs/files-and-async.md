# Telas, arquivos e operações assíncronas

## Formulários

Controllers são criados no estado da tela e descartados em `dispose`. As telas
de login e recuperação de senha permitem rolagem com teclado aberto.
Envios em andamento desabilitam botões; os view models também rejeitam chamadas
duplicadas. Retornos após fechamento das telas verificam `mounted` ou descarte
do view model antes de atualizar a apresentação.

Validações de cadastro: e-mail, senha com pelo menos seis caracteres, campos
obrigatórios de até 120 caracteres, telefone com 10 a 15 dígitos, graduação
inteira de 0 a 10 e peso maior que zero e até 500 kg (ponto ou vírgula decimal).
A data é obrigatória e o seletor aceita de 1900 até hoje. A senha enviada ao
Firebase é exatamente a digitada, incluindo espaços.

## Imagens

Perfil e certificados aceitam JPEG, PNG ou WebP até 5 MiB (5 × 1024 × 1024 bytes),
20 milhões de pixels e 8192 pixels por lado. O limite de bytes é aplicado antes
e durante a leitura; assinatura do arquivo, dimensões e decodificação são
validadas. Renomear um arquivo para `.jpg` não o transforma em uma imagem aceita.
O MIME real é enviado nos metadados do Storage, mesmo no caminho legado
`usuarios/{uid}/profile.jpg`.

A seleção cancelada não envia arquivos. Uma foto inexistente no Storage
(`object-not-found`) é normal; falhas de permissão ou conexão são apresentadas.
Erros de foto têm etapas distintas: envio, obtenção do link e atualização do
documento Firestore. O perfil local só recebe a nova URL após persistência.

O upload e a gravação do documento não são atômicos. Se a segunda etapa falhar,
o arquivo já pode ter sido enviado/sobrescrito no Storage; não há rollback
automático nem remoção de um arquivo que possa ser usado pelo perfil.

## Sessão e arquivos

Os repositórios recebem um `SessionGuard` que consulta o UID atual do Firebase Auth.
O UID solicitado precisa corresponder à sessão ativa. A verificação é repetida
após galeria/leitura do arquivo e nas transições entre requisições remotas.
Seleção iniciada numa conta não pode enviar para outra conta após troca de sessão.

Pedidos já enviados ao Firebase não são desfeitos quando a tela fecha. Seus
caminhos continuam associados ao UID original; os resultados não atualizam telas
descartadas. Nenhum novo pedido de atualização do perfil é iniciado se a sessão
mudar antes dessa etapa. O servidor deve aplicar autorização independentemente
das verificações do cliente.

Exclusão de certificado requer confirmação e mostra o resultado. Nomes com
separadores de caminho são rejeitados; a operação usa `certificados/{uid}/{name}`.

## WhatsApp

A solução adotada é abrir uma conversa externa em `wa.me/5521990466071`, usando
o número já presente no projeto: **+55 21 99046-6071**. O usuário confirma o envio
no WhatsApp. Não há envio automático, token de API, senha ou backend de mensagens.

A mensagem inicial solicita a ativação da carteirinha e não inclui dados pessoais
do perfil. Se a abertura falhar, o aplicativo mostra o telefone para contato.
Os testes usam um launcher falso e não abrem nem enviam mensagens reais.

## Regras Firebase: revisão pendente

Não existem arquivos de regras Firestore/Storage no projeto. `firebase.json`
contém somente configuração FlutterFire. As regras publicadas não foram obtidas,
alteradas ou implantadas, portanto sua segurança ainda não foi validada.

Quando estiverem disponíveis, verificar pelo menos:
- acesso apenas do proprietário autenticado aos seus perfis e arquivos;
- ativação controlada pelo servidor/admin, sem autoativação pelo aplicativo;
- limites de tamanho e MIME também no Storage;
- campos permitidos nas criações/atualizações e leitura necessária às transações;
- testes de acesso entre contas e de usuário desconectado nos emuladores.

Estas verificações no cliente não substituem regras de segurança do servidor.

## Verificação local

```powershell
flutter test --no-pub
flutter analyze --no-pub
```

A suíte inclui fechamento de tela durante requisição, teclado em viewport pequena,
envios duplicados, confirmação de exclusão, validação de arquivos, ausência de
foto, sessão alterada, falhas separadas de upload/documento e link do WhatsApp.
O build/dispositivo Android continua dependente da migração Gradle já documentada.
