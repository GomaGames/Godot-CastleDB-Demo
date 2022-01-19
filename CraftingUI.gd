extends Control

onready var inventory := $Inventory/ItemList
onready var craftable := $Craftable/ItemList
onready var craft_btn := $Craft
onready var tween := $Tween
onready var basic_items_texture := load("res://assets/crafting_materials/resources_basic.png")
onready var recipes_cdb := load("")

const atlas_tile_size := 24
const items = {
	"wood": [0, 0],
	"lumber": [1, 0],
	"stick": [2, 0],
	"rock": [3, 3],
	"stone": [3, 1],
	"leaves": [1, 9],
	"vine": [8, 6],
	"pickaxe": [9, 1],
	"hammer": [9, 2],
}

const selected_items:Dictionary = {} # idx: bool
const active_ingredients := []
var active_recipe := ""

class RecipeNode:
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

class RawMaterial:
	var name:String
	var icon:String

	func _init(name:String, icon:String):
		self.name = name
		self.icon = icon


# a trie with ingredients sorted by alpha ascending from root to last branch
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

var recipes: RecipeNode
var materials := Array() # -> RawMaterial

func read_db(db_path:String): # -> Dictionary
	var data_file = File.new()
	if data_file.open(db_path, File.READ) != OK:
		push_error("could not open: " + db_path)
		return null
	var data_text = data_file.get_as_text()
	data_file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		push_error(data_parse.error)
		return null
	return data_parse.result

class IngredientSorter:
	static func name_asc(a, b):
		if a.name < b.name:
			return true
		return false

func load_items():
	recipes = RecipeNode.new("root")
	var items_db:Dictionary = read_db("res://db/recipes.cdb")

	var items_sheet:Dictionary = items_db["sheets"][0]
	var items_columns:Array = items_sheet["columns"] # name, typeStr, display
	var items_lines:Array = items_sheet["lines"] # name, ingredients, icon

	for item in items_lines:
		if item.ingredients.size() == 0:
			materials.append(RawMaterial.new(item.name, item.icon))
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
			# parent_node.add(RecipeNode.new(item.name, true))


func _ready():
	load_items()
	
	add_item(inventory, "leaves")
	add_item(inventory, "leaves")
	add_item(inventory, "leaves")
	add_item(inventory, "wood")
	add_item(inventory, "wood")
	add_item(inventory, "wood")
	add_item(inventory, "wood")
	add_item(inventory, "wood")
	add_item(inventory, "wood")
	add_item(inventory, "rock")
	add_item(inventory, "rock")
	add_item(inventory, "rock")
	add_item(inventory, "rock")
	add_item(inventory, "rock")
	add_item(inventory, "rock")
	add_item(inventory, "vine")

	calculate_craftable()


func add_item(item_list:ItemList, name:String):
	var item:Array = items[name]
	var at:AtlasTexture = AtlasTexture.new()
	at.atlas = basic_items_texture
	at.region = Rect2(item[0]*atlas_tile_size, item[1]*atlas_tile_size, atlas_tile_size, atlas_tile_size)
	item_list.add_item(name, at)

func update_craftable():
	var craftable_item = calculate_craftable()
	craftable.clear()
	if craftable_item != null:
		add_item(craftable, craftable_item)
		active_recipe = craftable_item

func calculate_craftable():
	var selected_sorted := Array()

	for i in selected_items:
		if selected_items[i]:
			selected_sorted.append(inventory.get_item_text(i))

	selected_sorted.sort()

	var i := 0
	var l := selected_sorted.size()
	var r = recipes
	while i < l and r.has(selected_sorted[i]):
		r = r.get(selected_sorted[i])
		active_ingredients.append(selected_sorted[i])
		i += 1

	if r.item == "":
		craft_btn.disabled = true
		active_ingredients.clear()
		return null
	else:
		craft_btn.disabled = false
		return r.item

func _on_ItemList_multi_selected(index, _selected):
	if selected_items.has(index):
		selected_items[index] = !selected_items[index]
	else:
		selected_items[index] = true

	inventory.unselect_all()
	for i in selected_items:
		if selected_items[i]:
			inventory.select(i, false)

	update_craftable()


func _on_ItemList_item_activated(_index):
	craft_item()

func _on_Craft_pressed():
	craft_item()

func craft_item():
	if craftable.items.size() == 0:
		return
		
	for item in active_ingredients:
		for i in selected_items:
			if selected_items[i]:
				if item == inventory.get_item_text(i):
					inventory.remove_item(i)
					break

	# @todo animate selected inventory items out

	# animate craftable items in to inventory
	var s := Sprite.new()
	s.texture = craftable.get_item_icon(0)
	s.scale = Vector2(2,2)
	s.global_position = craftable.get_global_transform().get_origin()
	self.add_child(s)

	var dest := Vector2(s.global_position.x - 200, s.global_position.y)
	tween.interpolate_property(s, "position",
		s.global_position, dest, .3,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

	selected_items.clear()
	inventory.unselect_all()
	craftable.clear()
	craft_btn.disabled = true

func _on_Tween_tween_completed(object, _key):
	self.remove_child(object)
	add_item(inventory, active_recipe)
	active_recipe = ""
