# Design System — SalimERP (Mobile)

> Created by `/design-consultation` on 2026-07-14.
> Direction: keep the existing cyan/slate palette, upgrade the layout to a modern
> rounded/card-based system, adopt Thmanyah Sans, add an optional dark theme.
> Read this before ANY visual or UI change. Do not deviate without user approval.

## Product Context
- **What this is:** SalimERP mobile app — the staff-facing client for a healthcare clinic ERP.
- **Who it's for:** clinic staff on shift (workers, specialists, managers), phone in hand, many quick tasks per shift.
- **Space/industry:** healthcare / clinic operations. Peers: clinical staff apps, medical dashboards.
- **Project type:** mobile app (Flutter, custom `DSTheme`, not Material). Arabic-first, RTL.
- **Memorable thing:** "modern & polished" — feels like a premium 2026 product, not a generic internal tool.

## Aesthetic Direction
- **Direction:** refined-clinical, card-based, rounded and airy.
- **Decoration level:** intentional. Retire the decorative `soft_blobs` background; depth comes
  from surface elevation (soft shadows) and one gradient-filled featured card, not blobs.
- **Mood:** clean, trustworthy, quick to scan. Reference: MediCare medical app concept
  (rounded cards, floating pill nav, filled featured card) — adapted to staff screens with
  SalimERP's own cyan brand.
- **Reference:** https://dribbble.com/shots/25707198-Medical-App-UI-concept-MediCare (layout only, not its green)

## Typography
- **Family:** Thmanyah Sans (Arabic + Latin). Bundled at `assets/fonts/thmanyahsans/`.
- **Weights:** Light 300, Regular 400, Medium 500, Bold 700, Black 900.
- **Fallback:** Cairo → NotoSansArabic → NotoSans.
- **Data/tables:** use tabular figures (`FontFeature.tabularFigures()`) for counts, money, times.
- **Scale (px):** display 30/700 · headline 24/600 · title 18/600 · body 14/400 · label 14/700 · caption 12/400.
- **Line-height:** display 32, headline 32, title 26, body 22, caption 18.

## Color
Existing tokens from `lib/design_system/tokens/colors.dart` — DO NOT change the light values.

### Light (default)
- **Primary:** `#2BA6CB` — brand, primary actions, active nav, featured card fill.
- **Primary deep:** `#1E7F9C` — pressed state, gradient end for featured card.
- **Secondary:** `#0EA5E9` — info/links.
- **Accent (soft):** `#E3F6FB` · **Accent muted:** `#D9E2EC` · **Highlight:** `#E0F2FE`.
- **Background:** `#F8FAFC` · **Surface:** `#FFFFFF` · **Surface alt:** `#F1F5F9`.
- **Text:** primary `#0F172A`, secondary `#475569`, muted `#64748B`. **Border:** `#E2E8F0`.
- **Semantic:** success `#16A34A`, warning `#F59E0B`, danger `#E11D48`.

### Dark (optional, new — not enabled by default)
Redesigned surfaces (not inverted); same cyan brand, brightened for contrast.
- primary `#38BDF8` · primary deep `#0EA5E9` · background `#0B1220` · surface `#111C2E`
- surface alt `#1B2A41` · text `#E7EEF7` · text-2 `#93A4BC` · border `#243449`
- success `#22C55E` · warning `#F59E0B` · danger `#FB7185`

## Spacing
- **Base unit:** 4px. **Density:** comfortable (tables compact).
- **Scale:** 2xs(2) xs(4) sm(8) md(16) lg(24) xl(32) 2xl(48) 3xl(64).
- Screen padding 18px. Card padding 14px. Card gap 10px.

## Layout
- **Approach:** grid-disciplined, RTL-first.
- **Navigation:** floating pill bottom nav (not a flat bar). Active item fills with primary and
  expands to show its label; inactive items are icon-only. Center FAB may sit on the nav for
  the primary create action.
- **Featured card:** one gradient-filled hero card (primary → primary-deep) at the top of the
  home screen for the day's key metric + date strip.
- **Quick actions:** 4-up grid of rounded tiles under the hero (Appointments, Inventory, Sessions, Leave).
- **Lists:** white rounded cards with soft shadow, time chip + title + subtitle + chevron.
- **Search:** pill-shaped search field with soft shadow.
- **Border radius:** sm 12px, md 16px, cards 20px, hero 24px, pills/buttons 9999px.
- **Elevation:** shadow-sm `0 4px 14px rgba(15,23,42,.06)`, shadow `0 10px 30px rgba(15,23,42,.10)`.

## Motion
- **Approach:** intentional (guides, not decorates).
- **Easing:** enter ease-out, exit ease-in, move ease-in-out.
- **Duration:** micro 80ms, short 200ms, medium 320ms, long 500ms.
- Page transitions keep the existing fade; add list stagger on load, spring on FAB/press,
  shared-element for card → detail.

## Implementation notes (Flutter)
- Register Thmanyah Sans in `pubspec.yaml` under `fonts:` (all 5 weights, done).
- Set the base family to `Thmanyah Sans` in `lib/design_system/tokens/typography.dart`
  (currently `Cairo`); keep the Arabic fallbacks.
- Add a dark `DSColors.dark()` factory and a `DSTheme.dark(...)` alongside `DSTheme.light(...)`.
- New/updated components: `pill_nav`, gradient `featured_card`, `quick_action_grid`,
  larger radius on `ds_card`; remove `soft_blobs` from screen backgrounds.

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-07-14 | Keep existing cyan/slate palette | User: use the old colors, improve layout only |
| 2026-07-14 | Adopt Thmanyah Sans as base font | User-provided bundled font; modern premium Arabic face |
| 2026-07-14 | MediCare-style layout (rounded cards, pill nav, hero, quick grid) | User reference; upgrades polish without changing brand color |
| 2026-07-14 | Retire decorative `soft_blobs`; depth via elevation | Blobs read as AI-slop; elevation reads as premium |
| 2026-07-14 | Add optional dark theme (same cyan brand) | Clinical dark-mode demand; not default |
