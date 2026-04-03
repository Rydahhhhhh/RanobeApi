class_name RanobeBase
extends RefCounted

@warning_ignore_start("untyped_declaration", "unsafe_call_argument", "return_value_discarded", "unsafe_method_access")
func to_dict() -> Dictionary:
	var data := {}
	
	for prop: Dictionary in get_script().get_script_property_list():
		var value = get(prop.name)
		
		if value is RanobeBase:
			value = value.to_dict()
		
		data[prop.name] = value
	
	data.erase("ranobe_book.gd")
	
	return data
@warning_ignore_restore("untyped_declaration", "unsafe_call_argument", "return_value_discarded", "unsafe_method_access")

func _to_string() -> String:
	return JSON.stringify(to_dict(), "\t", false)

static func from_dict(dict: Dictionary, cls := RanobeBook) -> RanobeBase:
	var obj := cls.new()
	
	for key: String in dict:
		var value: Variant = dict[key]
		
		if typeof(value) in [TYPE_DICTIONARY, TYPE_ARRAY]:
			var parser_item_class: Script = get_property_class(key, obj)
		
			if not parser_item_class:
				continue
			@warning_ignore("unsafe_method_access")
			value = parser_item_class.from_dict(value, parser_item_class)
		
		obj.set(key, value)
	
	return obj
	
static func get_property_class(property: String, obj: Object) -> Script:
	var script: Script = obj.get_script()
	var script_map: Dictionary = script.get_script_constant_map()
	var src_code: String = script.source_code
	
	var key_i := src_code.find("var " + property + ": ")
	var nln_i := src_code.find("\n", key_i)
	
	var start: int = key_i + len(property) + 6
	var end: int = nln_i - start
	
	var cls_name := src_code.substr(start, end)
	
	for script_name: String in script_map:
		if cls_name == script_name:
			return script_map[script_name]
	
	#breakpoint
	
	return
		#return ERR_ALREADY_EXISTS
		#
	#var parser_item_class: Script = self.get(property).get_typed_script()
	#
	#var item = null
	#if parser_item_class != null:
		#item = _create_item.bindv(property_values).call(parser_item_class, value)
	#else:
		#item = value
	#
	#self.get(property).append(item)
	#print("Added Item (%s): " % property, item)
	#
#class RanobeBook extends RanobeBase:
	#var description: String
	#var description_ja: String
	#var id: float
	#var image_id: float
	#var lang: String
	#var romaji: String
	#var romaji_orig: String
	#var title: String
	#var title_orig: String
	#var c_release_date: float
	#var olang: String
	#var locked: bool
	#var hidden: bool
	#var image: RanobeImage
	#var rating: Dictionary
	#var num_reviews: Dictionary
	#var user_stats_score: Array
	#var user_stats_label: Array
	#var titles: Array
	#var editions: Array
	#var releases: Array
	#var publishers: Array
	#var series: Dictionary


class RanobeImage extends RanobeBase:
	var id: float
	var width: float
	var height: float
	var spoiler: bool
	var nsfw: bool
	var filename: String


class RanobeSeries:
	pass
