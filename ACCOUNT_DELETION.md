# Exclusão de conta e dados

O aplicativo chama a callable function `deleteOwnAccount`, na região
`southamerica-east1`, em Node.js 22, somente depois da reautenticação do
usuário.

A função usa exclusivamente o UID do token autenticado e remove, nesta ordem:

1. objetos sob `usuarios/{uid}/` no Firebase Storage;
2. objetos sob `certificados/{uid}/` no Firebase Storage;
3. documentos de `SolicitacoesAtivacao` cujo `userId` seja o UID;
4. `Usuarios/{uid}` e todas as suas subcoleções;
5. `usuarios/{uid}` e todas as suas subcoleções legadas;
6. a conta no Firebase Authentication.

As operações anteriores à exclusão do Authentication são idempotentes. A conta
do Authentication é removida por último para permitir nova tentativa após uma
falha parcial.

## Retenção e auditoria

`AuditoriaCarteiras` não é apagada automaticamente porque o contrato existente
define essa coleção como trilha administrativa imutável. Antes da implantação,
é obrigatório validar o esquema real, a base legal e o prazo de retenção. Dados
que não precisem ser legalmente retidos devem ser apagados ou anonimizados por
um processo administrativo documentado. A página pública e a declaração de
Segurança dos dados devem informar claramente qualquer retenção aplicável.

## Implantação

Na raiz do projeto:

```text
cd functions
npm install
npm run check
cd ..
firebase deploy --only functions:deleteOwnAccount
```

Não considere o fluxo ativo até a função estar implantada no projeto
`ibcjj-fa960` e os testes com Auth, Firestore e Storage de produção terem sido
executados.
