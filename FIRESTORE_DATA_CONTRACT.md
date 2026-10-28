# Contrato compartilhado do Firestore

Este aplicativo compartilha o projeto Firebase `ibcjj-fa960` com o aplicativo Kotlin CBJJB. Alterações de esquema devem permanecer retrocompatíveis: leitores toleram campos ausentes e atualizações nunca devem substituir o documento inteiro quando a intenção for alterar poucos campos.

## Usuários

Coleção: `Usuarios/{uid}`.

Campos comuns: `uid`, `nome`, `email`, `equipe`, `faixa`, `graduacao`, `genero`, `nascimento`, `peso`, `telefone`, `ativacao`, `profileImageBase64`, `profileImageUpdatedAt`.

Campos opcionais: `doc`, `tecnico`. A ausência equivale a texto vazio na apresentação, mas não autoriza o cliente a apagar o valor.

Controle da carteira:

- `appsCarteira`: lista contendo `cbjjb`, `ibcjj` ou ambos. Lista ausente/vazia mantém compatibilidade com cadastros antigos.
- `acessoVitalicio`: booleano. Quando verdadeiro, dispensa renovação anual, mas não ignora `appsCarteira`.
- `carteiraValidaAte`: timestamp inclusivo. A carteira comum é válida até o fim dessa data.

Somente a administração pode alterar os três campos de controle. Novos usuários são criados sem acesso vitalício e com somente o aplicativo de origem.

## Imagens e certificados

- Foto do perfil: Base64 em `Usuarios/{uid}.profileImageBase64`.
- Certificados: `Usuarios/{uid}/certificados/{id}` com `imageBase64`, `name` e `createdAt`.
- O cliente limita o Base64 antes do envio; as regras impõem no máximo 700.000 caracteres por certificado.

## Solicitações e auditoria

- `SolicitacoesAtivacao/{id}`: `userId`, `certificateIds`, `status: pendente`, `createdAt` e `sourceApp` (`cbjjb` ou `ibcjj`).
- `AuditoriaCarteiras/{id}`: eventos administrativos imutáveis. Deve registrar ator, usuário afetado, ação, valores anteriores/novos e timestamp do servidor.

As regras e os índices versionados estão em `firestore.rules` e `firestore.indexes.json`. A publicação deve ser feita uma única vez para o projeto compartilhado, após validação no emulador e aprovação do responsável pelo ambiente.
