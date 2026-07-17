# Antigravity IDE Prompt — Login, Connectivity, Forgot Password, Exam Graph, and Media Playback Fixes

You are working inside the existing Mi Digital Academy project repository.

Your task is to inspect the current codebase, understand the existing architecture, and implement only the changes listed below. Preserve the current technology stack, folder structure, naming conventions, design system, and already-completed fixes.

Do not assume anything silently. If any instruction is unclear, technically unsafe, conflicts with existing behavior, requires a new dependency, changes backend/API/database/auth behavior, affects production configuration, or cannot be verified from the codebase, STOP and ask for confirmation before performing that specific action.

## Core Rules

1. Do not introduce new frameworks, paid services, analytics, tracking, fake data, or unnecessary dependencies.
2. Do not alter unrelated files.
3. Do not remove existing functionality unless explicitly required by the requested changes.
4. Do not duplicate work already completed in previous commits.
5. If a shared component controls multiple platforms, implement the fix once at the shared component level.
6. If platform-specific behavior is required, isolate the fix to that platform.
7. If credentials, secure storage, platform permissions, or backend/API behavior are involved, use the existing project-approved mechanism only.
8. Do not store passwords in plain text.
9. Run relevant tests/checks after implementation.
10. Generate one single unified audit report proving what was changed, tested, and verified.

---

## Required Changes

### 1. Login Username Placeholder

In the login/sign-in section, change the username field placeholder text to exactly:

```text
Enter your Username
```

Make this change wherever the login username field is rendered across applicable platforms/screens in this project.

---

### 2. Incorrect Credentials Toast Message

When login fails specifically because of incorrect credentials, change the toast/error message to exactly:

```text
Oops! We couldn't Sign You In. Please check your Username or Password.
```

Important:
- Use this only for incorrect username/password credential failures.
- Do not show this message for network errors, server timeouts, validation errors, or unrelated login failures.
- Preserve existing error handling for other failure types unless it is currently incorrect or misleading.

---

### 3. Remember Me Functionality

When a user selects **Remember Me**, implement functionality so that the user's login credentials are saved only after the credentials are confirmed as correct.

Requirements:
- Save remembered login details only after successful authentication.
- On future visits/app launches, prefill or restore login details according to the existing UX pattern of the app.
- If the user does not select Remember Me, do not save credentials.
- If the user deselects Remember Me, clear any previously remembered credentials.
- Use the existing project-approved secure storage mechanism if available.
- Do not store passwords in plain text.
- If the project does not currently have a secure storage mechanism suitable for storing login credentials, STOP and ask for confirmation before adding a dependency or changing the security model.
- If the app currently supports token/session persistence instead of credential persistence, inspect the current authentication flow and ask before changing the model.
- Add/update tests for Remember Me behavior where possible.

---

### 4. Sign In Button Height and Text Size

Make the **Sign In** button and its text larger.

Button sizing requirement:
- Do not increase the horizontal width/x-axis size.
- Increase the vertical height/y-axis size only by 50%.
- Preserve existing alignment, margins, responsive behavior, and layout constraints.
- The button should remain visually consistent with the current design system.

Text requirement:
- Increase the Sign In button text size enough to match the larger button height.
- Do not make the text overflow, clip, or break the button layout.
- Preserve existing font family, font weight, and color unless the current style must be adjusted for readability.

Note:
The intended interpretation is: keep button width unchanged and increase only button height by 50%.

---

### 5. Internet Connectivity Toast for Online-Required Actions

When the user loses internet connectivity and tries to access something that requires an active internet connection, display this toast message exactly:

```text
Please connect to the internet to continue learning.
```

Rules:
- Show this message only when there is no active internet connection.
- Show this message only for actions/screens/services that require internet.
- Do not show this message when internet is active.
- Do not show this message when the user is watching videos stored offline.
- Do not show this message for services/features that do not require internet.
- Avoid repeated toast spam. If the user triggers the same offline action repeatedly, use the project’s existing debounce/throttle pattern if one exists.
- Reuse existing connectivity detection utilities/components if present.
- If no reliable connectivity detection mechanism exists, ask before introducing a new dependency or changing the connectivity architecture.

---

### 6. Forgot Password Page Image Loading Animation, Size, and Position

On the Forgot Password page, make the loading animation/image behavior exactly match the Sign In page.

Current issue:
- Forgot Password page image/loading animation is smaller.
- It has white edges/borders on the sides.
- It does not match the Sign In page size/position.

Requirements:
- Reuse the same image/loading animation component, sizing, positioning, clipping, background, and layout behavior used on the Sign In page wherever possible.
- Remove the unwanted white side edges/borders.
- Ensure the Forgot Password page remains responsive and does not create overflow/clipping issues.
- Preserve accessibility and scroll behavior.

---

### 7. Performance Overview — Exam History Performance Trend Graph X-Axis

In the Performance Overview section under Exam History, update the Performance Trend graph x-axis.

Requirements:
- The x-axis should show exam dates.
- Date format must be:

```text
DD/MM
```

- Rotate the x-axis date labels 90 degrees.
- The rotated date labels should read from bottom to top.
- Keep font size, color, and other visual attributes the same as the existing graph labels unless a small layout adjustment is required to prevent clipping.
- Ensure labels do not overlap, cut off, or break chart layout.
- If the graph currently does not receive exam dates from the data model/API, inspect the available data.
- If dates are unavailable from the frontend state/API response, STOP and ask before modifying backend/API/data structures.

---

### 8. Performance Trend Graph Hover Toast Text Colour

In the Performance Trend graph area, ensure that toast/tooltip/hover notification text colour is white.

Requirement:
- On hover over the graph, the notification/tooltip text color must be white only.
- Do not change unrelated tooltip styling unless necessary for readability.
- Preserve existing background, font size, and layout unless a minor adjustment is required to keep the tooltip readable.

---

### 9. Pause Media When Navigating Away

When a user is viewing a video or listening to audio, and the user navigates to any other section/screen away from the actual media playback screen, the media must immediately pause.

Requirements:
- Applies to video playback.
- Applies to audio/podcast playback.
- The media should pause immediately when the user navigates away from the screen where that media is actively playing.
- The media must stay paused unless the user manually resumes playback.
- Do not auto-resume media when returning to the screen.
- Handle app route changes, tab changes, drawer/sidebar navigation, back navigation, and screen disposal/lifecycle events as applicable to this project.
- Clean up media controllers/listeners safely to avoid memory leaks.
- Preserve offline video playback functionality.
- Preserve existing progress tracking/history behavior unless a change is required to pause safely.
- Add/update tests where possible.

---

## Required Implementation Process

### Step 1 — Repository Inspection

Before changing files, inspect:
- project framework and platform targets
- login/sign-in screen files
- authentication service/state management
- Remember Me checkbox/state implementation
- secure storage/session/token handling
- toast/snackbar/error message helpers
- connectivity detection utilities
- Forgot Password screen/component
- Sign In image/loading animation component
- Exam History / Performance Overview graph component
- graph tooltip/hover implementation
- video player implementation
- audio/podcast player implementation
- navigation/router/lifecycle handling
- existing test/lint/build scripts

Also run:

```bash
git status --short
git log --oneline --decorate -n 50
```

Do not modify files during inspection except generated cache cleanup if absolutely required.

---

### Step 2 — Task Mapping Before Implementation

Create an internal checklist mapping each requested change to:
- relevant file(s)
- current behavior found
- implementation approach
- risk level
- whether confirmation is needed

If any item cannot be confidently mapped, STOP and ask for confirmation before implementing that item.

---

### Step 3 — Implementation

Implement only the requested changes.

For every change:
- keep the fix minimal and scoped
- prefer shared utilities/components over duplicated platform-specific code
- preserve existing styles where not explicitly changed
- preserve existing tests
- add/update tests where practical
- do not change unrelated behavior

---

### Step 4 — Verification and Tests

After implementation, run all relevant available checks in the repository, including where applicable:

```bash
# Examples only — use the actual scripts/tools available in this project
flutter test
flutter analyze
npm test
npm run lint
npm run build
dart format --set-exit-if-changed .
```

Use only commands that match the actual project stack.

Required verification:
- Login username placeholder is updated.
- Incorrect credential message is updated and scoped only to incorrect credentials.
- Remember Me saves only after successful login.
- Remember Me does not save failed credentials.
- Remember Me clear/deselect behavior works.
- Sign In button width is unchanged.
- Sign In button height is increased by 50%.
- Sign In text is larger and not clipped.
- Offline toast appears only for internet-required actions.
- Offline toast does not appear during offline video playback.
- Forgot Password image/loading layout matches Sign In page.
- Exam graph x-axis shows dates in DD/MM format.
- Exam graph date labels are rotated 90 degrees bottom-to-top.
- Graph hover/tooltip text is white.
- Video pauses when navigating away.
- Audio/podcast pauses when navigating away.
- Media does not auto-resume unless the user manually resumes it.
- No unrelated UI regressions are introduced.

If a test/build/check cannot run in the current environment, document the exact reason. Do not claim it passed.

---

## Required Unified Audit Report

Create one single audit report at:

```text
docs/audits/login-connectivity-graph-media-fixes-unified-audit.md
```

If `docs/audits/` does not exist, create it.

The audit report must include:

1. Audit title
2. Date/time
3. Original requested changes summary
4. Repository/project detected
5. Git status before work
6. Files inspected
7. Files changed
8. Task completion matrix with columns:
   - Area
   - Requested change
   - Starting status
   - Final status
   - Files changed
   - Evidence/notes
9. Implementation summary
10. Tests/checks run
11. Test/check results
12. Build results, if applicable
13. Items verified manually
14. Items blocked, if any
15. Items needing confirmation, if any
16. Dependency changes, or state “No dependency changes”
17. Database/API/auth/config changes, or state “No database/API/auth/config changes”
18. Security note for Remember Me storage
19. Scope-control statement confirming no unrelated work was done
20. Known remaining risks
21. Final acceptance status:
   - ACCEPTED only if all requested applicable tasks are complete and tests/checks pass
   - PARTIALLY ACCEPTED if some tasks are blocked/need confirmation but implemented code passes
   - REJECTED if implementation or tests fail

---

## Final Antigravity Response Required

After completing the work, respond with:

1. Summary of completed changes
2. Audit report path
3. Tests/checks run and final result
4. Any blocked items or confirmations needed
5. Any files that require manual review

Do not exaggerate completion. Do not mark any item complete without code evidence and test/manual verification evidence.

Begin now with repository inspection and task mapping. Do not implement until you have separated safe actionable changes from items that need confirmation.
