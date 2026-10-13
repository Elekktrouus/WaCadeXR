extends Node


const PORT = 9080


var _tcp_server = TCPServer.new()


var _peers: Dictionary[int, WebSocketPeer] = {}

var last_peer_id := 1


func _ready():
	var err = _tcp_server.listen(PORT)
	if err == OK:
		print("Server started.")
	else:
		push_error("Unable to start server.")
		set_process(false)


func _process(_delta):
	while _tcp_server.is_connection_available():
		last_peer_id += 1
		var ws = WebSocketPeer.new()
		ws.accept_stream(_tcp_server.take_connection())
		_peers[last_peer_id] = ws

	for peer_id in _peers.keys():
		var peer = _peers[peer_id]

		peer.poll()

		var peer_state = peer.get_ready_state()
		if peer_state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count():
				var packet = peer.get_packet()
				var reply: PackedByteArray = []
				match packet.get(1): #what command is being requested
					0x12:
						peer.send(get_pong(packet))
					0x10:
						set_led_data(packet)
					0x11:
						peer.send(get_ready(packet))
				
		elif peer_state == WebSocketPeer.STATE_CLOSED:
			# Remove the disconnected peer.
			_peers.erase(peer_id)
			var code = peer.get_close_code()
			var reason = peer.get_close_reason()
			
func get_pong(packet: PackedByteArray) -> PackedByteArray:
	var reply: PackedByteArray = [0x01, 0x1A, 6]	
	for i in range(3,7):
		reply.append(packet.get(i))
	reply.append(0x51)
	reply.append(0xED)
	return(reply)

func set_led_data(packet: PackedByteArray):
	GlobalSignal.set_led.emit(packet.slice(4, 52))
	
func get_ready(packet: PackedByteArray):
	return([0x01, 0x19, 0])
