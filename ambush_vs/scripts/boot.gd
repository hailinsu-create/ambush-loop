extends Node

## Minimal boot placeholder for Ambush VS skeleton.
## No gameplay simulation lives here yet (W1 A1 scope).

func _ready() -> void:
	print("AMBUSH_VS_BOOT ok version=", ProjectSettings.get_setting("application/config/version", ""))
