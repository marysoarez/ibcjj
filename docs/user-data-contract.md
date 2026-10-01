# Contrato de dados do usuário

## Firestore e Storage

Cadastro, leitura e atualização de foto usam `Usuarios/{uid}`. O ID do documento
vem do Firebase Auth e prevalece sobre um eventual `uid` divergente salvo no mapa.
O Storage continua usando `usuarios/{uid}/profile.jpg`; esse caminho é independente
do nome da coleção e foi preservado para manter acesso às fotos existentes.

`UserModel.fromMap()` é a conversão de leitura; `toMap()` produz o mapa canônico
para gravação de perfis. Campos desconhecidos não fazem parte do modelo.

| Campos | Representação e padrão |
| --- | --- |
| uid, email | Texto; UID da sessão/documento, e-mail da sessão como fallback |
| nome, equipe, faixa, graduacao, genero, nascimento, peso, tecnico, telefone | Texto vazio quando ausente, nulo ou incompatível |
| ativacao | Texto; `pendente` quando ausente, nulo ou vazio |
| profileImageUrl | Texto ou `null` quando sem foto |

Peso, graduação e telefone numéricos legados são convertidos em texto. Outros
tipos inesperados não provocam cast inválido e usam o padrão do campo.
Datas continuam como texto, sem alteração do formato existente nesta etapa.

## Compatibilidade e cadastro

- A leitura usa `genero`; se vazio ou inválido, tenta a chave antiga `gênero`.
- Novos mapas gravam somente `genero`.
- Cadastros usam `UserModel.forRegistration()` com identidade do Firebase Auth.
  Sempre começam com `ativacao: pendente` e sem URL de foto, mesmo que o chamador
  forneça ativação ou foto. Os demais dados do formulário são preservados.
- Ativações de documentos existentes são preservadas na leitura.
- O modelo aceita mapas inexistentes e incompletos com os padrões acima.
  O repositório distingue documento inexistente retornando `null`; a autenticação
  oferece completar o perfil, preservando a sessão. A leitura não altera o banco.
- A criação do perfil usa uma transação. Se um documento já existir, os dados
  existentes são retornados, evitando redefinir ativação em tentativas repetidas.
- A foto usa uma gravação com merge de `uid` e `profileImageUrl`, preservando
  ativação, dados pessoais e campos adicionais. Se o documento não existir, esse
  merge cria um documento parcial; os demais campos recebem padrões na leitura.
- O estado local da foto só é alterado após a gravação no Firestore ter sucesso.
  Upload no Storage e gravação no Firestore não são atômicos; um upload concluído
  pode permanecer se a gravação posterior falhar.

Não foi executada migração de documentos remotos. A compatibilidade com `gênero`
deve permanecer até que os dados antigos sejam migrados em uma etapa específica.
O padrão `pendente` no cliente não substitui regras de autorização no Firestore.
A validação de ano da carteirinha na interface permanece fora desta etapa.

## Testes

```powershell
flutter test --no-pub test/models test/repositories test/viewmodels
```

Os testes cobrem conversão, campos incompletos, tipos inválidos, dados legados,
cadastro, coleção de destino, merge da foto e falha de persistência. Os testes
de fluxo usam doubles locais das interfaces Firebase e ImagePicker; não acessam
a rede e não validam regras de segurança publicadas ou transações do SDK real.

Nenhuma atualização de pacote foi necessária. `pubspec.yaml` e `pubspec.lock`
foram preservados. O teste antigo do contador em `test/widget_test.dart` foi
substituído por testes de inicialização e navegação por sessão.
