class_name Key extends HeldItem


const COLORS := {
	1: Color("#ff4040"),
	2: Color("#ffe240"),
	3: Color("#38ff26"),
	4: Color("#26ffe9"),
	5: Color("#2679ff"),
	6: Color("#a826ff"),
	7: Color("#ff26c9")
}


@export_enum("1:1", "2:2", "3:3", "4:4", "5:5", "6:6", "7:7") var channel : int = 1


func _ready() -> void:
	super._ready()
	modulate = COLORS[channel]
