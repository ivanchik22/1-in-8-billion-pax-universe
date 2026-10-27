extends Control
# Your fork's own launcher. Pax Universe shows it after its platform splash (Ctrl+F12 always switches games).
# Pax.platform gives the player, play(), our windows (Workshop, AI settings, profile) and switch_game().
# Keys, payment and login stay in Pax Universe windows — the fork only opens them.

func _ready() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-200, -160)
	box.custom_minimum_size = Vector2(400, 320)
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var title := Label.new()
	title.text = str(Pax.platform.info().get("title", "My game"))
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	var me := Label.new()
	var player: Dictionary = Pax.platform.player()
	me.text = "Hello, %s" % (str(player["nick"]) if str(player["nick"]) != "" else "player")
	box.add_child(me)
	_button(box, "▶  Play", func(): Pax.platform.play())
	_button(box, "🛠️  Workshop", func(): Pax.platform.open("store"))
	_button(box, "🧠  AI settings", func(): Pax.platform.open("нейросеть"))
	_button(box, "🌌  Switch game", func(): Pax.platform.switch_game())


func _button(box: VBoxContainer, text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	box.add_child(b)
