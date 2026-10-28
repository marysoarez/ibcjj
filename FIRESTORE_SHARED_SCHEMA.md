# Contrato compartilhado da carteirinha

Os aplicativos CBJJB (Android/Kotlin) e IBCJJ (Flutter) usam o mesmo projeto
Firebase (`ibcjj-fa960`) e a coleção `Usuarios`.

## Campos de acesso em `Usuarios/{uid}`

| Campo | Tipo | Regra |
| --- | --- | --- |
| `carteiraValidaAte` | Firestore Timestamp ou `null` | A carteirinha anual é válida até essa data, inclusive. |
| `acessoVitalicio` | boolean | Quando `true`, dispensa a validade anual. Deve ser concedido somente pela administração. |
| `appsCarteira` | array de strings | Valores aceitos: `cbjjb` e `ibcjj`. Use os dois para acesso nos dois aplicativos. |
| `ativacao` | string legada | Mantido somente para usuários antigos (`2026` ou `vitalício`). Novas rotinas administrativas devem usar os campos tipados. |

O acesso à carteirinha exige simultaneamente:

1. O identificador do aplicativo em `appsCarteira`.
2. `acessoVitalicio == true` ou `carteiraValidaAte` ainda não vencida.

Documentos antigos sem `appsCarteira` continuam liberados nos dois aplicativos
durante a migração. Novos cadastros recebem apenas o aplicativo de origem.

Exemplo de diretoria com acesso aos dois aplicativos:

```text
acessoVitalicio: true
appsCarteira: ["cbjjb", "ibcjj"]
carteiraValidaAte: null
```

Exemplo de atleta com validade anual apenas no IBCJJ:

```text
acessoVitalicio: false
appsCarteira: ["ibcjj"]
carteiraValidaAte: Timestamp da data final da anuidade
```

## Imagens Base64

- Foto: `Usuarios/{uid}.profileImageBase64`.
- Certificados: `Usuarios/{uid}/certificados/{certificateId}.imageBase64`.
- O texto Base64 deve ter no máximo 700.000 caracteres para manter margem em
  relação ao limite de 1 MiB de cada documento do Firestore.
