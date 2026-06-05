import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';

enum TemplateChannel {
  male('male'),
  female('female');

  const TemplateChannel(this.value);

  final String value;

  static TemplateChannel fromString(String value) {
    return TemplateChannel.values.firstWhere(
      (channel) => channel.value == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Unknown template channel'),
    );
  }
}

enum OpeningSampleStyle {
  scene('scene'),
  character('character'),
  suspense('suspense');

  const OpeningSampleStyle(this.value);

  final String value;

  static OpeningSampleStyle fromString(String value) {
    return OpeningSampleStyle.values.firstWhere(
      (style) => style.value == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown opening sample style',
      ),
    );
  }
}

class WorldTemplateLibrary {
  const WorldTemplateLibrary({
    required this.templateSchemaVersion,
    required this.language,
    required this.templates,
  });

  final int templateSchemaVersion;
  final String language;
  final List<WorldTemplate> templates;

  factory WorldTemplateLibrary.fromJson(Map<String, dynamic> json) {
    return WorldTemplateLibrary(
      templateSchemaVersion: json['templateSchemaVersion'] as int,
      language: json['language'] as String,
      templates: (json['templates'] as List<dynamic>)
          .map((item) => WorldTemplate.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorldTemplate {
  const WorldTemplate({
    required this.id,
    required this.channel,
    required this.sortOrder,
    required this.genreName,
    required this.subtitle,
    required this.description,
    required this.iconName,
    required this.tags,
    required this.review,
    required this.world,
    required this.characters,
    required this.foreshadowingArcs,
    required this.openingSamples,
  });

  final String id;
  final TemplateChannel channel;
  final int sortOrder;
  final String genreName;
  final String subtitle;
  final String description;
  final String iconName;
  final List<String> tags;
  final TemplateReviewMetadata review;
  final WorldTemplateWorld world;
  final List<WorldTemplateCharacter> characters;
  final List<ForeshadowingArc> foreshadowingArcs;
  final List<OpeningSample> openingSamples;

  String get displayTitle => '$genreName｜$subtitle';

  factory WorldTemplate.fromJson(Map<String, dynamic> json) {
    return WorldTemplate(
      id: json['id'] as String,
      channel: TemplateChannel.fromString(json['channel'] as String),
      sortOrder: json['sortOrder'] as int,
      genreName: json['genreName'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      review: TemplateReviewMetadata.fromJson(
        json['review'] as Map<String, dynamic>,
      ),
      world: WorldTemplateWorld.fromJson(json['world'] as Map<String, dynamic>),
      characters: (json['characters'] as List<dynamic>)
          .map(
            (item) =>
                WorldTemplateCharacter.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      foreshadowingArcs: (json['foreshadowingArcs'] as List<dynamic>)
          .map(
            (item) => ForeshadowingArc.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      openingSamples: (json['openingSamples'] as List<dynamic>)
          .map((item) => OpeningSample.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final searchableText = [
      genreName,
      subtitle,
      description,
      ...tags,
    ].join(' ').toLowerCase();
    return searchableText.contains(normalized);
  }
}

class TemplateReviewMetadata {
  const TemplateReviewMetadata({
    required this.sourceNote,
    required this.reviewedAt,
    required this.qualityChecks,
  });

  final String sourceNote;
  final DateTime reviewedAt;
  final List<String> qualityChecks;

  factory TemplateReviewMetadata.fromJson(Map<String, dynamic> json) {
    return TemplateReviewMetadata(
      sourceNote: json['sourceNote'] as String,
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      qualityChecks: (json['qualityChecks'] as List<dynamic>).cast<String>(),
    );
  }
}

class WorldTemplateWorld {
  const WorldTemplateWorld({
    required this.name,
    required this.description,
    required this.rules,
    required this.factions,
    required this.geography,
    required this.techLevel,
    required this.aliases,
  });

  final String name;
  final String description;
  final String rules;
  final String factions;
  final String geography;
  final String techLevel;
  final List<String> aliases;

  factory WorldTemplateWorld.fromJson(Map<String, dynamic> json) {
    return WorldTemplateWorld(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      rules: json['rules'] as String? ?? '',
      factions: json['factions'] as String? ?? '',
      geography: json['geography'] as String? ?? '',
      techLevel: json['techLevel'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  WorldSetting toWorldSetting() {
    return WorldSetting(
      id: '',
      name: name,
      description: description,
      rules: rules,
      factions: factions,
      geography: geography,
      techLevel: techLevel,
      aliases: aliases,
      createdAt: DateTime.now(),
    );
  }
}

class WorldTemplateCharacter {
  const WorldTemplateCharacter({
    required this.name,
    required this.personality,
    required this.appearance,
    required this.backstory,
    required this.aliases,
  });

  final String name;
  final String personality;
  final String appearance;
  final String backstory;
  final List<String> aliases;

  factory WorldTemplateCharacter.fromJson(Map<String, dynamic> json) {
    return WorldTemplateCharacter(
      name: json['name'] as String,
      personality: json['personality'] as String? ?? '',
      appearance: json['appearance'] as String? ?? '',
      backstory: json['backstory'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  CharacterCard toCharacterCard() {
    return CharacterCard(
      id: '',
      name: name,
      personality: personality,
      appearance: appearance,
      backstory: backstory,
      aliases: aliases,
      createdAt: DateTime.now(),
    );
  }
}

class ForeshadowingArc {
  const ForeshadowingArc({
    required this.setup,
    required this.development,
    required this.payoff,
  });

  final String setup;
  final String development;
  final String payoff;

  String get displayText => '$setup -> $development -> $payoff';

  factory ForeshadowingArc.fromJson(Map<String, dynamic> json) {
    return ForeshadowingArc(
      setup: json['setup'] as String,
      development: json['development'] as String,
      payoff: json['payoff'] as String,
    );
  }
}

class OpeningSample {
  const OpeningSample({required this.style, required this.text});

  final OpeningSampleStyle style;
  final String text;

  factory OpeningSample.fromJson(Map<String, dynamic> json) {
    return OpeningSample(
      style: OpeningSampleStyle.fromString(json['style'] as String),
      text: json['text'] as String,
    );
  }
}
