extends Button

@export var tool: EditorController.ToolType

func _pressed() -> void:
	EditorController.instance.change_tool(self.tool)
