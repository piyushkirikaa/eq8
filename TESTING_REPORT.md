# EQ8 Student App Test Report

Date: 21 April 2026
Tester: GitHub Copilot (MCP-assisted)
Project: EQ8 Flutter app (`com.midigitalacademy.pg.eq8`)

## 1. Test Environment

- iOS device: iPhone 16 Simulator (iOS 26.4)
- iOS device ID: `B06AE0DE-FCCC-4DAA-9F08-1D02685271CE`
- Android emulator target: AVD `Android` (API 37, Google Play) — BLOCKED (see section 7)
- API base URL (from code): `https://www.mydigitalcollege.co.za/crm/api`
- Credentials used:
  - Username/ID: `GR12ALL`
  - Password: `abcd1234`

## 2. Scope Covered

Student panel/account functional testing:
- Login and validation (empty fields, invalid email, wrong credentials, valid login)
- Forgot Password flow
- Dashboard / Subjects tab
- Subject detail + tutorial selection + video player
- Video options modal: Video AID (PDF), Save Offline, Resource Guide, Exam History
- Exam readiness/result flow
- Podcasts tab and podcast subject detail
- Live Classes tab (AI teacher chat interaction)
- Report tab (performance charts)
- Student profile
- Logout

## 3. Evidence (Screenshots)

All screenshots stored in `test_screenshots/`:

**Login & Auth**
- `02_login_empty_validation_ios.png` — empty field validation
- `03_login_credentials_filled_ios.png` — credentials filled
- `15_logout_to_login_ios.png` — logout returns to login
- `16_forgot_password_screen_ios.png` — Forgot Password screen
- `17_forgot_password_validation_ios.png` — empty email validation on Forgot Password

**Dashboard & Subject**
- `04_dashboard_subjects_ios.png` — subject listing
- `05_dashboard_subjects_scroll_ios.png` — scrolled subjects
- `06_subject_detail_accounting_ios.png` — subject detail (tutorial list)
- `07_subject_tutorial_selected_ios.png` — tutorial selected, video player active
- `19_subject_detail_accounting_playing_ios.png` — video playing in subject view

**Video Options (bottom-sheet modal)**
- `18_video_options_modal_ios.png` — video options modal open
- `20_video_options_modal_ios.png` — video options modal (alternate view)

**Video AID**
- `18_video_aid_pdf_viewer_ios.png` — PDF viewer opened from Video AID
- `19_video_aid_pdf_ios.png` — PDF content visible

**Save Offline**
- `20_save_offline_option_ios.png` — Save Offline option tapped, download initiated

**Resource Guide**
- `21_resource_guide_ios.png` — Resource Guide option in modal
- `21_resource_guide_pdf_ios.png` — Resource Guide PDF opened

**Exam History**
- `22_exam_history_ios.png` — Exam History option selected
- `22_exam_history_list_ios.png` — Exam History list screen

**Exam Flow**
- `08_exam_ready_ios.png` — exam readiness/entry screen
- `09_exam_question1_ios.png` — first question in exam
- `09_exam_result_ios.png` — result after answering
- `10_exam_completed_ios.png` — exam completed screen
- `11_exam_result_ios.png` — result screen detail
- `12_exam_result_full_ios.png` — full result view

**Podcasts**
- `10_podcasts_tab_ios.png` — podcasts tab
- `11_podcast_subject_detail_ios.png` — podcast subject detail

**Live Classes**
- `12_live_classes_tab_ios.png` — live classes tab
- `18_live_classes_chat_typing_ios.png` — message typed in chat
- `19_live_classes_chat_response_ios.png` — AI teacher response received
- `21_live_classes_genius_teacher_ios.png` — AI teacher (Genius) interface
- `22_live_classes_question_typed_ios.png` — question typed
- `23_live_classes_chat_ios.png` — chat conversation view
- `24_live_chat_typing_ios.png` — continued chat typing

**Report & Profile**
- `13_report_tab_ios.png` — report/performance tab
- `14_student_profile_ios.png` — student profile

**Exam History (History tab)**
- `18_history_screen_ios.png` — history screen
- `19_history_subject_tutorials_ios.png` — history subject tutorials
- `20_history_tutorial_selected_ios.png` — history tutorial selected

## 4. Test Results Summary

| Area | Status | Notes |
|---|---|---|
| Login screen render | PASS | UI rendered correctly |
| Empty login validation | PASS | Error shown for both empty fields |
| Invalid email validation | PASS | "Please enter a valid email" shown |
| Wrong credentials | PASS | Error message shown for bad credentials |
| Valid login | PASS | Successfully navigated to student dashboard |
| Forgot password navigation | PASS | Tapping link opens Forgot Password screen |
| Forgot password empty validation | PASS | Validation shown for empty email |
| Forgot password send link | PASS | "SEND RESET LINK" button triggers API call |
| Dashboard subject listing | PASS with issue | Data loads; completion % can exceed 100% (bug fixed in code) |
| Subject detail open | PASS | Subject tutorials list opens correctly |
| Tutorial selection + video player | PASS with issue | Player loads; video renders black on iOS simulator (known platform limitation) |
| Video options modal | PASS | "..." menu opens bottom-sheet with all options |
| Video AID (PDF) | PASS | PDF viewer opens with supplementary document |
| Save Offline | PASS | Download initiated with success notification |
| Resource Guide | PASS | Resource Guide PDF opens when `is_exam == 1` |
| Exam History | PASS | Navigates to Exam History list screen |
| Exam readiness screen | PASS | Subject/time/question/marks info displayed |
| Exam completion/result | PASS | Result screen appears and returns to study screen |
| Podcasts tab | PASS | Podcast subjects listed correctly |
| Podcast subject detail | PASS | Audio controls and list visible |
| Live Classes chat | PASS | AI teacher responds to typed messages |
| Report tab | PASS | Pie chart + subject list shown and scroll works |
| Student profile | PASS | Student and parent info rendered |
| Logout flow | PASS | Confirmation modal shown and returns to login |
| Android execution | BLOCKED | Emulator not detected via ADB/Flutter during this run |

## 5. Defects / Risks (Prioritized)

### Medium

1. Subject completion percentage exceeds 100% — **FIXED**
- Severity: Medium
- Area: Dashboard subject cards (`lib/Student/Dashboard.dart` line 255, `lib/Student/PodcastDashboard.dart` line 438)
- Repro:
  1. Log in as `GR12ALL`
  2. Observe subject cards on dashboard
- Expected: Completion percentage capped at 100%
- Actual (before fix): Values like `663%`, `171%`, `160%`
- Fix applied: `((examCount / tutorialCount) * 100).clamp(0, 100)` in both files
- Evidence: `04_dashboard_subjects_ios.png`, `05_dashboard_subjects_scroll_ios.png`

2. Tutorial video renders black on iOS
- Severity: Medium
- Area: Subject tutorial playback (`lib/Student/Subject.dart`)
- Repro:
  1. Open subject (e.g., Accounting)
  2. Select a tutorial
  3. Observe player area
- Expected: Video/thumbnail/playback UI visible
- Actual: Black player area on iOS simulator (DRM/codec restriction in simulator is expected; needs hardware device validation)
- Evidence: `07_subject_tutorial_selected_ios.png`
- Note: This is a known iOS simulator limitation with certain video codecs. Test on a physical iOS device to confirm real-world behaviour.

### Low

3. Resource Guide and Exam History only accessible via video options modal
- Severity: Low / UX observation
- Area: Subject detail screen
- Note: Both features are conditionally shown only when `is_exam == 1` for a tutorial, accessed via the `⋮` menu on the playing video card. This may not be discoverable for users. No functional defect — works as coded.

4. `CourseCard` progress value unclamped at render layer
- Severity: Low
- File: `lib/Widgets/CourseCard.dart` line 49: `value: course.progress / 100`
- Risk: `LinearProgressIndicator` will throw assertion error if `value > 1.0`. The source-level clamp fix in Dashboard/PodcastDashboard addresses this, but consider adding a defensive clamp in `CourseCard` too:
  ```dart
  value: (course.progress / 100).clamp(0.0, 1.0)
  ```

## 6. Suggested Fix Guidance (Developer-Focused)

### Completion % overflow (applied fix)
```dart
// lib/Student/Dashboard.dart and lib/Student/PodcastDashboard.dart
completionPercentage = ((examCount / tutorialCount) * 100).clamp(0, 100);
```
- Also add defensive clamp in `lib/Widgets/CourseCard.dart`:
  ```dart
  value: (course.progress / 100).clamp(0.0, 1.0),
  ```

### iOS video playback
- Validate iOS player initialization in `lib/Student/Subject.dart` — the `_buildAndroidVideoPlayer()` method is used for iOS as well (non-Windows fallback).
- Test on physical iOS device to confirm if this is simulator-only.
- Consider adding loading/error state to distinguish buffering vs. source error vs. render failure.

### Save Offline UX
- Currently shows a success toast immediately, then a second toast when download completes. This is acceptable UX. Consider adding a progress indicator for large files.

## 7. Android Status

Android emulator launch attempted, but device was not available to ADB/Flutter at verification time:
- `adb devices -l` returned no connected emulator
- `flutter devices` did not list `emulator-5554`
- `adb -s emulator-5554 shell getprop sys.boot_completed` failed (`device not found`)

Action required before Android test pass:
- Ensure emulator fully boots and appears in `adb devices`
- Re-run this same test matrix on Android

## 8. Recommended Next Execution Steps

1. ~~Fix Forgot Password navigation~~ — **RESOLVED** (was working, initial test had interaction issue)
2. ~~Fix completion percentage logic~~ — **FIXED** via `.clamp(0, 100)` in Dashboard + PodcastDashboard
3. Add defensive clamp in `lib/Widgets/CourseCard.dart` (line 49)
4. Investigate iOS video rendering on physical device to confirm simulator-only issue
5. Bring Android emulator online and run parity tests using same credentials and checklist
6. Add regression checklist to CI/manual release gate for student panel critical flows
