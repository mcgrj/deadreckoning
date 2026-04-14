# Leadership Under Pressure System
## Core Mechanic Design Document

---

# 🎯 Overview

The **Leadership Under Pressure** system is the core (“killer mechanic”) of the game.

> The player does not directly control outcomes.  
> They influence a volatile crew through decisions, and outcomes emerge from human reactions.

This system defines:
- Player identity (leadership style)
- How decisions are interpreted
- How the simulation evolves
- How stories emerge

---

# 🧠 Core Concept

Leadership style is **not chosen**.

Instead:
> It **emerges from repeated player decisions over time**

The game observes patterns in:
- Cards played
- Conflict resolution choices
- Crew favoritism
- Risk tolerance

---

# 🧩 System Structure

## 1. Action Tagging

Every player action carries hidden tags.

### Example Tags:
- Authority
- Empathy
- Neglect
- Favoritism
- Risk

### Example:

| Action | Tags |
|--------|------|
| Public Punishment | Authority, Fear |
| Hear Grievances | Empathy |
| Ignore Conflict | Neglect |
| Reward Crew | Favoritism |

---

## 2. Behaviour Tracking

The system tracks **recent trends**, not lifetime totals.

This ensures:
- Style can evolve during a run
- Player is not locked too early

---

## 3. Hidden Leadership Profiles

The system maps behaviour to inferred styles.

### Core Archetypes:

#### Authoritarian
- High authority usage
- Low empathy
- Maintains order, risks explosive collapse

#### Diplomatic
- High empathy
- Slower conflict resolution
- Reduces tension, risks indecision

#### Negligent
- Avoids action
- Lets systems drift
- Leads to chaotic failure

#### Opportunistic
- Favors individuals
- Exploits situations
- Creates instability

---

# 🔄 Interaction With Core Systems

## Simulation Layer

Leadership style directly influences:

- Morale decay rates
- Faction formation
- Conflict escalation
- Loyalty shifts

### Example:
Authoritarian → slower short-term unrest, faster long-term faction split

---

## Event System

Events react differently based on leadership style.

### Example:
Theft Event:

- Authoritarian → fear-based compliance or rebellion
- Diplomatic → prolonged investigation, reduced escalation
- Negligent → escalation into chaos

---

## Card System

Cards both:
- Express leadership
- Reinforce leadership

### Feedback Loop:

Player plays cards → style inferred → new cards offered → style reinforced

---

## Crew System

Crew react to leadership style:

- Loyal crew support authority
- Ambitious crew resist control
- Fearful crew comply temporarily

---

# 🧭 Player Experience

The player experiences leadership style through:

## 1. Consequences
- Delayed outcomes
- Escalating problems

## 2. Crew Feedback
- Dialogue
- Behaviour changes

## 3. Ship Log
- Narrative summaries

---

# 📖 Ship Log Integration

The ship log is the primary feedback system.

### During Run:
- “The captain’s harsh discipline keeps order… for now.”

### End of Run:
- “A strict and unforgiving command fractured the crew, leading to mutiny.”

---

# 🎯 Why This Mechanic Matters

## 1. Creates Ownership
Players feel responsible for outcomes.

## 2. Enables Emergence
Stories arise from system interactions, not scripts.

## 3. Drives Replayability
Different decisions → different leadership styles → different outcomes.

## 4. Reinforces Theme
The game is about leadership under pressure.

---

# ⚖️ Design Constraints

## Must Be:
- Readable (player understands cause/effect)
- Reactive (systems respond clearly)
- Flexible (style can evolve)

## Must Avoid:
- Hidden randomness without explanation
- Static leadership labels
- Optimal “correct” playstyle

---

# 🔥 Supporting Loop

## Pressure Loop

Simulation builds pressure → Event exposes conflict → Player acts → Consequences feed simulation

This loop ensures the leadership system is constantly exercised.

---

# 🧭 Final Definition

> A system where the player’s repeated decisions shape an emergent leadership identity, which directly influences how a simulated crew behaves and how events unfold.

---

