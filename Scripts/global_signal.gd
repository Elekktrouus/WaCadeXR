extends Node

signal touch_hit(side: int)
signal request_movement(target: Node3D, pos: Vector3)
signal set_led(packet: PackedByteArray)
var cab_controlled
