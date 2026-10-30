---
name: Baka
description: A private, local-only journal on aged paper.
colors:
  aged-paper: "#F5F0E8"
  paper-leaf: "#EDE8DC"
  paper-top-sheet: "#F8F4EC"
  terracotta: "#B85A28"
  terracotta-wash: "#F0D5C0"
  terracotta-deep: "#8A4419"
  terracotta-text: "#9C4A1F"
  sage: "#8A9E7E"
  sage-wash: "#DDE4D3"
  sage-deep: "#4A5A3C"
  walnut-ink: "#2C1A0E"
  umber-ink: "#3D2314"
  faded-ink: "#C03D2314"
  pencil-line: "#C8BAA6"
  error-red: "#C0392B"
  midnight-ink: "#1A1208"
  midnight-leaf: "#251A0F"
  midnight-top-sheet: "#2E2114"
  ember: "#D4784A"
  ember-wash: "#3D2010"
  ember-glow: "#E7B48C"
  candle-paper: "#E8DDD0"
  candle-ink: "#D4C4B0"
  midnight-line: "#3A2A1A"
typography:
  day-title:
    fontFamily: "Caveat"
    fontSize: "36px"
    fontWeight: 700
    lineHeight: 1.1
  screen-title:
    fontFamily: "Caveat"
    fontSize: "30px"
    fontWeight: 700
    lineHeight: 1.15
  hand-title:
    fontFamily: "Caveat"
    fontSize: "22px"
    lineHeight: 1.2
  section-label:
    fontFamily: "Caveat"
    fontSize: "17px"
    lineHeight: 1.2
  caption:
    fontFamily: "Caveat"
    fontSize: "15px"
    lineHeight: 1.3
  numeral-xl:
    fontFamily: "Playfair Display"
    fontSize: "64px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "-1px"
    fontFeature: "lnum, tnum"
  heading:
    fontFamily: "Playfair Display"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.3
  section-heading:
    fontFamily: "Playfair Display"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.3
  reading:
    fontFamily: "Lora"
    fontSize: "17px"
    lineHeight: 1.75
  row-title:
    fontFamily: "Lora"
    fontSize: "16px"
  body-preview:
    fontFamily: "Lora"
    fontSize: "15px"
    lineHeight: 1.55
  label:
    fontFamily: "Lora"
    fontSize: "14px"
  meta:
    fontFamily: "Lora"
    fontSize: "13px"
  counter:
    fontFamily: "Courier Prime"
    fontSize: "12px"
    letterSpacing: "0.5px"
rounded:
  tick: "2px"
  snack: "10px"
  field: "12px"
  card: "14px"
  sheet: "20px"
  pill: "999px"
spacing:
  hair: "4px"
  tight: "6px"
  group: "12px"
  gutter: "20px"
  section: "30px"
components:
  button-write:
    backgroundColor: "{colors.terracotta}"
    textColor: "{colors.paper-top-sheet}"
    typography: "{typography.row-title}"
    rounded: "{rounded.pill}"
    height: "56px"
    padding: "0 22px 0 18px"
  button-save:
    backgroundColor: "{colors.terracotta}"
    textColor: "{colors.paper-top-sheet}"
    rounded: "{rounded.pill}"
    padding: "8px 20px"
  button-save-disabled:
    backgroundColor: "{colors.terracotta-wash}"
    textColor: "{colors.terracotta-deep}"
    rounded: "{rounded.pill}"
  card-entry:
    backgroundColor: "{colors.paper-leaf}"
    textColor: "{colors.umber-ink}"
    rounded: "{rounded.card}"
    padding: "14px 18px 16px"
  chip-tag:
    textColor: "{colors.walnut-ink}"
    typography: "{typography.caption}"
    rounded: "{rounded.pill}"
  chip-status:
    backgroundColor: "{colors.terracotta-wash}"
    textColor: "{colors.terracotta-deep}"
    rounded: "{rounded.pill}"
    padding: "2px 8px"
  input-field:
    backgroundColor: "{colors.paper-leaf}"
    textColor: "{colors.walnut-ink}"
    rounded: "{rounded.field}"
  nav-bar:
    backgroundColor: "{colors.paper-top-sheet}"
    textColor: "{colors.faded-ink}"
    height: "64px"
  nav-indicator:
    backgroundColor: "{colors.terracotta-wash}"
    textColor: "{colors.terracotta}"
    rounded: "{rounded.pill}"
---

# Design System: Baka

## Overview

**Creative North Star: "The Kept Notebook"**

Baka is a private paper journal that quietly remembers. Every screen is a sheet of aged paper written on in terracotta ink; the interface is stationery, not software chrome. The product never shouts: it notices you showing up (a filled day, a streak that rolls forward, a page from a year ago) and says so in its own hand.

Density is calm and single-column. One 20px gutter holds every screen; sections breathe at 30px. Controls feel like tactile stationery: pills that read as tabs and stamps, chips like stickers, rows like ruled index lines. Two voices carry the system: a handwritten face for human moments and a bookish serif for everything you read or operate. A display serif sets headings and numerals.

Motion is quiet and earned. There is one authored moment, saving today's page, and everything else is short, exponential ease-out feedback that disappears under the system reduce-motion setting.

**Key Characteristics:**
- Aged-paper light theme ("Aged Paper") and a warm candlelit dark theme ("Midnight Ink"), each a full palette, not an inversion.
- One accent: terracotta ink. Sage is a secondary note for status only.
- Handwriting for human moments only; Lora for every control and reading surface.
- Flat paper surfaces; the Write button is the single lifted object.
- Ruled lines only where you write or read a page (editor and entry detail).

## Colors

Warm paper neutrals with a single terracotta ink; dark mode is the same desk by candlelight.

### Primary
- **Terracotta Ink** (light `terracotta`, dark `ember`): the only accent. Write and Save buttons, today's disc, streak, active tab, links, hashtags in text, heatmap's darkest step.
- **Terracotta Wash** (light `terracotta-wash`, dark `ember-wash`): accent containers. Nav indicator, today's disc fill, status and draft chips, disabled Save.
- **Fired Clay** (light `terracotta-deep`, dark `ember-glow`): text on terracotta-wash containers (chip labels, mood words).
- **Terracotta Script** (light `terracotta-text`, dark `ember`): terracotta for small text: links, hashtags, streak and milestone lines, "See all". Fills, icons and type ≥24px use Terracotta Ink.

### Secondary
- **Sage** (`sage`, with `sage-wash` / `sage-deep`): status-only ("Ready" capture chips) and the fallback tag colour. Never a second call to action.

### Neutral
- **Aged Paper** (`aged-paper`) / **Midnight Ink** (`midnight-ink`): screen background.
- **Paper Leaf** (`paper-leaf`) / **Midnight Leaf** (`midnight-leaf`): cards, inputs, keypad keys; one sheet laid on the page.
- **Top Sheet** (`paper-top-sheet`) / **Midnight Top Sheet** (`midnight-top-sheet`): nav bar, dialogs, sheets.
- **Walnut Ink** (`walnut-ink`) / **Candle Paper** (`candle-paper`): headings and primary text on the background.
- **Umber Ink** (`umber-ink`) / **Candle Ink** (`candle-ink`): text on cards.
- **Faded Ink** (`faded-ink`, umber at ~75%; dark: candle ink at ~66%): secondary text, dates in meta rows, inactive tabs. Holds ≥5.5:1 on paper and ≥4.8:1 on every dark surface.
- **Pencil Line** (`pencil-line`) / **Midnight Line** (`midnight-line`): outlines and dividers; at ~55% for soft dividers and ~70% (light) / ~18% (dark) for ruled page lines.

### Named Rules
**The One Ink Rule.** Terracotta is the only accent. If a second colour wants attention, it is wrong; sage marks status, never action.

**The Small Ink Rule.** Terracotta text under 24px uses Terracotta Script (≥5:1 on paper); white on Terracotta Ink is 4.6:1, and on dark the label on Ember is ink, not white.

**The Heatmap Ramp Rule.** Intensity is terracotta at fixed alphas (light 7 / 22 / 45 / 72 / 100%, dark 9 / 25 / 50 / 78 / 100%), never a new hue.

## Typography

**Display Font:** Playfair Display (headings, numerals)
**Body Font:** Lora (reading text and every control)
**Accent Font:** Caveat (handwriting for human moments)
**Counter Font:** Courier Prime (word counts, version)

**Character:** a literary serif pair with a hand that writes in the margins. The handwriting is warmth; the serif is trust.

Classic (above) is the default of five user-selectable presets (Classic, Plex, Garamond, Typewriter, Fraunces); the user can also override the writing font. Always reach type through the named roles, never by family.

### Hierarchy
- **Day title** (Caveat 700, 36px, 1.1): the weekday at the top of the editor and detail page.
- **Screen title** (Caveat 700, 30px, 1.15): greeting, "Your streak", "Settings".
- **Hand title / Section label / Caption** (Caveat 22 / 17 / 15px): card dates, list section names ("Today", "Last week"), mood words, tags, milestone and On-this-day lines.
- **Numeral XL** (Playfair 600, 64px, 1, -1px, lining + tabular figures): the Stats streak count.
- **Heading / Section heading** (Playfair 600, 20 / 18px, 1.3): Stats sections, dialog titles, settings groups.
- **Reading** (Lora 17px, 1.75): entry body in detail and editor; the measure sits inside the 20px gutter.
- **Row title / Label / Meta** (Lora 16 / 14 / 13px): settings rows, buttons, chips-as-controls, supporting lines.
- **Counter** (Courier Prime 12px, +0.5px): "212 words".

### Named Rules
**The Human Moments Rule.** Caveat only for titles, day names, dates, section names, captions, tags and mood words. Every control label, row, and paragraph is Lora.

**The Signature Hand Rule.** The two actions that start writing, Write and Edit, keep the handwritten face (Caveat 700, 18px). They are the only controls that do; Save and every other button stay Lora.

**The Lining Numerals Rule.** Any numeral set large in Playfair uses lining figures; old-style digits drop below the baseline and open a hole above.

## Layout

Single column at phone width with a 20px side gutter on every screen. Lists group into sections with 22px above a section label and 6px below it; cards stack with 12px between them (6px padding each side). Stats sections are separated by 30px with 14px between a heading and its content. The bottom nav is 64px; list content reserves 96px at the bottom so the Write button never covers the last card.

Text-heavy rows must survive 1.3× system text scale: fixed-height label rows scale with the text scaler, greeting parts shrink and ellipsize rather than overflow into actions.

## Elevation & Depth

Flat paper. Depth comes from stacking paper tones (background → leaf → top sheet) and pencil-line outlines, not shadows. Cards, dialogs, sheets and the nav bar carry no shadow and no surface tint.

### Shadow Vocabulary
- **Lifted object** (offset 0/3, blur 10, walnut ink at 20%): the Write button only.

### Named Rules
**The Single Lift Rule.** Exactly one object on a screen may cast a shadow, and it is the primary action. Everything else is paper on paper.

## Shapes

Gently rounded stationery. Cards round at 14px, inputs at 12px, dialogs and sheets at 20px, snackbars at 10px, heatmap cells at 2px. Anything you tap that is a single action or a tag is a full pill. Borders are 1px pencil lines; focus raises an input's border to 1.5px terracotta. No coloured edge strips on cards, ever.

## Components

### Buttons
Tactile stationery: pills that read like tabs and stamps.
- **Write** (extended FAB): terracotta pill, 56px tall, quill icon + "Write" in Caveat 700 18px (Signature Hand); the single lifted object. Shown on the Pages tab only.
- **Save:** terracotta pill in the editor app bar, Lora 15px semibold label, no icon; disabled state is terracotta-wash with fired-clay text.
- **Edit** (entry detail app bar): terracotta-wash pill, edit icon + "Edit" in Caveat 700 18px, fired-clay text (Signature Hand).
- **Secondary:** outlined pill in terracotta ("Use PIN instead"); never muted text, which reads as disabled.
- **Text buttons:** terracotta Lora label, 48px minimum target.

### Chips
- **Tag chip:** tag colour at 12% fill, 30% border, Caveat label, pill.
- **Status / draft chip:** terracotta-wash pill with a 5px terracotta dot and fired-clay Caveat label.
- **Mood:** glyph plus word together, never the glyph alone.

### Cards / Containers
- **Entry card:** paper-leaf, 14px corners, 14/18/16px padding, no border, no shadow, no edge strip. Head row: Caveat date left, mood glyph + word grouped right; up to three lines of Lora preview with terracotta hashtags; tag chips beneath.
- **Outlined card:** transparent with a pencil-line border for secondary notes (drafts, On this day).

### Inputs / Fields
- **Style:** paper-leaf fill, 12px corners, 1px pencil-line border, faded-ink hint.
- **Focus:** border becomes 1.5px terracotta.

### Navigation
- Three tabs (Pages, Stats, Settings) on the top sheet, 64px, labels always shown. Active tab: terracotta icon on a terracotta-wash pill indicator. Tabs cross-fade with a 4px rise (200ms) rather than cutting.

### This Week row (signature)
Seven 40px discs, Monday first. Written days fill with paper-leaf; today wears terracotta-wash with a 1.5px terracotta ring; a day's mood glyph sits inside. The current streak (flame + "N-day streak") sits on the right and opens Stats. Saving today's page is the system's one authored moment: the disc fills, the glyph settles from 0.6 scale, the streak rolls up, and on milestone days a handwritten line appears beneath.

### Ruled page
Editor and entry detail only: pencil-line rules behind the body text area, never behind stamps, mood or tags, never on cards.

## Do's and Don'ts

### Do:
- **Do** reach colours through tokens (`context.tokens`) and type through named roles (`AppText.*`).
- **Do** keep the 20px gutter on every screen.
- **Do** pair every mood glyph with its word.
- **Do** route every animation through `Motion` so reduce-motion turns it off; use exponential ease-out.
- **Do** keep delight proportional: celebrate milestones, let ordinary saves simply feel certain (a light haptic, no banner).

### Don't:
- **Don't** use Caveat for control labels, settings rows or paragraphs (Write and Edit are the only exceptions).
- **Don't** add a coloured left or right strip to cards.
- **Don't** put ruled lines on cards or anywhere outside the page body.
- **Don't** show the Write button on Stats or Settings; it covered real controls.
- **Don't** cast a shadow on anything but the Write button.
- **Don't** use bottom sheets for the mood selector; it expands inline.
