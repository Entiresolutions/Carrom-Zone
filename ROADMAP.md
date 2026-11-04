# 🎯 CarromMaster - Strategic Roadmap

## Competitive Analysis: Top 5 Carrom Games

### 1. Carrom Pool (Miniclip) - THE MARKET LEADER
- **Downloads:** 500M+
- **Rating:** 4.7 ⭐
- **Key Features:**
  - 3 game modes: Classic Carrom, Freestyle, Disc Pool
  - 2v2 multiplayer mode
  - Voice/video chat (premium)
  - Global matchmaking with arenas
  - Unlockable strikers & pucks
  - Victory chests & daily rewards
  - Lucky box, wheel spins
  - Weekly events
  - Offline play support
  - Smooth physics

### 2. Carrom King (Gametion)
- **Rating:** 4.4 ⭐
- **Features:** Classic rules, tournaments, leagues

### 3. World of Carrom (AppOn)
- **Rating:** 4.6 ⭐
- **Features:** 3D graphics, realistic physics

### 4. Carrom Lite (Yocheer)
- **Rating:** 4.7 ⭐
- **Features:** Offline-first, lightweight

### 5. Carrom Plus (Inhi Games)
- **Rating:** 4.7 ⭐
- **Features:** Multiple game modes, simple UI

---

## Our Competitive Advantages (To Build)

| Feature | Competitors | CarromMaster |
|---------|-------------|--------------|
| Open Source | ❌ | ✅ |
| Cross-platform (single codebase) | Partial | ✅ Web + Mobile + Desktop |
| No aggressive ads | ❌ | ✅ |
| Real-time multiplayer | Proprietary | ✅ Nakama (open source) |
| Customizable/moddable | ❌ | ✅ |
| Fair matchmaking | Questionable | ✅ ELO-based |

---

## Tech Stack (Production Grade)

### Frontend (Game Client)
- **Phaser 3** - 2D game engine with Matter.js physics
- **TypeScript** - Type safety
- **Capacitor** - Native mobile packaging

### Backend (Multiplayer Server)
- **Nakama** - Open source game server
  - Real-time multiplayer
  - Matchmaking
  - Leaderboards
  - Social features (friends, chat)
  - User accounts & authentication
  - In-app purchases
- **Docker** - Deployment

### Why Nakama?
- 100% open source (Apache 2.0)
- Built for games (by Heroic Labs)
- Handles: Auth, Matchmaking, Realtime, Leaderboards, Chat, Storage
- Scales horizontally
- Used by: Paradox Interactive, Rovio, Zynga

---

## Development Phases

### Phase 1: Core Game (Week 1-2) ✅ CURRENT
- [x] Basic game board & physics
- [x] Single player gameplay
- [x] Touch/mouse controls
- [x] Premium UI design
- [ ] Sound effects
- [ ] Better piece arrangement physics
- [ ] AI opponent (basic)

### Phase 2: Polish & Modes (Week 3-4)
- [ ] 3 Game Modes:
  - Classic Carrom (pocket your color + queen)
  - Freestyle (pocket any piece)
  - Disc Pool (simplified rules)
- [ ] Improved physics tuning
- [ ] Particle effects (pocket, collision)
- [ ] Haptic feedback (mobile)
- [ ] Background music
- [ ] Settings screen

### Phase 3: Nakama Integration (Week 5-6)
- [ ] Nakama server setup (Docker)
- [ ] User authentication (email, Google, Apple, guest)
- [ ] Player profiles
- [ ] Online 1v1 matchmaking
- [ ] Real-time game sync
- [ ] Basic leaderboard

### Phase 4: Social & Progression (Week 7-8)
- [ ] Friends system
- [ ] Private matches (play with friends)
- [ ] In-game chat
- [ ] XP & leveling
- [ ] Unlockable strikers/pucks
- [ ] Daily rewards
- [ ] Achievement system

### Phase 5: Monetization & Events (Week 9-10)
- [ ] Non-intrusive ads (rewarded video)
- [ ] Premium pass (no ads + exclusive items)
- [ ] Coin system
- [ ] Shop for cosmetics
- [ ] Weekly events/tournaments
- [ ] 2v2 mode

### Phase 6: Launch Prep (Week 11-12)
- [ ] Performance optimization
- [ ] App Store assets (screenshots, video)
- [ ] Privacy policy, terms
- [ ] Analytics (privacy-respecting)
- [ ] Soft launch (beta)
- [ ] Bug fixes from feedback
- [ ] Full launch

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   GAME CLIENTS                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐  │
│  │   Web   │  │   iOS   │  │ Android │  │Desktop │  │
│  │(Browser)│  │(Native) │  │(Native) │  │(Electron)│ │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬───┘  │
│       └────────────┴────────────┴─────────────┘      │
│                        │                             │
│              ┌─────────▼─────────┐                   │
│              │   Phaser 3 +      │                   │
│              │   TypeScript      │                   │
│              │   (Shared Code)   │                   │
│              └─────────┬─────────┘                   │
└────────────────────────┼────────────────────────────┘
                         │ WebSocket / HTTP
┌────────────────────────▼────────────────────────────┐
│                    NAKAMA SERVER                     │
│  ┌──────────────────────────────────────────────┐   │
│  │  • Authentication (Email, Social, Guest)      │   │
│  │  • Real-time Multiplayer (WebSocket)          │   │
│  │  • Matchmaking (ELO-based)                    │   │
│  │  • Leaderboards                               │   │
│  │  • Friends & Chat                             │   │
│  │  • Storage (player data, progress)            │   │
│  │  • In-App Purchases                           │   │
│  └──────────────────────────────────────────────┘   │
│                         │                            │
│              ┌──────────▼──────────┐                 │
│              │   PostgreSQL +      │                 │
│              │   CockroachDB       │                 │
│              └─────────────────────┘                 │
└──────────────────────────────────────────────────────┘
```

---

## Game Modes Specification

### 1. Classic Carrom
- 9 white + 9 black + 1 queen
- Each player assigned a color
- Must pocket queen AND cover it
- First to pocket all their pieces + queen wins
- Fouls: return 1 pocketed piece + opponent's turn

### 2. Freestyle
- Same pieces
- Pocket ANY piece for points
- White = 1 point, Black = 1 point, Queen = 5 points
- Highest score wins

### 3. Disc Pool (Simplified)
- Fewer pieces (5 each)
- No queen requirement
- Fastest mode

---

## Nakama Match Handler (Pseudocode)

```typescript
// Server-side match logic (Go or Lua)
interface MatchState {
  board: PiecePosition[];
  striker: StrikerState;
  currentTurn: 'player1' | 'player2';
  scores: { player1: number; player2: number };
  phase: 'aiming' | 'moving' | 'turnEnd';
}

// On player shoots
function onShoot(state: MatchState, playerId: string, angle: number, power: number) {
  if (state.currentTurn !== playerId) return; // Not your turn
  
  // Validate and apply physics
  state.striker.velocity = calculateVelocity(angle, power);
  state.phase = 'moving';
  
  // Broadcast to opponent
  broadcast(state);
}

// Physics simulation runs on server for authoritative state
// Client does prediction, server validates
```

---

## Revenue Model (Ethical)

### Free Features
- All game modes
- Online multiplayer
- Basic strikers/pucks
- Leaderboards

### Premium (One-time $4.99 or Subscription $1.99/mo)
- No ads
- Exclusive strikers/pucks
- Profile customization
- Priority matchmaking

### Cosmetic Purchases (Optional)
- Striker skins ($0.99-$2.99)
- Board themes ($1.99)
- Celebration effects ($0.99)

**NO Pay-to-Win!** All purchases are cosmetic only.

---

## Success Metrics

| Metric | Target (Month 1) | Target (Month 6) |
|--------|------------------|------------------|
| Downloads | 10,000 | 100,000 |
| DAU | 1,000 | 20,000 |
| Retention D1 | 40% | 50% |
| Retention D7 | 20% | 30% |
| Rating | 4.5+ | 4.7+ |
| Revenue | $500 | $5,000/mo |

---

## Next Steps

1. **Add sound effects** - Critical for game feel
2. **Implement AI opponent** - For offline play
3. **Set up Nakama server** - Multiplayer foundation
4. **Polish physics** - Key differentiator
5. **Add game modes** - Variety keeps players

---

## Resources

- [Nakama Docs](https://heroiclabs.com/docs/nakama/)
- [Phaser 3 Docs](https://phaser.io/docs/3.60.0)
- [Matter.js Physics](https://brm.io/matter-js/docs/)
- [Capacitor](https://capacitorjs.com/docs)
