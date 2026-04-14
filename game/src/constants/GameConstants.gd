# GameConstants.gd
# Centralised balance tuning constants. All magic numbers used in simulation
# code live here. Accessed globally via class_name: GameConstants.CONST_NAME
class_name GameConstants
extends Object

# Run-end thresholds
const MUTINY_COMMAND_THRESHOLD: int = 20
const MUTINY_BASE_RATE: float = 0.4
const BREAKDOWN_BURDEN_THRESHOLD: int = 100

# Stat clamp bounds
const BURDEN_MAX: int = 100
const BURDEN_MIN: int = 0
const COMMAND_MAX: int = 100
const COMMAND_MIN: int = 0

# Preparation screen
const MAX_UPGRADES: int = 2
const OBJECTIVE_SHORTLIST_SIZE: int = 3

# Save paths
const SAVE_DIR: String = "user://saves/"

# Incident system
const INCIDENT_BASE_TRIGGER_CHANCE: float = 0.25  # Chance per tick that any incident fires at all
const INCIDENT_COOLDOWN_TICKS: int = 5             # Ticks before the same incident can re-trigger

# Supply exhaustion penalties (burden spikes when a supply hits zero)
const BURDEN_ON_FOOD_EXHAUSTED: int = 6
const BURDEN_ON_WATER_EXHAUSTED: int = 8

# Travel simulation rates
const TRAVEL_FATIGUE_PER_TICK: int = 1
const SICKNESS_RISK_RISE_PER_TICK: int = 3   # Per tick when food or water is critically low
const SICKNESS_RISK_FALL_PER_TICK: int = 1   # Per tick when supplies are healthy
const SHIP_WEAR_MIN_PER_TICK: int = 1         # Minimum ship wear applied regardless of zone modifier

# Mutiny modifiers
const SUPPRESS_DISSENT_MUTINY_MULTIPLIER: float = 0.5

# Difficulty synthesis weights
const DIFFICULTY_BURDEN_WEIGHT: float = 0.3
const DIFFICULTY_COMMAND_WEIGHT: float = 0.3
const DIFFICULTY_CREW_LOSS_WEIGHT: int = 5
const DIFFICULTY_SUPPLY_DEPLETION_WEIGHT: int = 3
