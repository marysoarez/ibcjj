import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../data/certificates_repository.dart';
import '../models/certificate.dart';
import '../data/activation_contact.dart';

class CertificatesViewModel extends ChangeNotifier {
  final CertificatesRepository _repository;
  final String uid;
  final ActivationContact? _contact;
  List<Certificate> _items = [];
  List<Certificate> get items => List.unmodifiable(_items);
  bool busy = false;
  String? error;
  String? message;
  bool _disposed = false;
  CertificatesViewModel(this._repository, this.uid,
      {ActivationContact? contact})
      : _contact = contact;

  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    message = null;
    notifyListeners();
    try {
      await action();
    } catch (failure) {
      if (!_disposed) {
        error =
            failureMessage(failure, 'Não foi possível concluir a operação.');
      }
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> load() => _run(() async {
        final result = await _repository.list(uid);
        if (!_disposed) _items = result;
      });

  Future<void> add() => _run(() async {
        if (await _repository.add(uid)) {
          if (_disposed) return;
          message = 'Certificado enviado.';
          final result = await _repository.list(uid);
          if (!_disposed) _items = result;
        }
      });

  Future<void> delete(Certificate item) => _run(() async {
        await _repository.delete(uid, item.name);
        if (!_disposed) {
          _items = _items.where((value) => value.name != item.name).toList();
          message = 'Certificado excluído.';
        }
      });

  Future<void> requestActivation() => _run(() async {
        final contact = _contact;
        if (contact == null) {
          throw const AppFailure(
              'contact-missing', 'Contato de ativação não configurado.');
        }
        await contact.openConversation();
        if (!_disposed) {
          message =
              'Conversa aberta. Confirme o envio da mensagem no WhatsApp.';
        }
      });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
