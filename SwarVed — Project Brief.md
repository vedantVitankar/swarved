Project Brief

# SwarVed

A music player built from the ground up for one person — not a streaming app with features bolted on, but a private space for songs, voice, and memory to live together.

## What it is

SwarVed is a personal, cross-platform music player (Windows desktop and Android, from one codebase) that plays audio straight from a local folder — no streaming service, no account, no server in between. On its own, that already makes it a fast, private, ad-free player with a distinctive dark, warm-copper visual identity inspired by analog tape decks: folders read like a ledger, listening history reads like a logbook, and every control feels tactile rather than templated.

But the local-library player is the *foundation*, not the point. SwarVed exists to carry something more personal on top of it.

## The personal layer

### Voice interludes, instead of ads

Where a normal app would slot in an advertisement between tracks, SwarVed slots in short voice recordings — things said aloud, meant only for her, surfacing unexpectedly in the middle of a listening session instead of a jingle for something nobody asked for.

### A shared photo blog, inside the player

A running, scrollable collection of photos of the two of you, living inside the same app she already opens to listen to music — so it's discovered naturally, not sent as a separate link she has to remember to check.

### Song of the day / dedications

The ability to push a specific song to her directly, with a note attached to it — "this one's for you, because—" — turning a song recommendation into something closer to a letter.

### The logbook, reframed

The base player already tracks listening history and daily minutes for its own dashboard. In this context, that log quietly becomes a kind of shared diary — what was played, when, and how much — without either of you having to write anything down.

## Where it can go from here

The architecture is intentionally modular — each personal feature is its own self-contained layer on top of the base player, so none of the following requires rebuilding what already exists:

- **Memory lane** — a combined timeline weaving photos, dedicated songs, and dates into one chronological thread of the relationship.
- **Unlockable songs** — tracks that stay hidden until a specific date (an anniversary, a birthday) arrives.
- **Two-way dedications** — not just songs sent one direction, but a small back-and-forth: she sends one back, with her own note.
- **Mood collections** — hand-curated groupings beyond folders ("rainy day," "our road trip," "when you're missing me").
- **Custom themes** — alternate visual identities to pick from, beyond the tape-deck look it launches with.
- **Lock-screen moments** — a short note or photo surfacing on the lock screen alongside now-playing, not just track info.

## A few ideas of my own

Beyond what's already planned, here's where I'd push this further — each one is about creating a specific *moment*, not just adding a feature:

### Time capsules

A message recorded today, sealed, and literally unplayable until a date you set — your anniversary, her birthday, "open this when you miss me." Not a reminder, an actual lock: the app refuses to play it a day early. The waiting is part of the gift.

### Together, right now

A quiet, wordless signal — when you're both listening at the same moment, even to different songs, something small and ambient appears for each of you. No message sent, nothing to reply to. Just a sense of "I'm here too," surfacing on its own.

### Liner notes, in your own hand

Instead of plain metadata, certain songs carry a short note rendered in a handwriting-style font (or an actual photographed note) — the way vinyl sleeves used to carry a few lines explaining why a track mattered, except these are written for an audience of one.

### A constellation, not a folder list

For the songs that actually mean something, an alternate view: each one a point of light, with lines drawn between songs tied to the same memory. Not a replacement for the folder ledger — a second way to look at the handful of songs that aren't just songs.

### Year in songs

Once a year — timed to land on your anniversary — a short, auto-generated recap: not generic "top tracks," but the actual dedications, photos, and logged listening from that year, folded into one thing she opens and scrolls through.

### Small, unannounced delight

The tiny moments: a short affectionate line in place of a generic loading spinner, a brief flourish the first time a newly-dedicated song plays. None of it load-bearing — just texture that makes the app feel considered rather than assembled.

## How it's built

SwarVed is built in Flutter, which is what lets one codebase ship as both a Windows application and an Android app without maintaining two separate projects. Every piece of personal content — voice recordings, photos, dedications — lives on-device by default; nothing is uploaded anywhere unless that's deliberately built and secured later. The codebase itself is organized so that theme, data models, business logic, and each screen are cleanly separated files, specifically so new features (like the ones above) can be added as their own layer without touching or risking what already works.

built for her — swarved · a private player, not a product