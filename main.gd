extends Node

func _ready() -> void:
	
	
	

	#var book_data = await RanobeApi.get_books("The agent of four seasons", 1, 24, ["en"], "", ["digital"], "", [], "", [], "")
	
	var series_data = await RanobeApi.search_series("The otome heroine", 1, 24, ["ongoing"], [10, 17, 15, 1, 2, 4, 4, 5, 1])
	
	print(JSON.stringify(series_data, "	"))
	#print(JSON.stringify(await RanobeApi.search_books("Roll over and die"), "	"))
	#print(JSON.stringify(await RanobeApi.search_books("A Lily Blooms in another world"), "	"))
