// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openUrlInBrowser(String url) {
  html.window.location.assign(url);
}

String getCurrentWebOrigin() {
  try {
    return html.window.location.origin;
  } catch (e) {
    return 'http://localhost:8088';
  }
}
