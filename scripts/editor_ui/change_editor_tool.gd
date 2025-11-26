extends Button

@export var tool: EditorController.EditorToolType
@export var editor_controller: EditorController

func _pressed() -> void:
	self.editor_controller.change_tool(self.tool)
