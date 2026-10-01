# Preparação da base segura — 30/09/2026

## Backup local

- Arquivo: `.local-backups/before-secure-base-20260930-210755.zip`.
- SHA-256: `DD475C3CF0630B1BE1DC6A157812A92C6C04E5115E4E80BD2F42BAF8080E6DA8`.
- 240 entradas conferidas; inclui fontes, configurações e lockfile antes desta etapa.
- Exclui `.git`, `.dart_tool`, `build` e a própria pasta de backups.
- Contém a configuração antiga de assinatura. Guarde-o como arquivo sensível;
  `.local-backups/` é ignorada pelo Git. Uma cópia no mesmo disco não protege
  contra perda do disco; mantenha também uma cópia em armazenamento privado.

Para recuperar, extraia o ZIP em uma pasta separada e compare os arquivos antes
de copiar qualquer conteúdo para o projeto. Não publique o backup.

## Escopo

O remoto informado foi consultado e não apresentou referências/commits. A base
local inicia na branch `main`, com `origin` apontando para
`https://github.com/marysoarez/ibcjj.git`.

As credenciais de assinatura foram transferidas para `android/key.properties`,
ignorado pelo Git, e substituídas no Gradle pela leitura de propriedades locais.
`android/key.properties.example` contém somente exemplos. O keystore anterior
não está disponível no caminho configurado. Não houve rotação de credenciais.

## Ambiente e pendências

`flutter doctor -v` confirmou Flutter 3.35.4, Dart 3.9.2 e toolchain Android com
Java 17 e licenças aceitas. Não havia dispositivo Android conectado. O doctor
também apontou Visual Studio incompleto e Android Studio não detectado.

As falhas funcionais e o teste de contador identificados no diagnóstico continuam
pendentes. Esta etapa preserva o código de aplicação e as dependências diretas.

## Verificações executadas

- `flutter pub get --enforce-lockfile`: passou; SHA-256 do lockfile permaneceu igual.
- `git check-ignore`: confirmou exclusão do backup, propriedades locais e keystores.
- Varredura dos arquivos preparados para commit: não encontrou as senhas de
  assinatura existentes nem arquivos locais proibidos no conjunto versionado.
- `android/gradlew.bat -p android help --console=plain --no-daemon`: falhou no
  carregamento legado `app_plugin_loader.gradle`, antes de avaliar a assinatura.
  A migração de `android/settings.gradle` permanece pendente. Não foi possível
  validar builds Android nem a assinatura com o Gradle real nesta etapa.
- `git diff --cached --check`: apontou somente espaços finais preexistentes em
  `lib/views/register_page.dart:146` e `pubspec.yaml:52`; preservados nesta base.
- Foi adicionada uma exceção Git `safe.directory` somente para esta pasta, pois
  o proprietário Windows original é diferente do usuário atual.
