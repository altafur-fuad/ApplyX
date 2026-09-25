# ApplyX — Product Requirements Document (PRD)

**Project:** ApplyX
**Document:** Product Requirements Document
**Version:** 1.0.0
**Status:** Development Specification
**Primary Platform:** Android + iOS (Flutter)
**Backend:** Supabase + FastAPI
**AI:** Agentic AI orchestration with tool calling and human approval

---

## 1. Product Vision

ApplyX is an agentic opportunity-management mobile app for students and early-career users. The app turns a high-level career goal into a structured workflow: discover relevant opportunities, evaluate eligibility, compare them against the user's profile, prepare application materials, verify generated information, and present action-ready tasks for user approval.

ApplyX is **not** a generic chatbot and is **not** intended to blindly auto-submit applications. Its core value is an autonomous, observable, tool-using workflow with explicit human approval for consequential actions.

### Example user goal

> "I am a CSE student with Flutter, Python and ML skills. Find suitable internships and prepare the applications for me."

The agent should convert this into a plan, execute research and analysis tasks, create artifacts, and return a concise set of next actions.

---

## 2. Problem Statement

Students commonly search for opportunities across multiple sources, manually verify eligibility, compare requirements, tailor CVs and cover letters, remember deadlines, and track application status in separate places.

This fragmented workflow creates:

- repetitive manual research;
- missed deadlines;
- poor matching between profile and opportunities;
- generic application documents;
- weak visibility into what the AI actually did;
- difficulty recovering from failed or incomplete tasks.

ApplyX consolidates this workflow into one mobile-first agentic system.

---

## 3. Target Users

### Primary user

University students and recent graduates seeking:

- internships;
- entry-level jobs;
- hackathons;
- research opportunities;
- fellowships/programs;
- competitions.

### Initial persona

A Bangladesh-based CSE student who knows Flutter, Python and ML, has projects/GitHub work, and wants relevant opportunities without spending hours manually searching.

### Secondary users

Future versions may support career coaches, university career offices and student communities.

---

## 4. Product Goals

1. Convert a natural-language career goal into an executable agent plan.
2. Find and normalize relevant opportunities.
3. Explain why an opportunity matches or does not match the user's profile.
4. Identify missing requirements and blockers.
5. Generate application-ready artifacts.
6. Keep users in control of external or consequential actions.
7. Make agent activity observable and understandable.
8. Maintain a reliable application/deadline tracker.

---

## 5. Non-Goals for MVP

The first release should **not** attempt to:

- fully automate every external website application;
- scrape websites in ways that violate terms or access controls;
- guarantee opportunity eligibility;
- claim that AI-generated information is factual without verification;
- send external emails or submit applications without explicit approval;
- become a general-purpose autonomous assistant.

---

## 6. Core User Journey

```text
Install
  ↓
Onboarding
  ↓
Create Profile
  ↓
Create Goal
  ↓
Agent Plans Work
  ↓
Research Opportunities
  ↓
Eligibility Analysis
  ↓
Profile Fit Analysis
  ↓
Prepare Documents
  ↓
Verify Results
  ↓
User Reviews
  ↓
Approve / Reject Actions
  ↓
Track Applications
  ↓
Deadline / Follow-up Reminders
```

---

## 7. MVP Features

### 7.1 Authentication

- Email/password authentication.
- Optional Google/Apple sign-in where supported.
- Email verification.
- Session persistence.
- Sign out.
- Account deletion.

### 7.2 Onboarding

Collect only information required to deliver the product:

- name;
- education level;
- field/department;
- skills;
- experience level;
- location preference;
- work preference (remote/on-site/hybrid);
- opportunity types;
- CV/resume (optional in initial onboarding).

### 7.3 Profile

Users can maintain:

- headline;
- bio;
- skills;
- projects;
- education;
- experience;
- links (GitHub, LinkedIn, portfolio);
- resume versions;
- preferences.

### 7.4 Goal Creation

The user enters a natural-language goal.

Example:

> "Find paid remote Flutter internships suitable for a final-year CSE student."

The system extracts structured constraints but preserves the original user goal.

### 7.5 Agent Run

A run contains:

- goal;
- plan;
- tasks;
- tool calls;
- intermediate state;
- results;
- verification state;
- approval requests;
- final summary.

### 7.6 Opportunity Discovery

The research layer may query approved/available data sources and APIs.

Opportunity record should include:

- title;
- organization;
- opportunity type;
- location;
- remote status;
- deadline;
- source URL;
- description;
- requirements;
- compensation if explicitly available;
- freshness timestamp;
- source reliability metadata.

### 7.7 Eligibility Analysis

The agent should classify each opportunity into:

- likely eligible;
- partially eligible / needs review;
- likely not eligible;
- insufficient evidence.

The UI must distinguish **source facts** from **AI interpretation**.

### 7.8 Profile Fit

The system compares:

- required skills;
- preferred skills;
- education requirements;
- experience requirements;
- location/work preference;
- project relevance.

The system should provide reasons, not just a numeric match value.

### 7.9 Application Preparation

The agent can draft:

- tailored resume bullets;
- cover letter;
- short-answer responses;
- portfolio summary;
- project descriptions.

All generated artifacts should be editable by the user.

### 7.10 Human Approval

Actions that create external consequences must require explicit approval.

Examples:

- submit application;
- send external email;
- publish content;
- delete user data.

### 7.11 Application Tracker

Statuses:

```text
saved
preparing
ready_for_review
submitted
under_review
interview
rejected
offer
withdrawn
```

### 7.12 Notifications

MVP notifications:

- application deadline approaching;
- agent completed;
- approval required;
- agent failed and needs attention.

---

## 8. Agentic AI Requirements

### 8.1 Agent workflow

```text
Goal
 ↓
Planner
 ↓
Task Graph
 ↓
Tool Execution
 ↓
Observation
 ↓
Reasoning/Decision
 ↓
Artifact Generation
 ↓
Verification
 ↓
Approval Gate
 ↓
Action / Completion
```

### 8.2 Specialist agents

**Planner Agent**
- decomposes goals into tasks;
- chooses appropriate workflow.

**Research Agent**
- gathers opportunity data;
- records sources and timestamps.

**Eligibility Agent**
- compares source requirements with profile;
- flags uncertainty.

**Profile Agent**
- identifies relevant skills/projects;
- detects missing information.

**Document Agent**
- drafts application artifacts;
- uses only available user facts unless marked as a suggestion.

**Verification Agent**
- checks claims, fields and source freshness;
- detects missing evidence or contradictions.

**Action Agent**
- prepares or performs approved actions through permitted tools.

### 8.3 Agent states

```text
queued
planning
running
waiting_for_input
waiting_for_approval
completed
failed
cancelled
```

### 8.4 Tool policy

Agents may use only explicitly registered tools. Each tool must have:

- a name;
- purpose;
- input schema;
- output schema;
- permission classification;
- timeout;
- retry policy;
- audit logging.

### 8.5 Human-in-the-loop

No irreversible/consequential action may happen silently.

Every approval request must show:

- exact action;
- target;
- important inputs;
- generated content preview;
- risk/impact notice;
- approve/reject controls.

---

## 9. Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-01 | User can register/login | P0 |
| FR-02 | User can edit profile | P0 |
| FR-03 | User can create natural-language goal | P0 |
| FR-04 | Agent can create a task plan | P0 |
| FR-05 | Agent can research opportunities via approved tools | P0 |
| FR-06 | Agent can analyze eligibility | P0 |
| FR-07 | Agent can generate editable documents | P0 |
| FR-08 | Agent verifies output before finalizing | P0 |
| FR-09 | User can approve/reject consequential actions | P0 |
| FR-10 | User can track applications | P0 |
| FR-11 | User receives deadline/approval notifications | P1 |
| FR-12 | User can delete account and associated data | P0 |
| FR-13 | Agent failures are recoverable and visible | P0 |
| FR-14 | All important agent actions are auditable | P0 |

---

## 10. Non-Functional Requirements

### Performance

- Fast perceived startup.
- Paginated lists.
- Optimized images.
- Agent progress should stream/poll without blocking the UI.

### Reliability

- Agent runs must survive transient API failures where possible.
- Idempotent actions where applicable.
- Retry with backoff for safe operations.

### Security

- Never expose privileged backend keys in Flutter.
- Use Supabase Row Level Security.
- Validate backend input.
- Store secrets only in server-side environment variables.
- Encrypt sensitive transport/storage where supported.

### Privacy

- Minimize data collection.
- Clearly disclose AI/third-party processing.
- Provide deletion workflow.
- Provide privacy policy.

### Accessibility

- readable text sizes;
- semantic labels;
- sufficient contrast;
- touch targets suitable for mobile;
- do not rely on color alone.

---

## 11. UX Principles

1. **Clarity over decoration.**
2. **Agent activity must be visible.**
3. **Never hide uncertainty.**
4. **User remains in control.**
5. **Every screen needs a clear next action.**
6. **Do not overuse chat UI.**
7. **Show evidence/source next to important claims.**
8. **Use progressive disclosure for technical agent details.**

---

## 12. Success Metrics

MVP metrics:

- onboarding completion rate;
- goals created per active user;
- agent run completion rate;
- opportunity-to-saved rate;
- application preparation completion;
- approval conversion;
- deadline reminder engagement;
- agent failure rate;
- average time from goal to actionable result.

Do not optimize solely for total AI messages. Optimize for successful real-world outcomes.

---

## 13. Future Roadmap

### V1.1

- calendar integration;
- richer reminders;
- improved opportunity source coverage;
- document versioning.

### V1.2

- GitHub profile analysis;
- portfolio gap detection;
- richer research opportunities.

### V2

- approved email integration;
- external application assistance where permitted;
- collaborative mentor/coaching workflows;
- advanced analytics.

---

## 14. MVP Definition of Done

The MVP is complete when a new user can:

1. create an account;
2. complete profile;
3. state a career/opportunity goal;
4. start an agent run;
5. see the agent plan and progress;
6. receive opportunity results with source evidence;
7. review eligibility and fit reasoning;
8. generate editable application material;
9. approve/reject a consequential action;
10. save and track an application;
11. receive a relevant reminder;
12. delete the account.

---

## 15. Product Guardrails

ApplyX must never present AI interpretation as guaranteed fact. Opportunity details can change. Whenever possible, surface source URL and source freshness. The app must not encourage deception, fabrication of qualifications, or submission of false information.

---
