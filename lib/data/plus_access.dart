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

  bool owned = false, available = false, pending = false, busy = false;
  bool testing = kDebugMode;
  String? price, error;
  bool get enabled => testing || owned;
  Future<void> refresh() => _request('status');
  Future<void> restore() => _request('restore');
  Future<void> buy() => _request('buy');
  Future<void> _request(String method) async {
    if (busy || _closed) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
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
