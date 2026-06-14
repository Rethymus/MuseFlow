/// Knowledge-base staleness checker (MC-01).
///
/// Per MC-01 (research roadmap; NAACL 2025 DOME temporal conflict analysis):
/// as the story grows past ~100 chapters, a static knowledge base becomes a
/// liability — character cards and world settings go stale as the story
/// develops, and the AI is fed outdated context. This checker quantifies how
/// stale a KB entry is, given the chapter at which it was last verified and
/// the current chapter count, so the UI can prompt the author to refresh.
///
/// Levels:
///   - [KbStalenessLevel.fresh]: < [staleThreshold] chapters since verified
///     (or a legacy entry with no tracked verification chapter — treated as
///     fresh/unknown to avoid false positives on migration).
///   - [KbStalenessLevel.stale]: >= [staleThreshold] (10) chapters since verified.
///   - [KbStalenessLevel.veryStale]: >= [veryStaleThreshold] (20) chapters.
library;

/// How stale a knowledge-base entry is relative to the current chapter.
enum KbStalenessLevel {
  /// Recently verified (or legacy/untracked — not nagged).
  fresh,

  /// Approaching staleness — worth a review.
  stale,

  /// Severely out of date — risks feeding the AI conflicting context.
  veryStale,
}

/// The staleness verdict for a single KB entry.
class KbStalenessResult {
  /// The staleness level.
  final KbStalenessLevel level;

  /// How many chapters have passed since verification, or null if the entry
  /// has no tracked verification chapter (legacy data).
  final int? chaptersSinceVerified;

  /// Human-readable Chinese explanation for the UI.
  final String message;

  const KbStalenessResult({
    required this.level,
    required this.chaptersSinceVerified,
    required this.message,
  });
}

/// Computes staleness for knowledge-base entries.
class KbStalenessChecker {
  const KbStalenessChecker();

  /// Chapters-since-verification at/above which an entry is "stale" (worth
  /// review). Per MC-01: "超过 10 章未验证时自动提醒".
  static const int staleThreshold = 10;

  /// Chapters-since-verification at/above which an entry is "very stale"
  /// (urgent refresh). Double the stale threshold.
  static const int veryStaleThreshold = 20;

  /// Evaluates staleness for an entry verified at [lastVerifiedChapter]
  /// against the manuscript's [currentChapterCount].
  ///
  /// [lastVerifiedChapter] null means the entry predates staleness tracking
  /// (legacy data) — treated as fresh/unknown so migration doesn't nag.
  KbStalenessResult check(int? lastVerifiedChapter, int currentChapterCount) {
    if (lastVerifiedChapter == null) {
      return KbStalenessResult(
        level: KbStalenessLevel.fresh,
        chaptersSinceVerified: null,
        message: '该条目为旧版数据，尚未追踪验证章节。',
      );
    }

    // Defensive clamp: a stored verified-chapter ahead of the current count
    // (rollback / corruption) must never yield a negative staleness.
    final since = (currentChapterCount - lastVerifiedChapter).clamp(
      0,
      currentChapterCount < 0 ? 0 : 1 << 30,
    );

    if (since >= veryStaleThreshold) {
      return KbStalenessResult(
        level: KbStalenessLevel.veryStale,
        chaptersSinceVerified: since,
        message:
            '⚠️ 该条目已 $since 章未验证，严重过期，知识库可能正为 AI '
            '提供陈旧上下文，强烈建议立即回顾刷新。',
      );
    }
    if (since >= staleThreshold) {
      return KbStalenessResult(
        level: KbStalenessLevel.stale,
        chaptersSinceVerified: since,
        message: '该条目已 $since 章未验证，可能已过期，建议回顾更新角色/设定。',
      );
    }
    if (since == 0) {
      return KbStalenessResult(
        level: KbStalenessLevel.fresh,
        chaptersSinceVerified: 0,
        message: '该条目在本章刚刚验证，知识库信息新鲜。',
      );
    }
    return KbStalenessResult(
      level: KbStalenessLevel.fresh,
      chaptersSinceVerified: since,
      message: '该条目在 $since 章前验证，仍在保鲜期内。',
    );
  }
}
