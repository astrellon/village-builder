extends Button

@export var tool: EditorController.EditorToolType

func _pressed() -> void:
	EditorController.instance.change_tool(self.tool)
