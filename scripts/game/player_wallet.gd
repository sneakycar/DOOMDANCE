extends Node
class_name PlayerWallet

signal money_changed(amount: int)

@export var starting_money: int = 8

var money: int = 0

func _ready() -> void:
	money = starting_money
	money_changed.emit(money)

func can_afford(cost: int) -> bool:
	return money >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	money -= cost
	money_changed.emit(money)
	return true

func earn(amount: int) -> void:
	money += maxi(0, amount)
	money_changed.emit(money)
