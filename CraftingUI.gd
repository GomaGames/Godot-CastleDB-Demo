extends Control

onready var inventory := $Inventory/ItemList
onready var craftable := $Craftable/ItemList
onready var tween := $Tween
onready var basic_items := load("res://assets/crafting_materials/resources_basic.png")

const atlas_tile_size := 24
const items = {
	"wood": [0, 0],
	"lumber": [1, 0],
	"stick": [2, 0],
	"rock": [3, 3],
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
		
	func _init(name:String, item:String, children:Array = []):
		self.name = name
		self.item = item
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

# a trie with ingredients sorted by alpha ascending from root to last branch
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

func _ready():
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
	add_item(inventory, "vine")

	
	calculate_craftable()
	
func add_item(item_list:ItemList, name:String):
	var item:Array = items[name]
	var at:AtlasTexture = AtlasTexture.new()
	at.atlas = basic_items
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
		active_ingredients.clear()
		return null
	else:
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
	
func _on_Tween_tween_completed(object, _key):
	self.remove_child(object)
	add_item(inventory, active_recipe)
	active_recipe = ""
