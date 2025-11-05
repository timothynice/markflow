import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Local storage for Markdown documents backed by SharedPreferences.
///
/// Design
/// - Persist a list of documents under [_docsKey].
/// - Track the last opened document id under [_currentIdKey].
/// - Keep compatibility with legacy single-doc storage via [_legacyCurrentDocKey].
class MdLocalStore {
  static const _legacyCurrentDocKey = 'markdown.currentDoc';
  static const _docsKey = 'markdown.docs';
  static const _currentIdKey = 'markdown.currentDocId';
  static const _maxVersions = 20;

  /// Return the last opened document, or create a starter document if none exist.
  Future<MdDocument> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_currentIdKey);
    if (id != null) {
      final doc = await findById(id);
      if (doc != null) return doc;
    }
    // Fallback to legacy stored single document
    final legacyRaw = prefs.getString(_legacyCurrentDocKey);
    if (legacyRaw != null) {
      final jsonMap = jsonDecode(legacyRaw) as Map<String, dynamic>;
      final legacy = MdDocument.fromJson(jsonMap);
      // Ensure it's present in the list for consistency
      await save(legacy);
      return legacy;
    }
    // Nothing found: create a starter doc and commit it
    final starter = MdDocument(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Welcome',
      content: _starterContent,
      updatedAt: DateTime.now(),
      versions: [
        MdVersion(
          id: 'v_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
          content: _starterContent,
        ),
      ],
    );
    await save(starter);
    return starter;
  }

  /// List all persisted documents, sorted by updatedAt desc.
  Future<List<MdDocument>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_docsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => MdDocument.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (_) {
      // Corrupt data: reset
      await prefs.remove(_docsKey);
      return [];
    }
  }

  /// Find a document by id. Checks committed list and legacy current doc.
  Future<MdDocument?> findById(String id) async {
    final docs = await list();
    final match = docs.where((d) => d.id == id).toList();
    if (match.isNotEmpty) return match.first;
    final prefs = await SharedPreferences.getInstance();
    final legacyRaw = prefs.getString(_legacyCurrentDocKey);
    if (legacyRaw != null) {
      final jsonMap = jsonDecode(legacyRaw) as Map<String, dynamic>;
      final legacy = MdDocument.fromJson(jsonMap);
      if (legacy.id == id) return legacy;
    }
    return null;
  }

  /// Upsert the document into the list and mark as current. Also writes legacy key.
  Future<void> save(MdDocument doc) async {
    final prefs = await SharedPreferences.getInstance();
    final docs = await list();
    final idx = docs.indexWhere((d) => d.id == doc.id);
    if (idx >= 0) {
      docs[idx] = doc;
    } else {
      docs.add(doc);
    }
    // Keep a rolling versions history capped at [_maxVersions]
    if (doc.versions.length > _maxVersions) {
      doc.versions = doc.versions.sublist(doc.versions.length - _maxVersions);
    }
    final jsonStr = jsonEncode(docs.map((d) => d.toJson()).toList());
    await prefs.setString(_docsKey, jsonStr);
    await prefs.setString(_currentIdKey, doc.id);
    await prefs.setString(_legacyCurrentDocKey, jsonEncode(doc.toJson()));
  }

  /// Create a new unsaved document and set it as current. It is added to the list on first save.
  Future<MdDocument> createNew({String? title}) async {
    final now = DateTime.now();
    final doc = MdDocument(
      id: 'local-${now.millisecondsSinceEpoch}',
      title: (title?.trim().isNotEmpty ?? false) ? title!.trim() : 'Untitled',
      content: '',
      updatedAt: now,
      versions: [
        MdVersion(
          id: 'v_${now.millisecondsSinceEpoch}',
          createdAt: now,
          content: '',
        ),
      ],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentIdKey, doc.id);
    await prefs.setString(_legacyCurrentDocKey, jsonEncode(doc.toJson()));
    return doc;
  }

  /// Remove the legacy current document cache.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyCurrentDocKey);
  }

  /// Snapshot the current content into the document's versions and persist.
  Future<MdDocument> snapshot(MdDocument doc) async {
    final snapshot = MdVersion(
      id: 'v_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      content: doc.content,
    );
    final versions = [...doc.versions, snapshot];
    if (versions.length > _maxVersions) {
      versions.removeAt(0);
    }
    final updated = MdDocument(
      id: doc.id,
      title: doc.title,
      content: doc.content,
      updatedAt: DateTime.now(),
      versions: versions,
    );
    await save(updated);
    return updated;
  }
}

const _starterContent = '# Welcome to Markdown Editor\n\n'
    'This is a lightweight editor with live preview, autosave, and shortcuts.\n\n'
    '- Use the toolbar or ⌘/Ctrl + B, I for formatting.\n'
    '- Toggle Styled on mobile to see rendered Markdown.\n\n'
    '```dart\n'
    'void main() => print("Hello Markdown");\n'
    '```\n';
