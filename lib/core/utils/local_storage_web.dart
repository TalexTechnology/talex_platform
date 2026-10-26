import 'package:web/web.dart' as web;

void writeLocalStorage(String key, String value) {
  web.window.localStorage.setItem(key, value);
}
