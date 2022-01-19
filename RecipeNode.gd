class_name RecipeNode

var name:String
var item:String
var children:Array

func _init(name:String, item:String = "", children:Array = []):
	self.name = name # name of node
	self.item = item # crafted item name
	self.children = children

func has(child_name:String):
	for child in children:
		if child.name == child_name:
			return true
	return false

func get(child_name:String):
	for child in children:
		if child.name == child_name:
			return child
	return null

func add(child_node:RecipeNode):
	children.append(child_node)
	return child_node
