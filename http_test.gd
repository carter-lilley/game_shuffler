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

func query_game(game_title: String):
	print("Performing serach for ",game_title)
	if access_token:
		var game_req = 'search "' + game_title + '"; f id, name; limit 1;'
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

#https://images.igdb.com/igdb/image/upload/t_{size}/{hash}.jpg
#https://images.igdb.com/igdb/image/upload/t_1080p_2x/co2j5g.jpg!!!!
func game_query_result(result, response_code, headers, body):
	print("Result: ", result)
	print("Response Code: ", response_code)
	print("Query body: " + body.get_string_from_utf8())
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json[0] is Dictionary:
		print(json[0]["name"])
		query_cover(json[0]["id"])
	else:
		print("Query request failed with response code:", response_code)

func cover_query_result(result, response_code, headers, body):
	print("Result: ", result)
	print("Response Code: ", response_code)
	print("Query body: " + body.get_string_from_utf8())
