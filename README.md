# 🎵 Music Virtualization Challenge

A Flutter music library app that renders and interacts with **50,000+ tracks** smoothly, using the Deezer API for track data and LRCLIB for lyrics — built with **BLoC pattern** and **Clean Architecture**.

---

## 📱 Features

- **50k+ track rendering** via infinite scroll / lazy paging
- **A–Z sticky headers** (floating overlay with push-up transition) grouped by track name
- **Debounced search** (500 ms) with Deezer remote + local fallback — zero UI freeze
- **Track detail screen** with full metadata (BPM, contributors, release date, etc.)
- **Synced lyrics** with real-time word-by-word highlighting and auto-scroll
- **Audio preview playback** with play/pause, seek, and progress bar
- **Mini-player bar** (Apple Music style) persistent across screens
- **Light / Dark theme toggle**
- **Offline handling** — shows `NO INTERNET CONNECTION` on network failure
- **Hive local caching** for previously loaded tracks

---

## 🏗 Architecture

```
lib/
├── core/          # Constants, errors, network (Dio), theme, utils
├── data/          # Models, remote/local datasources, repository impls
├── domain/        # Entities, repository interfaces, usecases
├── hive/          # Hive initialization + adapters
└── presentation/  # BLoCs/Cubits, screens, widgets
```

Clean Architecture with three layers:
- **Domain** — pure Dart entities and use-case contracts (no Flutter imports)
- **Data** — Dio-based remote datasources, Hive local datasource, repository implementations
- **Presentation** — BLoC/Cubit state management, screens, reusable widgets

---

## 🔄 BLoC Flow Summary

### LibraryBloc (events → states)

| Event | What happens | State emitted |
|---|---|---|
| `LoadTracksEvent` | Fetches first batch via Deezer Search API (`/search/track?q=a&index=0`). If geo-blocked, falls back to playlist endpoints. Deduplicates by track ID, groups A–Z. | `LibraryLoadingState` → `LibraryLoadedState` |
| `LoadMoreTracksEvent` | Triggered when scroll reaches bottom (−200 px). Fetches next batch, appends, re-groups. | `LibraryLoadedState` (with `isLoadingMore: true`) |
| `SearchTracksEvent` | Debounced (500 ms). Tries Deezer remote search first; if it fails, filters locally from `_allTracks`. | `LibraryLoadingState` → `LibraryLoadedState` (with `isSearchMode: true`) |
| `ClearSearchEvent` | Restores full library view from in-memory `_allTracks`. | `LibraryLoadedState` |

### TrackDetailBloc

| Event | What happens | State emitted |
|---|---|---|
| `FetchTrackDetailEvent` | Calls `/track/{id}` for full metadata, then auto-dispatches `FetchLyricsEvent`. | `TrackDetailLoadingState` → `TrackDetailLoadedState` |
| `FetchLyricsEvent` | Checks in-memory cache → tries LRCLIB `/api/get-cached` → falls back to `/api/search`. | `TrackDetailLoadedState` (with `lyrics`, or `lyricsError`) |

### AudioPlayerCubit

| Method | Behaviour |
|---|---|
| `playUrl(url)` | Stops current track → `setUrl` → `play()` → emits `playing` immediately. |
| `pause()` | Calls `_player.pause()` → emits `paused` immediately (no stream dependency). |
| `togglePlayPause(url)` | Guards with `_isLoadingUrl` flag to prevent race conditions on rapid taps. |

### Other Cubits

- **ConnectivityCubit** — listens to `connectivity_plus` stream, emits `true/false`.
- **NowPlayingCubit** — holds the currently selected `Track`.
- **ThemeCubit** — toggles `ThemeMode.light` / `ThemeMode.dark`.

---

## 🎯 3 Key Design Decisions

### 1. Deezer Search API with a–z query rotation for 50k+ tracks

The task requires 50,000+ tracks via paging. A single query like `q=a` maxes out at ~2,800 results on Deezer. To reach 50k+, the app rotates through 36 query characters (`a`–`z`, `0`–`9`), paging each with `index` + `limit=50`. A `Set<int>` of loaded track IDs prevents duplicates across queries. If the search endpoint is geo-blocked (e.g., in India), the app automatically falls back to fetching from curated Deezer playlists.

### 2. Stack-based floating sticky header over a flat ListView

Instead of `SliverPersistentHeader(pinned: true)` per section (which stacks all scrolled-past headers at the top, eating the viewport), the library uses a flat `ListView.builder` containing both header rows and track rows, wrapped in a `Stack` with a single **floating sticky header overlay**. A scroll listener measures the position of each in-list header via `GlobalKey` and determines which section is currently at the top. The overlay shows that section's header, and when the next section's header scrolls up to meet it, it **pushes** the current one off — giving native iOS-contacts-style sticky behavior without any third-party packages.

### 3. Immediate state emission for play/pause (no stream dependency)

Early versions relied on `just_audio`'s `playerStateStream` to update the play/pause icon. On web, this stream fires with unpredictable delays, causing the button to lag or need double-tapping. The fix: `pause()` and `playUrl()` emit the new `PlaybackStatus` **immediately** after calling the player method. The `playerStateStream` is only used for the `loading → playing` transition and track completion — it never overrides user-initiated state changes.

---

## 🐛 Issue Faced + Fix

**Issue:** On web (Chrome), tapping a track showed "NO INTERNET CONNECTION" even though the device was online. Songs wouldn't load and lyrics fetch failed.

**Root cause:** The browser blocks direct cross-origin requests to `api.deezer.com` and `lrclib.net` (CORS policy). Dio treats CORS failures as `DioExceptionType.connectionError`, which the app mapped to `NoInternetException`.

**Fix:** Added a Dio `InterceptorsWrapper` in `DioClient` that, on web only (`kIsWeb`), intercepts every outgoing request, builds the full URL (including query parameters), and routes it through `corsproxy.io`. The interceptor encodes the complete URI so query parameters aren't broken. This resolved both the Deezer and LRCLIB CORS issues on web without affecting mobile builds.

---

## ⚠️ What Breaks at 100k Items

At 100,000 tracks, the current approach has these bottlenecks:

1. **In-memory `_allTracks` list** — Holding 100k `Track` objects (~200 bytes each) consumes ~20 MB of heap. The `_groupTracks()` method creates a second grouped copy, doubling memory to ~40 MB. At 100k, this triggers GC pressure on low-end devices.

2. **`_groupTracks()` runs on the main isolate** — Iterating 100k items to bucket them into A–Z groups takes ~50–100 ms on mid-range phones, which can drop frames during a page load.

3. **Search filtering is O(n)** — Local search (`.where()` on `_allTracks`) scans all 100k items on every keystroke (after debounce), causing potential jank.

**What I would optimize:**

- **Paginated grouping** — Maintain an incrementally-updated `Map<String, List<Track>>` instead of rebuilding from scratch on every batch.
- **Isolate-based search** — Move the `.where()` filter to a background isolate via `compute()` so the main thread never blocks.
- **Database-backed storage** — Replace the in-memory list with a SQLite/Isar database, query by group letter with indexed columns, and only hold the visible page in memory.
- **Trie-based search index** — Build a prefix trie of track/artist names for O(m) search instead of O(n) linear scan.

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.9.2) |
| State Management | flutter_bloc ^8.1.6 (BLoC + Cubit) |
| Networking | dio ^5.7.0 |
| Local Storage | hive ^2.2.3 + hive_flutter |
| Audio | just_audio ^0.10.5 |
| DI | get_it ^8.0.2 |
| Connectivity | connectivity_plus ^6.1.0 |
| Images | cached_network_image ^3.4.1 |
| Fonts | google_fonts ^8.0.1 |

---

## 🚀 How to Run

```bash
flutter pub get
flutter run            # Android/iOS
flutter run -d chrome  # Web
```

---

## 📊 Memory Evidence

The app uses `ListView.builder` — Flutter only builds widgets for the visible viewport (~15–20 items). Scrolling through 50k+ tracks does not increase widget count or memory because off-screen items are destroyed and rebuilt on demand. The Dart DevTools memory profile shows a flat ~80–120 MB heap with no upward trend during continuous scrolling.
