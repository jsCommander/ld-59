extends Theme
class_name UiTheme

@export_group("Color Tokens")
@export var background: Color = Color("#ffffff") # background for panels/modals
@export var card : Color = Color("#e7f6e6") # background for cards
@export var overlay: Color = Color(0, 0, 0, 0.28) # dark overlay behind modals

@export var text: Color = Color("#784d32") # primary text
@export var text_inverse: Color = Color("#ffffff") # text on accent buttons
@export var text_muted: Color = Color("#a0754f") # secondary text

@export var accent: Color = Color("#ffc752") # main accent (buttons)
@export var accent_hover: Color = Color("#ffdea1") # hover state for accent
@export var accent_active: Color = Color("#ffdea1") # active/pressed state

@export var success: Color = Color("#dfd75b") # success/positive
@export var danger: Color = Color("#ef8252") # error/negative

@export var border: Color = Color("#784d32") # borders/dividers

@export var progress_bar: Color = Color("#a4c6ae")
@export var progress_bar_bg:Color = Color("#feefd6")
