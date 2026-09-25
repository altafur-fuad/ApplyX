# ApplyX — UI/UX & Figma Design Specification

**Version:** 1.0.0
**Design Source of Truth:** Figma
**Implementation:** Flutter
**Style Direction:** Premium, minimal, intelligent, trustworthy, agentic

---

## 1. Design Objective

ApplyX should feel like a serious AI product rather than a generic chatbot.

The visual identity should communicate:

- intelligence;
- control;
- transparency;
- progress;
- trust;
- career/productivity orientation.

Avoid:

- excessive neon/cyberpunk styling;
- generic ChatGPT clones;
- overcrowded dashboards;
- constant chat bubbles;
- meaningless AI animations.

---

## 2. Recommended Visual Direction

### Theme

Primary launch theme: **dark-first with a clean professional light theme available later**.

### Suggested palette tokens

Do not hard-code these into random widgets; create design variables/tokens in Figma and matching Flutter constants.

```text
Background / Ink:
#0B1020

Surface:
#12192B

Surface Elevated:
#182137

Primary:
#7C5CFF

Secondary / Accent:
#3DD6C6

Text Primary:
#F7F8FC

Text Secondary:
#A9B2C7

Success:
#37C978

Warning:
#F5B940

Error:
#F15B67

Border:
#27324A
```

These are **starting tokens**, not a mandatory final palette. Refine them in Figma after visual review.

---

## 3. Typography

Preferred direction:

- modern sans-serif;
- highly readable;
- strong numeric hierarchy;
- 2–3 weights used consistently.

Example scale:

```text
Display       32 / Bold
H1            26 / Bold
H2            22 / Semibold
H3            18 / Semibold
Body          16 / Regular
Body Small    14 / Regular
Caption       12 / Medium
Button        14–16 / Semibold
```

Use platform-appropriate font fallbacks in Flutter.

---

## 4. Spacing System

Base unit: 4px.

```text
4   xs
8   sm
12  md-sm
16  md
20  lg-sm
24  lg
32  xl
40  xxl
48  section
```

Avoid arbitrary values like 13, 17, 21 unless a design requirement justifies them.

---

## 5. Radius System

```text
8px   small controls
12px  fields/cards
16px  major cards
24px  modal/sheet emphasis
999px pill/chip
```

---

## 6. Core Screens

### 6.1 Splash

Purpose: brand recognition, not a loading dashboard.

Elements:

- ApplyX logo;
- subtle background treatment;
- short loading state only when necessary.

---

### 6.2 Onboarding

3 short visual steps:

1. Define your goal.
2. Let your agents do the research.
3. Review and approve actions.

CTA:

**Get Started**

---

### 6.3 Authentication

Screens:

- Login
- Create Account
- Forgot Password
- Verification

Keep auth visually calm and simple.

---

### 6.4 Home Dashboard

Core hierarchy:

```text
Greeting
 ↓
Active Goal / Quick Create
 ↓
Agent Status
 ↓
Top Opportunities
 ↓
Application Deadlines
```

Do not make the dashboard look like a spreadsheet.

---

### 6.5 Create Goal

Hero copy:

> What are you trying to achieve?

Input can be a large text field.

Examples as chips:

- Find an internship
- Find research opportunities
- Prepare for hackathons

CTA:

**Start Agent**

---

### 6.6 Agent Activity

This is the signature screen.

Show an execution timeline:

```text
Goal received             ✓
Plan created              ✓
Searching opportunities   ✓
Checking eligibility     ●
Comparing your profile   ○
Preparing documents      ○
Verification             ○
```

Each step should be expandable for detail.

Important: animation should reflect real agent state, not fake progress.

---

### 6.7 Agent Result

Top section:

- goal;
- status;
- concise summary.

Then result groups:

```text
Recommended
Needs Review
Not Enough Evidence
```

Each opportunity card:

```text
Title
Organization
Remote / Location
Deadline
Why it matches
Missing requirements
Source
Save
```

---

### 6.8 Opportunity Detail

Sections:

- Overview
- Requirements
- Why this matches
- Missing requirements
- Source/evidence
- Deadline
- Actions

Primary CTA:

**Prepare Application**

---

### 6.9 Application Workspace

Tabs/sections:

- Resume
- Cover Letter
- Questions
- Checklist

The agent-generated content should always be editable.

---

### 6.10 Approval Screen

This is a critical trust screen.

Show:

```text
Agent wants to:
Submit application to XYZ

Target:
XYZ Internship Program

Generated content:
[preview]

Risk:
External submission

[Approve]
[Reject]
```

Approval should never be a hidden modal triggered after a confusing action.

---

### 6.11 Application Tracker

Use timeline/status chips instead of only tables.

Example:

```text
XYZ Internship
Ready for review
Deadline in 3 days

ABC Research
Submitted
Follow-up next week
```

---

### 6.12 Profile

Sections:

- About
- Skills
- Education
- Experience
- Projects
- Links
- Documents

Show profile completeness without gamifying it excessively.

---

### 6.13 Settings

Sections:

- Notifications
- AI preferences
- Privacy
- Connected accounts
- Data export/delete
- About

---

## 7. Signature Components

Build these as reusable Figma components and Flutter widgets:

- PrimaryButton
- SecondaryButton
- Glass/SurfaceCard
- StatusChip
- AgentStep
- AgentTimeline
- OpportunityCard
- MatchReasonRow
- EvidenceRow
- ApprovalCard
- DocumentPreview
- DeadlineRow
- EmptyState
- ErrorState
- LoadingSkeleton
- BottomSheetAction

---

## 8. Agent Visual Language

Agent status should be consistent everywhere.

```text
Queued       ○
Running      ◌ animated
Completed    ✓
Needs Input  !
Approval     ◆
Failed       ×
Cancelled    –
```

Do not rely only on color; pair icon + text + state.

---

## 9. Figma File Structure

Recommended Figma pages:

```text
00 — Cover & Notes
01 — Foundations
02 — Components
03 — Auth
04 — Onboarding
05 — Core Flows
06 — Agent System
07 — Opportunities
08 — Applications
09 — Profile & Settings
10 — Prototype
11 — Flutter Handoff
```

---

## 10. Figma Foundations Setup

Create variables/tokens for:

### Color

- background;
- surface;
- elevated surface;
- primary;
- secondary;
- text;
- border;
- success/warning/error.

### Spacing

4, 8, 12, 16, 20, 24, 32, 40, 48.

### Radius

8, 12, 16, 24, 999.

### Typography

Define text styles instead of manually formatting every layer.

---

## 11. Figma Component Rules

Create variants for state instead of duplicate components.

Example:

```text
Button
 ├── Type: Primary / Secondary / Ghost
 ├── Size: Small / Medium / Large
 └── State: Default / Pressed / Disabled / Loading
```

Agent Step:

```text
State: Queued / Running / Completed / Failed / Approval
```

Opportunity Card:

```text
Mode: Compact / Expanded
Saved: Yes / No
Match: Strong / Review / Unknown
```

---

## 12. How to Use Figma Make for This Project

### Step 1 — Create a new Figma file

Create the project manually in Figma first.

Create the pages listed above.

### Step 2 — Define the visual direction

Before asking Figma Make for screens, define:

- target platform: mobile;
- dark-first;
- typography direction;
- token palette;
- spacing system;
- app personality;
- target user;
- screen list.

### Step 3 — Generate the first system in Figma Make

Use a prompt like:

> Design a premium dark-first mobile UI system for ApplyX, an agentic AI career opportunity assistant. The experience should feel trustworthy, intelligent and minimal rather than cyberpunk or chatbot-like. Create reusable mobile components for buttons, text fields, status chips, cards, agent timeline steps, opportunity cards, evidence rows, approval cards, document previews, deadline rows, loading states and empty/error states. Use a 4px spacing system, consistent corner radii, strong accessibility contrast and clear visual hierarchy. Use an accent color sparingly. Focus on real product UI, not marketing landing pages.

### Step 4 — Generate screens in batches

Do not ask for all screens in one giant prompt.

Batch A:

```text
Onboarding
Login
Signup
Home
```

Batch B:

```text
Create Goal
Agent Activity
Agent Result
```

Batch C:

```text
Opportunity Detail
Application Workspace
Approval
```

Batch D:

```text
Application Tracker
Profile
Settings
```

This keeps consistency easier to review.

### Step 5 — Refine manually

After generation:

- align spacing;
- fix typography;
- normalize card geometry;
- remove unnecessary decoration;
- verify CTA hierarchy;
- add loading/empty/error states;
- convert repeated elements to components;
- apply variables/tokens.

### Step 6 — Prototype the core journey

The minimum prototype should be:

```text
Home
 ↓
Create Goal
 ↓
Agent Activity
 ↓
Results
 ↓
Opportunity Detail
 ↓
Prepare Application
 ↓
Approval
```

The prototype should make the agent workflow understandable before any Flutter code is written.

---

## 13. How to Translate Figma to Flutter

Use Figma as visual reference, not as a source of giant generated Flutter code.

Recommended process:

```text
Figma components
 ↓
Map to Flutter design tokens
 ↓
Build reusable widgets
 ↓
Implement feature screen
 ↓
Compare with Figma
 ↓
Refine spacing/typography
```

Flutter token examples:

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
```

Keep tokens in a central theme/core folder.

---

## 14. Flutter Handoff Checklist

For every screen:

```text
[ ] Figma frame exists
[ ] Mobile dimensions defined
[ ] Components mapped
[ ] States documented
[ ] Loading state defined
[ ] Error state defined
[ ] Empty state defined
[ ] Navigation action defined
[ ] Analytics events defined if needed
[ ] Accessibility reviewed
```

---

## 15. Design Review Checklist

Before implementation is considered ready:

- Does the user know what to do next?
- Is the agent state understandable without reading technical logs?
- Can uncertainty be seen?
- Can a user reverse/cancel safe actions where appropriate?
- Are source/evidence details easy to access?
- Is the approval interaction unmistakable?
- Does the design remain usable on smaller screens?
- Are loading and failure states coherent?

---

## 16. Anti-Patterns to Avoid

### Chatbox as entire product

A chat input is not the product. Use structured screens and workflows.

### Fake agent animation

Never show a fake 0–100% progress bar if actual task state is unknown.

### Too many cards

Cards should group meaningful information, not every sentence.

### Random AI visual effects

Do not add glowing borders or particle effects just to signal AI.

### Hidden approvals

External actions must have a visible approval gate.

---

## 17. Design Definition of Done

The design phase is complete when:

1. Foundation tokens exist.
2. Core components exist.
3. All MVP screens are designed.
4. All important states are designed.
5. Core prototype path works.
6. Mobile layouts have been checked.
7. Flutter implementation mapping is documented.


---

# 14. FINALIZED FIGMA DESIGN — APPROVED SOURCE OF TRUTH

**Status:** Finalized for MVP implementation

**Figma file:** https://www.figma.com/design/JieODpDKxzoEqOEgXOTRuj

**Figma file name:** `ApplyX — Agentic Opportunity App`

The Figma file contains the approved mobile UI frames for the MVP. Antigravity/Codex should treat this Figma file together with this document as the visual source of truth. Do not invent a different visual language unless explicitly requested.

### Final visual direction

- Product: ApplyX — Agentic Opportunity App
- Platform: mobile-first Flutter
- Primary mode: dark-first
- Visual tone: premium, calm, intelligent, trustworthy
- Layout: spacious, card-based, strong hierarchy
- Accent: purple primary with cyan AI-state accent
- Agent states: cyan = active, green = completed, amber = human approval, muted = queued
- Human approval must always be visually distinct from autonomous agent execution.
- Avoid generic chatbot UI, excessive gradients, excessive glassmorphism, cyberpunk/neon styling, and fake agent progress.

### Final color tokens

```text
Background       #0B0F14
Surface          #121821
Surface Elevated #18212C
Primary          #7C5CFC
AI Accent        #39D9FF
Success          #4ADE80
Warning          #FBBF24
Danger           #FB7185
Primary Text     #F5F7FA
Secondary Text   #9AA7B5
Border           #263241
```

### Final typography

```text
Display      34 / Extra Bold
H1           30 / Bold
H2           26 / Bold
H3           20 / Semi Bold
Body         16 / Regular
Body Small   14 / Regular
Caption      12 / Regular
Button       15 / Semi Bold
```

### Final spacing / shape rules

```text
Base spacing: 4px
Preferred: 4 / 8 / 12 / 16 / 24 / 32 / 48px
Small radius: 8px
Control radius: 12–14px
Major card radius: 18px
Large sheet/modal radius: 24px
Pill: 999px
Primary button height: 52px
```

### Final MVP screens in Figma

1. `Splash` — brand introduction
2. `Onboarding` — value proposition and first CTA
3. `Home` — greeting, agent status, active goal, applications
4. `Create Goal` — natural-language goal input and agent start
5. `Agent Activity` — real execution timeline and state visibility
6. `Results` — matched opportunities with fit and source information
7. `Opportunity Detail` — requirements, match explanation, missing evidence
8. `Approval` — explicit human approval before external action
9. `Tracker` — application lifecycle/status timeline
10. `Profile` — skills, preferences, documents

### Final reusable components

The Flutter implementation should create reusable equivalents of these Figma concepts:

```text
PrimaryButton
SecondaryButton
SurfaceCard
StatusChip
AgentStep
OpportunityCard
ApprovalPanel
ApplicationTimeline
ProfileSection
```

### Agent activity visual contract

The `Agent Activity` screen is the signature ApplyX interaction. It must reflect actual backend/agent state. Never animate a step as completed before the backend reports it completed. Recommended state mapping:

```text
queued          → muted
running         → cyan
completed       → green
waiting_approval → amber
failed          → danger
cancelled       → muted/secondary
```

### Approval visual contract

Any operation that could affect an external service, submit an application, send a message, or otherwise create an external side effect must enter a visible approval state. The approval screen must show:

- intended action;
- target;
- generated content/changes;
- relevant risk or side-effect;
- `Approve & continue`;
- `Review first` / `Reject`.

### Figma → Flutter handoff procedure

Antigravity must follow this order:

1. Read `PRD.md`, `architecture.md`, `rules.md`, `AGENT_SPEC.md`, `API_SPEC.md`, `task.md`, and this file.
2. Open the approved Figma file above.
3. Inspect the relevant Figma screen before implementing it.
4. Reuse the defined tokens rather than inventing new colors, radii, or spacing.
5. Build shared Flutter components first.
6. Implement screens in the exact MVP order above.
7. Match the Figma layout, hierarchy, text scale, states, and spacing.
8. If a design detail is ambiguous, preserve the existing system and choose the smallest consistent implementation; do not redesign the screen.
9. After implementation, compare Flutter screenshots against the Figma frames and fix visual differences.

### Figma maintenance rule

If the UI is intentionally changed during development, update the Figma source of truth and then update this section of `design.md`. Do not allow Figma, `design.md`, and Flutter to silently diverge.

### Direct instruction for Antigravity

> **IMPORTANT:** The Figma file linked in this document is the approved visual source of truth for ApplyX MVP. Do not create a new visual style. Implement the existing screens and tokens faithfully in Flutter. If a screen is missing a small implementation detail, infer it from neighboring components and the design system rather than redesigning the product.
