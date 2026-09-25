# Salama Health — API contract

What the mobile app sends and what it expects back. Every field listed here is
read by the Flutter client today; anything the app can live without is marked
**optional**, and the app's fallback is stated.

- Base URL is compiled in: `--dart-define=API_BASE_URL=...`
  (default `https://salamahealth.duckdns.org`, TLS via Let's Encrypt). Plain
  HTTP 308-redirects to HTTPS, and the app permits cleartext only to loopback
  hosts for local development.
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
    "active": true,
    "supportEmail": "support@example.org",
    "supportPhone": "+211920000000"
  }
}
```

`county` and `facility` are **not optional in practice**: the app header shows
`county • facility` on every main screen and renders nothing there if they are
missing. `supportEmail` / `supportPhone` drive the Contact support sheet; leave
them out and it tells the worker to go to their supervisor rather than showing a
placeholder address.

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

### POST `/auth/change-pin` — **not deployed yet**
A `404` is reported to the worker as "not available on the server yet, ask your
supervisor to reset it", rather than as a wrong PIN.

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

**Risk bands.** Send `riskBand` (`High` | `Medium` | `Watch` | `Low`) and the app
uses it directly. When it is absent the app derives one from `riskScore` using
the cut-offs fitted to the live distribution on 25 Sep 2026:

| Band | Score |
|---|---|
| High | ≥ 0.193 |
| Medium | ≥ 0.068 |
| Watch | ≥ 0.022 |
| Low | < 0.022 |

The index is soft-capped, normalised and multiplicative, so scores cluster low —
p90 is 0.193, not 0.90. These split the caseload roughly 10/20/30/40 percent.
The app's display wording (High priority / Elevated / Watch / Routine) is a
presentation layer over the same four bands.

**`riskPending`** (optional, default false): true means the model has not scored
this child yet, and the app shows "Awaiting score" instead of a band. Omitting
`riskScore` entirely has the same effect.

**A `riskScore` of exactly `0.0` is a real result**, not a missing one — the index
is multiplicative, so a child with no vaccination debt scores zero, meaning fully
up to date. The app treats 0.0 as a genuine Low band; only an absent score counts
as unscored. About 11% of children are legitimately at zero.

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

> **Currently accepted and discarded** (25 Sep): `consentGiven`, `consentAt`,
> `bornDateEstimated`, `dueVaccines`, `notes`, `registeredBy`, `registeredAt`.
> The app keeps sending them so nothing changes here when storage lands. Until
> it does, **a 200 from this endpoint is not evidence that consent was
> recorded** — the app keeps its own local consent log
> (`ConsentLogRepository`, exportable as CSV from App settings) so registrations
> made in the meantime can be reconciled rather than left unattested.
> `site` on `POST /vaccinations` is dropped the same way.

### PATCH `/children/{id}`
Partial update, same field names. Currently unused by the UI but wired.

---

## 3. Vaccinations

### GET `/vaccinations?childId=`
→ array of `history[]` objects (see above).

This is what the medical-history timeline reads when it opens. Until it answers
the app shows the `history` that came with the child, so a slow response degrades
to slightly thinner history rather than an empty screen.

### POST `/vaccinations`
```json
{
  "childId": "uuid",
  "vaccine": "Penta-2",
  "batchNumber": "B-2231",
  "site": "Left arm",
  "notes": "Caregiver reported mild fever after the last dose",
  "status": "given",
  "dateGiven": "2026-09-24T08:41:00Z",
  "clientUuid": "uuid"
}
```
→ the created record. `batchNumber`, `site` and `notes` are optional — `site` and
`notes` are recorded by the dose sheet and were previously dropped on the floor.
`clientUuid` is the idempotency key, as above.

**The identical object** is what appears in `vaccinations[]` on `/sync/upload`, so
one handler serves both paths.

---

## 3b. Visits *(new)*

### POST `/visits` — **not deployed yet**
Sent as each stop of a route is completed. Until the route exists, a `404`/`405`
is treated as "not built" rather than a refusal: the visit goes to the outbox and
reaches the server in `visits[]` on `/sync/upload`. Nothing in the app needs to
change when it lands.

```json
{
  "clientUuid": "uuid",
  "childId": "uuid",
  "status": "visited",
  "visitedAt": "2026-09-24T08:41:00Z",
  "routeOrder": 3
}
```

- `status` is `visited` | `skipped`.
- Same body as the entries in `visits[]` on `/sync/upload`; same idempotency key.
- A rejection is shown to the worker but does not stop the route — the next stop
  is always reachable.

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
  "assigned": true,
  "sarObservedAt": "2026-09-25"
}]
```

- `risk` is one of `Critical` | `High` | `Medium` | `Low`. The app collapses
  Critical/High into one red band.
- `cdiScore` 0–1. The app treats **`>= 0.75` as a cold-chain alert**, below that
  as a general climate alert.
- `county` and `state` are joined for display.
- `daysToWindow` `0` means the disruption is already active.
- `sarObservedAt` (optional) is the date of the satellite radar pass behind the
  score. **Null means the score came from seasonal estimates rather than an
  actual pass**, which is materially weaker evidence — the facility sheet says
  "Seasonal estimate — no radar pass" so a worker moving a vaccine run knows
  what they are acting on.
- `state` comes back as `"Unity"`, not `"Unity State"`; the app joins county and
  state for display either way.

### GET `/facilities/{id}`
Same object. Fetched when a facility's detail sheet opens, because the CDI score
and hazard window are forecasts that move during the day. The copy from the list
is shown until it answers.

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
{
  "dosesThisMonth": 214,
  "coverageRate": 0.78,
  "childrenReached": 168,
  "dropoutRate": 0.12,
  "period": "September 2026"
}
```
Rates are 0–1, not percentages.

`period` (optional) is the label the app shows on the Reports chip and on the
exported report. Send it whenever the figures cover something other than the
device's current month — without it the app falls back to the phone's clock,
which will disagree with you at a month boundary or in another timezone.

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

### GET `/devices/alerts`
Currently served under `/devices`; the client points there. If it returns a
non-empty array it drives the Alerts screen and the bell badge. If it 404s or fails, the app derives alerts on-device
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
7. `/vaccinations` GET, `/children/{id}`, `/facilities/{id}` — fuller detail on
   open; each degrades to the copy the app already holds.
8. `/visits` POST — live visit outcomes (the sync batch already carries them).
9. `/reports/*`, `/routes/optimized`, `/activity`.
10. `/alerts`, `/auth/change-pin` — both have working fallbacks.

Every path the client calls is declared in one file,
[`lib/core/api/api_routes.dart`](../lib/core/api/api_routes.dart) — check it
against this document rather than grepping the repositories.
