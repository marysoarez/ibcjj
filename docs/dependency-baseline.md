# Revisão das dependências

Durante o diagnóstico anterior, `flutter analyze` executou a resolução automática
de dependências e alterou 14 versões transitivas. Não havia Git nem uma cópia
confirmada do lockfile anterior. O backup desta etapa já contém o resultado dessa
resolução; não é uma cópia anterior ao diagnóstico.

| Pacote | Antes, conforme log | Atual |
| --- | --- | --- |
| characters | 1.3.0 | 1.4.0 |
| clock | 1.1.1 | 1.1.2 |
| collection | 1.19.0 | 1.19.1 |
| fake_async | 1.3.1 | 1.3.3 |
| leak_tracker | 10.0.7 | 11.0.2 |
| leak_tracker_flutter_testing | 3.0.8 | 3.0.10 |
| leak_tracker_testing | 3.0.1 | 3.0.2 |
| matcher | 0.12.16+1 | 0.12.17 |
| meta | 1.15.0 | 1.16.0 |
| path | 1.9.0 | 1.9.1 |
| stack_trace | 1.12.0 | 1.12.1 |
| stream_channel | 2.1.2 | 2.1.4 |
| test_api | 0.7.3 | 0.7.6 |
| vector_math | 2.1.4 | 2.2.0 |

As mudanças incluem bibliotecas utilizadas pelo Flutter e pelo seu framework de
testes. O log não permite reconstruir com segurança todos os hashes e requisitos
do lockfile anterior. Por isso, preservamos o lockfile atual como primeira base
versionada, sem editar versões ou hashes manualmente. `pubspec.yaml` permanece
com as restrições existentes; não foi executado upgrade de dependências diretas.

O lockfile declara Dart `>=3.8.0-0 <4.0.0` e Flutter `>=3.27.0`, embora o pubspec
ainda permita Dart desde 3.1.3. Use Flutter 3.35.4 / Dart 3.9.2 para esta base.
Uma futura revisão deve alinhar o mínimo declarado ao ambiente realmente testado.

Para conferir a resolução sem permitir atualização silenciosa do lockfile:

```powershell
flutter pub get --enforce-lockfile
```

Depois, use `--no-pub` nos comandos de análise, testes e build. Atualizações de
pacotes devem ser feitas separadamente, com revisão do diff de `pubspec.lock`.
