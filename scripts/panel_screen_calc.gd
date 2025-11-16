extends Node

@export_category("Amp-Freq Panels")
@export var sinFreqPanel: Node
@export var sinAmpPanel: Node
var textFreq
var textAmp

signal SinFreq(freq: float)
signal SinAmp(amp: float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if sinFreqPanel:
		textFreq = sinFreqPanel.find_child("LineEdit", true, true)
		textFreq.text = str(0.0)
	
	if sinAmpPanel:
		textAmp = sinAmpPanel.find_child("LineEdit", true, true)
		textAmp.text = str(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func execute(percentage, wheelType) -> void:
	var rounded_percentage
	if wheelType == "SinAmp":
		rounded_percentage = round_to_dec(percentage, 1)
		emit_signal("SinAmp", rounded_percentage)
	elif wheelType == "SinFreq":
		rounded_percentage = round_to_dec(percentage, 2)
		emit_signal("SinFreq", rounded_percentage)
	
	rounded_percentage = rounded_percentage * pow(10, 1)
	
	
	if wheelType == "SinFreq":
		textFreq.text = str(rounded_percentage)
	if wheelType == "SinAmp":
		textAmp.text = str(int(rounded_percentage))

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
