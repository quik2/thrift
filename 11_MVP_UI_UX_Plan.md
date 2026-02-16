# ThriftFlip MVP UI/UX Plan (Canonical)
### Screen-by-screen implementation plan for the launch product

---

## Document Role

This is the build-facing UI/UX specification for MVP.

Authority order:
1. `12_MVP_Canonical_Plan.md`
2. `13_MVP_Build_Checklist.md`
3. `14_MVP_Risk_and_Decisions.md`
4. this UI plan

---

## MVP Design Principles

1. **Camera-first:** app opens directly to scan.
2. **Trust-first:** confidence and uncertainty are explicit.
3. **Action-first:** every result offers clear next actions.
4. **Low-friction:** minimal steps from capture to decision.

---

## MVP Navigation

Bottom tab structure:
1. Scan (default)
2. Collection
3. Sell (eBay-only in MVP scope)

Profile/settings can remain a top-corner sheet.

---

## Screen 1: Onboarding

Goals:
1. explain what to scan (tag + item)
2. set trust expectations
3. collect camera permission

Required copy behavior:
1. do not claim "scan anything"
2. do claim confidence-scored estimates
3. privacy copy must match actual save/share behavior

---

## Screen 2: Scan (Home)

Required elements:
1. full-screen camera feed
2. tag guidance overlay
3. primary scan button
4. gallery import option
5. flash toggle

Interaction requirements:
1. guidance emphasizes tag visibility
2. OCR lock indication is visible
3. failure state offers actionable retry tips

---

## Screen 3: Scanning State

Required behavior:
1. clear in-progress state
2. brief and responsive visual feedback
3. no fake precision claims during processing

If processing delays occur:
1. keep user informed
2. provide cancel/retry behavior

---

## Screen 4: Result Card (Primary Value Moment)

Must display:
1. candidate identification output
2. confidence score
3. estimated range (`low`, `median`, `high`)
4. comp depth (`n` sold/current comps)
5. supporting comps preview

Actions:
1. Save
2. Rescan
3. Mark incorrect
4. Open item detail

### Low-Confidence Variant (Required)

When confidence is low:
1. use cautious wording ("might be")
2. widen estimate range
3. suggest tag-focused rescan
4. suppress strong recommendation language

---

## Screen 5: Collection

Purpose:
1. persist user value from scans
2. enable revisiting and correction

Required data in list:
1. item photo
2. label/output
3. estimate range
4. confidence badge
5. saved timestamp

Filters (MVP-friendly):
1. All
2. High confidence
3. Needs review

---

## Screen 6: Item Detail

Required sections:
1. scan result summary
2. range breakdown
3. confidence explanation inputs
4. comp list details
5. correction controls

Optional (if implemented):
1. eBay draft/publish entry point

---

## Screen 7: Sell Tab (MVP Scope)

MVP interpretation:
1. eBay-focused selling workflow only
2. no Poshmark/Mercari/Depop controls in MVP UI

If Sell is included at launch:
1. clearly label as eBay workflow
2. show draft status, publish status, and failures
3. keep unsupported marketplaces out of active controls

---

## Paywall and Packaging UX

Canonical packaging for MVP:
1. Free: 5 scans per day
2. Paid: deeper workflow and selling utility

Paywall rules:
1. show after value moment, not before first useful scan
2. avoid inflated social proof placeholders
3. keep claims aligned to actual available features

---

## Copy Rules

Allowed claim style:
1. "confidence-scored estimate"
2. "based on recent comps"
3. "review before listing"

Disallowed claim style:
1. "always accurate"
2. "scan anything"
3. "list everywhere" (in MVP)

---

## Visual System (MVP)

Keep the existing design direction but prioritize clarity:
1. high contrast for value and confidence
2. distinct visual treatment for low-confidence states
3. restrained motion focused on scan and reveal moments

Design system must support:
1. fast readability in store lighting conditions
2. one-handed use
3. screenshot readability for support/debugging

---

## States Checklist

Required states across core screens:
1. empty state
2. loading state
3. low-confidence state
4. no-comp state
5. network failure state
6. OCR-failure state
7. provider timeout state

Each state must provide:
1. plain-language explanation
2. immediate next action

---

## Instrumentation Requirements

Track at minimum:
1. scan started/completed/failed
2. confidence band distribution
3. save rate
4. correction rate
5. rescan rate
6. sell-tab entry rate

Use this data to iterate UX and calibration.

---

## Accessibility and Reliability Requirements

1. large tap targets for core actions
2. legible typography at default and larger text settings
3. deterministic state transitions
4. recoverable failure states without forced app restart

---

## Out of Scope in This MVP UI

1. Poshmark/Mercari/Depop connection screens
2. one-tap multi-platform publish UI
3. advanced gamification systems
4. widget-first growth loops

---

## Definition of UI/UX Done

The UI/UX plan is complete for MVP when:
1. users understand what to scan
2. users understand confidence meaning
3. users can act on outputs quickly
4. users can recover from common failures
5. all visible claims match shipped behavior

---

## Component Specifications

This section defines the production-ready component library for ThriftFlip MVP. Every component includes a full contract: purpose, variants, props, dimensions, tokens, states, and accessibility. A developer should be able to implement any component directly from this spec without ambiguity.

All components use `TFColor`, `TFFont`, `TFSpacing`, and `TFRadius` tokens from `Core/DesignSystem/`. Never hardcode values.

---

### Semantic Token Map

Before individual components, this section defines the semantic role aliases that all components reference.

#### Color Tokens by Semantic Role

| Semantic Role | Token | Dark Value | Light Value | Usage |
|---|---|---|---|---|
| `--color-positive` | `TFColor.gainGreen` | #5AC53A | #5AC53A | Profit, high confidence, success, primary CTA |
| `--color-warning` | `TFColor.warning` | #EB5D2A | #EB5D2A | Low confidence, errors, value decrease |
| `--color-critical` | `TFColor.warning` | #EB5D2A | #EB5D2A | Destructive actions, critical errors (same hue, reserved for future split) |
| `--color-accent` | `TFColor.gold` | #F6C86A | #F6C86A | Medium confidence, highlights, premium features |
| `--color-surface-1` | `TFColor.background` | #1F2123 | #FFFFFF | Root background |
| `--color-surface-2` | `TFColor.cardSurface` | #2A2C2E | #F5F5F7 | Cards, sheets, elevated containers |
| `--color-surface-3` | `TFColor.cardSurface.opacity(0.65)` | rgba(42,44,46,0.65) | rgba(245,245,247,0.65) | Glassmorphic containers |
| `--color-surface-glass` | `.glassEffect(.regular)` | System glass | System glass | Tab bar, navigation chrome, sheet handles |
| `--text-primary` | `TFColor.textPrimary` | #FFFFFF | #1A1A1A | Headlines, hero numbers, primary labels |
| `--text-secondary` | `TFColor.textSecondary` | #9CA3AF | #6B7280 | Supporting text, descriptions |
| `--text-muted` | `TFColor.textTertiary` | #48484A | #9CA3AF | Metadata, timestamps, tertiary info |
| `--border-subtle` | `Color.white.opacity(0.12)` | rgba(255,255,255,0.12) | rgba(0,0,0,0.06) | Card borders, dividers |
| `--border-inner-highlight` | `Color.white.opacity(0.06)` | rgba(255,255,255,0.06) | rgba(255,255,255,0.5) | Inner top highlight on glass cards |

#### Glassmorphic Card Material (Reusable)

```swift
struct TFGlassCard: ViewModifier {
    var cornerRadius: CGFloat = TFRadius.large // 16pt default

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(TFColor.cardSurface.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            .frame(height: cornerRadius * 2)
                            .clipped()
                    }
            }
    }
}
```

---

### Iconography Rules

| Rule | Specification |
|---|---|
| **Symbol Set** | SF Symbols exclusively; no custom icon assets in MVP |
| **Stroke Weight** | `.regular` weight for all icons (matches SF Pro body weight) |
| **Corner Style** | System default (rounded); do not apply `.monochrome` rendering unless specified |
| **Rendering Mode** | `.hierarchical` for multi-layer icons; `.monochrome` for single-color icons |
| **Filled vs Outline** | Outlined for inactive/default state; filled (`.fill` variant) for selected/active state |
| **Nav Bar Icons** | 24pt frame, outlined default, filled when selected |
| **Content Icons** | Match the text size of their context (e.g., 14pt icon next to caption text) |
| **Semantic Color** | Icons inherit the text color of their context unless they carry independent meaning |
| **Positive Semantic** | `TFColor.gainGreen` — checkmarks, savings, high confidence dot |
| **Warning Semantic** | `TFColor.warning` — alerts, low confidence dot, error icons |
| **Neutral Semantic** | `TFColor.textSecondary` — informational icons, navigation |
| **Accessibility** | Every icon paired with text is decorative (`accessibilityHidden(true)`); standalone icons require `accessibilityLabel` |

---

### Component 1: AppHeader

**File:** `Core/DesignSystem/Components/AppHeader.swift`

**Purpose:** Top navigation bar for non-camera screens (Collection, Sell, Item Detail). Provides screen title and optional trailing action. Not used on Scan screen (camera fills full screen).

#### Variants

| Variant | Description |
|---|---|
| `default` | Title + optional trailing button |
| `withSubtitle` | Title + subtitle line (e.g., "My Finds" + "24 items") |
| `transparent` | No background, used when scrolled to top with content behind |

#### Props

```swift
struct AppHeader: View {
    let title: String
    let subtitle: String?
    let trailingIcon: String?
    let trailingAction: (() -> Void)?
    let style: AppHeaderStyle
}

enum AppHeaderStyle {
    case opaque
    case transparent
}
```

#### Dimensions

| Property | Value |
|---|---|
| Height | 44pt content + top safe area inset |
| Horizontal padding | `TFSpacing.md` (16pt) |
| Title baseline to top | 12pt from bottom of safe area |
| Trailing icon frame | 44x44pt touch target, icon 24pt |

#### Typography

| Element | Token |
|---|---|
| Title | `TFFont.title1` (28pt semibold) |
| Subtitle | `TFFont.caption` (14pt medium) |

#### Colors

| Element | Token |
|---|---|
| Title text | `TFColor.textPrimary` |
| Subtitle text | `TFColor.textSecondary` |
| Trailing icon | `TFColor.textSecondary` |
| Background (opaque) | `TFColor.background` |
| Background (transparent) | `.clear` |

#### Border/Shadow

| Property | Value |
|---|---|
| Bottom separator (opaque) | `TFColor.cardSurface`, 0.5pt, full width |
| Shadow | None |

#### Spacing

| Property | Token |
|---|---|
| Title to subtitle | `TFSpacing.xs` (4pt) |
| Leading edge to title | `TFSpacing.md` (16pt) |
| Trailing icon to edge | `TFSpacing.md` (16pt) |

#### Icon Size

| Element | Size |
|---|---|
| Trailing action icon | 24pt, outlined, `.regular` weight |

#### Accessibility

| Property | Value |
|---|---|
| Title | `.accessibilityAddTraits(.isHeader)`, `.accessibilityHeading(.h1)` |
| Trailing button | `accessibilityLabel` from caller (e.g., "Profile", "Filter") |

#### Visual State Matrix

| State | Title | Trailing Icon | Background |
|---|---|---|---|
| Default | `textPrimary` | `textSecondary` | `background` / `.clear` |
| Pressed (trailing) | unchanged | `textPrimary`, scale 0.92 | unchanged |
| Scrolled (opaque) | unchanged | unchanged | `background` + bottom separator |
| Disabled | N/A | N/A | N/A |
| Loading | N/A | N/A | N/A |
| Error | N/A | N/A | N/A |

---

### Component 2: BottomTabBar

**File:** `App/ContentView.swift` (inline in `TabView` configuration)

**Purpose:** Primary navigation for the three app sections: Scan, Collection, Sell. Always visible except during full-screen camera capture and sheet presentations. Uses liquid glass material on iOS 26+, falling back to `.ultraThinMaterial` on iOS 17-25.

#### Variants

| Variant | Description |
|---|---|
| `default` | Three tabs, one selected |
| `scanActive` | Scan tab selected, camera behind (dark surround enforced) |
| `badged` | Collection tab shows unread count badge |

#### Props

```swift
TabView(selection: $selectedTab) {
    ScanView()
        .tabItem {
            Label("Scan", systemImage: selectedTab == .scan ? "camera.fill" : "camera")
        }
        .tag(Tab.scan)

    CollectionView()
        .tabItem {
            Label("My Finds", systemImage: selectedTab == .collection ? "square.stack.fill" : "square.stack")
        }
        .tag(Tab.collection)

    SellView()
        .tabItem {
            Label("Sell", systemImage: selectedTab == .sell ? "tag.fill" : "tag")
        }
        .tag(Tab.sell)
}
```

#### Dimensions

| Property | Value |
|---|---|
| Content height | 49pt (Apple standard) |
| Total height | 49pt + bottom safe area inset (34pt on modern iPhones = 83pt total) |
| Icon frame | 24pt within 28x28pt bounding box |
| Label baseline | 4pt below icon bottom |
| Tab item touch target | Full tab width x 49pt (minimum 44pt wide per tab) |

#### Typography

| Element | Token |
|---|---|
| Tab label | `TFFont.micro` (12pt regular) |

#### Colors

| Element | Token |
|---|---|
| Selected icon | `TFColor.gainGreen` |
| Selected label | `TFColor.gainGreen` |
| Unselected icon | `TFColor.textSecondary` |
| Unselected label | `TFColor.textSecondary` |
| Background (iOS 26+) | `.glassEffect(.regular)` (system liquid glass) |
| Background (iOS 17-25) | `.ultraThinMaterial` with `TFColor.cardSurface.opacity(0.85)` tint |
| Active indicator | None (color change only, no pill/underline) |

#### Border/Shadow

| Property | Value |
|---|---|
| Top separator | `Color.white.opacity(0.08)`, 0.5pt (dark); `Color.black.opacity(0.06)` (light) |
| Shadow | None (glass material provides its own depth) |

#### Spacing

| Property | Token |
|---|---|
| Icon to label | 2pt (system default) |
| Inter-tab | Equal distribution (`.frame(maxWidth: .infinity)`) |

#### Icon Size

| Element | Size | Style |
|---|---|---|
| Tab icon (unselected) | 24pt | Outlined (e.g., `camera`) |
| Tab icon (selected) | 24pt | Filled (e.g., `camera.fill`) |

#### Safe Area Behavior

The tab bar extends its background material into the bottom safe area. Content scrolls behind the translucent bar. The `safeAreaInset(edge: .bottom)` is automatically handled by `TabView`. Content views must NOT add their own bottom padding for the tab bar.

#### Accessibility

| Property | Value |
|---|---|
| Tab trait | `.accessibilityAddTraits(.isTabBar)` (automatic with TabView) |
| Each tab | `accessibilityLabel` matches the label text |
| Badge | `accessibilityLabel` includes badge count: "My Finds, 3 new items" |

#### Visual State Matrix

| State | Icon | Label | Background |
|---|---|---|---|
| Default (unselected) | `textSecondary`, outlined | `textSecondary` | Glass/material |
| Selected | `gainGreen`, filled | `gainGreen` | Glass/material |
| Pressed | Scale 0.92, 0.1s | Match pressed tab color | unchanged |
| Disabled | N/A (tabs always enabled) | N/A | N/A |
| Loading | N/A | N/A | N/A |
| Error | N/A | N/A | N/A |

---

### Component 3: ScanOverlayFrame

**File:** `Features/Scan/ScanOverlayFrame.swift`

**Purpose:** Visual guide overlaid on the camera feed that helps users frame the clothing tag or item. Provides alignment guidance without obstructing the camera. Animates to indicate OCR lock state.

#### Variants

| Variant | Description |
|---|---|
| `searching` | Pulsing corner brackets, waiting for tag |
| `locked` | Solid green frame, tag text detected |
| `failed` | Red/warning frame, brief shake, OCR could not read |

#### Props

```swift
struct ScanOverlayFrame: View {
    let state: ScanOverlayState
    let guidanceText: String
}

enum ScanOverlayState {
    case searching
    case locked
    case failed
}
```

#### Dimensions

| Property | Value |
|---|---|
| Frame size | 280 x 180pt (landscape tag orientation) |
| Corner bracket length | 32pt per side |
| Corner bracket thickness | 3pt |
| Corner radius (frame) | `TFRadius.medium` (12pt) |
| Guidance text position | 16pt below frame bottom |
| Vertical center offset | -40pt (shifted above center to avoid thumb/scan button) |

#### Typography

| Element | Token |
|---|---|
| Guidance text | `TFFont.caption` (14pt medium) |

#### Colors

| Element | Searching | Locked | Failed |
|---|---|---|---|
| Corner brackets | `Color.white.opacity(0.6)` | `TFColor.gainGreen` | `TFColor.warning` |
| Guidance text | `Color.white.opacity(0.8)` | `TFColor.gainGreen` | `TFColor.warning` |
| Frame interior | `.clear` | `.clear` | `.clear` |
| Vignette overlay | `Color.black.opacity(0.3)` outside frame | Same | Same |

#### Border/Shadow

| Property | Value |
|---|---|
| Corner brackets | 3pt stroke, `.round` line cap |
| Frame fill | Fully transparent (camera visible) |
| Outer vignette | Radial gradient from `.clear` at frame to `Color.black.opacity(0.3)` at edges |

#### Spacing

| Property | Token |
|---|---|
| Frame to guidance text | `TFSpacing.md` (16pt) |

#### Animation

| State Transition | Animation |
|---|---|
| Searching pulse | Corner bracket opacity oscillates 0.4–0.8, 1.5s ease-in-out, repeat |
| Searching → Locked | Brackets animate to `gainGreen`, 0.3s spring(response: 0.4, dampingFraction: 0.7) |
| Searching → Failed | Brackets animate to `warning`, shake offset +/- 8pt, 0.4s |
| Failed auto-reset | Returns to `searching` after 2s |

#### Accessibility

| Property | Value |
|---|---|
| Frame | `accessibilityHidden(true)` (decorative) |
| Guidance text | `accessibilityLabel(guidanceText)` |
| State changes | Post `.announcement`: "Tag detected" / "Could not read tag" |

#### Visual State Matrix

| State | Brackets | Guidance | Animation |
|---|---|---|---|
| Searching | White 60%, pulsing | "Center the tag in the frame" | Pulse |
| Locked | `gainGreen`, solid | "Tag detected" | Spring snap |
| Failed | `warning`, solid | "Couldn't read tag — try again" | Shake |

---

### Component 4: PrimaryScanButton

**File:** `Core/DesignSystem/Components/ScanButton.swift`

**Purpose:** The main capture trigger on the Scan screen. Always visible at the bottom of the camera view. Large, accessible, unmistakable. Indicates scanning state with spinner.

#### Variants

| Variant | Description |
|---|---|
| `ready` | Green circle, camera icon, tappable |
| `scanning` | Green circle, spinning progress, not tappable |
| `cooldown` | Brief disabled state after scan (prevents double-tap), dimmed |
| `disabled` | Greyed out, no camera permission or rate limited |

#### Props

```swift
struct PrimaryScanButton: View {
    let state: ScanButtonState
    let action: () -> Void
}

enum ScanButtonState {
    case ready
    case scanning
    case cooldown
    case disabled
}
```

#### Dimensions

| Property | Value |
|---|---|
| Outer diameter | 72pt |
| Inner icon/spinner size | 28pt |
| Touch target | 72pt (exceeds 44pt minimum) |
| Ring border (outer) | 4pt stroke, `Color.white.opacity(0.3)` |
| Position | Center-x, 40pt above tab bar top edge |

#### Colors

| Element | Ready | Scanning | Cooldown | Disabled |
|---|---|---|---|---|
| Background fill | `TFColor.gainGreen` | `TFColor.gainGreen` | `TFColor.gainGreen.opacity(0.4)` | `TFColor.textTertiary.opacity(0.3)` |
| Icon/spinner | `.white` | `.white` | `.white.opacity(0.5)` | `.white.opacity(0.3)` |
| Outer ring | `Color.white.opacity(0.3)` | `Color.white.opacity(0.3)` | `Color.white.opacity(0.15)` | `Color.white.opacity(0.1)` |

#### Border/Shadow

| Property | Value |
|---|---|
| Outer ring | 4pt stroke, `Color.white.opacity(0.3)`, 2pt gap from fill |
| Drop shadow | `Color.black.opacity(0.3)`, radius 8pt, y-offset 4pt |

#### Spacing

| Property | Token |
|---|---|
| Bottom edge to tab bar top | 40pt (fixed) |
| Ring gap (outer ring to fill) | 2pt |

#### Icon Size

| Element | Size | Symbol |
|---|---|---|
| Camera icon (ready) | 28pt | `camera.fill` |
| Spinner (scanning) | 28pt | `ProgressView().tint(.white)` |

#### Accessibility

| Property | Value |
|---|---|
| Ready | `accessibilityLabel("Scan item")`, `accessibilityHint("Takes a photo of the tag and item")` |
| Scanning | `accessibilityLabel("Scanning in progress")`, `.updatesFrequently` |
| Cooldown | `accessibilityLabel("Scan button cooling down")` |
| Disabled | `accessibilityLabel("Scan unavailable")`, hint explains reason |

#### Visual State Matrix

| State | Fill | Icon | Ring | Shadow | Interaction |
|---|---|---|---|---|---|
| Ready | `gainGreen` | `camera.fill` white | white 30% | Yes | Tappable |
| Pressed | `gainGreen` `.brightness(-0.1)` | unchanged | unchanged | Yes | Scale 0.9, spring |
| Scanning | `gainGreen` | Spinner white | white 30% | Yes | `disabled(true)` |
| Cooldown | `gainGreen` 40% | `camera.fill` 50% | white 15% | Dimmed | `disabled(true)`, 1s auto-reset |
| Disabled | `textTertiary` 30% | `camera.fill` 30% | white 10% | None | `disabled(true)` |

---

### Component 5: ResultBottomSheet

**File:** `Features/Result/ResultBottomSheet.swift`

**Purpose:** The primary value delivery surface. Slides up from the bottom after a scan completes, showing identification, confidence, price range, comparable listings, and action buttons. Uses `presentationDetents` for snap heights.

#### Variants

| Variant | Description |
|---|---|
| `highConfidence` | Direct identification, green confidence, full comp display |
| `mediumConfidence` | Hedged identification, gold confidence, full comp display |
| `lowConfidence` | Cautious identification, warning banner, rescan-primary CTA |
| `loading` | Skeleton placeholders while result processes |
| `error` | Error message with retry action |

#### Props

```swift
struct ResultBottomSheet: View {
    let result: ScanResult?
    let error: ScanError?
    let onSave: () -> Void
    let onRescan: () -> Void
    let onCorrect: () -> Void
    let onDismiss: () -> Void
}
```

#### Dimensions

| Property | Value |
|---|---|
| Presentation detents | `.height(380)` (collapsed), `.large` (expanded) |
| Default detent | `.height(380)` |
| Corner radius | 20pt (matches glassmorphic card spec) |
| Drag indicator | System default (5x36pt, centered) |
| Max content width | Screen width (full bleed sheet) |

#### Internal Stack Order (exact, top to bottom)

| Row | Content | Spacing After |
|---|---|---|
| 1. Title Row | Brand + item name (left), dismiss X (right) | `TFSpacing.sm` (8pt) |
| 2. Category Row | Category + garment type label | `TFSpacing.md` (16pt) |
| 3. Confidence Row | `ConfidenceBadge` + confidence factors summary | `TFSpacing.md` (16pt) |
| 4. Price Block | `PriceRangeBlock` (hero median + low/high) | `TFSpacing.sm` (8pt) |
| 5. Comp Depth Row | "Based on N comps" label | `TFSpacing.md` (16pt) |
| 6. Comp Carousel | Horizontal scroll of `CompCard` items | `TFSpacing.lg` (24pt) |
| 7. Action Row | Primary + secondary buttons | `TFSpacing.md` (16pt) to bottom |

Low-confidence variant inserts a **Warning Banner** between Title Row and Category Row:
- Full-width, `TFColor.warning.opacity(0.12)` background
- `TFColor.warning` text: "We're not sure about this one"
- `TFFont.caption`, corner radius `TFRadius.small` (8pt)
- Spacing: `TFSpacing.sm` (8pt) above and below

#### Typography

| Element | Token |
|---|---|
| Brand + item name | `TFFont.headline` (18pt semibold) |
| Category/garment | `TFFont.caption` (14pt medium) |
| Comp depth label | `TFFont.micro` (12pt regular) |
| Warning banner | `TFFont.caption` (14pt medium) |

#### Colors

| Element | Token |
|---|---|
| Sheet background | `TFColor.cardSurface` (solid, not glass — content surface) |
| Title text | `TFColor.textPrimary` |
| Category text | `TFColor.textSecondary` |
| Comp depth text | `TFColor.textTertiary` |
| Dismiss icon | `TFColor.textTertiary` |

#### Border/Shadow

| Property | Value |
|---|---|
| Sheet corner radius | 20pt, top corners only |
| Sheet shadow | System `.presentationDetents` shadow (automatic) |

#### Spacing

| Property | Token |
|---|---|
| Content horizontal padding | `TFSpacing.lg` (24pt) |
| Top padding (below handle) | `TFSpacing.md` (16pt) |
| Bottom padding | `TFSpacing.lg` (24pt) + safe area |
| Between stack rows | See Internal Stack Order table above |

#### Icon Size

| Element | Size | Symbol |
|---|---|---|
| Dismiss button | 20pt icon in 44x44pt target | `xmark` |

#### Accessibility

| Property | Value |
|---|---|
| Sheet | `accessibilityLabel("Scan result")` |
| On appear | Post `.screenChanged` with result summary |
| Title row | `.accessibilityHeading(.h1)` |
| Confidence | Reads as "High confidence, 87 percent" |
| Price | Reads as "Estimated value $67.50, range $42 to $95" |

#### Visual State Matrix

| State | Content | CTA | Background |
|---|---|---|---|
| High confidence | Direct identification | "Save" primary (green) | `cardSurface` |
| Medium confidence | "Likely [brand] [item]" | "Save" primary (green) | `cardSurface` |
| Low confidence | "This might be [brand]" + warning banner | "Rescan" primary, "Save Anyway" secondary | `cardSurface` |
| Loading | Skeleton placeholders (see Loading Skeletons) | Disabled grey buttons | `cardSurface` |
| Error | `ErrorStateCard` embedded | "Try Again" primary | `cardSurface` |

---

### Component 6: ConfidenceBadge

**File:** `Core/DesignSystem/Components/ConfidenceBadge.swift`

**Purpose:** Compact visual indicator of confidence level. Appears on result sheets, collection cards, and item detail views. Communicates trust level at a glance via color and label.

#### Variants

| Variant | Description |
|---|---|
| `full` | Pill with dot + level label + percentage (e.g., "High · 87%") |
| `compact` | Small dot + percentage only (e.g., "· 87%") for list rows |
| `dotOnly` | Colored dot only, no text, for very tight layouts |

#### Props

```swift
struct ConfidenceBadge: View {
    let level: ConfidenceLevel
    let score: Int
    let style: BadgeStyle

    init(level: ConfidenceLevel, score: Int, style: BadgeStyle = .full) { ... }
}

enum BadgeStyle {
    case full
    case compact
    case dotOnly
}
```

#### Dimensions

| Property | Full | Compact | DotOnly |
|---|---|---|---|
| Height | 24pt | 20pt | 8pt |
| Min width | 80pt | 48pt | 8pt |
| Dot diameter | 6pt | 6pt | 8pt |
| Corner radius | `TFRadius.pill` (999pt) | `TFRadius.pill` | Circle |

#### Typography

| Element | Token |
|---|---|
| Level label (full) | `TFFont.caption` (14pt medium) |
| Percentage (compact) | `TFFont.micro` (12pt regular) |

#### Colors

| Element | High | Medium | Low |
|---|---|---|---|
| Dot fill | `TFColor.gainGreen` | `TFColor.gold` | `TFColor.warning` |
| Text | `TFColor.gainGreen` | `TFColor.gold` | `TFColor.warning` |
| Background | `TFColor.gainGreen.opacity(0.15)` | `TFColor.gold.opacity(0.15)` | `TFColor.warning.opacity(0.15)` |

#### Border/Shadow

None.

#### Spacing

| Property | Token |
|---|---|
| Horizontal padding (full) | `TFSpacing.sm` (8pt) |
| Horizontal padding (compact) | `TFSpacing.xs` (4pt) leading, `TFSpacing.sm` (8pt) trailing |
| Dot to text | `TFSpacing.xs` (4pt) |
| Vertical padding | `TFSpacing.xs` (4pt) |

#### Icon Size

| Element | Size |
|---|---|
| Confidence dot | 6pt (full/compact), 8pt (dotOnly) — uses `Circle()`, not SF Symbol |

#### Accessibility

| Property | Value |
|---|---|
| Full | `accessibilityLabel("Confidence: [level], [score] percent")` |
| Compact | `accessibilityLabel("[level] confidence, [score] percent")` |
| DotOnly | `accessibilityLabel("[level] confidence")` |

#### Visual State Matrix

| State | Dot | Text | Background |
|---|---|---|---|
| Default (High) | `gainGreen` | "High · 87%" | `gainGreen` 15% |
| Default (Medium) | `gold` | "Medium · 62%" | `gold` 15% |
| Default (Low) | `warning` | "Low · 31%" | `warning` 15% |
| Loading | Shimmer placeholder, pill shape | N/A | `textTertiary` 10% |

---

### Component 7: PriceRangeBlock

**File:** `Core/DesignSystem/Components/PriceRangeView.swift`

**Purpose:** Hero display of the price estimate. Shows the median as a large hero number with the low-high range below. This is the core value moment — the number users came for. Uses monospace numerics for optical alignment.

#### Variants

| Variant | Description |
|---|---|
| `hero` | Large display for result sheet (42pt median) |
| `inline` | Smaller display for collection cards and detail views (22pt median) |
| `lowConfidence` | Hero size but muted color with "est." suffix |

#### Props

```swift
struct PriceRangeBlock: View {
    let priceRange: PriceRange
    let confidence: ConfidenceLevel
    let style: PriceBlockStyle

    init(priceRange: PriceRange, confidence: ConfidenceLevel, style: PriceBlockStyle = .hero) { ... }
}

enum PriceBlockStyle {
    case hero
    case inline
}
```

#### Dimensions

| Property | Hero | Inline |
|---|---|---|
| Median number height | ~50pt (42pt font + line height) | ~26pt (22pt font) |
| Range line height | ~18pt (14pt font) | ~16pt (12pt font) |
| Total block height | ~76pt | ~46pt |
| Min width | 120pt | 80pt |

#### Typography

| Element | Hero | Inline |
|---|---|---|
| Median price | `TFFont.display` (42pt bold) | `TFFont.title2` (22pt semibold) |
| Low-high range | `TFFont.caption` (14pt medium) | `TFFont.micro` (12pt regular) |
| "est." suffix | `TFFont.caption` (14pt medium) | `TFFont.micro` (12pt regular) |

All numeric values use `.monospacedDigit()` modifier for consistent width.

#### Colors

| Element | High/Medium Confidence | Low Confidence |
|---|---|---|
| Median price | `TFColor.textPrimary` | `TFColor.textSecondary` |
| "est." suffix | N/A (hidden) | `TFColor.textTertiary` |
| Low-high range | `TFColor.textSecondary` | `TFColor.textTertiary` |

#### Border/Shadow

None. Text-only block.

#### Spacing

| Property | Token |
|---|---|
| Median to range | `TFSpacing.xs` (4pt) |

#### Number Formatting

```swift
// "$67.50" or "$67" (suppress .00 cents)
// Thousands separator: "$1,250"
// Always currency symbol, never ISO code
```

#### Accessibility

| Property | Value |
|---|---|
| Combined read | `accessibilityLabel("Estimated value [median], range [low] to [high]")` |
| Low confidence | `accessibilityLabel("Rough estimate [median], range [low] to [high]")` |
| Element | `accessibilityElement(children: .combine)` |

#### Visual State Matrix

| State | Median Color | Range Color | Suffix |
|---|---|---|---|
| Default (high) | `textPrimary` | `textSecondary` | Hidden |
| Default (medium) | `textPrimary` | `textSecondary` | Hidden |
| Low confidence | `textSecondary` | `textTertiary` | "est." visible |
| Loading | Shimmer placeholders | Shimmer | Hidden |

---

### Component 8: CompCard

**File:** `Core/DesignSystem/Components/CompCard.swift`

**Purpose:** Individual comparable listing card shown in the horizontal carousel on the result sheet. Shows a thumbnail, title, price, and sold/active status. Tappable to open the eBay listing in Safari.

#### Variants

| Variant | Description |
|---|---|
| `default` | Thumbnail + title + price + status |
| `noImage` | Placeholder thumbnail with `photo` SF Symbol |
| `skeleton` | Loading placeholder |

#### Props

```swift
struct CompCard: View {
    let comp: CompListing
    let onTap: (() -> Void)?
}
```

#### Dimensions

| Property | Value |
|---|---|
| Card width | 160pt (fixed, for horizontal scroll) |
| Card height | 180pt |
| Thumbnail | 160 x 100pt (aspect fill, clipped) |
| Thumbnail corner radius | `TFRadius.medium` (12pt) top corners only |
| Card corner radius | `TFRadius.medium` (12pt) |
| Touch target | Full card (160 x 180pt) |

#### Typography

| Element | Token |
|---|---|
| Title | `TFFont.caption` (14pt medium), 1 line, truncated |
| Price | `TFFont.headline` (18pt semibold), `.monospacedDigit()` |
| Status label | `TFFont.micro` (12pt regular), uppercase |

#### Colors

| Element | Token |
|---|---|
| Card background | `TFColor.cardSurface` |
| Title text | `TFColor.textPrimary` |
| Price text | `TFColor.textPrimary` |
| Sold badge text | `TFColor.gainGreen` |
| Sold badge background | `TFColor.gainGreen.opacity(0.15)` |
| Active badge text | `TFColor.textSecondary` |
| Active badge background | `TFColor.textSecondary.opacity(0.15)` |
| No-image placeholder icon | `TFColor.textTertiary` |
| No-image placeholder bg | `TFColor.background` |

#### Border/Shadow

| Property | Value |
|---|---|
| Card border | `Color.white.opacity(0.08)`, 1pt |
| Card shadow | `Color.black.opacity(0.15)`, radius 4pt, y-offset 2pt |

#### Spacing

| Property | Token |
|---|---|
| Thumbnail to title | `TFSpacing.sm` (8pt) |
| Title to price row | `TFSpacing.xs` (4pt) |
| Content horizontal padding | `TFSpacing.sm` (8pt) |
| Content bottom padding | `TFSpacing.sm` (8pt) |
| Between comp cards (carousel) | `TFSpacing.sm` (8pt) |

#### Icon Size

| Element | Size | Symbol |
|---|---|---|
| Placeholder image icon | 24pt | `photo` |

#### Accessibility

| Property | Value |
|---|---|
| Card | `accessibilityLabel("[title], [price], [sold/active]")` |
| Action | `accessibilityHint("Opens listing on eBay")` |
| Traits | `.isButton`, `.isLink` |

#### Visual State Matrix

| State | Thumbnail | Title | Price | Border |
|---|---|---|---|---|
| Default | Image | `textPrimary` | `textPrimary` | white 8% |
| Pressed | `.opacity(0.8)` | unchanged | unchanged | white 15% |
| No image | Placeholder | `textPrimary` | `textPrimary` | white 8% |
| Skeleton | Shimmer rect | Shimmer line | Shimmer line | white 5% |

---

### Component 9: ActionButton

**File:** `Core/DesignSystem/Components/ActionButton.swift`

**Purpose:** Universal action button used across all screens. Supports primary (filled), secondary (outlined), and text-only styles. Handles loading state with inline spinner.

#### Variants

| Variant | Description |
|---|---|
| `primary` | Filled background, white text |
| `secondary` | Outlined border, colored text |
| `text` | No background, no border, colored text only |
| `destructive` | Filled warning background, white text |

#### Props

```swift
struct ActionButton: View {
    let title: String
    let icon: String?
    let style: ActionButtonStyle
    let size: ActionButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: ActionButtonStyle = .primary,
        size: ActionButtonSize = .large,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) { ... }
}

enum ActionButtonStyle {
    case primary
    case secondary
    case text
    case destructive
}

enum ActionButtonSize {
    case large    // Full width, 52pt height
    case medium   // Hug content, 44pt height
    case small    // Hug content, 36pt height
}
```

#### Dimensions

| Property | Large | Medium | Small |
|---|---|---|---|
| Height | 52pt | 44pt | 36pt |
| Width | Full parent width | Hug content + padding | Hug content + padding |
| Min width | N/A | 120pt | 80pt |
| Corner radius | `TFRadius.medium` (12pt) | `TFRadius.small` (8pt) | `TFRadius.small` (8pt) |
| Touch target | Full button area (min 44pt height) | 44pt minimum | 44pt minimum (padded if needed) |

#### Typography

| Element | Large | Medium | Small |
|---|---|---|---|
| Title | `TFFont.headline` (18pt semibold) | `TFFont.body` (16pt regular) | `TFFont.caption` (14pt medium) |

#### Colors

| Element | Primary | Secondary | Text | Destructive |
|---|---|---|---|---|
| Background | `TFColor.gainGreen` | `.clear` | `.clear` | `TFColor.warning` |
| Text | `.white` | `TFColor.gainGreen` | `TFColor.gainGreen` | `.white` |
| Border | None | `TFColor.gainGreen`, 1.5pt | None | None |
| Disabled bg | `TFColor.textTertiary.opacity(0.2)` | `.clear` | `.clear` | `TFColor.textTertiary.opacity(0.2)` |
| Disabled text | `TFColor.textTertiary` | `TFColor.textTertiary` | `TFColor.textTertiary` | `TFColor.textTertiary` |
| Disabled border | N/A | `TFColor.textTertiary.opacity(0.3)` | N/A | N/A |

#### Border/Shadow

| Property | Primary | Secondary | Text | Destructive |
|---|---|---|---|---|
| Border | None | `TFColor.gainGreen`, 1.5pt | None | None |
| Shadow | None | None | None | None |

#### Spacing

| Property | Token |
|---|---|
| Horizontal padding (large) | `TFSpacing.lg` (24pt) |
| Horizontal padding (medium) | `TFSpacing.md` (16pt) |
| Horizontal padding (small) | `TFSpacing.sm` (8pt) |
| Icon to title | `TFSpacing.sm` (8pt) |

#### Icon Size

| Element | Large | Medium | Small |
|---|---|---|---|
| Leading icon | 20pt | 18pt | 16pt |
| Loading spinner | 20pt | 18pt | 16pt |

#### Accessibility

| Property | Value |
|---|---|
| Label | `accessibilityLabel(title)` |
| Loading | `accessibilityLabel("[title], loading")`, `.updatesFrequently` |
| Disabled | Handled by `.disabled()` modifier |
| Hint | Caller provides via `.accessibilityHint()` |

#### Visual State Matrix

| State | Background | Text | Border | Icon |
|---|---|---|---|---|
| Default | Style color | Style text | Style border | Visible |
| Pressed | `brightness(-0.1)` | unchanged | unchanged | unchanged |
| Disabled | Muted (see Colors) | `textTertiary` | Muted | `textTertiary` |
| Loading | Style color | Hidden | Style border | Replaced by spinner |

---

### Component 10: FilterChip

**File:** `Core/DesignSystem/Components/FilterChip.swift`

**Purpose:** Horizontal filter pills used in the Collection view for filtering items by confidence level or status. Supports single-select semantics.

#### Variants

| Variant | Description |
|---|---|
| `unselected` | Outlined, muted colors |
| `selected` | Filled background, white text |

#### Props

```swift
struct FilterChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
}
```

#### Dimensions

| Property | Value |
|---|---|
| Height | 36pt |
| Min width | 64pt |
| Corner radius | `TFRadius.pill` (999pt) |
| Touch target | 36pt height (padded to 44pt vertically via scroll view content insets) |

#### Typography

| Element | Token |
|---|---|
| Label | `TFFont.caption` (14pt medium) |

#### Colors

| Element | Unselected | Selected |
|---|---|---|
| Background | `TFColor.cardSurface` | `TFColor.gainGreen` |
| Text | `TFColor.textSecondary` | `.white` |
| Border | `Color.white.opacity(0.08)`, 1pt | None |
| Icon tint | `TFColor.textSecondary` | `.white` |

#### Border/Shadow

| Property | Value |
|---|---|
| Unselected border | `Color.white.opacity(0.08)`, 1pt |
| Selected border | None |
| Shadow | None |

#### Spacing

| Property | Token |
|---|---|
| Horizontal padding | `TFSpacing.md` (16pt) |
| Vertical padding | `TFSpacing.sm` (8pt) |
| Icon to label | `TFSpacing.xs` (4pt) |
| Between chips | `TFSpacing.sm` (8pt) |
| Chip row horizontal inset | `TFSpacing.md` (16pt) leading/trailing |

#### Icon Size

| Element | Size |
|---|---|
| Leading icon | 14pt |

#### Accessibility

| Property | Value |
|---|---|
| Role | `.isButton` |
| Selected | `.isSelected` when `isSelected == true` |
| Label | `accessibilityLabel(label)` |

#### Visual State Matrix

| State | Background | Text | Border |
|---|---|---|---|
| Unselected | `cardSurface` | `textSecondary` | white 8% |
| Selected | `gainGreen` | `.white` | None |
| Pressed (unselected) | `cardSurface` `brightness(-0.05)` | unchanged | unchanged |
| Pressed (selected) | `gainGreen` `brightness(-0.1)` | unchanged | unchanged |
| Disabled | `cardSurface.opacity(0.5)` | `textTertiary` | white 4% |

---

### Component 11: CollectionCard

**File:** `Core/DesignSystem/Components/CollectionCard.swift`

**Purpose:** Grid-layout card for the Collection view. Shows item thumbnail, brand label, price estimate, and confidence indicator. Supports 2-column grid layout.

#### Variants

| Variant | Description |
|---|---|
| `default` | Full card with all info |
| `corrected` | Shows "Corrected" badge overlay |
| `lowConfidence` | Warning-tinted confidence, muted price |

#### Props

```swift
struct CollectionCard: View {
    let item: SavedItem
    let onTap: () -> Void
}
```

#### Dimensions

| Property | Value |
|---|---|
| Card width | `(screenWidth - 48) / 2` (2-column grid, 16pt side margins + 16pt gutter) |
| Image aspect ratio | 4:3 (width : height) |
| Image height | Card width * 0.75 |
| Card corner radius | `TFRadius.large` (16pt) |
| Image corner radius | `TFRadius.large` (16pt) top corners only |
| Total card height | Image height + ~88pt content area |
| Touch target | Full card |

#### Badge Position

| Badge | Position | Offset |
|---|---|---|
| Confidence (dotOnly) | Top-right of image | 8pt from top, 8pt from right |
| "Corrected" label | Top-left of image | 8pt from top, 8pt from left |

#### Typography

| Element | Token | Max Lines |
|---|---|---|
| Brand name | `TFFont.caption` (14pt medium) | 1, truncated |
| Item name | `TFFont.micro` (12pt regular) | 1, truncated |
| Median price | `TFFont.headline` (18pt semibold), `.monospacedDigit()` | 1 |
| Low-high range | `TFFont.micro` (12pt regular) | 1 |

#### Value Text Format

```swift
// Median: "$67" or "$67.50" (suppress .00, keep other cents)
// Range: "$42 - $95" in micro/textTertiary
// Low confidence: median in textSecondary + "est."
```

#### Confidence Placement

`ConfidenceBadge(style: .dotOnly)` as overlay on image, top-right corner, 8pt inset. Badge sits on a `Color.black.opacity(0.4)` pill (20x20pt) for legibility over any image.

#### Colors

| Element | Token |
|---|---|
| Card background | `TFColor.cardSurface` |
| Brand text | `TFColor.textPrimary` |
| Item name text | `TFColor.textSecondary` |
| Median price | `TFColor.textPrimary` (high/med), `TFColor.textSecondary` (low) |
| Range text | `TFColor.textTertiary` |
| "Corrected" badge bg | `TFColor.gold.opacity(0.85)` |
| "Corrected" badge text | `TFColor.background` (dark on gold) |
| Image placeholder | `TFColor.background`, `photo` icon in `textTertiary` |

#### Border/Shadow

| Property | Value |
|---|---|
| Card border | `Color.white.opacity(0.08)`, 1pt |
| Card shadow | `Color.black.opacity(0.1)`, radius 4pt, y-offset 2pt |

#### Spacing

| Property | Token |
|---|---|
| Image to brand | `TFSpacing.sm` (8pt) |
| Brand to item name | `TFSpacing.xs` (4pt) |
| Item name to price | `TFSpacing.sm` (8pt) |
| Content horizontal padding | `TFSpacing.sm` (8pt) |
| Content bottom padding | `TFSpacing.sm` (8pt) |
| Grid gutter (between cards) | `TFSpacing.md` (16pt) |
| Grid side margins | `TFSpacing.md` (16pt) |

#### Icon Size

| Element | Size |
|---|---|
| Placeholder photo icon | 28pt |
| Confidence dot (overlay) | 8pt (dotOnly style) |

#### Accessibility

| Property | Value |
|---|---|
| Card | `accessibilityLabel("[brand] [itemName], estimated [median], [confidence level] confidence")` |
| Corrected | Append ", corrected" to label |
| Action | `accessibilityHint("Opens item detail")` |
| Traits | `.isButton` |

#### Visual State Matrix

| State | Image | Text | Border | Overlay |
|---|---|---|---|---|
| Default | Item photo | Standard colors | white 8% | Confidence dot |
| Pressed | `opacity(0.85)`, scale 0.97 | unchanged | unchanged | unchanged |
| Corrected | Item photo | Standard colors | white 8% | Confidence dot + "Corrected" badge |
| Low confidence | Item photo | Muted median price | white 8% | Warning-color dot |
| Loading | Shimmer rectangle | Shimmer lines | white 5% | None |

---

### Component 12: StatCard

**File:** `Core/DesignSystem/Components/StatCard.swift`

**Purpose:** Summary statistic display used in the Collection header or dashboard area. Shows a large numeric value with a small label. Used for "Total Items," "Portfolio Value," "Avg. Confidence," etc.

#### Variants

| Variant | Description |
|---|---|
| `default` | Number + label |
| `withTrend` | Number + label + trend arrow (up/down/neutral) |
| `currency` | Number formatted as currency + label |

#### Props

```swift
struct StatCard: View {
    let value: String
    let label: String
    let trend: StatTrend?
    let trendValue: String?
}

enum StatTrend {
    case up
    case down
    case neutral
}
```

#### Dimensions

| Property | Value |
|---|---|
| Min width | 100pt |
| Width | Flexible, expands in grid (typically 1/3 of screen - margins) |
| Height | Hug content, typically ~72pt |
| Corner radius | `TFRadius.medium` (12pt) |

#### Typography

| Element | Token |
|---|---|
| Value | `TFFont.title1` (28pt semibold), `.monospacedDigit()` |
| Label | `TFFont.micro` (12pt regular) |
| Trend value | `TFFont.micro` (12pt regular) |

#### Colors

| Element | Token |
|---|---|
| Card background | `TFColor.cardSurface` (or glassmorphic with `TFGlassCard`) |
| Value text | `TFColor.textPrimary` |
| Label text | `TFColor.textSecondary` |
| Trend up | `TFColor.gainGreen` |
| Trend down | `TFColor.warning` |
| Trend neutral | `TFColor.textTertiary` |

#### Border/Shadow

| Property | Value |
|---|---|
| Border | `Color.white.opacity(0.08)`, 1pt |
| Shadow | None |

#### Spacing

| Property | Token |
|---|---|
| Value to label | `TFSpacing.xs` (4pt) |
| Internal padding | `TFSpacing.md` (16pt) |
| Between stat cards (grid) | `TFSpacing.sm` (8pt) |
| Trend icon to trend value | `TFSpacing.xs` (4pt) |

#### Icon Size

| Element | Size | Symbol |
|---|---|---|
| Trend arrow up | 12pt | `arrow.up.right` |
| Trend arrow down | 12pt | `arrow.down.right` |
| Trend neutral | 12pt | `arrow.right` |

#### Accessibility

| Property | Value |
|---|---|
| Card | `accessibilityElement(children: .combine)` |
| Read order | "[value] [label]" then "[trend direction] [trendValue]" if present |

#### Visual State Matrix

| State | Value | Label | Trend | Background |
|---|---|---|---|---|
| Default | `textPrimary` | `textSecondary` | Color-coded | `cardSurface` |
| Loading | Shimmer block | Shimmer line | Hidden | `cardSurface` |
| Error | "--" placeholder | Label visible | Hidden | `cardSurface` |

---

### Component 13: EmptyStateCard

**File:** `Core/DesignSystem/Components/EmptyStateView.swift`

**Purpose:** Full-screen or section-level placeholder when no content exists. Used for empty collection, no scan results, first-time states. Provides an icon, message, and optional CTA.

#### Presets

| Variant | Icon | Title | Message |
|---|---|---|---|
| `noScans` | `camera.viewfinder` | "No scans yet" | "Scan a tag and item to see what it's worth." |
| `noComps` | `magnifyingglass` | "No comparables found" | "We couldn't find similar listings. Try scanning the tag for better results." |
| `ocrFailed` | `text.viewfinder` | "Couldn't read the tag" | "Make sure the tag text is visible and well-lit, then try again." |
| `offline` | `wifi.slash` | "No connection" | "Check your internet and try again." |
| `rateLimited` | `lock.fill` | "Daily limit reached" | "You've used all 5 free scans today. Upgrade for unlimited scans." |

#### Props

```swift
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?
    let secondaryActionLabel: String?
    let secondaryAction: (() -> Void)?
}
```

#### Dimensions

| Property | Value |
|---|---|
| Layout | Centered vertically and horizontally in parent |
| Max message width | 280pt |
| Icon frame | 48x48pt |
| Button height | 44pt (medium ActionButton) |
| Button min width | 160pt |

#### Typography

| Element | Token |
|---|---|
| Title | `TFFont.headline` (18pt semibold) |
| Message | `TFFont.body` (16pt regular) |
| Secondary action | `TFFont.caption` (14pt medium) |

#### Colors

| Element | Token |
|---|---|
| Icon | `TFColor.textTertiary` |
| Title | `TFColor.textPrimary` |
| Message | `TFColor.textSecondary` |
| Primary action | `TFColor.gainGreen` bg, `.white` text (ActionButton primary) |
| Secondary action | `TFColor.textSecondary` text (ActionButton text style) |

#### Border/Shadow

None. Transparent, centered layout.

#### Spacing

| Property | Token |
|---|---|
| Icon to title | `TFSpacing.md` (16pt) |
| Title to message | `TFSpacing.sm` (8pt) |
| Message to primary action | `TFSpacing.lg` (24pt) |
| Primary to secondary action | `TFSpacing.sm` (8pt) |

#### Icon Size

| Element | Size |
|---|---|
| Hero icon | 48pt, `.regular` weight |

#### Accessibility

| Property | Value |
|---|---|
| Container | `accessibilityElement(children: .combine)` |
| Title | `.accessibilityAddTraits(.isHeader)` |
| Icon | Decorative (hidden from VoiceOver) |

#### Visual State Matrix

| State | Icon | Title | Message | Button |
|---|---|---|---|---|
| Default | `textTertiary` | `textPrimary` | `textSecondary` | Visible if action provided |
| Pressed (button) | unchanged | unchanged | unchanged | Per ActionButton pressed |

---

### Component 14: ErrorStateCard

**File:** `Core/DesignSystem/Components/ErrorStateCard.swift`

**Purpose:** Inline error display within a container (sheet, card, section). Unlike EmptyStateCard (full-screen), ErrorStateCard is compact and embeddable. Shows error type, user-readable message, and a retry action.

#### Variants

| Variant | Description |
|---|---|
| `retryable` | Shows retry button (network, timeout, OCR failures) |
| `nonRetryable` | Shows dismiss or alternate action (rate limited, no comps) |
| `inline` | Compact single-line error for embedding in forms |

#### Props

```swift
struct ErrorStateCard: View {
    let error: ScanError
    let message: String
    let isRetryable: Bool
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
}
```

#### Dimensions

| Property | Value |
|---|---|
| Width | Full parent width - padding |
| Min height | 120pt (standard), 44pt (inline) |
| Corner radius | `TFRadius.medium` (12pt) |
| Icon frame | 36x36pt (standard), 20x20pt (inline) |

#### Typography

| Element | Token |
|---|---|
| Error title | `TFFont.headline` (18pt semibold) |
| Error message | `TFFont.body` (16pt regular) |
| Inline message | `TFFont.caption` (14pt medium) |

#### Colors

| Element | Token |
|---|---|
| Background | `TFColor.warning.opacity(0.08)` |
| Border | `TFColor.warning.opacity(0.2)`, 1pt |
| Icon | `TFColor.warning` |
| Error title | `TFColor.textPrimary` |
| Error message | `TFColor.textSecondary` |
| Retry button | ActionButton secondary style |

#### Border/Shadow

| Property | Value |
|---|---|
| Border | `TFColor.warning.opacity(0.2)`, 1pt stroke |
| Shadow | None |

#### Spacing

| Property | Token |
|---|---|
| Internal padding | `TFSpacing.md` (16pt) |
| Icon to title | `TFSpacing.sm` (8pt) |
| Title to message | `TFSpacing.xs` (4pt) |
| Message to retry button | `TFSpacing.md` (16pt) |

#### Icon Size

| Element | Size | Symbol |
|---|---|---|
| Error icon (standard) | 36pt | `exclamationmark.triangle.fill` |
| Error icon (inline) | 20pt | `exclamationmark.triangle.fill` |

#### Accessibility

| Property | Value |
|---|---|
| Container | `accessibilityElement(children: .combine)` |
| Read order | "Error: [title]. [message]. [Retry / Dismiss] button" |
| On appear | Post `.announcement` with error message |

#### Visual State Matrix

| State | Icon | Background | Message | Action |
|---|---|---|---|---|
| Default (retryable) | `warning` | `warning` 8% | Error copy | "Try Again" button |
| Default (non-retryable) | `warning` | `warning` 8% | Error copy | "OK" / "Upgrade" button |
| Inline | `warning` 20pt | `warning` 8% | Single line | No button |
| Loading (retrying) | Spinner replaces icon | unchanged | "Retrying..." | Disabled button |

---

### Component 15: PaywallPlanCard

**File:** `Features/Paywall/PaywallPlanCard.swift`

**Purpose:** Pricing tier card on the paywall screen. Shows plan name, price, feature list, and selection state. Used in a vertical stack to compare Free vs. Pro tiers.

#### Variants

| Variant | Description |
|---|---|
| `free` | Current plan indicator, greyed features, no CTA |
| `pro` | Highlighted, gold accent, feature list, CTA |
| `proSelected` | Pro card in selected state (expanded, prominent CTA) |
| `loading` | Skeleton while StoreKit products load |

#### Props

```swift
struct PaywallPlanCard: View {
    let planName: String
    let price: String
    let priceSubtext: String?
    let features: [PaywallFeature]
    let isCurrentPlan: Bool
    let isSelected: Bool
    let isMostPopular: Bool
    let onSelect: () -> Void
}

struct PaywallFeature: Identifiable {
    let id = UUID()
    let text: String
    let isIncluded: Bool
}
```

#### Dimensions

| Property | Value |
|---|---|
| Width | Full parent width - `TFSpacing.lg` (24pt) * 2 |
| Min height | 200pt |
| Corner radius | 20pt |
| Feature row height | 32pt |
| "Most Popular" badge height | 24pt |
| Touch target | Full card |

#### Typography

| Element | Token |
|---|---|
| Plan name | `TFFont.headline` (18pt semibold) |
| Price | `TFFont.title1` (28pt semibold), `.monospacedDigit()` |
| Price subtext | `TFFont.micro` (12pt regular) |
| Feature text | `TFFont.body` (16pt regular) |
| "Most Popular" badge | `TFFont.micro` (12pt regular), uppercase, 0.5pt letter-spacing |
| CTA button | Per ActionButton spec (large) |
| "Current Plan" label | `TFFont.caption` (14pt medium) |

#### Colors

| Element | Free | Pro (unselected) | Pro (selected) |
|---|---|---|---|
| Card background | `TFColor.cardSurface` | `TFColor.cardSurface` | Glassmorphic: `cardSurface.opacity(0.65)` |
| Card border | `Color.white.opacity(0.08)` | `TFColor.gold.opacity(0.3)` | `TFColor.gold.opacity(0.6)` |
| Plan name | `TFColor.textSecondary` | `TFColor.textPrimary` | `TFColor.textPrimary` |
| Price | `TFColor.textSecondary` | `TFColor.textPrimary` | `TFColor.gold` |
| Price subtext | `TFColor.textTertiary` | `TFColor.textSecondary` | `TFColor.textSecondary` |
| Feature included icon | `TFColor.textTertiary` | `TFColor.gainGreen` | `TFColor.gainGreen` |
| Feature excluded icon | `TFColor.textTertiary.opacity(0.5)` | `TFColor.textTertiary` | `TFColor.textTertiary` |
| Feature included text | `TFColor.textTertiary` | `TFColor.textPrimary` | `TFColor.textPrimary` |
| Feature excluded text | `TFColor.textTertiary.opacity(0.5)` | `TFColor.textTertiary` | `TFColor.textTertiary` |
| "Most Popular" badge bg | N/A | `TFColor.gold.opacity(0.15)` | `TFColor.gold.opacity(0.2)` |
| "Most Popular" badge text | N/A | `TFColor.gold` | `TFColor.gold` |
| "Current Plan" label | `TFColor.textTertiary` | N/A | N/A |

#### Border/Shadow

| Property | Free | Pro | Pro Selected |
|---|---|---|---|
| Border | white 8%, 1pt | `gold` 30%, 1pt | `gold` 60%, 1.5pt |
| Shadow | None | None | `TFColor.gold.opacity(0.1)`, radius 12pt, y-offset 4pt |
| Inner highlight | None | None | `Color.white.opacity(0.06)` top edge |

#### Spacing

| Property | Token |
|---|---|
| Card internal padding | `TFSpacing.lg` (24pt) |
| Plan name to price | `TFSpacing.sm` (8pt) |
| Price to price subtext | `TFSpacing.xs` (4pt) |
| Price area to feature list | `TFSpacing.md` (16pt) |
| Between features | `TFSpacing.sm` (8pt) |
| Feature list to CTA | `TFSpacing.lg` (24pt) |
| "Most Popular" badge to top | -12pt (overlapping card top edge, centered) |
| Between plan cards | `TFSpacing.md` (16pt) |

#### Icon Size

| Element | Size | Symbol |
|---|---|---|
| Feature included | 16pt | `checkmark.circle.fill` |
| Feature excluded | 16pt | `xmark.circle` (outlined) |

#### Accessibility

| Property | Value |
|---|---|
| Card | `accessibilityElement(children: .combine)` |
| Read order | "[planName], [price], [priceSubtext]. Features: [list]. [Most Popular if applicable]" |
| Selection | `.isButton` |
| Current plan | Label includes "Current plan" |

#### Visual State Matrix

| State | Border | Price | Features | CTA |
|---|---|---|---|---|
| Default (free) | white 8% | `textSecondary` | Muted | None (shows "Current Plan") |
| Default (pro) | `gold` 30% | `textPrimary` | Full color | "Start Free Trial" |
| Selected (pro) | `gold` 60% + shadow | `gold` | Full color | "Start Free Trial" (prominent) |
| Pressed | Scale 0.98 | unchanged | unchanged | Per ActionButton |
| Loading | Shimmer fill | Shimmer | Shimmer lines | Shimmer button |

---

### Chart Component: PriceHistoryChart

**File:** `Core/DesignSystem/Components/PriceHistoryChart.swift`

**Purpose:** Price trend visualization for item detail view and portfolio summary. Built with Swift Charts. Shows price comp distribution over time with an interactive scrub tooltip.

#### Framework

Swift Charts (`import Charts`). No third-party charting libraries.

#### Dimensions

| Property | Value |
|---|---|
| Chart height | 200pt (fixed) |
| Chart horizontal padding | `TFSpacing.md` (16pt) |
| Line width | 2pt |
| Scrub dot diameter | 10pt (outer), 6pt (inner) |
| Tooltip height | 36pt |
| Tooltip corner radius | `TFRadius.small` (8pt) |
| Tooltip min width | 80pt |

#### Line Style

```swift
LineMark(...)
    .interpolationMethod(.catmullRom)
    .foregroundStyle(
        LinearGradient(
            colors: [TFColor.gainGreen, TFColor.gold],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
```

#### Area Fill

```swift
AreaMark(...)
    .foregroundStyle(
        LinearGradient(
            colors: [TFColor.gainGreen.opacity(0.2), TFColor.gainGreen.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    )
```

#### Dot Style

| Element | Appearance |
|---|---|
| Data points | Hidden by default (line only) |
| Scrub dot outer | 10pt circle, `TFColor.gainGreen` |
| Scrub dot inner | 6pt circle, `TFColor.background` |
| Scrub vertical rule | 1pt width, `TFColor.textTertiary.opacity(0.3)`, full chart height |

#### Tooltip Style

| Property | Value |
|---|---|
| Background | `TFColor.cardSurface` |
| Border | `Color.white.opacity(0.12)`, 1pt |
| Corner radius | `TFRadius.small` (8pt) |
| Price text | `TFFont.caption` (14pt medium), `TFColor.textPrimary`, `.monospacedDigit()` |
| Date text | `TFFont.micro` (12pt regular), `TFColor.textSecondary` |
| Padding | `TFSpacing.sm` (8pt) |
| Position | Centered above scrub dot, clamped to chart bounds |
| Shadow | `Color.black.opacity(0.2)`, radius 4pt |

#### Axis Visibility Policy

| Axis | Visibility | Style |
|---|---|---|
| X-axis labels | Visible, 3–5 labels max | `TFFont.micro`, `TFColor.textTertiary`, "MMM d" format |
| Y-axis labels | Hidden | N/A |
| X-axis line | Hidden | N/A |
| Y-axis line | Hidden | N/A |
| Grid lines (horizontal) | 3 lines, dashed | `TFColor.textTertiary.opacity(0.1)`, `StrokeStyle(lineWidth: 0.5, dash: [4, 4])` |
| Grid lines (vertical) | Hidden | N/A |

#### Scrub Interaction

```swift
// DragGesture on chart overlay
// On drag: snap to nearest data point, show tooltip + dot + vertical rule
// On drag end: tooltip fades out after 1.5s delay
// Haptic: UIImpactFeedbackGenerator(.light) on each snap
```

#### Accessibility

| Property | Value |
|---|---|
| Chart | `accessibilityLabel("Price history chart, [count] data points, range [min] to [max]")` |
| Data points | Individual `accessibilityElement` per point: "[date]: [price]" |
| Scrub | `.accessibilityAdjustableAction` for VoiceOver swipe through points |

#### Visual State Matrix

| State | Line | Tooltip | Grid |
|---|---|---|---|
| Default (not scrubbing) | Gradient line + area fill | Hidden | Visible |
| Scrubbing | Gradient line + area fill | Visible + dot + rule | Visible |
| No data | Hidden | Hidden | Hidden, show EmptyStateCard |
| Loading | Hidden, shimmer rectangle | Hidden | Shimmer lines |

---

### Loading Skeleton Components

**Directory:** `Core/DesignSystem/Components/Skeletons/`

**Purpose:** Dedicated skeleton loading states for major content areas. Maintains the exact layout dimensions of their loaded counterparts so content does not shift on load.

#### Shimmer Animation (Shared)

```swift
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.08), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(15))
                .offset(x: phase * 400)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
```

#### Skeleton 1: ResultSheetSkeleton

**File:** `Core/DesignSystem/Components/Skeletons/ResultSheetSkeleton.swift`

Matches the exact layout of `ResultBottomSheet` internal stack:

| Row | Skeleton Element | Dimensions |
|---|---|---|
| Title Row | Rounded rect placeholder | 200 x 22pt left, 40 x 22pt right |
| Category Row | Rounded rect placeholder | 140 x 16pt |
| Confidence Row | Pill placeholder | 80 x 24pt |
| Price Block | Large rounded rect | 160 x 48pt (median) + 120 x 16pt (range) |
| Comp Depth | Rounded rect placeholder | 100 x 14pt |
| Comp Carousel | 3x card placeholders | 160 x 180pt each, horizontal scroll |
| Action Row | 2x button placeholders | Full width x 52pt, 48% width x 52pt |

All placeholder elements: `TFColor.textTertiary.opacity(0.1)` fill, `TFRadius.small` corners, `.shimmer()`.

Spacing between rows matches ResultBottomSheet Internal Stack Order exactly.

#### Skeleton 2: CollectionGridSkeleton

**File:** `Core/DesignSystem/Components/Skeletons/CollectionGridSkeleton.swift`

Matches 2-column grid layout of CollectionCard:

| Element | Skeleton |
|---|---|
| Cards | 6 placeholder cards (fills viewport) |
| Image area | Rounded rect, 4:3 aspect ratio, `TFRadius.large` top corners |
| Brand line | Rounded rect, 70% card width x 14pt |
| Item line | Rounded rect, 50% card width x 12pt |
| Price line | Rounded rect, 40% card width x 20pt |

All use `TFColor.textTertiary.opacity(0.1)` fill and `.shimmer()`.

#### Skeleton 3: StatsHeaderSkeleton

**File:** `Core/DesignSystem/Components/Skeletons/StatsHeaderSkeleton.swift`

Matches horizontal StatCard grid:

| Element | Skeleton |
|---|---|
| Cards | 3 placeholder stat cards |
| Value placeholder | Rounded rect, 60% card width x 28pt |
| Label placeholder | Rounded rect, 80% card width x 12pt |

Container matches StatCard dimensions with `TFRadius.medium` corners. Uses `.shimmer()`.

#### Skeleton Behavior Rules

1. Match exact dimensions of loaded content — no layout shift on load.
2. Fill color: `TFColor.textTertiary.opacity(0.1)` in both light and dark modes.
3. Corner radii match the component they replace.
4. Shimmer runs continuously at 1.5s per cycle.
5. Not interactive: `allowsHitTesting(false)`.
6. Transition to content: `.transition(.opacity.combined(with: .scale(scale: 0.98)))` with `.easeOut(duration: 0.25)`.
7. VoiceOver: `accessibilityLabel("Loading")` on container.

---

### Component Build Order

| Phase | Components | Dependencies |
|---|---|---|
| 1 | Design tokens (Colors, Typography, Spacing, Radius) | None |
| 2 | `TFGlassCard` modifier, `ShimmerModifier` | Phase 1 |
| 3 | `ConfidenceBadge`, `ActionButton`, `FilterChip` | Phase 1 |
| 4 | `PriceRangeBlock`, `CompCard` | Phase 1 + Models |
| 5 | `EmptyStateCard`, `ErrorStateCard` | Phase 3 (ActionButton) |
| 6 | `StatCard`, `CollectionCard` | Phase 3 + Phase 4 |
| 7 | `ScanOverlayFrame`, `PrimaryScanButton` | Phase 1 |
| 8 | `PriceHistoryChart` | Phase 1 + Swift Charts |
| 9 | `ResultBottomSheet` | Phase 3 + 4 + 5 |
| 10 | `AppHeader`, `BottomTabBar` | Phase 1 (built with screens) |
| 11 | All skeleton variants | Phase 2 + matching component dimensions |
| 12 | `PaywallPlanCard` | Phase 3 (ActionButton) |

---

## Summary

MVP UI/UX success = trusted scan-to-decision loop.

Everything else is optional until this loop is reliable and repeatedly used.
