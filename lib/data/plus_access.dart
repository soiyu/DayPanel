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

  bool owned = _forcePlus,
      available = _forcePlus,
      pending = false,
      busy = false;
  bool testing = kDebugMode && !_forceFree && !_forcePlus;
  String? price, error;
  bool get enabled {
    if (_forceFree) return false;
    if (_forcePlus) return true;
    return testing || owned;
  }

  Future<void> refresh() => _request('status');
  Future<void> restore() => _request('restore');
  Future<void> buy() => _request('buy');
  Future<void> _request(String method) async {
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
      if (_forceFree) {
        owned = false;
        available = false;
        pending = false;
        testing = false;
        return;
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
      }
    } on MissingPluginException {
      available = false;
    } on PlatformException catch (e) {
      error = e.code;
    } finally {
      busy = false;
      if (!_closed) notifyListeners();
    }
  }
}
