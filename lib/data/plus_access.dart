import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlusAccess extends ChangeNotifier {
  static const channel = MethodChannel('app.daypanel.next/billing');
  bool _closed = false;
  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }

  static const bool _forceFree = bool.fromEnvironment(
    'DAYPANEL_FORCE_FREE',
    defaultValue: false,
  );
  static const bool _forcePlus = bool.fromEnvironment(
    'DAYPANEL_FORCE_PLUS',
    defaultValue: false,
  );

  bool _forceFreeActive = _forceFree;

  bool owned = _forcePlus,
      available = _forcePlus,
      pending = false,
      busy = false;
  late bool testing = (kDebugMode || _forcePlus) && !_forceFreeActive;
  String? price, error;
  bool get enabled {
    if (_forcePlus) return true;
    if (_forceFreeActive) return false;
    return testing || owned;
  }

  Future<void> refresh({bool userInitiated = false}) =>
      _request('status', userInitiated: userInitiated);
  Future<void> restore() => _request('restore', userInitiated: true);
  Future<void> buy() => _request('buy', userInitiated: true);
  Future<void> _request(String method, {bool userInitiated = false}) async {
    if (busy || _closed) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (_forcePlus) {
        owned = true;
        available = true;
        pending = false;
        testing = false;
        error = null;
        return;
      }
      if (_forceFreeActive) {
        if (userInitiated || method == 'restore' || method == 'buy') {
          _forceFreeActive = false;
        } else if (!kDebugMode) {
          owned = false;
          available = false;
          pending = false;
          testing = false;
          return;
        }
      }
      final map = await channel.invokeMapMethod<String, Object?>(method);
      if (_closed) return;
      if (map != null) {
        owned = map['owned'] == true;
        available = map['available'] == true;
        pending = map['pending'] == true;
        testing = map['testing'] == true && kDebugMode;
        price = map['price'] as String?;
        error = map['error'] as String?;
        if (userInitiated || method == 'restore' || method == 'buy') {
          _forceFreeActive = false;
        }
      }
    } on MissingPluginException {
      if (kDebugMode &&
          (userInitiated || method == 'restore' || method == 'buy')) {
        _forceFreeActive = false;
        testing = true;
        owned = true;
        available = true;
        error = null;
      } else {
        available = false;
      }
    } on PlatformException catch (e) {
      error = e.code;
    } finally {
      busy = false;
      if (!_closed) notifyListeners();
    }
  }
}
