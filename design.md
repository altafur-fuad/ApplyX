# ApplyX — Master Design System (design.md)

**Version:** 2.0.0 (Master UI Redesign)
**Platform:** Flutter (Mobile-First)

## Sources of Truth
*   **REFERENCE IMAGE** = VISUAL INSPIRATION
*   **PRD** = PRODUCT SOURCE OF TRUTH
*   **ARCHITECTURE** = TECHNICAL SOURCE OF TRUTH

## 1. Design Philosophy
ApplyX is a personal, intelligent career command center. It turns high-level career goals into a structured, observable workflow. The design must feel intelligent, calm, premium, warm, trustworthy, modern, slightly futuristic, human-centered, and purposeful. It must NOT look like a generic corporate app, a template-generated SaaS dashboard, a basic job board, or a chatbot.

## 2. Visual Identity
The visual language is derived from a specific reference image. It uses warm cream backgrounds, golden-yellow to soft-peach gradients, organic flowing wave shapes, and soft glass cards. The interface should breathe with premium whitespace, utilizing soft shadows and elegant typography.

## 3. Color Palette
The color palette is controlled and warm. Avoid neon colors, generic SaaS purple/blue gradients, extremely saturated colors, pure black backgrounds, and pure white everywhere.

*   **Background / Cream (Primary):** `#FFF9E8`, `#FFF6DC`, `#FFF3D2`
*   **Warm Yellow:** `#FFD76A`, `#F7C95E`
*   **Golden Orange:** `#F2B65D`, `#EFAE58`
*   **Soft Peach:** `#F3C29B`
*   **Primary Text (Warm Brown):** `#5A4635`, `#6B5542`
*   **Secondary Text (Muted):** `#9A8875`
*   **Accent/Focus:** Warm golden or peach accents.
*   **Success:** Soft, natural green (ensure readability).
*   **Warning:** Golden orange (reusing the palette).
*   **Error:** Soft, muted red/coral.

## 4. Gradient System
Gradients are soft, organic, premium, subtle, and intentional. Do not make every component a gradient.

*   **Primary Gradient Flow:** Cream → Warm Yellow → Golden Orange → Soft Peach.
*   **Usage:** Hero backgrounds, onboarding backgrounds, decorative organic shapes, active states, important CTA areas, agent activity highlights, match score emphasis, and selected navigation states.

## 5. Typography
Clean, editorial, premium, and highly readable.
*   **Hierarchy:**
    *   **Large:** Screen/hero titles.
    *   **Medium:** Section titles.
    *   **Small:** Supporting information.
*   **Color:** Warm dark brown (`#5A4635` or `#6B5542`) for primary text.
*   **Rules:** Avoid overly thin typography, excessive font sizes, and making everything bold. Maintain strong visual hierarchy.

## 6. Spacing System
Use a structured grid, allowing the UI to breathe. Combine open layouts with premium whitespace.
*   4px, 8px, 12px, 16px, 24px, 32px, 48px.

## 7. Border Radius
*   **Moderate Radius:** Avoid excessive pill shapes or overly sharp corners.
*   **Cards/Surfaces:** ~16px - 24px.
*   **Buttons:** Moderate radius (e.g., 12px - 16px).

## 8. Shadows
*   **Soft Shadows:** Used to create subtle depth, particularly for GlassCards and primary buttons. Avoid harsh, dark, or generic Material shadows.

## 9. Glass System
A reusable `GlassCard` or glass surface system to create depth.
*   **Characteristics:** Semi-transparent warm/cream background, subtle transparency, subtle border, soft shadow, moderate corner radius, optional blur, and background gradient visibility through the surface.
*   **Usage:** Open layouts, floating information. Do NOT make every element a glass card (avoid stacked generic cards).

## 10. Organic Shape System
Flowing organic shapes are used primarily as background decoration.
*   **Characteristics:** Flowing curves, organic waves, soft blobs, layered curved ribbons, subtle gradient shapes.
*   **Locations:** Onboarding, authentication, hero sections, empty states, major agent sections.
*   **Rules:** Must remain behind content, must not reduce readability, must be an ApplyX-specific interpretation (not a direct copy).

## 11. Buttons
*   **Primary Button:** Premium and important. Warm golden gradient, cream surface, warm brown text, subtle shadow, moderate radius.
*   **Hierarchy:** Primary, Secondary, Tertiary. Important actions stand out visually. Approval actions must feel deliberate and safe. Avoid giant generic Material buttons.

## 12. Inputs
*   **Characteristics:** Warm cream surface, subtle border, soft focus state, clear label hierarchy, warm accent focus indicator.
*   **Avoid:** Generic default Flutter TextField appearance.

## 13. Cards
*   Use open layouts, large typography, whitespace, and section headers. Combine with the Glass System and Organic Backgrounds. Avoid generic, repetitive card lists.

## 14. Navigation
*   **Bottom Navigation:** Integrated with the visual system. Warm cream surface, subtle glass effect where appropriate. Selected state uses a warm gradient/accent. Minimal icons, clear labels only where useful. Avoid generic Material `BottomNavigationBar` appearance.

## 15. Agent Activity
*   **Visuals:** Timeline/progress visualization. Feel like the agent is actually working.
*   **Elements:** Live status, completed tasks, current task, verification, waiting for approval, needs input. Use gradients and organic shapes to highlight activity.

## 16. Match Score
*   **Visuals:** Visually meaningful match indicators. Large match visualizations on details screens. Elegant and analytical representation.
*   **Usage:** Highlight strengths and gaps clearly.

## 17. Verification
*   **Visuals:** Make verification feel trustworthy. Clear visual distinction between VERIFIED, REVIEW, and UNSUPPORTED. Do not use alarming colors unnecessarily.

## 18. Approval
*   **Visuals:** A high-trust screen. The UI must convey "Nothing happens until I approve it." The approval action must feel deliberate. Emphasize risk, exact action, and verification state.

## 19. Empty States
*   Use organic shapes as background decoration. Keep it calm, with clear next actions.

## 20. Loading States
*   Preserve existing loading logic. Visually integrate with the warm, flowing aesthetic. Avoid generic circular progress indicators where a more integrated skeleton or organic animation fits better.

## 21. Error States
*   Clear, human-centered, and recoverable. Use warm, muted error colors (e.g., coral/peach variants) instead of harsh, alarming reds.

## 22. Accessibility
*   Maintain readable contrast (especially with warm text on warm backgrounds).
*   Sufficient touch targets.
*   Readable typography.
*   Semantic labels where appropriate.
*   Clear status communication (do not rely only on color; use icons/shapes).

## 23. Responsive Behavior
*   Primary target: Android mobile. Optimize for common mobile dimensions.
*   Use `SafeArea`, responsive constraints, flexible layouts, proper scrolling, and `MediaQuery`/`LayoutBuilder`.
*   Avoid hardcoded pixel positions, overflow, tiny text, and clipped content.

## 24. Do / Don't Rules
*   **DO:** Combine open layouts, typography, whitespace, and organic background elements. Ensure human approval feels deliberate. Make it feel like ApplyX.
*   **DON'T:** Copy exact content/branding from the reference. Use neon colors, generic SaaS gradients, or pure black/white everywhere. Make every element a glass card or generic card. Create a generic Material app, SaaS dashboard, job board, or AI chatbot.

## 25. Screen-Specific Rules
1.  **Onboarding:** Tell me your goal. I'll do the legwork. Large open composition, organic gradient shapes, cream background, subtle glass CTA.
2.  **Home:** Personal command center. Greeting, active goal, agent status, pending approval. Hierarchy and whitespace, not just a dashboard of cards.
3.  **Create Goal:** Progressive composition (not a long form). Glass input groups, warm gradient CTA.
4.  **Agent Activity:** Timeline/progress. The agent is actually working.
5.  **Discover:** Match percentage, meaningful match indicators (not generic job cards).
6.  **Opportunity Details:** Analytical but elegant. Large match visualization.
7.  **Verification:** Trustworthy. Distinct states for verified, review, unsupported.
8.  **Approval:** High-trust. Deliberate action.
9.  **Application Tracker:** Timeline/board-inspired. Warm visual indicators (not a generic kanban).
10. **Profile & Documents:** Clean, open layout, selective glass sections.
