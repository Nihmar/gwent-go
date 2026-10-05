AGENTS.md

Project Overview

This repository contains the development of a cross-platform Flutter application implementing Gwent, the card game from The Witcher 3: Wild Hunt.

The application will initially target:

- Android
- Linux
- Windows

Support for the following platforms is planned for the future:

- iOS
- macOS

The goal is to build a maintainable, extensible Flutter implementation of the game rather than a pixel-perfect recreation of an existing implementation.

---

Reference Repository

The original/reference implementation and its associated game assets are available in a directory that is intentionally excluded from Git through ".gitignore".

That repository must be treated primarily as a reference for game rules, mechanics, card behavior, game flow, and visual inspiration.

Important

The Flutter application must not be a one-to-one port or reproduction of the reference implementation.

Do not:

- blindly reproduce its architecture;
- copy its UI structure;
- copy its game-board implementation;
- reproduce its internal code structure;
- assume that every implementation detail of the reference repository must be preserved.

Instead:

1. Study the reference implementation to understand the rules and mechanics.
2. Extract the relevant game-domain knowledge.
3. Design the Flutter application using an architecture appropriate for Flutter and the target platforms.
4. Implement the game independently.

The reference implementation is therefore a source of truth for gameplay behavior, not a template for the application's technical architecture.

---

Design and UI Principles

Material Design

The application's general UI must use Material Design / Flutter Material components.

This includes:

- navigation;
- menus;
- dialogs;
- settings;
- buttons;
- controls;
- screens;
- overlays;
- general application layout.

Card Artwork

The artwork of individual cards is an exception.

Cards may use their original/reference artwork where appropriate.

The visual identity of the individual cards should preserve the recognizable Gwent aesthetic.

Game Board

The game board itself must not simply use the original/reference game-board image as a background.

Instead, construct the game board using Flutter widgets and Material-compatible UI primitives.

The board should be composed from elements such as:

- containers;
- rows and columns;
- cards;
- dividers;
- icons;
- text;
- Material surfaces;
- custom-painted elements where appropriate.

This is intentional: a widget-based game board provides substantially greater flexibility for:

- responsive layouts;
- different screen sizes;
- Android/Linux/Windows;
- accessibility;
- animations;
- future themes;
- alternative visual representations;
- possible future multiplayer functionality.

The board may reproduce the visual language and gameplay structure of Gwent without being a static copy of the original board image.

---

Gameplay and Rules

The implementation must faithfully reproduce the relevant gameplay rules and mechanics of Gwent as represented by the reference implementation.

The rules should be implemented independently from the UI.

Game logic must not depend directly on Flutter widgets or rendering code.

Prefer a clear separation between:

- game state;
- game rules;
- card definitions;
- effects;
- player state;
- turn/round management;
- AI;
- UI state;
- rendering.

This separation is particularly important because the game may eventually support multiplayer.

---

Difficulty Levels

The application must provide three difficulty levels:

1. Easy
2. Normal
3. Hard

These difficulty levels must be implemented regardless of how many difficulty levels are present in the reference implementation.

The reference implementation must not be treated as a restriction on the number or design of available difficulties.

Difficulty should primarily affect the behavior and decision-making of the AI rather than arbitrarily modifying game rules.

The architecture should allow additional difficulty levels to be introduced later without requiring a major rewrite of the game engine.

---

Architecture

The application should use a modular architecture appropriate for Flutter.

Game-domain logic should remain as platform-independent as reasonably possible.

Avoid coupling the core game engine to:

- Android APIs;
- Linux APIs;
- Windows APIs;
- Flutter widgets;
- platform-specific UI code.

The architecture should make it possible to reuse the same game engine across all supported platforms.

Prefer composition and clearly defined interfaces over large monolithic classes.

Potential architectural boundaries include:

- "core" / domain logic;
- game rules;
- cards;
- game state;
- AI;
- presentation;
- widgets;
- screens;
- localization;
- persistence;
- platform integrations.

The exact directory structure may evolve as the project develops. Do not create abstractions solely for the sake of abstraction.

---

Localization

The initial application language is English.

However, localization must be considered from the beginning.

Do not hard-code user-facing strings throughout the application.

Use Flutter's localization mechanisms and design the application so that additional languages can be introduced later without modifying game logic.

At minimum, the architecture should be compatible with future translations of:

- UI text;
- menus;
- settings;
- tutorials;
- game messages;
- card descriptions;
- ability descriptions;
- accessibility labels.

Game-domain identifiers should remain language-independent.

---

Future Multiplayer Support

Multiplayer is not currently required to be implemented.

However, the architecture must not unnecessarily prevent multiplayer from being introduced later.

In particular, the game engine should ideally be capable of separating:

- authoritative game state;
- player actions;
- game events;
- deterministic rule evaluation;
- presentation.

The project should consider the feasibility of local multiplayer in the future, including possible transports such as:

- LAN;
- Wi-Fi Direct;
- Bluetooth.

No specific transport or networking implementation should be introduced merely for future-proofing unless it is actually required.

Instead, document architectural decisions that could affect future multiplayer support.

When appropriate, create design notes or issues to investigate:

- local multiplayer architecture;
- peer-to-peer vs host/client models;
- synchronization;
- deterministic game state;
- connection discovery;
- LAN discovery;
- Wi-Fi Direct;
- Bluetooth;
- reconnection;
- player identity.

These are future considerations, not current implementation requirements.

---

Platform Support

The application should be designed to work correctly across:

- Android;
- Linux;
- Windows.

Avoid unnecessarily platform-specific implementations.

When platform-specific behavior is required, isolate it behind appropriate interfaces or platform-specific implementations.

The architecture should leave room for future:

- iOS;
- macOS.

Do not introduce platform-specific assumptions that would make future Apple-platform support unnecessarily difficult.

---

Source Code Size

As a general rule, individual source files should remain at approximately 500 lines or fewer.

This is a guideline rather than an absolute prohibition.

If a file needs to exceed approximately 500 lines:

1. Determine whether it can reasonably be split.
2. Prefer extracting logically independent components.
3. Avoid artificial splitting that makes the code harder to understand.
4. If exceeding the limit is genuinely justified, document the reason in the relevant code/design context.

Large files should not be allowed to grow simply because splitting them requires additional work.

---

Git Workflow

Development must follow a feature-branch workflow.

Do not develop all features directly on "main".

For each meaningful feature, change, refactor, or independent piece of work:

1. Create an appropriate branch.
2. Implement the work on that branch.
3. Make incremental commits.
4. Push the branch when appropriate.
5. Open a Pull Request against "main".
6. Review and validate the changes.
7. Merge the Pull Request into "main".

Branch names should clearly describe their purpose.

Examples:

feature/game-board
feature/card-effects
feature/ai-hard-difficulty
feature/localization
refactor/game-engine
fix/card-draw-bug

---

Commit Strategy

Prefer small, focused, incremental commits over large monolithic commits.

The goal is to make development history useful for:

- debugging;
- reviewing;
- reverting;
- bisecting;
- branching alternative implementations;
- recovering from problematic changes.

Avoid combining unrelated changes into the same commit.

A feature may therefore contain multiple commits representing logical steps in its implementation.

Commits must be written in English.

Use clear commit messages that describe the change.

---

Pull Requests

Every feature branch must be integrated into "main" through a Pull Request.

Pull Requests must be written in English.

A Pull Request should clearly explain:

- what was changed;
- why it was changed;
- relevant architectural decisions;
- important implementation details;
- testing performed;
- known limitations or follow-up work.

Avoid unnecessarily large Pull Requests when the work can naturally be divided into smaller independent changes.

---

Issues

Issues must be written in English.

Issues should be specific and actionable.

When appropriate, issues should contain:

- context;
- expected behavior;
- actual behavior;
- proposed approach;
- acceptance criteria;
- dependencies;
- known limitations.

Use issues to track future work rather than keeping substantial architectural decisions only in chat.

---

Documentation

All project documentation must be written in English.

This includes:

- README files;
- architecture documentation;
- design documents;
- technical notes;
- issue descriptions;
- Pull Requests;
- commit messages;
- development plans.

Documentation should be updated when architectural or behavioral changes make existing documentation inaccurate.

---

Agent Communication

The language used when communicating directly with the development agent is unrestricted.

The developer may communicate with the agent in:

- English;
- Italian.

The agent may respond in either language according to the language used by the developer.

This does not change the requirement that repository artifacts must be written in English.

Repository artifacts include code documentation where applicable, commits, issues, Pull Requests, and project documentation.

---

Testing

Game rules and game-domain logic should be tested independently from the Flutter UI whenever possible.

Prioritize automated tests for:

- card effects;
- game rules;
- round transitions;
- turn transitions;
- scoring;
- card drawing;
- deck behavior;
- player state;
- AI decisions;
- difficulty levels;
- edge cases.

UI tests should be added where they provide meaningful coverage of important user-facing behavior.

Do not rely exclusively on manual testing for core game mechanics.

---

AI

The AI must be implemented independently from the UI.

The three initial difficulty levels should provide meaningfully different decision-making behavior:

- Easy — simple and less optimal decision-making.
- Normal — competent gameplay with reasonable strategic decisions.
- Hard — substantially stronger strategic decision-making.

Avoid implementing difficulty simply by applying arbitrary bonuses or penalties unless the game rules explicitly require them.

The AI architecture should allow future improvements without requiring changes to the underlying game engine.

---

Assets and Intellectual Property

The reference repository and its assets are available locally through the directory excluded by ".gitignore".

Use those resources as permitted by the project's intended development context.

Do not unnecessarily duplicate large reference assets into the Flutter repository.

The application architecture should distinguish between:

- game logic;
- application code;
- reference assets;
- application assets.

Do not make the application's core functionality dependent on the presence of the ignored reference repository at runtime.

---

Development Principles

When making implementation decisions:

1. Prefer correctness of game rules over visual similarity to the reference implementation.
2. Prefer maintainable architecture over a quick one-to-one port.
3. Keep game logic independent from UI.
4. Keep the UI responsive across different screen sizes and platforms.
5. Use Material Design for the application and game-board UI.
6. Preserve the distinctive artwork of individual cards where appropriate.
7. Design localization into the application from the beginning.
8. Keep future multiplayer support in mind without prematurely implementing it.
9. Keep files reasonably small and cohesive.
10. Make incremental, reversible Git commits.
11. Use feature branches and Pull Requests.
12. Keep all repository-facing communication in English.
13. Treat the reference repository as a source of gameplay knowledge, not as the application's architectural blueprint.

---

Current Scope

The initial development scope is:

- Flutter application;
- Android support;
- Linux support;
- Windows support;
- English language;
- Gwent gameplay;
- Gwent cards and card mechanics;
- Material Design application UI;
- widget-based Material game board;
- Easy AI;
- Normal AI;
- Hard AI;
- automated testing of core game rules;
- architecture prepared for future localization;
- architecture considerate of future multiplayer.

The following are future scope and should not be implemented unless explicitly requested:

- iOS;
- macOS;
- online multiplayer;
- local multiplayer;
- LAN networking;
- Bluetooth multiplayer;
- Wi-Fi Direct multiplayer;
- additional languages.

Future functionality should be represented through appropriate architectural considerations and, where useful, documented issues rather than speculative implementation.
