class_name RanobeBook 
extends RanobeBase

var description: String
var description_ja: String
var id: float
var image_id: float
var lang: String
var romaji: String
var romaji_orig: String
var title: String
var title_orig: String
var c_release_date: float
var olang: String
var locked: bool
var hidden: bool
var image: RanobeImage
var rating: Dictionary
var num_reviews: Dictionary
var user_stats_score: Array
var user_stats_label: Array
var titles: Array
var editions: Array
var releases: Array
var publishers: Array
var series: Dictionary



	#if _item_exists(property, value):


class RanobeImage extends RanobeBase:
	var id: float
	var width: float
	var height: float
	var spoiler: bool
	var nsfw: bool
	var filename: String


class RanobeSeries:
	pass
