extends Node

var url_auth = "https://id.twitch.tv/oauth2/token"
var url_query = "https://api.igdb.com/v4/games"
var client_id : String = "vq8irgof6mycds0jjox37jsuekoz52"
var client_secret : String = "3itbm4miw51xr9tuw8shwp2u7zbnf1"
var grant_type : String = "client_credentials"

func _ready():
	$HTTPRequest.request_completed.connect(auth_complete)
	var auth_request: String = url_auth + "?client_id=" + client_id + "&client_secret=" + client_secret + "&grant_type=" + grant_type
	$HTTPRequest.request(auth_request,[],HTTPClient.METHOD_POST)
	
var access_token: String
func auth_complete(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		if result == OK:
			access_token = json["access_token"]  # Save the access token
			print("Authentication successful")
		else:
			print("Error parsing JSON:", json.error_string)
	else:
		print("Auth request failed with response code:", response_code)

func query_igdb(game_title: String):
	if access_token != "":
		var request_body = 'fields *; where name ~ "*' + game_title + '*";'
		var headers = [
			"Client-ID: " + client_id,
			"Authorization: Bearer " + access_token,
			"Content-Type: application/json"
		]
		$HTTPRequest.request(url_query, headers, HTTPClient.METHOD_POST, request_body)
