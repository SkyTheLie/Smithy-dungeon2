class_name LanWindow
extends PanelContainer
## Main menu, "LAN": joins a game another player hosts (admin panel, tab "LAN"). While open it
## listens for hosts in the network (Net.start_discovery) and shows a button per game found; if
## the search finds nothing (firewall, other subnet), the host's IP address can be typed in.
## The game starts by itself once the host's world arrived (Net._receive_world loads it).

## Last address typed in (user://settings.cfg), so it needn't be typed again.
const SETTINGS_SECTION: String = "lan"
const SETTINGS_KEY: String = "last_address"

@onready var _server_list: VBoxContainer = %ServerList
@onready var _empty_label: Label = %EmptyLabel
@onready var _address_edit: LineEdit = %AddressEdit
@onready var _join_button: Button = %JoinButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_address_edit.text = str(WindowLayout.get_setting(SETTINGS_SECTION, SETTINGS_KEY, "127.0.0.1"))
	_join_button.pressed.connect(func() -> void: _join(_address_edit.text))
	_address_edit.text_submitted.connect(_join)
	visibility_changed.connect(_on_visibility_changed)
	Net.servers_changed.connect(_on_servers_changed)
	Net.status_changed.connect(_update_status)


func _exit_tree() -> void:
	Net.stop_discovery()


func _on_visibility_changed() -> void:
	if visible:
		Net.start_discovery()
		_rebuild_servers()
		_update_status()
	else:
		Net.stop_discovery()
		_address_edit.release_focus()


func _on_servers_changed() -> void:
	if visible:
		_rebuild_servers()


## A button per game found ("Name – 192.168.0.5"), a full game can't be clicked.
func _rebuild_servers() -> void:
	for child in _server_list.get_children():
		if child != _empty_label:
			child.queue_free()
	_empty_label.visible = Net.servers.is_empty()
	for key: String in Net.servers:
		var info: Dictionary = Net.servers[key]
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		var full: bool = int(info["open"]) <= 0
		button.text = "%s – %s%s" % [info["name"], info["ip"], (" (" + Language.translate("voll") + ")") if full else ""]
		button.disabled = full
		button.pressed.connect(_join.bind(str(info["ip"])))
		_server_list.add_child(button)


func _join(address: String) -> void:
	if Net.is_guest():
		return
	_address_edit.text = address
	WindowLayout.set_setting(SETTINGS_SECTION, SETTINGS_KEY, address)
	if Net.join_game(address) == OK:
		_status_label.text = Language.translate("Verbinde mit %s ...") % address


func _update_status() -> void:
	if not is_inside_tree():
		return
	_join_button.disabled = Net.is_guest()
	if not Net.last_error.is_empty():
		_status_label.text = Net.last_error
	elif not Net.is_guest():
		_status_label.text = ""
