extends Node
class_name HTTPManager
var url_auth := "https://id.twitch.tv/oauth2/token"
var igdb_games_url := "https://api.igdb.com/v4/games"
var igdb_platforms_url := "https://api.igdb.com/v4/platforms"
var client_id := "vq8irgof6mycds0jjox37jsuekoz52"
var client_secret := "nfpyte210unj6m5ugempo41gswkouj"
var grant_type := "client_credentials"

var access_token := ""
@onready var placeholder_tex := preload("res://Images/placeholder_cover.jpg")

func _ready():
	print("Ready test")
	await authenticate()

# Authenticate with Twitch and get access token
func authenticate() -> void:
	var auth_url = "%s?client_id=%s&client_secret=%s&grant_type=%s" % [url_auth, client_id, client_secret, grant_type]
	var res = await send_http_request(auth_url, [], HTTPClient.METHOD_POST)
	if res.size() > 0 and res[1] == 200:
		var parsed = JSON.parse_string(res[3].get_string_from_utf8())
		if parsed.has("access_token"):
			access_token = parsed["access_token"]
			print("Authenticated with IGDB.")
		else:
			push_error("Access token not found in response.")
	else:
		push_error("Failed to authenticate with Twitch.")

# Public function to query game info
func query_game(title: String, system: String) -> Dictionary:
	var result = {
		"id": 0,
		"name": "",
		"release": "",
		"tex": placeholder_tex
	}

	if access_token == "":
		push_error("No access token.")
		return result

	var platform_id = await get_platform_id_from_slug(system)
	if platform_id == -1:
		push_error("Could not find platform ID for system: %s" % system)
		return result

	var headers = [
		"Client-ID: " + client_id,
		"Authorization: Bearer " + access_token,
		"Content-Type: application/json"
	]

	var query = '''
		search "%s";
		fields id, name, first_release_date, cover.image_id;
		where platforms = [%d];
		limit 1;
	''' % [title, platform_id]

	var game_res = await send_http_request(igdb_games_url, headers, HTTPClient.METHOD_POST, query.strip_edges())
	if game_res.size() == 0 or game_res[1] != 200:
		push_error("Game query failed with code: %d" % game_res[1])
		return result

	var parsed = JSON.parse_string(game_res[3].get_string_from_utf8())
	if parsed.is_empty():
		print("No results for game: %s" % title)
		return result

	var game = parsed[0]
	result["id"] = game.get("id", 0)
	result["name"] = game.get("name", "")
	if game.has("first_release_date"):
		var date = Time.get_date_dict_from_unix_time(game["first_release_date"])
		result["release"] = date["year"]

	if game.has("cover") and game["cover"].has("image_id"):
		var img_id = game["cover"]["image_id"]
		var img_url = "https://images.igdb.com/igdb/image/upload/t_1080p_2x/%s.jpg" % img_id
		var img_res = await send_http_request(img_url, [], HTTPClient.METHOD_GET)
		if img_res.size() > 0 and img_res[1] == 200:
			var img = Image.new()
			if img.load_jpg_from_buffer(img_res[3]) == OK:
				result["tex"] = ImageTexture.create_from_image(img)
			else:
				push_error("Failed to load image from buffer.")
		else:
			push_error("Image download failed: %d" % img_res[1])
	else:
		print("No cover image found for game: %s" % title)

	return result

# Look up platform ID from system string like 'ngc'
func get_platform_id_from_slug(slug: String) -> int:
	var query := "fields id, name, slug;\nwhere slug = \"%s\";" % slug
	var headers = [
		"Client-ID: %s" % client_id,
		"Authorization: Bearer %s" % access_token
	]
	var res = await send_http_request("https://api.igdb.com/v4/platforms", headers, HTTPClient.METHOD_POST, query)

	if res.size() > 0 and res[1] == 200:
		var parsed = JSON.parse_string(res[3].get_string_from_utf8())
		if parsed.size() > 0:
			print("[HTTPManager]","Platform slug returned ID: ",parsed[0].get("id", -1))
			return parsed[0].get("id", -1)

	push_error("Platform slug '%s' not found." % slug)
	return -1

# Helper function to spawn an HTTPRequest for each request
func send_http_request(
	url: String,
	headers: PackedStringArray,
	method: int,
	body: String = ""
) -> Array:
	var req := HTTPRequest.new()
	add_child(req)
	var ok = req.request(url, headers, method, body)
	if ok != OK:
		push_error("Failed to send HTTP request to %s" % url)
		req.queue_free()
		return []
	var res = await req.request_completed
	req.queue_free()
	return res
