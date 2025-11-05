// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

Future<bool> saveTextFile(String filename, String content) async {
  final bytes = utf8.encode(content);
  final base64 = base64Encode(bytes);
  final anchor = html.AnchorElement(href: 'data:text/plain;base64,$base64')
    ..setAttribute('download', filename);
  anchor.click();
  return true;
}
