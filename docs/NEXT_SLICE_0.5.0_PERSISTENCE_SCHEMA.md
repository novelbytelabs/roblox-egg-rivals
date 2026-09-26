# Egg Rivals 0.5.0 — Persistence Schema Foundation

Status: **IMPLEMENTED / VERIFICATION PENDING**

DataStore I/O: **NOT IMPLEMENTED**

## Purpose

Prove that Egg Rivals can represent and reconstruct its real durable player state before introducing any live cloud writes.

## Durable v1 record

The versioned record includes:

- user id and schema version;
- Speed, Coins and Coin remainder;
- Speed Lab grade, tuning, milestone and cumulative records;
- tutorial/onboarding/hatched progression;
- ranch expansion;
- exact inventory item IDs, kinds, rarity/creature/element state, Favorite/Lock, pet mode and cosmetic variant;
- pet welcome-history owner ids;
- active pet id;
- incubating egg id, element and remaining duration;
- selected Duel Armory loadout;
- selected Elemental Bazaar ranch theme.

## Explicitly transient / excluded

The durable record does not contain:

- active Trade, Exchange or Duel transaction state;
- holds, previews or reservations;
- Sprint/Trial sessions;
- carried world eggs;
- live Roblox Instances;
- active Overdrive time;
- current momentum/energy/precision toggle;
- temporary slows/rate-limit timestamps;
- Night Market per-Night usage.

Unresolved item transaction state causes capture validation to fail instead of being normalized.

## Restore behavior

Restore validates the entire record before mutation, rejects foreign-user records and item-id collisions, replaces only the target player's inventory, reconstructs incubator models, reapplies Speed Lab/ranch/theme presentation, restores active/pen pet state and resets transient lab/session state.

## Regression intent

The 0.5.0 regression family is designed to falsify:

- non-serializable values leaking into the record;
- unresolved item transaction serialization;
- wrong-user acceptance;
- impossible Speed/tier combinations;
- duplicate or sparse inventory arrays;
- mismatched incubation/egg state;
- item-id loss;
- cosmetic/lock/pet-mode loss;
- transient lab state accidentally persisting;
- fixture state surviving an exact baseline restore.

A fresh exact-source one-server/two-client Studio regression is required before the schema can be treated as verified.

## Not claimed

This slice does **not** establish live persistence. It does not call DataStoreService, does not test cross-server concurrency, and does not prove retry/session-lock/shutdown behavior.
