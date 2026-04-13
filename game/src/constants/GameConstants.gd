# GameConstants.gd
# Centralised balance tuning constants. All magic numbers used in simulation
# code live here. Accessed as autoload singleton: GameConstants.CONST_NAME
class_name GameConstants

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

# Difficulty synthesis weights
const DIFFICULTY_BURDEN_WEIGHT: float = 0.3
const DIFFICULTY_COMMAND_WEIGHT: float = 0.3
const DIFFICULTY_CREW_LOSS_WEIGHT: int = 5
const DIFFICULTY_SUPPLY_DEPLETION_WEIGHT: int = 3
