class_name Recipe

func _init():
	pass

# creates a trie with ingredients sorted by alpha ascending from root to last branch
"""
var recipes := RecipeNode.new("root", "", [
	RecipeNode.new("wood", "", [
		RecipeNode.new("wood", "lumber")
	]),
	RecipeNode.new("leaves", "", [
		RecipeNode.new("leaves", "", [
			RecipeNode.new("leaves", "vine")
		])
	]),
	RecipeNode.new("lumber", "", [
		RecipeNode.new("rock", "", [
			RecipeNode.new("vine", "hammer"),
			RecipeNode.new("rock", "", [
				RecipeNode.new("vine", "pickaxe")
			])
		])
	])
])
"""

# takes in a castledb file
# returns a RecipeNode tree
static func load_recipes(db:Dictionary, sheet:String) -> RecipeNode:
	var recipes := RecipeNode.new("root")

	var items_sheet:Dictionary = db["sheets"][0] # @TODO use sheet param
	var items_columns:Array = items_sheet["columns"] # name, typeStr, display
	var items_lines:Array = items_sheet["lines"] # name, ingredients, icon

	for item in items_lines:
		if item.ingredients.size() == 0:
			# TODO handle this later
			# materials.append(RawMaterial.new(item.name, item.icon))
			pass
		else:
			item.ingredients.sort_custom(IngredientSorter, "name_asc")
			var parent_node := recipes
			var node:RecipeNode
			for i in item.ingredients:
				node = parent_node.get(i.name)
				if node == null:
					node = parent_node.add(RecipeNode.new(i.name))
				parent_node = node
			# the last node sets the item
			parent_node.item = item.name

	return recipes


class IngredientSorter:
	static func name_asc(a, b):
		if a.name < b.name:
			return true
		return false

