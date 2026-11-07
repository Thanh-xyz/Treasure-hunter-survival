# Multiplayer Architecture Specification

- Stage: BRAINSTORM · 2026-11-07
- Builds on: `LanSession` (ENet UDP 24567, `PROTOCOL_VERSION 5`, `MAX_CLIENTS 3` → 4 players,
  host-authoritative monsters/combat/loot/potions/respawn, loot reservation + ACK, disconnect
  replay) and the approved layering in `docs/reports/gameplay-architecture.md`.

## 1. Principles

1. **Offline is the reference authority.** Every rule runs as a pure function or command that
   the offline game calls directly and the LAN host calls on behalf of peers.
2. **Clients send intents, hosts send facts.** No client ever mutates shared state or its own
   inventory from a shared source without host confirmation.
3. **Every mutation is idempotent** (`op_id` per request). Retries can't duplicate items.
4. **Transport is an adapter.** ENet today; a future online server reuses the same command and
   snapshot schemas.

## 2. Layering

```text
Presentation (scenes, HUD)  ──commands──►  CommandBus
                                             │
               ┌─────────────────────────────┼─────────────────────────┐
               ▼ offline                      ▼ LAN client               ▼ LAN host
        LocalAuthority                 RemoteAuthority (RPC)      HostAuthority
        (executes rules)               (sends intent, awaits      (validates, executes rules,
                                        fact)                      broadcasts facts)
               └──────────────► Pure rules: Combat, StatBlock, Inventory.transact,
                                 Recipes, Gathering, Building validation, Loot, Quests
```

New: a `CommandBus` autoload and an `Authority` interface with three implementations. Existing
`LanSession` RPC handlers are refactored gradually into `HostAuthority` handlers. This is
incremental: each system moves when it gets LAN support.

## 3. Ownership model

| State | Owner | Persisted in |
| --- | --- | --- |
| Character (level, stats, heroes, skills) | the peer's own save; host keeps a session copy | peer save |
| Inventory / pouch / equipment | peer save; **all changes during LAN are host-validated** | peer save (committed on host confirm) |
| World state (terrain breaks, nodes, chests, outposts, bosses, clock, events) | host | host world save |
| Shared homestead | host | host save |
| Monsters, projectiles, loot drops | host | not persisted (except boss timers) |
| Pets and mounts (simulation) | host, as allies of a peer | peer save (progression) |
| Kindled Keys | host | host world save + peer bag on commit |

### Anti-dupe on peer-owned inventory
The host keeps an **escrow ledger** per peer for the session: every grant or consume has an
`op_id`, the peer commits it locally on the ACK, and the host replays unacknowledged ops on
reconnect (generalising today's loot reservation and potion confirmation). On session end, the
peer save and the host ledger reconcile. Mismatches are logged and the host's version wins.

## 4. System synchronisation matrix

| System | Today | Target | Messages |
| --- | --- | --- | --- |
| Transforms, zone | ✅ | ✅ + interpolation tuning | snapshot 20 Hz |
| Monster spawn/HP/death | ✅ | ✅ + statuses, elites, bosses' phases | batch 10 Hz |
| Player HP/death/respawn | ✅ | ✅ + dodge i-frames, statuses | |
| Hit requests | ✅ | ✅ + skill casts via `CastSkill(skill, aim)` | intent → result |
| Loot drops + capacity ACK | ✅ | ✅ + bound items, pouch routing | |
| Potions | ✅ | ✅ all consumables | |
| Equipment / enhancement / runes | ❌ | host-validated commands | `Equip`, `Enhance`, `Socket` |
| Crafting | ❌ | host-validated; station ownership | `Craft(recipe, station_uid)` |
| Gathering / terrain | ❌ | host-owned node/tile state | `Gather(node_uid)`, tile delta batches |
| Chests / dig plots / maps | ❌ | host roll, peer receive | |
| Buffs | ❌ | host-timed | |
| Quests | ❌ | per-peer progress; host emits shared events (kills, boss) with credit lists | |
| Pets / mounts | ❌ | host simulation, peer commands | |
| Building (shared homestead) | ❌ | host validation, permission levels | `Place`, `Upgrade`, `Move` |
| Kindled Key | ❌ | host-owned, carrier broadcast | |
| World clock / events | ❌ | host clock broadcast every 5 s | |
| PvP | ❌ | opt-in duel flag, arena mode, Ashen Wastes PvP | `DuelRequest`, `PvPHit` |

## 5. Session lifecycle

- **Discovery**: manual IP (existing) plus UDP broadcast LAN discovery (new).
- **Join**: protocol version check (exists), plus a content-hash check (GameContent version) so
  mismatched builds are rejected cleanly.
- **Capacity**: host + 3 clients (`MAX_CLIENTS 3`, already 4 players).
- **Reconnection**: each peer gets a session token. A rejoin within 120 s restores the slot,
  position and the escrow ledger. After that, the peer's character is released.
- **Host loss**: clients fall back to their offline save plus committed ledger (existing
  disconnect replay generalised). No host migration in v1.
- **Error recovery**: per-message validation (bounds, rate limits — existing clamps like
  `MAX_PLAYER_ATTACK`), malformed messages drop with a log, repeated offenders are kicked.

## 6. PvP

| Mode | Rules |
| --- | --- |
| Duel | Both accept; 2-minute limit; higher HP% wins on time-out; no item loss |
| LAN Arena | 1v1 / 2v2 in a dedicated arena scene; stats normalised option; Valor rewards |
| Ashen Wastes flag | Region-wide PvP in LAN sessions when the host enables it; carried Kindled Keys transfer on kill; nothing else drops |

The damage formula is shared. A PvP damage scalar (0.6) keeps time-to-kill readable.

## 7. Bandwidth and performance budget

4 players, up to 96 enemies in the batch (existing `MAX_ENEMY_BATCH`), 20 Hz player / 10 Hz
enemy snapshots, tile deltas batched at 5 Hz. Target < 64 KB/s host upload. Measure with the
existing two-process harnesses extended to 4 processes.

## 8. Future online (P10 — design only)

| Concern | Direction |
| --- | --- |
| Server | Headless Godot server reusing `HostAuthority` and the pure rules; zone shards |
| Accounts | Auth service (OAuth / email) → JWT → game server; character data in Postgres |
| Persistence | Server-owned saves; offline saves become imports on first link (one-way, with checks) |
| Social | Parties (reuse LAN party), clans with a shared homestead (the VILLAGE model), trading via escrow ledger |
| Matchmaking | Arena queue service |
| Anti-cheat | Server authority (already the LAN model), rate limits, economy anomaly detection |
| Events | Server event calendar replaces the local clock |

Nothing in v1 should block this. The rule is: no gameplay rule may live only in presentation
code or only in `LanSession`.
