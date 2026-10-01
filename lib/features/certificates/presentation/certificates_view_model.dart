import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../data/certificates_repository.dart';
import '../models/certificate.dart';

class CertificatesViewModel extends ChangeNotifier {
  final CertificatesRepository _repository;
  final String uid;
  List<Certificate> _items = [];
  List<Certificate> get items => List.unmodifiable(_items);
  bool busy = false;
  String? error;
  bool _disposed = false;
  CertificatesViewModel(this._repository, this.uid);

  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
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
          final result = await _repository.list(uid);
          if (!_disposed) _items = result;
        }
      });

  Future<void> delete(Certificate item) => _run(() async {
        await _repository.delete(uid, item.name);
        if (!_disposed) {
          _items = _items.where((value) => value.name != item.name).toList();
        }
      });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
