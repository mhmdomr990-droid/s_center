# API Reference

## Lecture Media Upload and Access

### Entity changes
- `lectures.storage_filename`: internal stored filename for `VIDEO` lectures.
- `lectures.file_size`: size in bytes.
- `lectures.duration_seconds`: optional best-effort duration from `ffprobe` when available.
- `lectures.upload_status`: `PENDING`, `READY`, or `FAILED`.
- For `VIDEO` lectures, external `url` values are no longer used as the source of truth.

### Environment variables
- `VIDEO_STORAGE_PATH`: storage directory outside `public/`.
- `VIDEO_MAX_SIZE_MB`: multer upload limit in megabytes.
- `VIDEO_SIGNING_SECRET`: HMAC secret for signed media tokens.
- `DOWNLOAD_URL_EXPIRY_MINUTES`: download token lifetime in minutes.
- `DOWNLOAD_TTL_DAYS`: client-side retention hint returned with download links.

### Endpoints

| Method | Path | Role | Purpose |
|---|---|---|---|
| POST | `/api/admin/courses/:id/lectures` | ADMIN | Create a lecture; `VIDEO` lectures require multipart upload in `video` field. |
| POST | `/api/admin/lectures/:id` | ADMIN | Update a lecture; may replace the video file via multipart upload. |
| POST | `/api/teacher/courses/:id/lectures` | TEACHER | Create a lecture for the teacher's own course; `VIDEO` lectures require multipart upload in `video` field. |
| POST | `/api/teacher/lectures/:id` | TEACHER | Update a teacher lecture; may replace the video file via multipart upload. |
| POST | `/api/lectures/:id/stream-url` | STUDENT, TEACHER, ADMIN | Issue a short-lived signed stream URL. Students must currently own the course; staff must own or administer the lecture context. |
| POST | `/api/lectures/:id/download-url` | STUDENT | Issue a longer-lived signed download URL for offline use. |
| GET | `/media/play/:token` | none | Stream a video with HTTP Range support using only the signed token. |
| GET | `/media/download/:token` | none | Download a video with HTTP Range support using only the signed token. |

### Multipart lecture payload

For `VIDEO` lectures, send the request as `multipart/form-data` with:
- `title`
- `type=VIDEO`
- `sort_order`
- `course_id` on admin create, or route param on teacher create
- `video` file field
- `url` must not be present for `VIDEO` lectures

For `TEXT` / `PDF` lectures, the same route still accepts regular fields; `url` remains available for non-video content.

### Stream URL response

`POST /api/lectures/:id/stream-url`

```json
{
  "success": true,
  "data": {
    "url": "/media/play/<signed-token>"
  }
}
```

### Download URL response

`POST /api/lectures/:id/download-url`

```json
{
  "success": true,
  "data": {
    "url": "/media/download/<signed-token>",
    "expires_at": "2026-09-23T12:00:00.000Z",
    "lecture_id": 12,
    "course_id": 5,
    "download_ttl_days": 90
  }
}
```

### Signed media behavior
- Tokens are HMAC-SHA256 signed and short-lived.
- Tokens are verified again on every `GET /media/play/:token` and `GET /media/download/:token` request.
- The media route re-checks current entitlement and publish state before streaming any bytes.
- Raw file paths and internal filenames are never returned to the client.
- Range requests are supported for seeking and download resume.
