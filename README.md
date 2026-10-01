# IBCJJ — Carteira Digital

Aplicativo Flutter com autenticação, perfil e certificados usando Firebase Auth,
Firestore e Storage. Repositório: https://github.com/marysoarez/ibcjj.git.

## Ambiente de referência

- Flutter **3.35.4**, canal stable, revisão `d693b4b9db`.
- Dart **3.9.2**, incluído nessa versão do Flutter.
- Java **17** (ambiente verificado: Temurin 17.0.16+8).
- Android SDK instalado e licenças aceitas. Ambiente local: SDK/build-tools 36.1.0.
- Configuração atual: Gradle 8.2.1, Android Gradle Plugin 8.2.1, Kotlin 1.9.0,
  Android mínimo 23 e target 34.

`.flutter-version` registra a versão de referência; não instala nem seleciona o
SDK automaticamente. Instale essa versão e coloque seu diretório `bin` no PATH.
Mantenha `pubspec.lock` versionado para reproduzir as dependências resolvidas.

## Preparar e executar

```powershell
git clone https://github.com/marysoarez/ibcjj.git
cd ibcjj
flutter --version
dart --version
flutter doctor -v
flutter doctor --android-licenses
flutter pub get --enforce-lockfile
flutter devices
flutter run -d <id-do-dispositivo-android>
```

Conecte um dispositivo Android com depuração USB ou inicie um emulador.
`android/local.properties` contém os caminhos locais do SDK Android e Flutter e
é ignorado pelo Git. O Flutter normalmente o gera; confira esses caminhos caso
o Gradle não encontre os SDKs.

O projeto usa o Firebase `ibcjj-fa960`. Os identificadores do aplicativo estão em
`lib/firebase_options.dart`, `android/app/google-services.json` e nas configurações
nativas existentes. Para usar outro projeto, gere configurações correspondentes
para o application ID `com.marysoarez.ibcjj_flutter` e as plataformas desejadas.
O responsável pelo Firebase precisa habilitar autenticação por e-mail/senha,
Firestore e Storage e configurar suas regras de acesso. As regras publicadas não
estão incluídas nem foram auditadas nesta etapa. Não use dados reais para testes.

## Assinatura Android

Builds debug não precisam da chave de produção. Para release:

```powershell
# Apenas em um clone novo, se o arquivo local ainda não existir:
Copy-Item android/key.properties.example android/key.properties
```

Edite `android/key.properties` localmente com o alias, as senhas e o caminho da
chave existente. Use barras `/` no caminho; caminhos relativos partem de
`android/`. Não substitua uma chave usada para publicar o aplicativo sem verificar
o processo de assinatura existente. O arquivo local e os keystores são ignorados.
O build release deve falhar se a configuração ou o arquivo de chave estiver ausente.

```powershell
flutter build appbundle --release --no-pub
```

O caminho antigo do keystore não existe nesta máquina. É necessário recuperar a
chave correta e atualizar `storeFile` antes de assinar um release. As credenciais
anteriores foram preservadas somente no arquivo local; não foram rotacionadas.

## Verificações e limitações conhecidas

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

O teste de contador foi substituído por testes reais de inicialização, sessão,
repositórios e navegação. A arquitetura está documentada em
[arquitetura e autenticação](docs/architecture.md).

A configuração Android ainda contém carregamento legado de plugins em
`android/settings.gradle`: a verificação `gradlew help` confirmou que o Flutter
instalado rejeita esse método. É necessário migrar o carregamento de plugins em
uma próxima etapa antes de executar/buildar Android. Isso também impediu validar
a nova configuração de assinatura no Gradle real.

Veja [a revisão das dependências](docs/dependency-baseline.md) e
[o registro da preparação](docs/secure-baseline.md).

## Contrato de usuários

Leia [o contrato de dados e sua compatibilidade](docs/user-data-contract.md).
Os testes específicos de cadastro, leitura, foto e conversão podem ser executados
com `flutter test --no-pub test/models test/repositories test/viewmodels`.
