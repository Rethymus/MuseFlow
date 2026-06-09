# Preflight Chapter Memory Warning Design

Date: 2026-06-10

## Context

README positions MuseFlow as author-led AI assistance for long-form fiction.
Recent AI writing research emphasizes the same pressure point: memory and
planning help only when the author can see and control what the tool is using.

MuseFlow already has report-level chapter memory freshness checks, but editor
AI prompts can still receive adjacent chapter summaries without any freshness
context. If a stored summary is stale after rewrites, splits, merges, or
reorders, the model may preserve the wrong continuity and push the author away
from the actual manuscript.

## Change

`ChapterMemoryWarningBuilder` now compares a stored adjacent summary with the
actual adjacent chapter text and returns a concise warning when overlap is low.

`PromptContext` carries optional freshness warnings for previous and next
chapter summaries.

`ChapterContextMiddleware` now appends those warnings beside the adjacent
summary and explicitly tells the model:

- the summary is advisory review context;
- current author text, selected text, and knowledge base facts take priority;
- stale summaries must not override established facts, relationships, or
  foreshadowing.

## Author Experience

This keeps chapter memory useful without making it invisible authority. Later
UI or report code can generate these warnings from local freshness signals, and
the prompt layer will already preserve the author's control before AI output is
produced.

## Non-Goals

- No automatic chapter summary regeneration.
- No new AI calls.
- No persistence schema changes.
- No claim that local heuristics can prove a summary is wrong.

## Verification

Automated tests cover:

- deterministic warning generation for stale previous/next summaries;
- healthy, thin, and empty summary boundaries;
- warning fields on `PromptContext`;
- warning preservation through message helper methods;
- previous and next chapter warnings in `ChapterContextMiddleware`;
- blank warnings not polluting prompts.
