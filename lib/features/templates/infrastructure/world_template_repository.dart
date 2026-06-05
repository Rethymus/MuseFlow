import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:museflow/features/templates/domain/world_template.dart';

typedef TemplateAssetLoader = Future<String> Function(String path);

class WorldTemplateRepository {
  WorldTemplateRepository({
    this.assetPath = 'assets/templates/world_presets/templates_zh.json',
    TemplateAssetLoader? assetLoader,
  }) : _assetLoader = assetLoader ?? rootBundle.loadString;

  final String assetPath;
  final TemplateAssetLoader _assetLoader;

  WorldTemplateLibrary? _cache;

  Future<WorldTemplateLibrary> loadLibrary() async {
    final cached = _cache;
    if (cached != null) return cached;

    final content = await _assetLoader(assetPath);
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final library = WorldTemplateLibrary.fromJson(decoded);
    _cache = library;
    return library;
  }

  Future<List<WorldTemplate>> getAll() async {
    final library = await loadLibrary();
    final templates = [...library.templates]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return templates;
  }

  Future<WorldTemplate?> getById(String id) async {
    final templates = await getAll();
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  Future<List<WorldTemplate>> filterByChannel(TemplateChannel? channel) async {
    final templates = await getAll();
    if (channel == null) return templates;
    return templates.where((template) => template.channel == channel).toList();
  }

  Future<List<WorldTemplate>> search(String query) async {
    final templates = await getAll();
    return templates.where((template) => template.matchesQuery(query)).toList();
  }
}
