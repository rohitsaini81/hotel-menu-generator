import 'dart:html' as html;

String? readWebClientId() {
  final meta = html.document.querySelector(
    'meta[name="google-signin-client_id"]',
  );
  final content = meta?.getAttribute('content')?.trim();
  if (content == null || content.isEmpty) {
    return null;
  }
  return content;
}
