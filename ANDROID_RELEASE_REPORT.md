# Relatório de preparação Android / Google Play

Data: 16/10/2026

## Toolchain final

- Flutter 3.35.4 stable (engine c298091351)
- Dart 3.9.2
- Android compileSdk/targetSdk 36; minSdk 24 (padrão desta versão do Flutter)
- Android Gradle Plugin 8.9.1
- Gradle 8.12
- Kotlin 2.1.0
- Java 17
- NDK 27.0.12077973
- Google Services Gradle plugin 4.4.2

## Diagnóstico e correções

- O Firebase era inicializado duas vezes. A inicialização agora ocorre uma vez antes da criação dos serviços Firebase e apresenta uma tela de erro segura se falhar.
- A restauração de sessão podia exibir o login enquanto ainda carregava o perfil e falhava quando o documento do Firestore não existia ou a rede estava indisponível. Foi adicionado estado explícito de restauração e fallback para o usuário do Firebase Auth.
- Login usava uma coluna fixa suscetível a overflow com teclado e edge-to-edge. Login agora usa SafeArea, rolagem e viewInsets; cadastro, recuperação, perfil, edição e certificados também foram protegidos com SafeArea.
- compileSdk e targetSdk foram fixados em API 36. AGP, Gradle, Kotlin, Java e NDK foram alinhados ao template oficial do Flutter 3.35.4.
- Plugins nativos foram atualizados. Firebase foi fixado na geração compatível com Kotlin 2.1; releases posteriores exigiam metadados Kotlin 2.3, fora da matriz suportada pelo Flutter instalado.
- No Windows, projeto em G: e cache Pub em C: quebravam o cache incremental Kotlin. A compilação Kotlin foi configurada como não incremental/in-process.
- O teste de contador do template, que falhava e não representava o aplicativo, foi substituído por testes do modelo de usuário.

## Bibliotecas nativas e 16 KB

O AAB final contém, para arm64-v8a, armeabi-v7a e x86_64:

- libapp.so
- libflutter.so
- libdatastore_shared_counter.so

Os três APKs release por ABI passaram em `zipalign -c -P 16 4`. O APK arm64 foi verificado em modo detalhado e todas as três bibliotecas ficaram alinhadas. O engine Flutter atualizado e o NDK 27 corrigem o risco presente no artefato antigo.

## APIs de barras do sistema

Não há chamadas próprias a `Window.setStatusBarColor`, `Window.setNavigationBarColor` ou `Window.setNavigationBarDividerColor`. Eventuais referências remanescentes pertencem ao embedding/engine Flutter e são mantidas pelo SDK para compatibilidade entre versões Android; arquivos internos do Flutter não foram modificados.

## Exclusão de conta

Existe opção autenticada no menu, com aceite, senha, reautenticação e segunda confirmação. Ela remove certificados, solicitações, perfil e conta Firebase do próprio UID. A efetividade e autorização ainda dependem das regras implantadas no Firebase. Não há Cloud Function/backend neste repositório para tornar a operação atômica ou aplicar retenção legal; isso deve ser validado antes da publicação. A URL externa `https://www.ibcjj.com/exclusao-de-conta` também deve ser corrigida/validada fora deste repositório.

## Validações executadas

- `flutter doctor -v`: Android SDK 36.1 e Java 17 detectados; licenças Android parcialmente pendentes.
- `flutter pub get`: aprovado.
- `flutter test`: 2 testes aprovados.
- `flutter analyze`: sem erros de compilação; 45 diagnósticos de lint preexistentes (42 info e 3 warnings).
- `flutter build appbundle --release`: aprovado; AAB de 46,3 MB.
- `flutter build apk --release --split-per-abi`: aprovado nas três ABIs.
- Manifesto compilado: package `com.marysoarez.final_ibcjj`, versionName 9.0.2, targetSdk 36, compileSdk 36 e minSdk 24.

## Pendências manuais

- Testar instalação limpa, atualização sobre a versão 9, sessão válida/expirada e modo offline em dispositivos ou emuladores Android 15 e 16.
- Testar em dispositivo/emulador configurado com páginas reais de 16 KB; o alinhamento do artefato foi validado, mas não havia dispositivo Android conectado.
- Validar Firebase Auth, Firestore, regras de segurança, exclusão integral/retção, upload de foto/certificados e abertura do WhatsApp/site contra o ambiente de produção.
- Revisar visualmente edge-to-edge com navegação por gestos, três botões, rotação e teclado.
- Aceitar as licenças Android pendentes no ambiente de build.
- Validar a página externa de exclusão e atualizar o formulário do Google Play Console.
- Resolver os lints restantes em uma rodada separada, sem bloquear o release atual.

## Artefatos

- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

Nenhum artefato foi publicado e nenhum identificador, credencial ou configuração de assinatura foi alterado.
