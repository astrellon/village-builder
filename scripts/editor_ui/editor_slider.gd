extends VBoxContainer

@export var slider: HSlider
@export var label: Label
@export var is_int: bool
@export var parameter: EditorController.ParameterType

var _prefix: String = ""

func _ready() -> void:
	self._prefix = self.label.text
	self.slider.value_changed.connect(self._on_slider_changed)
	self._prefix = self.label.text
	if self._prefix[-1] != ' ':
		self._prefix += ' '
	
	self._on_scene_change()

func _on_scene_change() -> void:
	var value = self._get_parameter()
	if value == null:
		self.slider.editable = false
	else:
		self.slider.editable = true
		self.slider.value = value
		self._on_slider_changed(value)

func _on_slider_changed(value: float) -> void:
	if self.is_int:
		var as_int = int(value)
		self.label.text = self._prefix + str(as_int)
		self._update_parameter(as_int)
	else:
		self.label.text = self._prefix + str(value)
		self._update_parameter(value)

func _get_parameter() -> Variant:
	return EditorController.instance.get_parameter(self.parameter)

func _update_parameter(value: Variant) -> void:
	EditorController.instance.set_parameter(self.parameter, value)
