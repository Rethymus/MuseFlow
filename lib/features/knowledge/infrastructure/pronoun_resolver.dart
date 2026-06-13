/// Pronoun coreference resolver for Chinese text.
///
/// Maps pronouns (他/她/它/他们/她们) to recently mentioned characters
/// based on gender matching and recency of mention.
///
/// Phase 20 (KNOW-01): Enables knowledge injection to recognize when
/// pronouns refer to tracked characters, improving context relevance.
library;

/// Gender classification for characters.
enum Gender {
  /// Male (他).
  male,

  /// Female (她).
  female,

  /// Unknown or non-binary (它).
  unknown,
}

/// Result of pronoun resolution.
class PronounResolution {
  /// The character ID the pronoun resolves to.
  final String entityId;

  /// The character name the pronoun resolves to.
  final String entityName;

  /// The gender of the resolved character.
  final Gender gender;

  /// Position of the pronoun in the text.
  final int pronounPosition;

  const PronounResolution({
    required this.entityId,
    required this.entityName,
    required this.gender,
    required this.pronounPosition,
  });
}

/// Resolves Chinese pronouns to character entities based on context.
///
/// Uses a simple heuristic approach:
/// 1. Find all character name mentions in the text
/// 2. For each pronoun, find the closest preceding name mention
/// 3. Among same-gender characters, prefer the most recently mentioned
///
/// This is a lightweight, deterministic resolver suitable for real-time
/// editor context. It does not use ML models or external NLP libraries.
class PronounResolver {
  /// Pronoun-to-gender mapping.
  static const _pronounGenders = <String, Gender>{
    '他': Gender.male,
    '她': Gender.female,
    '它': Gender.unknown,
    '他们': Gender.male,
    '她们': Gender.female,
    '它们': Gender.unknown,
  };

  /// Resolves a single pronoun at a given position in the text.
  ///
  /// [pronoun] is the pronoun text (他/她/它).
  /// [pronounIndex] is the character offset of the pronoun in [text].
  /// [text] is the surrounding context text.
  /// [characters] maps character names to their gender.
  ///
  /// Returns null if the pronoun cannot be resolved.
  PronounResolution? resolvePronoun({
    required String pronoun,
    int? pronounIndex,
    required String text,
    required Map<String, Gender> characters,
  }) {
    if (text.isEmpty || characters.isEmpty) return null;

    final gender = _pronounGenders[pronoun];
    if (gender == null) return null;

    // Find position of pronoun in text if not provided
    final pronounPos = pronounIndex ?? text.indexOf(pronoun);
    if (pronounPos < 0) return null;

    // Find all character name mentions before the pronoun, with positions
    final mentions = <_NameMention>[];
    for (final entry in characters.entries) {
      final name = entry.key;
      final charGender = entry.value;
      var start = 0;
      while (start < pronounPos) {
        final index = text.indexOf(name, start);
        if (index == -1 || index >= pronounPos) break;
        mentions.add(
          _NameMention(name: name, gender: charGender, position: index),
        );
        start = index + name.length;
      }
    }

    if (mentions.isEmpty) return null;

    // Sort by position (most recent first)
    mentions.sort((a, b) => b.position.compareTo(a.position));

    // First try to find a gender-matched mention
    for (final m in mentions) {
      if (_genderMatches(m.gender, gender)) {
        return PronounResolution(
          entityId: m.name,
          entityName: m.name,
          gender: m.gender,
          pronounPosition: pronounPos,
        );
      }
    }

    // Fallback: if no gender match, try unknown-gender characters
    for (final m in mentions) {
      if (m.gender == Gender.unknown) {
        return PronounResolution(
          entityId: m.name,
          entityName: m.name,
          gender: m.gender,
          pronounPosition: pronounPos,
        );
      }
    }

    return null;
  }

  /// Resolves all pronouns in the text.
  ///
  /// Returns a list of [PronounResolution] for each pronoun found,
  /// in order of their position in the text.
  List<PronounResolution> resolveAll({
    required String text,
    required Map<String, Gender> characters,
  }) {
    if (text.isEmpty || characters.isEmpty) return const [];

    final results = <PronounResolution>[];
    var searchStart = 0;

    // Find pronouns from longest to shortest to handle overlapping matches
    // (e.g., 他们 before 他)
    final sortedPronouns = _pronounGenders.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    while (searchStart < text.length) {
      String? foundPronoun;
      int foundPos = -1;

      for (final pronoun in sortedPronouns) {
        final pos = text.indexOf(pronoun, searchStart);
        if (pos != -1 && (foundPos == -1 || pos < foundPos)) {
          foundPronoun = pronoun;
          foundPos = pos;
        }
      }

      if (foundPronoun == null || foundPos == -1) break;

      final resolution = resolvePronoun(
        pronoun: foundPronoun,
        pronounIndex: foundPos,
        text: text,
        characters: characters,
      );

      if (resolution != null) {
        results.add(resolution);
      }

      searchStart = foundPos + foundPronoun.length;
    }

    // Sort by position
    results.sort((a, b) => a.pronounPosition.compareTo(b.pronounPosition));
    return results;
  }

  /// Checks if a character's gender matches a pronoun's gender.
  bool _genderMatches(Gender charGender, Gender pronounGender) {
    if (charGender == pronounGender) return true;
    // male/female pronouns can also match unknown-gender characters
    // (as a fallback), but that's handled separately in resolvePronoun
    return false;
  }
}

/// Internal class tracking a character name mention in text.
class _NameMention {
  final String name;
  final Gender gender;
  final int position;

  const _NameMention({
    required this.name,
    required this.gender,
    required this.position,
  });
}
