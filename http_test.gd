extends Node

var url_auth = "https://id.twitch.tv/oauth2/token"
var game_query = "https://api.igdb.com/v4/games"
var cover_query = "https://api.igdb.com/v4/covers"
var client_id : String = "vq8irgof6mycds0jjox37jsuekoz52"
var client_secret : String = "3itbm4miw51xr9tuw8shwp2u7zbnf1"
var grant_type : String = "client_credentials"

func _ready():
	$cover_request.request_completed.connect(cover_query_result)
	$game_request.request_completed.connect(game_query_result)
	$auth_request.request_completed.connect(auth_complete)
	$image_request.request_completed.connect(image_query_result)
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

var curr_title
var curr_info
func query_game(game_title: String, game_plat : String):
	curr_title = game_title
	curr_info = game_plat
	print("Performing serach for ",game_title)
	if access_token:
		#var game_req = 'search "' + game_title + '";' + 'f id, name; w platforms = "' + game_plat + '"; limit 1'
		var game_req = 'search "' + game_title + '";' + 'f id, name; limit 1;'
		#var game_req = 'f id, name; w name ~ *"${'+ game_title +'}"*; limit 1;'
		#`name ~ *"${query}"*`
		var headers = [
			"Client-ID: " + client_id,
			"Authorization: Bearer " + access_token,
			"Content-Type: application/json",  # Ensure the content type is set
		]
		$game_request.request(game_query, headers, HTTPClient.METHOD_POST, game_req)

func query_cover(game_id: int):
	print("Performing cover search for ID: ",str(game_id))
	if access_token:
		var cover_req = 'f url, image_id; 
						 w game = ' + str(game_id) + '; limit 1;'
		var headers = [
			"Client-ID: " + client_id,
			"Authorization: Bearer " + access_token,
			"Content-Type: application/json",  # Ensure the content type is set
		]
		$cover_request.request(cover_query, headers, HTTPClient.METHOD_POST, cover_req)

func game_query_result(result, response_code, headers, body):
	print("Game Query Response: ", response_code)
	print("Query body: " + body.get_string_from_utf8())
	var game = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		if !game.is_empty():
			query_cover(game[0]["id"])
		else:
			print("No results found.")
			game_intro_scene(null)
	else:
		push_error("Query request failed with response code:", response_code)

func cover_query_result(result, response_code, headers, body):
	print("Cover Query Response: ", response_code)
	var req = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		if !req.is_empty():
			var img_URL = 'https://images.igdb.com/igdb/image/upload/t_1080p_2x/' + req[0]["image_id"] + '.jpg'
			print(img_URL)
			$image_request.request(img_URL)
	else:
		push_error("An error occurred in the HTTP request.")

func image_query_result(result, response_code, headers, body):
	print("Image Query Response: ", response_code)
	if response_code == 200:
		var image = Image.new()
		var load_result = image.load_jpg_from_buffer(body)
		if load_result == OK:
			var texture = ImageTexture.create_from_image(image)
			game_intro_scene(texture)
		else:
			push_error("Failed to load image from buffer: ", load_result)
	else:
		push_error("Request failed with response code: ", response_code)

@onready var pop_up_scene = preload("res://Scenes/game_intro.tscn")  # Load the scene as a PackedScene
func game_intro_scene(tex : Texture2D):
	var pop_up_instance = pop_up_scene.instantiate()
	add_child(pop_up_instance)
	pop_up_instance.set_info(curr_title,curr_info)
	if tex:
		pop_up_instance.set_art(tex)
	
