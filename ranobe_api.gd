extends Node
## https://ranobedb.org/api/docs/v0
const ENDPOINT := "https://ranobedb.org/api/v0/"
# "There are currently no rate-limits, but please do not exceed over 60 requests in 1 minute."
const RATE_LIMIT_IN_SECONDS := 1 # 60 (request) / 60 (seconds)

const COMMON_LANGUAGES = ['ja', 'en', 'zh-Hans', 'zh-Hant', 'fr', 'es', 'ko', 'ar', 'bg', 'ca', 'cs', 'ck', 'da', 'de', 'el', 'eo', 'eu', 'fa', 'fi', 'ga', 'gd', 'he', 'hi', 'hr', 'hu', 'id', 'it', 'iu', 'mk', 'ms', 'la', 'lt', 'lv', 'nl', 'no', 'pl', 'pt-pt', 'pt-br', 'ro', 'ru', 'sk', 'sl', 'sr', 'sv', 'ta', 'th', 'tr', 'uk', 'ur', 'vi']

const CACHE_STORE := 1 << 0
const CACHE_REQUEST := 1 << 1
const CACHE_FORCE_REQUEST := 1 << 2
const CACHE_DEFAULT := CACHE_STORE | CACHE_REQUEST

@onready var rate_limiter := Timer.new()
@onready var http_request := HTTPRequest.new()

var valid_tags: Dictionary

func _ready() -> void:
	add_child(http_request)
	add_child(rate_limiter)
	
	self.valid_tags = await fetch_tags()

func _fetch(url: String, cache_flags := CACHE_DEFAULT, cache_lifespan := Cache.WEEK_IN_SECONDS) -> Dictionary:
	url = ENDPOINT + url
	print("Fetching: %s" % url)
	
	var cache := Cache.new(url, cache_lifespan)
	
	if not (cache_flags & CACHE_FORCE_REQUEST):
		if (cache_flags & CACHE_REQUEST) and cache.can_request():
			return cache.get_data()
	
	if not rate_limiter.is_stopped():
		await rate_limiter.timeout
	
	rate_limiter.start(RATE_LIMIT_IN_SECONDS * 1.1)
	http_request.request(url)
	
	var response = await http_request.request_completed
	
	#var result: int = response[0]
	var response_code: int = response[1]
	#var headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code not in [200, 304]:
		push_error("Request failed: %s" % url)
		return {}
	
	var data_string: String = body.get_string_from_utf8()
	var parsed_data: Dictionary = JSON.parse_string(data_string)
	if not parsed_data:
		push_error("Could not parse data")
		return {}
	
	if cache_flags & CACHE_STORE:
		if not cache.store_data(parsed_data):
			push_warning("Store data failed")
	
	return parsed_data

func search_series(
	query: String,
	page: int = 1,
	limit: int = 24,
	pub_status: Array[String] = [], # 'ongoing' | 'completed' | 'hiatus' | 'stalled' | 'cancelled' | 'unknown' 
	tags_include: Array[float] = [],
 	tags_exclude: Array[float] = [],
	til: String = "", # 'and' | 'or' Tags include logic 
	tel: String = "", # 'and' | 'or' Tags exclude logic
	staff: Array[int] = [],
	staff_logic: String = "", # 'and' | 'or'
	publishers: Array[int] = [],
	publisher_logic: String = "", # 'and' | 'or'
	sort: String = "", #  'Relevance desc' | 'Relevance asc' | 'Title asc' | 'Title desc' | 'Start date asc' | 'Start date desc' | 'End date asc' | 'End date desc' | 'Num. books asc' | 'Num. books desc'
) -> Dictionary:
	var url := "series?q=" + query.uri_encode()
	
	if page > 1:
		url += "&page=" + str(page)
	
	if limit != 24:
		url += "&limit=" + str(limit)
	
	#region publication status
	if not pub_status.is_empty():
		for status: String in pub_status:
			if status in ['ongoing', 'completed', 'hiatus', 'stalled', 'cancelled', 'unknown']:
				url += "&pubStatus=" + status
	#endregion
	
	#region genres & tags
	
	if not tags_include.is_empty():
		for genre: int in _validate_tags(tags_include):
			var param_str := "&tagsInclude=" + str(genre)
			if param_str not in url:
				url += param_str
	
	if not tags_exclude.is_empty():
		for genre: int in _validate_tags(tags_exclude):
			var param_str := "&tagsExclude=" + str(genre)
			if param_str not in url:
				url += param_str
	
	if not til.is_empty():
		if til in ["and", "or"]:
			url += "&til=" + til
	
	if not tel.is_empty():
		if til in ["and", "or"]:
			url += "&tel=" + tel
	#endregion
	
	#region Staff
	for staff_id in staff:
		url += "&staff=" + str(staff_id)
	
	if not staff_logic.is_empty():
		if staff_logic in ["and", "or"]:
			url += "&sl=" + staff_logic
	
	#endregion
	
	#region Publisher
	for publisher_id in publishers:
		url += "&p=" + str(publisher_id)
	
	if not publisher_logic.is_empty():
		if publisher_logic in ["and", "or"]:
			url += "&pl=" + publisher_logic
	
	#endregion
	
	if not sort.is_empty():
		if sort in ['Relevance desc', 'Relevance asc', 'Title asc', 'Title desc', 'Release date asc', 'Release date desc']:
			url += "&sort=" + sort.replace(" ", "+")
	
	return await _fetch(url) 

func search_books(
	query: String,
	page: int = 1,
	limit: int = 24,
	release_languages: Array[String] = [],
	release_language_logic: String = "", # 'and' | 'or'
	release_formats: Array[String] = [],
	release_format_logic: String = "", # 'and' | 'or'
	staff: Array[int] = [],
	staff_logic: String = "", # 'and' | 'or'
	publishers: Array[int] = [],
	publisher_logic: String = "", # 'and' | 'or'
	sort: String = "", # 'Relevance desc' | 'Relevance asc' | 'Title asc' | 'Title desc' | 'Release date asc' | 'Release date desc'
) -> Dictionary:
	var url := "books?q=" + query.uri_encode()
	
	if page > 1:
		url += "&page=" + str(page)
	
	if limit != 24:
		url += "&limit=" + str(limit)
	
	#region Language
	for release_language in release_languages:
		if release_language not in COMMON_LANGUAGES:
			continue
		url += "&rl=" + release_language
	
	if not release_language_logic.is_empty():
		if release_language_logic in ["and", "or"]:
			url += "&rll=" + release_language_logic
	
	#endregion
	
	#region Format
	for release_format in release_formats:
		if release_format not in ["digital", "print", "audio"]:
			continue
		url += "&rf=" + release_format
	
	if not release_format_logic.is_empty():
		if release_format_logic in ["and", "or"]:
			url += "&rfl=" + release_format_logic
	
	#endregion
	
	#region Staff
	for staff_id in staff:
		url += "&staff=" + str(staff_id)
	
	if not staff_logic.is_empty():
		if staff_logic in ["and", "or"]:
			url += "&sl=" + staff_logic
	
	#endregion
	
	#region Publisher
	for publisher_id in publishers:
		url += "&p=" + str(publisher_id)
	
	if not publisher_logic.is_empty():
		if publisher_logic in ["and", "or"]:
			url += "&pl=" + publisher_logic
	
	#endregion
	
	if not sort.is_empty():
		if sort in ['Relevance desc', 'Relevance asc', 'Title asc', 'Title desc', 'Release date asc', 'Release date desc']:
			url += "&sort=" + sort.replace(" ", "+")
	
	return await _fetch(url)

func fetch_book(ranobe_book_id: float) -> Dictionary:
	return (await _fetch("book/" + str(ranobe_book_id))).get("book", {})

func fetch_series(ranobe_series_id: float) -> Dictionary:
	return (await _fetch("series/" + str(ranobe_series_id))).get("series", {})

func fetch_tags(cache_flags := CACHE_DEFAULT):
	var cache := Cache.new("TAGS", Cache.MONTH_IN_SECONDS)
	
	if not (cache_flags & CACHE_FORCE_REQUEST):
		if (cache_flags & CACHE_REQUEST) and cache.can_request():
			return cache.get_data()
	
	var response: Dictionary = await RanobeApi._fetch("tags", cache_flags, Cache.MONTH_IN_SECONDS)
	
	var tags: Array = response.tags
	
	var current_page := float(response.currentPage)
	var total_pages := float(response.totalPages)
	
	while current_page < total_pages:
		var new_page := current_page + 1
		var url: String = "tags?page=" + str(new_page)
		
		response = await RanobeApi._fetch(url, cache_flags, Cache.MONTH_IN_SECONDS)
		tags.append_array(response.tags)
		
		current_page = float(response.currentPage)
	
	var parsed_tags: Dictionary[String, Dictionary]
	
	for tag in tags:
		parsed_tags.get_or_add(tag.ttype, {})[tag.name] = tag
		tag.erase("ttype")
		tag.erase("name")
	
	if cache_flags & CACHE_STORE:
		if not cache.store_data(parsed_tags):
			push_warning("Store data failed")
	
	return parsed_tags

func _validate_tags(tags: Array[float]) -> Array[float]:
	var valid_tag_ints: Array[float] = []
	
	for tag in valid_tags.genre.values() + valid_tags.tag.values():
		valid_tag_ints.append(float(tag.id))
	
	valid_tag_ints.sort()
	
	for tag in tags.duplicate():
		if tag not in valid_tag_ints:
			tags.erase(tag)
	
	return tags
	
class Cache:
	const MONTH_IN_SECONDS := 2629746
	const WEEK_IN_SECONDS := 604800
	
	const CACHE_DIR := "user://RanobeDB"
	
	var file_path: String
	var lifespan: int
	
	static func _static_init() -> void:
		if not DirAccess.dir_exists_absolute(CACHE_DIR):
			@warning_ignore("return_value_discarded")
			DirAccess.make_dir_absolute(CACHE_DIR)
	
	static func get_file_path(url: String) -> String:
		return CACHE_DIR + "//" + url.validate_filename()
	
	func _init(url: String, lifespan_in_seconds: int) -> void:
		self.file_path = get_file_path(url)
		self.lifespan = lifespan_in_seconds
	
	func _last_updated() -> float:
		return Time.get_unix_time_from_system() - FileAccess.get_modified_time(self.file_path)
	
	func can_request() -> bool:
		if _last_updated() > self.lifespan:
			return false
		
		var file := FileAccess.open(self.file_path, FileAccess.READ)
		if not file:
			match FileAccess.get_open_error():
				ERR_FILE_NOT_FOUND:
					return false
				_:
					push_error("Failed to open file")
					return false
		
		return true 
	
	func get_data() -> Dictionary:
		var file := FileAccess.open(self.file_path, FileAccess.READ)
		return file.get_var() 
	
	func store_data(request_data: Dictionary) -> bool:
		var file := FileAccess.open(self.file_path, FileAccess.WRITE)
		return file.store_var(request_data)
	
	
	
