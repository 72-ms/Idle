# Chronoforge: Idle Game Development Plan

## Context

We're building an iOS idle game from scratch (empty repo). The goal is to combine the best mechanics from top idle games (Cookie Clicker, Adventure Capitalist, Realm Grinder, Melvor Idle, Cell to Singularity, Egg Inc., etc.) into a single, polished experience. The game should be native iOS using SpriteKit + SwiftUI for optimal performance and small app size.

---

## Market Research Summary

### Top Idle Games Analyzed
| Game | Best Feature |
|------|-------------|
| Cookie Clicker | Simple core loop, satisfying prestige ("ascension") |
| Adventure Capitalist | Multiple income streams, angel investors, offline earnings |
| Idle Miner Tycoon | Manager automation system, multiple zones |
| Realm Grinder | Deep faction system, massive replayability |
| Melvor Idle | RPG skills (combat + non-combat), deep progression |
| Kittens Game | Civilization building, seasons, resource management |
| Universal Paperclips | Narrative phases that transform gameplay |
| Egg, Inc. | Polished visuals, co-op contracts, prestige eggs |
| Cell to Singularity | Evolution tech tree, educational theme, beautiful art |
| Antimatter Dimensions | Multiple prestige layers, deep endgame math |
| Idle Slayer | Pixel art + runner mechanics, skill tree, minigames |
| Tap Titans 2 | Hero collection, clan raids, tournaments |

### Key Insights
- **18% stickiness** for idle games (vs 10.5% other casual)
- Daily rewards boost 1-week retention by **30%**
- Social/leaderboards boost retention by **50%**
- **62% of revenue** now from IAP (58% of that is cosmetics)
- Ethical monetization is a **competitive advantage**
- Players love: number go up, discovery, collection, optimization
- Players hate: cluttered UI, pay-to-win, too many ads, early walls

### Design Principles from Research
- **Core loop**: Earn → Upgrade → Prestige → Earn faster (repeat with layered complexity)
- **3 engagement phases**: Hook (0-30 min), Habit (1-7 days), Hobby (weeks-months)
- **Prestige formula**: `prestigeCurrency = totalLifetimeEarnings^exponent × multiplier`
- **Offline progression** with caps to encourage return visits
- **Active vs passive balance**: Manual play should give bonuses but automation should feel rewarding
- **Discovery**: Much of the fun is discovering new mechanics organically

### Player Psychology
- "Number go up" is the core satisfaction
- Collection & novelty discovery drive engagement
- Soothing repetition provides comfort and relaxation
- Milestone satisfaction triggers dopamine responses
- Exponential growth curves make progress feel rewarding

### Common Mistakes to Avoid
- Cluttered, confusing interfaces
- Difficulty spikes too early
- Feature overload that overwhelms new players
- Automating too early (ruins the active engagement phase)
- Audio-visual mismatch breaking immersion

---

## Game Concept: **Chronoforge**

### Elevator Pitch
You are a **Timesmith** — a cosmic blacksmith who forges the fabric of time itself. Harvest temporal energy from different eras, forge powerful Time Relics, and prestige by collapsing timelines to restart stronger. Each era (Ancient, Medieval, Industrial, Digital, Cosmic) plays differently and unlocks new mechanics, creating a game that evolves as you progress.

### Why This Theme Works
- **Familiar enough**: Crafting/forging is universally understood
- **Unique enough**: Time-forging hasn't been done in idle games
- **Supports progression naturally**: Eras provide clear visual/mechanical phases
- **Justifies prestige**: "Collapsing timelines" is a thematic reset
- **Scales infinitely**: Time is abstract enough to support endless numbers
- **Visual variety**: Each era has distinct art, keeping the game fresh

### Unique Selling Points (vs Competition)
1. **Era System** (inspired by Cell to Singularity + Universal Paperclips): Each era introduces fundamentally new mechanics, not just bigger numbers
2. **Relic Forging** (inspired by Realm Grinder factions): Craft relics that change your playstyle — choose synergies, not just upgrades
3. **Timeline Collapse prestige** (inspired by Antimatter Dimensions layers): Multi-layered prestige with thematic storytelling
4. **Temporal Skills** (inspired by Melvor Idle): Both active and passive skill trees that persist across prestiges
5. **Chrono Contracts** (inspired by Egg Inc. co-op): Async multiplayer goals for community engagement

---

## Core Gameplay Loop

```
TAP to harvest Temporal Energy (TE)
  → SPEND TE on Generators (auto-produce TE)
    → SPEND TE on Upgrades (multiply production)
      → FORGE Relics (powerful items with unique effects)
        → UNLOCK new Eras (new mechanics + visual themes)
          → COLLAPSE TIMELINE (prestige: reset for Chrono Shards)
            → SPEND Chrono Shards on permanent upgrades
              → REPEAT (faster, deeper, with new content unlocked)
```

### Detailed Mechanics

#### Primary Currency: Temporal Energy (TE)
- Earned by tapping (active) or via Generators (passive)
- Spent on generators, upgrades, and relic forging
- Resets on prestige

#### Generators (per Era — 5 eras, 4 generators each = 20 total)
- **Ancient Era**: Sundial, Hourglass, Water Clock, Astrolabe
- **Medieval Era**: Bell Tower, Clockwork, Pendulum, Orrery
- **Industrial Era**: Steam Clock, Telegraph, Assembly Line, Dynamo
- **Digital Era**: Quartz Processor, Server Farm, Quantum Clock, AI Core
- **Cosmic Era**: Pulsar Tap, Black Hole Engine, Entropy Harvester, Chrono Reactor

Each generator has: base production rate, exponential cost scaling, and milestone bonuses at quantities 10/25/50/100/250/500.

#### Cost Formula
```
cost(n) = baseCost × costMultiplier^n
```
Where `costMultiplier` ranges from 1.07 (cheap generators) to 1.15 (expensive ones).

#### Production Formula
```
production = baseRate × quantity × upgradeMultiplier × skillMultiplier × relicMultiplier
```

#### Upgrades
- Per-generator multipliers (2x, 4x, etc.)
- Global multipliers
- Tap power increases
- Offline efficiency boosts

#### Relic Forging (Unique Feature)
- Combine TE + special materials dropped by generators
- Each relic has a unique passive effect (e.g., "Hourglass of Greed: +50% TE from first generator in each era")
- Relics persist across soft prestiges, reset on hard prestige
- Players choose which relics to equip (limited slots) creating build diversity
- Relic synergies reward experimentation

---

## Progression Systems (Layered)

### Layer 1: Within-Run Progression
- Buy generators → upgrade generators → unlock next era
- Linear within each era, branching choices via relics

### Layer 2: Soft Prestige — "Timeline Collapse"
- **Currency**: Chrono Shards (CS)
- **Formula**: `CS = floor((totalTE / 1e12) ^ 0.5)`
- **Resets**: TE, generators, upgrades
- **Keeps**: Chrono Shards, skill tree progress, relics
- **Unlocks**: Chrono Skill Tree
- **When to prestige**: When next milestone takes longer than restarting with new bonuses

### Layer 3: Chrono Skill Tree (persistent across soft prestiges)
- 3 branches:
  - **Acceleration** — production speed & multipliers
  - **Resonance** — offline earnings & generator synergies
  - **Mastery** — tap power, relic slots, era unlock speed
- ~30 nodes per branch, spent with Chrono Shards
- Nodes have multiple levels for incremental investment

### Layer 4: Hard Prestige — "Epoch Reset" (unlocks after ~2 weeks of play)
- **Currency**: Epoch Crystals (EC)
- **Formula**: `EC = floor((totalLifetimeCS / 1e6) ^ 0.4)`
- **Resets**: Everything including Chrono Shards and skill tree
- **Keeps**: Epoch Crystals, Epoch Perks, cosmetics
- **Epoch Perks**: Powerful permanent bonuses (start with generators unlocked, auto-tap, +relic slots, etc.)

### Layer 5: Endgame — "The Eternal Forge" (unlocks after ~1 month)
- Prestige currencies compound
- Unique challenges / modifiers for each run (e.g., "no tapping", "single era only")
- Leaderboards for fastest timeline collapse
- Seasonal content rotations

---

## Feature Breakdown by Phase

### Hook Phase (First 30 Minutes)
- Tap to earn TE with satisfying particles and sounds
- Buy first 2-3 generators (Sundial, Hourglass, Water Clock)
- Watch numbers grow exponentially
- Unlock first upgrade milestone
- Brief tutorial via ambient UI hints (no intrusive popups)
- Ancient Era pixel art with warm gold/sand palette
- First "wow" moment: visual cascade effect when buying 10th Sundial
- Haptic feedback on every tap and purchase

### Habit Phase (Days 1-7)
- Unlock Medieval Era (new visual theme, new generators, new music)
- First Timeline Collapse (prestige) — discover the meta-game
- Start investing Chrono Shards into skill tree
- Forge first Relic — realize build customization potential
- Daily login calendar with escalating rewards
- Offline earnings notification: "While you were away, you earned 1.5M TE!"
- Unlock Industrial Era by end of week
- Push notifications for full offline earnings bank

### Hobby Phase (Weeks 2+)
- Digital and Cosmic eras with increasingly unique mechanics
- Relic build optimization — experiment with different loadouts
- Epoch Reset (hard prestige) for deep replayability
- Chrono Contracts (async co-op goals with other players)
- Weekly challenges with unique modifiers
- Leaderboards for competitive players
- Seasonal events with exclusive cosmetics
- The Eternal Forge endgame content

---

## Monetization Strategy (Ethical, Player-Friendly)

### Free-to-Play Core
- **All gameplay content is earnable for free**
- No pay-to-win mechanics
- No energy/stamina gates
- No "watch ad or wait" timers

### Revenue Streams

#### 1. Cosmetic Shop (primary — target 58%+ of IAP revenue)
- Era-themed skins for generators
- Particle effect themes (fire, ice, cosmic, nature, etc.)
- UI color themes and backgrounds
- Exclusive relic visual appearances
- Timesmith avatar customization

#### 2. Chrono Pass (Battle Pass — monthly, $4.99)
- **Free track**: Basic rewards for all players (TE, materials)
- **Premium track**: Cosmetics, bonus TE, extra relic slot
- No gameplay-critical exclusives on premium track
- 30 tiers, progressed via normal gameplay

#### 3. Reward Videos (opt-in only)
- 2x production for 30 minutes
- Instant offline earnings collection
- Bonus Chrono Shards on prestige (+10%)
- Capped at ~10/day to prevent ad fatigue

#### 4. Starter Pack (one-time, $2.99)
- Small Chrono Shard boost + exclusive "Founder" cosmetic
- Good conversion tool for new players

#### 5. Remove Ads ($4.99 one-time)
- Removes all banner/interstitial ads permanently
- Reward videos remain available as opt-in

### What We Will NOT Do
- No loot boxes or gacha mechanics
- No paywalled eras or generators
- No "watch ad or wait" timers
- No pay-to-skip-prestige
- No pay-to-win advantages

---

## Technical Architecture

### Platform & Frameworks
- **iOS 17+** (Swift 5.9+)
- **SpriteKit**: Game scene rendering, particle effects, animations
- **SwiftUI**: All menus, settings, shop, skill tree UI
- **Combine**: Reactive data binding between game state and UI
- **SwiftData**: Local persistence
- **GameKit**: Leaderboards, achievements
- **CloudKit**: iCloud save sync
- **StoreKit 2**: In-app purchases
- **AdMob/AppLovin**: Ad mediation
- **UserNotifications**: Push notifications for offline earnings

### App Structure
```
Chronoforge/
├── App/
│   ├── ChronoforgeApp.swift          # App entry point
│   └── AppState.swift                 # Global app state
├── Core/
│   ├── GameEngine.swift               # Main game loop & tick system
│   ├── OfflineCalculator.swift        # Offline earnings math
│   ├── PrestigeManager.swift          # Timeline Collapse & Epoch Reset
│   ├── SaveManager.swift              # Persistence layer
│   └── NumberFormatter.swift          # Large number display (1.5M, 2.3B, etc.)
├── Models/
│   ├── Generator.swift                # Generator data model
│   ├── Upgrade.swift                  # Upgrade data model
│   ├── Relic.swift                    # Relic data model
│   ├── Era.swift                      # Era definitions
│   ├── SkillTree.swift                # Chrono skill tree
│   ├── PlayerState.swift              # All player progress
│   └── GameConfig.swift               # Balance constants & formulas
├── Views/
│   ├── MainGameView.swift             # Primary game screen (SwiftUI host)
│   ├── GameScene.swift                # SpriteKit scene for animations
│   ├── GeneratorListView.swift        # Generator purchase/upgrade UI
│   ├── UpgradeShopView.swift          # Upgrades panel
│   ├── RelicForgeView.swift           # Relic crafting screen
│   ├── SkillTreeView.swift            # Chrono skill tree
│   ├── PrestigeView.swift             # Timeline Collapse confirmation
│   ├── SettingsView.swift             # Settings & preferences
│   ├── ShopView.swift                 # Cosmetic shop & IAP
│   └── StatsView.swift                # Player statistics
├── Services/
│   ├── AudioManager.swift             # Sound & music
│   ├── HapticsManager.swift           # Haptic feedback
│   ├── NotificationManager.swift      # Push notifications
│   ├── AnalyticsManager.swift         # Event tracking
│   ├── AdManager.swift                # Ad mediation
│   └── CloudSyncManager.swift         # iCloud saves
└── Resources/
    ├── Assets.xcassets                # Images & colors
    ├── Sounds/                        # SFX
    ├── Music/                         # Background tracks
    └── Particles/                     # SpriteKit particle files
```

### Key Technical Decisions
- **Game tick**: 0.1s interval for smooth counter updates via `Timer.publish`
- **Offline calc**: On app launch, calculate `timeDelta × productionRate × offlineEfficiency` (capped at 8 hours to encourage return visits)
- **Number system**: Use `Decimal` for precision; custom `BigNumber` type if numbers exceed `Decimal` range
- **Save system**: Auto-save every 30 seconds + on `scenePhase` change to `.background`
- **State management**: Single `@Observable PlayerState` drives all UI reactively

---

## Data Model (Core Entities)

```swift
@Observable
class PlayerState {
    var temporalEnergy: Decimal          // Primary currency
    var chronoShards: Int                // Soft prestige currency
    var epochCrystals: Int               // Hard prestige currency
    var generators: [GeneratorState]     // Owned generators & levels
    var upgrades: Set<UpgradeID>         // Purchased upgrades
    var relics: [Relic]                  // Forged relics
    var equippedRelics: [Relic]          // Currently active relics (limited slots)
    var skillTree: SkillTreeState        // Skill allocations
    var epochPerks: Set<EpochPerkID>     // Hard prestige perks
    var currentEra: Era                  // Furthest unlocked era
    var totalPrestigeCount: Int
    var totalEpochCount: Int
    var statistics: PlayerStatistics     // Lifetime stats
    var lastSaveTimestamp: Date
    var cosmetics: PlayerCosmetics       // Owned & equipped cosmetics
}

struct GeneratorState: Codable, Identifiable {
    let id: GeneratorID
    var quantity: Int
    let era: Era
    let baseProduction: Decimal
    let costBase: Decimal
    let costMultiplier: Double           // Typically 1.07-1.15
}

struct Relic: Codable, Identifiable {
    let id: UUID
    let type: RelicType
    let name: String
    let effect: RelicEffect              // Enum of possible effects
    let magnitude: Double
    let era: Era
}

struct SkillTreeState: Codable {
    var acceleration: [SkillNodeID: Int]  // Node ID → level
    var resonance: [SkillNodeID: Int]
    var mastery: [SkillNodeID: Int]
    var availablePoints: Int
}

enum Era: String, Codable, CaseIterable {
    case ancient, medieval, industrial, digital, cosmic
}
```

---

## Art Style & Audio

### Visual Direction
- **Style**: Modern pixel art with clean, readable UI
- **Palette**: Each era has a distinct color scheme:
  - **Ancient**: warm golds, sand, terracotta
  - **Medieval**: cool grays, deep blues, candlelight amber
  - **Industrial**: brass, copper, steam whites
  - **Digital**: neon cyan, dark backgrounds, glitch effects
  - **Cosmic**: deep purples, starfield, iridescent shimmer
- **Animations**: Smooth particle effects for TE generation, satisfying bounce on tap, cascade effects on milestones
- **UI**: Clean SwiftUI with era-themed accent colors, minimal chrome, big readable numbers front and center

### Audio Direction
- **Music**: Lo-fi ambient tracks per era (loopable, non-fatiguing, 2-3 min loops)
- **SFX**: Satisfying tap sounds (varies by era), generator hums, prestige chime, upgrade dings
- **Haptics**: Light tap feedback, medium on purchase, heavy on prestige/milestone
- **Player control**: Independent volume sliders for music, SFX, and haptic toggle

---

## Key Screens / Views

1. **Main Game Screen** — SpriteKit scene (center) + TE counter (top) + tap area + generator list (bottom scrollable)
2. **Generator Panel** — List of available generators with buy/upgrade buttons, quantity display, production rate
3. **Upgrade Shop** — Grid of available upgrades, locked/unlocked states, cost display
4. **Relic Forge** — Crafting interface: select materials → preview relic → forge. Equipped relics display.
5. **Skill Tree** — Visual node graph with 3 branches, tap to allocate Chrono Shards
6. **Prestige Screen** — Timeline Collapse confirmation: shows CS to earn, what resets, what persists
7. **Stats Screen** — Lifetime stats: total TE earned, prestiges, time played, generators bought, etc.
8. **Settings** — Sound/haptics toggles, save management, credits, support link
9. **Shop** — Cosmetic items, Chrono Pass, IAP, remove ads
10. **Era Selector** — Tab bar or swipe navigation between unlocked eras

---

## MVP Scope (Phase 1 Build)

### MVP Features (Build First)
1. Core tap-to-earn mechanic with Temporal Energy
2. Ancient Era generators (4) with purchase & exponential cost scaling
3. Basic upgrades (per-generator multipliers)
4. Large number formatting (K, M, B, T, etc.)
5. Auto-save & load with SwiftData
6. Offline earnings calculation on app resume
7. Basic SpriteKit scene with tap particle effects
8. Generator list UI (SwiftUI)
9. Medieval Era unlock (2nd era with new generators)
10. Timeline Collapse (soft prestige) with Chrono Shards
11. Basic Chrono Skill Tree (10 nodes across 3 branches)
12. Settings screen (sound, haptics, reset save)
13. Stats screen with lifetime tracking

### Phase 2 (Post-MVP)
- Industrial + Digital + Cosmic eras
- Full skill tree (90 nodes)
- Relic forging system
- Cosmetic shop + IAP via StoreKit 2
- Reward video ads
- Chrono Pass (battle pass)
- Push notifications for offline earnings
- Daily login rewards

### Phase 3 (Growth)
- Epoch Reset (hard prestige layer)
- Chrono Contracts (async co-op)
- Leaderboards & achievements (GameKit)
- iCloud save sync (CloudKit)
- Seasonal events with exclusive cosmetics
- The Eternal Forge endgame content
- Weekly challenges with modifiers

---

## Balance Guidelines

### Early Game (Hour 1)
- Tap value: 1 TE
- Sundial cost: 10 TE, produces 0.5 TE/s
- Hourglass cost: 100 TE, produces 3 TE/s
- Water Clock cost: 1,000 TE, produces 15 TE/s
- Astrolabe cost: 10,000 TE, produces 80 TE/s
- First upgrade: 500 TE (2x Sundial production)

### Mid Game (Week 1)
- Players should prestige 3-5 times
- Medieval Era unlocks at ~1e6 total TE
- First relic forgeable after 2nd prestige

### Late Game (Month 1+)
- Numbers in the 1e30+ range
- Epoch Reset available after ~10 prestiges
- Endgame content unlocks after first Epoch Reset

---

## Verification & Testing Plan

1. **Unit Tests**: Game engine math (production rates, prestige formulas, cost scaling)
2. **UI Tests**: Purchase flows, prestige flow, navigation between screens
3. **Balance Testing**: Play through hook phase in <30 min, first prestige by hour 2-3
4. **Offline Test**: Background app for various durations, verify correct earnings calculation
5. **Performance**: Profile SpriteKit scene for 60fps on iPhone 12+
6. **Save/Load**: Kill app at various states, verify clean restore every time
7. **Device Testing**: iPhone SE (small screen) through iPhone 16 Pro Max
8. **Accessibility**: VoiceOver support, Dynamic Type for key UI elements
