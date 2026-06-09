# Author-Controlled Diff Alignment

## Context

README positions MuseFlow as author-led AI assistance: AI can help polish text,
but the author keeps control over story decisions. Recent external HCI research
also frames writer agency and ownership as central risks in AI-assisted writing.

MuseFlow already exposes sentence-level accept/reject controls after editor AI
operations. The weak point was the diff alignment algorithm: it paired sentences
by position. If AI inserted or removed one sentence, every later sentence could
appear as a false modification. That makes the review surface less trustworthy
and forces the author to reason about AI changes the tool created artificially.

## Change

`DiffCalculator` now:

- segments original and AI text into sentences;
- aligns similar sentences with an LCS-style dynamic program;
- omits unchanged aligned sentences from pending diffs;
- emits zero-width insertions at the real insertion point;
- emits deletions at the original sentence range;
- preserves unrelated one-sentence replacements as a single modification.

`EditorAINotifier` now:

- rejects pending AI suggestions by updating diff status only, because pending AI
  output has not been written into the document yet;
- accepts all pending diffs from the end of the selection backward, so earlier
  insertions/deletions do not shift later offsets before they are applied.

## Author Experience

The author sees fewer false positives in the accept/reject layer. Inserted AI
sentences are shown as additions, removed author sentences are shown as
deletions, and unchanged later sentences stay out of the review queue.

This supports the product principle that AI suggestions are draft material until
the author explicitly accepts them.

## Verification

Automated checks cover:

- equal sentence-count modifications;
- pure insertions and deletions;
- inserted/deleted middle sentences without cascading modifications;
- unchanged text producing no pending diffs;
- unrelated single-sentence replacement staying one modification;
- existing editor AI streaming and review-signal behavior.
