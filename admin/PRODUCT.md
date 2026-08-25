# Product

## Register

product

## Users

University lecturers, department admins, and registrar staff managing OROmark — a LAN-based classroom attendance system. They're not casual users: this is a work tool opened between classes or at a desk, often quickly, to check attendance stats, add/edit a student or lecturer, or set up a course roster. Low patience for friction, no tolerance for unclear data (attendance numbers are the whole point of the product).

## Product Purpose

The admin dashboard is the back office for OROmark: manage students, lecturers, and courses; enroll students into courses; and see attendance analytics rolled up from the mobile app's live sessions. It's the source of truth staff use to keep the roster correct, so the mobile app's offline UDP-based attendance flow has accurate data to work against. Success = staff can find and fix roster/course data fast, and trust the attendance numbers they see.

## Brand Personality

Precise, calm, quietly confident — an institutional tool, not a consumer SaaS product. It should feel like it belongs to a university system: trustworthy and legible over flashy. The existing brand (deep teal primary, amber secondary, a muted tertiary green, and a clear blue accent) already leans serious-but-warm rather than corporate-cold; the redesign should lean into that rather than genericize it into another gray SaaS dashboard.

## Anti-references

Generic AI-generated SaaS admin templates: undifferentiated gray-on-white dashboards, tiny 11-13px body/nav text presented as if it were normal reading size, cards-for-everything, no real type hierarchy beyond bold vs. not-bold. The current dashboard has drifted here — nav labels sit at 13.5px, secondary sidebar text at 11px, no deliberate type scale — and reads as "default Tailwind admin," not as OROmark's own product.

## Design Principles

1. **Type is the primary lever, not decoration.** This is a data-dense internal tool: the type scale needs a real hierarchy (page titles, section headings, table/list body, meta text) at readable sizes, not a flat field of 11-14px text.
2. **The sidebar is the app's spine, not a thin utility rail.** It should feel like a considered piece of product chrome — clear active state, comfortable label size, real breathing room — not a cramped icon list.
3. **Brand colors are load-bearing, not accent-only.** Teal primary, amber secondary, and the accent blue should show up with intention (active states, key stats, chart series) rather than being confined to tiny icon chips.
4. **Legible over clever.** Staff are scanning for specific data (a student, a course, an attendance number) under time pressure — clarity and contrast beat visual flourish everywhere in this register.

## Accessibility & Inclusion

Standard WCAG AA: body text ≥4.5:1 contrast, large text/UI components ≥3:1, visible focus states on every interactive element, no color-only status signaling (attendance present/late/absent already pairs color with text, keep that pattern everywhere new).
