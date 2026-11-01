# AGENTS.md — Complete Project Reference

> **Purpose of this file:** Give any AI model a complete, accurate, code-verified mental model of this project in one read. Everything below was verified directly against the source code (backend + Flutter app). Read this first, then open only the specific files you need.
>
> **File location:** `<repo-root>/AGENTS.md` (project root — the single source of truth)
> **Mobile app root:** `mobile/` (Flutter)
> **Last verified:** 2026-11-01
> **Maintenance rule:** see §13 — this file MUST be updated in the same session as any code change.

---

## 1. Project Overview

**s_center** ("NSC — the National Science Center", Arabic: المركز الوطني للعلوم) is an Arabic (RTL) education platform that sells video/PDF/text courses organized by **academic specialization** and **year (1–5)**. Teachers earn a percentage of every sale.

**Three user roles** (`UserRole` enum): `STUDENT`, `TEACHER`, `ADMIN`.

**Three front-ends sharing one backend:**

| Front-end | Tech | URL | Audience |
|---|---|---|---|
| JSON API | Express + TypeORM + MySQL (TypeScript) | `/api/*` | **Flutter app (the main focus of future work)** |
| Control panel | Server-rendered EJS (Arabic RTL) | `/panel/*` | Admin + Teacher (web) |
| Legacy student SPA | Static HTML/JS | `/student/*` | Used by Playwright e2e tests only |

> **Rule of thumb for future changes:** almost all upcoming work happens in the **Flutter app** (`mobile/`). The backend is considered stable — but you must understand it deeply to consume it professionally.

---

## 2. Repository Map

```
s_center/
├── src/
│   ├── server.ts                 # bootstrap: DB init → seed admin → cleanup loop → listen
│   ├── app.ts                    # Express app wiring (middleware order matters)
│   ├── seed-admin.ts             # ensureDefaultAdmin() + CLI (npm run seed:admin)
│   ├── config/
│   │   ├── env.ts                # zod-validated env (see §11)
│   │   └── data-source.ts        # TypeORM DataSource (MySQL, utf8mb4_unicode_ci)
│   ├── entities/                 # 14 entities + enums.ts + BaseColumns.ts (id, created_at, updated_at)
│   ├── modules/                  # API feature modules (routes + controller + service + schemas)
│   │   ├── auth/  catalog/  purchase/  wallet/  media/  notifications/  teacher/  admin/
│   ├── services/
│   │   ├── lectureAccess.ts      # access = Purchase(course) OR active LectureGrant(lecture)
│   │   ├── media.ts              # HMAC signed media tokens, upload rules, Range streaming, ffprobe
│   │   ├── idempotency.ts        # executeIdempotent + 48h cleanup
│   │   └── auditLog.ts           # logAuditEvent
│   ├── middlewares/              # auth, role, validate (zod), rateLimit, error, videoUpload (multer)
│   ├── utils/                    # money (bigint cents), jwt, AppError, pagination, asyncHandler, requestSchemas
│   ├── panel/                    # EJS admin+teacher panel (routes, controllers, views, CSRF, flash)
│   └── types/                    # express/cookie-parser/multer .d.ts
├── mobile/                       # FLUTTER APP (GetX, Arabic RTL, v1.0.7)
│   ├── lib/
│   │   ├── main.dart             # boot: fonts, DI singletons, foreground task, screen guard
│   │   ├── app/                  # routes, theme, transitions, version.dart
│   │   ├── data/
│   │   │   ├── models/           # 9 models (user, course, lecture, purchase, transaction, topup_request, notification, payout, specialization)
│   │   │   ├── providers/        # ApiClient (Dio) + Auth/Catalog/Media/Notification/Purchase/Wallet/Teacher/Admin providers
│   │   │   └── services/         # storage, device, device_guard, screen_guard, app_status,
│   │   │                         # catalog_lookup, offline_cache, download_manager, upload_manager, video_compressor
│   │   ├── modules/              # splash, auth, home_shell, maintenance, security,
│   │   │                         # student/{home,courses,lecture,wallet,notifications,downloads,profile},
│   │   │                         # teacher/{dashboard,courses,earnings,account,lectures},
│   │   │                         # admin/{users,teachers,content,purchases,topups,notifications,account}
│   │   ├── utils/format.dart
│   │   └── widgets/              # 15 shared widgets (course_card, lecture_tile, pdf_viewer_page, offline_banner, …)
│   ├── third_party/              # vendored video_compress + flutter_foreground_task
│   └── test/crypto_roundtrip_test.dart
├── public/                       # landing, welcome, student-app SPA, panel assets, vendor/chart.umd.js
├── tests/e2e/                    # Playwright (full-e2e.spec.ts, global-setup, utils)
├── scripts/                      # smoke-test.ts (teacher-earnings regression), copy-panel-assets.mjs
├── docs/                         # API_REFERENCE.md (media feature), E2E_TESTING.md
└── storage/videos/               # uploaded lecture files (UUID.ext) — outside public/
```

---

## 3. Tech Stack & Architecture

### Backend
- **Express 4** + **TypeORM 0.3** + **MySQL** + **TypeScript** (CommonJS, ES2020, strict, decorators).
- **zod** validation via `validate({body, query, params})` middleware; all object schemas use `.strict()` (unknown keys → 400).
- **bcrypt cost 12** everywhere. **jsonwebtoken** (no refresh tokens).
- **multer** diskStorage for lecture uploads; **ffprobe** (`spawnSync`) for video duration.
- Money never uses floats — always **BigInt cents** (see §5).

### Middleware order in `src/app.ts` (important)
1. EJS view engine + `app.locals.money` (Intl `ar-SY`) / `app.locals.date`
2. **helmet is commented out** (disabled) — security relies on sameSite cookies + CSRF + origin checks
3. `cors({origin: CORS_ORIGINS, credentials: true})` → cookieParser → json(1mb) → urlencoded
4. `Cache-Control: no-store` for `/student`, `/panel`, `/js`, `/css`
5. static: `/student` → `public/student-app`, then `public/` at root
6. `app.use('/api', generalRateLimit)` — 300 req / 15 min per IP
7. `GET /api/app-status` (public)
8. **Maintenance gate**: if `AppSetting.maintenance_mode == '1'` → 503 `{success:false, maintenance:true, message}` for every `/api` path EXCEPT `/auth/*`, `/admin/*`, `/app-status`
9. Module routers, then `GET /media/play/:token`, `GET /media/download/:token`, then `/panel*` (+`csrfOrigin`), then `errorMiddleware`

### Flutter app
- **GetX** (controllers + `.obs` + `Obx` + `Bindings`), **Dio** for HTTP, forced Arabic locale + RTL.
- **No flavors / no --dart-define**: base URL hardcoded in `lib/data/providers/api_client.dart`:
  ```dart
  static const String defaultBaseUrl = 'http://143.244.151.183/api';
  ```
  Media origin strips `/api` → `http://143.244.151.183`.
- Navigation at login: `AuthController` → `Get.offAll(StudentShell | TeacherShell | AdminShell)` (IndexedStack bottom-nav shells), **not** the named-route table.

---

## 4. Data Model (TypeORM entities)

All entities extend `BaseColumns`: `id` (auto-increment PK), `created_at`, `updated_at`.

### Enums (`src/entities/enums.ts`, stored as MySQL `enum`)
| Enum | Values |
|---|---|
| `UserRole` | `STUDENT`, `TEACHER`, `ADMIN` |
| `LectureType` | `VIDEO`, `PDF`, `TEXT` |
| `LectureUploadStatus` | `PENDING`, `READY`, `FAILED` (default READY — processing is synchronous) |
| `TopupMethod` | `SHAM_CASH`, `TRANSFER_OFFICE` |
| `TopupStatus` | `PENDING`, `APPROVED`, `REJECTED` |
| `TransactionType` | `TOPUP`, `PURCHASE` (refunds are recorded as `TOPUP`) |
| `PurchaseSource` | `PURCHASED`, `GRANTED` |
| `CourseSwapStatus` | `PENDING`, `APPROVED`, `REJECTED` |

### Entity fields (business meaning)
- **User** — `username` (unique, `^[a-z0-9_]+$`), `full_name`, `password_hash`, `role`, `specialization_id` (nullable, `SET NULL` — student's faculty; gates grants), `phone`, `token_version` (int, bumped by logout-all), `is_test`, `is_active`, **`balance` DECIMAL(12,2)** (students only), `device_id` (single-device lock for students).
- **Specialization** — `name`, `is_published`, `sort_order`.
- **Course** — `specialization_id` (required, RESTRICT), `teacher_id` (nullable, SET NULL — current owner), `year` (1–5), `name`, `description`, **`price` DECIMAL(12,2)**, `is_published`, `sort_order`, **`teacher_percent` DECIMAL(5,2)** (0–100). Index on `(specialization, year)`.
- **Lecture** — `course_id` (required), `created_by` (SET NULL), `title`, `type`, `url` (external, for PDF/TEXT only), `storage_filename` (uploaded file, UUID.ext), `file_size` (bigint), `duration_seconds` (video, via ffprobe), `upload_status`, `content` (TEXT body), `is_published`, `sort_order`.
- **Purchase** — **unique `(user_id, course_id)`**. Snapshots: `teacher_id` (SET NULL), `teacher_share` DECIMAL(12,2), `price_paid`. `source` ∈ {PURCHASED, GRANTED}, `granted_by` (SET NULL). ⚠️ **This table is the ownership record AND the earnings ledger.**
- **Transaction** — append-only wallet ledger: `type`, `amount`, `balance_after`, `description`, `reference_type`, `reference_id`. Observed `reference_type`: `TOPUP_REQUEST`, `PURCHASE`, `COURSE_SWAP_CHARGE`, `COURSE_SWAP_REFUND`, `ADMIN_ADJUSTMENT`.
- **TopupRequest** — **unique `(method, reference_number)`**, `user_id`, `amount`, `sender_name`, `note`, `status`, `reject_reason`, `reviewed_by`, `reviewed_at`.
- **TeacherPayout** — `teacher_id`, `amount`, `note`, `created_by` (required). A record only; no money moves in-platform.
- **CourseSwapRequest** — `student_id`, `old_purchase_id` (SET NULL), `old_course_id`, `new_course_id`, `old_teacher`/`new_teacher` + both shares (snapshots), `status`, `reason`, `admin_note`, `approved_by`/`approved_at`, `rejected_by`/`rejected_at`.
- **LectureGrant** — **unique `(user_id, lecture_id)`**, `granted_by`, `granted_at`, **`revoked` bool (soft revoke; re-grant reactivates the same row)**.
- **Notification** — `user_id`, `title` (≤180), `body`, `is_read`.
- **AppSetting** — key/value. Keys: `maintenance_mode` (`'1'`/`'0'`), `maintenance_message`.
- **AuditLog** — `actor_id`, `action`, `entity_type`, `entity_id`, `metadata` (JSON string).
- **IdempotencyKey** — unique index `(actor_id, key, route)`, `response_status`, `response_body`, `is_processing`.

### Access rule (single source of truth — `src/services/lectureAccess.ts`)
A student can open a lecture **iff** they have a `Purchase` for the whole course **OR** an active (non-revoked) `LectureGrant` for that lecture. For students the whole publish chain must hold: specialization → course → lecture. Teachers: only their own courses (`course.teacher_id == user.id`). Admins: unrestricted.

---

## 5. Money Rules (critical)

- **DB:** all monetary columns are MySQL `DECIMAL(12,2)` → **TypeScript strings**.
- **Arithmetic:** `src/utils/money.ts` uses **BigInt cents** — `toCents(str) → bigint`, `centsToMoney(bigint) → "x.xx"` (always 2 decimals, sign preserved), `addMoney`, `subtractMoney`, `calculateMoneyShare(amount, percent)` (rounds half-away-from-zero).
- **Input normalization** (`moneySchema` / `positiveMoneySchema` / `signedMoneySchema`): accepts Arabic-Indic `٠-٩` and Eastern `۰-۹` digits, strips thousands separator `٬`, treats `٫` as `.`, `,` → `.` only when no `.` exists; regex `^-?\d+(\.\d{1,2})?$`.
- **No currency code is stored anywhere.** Display uses `Intl.NumberFormat('ar-SY')` (implies Syrian pounds-style amounts, but effectively "platform credit").
- ⚠️ **In Flutter, never do money math with `double`.** Use strings end-to-end, or BigInt cents. The server is the authority.

---

## 6. Auth, Security, Rate Limits

### API auth (`src/middlewares/auth.ts`)
- Single JWT in `Authorization: Bearer`. Payload: `{userId, role, deviceId, tokenVersion}`.
- Checks on **every** request: signature → user exists & `is_active` → **role must match token role** → **`tokenVersion` must match** (else 401 — this is the global logout mechanism) → for STUDENT: `user.deviceId === payload.deviceId` else **403 "This account is linked to another device"**.
- **Expiry:** student `JWT_EXPIRES_IN` (7d), staff `STAFF_JWT_EXPIRES_IN` (14d). **No refresh token.**
- Device binding: `registerStudent` stores `device_id`; `loginUser` requires it for students on first login and rejects mismatch. Admin clears it via `POST /api/admin/users/:id/reset-device`.

### Panel (web) auth
Cookie `panel_token` (httpOnly, sameSite=strict, 7 days), same JWT secret, but **does NOT check `tokenVersion`** (logout-all does not kill panel sessions). CSRF = double-submit `panel_csrf_token` + Origin/Referer same-host check (`timingSafeEqual`). Flash messages via `panel_flash` cookie.

### Rate limits (`src/middlewares/rateLimit.ts`)
| Limiter | Window | Max | Key |
|---|---|---|---|
| `generalRateLimit` (all `/api`) | 15 min | 300 | IP |
| `authRateLimit` (`/auth/register`, `/auth/login`, `/panel/login`) | 15 min | 50 (10 000 in test) | IP |
| `lectureStreamUrlRateLimit` | 1 h | **20** | `user:{id}` or IP |
| `lectureDownloadUrlRateLimit` | 1 h | **30** | `user:{id}` or IP |

> UX implication: the app's "download once, forever" policy exists partly because of this 30/h cap.

### Global logout
`POST /api/auth/logout-all` → `tokenVersion += 1` → every existing API token becomes invalid (401). The Flutter app must wipe the session on any 401.

---

## 7. Full API Contract (verified against code)

### 7.1 Response envelope
```jsonc
// Success
{ "success": true, "data": { }, "meta": { "page": 1, "limit": 20, "total": 57 } }
// Error
{ "success": false, "message": "Insufficient balance", "code": null }
// Maintenance (HTTP 503)
{ "success": false, "maintenance": true, "message": "التطبيق قيد الصيانة حاليًا" }
```
- `code` is only present for explicit AppError codes (`INVALID_IDEMPOTENCY_KEY`, `IDEMPOTENCY_IN_PROGRESS`).
- **Two pagination styles** (know both):
  1. **DB-level**: `{ "items": [...], "total": 12, "limit": 20, "offset": 0 }` — wallet transactions, wallet top-up requests, notifications (which additionally return `"unread_count"`).
  2. **In-memory** (`paginateItems`): `{ "data": [...], "meta": { "page", "limit", "total" } }` — every admin & teacher list endpoint. `limit ≤ 100`, default 20, `page ≥ 1`.

### 7.2 Auth — `/api/auth`
| Method + Path | Auth | Body | Success `data` |
|---|---|---|---|
| `POST /register` | public + rate limit | `{username, full_name, password, phone?, specialization_id?, device_id}` | `{token, user}` (201) |
| `POST /login` | public + rate limit | `{username, password, device_id?}` | `{token, user}` |
| `GET /me` | Bearer | — | `user` |
| `PATCH /profile` | Bearer | `{full_name?, phone?, specialization_id?}` | `user` |
| `POST /change-password` | Bearer | `{old_password, new_password}` | `{message}` |
| `POST /logout-all` | Bearer | — | `{message}` |

```jsonc
// POST /api/auth/login  →  200
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": 12, "username": "ahmad", "full_name": "أحمد", "role": "STUDENT",
      "specialization_id": 3, "phone": "0999123456",
      "is_active": true, "is_test": false, "balance": "1500.00"
    }
  }
}
```
> ⚠️ `balance` is **only present for STUDENT** (`undefined` for TEACHER/ADMIN → make the Dart field nullable).
> Validation: `username` `^[a-z0-9_]+$` (3–30, auto-lowercased), `password` 8–128, `phone` `^\+?[0-9\s\-()]{7,30}$`, `full_name` 2–120.
> Errors: 401 wrong credentials · 403 inactive account · 403 "This account is linked to another device" · 409 username exists · 400 `device_id is required` (student first login).

### 7.3 Catalog — `/api`
| Method + Path | Auth | Notes |
|---|---|---|
| `GET /specializations` | **public** | published only, sorted by `sort_order, id` |
| `GET /courses?specializationId&year` | Bearer | if `specializationId` omitted → uses the student's own specialization |
| `GET /courses/:id/lectures` | Bearer | lock state + signed PDF urls |

```jsonc
// GET /api/courses → 200
{ "success": true, "data": [ {
    "id": 7, "specialization_id": 3, "year": 2, "name": "التفاضل",
    "description": "...", "price": "2500.00", "is_published": true, "sort_order": 0,
    "teacher_full_name": "أ. سامر", "purchased": false, "source": "PURCHASED", "is_granted": false
} ] }
```
```jsonc
// GET /api/courses/7/lectures → 200
// Locked lecture (student without access): url/content forced to null
{ "id": 31, "title": "مقدمة", "type": "VIDEO", "url": null, "content": null,
  "is_published": true, "sort_order": 0, "locked": true }
// Unlocked lecture:
{ "id": 32, "title": "ملخص", "type": "PDF", "url": "/media/play/<HMAC-token-30min>",
  "content": null, "is_published": true, "sort_order": 1 }
// NOTE: VIDEO lectures always return url=null here — the app must call POST /lectures/:id/stream-url.
```

### 7.4 Wallet — `/api/wallet`
| Method + Path | Notes |
|---|---|
| `GET /` | → `{ "balance": "1500.00" }` |
| `GET /transactions?limit&offset` | → `{items, total, limit, offset}` |
| `POST /topup-requests` | requires `Idempotency-Key`; → topup object (201) |
| `GET /topup-requests?limit&offset` | → `{items, total, limit, offset}` |

```jsonc
// POST /api/wallet/topup-requests  Body:
{ "amount": "5000", "method": "SHAM_CASH", "reference_number": "SC-88921", "sender_name": "أحمد", "note": "تحويل" }
// → 201
{ "success": true, "data": {
    "id": 4, "amount": "5000.00", "method": "SHAM_CASH", "reference_number": "SC-88921",
    "sender_name": "أحمد", "note": "تحويل", "status": "PENDING",
    "reject_reason": null, "reviewed_by": null, "reviewed_at": null, "created_at": "2026-11-01T10:00:00.000Z"
} }
```
```jsonc
// Transaction item shape (wallet + admin user transactions)
{ "id": 91, "type": "TOPUP", "amount": "5000.00", "balance_after": "6500.00",
  "description": "Top-up request approved: SC-88921",
  "reference_type": "TOPUP_REQUEST", "reference_id": 4, "created_at": "..." }
```
> Errors: 400 "You already have 5 pending top-up requests" · 409 "This transfer was already submitted" (duplicate `reference_number`) · 400 invalid money.

### 7.5 Purchase & Course Swap — `/api`
| Method + Path | Notes |
|---|---|
| `POST /courses/:id/purchase` | `Idempotency-Key`; → `{message, purchase:{id, course_id, price_paid}, balance}` |
| `GET /me/courses` | array (no pagination) |
| `GET /me/payments` | PURCHASE transactions only |
| `POST /course-swap-requests` | `{old_purchase_id, new_course_id, reason?≤500}` |
| `GET /course-swap-requests` | student's own requests |

```jsonc
// POST /api/courses/7/purchase  → 200
{ "success": true, "data": {
    "message": "Course purchased successfully",
    "purchase": { "id": 55, "course_id": 7, "price_paid": "2500.00" },
    "balance": "4000.00"
} }
```
```jsonc
// GET /api/me/courses → item
{ "purchase_id": 55, "id": 7, "specialization_id": 3, "teacher_full_name": "أ. سامر",
  "year": 2, "name": "التفاضل", "description": "...", "price": "2500.00",
  "price_paid": "2500.00", "teacher_share": "750.00", "source": "PURCHASED",
  "is_granted": false, "purchased_at": "2026-11-01T12:00:00.000Z" }
```
```jsonc
// POST /api/course-swap-requests  Body: { "old_purchase_id": 55, "new_course_id": 9, "reason": null }
// → 201
{ "success": true, "data": {
    "id": 12, "status": "PENDING", "old_course_id": 7, "new_course_id": 9,
    "old_teacher_share": "750.00", "new_teacher_share": "900.00",
    "reason": null, "requested_at": "...", "window_hours_remaining": 61
} }
```
> Purchase errors: 404 course/user not found · **409 "You already purchased this course"** · **400 "Insufficient balance"**.
> Swap errors: 400 window expired / same course (Arabic messages) · 409 student already owns the replacement · 409 a PENDING request already exists for that purchase.

**Course-swap business rules (72-hour window, `COURSE_SWAP_WINDOW_HOURS = 72`):**
- Eligibility is measured from the **original purchase's `created_at`** and re-checked again at approval time.
- On approval the old `Purchase` row is **deleted** and a replacement `Purchase` is inserted (kept `GRANTED` with `0.00` if the original was granted).
- Price delta is charged/refunded **only if the original source was PURCHASED**:
  - charge → `Transaction(type=PURCHASE, reference_type=COURSE_SWAP_CHARGE)`
  - refund → `Transaction(type=TOPUP, reference_type=COURSE_SWAP_REFUND)`
- ⚠️ The charge path has **no sufficiency check** — it can push a balance negative (known gap).

### 7.6 Media — `/api` + `/media`
| Method + Path | Who | Rate limit | Result |
|---|---|---|---|
| `POST /lectures/:id/stream-url` | any authed role (access re-checked) | 20/h | `{ "url": "/media/play/<token>" }` — valid **10 min** |
| `POST /lectures/:id/download-url` | **STUDENT only** | 30/h | download url (below), audit-logged |
| `GET /media/play/:token` | signed token, **no Bearer** | — | 200/206 stream, 403/404 on failure |
| `GET /media/download/:token` | signed token | — | same + `Content-Disposition: attachment` |

```jsonc
// POST /api/lectures/32/download-url → 200
{ "success": true, "data": {
    "url": "/media/download/<HMAC-token>", "expires_at": "2026-11-01T14:00:00.000Z",
    "lecture_id": 32, "course_id": 7, "download_ttl_days": 100
} }
```
- **Relative URLs**: the Flutter app prepends the media origin (baseUrl minus `/api`).
- Token = `base64url(JSON payload).HMAC-SHA256(VIDEO_SIGNING_SECRET)`, payload `{lecture_id, user_id, purpose, exp, nonce, role}`; verified with `timingSafeEqual` and **re-validated on every byte** (user active, role match, entitlement, publish chain, file on disk).
- Streaming supports HTTP `Range` (206 + `Content-Range`, suffix ranges, 416 on invalid).
- Upload rules: multer field **`video`**, ext ∈ `.mp4/.webm/.mov/.mkv/.pdf` **and** extension↔mimetype match, max `VIDEO_MAX_SIZE_MB` (2048 MB default).

### 7.7 Notifications — `/api/notifications`
| Method + Path | Result |
|---|---|
| `GET /?limit&offset` | `{items:[{id,user_id,title,body,is_read,created_at}], unread_count, total, limit, offset}` |
| `PATCH /:id/read` | `{message}` (idempotent) |
| `PATCH /read-all` | `{message}` |

### 7.8 Teacher — `/api/teacher` (all: `authMiddleware + requireRole(TEACHER)`)
| Method + Path | Result |
|---|---|
| `GET /courses?page&limit` | `{data:[{course_id,name,year,description,price,is_published,sort_order,purchases_count,earned}], meta}` |
| `GET /dashboard?days=7\|30\|90` | `{...stats, daily_sales:[{date,purchases_count,earned}], per_course}` (dates in **+03:00**) |
| `GET /stats` | `{total_purchases, total_earned, total_paid, remaining, courses:[{course_id,name,purchases_count,earned}]}` |
| `GET /earnings?month=YYYY-MM` | `{month, courses:[...], payouts:[{id,amount,note,created_by,created_at}]}` |
| `GET /payouts?page&limit` | `{data, meta}` |
| `GET /purchases?course_id&search&page&limit` | `{data:[{id,student_id,username,full_name,course_id,course_name,specialization_name,price_paid,teacher_share,source,source_label,created_at}], meta}` |
| `GET /courses/:id` | course detail + `purchases_count`, `earned`, `teacher_percent` |
| `PATCH /courses/:id` | `{description}` only (≤5000, nullable) |
| `GET /courses/:id/lectures` | **all** lectures incl. unpublished |
| `GET /courses/:id/preview` | published lectures only |
| `POST /courses/:id/lectures` | **multipart** field `video` + body → 201 lecture |
| `PATCH /lectures/:id` | multipart optional `video` + partial body |
| `PATCH /lectures/:id/published` | `{is_published}` |
| `DELETE /lectures/:id` | permanent + stored file removed |
| `PUT /courses/:id/lectures/order` | `{lecture_ids}` must include **every lecture exactly once** → else 400 |

```jsonc
// Lecture object returned by teacher/admin endpoints
{ "id": 32, "course_id": 7, "title": "ملخص", "type": "PDF", "url": null,
  "content": null, "is_published": true, "sort_order": 1,
  "created_by": 4, "created_at": "...", "updated_at": "..." }
```
Lecture body schema: `{title(1–150), type:'VIDEO'|'PDF'|'TEXT', url?, content?, sort_order?}`.
Type↔file rules: **VIDEO** ⇒ file required, `url` forbidden, `.pdf` file rejected · **PDF** ⇒ `.pdf` file **or** url · **TEXT** ⇒ no file. On any error the freshly uploaded file is deleted.

### 7.9 Admin — `/api/admin` (all: `requireRole(ADMIN)`; bypass the maintenance gate)
| Group | Endpoints |
|---|---|
| Badges | `GET /badges` → `{pending_topups, pending_topups_amount}` |
| Specializations | `GET/POST /specializations`, `GET/PATCH/DELETE /specializations/:id`, `PATCH /specializations/:id/published` (DELETE = archive/unpublish) |
| Courses | `GET/POST /courses`, `GET/PATCH/DELETE /courses/:id`, `PATCH /courses/:id/published`, `GET /courses/:id/lectures`, `PUT /courses/:id/lectures/order` |
| Lectures | `GET/POST /lectures`, `GET/PATCH/DELETE /lectures/:id`, `PATCH /lectures/:id/published` (POST/PATCH accept multipart `video`) |
| Top-ups | `GET /topup-requests?status&page&limit`, `GET /topup-requests/:id`, `POST /topup-requests/:id/approve`, `POST /topup-requests/:id/reject` `{reason(1–1000)!}` |
| Swaps | `GET /course-swap-requests` (**pending only**), `POST .../approve` `{admin_note?}`, `POST .../reject` `{reason?}` |
| Users | `GET /users?search&role&is_active&is_test&page&limit`, `GET /users/:id` (+`purchases_count`, `last_topups`), `GET /users/:id/transactions`, `GET /users/:id/purchases` |
| User actions | `PATCH /users/:id/active`, `POST /users/:id/reset-device`, `POST /users/:id/adjust-balance` (+Idempotency-Key), `POST /users/:id/reset-password` |
| Grants | `POST /users/:id/grant-course` `{course_id}`, `DELETE /users/:id/grant-course`, `POST /users/:userId/grant-lecture/:lectureId`, `POST /users/:userId/grant-lectures` `{lecture_ids}`, `POST /users/:userId/revoke-lecture-grant/:lectureId`, `GET /users/:userId/lecture-grants` |
| Teachers | `POST /teachers`, `GET /teachers`, `GET/PATCH /teachers/:id`, `POST/GET /teachers/:id/payouts` (+Idempotency-Key on POST) |
| Misc | `POST /admins`, `POST /notifications` `{all:true,...}` or `{user_id,...}`, `GET/PATCH /settings/maintenance`, `GET /purchases` (global history) |
| Stats | `GET /stats/overview`, `/stats/sales?days`, `/stats/top-courses?limit`, `/stats/by-specialization`, `/stats/teachers` (all accept `from`/`to` ISO datetime) |

```jsonc
// GET /api/admin/users → item (mapUser)
{ "id": 12, "username": "ahmad", "full_name": "أحمد", "phone": "0999123456",
  "role": "STUDENT", "specialization_id": 3, "specialization_name": "الهندسة المدنية",
  "is_active": true, "balance": "1500.00", "created_at": "...", "updated_at": "..." }
```
```jsonc
// GET /api/admin/teachers → item (mapTeacherAggregate)
{ "teacher_id": 4, "username": "samer", "full_name": "أ. سامر", "is_active": true,
  "purchases_count": 42, "paid_count": 35, "free_count": 7, "paid_revenue": "105000.00",
  "earned": "112000.00", "paid": "50000.00", "remaining": "62000.00" }
```
```jsonc
// POST /api/admin/users/:userId/grant-lectures  Body: { "lecture_ids": [31, 32, 33] }
// → 200 — note partial success is possible
{ "success": true, "data": {
    "message": "تم منح 2 محاضرة مجانية، وتعذر منح 1 محاضرة",
    "user_id": 12, "granted": 2, "failed": 1,
    "results": [ { "success": true, "statusCode": 201, "lecture_id": 31, "course_id": 7,
                   "message": "تم منح المحاضرة المجانية بنجاح", "grant_id": 8, "reactivated": false }, ... ]
} }
```
> Admin error highlights: 400 grant specialization mismatch ("Course specialization does not match student specialization") · 409 already has access · 400 "Balance cannot go below zero" · 400 "Payout amount exceeds remaining balance" · 400 top-up not pending · 400/409 swap no longer pending.

### 7.10 Idempotency (`Idempotency-Key` header)
Only these 4 routes use it: **course purchase**, **topup request creation**, **admin adjust-balance**, **admin teacher payout**.
- Key must be **8–64 chars** (else 400 `INVALID_IDEMPOTENCY_KEY`).
- Same `(actor, route, key)` replays the stored response (including stored 4xx!) for **48 hours**.
- A duplicate while still processing → **409 `IDEMPOTENCY_IN_PROGRESS`**.
- Unexpected (non-AppError) errors delete the marker so the client can retry.
- The Flutter app sends `Uuid().v4()` on purchase and top-up.
- The panel does **not** use it (relies on DB unique constraints + pessimistic locks).

---

## 8. Core Algorithms & Invariants

### Purchase (`purchaseCourse`) — transaction + `pessimistic_write` lock on the user row
1. Course + specialization must be published (else 404) → 2. existing purchase → 409 → 3. **`balance >= price` else 400** → 4. insert `Purchase` with snapshot `teacher_share = price × teacher_percent` → 5. deduct balance → 6. `Transaction(type=PURCHASE)` → 7. `notify(...)` inside the same transaction.

### Teacher earnings are **historical snapshots** (the golden rule, repeated in code comments)
All earnings = `SUM(purchase.teacher_share)` grouped by **`purchase.teacher_id`** — never re-derived from `course.teacher_id`. Reassigning a course to a new teacher **never** reattributes past earnings (audited as `COURSE_TEACHER_REASSIGNED`). Any feature touching earnings must respect this.

### Teacher payouts
`payoutTeacher`: `SUM(payouts) ≤ SUM(purchase.teacher_share)` always (checked in-transaction) → else 400. Payouts are records only; `User.balance` for teachers is unrelated.

### Grants
- **Course grant**: student's specialization **must match** the course's (this check does **not** exist on the paid path), `source=GRANTED`, `pricePaid/teacherShare='0.00'`.
- **Lecture grant**: 409 if the student already owns the whole course or holds an active grant; a **revoked** grant is reactivated (row reused) rather than re-inserted; revoke is a soft flag.

### Audit actions emitted
`COURSE_SWAP_REQUESTED|APPROVED|REJECTED`, `GRANT_COURSE`, `REVOKE_GRANT`, `GRANT_LECTURE`, `REACTIVATE_LECTURE_GRANT`, `REVOKE_LECTURE_GRANT`, `COURSE_TEACHER_REASSIGNED`, `LECTURE_DOWNLOAD_URL_ISSUED`.

### Error handling (`src/middlewares/error.ts`)
`AppError(statusCode, message, code)` → JSON for `/api`, flash+redirect for `/panel`. dup-key (MySQL errno 1062) → **409**. Multer `LIMIT_*` → 400. ZodError → 400. Unknown → 500 "Internal server error". Messages are sometimes English, sometimes Arabic (the Flutter `api_exception.dart` maps them and **ignores server messages longer than 120 chars**).

### Concurrency
Pessimistic row locks (`pessimistic_write`) inside `AppDataSource.transaction` on: buyer user (purchase), topup request + user (approve), user (adjust-balance), student (swap approval), lecture grant rows (grant/revoke), teacher (payout), all lectures of a course (reorder).

---

## 9. Flutter App Details

- **State:** GetX. Singletons via `Get.put` in `main.dart` (`StorageService`, `DeviceService`, `ApiClient`, `ThemeController`, `AuthController`, `DownloadManager`, `UploadManager` — the last two permanent).
- **Shells:** `StudentShell` (Home/Courses/Notifications/Wallet/Profile) · `TeacherShell` (Dashboard/Courses/Earnings/Profile) · `AdminShell` (Topups+badge/Users/Content/Teachers/Notifications/Account).
- **HTTP:** `ApiClient` (Dio, 10s connect / 15s receive) with a Bearer interceptor + 503→maintenance dialog. A **separate Dio** (60s/300s) for media downloads. Uploads use a 30-minute receive timeout.
- **Storage:** `shared_preferences` only (legacy migration from `FlutterSecureStorage`). Keys: `auth_token`, `user_data`, `theme_mode_v2`.
- **Device binding:** `device_id` = native `android-<ANDROID_ID>` via MethodChannel `com.scenter.mobile/device`.
- **Offline downloads (AES-256-CBC):** random 16-byte IV per 64 KiB chunk, container magic `SCV1` (`53 43 56 31`), files under `appSupport/downloads/u<userId>/<lectureId>.enc`, key (32 random bytes) in prefs `lecture_aes_key_v1`. **Download once forever** (`everDownloaded`), manual delete blocked, expiry via server `download_ttl_days`. Roundtrip tested in `mobile/test/crypto_roundtrip_test.dart`.
- **Playback:** offline first (decrypt to temp) → else `POST /lectures/:id/stream-url`; stream url considered stale after **9 minutes**; resume position saved every 5s (`lecture_progress_v1`), removed at ≥95%; auto-recovery up to 2 reloads; PDFs via `pdfx` (hosted ones are decrypted/fetched to temp first).
- **Uploads (teacher/admin):** `VideoCompress` (960×540, 15 fps, linear ETA) inside a `flutter_foreground_task` service; rejected if output is not < 0.9× the source.
- **Security:** `screen_security` blocks screenshots/recording, native emulator detection blocks the app, `ALLOW_CAPTURE_BY_NONE` on API ≥ 29.
- **Notifications:** 30s polling for `unread_count`.
- ⚠️ **Known workaround in the app:** `AdminProvider.createStudent()` posts to `${origin}/panel/admin/students` with **forged panel cookies** (`panel_token` + a fake 48-hex `panel_csrf_token` + `x-csrf-token`), expects 302, and parses the `panel_flash` Set-Cookie — because there is **no admin "create student" endpoint under `/api`**. Preserve this or add a proper endpoint before changing it.

---

## 10. Known Gaps & Warnings (do not "fix" silently)

1. **No refund endpoint** — `/api/admin/purchases/:id/refund` does not exist (flagged HIGH by the e2e suite).
2. **No `/api/admin/students` (create student)** — hence the panel-cookie workaround above.
3. **Course-swap charge path can drive a balance negative** (no sufficiency check in `approveCourseSwapRequest`).
4. **Specialization match is enforced only for free grants**, not for paid purchases.
5. **`admin_note` / `reason` on swap decisions reach the service unvalidated** (`courseSwapDecisionSchema` exists in `purchase/schemas.ts` but is not wired to the routes).
6. **helmet/CSP is disabled** in `src/app.ts`.
7. Panel tokens are **not** invalidated by `logout-all` (no `tokenVersion` check in `panelAuth`).
8. `TEST_REPORT.md` is stale — it describes an older `scripts/smoke-test.ts`.
9. **No audit-log page** in the panel and no API to read `audit_logs` (flagged MEDIUM by e2e).
10. There is no currency field anywhere; formatting is `ar-SY` by convention only.

---

## 11. Commands & Configuration

```bash
npm run dev            # ts-node-dev + copy panel assets (dev server)
npm run build          # tsc → dist/ + copy panel assets
npm start              # node dist/server.js
npm run seed:admin     # create default admin if none exists
npm run test:smoke     # requires a running server (teacher-earnings regression)
npm run test:e2e       # Playwright (creates <DB>_e2e schema, seeds admin, tiny.mp4)
cd mobile && flutter run / flutter build apk   # app (minSdk flutter default, usesCleartextTraffic=true)
```

**Env (`.env`, validated by `src/config/env.ts`):** `NODE_ENV`, `PORT` (3000), `DB_HOST/PORT/USER/PASSWORD/NAME`, `DB_NAME_TEST`, `DB_SYNC` (TypeORM synchronize), `JWT_SECRET`, `JWT_EXPIRES_IN` (7d), `STAFF_JWT_EXPIRES_IN` (14d), `CORS_ORIGINS`, `VIDEO_STORAGE_PATH` (`storage/videos`), `VIDEO_MAX_SIZE_MB` (2048), `VIDEO_SIGNING_SECRET` (defaults to `JWT_SECRET`), `DOWNLOAD_URL_EXPIRY_MINUTES` (120), `DOWNLOAD_TTL_DAYS` (100), `ADMIN_USERNAME`/`ADMIN_PASSWORD` (defaults `asmaa`/`asmaa2026` ⚠️), `DEBUG_PANEL`.

---

## 12. Instructions for the AI Model

**When asked to change something:**
1. Start from the relevant section of this file; it is authoritative for behavior and shapes.
2. For **Flutter** changes: read `mobile/lib/data/providers/*.dart` (exact endpoints/models) and the specific module under `mobile/lib/modules/...`. Keep the GetX patterns (`.obs`, `Obx`, bindings) and Arabic RTL UI. Keep money as strings. Never assume an endpoint exists without checking §7.
3. For **backend** changes: read the module's `routes.ts` → `schemas.ts` → `controller.ts` → `service.ts`. Keep the `{success, data}` envelope, zod `.strict()` schemas, `AppError` + `asyncHandler`, and money-as-BigInt-cents. Any new money-moving POST must use `executeIdempotent` and a transaction with a pessimistic lock.
4. **Never** change: the `Purchase` snapshot semantics (teacher attribution), the access rule in `lectureAccess.ts`, the response envelope, field naming (snake_case in API payloads), or the money string format — unless explicitly asked, and then flag the consequences.
5. When adding an endpoint the Flutter app needs (e.g., create-student, refund), prefer adding a proper `/api` endpoint over extending the panel-cookie workaround — and update §7 of this file.
6. Errors returned to the app should stay **short (<120 chars)** and may be Arabic or English; `api_exception.dart` drops longer messages.

**When this file and the code disagree, the code wins — then update this file.**

---

## 13. File Maintenance Rule (mandatory)

**Any AI or human who changes this repo MUST update this file in the same session, before finishing the task.**

After every code change, review the affected sections and update them, then bump the **Last verified** date in the header:

| What changed | Which sections to update |
|---|---|
| New / changed / removed API endpoint, request body, or response shape | §7 (Full API Contract) — with a fresh JSON example |
| New entity, field, enum value, relation, or invariant | §4 (Data Model) |
| Money handling, rounding, or normalization change | §5 (Money Rules) |
| Auth, device binding, token version, rate limit, maintenance change | §6 (Auth & Security) |
| Business logic (purchase, swap, grants, earnings, idempotency, media) | §8 (Core Algorithms) |
| Flutter architecture, screens, storage, upload/download, providers | §9 (Flutter App) |
| A known gap got fixed (or a new one appeared) | §10 (Known Gaps) |
| New env var, command, or script | §11 (Commands & Configuration) |
| New conventions or "never do this" rules | §12 (Instructions) |

**Rules of the update itself:**
1. **Be surgical** — edit only the affected lines; do not rewrite unrelated sections.
2. **Keep it verified** — only document what the code actually does. If unsure, open the file and check; never guess.
3. **Keep examples real** — JSON examples must match the actual response shape (field names, types, 2-decimal money strings).
4. **Bump the date** — change `Last verified:` to today (ISO `YYYY-MM-DD`).
5. If a change is too large to document fully in one pass, add a `⚠️ TODO:` line in the affected section rather than leaving it silently wrong.

**Why this matters:** this file is the onboarding context given to AI models. A stale file is worse than no file — it confidently teaches wrong behavior. Five minutes of updating at the end of each task keeps it trustworthy indefinitely.
