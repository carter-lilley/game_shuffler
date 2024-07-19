extends Node

var url = "https://id.twitch.tv/oauth2/token"
var client_id : String = "vq8irgof6mycds0jjox37jsuekoz52"
var client_secret : String = "3itbm4miw51xr9tuw8shwp2u7zbnf1"
var grant_type : String = "client_credentials"

func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed)
	var request: String = url + "?client_id=" + client_id + "&client_secret=" + client_secret + "&grant_type=" + grant_type
	$HTTPRequest.request(request,[],HTTPClient.METHOD_POST)

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json["expires_in"])
