# Client QA Remaining Fixes Unified Audit

Date/time: 2026-07-09 15:30:48 IST

## Original Client Checklist Summary

The checklist covered Website/Browser, iPhone/iOS, Mac, iPad, Android Phone, and Windows App issues across landing content, login/forgot password/OTP, subject video and PDF aids, exams, reports, podcasts, live classes, feedback, and logout. Recent commits already covered many login, forgot password, offline video, device-status, tutorial clipping, video progress, and logout-loader items; those were treated as verify-only unless current code contradicted them.

## Current Repository / Project Detected

- Flutter project: `EQ8`, description `mydigitalcollege student app`
- Main app code: `lib/`
- Platforms present: `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/`
- Platform not present in repository: none of the requested platform folders are missing; iPad is represented by the iOS Flutter target, not a separate folder.
- Available project checks detected: `flutter analyze`, `flutter test`, `flutter build web`, `flutter build apk --debug`

## Git History Reviewed

Reviewed `git status --short`, `git log --oneline --decorate -n 80`, `git diff --stat`, and `git diff --name-only`.

Recent completed commits considered include:

- `8458233` login/dashboard global loading spinner
- `dd64898`, `c0b3812`, `2cad4b7`, `82e59ff` forgot password label and flow work
- `b54bc35`, `927ef51`, `3d77efa` offline/download/video aid work
- `24fc433`, `e5cdd1c`, `7c07819` device status sheet work
- `62f61db`, `e7367a7` tutorial safe-area padding
- `8050134`, `9651e92`, `fbb7f03` video progress bar/Flick settings work
- `a2e0774`, `9df95fe` logout loader overlay work

## Full Task Matrix

| Area | Platform | Client request | Starting status | Final status | Files changed | Evidence/notes |
| --- | --- | --- | --- | --- | --- | --- |
| Website content/FAQ/footer/hero | Web | Landing logo, FAQ, footer, age animal images, hero buttons | Not present in repository | Not present / Needs confirmation | None | `rg` found no FAQ/hero/footer/marketing landing strings in `lib/` or `web/`; Flutter app web target exists, but not a distinct website landing page. Animal assets matching age groups were not present. |
| Login loading | iOS/Android/Mac/iPad/Windows | Add timeout/error cleanup where missing | Partially complete | Implemented shared timeout | `lib/SignIn.dart` | Existing loader was present; sign-in request now times out after 25 seconds and existing catch/finally cleanup handles feedback/hide. |
| Login layout | Mac/iPad/Windows related | Prevent launch art hiding form | Partially complete | Implemented shared layout cap | `lib/SignIn.dart` | Non-Windows login background image now has a max-height and `BoxFit.contain`; Windows already used compact logo. |
| Forgot password layout/timeout | Mac/iPad/Windows related | Prevent art hiding form; avoid stuck reset request | Partially complete | Implemented shared layout cap and timeout | `lib/forgot.dart` | Existing validation/dialogs preserved; reset API now times out after 25 seconds. |
| Verify OTP layout/text/button | Mac/Windows | Button whole area clickable; casing; layout | Incomplete | Implemented | `lib/veryfy.dart` | Removed nested `GestureDetector`; `OutlinedButton.onPressed` handles click; text changed to `Verify OTP`; Lottie area capped. |
| Exam counter | iOS/Mac/iPad/Android/Windows | Never show `6/5`; completion shows `5/5` | Incomplete | Implemented | `lib/Student/Test.dart` | Display question number is clamped to total question count. |
| Exam Previous | iOS/Mac/iPad/Android/Windows | Fix Previous button navigation | Incomplete | Implemented | `lib/Student/Test.dart` | Previous now decrements `_questionIndex`, removes last answer, and recalculates progress. |
| Exam exit dialog | iOS/iPad/Android/Windows | Highlight `CONTINUE EXAM` as main/default action | Incomplete | Implemented | `lib/Student/Test.dart` | `CONTINUE EXAM` is now the primary elevated action; cancel is secondary text action. |
| Exam timer | iOS/Mac/iPad/Android/Windows | Fix timer speed | Blocked | Blocked / Needs confirmation | None | Current `Test.dart` only displays question count remaining, not a countdown timer. `StartYourExam.dart` displays `allowed_time`, but no exam timer implementation was found to safely correct. |
| Exam history chart labels/cutoff | iOS/iPad/Android/Windows | Avoid `ExamExam...`; chart cut-off | Partially complete | Verified existing likely complete | None | Bottom labels already generated as separate `Text('Exam n')`; chart wrapped in scrollable content. No code change made. |
| Report title | All app platforms | Change `Performance Analysis` to `Progress Tracking` | Incomplete | Implemented | `lib/Student/ExamReport.dart` | AppBar title updated. |
| Feedback submit | Windows/Other | Button doing nothing; add loading/success/failure feedback | Incomplete | Implemented | `lib/Student/FeedbackController.dart` | Feedback now validates trimmed input, disables while submitting, shows spinner, applies 20s timeout, handles success and failure response. |
| Subject last tutorial/no-wifi/offline/video progress | iOS/iPad/Android/Mac/Windows | Verify completed subject/video items | Already complete / verify-only | Verified from code/history where possible | None | Recent commits and code show bottom padding, `DeviceStatusSheet`, offline file playback, high-contrast progress, and PDF loading overlays. Device/backend runtime behavior not proven without devices/services. |
| Resource Guide / Video Aid loading | iOS/Mac/iPad/Android/Windows | Add spinner if missing | Already complete / verify-only | Verified from code | None | `Subject.dart` and `PodcastSubject.dart` already call `loaderOverlay.show/hide` around PDF aid downloads/opening. |
| Podcasts | Mac/Android | Progress/jump controls/loading/error feedback | Partially complete | Verified partial, no safe code change | None | `PodcastSubject.dart` already has progress slider and 10-second replay/forward controls. Network/backend podcast failure behavior needs runtime service verification. |
| Live classes AI error | Mac | Investigate intermittent backend/API error | Needs confirmation | Blocked | None | AI response depends on external API/backend behavior and credentials; no safe frontend-only proof from repo. |
| Logout clickable size/consistency | All app platforms | Increase tap size; fix inconsistent logout | Partially complete | Needs confirmation | None | Multiple screens implement separate logout sheets/buttons; changing all without shared component would be broader UI refactor. Existing logout loader overlay was not duplicated. |
| Branding `EQ8` text | Windows | Fix page text saying EQ8 if incorrect branding | Needs confirmation | Needs confirmation | None | `pubspec.yaml` and package name are `EQ8`, while UI uses Mi Digital Academy/midigitalacademy. Client confirmation needed before changing app/package/MSIX branding. |
| Email/OTP backend delivery | Mac/Windows/Android | Fix if frontend issue, otherwise document | Needs confirmation | Blocked / Needs backend verification | None | Reset/OTP delivery depends on API/provider; frontend request paths exist, but production delivery cannot be verified from repo alone. |

## Verified Complete Without Code Changes

- Forgot Password label appears as `Forgot Password?` on sign-in.
- Forgot Password validation, loading, cancel request, and success/error handling exist.
- Device status sheet exists with light blue/white styling and countdown behavior.
- Subject tutorial list bottom padding exists in recent commits.
- Offline video file playback and offline message work were present in recent history.
- Resource Guide / Video Aid overlays are present around document download/open actions.
- Android and shared video progress bar visibility work is present in recent history/code.
- Podcast progress and 10-second jump controls already exist.

## Implemented In This Run

- Added 25-second sign-in request timeout.
- Added bounded login art layout for non-Windows targets.
- Added 25-second forgot-password request timeout.
- Added bounded forgot-password art layout for non-Windows targets.
- Capped Verify OTP Lottie art, changed button text to `Verify OTP`, and made the full button clickable.
- Fixed exam question counter clamping so it cannot display beyond total question count.
- Implemented exam Previous navigation and answer/progress rollback.
- Promoted `CONTINUE EXAM` to the primary/default exam-exit action.
- Renamed report title to `Progress Tracking`.
- Added feedback submission validation, disabled/loading state, timeout, success handling, and failure handling.

## Blocked / Needs Confirmation

- Website landing/FAQ/footer/logo/age animal image items: no matching landing page or FAQ content found; no relevant animal assets found.
- Exam timer speed: no actual countdown timer implementation found in exam screen.
- Email/OTP delivery failures: require backend/email provider/API verification.
- Live class intermittent AI error: depends on external AI/backend response.
- Logout consistency across every screen: there are multiple separate logout implementations; a complete fix should be confirmed as a shared component/refactor task.
- Windows `EQ8` branding: project/package/MSIX names still use `EQ8`; needs product owner confirmation before renaming.

## Files Changed

- `lib/SignIn.dart`
- `lib/forgot.dart`
- `lib/veryfy.dart`
- `lib/Student/Test.dart`
- `lib/Student/ExamReport.dart`
- `lib/Student/FeedbackController.dart`
- `docs/audits/client-qa-remaining-fixes-unified-audit.md`

## Tests / Checks Run

- `dart format lib/Student/Test.dart lib/veryfy.dart lib/Student/ExamReport.dart lib/Student/FeedbackController.dart lib/SignIn.dart lib/forgot.dart`
  - Passed after sandbox approval for Flutter SDK cache writes.
- `flutter analyze`
  - Ran after sandbox approval; failed with 379 existing warnings/infos. No compile errors were reported in the visible output. Findings include longstanding file naming, deprecated API, unused imports/fields, and style issues across the repo.
- `flutter test`
  - Did not run tests: `test` directory has no files ending in `_test.dart`.
- `flutter build web`
  - Passed; built `build/web`.
  - Warnings: deprecated `index.html` loader/service worker APIs and Wasm dry-run incompatibilities from web dependencies.
- `flutter build apk --debug`
  - Passed; built `build/app/outputs/flutter-apk/app-debug.apk`.
  - Warnings: future Flutter support warnings for Gradle/AGP/Kotlin versions and obsolete Java 8 source/target warnings.

## Build Results

- Web build: passed.
- Android debug APK build: passed.
- iOS/macOS/Windows native builds: not run in this pass; platform folders are present, but build verification would require separate target-specific toolchain/signing/runtime checks.

## Dependency / Database / API / Auth Changes

- No dependency changes.
- No database/API/auth/config changes.
- Frontend API request timeouts were added for sign-in, forgot password, and feedback submission.

## Scope Control

Changes were limited to directly actionable shared Flutter screens found in the checklist. Already completed work from recent commits was not reimplemented, renamed, or refactored. Unavailable backend/provider/asset/landing-page items were documented rather than guessed.

## Known Remaining Risks

- `flutter analyze` has a large pre-existing warning baseline and exits nonzero.
- Several checklist items require real devices, production services, API credentials, or client-provided assets for full verification.
- iOS/macOS/Windows builds were not executed in this environment during this run.
- Web marketing checklist items may belong to a separate site not present in this repository.

## Final Acceptance Status

PARTIALLY ACCEPTED.

Implemented code passes formatting, web build, and Android debug build. Some applicable items remain blocked or need confirmation, and `flutter analyze` remains non-passing due to the repository's existing warning baseline.
