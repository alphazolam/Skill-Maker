--Skill Maker (formerly Spell Maker) for Dragons Dogma 2
--Create your own skills as sequences of animations, melee attacks, summons, lightning, explosions and other magical or physical effects
--By alphaZomega
--Requires REFramework
local version = "1.18"

--Fixed most bugs caused by the October DD2 updates
--Disabled summoning of skeletons and bandits to prevent crashing
--Fixed summons attacking and hurting the player (broken with game updates)
--Added 'Turn Speed' node option for turning slower/faster with 'Turn to Analog Stick'
--Added 'Hide UI' Skill Setting to manually disable a Skill from appearing in the in-game UI
--Added interpolation frames option to 'Custom Motion/Frame'
--Added start frames (in parenthesis) for 'Skill States' text box in States
--Added 'GameTime' variable to 'Custom Function' to tell the current time (accounting for pause), and removed 'ElapsedTime'
--Added 'ReachedEnemy' function to 'Custom Function' to tell when Pl Soft Lock target has been approached
--Added 'ActiveSummons' variable to 'Custom Function' to manage all spawned summons
--You can now input 'nil' as the Custom Motion motlist and just use known bankID and motionID to play animations
--Typing '1' while trying to type '13' into Skill Duration will no longer set the duration to 1 second while still typing
--Added 'Mirror Wp' node option to mirror weapon to other hand
--Added 'Mirror Time' node option to set the duration of mirroring
--Fixed issues with ballista and some other special controls

local sms
local default_sms = {
	enabled = true,
	modifier_inhibits_buttons = true,
	spells = {},
	use_modifier = true,
	crosshair_type = 3,
	last_sel_spells = {},
	shell_lifetime_limit = 120,
	use_window = true,
	do_shift_sheathe = true,
	do_swap_lshoulders = true,
	maximum_range = 100,
	move_cam_for_crosshair = 4,
	load_cfgs_w_modifier = true,
	load_cfgs_w_cfg_modifier = true,
	ingame_ui_buttons = true,
	do_clear_spells_on_cfg_load = false,
	do_force_cam_dist = true,
	max_spells = 24,
	max_configs = 8,
	configs = {},
	configs_loadcontrols = {},
	preset_descs = {},
}

scene_ctr = 0
while scene_ctr < 100 and not pcall(function()
	scene = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")
	scene_ctr = nil
end) do scene_ctr = scene_ctr + 1 end

local function setup_gamepad_specific_defaults()
	local is_pad_connected = sdk.call_native_func(sdk.get_native_singleton("via.hid.Gamepad"), sdk.find_type_definition("via.hid.GamePad"), "getMergedDevice", 0):get_Connecting()
	local do_shift_sheathe = is_pad_connected
	local do_swap_lshoulders = is_pad_connected
	default_sms.hotkeys = {
		["Modifier / Inhibit"] = is_pad_connected and "LT (L2)" or "X",
		["SM Modifier2"] = is_pad_connected and "LB (L1)" or "R Mouse",
		["SM Config Modifier"] = is_pad_connected and "RB (R1)" or "LAlt",
		["Prev Sel Shell"] = "Alpha3",
		["Next Sel Shell"] = "Alpha4",
		["UI Modifier"] = "LShift",
		["Reset Player State"] = "Back",
		["SM Clean Up"] = "Back",
		["Undo"] = "Z",
		["Redo"] = "Y",
		["Use Skill 1"] = is_pad_connected and "Y (Triangle)" or "V", 
		["Use Skill 2"] = is_pad_connected and "A (X)" or "Space",
		["Use Skill 3"] = is_pad_connected and "X (Square)" or "L Mouse",
		["Use Skill 4"] = is_pad_connected and "B (Circle)" or "LShift",
		["Use Skill 5"] = is_pad_connected and "LUp" or "Alpha1",
		["Use Skill 6"] = is_pad_connected and "LDown" or "Alpha2",
		["Use Skill 7"] = is_pad_connected and "LLeft" or "Alpha3",
		["Use Skill 8"] = is_pad_connected and "LRight" or "Alpha4",
		["Use Skill 9"] = is_pad_connected and "LStickPush" or "C",
		["Use Skill 10"] = is_pad_connected and "RStickPush" or "G",
		["Use Skill 11"] = is_pad_connected and "RB (R1)" or "R Mouse",
		["Use Skill 12"] = is_pad_connected and "RT (R2)" or "E",
		["Use Skill 13"] = is_pad_connected and "Y (Triangle)" or "V",
		["Use Skill 14"] = is_pad_connected and "A (X)" or "Space",
		["Use Skill 15"] = is_pad_connected and "X (Square)" or "L Mouse",
		["Use Skill 16"] = is_pad_connected and "B (Circle)" or "LShift",
		["Use Skill 17"] = is_pad_connected and "LUp" or "Alpha1",
		["Use Skill 18"] = is_pad_connected and "LDown" or "Alpha2",
		["Use Skill 19"] = is_pad_connected and "LLeft" or "Alpha3",
		["Use Skill 20"] = is_pad_connected and "LRight" or "Alpha4",
		["Use Skill 21"] = is_pad_connected and "LStickPush" or "C",
		["Use Skill 22"] = is_pad_connected and "RStickPush" or "G",
		["Use Skill 23"] = is_pad_connected and "RB (R1)" or "R Mouse",
		["Use Skill 24"] = is_pad_connected and "RT (R2)" or "E",
		["Load Config 1"] = is_pad_connected and "Y (Triangle)" or "[Not Bound]",
		["Load Config 2"] = is_pad_connected and "A (X)" or "[Not Bound]",
		["Load Config 3"] = is_pad_connected and "X (Square)" or "[Not Bound]",
		["Load Config 4"] = is_pad_connected and "B (Circle)" or "[Not Bound]",
		["Load Config 5"] = is_pad_connected and "LUp" or "[Not Bound]",
		["Load Config 6"] = is_pad_connected and "LDown" or "[Not Bound]",
		["Load Config 7"] = is_pad_connected and "LLeft" or "[Not Bound]",
		["Load Config 8"] = is_pad_connected and "LRight" or "[Not Bound]",
	}
end

local imgui_spells = {}

local function setup_default_lists()
	local last_spell = sms.spells[#sms.spells]
	local new_spells = {}
	for i, spell in pairs(sms.spells) do
		if i > sms.max_spells then sms.spells[i] = nil end
	end
	
	for i = 1, sms.max_spells do 
		imgui_spells[i] = {preset_idx=presets_glob and hk.find_index(presets_glob, sms.last_sel_spells[i]) or 1, shell_datas={}, scale_together=true, tmp={},}
		default_sms.hotkeys["Use Skill "..i] = default_sms.hotkeys["Use Skill "..i] or "[Not Bound]"
		new_spells[i] = {
			activate_fn = "",
			enabled = true,
			duration = 1.0,
			stam_cost = 0.0,
			job_idx = 1,
			require_weapon = false,
			require_hitbox = false,
			hide_ui = false,
			state_type_idx = 2,
			use_modifier2 = i > 12,
			damage_multiplier = 1.0,
			desc = "",
			do_hold_button = false,
			do_move_cam = false,
			do_auto = false,
			states = {Always=false, Standing=true, Airborne=false, Falling=false, Job=false, Damaged=false, Climbing=false, Sprinting=false, Aiming=false,}, 
			spell_states = "",
			custom_states = "",
			anim_states = "",
			frame_range = {-1.0,-1.0},
			frame_range_upper = {-1.0,-1.0},
			wp_idx = 1,
			unedited = true,
			shells = {
				{
					enabled = true,
					action_idx = 1, 
					action_name = "None",
					anim_speed = 1.0,
					attach_euler = {0,0,0},
					attach_pos = {0,0,0},
					attach_to_joint = false, 
					attack_rate = 1.0,
					boon_type = 1,
					boon_color = {1.0,1.0,1.0,1.0},
					cast_type = 1, 
					camera_dist = -1.0,
					coloring = {1,1,1,1},
					custom_fn = "",
					custom_motion = "",
					do_abs_lifetime = false,
					do_carryover_prev = false,
					do_simplify_action = true,
					do_hold = false,
					do_iframes = false,
					do_inhibit_buttons = false,
					do_mirror_action = false,
					do_mirror_wp = false,
					mirror_time = -1.0,
					do_no_attach_rotate = false,
					do_aim_up_down = false,
					do_pl_soft_lock = false,
					pl_velocity = {0.0,0.0,0.0},
					pl_velocity_type = 1,
					do_sfx = true,
					do_vfx = true,
					do_teleport_player = false,
					do_turn_constantly = false,
					do_true_hold = false,
					enemy_soft_lock = false,
					--enchant_type = 1,
					freeze_crosshair = false, 
					hold_color = {1.0,1.0,1.0,1.0},
					is_decorative = false,
					joint_idx = 2,
					joint_name = "root",
					lifetime = -1.0,
					max_ids = 1, 
					omentime = -1.0,
					pshell_attach_type = 1,
					rot_type_idx = 1,
					scale = {1.0, 1.0, 1.0}, 
					setland_idx = 1,
					shell_id = 0,
					skyfall_cam_relative = true,
					skyfall_dest_offs = {0,0,0},
					skyfall_pos_offs = {0,100,0},
					skyfall_random_xz = false,
					soft_lock_range = 1.5,
					speed = 1.0, 
					start = 0, 
					summon_idx = 1,
					summon_action_idx = 1,
					summon_attack_rate = 1.0,
					summon_no_dissolve = false,
					summon_timer = 30.0,
					summon_scale = 1.0,
					summon_hostile = false,
					turn_idx = 1,
					turn_speed = 1.0,
					udata_idx = 1, 
					udata_name = "None",
					--shell_type = 1
					world_speed = 1.0,
				},
			}
		}
		if i > #default_sms.spells and i > default_sms.max_spells then
			new_spells[i].state_type_idx = last_spell.state_type_idx
			new_spells[i].use_modifier2 = last_spell.use_modifier2
		end
	end
	default_sms.spells = new_spells
	
	for i = 1, sms.max_configs do 
		default_sms.configs[i] = 1
		default_sms.configs_loadcontrols[i] = false
		default_sms.hotkeys["Load Config "..i] = default_sms.hotkeys["Load Config "..i] or "[Not Bound]"
	end
end

local action_names = json.load_file("SkillMaker\\ActionNames.json")
local user_paths = json.load_file("SkillMaker\\UserFiles.json")
local enemy_action_names = json.load_file("SkillMaker\\EnemyActionNames.json")
local action_tooltips = {}
local shell_descs = {}
local udata_descs = {""}
local user_paths_short = {}
local action_names_numbered = {}
local udatas_ordered = {}

 --update old skill var names etc from prev SM versions:
local function update_spell(spell_tbl, idx)
	local def_tbl = default_sms.spells[idx] or default_sms.spells[1]
	spell_tbl.state_type_idx, spell_tbl.use_modifier = spell_tbl.use_modifier and 2 or spell_tbl.state_type_idx, nil
	spell_tbl.frame_range, spell_tbl.minimum_frame = spell_tbl.minimum_frame and Vector2f.new(spell_tbl.minimum_frame, -1) or spell_tbl.frame_range, nil
	spell_tbl.frame_range_upper, spell_tbl.minimum_frame_upper = spell_tbl.minimum_frame_upper and Vector2f.new(spell_tbl.minimum_frame_upper, -1) or spell_tbl.frame_range_upper, nil
	for i, shell in ipairs(spell_tbl.shells) do 
		shell.action_idx = func.find_key(action_names, shell.action_name) or shell.action_idx --update old nodes
		shell.udata_idx = func.find_key(user_paths, shell.udata_name) or shell.udata_idx --update old user files
		if shell.skyfall_cam_relative == nil then shell.skyfall_cam_relative = false end
		if spell_tbl.require_hitbox == nil and shell.action_idx == 1 then shell.anim_speed = 1.0 end
		if type(shell.scale) == "number" then shell.scale = {shell.scale, shell.scale, shell.scale} end
		shell.pl_velocity, shell.pl_intertia = shell.pl_intertia or shell.pl_velocity, nil --fucking typo
		if not shell.turn_speed and shell.turn_idx == 4 then 
			shell.turn_idx = 2
			shell.turn_speed = 2.0
		end
		hk.recurse_def_settings(shell, def_tbl.shells[1])
	end
	return hk.recurse_def_settings(spell_tbl, def_tbl)
end

local hk = require("Hotkeys/Hotkeys")
local func = require("_SharedCore/Functions")
local ui = require("_SharedCore/Imgui")
sms = func.convert_tbl_to_numeric_keys(hk.recurse_def_settings(json.load_file("SkillMaker\\SkillMaker.json") or {}, default_sms))
setup_gamepad_specific_defaults()
setup_default_lists()
hk.recurse_def_settings(sms, default_sms)
hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)

for i, spell_tbl in pairs(sms.spells) do
	update_spell(spell_tbl, i)
end

local chr_mgr = sdk.get_managed_singleton("app.CharacterManager")
local chr_edit_mgr = sdk.get_managed_singleton("app.CharacterEditManager")
local cam_mgr = sdk.get_managed_singleton("app.CameraManager")
local em_mgr = sdk.get_managed_singleton("app.EnemyManager")
local shell_mgr = sdk.get_managed_singleton("app.ShellManager")
local gen_mgr = sdk.get_managed_singleton("app.GenerateManager")
local battle_mgr = sdk.get_managed_singleton("app.BattleManager")
local opt_mgr = sdk.get_managed_singleton("app.OptionManager")
local nav_mgr = sdk.get_managed_singleton("app.NavigationManager")
local col = ValueType.new(sdk.find_type_definition("via.Color"))
local white = ValueType.new(sdk.find_type_definition("via.Color")); white.rgba = 0xFFFFFFFF
local lookat_method = sdk.find_type_definition("via.matrix"):get_method("makeLookAtRH")
local rotate_yaw_method = sdk.find_type_definition("via.MathEx"):get_method("rotateYaw(via.vec3, System.Single)")
local transform_method = sdk.find_type_definition("via.MathEx"):get_method("transform(via.vec3, via.Quaternion)")--sdk.find_type_definition("via.MathEx"):get_method("rotateYaw(via.vec3, System.Single)")
local euler_to_quat = sdk.find_type_definition("via.quaternion"):get_method("makeEuler(via.vec3, via.math.RotationOrder)")
local set_node_method = sdk.find_type_definition("via.motion.MotionFsm2Layer"):get_method("setCurrentNode(System.String, via.behaviortree.SetNodeInfo, via.motion.SetMotionTransitionInfo)")
local keybinds
local rev_keys_enum = {}; for name, key_id in pairs(hk.keys) do rev_keys_enum[key_id] = name end; rev_keys_enum[1], rev_keys_enum[2] = "L Mouse", "R Mouse"
local interper = sdk.create_instance("via.motion.SetMotionTransitionInfo"):add_ref()
local setn = ValueType.new(sdk.find_type_definition("via.behaviortree.SetNodeInfo"))
local old_cam_dist
interper:set_InterpolationFrame(12.0)
setn:call("set_Fullname", true)
local damp_float01 = sdk.create_instance("app.DampingFloat"):add_ref()
damp_float01["<Exp>k__BackingField"] = 0.90
damp_float01._Current = 0.0
local damp_float02 = sdk.create_instance("app.DampingFloat"):add_ref()
damp_float02["<Exp>k__BackingField"] = 0.90
damp_float02._Current = 5.0

local changed = false
local was_changed = true --initial save
local needs_setup = false
local do_show_crosshair = false
local is_casting = false
local do_inhibit_all_buttons = false
local is_modifier_down = false
local is_modifier2_down = false
local ui_mod_down = false
local pressed_cancel = false
local is_battling = false
local is_paused = false
local is_sws_down = false
local real_rad_l

local last_loco_time = 0.0
local cast_prep_type = 0.0
local forced_spell
local selected_shell
local player
local camera
local cam_matrix
local pl_xform
local node_name = ""
local node_name2 = ""
local ray_result
local camera_dist
local game_time = os.clock()
local last_time = os.clock()
local skill_delta_time = 0
local delta_time = 0
local cast_shell

local presets_glob
local presets_map
local configs_glob
local configs_glob_short
local gamepad_button_guis
local udatas = {}
local temp_fns = {}
local mot_fns = {}
local beh_fns = {}
local nav_fns = {}
local turn_fns = {}
local casted_spells = {}
local spells_by_hotkeys = {}
local spells_by_hotkeys2 = {}
local spells_by_hotkeys_sws = {}
local spells_by_hotkeys_no_sws = {}
local configs_by_hotkeys = {}
local ui_fns = {}
local clipboard = {}
local active_spells = {}
local active_shells = {}
local active_summons = {}
local undo = {idx=0}
local temp = {
	last_listbox_filters = {},
}

local enums = {}
enums.chara_id_enum, enums.chara_id_names = func.generate_statics("app.CharacterID")
enums.pants_enum, enums.pants = func.generate_statics("app.PantsStyle")
enums.helms_enum, enums.helms = func.generate_statics("app.HelmStyle")
enums.mantles_enum, enums.mantles = func.generate_statics("app.MantleStyle")
enums.tops_enum, enums.tops = func.generate_statics("app.TopsStyle")
enums.skills_enum, enums.skills = func.generate_statics("app.HumanCustomSkillID")
enums.wp_enum, enums.wps = func.generate_statics("app.WeaponID")
--enums.shell_id_enum, enums.shell_id_names = func.generate_statics("app.ShellID"); table.insert(shell_id_names, 1, "Default")

local fem_tops = {
	[enums.tops_enum.Tops_034] = true,
	[enums.tops_enum.Tops_310] = true,
	[enums.tops_enum.Tops_312] = true,
	[enums.tops_enum.Tops_314] = true,
	[enums.tops_enum.Tops_315] = true,
}

local fem_pants = {
	[enums.pants_enum.Pants_238] = true,
	[enums.pants_enum.Pants_023] = true,
	[enums.pants_enum.Pants_036] = true,
	[enums.pants_enum.Pants_275] = true,
	[enums.pants_enum.Pants_009] = true,
}

local next, ipairs, pairs = next, ipairs, pairs

local function set_wc(name, tbl, val, parent_tbl)
	was_changed = was_changed or changed
	if val and imgui.begin_popup_context_item(name) then  
		if imgui.menu_item("Reset Value") then
			if tbl and val ~= nil then
				tbl[name] = val
			else
				sms[name] = default_sms[name]
			end
			changed, was_changed = true, true
		end
		imgui.end_popup() 
	end
	if changed and parent_tbl and ui_mod_down then
		local this_idx = func.find_index(parent_tbl, tbl)
		for i = this_idx+1, #parent_tbl do
			if name == "enabled" or parent_tbl[i].enabled then 
				parent_tbl[i][name] = tbl[name]
			end
		end
	end
end

local function tooltip(text)
	if imgui.is_item_hovered() then
		imgui.set_tooltip(text)
	end
end

local bad_shells = {
	["AppSystem/ch/ch227/userdata/ch227shellparamdata.user"] = {[0]=true},
	["AppSystem/ch/ch225/userdata/ch225shellparamdata.user"] = {[0]=true},
	["AppSystem/ch/ch230/userdata/shell/ch230shellparamdata_job09.user"] = {[3]=true, [9]=true, [10]=1, [11]=1},
	["AppSystem/shell/userdata/humanshellparamdata_job09.user"] = {[3]=true, [9]=true, [10]=1, [11]=1},
}

local state_names = {"Always", "Standing", "Airborne", "Falling", "Damaged", "Job", "Climbing", "Sprinting", "Aiming"}

local state_keywords = {
	Always = {""},
	Standing = {"NormalLocomotion", "Strafe"},
	Airborne = {"Jump", "Air", "Levitat"},
	Falling = {"Fall"},
	Job = {"Job%d%d"},
	Damaged = {"Damage"},
	Climbing = {"Climb"},
	Sprinting = {"Dash"},
	Aiming = {"Aim"},
}

local joint_list = {
	"[Input Joint Name]",
	"root",
	"Hip",
	"Spine_1",
	"Spine_2",
	"Neck_0",
	"Neck_1",
	"Head_0",
	"Spine_1",
	"R_Arm_Upper",
	"R_Arm_Lower",
	"R_Hand_Palm",
	"R_Hand_IndexF_3",
	"R_PropA",
	"R_PropB",
	"L_Arm_Upper",
	"L_Arm_Lower",
	"L_Hand_Palm",
	"L_Hand_IndexF_3",
	"L_PropA",
	"L_PropB",
	"R_Leg_Upper",
	"R_Leg_Lower",
	"R_Leg_Foot",
	"R_Leg_Toes",
	"L_Leg_Upper",
	"L_Leg_Lower",
	"L_Leg_Foot",
	"L_Leg_Toes",
}

local weapon_types = {"Any", "Unarmed", "Sword", "Shield", "Two-Hander", "Dagger", "Bow", "Magick Bow", "Staff", "Archistaff", "Duospear", "Censer", "Melee Weapons", "Bows", "Staves"}

local weapon_types_map = {
	wp00 = "Sword",
	wp01 = "Shield",
	wp02 = "Two-Hander",
	wp03 = "Dagger",
	wp04 = "Bow",
	wp05 = "Magick Bow",
	wp06 = "Quiver",
	wp07 = "Staff",
	wp08 = "Archistaff",
	wp09 = "Duospear",
	wp10 = "Censer",
	wp11 = "Arrow",
}

local enemies_map = {
    ["AppSystem/ch/ch220/prefab/ch220000_00.pfb"] = "Goblin",
    ["AppSystem/ch/ch220/prefab/ch220001_00.pfb"] = "Hobgoblin",
    ["AppSystem/ch/ch220/prefab/ch220001_20.pfb"] = "Hobgoblin",
    ["AppSystem/ch/ch220/prefab/ch220002_00.pfb"] = "Chopper",
    ["AppSystem/ch/ch220/prefab/ch220003_00.pfb"] = "Knacker",
    ["AppSystem/ch/ch221/prefab/ch221000_00.pfb"] = "Saurian",
    ["AppSystem/ch/ch221/prefab/ch221001_00.pfb"] = "Asp",
    ["AppSystem/ch/ch221/prefab/ch221002_00.pfb"] = "Rattler",
    ["AppSystem/ch/ch221/prefab/ch221002_20.pfb"] = "Rattler",
    ["AppSystem/ch/ch221/prefab/ch221003_00.pfb"] = "Magma Scale",
    ["AppSystem/ch/ch221/prefab/ch221004_00.pfb"] = "Serpent",
    ["AppSystem/ch/ch222/prefab/ch222000_00.pfb"] = "Harpy",
    ["AppSystem/ch/ch222/prefab/ch222001_00.pfb"] = "Venin Harpy",
    ["AppSystem/ch/ch222/prefab/ch222002_00.pfb"] = "Gore Harpy",
    ["AppSystem/ch/ch222/prefab/ch222003_00.pfb"] = "Succubus",
    ["AppSystem/ch/ch222/prefab/ch222003_20.pfb"] = "Succubus",
    ["AppSystem/ch/ch223/prefab/ch223000_00.pfb"] = "Wolf",
    ["AppSystem/ch/ch223/prefab/ch223001_00.pfb"] = "Redwolf",
    ["AppSystem/ch/ch223/prefab/ch223001_01.pfb"] = "Redwolf",
    ["AppSystem/ch/ch224/prefab/ch224000_00.pfb"] = "Slime",
    ["AppSystem/ch/ch224/prefab/ch224001_00.pfb"] = "Ooze",
    ["AppSystem/ch/ch224/prefab/ch224002_00.pfb"] = "Sludge",
    ["AppSystem/ch/ch225/prefab/ch225000_00.pfb"] = "Phantom",
    ["AppSystem/ch/ch225/prefab/ch225001_00.pfb"] = "Phantasm",
    ["AppSystem/ch/ch225/prefab/ch225002_00.pfb"] = "Specter",
    ["AppSystem/ch/ch227/prefab/ch227000_00.pfb"] = "Lich",
    ["AppSystem/ch/ch227/prefab/ch227001_00.pfb"] = "Wight",
    ["AppSystem/ch/ch228/prefab/ch228000_00.pfb"] = "Undead",
    ["AppSystem/ch/ch228/prefab/ch228002_00.pfb"] = "Stout Undead",
    ["AppSystem/ch/ch229/prefab/ch229000_00.pfb"] = "Dullahan",
    ["AppSystem/ch/ch250/prefab/ch250000_00.pfb"] = "Cyclops",
    ["AppSystem/ch/ch250/prefab/ch250000_01.pfb"] = "Cyclops",
    ["AppSystem/ch/ch250/prefab/ch250000_10.pfb"] = "Cyclops",
    ["AppSystem/ch/ch250/prefab/ch250000_11.pfb"] = "Cyclops",
    ["AppSystem/ch/ch250/prefab/ch250000_12.pfb"] = "Cyclops",
    ["AppSystem/ch/ch250/prefab/ch250000_20.pfb"] = "Cyclops",
    ["AppSystem/ch/ch250/prefab/ch250000_21.pfb"] = "Cyclops",
    ["AppSystem/ch/ch250/prefab/ch250000_22.pfb"] = "Cyclops",
    ["AppSystem/ch/ch251/prefab/ch251000_00.pfb"] = "Ogre",
    ["AppSystem/ch/ch251/prefab/ch251001_00.pfb"] = "Grim Ogre",
    ["AppSystem/ch/ch252/prefab/ch252000_00.pfb"] = "Golem",
    ["AppSystem/ch/ch252/prefab/ch252000_01.pfb"] = "Golem",
    ["AppSystem/ch/ch252/prefab/ch252000_02.pfb"] = "Golem",
    ["AppSystem/ch/ch252/prefab/ch252000_03.pfb"] = "Golem",
    ["AppSystem/ch/ch253/prefab/ch253000_00.pfb"] = "Griffin",
    ["AppSystem/ch/ch253/prefab/ch253001_00.pfb"] = "Sphinx",
    ["AppSystem/ch/ch253/prefab/ch253010_00.pfb"] = "Vermund Purgener",
    ["AppSystem/ch/ch253/prefab/ch253011_00.pfb"] = "Island Encampment Purgener",
    ["AppSystem/ch/ch254/prefab/ch254000_00.pfb"] = "Chimera",
    ["AppSystem/ch/ch254/prefab/ch254001_00.pfb"] = "Gorechimera",
    ["AppSystem/ch/ch255/prefab/ch255000_00.pfb"] = "Medusa",
    ["AppSystem/ch/ch255/prefab/ch255000_01.pfb"] = "Medusa",
    ["AppSystem/ch/ch255/prefab/ch255000_90.pfb"] = "Medusa",
    ["AppSystem/ch/ch255/prefab/ch255010_00.pfb"] = "Sacred Arbor Purgener",
    ["AppSystem/ch/ch255/prefab/ch255011_00.pfb"] = "Volcanic Island Purgener",
    ["AppSystem/ch/ch256/prefab/ch256000_00.pfb"] = "Minotaur",
    ["AppSystem/ch/ch256/prefab/ch256001_00.pfb"] = "Goreminotaur",
    ["AppSystem/ch/ch257/prefab/ch257000_00.pfb"] = "Drake",
    ["AppSystem/ch/ch257/prefab/ch257001_00.pfb"] = "Lesser Dragon",
    ["AppSystem/ch/ch258/prefab/ch258000_00.pfb"] = "Dragon",
    ["AppSystem/ch/ch258/prefab/ch258000_10.pfb"] = "Dragon",
    ["AppSystem/ch/ch258/prefab/ch258000_20.pfb"] = "Dragon",
    ["AppSystem/ch/ch258/prefab/ch258000_30.pfb"] = "Dragon",
    ["AppSystem/ch/ch258/prefab/ch258001_00.pfb"] = "Nex",
    ["AppSystem/ch/ch259/prefab/ch259000_00.pfb"] = "Talos",
    ["AppSystem/ch/ch260/prefab/ch260000_00.pfb"] = "Garm",
    ["AppSystem/ch/ch260/prefab/ch260001_00.pfb"] = "Warg",
	["AppSystem/ch/ch226/prefab/ch226000_00.pfb"] = "Skeleton", --Skeletons
	["AppSystem/ch/ch226/prefab/ch226000_01.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226001_01.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226001_03.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226001_05.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226001_06.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226002_01.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226002_03.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226002_05.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226002_06.pfb"] = "Skeleton",
	["AppSystem/ch/ch226/prefab/ch226003_00.pfb"] = "Skeleton Lord",
	["AppSystem/ch/ch230/prefab/ch230000_01.pfb"] = "Bandit", --Bandits
	["AppSystem/ch/ch230/prefab/ch230000_02.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230000_03.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230000_04.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230001_01.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230001_02.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230001_03.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230001_04.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230001_05.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230001_06.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230002_01.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230002_02.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230002_03.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230002_04.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230002_05.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230002_06.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230012_02.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230012_04.pfb"] = "Bandit",
	["AppSystem/ch/ch230/prefab/ch230100_04.pfb"] = "Bandit", 
}

_G.sm_summons = {} --shared with Monster Infighting
local enemies_list = {"None"}
for path, name in func.orderedPairs(enemies_map) do
	table.insert(enemies_list, name .. " - " .. path)
end

local function setup_presets_glob()
	presets_map = {}
	presets_glob = fs.glob("SkillMaker\\\\Skills\\\\.*json")
	local presets_len = table.concat(presets_glob):len()
	--if sms.presets_len ~= presets_len then
		was_changed = true
		sms.presets_len = presets_len
		sms.preset_descs = {}
		for i, path in ipairs(presets_glob) do 
			local json_data = json.load_file(path)
			sms.preset_descs[i+1] = json_data and json_data.desc or "ERROR: Failed to read json file"
		end
	--end
	for i, path in ipairs(presets_glob) do
		presets_glob[i] = path:match("SkillMaker\\Skills\\(.+).json") 
		presets_map[presets_glob[i] ] = i
	end
	for i, imgui_spell in pairs(imgui_spells) do
		imgui_spell.preset_text = sms.last_sel_spells[i] or imgui_spell.preset_text
	end
	table.insert(presets_glob, 1, "[Reset Skill Slot]")
end
setup_presets_glob()

if true then
	enemy_action_names.Bandit = hk.merge_tables({}, action_names)
	for name, list in pairs(enemy_action_names) do
		table.insert(list, 1, "None")
	end

	for i, udata_path in ipairs(user_paths) do
		user_paths_short[i] = i .. ".	" .. (udata_path:match(".+%/(.+)") or udata_path)
		udatas[udata_path] = sdk.create_userdata("app.ShellParamData", udata_path)
	end

	local first_upperbody = func.find_index(action_names, "DrawWeapon")
	for i, action_name in ipairs(action_names) do
		action_names_numbered[i] = i .. ".	" .. action_name
		action_tooltips[i] = i >= first_upperbody and "Upper Body Action" or ""
	end

	for i, shell_desc in ipairs(json.load_file("SkillMaker\\ShellDescs.json") or {}) do
		if not shell_descs[shell_desc.File] then
			table.insert(udata_descs, shell_desc["File Description"])
			shell_descs[shell_desc.File] = {titles={}, descs={}}
		end
		local key = tonumber(shell_desc["Shell ID"]) + 1
		shell_descs[shell_desc.File].titles[key] = shell_desc["Shell ID"] .. ".	" .. shell_desc.Title
		shell_descs[shell_desc.File].descs[key]  = shell_desc.Description
	end
end

local function listbox_ctx_menu(imgui_data, key, key2)
	if imgui.begin_popup_context_item(key.."_listbox"..(key2 or "")) then  
		if imgui.menu_item(imgui_data[key.."_show_listbox"] and "Hide Listbox" or "Show Listbox") then
			imgui_data[key.."_show_listbox"] = not imgui_data[key.."_show_listbox"]
		end
		imgui.end_popup() 
	end
end

local function expand_as_listbox(imgui_data, key, shell, idx_key, disp_name, list, short_list, desc_list, ttip, parent_tbl, skip_wc)
	short_list = short_list or list
	imgui_data[key.."_list_idx"] = imgui_data[key.."_list_idx"] or shell[idx_key]
	ttip = ttip or ""
	
	changed, shell[idx_key]  = imgui.combo(disp_name, shell[idx_key], short_list)
	listbox_ctx_menu(imgui_data, key, 0)
	tooltip(ttip)
	
	--[[if key == "preset" and ui.FilePicker and not imgui.same_line() and imgui.button("Pick File") then
		ui.FilePicker.instance = ui.FilePicker:new({filters={"json", currentDir="SkillMaker\\Skills\\", doReset=true}})
	end
	
	if ui.FilePicker.instance then 
		local path = ui.FilePicker.instance:displayPickerWindow()
		if path then 
			re.msg(path)
		end
		imgui.same_line()
		imgui.text(ui.FilePicker.instance.lastPickedItem)
	end]]
	
	if imgui_data[key.."_show_listbox"] then
		imgui.text("		       "); imgui.same_line()
		changed, imgui_data[key.."_filter"] = imgui.input_text(disp_name .. " Filter", imgui_data[key.."_filter"] or temp.last_listbox_filters[key])
		temp.last_listbox_filters[key] = imgui_data[key.."_filter"]
		tooltip("Filter by name\nRight click to show/hide list box")
		if changed then imgui_data[key.."_list"] = nil end
		listbox_ctx_menu(imgui_data, key, 1)
		
		if imgui_data[key.."_filter"] ~= "" and not imgui_data[key.."_list"] then
			local lower_filter = imgui_data[key.."_filter"]:lower()
			imgui_data[key.."_map"] = {}
			imgui_data[key.."_list"] = {}
			for j, name in ipairs(list) do
				local desc = desc_list and desc_list[j] and desc_list[j]:lower()
				if name:lower():find(lower_filter) or (desc and desc:find(lower_filter)) then
					imgui_data[key.."_map"][short_list[j] ] = j
					table.insert(imgui_data[key.."_list"], short_list[j])
				end
			end
			imgui_data[key.."_list_idx"] = func.find_key(imgui_data[key.."_list"], short_list[imgui_data[key.."_list_idx"] ])
		end
		
		imgui.text("		       "); imgui.same_line()
		if imgui.begin_list_box(disp_name, #list) then
			for j, name in ipairs(imgui_data[key.."_list"] or short_list) do
				local map_idx = imgui_data[key.."_list"] and imgui_data[key.."_map"][name]
				local desc = desc_list and desc_list[map_idx or j]
				local length = desc and desc:len()
				desc = desc and length > 3 and desc:sub(1, (desc:find("\n") or (length > 30 and 38) or 0) - 1)..(length > 30 and "..." or "") or desc
				if imgui.menu_item(name, desc, (imgui_data[key.."_list_idx"]==j), true) then
					imgui_data[key.."_list_idx"] = j
					shell[idx_key] = map_idx or j
					changed = true
				end
				tooltip(desc_list and desc_list[map_idx or j] ~= "" and desc_list[map_idx or j] or ttip)
			end
			imgui.end_list_box()
		end
		listbox_ctx_menu(imgui_data, key)
	end
	if not skip_wc then 
		set_wc(idx_key, shell, nil, parent_tbl)
	end
	
	return changed
end

local function check_config_name()
	if sms.last_config and next(sms.last_config.last_sel_spells or {}) then
		sms.last_config.has_config_name = not not sms.last_config.name
		for idx, spell_name in pairs(sms.last_config.last_sel_spells) do
			if sms.last_sel_spells[idx] ~= spell_name then sms.last_config.has_config_name = false; break end
		end
	end
end

local function load_spell(json_data, spell_idx, spell_name, do_load_controls)
	if not next(json_data) then return end
	local og_spell_tbl = sms.spells[spell_idx]
	if do_load_controls then
		if json_data.hotkey then  sms.hotkeys["Use Skill "..spell_idx], hk.hotkeys["Use Skill "..spell_idx] = json_data.hotkey, json_data.hotkey  end
	else
		json_data.use_modifier2, json_data.state_type_idx, json_data.use_modifier = og_spell_tbl.use_modifier2, og_spell_tbl.state_type_idx, nil
	end
	local spell_tbl = update_spell(json_data, spell_idx) 
	spell_tbl.unedited = false
	sms.spells[spell_idx] = spell_tbl
	imgui_spells[spell_idx].preset_idx = hk.find_index(presets_glob, spell_name or sms.last_sel_spells[spell_idx]) or 1
	imgui_spells[spell_idx].precached_json = json_data
	sms.last_sel_spells[spell_idx] = presets_glob[imgui_spells[spell_idx].preset_idx]
	imgui_spells[spell_idx].preset_text = sms.last_sel_spells[spell_idx] 
end

local function load_config(config_path, idx)
	sms.last_config = func.convert_tbl_to_numeric_keys(json.load_file(config_path))
	sms.last_config.name = config_path:match(".+\\(.+)%.json")
	local highest_idx = 0; 
	for i, spell_tbl in pairs(sms.last_config.last_sel_spells or {}) do 
		if i > highest_idx then highest_idx = i end 
	end
	if highest_idx > sms.max_spells then
		sms.max_spells = highest_idx
		setup_default_lists()
		hk.recurse_def_settings(sms, default_sms)
		hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
	end
	if sms.do_clear_spells_on_cfg_load then
		for i, spell_tbl in pairs(sms.spells) do
			sms.last_sel_spells[i] = nil
			local prev_ctrls = {use_modifier2=spell_tbl.use_modifier2, spell_tbl.state_type_idx}
			sms.spells[i] = hk.recurse_def_settings({}, default_sms.spells[1])
			func.merge_tables(sms.spells[i], prev_ctrls)
		end
	end
	for i, spell_name in pairs(sms.last_config.last_sel_spells or {}) do
		local json_data = json.load_file("SkillMaker\\Skills\\"..spell_name..".json")
		if json_data then
			sms.last_sel_spells[i] = spell_name
			load_spell(json_data, i, spell_name)
			if sms.configs_loadcontrols[idx] then
				src_tbl = sms.last_config.controls and sms.last_config.controls[i] or default_sms.spells[i] or default_sms.spells[1]
				sms.hotkeys["Use Skill "..i] = src_tbl.hotkey or default_sms.hotkeys["Use Skill "..i] or sms.hotkeys["Use Skill "..i]
				sms.spells[i].state_type_idx, sms.spells[i].use_modifier2 =  src_tbl.state_type_idx, src_tbl.use_modifier2
			end
		end
	end
	hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
	check_config_name()
end

function split(s, delimiter)
	result = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end

local function get_cam_dist_info()
	local cam_ctrl = cam_mgr._MainCameraControllers[0]._CurrentCameraController
	local is_narrow = not not cam_ctrl["<CurrentLevelInfo>k__BackingField"]
	local pl_cam_settings = cam_ctrl[is_narrow and "<CurrentLevelInfo>k__BackingField" or is_aiming and "_AimSetting" or "_PlayerCameraSettings"]
	local dist_name = (is_narrow or is_aiming) and "_Distance" or "_CameraDistance"
	return pl_cam_settings, dist_name
end

local function cleanup()
	game_time = 0.0
	temp_fns.cleanup_fn = function()
		temp_fns.cleanup_fn = nil
		casted_spells = {}
		for i, shell in pairs(shell_mgr.ShellList._items) do
			if shell then shell:get_GameObject():destroy(shell:get_GameObject()) end
		end
		for ch2, state in pairs(sm_summons) do
			ch2:get_GameObject():destroy(ch2:get_GameObject())
		end
		sm_summons = {}
	end
end

local function fix_player()
	temp_fns.fix_player_fsm = function()
		temp_fns.fix_player_fsm = nil
		mfsm2:restartTree()
		player["<ActionManager>k__BackingField"]:requestActionCore(0, "DmgShrinkAirWallCrush", 0)
		player["<StatusConditionCtrl>k__BackingField"]:reqStatusConditionCureAll()
		player["<Hit>k__BackingField"]:recoverHp(100000.0, false, 0, false)
		player:get_StaminaManager():recoverAll()
		cam_mgr._MainCameraControllers[0]["<BaseOffset>k__BackingField"] = Vector3f.new(0, 1.501, -0.043)
		local pl_cam_settings, dist_name = get_cam_dist_info()
		if pl_cam_settings then pl_cam_settings:call(".ctor") end
	end
end

local function change_material_float4(mesh, color, param_name, do_children, search_term)
	local mat_count = mesh:get_MaterialNum()
	for m=0, mesh:get_MaterialNum()-1 do
		if not search_term or mesh:getMaterialName(m):find(search_term) then
			for i=0,  mesh:getMaterialVariableNum(m)-1 do
				if mesh:getMaterialVariableName(m, i) == param_name then
					mesh:setMaterialFloat4(m, i, color)
					break
				end
			end
		end
	end
	if do_children then
		for c, child in pairs(func.get_children(mesh:get_GameObject():get_Transform()) or {}) do
			local cmesh = func.getC(child:get_GameObject(), "via.render.Mesh")
			if cmesh then
				change_material_float4(cmesh, color, search_term, true)
			end
		end
	end
end

local function add_dynamic_motionbank(motion, motlist_path, new_bank_id)
	local new_dbank
	local bank_count = motion:getDynamicMotionBankCount()
	local insert_idx = bank_count
	for i=0, bank_count-1 do
		local dbank = motion:getDynamicMotionBank(i)
		if dbank and (dbank:get_BankID() == new_bank_id) or (dbank:get_MotionList() and dbank:get_MotionList():ToString():lower():find(motlist_path:lower())) then
			new_dbank, insert_idx = dbank, i
			break
		end
	end
	if not new_dbank then
		motion:setDynamicMotionBankCount(bank_count+1)
	end
	new_dbank = new_dbank or sdk.create_instance("via.motion.DynamicMotionBank"):add_ref()
	new_dbank:set_MotionList(func.create_resource("via.motion.MotionListResource", motlist_path))
	new_dbank:set_OverwriteBankID(true)
	new_dbank:set_BankID(new_bank_id)
	motion:setDynamicMotionBank(insert_idx, new_dbank)
	
	return new_dbank
end

local function disp_imgui_element(key, value)
	if EMV then 
		EMV.read_imgui_element(value)
	elseif type(value) == "table" then
		if imgui.tree_node(key) then
			for k, v in pairs(value) do
				disp_imgui_element(k, v)
			end
			imgui.tree_pop()
		end
	elseif (type(value) == "userdata" or type(value) == "number") then
		if sdk.is_managed_object(value) and imgui.tree_node(key) then
			object_explorer:handle_address(value)
			imgui.tree_pop()
		end
	else
		imgui.text(tostring(key) .. "  :  " .. tostring(value))
	end
end

local imgui2 --Used to prevent imgui.drag_float from changing values as you're still typing them
imgui2 = {
	data = {},
	drag_float = function(key, label, value, increment, range_begin, range_end, format)
		local ch
		ch, imgui2.data[key] = imgui.drag_float(label, imgui2.data[key] or value, increment, range_begin, range_end, format)
		if not imgui.is_item_active() and imgui2.data[key] ~= value then  
			return true, imgui2.data[key]
		end
		return false, value
	end,
}

local function display_mod_imgui(is_window)
	imgui.begin_rect()
	
	if not is_window then
		changed, sms.use_window = imgui.checkbox("Use Window", sms.use_window); set_wc("use_window")
		tooltip("Display this menu in its own window")
	end
	
	if imgui.button("Reset to Defaults") then
		was_changed = true
		setup_gamepad_specific_defaults()
		setup_default_lists()
		sms = hk.recurse_def_settings({}, default_sms)
		hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
		hk.reset_from_defaults_tbl(default_sms.hotkeys)
	end
	tooltip("Set all mod settings and skills back to their defaults")
	
	imgui.same_line()
	if imgui.button("Rescan") then
		presets_glob = nil
		configs_glob = nil
	end
	tooltip("Reloads the list of skill and skillset json files from [DD2 Game Directory]\\reframework\\data\\SkillMaker\\")
	
	if player then 
		imgui.same_line()
		if imgui.button("Reset Player State") or hk.check_hotkey("Reset Player State") then
			fix_player()
		end
		tooltip("Return the player to the normal walking state")
		
		imgui.same_line() 
		if imgui.button("Clean Up") then
			cleanup()
		end
		tooltip("Remove all spawned shells and summons from the scene")
	end
	imgui.same_line()
	imgui.text_colored("Mouse here for tips", 0xFFAAFFFF)
	tooltip("- Right click on any option to reset it\n- Ctrl + click on any slider to type-in\n- Press "..sms.hotkeys["UI Modifier"].." + "..sms.hotkeys["Undo"].." to undo\n- Press "..sms.hotkeys["UI Modifier"].." + "..sms.hotkeys["Redo"].." to redo"
	.."\n- Hold ["..sms.hotkeys["UI Modifier"].."] while changing a setting to change that setting for all enabled nodes below the node being changed\n- If a problem happens with your controls, try resetting them in the game's Options menu")
	
	if imgui.tree_node("Mod Options") then
		imgui.begin_rect()
		changed, sms.shell_lifetime_limit = imgui.drag_float("Shell Lifetime Limit", sms.shell_lifetime_limit, 0.1, 0, 10000, "%.2f seconds"); set_wc("shell_lifetime_limit")
		tooltip("The maximum amount of time a shell can exist before being destroyed by the script")
		
		changed, sms.maximum_range = imgui.drag_float("Maximum Skill Range", sms.maximum_range, 0.1, 0, 10000, "%.2f meters"); set_wc("maximum_range")
		tooltip("Skills cast further than this distance will do no damage")
		
		changed, sms.crosshair_type = imgui.combo("Crosshair", sms.crosshair_type, {"None", "Show", "Show with Modifier"}); set_wc("crosshair_type")
		tooltip("Display a crosshair where the skill would appear")
		
		changed, sms.move_cam_for_crosshair = imgui.combo("Move Cam for Crosshair", sms.move_cam_for_crosshair, {"Don't Move Cam", "Move Cam for Modifier", "Move Cam for Skills", "Move Cam for Skills and Modifier"}); set_wc("move_cam_for_crosshair")
		tooltip("Moves the camera to the right when executing a skill or using the modifier to ensure you can see the crosshair")
		
		local was_was_changed = was_changed
		changed, sms.max_spells = imgui.drag_int("Max Skills", sms.max_spells, 1, 0, 9999); set_wc("max_spells")
		tooltip("The maximum number of Skills available in the mod\nNewly added Skill slots will take controls settings from the previous slot")
		
		changed, sms.max_configs = imgui.drag_int("Max Skillsets", sms.max_configs, 1, 0, 9999); set_wc("max_configs")
		tooltip("The maximum number of Skillsets available in the mod")
		if was_changed and not was_was_changed then 
			setup_default_lists()
			hk.recurse_def_settings(sms, default_sms)
			hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
		end
		
		changed, sms.modifier_inhibits_buttons = imgui.checkbox("Modifier Inhibits Buttons", sms.modifier_inhibits_buttons); set_wc("modifier_inhibits_buttons")
		tooltip("Holding down the Modifier hotkey will prevent the face buttons from being pressed")
		
		changed, sms.do_shift_sheathe = imgui.checkbox("L1 + L2 to Sheathe/Unsheathe", sms.do_shift_sheathe); set_wc("do_shift_sheathe")
		tooltip("Changes it so that you have to hold Left Bumper before pressing Left Trigger to sheathe / unsheathe your weapon")
		
		changed, sms.do_swap_lshoulders = imgui.checkbox("L1 or L2 to Switch Weapon Skill, L1 to Spell Cancel", sms.do_swap_lshoulders); set_wc("do_swap_lshoulders")
		tooltip("Changes it so that both L1 and L2 function as 'Switch Weapon Skill' and can be used to hold spells while casting. 'Cancel Spell' is remapped to L1")
		
		if sms.modifier_inhibits_buttons then --and sms.do_shift_sheathe and sms.hotkeys["Modifier / Inhibit"] == "LT (L2)" then
			changed, sms.ingame_ui_buttons = imgui.checkbox("Display In-Game GUI", sms.ingame_ui_buttons); set_wc("ingame_ui_buttons")
			tooltip("Show custom skill names for the face and shoulder buttons while holding down L2")
		end
		
		changed, sms.do_force_cam_dist = imgui.checkbox("Force Reset Camera Distance", sms.do_force_cam_dist); set_wc("do_force_cam_dist")
		tooltip("The camera distance will always reset to a default value between skills")
		
		changed = hk.hotkey_setter("Modifier / Inhibit", nil, nil, "Hold this button to control other skill hotkeys and prepare-spellcasting animations.\nCan optionally disable the face buttons while held down"); set_wc()
		changed = hk.hotkey_setter("SM Modifier2", nil, "2nd Modifier", "Hold this button along with 'Modifier / Inhibit' to trigger even more skills"); set_wc()
		changed = hk.hotkey_setter("UI Modifier", nil, nil, "Hold this button to change functionalities in the UI"); set_wc()
		changed = hk.hotkey_setter("Undo", "UI Modifier", nil, "Go back one state"); set_wc()
		changed = hk.hotkey_setter("Redo", "UI Modifier", nil, "Go forward one state"); set_wc()
		changed = hk.hotkey_setter("Reset Player State", nil, nil, "Return the player to the normal walking state"); set_wc()
		changed = hk.hotkey_setter("SM Clean Up", nil, nil, "Remove all spawned shells and summons from the scene"); set_wc()
		changed = hk.hotkey_setter("Prev Sel Shell", nil, nil, "Skip to the previous Shell ID in the last selected node"); set_wc()
		changed = hk.hotkey_setter("Next Sel Shell", nil, nil, "Skip to the next Shell ID in the last selected node"); set_wc()
		
		imgui.end_rect(1)
		imgui.tree_pop()
	end
	imgui.spacing()
	
	if imgui.tree_node("Skillsets") then
		imgui.begin_rect()
		
		changed, sms.do_clear_spells_on_cfg_load = imgui.checkbox("Clear Skills on Load", sms.do_clear_spells_on_cfg_load)
		tooltip("If checked, all skills will be reset before loading any Skillset")
		
		if imgui.button("Save") then
			local controls = {}
			local used_spells = {}
			for i, spell_tbl in ipairs(sms.spells) do
				used_spells[i] = spell_tbl.enabled and sms.last_sel_spells[i] or nil
				controls[i] = used_spells[i] and {state_type_idx=spell_tbl.state_type_idx, hotkey=sms.hotkeys["Use Skill "..i], use_modifier2=spell_tbl.use_modifier2}
			end
			json.dump_file("SkillMaker\\Skillsets\\"..config_txt..".json", {last_sel_spells=used_spells, controls=controls})
			configs_glob = nil
		end
		tooltip("Save the current skill configuration as a Skillset to [DD2 Game Folder]\\reframework\\data\\SkillMaker\\Skillsets\\")
		imgui.same_line()
		
		imgui.set_next_item_width(imgui.calc_item_width() * 0.8)
		changed, config_txt = imgui.input_text(" ", config_txt)
		tooltip("Type the name of the new Skillset in which to save the current list of skills")
		
		imgui.same_line()
		changed, sms.load_cfgs_w_cfg_modifier = imgui.checkbox("Skillset Modifier", sms.load_cfgs_w_cfg_modifier); set_wc("load_cfgs_w_cfg_modifier")
		tooltip("Require holding the Skillset Modifier down when selecting Skillsets via hotkey")
		
		imgui.same_line()
		changed, sms.load_cfgs_w_modifier = imgui.checkbox("Modifier", sms.load_cfgs_w_modifier); set_wc("load_cfgs_w_modifier")
		tooltip("Require holding the Modifier down when selecting Skillsets via hotkey")
		
		for i=1, sms.max_configs do 
			imgui.push_id(124235+i)
			local clicked_load = imgui.button("Load") and #configs_glob > 0; imgui.same_line()
			tooltip("Load a Skillset")
			
			imgui.push_id(224235+i)
			changed, sms.configs_loadcontrols[i] = imgui.checkbox("", sms.configs_loadcontrols[i]); imgui.same_line()
			tooltip("Load controls from this Skillset")
			imgui.pop_id()
			
			imgui.set_next_item_width(imgui.calc_item_width() * 0.75)
			changed, sms.configs[i] = imgui.combo("", sms.configs[i], configs_glob_short); set_wc(); imgui.same_line()
			tooltip("The name of the Skillset configuration file to load. A list of skills from it will replace the current skills")
			
			if sms.load_cfgs_w_cfg_modifier then
				changed = hk.hotkey_setter("SM Config Modifier", nil, ""); set_wc() 
				imgui.same_line(); imgui.text("+"); imgui.same_line()
			end
			changed = hk.hotkey_setter("Load Config "..i, sms.load_cfgs_w_modifier and "Modifier / Inhibit", ""); set_wc()
			
			if clicked_load and sms.configs[i] > 1 then
				load_config(configs_glob[sms.configs[i] ], i)
				config_txt = configs_glob_short[sms.configs[i] ]
				was_changed = true
			end
			imgui.pop_id()
		end
		
		imgui.end_rect(1)
		imgui.tree_pop()
	end
	
	local mot_info, mot_info2 = player and player.FullBodyLayer:get_HighestWeightMotionNode(), player and player.UpperBodyLayer:get_HighestWeightMotionNode()
	local anim_name, anim_name2 = mot_info and mot_info:get_MotionName(), mot_info2 and mot_info2:get_MotionName()
	local bank, bank2 = mot_info and mot_info:get_MotionBankID(), mot_info2 and mot_info2:get_MotionBankID()
	local mot_id, mot_id2 = mot_info and mot_info:get_MotionID(), mot_info2 and mot_info2:get_MotionID()
	local frame, frame2 = player and player.FullBodyLayer:get_Frame(), player and player.UpperBodyLayer:get_Frame()
	
	if is_window then imgui.begin_child_window(nil, false, 0) end
	imgui.text("")
	imgui.spacing()
	
	for i, spell_tbl in ipairs(sms.spells) do
		local imgui_data = imgui_spells[i]
		local running_spell_tbl = casted_spells[i]
		imgui_data.precached_json = imgui_data.precached_json or (imgui_data.preset_idx > 1 and json.load_file("SkillMaker\\Skills\\"..presets_glob[imgui_data.preset_idx]..".json")) or {}
		if imgui_data.nodes_expanded == nil then imgui_data.nodes_expanded = #spell_tbl.shells < 4 end
		local glob_idx = presets_map[sms.last_sel_spells[i] ]
		
		--local opened = ui.tree_node_colored("Skill "..i, "Skill "..i, sms.last_sel_spells[i] or "", running_spell_tbl and 0xFFAAFFFF or (spell_tbl.enabled and 0xFFE0853D or 0xFF999999))
		local opened = imgui.tree_node_str_id("Skill"..i, ""); imgui.same_line(); imgui.text_colored("Skill "..i, running_spell_tbl and 0xFFAAFFFF or (spell_tbl.enabled and 0xFFFFFFFF or 0xFF999999))
		imgui.same_line(); imgui.text_colored(sms.last_sel_spells[i] or "", running_spell_tbl and 0xFFAAFFFF or 0xFFE0853D)
		local spell_desc = glob_idx and sms.preset_descs[glob_idx+1] and sms.preset_descs[glob_idx+1] 
		if spell_desc and spell_desc ~= "" then tooltip(spell_desc) end
		--spell_tbl.unedited = spell_tbl.unedited == false
		if spell_tbl.unedited then spell_tbl.enabled = false end
		
		if spell_tbl.use_modifier2 and not imgui.same_line() then
			imgui.push_id(i + 34543674)
			changed = hk.hotkey_setter("SM Modifier2", nil, "", nil); set_wc()
			imgui.pop_id()
			imgui.same_line()
			imgui.text("+")
		end
		
		if spell_tbl.state_type_idx == 3 and not imgui.same_line() then
			imgui.push_id(i + 34543675)
			imgui.button("Switch Weapon Skill")
			imgui.pop_id()
			imgui.same_line()
			imgui.text("+")
		end
		
		imgui.same_line()
		changed = hk.hotkey_setter("Use Skill "..i, spell_tbl.state_type_idx == 2 and "Modifier / Inhibit", "", "Creates a shell for skill "..i); set_wc()
		
		if opened then
			local was_changed_before_spell = was_changed
			imgui.begin_rect()
			
			changed, spell_tbl.enabled = imgui.checkbox("Enabled", spell_tbl.enabled); set_wc("enabled", spell_tbl, true)
			tooltip("Enable/Disable the skill")
			
			imgui.same_line()
			changed, imgui_data.do_load_controls = imgui.checkbox("Load Controls", imgui_data.do_load_controls)
			tooltip("Load skills for this slot using the hotkeys and activation controls they were saved with")
			
			imgui.same_line()
			if imgui.button("Copy") then
				clipboard.spell = hk.recurse_def_settings({}, spell_tbl)
				clipboard.spell_name = sms.last_sel_spells[i]
			end
			tooltip("Copy Skill to clipboard")
			if clipboard.spell then 
				if not imgui.same_line() and imgui.button("Paste") then
					sms.last_sel_spells[i] = clipboard.spell_name
					sms.spells[i] = hk.recurse_def_settings({}, clipboard.spell)
				end
				tooltip("Paste Skill from clipboard")
			end
			
			if imgui.button(" Save Skill  ") and imgui_data.preset_text:len() > 0 then
				local txt = imgui_data.preset_text:gsub("%.json", "") .. ".json"
				local to_dump = hk.merge_tables({}, spell_tbl)
				to_dump.hotkey = sms.hotkeys["Use Skill "..i]
				if json.dump_file("SkillMaker\\Skills\\"..txt, to_dump) then
					sms.last_sel_spells[i] = txt:sub(1, -6)
					presets_glob = nil
					was_changed = true
					re.msg("Saved to\nreframework\\data\\SkillMaker\\Skills\\"..txt)
					sms.presets_len = 0
				end
			end
			tooltip("Input new skill name and save the current settings to a json file in\n[DD2 Game Directory]\\reframework\\data\\SkillMaker\\Skills\\")
			
			imgui.same_line() 
			changed, imgui_data.preset_text = imgui.input_text("  ", imgui_data.preset_text)
			tooltip("Right click to set description\nUse a '\\' in the name (to save to a folder) or a ' - ' and only the text after that delimiter will be displayed as the title for the in-game GUI")
			
			if imgui.begin_popup_context_item("desc") then  
				if imgui.menu_item(imgui_data.show_desc_editor and "Hide Desciption" or "Edit description") then
					imgui_data.show_desc_editor = not imgui_data.show_desc_editor
				end
				imgui.end_popup() 
			end
			
			if imgui_data.show_desc_editor then
				imgui.text("				"); imgui.same_line()
				changed, spell_tbl.desc = imgui.input_text_multiline("Description", spell_tbl.desc)
			end
			
			local clicked_button = imgui.button(" Load Skill  ")
			tooltip("Load settings from a json file in\n[DD2 Game Directory]\\reframework\\data\\SkillMaker\\Skills\\")
			imgui.same_line()
			
			if expand_as_listbox(imgui_data, "preset", imgui_data, "preset_idx", " ", presets_glob or {}, nil, sms.preset_descs, "Right click to show/hide list box", nil, true) then
				imgui_data.precached_json = json.load_file("SkillMaker\\Skills\\"..presets_glob[imgui_data.preset_idx]..".json") or {} or imgui_data.precached_json
			end
			
			if clicked_button then
				if imgui_data.preset_idx == 1 then
					sms.spells[i] = hk.recurse_def_settings({}, default_sms.spells[i])
					sms.last_sel_spells[i] = nil
					imgui_data.preset_text = ""
				else
					imgui_data.precached_json = json.load_file("SkillMaker\\Skills\\"..presets_glob[imgui_data.preset_idx]..".json") or {}
					load_spell(imgui_data.precached_json, i, presets_glob[imgui_data.preset_idx], imgui_data.do_load_controls)
					imgui_data.preset_text = presets_glob[imgui_data.preset_idx]
				end
				presets_glob = nil
				was_changed = true
				sms.presets_len = 0
			end
			
			changed, imgui_data.time_slider = imgui.slider_float("Time", running_spell_tbl and game_time - running_spell_tbl.storage.start, 0.0, spell_tbl.duration, "%.2f seconds")
			tooltip("Seek bar for the skill while it is executing")
			if changed then 
				if running_spell_tbl then
					running_spell_tbl.storage.start = running_spell_tbl.storage.start + ((game_time - running_spell_tbl.storage.start) - imgui_data.time_slider)
					for s = #running_spell_tbl.storage, 1, -1 do
						if running_spell_tbl.storage[s].start > game_time - running_spell_tbl.storage.start then
							running_spell_tbl.storage[s] = nil
						end
					end
				else
					forced_spell = i
				end
			end
			
			changed, spell_tbl.duration = imgui2.drag_float(spell_tbl, "Skill Duration", spell_tbl.duration, 0.01, 0.0, 100.0, "%.2f seconds"); set_wc("duration", spell_tbl, 1.0, sms.spells)
			tooltip("The duration of the skill in seconds")
			
			local opened_ssettings = imgui.tree_node("Skill Settings")
			tooltip("Basic settings for this skill")
			if opened_ssettings then
				imgui.begin_rect()
				changed, spell_tbl.stam_cost = imgui.slider_int("Stamina Cost", spell_tbl.stam_cost, 0, 1000); set_wc("stam_cost", spell_tbl, 0, sms.spells)
				tooltip("The amount of stamina lost by performing this skill\nStamina will be subtracted on the first node with a shell")
				
				changed, spell_tbl.damage_multiplier = imgui.drag_float("Damage Multiplier", spell_tbl.damage_multiplier, 0.1, 0, 1000); set_wc("damage_multiplier", spell_tbl, 1.0, sms.spells)
				tooltip("The overall amount of damage dealt by the skill will be multiplied by this number")
				
				changed, spell_tbl.job_idx = imgui.combo("Vocation", spell_tbl.job_idx, {"All", "Fighter", "Archer", "Mage", "Thief", "Warrior", "Sorcerer", "Mystic Spearhead", "Magick Archer", "Trickster", "Warfarer",}); set_wc("job_idx", spell_tbl, 1, sms.spells)
				tooltip("The vocation required to use this skill")
				
				changed, spell_tbl.wp_idx = imgui.combo("Weapon", spell_tbl.wp_idx, weapon_types); set_wc("wp_idx", spell_tbl, 1, sms.spells)
				tooltip("The weapon required to use this skill")
				
				changed, spell_tbl.state_type_idx = imgui.combo("Activation Controls", spell_tbl.state_type_idx, {"Activate always", "When holding Modifier", "When holding 'Switch Weapon Skill'", "When not holding 'Switch Weapon Skill'"}); set_wc("state_type_idx", spell_tbl, 2, sms.spells)
				tooltip("Specify if you have to hold one of these buttons to perform this skill")
				
				changed, spell_tbl.use_modifier2 = imgui.checkbox("Use Modifier (2nd)", spell_tbl.use_modifier2); set_wc("use_modifier2", spell_tbl, false, sms.spells)
				tooltip("Make it so you have to hold down a second button along with the inhibit modifier to trigger the skill")
				
				imgui.same_line()
				changed, spell_tbl.require_weapon = imgui.checkbox("Require Weapon Drawn", spell_tbl.require_weapon); set_wc("require_weapon", spell_tbl, false, sms.spells)
				tooltip("If checked, you must have unsheathed your weapon to use this skill")
				
				imgui.same_line()
				changed, spell_tbl.hide_ui = imgui.checkbox("Hide in UI", spell_tbl.hide_ui); set_wc("hide_ui", spell_tbl, false, sms.spells)
				tooltip("If checked, this skill will not be displayed in the game's D-pad or face buttons UI")
				
				changed, spell_tbl.do_move_cam = imgui.checkbox("Move Camera		", spell_tbl.do_move_cam); set_wc("do_move_cam", spell_tbl, false, sms.spells)
				tooltip("If checked, the camera will move right while this skill is active if the global mod option 'Move Cam for Crosshair' is set to move for Skills")
				
				imgui.same_line()
				changed, spell_tbl.do_auto = imgui.checkbox("Automatic", spell_tbl.do_auto); set_wc("do_auto", spell_tbl, false, sms.spells)
				tooltip("If checked, this skill will be performed automatically, without pressing any buttons")
				
				imgui.same_line()
				changed, spell_tbl.do_hold_button = imgui.checkbox("Hold Button", spell_tbl.do_hold_button); set_wc("do_hold_button", spell_tbl, false, sms.spells)
				tooltip("If checked, the skill will cancel if the hotkey is released")
				
				local opened_func = imgui.tree_node("Activation Function")
				tooltip("Use a custom Lua function to check if this Skill can execute\nReturn 'true' to allow skill activation\nVariables:\n	'Player' - Player's [app.Character]"
				.."\n	'ActName' - Player's current action (String)\n	'ActName2' - Player's current UpperBody action (String)\n	'ActiveSkills' - Dictionary of current running Skills by Skill name"
				.."\n	'Kill(SkillName)' - Call to end a Skill by name\n	'Exec(SkillName)' - Call to start a Skill by name\n	'func' - Table of functions from Functions.lua (from _ScriptCore)\n	'hk' - Table of functions from Hotkeys.lua (from _ScriptCore)")
				if opened_func then
					imgui.begin_rect()
					changed, spell_tbl.activate_fn = imgui.input_text_multiline("Function", spell_tbl.activate_fn); set_wc()
					if imgui_data.error_txt then 
						imgui.text_colored(imgui_data.error_txt, 0xFF0000FF)
					end
					imgui.end_rect(1)
					imgui.tree_pop()
				end
				
				imgui.end_rect(1)
				imgui.tree_pop()
			end
			
			local opened_states = imgui.tree_node("States") 
			tooltip("What states the player can be in to perform this skill")
			if opened_states then
				imgui.begin_rect()
				
				imgui.text("Current Action:"); imgui.same_line() 
				imgui.text_colored(node_name, 0xFFAAFFFF)
				imgui.text("Current Anim:"); imgui.same_line()
				imgui.text_colored(bank, 0xFF00FF00); imgui.same_line(); tooltip("BankID")
				imgui.text_colored(mot_id, 0xFFFFFFAA); imgui.same_line(); tooltip("MotionID")
				imgui.text_colored(string.format("%3.02f", frame or 0), 0xFFE0853D); imgui.same_line(); tooltip("Frame")
				imgui.text_colored(anim_name, 0xFFAAFFFF)
				
				imgui.text("Current Upper Body Action:"); imgui.same_line() 
				imgui.text_colored(node_name2, 0xFFAAFFFF)
				imgui.text("Current Upper Body Anim:"); imgui.same_line()
				imgui.text_colored(bank2, 0xFF00FF00); imgui.same_line(); tooltip("BankID")
				imgui.text_colored(mot_id2, 0xFFFFFFAA); imgui.same_line(); tooltip("MotionID")
				imgui.text_colored(string.format("%3.02f", frame2 or 0), 0xFFE0853D); imgui.same_line(); tooltip("Frame")
				imgui.text_colored(anim_name2, 0xFFAAFFFF)
				
				--[[imgui.text("Current Action:"); imgui.same_line(); imgui.same_line(); imgui.text_colored(node_name, 0xFFAAFFFF)
				imgui.text("Current Anim:"); imgui.same_line(); imgui.text_colored(mfsm2 and string.format("%3.02f", player.FullBodyLayer:get_Frame()), 0xFFE0853D); imgui.same_line(); imgui.text_colored(anim_name2, 0xFFAAFFFF)
				imgui.text("Current Upper Body Anim:"); imgui.same_line(); imgui.same_line(); imgui.text_colored(anim_name, 0xFFAAFFFF)
				imgui.text("Current Upper Body Action:"); imgui.same_line(); imgui.text_colored(mfsm2 and string.format("%3.02f", player.UpperBodyLayer:get_Frame()), 0xFFE0853D); imgui.same_line(); imgui.text_colored(node_name2, 0xFFAAFFFF)]]
				
				changed, spell_tbl.spell_states = imgui.input_text("Skill States", spell_tbl.spell_states); set_wc("spell_states", spell_tbl, "", sms.spells)
				tooltip("The skill can only be used if one of these other skills is running\nSeparate different skill names with ', ' commas\nCombine different skill names with '+' plus signs (no spaces around '+')\nAdd parenthesis with a time range (in seconds) to count it only during specific time of that skill, like: MySkill(0.4,2.2)")
				
				changed, spell_tbl.custom_states = imgui.input_text("Custom States", spell_tbl.custom_states); set_wc("custom_states", spell_tbl, "", sms.spells)
				tooltip("Keywords to search the player's current Action name for to see if the skill can be used\n	Separate different keywords with ', ' commas\n	Add a '`' (backtick) to any keyword to make all keywords only required if no checkbox states are fulfilled")
				
				changed, spell_tbl.anim_states = imgui.input_text("Anim States", spell_tbl.anim_states); set_wc("anim_states", spell_tbl, "", sms.spells)
				tooltip("Keywords to search the player's current animation name for to see if the skill can be used\n	Separate different keywords with ', ' commas\n	Add a '`' (backtick) to any keyword to make all keywords only required if no checkbox states are fulfilled")
				
				changed, spell_tbl.frame_range = ui.table_vec(imgui.drag_float2, "Frame Range", spell_tbl.frame_range, {1.0, -1.0, 10000, "%3.02f frames"}); set_wc("frame_range", spell_tbl, {-1.0, -1.0}, sms.spells)
				tooltip("[Start Frame] [End Frame]\nThe current frame of the player's body animation must be between the start and end frames of this range for this skill to trigger\nSet to -1.0 to leave unmodified")
				
				changed, spell_tbl.frame_range_upper = ui.table_vec(imgui.drag_float2, "Frame Range (Upper Body)", spell_tbl.frame_range_upper, {1.0, -1.0, 10000, "%3.02f frames"}); set_wc("frame_range_upper", spell_tbl, {-1.0, -1.0}, sms.spells)
				tooltip("[Start Frame] [End Frame]\nThe current frame of the player's upper body animation must be between the start and end frames of this range for this skill to trigger\nSet to -1.0 to leave unmodified")
				
				changed, spell_tbl.require_hitbox = imgui.checkbox("Hitbox Frame", spell_tbl.require_hitbox); set_wc("require_hitbox", spell_tbl, false)
				tooltip("If checked, this Skill can only activate on a frame where you are actively projecting a hitbox (capable of damaging the enemy)")
				
				imgui.begin_rect()
				for i, state_name in ipairs(state_names) do 
					changed, spell_tbl.states[state_name] = imgui.checkbox(state_name, spell_tbl.states[state_name]); set_wc(state_name, spell_tbl.states, default_sms.spells[1].states[state_name], sms.spells)
					tooltip("Scans the current action name with a list of keywords related to the "..state_name.." state")
				end
				imgui.end_rect(0)
				
				imgui.end_rect(1)
				imgui.tree_pop()
			end
			
			local shells = spell_tbl.shells
			local last_start = 0
			local shift_amt = 0
			local opened_nodes = imgui.tree_node("Nodes")
			tooltip("The sequence of actions and shells that make up the skill")
			local running_shell = running_spell_tbl and running_spell_tbl.storage[#running_spell_tbl.storage] and running_spell_tbl.storage[#running_spell_tbl.storage].shell
			
			if opened_nodes then
				imgui.indent()
				local clicked_expand = imgui.button((imgui_data.nodes_expanded and "Collapse" or "Expand").." All Nodes")
				if clicked_expand then imgui_data.nodes_expanded = not imgui_data.nodes_expanded end
				--imgui.text_colored("*Hold ["..sms.hotkeys["UI Modifier"].."] while changing a setting to change that setting for all enabled nodes below the node being changed", 0xFFAAFFFF)
				
				for s, shell in pairs(shells) do
					local imgui_shell = imgui_data.shell_datas[s] or {enabled=true, opened=#shells < 4, last_data={}}
					imgui_shell.last_store = running_spell_tbl and running_spell_tbl.storage[s] or imgui_shell.last_store
					imgui_data.shell_datas[s] = imgui_shell
					local was_changed_before_node = was_changed
					--EMV.read_imgui_element(imgui_shell)
					local is_shell_running = running_shell and shell.enabled and (running_shell == shell or (running_shell.start == shell.start and game_time - running_spell_tbl.storage.start  - 0.05 <= shell.start))
					if is_shell_running then imgui.begin_rect(); imgui.begin_rect() end
					
					imgui.begin_rect()
					imgui.push_id(s)
					--asd = {temp_fns=temp_fns, beh_fns=beh_fns, sm_summons=sm_summons, active_shells=active_shells}
					imgui.text_colored("Node "..s.."   ", not shell.enabled and 0xFF999999 or is_shell_running and 0xFFAAFFFF or (imgui_shell.last_store and beh_fns[imgui_shell.last_store] and 0xFFFFFFFF) or 0xFFE0853D)
					tooltip("Click to "..(imgui_shell.opened and "Collapse" or "Expand").."\nRight click to copy/paste")
					
					local function expander()
						if imgui.is_item_hovered() and imgui.is_mouse_clicked() then
							imgui_shell.opened = not imgui_shell.opened
						elseif clicked_expand then
							imgui_shell.opened = imgui_data.nodes_expanded
						end
					end
					expander()
					
					if imgui.begin_popup_context_item("Node ctx") then
						if imgui.menu_item("Copy") then
							clipboard.shell = hk.recurse_def_settings({}, shell)
						end
						if clipboard.shell and imgui.menu_item("Paste") then
							shells[s] = hk.recurse_def_settings({}, clipboard.shell)
							shells[s].start = shell.start
							was_changed = true
						end
						imgui.end_popup() 
					end
					
					imgui.same_line()	
					imgui.text_colored("A", shell.action_idx > 1 and 0xFFAAFFAA or 0xFF999999); tooltip("Has Action"); expander()
					imgui.same_line(); imgui.text("|"); imgui.same_line()
					imgui.text_colored("S", shell.udata_idx > 1 and 0xFFAAFFAA or 0xFF999999); tooltip("Has Shell"); expander()
					imgui.same_line(); imgui.text("|"); imgui.same_line()
					imgui.text_colored("P", (shell.anim_speed ~= 1.0 or shell.world_speed ~= 1.0) and 0xFFAAFFAA or 0xFF999999); tooltip("Has Speed"); expander()
					imgui.same_line(); imgui.text("|"); imgui.same_line()
					imgui.text_colored("C", shell.camera_dist ~= -1.0 and 0xFFAAFFAA or 0xFF999999); tooltip("Has Camera Distance"); expander()
					imgui.same_line(); imgui.text("|"); imgui.same_line()
					imgui.text_colored("V", shell.pl_velocity_type ~= 1 and 0xFFAAFFAA or 0xFF999999); tooltip("Has Velocity"); expander()
					imgui.same_line(); imgui.text("|"); imgui.same_line()
					imgui.text_colored("Sm", shell.summon_idx ~= 1 and 0xFFAAFFAA or 0xFF999999); tooltip("Has Summon"); expander()
					imgui.same_line(); imgui.text("|"); imgui.same_line()
					imgui.text_colored("Fn", shell.custom_fn ~= "" and 0xFFAAFFAA or 0xFF999999); tooltip("Has Custom Function"); expander()
					imgui.same_line(); imgui.text("|"); imgui.same_line()
					imgui.text_colored(string.format("%3.02fs", (shells[s+1] and shells[s+1].start or spell_tbl.duration) - shell.start), is_shell_running and 0xFFFFFFFF or 0xFF999999); tooltip("Duration"); expander()
					
					imgui.same_line()
					imgui.text_colored((selected_shell == shell) and "SELECTED" or "", 0xFFAAFFFF)
					if not imgui_shell.opened then imgui.spacing() end
					
					if not imgui_shell.opened then
						shell.start = shell.start + shift_amt
						imgui.pop_id()
						imgui.end_rect(0)
					else
						if imgui.button(" + ") then
							table.insert(shells, s+1, hk.merge_tables({}, shell))
							was_changed, spell_tbl.enabled = true, true
						end
						tooltip("Add a new node")
						
						imgui.same_line()
						if imgui.button(" - ") and #shells > 1 then
							table.remove(shells, s)
							was_changed = true
						end
						tooltip("Remove this node")
						
						imgui.same_line()
						local prev_shell_start = shell.start
						changed, shell.start = imgui.slider_float("Start Time", shell.start + shift_amt, 0, spell_tbl.duration, "%.2fs"); set_wc()
						tooltip("The start time of the this node during the skill\nHold "..sms.hotkeys["UI Modifier"].." (UI Modifier) to move all start times in the nodes below along with it")
						shift_amt = (changed and ui_mod_down and (shell.start - prev_shell_start)) or shift_amt
						if shell.start > spell_tbl.duration then shell.start = spell_tbl.duration end
						if shell.start < last_start then shell.start = last_start end
						last_start = shell.start
						
						if imgui.arrow_button("Up", 2) and s > 1 then
							shells[s-1].start, shells[s].start = shell.start, shells[s-1].start
							shells[s-1], shells[s] = shell, shells[s-1]
							was_changed = true
						end
						tooltip("Move this node up one")
						
						imgui.same_line()
						if imgui.arrow_button("Down", 3) and s < #shells then
							shells[s+1].start, shells[s].start = shell.start, shells[s+1].start
							shells[s+1], shells[s] = shell, shells[s+1]
							was_changed = true
						end
						tooltip("Move this node down one")
						
						imgui.same_line()
						if expand_as_listbox(imgui_shell, "action", shell, "action_idx", "Action", action_names, action_names_numbered, action_tooltips, "The action that will play when running this node\nRight click to show/hide list box\nDouble-click in list box to preview", shells) then
							local ticks = 0
							temp_fns.play_action = function()
								temp_fns.play_action, ticks = ticks < 3 and temp_fns.play_action or nil, ticks + 1
								if imgui.is_mouse_double_clicked() then --it only reports the change 3 frames later..
									player["<ActionManager>k__BackingField"]:requestActionCore(0, action_names[shell.action_idx], action_tooltips[shell.action_idx]=="" and 0 or 1)
								end
							end
						end
						
						if imgui.button(" Select ") then
							selected_shell = shell
							imgui_shell.show_more = not imgui_shell.show_more
						end
						tooltip("Select this node")
						
						imgui.same_line()
						if shell.action_idx == 2 then
							changed, shell.action_name = imgui.input_text("Custom Action Name", shell.action_name); set_wc()
							imgui.text("		       "); imgui.same_line()
						else
							shell.action_name = action_names[shell.action_idx]
						end
						
						expand_as_listbox(imgui_shell, "udata", shell, "udata_idx", "Shell File", user_paths_short, user_paths_short, udata_descs, "The userdata file containing the collection of shells selectable with 'Shell ID'\nRight click to show/hide list box", shells)
						if changed then shell.shell_id = 0; imgui_shell.shell_list_idx = 1; imgui_shell.shell_list = nil end
						
						local udata_path = user_paths[shell.udata_idx]
						udatas[udata_path] = udatas[udata_path] or sdk.create_userdata("app.ShellParamData", udata_path)
						shell.max_ids = udatas[udata_path].ShellParams._size
						shell.udata_name = user_paths[shell.udata_idx]
						
						local line_started = false
						local function set_line_start()
							if not line_started then imgui.text("		       ") end; imgui.same_line(); line_started = true
						end
						
						--imgui.text("		       "); imgui.same_line()
						changed, shell.enabled = imgui.checkbox("On  ", shell.enabled); set_wc("enabled", shell, true, shells); imgui.same_line()
						tooltip("Enable/disable use of this node")
						
						if shell.udata_idx > 1 then
							local sdesc_tbl = shell_descs[user_paths_short[shell.udata_idx]:match("\t(.+)")]
							
							shell.shell_id = shell.shell_id + 1
							if expand_as_listbox(imgui_shell, "shell", shell, "shell_id", "Shell ID", sdesc_tbl.titles, sdesc_tbl.titles, sdesc_tbl.descs, "The ID of the shell in the file\nRight click to show/hide list box\nDouble-click in list box to preview", shells) and shell.cast_type == 3 then
								local ticks = 0
								temp_fns.play_action = function()
									temp_fns.play_action, ticks = ticks < 3 and temp_fns.play_action or nil, ticks + 1
									if imgui.is_mouse_double_clicked() then --it only reports the change 3 frames later..
										cast_shell(shell, {})
									end
								end
							end
							
							shell.shell_id = shell.shell_id - 1
							
							local sz = udata_path ~= "None" and shell.max_ids - 1
							if sz and sz > 0 then
								if shell.shell_id > sz then shell.shell_id = sz end
								if shell.shell_id < 0 then shell.shell_id = 0 end
							end
							
							local bad_shell = bad_shells[shell.udata_name]
							if bad_shell and bad_shell[shell.shell_id] then
								imgui.text_colored("					Warning: Dangerous shell, modify with care", 0xFF88FFFF)
							end
							
							imgui.text("		       "); imgui.same_line()
							changed, shell.cast_type = imgui.combo("Cast Type", shell.cast_type, {"Target", "Skyfall", "Player", "Previous Shell"}); set_wc("cast_type", shell, 1, shells)
							tooltip("The spawn location of the shell")
							
							if shell.cast_type == 3 then --player
								imgui.text("		       "); imgui.same_line()
								changed, shell.joint_idx = imgui.combo("Joint Name", shell.joint_idx, joint_list); set_wc("joint_idx", shell, 1, shells)
								if changed then shell.joint_name = shell.joint_idx > 1 and joint_list[shell.joint_idx] or shell.joint_name end
								tooltip("Select a joint name from the list")
								if shell.joint_idx == 1 then
									imgui.text("		       "); imgui.same_line()
									changed, shell.joint_name = imgui.input_text("Input Joint Name", shell.joint_name or "root"); set_wc("joint_name", shell, "root", shells)
									tooltip("The joint on the player that the shell will spawn on")
								end
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.rot_type_idx = imgui.combo("Rotation Type", shell.rot_type_idx, {"Joint", "Player Base", "Crosshair"}); set_wc("rot_type_idx", shell, false, shells)
								tooltip("The rotation of the spawned shell on the player can be relative to the joint its mounted to, relative to the overall player rotation, or can be pointed towards the crosshair")
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.attach_to_joint = imgui.checkbox("Attach to Joint", shell.attach_to_joint); set_wc("attach_to_joint", shell, false, shells)
								tooltip("If checked, the shell will be mounted on the selected joint until it expires")
								
								imgui.same_line()
								changed, shell.do_no_attach_rotate = imgui.checkbox("No Attach Rotation", shell.do_no_attach_rotate); set_wc("do_no_attach_rotate", shell, false, shells)
								tooltip("If checked, the shell will not rotate while attached to the selected joint")
								
								if shell.rot_type_idx < 3 then
									imgui.same_line()
									changed, shell.do_aim_up_down = imgui.checkbox("Aim Up/Down", shell.do_aim_up_down); set_wc("do_aim_up_down", shell, false, shells)
									tooltip("If checked, the projectile will be aimed up or down from its joint based on the camera direction\nCan be combined with 'Soft Lock' to autoaim at aligned enemies")
								end
							end
							
							if shell.cast_type == 3 or shell.cast_type == 4 then --skyfall
								imgui.text("		       "); imgui.same_line()
								changed, shell.attach_pos = ui.table_vec(imgui.drag_float3, "Position Offset", shell.attach_pos, {0.01, -10000, 10000}); set_wc("attach_pos", shell, {0,0,0}, shells)
								tooltip("This offset will be added to the shell spawn position (X / Y / Z)")
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.attach_euler = ui.table_vec(imgui.drag_float3, "Rotation Offset", shell.attach_euler or {0,0,0}, {0.01, -math.pi, math.pi}); set_wc("attach_euler", shell, {0,0,0}, shells)
								tooltip("This offset will be added to the shell spawn rotation (Pitch / Yaw / Roll)")
							end
							
							if shell.cast_type == 2 then --skyfall
								imgui.text("		       "); imgui.same_line()
								changed, shell.skyfall_pos_offs = ui.table_vec(imgui.drag_float3, "Skyfall Position Offset", shell.skyfall_pos_offs or {0,0,0}, {0.01, -10000, 10000}); set_wc("skyfall_pos_offs", shell, {0,100,0}, shells)
								tooltip("This offset will be added to the player's position to determine where the shell will spawn")
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.skyfall_dest_offs = ui.table_vec(imgui.drag_float3, "Skyfall Destination Offset", shell.skyfall_dest_offs or {0,0,0}, {0.01, -10000, 10000}); set_wc("skyfall_dest_offs", shell, {0,0,0}, shells)
								tooltip("This offset will be added to the crosshair position to determine where the shell will travel towards")
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.skyfall_random_xz = imgui.checkbox("Skyfall Random XZ", shell.skyfall_random_xz); set_wc("skyfall_random_xz", shell, true, shells)
								tooltip("If checked, the the X and Z coordinates of the Skyfall Position Offset will be set within a random range of [-x, x] and [-z, z]")
								
								imgui.same_line()
								changed, shell.skyfall_cam_relative = imgui.checkbox("Skyfall Cam-Relative", shell.skyfall_cam_relative); set_wc("skyfall_cam_relative", shell, true, shells)
								tooltip("If checked, skyfall's position coordinates will be made relative to the camera position rather than to the player position")
							end
							
							if shell.cast_type == 4 then --previous shell
								imgui.text("		       "); imgui.same_line()
								changed, shell.pshell_attach_type = imgui.combo("Shell Attach Type", shell.pshell_attach_type, {"Don't Attach", "Attach Always", "Attach Until Contact"}); set_wc("pshell_attach_type", shell, false, shells)
								tooltip("The shell can be mounted on the previous shell until the previous shell expires or until the previous shell hits something")
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.do_carryover_prev = imgui.checkbox("Continuous Shell", shell.do_carryover_prev); set_wc("do_carryover_prev", shell, true, shells)
								tooltip("If checked, the previous shell position and rotation will be carried over from the previous node, allowing one shell to be carried across multiple nodes even though its not directly 'previous' in the sequence")
							end
						
							--imgui.text("		       "); imgui.same_line()
							local old = shell.scale
							changed, imgui_data.scale_together = imgui.checkbox("       ", imgui_data.scale_together); imgui.same_line(); tooltip("Scale XYZ together")
							changed, shell.scale = ui.table_vec(imgui.drag_float3, "Shell Scale", shell.scale, {0.01, 0.01, 10, "%.2fx"}); set_wc("scale", shell, {1.0,1.0,1.0}, shells)
							tooltip("The size of the effect")		
							if changed and imgui_data.scale_together then
								if old[1] ~= shell.scale[1] then shell.scale = {shell.scale[1], shell.scale[1], shell.scale[1]} end
								if old[2] ~= shell.scale[2] then shell.scale = {shell.scale[2], shell.scale[2], shell.scale[2]} end
								if old[3] ~= shell.scale[3] then shell.scale = {shell.scale[3], shell.scale[3], shell.scale[3]} end
							end
							
							imgui.text("		       "); imgui.same_line()
							changed, shell.speed = imgui.drag_float("Shell Speed", shell.speed, 0.01, 0.0, 10.0, "%.2fx"); set_wc("speed", shell, 1.0, shells)
							tooltip("The speed of this shell")		
							
							imgui.text("		       "); imgui.same_line()
							changed, shell.attack_rate = imgui.drag_float("Shell Attack Rate", shell.attack_rate, 0.1, 0.0, 1000.0, "%.2fx"); set_wc("attack_rate", shell, 1.0, shells)
							tooltip("The amount of damage this shell deals")	
							
							local last_lifetime = shell.lifetime
							imgui.text("		       "); imgui.same_line()
							changed, shell.lifetime = imgui.drag_float("Shell Lifetime", shell.lifetime, 0.01, -2.0, 1000.0, "%.2f seconds"); set_wc("lifetime", shell, -1.0, shells)
							tooltip("How long this shell will exist\nSet to -1 to leave unmodified\nSet to -2 to delete the shell after the next node")
							if changed and shell.lifetime < 0 and shell.lifetime > last_lifetime then shell.lifetime = math.ceil(shell.lifetime) end
							if shell.lifetime < 0 then shell.lifetime = math.floor(shell.lifetime) end
							
							local last_omentime = shell.omentime
							imgui.text("		       "); imgui.same_line()
							changed, shell.omentime = imgui.drag_float("Shell Omen Time", shell.omentime, 0.01, -1.0, 1000.0, "%.2f seconds"); set_wc("omentime", shell, -1.0, shells)
							tooltip("The amount of warning time given before the shell goes off\nSet to 0 to disable\nSet to -1 to leave unmodified")
							if changed and shell.omentime < 0 and shell.omentime > last_omentime then shell.omentime = 0 end
							if shell.omentime < 0 then shell.omentime = -1 end
						
							imgui.text("		       "); imgui.same_line()
							changed, shell.coloring = ui.table_vec(imgui.color_edit4, "Shell Coloring", shell.coloring or {0,0,0,0}, {0.01, 0, 1, 17301504}); set_wc("coloring", shell, nil, shells)
							tooltip("The color of the shell's visual effects (Red / Blue / Green / Alpha)")
							
							imgui.text("		       "); imgui.same_line()
							changed, shell.setland_idx = imgui.combo("Set Land", shell.setland_idx, {"Default", "Off", "On"}); set_wc("setland_idx", shell, false, shells)
							tooltip("Whether the shell will appear only on the ground or if it can appear in midair")
							
							--[[imgui.text("		       "); imgui.same_line()
							changed, shell.shell_option = imgui.drag_int("Shell Option", shell.shell_option, 1, -1, 1000); set_wc("shell_option", shell, -1.0, shells)
							--tooltip("The amount of warning time given before the shell goes off\nSet to 0 to disable\nSet to -1 to leave unmodified")]]
							
							imgui.text("		       "); imgui.same_line()
							changed, shell.summon_idx = imgui.combo("Summon", shell.summon_idx, enemies_list); set_wc("summon_idx", shell, 1, shells)
							if changed then shell.summon_action_idx = 1 end
							tooltip("SKELETONS AND BANDITS CURRENTLY DO NOT SPAWN thanks to Capcom update\nRight click to show/hide list box")
							
							if shell.summon_idx > 1 then
								imgui.text("		       "); imgui.same_line()
								local em_name = enemies_list[shell.summon_idx]:match("(.+) %- ")
								expand_as_listbox(imgui_shell, "summon_action", shell, "summon_action_idx", "Summon Action", enemy_action_names[em_name], nil, nil, "The action that the enemy will perform when spawned\nRight click to show/hide list box", shells)
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.summon_timer = imgui.drag_float("Summon Time Limit", shell.summon_timer, 0.1, 0.0, 10000.0, "%.2f seconds"); set_wc("summon_timer", shell, 1, shells)
								tooltip("How long the summon can exist")
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.summon_scale = imgui.drag_float("Summon Scale", shell.summon_scale, 0.01, 0.01, 100.0, "%.2fx"); set_wc("summon_scale", shell, 1, shells)
								tooltip("How large or small the summon will be, relative to its normal size")
								
								imgui.text("		       "); imgui.same_line()
								changed, shell.summon_attack_rate = imgui.drag_float("Summon Attack Rate", shell.summon_attack_rate, 0.01, 0.01, 100.0, "%.2fx"); set_wc("summon_attack_rate", shell, 1, shells)
								tooltip("Multiplier for how much damage the summon will deal with its attacks")
							end
							
							--imgui.text("		       "); imgui.same_line()
							--changed, shell.enchant_type = imgui.combo("Shell Enchantment", shell.enchant_type, {"Default Enchantment", "No Enchantment", "Fire Enchantment", "Ice Enchantment", "Thunder Enchantment", "Light Enchantment"}); set_wc("enchant_type", shell, 1, shells)
							--tooltip("The shell will carry this elemental power")
						end
						
						--if shell.action_idx > 1 then
							if shell.udata_idx > 1 then imgui.text("		       "); imgui.same_line() end
							changed, shell.turn_idx = imgui.combo("Turn Player", shell.turn_idx, {"Don't Turn", "Turn to Analog Stick", "Turn to Camera"}); set_wc("turn_idx", shell, 1, shells)
							tooltip("Make the player turn in the direction that the camera is looking or in the direction being inputted")
						--end
						
						if shell.turn_idx == 2 or shell.turn_idx == 4 then
							imgui.text("		       "); imgui.same_line()
							changed, shell.turn_speed = imgui.drag_float("Turn Speed", shell.turn_speed, 0.001, 0.0, 2.0, "%.2fx"); set_wc("turn_speed", shell, 1.0, shells)
							tooltip("The speed at which you will turn with 'Turn to Analog Stick' enabled")
						end
						
						if shell.udata_idx > 1 and shell.summon_idx > 1 then
							set_line_start()
							changed, shell.summon_no_dissolve = imgui.checkbox("Summon No-Dissolve", shell.summon_no_dissolve); set_wc("summon_no_dissolve", shell, false, shells)
							tooltip("The summoned enemy will instantly materialize rather than dissolve into reality")
						end
						
						set_line_start()
						changed, shell.do_mirror_action = imgui.checkbox("Mirror", shell.do_mirror_action); set_wc("do_mirror_action", shell, false, shells)
						tooltip("The animation of the action will be flipped left to right")
						
						imgui.same_line()
						changed, shell.do_mirror_wp = imgui.checkbox("Mirror Wp", shell.do_mirror_wp); set_wc("do_mirror_wp", shell, false, shells)
						tooltip("Your weapon will be moved to the opposite hand")
						
						if shell.action_idx > 1 then
							imgui.same_line()
							changed, shell.do_simplify_action = imgui.checkbox("Simplify Action", shell.do_simplify_action); set_wc("do_simplify_action", shell, false, shells)
							tooltip("If checked, only the animation part of the action will be enabled")
						end
						line_started = false
						
						local is_cast_hold = false
						if shell.action_idx > 1 and (shell.action_name:find("Prepare") or shell.action_name:find("Ready")) then
							set_line_start()
							changed, shell.do_hold = imgui.checkbox("Hold", shell.do_hold); set_wc("do_hold", shell, false, shells)
							tooltip("The next node will not start until the Prepare animation is completed or the modifier is let go after the node's time is over")
							local subbed = shell.action_name:sub(1,5)
							is_cast_hold = subbed == "Job03" or subbed == "Job06" or subbed == "JobMa"
							if shell.do_hold and not imgui.same_line() then
								changed, shell.do_true_hold = imgui.checkbox("True Hold", shell.do_true_hold); set_wc("do_true_hold", shell, false, shells)
								tooltip("The next node will not start until the Prepare animation is completed\nUse this only with the correct weapon for the animation")
							end
						elseif shell.do_hold then
							shell.do_hold, shell.do_true_hold = false, false
						end
						
						if shell.udata_idx > 1 then
							set_line_start()
							changed, shell.do_vfx = imgui.checkbox("VFX", shell.do_vfx); set_wc("do_vfx", shell, true, shells)
							tooltip("Render visual effects for this shell")
							
							imgui.same_line()
							changed, shell.do_sfx = imgui.checkbox("SFX", shell.do_sfx); set_wc("do_sfx", shell, true, shells)
							tooltip("Play sound effects for this shell")
						
							imgui.same_line() 
							changed, shell.do_teleport_player = imgui.checkbox("Pl Teleport", shell.do_teleport_player); set_wc("do_teleport_player", shell, false, shells)
							tooltip("The player will be teleported to the location of the shell")
							
							imgui.same_line() 
							changed, shell.is_decorative = imgui.checkbox("Decorative", shell.is_decorative); set_wc("is_decorative", shell, false, shells)
							tooltip("Makes it so this shell will not collide with anything")
							
							if shell.lifetime >= 0 then
								imgui.same_line() 
								changed, shell.do_abs_lifetime = imgui.checkbox("Abs. Lifetime", shell.do_abs_lifetime); set_wc("do_abs_lifetime", shell, false, shells)
								tooltip("Makes it so this shell will not expire before its lifetime is up")
							end
							
							imgui.same_line()
							changed, shell.enemy_soft_lock = imgui.checkbox("Soft Lock", shell.enemy_soft_lock); set_wc("enemy_soft_lock", shell, false, shells)
							tooltip("The shell will jump onto the nearest enemy to its position or target position")
							
							if shell.enemy_soft_lock then
								imgui.text("		       "); imgui.same_line()
								changed, shell.soft_lock_range = imgui.drag_float("Soft Lock Range", shell.soft_lock_range, 0.01, -1.0, 1000.0, "%.2f meters"); set_wc("soft_lock_range", shell, 1.5, shells)
								tooltip("The maximum distance that the shell will travel from its expected position to jump onto an enemy")
							end
						end
						
						imgui.text("		       "); imgui.same_line()
						changed, shell.do_inhibit_buttons = imgui.checkbox("Inhibit", shell.do_inhibit_buttons); set_wc("do_inhibit_buttons", shell, false, shells)
						tooltip("You cannot move or do anything while this node is active")
						
						local has_pl_soft_lock = false
						if shell.turn_idx > 1 or (s > 1 and shells[s-1].do_turn_constantly and shells[s-1].turn_idx > 1) then
							--set_line_start()
							imgui.same_line()
							changed, shell.do_turn_constantly = imgui.checkbox("Turn Constantly", shell.do_turn_constantly); set_wc("do_turn_constantly", shell, false, shells)
							tooltip("The player will constantly turn in the direction from 'Turn Player' during this node")
							if shell.turn_idx == 2 then 
								imgui.same_line()
								changed, shell.do_pl_soft_lock = imgui.checkbox("Pl Soft Lock", (shell.pl_velocity_type == 7) or shell.do_pl_soft_lock); set_wc("do_pl_soft_lock", shell, false, shells)
								tooltip("The player will snap-turn towards enemies nearest in the direction of the analog stick")
								has_pl_soft_lock = true
							end
						end
					
						imgui.same_line()
						changed, shell.do_iframes = imgui.checkbox("Pl Invincibility", shell.do_iframes); set_wc("do_iframes", shell, false, shells)
						tooltip("The player will be invincible during this node")
						
						imgui.same_line()
						changed, shell.freeze_crosshair = imgui.checkbox("Freeze Crosshair", shell.freeze_crosshair); set_wc("freeze_crosshair", shell, false, shells)
						tooltip("If checked while using the crosshair to cast, the crosshair's position will carry over into the next node")
						
						if shell.summon_idx > 1 then
							imgui.same_line()
							changed, shell.summon_hostile = imgui.checkbox("Hostile Summon", shell.summon_hostile); set_wc("summon_hostile", shell, false, shells)
							tooltip("Make this summon be an enemy")
						end
						
						if is_cast_hold then
							imgui.text("		       "); imgui.same_line()
							changed, shell.hold_color = ui.table_vec(imgui.color_edit4, "Hold Coloring", shell.hold_color, {0.01, 0, 1, 17301504}); set_wc("coloring", shell, nil, shells)
							tooltip("The color of the prepare casting action's visual effects (Red / Blue / Green / Alpha)")
						end
						
						if shell.do_mirror_action or shell.do_mirror_wp then
							imgui.text("		       "); imgui.same_line()
							local last_mirror_time = shell.mirror_time
							changed, shell.mirror_time = imgui.drag_float("Mirror Time", shell.mirror_time, 0.01, -1.0, 10000.0, "%.2f seconds"); set_wc("mirror_time", shell, -1.0, shells)
							tooltip("How long the animation will stay mirrored after the start of this node\nSet to -1 to mirror until the end of the action")
							if changed and shell.mirror_time < 0 and shell.mirror_time > last_mirror_time then shell.mirror_time = 0 end
							if shell.mirror_time < 0 then shell.mirror_time = -1 end
						end
						
						local last_cam_dist = shell.camera_dist
						imgui.text("		       "); imgui.same_line()
						changed, shell.camera_dist = imgui.drag_float("Camera Distance", shell.camera_dist, 0.01, -1.0, 100.0, "%.2f meters"); set_wc("camera_dist", shell, -1.0, shells)
						tooltip("How far the camera will be from the player\nSet to -1 to leave unmodified")
						if changed and shell.camera_dist < 0 and shell.camera_dist > last_cam_dist then shell.camera_dist = 0 end
						if shell.camera_dist < 0 then shell.camera_dist = -1 end
					
						imgui.text("		       "); imgui.same_line()
						changed, shell.boon_type = imgui.combo("Boon Type", shell.boon_type, {"None", "Fire", "Ice", "Thunder"}); set_wc("boon_type", shell, 1.0, shells)
						tooltip("Your weapon will have this boon applied during this node")
						
						if shell.boon_type > 1 then
							imgui.text("		       "); imgui.same_line()
							changed, shell.boon_color = ui.table_vec(imgui.color_edit4, "Boon Coloring", shell.boon_color, {0.01, 0, 1, 17301504}); set_wc("boon_color", shell, nil, shells)
							tooltip("The color of the boon's visual effects (Red / Blue / Green / Alpha)")
						end
					
						imgui.text("		       "); imgui.same_line()
						changed, shell.pl_velocity_type = imgui.combo("Pl Velocity Type", shell.pl_velocity_type, {"No Velocity", "Player Direction", "Towards Crosshair", "Towards Shell", "Towards Camera", "Towards Analog Stick", has_pl_soft_lock and "Pl Soft Lock Target"}); set_wc("pl_velocity_type", shell, 1, shells)
						tooltip("How velocity and/or movespeed will be applied to the player during this node")
						
						if shell.pl_velocity_type > 1 then
							imgui.text("		       "); imgui.same_line()
							changed, shell.pl_velocity = ui.table_vec(imgui.drag_float3, "Pl Velocity Vector", shell.pl_velocity, shell.do_constant_speed and {0.01, -50.0, 50.0} or {0.001, -1.0, 1.0}); set_wc("pl_velocity", shell, {0.0,0.0,0.0}, shells)
							tooltip(shell.do_constant_speed and "The directional movement speed of the player, applied constantly (X | Y | Z)" or "This force vector will be applied once to the player with physics (X | Y | Z , works best in midair)\nUse a positive value on the Z axis to go forward")
							
							imgui.text("		       "); imgui.same_line()
							changed, shell.do_constant_speed = imgui.checkbox("Constant Speed", shell.do_constant_speed); set_wc("do_constant_speed", shell, false, shells)
							tooltip("If checked, the player will move in the direction constantly and without physics, rather than a single push")
						end
						
						imgui.text("		       "); imgui.same_line()
						changed, shell.world_speed = imgui.drag_float("World Speed", shell.world_speed, 0.01, 0, 10.0, "%.2fx"); set_wc("world_speed", shell, 1.0, shells)
						tooltip("The game will be set to this speed during this node")
						
						imgui.text("		       "); imgui.same_line()
						changed, shell.anim_speed = imgui.drag_float("Action Speed", shell.anim_speed, 0.01, 0, 10, "%.2fx"); set_wc("anim_speed", shell, 1.0, shells)
						tooltip("The speed of the animation playing for this node")
						
						if shell.action_idx > 1 then
							imgui.text("		       "); imgui.same_line()
							changed, shell.custom_motion = imgui.input_text("Custom Motion/Frame", shell.custom_motion); set_wc("custom_motion", shell, "", shells)
							tooltip("Play this action using a custom animation\nFormat:\n	[Motlist File], [Bank ID], [Motion ID], [Layer Index], [Frame], [Num Interpolation Frames]\nExample:\n	animation\\ch\\ch26\\motlist\\ch26_003_atk.motlist, 7777, 169, 0.0, 15.0"
							.."\n\n- The motlist file should exist in the PAK or in your natives folder\n- Make up a unique Bank ID to always use with this motlist\n- The Motion ID must be the ID of an animation in a motlist file"
							.."\n- The Layer Index is 0 for body and 1 for upper body\n- The frame is the frame the animation will start on, with a decimal (i.e. '4.5'). It can be omitted to start at 0.0\n- The number of interpolation frames determines how quickly the animation transitions"
							.."\n\nAlternatively, this field can be used to set the frame on the current action\nAlt Format:\n	[Frame], [Layer Index] [Num Interpolation Frames]")
						end
						
						imgui.text("		       "); imgui.same_line()
						local opened_func = imgui.tree_node("Custom Function")
						tooltip("Repeat a Lua function during this node\nVariables:\n	'Skill' - Lua table of data about this skill\n	'Node' - Lua table of data about this node\n	'Player' - Player's [app.Character]"
						.."\n	'Summon' - Summon's [app.Character]\n	'Shell' - Shell's [app.Shell]\n	'ActName' - Player's current action (String)\n	'ActName2' - Player's current UpperBody action (String)\n	'ActiveSummons' - All active summons table (Nodes)"
						.."\n	'ActiveSkills' - Dictionary of current running Skills by Skill name\n	'GameTime' - The clock of the game, accounting for pause\n\n	'Hold()' - Call to prevent the timeline from moving beyond this node for a frame"
						.."\n	'RepeatNode()' - Call to replay the current node\n	'Stop()' - Call to end the function (stop repeating)\n	'Kill(SkillName)' - Call to end a Skill. Omit 'SkillName' to kill this skill"
						.."\n	'Exec(SkillName)' - Call to force-start another skill by name\n	'ReachedEnemy(Distance)' - Becomes true when the player becomes within [Distance] of the Pl Soft-Lock target"
						.."\n\n	'func' - Table of functions from Functions.lua (from _ScriptCore)\n	'hk' - Table of functions and hotkeys from Hotkeys.lua (from _ScriptCore)")
						if opened_func then
							imgui.text("		       "); imgui.same_line()
							imgui.begin_rect()
							changed, shell.custom_fn = imgui.input_text_multiline("Function", shell.custom_fn); set_wc()
							if imgui_shell.error_txt then 
								imgui.text_colored(imgui_shell.error_txt, 0xFF0000FF)
							end
							
							if not EMV or imgui.tree_node("Vars") then
								local storage = imgui_shell.last_store
								local ld = imgui_shell.last_data
								ld.Player, ld.Skill, ld.Node, ld.Summon, ld.Shell = player, storage and storage.parent, storage, storage and storage.summon_inst, storage and storage.final_instance
								disp_imgui_element("Vars", imgui_shell.last_data)
								if EMV then imgui.tree_pop() end
							end
							imgui.end_rect(1)
							imgui.tree_pop()
						end
						
						if was_changed and not was_changed_before_node then
							selected_shell = shell
						end
						
						imgui.pop_id()
						imgui.end_rect(0)
						
						imgui.spacing()
					end
					
					if is_shell_running then imgui.end_rect(1); imgui.end_rect(2) end
				end
				imgui.unindent()
				imgui.tree_pop()
			end
			
			if spell_tbl.unedited and was_changed and not was_changed_before_spell then
				spell_tbl.unedited, spell_tbl.enabled = false, true
			end
			
			imgui.spacing()
			imgui.end_rect(1)
			imgui.tree_pop()
		end
		
		imgui.spacing()
	end
	
	
	imgui.text("																			v"..version.."  |  By alphaZomega")
	imgui.end_rect(2)
	imgui.spacing()
	if is_window then imgui.end_child_window() end
end

local function reset_fall_height(seconds)
	local f_param = player["<FallDamageParamCalc>k__BackingField"]["<Param>k__BackingField"]
	f_param.HeightDamageForHuman, f_param.HeightDamageForSmall, f_param.HeightDamageForLarge = 1000, 1000, 1000
	local start = game_time
	
	temp_fns.fix_fall_height = function()
		if game_time - start > seconds then --game tries admirably hard to remember your last freefall state
			temp_fns.fix_fall_height = nil
			f_param.HeightDamageForHuman, f_param.HeightDamageForSmall, f_param.HeightDamageForLarge = 8.0, 3.5, 10.0
		end
	end
end

local function nearest_enemy_fn(compare_pos, extra_fn, do_add_player)
	local dist = 999999
	local closest_pos
	local closest_em
	local targ_list = func.lua_get_array(em_mgr._EnemyList._items, true)
	if do_add_player then table.insert(targ_list, 1, player) end
	for i, enemy in ipairs(targ_list) do
		local chara = enemy._Chara
		if chara then
			local em_pos = (chara.Hip or chara["<Transform>k__BackingField"]):get_Position()
			local this_dist = (em_pos - compare_pos):length()
			if ((do_add_player and i == 1) or chara["<Hit>k__BackingField"]:get_Hp() > 0) and this_dist < dist and (not extra_fn or extra_fn(this_dist)) then
				dist, closest_pos, closest_em = this_dist, em_pos, enemy
			end
		end
	end
	return closest_pos, closest_em
end

--Spawn and manage sm_summons
local function summon(storage, position, rotation)
	local shell = storage.shell	
	local pfb_path = enemies_list[shell.summon_idx]:match("(AppSys.+)")
	
	if pfb_path:find("ch23") or pfb_path:find("ch22600[0123]") then 
		print("Skill Maker: Aborted spawning of skeleton or bandit summon to prevent a crash")
		return nil
	end
	
	local pfb = sdk.create_instance("via.Prefab"):add_ref()
	pfb:set_Path(pfb_path)
	pfb:set_Standby(true)
	local pfb_ctrl = sdk.create_instance("app.PrefabController"):add_ref()
	pfb_ctrl._Item = pfb
	local i_info = sdk.create_instance("app.InstanceInfo"):add_ref()
	local g_info = sdk.create_instance("app.GenerateInfo.GenerateInfoContainer"):add_ref()
	g_info._CommonInfo._ContextPosition = scene:toUniversalPosition(position)
	g_info._CommonInfo._ContextAngle = rotation
	g_info._StatusInfo["<ScaleRate>k__BackingField"] = shell.summon_scale
	g_info._StatusInfo._CustomCharaStatusID = 0
	g_info._CharaInfo._IsWanderMode = true
	--g_info._CharaInfo._IsDestinationMove = true
	local chara_id_name = pfb_path:match(".+/(.+)%.pfb")
	g_info._CommonInfo._ObjectID._SelectedCharacterID = enums.chara_id_enum[chara_id_name]
	g_info["<HumanInfo>k__BackingField"]["<Meta>k__BackingField"] = sdk.create_instance("app.CharacterEditDefine.MetaData"):add_ref()
	local enemy, chara, em_ui, did_poof, did_col, did_act
	storage.summon_start = game_time
	
	beh_fns[g_info] = function()
		local prev_enemy = enemy
		enemy = enemy or i_info["<Instance>k__BackingField"]
		
		if enemy and not enemy:get_Valid() then
			beh_fns[g_info], sm_summons[chara] = nil
			
		elseif game_time - storage.summon_start > shell.summon_timer then
			beh_fns[g_info], sm_summons[chara], active_summons[chara] = nil
			gen_mgr:call("requestDestroy(app.GenerateInfo.GenerateInfoContainer, System.Boolean, System.Boolean, System.Boolean, System.Boolean)", g_info, false, false, false, false)
			enemy:destroy(enemy)
		elseif not enemy and pfb:get_Ready() then
			chr_mgr["<CustomCharaStatusParam>k__BackingField"]._CustomCharaParams[1]._AttackRate = shell.summon_attack_rate * storage.spell.damage_multiplier
			gen_mgr:call("requestCreateInstance(app.PrefabController, app.GenerateInfo.GenerateInfoContainer, System.Int32, app.InstanceInfo, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>)", 
				pfb_ctrl, g_info, 0, i_info, nil, nil)
				
		elseif enemy and not prev_enemy then
			chara = i_info["<Chara>k__BackingField"]
			storage.summon_inst = chara
			sm_summons[chara] = not shell.summon_hostile
			active_summons[chara] = storage
			em_ui = func.getC(enemy:get_Transform():find("ui020601"):get_GameObject(), "app.ui020601")
			em_ui.IsHostile = true
			
			local hate = chara["<HateSystem>k__BackingField"]
			for i, hate_param in ipairs({hate.HateRecvSetting._CommonParams[11], hate.HateRecvSetting._CommonParams[7], hate.HateRecvSetting._CustomParams._items[0]}) do --chara bias, item bias and custom bias
				hate_param._NormalMax, hate_param._NotForgetMax, hate_param._MaxDistance = 0.01, 0.01, 0.011
			end
			hate.HateRecvSetting._ReactionArizenRate = 0.0
			hate.HateRecvSetting._AutoDistanceParam._ArizenRate = 0.0
			hate.HateRecvSetting._DamageToHate._ArizenRate = 0.0
			hate.HateRecvSetting._MaxDistance = 0.1
			hate.HateRecvSetting._MinDistanceHate = 0.1
			hate.HateRecvSetting._MaxDistanceHate = 0.11
			
			interest_marker = func.getC(enemy, "app.InterestMarkerAutoRequester")
			interest_marker.RequesterData._AttackRequestInfo._PrioltiryValue = 108
			interest_marker.RequesterData._AttackRequestInfo._CheckInfos[0]._TargetCheck.BattleRelationship = 1
			
			local ud_light_sensor = chara:get_LightDarkSensor()
			if ud_light_sensor then ud_light_sensor:set_Enabled(false) end
			if shell.summon_no_dissolve then
				chara.CharaDissolveCtrl["<IsDisableStartDissolve>k__BackingField"] = true
			end
			
			if chara_id_name:find("ch220") then
				chara.CharaEditWarpCtrl:call("buildPartsFromCh220(System.UInt16, System.UInt16, System.UInt16)", 0, 0, 0)
			elseif chara_id_name:find("ch230") then
				chara.CharaEditWarpCtrl:call("buildPartsFromCh230(System.Byte, System.Byte)", math.random(0,255), math.random(0,255))
				local parts = func.getC(enemy, "app.PartSwapper")
				local is_male = parts._Meta._Gender == 2776536455
				local new_top = enums.tops_enum[enums.tops[math.random(1, 101)] ]
				while (is_male and fem_tops[new_top]) do new_top = enums.tops_enum[enums.tops[math.random(1, 101)] ] end
				parts._Meta._TopsStyle = new_top
				local new_pants = enums.pants_enum[enums.pants[math.random(1, 75)] ]
				while (is_male and fem_pants[new_pants]) do new_pants = enums.pants_enum[enums.pants[math.random(1, 75)] ] end
				parts._Meta._PantsStyle = new_pants
				if math.random(1,2) == 1  then parts._Meta._HelmStyle = enums.helms_enum[enums.helms[math.random(1, 91)] ] end
				if math.random(1,2) == 1 then parts._Meta._MantleStyle = enums.mantles_enum[enums.mantles[math.random(1, 54)] ] end
				parts:requestSwap()
				
				--[[local human_enemy = chara["<Human>k__BackingField"].HumanEnemyController
				temp_fns[human_enemy] = function()
					if not human_enemy.JobContext then return end
					temp_fns[human_enemy] = nil 
					local job_id = human_enemy.JobContext.CurrentJob
					local skills = human_enemy.SkillContext.EquipedSkills[job_id].Skills
					if job_id == 1 then
						skills[0] = math.random(0, 12)
						skills[1] = math.random(0, 12)
						skills[2] = math.random(0, 12)
						skills[3] = math.random(0, 12)
					end
					if job_id == 2 then
						skills[0] = math.random(13, 23)
						skills[1] = math.random(13, 23)
						skills[2] = math.random(13, 23)
						skills[3] = math.random(13, 23)
					end
					if job_id == 3 then
						skills[0] = math.random(24, 37)
						skills[1] = math.random(24, 37)
						skills[2] = math.random(24, 37)
						skills[3] = math.random(24, 37)
					end
					if job_id == 4 then
						skills[0] = math.random(38, 49)
						skills[1] = math.random(38, 49)
						skills[2] = math.random(38, 49)
						skills[3] = math.random(38, 49)
					end
					if job_id == 5 then
						skills[0] = math.random(50, 61)
						skills[1] = math.random(50, 61)
						skills[2] = math.random(50, 61)
						skills[3] = math.random(50, 61)
					end
				end]]
			end
			
		elseif em_ui and em_ui.HP then --every frame
			local em_xform = enemy:get_Transform()
			local t_ctrl = chara.EnemyCtrl.Ch2["<TargetController>k__BackingField"]
			storage.summon_pos = em_xform:get_Position()
			storage.num_living_children = storage.num_living_children + 1
			
			if t_ctrl then
				t_ctrl["<TargetType>k__BackingField"] = 9
				temp_fns[t_ctrl] = function() 
					temp_fns[t_ctrl] = nil
					t_ctrl["<TargetType>k__BackingField"] = 9
				end
				if t_ctrl["<TargetCharacter>k__BackingField"] == player then t_ctrl:changeTarget() end
			end
			local hate = chara["<HateSystem>k__BackingField"]
			
			temp_fns[hate] = function()
				temp_fns[hate] = nil
				local copy, inserted = hate._Ranking:MemberwiseClone():add_ref(), 0
				for i, elem in pairs(copy.get_elements and copy:get_elements() or {}) do 
					if elem then 
						if elem["<TargetCharacter>k__BackingField"] ~= player then 
							hate._Ranking[inserted] = elem 
							inserted = inserted + 1
						else
							hate._Ranking[#copy-1] = elem
							elem._TargetHateValue_Distance = 0.0
						end 
					end
				end
			end
			
			if not did_col and not shell.summon_hostile then
				did_col = em_ui.HP:set_ColorScale(Vector4f.new(0,0.25,1,1))
			end
			
			if not did_act and shell.summon_action_idx > 1 then
				did_act = true
				local em_name = enemies_list[shell.summon_idx]:match("(.+) %- ")
				local act_name = enemy_action_names[em_name][shell.summon_action_idx]
				local t_start, tries = game_time, 0
				
				temp_fns.set_summon_action_fn = function()
					temp_fns.set_summon_action_fn = (tries < 10) and temp_fns.set_summon_action_fn or nil -- and not chara["<ActionManager>k__BackingField"].Fsm:getCurrentNodeName(0):find(act_name)
					chara["<ActionManager>k__BackingField"]:requestActionCore(0, act_name, 0)
					local em_nname = chara["<ActionManager>k__BackingField"].Fsm:getCurrentNodeName(0)
					if not em_nname:find("Fall") and not em_nname:find("Land") then tries = tries + 1 end
				end
				temp_fns.set_summon_action_fn()
			end
			
			if chara["<Hit>k__BackingField"]:get_Hp() > 0 then
				em_ui.IsReqDisp = true
				em_ui:set_DrawSelf(true)
				em_ui:set_UpdateSelf(true)
			end
			
			if not did_poof and game_time - storage.summon_start > shell.summon_timer - 0.5 then
				did_poof = true
				shell_mgr:call("requestCreateShell(via.GameObject, via.vec3, via.Quaternion, app.ShellRequest.ShellCreateInfo, app.ShellParamData, app.ShellRequest.EventCreateShellSuccess, app.ShellRequest.EventBeforeShellInstantiate)", 
					player:get_GameObject(), em_xform:get_Position(),  em_xform:get_Rotation(), storage.shell_req, storage.udata, nil, nil)
			end
		end
	end
end

function cast_shell(shell, storage)
	local shellreq = player:call("getComponent(System.Type)", sdk.typeof("app.ShellRequest"))
	local udata_path = user_paths[shell.udata_idx]
	udatas[udata_path] = udatas[udata_path] or sdk.create_userdata("app.ShellParamData", udata_path)
	storage.shell_req = sdk.create_instance("app.ShellRequest.ShellCreateInfo"):add_ref()
	storage.shell_req.ShellParamIdHash = udatas[udata_path].ShellParams._items[shell.shell_id]._ShellParamIdHash
	storage.udata = udatas[udata_path]
	storage.sparam = udatas[udata_path].ShellParams._items[shell.shell_id]
	local ray_pos = (_G.lock_on_target and lock_on_target.lock_pos) or (storage.ray and storage.ray[2])
	local pl_mat = pl_xform:get_WorldMatrix()
	local attach_joint = shell.cast_type == 3 and (pl_xform:getJointByName(shell.joint_name) or pl_xform:getJointByName("Spine_2"))
	local is_ray_type = shell.cast_type == 2 or (shell.cast_type == 3 and (shell.rot_type_idx == 3 or (shell.do_aim_up_down and shell.enemy_soft_lock and (_G.lock_on_target or (ray_pos - pl_mat[3]):dot(pl_mat[2]) >= 5.5) and 1))) --Soft-lock + Aim up/down on 'Player' cast-type will use rays to softlock projectiles to aligned enemies:
	
	if shell.cast_type == 2 then 
		ray_pos = ray_pos + transform_method:call(nil, Vector3f.new(shell.skyfall_dest_offs[1], shell.skyfall_dest_offs[2], shell.skyfall_dest_offs[3]), pl_xform:get_Rotation())
	end
	
	storage.pos = (shell.cast_type == 1 and ray_pos) --Target
		or  (shell.cast_type == 2 and (shell.skyfall_cam_relative and cam_matrix[3] or pl_xform:get_Position())) --Skyfall
		or  (shell.cast_type == 3 and attach_joint:get_Position() + transform_method:call(nil, Vector3f.new(shell.attach_pos[1], shell.attach_pos[2], shell.attach_pos[3]), pl_xform:get_Rotation()))  --Player
		or  (shell.cast_type == 4 and storage.p_instance_pos + transform_method:call(nil, Vector3f.new(shell.attach_pos[1], shell.attach_pos[2], shell.attach_pos[3]), storage.p_instance_rot)) --Prev Shell
		--or  cam_matrix[3] --Camera
	
	if shell.cast_type == 2 then
		local offs = Vector3f.new(shell.skyfall_pos_offs[1], shell.skyfall_pos_offs[2], shell.skyfall_pos_offs[3]) * 1000
		if offs.x ~= offs.z then
			offs.x = (shell.skyfall_random_xz and math.floor(offs.x) ~= 0 and math.random(-math.floor(offs.x), math.floor(offs.x))) or offs.x
			offs.z = (shell.skyfall_random_xz and math.floor(offs.z) ~= 0 and math.random(-math.floor(offs.z), math.floor(offs.z))) or offs.z
		end
		storage.pos = storage.pos + (transform_method:call(nil, offs, shell.skyfall_cam_relative and (camera:get_WorldMatrix()[2] * -1):to_quat() or pl_xform:get_Rotation()) * 0.001)
	end
	
	storage.em_soft_lock_pos = nil
	if shell.enemy_soft_lock then
		storage.em_soft_lock_pos = nearest_enemy_fn(is_ray_type and ray_pos or storage.pos, function(this_dist)
			return this_dist < shell.soft_lock_range
		end)
		if storage.em_soft_lock_pos then
			--if shell.cast_type == 3 or shell.cast_type == 4 then  storage.em_soft_lock_pos = storage.em_soft_lock_pos + transform_method:call(nil, Vector3f.new(shell.attach_pos[1], shell.attach_pos[2], shell.attach_pos[3]), pl_xform:get_Rotation()) end
			if is_ray_type then
				ray_pos = storage.em_soft_lock_pos
			else
				storage.pos = storage.em_soft_lock_pos
			end
		elseif is_ray_type == 1 then
			is_ray_type = false --it's conditional that an enemy must be soft-locked when using up/down ray soft-lock
		end
	end
	
	storage.is_in_range = (pl_xform:get_Position() - storage.pos):length() < sms.maximum_range
	local rot_mat = (is_ray_type and lookat_method:call(nil, storage.pos, ray_pos, Vector3f.new(0,1,0)):inverse()) or (attach_joint and  shell.rot_type_idx < 3 and attach_joint:get_WorldMatrix()) or cam_matrix
	local p_shell_eul = shell.cast_type == 4 and storage.p_instance_rot and storage.p_instance_rot:to_euler()
	
	if attach_joint and not is_ray_type and shell.do_aim_up_down then
		local eul = attach_joint:get_EulerAngle()
		storage.add_cam_rot = Vector3f.new(-(camera:get_GameObject():get_Transform():get_EulerAngle().x * 1.0), eul.y, eul.z)
		rot_mat = euler_to_quat:call(nil, storage.add_cam_rot, 0):to_mat4()
	end
	
	storage.rot = (p_shell_eul and euler_to_quat:call(nil, p_shell_eul, 0)) or (rot_mat[2] * ((cam_matrix==rot_mat or is_ray_type) and -1 or 1)):to_quat():normalized()
	if shell.cast_type == 4 or shell.cast_type == 3 and shell.rot_type_idx <= 2 then
		storage.rot = storage.rot * euler_to_quat:call(nil, Vector3f.new(shell.attach_euler[1], shell.attach_euler[2], shell.attach_euler[3]), 0)
	end
	
	if is_ray_type == 1 then
		storage.add_cam_rot = storage.rot:to_euler()
	end
	
	local base = udatas[udata_path].ShellParams._items[shell.shell_id]._ShellParameterBase.ShellBaseParam
	base.UseScale = table.concat(shell.scale) ~= "1.01.01.0"
	base.Scale = shell.scale[1] > 0 and shell.scale[2] > 0 and shell.scale[3] > 0 and Vector3f.new(shell.scale[1], shell.scale[2], shell.scale[3]) or base.Scale
	base.UseLifeTime = shell.lifetime >= 0
	base.LifeTime = shell.lifetime >= 0 and shell.lifetime or base.LifeTime
	
	if shell.omentime ~= -1 then 
		base.UseOmenPhase = shell.omentime > 0
		base.OmenTime = base.UseOmenPhase and shell.omentime or base.OmenTime
	end
	
	if shell.setland_idx > 1 then
		base.UseSetLand = shell.setland_idx == 3
	end
	
	if shell.summon_idx > 1 then
		local spawn_pos = (shell.cast_type == 3 and shell.rot_type_idx == 3) and ray_pos or storage.pos
		local corrected = p_shell_eul and Vector3f.new(p_shell_eul.x, p_shell_eul.y, 0)
		local closest_em_pos = (table.concat(shell.attach_euler):gsub("%.0", "") == "000") and nearest_enemy_fn(is_ray_type and ray_pos or storage.pos, function(this_dist) return this_dist < 100.0 end, true)
		local lookat_mat = closest_em_pos and spawn_pos ~= closest_em_pos and lookat_method:call(nil, spawn_pos, closest_em_pos, Vector3f.new(0,1,0))
		local eul = lookat_mat and Vector3f.new(0, lookat_mat:inverse():to_quat():to_euler().y + math.pi, 0) or storage.rot:to_euler()
		summon(storage, spawn_pos, euler_to_quat:call(nil, Vector3f.new(0, eul.y, 0), 0))
	end

	if shell.do_teleport_player and (not shell.enemy_soft_lock or storage.em_soft_lock_pos ~= nil) then
		pl_xform:set_Position(storage.pos)
		mot_fns[pl_xform] = function()
			mot_fns[pl_xform] = nil
			pl_xform:set_Position(storage.pos)
		end
		--player["<CharaController>k__BackingField"]:warp() --causes getting stuck in walls
	end
	
	log.info("Generating shell\n	" .. user_paths_short[shell.udata_idx] .. " --> " .. shell.shell_id)
	
	return shell_mgr:call("requestCreateShell(via.GameObject, via.vec3, via.Quaternion, app.ShellRequest.ShellCreateInfo, app.ShellParamData, app.ShellRequest.EventCreateShellSuccess, app.ShellRequest.EventBeforeShellInstantiate)", 
		player:get_GameObject(), storage.pos, storage.rot, storage.shell_req, udatas[udata_path], nil, nil)
end

re.on_application_entry("UpdateMotion", function() 
	for name, fn in pairs(mot_fns) do
		fn()
	end
end)

re.on_script_reset(function()
	cleanup()
	game_time = 0.0
	if player then fix_player() end
	for i, fn in pairs(temp_fns) do fn(true) end
end)

re.on_application_entry("UpdateBehavior", function() 

	timescale_mult = 1 / sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "get_GlobalSpeed")
	delta_time = os.clock() - last_time
	last_time = os.clock()
	if not is_paused then
		skill_delta_time = delta_time * (temp_fns.fix_world_speed and 1.0 or timescale_mult) * ((not player or temp_fns.player_speed_fn) and 1.0 or player.WorkRate:get_Rate()) --account for hitstop and natural slo mo
		game_time = game_time + skill_delta_time
	else
		skill_delta_time = 0.0
	end
	
	local last_pl_xform = pl_xform
	player = chr_mgr:get_ManualPlayer()
	pl_xform = player and player:get_Valid() and player:get_GameObject():get_Transform()
	camera = sdk.get_primary_camera()
	cam_matrix = camera and camera:get_WorldMatrix()
	is_casting = func.get_table_size(casted_spells) > 0 and is_casting
	do_inhibit_all_buttons = is_casting and do_inhibit_all_buttons
	old_cam_dist = (is_casting or temp_fns.fix_cam_dist) and old_cam_dist
	mfsm2 = pl_xform and player["<ActionManager>k__BackingField"].Fsm
	node_name = mfsm2 and mfsm2:getCurrentNodeName(0) or ""
	needs_setup = needs_setup or (pl_xform and not last_pl_xform)
	gamepad_button_guis = mfsm2 and gamepad_button_guis
	is_battling = battle_mgr._BattleMode == 2
	last_loco_time = node_name:sub(1,10) == "Locomotion" and last_loco_time or game_time
	keybinds = keybinds or sdk.get_managed_singleton("app.UserInputManager")["<KeyBindController>k__BackingField"]._KeyBindSettingTables[0]
	
	local hit_prev = selected_shell and hk.check_hotkey("Prev Sel Shell")
	local hit_next = selected_shell and hk.check_hotkey("Next Sel Shell")
	
	if hit_next then
		selected_shell.shell_id = selected_shell.shell_id + 1 
		if selected_shell.shell_id == selected_shell.max_ids then
			selected_shell.udata_idx = selected_shell.udata_idx + 1; if selected_shell.udata_idx > #user_paths then selected_shell.udata_idx = 1 end
			local udata_path = user_paths[selected_shell.udata_idx]
			udatas[udata_path] = udatas[udata_path] or sdk.create_userdata("app.ShellParamData", udata_path)
			selected_shell.max_ids = udatas[udata_path].ShellParams._size
			selected_shell.shell_id = 0
		end
	end
	
	if hit_prev then
		selected_shell.shell_id = selected_shell.shell_id - 1
		if selected_shell.shell_id < 0 then
			selected_shell.udata_idx = selected_shell.udata_idx - 1; if selected_shell.udata_idx < 0 then selected_shell.udata_idx = #user_paths end
			local udata_path = user_paths[selected_shell.udata_idx]
			udatas[udata_path] = udatas[udata_path] or sdk.create_userdata("app.ShellParamData", udata_path)
			selected_shell.max_ids = udatas[udata_path].ShellParams._size
			selected_shell.shell_id = selected_shell.max_ids - 1
		end
	end
	
	if not presets_glob then
		setup_presets_glob()
	end
	
	if not configs_glob then
		configs_glob, configs_glob_short = fs.glob("SkillMaker\\\\[CS][ok][ni][fl][il][gs][se]t?s?\\\\.*json"), {}
		for i, path in ipairs(configs_glob) do
			configs_glob_short[i] = path:match(".+\\(.+)%.json")
		end
		table.insert(configs_glob_short, 1, "[Select Skillset]")
		table.insert(configs_glob, 1, "[Select Skillset]")
	end
	
	is_modifier_down = hk.check_hotkey("Modifier / Inhibit", true)
	is_modifier2_down = hk.check_hotkey("SM Modifier2", true)
	is_cfg_modifier_down = hk.check_hotkey("SM Config Modifier", true)
	do_show_crosshair = (sms.crosshair_type == 2 or (sms.crosshair_type == 3 and is_modifier_down))
	
	for i, config_idx in ipairs(sms.configs) do
		if config_idx ~= 1 and (not sms.load_cfgs_w_modifier or is_modifier_down) and (not sms.load_cfgs_w_cfg_modifier or is_cfg_modifier_down) and hk.check_hotkey("Load Config "..i, 1) then
			load_config(configs_glob[sms.configs[i] ], i)
			was_changed = true
			return nil
		end
	end
	
	if hk.check_hotkey("SM Clean Up") then
		cleanup()
		if temp_fns.fix_cam_dist then temp_fns.fix_cam_dist(true) end
	end
	
	if not mfsm2 or not player:get_Input().PadAssign then-- or is_paused then 
		return nil
	end
	
	local assign_list = player:get_Input().PadAssign.AssignList
	is_sws_down = hk.kb:isDown(keybinds[221844253]._PrimaryKey) or (hk.pad:get_Button() | assign_list[4].Button) == hk.pad:get_Button()
	node_name2 = mfsm2:getCurrentNodeName(1)
	cast_prep_type = 0
	
	if node_name2:find("Ready") or node_name2:find("Prepare") then
		cast_prep_type = is_casting and 2 or 1
		if is_casting and sms.do_swap_lshoulders and hk.gp_state.triggered[256] then --LB
			player["<ActionManager>k__BackingField"]:requestActionCore(0, "DefaultCancelAction", 0)
		end
	end
	
	active_shells = {}
	for name, fn in pairs(temp_fns) do
		fn()
	end
	
	if (was_changed or needs_setup) then
		needs_setup = false
		
		assign_list[32].PreInput = sms.do_shift_sheathe and 15 or 0
		assign_list[33].PreInput = sms.do_shift_sheathe and 15 or 0
		assign_list[57].Action = sms.do_swap_lshoulders and 14 or 60
		assign_list[57].Button = sms.do_swap_lshoulders and 512 or 0
		
		spells_by_hotkeys, spells_by_hotkeys2, spells_by_hotkeys_sws, spells_by_hotkeys_no_sws = {}, {}, {}, {}
		for i, spell_tbl in ipairs(sms.spells) do
			if spell_tbl.enabled and not spell_tbl.hide_ui then
				local hotkey = sms.hotkeys["Use Skill "..i]
				if spell_tbl.state_type_idx == 2 then spells_by_hotkeys[hotkey] = spells_by_hotkeys[hotkey] or i end
				if spell_tbl.use_modifier2 then spells_by_hotkeys2[hotkey] = spells_by_hotkeys2[hotkey] or i end
				if spell_tbl.state_type_idx == 3 then spells_by_hotkeys_sws[hotkey] = spells_by_hotkeys_sws[hotkey] or i end
				if spell_tbl.state_type_idx == 4 then spells_by_hotkeys_no_sws[hotkey] = spells_by_hotkeys_no_sws[hotkey] or i end
			end
		end
		
		for i, config in ipairs(sms.configs) do
			configs_by_hotkeys[sms.hotkeys["Load Config "..i] ] = configs_by_hotkeys[sms.hotkeys["Load Config "..i] ] or i
		end
		
		if not gamepad_button_guis or needs_setup then 
			local ui010201 = scene:call("findGameObject(System.String)", "ui010201"):call("getComponent(System.Type)", sdk.typeof("app.GUIBase"))
			local ui020401 = scene:call("findGameObject(System.String)", "ui020401"); ui020401 = ui020401 and ui020401:call("getComponent(System.Type)", sdk.typeof("app.GUIBase"))
			local gui_get_method = sdk.find_type_definition("via.gui.Control"):get_method("getObject(System.String)")
			
			gamepad_button_guis = ui020401 and {
				face_obj = ui010201:get_GameObject(),
				face_arr = {"Y (Triangle)", "A (X)", "X (Square)", "B (Circle)", "RT (R2)", "RB (R1)", "LT (L2)", "LB (L1)"},
				face_arr_kb = {
					rev_keys_enum[keybinds[2588992438]._PrimaryKey], --up
					rev_keys_enum[keybinds[2595772414]._PrimaryKey], --down
					rev_keys_enum[keybinds[3447232229]._PrimaryKey], --left
					rev_keys_enum[keybinds[2490904261]._PrimaryKey], --right
					rev_keys_enum[keybinds[1444520514]._PrimaryKey], --grab
					rev_keys_enum[keybinds[1147561799]._PrimaryKey], --job-shift
					rev_keys_enum[keybinds[4267829885]._PrimaryKey], --sheathe
				},
				["Y (Triangle)"] = gui_get_method:call(ui010201.Root, "PNL_top/PNL_L02/PNL_txt/mtx_00"),
				["A (X)"] = gui_get_method:call(ui010201.Root, "PNL_top/PNL_R03/PNL_txt/mtx_00"),
				["X (Square)"] = gui_get_method:call(ui010201.Root, "PNL_top/PNL_L03/PNL_txt/mtx_00"),
				["B (Circle)"] = gui_get_method:call(ui010201.Root, "PNL_top/PNL_R02/PNL_txt/mtx_00"),
				["RB (R1)"] = gui_get_method:call(ui010201.Root, "PNL_top/PNL_R01/PNL_txt/mtx_00"),
				["RT (R2)"] = gui_get_method:call(ui010201.Root, "PNL_top/PNL_R00/PNL_txt/mtx_00"),
				["LT (L2)"] = gui_get_method:call(ui010201.Root, "PNL_top/PNL_L00/PNL_txt/mtx_00"),
				["LB (L1)"] = gui_get_method:call(ui010201.Root, "PNL_top/PNL_L01/PNL_txt/mtx_00"),
				dpad_obj = ui020401:get_GameObject(),
				dpad_arr = {"LUp", "LDown", "LLeft", "LRight",},
				dpad_arr_kb = {"Alpha1", "Alpha2", "Alpha3", "Alpha4"},
				["LLeft"] = gui_get_method:call(ui020401.Root, "PNL_Pawncommand/PNL_Leftkey/PNL_txt/mtx_00"),
				["LRight"] = gui_get_method:call(ui020401.Root, "PNL_Pawncommand/PNL_Rightkey/PNL_txt/mtx_00"),
				["LUp"] = gui_get_method:call(ui020401.Root, "PNL_Pawncommand/PNL_Upkey/PNL_txt/mtx_00"),
				["LDown"] = gui_get_method:call(ui020401.Root, "PNL_Pawncommand/PNL_Downkey/PNL_txt/mtx_00"),
			}
		end
		
		check_config_name()
	end

	if (do_inhibit_all_buttons or (is_modifier_down and sms.modifier_inhibits_buttons)) and not temp_fns.fix_buttons then
		local assigns = {}
		for i, assign in pairs(assign_list._items) do
			if assign then assigns[assign] = assign.Button end
		end
		
		assign_list[0].Action, assign_list[1].Action, assign_list[2].Action, assign_list[10].Action = 0, 0, 0, 0
		assign_list[6].Action, assign_list[7].Action, assign_list[8].Action, assign_list[9].Action = 0, 0, 0, 0
		assign_list[19].Action, assign_list[20].Action, assign_list[21].Action, assign_list[22].Action = 0, 0, 0, 0
		assign_list[34].Action, assign_list[35].Action, assign_list[36].Action, assign_list[37].Action = 0, 0, 0, 0
		assign_list[12].Action, assign_list[14].Action, assign_list[18].Action, assign_list[11].Action = 0, 0, 0, 0
		if not node_name2:find("Aim") then 
			assign_list[15].Action = 0 
		end
		
		temp_fns.fix_buttons = temp_fns.fix_buttons or function()
			if not hk.check_hotkey("Modifier / Inhibit", true) and not do_inhibit_all_buttons then
				temp_fns.fix_buttons = nil
				assign_list[0].Action, assign_list[1].Action, assign_list[2].Action, assign_list[10].Action = 1, 2, 3, 4 --default face buttons
				assign_list[6].Action, assign_list[7].Action, assign_list[8].Action, assign_list[9].Action = 7, 8, 9, 10 --shift face button skills
				assign_list[19].Action, assign_list[20].Action, assign_list[21].Action, assign_list[22].Action = 19, 18, 20, 17 --dpad pawn commands
				assign_list[34].Action, assign_list[35].Action, assign_list[36].Action, assign_list[37].Action = 43, 38, 39, 40 --shift dpad shortcuts
				assign_list[12].Action, assign_list[14].Action, assign_list[15].Action, assign_list[18].Action = 5, 29, 11, 16 --grab, job action, aim bow, cam reset
				assign_list[11].Action = 4 --dash (stick push)
				for assign, button in pairs(assigns) do
					assign.Button = button
				end
			end
		end
	end
	
	if sms.do_swap_lshoulders and node_name2:find("Aim") then
		local og_act = assign_list[13].Action
		assign_list[13].Action = 0
		temp_fns.fix_cancel_button = temp_fns.fix_cancel_button or function()
			if not node_name2:find("Aim") or not is_casting then
				temp_fns.fix_cancel_button = nil
				assign_list[13].Action = og_act
			end
		end
	end
	
	assign_list[55].Action = 0 --kill random clones of AttackS and AttackL
	assign_list[56].Action = 0
	
	if assign_list._size > 64 then
		assign_list._size = 64
		assign_list:TrimExcess()
	end
	
	local results = func.cast_ray(cam_matrix[3], cam_matrix[3] + cam_matrix[2] * -10000, 3, 1, 0.2, 0)
	local r_result = results[1]
	if r_result and r_result[1] == player:get_GameObject() then r_result = results[2] end
	ray_result = r_result or func.cast_ray(cam_matrix[3], cam_matrix[3] + cam_matrix[2] * -10000, 2, 0, nil, 0)[1] or {{},(cam_matrix[3] + cam_matrix[2] * -100)}
	
	local should_move_cam = (sms.move_cam_for_crosshair >= 3 and is_casting == 1) or ((sms.move_cam_for_crosshair == 2 or sms.move_cam_for_crosshair == 4) and is_modifier_down)
	
	if should_move_cam or damp_float01._Current < -0.01 then
		damp_float01._Source, damp_float01._Target = damp_float01._Current, should_move_cam and -0.642 or 0.0
		damp_float01:updateParam()
		
		local main_ctrl = cam_mgr._MainCameraControllers[0]
		local added_amt = rotate_yaw_method:call(nil, Vector3f.new(damp_float01._Current, 0, 0), camera:get_GameObject():get_Transform():get_EulerAngle().y + math.pi)
		main_ctrl["<BaseOffset>k__BackingField"] = main_ctrl["<BaseOffset>k__BackingField"] + added_amt
		
		temp_fns.fix_cam_offset = function()
			temp_fns.fix_cam_offset = nil
			main_ctrl["<BaseOffset>k__BackingField"] = Vector3f.new(0, 1.501, -0.043)
		end
	end
	
	local casted_this_frame = {}
	local active_states = {Sprinting=player["<InputProcessor>k__BackingField"].DashSwitch and node_name:find("NormalLocomotion")}
	local is_wp_drawn = player["<SheatheDrawController>k__BackingField"]["<IsDraw>k__BackingField"] --or node_name2:find( "Draw") or node_name2:find( "Sheathe")
	local is_hitbox_frame = false
	local stam_mgr = player:get_StaminaManager()
	
	for i = #sms.spells, 1, -1 do --reversed since people put the hotkeys with more modifiers at the bottom
		local spell_tbl = sms.spells[i]
		local modf_ready = (not spell_tbl.use_modifier2 or is_modifier2_down) and (spell_tbl.state_type_idx ~= 2 or is_modifier_down) 
		local is_forced = forced_spell == i
		
		if not is_paused and (is_forced or (spell_tbl.enabled and modf_ready and not casted_spells[i]) and (hk.check_hotkey("Use Skill "..i, 1) or spell_tbl.do_auto)) then
			local is_correct_vocation = (spell_tbl.job_idx == 1 or player["<Human>k__BackingField"]["<JobContext>k__BackingField"].CurrentJob == spell_tbl.job_idx - 1)
			
			local is_cancelable_ready = (spell_tbl.custom_states == "")
			if not is_cancelable_ready then
				for k, keyword in ipairs(split(spell_tbl.custom_states, ", ?")) do
					local kw = keyword:gsub("`", "")
					is_cancelable_ready = is_cancelable_ready or node_name:find(kw) or node_name2:find(kw)
				end
			end
			
			local is_state_ready = false
			for name, state in pairs(spell_tbl.states) do
				for k, keyword in ipairs(state_keywords[name] or {}) do
					active_states[name] = active_states[name] or node_name:find(keyword)
					is_state_ready = is_state_ready or (state and active_states[name])
				end
			end
			
			if spell_tbl.custom_states:find("`") then
				is_state_ready = is_state_ready or is_cancelable_ready
				is_cancelable_ready = is_cancelable_ready or is_state_ready
			end
			
			local is_anim_ready = (spell_tbl.anim_states == "")
			if not is_anim_ready then
				local mot_info, mot_info2 = player.FullBodyLayer:get_HighestWeightMotionNode(), player.UpperBodyLayer:get_HighestWeightMotionNode()
				local anim_name, anim_name2 = mot_info and mot_info:get_MotionName() or "", mot_info2 and mot_info2:get_MotionName() or ""
				for k, keyword in ipairs(split(spell_tbl.anim_states, ", ?")) do
					local kw = keyword:gsub("`", "")
					is_anim_ready = is_anim_ready or anim_name:find(kw) or anim_name2:find(kw)
				end
			end
			
			if is_forced or (is_correct_vocation and is_cancelable_ready and is_state_ready and is_anim_ready and (spell_tbl.stam_cost == 0 or stam_mgr["<RemainingAmount>k__BackingField"] > 0) and not casted_this_frame[hk.hotkeys["Use Skill "..i] ]) then
				local curr_r_weapon = not is_wp_drawn and "Unarmed" or weapon_types_map[enums.wp_enum[player["<Human>k__BackingField"].PrevRightWeapon]:sub(1,4)]
				local curr_l_weapon = weapon_types_map[enums.wp_enum[player["<Human>k__BackingField"].PrevLeftWeapon]:sub(1,4)]
				local is_correct_weapon = spell_tbl.wp_idx == 1 or (spell_tbl.wp_idx == 2 and curr_r_weapon == "Unarmed") or weapon_types[spell_tbl.wp_idx] == curr_r_weapon or weapon_types[spell_tbl.wp_idx] == curr_l_weapon or (spell_tbl.wp_idx == 14 and curr_l_weapon:find("Bow")) 
					or (spell_tbl.wp_idx == 15 and curr_r_weapon:find("Staff")) or (spell_tbl.wp_idx == 13 and (curr_r_weapon == "Sword" or curr_r_weapon == "Two-Hander" or curr_r_weapon == "Dagger" or curr_r_weapon == "Duospear"))
				local is_basic_ready = (spell_tbl.state_type_idx ~= 4 or not is_sws_down) and (spell_tbl.state_type_idx ~= 3 or is_sws_down)
				local body_frame, upperbody_frame = player.FullBodyLayer:get_Frame(), player.UpperBodyLayer:get_Frame()
				local is_body_frame_ready = (spell_tbl.frame_range[1] == -1.0 or body_frame >= spell_tbl.frame_range[1]) and (spell_tbl.frame_range[2] == -1.0 or body_frame <= spell_tbl.frame_range[2])
				local is_upperbody_frame_ready = (spell_tbl.frame_range_upper[1] == -1.0 or upperbody_frame >= spell_tbl.frame_range_upper[1]) and (spell_tbl.frame_range_upper[2] == -1.0 or upperbody_frame <= spell_tbl.frame_range_upper[2])
				local wep_ready = (not spell_tbl.require_weapon or is_wp_drawn) or is_forced
				
				local hitbox_ready = not spell_tbl.require_hitbox or is_hitbox_frame
				if not hitbox_ready then
					local req_tracks = player:get_SequenceController().TracksList[0].Tracks[sdk.typeof("app.ColliderReqTracks")]
					is_hitbox_frame = is_hitbox_frame or req_tracks.ReqId1 >= 0 or req_tracks.ReqId2 >= 0 or req_tracks.ReqId3 >= 0 or req_tracks.ReqId4 >= 0 or req_tracks.ReqId5 >= 0 or req_tracks.ReqId6 >= 0 or req_tracks.ReqId7 >= 0 or req_tracks.ReqId8 >= 0 or req_tracks.ReqId9 >= 0
					hitbox_ready = is_hitbox_frame
				end
				
				local custom_fn_ready = spell_tbl.activate_fn == ""
				if not custom_fn_ready then
					_G.Player, _G.ActName, _G.ActName2, _G.ActiveSkills = player, node_name, node_name2, active_spells
					_G.Exec = function(spell_name) 
						local spell_idx = func.find_key(sms.last_sel_spells, spell_name)
						if spell_idx then forced_spell = spell_idx end
					end
					_G.Kill = function(spell_name) 
						if active_spells[spell_name] then casted_spells[active_spells[spell_name].idx] = nil end
					end
					local try, output = pcall(load(spell_tbl.activate_fn))
					_G.Player, _G.ActName, _G.ActName2, _G.ActiveSkills, _G.Exec, _G.Kill = nil
					if imgui_spells[i] then imgui_spells[i].error_txt = not try and output end
					custom_fn_ready = try and output
				end
				
				local required_spell_cast = spell_tbl.spell_states == ""
				if not required_spell_cast then
					for n, spell_name in ipairs(split(spell_tbl.spell_states, ", ?")) do
						local sub_state = true
						for s, sub_name in ipairs(split(spell_name, "+")) do
							local found_idx = func.find_key(casted_spells, sub_name:match("(.*)%(") or sub_name, "name")
							sub_state = found_idx and sub_state
							if sub_state then
								local stime = game_time - casted_spells[found_idx].storage.start
								local range = sub_name:match("%((.+)%)"); range = range and split(range, ",")
								sub_state = sub_state and stime >= (range and tonumber(range[1]) or 0.0) and stime <= (range and tonumber(range[2]) or 999999.0)
							end
						end
						required_spell_cast = required_spell_cast or sub_state
					end
				end
				
				if not wep_ready then
					player["<ActionManager>k__BackingField"]:requestActionCore(0, "DrawWeapon", 1)
					goto exit
				elseif is_forced or (required_spell_cast and cast_prep_type == 0 and is_correct_weapon and is_body_frame_ready and is_upperbody_frame_ready and is_basic_ready and hitbox_ready) then
					if not custom_fn_ready then goto exit end
					casted_this_frame[hk.hotkeys["Use Skill "..i] ] = true
					local storage = {
						subbed_stamina = false,
						start = game_time,
						og_start = game_time,
						spell_idx = i,
						idx = i,
					}
					
					if active_states.Falling and spell_tbl.states.Falling then --reset fall on midair cast
						reset_fall_height(3.0)
					end
					
					local hold_start
					local parsed_shells = {}
					for s, shell in ipairs(spell_tbl.shells) do
						if shell.enabled then table.insert(parsed_shells, shell) end
					end
					
					temp_fns["kill_spell"..i] = function()
						if (game_time - storage.start > spell_tbl.duration + 0.25) or (spell_tbl.do_hold_button and not hk.check_hotkey("Use Skill "..i, true)) then --slight delay
							temp_fns["kill_spell"..i] = nil
							casted_spells[i] = nil
							is_casting = next(casted_spells)
							--print("Killed skill", i)
						end
					end
					
					local status_ctrl = player["<StatusConditionCtrl>k__BackingField"]
					local boon_flag = temp_fns[status_ctrl] and 0 or status_ctrl.ActiveStatusConditionFlag
					local boon_time_remain = status_ctrl.NeedUpdateStatusConditionInfoList._items[0]["<ActiveRemainTime>k__BackingField"]
					
					casted_spells[i] = {
						
						name = sms.last_sel_spells[i],
						
						storage = storage,
						
						fn = function(storage)
							is_casting = (spell_tbl.do_move_cam and 1) or true
							
							for s, shell in ipairs(parsed_shells) do
								local store = storage[s]
								local prev_shell = storage[s-1] and parsed_shells[s-1]
								local this_act_name = prev_shell and mfsm2:getCurrentNodeName(storage[s-1].layer_idx):match(".+%.(.+)")
								local is_prep = prev_shell and prev_shell.do_true_hold and this_act_name and (this_act_name:find("Prepare"))
								local is_hold = prev_shell and prev_shell.do_hold and (is_prep or hk.check_hotkey("Modifier / Inhibit", true))
								local same_node = prev_shell and (prev_shell.action_name == this_act_name or prev_shell.action_name:gsub("Prepare", "Ready") == this_act_name)
								local stopped_fn = false
								
								if is_hold and (same_node or is_prep) and game_time - storage.start >= shell.start then
									hold_start = hold_start or game_time
									storage.start = storage.og_start + (game_time - hold_start)
								end
								
								if pressed_cancel then
									casted_spells[i] = nil
									is_casting = next(casted_spells)
									print("Pressed Cancel", i)
									return nil
								elseif not (is_hold and same_node) and not storage[s] and game_time - storage.start >= shell.start and not pressed_cancel then
									do_inhibit_all_buttons = shell.do_inhibit_buttons
									hold_start = nil
									storage[s] = {
										name = s,
										start = game_time, 
										ray = (shell.freeze_crosshair and storage[s-1] and storage[s-1].ray) or ray_result,
										shell = shell,
										spell = spell_tbl,
										pstore = storage[s-1], 
										num_living_children = 1,
										children = {},
										parent = storage,
									}
									
									store = store or storage[s]
									local prev_store = store.pstore
									while prev_store and prev_store.shell.cast_type == 4 and prev_store.shell.do_carryover_prev do
										prev_store = prev_store.pstore
										store.carryover_pstore = prev_store or store.carryover_pstore
									end
									prev_store = store.carryover_pstore or store.pstore
									store.p_instance_pos = prev_store and (prev_store.instance_pos or prev_store.pos)
									store.p_instance_rot = prev_store and (prev_store.instance_rot or prev_store.rot)
									
									if shell.world_speed ~= 1.0 then
										sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "set_GlobalSpeed", shell.world_speed)
										local old_wspeed_fn = temp_fns.fix_world_speed
										
										temp_fns.fix_world_speed = function()
											if not casted_spells[i] or s ~= #storage then
												temp_fns.fix_world_speed = old_wspeed_fn or nil
												sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "set_GlobalSpeed", 1.0)
											else
												sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "set_GlobalSpeed", is_paused and 1.0 or shell.world_speed) 
											end
										end
									end
									
									if shell.do_iframes then
										player["<Hit>k__BackingField"]["<IsInvincible>k__BackingField"] = true
										
										temp_fns.fix_iframes = function()
											if not casted_spells[i] or s ~= #storage then
												temp_fns.fix_iframes = nil
												player["<Hit>k__BackingField"]["<IsInvincible>k__BackingField"] = false
											end
										end
									end
									
									if shell.boon_type ~= 1 then
										status_ctrl:reqStatusConditionApplyCore(shell.boon_type==2 and 15 or shell.boon_type==3 and 16 or 17, nil, nil, false)
										local r_wp_obj = pl_xform:find(enums.wp_enum[player["<Human>k__BackingField"].PrevRightWeapon])
										local l_wp_obj = pl_xform:find(enums.wp_enum[player["<Human>k__BackingField"].PrevLeftWeapon])
										local boon_col, wp_obj2 = table.concat(shell.boon_color) ~= "1.01.01.01.0" and Vector4f.new(shell.boon_color[1], shell.boon_color[2], shell.boon_color[3], shell.boon_color[4])
										for i, child in ipairs(func.get_children(pl_xform)) do 
											if child ~= r_wp_obj and child:get_GameObject():get_Name() == r_wp_obj:get_GameObject():get_Name() then wp_obj2 = child; break end 
										end
										
										temp_fns[status_ctrl] = function()
											if not casted_spells[i] or #storage ~= s then
												temp_fns[status_ctrl] = nil
												status_ctrl:call("reqStatusConditionCure(app.StatusConditionDef.StatusConditionFlag)", shell.boon_type==2 and 32768 or shell.boon_type==3 and 65536 or 131072)
												if ((boon_flag | 32768 == boon_flag) or (boon_flag | 65536 == boon_flag) or (boon_flag | 131072 == boon_flag)) then
													status_ctrl:reqStatusConditionApplyCore((boon_flag | 32768 == boon_flag) and 15 or (boon_flag | 65536 == boon_flag) and 16 or 17, nil, nil, false)
													
													temp_fns[status_ctrl] = function()
														temp_fns[status_ctrl] = nil
														status_ctrl.NeedUpdateStatusConditionInfoList._items[0].ActionList._items[0].ActiveTimer = boon_time_remain
													end
												end
											elseif boon_col then
												col:call(".ctor(via.vec4)", boon_col)
												local pl_children = func.get_children(pl_xform)
												for i, child in ipairs(pl_children) do
													if child:get_GameObject():get_Name() == "effect_ch000000_00" then
														local sparks =  func.getC(child:get_GameObject(), "via.effect.EffectPlayer")
														if sparks and (sparks:get_Resource() or sparks):ToString():find("wp_") then sparks:set_Color(col) end
													end
												end
												for i, wp_obj in pairs({l_wp_obj, r_wp_obj, wp_obj2}) do
													local mesh = func.getC(wp_obj:get_GameObject(), "via.render.Mesh")
													if mesh then
														change_material_float4(mesh, boon_col, "Enchant_Color1")
														change_material_float4(mesh, boon_col, "Enchant_Color2")
													end
													local children = func.get_children(wp_obj) or {}
													local efx_obj, base_amt = pl_xform:find("effect_"..wp_obj:get_GameObject():get_Name()), 0
													if efx_obj then 
														local efx_obj2; for i, child in ipairs(pl_children) do 
															if child ~= efx_obj and child:get_GameObject():get_Name() == efx_obj:get_GameObject():get_Name() then efx_obj2 = child; break end 
														end
														if efx_obj2 then table.insert(children, 1, efx_obj2) end
														table.insert(children, 1, efx_obj) 
														base_amt = 1 + (efx_obj2 and 1 or 0)
													end
													for i, child in ipairs(children) do
														local efx_player = func.getC(child:get_GameObject(), "via.effect.EffectPlayer")
														if i <= base_amt and player["<SheatheDrawController>k__BackingField"]["<IsDraw>k__BackingField"] then efx_player:set_Color(col) end
														for i, param_name in ipairs({"ParticleColor", "BaseColor", "FireColor", "LightningColor"}) do
															local extern = efx_player and efx_player:getExternParameter(param_name); if extern then extern:set_Color(col) end
														end
													end
												end
											end
										end
									end
			
									if shell.camera_dist ~= -1 then
										local pl_cam_settings, dist_name = get_cam_dist_info()
										if pl_cam_settings then
											local timer_start
											
											temp_fns.fix_cam_dist = function(finish)
												old_cam_dist = old_cam_dist or (sms.do_force_cam_dist and 5.5 or pl_cam_settings[dist_name])
												timer_start = timer_start or (not casted_spells[i] or (s ~= #storage)) and game_time
												damp_float02._Source, damp_float02._Target = damp_float02._Current, timer_start and old_cam_dist or shell.camera_dist
												damp_float02:updateParam()
												if timer_start and game_time - timer_start > 3.0 or finish then
													temp_fns.fix_cam_dist = nil
													pl_cam_settings[dist_name] = old_cam_dist
												else
													pl_cam_settings[dist_name] = damp_float02._Current
												end
											end
										end
									end
										
									if shell.anim_speed ~= 1.0 then
										local old_speed_fn = temp_fns.player_speed_fn
										
										temp_fns.player_speed_fn = function()
											temp_fns.player_speed_fn = is_casting and s == #storage and temp_fns.player_speed_fn or nil
											if shell.anim_speed >= 0.0 then
												player.WorkRate.NextRateValue = shell.anim_speed
												player.WorkRate.NextApplyRate = shell.anim_speed
											else
												player.FullBodyLayer:set_Speed(temp_fns.player_speed_fn and shell.anim_speed or 1.0)
												player.UpperBodyLayer:set_Speed(temp_fns.player_speed_fn and shell.anim_speed or 1.0)
											end
											temp_fns.player_speed_fn = temp_fns.player_speed_fn or old_speed_fn
										end
									end
									
									store.action_start = game_time
									
									if shell.turn_idx > 1 then
										turn_fns.turn_player = function()
											turn_fns.turn_player = (shell.do_turn_constantly and is_casting and casted_spells[i] and (s == #storage or (parsed_shells[#storage] and parsed_shells[#storage].do_turn_constantly))) and turn_fns.turn_player or nil
											local cam_yaw = camera:get_GameObject():get_Transform():get_EulerAngle().y + math.pi
											local input_yaw = cam_yaw + (real_rad_l or player:get_Input():get_AngleRadL())
											local pl_soft_lock_pos = shell.do_pl_soft_lock and nearest_enemy_fn(player.Hip:get_Position() + rotate_yaw_method:call(nil, cam_matrix[2] * 3.0, player:get_Input():get_AngleRadL() + math.pi), function(this_dist)
												return  this_dist < 5.0
											end)
											
											if pl_soft_lock_pos then
												store.pl_soft_lock_pos = pl_soft_lock_pos
												local pl_lock_yaw = lookat_method:call(nil, pl_xform:get_Position(), pl_soft_lock_pos, Vector3f.new(0,1,0)):inverse():to_quat():to_euler().y + math.pi 
												if math.abs(pl_lock_yaw - input_yaw) < 2.0 then 
													input_yaw = pl_lock_yaw
												end
											end
											local target_yaw = (shell.turn_idx == 3 and cam_yaw) or input_yaw
											local target_yaw_deg = target_yaw  * 57.2958
											
											if shell.turn_idx == 3 or input_yaw ~= cam_yaw then
												mot_fns.interp_rot = function()
													mot_fns.interp_rot = game_time - store.action_start < 0.2 and mot_fns.interp_rot or nil
													local pl_eul = pl_xform:get_EulerAngle()
													local new_quat = euler_to_quat:call(nil, Vector3f.new(pl_eul.x, target_yaw, pl_eul.z), 0)
													player["<TargetAngleCtrl>k__BackingField"].Move["<AngleDeg>k__BackingField"] = target_yaw_deg
													player["<TargetAngleCtrl>k__BackingField"].Front["<AngleDeg>k__BackingField"] = target_yaw_deg
													pl_xform:set_Rotation(pl_xform:get_Rotation():slerp(new_quat, 0.5 * shell.turn_speed)) 
													
													turn_fns.interp_rot = function()
														turn_fns.interp_rot = nil
														player:setVariableTurnAngleDeg(target_yaw_deg)
														player:set_TargetFrontAngleDeg(target_yaw_deg)
														player:set_TargetMoveAngleDeg(target_yaw_deg)
													end
												end
												mot_fns.interp_rot()
											end
										end
										turn_fns.turn_player()
									end
									
									local node 
									if shell.action_idx > 1 then
										
										local tree = mfsm2:getLayer(0):get_tree_object()
										node = tree:get_node_by_name(shell.action_name)
										local actions = node and node:get_actions()
										if actions and not actions[1] then actions = node:get_unloaded_actions() end	
										
										if not node then 
											store.layer_idx = 1
											tree = mfsm2:getLayer(1):get_tree_object() --UpperBody
											node = tree:get_node_by_name(shell.action_name)
											if node then
												player["<ActionManager>k__BackingField"]:requestActionCore(0, shell.action_name, 1)
												
												temp_fns.set_strafe = shell.do_hold and function()
													if game_time - store.action_start > 0.1 then temp_fns.set_strafe = nil end
													set_node_method:call(mfsm2:getLayer(0), "Locomotion.Strafe", setn, interper)
												end or nil
												
												local concat = table.concat(shell.hold_color)
												if concat ~= "1.01.01.01.0" and concat ~= "1111" and (node:get_name():find("Prepare") or node:get_name():find("Ready")) then
													temp_fns.hold_effect_color_fn = function()
														temp_fns.hold_effect_color_fn = is_casting and temp_fns.hold_effect_color_fn or nil
														local node2 = tree:get_node_by_name(mfsm2:getCurrentNodeName(1):match(".+%.(.+)"))
														local actions2 = node2:get_actions(); if not actions2[1] then actions2 = node2:get_unloaded_actions() end
														local action2 = actions2[5] and actions2[5].EffectElementID and actions2[5] or actions2[2]
														
														if action2 and action2.Effect and action2.Effect.CreatedEffects._entries[0].value then
															if node2:get_name():find("Ready") then temp_fns.hold_effect_color_fn = nil end
															local effect = action2.Effect.CreatedEffects._entries[0].value._items[0]
															col:call(".ctor(via.vec4)", Vector4f.new(shell.hold_color[1], shell.hold_color[2], shell.hold_color[3], shell.hold_color[4]))
															effect:getExternParameters(1):set_Color(col)
															effect:getExternParameters(2):set_Color(col)
															effect:getExternParameters(3):set_Color(col)
															effect:set_Color(col)
														end
													end
													temp_fns.hold_effect_color_fn()
												end
											end
										else
											store.layer_idx = 0
											actions = node:get_actions(); if not actions[1] then actions = node:get_unloaded_actions() end
											if shell.do_simplify_action then
												for a, action in ipairs(actions) do action:set_Enabled(a==1) end
											end
											player["<ActionManager>k__BackingField"]:requestActionCore(0, shell.action_name, 0)
										end
										
										if node then
											local splitted_cmotion = shell.custom_motion ~= "" and split(shell.custom_motion, ", ?")
											if splitted_cmotion then
												local layer = splitted_cmotion[4] == 1 and player.UpperBodyLayer or player.FullBodyLayer
												if tonumber(splitted_cmotion[1]) then
													local ticks = 0
													mot_fns.change_frame = function()
														mot_fns.change_frame = temp_fns[node] and ticks < 1 and mot_fns.change_frame or nil
														ticks = ticks + 1
														local mnode = layer:get_HighestWeightMotionNode()
														if mnode then
															layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
																mnode:get_MotionBankID(), mnode:get_MotionID(), tonumber(splitted_cmotion[1]) or layer:get_Frame(), tonumber(splitted_cmotion[3]) or 20.0, 2, 0)
														end
													end
												elseif #splitted_cmotion >= 3 then
													if splitted_cmotion[1]:find("motlist") then
														add_dynamic_motionbank(player:get_Motion(), splitted_cmotion[1], tonumber(splitted_cmotion[2]))
													end
													if actions then actions[1]:set_Enabled(false) end
													
													temp_fns.change_motion = function()
														temp_fns.change_motion = nil
														layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
															tonumber(splitted_cmotion[2]), tonumber(splitted_cmotion[3]), tonumber(splitted_cmotion[5]) or 0.0, tonumber(splitted_cmotion[6]) or 20.0, 2, 0)
													end
												end
											end
											
											storage.last_node_name = node:get_full_name()
											local layer = store.layer_idx==0 and player.FullBodyLayer or player.UpperBodyLayer
											
											temp_fns[node] = function()
												local nname = mfsm2 and mfsm2:getCurrentNodeName(store.layer_idx)
												temp_fns[node] = nname and temp_fns[node]
												if nname and game_time - store.action_start > 0.1 and nname:match(".+%.(.+)") ~= node:get_name() then
													temp_fns[node] = nil
													for a, action in ipairs(actions or {}) do action:set_Enabled(true) end
													local is_current_node = s == #storage
													local is_damaged = node_name:find("Damage") and not storage.last_node_name:find("Damage")
													--local has_landed = node_name:find("Landing$") and not storage.last_node_name:find("Landing$")
													layer:set_MirrorSymmetry(false)
													
													if is_damaged or pressed_cancel or (store.layer_idx == 1 and is_current_node and (not shell.do_hold or (nname:gsub("Ready", "Prepare"):match(".+%.(.+)") ~= node:get_name() and not nname:find("Shoot")))) then
														casted_spells = {} --cancel spells due to interruption
														print("Cancelled skills", i)
														is_casting = false
														if mfsm2:getCurrentNodeName(0) == "Locomotion.Strafe" then
															player["<ActionManager>k__BackingField"]:requestActionCore(0, "NormalLocomotion", 0)
														end
													end
												end
											end
										end
									end
									
									if shell.do_mirror_action or shell.do_mirror_wp then
										local paired_fn = temp_fns[node or 0]
										local mirror_st = shell.mirror_time > -1 and game_time
										local layer = store.layer_idx==1 and player.UpperBodyLayer or player.FullBodyLayer
										
										mot_fns.mirror_fn = function()
											local should_run = not mirror_st and casted_spells[i] and (temp_fns[node or 0]==paired_fn or s == #storage) or mirror_st and (game_time - mirror_st < shell.mirror_time) 
											mot_fns.mirror_fn = should_run and mot_fns.mirror_fn or nil
											layer:set_MirrorSymmetry(shell.do_mirror_action and not not mot_fns.mirror_fn)
											
											if mot_fns.mirror_fn and shell.do_mirror_wp then
												local l_wp_a, l_wp_b = pl_xform:getJointByName("L_PropA"), pl_xform:getJointByName("L_PropB")
												local r_wp_a, r_wp_b = pl_xform:getJointByName("R_PropA"), pl_xform:getJointByName("R_PropB")
												local l_wp_a_pos, l_wp_a_rot = l_wp_a:get_Position(), l_wp_a:get_Rotation()
												local l_wp_b_pos, l_wp_b_rot = l_wp_b:get_Position(), l_wp_b:get_Rotation()
												l_wp_a:set_Position(r_wp_a:get_Position()); l_wp_a:set_Rotation(r_wp_a:get_Rotation())
												r_wp_a:set_Position(l_wp_a_pos); r_wp_a:set_Rotation(l_wp_a_rot)
												l_wp_b:set_Position(r_wp_b:get_Position()); l_wp_b:set_Rotation(r_wp_b:get_Rotation())
												r_wp_b:set_Position(l_wp_b_pos); r_wp_b:set_Rotation(l_wp_b_rot)
											end
										end
									end
									
									if shell.udata_idx > 1 and casted_spells[i] then
										if not storage.subbed_stamina then
											storage.subbed_stamina = true
											stam_mgr["<RemainingAmount>k__BackingField"] = stam_mgr["<RemainingAmount>k__BackingField"] - spell_tbl.stam_cost
										end
										store.req_id = cast_shell(shell, store) --fire the shell
									end
									
									local died, did_velocity, had_fn = false, false
									beh_fns[store] = function() -- manage every frame
										died = store.num_living_children == 0 and (died and 1 or true) or false
										if died == 1 and not casted_spells[i] then beh_fns[store] = nil end --kill after 2 frames of no children
										store.num_living_children = 0
										store.final_instance = store.children[#store.children] or (store.instance and store.instance["<Shell>k__BackingField"]) --we only want the position of the final child shell
										local prev_store = (store.carryover_pstore or store.pstore)

										if store.final_instance and store.final_instance:get_Valid() then
											local xform = store.final_instance:get_GameObject():get_Transform()
											store.instance_pos = xform:get_Position()
											store.instance_rot = xform:get_Rotation()
											store.hit_substance = store.final_instance.HitSubstance or store.final_instance["<TerrainHitResult>k__BackingField"]
										end
										store.instance_pos = store.summon_pos or store.instance_pos --sm_summons just override shells for now
										store.p_instance_pos = prev_store and prev_store.instance_pos
										store.p_instance_rot = prev_store and prev_store.instance_rot
										
										if s == #storage and shell.pl_velocity_type > 1 then
											local pl_pos = pl_xform:get_Position()
											local shell_pos = store.pos or store.p_instance_pos
											local cam_eul = shell.pl_velocity_type == 6 and camera:get_GameObject():get_Transform():get_EulerAngle()
											local input_rot = cam_eul and euler_to_quat:call(nil, Vector3f.new(cam_eul.x, cam_eul.y + math.pi + (real_rad_l or player:get_Input():get_AngleRadL()), cam_eul.z), 0)
											local em_pos = store.pl_soft_lock_pos
											if shell.pl_velocity_type ~= 7 or (em_pos and (em_pos - pl_pos):length() > 1.33) then
												local base_rot = input_rot or ((shell.pl_velocity_type == 2) and pl_xform:get_Rotation()) or (shell.pl_velocity_type == 5 and (cam_matrix[2] * -1):to_quat())
													or (lookat_method:call(nil, pl_pos, (shell.pl_velocity_type == 4 and shell_pos ~= pl_pos and shell_pos) or em_pos or store.ray[2], Vector3f.new(0,1,0))[2] * -1):to_quat():conjugate()
												if shell.do_constant_speed then
													local mat = base_rot:to_mat4()
													pl_xform:set_Position(pl_xform:get_Position() + ((mat[2] * shell.pl_velocity[3]) + (mat[1] * shell.pl_velocity[2]) + (mat[0] * shell.pl_velocity[1])) * skill_delta_time * timescale_mult)
												elseif not did_velocity then
													did_velocity = true
													reset_fall_height(0.5)
													player["<FreeFallCtrl>k__BackingField"]:call("startWithFrame(via.vec3, System.Single)", transform_method:call(nil, Vector3f.new(shell.pl_velocity[1], shell.pl_velocity[2], shell.pl_velocity[3]), base_rot), -9.8)
												end
											end
										end
										
										if shell.custom_fn ~= "" and not stopped_fn then
											_G.Node = store
											_G.Skill = storage
											_G.Player = player
											_G.Summon = store.summon_inst
											_G.Shell = store.final_instance
											_G.ActName = node_name
											_G.ActName2 = node_name2
											_G.ActiveSkills = active_spells
											_G.GameTime = game_time
											_G.ReachedEnemy = function(dist) return store.pl_soft_lock_pos and ((store.pl_soft_lock_pos - pl_xform:get_Position()):length() <= (dist or 1.33)) end
											_G.Hold = function() if s == #storage then storage.start = storage.start + skill_delta_time end end
											_G.ActiveSummons = active_summons
											_G.RepeatNode = function() 
												storage[s], beh_fns[store] = nil 
												storage.start = storage.start + skill_delta_time
											end
											_G.Stop = function() stopped_fn = true end
											_G.Exec = function(spell_name) 
												local spell_idx = func.find_key(sms.last_sel_spells, spell_name)
												if spell_idx then forced_spell = spell_idx end
											end
											_G.Kill = function(spell_name) 
												if spell_name then
													if active_spells[spell_name] then casted_spells[active_spells[spell_name].idx] = nil end
												else
													casted_spells[i] = nil 
												end
											end
											local try, out = pcall(load(shell.custom_fn))
											_G.Node, _G.Skill, _G.Player, _G.Summon, _G.Shell, _G.ActName, _G.ActName2, _G.ActiveSkills, _G.GameTime, _G.ReachedEnemy, _G.Hold, _G.ActiveSummons, _G.RepeatNode, _G.Stop, _G.Exec, _G.Kill = nil
											local imgui_shell = imgui_spells[i] and imgui_spells[i].shell_datas[s]
											if imgui_shell then imgui_shell.error_txt = not try and out end
										end
									end
									beh_fns[store]()
									
								elseif store and not store.instance then --manage the current shell
									store.instance = store.req_id and shell_mgr["<InstantiatedShellDict>k__BackingField"][store.req_id]
									local imgui_shell = imgui_spells[i] and imgui_spells[i].shell_datas[s]
									if imgui_shell then 
										imgui_shell.last_store = store
									end
									
									local found_shell_inst = store.instance and store.instance["<Shell>k__BackingField"]
									if found_shell_inst then
										local function make_temp_fn(shell_inst, is_child)
											
											local work_rate = func.getC(shell_inst:get_GameObject(), "app.WorkRate")
											local xform = shell_inst:get_GameObject():get_Transform()
											local pl_joint = pl_xform:getJointByName(shell.joint_name)
											local add_param_ids = {}
											local rot_euler = store.rot:to_euler()
											store.add_param_ids = add_param_ids
											
											--Find child shells
											for a, aparam in pairs(store.sparam._ShellAdditionalParameter._items) do
												local id_hashlist = {aparam._ShellParamIDHash}
												local arr = aparam._ShellGeneratorConditionInfos or aparam._ShellGeneratorTimerInfos
												
												for e, element in pairs(arr and arr._items or {}) do
													table.insert(id_hashlist, element._ShellIDHash)
												end
												
												for h, hash in ipairs(id_hashlist) do 
													add_param_ids[hash] = shell
													local aparam_idx = func.find_key(store.udata.ShellParams._items, hash, "_ShellParamIdHash")
													if aparam_idx then 
														local aparam2 = store.udata.ShellParams._items[aparam_idx]
														local base = aparam2._ShellParameterBase.ShellBaseParam
														base.UseScale = table.concat(shell.scale) ~= "1.01.01.0"
														base.Scale = shell.scale[1] > 0 and shell.scale[2] > 0 and shell.scale[3] > 0 and Vector3f.new(shell.scale[1], shell.scale[2], shell.scale[3]) or base.Scale --set child shell udata settings
														base.UseLifeTime = shell.lifetime >= 0
														base.LifeTime = shell.lifetime
														if shell.omentime ~= -1 then 
															base.UseOmenPhase = shell.omentime > 0
															base.OmenTime = base.UseOmenPhase and shell.omentime or base.OmenTime
														end
														if shell.setland_idx > 1 then
															base.UseSetLand = shell.setland_idx == 3
														end
													end
												end
											end
											
											local efx2 = shell_inst["<EffectManager2>k__BackingField"]
											col:call(".ctor(via.vec4)", Vector4f.new(shell.coloring[1], shell.coloring[2], shell.coloring[3], shell.coloring[4]))
											for i, c_effect_data in ipairs(efx2.CreatedEffectDataList._items:get_elements()) do
												for i, c_effect in ipairs(c_effect_data.list._items.get_elements and c_effect_data.list._items:get_elements() or {}) do
													if not shell.do_vfx then 
														c_effect:killAllInternal()
													else
														c_effect:setRootColor(col)
													end
												end
											end
											
											local elements = {}
											for id, std_data in pairs(efx2.StandardDataMap._entries and func.lua_get_dict(efx2.StandardDataMap, true) or {}) do
												for e, element in pairs(std_data.Elements._items.get_elements and std_data.Elements._items or {}) do
													elements[element] = element.Color
													element.Color = col
												end
											end
											
											temp_fns[efx2] = function()
												if not casted_spells[i] then
													temp_fns[efx2] = nil
													for element, color in pairs(elements) do
														element.Color = white --color
													end
												end
											end
											
											if not shell.do_vfx then
												if shell_inst["<Mesh>k__BackingField"] then shell_inst["<Mesh>k__BackingField"]:set_Enabled(false) end
												efx2:call(".cctor()") 
												efx2:call(".ctor()") 
											end
											
											if not shell.do_sfx then 
												local go, wwise = shell_inst:get_GameObject(), shell_inst["<WwiseContainer>k__BackingField"]
												for i, entry in pairs(func.lua_get_array(wwise._TriggerInfoList._items, true)) do
													if entry then wwise:stopTriggered(entry._TriggerId, go, 0.0) end
												end
												shell_inst["<WwiseContainer>k__BackingField"]:call(".cctor()") 
												shell_inst["<WwiseContainer>k__BackingField"]:call(".ctor()") 
											end
											
											if shell.is_decorative then
												shell_inst["<ColliderStep>k__BackingField"] = 99999
											--	shell_inst["<HitCtrl>k__BackingField"]:set_Enabled(false)
											--	shell_inst["<HitCtrl>k__BackingField"]["<CachedRequestSetCollider>k__BackingField"]:set_Enabled(false)
											end
											
											--if shell.enchant_type > 1 then 
											--	shell_inst["<EnchantElementType>k__BackingField"] = shell.enchant_type - 2
											--end
											
											local attached_only_once = false
											local cant_search_children = false
											
											--manage the current shell's speed and damage every frame
											temp_fns[shell_inst] = function() 
												temp_fns[shell_inst] = shell_inst:get_Valid() and game_time - storage.start < sms.shell_lifetime_limit and (shell.lifetime ~= -2.0 or (#storage <= s+1)) and temp_fns[shell_inst] or nil
												store.num_living_children = store.num_living_children + 1
												
												if temp_fns[shell_inst] then
													active_shells[shell_inst] = store
													cant_search_children = cant_search_children or (casted_spells[i] == nil) or (s ~= #storage and storage[s+1])
													shell_inst["<HitCtrl>k__BackingField"]["<AttackRate>k__BackingField"] = store.is_in_range and (shell.attack_rate * spell_tbl.damage_multiplier) or 0 
													work_rate.NextRateValue = shell.speed
													work_rate.NextApplyRate = shell.speed
													
													if not is_child then
														if pl_joint and not attached_only_once and shell.cast_type == 3 then
															attached_only_once = not shell.attach_to_joint or (shell.rot_type_idx == 3)
															shell.attach_pos = shell.attach_pos or {0,0,0}
															xform:set_Position(pl_joint:get_Position() + transform_method:call(nil, Vector3f.new(shell.attach_pos[1], shell.attach_pos[2], shell.attach_pos[3]), shell.rot_type_idx == 1 and pl_joint:get_Rotation() or pl_xform:get_Rotation()))
															if not shell.do_no_attach_rotate then
																if store.add_cam_rot then 
																	xform:set_EulerAngle(store.add_cam_rot + Vector3f.new(shell.attach_euler[1], shell.attach_euler[2], shell.attach_euler[3])) -- 
																elseif shell.rot_type_idx == 3 then
																	xform:set_EulerAngle(rot_euler + Vector3f.new(shell.attach_euler[1], shell.attach_euler[2], shell.attach_euler[3])) -- 
																elseif shell.rot_type_idx == 2 then
																	local pl_eul = pl_xform:get_EulerAngle() 
																	xform:set_EulerAngle(Vector3f.new(shell.attach_euler[1] + pl_eul.x, shell.attach_euler[2] + pl_eul.y, shell.attach_euler[3] + pl_eul.z))
																elseif shell.rot_type_idx == 1 then
																	xform:set_EulerAngle(pl_joint:get_EulerAngle() + Vector3f.new(shell.attach_euler[1], shell.attach_euler[2], shell.attach_euler[3])) -- 
																end
															end
														elseif shell.cast_type == 4 and store.p_instance_pos then
															if not attached_only_once then
																local eul = store.p_instance_rot:to_euler()
																xform:set_Position(store.p_instance_pos + transform_method:call(nil, Vector3f.new(shell.attach_pos[1], shell.attach_pos[2], shell.attach_pos[3]), store.p_instance_rot))
																local new_eul = Vector3f.new(eul.x, eul.y, 0) + Vector3f.new(shell.attach_euler[1], shell.attach_euler[2], shell.attach_euler[3])
																xform:set_EulerAngle(new_eul)
																shell_inst["<MoveVector>k__BackingField"] = Vector3f.new(math.cos(new_eul.x) * math.sin(new_eul.y), -math.sin(new_eul.x), math.cos(new_eul.x) * math.cos(new_eul.y))
															end
															attached_only_once = (shell.pshell_attach_type == 1) or (shell.pshell_attach_type == 3 and (store.carryover_pstore or store.pstore).hit_substance)
														end
													end
													
													if not cant_search_children then
														local slist_copy = func.lua_get_array(shell_mgr.ShellList._items)
														
														for param_hash, shell_tbl in pairs(add_param_ids) do
															local idx = func.find_key(slist_copy, param_hash, "<ShellParamId>k__BackingField")
															while idx do
																local child_shell = slist_copy[idx]
																slist_copy[idx] = nil
																idx = func.find_key(slist_copy, param_hash, "<ShellParamId>k__BackingField")
																
																if not temp_fns[child_shell] and child_shell["<RequestId>k__BackingField"] > store.req_id and (s == #storage or (storage[s+1] and storage[s+1].cast_type ~= 4)) then 
																	table.insert(store.children, child_shell)
																	make_temp_fn(child_shell, true)
																	temp_fns[child_shell]()
																end
															end
														end
													end
												elseif shell_inst:get_Valid() then
													shell_inst:get_GameObject():destroy(shell_inst:get_GameObject())
												end
											end
											temp_fns[shell_inst]()
										end
										make_temp_fn(found_shell_inst)
									end
								end
							end
						end
					}
				end
			end
		end
	end
	
	::exit::
	active_spells = {}
	local tmp_spells = {}; 
	for idx, tbl in pairs(casted_spells) do 
		tbl.name = sms.last_sel_spells[idx] or "Skill "..idx 
		tbl.idx = idx
		active_spells[tbl.name] = tbl
		tmp_spells[idx] = tbl 
	end 
	for idx, cast_spell_tbl in pairs(tmp_spells) do
		cast_spell_tbl.fn(cast_spell_tbl.storage)
	end
	pressed_cancel = false
	forced_spell = nil
end)

re.on_pre_application_entry("UpdateBehavior", function() 
	if ui_mod_down and undo[undo.idx-1] and hk.check_hotkey("Undo") then
		was_changed = 1
		undo.idx = undo.idx - 1
		sms = hk.recurse_def_settings({}, undo[undo.idx])
		for i, imgui_data in pairs(imgui_spells) do imgui_data.tmp = {} end
	end
	if ui_mod_down and undo[undo.idx+1] and hk.check_hotkey("Redo") then
		was_changed = 1
		undo.idx = undo.idx + 1
		sms = hk.recurse_def_settings({}, undo[undo.idx])
		for i, imgui_data in pairs(imgui_spells) do imgui_data.tmp = {} end
	end

	for name, fn in pairs(beh_fns) do
		fn()
	end
end)

re.on_application_entry("LateUpdateBehavior", function() 
	if was_changed then
		hk.update_hotkey_table(sms.hotkeys)
		json.dump_file("SkillMaker\\SkillMaker.json", sms)
		imgui2.data = {} --clear temp values
		
		if was_changed ~= 1 then
			local not_dragged = not imgui.is_mouse_down()
			
			temp_fns.set_undo = function()
				if not_dragged or imgui.is_mouse_released() then
					temp_fns.set_undo = nil
					undo.idx = undo.idx + 1
					table.insert(undo, undo.idx, hk.recurse_def_settings({}, sms))
					while undo[undo.idx+1] do table.remove(undo, undo.idx+1) end
					if #undo > 100 then 
						undo.idx = undo.idx - 1
						table.remove(undo, 1)
					end
				end
			end
			temp_fns.set_undo()
		end
		was_changed = false
	end
	
	if sms.ingame_ui_buttons and sms.modifier_inhibits_buttons and gamepad_button_guis and gamepad_button_guis.face_obj:get_DrawSelf() then	
		local hotkey_arr =  hk.buttons[sms.hotkeys["Modifier / Inhibit"] ] and gamepad_button_guis.face_arr or gamepad_button_guis.face_arr_kb
		gamepad_button_guis.face_obj:set_DrawSelf(true)
		gamepad_button_guis.face_obj:set_UpdateSelf(true)
		local swap_cancel_prep = sms.do_swap_lshoulders and cast_prep_type == 2
		
		for j, hotkey_str in ipairs(gamepad_button_guis.face_arr) do
			local hotkey = hotkey_arr[j]
			local cfg_idx = configs_by_hotkeys[hotkey]
			local spell_idx = (is_modifier2_down and ((is_modifier_down and spells_by_hotkeys2[hotkey]) or (is_sws_down and spells_by_hotkeys_sws[hotkey]) or (not is_sws_down and spells_by_hotkeys_no_sws[hotkey]))) 
				or (is_modifier_down and (((is_sws_down and spells_by_hotkeys_sws[hotkey]) or (not is_sws_down and spells_by_hotkeys_no_sws[hotkey])) or ((spells_by_hotkeys[hotkey] and not sms.spells[spells_by_hotkeys[hotkey] ].use_modifier2) and spells_by_hotkeys[hotkey])))
				or (is_sws_down and spells_by_hotkeys_sws[hotkey]) or (not is_sws_down and spells_by_hotkeys_no_sws[hotkey])
			local txt_obj = gamepad_button_guis[hotkey_str]
			local panel = txt_obj:get_Parent()
			local old_col, old_button_col, old_cs
			
			if hotkey_str == sms.hotkeys["Modifier / Inhibit"] then
				local msg = cast_prep_type == 1 and sms.do_swap_lshoulders and "Cancel" or (hk.gp_state.down[256] and not is_modifier_down and sms.do_shift_sheathe and "Sheathe/Draw") or ((sms.last_config and sms.last_config.has_config_name and (sms.last_config.name.." Skill"))) or "Skill Maker" 
				txt_obj:set_Message("<COLOR preset=\"arrow\"></COLOR>"..msg)
				if is_modifier_down then 
					old_cs = {Vector4f.new(1,1,1,1), Vector3f.new(0,0,0)}
				end
				old_col = txt_obj:get_Color()
				if cast_prep_type then txt_obj:set_Visible(true) end
			elseif hotkey_str == sms.hotkeys["SM Modifier2"] and (is_modifier_down or swap_cancel_prep) then
				txt_obj:set_Message("<COLOR preset=\"arrow\"></COLOR>"..((swap_cancel_prep and "Cancel") or (is_modifier_down and ((sms.last_config and sms.last_config.has_config_name and ("Switch "..sms.last_config.name.." Skill")) or "Switch SM Skill"))))
				txt_obj:set_Visible(true)
				old_col = txt_obj:get_Color()
				if is_modifier2_down then 
					old_cs = {Vector4f.new(1,1,1,1), Vector3f.new(0,0,0)}
				end
			elseif cfg_idx and sms.configs[cfg_idx] > 1 and (not sms.load_cfgs_w_modifier or is_modifier_down) and (not sms.load_cfgs_w_cfg_modifier or is_cfg_modifier_down) then
				local txt = configs_glob_short[sms.configs[cfg_idx] ]
				txt = "["..(txt:match(".+ %- (.+)") or txt:match(".+%\\(.+)") or txt):gsub("_", " ").."]"
				txt_obj:set_Message("<COLOR preset=\"arrow\"></COLOR>"..txt)
				txt_obj:set_Visible(true)
				old_cs = hk.gp_state.down[hk.buttons[hotkey_str] ] and {Vector4f.new(1,1,1,1), Vector3f.new(0,0,0)}
				old_col = txt_obj:get_Color()
			elseif (spell_idx and ((is_modifier_down and spells_by_hotkeys[hotkey]) or (is_sws_down and spells_by_hotkeys_sws[hotkey]) or (not is_sws_down and spells_by_hotkeys_no_sws[hotkey]))) or (not spell_idx and sms.modifier_inhibits_buttons and is_modifier_down) then
				local txt = not spell_idx and " " or sms.last_sel_spells[spell_idx] ~= "" and sms.last_sel_spells[spell_idx] or (spell_idx and "Skill "..spell_idx) or " " --txt_obj:get_Message()
				txt = (txt:match(".+ %- (.+)") or txt:match(".+%\\(.+)") or txt):gsub("_", " ")
				old_cs = casted_spells[spell_idx] and {Vector4f.new(1,1,1,1), Vector3f.new(0,0,0)}--{panel:get_ColorScale(), panel:get_ColorOffset()}
				old_col = txt_obj:get_Color()
				txt_obj:set_Message("<COLOR preset=\"arrow\"></COLOR>"..txt)
				txt_obj:set_Visible(true)
			end

			if old_cs or old_col then 
				if old_col then 
					col.rgba = 0x8FFFFFFF
					txt_obj:set_Color(col) 
					old_button_col = txt_obj:get_Parent():get_Next():get_Color()
					txt_obj:get_Parent():get_Next():set_Color(col)
				end
				if old_cs then 
					panel:set_ColorScale(Vector4f.new(4,4,4,4)) 
					panel:set_ColorOffset(Vector3f.new(15,14,10))
				end
				temp_fns[panel] = function()
					temp_fns[panel] = nil
					if old_col then 
						txt_obj:set_Color(old_col)
						txt_obj:get_Parent():get_Next():set_Color(old_button_col)
					end
					if old_cs then 
						panel:set_ColorScale(old_cs[1])
						panel:set_ColorOffset(old_cs[2])
					end
				end
			end
		end
	end
end)

re.on_frame(function()
	math.randomseed(math.floor(os.clock()*100))
	ui_mod_down = reframework:is_drawing_ui() and (hk.check_hotkey("UI Modifier", true) or ((imgui.is_mouse_down() or imgui.is_mouse_released() or imgui.is_mouse_clicked()) and ui_mod_down))
	
	if ray_result and do_show_crosshair then
		local pos_2d = draw.world_to_screen(ray_result[2])
		if pos_2d then draw.filled_circle(pos_2d.x, pos_2d.y, 2.5, 0xAAFFFFFF, 0) end
		
		for idx, cast_tbl in pairs(casted_spells) do
			local current = cast_tbl.storage[#cast_tbl.storage]
			if current and current.shell.freeze_crosshair and current.shell.cast_type <= 2 and current.shell.udata_idx > 1 then
				local pos_2d = draw.world_to_screen(current.ray[2])
				if pos_2d then draw.filled_circle(pos_2d.x, pos_2d.y, 2.5, 0xFF0000FF, 0) end
			end
		end
	end
	
	if reframework:is_drawing_ui() then
		if not sms.use_window or imgui.begin_window("Skill Maker", true, 0) == false then 
			sms.use_window = false
		else
			imgui.push_id(91724)
			display_mod_imgui(true)
			imgui.pop_id()
			imgui.end_window()
		end
	end
	
	is_paused = true
end)

re.on_draw_ui(function()
	if imgui.tree_node("Skill Maker") then
		display_mod_imgui()
		imgui.tree_pop()
	end
end)

sdk.hook(sdk.find_type_definition("app.CharacterInput"):get_method("set_AxisL"), function(args)
    is_paused, real_rad_l = sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "get_GlobalSpeed") < 0.01
	if do_inhibit_all_buttons then 
		real_rad_l = sdk.to_valuetype(args[3], "via.vec2")
		real_rad_l = -math.atan(math.floor(real_rad_l.x * 10 + 0.5)/10,  math.floor(real_rad_l.y * 10 + 0.5)/10)-- - math.pi
		args[3] = sdk.to_ptr(ValueType.new(sdk.find_type_definition("via.vec2")):get_address())
	end
end)

sdk.hook(sdk.find_type_definition("app.HumanStaminaController"):get_method("Chara_OnConsumeStaminaHandler"), function(args)
    if is_casting and game_time - last_loco_time < 1.0 then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end)

sdk.hook(sdk.find_type_definition("app.StaminaManager"):get_method("add"), function(args)
    if is_casting and game_time - last_loco_time < 1.0 then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end)

sdk.hook(sdk.find_type_definition("app.ui020401"):get_method("update"), 
	function(args)
		for name, fn in pairs(ui_fns) do
			fn()
		end
	end,
	function(retval)
		if sms.ingame_ui_buttons and sms.modifier_inhibits_buttons and gamepad_button_guis and is_modifier_down and gamepad_button_guis.face_obj:get_DrawSelf() then
			gamepad_button_guis.dpad_obj:set_DrawSelf(true)
			gamepad_button_guis.dpad_obj:set_UpdateSelf(true)

			local hotkey_arr = hk.buttons[sms.hotkeys["Modifier / Inhibit"] ] and gamepad_button_guis.dpad_arr or gamepad_button_guis.dpad_arr_kb
			for j, hotkey_str in ipairs(gamepad_button_guis.dpad_arr) do
				local hotkey = hotkey_arr[j]
				local cfg_idx = configs_by_hotkeys[hotkey]
				local spell_idx = (is_modifier2_down and ((is_modifier_down and spells_by_hotkeys2[hotkey]) or (is_sws_down and spells_by_hotkeys_sws[hotkey]) or (not is_sws_down and spells_by_hotkeys_no_sws[hotkey]))) 
					or (is_modifier_down and (((is_sws_down and spells_by_hotkeys_sws[hotkey]) or (not is_sws_down and spells_by_hotkeys_no_sws[hotkey])) or ((spells_by_hotkeys[hotkey] and not sms.spells[spells_by_hotkeys[hotkey] ].use_modifier2) and spells_by_hotkeys[hotkey])))
					or (is_sws_down and spells_by_hotkeys_sws[hotkey]) or (not is_sws_down and spells_by_hotkeys_no_sws[hotkey])
				local txt_obj = gamepad_button_guis[hotkey_str]
				local txt
				
				if cfg_idx and sms.configs[cfg_idx] > 1 and (not sms.load_cfgs_w_modifier or is_modifier_down) and (not sms.load_cfgs_w_cfg_modifier or is_cfg_modifier_down) then
					txt = configs_glob_short[sms.configs[cfg_idx] ]
					txt = "["..(txt:match(".+ %- (.+)") or txt:match(".+%\\(.+)") or txt):gsub("_", " ").."]"
				elseif (spell_idx and ((is_modifier_down and spells_by_hotkeys[hotkey]) or (is_sws_down and spells_by_hotkeys_sws[hotkey]) or (not is_sws_down and spells_by_hotkeys_no_sws[hotkey]))) or (not spell_idx and sms.modifier_inhibits_buttons and is_modifier_down) then
					txt = not spell_idx and " " or sms.last_sel_spells[spell_idx] ~= "" and sms.last_sel_spells[spell_idx] or "Skill "..spell_idx
					txt = (txt:match(".+ %- (.+)") or txt:match(".+%\\(.+)") or txt):gsub("_", " ")
				end
				
				if txt then
					local panel = txt_obj:get_Parent()
					local old_txt = txt_obj:get_Message()
					panel:set_Visible(true)
					txt_obj:set_Visible(true)
					if pcall(txt_obj.call, txt_obj, "set_Message(System.String)", txt) then
						local old_col = txt_obj:get_Color()
						col:call(".ctor(System.Int32, System.Int32, System.Int32, System.Int32)", old_col:get_r(), old_col:get_g(), old_col:get_b(), 255)
						txt_obj:set_Color(col)
						panel:set_ColorScale(Vector4f.new(1,1,1,0.5))
						local old_cs = (casted_spells[spell_idx] or hk.gp_state.down[hk.buttons[hotkey_str] ]) and {panel:get_ColorScale(), panel:get_ColorOffset()}
						if old_cs then
							panel:set_ColorScale(Vector4f.new(2,2,2,2))
							panel:set_ColorOffset(Vector3f.new(15,14,11))
						end
						
						ui_fns[txt_obj] = function()
							ui_fns[txt_obj] = nil
							gamepad_button_guis.dpad_obj:set_DrawSelf(true)
							gamepad_button_guis.dpad_obj:set_UpdateSelf(true)
							
							if gamepad_button_guis.dpad_obj:get_Update() and gamepad_button_guis.dpad_obj:get_Draw() then
								pcall(txt_obj.call, txt_obj, "set_Message(System.String)", old_txt)
								txt_obj:set_Color(old_col)
								if old_cs then 
									panel:set_ColorScale(old_cs[1])
									panel:set_ColorOffset(old_cs[2])
								end
							end
						end
					end
				end
			end
		end
		return retval
	end
)

--This gets called like 2000 times per second so it must be efficient:
sdk.hook(sdk.find_type_definition("app.BattleRelationshipHolder"):get_method("getRelationshipFromTo(app.Character, app.Character)"), 
	function(args)
		if sdk.to_int64(args[4]) ~= 0 and (next(sm_summons) or (is_casting and is_battling and sdk.to_int64(args[3]) == player:get_address())) then
			thread.get_hook_storage().ags = args
		end
	end,
	function(retval)
		local args = thread.get_hook_storage().ags
		if args then
			local cha1 = sdk.to_managed_object(args[3])
			local cha2 = sdk.to_managed_object(args[4])
			if sdk.to_int64(retval) == 0 and cha1 == player and is_casting and is_battling and func.getC(cha2:get_GameObject(), "app.NPCBehavior") then
				retval = sdk.to_ptr(2) 
			elseif sm_summons[cha1] then
				retval = sdk.to_ptr((cha2 == player or sm_summons[cha2] or func.getC(cha2:get_GameObject(), "app.NPCBehavior")) and 2 or 1)
			elseif sm_summons[cha2] then
				retval = sdk.to_ptr((cha1 == player or sm_summons[cha1] or func.getC(cha1:get_GameObject(), "app.NPCBehavior")) and 2 or 1)
			end
		end
		return retval
	end
)

sdk.hook(sdk.find_type_definition("app.HumanDefaultCancelAction"):get_method("start"), function(args)
	pressed_cancel = (cast_prep_type > 0)
end)

sdk.hook(sdk.find_type_definition("app.ResetCameraToLockOnTarget"):get_method("start"), function(args)
	if is_casting then return sdk.PreHookResult.SKIP_ORIGINAL end
end)

sdk.hook(sdk.find_type_definition("app.ResetCameraToLockOnTarget"):get_method("update"), function(args)
	if is_casting then return sdk.PreHookResult.SKIP_ORIGINAL end
end)

sdk.hook(sdk.find_type_definition("app.ResetCameraToLockOnTarget"):get_method("setCameraAngle"), function(args)
	if is_casting then return sdk.PreHookResult.SKIP_ORIGINAL end
end)

sdk.hook(sdk.find_type_definition("app.HumanShootArrow"):get_method("start(via.behaviortree.ActionArg)"), function(args)
	if cast_prep_type == 2 and sdk.to_managed_object(args[2]).Chara == player then return sdk.PreHookResult.SKIP_ORIGINAL end
end)

sdk.hook(sdk.find_type_definition("app.TurnController"):get_method("updateAngle"), function(args)
	if sdk.to_managed_object(args[2]).Transform ~= pl_xform then return end
	for name, fn in pairs(hk.merge_tables({}, turn_fns)) do
		fn()
	end
end)

sdk.hook(sdk.find_type_definition("app.Shell"):get_method("checkFinish"), 
	function(args)
		local shell = sdk.to_managed_object(args[2])
		local store = active_shells[shell]
		local timer = store and store.shell.do_abs_lifetime and not shell["<TerrainHitResult>k__BackingField"] and not store.children[1] and shell["<LiveTimer>k__BackingField"]
		if timer and timer._FinishFrame ~= math.huge and timer._ElapsedFrame < timer._FinishFrame then 
			thread.get_hook_storage().retval = sdk.to_ptr(false)
		end
	end,
	function(retval)
		return thread.get_hook_storage().retval or retval
	end
)

--[[
sdk.hook(sdk.find_type_definition("app.HumanReadySpell"):get_method("start"), function(args)
	if cast_prep_type > 0 then
		player["<Human>k__BackingField"].PrevRightWeapon = 3296903055
		player["<Human>k__BackingField"].PrevLeftWeapon = 0
	end
end)]]

sdk.hook(sdk.find_type_definition("app.CinematicActionCameraController"):get_method("playAction"), function(args)
	if temp_fns.fix_cam_dist then return sdk.PreHookResult.SKIP_ORIGINAL end
end)

sdk.hook(sdk.find_type_definition("app.WorkRate"):get_method("setHitStop(System.Single, System.Single, System.Boolean)"), function(args)
	if temp_fns.player_speed_fn and sdk.to_managed_object(args[2]) == player.WorkRate then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end)

--app.Character.isFurtherAttackable(System.Boolean)