# SalimERP Mobile — Claude Code Context

Flutter staff client for the SalimERP clinic system. Arabic-first, RTL. Custom design
system (`lib/design_system/`, `DSTheme` on `WidgetsApp` — not Material).

- **API base URL:** `lib/services/api_config.dart` → `https://salimerp.on-forge.com`.
- **Backend source:** `../salimerp` (Laravel).

## Design System
Always read DESIGN.md before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.

Current direction (v2): existing cyan/slate palette, Thmanyah Sans font, rounded
card-based layout with a floating pill nav and gradient featured card, optional dark theme.
