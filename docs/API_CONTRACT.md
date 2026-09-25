# Salama Health — API contract

What the mobile app sends and what it expects back. Every field listed here is
read by the Flutter client today; anything the app can live without is marked
**optional**, and the app's fallback is stated.

- Base URL is compiled in: `--dart-define=API_BASE_URL=https://api.example.org`
  (default `http://54.205.9.90`).
- All requests except login and refresh carry `Authorization: Bearer <accessToken>`.
- Errors should return `{"detail": "human readable message"}`; the app shows
  `detail` verbatim, so write it for a health worker, not a developer.
- Timestamps are ISO-8601 UTC. Dates without a time are `YYYY-MM-DD`.
- The app treats a connection failure differently from a rejection. A 4xx/5xx is
  shown as an error; an unreachable server falls back to cached data and queues
  writes. Do not return 200 with an error body.

---

## 1. Auth

### POST `/auth/login`
No auth header.

```json
{ "workerId": "CHW-0142", "pin": "1234" }
```

```json
{
  "accessToken": "<jwt>",
  "refreshToken": "<jwt>",
  "worker": {
    "id": "uuid",
    "name": "Nyakuma Deng",
    "role": "Community Health Worker",
    "workerId": "CHW-0142",
    "facility": "Bentiu PHCC",
    "county": "Rubkona",
    "phone": "+211920000000",
    "facilitiesCount": 4,
    "active": true
  }
}
```

### POST `/auth/refresh`
No auth header. Called automatically on any 401.

```json
{ "refreshToken": "<jwt>" }
```
→ `{ "accessToken": "<jwt>" }`

Return **401** only when the refresh token is genuinely invalid — that signs the
worker out of the device.

### GET `/auth/me`
→ the same `worker` object as above.

> **Important:** the app only discards a session on a real `401`. Any other
> failure (timeout, 500, no connection) keeps the session and falls back to the
> cached profile. Do not return 401 for transient server problems.

### POST `/auth/change-pin` *(new — Security screen)*
```json
{ "currentPin": "1234", "newPin": "8391" }
```
→ `200` with any body. Return `400`/`401` with `detail` on a wrong current PIN.

---

## 2. Children

### GET `/children?status=`
`status` is optional (`toVisit` | `visited` | `missed`). Returns the signed-in
worker's caseload as an array.

```json
[{
  "id": "uuid",
  "qrCode": "SSD-7K4M-2Q9X",
  "name": "Nyawal Gatluak",
  "gender": "F",
  "bornDate": "2025-03-14",
  "riskScore": 0.92,
  "distanceKm": 3.4,
  "lastSeen": "2026-08-30T09:12:00Z",
  "currentLocation": "Rubkona",
  "parentName": "Nyalel Gatluak",
  "parentPhone": "+211920111222",
  "facilityId": "uuid",
  "workerId": "uuid",
  "latitude": 9.38,
  "longitude": 29.82,
  "dueVaccines": ["Penta-2", "PCV-2"],
  "status": "toVisit",
  "history": [
    { "vaccine": "BCG", "dose": "1", "date": "2025-03-14", "status": "given", "batch": "B-2231" }
  ]
}]
```

**Risk bands** are derived client-side from `riskScore`: `>= 0.90` high,
`>= 0.80` elevated, `>= 0.72` watch, below that routine. Keep the scale 0–1.

`history[].status` is `given` | `due` | `missed`. `history` is **optional** here
(the list view does not need it) but must be present on the detail endpoint.

### GET `/children/{id}`
One child, same shape, `history` required.

### GET `/children/lookup?qr=`
Resolve a scanned code. The app strips a leading `SALAMA:CHILD:` prefix before
sending, so match on the bare code (`SSD-7K4M-2Q9X`). Return **404** when not
found — the scanner then falls back to the cached caseload.

### POST `/children` — registration
Sent when a child is registered with a connection. The identical object is sent
inside `newChildren[]` on `/sync/upload` when registered offline, so **both
paths must accept the same body**.

```json
{
  "clientUuid": "9f1c...-uuid-v4",
  "qrCode": "SSD-7K4M-2Q9X",
  "name": "Nyawal Gatluak",
  "gender": "F",
  "bornDate": "2025-03-14",
  "bornDateEstimated": true,
  "parentName": "Nyalel Gatluak",
  "parentPhone": "+211920111222",
  "currentLocation": "Rubkona",
  "distanceKm": 3.4,
  "facilityId": "uuid",
  "dueVaccines": ["BCG", "OPV-0", "Penta-1"],
  "notes": "Twin sibling registered same day",
  "consentGiven": true,
  "consentAt": "2026-09-24T08:41:00Z",
  "registeredBy": "CHW-0142",
  "registeredAt": "2026-09-24T08:41:00Z"
}
```

Notes for the backend:
- `qrCode` is **generated on the device** so the caregiver can be handed a code
  immediately, with or without signal. Treat it as the child's code; reject a
  duplicate with `409`. If you must reassign one, return the authoritative code
  in the response — the app displays what you return.
- `clientUuid` is the idempotency key. The same registration may arrive twice
  (once live, once in a sync batch) after a flaky connection. Second arrival →
  no new row.
- `bornDateEstimated: true` means the worker picked an age bracket, not a date.
  Worth storing — it affects how much to trust schedule calculations.
- `consentGiven` is always `true`; the app refuses to submit otherwise. Store
  `consentAt` — it is the record that consent was taken before registration.
- Response is a full child object (as in GET `/children`).

### PATCH `/children/{id}`
Partial update, same field names. Currently unused by the UI but wired.

---

## 3. Vaccinations

### GET `/vaccinations?childId=`
→ array of `history[]` objects (see above).

### POST `/vaccinations`
```json
{
  "childId": "uuid",
  "vaccine": "Penta-2",
  "dose": "2",
  "batchNumber": "B-2231",
  "status": "given",
  "dateGiven": "2026-09-24T08:41:00Z",
  "clientUuid": "uuid"
}
```
→ the created record. `dose` and `batchNumber` are optional. `clientUuid` is the
idempotency key, as above.

---

## 4. Facilities

### GET `/facilities?assignedOnly=true`
```json
[{
  "id": "uuid",
  "name": "Bentiu PHCC",
  "county": "Rubkona",
  "state": "Unity State",
  "children": 412,
  "cdiScore": 0.82,
  "risk": "High",
  "hazard": "Flooding",
  "daysToWindow": 6,
  "hazardDetail": "Seasonal flooding is forecast to cut the Bentiu–Rubkona road.",
  "hazardTimeframe": "10–14 days",
  "highPriority": 38,
  "dueSoon": 91,
  "recentlyVisited": 26,
  "assigned": true
}]
```

- `risk` is one of `Critical` | `High` | `Medium` | `Low`. The app collapses
  Critical/High into one red band.
- `cdiScore` 0–1. The app treats **`>= 0.75` as a cold-chain alert**, below that
  as a general climate alert.
- `county` and `state` are joined for display.
- `daysToWindow` `0` means the disruption is already active.

### GET `/facilities/{id}`
Same object.

---

## 5. Activity

### GET `/activity?limit=50`
```json
[{
  "type": "vaccination",
  "title": "Penta-2 given to Nyawal Gatluak",
  "subtitle": "Rubkona · batch B-2231",
  "createdAt": "2026-09-24T08:41:00Z"
}]
```
`type` is `vaccination` | `visit` | `sync` | `alert` | `registration`. Anything
else renders as `visit`.

---

## 6. Reports

### GET `/reports/summary`
```json
{ "dosesThisMonth": 214, "coverageRate": 0.78, "childrenReached": 168, "dropoutRate": 0.12 }
```
Rates are 0–1, not percentages.

### GET `/reports/doses-weekly`
```json
{ "days": [ { "label": "Mon", "count": 24 } ] }
```

### GET `/reports/coverage-by-vaccine`
```json
{ "vaccines": [ { "name": "BCG", "coverage": 0.91 } ] }
```

---

## 7. Routes

### GET `/routes/optimized`
```json
{
  "stops": [{
    "childId": "uuid",
    "childName": "Nyawal Gatluak",
    "riskBand": "High",
    "distanceKm": 3.4,
    "latitude": 9.38,
    "longitude": 29.82,
    "currentLocation": "Rubkona",
    "order": 1
  }],
  "totalKm": 18.6,
  "estMinutes": 240
}
```
`riskBand` is `High` | `Medium` | `Watch` | `Low`. Order the array as it should
be walked; `order` is displayed to the worker.

---

## 8. Sync

### GET `/sync/status`
```json
{ "lastSync": "2026-09-24T06:10:00Z", "pendingRecords": 0 }
```
`pendingRecords` is anything the **server** knows is outstanding; the app adds
its own local queue count on top. When this endpoint is unreachable the app
falls back to the local count alone, so it never reports "0 waiting" while work
sits on the phone.

### POST `/sync/upload`
```json
{
  "vaccinations": [ { "...": "as POST /vaccinations" } ],
  "newChildren":  [ { "...": "as POST /children" } ],
  "visits":       [ {
      "clientUuid": "uuid",
      "childId": "uuid",
      "status": "visited",
      "visitedAt": "2026-09-24T08:41:00Z",
      "routeOrder": 3
  } ]
}
```

Response:
```json
{
  "vaccinationsSaved": 4,
  "childrenSaved": 1,
  "visitsSaved": 7,
  "duplicatesSkipped": 2,
  "errors": []
}
```

Rules that matter to the client:
- **De-duplicate on `clientUuid`.** A batch may be uploaded twice.
- The app **clears its queue on a 2xx**, so a partial success must still report
  what failed in `errors[]` — anything you silently drop is gone from the phone.
- All three arrays may be empty.
- `visits[].status` is `visited` | `skipped` (skipped comes from the route
  runner).

---

## 9. Alerts *(new — optional)*

### GET `/alerts`
If this endpoint exists and returns a non-empty array, it drives the Alerts
screen and the bell badge. If it 404s or fails, the app derives alerts on-device
from facility risk, overdue children and the offline queue — so shipping it is
an upgrade, not a prerequisite.

```json
[{
  "id": "stable-id",
  "kind": "coldChain",
  "severity": "critical",
  "title": "Cold chain at risk — Bentiu PHCC",
  "body": "Forecast highs above 38°C for five days with no backup power.",
  "action": "Move doses forward and pre-position vaccines",
  "facilityId": "uuid",
  "childId": null,
  "daysToWindow": 3,
  "createdAt": "2026-09-24T06:00:00Z"
}]
```

- `kind`: `coldChain` | `climate` | `overdueChild` | `coverage` | `sync`
- `severity`: `critical` | `warning` | `info`
- `id` **must be stable across requests** — read/unread state is stored against
  it on the device. A regenerated id makes a dismissed alert reappear.
- `facilityId` / `childId` make the alert tappable through to that record.

---

## Implementation order

If the backend is being built from scratch, this order unblocks the app fastest:

1. `/auth/login`, `/auth/refresh`, `/auth/me` — nothing works without these.
2. `/children`, `/children/lookup` — the caseload and the scanner.
3. `/vaccinations` POST — the core action.
4. `/sync/status`, `/sync/upload` — makes offline work real.
5. `/facilities` — the climate-risk story on the home screen.
6. `/children` POST — registration (the queue already carries it via sync).
7. `/reports/*`, `/routes/optimized`, `/activity`.
8. `/alerts`, `/auth/change-pin` — both have working fallbacks.
