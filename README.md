# hl2rp

**Combine Conscript Roleplay** - a [Helix](https://helixframework.org/) schema
for Garry's Mod, built around the Combine Civil Authority's chain of command.
Every character starts out as an unranked **Conscript** and is promoted up
through Private, Corporal, Sergeant, Overwatch Elite and Elite Commander by
server staff. A separate **City Resident** faction is included so there are
civilians for Civil Protection to actually police.

## Requirements

- A Garry's Mod dedicated server (or listen server) with **Half-Life 2** base
  content mounted, for the stock CP/Combine player models and weapons.
- The [Helix framework](https://github.com/NebulousCloud/helix) installed as
  a base gamemode (`garrysmod/gamemodes/helix`). This schema derives from it
  and will not load without it.

## Installation

1. Install Helix itself into `garrysmod/gamemodes/helix` per the framework's
   own instructions.
2. Clone this repo into `garrysmod/gamemodes/` as `hl2rp`, so you end up with
   `garrysmod/gamemodes/hl2rp/hl2rp.txt`.
3. Set your server to run it, e.g. in `server.cfg`:
   ```
   gamemode hl2rp
   map rp_city17_v1
   ```
4. Start the server. On first load Helix will build its database tables
   automatically.

## What's in here

- `gamemode/` - the minimal schema boilerplate (`DeriveGamemode("helix")`
  plus the `SCHEMA` table).
- `schema/factions/` - `Civil Protection` and `City Resident`, both open
  (unwhitelisted) factions.
- `schema/classes/` - the six-rank Civil Protection ladder. Only
  `Conscript` is selectable on its own; every rank above it requires an
  admin to whitelist it onto the character first.
- `schema/items/` - stunstick, pistol, SMG, an inspectable ID card, and a
  consumable armor repair kit.
- `schema/sh_commands.lua` - `/ccsetrank <player> <rank>`, the admin command
  used to promote (or demote) a Civil Protection character. Valid rank
  keywords: `conscript`, `private`, `corporal`, `sergeant`, `elite`,
  `commander`.
- `schema/config.lua` - sets the in-character currency to "Combine credits".

## Extending it

This is a base to build on, not a finished server:

- No custom HUD, F1 menu tabs, or scoreboard yet - Helix's defaults are used.
- No dispatch/radio system, checkpoints, or Nova Prospekt-style detention
  gameplay - these would be schema plugins under `schema/plugins/`.
- No map is bundled. Combine RP servers commonly use `rp_city17` variants or
  a custom City 17-style map; pick one that supports Helix's spawn/entity
  conventions.
- Rank promotion is entirely staff-driven via `/ccsetrank`. If you want
  in-game progression (playtime, exams, NPC processing), that belongs in a
  new plugin rather than the class files themselves.

## A note on accuracy

This schema was written to the publicly documented Helix conventions
(`DeriveGamemode`, the `schema/factions|classes|items|languages` auto-load
folders, `ix.command.Add`, `character:hasClassWhitelist`/`classWhitelist`,
etc.), but it has **not been run against a live Helix install** in this
environment (no Garry's Mod runtime here). If your Helix version renamed any
of those character methods, you'll see a clear Lua error naming the missing
function on load - check the Helix changelog/wiki for the current name and
adjust `schema/classes/*.lua` and `schema/sh_commands.lua` accordingly.
