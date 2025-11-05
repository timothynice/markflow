// Fallback (non-web) no-op downloader. Returns false to indicate not supported.
Future<bool> saveTextFile(String filename, String content) async {
  return false;
}
