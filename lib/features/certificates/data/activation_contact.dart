import 'package:url_launcher/url_launcher.dart';
import '../../../core/errors/app_failure.dart';

abstract class ActivationContact {
  Future<void> openConversation();
}

class WhatsAppActivationContact implements ActivationContact {
  final Future<bool> Function(Uri)? launcher;
  const WhatsAppActivationContact({this.launcher});

  static Uri get conversationUri => Uri.https('wa.me', '/5521990466071', {
        'text':
            'Olá! Gostaria de solicitar a ativação da minha carteirinha IBCJJ.',
      });

  @override
  Future<void> openConversation() async {
    try {
      final opened = await (launcher?.call(conversationUri) ??
          launchUrl(conversationUri, mode: LaunchMode.externalApplication));
      if (!opened) throw StateError('No external application');
    } catch (_) {
      throw const AppFailure('whatsapp-unavailable',
          'Não foi possível abrir o WhatsApp. Tente novamente ou contate a IBCJJ pelo número +55 21 99046-6071.');
    }
  }
}
