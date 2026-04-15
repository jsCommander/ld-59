class_name UpgradeData extends BaseGameData

# --- Exports ---
@export_group("Display")
@export var display_name: String
@export var description: String
@export var icon: Texture2D

@export_group("Classification")
@export var rarity: Constants.UpgradeRarity = Constants.UpgradeRarity.COMMON
@export var upgrade_type: Constants.UpgradeType = Constants.UpgradeType.GLOBAL
@export var trade_off_type: Constants.TradeOffType = Constants.TradeOffType.PURE
@export var target_dev_type: Constants.DevType
@export_group("Stat Effects")
@export var global_damage: float = 0.0
@export var feature_damage: float = 0.0
@export var bug_damage: float = 0.0
@export var feature_chance: float = 0.0
@export var bug_chance: float = 0.0
@export var boost_power: float = 0.0
@export var boost_duration: float = 0.0
@export var auto_click_speed: float = 0.0
@export var reward_bonus: float = 0.0
@export var upgrade_choices: int = 0
