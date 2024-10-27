extends Node

var url_auth = "https://id.twitch.tv/oauth2/token"
var game_query = "https://api.igdb.com/v4/games"
var cover_query = "https://api.igdb.com/v4/covers"
var client_id : String = "vq8irgof6mycds0jjox37jsuekoz52"
var client_secret : String = "87ql51uffe48uyvmzdzk1l3dd66vdo"
var grant_type : String = "client_credentials"

func _ready():
	$auth_request.request_completed.connect(auth_complete)
	var auth_request: String = url_auth + "?client_id=" + client_id + "&client_secret=" + client_secret + "&grant_type=" + grant_type
	$auth_request.request(auth_request,[],HTTPClient.METHOD_POST)
	
var access_token: String
func auth_complete(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		if result == OK:
			access_token = json["access_token"]  # Save the access token
			print("Authentication successful: ", access_token)
		else:
			print("Error parsing JSON:", json.error_string)
	else:
		print("Auth request failed with response code:", response_code)

@onready var placeholder_tex = preload("res://Images/placeholder_cover.jpg")
#Query a game by saerching it's title...
func query_game(game_title: String, game_plat : String) -> Dictionary:
	var res_dict = {
			"id": 0,
			"name": "", 
			"release": "",
			"tex": Texture2D
		}
	res_dict["tex"] = placeholder_tex
	
	if access_token:
		#var game_req = 'search "' + game_title + '";' + 'f id, name; w platforms = "' + game_plat + '"; limit 1'
		var game_req = 'search "' + game_title + '";' + 'f id, name, first_release_date; ; limit 1;'
		#var game_req = 'f id, name, first_release_date; w name ~ *"${'+ game_title +'}"*; limit 1;'
		#'fields age_ratings,aggregated_rating,aggregated_rating_count,alternative_names,artworks,bundles,category,checksum,collection,collections,cover,created_at,dlcs,expanded_games,expansions,external_games,first_release_date,follows,forks,franchise,franchises,game_engines,game_localizations,game_modes,genres,hypes,involved_companies,keywords,language_supports,multiplayer_modes,name,parent_game,platforms,player_perspectives,ports,rating,rating_count,release_dates,remakes,remasters,screenshots,similar_games,slug,standalone_expansions,status,storyline,summary,tags,themes,total_rating,total_rating_count,updated_at,url,version_parent,version_title,videos,websites;'
		var headers = [
			"Client-ID: " + client_id,
			"Authorization: Bearer " + access_token,
			"Content-Type: application/json",  # Ensure the content type is set
		]
		
		print("Performing search for ",game_title)
		if $game_request.request(game_query, headers, HTTPClient.METHOD_POST, game_req) != OK:
			push_error("Failed to send game request.")
# 	Wait for game response...
		var qry_game_res = await $game_request.request_completed
		print("Game Query Response: ", qry_game_res[1])
		var parse_game = JSON.parse_string(qry_game_res[3].get_string_from_utf8())
		if qry_game_res[1] == 200:
			if !parse_game.is_empty(): 
				var game_info = parse_game[0]
				print(game_info)
#	Fill return dictionary with relavant info
				res_dict["name"] = game_info["name"]
				res_dict["id"] = game_info["id"]
				#res_dict["release"] = game_info["first_release_date"]
				if game_info.has("first_release_date"):
					var date_dict : Dictionary = Time.get_date_dict_from_unix_time(game_info["first_release_date"])
					res_dict["release"] = date_dict["year"]
#	Construct Cover request
				var cover_req = 'f url, image_id; 
						w game = ' + str(game_info["id"]) + '; limit 1;'
				print("Performing cover search for ID: ",str(game_info["id"]))
				if $cover_request.request(cover_query, headers, HTTPClient.METHOD_POST, cover_req) != OK:
					push_error("Failed to send cover request.")
#	Wait for cover response...
				var qry_cover_res = await $cover_request.request_completed #AWAIT FOR COVER RESPONSE
				print("Cover Query Response: ", qry_cover_res[1])
				var parse_cover = JSON.parse_string(qry_cover_res[3].get_string_from_utf8())
				if qry_cover_res[1] == 200:
					if !parse_cover.is_empty():
						var cover_info = parse_cover[0]
						var cover_URL = 'https://images.igdb.com/igdb/image/upload/t_1080p_2x/' + cover_info["image_id"] + '.jpg'
						print(cover_URL)
						if $image_request.request(cover_URL) != OK:
							push_error("Failed to send image request.")
						var qry_image_res = await $image_request.request_completed #AWAIT FOR IMAGE RESPONSE
						print("Image Query Response: ", qry_image_res[1])
						if qry_image_res[1] == 200:
							var image = Image.new()
							if image.load_jpg_from_buffer(qry_image_res[3]) != OK:
								push_error("Failed to load image from buffer.")
							res_dict["tex"] = ImageTexture.create_from_image(image)
						else: push_error("Image query failed with response code:", qry_game_res[1])
				else: push_error("Cover query failed with response code:", qry_cover_res[1])
			else: print("No game results found.")
		else: push_error("Game query failed with response code:", qry_game_res[1])
	else: push_error("No IGDB access token.")
	return res_dict
							#notifman.notif_intro(texture, "TILE", "INFO")
