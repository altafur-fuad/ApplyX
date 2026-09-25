# ApplyX — Master Task Plan

**Version:** 1.0.0
**Status:** Ready for Execution

Use this file as the project execution checklist. Complete tasks in order unless a dependency explicitly allows parallel work.

---

## Phase 0 — Project Initialization

- [ ] Confirm product name: ApplyX
- [ ] Create GitHub repository
- [ ] Create Flutter project
- [ ] Choose state-management solution
- [ ] Define package/bundle identifier
- [ ] Create `PRD.md`, `architecture.md`, `rules.md`, `design.md`, `task.md`, `memory.md`
- [ ] Create `.gitignore`
- [ ] Create `.env.example`
- [ ] Configure base README

**Exit criteria:** project runs on a local Android emulator/device.

---

## Phase 1 — Product & UX

- [ ] Validate MVP scope
- [ ] Confirm user journey
- [ ] Define MVP navigation
- [ ] Create Figma file
- [ ] Create Figma pages
- [ ] Define color/typography/spacing/radius tokens
- [ ] Build core components
- [ ] Design onboarding
- [ ] Design auth
- [ ] Design home
- [ ] Design goal creation
- [ ] Design agent activity
- [ ] Design results
- [ ] Design opportunity detail
- [ ] Design application workspace
- [ ] Design approval flow
- [ ] Design tracker
- [ ] Design profile/settings
- [ ] Add loading/error/empty states
- [ ] Build Figma prototype of the primary journey

**Exit criteria:** Figma prototype demonstrates the core user journey end-to-end.

---

## Phase 2 — Supabase Foundation

- [ ] Create development Supabase project
- [ ] Configure Auth
- [ ] Create profiles table
- [ ] Create goals table
- [ ] Create opportunities table
- [ ] Create opportunity_matches table
- [ ] Create applications table
- [ ] Create documents table
- [ ] Create agent_runs table
- [ ] Create agent_tasks table
- [ ] Create tool_calls table
- [ ] Create approvals table
- [ ] Create notifications table
- [ ] Add timestamps and indexes
- [ ] Configure Row Level Security
- [ ] Test ownership policies
- [ ] Create storage buckets only when required

**Exit criteria:** authenticated test user can safely CRUD allowed resources.

---

## Phase 3 — Flutter Foundation

- [ ] Add app theme
- [ ] Add design tokens
- [ ] Add router/navigation
- [ ] Add error handling foundation
- [ ] Add network client
- [ ] Add Supabase client
- [ ] Add secure local session handling
- [ ] Build reusable button/input/card components
- [ ] Build loading/empty/error components

**Exit criteria:** design system and navigation foundation are stable.

---

## Phase 4 — Authentication

- [ ] Login
- [ ] Signup
- [ ] Logout
- [ ] Session restore
- [ ] Verification flow
- [ ] Forgot password
- [ ] Delete account
- [ ] Auth error states

**Exit criteria:** user can complete the full authentication lifecycle.

---

## Phase 5 — Profile & Goals

- [ ] Onboarding flow
- [ ] Profile editor
- [ ] Skills editor
- [ ] Education editor
- [ ] Projects editor
- [ ] External links
- [ ] Goal creation
- [ ] Goal list
- [ ] Goal detail

**Exit criteria:** user profile and natural-language goals persist correctly.

---

## Phase 6 — FastAPI Backend

- [ ] Create FastAPI project
- [ ] Environment configuration
- [ ] Authentication middleware
- [ ] Error response model
- [ ] Goal endpoints
- [ ] Agent run endpoints
- [ ] Opportunity endpoints
- [ ] Document endpoints
- [ ] Application endpoints
- [ ] Approval endpoints
- [ ] Logging
- [ ] Timeouts
- [ ] Rate limiting strategy

**Exit criteria:** Flutter can securely communicate with staging backend.

---

## Phase 7 — Agent Core

- [ ] Define agent state model
- [ ] Define task schema
- [ ] Define tool schema
- [ ] Build tool registry
- [ ] Build planner agent
- [ ] Build research agent
- [ ] Build eligibility agent
- [ ] Build profile-fit agent
- [ ] Build document agent
- [ ] Build verification agent
- [ ] Build action agent
- [ ] Persist agent run state
- [ ] Persist task state
- [ ] Add retry policy
- [ ] Add cancellation
- [ ] Add timeout handling
- [ ] Add audit logging

**Exit criteria:** one complete agent run works from goal to verified result.

---

## Phase 8 — Opportunity Pipeline

- [ ] Choose approved data sources
- [ ] Build source connectors
- [ ] Normalize opportunity schema
- [ ] Store source URL
- [ ] Store fetched timestamp
- [ ] Deduplicate records
- [ ] Parse requirements
- [ ] Map opportunities to profile
- [ ] Build result ranking/explanation logic without hiding uncertainty

**Exit criteria:** user receives useful, source-backed opportunity results.

---

## Phase 9 — Application Preparation

- [ ] Generate resume bullets
- [ ] Generate cover letter
- [ ] Generate short-answer drafts
- [ ] Add editing experience
- [ ] Save document versions
- [ ] Attach documents to applications
- [ ] Build application checklist

**Exit criteria:** user can produce and edit a complete application package.

---

## Phase 10 — Human Approval

- [ ] Create approval data model
- [ ] Build approval API
- [ ] Build approval UI
- [ ] Show exact action/target
- [ ] Show content preview
- [ ] Enforce approval server-side
- [ ] Add approve/reject state
- [ ] Prevent duplicate actions
- [ ] Audit approval events

**Exit criteria:** no consequential external action can execute without explicit approval.

---

## Phase 11 — Notifications

- [ ] Push notification foundation
- [ ] Agent completion notification
- [ ] Approval notification
- [ ] Deadline notification
- [ ] Deep links
- [ ] Notification preferences

**Exit criteria:** notifications lead to the correct in-app context.

---

## Phase 12 — Testing

### Flutter

- [ ] Unit tests
- [ ] Widget tests
- [ ] Integration tests
- [ ] Navigation tests

### Backend

- [ ] API tests
- [ ] Auth tests
- [ ] RLS/security tests
- [ ] Agent workflow tests
- [ ] Tool failure tests
- [ ] Approval tests

### Manual

- [ ] Android physical device
- [ ] Small screen
- [ ] Large screen
- [ ] Slow network
- [ ] Offline behavior
- [ ] App restart during agent run
- [ ] Expired session
- [ ] Large document upload

**Exit criteria:** release candidate has no known P0/P1 blocker.

---

## Phase 13 — Security & Privacy

- [ ] Remove secrets from client
- [ ] Verify environment variables
- [ ] Verify RLS
- [ ] Audit logs for sensitive content
- [ ] Upload validation
- [ ] Privacy policy
- [ ] Terms if needed
- [ ] Account deletion
- [ ] Data export/delete workflow
- [ ] Review AI vendor data processing
- [ ] Review permissions

**Exit criteria:** privacy/security checklist approved for release.

---

## Phase 14 — Production Infrastructure

- [ ] Create production Supabase project
- [ ] Create production backend
- [ ] Configure production domain/API
- [ ] Configure production secrets
- [ ] Configure monitoring
- [ ] Configure crash/error tracking
- [ ] Configure backups/recovery plan
- [ ] Verify staging ≠ production

**Exit criteria:** production infrastructure is isolated and tested.

---

## Phase 15 — Android Release

- [ ] Confirm application ID
- [ ] Configure release signing
- [ ] Protect signing credentials
- [ ] Verify target/compile API requirements
- [ ] Build release AAB
- [ ] Test release build
- [ ] Prepare store icon
- [ ] Prepare screenshots
- [ ] Write title/description
- [ ] Prepare privacy URL
- [ ] Complete Data Safety declaration
- [ ] Complete content rating
- [ ] Provide reviewer/demo access if login is required
- [ ] Upload to Play Console
- [ ] Run required testing track
- [ ] Fix review/test issues
- [ ] Submit production release

**Exit criteria:** production Android app is live.

---

## Phase 16 — iOS Release

- [ ] Join Apple Developer Program
- [ ] Configure Apple App ID/Bundle ID
- [ ] Configure signing
- [ ] Create App Store Connect app record
- [ ] Configure app metadata
- [ ] Prepare screenshots
- [ ] Complete App Privacy
- [ ] Add privacy policy URL
- [ ] Upload release build
- [ ] Test with TestFlight
- [ ] Provide review/demo access
- [ ] Submit App Review
- [ ] Fix review issues if any
- [ ] Release to App Store

**Exit criteria:** production iOS app is live.

---

## Phase 17 — Post-Launch

- [ ] Monitor crashes
- [ ] Monitor API/agent failures
- [ ] Monitor usage metrics
- [ ] Monitor AI cost
- [ ] Collect user feedback
- [ ] Create bug backlog
- [ ] Prioritize next release
- [ ] Update changelog
- [ ] Maintain store metadata
- [ ] Maintain OS/API compatibility

---

## Definition of Ready for Release

```text
[ ] Core journey works
[ ] No P0/P1 blockers
[ ] Security reviewed
[ ] Privacy reviewed
[ ] Store metadata complete
[ ] Release builds tested
[ ] Backend production-ready
[ ] Monitoring active
[ ] Support contact active
[ ] Rollback/mitigation plan understood
```

---

## Current Sprint

When work begins, add a sprint header here:

```text
Sprint:
Goal:
Start:
End:
Owner:

Tasks:
- [ ] ...
```

---

## Phase 0A — Project Documentation & Contracts

- [ ] Review `README.md`
- [ ] Review `API_SPEC.md`
- [ ] Review `AGENT_SPEC.md`
- [ ] Review `database.sql`
- [ ] Review `folder-structure.md`
- [ ] Review `DEPLOYMENT.md`
- [ ] Configure `.env.example`
- [ ] Create real environment files outside Git
- [ ] Convert `database.sql` into tracked Supabase migrations before production

**Exit criteria:** a new developer can clone the repository, understand the architecture, configure local services, and identify the first implementation slice without guessing core contracts.
