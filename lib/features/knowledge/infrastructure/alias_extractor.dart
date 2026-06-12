/// Automatic alias/nickname extractor from character descriptions.
///
/// Scans personality, appearance, and backstory text for common Chinese
/// nickname patterns and extracts potential aliases that the [NameIndex]
/// can use for fuzzy matching.
///
/// Phase 20 (KNOW-01): Enables knowledge injection to match characters
/// even when the text uses nicknames not explicitly registered as aliases.
library;

/// Extracts potential aliases from character description text.
///
/// Recognizes common Chinese nickname patterns:
/// - 小 + surname/given name: 小林, 小风
/// - 阿 + given name: 阿云
/// - 老 + surname: 老王
/// - 儿 suffix: 风儿
/// - Title + surname: 李掌柜, 张师兄
class AliasExtractor {
  /// Minimum alias length to be considered valid.
  static const minAliasLength = 2;

  /// Maximum alias length to be considered valid.
  static const maxAliasLength = 6;

  /// Common Chinese surname characters (top 100, abbreviated).
  ///
  /// Used to detect surname-based nickname patterns like 小林, 老王.
  static const _commonSurnames = {
    '王', '李', '张', '刘', '陈', '杨', '黄', '赵', '周', '吴',
    '徐', '孙', '胡', '朱', '高', '林', '何', '郭', '马', '罗',
    '梁', '宋', '郑', '谢', '韩', '唐', '冯', '于', '董', '萧',
    '程', '曹', '袁', '邓', '许', '傅', '沈', '曾', '彭', '吕',
    '苏', '卢', '蒋', '蔡', '贾', '丁', '魏', '薛', '叶', '阎',
    '余', '潘', '杜', '戴', '夏', '钟', '汪', '田', '任', '姜',
    '范', '方', '石', '姚', '谭', '廖', '邹', '熊', '金', '陆',
    '郝', '孔', '白', '崔', '康', '毛', '邱', '秦', '江', '史',
    '顾', '侯', '邵', '孟', '龙', '万', '段', '雷', '钱', '汤',
  };

  /// Common titles that form title+name patterns.
  static const _titles = {
    '掌柜', '师傅', '师兄', '师姐', '师弟', '师妹',
    '大哥', '大姐', '二哥', '二姐',
    '公子', '小姐', '姑娘', '老爷', '夫人',
    '师父', '徒弟', '道长', '方丈', '长老',
  };

  /// Extracts potential aliases from character text fields.
  ///
  /// [name] is the character's official name (used to derive nickname
  /// components like surname and given name).
  /// [description], [personality], [appearance], [backstory] are the
  /// text fields to scan for patterns.
  /// [existingAliases] are already-known aliases to exclude from results.
  /// [extraText] is any additional text to scan.
  List<String> extract({
    required String name,
    String? description,
    String? personality,
    String? appearance,
    String? backstory,
    String? extraText,
    List<String> existingAliases = const [],
  }) {
    if (name.length < 2) return const [];

    // Combine all text sources
    final text = [
      description,
      personality,
      appearance,
      backstory,
      extraText,
    ].where((s) => s != null && s.isNotEmpty).join('\n');

    if (text.isEmpty) return const [];

    // Parse name into components
    final surname = _extractSurname(name);
    final givenName = _extractGivenName(name, surname);

    // Build exclusion set
    final exclude = <String>{
      name,
      ...existingAliases,
    };

    // Collect aliases from all patterns
    final found = <String>{};

    // Pattern 1: 小 + surname/given name (小林, 小风)
    _findPrefixedAlias(text, '小', surname, exclude, found);
    _findPrefixedAlias(text, '小', givenName, exclude, found);

    // Pattern 2: 阿 + given name (阿云)
    _findPrefixedAlias(text, '阿', givenName, exclude, found);

    // Pattern 3: 老 + surname (老王)
    _findPrefixedAlias(text, '老', surname, exclude, found);

    // Pattern 4: 儿 suffix (风儿)
    _findSuffixAlias(text, '儿', givenName, exclude, found);
    _findSuffixAlias(text, '儿', name, exclude, found);

    // Pattern 5: Title + surname/name (李掌柜, 张师兄)
    for (final title in _titles) {
      _findTitleAlias(text, title, surname, exclude, found);
      _findTitleAlias(text, title, name, exclude, found);
    }

    // Filter by length and return
    return found
        .where(
          (a) =>
              a.length >= minAliasLength && a.length <= maxAliasLength,
        )
        .toList()
      ..sort();
  }

  /// Extracts the likely surname from a Chinese name.
  ///
  /// For 2-char names: assumes first char is surname (common for modern).
  /// For 3+ char names: checks if first char is a common surname, then
  /// tries 2-char compound surnames.
  String _extractSurname(String name) {
    if (name.isEmpty) return '';

    // Single char name — no surname to extract
    if (name.length == 1) return name;

    // Check for compound surnames (2-char surnames)
    if (name.length >= 3) {
      final compound = name.substring(0, 2);
      if (_isCompoundSurname(compound)) return compound;
    }

    // Default: first character is surname (validate against known surnames)
    final candidate = name[0];
    if (_commonSurnames.contains(candidate)) return candidate;
    return candidate;
  }

  /// Checks if a 2-character string is a known compound surname.
  bool _isCompoundSurname(String s) {
    // Common compound surnames in Chinese
    const compoundSurnames = {
      '欧阳', '上官', '司马', '诸葛', '东方', '西门', '南宫',
      '北堂', '令狐', '慕容', '轩辕', '公孙', '百里',
    };
    return compoundSurnames.contains(s);
  }

  /// Extracts the given name (excluding surname).
  String _extractGivenName(String name, String surname) {
    if (name.length <= surname.length) return '';
    return name.substring(surname.length);
  }

  /// Finds prefix+name patterns (小风, 阿云, 老王) in text.
  void _findPrefixedAlias(
    String text,
    String prefix,
    String namePart,
    Set<String> exclude,
    Set<String> found,
  ) {
    if (namePart.isEmpty) return;
    final candidate = '$prefix$namePart';
    if (exclude.contains(candidate)) return;
    if (text.contains(candidate)) {
      found.add(candidate);
    }
  }

  /// Finds name+suffix patterns (风儿) in text.
  void _findSuffixAlias(
    String text,
    String suffix,
    String namePart,
    Set<String> exclude,
    Set<String> found,
  ) {
    if (namePart.isEmpty) return;
    final candidate = '$namePart$suffix';
    if (exclude.contains(candidate)) return;
    if (text.contains(candidate)) {
      found.add(candidate);
    }
  }

  /// Finds title+name patterns (李掌柜, 张师兄) in text.
  void _findTitleAlias(
    String text,
    String title,
    String namePart,
    Set<String> exclude,
    Set<String> found,
  ) {
    if (namePart.isEmpty) return;
    final candidate = '$namePart$title';
    if (exclude.contains(candidate)) return;
    if (text.contains(candidate)) {
      found.add(candidate);
    }
  }
}
