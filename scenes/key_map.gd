extends Node


func _ready():
	load_keymap()


func load_keymap() :
	InputMap.add_action("mv_fw")
	InputMap.add_action("mv_bw")
	InputMap.add_action("mv_lf")
	InputMap.add_action("mv_rg")
	InputMap.add_action("mv_up")
	InputMap.add_action("mv_dn")
	InputMap.add_action("jump")
	InputMap.add_action("shoot")
	
	
	var k_fw = InputEventKey.new()
	k_fw.physical_keycode = KEY_W
	InputMap.action_add_event("mv_fw", k_fw)
	var k_bw = InputEventKey.new()
	k_bw.physical_keycode = KEY_S
	InputMap.action_add_event("mv_bw", k_bw)
	var k_lf = InputEventKey.new()
	k_lf.physical_keycode = KEY_A
	InputMap.action_add_event("mv_lf", k_lf)
	var k_rg = InputEventKey.new()
	k_rg.physical_keycode = KEY_D
	InputMap.action_add_event("mv_rg", k_rg)
	
	var k_fwa = InputEventKey.new()
	k_fwa.physical_keycode = KEY_UP
	InputMap.action_add_event("mv_fw", k_fwa)
	var k_bwa = InputEventKey.new()
	k_bwa.physical_keycode = KEY_DOWN
	InputMap.action_add_event("mv_bw", k_bwa)
	var k_lfa = InputEventKey.new()
	k_lfa.physical_keycode = KEY_LEFT
	InputMap.action_add_event("mv_lf", k_lfa)
	var k_rga = InputEventKey.new()
	k_rga.physical_keycode = KEY_RIGHT
	InputMap.action_add_event("mv_rg", k_rga)
	
	var k_up = InputEventKey.new()
	k_up.physical_keycode = KEY_E
	InputMap.action_add_event("mv_up", k_up)
	var k_dn = InputEventKey.new()
	k_dn.physical_keycode = KEY_Q
	InputMap.action_add_event("mv_dn", k_dn)
	
	var k_jp = InputEventKey.new()
	k_jp.physical_keycode = KEY_SPACE
	InputMap.action_add_event("jump", k_jp)
	
	
	
	var m_sha = InputEventMouseButton.new()
	m_sha.button_index = 1
	#m_sha.butt
	#k_rga.physical_keycode = KEY_RIGHT
	InputMap.action_add_event("shoot", m_sha)
	
