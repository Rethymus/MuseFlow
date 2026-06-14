# MuseFlow

[![CI](https://github.com/Rethymus/MuseFlow/actions/workflows/ci.yml/badge.svg)](https://github.com/Rethymus/MuseFlow/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-0.1.4-blue?style=flat-square)](https://github.com/Rethymus/MuseFlow/releases)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux%20%7C%20Windows%20%7C%20Web-lightgrey?style=flat-square)](#tech-stack)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)](CONTRIBUTING.md)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-FF5C7C?style=flat-square)
![Hive CE](https://img.shields.io/badge/Hive_CE-EEB33B?style=flat-square)
![super_editor](https://img.shields.io/badge/super__editor-4B5563?style=flat-square)
![OpenAI](https://img.shields.io/badge/OpenAI-111111?style=flat-square&logo=openai&logoColor=white)
![Claude](https://img.shields.io/badge/Claude-D97757?style=flat-square)
![DeepSeek](https://img.shields.io/badge/DeepSeek-4D6BFE?style=flat-square)
![Ollama](https://img.shields.io/badge/Ollama-111827?style=flat-square)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white)

English | [中文](README.md)

> Imagination as the bones. AI as the wings.

MuseFlow is an AI-assisted writing workspace for long-form fiction authors. It is not a one-click novel generator, and it does not reduce writers to prompt operators. Its job is quieter and more useful: capture ideas, organize settings, protect foreshadowing, polish prose, and keep the author in control of the story.

## Why MuseFlow Exists

As fiction platforms become stricter about low-effort AI content, the real question is not whether writers should use AI. The question is who leads the story. MuseFlow is built around a clear answer: the author leads. AI listens to your material, helps structure what is already in your mind, and turns scattered fragments into workable drafts. Characters, world rules, promises, pacing, and judgment stay with the writer.

The Chinese name, 灵韵, means the spirit and rhythm of inspiration. MuseFlow combines Muse and Flow: a tool for entering a steadier creative state without surrendering authorship.

## Who It Is For

- **Writers with big stories and rough prose**: rich worlds and strong scenes, but difficulty with openings, transitions, and line-level expression.
- **Plot-first creators**: authors who want help managing characters, settings, clues, and structure instead of generic AI prose.
- **Serial fiction authors**: writers who need to remember every promise, hidden thread, and character boundary across dozens or hundreds of chapters.

## A Real User Journey

The screenshots below come from a reproducible README UI evidence flow. We step into the role of a xianxia serial author and move through idea capture, manuscript management, chapter writing, knowledge management, structure tracking, analytics, and model configuration. The screenshots use offline demo data and do not display real API keys.

### 1. Manage Multiple Works

The manuscript library supports parallel projects, progress tracking, genres, target word counts, and recent activity.

![Manuscript library](docs/readme/screenshots/01-manuscript-library.png)

### 2. Capture Ideas Before They Disappear

The capture inbox stores scenes, lines, conflicts, and foreshadowing seeds. Tags make raw ideas searchable before they become chapters.

![Capture inbox](docs/readme/screenshots/02-capture-inbox.png)

### 3. Organize Fragments and Write Chapters

AI organization turns selected idea fragments into structured draft material that the author can accept, revise, or retry.

![AI organization](docs/readme/screenshots/03-ai-organization.png)

The chapter editor provides a chapter sidebar, rich text editing, a toolbar, auto-save, and word counts. AI helps revise and organize; it does not take the pen away.

![Chapter editor](docs/readme/screenshots/04-chapter-editor.png)

The editor AI toolbar supports tone rewrite, paragraph polish, and free-form instructions, with the author confirming the result.

![Editor AI toolbar](docs/readme/screenshots/05-editor-ai-toolbar.png)

### 4. Give AI a Memory

Character cards preserve personality, appearance, aliases, and backstory, so AI-assisted writing knows who a character is and how they should behave.

![Character cards](docs/readme/screenshots/06-knowledge-characters.png)

World settings store rules, factions, geography, and technology or magic levels. For high-setting genres, this is the foundation for consistency.

![World settings](docs/readme/screenshots/07-knowledge-world.png)

### 5. Start Faster With Templates and Rules

The template gallery turns genre patterns into reusable world-building scaffolds. It helps authors move from a concept to a writable setting faster.

![Template gallery](docs/readme/screenshots/08-template-gallery.png)

Skill documents define active writing rules: power hierarchy, faction relationships, banned tropes, terminology, and anti-AI-scent style constraints.

![Skill rules](docs/readme/screenshots/09-skill-rules.png)

### 6. Protect Long-Form Structure

Foreshadowing management tracks where a clue was planted, whether it is developing, and when it should resolve.

![Foreshadowing](docs/readme/screenshots/10-foreshadowing.png)

The plot timeline organizes key beats by chapter, involved characters, writing state, and linked foreshadowing.

![Plot timeline](docs/readme/screenshots/11-plot-timeline.png)

The story arc graph helps authors inspect setup, turns, climaxes, and resolutions visually.

![Story arc](docs/readme/screenshots/12-story-arc.png)

The logic guardian highlights consistency risks, forgotten threads, and setting drift.

![Logic guardian](docs/readme/screenshots/13-logic-guardian.png)

Cleanup and export prepare the manuscript for delivery with format checks and bundled output.

![Cleanup and export](docs/readme/screenshots/14-export-cleanup.png)

### 7. Measure the Writing Process

Writing stats show daily output, speed trends, AI-assist ratio, and session count. MuseFlow does not reward empty volume; it helps writers understand their rhythm.

![Writing stats](docs/readme/screenshots/15-writing-stats.png)

Token auditing records input, output, model, and operation type for every AI call. Long-form projects need transparent cost control.

![Token audit](docs/readme/screenshots/16-token-audit.png)

The reports hub brings together cost, pain points, anti-AI-scent evaluation, and knowledge-base consistency checks.

![Reports hub](docs/readme/screenshots/17-reports-hub.png)

Report details project short-form, long-form, and serialized usage costs.

![Report details](docs/readme/screenshots/18-report-details.png)

### 8. Keep Models and Style Under Author Control

Settings centralize models, local data, and writing statistics controls.

![Settings](docs/readme/screenshots/19-settings.png)

AI provider management supports multiple providers and OpenAI-compatible endpoints, including OpenAI, Claude, DeepSeek, Ollama, and similar services.

![AI providers](docs/readme/screenshots/20-ai-providers.png)

AI phrase filtering lets writers maintain their own banned phrase list and suppress mechanical summary language.

![AI phrase filtering](docs/readme/screenshots/21-banned-phrases.png)

## Core Capabilities

- **Manuscripts and chapters**: manuscript library, chapter sidebar, chapter-level auto-save, reordering, and chapter-aware export.
- **Capture and AI organization**: fragments, tags, structured prompt pipeline, local polishing, and rewriting.
- **Knowledge and rule control**: character cards, world settings, templates, Skill documents, entity matching, and context injection.
- **Long-form structure**: foreshadowing lifecycle, plot nodes, story arc graph, logic guardian, cleanup, and export.
- **Analytics and cost transparency**: writing stats, token audit, cost report, pain point report, anti-AI-scent evaluation, and consistency analysis.
- **Lightweight cross-platform design**: Flutter-based and local-first. Android, Linux, and Windows are release targets; Web is a testing/UAT target for fast README journey validation.

## Tech Stack

- Flutter / Dart
- Riverpod
- Hive CE local storage
- super_editor rich text editing
- go_router navigation
- fl_chart / graphview visualization
- OpenAI / Claude / DeepSeek / Ollama model adapters
- Android / Linux local build validation, Windows as a GitHub Actions build target, and Web as a testing build target

## Run and Verify

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

This README uses 21 reproducible UI feature screenshots stored in `docs/readme/screenshots/`. They are generated by `scripts/generate_readme_screenshots.mjs` with offline demo data and no real API keys.

## v1.3 User Journey Site

- [Open the v1.3 static showcase](docs/v1.3-user-journey/index.html)
- [Read the 100-chapter xianxia sample](docs/v1.3-user-journey/xianxia-100-chapter-sample.html)
- [View the v1.3 user journey validation report](docs/v1.3-user-journey/validation-report.html)
- [View chapter JSON data](docs/v1.3-user-journey/data/chapters.json)

GitHub displays HTML files as source. For the full visual experience, clone the repository and open `docs/v1.3-user-journey/index.html` in a browser.

## When Authors Meet AI

Eliminating the AI scent is the soul of MuseFlow, not an add-on. That forces a real question: as AI writing capabilities keep improving, how do mature creators actually choose? The answers diverge.

The Chinese novelist **Yu Hua** still puts it sharply: as he understands GPT today, it "can probably write a mediocre novel, but not one full of personality — because the human brain always makes mistakes, and that is precisely what makes it most precious."

**Hao Jingfang** (author of *Folding Beijing*, and the next Chinese writer after Liu Cixin's *The Three-Body Problem* to win the Hugo Award) gives a different answer. She admits that in her new novel this year, AI-written content already accounts for half. "My editor kept praising how much better I wrote this year, and readers couldn't tell which parts were AI." For a long time, writers caught using AI tended to deny it; openly admitting it — and taking pride in it — remains rare.

**Olga Tokarczuk** (2018 Nobel laureate in literature) goes further. She purchased a premium tier of an AI model and peppers it with questions while writing: What kind of music would the protagonist listen to? Darling, how do we make this story better? She knows AI hallucinates on "hard data" such as economics, yet believes the technology has "incredible advantages" in literary creation — which left many readers rattled once they learned.

**Anthony Horowitz** (author of the *Magpie Murders* trilogy) reads more like a cautious pragmatist. He says writing with AI feels "like cheating," and he has seen its clumsiness firsthand: ask it the shape of a potato and it answers *ellipsoid*; let it turn that into prose and you get a sentence like "the potato on the plate was ellipsoid in shape."

From skepticism to embrace, from feeling betrayed to feeling like a cheat, authors' attitudes are splitting. MuseFlow does not take sides for the writer; it holds one line — let AI understand your material, organize your settings, and polish your prose, while the story stays the author's. That is exactly what Yu Hua calls "the most precious thing about the human brain."

> These author quotes are drawn from an article by "山下热狗" on XIAOHEIHE, "当雨果奖&诺奖得主开始用AI写作，作为普通人你会坚守还是倒戈？" ([original link](https://www.xiaoheihe.cn/app/bbs/link/2db772047c7c?h_camp=link&h_session_id=laQc8HhHmBTV48ud&h_src=YXBwX3NoYXJl)).

## Vision

MuseFlow aims to become a durable AI workbench for fiction authors: no fast-food literature, no replacement of human taste, and no surrender of the story. It keeps the writer's temperature in every captured idea, structural review, and polished paragraph.
