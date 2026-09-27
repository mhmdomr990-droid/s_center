# E2E Browser Action Report

## Action Matrix

| Role | Page | Element/Action | Result | Error Detail | Screenshot |
| --- | --- | --- | --- | --- | --- |
| ADMIN | specific-flow | Auth incorrect credentials rejected | PASS | - | - |
| ADMIN | specific-flow | Device lock rejects second device login | PASS | - | - |
| ADMIN | specific-flow | Student A purchases course successfully | PASS | - | - |
| ADMIN | specific-flow | Student B purchase rejected with insufficient balance | PASS | - | - |
| ADMIN | specific-flow | Student topup request is created | PASS | - | - |
| ADMIN | specific-flow | Admin reassigns course to teacher B | PASS | - | - |
| ADMIN | specific-flow | Teacher earnings remain with teacher A immediately after reassignment | PASS | - | - |
| ADMIN | specific-flow | Admin approves topup request | PASS | - | - |
| ADMIN | specific-flow | Student B can purchase after approved topup | PASS | - | - |
| ADMIN | specific-flow | Teacher reassignment historical earnings are preserved after new purchase | PASS | - | - |
| ADMIN | specific-flow | Teacher payout records and over-limit rejection work | PASS | - | - |
| ADMIN | specific-flow | Teacher B cannot access teacher A resources | PASS | - | - |
| ADMIN | specific-flow | Teacher cannot reach admin API routes | PASS | - | - |
| ADMIN | specific-flow | Teacher responses do not leak student identity fields | PASS | - | - |
| ADMIN | specific-flow | Student stream URL returns partial content and video can seek | PASS | - | - |
| ADMIN | specific-flow | Student download URL can be fetched | PASS | - | - |
| ADMIN | specific-flow | Profile change-password and logout-all invalidate old token | PASS | - | - |
| ADMIN | specific-flow | Admin audit log page probe | PASS | - | - |
| ADMIN | specific-flow | Admin refund endpoint probe | PASS | - | - |
| ADMIN | http://127.0.0.1:3000/panel/admin/overview | ◐ [html > body > div.panel-shell > aside.panel-sidebar > div.panel-brand:nth-of-type(1) > button.polish-theme-toggle] (confirm) | PASS | ok (confirm) | - |
| ADMIN | http://127.0.0.1:3000/panel/admin/overview | نظرة عامة [html > body > div.panel-shell > aside.panel-sidebar > nav.panel-nav > a:nth-of-type(1)] (confirm) | PASS | ok (confirm) | - |
| ADMIN | http://127.0.0.1:3000/panel/admin/overview | التخصصات [html > body > div.panel-shell > aside.panel-sidebar > nav.panel-nav > a:nth-of-type(2)] (confirm) | PASS | ok (confirm) | - |
| ADMIN | http://127.0.0.1:3000/panel/admin/specializations | ☀ [html > body > div.panel-shell > aside.panel-sidebar > div.panel-brand:nth-of-type(1) > button.polish-theme-toggle] (confirm) | PASS | ok (confirm) | - |
| ADMIN | http://127.0.0.1:3000/panel/admin/specializations | نظرة عامة [html > body > div.panel-shell > aside.panel-sidebar > nav.panel-nav > a:nth-of-type(1)] (confirm) | PASS | ok (confirm) | - |
| ADMIN | http://127.0.0.1:3000/panel/admin/specializations | التخصصات [html > body > div.panel-shell > aside.panel-sidebar > nav.panel-nav > a:nth-of-type(2)] (confirm) | PASS | ok (confirm) | - |
| TEACHER | http://127.0.0.1:3000/panel/teacher/courses | ◐ [html > body > div.panel-shell > aside.panel-sidebar > div.panel-brand:nth-of-type(1) > button.polish-theme-toggle] (confirm) | PASS | ok (confirm) | - |
| TEACHER | http://127.0.0.1:3000/panel/teacher/courses | كورساتي [html > body > div.panel-shell > aside.panel-sidebar > nav.panel-nav > a:nth-of-type(1)] (confirm) | PASS | ok (confirm) | - |
| TEACHER | http://127.0.0.1:3000/panel/teacher/courses | المحاضرات [html > body > div.panel-shell > aside.panel-sidebar > nav.panel-nav > a:nth-of-type(2)] (confirm) | PASS | ok (confirm) | - |
| TEACHER | http://127.0.0.1:3000/panel/teacher/lectures | ☀ [html > body > div.panel-shell > aside.panel-sidebar > div.panel-brand:nth-of-type(1) > button.polish-theme-toggle] (confirm) | PASS | ok (confirm) | - |
| TEACHER | http://127.0.0.1:3000/panel/teacher/lectures | كورساتي [html > body > div.panel-shell > aside.panel-sidebar > nav.panel-nav > a:nth-of-type(1)] (confirm) | PASS | ok (confirm) | - |
| TEACHER | http://127.0.0.1:3000/panel/teacher/lectures | المحاضرات [html > body > div.panel-shell > aside.panel-sidebar > nav.panel-nav > a:nth-of-type(2)] (confirm) | PASS | ok (confirm) | - |
| STUDENT | http://127.0.0.1:3000/student/index.html | ◐ [html > body > div.student-shell > nav.student-nav > div.student-nav-inner > button.polish-theme-toggle] (confirm) | PASS | ok (confirm) | - |
| STUDENT | http://127.0.0.1:3000/student/index.html | ⌂<br>الرئيسية [body > div.student-shell > nav.student-nav > div.student-nav-inner > div.student-nav-links:nth-of-type(2) > a.student-nav-link:nth-of-type(1)] (confirm) | PASS | ok (confirm) | - |
| STUDENT | http://127.0.0.1:3000/student/index.html | $<br>المحفظة [body > div.student-shell > nav.student-nav > div.student-nav-inner > div.student-nav-links:nth-of-type(2) > a.student-nav-link:nth-of-type(2)] (confirm) | PASS | ok (confirm) | - |
| STUDENT | http://127.0.0.1:3000/student/wallet.html | ☀ [html > body > div.student-shell > nav.student-nav > div.student-nav-inner > button.polish-theme-toggle] (confirm) | PASS | ok (confirm) | - |
| STUDENT | http://127.0.0.1:3000/student/wallet.html | ⌂<br>الرئيسية [body > div.student-shell > nav.student-nav > div.student-nav-inner > div.student-nav-links:nth-of-type(2) > a.student-nav-link:nth-of-type(1)] (confirm) | PASS | ok (confirm) | - |
| STUDENT | http://127.0.0.1:3000/student/wallet.html | $<br>المحفظة [body > div.student-shell > nav.student-nav > div.student-nav-inner > div.student-nav-links:nth-of-type(2) > a.student-nav-link:nth-of-type(2)] (confirm) | PASS | ok (confirm) | - |
| ADMIN | specific-flow | Teacher cannot reach /panel/admin/* | PASS | - | - |

## قائمة المشاكل

| Severity | Role | Page | Repro Steps | Expected | Actual | Root Cause | Fix |
| --- | --- | --- | --- | --- | --- | --- | --- |
| HIGH | ADMIN | /api/admin/purchases/:id/refund | Call refund endpoint for a valid admin token | Refund operation should exist and update balance/access atomically | Refund endpoint is missing (404). | Refund workflow is not implemented in admin API/service. | Implement refund service transaction, route/controller, and panel action in test-safe data scope. |
| MEDIUM | ADMIN | /panel/admin/audit-logs | Open audit log page from admin session | Audit log UI page should exist and render | Route unavailable or redirects unexpectedly (status 404) | No panel route/view is implemented for audit log browsing. | Add admin panel route/controller/view for audit logs and wire it in sidebar. |