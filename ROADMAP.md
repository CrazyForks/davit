# Roadmap — from HN feedback (Show HN, 82 pts)

Thread: https://news.ycombinator.com/item?id=48821848

Inventory of suggestions from the thread plus feature gaps vs. the two sibling
projects mentioned (contained-app, berth). Not commitments — a menu to prioritize.

## A. Direct suggestions from the thread

Status: **Wave 1 done** (shipped in `48a8a6a`, live on davit.app). The only
remaining A item is #2 (file browsing), intentionally scheduled in Wave 2.

| # | Suggestion | Who | Type | Status |
|---|---|---|---|---|
| 1 | Getting-started tutorial on the site: a good demo image; the run dialog's `nginx:latest` default is a weak demo | simonw | Docs/site | ✅ done — 2-min walkthrough on site + README, `nginxdemos/hello` demo, pull-sheet suggestion updated |
| 2 | In-container file browsing (list/download/upload/delete files inside a container) | neodymiumphish (also in contained-app) | Feature | ✅ done — Files tab (Wave 2) |
| 3 | State the memory footprint — "Docker Desktop is a memory hog, what's Davit's?" | ballislife30 | Docs | ✅ done — FAQ (architectural framing; platform idles ~25 MB) |
| 4 | Host→container name resolution / DNS | nvahalik; dofm suggests an Avahi/zeroconf alias trick | Docs (now) / feature (later) | ✅ doc done — FAQ documents the Avahi mDNS trick; built-in resolution still a later feature |
| 5 | OrbStack comparison + efficiency framing | oulipo2 | Docs/FAQ | ✅ done — FAQ |
| 6 | Menu bar integration | mrbnprck | — | ✅ already shipped |

## B. Feature gaps vs. contained-app / berth (context, not asks)

| Feature | Them | Us | Effort | Notes |
|---|---|---|---|---|
| Docker Compose import (parse compose → forms / multi-container run) | both | ✗ | L | apple/container has no native compose; we'd parse + create N containers |
| Registry login management (keychain creds) | both | ✗ | M | CLI had `registry login`; API likely exposes it — verify |
| "Reveal the `container` CLI command" before an action | contained-app | ✗ | S | Cheap trust/教学 win; we already build equivalent arg arrays |
| Global search across containers/images/volumes/networks | berth | partial (per-tab search) | M | |
| Image build from Dockerfile | contained-app (exp.) | ✗ | L | builder shim; heavier |
| Per-image tag/registry actions, Docker Hub search | contained-app | partial (tag only) | M | |
| File browsing | contained-app | ✗ | M | = item 2 |

## C. Proposed sequencing

**Wave 1 — quick, high-leverage (mostly docs) — ✅ DONE (`48a8a6a`, live):**
- (1) ✅ Getting-started section on davit.app + README using `nginxdemos/hello`.
- (5) ✅ OrbStack/Docker comparison + (3) ✅ memory FAQ (architectural framing).
- (4) ✅ Documented the Avahi alias trick for host→container name resolution.
- (6) ✅ Menu bar already shipped.

**Wave 2 — contained, high-value features:**
- (2) ✅ In-container **file browser** — Files tab: breadcrumb navigation, download
  (copyOut), upload (copyIn), delete; portable listing via `stat` with an `ls`
  fallback. Backend covered by a selftest step.
- "Reveal CLI command" affordance on run/exec/etc. — small, builds trust. (next)

**Wave 3 — bigger bets (pick based on demand):**
- Registry login management (unblocks private images cleanly).
- Docker Compose import (most-requested class of feature in this space).
- Image build from a Dockerfile.

## Feasibility notes (grounded in the API)
- File browsing: `ContainerClient.exec` + `copyIn`/`copyOut` exist — no new daemon capability needed.
- Registry login: the platform had `container registry login`; confirm the client surface before scoping.
- Compose/build: larger; build needs the builder shim, compose is pure app-side orchestration.
