--Skill Maker (formerly Spell Maker) for Dragons Dogma 2
--Create your own skills as sequences of animations, melee attacks, summons, lightning, explosions and other magical or physical effects
--By alphaZomega
--Requires REFramework
local version = "1.19"
print("Skill Maker v"..version)

--Added 'Enemy Skill' mod capability, Skill Maker can now give skills to enemies and NPCs
--Improved summon AI
--Summons will now follow you
--Added 'Summon Speed' node option to control the speed of summons
--Added 'Summon Color' and its material/variable search text to change the colors of a summon
--You can re-trigger a skill while it's already running if you list it as a requirement for itself in Skill States
--Added 'Possess Enemy' node option (used with 'Soft Lock') to take control of or resurrect enemies and make them like summons
--NPCs no longer chase summons around
--'Target' cast type now can use position/rotation offsets
--Added 'Damage Type' node option for shells and player to make hits blow the enemy away etc
--Node boons now remember previous node boons correctly and restore them after the current one is over
--'Abs. Lifetime' now deletes shells that exist beyond their lifetime
--Skills and the Enemy Skill menu can now be used in separate windows
--More shells are be colored now
--You can now add position and rotation offsets to 'Crosshair' rotation type for 'Player' cast type
--Added enemy behaviors for summons and enemy skills
--Added 'Double Tap' button press functionality for activating skills
--Optimized how changing shell colors works (was a major FPS drain with flashy skills)
--You can now use "Custom Motion" on any node
--Added 'Hit Contact' skill activation option to activate only when actually hitting the enemy
--Added 'Button Type' option to let you trigger skills by double-tap or holding a button
--Summoned bosses now have floating health bars
--Added 'Action VFX Coloring' to color non-shell effects created by actions
--Changed internal variable names from 'spell' to 'skill' and 'shell' to 'smnode' (this means skills from v1.19+ will not work in older versions)
--Added the ability to drag-and-drop skills to different locations in the list by dragging on the 'Enabled' checkbox and releasing it on other skill's checkboxes
--Added support for imgui themes from _ScriptCore v1.1.8+
--Updated UI to be more neat and clear
--Many other small changes

--NOTE:
-- Early on, this script was called "Spell Maker" and skills were known as spells, so "skill" and "spell" may be used interchangably as variable names in the code 
-- At first the script was only managing shells, so Skill Maker nodes were called "shells" as variables too. This has been changed as of v1.19, but the old names remain available as aliases in metatables

local hk = require("Hotkeys/Hotkeys")
local func = require("_SharedCore/Functions")
local ui = require("_SharedCore/Imgui")

local sms = json.load_file("SkillMaker\\SkillMaker.json") or {}
local default_sms = {
	enabled = true,
	modifier_inhibits_buttons = true,
	skills = {},
	use_modifier = true,
	crosshair_type = 3,
	last_sel_spells = {},
	last_sel_em_spells = {},
	shell_lifetime_limit = 120,
	use_window = true,
	do_shift_sheathe = true,
	do_swap_lshoulders = true,
	maximum_range = 100,
	move_cam_for_crosshair = 4,
	load_sksets_w_modifier = true,
	load_sksets_w_sksets_modifier = true,
	ingame_ui_buttons = true,
	do_clear_spells_on_skset_load = true,
	do_clear_spells_on_em_cfg_load = true,
	do_force_cam_dist = true,
	use_colored_nodes = true,
	use_gamepad_defaults = true,
	show_boss_hp_bars = true,
	summons_lead_projectiles = true,
	theme_type = 1,
	max_skills = 24,
	max_skillsets = 8,
	skill_descs = {},
	enemyskills = {},
	skillsets = {
		idxes = {},
		loadcontrols = {},
	},
}

local function setup_gamepad_specific_defaults()
	local use_pad = sms.use_gamepad_defaults
	local do_shift_sheathe = use_pad
	local do_swap_lshoulders = use_pad
	default_sms.hotkeys = {
		["Modifier / Inhibit"] = use_pad and "LT (L2)" or "X",
		["SM Modifier2"] = use_pad and "LB (L1)" or "R Mouse",
		["SM Config Modifier"] = use_pad and "RB (R1)" or "LAlt",
		["UI Modifier"] = "LShift",
		["UI Modifier2"] = "Control",
		["Reset Player State"] = "Back",
		["SM Clean Up"] = "Back",
		["Undo"] = "Z",
		["Redo"] = "Z",
		["Redo_$"] = "LShift",
		["Run Enemy Skill Test"] = "K",
		["Use Skill 1"] = use_pad and "Y (Triangle)" or "V", 
		["Use Skill 2"] = use_pad and "A (X)" or "Space",
		["Use Skill 3"] = use_pad and "X (Square)" or "L Mouse",
		["Use Skill 4"] = use_pad and "B (Circle)" or "LShift",
		["Use Skill 5"] = use_pad and "LUp" or "Alpha1",
		["Use Skill 6"] = use_pad and "LDown" or "Alpha2",
		["Use Skill 7"] = use_pad and "LLeft" or "Alpha3",
		["Use Skill 8"] = use_pad and "LRight" or "Alpha4",
		["Use Skill 9"] = use_pad and "LStickPush" or "C",
		["Use Skill 10"] = use_pad and "RStickPush" or "G",
		["Use Skill 11"] = use_pad and "RB (R1)" or "R Mouse",
		["Use Skill 12"] = use_pad and "RT (R2)" or "E",
		["Use Skill 13"] = use_pad and "Y (Triangle)" or "V",
		["Use Skill 14"] = use_pad and "A (X)" or "Space",
		["Use Skill 15"] = use_pad and "X (Square)" or "L Mouse",
		["Use Skill 16"] = use_pad and "B (Circle)" or "LShift",
		["Use Skill 17"] = use_pad and "LUp" or "Alpha1",
		["Use Skill 18"] = use_pad and "LDown" or "Alpha2",
		["Use Skill 19"] = use_pad and "LLeft" or "Alpha3",
		["Use Skill 20"] = use_pad and "LRight" or "Alpha4",
		["Use Skill 21"] = use_pad and "LStickPush" or "C",
		["Use Skill 22"] = use_pad and "RStickPush" or "G",
		["Use Skill 23"] = use_pad and "RB (R1)" or "R Mouse",
		["Use Skill 24"] = use_pad and "RT (R2)" or "E",
		["Load Skillset 1"] = use_pad and "Y (Triangle)" or "[Not Bound]",
		["Load Skillset 2"] = use_pad and "A (X)" or "[Not Bound]",
		["Load Skillset 3"] = use_pad and "X (Square)" or "[Not Bound]",
		["Load Skillset 4"] = use_pad and "B (Circle)" or "[Not Bound]",
		["Load Skillset 5"] = use_pad and "LUp" or "[Not Bound]",
		["Load Skillset 6"] = use_pad and "LDown" or "[Not Bound]",
		["Load Skillset 7"] = use_pad and "LLeft" or "[Not Bound]",
		["Load Skillset 8"] = use_pad and "LRight" or "[Not Bound]",
	}
end

local em_groups
local imgui_skills = {}
local imgui_em_skills = {}
local redirect_names = {"Don't Redirect"}
local action_names = json.load_file("SkillMaker\\ActionNames.json")
local user_paths = json.load_file("SkillMaker\\UserFiles.json")
local enemy_list = json.load_file("EnemyRandomizer\\EnemyList.json")
local enemy_behaviors = json.load_file("SkillMaker\\EnemyBehaviors.json")
local enemy_action_names = json.load_file("SkillMaker\\EnemyActionNames.json")
local action_names_numbered = {}

enemy_action_names["Battahl Purgener"] = enemy_action_names["Sacred Arbor Purgener"]
enemy_action_names["Vermund Purgener"] = enemy_action_names["Sacred Arbor Purgener"]
enemy_action_names["Island Encampment Purgener"] = enemy_action_names["Sacred Arbor Purgener"]
enemy_action_names.Rogue = hk.merge_tables({}, action_names)
for i, name in ipairs({"Lost Mercenary", "Coral Snake", "Scavenger", "NPC", "Pawn", "Skeleton"}) do enemy_action_names[name] = enemy_action_names.Rogue end --generic fallbacks for when no vocation specified
table.insert(action_names, 1, "[Input Name]"); table.insert(action_names_numbered, 1, "[Input Name]")
table.insert(action_names, 1, "None"); table.insert(action_names_numbered, 1, "None")

enemy_list.ch1 = {name="Pawn", is_human=true} --fake enemy entries for Pawn and NPC
enemy_list.ch3 = {name="NPC", is_human=true}

local function setup_default_lists()
	local last_skill = sms.skills[#sms.skills]
	local new_skills = {}
	local new_em_skills = {}
	for i, skill in pairs(sms.skills) do
		if i > sms.max_skills then sms.skills[i] = nil end
	end
	
	for i = 1, sms.max_skills do 
		imgui_skills[i] = {
			preset_idx = presets_glob and func.find_index(presets_glob, sms.last_sel_spells[i]) or 1, 
			shell_datas = {}, 
			scale_together = true,
			do_load_controls = true,
			nodes_expanded = false,
		}
		default_sms.hotkeys["Use Skill "..i] = default_sms.hotkeys["Use Skill "..i] or "[Not Bound]"
		new_skills[i] = {
			name = "",
			sm_version = version,
			preset_idx = 1,
			activate_fn = "",
			enabled = false,
			duration = 1.0,
			stam_cost = 0.0,
			job_idx = 1,
			require_weapon = false,
			require_hitbox = false,
			require_hitbox_contact = false,
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
			button_press_type = 1,
			button_hold_time = 0.5,
			smnodes = {
				{
					enabled = true,
					action_idx = 1, 
					action_name = "None",
					anim_speed = 1.0,
					attach_euler = {0,0,0},
					attach_pos = {0,0,0},
					attach_to_joint = false, 
					attack_rate = 1.0,
					attack_rate_pl = 1.0,
					partswap_data = "",
					boon_type = 1,
					boon_color = {1.0,1.0,1.0,1.0},
					boon_time = -1.0,
					cast_type = 1, 
					camera_dist = -1.0,
					coloring = {1,1,1,1},
					custom_fn = "",
					custom_motion = "",
					do_abs_lifetime = false,
					do_carryover_prev = false,
					do_simplify_action = false,
					do_hold = false,
					do_iframes = false,
					do_inhibit_buttons = false,
					do_mirror_action = false,
					do_mirror_wp = false,
					mirror_time = -1.0,
					do_no_attach_rotate = false,
					do_aim_up_down = false,
					pl_velocity = {0.0,0.0,0.0},
					pl_velocity_type = 1,
					do_sfx = true,
					do_vfx = true,
					do_teleport_player = false,
					do_turn_constantly = false,
					do_true_hold = false,
					dmg_type_owner = 1,
					dmg_type_shell = 1,
					enemy_soft_lock = false,
					soft_lock_type = 1,
					do_possess_enemy = false,
					--enchant_type = 1,
					freeze_crosshair = false, 
					hold_color = {1.0,1.0,1.0,1.0},
					is_decorative = false,
					joint_idx = 2,
					joint_name = "root",
					lifetime = -1.0,
					max_ids = 1, 
					name = "",
					action_vfx_color = {1.0,1.0,1.0,1.0},
					action_vfx_color_time = 0.0,
					omentime = -1.0,
					pshell_attach_type = 1,
					rot_type_idx = 2,
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
					--summon_action_name = "",
					summon_attack_rate = 1.0,
					summon_hp_rate = 1.0,
					summon_no_dissolve = false,
					summon_timer = 30.0,
					summon_scale = 1.0,
					summon_hostile = false,
					summon_hostile_to_all = false,
					summon_speed = 1.0,
					summon_color = {1.0,1.0,1.0},
					summon_col_mat_term = "",
					summon_col_var_term = "",
					summon_var_tblstr = "",
					summon_behavior_category = 0,
					summon_behavior_type = 1,
					enemy_behavior_category = 0,
					enemy_behavior_type = 1,
					turn_idx = 1,
					turn_speed = 1.0,
					udata_idx = 1, 
					udata_name = "None",
					--shell_type = 1,
					world_speed = 1.0,
				},
			}
		}
		if i > #default_sms.skills and i > default_sms.max_skills then
			new_skills[i].state_type_idx = last_skill.state_type_idx
			new_skills[i].use_modifier2 = last_skill.use_modifier2
		end
	end
	
	local em_skill_fields = {
		enabled = true,
		do_upperbody = false,
		em_job_idx = 1,
		act_name = "",
		replace_idx = 1,
		search_txt = "",
		anim_search_txt = "",
		preset_idx = 1,
		odds_to_replace = 1.0,
		activate_interval = -1.0,
		name = "",
		summon_skill_name = "",
		do_replace_enemy = false,
		do_replace_dont_respawn = false,
		min_player_lvl = 0,
		delay_time = 0.0,
	}
	
	local em_skill_remove_fields = {"anim_states","custom_states","do_auto","do_hold_button","do_move_cam","frame_range","frame_range_upper",
		"hide_ui","require_weapon","spell_states","stam_cost","state_type_idx","states","use_modifier2","wp_idx",}
	for name, list in func.orderedPairs(enemy_action_names) do
		table.insert(redirect_names, name)
		default_sms.last_sel_em_spells[name] = {}
		new_em_skills[name] = {
			enabled = false,
			do_clear_spells_on_em_cfg_load = true,
			skills = {hk.merge_tables({}, em_skill_fields)},
			redirect_idx = 1,
			locations = "",
		}
		new_em_skills[name].skills[1] = hk.merge_tables(new_em_skills[name].skills[1], new_skills[1])
		local skill_one = new_em_skills[name].skills[1]
		for i, key in pairs(em_skill_remove_fields) do
			skill_one[key] = nil
		end
	end
	--[[
	for species_name, tbl in pairs(em_groups.groups) do 
		local redirect_idx = func.find_key(redirect_names, tbl[1])
		for i, name in ipairs(tbl) do  
			if i > 1 and new_em_skills[name] then
				new_em_skills[name].redirect_idx = redirect_idx
			end
		end
	end
	]]
	default_sms.skills = new_skills
	default_sms.enemyskills = new_em_skills
	
	for name, list in pairs(enemy_action_names) do
		local is_human = (name=="Rogue" or name=="Lost Mercenary" or name=="Coral Snake" or name=="Scavenger" or name=="NPC" or name=="Pawn")
		imgui_em_skills[name] = {enemy_name=name, dummy_think_on=true, do_dummy_reset=true, is_human=is_human, is_jobber=(is_human or name=="Skeleton"), is_skel=name=="Skeleton", dummy_hostile=true}
		for i, em_skills_tbl in pairs((sms.enemyskills[name] or default_sms.enemyskills[name]).skills) do
			imgui_em_skills[name][i] = hk.recurse_def_settings({}, imgui_skills[1])
			imgui_em_skills[name][i].enemy_name = name
			imgui_em_skills[name][i].parent = imgui_em_skills[name]
		end
	end
	
	for i = 1, sms.max_skillsets do 
		default_sms.skillsets.idxes[i] = 1
		default_sms.skillsets.loadcontrols[i] = true
		default_sms.hotkeys["Load Skillset "..i] = default_sms.hotkeys["Load Skillset "..i] or "[Not Bound]"
	end
end

local shell_descs = {}
local udata_descs = {""}
local user_paths_short = {}
local udatas_ordered = {}

 --update old skill var names etc from prev SM versions:
local function update_skill(skill_tbl, idx, enemy_name)
	local skills_list = enemy_name and default_sms.enemyskills[name] or default_sms.skills
	local def_tbl = skills_list[idx] or skills_list[1]
	skill_tbl.state_type_idx, skill_tbl.use_modifier = skill_tbl.use_modifier and 2 or skill_tbl.state_type_idx, nil
	skill_tbl.frame_range, skill_tbl.minimum_frame = skill_tbl.minimum_frame and Vector2f.new(skill_tbl.minimum_frame, -1) or skill_tbl.frame_range, nil
	skill_tbl.frame_range_upper, skill_tbl.minimum_frame_upper = skill_tbl.minimum_frame_upper and Vector2f.new(skill_tbl.minimum_frame_upper, -1) or skill_tbl.frame_range_upper, nil
	skill_tbl.desc = skill_tbl.desc and skill_tbl.desc:gsub("%%(?!%%)", "%%%%") or skill_tbl.desc
	skill_tbl.smnodes, skill_tbl.shells = skill_tbl.shells or skill_tbl.smnodes, nil
	skill_tbl.name, skill_tbl.spell_name = skill_tbl.spell_name or skill_tbl.name
	local act_names = enemy_name and enemy_action_names[enemy_name].names or action_names
	
	for i, smnode in ipairs(skill_tbl.smnodes) do 
		smnode.action_idx = func.find_key(act_names, smnode.action_name) or smnode.action_idx --update old nodes
		smnode.udata_idx = func.find_key(user_paths, smnode.udata_name) or smnode.udata_idx --update old user files
		
		if smnode.do_simplify_action == nil then smnode.do_simplify_action = true end
		if smnode.skyfall_cam_relative == nil then smnode.skyfall_cam_relative = false end
		if skill_tbl.require_hitbox == nil and smnode.action_idx == 1 then smnode.anim_speed = 1.0 end
		if type(smnode.scale) == "number" then smnode.scale = {smnode.scale, smnode.scale, smnode.scale} end
		if smnode.do_pl_soft_lock then smnode.turn_idx, smnode.do_pl_soft_lock = 4, nil end
		if smnode.summon_color == nil and not smnode.turn_speed and smnode.turn_idx == 4 then 
			smnode.turn_idx = 2
			smnode.turn_speed = 2.0
		end
		hk.recurse_def_settings(smnode, def_tbl.smnodes[1])
	end
	--if skill_tbl.unedited then skill_tbl.enabled = false end
	return hk.recurse_def_settings(skill_tbl, def_tbl)
end

em_groups = {
	searched = {},
	species_map = {},
	cat_names = {
		"All",
		"Bosses",
		"Canines",
		"Dragons",
		"Enemies",
		"Floaters",
		"Flyers",
		"Humans",
		"Lizards",
		"Undead",
	},
	categories = {
		All = {},
		Humans = {},
		Undead = {},
		Bosses = {},
		Flyers = {},
		Floaters = {},
		Canines = {},
		Lizards = {},
		Enemies = {},
		Dragons = {},
	},
	names = {},
	groups = {
		["Harpies"] = {
			"Harpy",
			"Venin Harpy",
			"Gore Harpy",
			"Succubus",
		},
		["Goblins"] = {
			"Goblin",
			"Hobgoblin",
			"Chopper",
			"Knacker",
		},
		["Lizards"] = {
			"Rattler",
			"Magma Scale",
		},
		["Lizardmen"] = {
			"Saurian",
			"Asp",
			"Serpent",
		},
		["Wolves"] = {
			"Wolf",
			"Redwolf",
		--    "Blackdog",
		},
		["Slimes"] = {
			"Slime",
			"Ooze",
			"Sludge",
		},
		["Phantoms"] = {
			"Phantom",
			"Phantasm",
			"Specter",
		},
		["Skeletons"] = {
			"Skeleton",
			"Skeleton Lord",
		},
		["Skeletal Mages"] = {
			"Lich",
			"Wight",
		},
		["Zombies"] = {
			"Undead",
			"Stout Undead",
		},
		["Dullahan"] = {
			"Dullahan",
		},
		["Bandits"] = {
			"Rogue",
			"Lost Mercenary",
			"Coral Snake",
			"Scavenger",
		},
		["Purgeners"] = {
			--"Battahl Purgener",
			"Vermund Purgener",
			"Island Encampment Purgener",
			"Sacred Arbor Purgener",
			"Volcanic Island Purgener",
		},
		["Cyclops"] = {
			"Cyclops",
		},
		["Ogres"] = {
			"Ogre",
			"Grim Ogre",
		},
		["Golems"] = {
			"Golem",
		},
		["Griffins"] = {
			"Griffin",
		},
		["Sphinx"] = {
			"Sphinx",
		},
		["Chimeras"] = {
			"Chimera",
			"Gorechimera",
		},
		["Medusas"] = {
			"Medusa",
		},
		["Minotaurs"] = {
			"Minotaur",
			"Goreminotaur",
		},
		["Drakes"] = {
			"Drake",
			"Lesser Dragon",
		},
		["Dragons"] = {
			"Dragon",
			--"Nex",
		},
		["Talos"] = {
			"Talos",
		},
		["Giant Wolves"] = {
			"Garm",
			"Warg",
		},
		["NPCs"] = {
			"Pawn",
			"NPC",
		},
	},
}

for spc_name, list in pairs(em_groups.groups) do 
	for i, name in ipairs(list) do em_groups.species_map[name] = spc_name end
end

for ch_id, tbl in pairs(enemy_list) do
	local species_name = em_groups.species_map[tbl.name]
	if species_name and not em_groups.searched[species_name] then
		em_groups.searched[species_name] = true
		if tbl.is_boss then 
			table.insert(em_groups.categories.Bosses, species_name) 
		elseif species_name ~= "NPCs" then 
			table.insert(em_groups.categories.Enemies, species_name) 
		end
		table.insert(em_groups.categories.All, species_name)
		if tbl.is_human then table.insert(em_groups.categories.Humans, species_name) end
		if tbl.is_undead then table.insert(em_groups.categories.Undead, species_name) end
		if tbl.is_lizard then table.insert(em_groups.categories.Lizards, species_name) end
		if tbl.can_fly then table.insert(em_groups.categories.Flyers, species_name) end
		if tbl.can_float then table.insert(em_groups.categories.Floaters, species_name) end
		if tbl.is_dragon then table.insert(em_groups.categories.Dragons, species_name) end
		if tbl.is_canine then table.insert(em_groups.categories.Canines, species_name) end
	end
end

em_groups.searched = nil
for i, list in pairs(em_groups.categories) do table.sort(list) end
for name, group in pairs(em_groups.groups) do table.insert(em_groups.names, name) end
table.sort(em_groups.names)

if sms.use_gamepad_defaults == nil then 
	sms.use_gamepad_defaults = sdk.call_native_func(sdk.get_native_singleton("via.hid.Gamepad"), sdk.find_type_definition("via.hid.GamePad"), "getMergedDevice", 0):get_Connecting() 
end

--update old var names:
if sms.enemyskills then
	sms.skills, sms.spells = sms.spells or sms.skills, nil
	sms.skillsets, sms.configs, sms.configs_loadcontrols = sms.skillsets or {idxes=sms.configs, loadcontrols=sms.configs_loadcontrols}, nil, nil
	sms.skill_descs, sms.preset_descs = sms.preset_descs or sms.skill_descs, nil
	for i, skillslist in pairs(sms.enemyskills) do skillslist.skills, skillslist.spells = skillslist.spells or skillslist.skills, nil end
end

--load + update json data:
sms = func.convert_tbl_to_numeric_keys(hk.recurse_def_settings(sms, default_sms))
setup_gamepad_specific_defaults()
if not pcall(setup_default_lists) then 
	re.msg("Corrupt Skillmaker.json")
	sms = hk.recurse_def_settings({}, default_sms)
	setup_default_lists()
end
hk.recurse_def_settings(sms, default_sms)
hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)

for i, skill_tbl in pairs(sms.skills) do
	update_skill(skill_tbl, i)
end

for em_name, skills_list in pairs(sms.enemyskills) do
	for i, em_skill_tbl in pairs(skills_list.skills) do
		update_skill(em_skill_tbl, i, em_name)
	end
end

local scene = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")
local chr_mgr = sdk.get_managed_singleton("app.CharacterManager")
local chr_edit_mgr = sdk.get_managed_singleton("app.CharacterEditManager")
local rel_holder = sdk.get_managed_singleton("app.BattleRelationshipHolder")
local wgraph_mgr = sdk.get_managed_singleton("app.AIWorldGraphManager")
local cam_mgr = sdk.get_managed_singleton("app.CameraManager")
local em_mgr = sdk.get_managed_singleton("app.EnemyManager")
local shell_mgr = sdk.get_managed_singleton("app.ShellManager")
local gen_mgr = sdk.get_managed_singleton("app.GenerateManager")
local battle_mgr = sdk.get_managed_singleton("app.BattleManager")
local opt_mgr = sdk.get_managed_singleton("app.OptionManager")
local nav_mgr = sdk.get_managed_singleton("app.NavigationManager")
local col = ValueType.new(sdk.find_type_definition("via.Color"))
local lookat_method = sdk.find_type_definition("via.matrix"):get_method("makeLookAtRH")
local rotate_yaw_method = sdk.find_type_definition("via.MathEx"):get_method("rotateYaw(via.vec3, System.Single)")
local transform_method = sdk.find_type_definition("via.MathEx"):get_method("transform(via.vec3, via.Quaternion)")
local euler_to_quat = sdk.find_type_definition("via.quaternion"):get_method("makeEuler(via.vec3, via.math.RotationOrder)")
local set_node_method = sdk.find_type_definition("via.motion.MotionFsm2Layer"):get_method("setCurrentNode(System.String, via.behaviortree.SetNodeInfo, via.motion.SetMotionTransitionInfo)")
local keybinds
local rev_keys_enum = {}; for name, key_id in pairs(hk.keys) do rev_keys_enum[key_id] = name end; rev_keys_enum[1], rev_keys_enum[2] = "L Mouse", "R Mouse"
local interper = sdk.create_instance("via.motion.SetMotionTransitionInfo"):add_ref()
local setn = ValueType.new(sdk.find_type_definition("via.behaviortree.SetNodeInfo"))
local old_cam_dist
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
local ui_mod2_down = false
local pressed_cancel = false
local is_battling = false
local is_paused = false
local is_sws_down = false
local is_summoning = false
local real_rad_l

local last_loco_time = 0.0
local cast_prep_type = 0.0
local forced_skill
local player
local camera
local cam_matrix
local pl_xform
local mfsm2
local node_name = ""
local node_name2 = ""
local ray_result
local camera_dist
local game_time = os.clock()
local last_time = os.clock()
local ticks = 0
local skill_delta_time = 0
local delta_time = 0
local cast_shell
local summon

local presets_glob
local em_presets_glob
local presets_map
local enemy_skillsets
local skillsets_glob
local gamepad_button_guis
local udatas = {}
local temp_fns = {}
local frame_fns = {}
local mot_fns = {}
local pre_fns = {}
local late_fns = {}
local turn_fns = {}
local dmg_tbl = {}
local window_fns = {}
local casted_spells = {}
local skills_by_hotkeys = {}
local skills_by_hotkeys2 = {}
local skills_by_hotkeys_sws = {}
local skills_by_hotkeys_no_sws = {}
local sksets_by_hotkeys = {}
local ui_fns = {}
local clipboard = {}
local active_skills = {}
local active_shells = {}
local active_summons = {}
local enemy_casts = {}
local rel_db = {}
local active_states = {}
local replaced_enemies = {}
local undo = {idx=0}
local tooltips = {}
local projectile_speeds = {}

--misc stuff
local temp = {
	omen_reqs = {},
	summon_dummies = {},
	last_listbox_filters = {},
	last_cast_skills = {},
	do_start_buttons = true, --prevents some weird glitch where buttons start out inhibited and dont enable til you do a SM skill
	job_mixup_ranges = {[1]={0, 12}, [2]={13, 23}, [3]={24, 37}, [4]={38, 49}, [5]={50, 61}, [6]={62, 69}},
	pos_sub_mth = sdk.find_type_definition("app.PosConv"):get_method("sub(via.Position, via.Position)"),
	chest_joint_mth = sdk.find_type_definition("app.TransformExtension"):get_method("getCharacterChestJoint(via.Transform)"),
	last_pl_hit_landed = 0,
	use_emsk_window = true,
	targ_hooked = false,
	selected_shell = nil,
	callbacks = {
	    OnPreUpdateBehavior = pre_fns,
		OnUpdateMotion = mot_fns,
		OnUpdateBehavior = temp_fns,
		OnLateUpdateBehavior = late_fns,
		OnFrame = frame_fns,
	},
}

local enums = {}
enums.chara_id_enum, enums.chara_id_names = func.generate_statics("app.CharacterID")
enums.pants_enum, enums.pants = func.generate_statics("app.PantsStyle")
enums.helms_enum, enums.helms = func.generate_statics("app.HelmStyle")
enums.mantles_enum, enums.mantles = func.generate_statics("app.MantleStyle")
enums.tops_enum, enums.tops = func.generate_statics("app.TopsStyle")
enums.skills_enum, enums.skills = func.generate_statics("app.HumanCustomSkillID")
enums.wp_enum, enums.wps = func.generate_statics("app.WeaponID")
enums.dmg_enum, enums.dmgs = func.generate_statics("app.AttackUserData.DamageTypeEnum") 
table.insert(enums.dmgs, 1, "Default Damage Type")
enums.dmgs_melee = hk.merge_tables({}, enums.dmgs)
table.insert(enums.dmgs_melee, "Force Finishing Move")

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

local function tooltip(text)
	if imgui.is_item_hovered() then
		imgui.set_tooltip(tostring(text))
	end
end

local function set_wc(name, tbl, val, parent_tbl, color_tooltip)
	was_changed = was_changed or changed
	local reset_color = false
	if color_tooltip then
		tooltip(color_tooltip) 
		imgui.push_id(name.."Col"); imgui.same_line(); reset_color = imgui.button("Reset"); imgui.pop_id() --stupid color picker monopolizes the context menu
	end 
	if val and (reset_color or imgui.begin_popup_context_item(name)) then  
		if reset_color or imgui.menu_item("Reset Value") then
			if tbl and val ~= nil then
				tbl[name] = val
			else
				sms[name] = default_sms[name]
			end
			changed, was_changed = true, true
		end
		if not reset_color then imgui.end_popup() end
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

local bad_shells = {
	["AppSystem/ch/ch227/userdata/ch227shellparamdata.user"] = {[0]=true},
	["AppSystem/ch/ch225/userdata/ch225shellparamdata.user"] = {[0]=true},
	["AppSystem/ch/ch230/userdata/shell/ch230shellparamdata_job09.user"] = {[3]=true, [9]=true, [10]=1, [11]=1},
	["AppSystem/shell/userdata/humanshellparamdata_job09.user"] = {[3]=true, [9]=true, [10]=1, [11]=1},
}

local vocation_names = {"All", "Fighter", "Archer", "Mage", "Thief", "Warrior", "Sorcerer", "Mystic Spearhead", "Magick Archer", "Trickster", "Warfarer",}
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

local weps = {
	types = {"Any", "Unarmed", "Sword", "Shield", "Two-Hander", "Dagger", "Bow", "Magick Bow", "Staff", "Archistaff", "Duospear", "Censer", "Melee Weapons", "Bows", "Staves"},
	map = {
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
	},
	job_to_wp_map = {
		[1] = "Sword",
		[2] = "Bow",
		[3] = "Staff",
		[4] = "Dagger",
		[5] = "Two-Hander",
		[6] = "Archistaff",
		[7] = "Duospear",
		[8] = "Magick Bow",
		[9] = "Censer",
	},
	job_to_sub_wp_map = {
		[1] = "Shield",
	},
	getWeaponJob = function(weapon, map)
		return map[weapon and weapon['<Weapon>k__BackingField'] and weapon['<Weapon>k__BackingField'].Job or -1] or "Unarmed"
	end,
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
	["AppSystem/ch/ch226/prefab/ch226000_00.pfb"] = "Skeleton (Skel Fighter)", --Skeletons
	["AppSystem/ch/ch226/prefab/ch226000_01.pfb"] = "Skeleton (Skel Fighter)",
	["AppSystem/ch/ch226/prefab/ch226001_01.pfb"] = "Skeleton (Skel Fighter)",
	["AppSystem/ch/ch226/prefab/ch226001_03.pfb"] = "Skeleton (Skel Mage)",
	["AppSystem/ch/ch226/prefab/ch226001_05.pfb"] = "Skeleton (Skel Warrior)",
	["AppSystem/ch/ch226/prefab/ch226001_06.pfb"] = "Skeleton (Skel Sorcerer)",
	["AppSystem/ch/ch226/prefab/ch226002_01.pfb"] = "Skeleton (Skel Fighter)",
	["AppSystem/ch/ch226/prefab/ch226002_03.pfb"] = "Skeleton (Skel Mage)",
	["AppSystem/ch/ch226/prefab/ch226002_05.pfb"] = "Skeleton (Skel Warrior)",
	["AppSystem/ch/ch226/prefab/ch226002_06.pfb"] = "Skeleton (Skel Sorcerer)",
	["AppSystem/ch/ch226/prefab/ch226003_00.pfb"] = "Skeleton Lord (Warrior)",
	["AppSystem/ch/ch230/prefab/ch230000_01.pfb"] = "Rogue (Fighter)", --Bandits
	["AppSystem/ch/ch230/prefab/ch230000_02.pfb"] = "Rogue (Archer)",
	["AppSystem/ch/ch230/prefab/ch230000_03.pfb"] = "Rogue (Mage)",
	["AppSystem/ch/ch230/prefab/ch230000_04.pfb"] = "Rogue (Thief)",
	["AppSystem/ch/ch230/prefab/ch230001_01.pfb"] = "Lost Mercenary (Fighter)",
	["AppSystem/ch/ch230/prefab/ch230001_02.pfb"] = "Lost Mercenary (Archer)",
	["AppSystem/ch/ch230/prefab/ch230001_03.pfb"] = "Lost Mercenary (Mage)",
	["AppSystem/ch/ch230/prefab/ch230001_04.pfb"] = "Lost Mercenary (Thief)",
	["AppSystem/ch/ch230/prefab/ch230001_05.pfb"] = "Lost Mercenary (Warrior)",
	["AppSystem/ch/ch230/prefab/ch230001_06.pfb"] = "Lost Mercenary (Sorcerer)",
	["AppSystem/ch/ch230/prefab/ch230002_01.pfb"] = "Lost Mercenary (Fighter)",
	["AppSystem/ch/ch230/prefab/ch230002_02.pfb"] = "Lost Mercenary (Archer)",
	["AppSystem/ch/ch230/prefab/ch230002_03.pfb"] = "Lost Mercenary (Mage)",
	["AppSystem/ch/ch230/prefab/ch230002_04.pfb"] = "Lost Mercenary (Thief)",
	["AppSystem/ch/ch230/prefab/ch230002_05.pfb"] = "Lost Mercenary (Warrior)",
	["AppSystem/ch/ch230/prefab/ch230002_06.pfb"] = "Lost Mercenary (Sorcerer)",
	["AppSystem/ch/ch230/prefab/ch230012_02.pfb"] = "Coral Snake (Archer)",
	["AppSystem/ch/ch230/prefab/ch230012_04.pfb"] = "Coral Snake (Thief)",
	["AppSystem/ch/ch230/prefab/ch230100_04.pfb"] = "Scavenger (Thief)", 
}

local function update_last_sel_spells()
	for i, skill_tbl in ipairs(sms.skills) do
		imgui_skills[i].preset_text = skill_tbl.name
		sms.last_sel_spells[i] = skill_tbl.name
		imgui_skills[i].preset_idx = func.find_index(presets_glob, skill_tbl.name) or 1
	end
	for name, enemy_tbl in pairs(sms.enemyskills) do
		for i, skill_tbl in ipairs(enemy_tbl.skills) do
			local imgui_skill_list = imgui_em_skills[name]
			if imgui_skill_list then
				imgui_skill_list[i].preset_text = skill_tbl.name
				sms.last_sel_em_spells[name][i] = skill_tbl.name
				imgui_skill_list[i].preset_idx = func.find_index(imgui_skill_list[i].do_browse_pl_skills and presets_glob or em_presets_glob[name], skill_tbl.name) or 1
			end
		end
	end
end

local function setup_skillsets_glob()
	local glob = fs.glob("SkillMaker\\\\.*Skillsets\\\\.*json")
	enemy_skillsets, skillsets_glob = {"[Select Skillset]"}, {"[Select Skillset]", short={"[Select Skillset]"}}
	local combined_list = hk.merge_tables({["All Enemies"]={}}, enemy_action_names)
	
	for name, list in pairs(combined_list) do 
		enemy_skillsets[name] = enemy_skillsets[name] or {names={(name=="All Enemies") and "[Select Enemy Skillset List]" or "[Select Enemy Skillset]", "[Clear All]"}}
	end
	
	for i, path in ipairs(glob) do
		local path_name = path:match("Skillsets\\(.-)\\")
		if path:find("EnemySkillset") then
			table.insert(enemy_skillsets[path_name], path)
			table.insert(enemy_skillsets[path_name].names, path:match(".+\\(.+)%.json"))
		else
			table.insert(skillsets_glob, path)
			table.insert(skillsets_glob.short, path:match(".+\\(.+)%.json"))
		end
	end
end
setup_skillsets_glob()

local function setup_presets_glob(do_descs)
	do_descs = do_descs or (presets_glob == false)
	presets_map = {}
	presets_glob, em_presets_glob = {"[Reset Skill Slot]", full_paths={""}}, {}
	local glob = fs.glob("SkillMaker\\\\.*json")
	
	for i, path in ipairs(glob) do 
		local name = path:match("SkillMaker\\Skills\\(.+).json") 
		if name then
			table.insert(presets_glob, name)
			table.insert(presets_glob.full_paths, path)
			presets_map[name] = #presets_glob
		end
	end
	
	if do_descs or #sms.skill_descs ~= #presets_glob then 
		sms.skill_descs = {}
		for i=2, #presets_glob do 
			local json_data = json.load_file("SkillMaker\\Skills\\"..presets_glob[i]..".json")
			sms.skill_descs[i] = json_data and json_data.desc or "ERROR: Failed to read json file"
		end
	end
	
	for i, imgui_skill in ipairs(imgui_skills) do
		imgui_skill.preset_text = sms.last_sel_spells[i] or imgui_skill.preset_text
	end
	
	for name, imgui_list in pairs(imgui_em_skills) do
		em_presets_glob[name] = {"[Reset Skill Slot]", full_paths={""}}
		for i, imgui_skill in ipairs(imgui_list) do
			imgui_skill.preset_text = sms.last_sel_em_spells[name][i] or imgui_skill.preset_text
		end
	end
	
	for i, path in ipairs(glob) do 
		local em_name, filename = path:match("SkillMaker\\EnemySkills\\(.-)[\\/](.+).json")
		if em_name and filename then
			table.insert(em_presets_glob[em_name], filename) 
			table.insert(em_presets_glob[em_name].full_paths, path) 
		end
	end
	
	update_last_sel_spells()
	was_changed = true
end
setup_presets_glob()

_G.sm_summons = {} --shared with Monster Infighting, holds friendly and enemy summons but enemies have a value of 'false' while friendly have node storage tables
_G.em_summons = {}
local summon_record = {}

local enemy_names = {
	short = {
		"None", 
		no_parens={}
	},
	"None",
}

local enemy_behaviors_imgui = {
	categories={}, 
	categories_named={},
}

do
	for path, name in func.orderedPairs(hk.merge_tables({}, enemies_map)) do
		local id = path:match("ch%d%d%d")
		local short_name = name:match("(.+) %(") or name
		local ch_name = path:match("prefab/(.+)%.pfb")
		table.insert(enemy_names, name .. " - " .. path)
		table.insert(enemy_names.short, name)
		table.insert(enemy_names.short.no_parens, short_name)
		enemies_map[short_name], enemies_map[id] = enemies_map[short_name] or id, enemies_map[id] or short_name
		enemies_map[ch_name] = name
	end
	
	for name, list in func.orderedPairs(enemy_action_names) do
		if name == "Rogue" or list ~= enemy_action_names.Rogue then
			table.insert(list, 1, "[Input Name]")
			table.insert(list, 1, "None") --just to keep it consistent
		end
		list.names = {"None", "[Input Name]"}
		for i=3, #list do
			list.names[i] = i-2 ..".	"..list[i]
		end
	end
	
	for name, list in func.orderedPairs(enemy_behaviors) do
		table.insert(enemy_behaviors_imgui.categories, name)
		table.insert(enemy_behaviors_imgui.categories_named, name .. (enemies_map[name] and (" ("..enemies_map[name]..")") or ""))
		enemy_behaviors_imgui[name] = {"None"}
		for i, path in func.orderedPairs(list) do
			table.insert(enemy_behaviors_imgui[name], i..".	"..path)
		end
	end
	
	for i, udata_path in ipairs(user_paths) do
		user_paths_short[i] = i-1 .. ".	" .. (udata_path:match(".+%/(.+)") or udata_path)
		udatas[udata_path] = sdk.create_userdata("app.ShellParamData", udata_path)
	end
	user_paths_short[1] = "None"

	local first_upperbody = func.find_index(action_names, "DrawWeapon")
	for i=3, #action_names do
		action_names_numbered[i] = i-2 .. ".	" .. action_names[i]
		tooltips[i] = i >= first_upperbody and "Upper Body Action" or ""
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

local function get_fsm_node(chara, name, layer)
	local tree = chara:get_ActionManager().Fsm:getLayer(layer or 0):get_tree_object()
	return tree:get_node_by_name(name:match(".+%.(.+)") or name)
end

local function is_obscured(position, start_mat, ray_layer, ray_maskbits, leeway)
	start_mat = start_mat or cam_matrix
	local ray_results = start_mat and func.cast_ray(start_mat[3], position, ray_layer or 2, ray_maskbits or 0) or {}
	return ray_results[1] and (start_mat[3] - ray_results[1][2]):length() + (leeway or 0.25) < (start_mat[3] - position):length()
end

local function is_visible(xform, position)
	position = position or temp.chest_joint_mth:call(nil, xform):get_Position()
	local delta = cam_matrix[3] - position
	local w2s = (delta:dot(cam_matrix[2]) > 0.0) and draw.world_to_screen(position)
	if w2s and w2s.x > 0 and w2s.x < temp.disp_sz.x and w2s.y > 0 and w2s.y < temp.disp_sz.y then
		return not is_obscured(position)
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

local function drag_float_neg_one(label, parent_tbl, key, increment, maximum, fmt)
	local last_value = parent_tbl[key]
	changed, parent_tbl[key] = imgui.drag_float(label, parent_tbl[key], increment, -1.0, maximum, fmt)
	if changed and parent_tbl[key] < 0 and parent_tbl[key] > last_value then parent_tbl[key] = 0 end
	if parent_tbl[key] < 0 then parent_tbl[key] = -1 end
end

local function expand_as_text_box(imgui_data, key, label, value, ttip)
	local do_multiline = imgui_data[key.."_do_multiline"]
	local imgui_text_fn = do_multiline and imgui.input_text_multiline or imgui.input_text
	
	changed, value = ui.imgui_safe_input(imgui_text_fn, key, label, value)
	tooltip((ttip or "").."Right click to expand text box")
	if imgui.begin_popup_context_item(key.."ctx") then
		if imgui.menu_item(do_multiline and "Collapse" or "Expand") then
			imgui_data[key.."_do_multiline"] = not do_multiline
		end
		imgui.end_popup() 
	end
	return changed, value
end

local function expand_as_listbox(imgui_data, key, savedata, value, label, list, short_list, desc_list, ttip, parent_tbl, skip_wc, indent_amt, listbox_width)
	local add_amt = short_list and #short_list - #list or 0
	short_list = short_list or list
	imgui_data[key.."_list_idx"] = imgui_data[key.."_list_idx"] or savedata[value]
	ttip = ttip or ""
	
	changed, savedata[value]  = imgui.combo(label, savedata[value], short_list)
	listbox_ctx_menu(imgui_data, key, 0)
	tooltip(ttip)
	
	if imgui_data[key.."_show_listbox"] then
		local calc_width = imgui.calc_item_width()
		if indent_amt then imgui.indent(indent_amt) end
		if listbox_width then imgui.set_next_item_width(calc_width * listbox_width) end
		changed, imgui_data[key.."_filter"] = imgui.input_text(label .. " Filter", imgui_data[key.."_filter"] or temp.last_listbox_filters[key])
		temp.last_listbox_filters[key] = imgui_data[key.."_filter"]
		tooltip("Filter by name\nRight click to show/hide list box")
		if changed then imgui_data[key.."_list"] = nil end
		listbox_ctx_menu(imgui_data, key, 1)
		local lower_filter = (filter ~= "" and not imgui_data[key.."_list"]) and imgui_data[key.."_filter"]:lower()
		
		if lower_filter and pcall(string.find, "test", lower_filter) then
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
		
		if listbox_width then imgui.set_next_item_width(calc_width * listbox_width) end
		if imgui.begin_list_box(label, #list) then
			for j, name in ipairs(imgui_data[key.."_list"] or short_list) do
				local map_idx = imgui_data[key.."_list"] and imgui_data[key.."_map"][name]
				local desc = desc_list and desc_list[map_idx or j]
				local length = desc and desc:len()
				desc = desc and length > 3 and desc:sub(1, (desc:find("\n") or (length > 30 and 38) or 0) - 1)..(length > 30 and "..." or "") or desc
				if imgui.menu_item(name, desc, (imgui_data[key.."_list_idx"]==j), true) then
					imgui_data[key.."_list_idx"] = j
					savedata[value] = map_idx or j
					changed = true
				end
				local ttip2 = desc_list and desc_list[map_idx or j] ~= "" and desc_list[map_idx or j]
				tooltip(ttip2 and ttip2:gsub("%%", "%%%%") or ttip)
			end
			imgui.end_list_box()
		end
		if indent_amt then imgui.unindent(indent_amt) end
		listbox_ctx_menu(imgui_data, key)
	end
	
	if not skip_wc then 
		set_wc(value, savedata, nil, parent_tbl)
	end
	
	return changed
end

local function check_skillset_name()
	if sms.last_skset and next(sms.last_skset.last_sel_spells or {}) then
		sms.last_skset.has_skillset_name = not not sms.last_skset.name
		for idx, spell_name in pairs(sms.last_skset.last_sel_spells) do
			if sms.last_sel_spells[idx] ~= spell_name then sms.last_skset.has_skillset_name = false; break end
		end
	end
end

local function load_skill(json_data, skill_idx, skill_name, do_load_controls, og_skill, enemy_name, use_em_glob_type)
	if not next(json_data) then return end
	og_skill = og_skill or sms.skills[skill_idx]
	local parent_tbl = enemy_name and sms.enemyskills[enemy_name].skills or sms.skills
	local def_parent_tbl = enemy_name and default_sms.enemyskills[enemy_name].skills or default_sms.skills
	local glob = use_em_glob_type and em_presets_glob or presets_glob
	local imgui_data = use_em_glob_type and imgui_em_skills[enemy_name][skill_idx] or imgui_skills[skill_idx]
	local skill_names = use_em_glob_type and sms.last_sel_em_spells[enemy_name] or sms.last_sel_spells
	imgui_data.preset_idx = func.find_index(glob, skill_name or skill_names[skill_idx]) or 1
	
	if do_load_controls then
		if json_data.hotkey then  
			sms.hotkeys["Use Skill "..skill_idx], hk.hotkeys["Use Skill "..skill_idx] = json_data.hotkey, json_data.hotkey  
		end
	else
		json_data.use_modifier2, json_data.state_type_idx, json_data.use_modifier = og_skill.use_modifier2, og_skill.state_type_idx, nil
	end
	local skill_tbl = update_skill(json_data, skill_idx, enemy_name) 
	skill_tbl = hk.recurse_def_settings(skill_tbl, def_parent_tbl[1])
	skill_tbl.name = skill_name
	
	parent_tbl[skill_idx] = skill_tbl
	--skill_names[skill_idx] = glob[imgui_skills[skill_idx].preset_idx]
	imgui_data.precached_json = json_data
	imgui_data.preset_text = skill_name
	skill_tbl.unedited = nil
	update_last_sel_spells()
end

local function load_skillset(skillset_path, idx)
	sms.last_skset = func.convert_tbl_to_numeric_keys(json.load_file(skillset_path))
	sms.last_skset.name = skillset_path:match(".+\\(.+)%.json")
	local highest_idx = 0; 
	for i, skill_tbl in pairs(sms.last_skset.last_sel_spells or {}) do 
		if i > highest_idx then highest_idx = i end 
	end
	if highest_idx > sms.max_skills then
		sms.max_skills = highest_idx
		setup_default_lists()
		hk.recurse_def_settings(sms, default_sms)
		hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
	end
	if sms.do_clear_spells_on_skset_load then
		for i, skill_tbl in pairs(sms.skills) do
			sms.last_sel_spells[i] = nil
			local prev_ctrls = {use_modifier2=skill_tbl.use_modifier2, skill_tbl.state_type_idx}
			sms.skills[i] = hk.recurse_def_settings({}, default_sms.skills[1])
			func.merge_tables(sms.skills[i], prev_ctrls)
		end
	end
	for i, skill_name in pairs(sms.last_skset.last_sel_spells or {}) do
		local json_data = json.load_file("SkillMaker\\Skills\\"..skill_name..".json")
		if json_data then
			json_data.name = json_data.name or skill_name
			sms.last_sel_spells[i] = skill_name
			load_skill(json_data, i, skill_name)
			if sms.skillsets.loadcontrols[idx] then
				local src_tbl = sms.last_skset.controls and sms.last_skset.controls[i] or default_sms.skills[i] or default_sms.skills[1]
				sms.hotkeys["Use Skill "..i] = src_tbl.hotkey or default_sms.hotkeys["Use Skill "..i] or sms.hotkeys["Use Skill "..i]
				sms.skills[i].state_type_idx, sms.skills[i].use_modifier2 =  src_tbl.state_type_idx, src_tbl.use_modifier2
				sms.skills[i].button_press_type, sms.skills[i].button_hold_time =  src_tbl.button_press_type, src_tbl.button_hold_time
				sms.skills[i] = hk.recurse_def_settings(sms.skills[i], default_sms.skills[1])
			end
		end
	end
	hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
	check_skillset_name()
end

local function get_table_load_fn(fn_str)
	if not fn_str:find("return [%a%(]") then
		fn_str = "return {"..fn_str.."}"
	end
	return load(fn_str)
end

function split(s, delimiter, remove_outer_spaces)
	local result = {}
	for part in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, remove_outer_spaces and part:match("^%s*(.-)%s*$") or part)
	end
	return result
end

local function normalize_single(value, min_input, max_input, min_output, max_output)
	value = math.max(min_input, math.min(max_input, value))
	return min_output + (value - min_input) * (max_output - min_output) / (max_input - min_input)
end

local function clamp(x, lim_a, lim_b)
	if x < lim_a then x = lim_a end
	if x > lim_b then x = lim_b end
	return x
end

local function lerp(a, b, fac) 
	return (a * (1.0 - fac)) + (b * fac);
end
	
local function get_cam_dist_info()
	local cam_ctrl = cam_mgr._MainCameraControllers[0]._CurrentCameraController
	local is_narrow = not not cam_ctrl["<CurrentLevelInfo>k__BackingField"]
	local pl_cam_settings = cam_ctrl[is_narrow and "<CurrentLevelInfo>k__BackingField" or is_aiming and "_AimSetting" or "_PlayerCameraSettings"]
	local dist_name = (is_narrow or is_aiming) and "_Distance" or "_CameraDistance"
	return pl_cam_settings, dist_name
end

local function cleanup(now, do_all)
	
	temp_fns.cleanup_fn = function()
		temp_fns.cleanup_fn = nil
		casted_spells, rel_db = {}, {}
		for i, shell in pairs(shell_mgr.ShellList._items) do
			if shell then shell:get_GameObject():destroy(shell:get_GameObject()) end
		end
		for chr, node_store in pairs(sm_summons) do
			node_store = node_store or em_summons[chr]
			if (do_all or not temp.summon_dummies[chr]) and node_store.summon_updater then  
				--if not node_store.is_possessed then chr:get_GameObject():destroy(chr:get_GameObject()) end
				node_store.summon_updater(true)
			end
		end
	end
	if now then temp_fns.cleanup_fn() end
end

local function reset_character(now, chara)
	chara = chara or player
	
	temp_fns.reset_character_fsm = function()
		temp_fns.reset_character_fsm = nil
		if not chara:get_Valid() then return end
		if chara.EnemyCtrl.Ch2 then
			local exec = chara.EnemyCtrl.Ch2:get_ActInter():get_Executor()
			exec:forceEndActionForState() 
		end
		local act_mgr = chara:get_ActionManager()
		act_mgr.Fsm:restartTree()
		act_mgr:requestActionCore(0, chara == player and "DmgShrinkAirWallCrush" or "NormalLocomotion", 0)
		chara["<StatusConditionCtrl>k__BackingField"]:reqStatusConditionCureAll()
		chara["<Hit>k__BackingField"]:recoverHp(100000.0, false, 0, false)
		chara:get_StaminaManager():recoverAll()
		if chara == player then
			cam_mgr._MainCameraControllers[0]["<BaseOffset>k__BackingField"] = Vector3f.new(0, 1.501, -0.043)
			local pl_cam_settings, dist_name = get_cam_dist_info()
			if pl_cam_settings then pl_cam_settings:call(".ctor") end
			temp_fns.set_nloco = function() temp_fns.set_nloco = nil; act_mgr:requestActionCore(0, 'NormalLocomotion', 0) end
		end
	end
	if now then temp_fns.reset_character_fsm() end
end

local function change_material_float4(main_mesh, color, param_name, do_children, mat_search_term, var_search_term, var_tbl_str, do_print)
	local checked, data_map, var_map = {}, {}
	if (var_tbl_str and var_tbl_str ~= "") then 
		var_map = get_table_load_fn(var_tbl_str)()
	end
	var_map = type(var_map)=="table" and var_map or {}
	for mat_name, sub_tbl in pairs(var_map) do
		data_map[mat_name] = data_map[mat_name] or {}
		for var_name, value in pairs(sub_tbl) do
			if type(value)=="table" then 
				sub_tbl[var_name] = value[2] and Vector4f.new(value[1], value[2], value[3], value[4] or 1) or value
				if value.multiply then data_map[mat_name][var_name] = "*"
				elseif value.add then data_map[mat_name][var_name] = "+"
				elseif value.subtract then data_map[mat_name][var_name] = "-" end
			end 
		end
	end
	
	local function recurse(mesh)
		local mat_count = mesh:get_MaterialNum()
		for m=0, mesh:get_MaterialNum()-1 do
			local mat_name = mesh:getMaterialName(m)
			local vmap = var_map[mat_name] or var_map[1] or {}
			if not mat_search_term or mat_name:find(mat_search_term) then
				if vmap.Enabled == false then 
					mesh:setMaterialsEnable(m, vmap.Enabled)
				else
					for i=0,  mesh:getMaterialVariableNum(m)-1 do
						local var_name, found = mesh:getMaterialVariableName(m, i)
						local vmap_val = vmap[var_name]
						if vmap_val or not checked[var_name] then
							if vmap_val then 
								local op = data_map[mat_name] and data_map[mat_name][var_name]
								if op then 
									local mth = tonumber(vmap_val) and mesh.getMaterialFloat or mesh.getMaterialFloat4
									local current = mth:call(mesh, m, i)
									if op == "*" then vmap_val = tonumber(vmap_val) and vmap_val*current or Vector4f.new(vmap_val.x*current.x, vmap_val.y*current.y, vmap_val.z*current.z, vmap_val.w and vmap_val.w*current.w or 1)
									elseif op == "+" then vmap_val = vmap_val + current
									elseif op == "-" then vmap_val = vmap_val - current end
								end
								if tonumber(vmap_val) then 
									found = mesh:setMaterialFloat(m, i, vmap_val) 
								else
									found = mesh:setMaterialFloat4(m, i, vmap_val)
								end
							elseif var_name == param_name or (var_search_term and var_name:find(var_search_term)) then 
								found = mesh:setMaterialFloat4(m, i, color)
								if var_name == param_name and not next(var_map) then break end
							end
							checked[var_name] = checked[var_name] or not found
						end
					end
				end
			end
		end
		if do_children then
			for c, child in pairs(func.get_children(mesh:get_GameObject():get_Transform()) or {}) do
				local cmesh = func.getC(child:get_GameObject(), "via.render.Mesh")
				if cmesh then
					recurse(cmesh)
				end
			end
		end
	end
	recurse(main_mesh)
end

local function change_efx2_color(efx2, nstore, color_tbl)
	local key = nstore.parent.idx
	local shell = nstore.shell
	color_tbl = color_tbl or shell.coloring
	local coloring = ValueType.new(sdk.find_type_definition("via.Color"))
	coloring:call(".ctor(via.vec4)", Vector4f.new(color_tbl[1], color_tbl[2], color_tbl[3], color_tbl[4]))
	local do_color = shell.do_vfx and table.concat(color_tbl) ~= "1.01.01.01.0"
	local c_effects = {}
	--local radial_blurs = {}
	local start = game_time
	
	temp_fns[efx2] = function(force)
		if (not next(c_effects) and not force) or (game_time - start > sms.shell_lifetime_limit) then
			temp_fns[efx2] = nil
			--for radial, filter in pairs(radial_blurs) do
			--	filter:set_Enabled(true)
			--end
		elseif efx2.CreatedEffectDataList then
			for i, c_effect_data in pairs(efx2.CreatedEffectDataList._items) do
				if not c_effect_data then break end
				for c, c_effect in pairs(func.lua_get_array(c_effect_data.list._items)) do
					if not c_effect then break end
					if not c_effect.IsFinished and not c_effects[c_effect] then --only change new ones
						local try, dict = pcall(func.lua_get_dict, c_effect.CreatedEffects)
						for std_data_elem, effect_player_list in pairs(try and dict or {}) do
							--if do_color then std_data_elem.Color = coloring end
							if effect_player_list._items.__pairs then --weird bug
								for e, effect_player in pairs(effect_player_list._items) do
									if not effect_player then break end
									c_effects[c_effect] = c_effects[c_effect] or {}
									table.insert(c_effects[c_effect], effect_player)
									if do_color then effect_player:set_Color(coloring) end
								end
							end
						end
						if do_color then c_effect:setRootColor(coloring) end
						if not shell.do_vfx then c_effect:killAllInternal() end
					end
				end
			end
		end
		for c_effect, effect_player_list in pairs(c_effects) do
			if c_effect.IsFinished or not effect_player_list[1]:get_Valid() then 
				c_effects[c_effect] = nil
			--[[elseif do_color then
				for i, effect_player in pairs(effect_player_list) do
					local radial = func.getC(effect_player:get_GameObject(), "app.RadialBlurControlUnit")
					if radial and radial._FilterRadialBlur then 
						radial._FilterRadialBlur:set_Enabled(false)
						radial_blurs[radial] = radial._FilterRadialBlur
					end
				end]]
			end
		end
	end
	temp_fns[efx2](true)
	
	if not shell.do_vfx then
		local mesh = func.getC(efx2:get_GameObject(), "app.Shell")["<Mesh>k__BackingField"]
		if mesh then mesh:set_Enabled(false) end
		efx2:call(".cctor()") 
		efx2:call(".ctor()") 
	end
end

local function change_shell_udata(base, smnode)
	local backup, start = base:MemberwiseClone():add_ref(), game_time
	base.UseScale = table.concat(smnode.scale) ~= "1.01.01.0"
	base.Scale = smnode.scale[1] > 0 and smnode.scale[2] > 0 and smnode.scale[3] > 0 and Vector3f.new(smnode.scale[1], smnode.scale[2], smnode.scale[3]) or base.Scale
	base.UseLifeTime = smnode.lifetime >= 0
	base.LifeTime = smnode.lifetime >= 0 and smnode.lifetime or base.LifeTime
	if smnode.omentime ~= -1 then 
		base.UseOmenPhase = smnode.omentime > 0
		base.OmenTime = base.UseOmenPhase and smnode.omentime or base.OmenTime
	end
	if smnode.setland_idx > 1 then
		base.UseSetLand = smnode.setland_idx == 3
	end
	
	pre_fns[base] = pre_fns[base] or function()
		if game_time - start > 0.1 then
			pre_fns[base] = nil
			func.copy_fields(backup, base)
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

local function enable_pl_fsm_on_em(chr)
	local act_mgr = chr:get_ActionManager()
	if act_mgr.Fsm:getLayer(0):get_MotionFsm2Resource():get_ResourcePath():find("000000") then return end
	local new_layer = sdk.create_instance("via.motion.MotionFsm2Layer"):add_ref(); new_layer:call(".ctor()")
	local new_layer2 = sdk.create_instance("via.motion.MotionFsm2Layer"):add_ref(); new_layer2:call(".ctor()")
	new_layer:set_MotionFsm2Resource(func.create_resource("via.motion.MotionFsm2Resource", "AppSystem/ch/ch000/motionfsm/ch000000.motfsm2"))
	new_layer2:set_MotionFsm2Resource(func.create_resource("via.motion.MotionFsm2Resource", "AppSystem/ch/ch000/motionfsm/ch000000_upperbody.motfsm2"))
	act_mgr.Fsm:setLayer(0, new_layer)
	act_mgr.Fsm:setLayer(1, new_layer2)
	
	late_fns[new_layer2] = function()
		local layer0, layer1 = act_mgr.Fsm:getLayer(0), act_mgr.Fsm:getLayer(1)
		if (layer0 and not layer0:get_tree_object()) or (layer1 and not layer1:get_tree_object()) then return end
		late_fns[new_layer2] = nil
		local node = layer0 and layer0:get_tree_object():get_node_by_name("Job07_DragonStinger")
		if node then node:get_unloaded_actions()[1]:set_Enabled(false) end --it crashes
		local node2 = layer1 and layer1:get_tree_object():get_node_by_name("SheatheWeapon")
		if node2 then node2:get_unloaded_actions()[1]:set_Enabled(false) end --Sheathe weapon mot seems to break and must be disabled
	end
end

local function disp_imgui_element(key, value, tip)
	local use_tbl = not EMV and type(value) == "table"
	local use_obj = not (EMV or is_tbl) and (type(value) == "userdata" or type(value) == "number") and sdk.is_managed_object(value)
	local use_tree = (EMV or use_tbl or use_obj)
	
	local opened = use_tree and imgui.tree_node(key)
	if use_tree and tip then tooltip(tip) end
	if opened then 
		if use_tbl then 
			for k, v in pairs(value) do
				disp_imgui_element(k, v)
			end
		elseif use_obj then
			object_explorer:handle_address(value)
		elseif EMV then
			EMV.read_imgui_element(value, nil, nil, key)
		else
			imgui.text(tostring(k) .. ":  " .. tostring(value))
		end
		imgui.tree_pop()
	end
	if not use_tree then
		imgui.text(tostring(key) .. "  :  " .. tostring(value))
	end
end

local function disp_message_box(message, msg_time, color)
	msg_time = msg_time or 5.0
	local start
	
	frame_fns.messagebox = function()
		start = start or os.clock()
		frame_fns.messagebox = os.clock() - start < msg_time and frame_fns.messagebox or nil
		local text_sz = imgui.calc_text_size(message) * 1.25; text_sz.y = text_sz.y * 3.0
		imgui.set_next_window_size(text_sz, 1)
		imgui.set_next_window_pos({temp.disp_sz.x / 2 - (text_sz.x / 2), temp.disp_sz.y / 2 - (text_sz.y / 2)}, 1, {0,0})
		imgui.begin_window("Skill Maker Message", true, 0)
		imgui.text_colored(message, color or 0xFFFFFFFF)
		imgui.end_window()
	end
end

local function drag_and_drop_skill_swapper(i, skill_tbl, imgui_data, current_list, imgui_data_list)
	if imgui.is_item_hovered() then 
		imgui_data.swap_click_start_time = (imgui.is_mouse_clicked() and os.clock()) or imgui_data.swap_click_start_time
		
		if temp.swap_skill_data and not imgui.is_mouse_down() then
			local swap_skill_data = temp.swap_skill_data
			frame_fns.drag_skill, temp.swap_skill_data = nil
			if (swap_skill_data.coords - imgui.get_cursor_screen_pos()):length() < 30 and (swap_skill_data.index ~= i or (current_list ~= swap_skill_data.list)) then		
				local ctrls_map = {}
				for h=1, sms.max_skills do 
					ctrls_map[h] = sms.hotkeys["Use Skill "..h] 
				end
				local swap_idx = swap_skill_data.index
				if ui_mod2_down then
					current_list[i], swap_skill_data.list[swap_idx] = swap_skill_data.skill_tbl, skill_tbl
					if current_list == sms.skills and swap_skill_data.list == sms.skills then
						swap_skill_data.imgui_list[swap_idx], imgui_data_list[i] = imgui_data_list[i], swap_skill_data.imgui_list[swap_idx]
						sms.hotkeys["Use Skill "..i], sms.hotkeys["Use Skill "..swap_idx] = sms.hotkeys["Use Skill "..swap_idx], sms.hotkeys["Use Skill "..i]
						imgui_data_list[i], swap_skill_data.imgui_list[swap_idx] = swap_skill_data.imgui_data, imgui_data
					else 
						local copy = hk.recurse_def_settings({}, imgui_data_list[i])
						imgui_data_list[i], swap_skill_data.imgui_list[swap_idx] = hk.recurse_def_settings(swap_skill_data.imgui_data, copy), hk.recurse_def_settings(imgui_data,  swap_skill_data.imgui_list[swap_idx])
					end
				else
					local function move_element(array, from_index, to_index)
						local element = not ui_mod_down and table.remove(array, from_index) or swap_skill_data.list[from_index]
						table.insert(array, to_index, element)
					end
					if (current_list == sms.skills) and (current_list == swap_skill_data.list) then
						move_element(current_list, swap_idx, i)
						move_element(imgui_data_list, swap_idx, i)
						move_element(ctrls_map, swap_idx, i)
					else
						if #swap_skill_data.list > 1 and not ui_mod_down then
							table.remove(swap_skill_data.list, swap_idx)
							table.remove(swap_skill_data.imgui_list, swap_idx)
							if swap_skill_data.list == sms.skills then 
								table.remove(ctrls_map, swap_idx) 
							end
						end
						
						local sample_imgui = imgui_data_list[1]
						table.insert(current_list, i, ui_mod_down and hk.recurse_def_settings({}, swap_skill_data.skill_tbl) or swap_skill_data.skill_tbl)
						table.insert(imgui_data_list, i, ui_mod_down and hk.recurse_def_settings({}, swap_skill_data.imgui_data) or swap_skill_data.imgui_data)
						hk.recurse_def_settings(imgui_data_list[i], sample_imgui) 
						if current_list == sms.skills then 
							table.insert(ctrls_map, i, "[Not Bound]")
							hk.recurse_def_settings(current_list[i], default_sms.skills[1]) 
						else
							hk.recurse_def_settings(current_list[i], default_sms.enemyskills.Goblin.skills[1]) 
						end
					end
					for h, hotkey in ipairs(ctrls_map) do
						sms.hotkeys["Use Skill "..h] = hotkey
					end
				end
				setup_default_lists()
				hk.recurse_def_settings(sms, default_sms)
				hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
				update_last_sel_spells()
				was_changed = (current_list ~= swap_skill_data.list) and "cross_skillswap" or "skillswap"
				return true
			end
		end
		
		if imgui.is_mouse_down() and imgui_data.swap_click_start_time and os.clock() - imgui_data.swap_click_start_time > 0.15 then 
			imgui_data.swap_click_start_time = nil
			local last_sel_spells = (imgui_data.enemy_name and sms.last_sel_em_spells[imgui_data.enemy_name] or sms.last_sel_spells)
			local text = "Skill ".. i .. "\n" .. (last_sel_spells[i] ~= "Skill "..i and last_sel_spells[i] or "")
			local text_sz = imgui.calc_text_size(text)
			local ticks_st = ticks
			
			frame_fns.drag_skill = frame_fns.drag_skill or function()
				local cursor_pos = sdk.call_native_func(sdk.get_native_singleton("via.hid.Mouse"), sdk.find_type_definition("via.hid.Mouse"), "get_ScreenCursorPosition()")
				if (imgui.is_mouse_down() or ticks_st and (ticks - ticks_st < 5)) and text_sz then 
					imgui.set_next_window_pos({cursor_pos.x-20, cursor_pos.y-text_sz.y}, 1, {0,0})
					imgui.set_next_window_size({text_sz.x * 1.2, text_sz.y * 1.2}, 1)
					imgui.begin_window("dragger", true, 129)
					imgui.text_colored(text, 0xFFFFFFFF)
					imgui.end_window()
					ticks_st = ticks_st and ticks - ticks_st < 2 and ticks_st
				else
					ticks_st, text_sz = ticks_st or ticks, nil
					frame_fns.drag_skill = ticks - ticks_st < 3 and frame_fns.drag_skill or nil
					temp.swap_skill_data = frame_fns.drag_skill and {coords=Vector2f.new(cursor_pos.x, cursor_pos.y), index=i, list=current_list, imgui_list=imgui_data_list, skill_tbl=skill_tbl, imgui_data=imgui_data}
				end
			end
		end
	end
end

local function get_req_tracks(chara) --jfc
	local seq = chara:get_SequenceController()
	local tlist = seq and seq.TracksList
	local tracks = tlist and tlist[0] and tlist[0].Tracks
	return tracks and tracks:ContainsKey(sdk.typeof("app.ColliderReqTracks")) and tracks[sdk.typeof("app.ColliderReqTracks")]
end

local function disp_smnode_imgui(shell, shell_idx, skill_tbl, imgui_data, smnodes, running_skill_tbl, enemy_name, enemy_chr)
	--imgui.push_item_width(imgui.calc_item_width()*0.8)
	
	local imgui_shell = imgui_data.shell_datas[shell_idx] or {enabled=true, opened=false, last_data={}}
	imgui_shell.last_store = running_skill_tbl and running_skill_tbl.storage[shell_idx] or imgui_shell.last_store
	imgui_data.shell_datas[shell_idx] = imgui_shell
	local was_changed_before_node = was_changed
	local is_smnode_running = imgui_data.running_shell and shell.enabled and (imgui_data.running_shell == shell or (imgui_data.running_shell.start == shell.start and game_time - running_skill_tbl.storage.start  - 0.05 <= shell.start))
	if is_smnode_running then imgui.begin_rect(); imgui.begin_rect() end
	local smnode_key = tostring(shell)
	
	local this_action_names = enemy_name and imgui_data.enemy_act_list or action_names
	local this_action_names_numbered = enemy_name and this_action_names.names or action_names_numbered 
	local owner = enemy_chr or player
	
	imgui_shell.border_color = sms.use_colored_nodes and (imgui_shell.border_color or math.random(0x00AAAAAA,0x00DDDDDD) - 1 + 4278190080) or nil
	if sms.use_colored_nodes then imgui.push_style_color(5, imgui_shell.border_color) end
	
	imgui.begin_rect()
	imgui.push_id(shell_idx)
	local is_node_active = (imgui_shell.last_store and pre_fns[imgui_shell.last_store])
	imgui.text_colored("Node "..((shell_idx < 10 and "  " or "")..shell_idx).."   ", not shell.enabled and 0xFF999999 or is_smnode_running and 0xFFAAFFFF or (is_node_active and 0xFFFFFFFF) or 0xFFE0853D)
	tooltip((is_node_active and "This node is managing its spawned shells/summons\n" or "").."Click to "..(imgui_shell.opened and "Collapse" or "Expand").."\nRight click to copy/paste")
	
	local function expander()
		if imgui.is_item_hovered() and imgui.is_mouse_clicked() then
			imgui_shell.opened = not imgui_shell.opened
		elseif imgui_data.clicked_expand then
			imgui_shell.opened = imgui_data.nodes_expanded
		end
	end
	expander()
	
	if imgui.begin_popup_context_item("Node ctx") then
		if imgui.menu_item("Copy") then
			clipboard.shell = hk.recurse_def_settings({}, shell)
		end
		if clipboard.shell and imgui.menu_item("Paste") then
			smnodes[shell_idx] = hk.recurse_def_settings({}, clipboard.shell)
			smnodes[shell_idx].start = shell.start
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
	imgui.text_colored("M", shell.custom_motion ~= "" and 0xFFAAFFAA or 0xFF999999); tooltip("Has Custom Motion"); expander()
	imgui.same_line(); imgui.text("|"); imgui.same_line()
	imgui.text_colored("B", shell.boon_type > 1 and 0xFFAAFFAA or 0xFF999999); tooltip("Has Boon"); expander()
	imgui.same_line(); imgui.text("|"); imgui.same_line()
	imgui.text_colored("Sm", shell.udata_idx > 1 and (shell.summon_idx ~= 1 or (shell.enemy_soft_lock and shell.do_possess_enemy)) and 0xFFAAFFAA or 0xFF999999); tooltip("Has Summon"); expander()
	imgui.same_line(); imgui.text("|"); imgui.same_line()
	imgui.text_colored("Fn", shell.custom_fn ~= "" and 0xFFAAFFAA or 0xFF999999); tooltip("Has Custom Function"); expander()
	imgui.same_line(); imgui.text("|"); imgui.same_line()
	imgui.text_colored(string.format("%3.02fs", (smnodes[shell_idx+1] and smnodes[shell_idx+1].start or skill_tbl.duration) - shell.start), is_smnode_running and 0xFFFFFFFF or 0xFF999999); tooltip("Duration"); expander()
	if shell.name ~= "" then 
		imgui.same_line(); imgui.text("|"); imgui.same_line(); imgui.text_colored(shell.name, 0xFFFFAAAAFF)
	end
	
	--imgui.same_line()
	--imgui.text_colored((selected_shell == shell) and "SELECTED" or "", 0xFFAAFFFF)
	if not imgui_shell.opened then imgui.spacing() end
	
	if not imgui_shell.opened then
		shell.start = shell.start + imgui_data.shift_amt
		imgui.pop_id()
		imgui.end_rect(0)
	else
		if imgui.button(" + ") then
			table.insert(smnodes, shell_idx+1, hk.merge_tables({}, shell))
			was_changed, skill_tbl.enabled = true, true
		end
		tooltip("Add a new node")
		
		imgui.same_line()
		if imgui.button(" - ") and #smnodes > 1 then
			table.remove(smnodes, shell_idx)
			was_changed = true
		end
		tooltip("Remove this node")
		
		imgui.same_line()
		local prev_shell_start = shell.start
		changed, shell.start = imgui.slider_float("Start Time / Name", shell.start + imgui_data.shift_amt, 0, skill_tbl.duration, "%.2fs"); set_wc()
		tooltip("The start time of the this node during the skill\nHold "..sms.hotkeys["UI Modifier"].." (UI Modifier) to move all start times in the nodes below along with it\nRight click to set node name")
		
		imgui_data.shift_amt = (changed and ui_mod_down and (shell.start - prev_shell_start)) or imgui_data.shift_amt
		if shell.start > skill_tbl.duration then shell.start = skill_tbl.duration end
		if shell.start < (imgui_data.last_start) then shell.start = imgui_data.last_start end
		imgui_data.last_start = shell.start
		
		if imgui.begin_popup_context_item(3923425 + shell_idx) then  
			if imgui.menu_item(imgui_data.show_node_name and "Hide name" or "Show name") then
				imgui_data.show_node_name = not imgui_data.show_node_name
			end
			imgui.end_popup() 
		end
		
		if imgui_data.show_node_name then 
			imgui.indent(60)
			changed, shell.name = imgui.input_text("Node Name", shell.name); set_wc("name", shell, "", smnodes);
			tooltip("The name of this node, for your reference")
			imgui.unindent(60)
		end
		
		if imgui.arrow_button("Up", 2) and shell_idx > 1 then
			smnodes[shell_idx-1].start, smnodes[shell_idx].start = shell.start, smnodes[shell_idx-1].start
			smnodes[shell_idx-1], smnodes[shell_idx] = shell, smnodes[shell_idx-1]
			was_changed = true
		end
		tooltip("Move this node up one")
		
		imgui.same_line()
		if imgui.arrow_button("Down", 3) and shell_idx < #smnodes then
			smnodes[shell_idx+1].start, smnodes[shell_idx].start = shell.start, smnodes[shell_idx+1].start
			smnodes[shell_idx+1], smnodes[shell_idx] = shell, smnodes[shell_idx+1]
			was_changed = true
		end
		tooltip("Move this node down one")
		
		imgui.same_line()
		if expand_as_listbox(imgui_shell, "action", shell, "action_idx", "Action", this_action_names, this_action_names_numbered, tooltips, 
		"The action that will play when running this node\nRight click to show/hide list box\nInput 'Reset' to force reset the character\nDouble-click in list box to preview", smnodes, false, 60) then
			local ticks = 0
			
			temp_fns.play_action = function()
				temp_fns.play_action, ticks = ticks < 3 and temp_fns.play_action or nil, ticks + 1
				if imgui.is_mouse_double_clicked() then --it only reports the change 3 frames later..
					owner:get_ActionManager():requestActionCore(0, this_action_names[shell.action_idx], tooltips[shell.action_idx]=="" and 0 or 1)
				end
			end
		end
		
		changed, shell.enabled = imgui.checkbox("On  ", shell.enabled); set_wc("enabled", shell, true, smnodes); imgui.same_line()
		tooltip("Enable/disable use of this node")
		
		imgui.indent(60)
		
		if shell.action_idx == 2 then
			changed, shell.action_name = ui.imgui_safe_input(imgui.input_text, smnode_key.."actname", "Custom Action Name", shell.action_name); set_wc()
		else
			shell.action_name = this_action_names[shell.action_idx]
		end
		local calc_width = imgui.calc_item_width()
		expand_as_listbox(imgui_shell, "udata", shell, "udata_idx", "Shell File", user_paths_short, user_paths_short, udata_descs, "The userdata file containing the collection of smnodes selectable with 'Shell ID'\nRight click to show/hide list box", smnodes)
		if changed then shell.shell_id = 0; imgui_shell.shell_list_idx = 1; imgui_shell.shell_list = nil end
		
		local udata_path = user_paths[shell.udata_idx]
		udatas[udata_path] = udatas[udata_path] or sdk.create_userdata("app.ShellParamData", udata_path)
		shell.max_ids = udatas[udata_path].ShellParams._size
		shell.udata_name = user_paths[shell.udata_idx]
		
		if shell.udata_idx > 1 then
			local sdesc_tbl = shell_descs[user_paths_short[shell.udata_idx]:match("\t(.+)")]
			
			shell.shell_id = shell.shell_id + 1
			if expand_as_listbox(imgui_shell, "shell", shell, "shell_id", "Shell ID", sdesc_tbl.titles, sdesc_tbl.titles, sdesc_tbl.descs, "The ID of the shell in the file\nRight click to show/hide list box\nDouble-click in list box to preview", smnodes) and shell.cast_type == 3 then
				local ticks = 0
				temp_fns.play_action = function()
					temp_fns.play_action, ticks = ticks < 3 and temp_fns.play_action or nil, ticks + 1
					if imgui.is_mouse_double_clicked() then --it only reports the change 3 frames later..
						cast_shell(shell, {}, player, true)
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
		end
		
		if enemy_name then
			local ch2_name = func.find_key(enemy_list, enemy_name, "name"):sub(1,5)
			imgui_shell.def_category_idx = imgui_shell.def_category_idx or func.find_key(enemy_behaviors_imgui.categories, ch2_name)
			if shell.enemy_behavior_category == 0 then 
				shell.enemy_behavior_category = imgui_shell.def_category_idx
			end
			imgui.push_id(7777 + shell_idx)
			imgui.set_next_item_width(calc_width * 0.2)
			changed, shell.enemy_behavior_category = imgui.combo("", shell.enemy_behavior_category, enemy_behaviors_imgui.categories_named); set_wc("enemy_behavior_category", shell, imgui_shell.def_category_idx, smnodes) 
			tooltip("The type of behavior to be used")
			imgui.pop_id() 
			if changed then 
				shell.enemy_behavior_type, imgui_shell.enemy_behavior_list = 1
			end
			imgui.same_line()
			imgui.set_next_item_width(calc_width * 0.79)
			local bhv_cat = enemy_behaviors_imgui.categories[shell.enemy_behavior_category]
			expand_as_listbox(imgui_shell, "enemy_behavior_type", shell, "enemy_behavior_type", "Behavior", enemy_behaviors_imgui[bhv_cat], nil, nil, "The AI task that the enemy will perform when this node is triggered", smnodes)
		end
		
		if shell.udata_idx > 1 then
			changed, shell.cast_type = imgui.combo("Cast Type", shell.cast_type, {"Target", "Skyfall", "Owner", "Previous Shell"}); set_wc("cast_type", shell, 1, smnodes)
			tooltip("The spawn location of the shell")
			
			local has_summon_joint = shell.cast_type == 4 and smnodes[shell_idx-1] and smnodes[shell_idx-1].summon_idx > 1
			if shell.cast_type == 3 or has_summon_joint then --player / summon attach
				
				changed, shell.joint_idx = imgui.combo(has_summon_joint and "Summon Attach Joint" or "Joint Name", shell.joint_idx, joint_list); set_wc("joint_idx", shell, 1, smnodes)
				if changed then shell.joint_name = shell.joint_idx > 1 and joint_list[shell.joint_idx] or shell.joint_name end
				tooltip("Select a joint name from the list")
				if shell.joint_idx == 1 then
					changed, shell.joint_name = ui.imgui_safe_input(imgui.input_text, smnode_key.."inputjoint", "Input Joint Name", shell.joint_name or "root"); set_wc("joint_name", shell, "root", smnodes)
					tooltip("The joint on the player that the shell will spawn on")
				end
				
				changed, shell.rot_type_idx = imgui.combo("Rotation Type", shell.rot_type_idx, {"Joint", "Player Base", "Crosshair"}); set_wc("rot_type_idx", shell, false, smnodes)
				tooltip("The rotation of the spawned shell on the player can be relative to the joint its mounted to, relative to the overall player rotation, or can be pointed towards the crosshair")
				
				changed, shell.attach_to_joint = imgui.checkbox("Attach to Joint", shell.attach_to_joint); set_wc("attach_to_joint", shell, false, smnodes)
				tooltip("If checked, the shell will be mounted on the selected joint until it expires")
				
				imgui.same_line()
				changed, shell.do_no_attach_rotate = imgui.checkbox("No Attach Rotation", shell.do_no_attach_rotate); set_wc("do_no_attach_rotate", shell, false, smnodes)
				tooltip("If checked, the shell will not rotate while attached to the selected joint")
				
				if shell.cast_type == 3 and shell.rot_type_idx < 3 then
					imgui.same_line()
					changed, shell.do_aim_up_down = imgui.checkbox("Aim Up/Down", shell.do_aim_up_down); set_wc("do_aim_up_down", shell, false, smnodes)
					tooltip("If checked, the projectile will be aimed up or down from its joint based on the camera direction\nCan be combined with 'Soft Lock' to autoaim at aligned enemies")
				end
			end
			
			if shell.cast_type ~= 2 then
				changed, shell.attach_pos = ui.table_vec(imgui.drag_float3, "Position Offset", shell.attach_pos, {0.01, -10000, 10000}); set_wc("attach_pos", shell, {0,0,0}, smnodes)
				tooltip("This offset will be added to the shell spawn position (X / Y / Z)")
				
				changed, shell.attach_euler = ui.table_vec(imgui.drag_float3, "Rotation Offset", shell.attach_euler or {0,0,0}, {0.01, -math.pi, math.pi}); set_wc("attach_euler", shell, {0,0,0}, smnodes)
				tooltip("This offset will be added to the shell spawn rotation (Pitch / Yaw / Roll)")
			end
			
			if shell.cast_type == 2 then --skyfall
				changed, shell.skyfall_pos_offs = ui.table_vec(imgui.drag_float3, "Skyfall Position Offset", shell.skyfall_pos_offs or {0,0,0}, {0.01, -10000, 10000}); set_wc("skyfall_pos_offs", shell, {0,100,0}, smnodes)
				tooltip("This offset will be added to the player's position to determine where the shell will spawn")
				
				changed, shell.skyfall_dest_offs = ui.table_vec(imgui.drag_float3, "Skyfall Destination Offset", shell.skyfall_dest_offs or {0,0,0}, {0.01, -10000, 10000}); set_wc("skyfall_dest_offs", shell, {0,0,0}, smnodes)
				tooltip("This offset will be added to the crosshair position to determine where the shell will travel towards")
				
				changed, shell.skyfall_random_xz = imgui.checkbox("Skyfall Random XZ", shell.skyfall_random_xz); set_wc("skyfall_random_xz", shell, true, smnodes)
				tooltip("If checked, the the X and Z coordinates of the Skyfall Position Offset will be set within a random range of [-x, x] and [-z, z]")
				
				imgui.same_line()
				changed, shell.skyfall_cam_relative = imgui.checkbox("Skyfall Cam-Relative", shell.skyfall_cam_relative); set_wc("skyfall_cam_relative", shell, true, smnodes)
				tooltip("If checked, skyfall's position coordinates will be made relative to the camera position rather than to the player position")
			end
			
			if shell.cast_type == 4 then --previous shell
				changed, shell.pshell_attach_type = imgui.combo("Shell Attach Type", shell.pshell_attach_type, {"Don't Attach", "Attach Always", "Attach Until Contact", "Attach Always (With Children)", "Attach Until Contact (With Children)"}); set_wc("pshell_attach_type", shell, false, smnodes)
				tooltip("The shell can be mounted on the previous shell until the previous shell expires or until the previous shell hits something")
				
				changed, shell.do_carryover_prev = imgui.checkbox("Continuous Shell", shell.do_carryover_prev); set_wc("do_carryover_prev", shell, true, smnodes)
				tooltip("If checked, the previous shell position and rotation will be carried over from the previous node, allowing one Previous Shell to be used by multiple nodes even though it's not directly 'previous' in the sequence")
			end
		
			local old = shell.scale
			imgui.unindent(60)
			changed, imgui_data.scale_together = imgui.checkbox("       ", imgui_data.scale_together); imgui.same_line(); tooltip("Scale XYZ together")
			imgui.indent(60)
			changed, shell.scale = ui.table_vec(imgui.drag_float3, "Shell Scale", shell.scale, {0.01, 0.01, 10, "%.2fx"}); set_wc("scale", shell, {1.0,1.0,1.0}, smnodes)
			tooltip("The size of the effect")		
			if changed and imgui_data.scale_together then
				if old[1] ~= shell.scale[1] then shell.scale = {shell.scale[1], shell.scale[1], shell.scale[1]} end
				if old[2] ~= shell.scale[2] then shell.scale = {shell.scale[2], shell.scale[2], shell.scale[2]} end
				if old[3] ~= shell.scale[3] then shell.scale = {shell.scale[3], shell.scale[3], shell.scale[3]} end
			end
			
			changed, shell.speed = imgui.drag_float("Shell Speed", shell.speed, 0.01, 0.0, 10.0, "%.2fx"); set_wc("speed", shell, 1.0, smnodes)
			tooltip("The speed of this shell")		
			
			changed, shell.attack_rate = imgui.drag_float("Shell Attack Rate", shell.attack_rate, 0.01, 0.0, 1000.0, "%.3fx"); set_wc("attack_rate", shell, 1.0, smnodes)
			tooltip("The amount of damage this shell deals")	
			
			drag_float_neg_one("Shell Lifetime", shell, "lifetime", 0.01, 1000.0, "%.2f seconds"); set_wc("lifetime", shell, -1.0, smnodes); set_wc("lifetime", shell, -1.0, smnodes)
			tooltip("How long this shell will exist\nSet to -1 to leave unmodified\nSet to -2 to delete the shell after the next node")
			
			drag_float_neg_one("Shell Omen Time", shell, "omentime", 0.01, 1000.0, "%.2f seconds"); set_wc("omentime", shell, -1.0, smnodes); set_wc("omentime", shell, -1.0, smnodes)
			tooltip("The amount of warning time given before the shell goes off\nSet to 0 to disable\nSet to -1 to leave unmodified")
		
			changed, shell.coloring = ui.table_vec(imgui.color_edit4, "Shell Coloring", shell.coloring, {17301504}); set_wc("coloring", shell, {1.0,1.0,1.0,1.0}, smnodes, "The color of the shell's visual effects (Red / Blue / Green / Alpha)")
			
			changed, shell.setland_idx = imgui.combo("Set Land", shell.setland_idx, {"Default", "Off", "On"}); set_wc("setland_idx", shell, false, smnodes)
			tooltip("Whether the shell will appear only on the ground or if it can appear in midair")
			
			--changed, shell.shell_option = imgui.drag_int("Shell Option", shell.shell_option, 1, -1, 1000); set_wc("shell_option", shell, -1.0, smnodes)
			--tooltip("The amount of warning time given before the shell goes off\nSet to 0 to disable\nSet to -1 to leave unmodified")
			
			--changed, shell.enchant_type = imgui.combo("Shell Enchantment", shell.enchant_type, {"Default Enchantment", "No Enchantment", "Fire Enchantment", "Ice Enchantment", "Thunder Enchantment", "Light Enchantment"}); set_wc("enchant_type", shell, 1, smnodes)
			--tooltip("The shell will carry this elemental power")
			
			changed, shell.dmg_type_shell = imgui.combo("Shell Damage Type", shell.dmg_type_shell, enums.dmgs); set_wc("dmg_type_shell", shell, 1, smnodes)
			tooltip("The type of damage the shell created during this node will do")
		end
		
		if shell.udata_idx > 1 then  end
		changed, shell.turn_idx = imgui.combo("Turn Player", shell.turn_idx, {"Don't Turn", "Turn to Analog Stick", "Turn to Camera", "Turn to Target"}); set_wc("turn_idx", shell, 1, smnodes)
		tooltip("Make the player turn in the direction being inputted, in the direction that the camera is looking or in the direction of the nearest target")
		
		if shell.turn_idx == 2 or shell.turn_idx == 4 then
			changed, shell.turn_speed = imgui.drag_float("Turn Speed", shell.turn_speed, 0.001, 0.0, 2.0, "%.4fx"); set_wc("turn_speed", shell, 1.0, smnodes)
			tooltip("The speed at which you will turn with 'Turn to Analog Stick' enabled")
		end
		
		if shell.udata_idx > 1 and shell.summon_idx > 1 then
			changed, shell.summon_no_dissolve = imgui.checkbox("Summon No-Dissolve", shell.summon_no_dissolve); set_wc("summon_no_dissolve", shell, false, smnodes)
			tooltip("The summoned enemy will instantly materialize rather than dissolve into reality")
			
			imgui.same_line()
			changed, shell.summon_hostile = imgui.checkbox("Hostile Summon", shell.summon_hostile); set_wc("summon_hostile", shell, false, smnodes)
			tooltip("Make this summon be an enemy")
			
			if shell.summon_hostile then
				imgui.same_line()
				changed, shell.summon_hostile_to_all = imgui.checkbox("Hostile to All", shell.summon_hostile_to_all); set_wc("summon_hostile_to_all", shell, false, smnodes)
				tooltip("Make this summon be hostile to everyone")
			end
		end
		
		changed, shell.do_mirror_action = imgui.checkbox("Mirror", shell.do_mirror_action); set_wc("do_mirror_action", shell, false, smnodes)
		tooltip("The animation of the action will be flipped left to right")
		
		imgui.same_line()
		changed, shell.do_mirror_wp = imgui.checkbox("Mirror Wp", shell.do_mirror_wp); set_wc("do_mirror_wp", shell, false, smnodes)
		tooltip("Your weapon will be moved to the opposite hand")
		
		if shell.action_idx > 1 then
			imgui.same_line()
			changed, shell.do_simplify_action = imgui.checkbox("Simplify Action", shell.do_simplify_action); set_wc("do_simplify_action", shell, false, smnodes)
			tooltip("If checked, only the animation part of the action will be enabled")
		end
		
		local is_cast_hold = false
		if shell.action_idx > 1 and (shell.action_name:find("Prepare") or shell.action_name:find("Ready")) then
			
			changed, shell.do_hold = imgui.checkbox("Hold", shell.do_hold); set_wc("do_hold", shell, false, smnodes)
			tooltip("The next node will not start until the Prepare animation is completed or the modifier is let go after the node's time is over")
			local subbed = shell.action_name:sub(1,5)
			is_cast_hold = subbed == "Job03" or subbed == "Job06" or subbed == "JobMa"
			if shell.do_hold and not imgui.same_line() then
				changed, shell.do_true_hold = imgui.checkbox("True Hold", shell.do_true_hold); set_wc("do_true_hold", shell, false, smnodes)
				tooltip("The next node will not start until the Prepare animation is completed\nUse this only with the correct weapon for the animation")
			end
		elseif shell.do_hold then
			shell.do_hold, shell.do_true_hold = false, false
		end
		
		if shell.udata_idx > 1 then
			changed, shell.do_vfx = imgui.checkbox("VFX", shell.do_vfx); set_wc("do_vfx", shell, true, smnodes)
			tooltip("Render visual effects for this shell")
			
			imgui.same_line()
			changed, shell.do_sfx = imgui.checkbox("SFX", shell.do_sfx); set_wc("do_sfx", shell, true, smnodes)
			tooltip("Play sound effects for this shell")
		
			imgui.same_line() 
			changed, shell.do_teleport_player = imgui.checkbox("Pl Teleport", shell.do_teleport_player); set_wc("do_teleport_player", shell, false, smnodes)
			tooltip("The player will be teleported to the location of the shell")
			
			imgui.same_line() 
			changed, shell.is_decorative = imgui.checkbox("Decorative", shell.is_decorative); set_wc("is_decorative", shell, false, smnodes)
			tooltip("Makes it so this shell will not collide with anything")
			
			if shell.lifetime >= 0 then
				imgui.same_line() 
				changed, shell.do_abs_lifetime = imgui.checkbox("Abs. Lifetime", shell.do_abs_lifetime); set_wc("do_abs_lifetime", shell, false, smnodes)
				tooltip("Makes it so this shell will not expire before its lifetime is up")
			end
			
			imgui.same_line()
			changed, shell.enemy_soft_lock = imgui.checkbox("Soft Lock", shell.enemy_soft_lock); set_wc("enemy_soft_lock", shell, false, smnodes)
			tooltip("The shell will jump onto the nearest enemy to its position or target position")
			
			if shell.enemy_soft_lock then 
				imgui.same_line()
				changed, shell.do_possess_enemy = imgui.checkbox("Possess Enemy", shell.do_possess_enemy); set_wc("do_possess_enemy", shell, false, smnodes)
				tooltip("The enemy found by 'Soft Lock' will be turned to fight by your side")
			end
		end
		shell.do_possess_enemy = shell.udata_idx > 1 and shell.enemy_soft_lock and shell.do_possess_enemy
		
		changed, shell.do_inhibit_buttons = imgui.checkbox(enemy_name and "Don't Think" or "Inhibit", shell.do_inhibit_buttons); set_wc("do_inhibit_buttons", shell, false, smnodes)
		tooltip("You cannot move or do anything while this node is active\nOn enemies, this prevents their AI from doing anything during this node")
		
		if shell.turn_idx > 1 or (shell_idx > 1 and smnodes[shell_idx-1].do_turn_constantly and smnodes[shell_idx-1].turn_idx > 1) then
			imgui.same_line()
			changed, shell.do_turn_constantly = imgui.checkbox("Turn Constantly", shell.do_turn_constantly); set_wc("do_turn_constantly", shell, false, smnodes)
			tooltip("The player will constantly turn in the direction from 'Turn Player' during this node")
			--[[if shell.turn_idx == 2 then 
				imgui.same_line()
				changed, shell.do_pl_soft_lock = imgui.checkbox("Pl Soft Lock", (shell.pl_velocity_type == 7) or shell.do_pl_soft_lock); set_wc("do_pl_soft_lock", shell, false, smnodes)
				tooltip("The player will snap-turn towards enemies nearest in the direction of the analog stick")
				has_pl_soft_lock = true
			end]]
		end
	
		imgui.same_line()
		changed, shell.do_iframes = imgui.checkbox("Pl Invincibility", shell.do_iframes); set_wc("do_iframes", shell, false, smnodes)
		tooltip("The player will be invincible during this node")
		
		imgui.same_line()
		changed, shell.freeze_crosshair = imgui.checkbox("Freeze Crosshair", shell.freeze_crosshair); set_wc("freeze_crosshair", shell, false, smnodes)
		tooltip("If checked while using the crosshair to cast, the crosshair's position from the previous node will carry over into this node")
		
		if shell.enemy_soft_lock and shell.udata_idx > 1 then
			changed, shell.soft_lock_range = imgui.drag_float("Soft Lock Range", shell.soft_lock_range, 0.01, -1.0, 1000.0, "%.2f meters"); set_wc("soft_lock_range", shell, 1.5, smnodes)
			tooltip("The maximum distance that the shell will travel from its expected position to jump onto an enemy")
			
			changed, shell.soft_lock_type = imgui.combo("Soft Lock Type", shell.soft_lock_type, {"Living Enemies", "Dead Enemies", "Living and Dead Enemies"}); set_wc("soft_lock_type", shell, 1, smnodes)
			tooltip("Choose which type of enemies can be found by 'Soft Lock'")
		end
		
		if is_cast_hold then
			changed, shell.hold_color = ui.table_vec(imgui.color_edit4, "Hold Coloring", shell.hold_color, {17301504}); set_wc("hold_color", shell, {1.0,1.0,1.0,1.0}, smnodes, "The color of the prepare casting action's visual effects (Red / Blue / Green / Alpha)")
		end
		
		if shell.do_mirror_action or shell.do_mirror_wp then
			
			drag_float_neg_one("Mirror Time", shell, "mirror_time", 0.01, 10000.0, "%.2f seconds"); set_wc("mirror_time", shell, -1.0, smnodes)
			tooltip("How long the animation will stay mirrored after the start of this node\nSet to -1 to mirror until the end of the action")
		end 
		
		if not shell.do_possess_enemy and shell.udata_idx > 1 then
			if expand_as_listbox(imgui_shell, "summon_idx", shell, "summon_idx", "Summon", enemy_names, nil, nil, "Select a monster that will spawn on this shell\nRight click to show/hide list box", smnodes) then 
				shell.summon_action_idx, shell.summon_behavior_type = 1 , 1
				shell.summon_behavior_category = func.find_key(enemy_behaviors_imgui.categories, enemy_names[shell.summon_idx]:match("(ch%d%d%d)"))
			end
		end
		
		if (shell.udata_idx > 1 and shell.summon_idx > 1) or shell.do_possess_enemy then
			
			if not shell.do_possess_enemy then
				local full_path = enemy_names[shell.summon_idx]
				local em_name = full_path:match("(.+) %- "); em_name = em_name:match(".+%((.+)%)") or em_name
				expand_as_listbox(imgui_shell, "summon_action", shell, "summon_action_idx", "Summon Action", enemy_action_names[em_name].names, nil, nil, "The action that the enemy will perform when spawned\nRight click to show/hide list box", smnodes)
				--[[if shell.summon_action_idx == 2 then
					changed, shell.summon_action_name = ui.imgui_safe_input(imgui.input_text, smnode_key.."sumactname", "Summon Action Name", shell.summon_action_name); set_wc()
				else
					shell.summon_action_name = enemy_action_names[em_name].names[shell.summon_action_idx]
				end]]
				
				local ch2_name = full_path:match("ch%d%d%d")
				
				imgui.push_id(6666 + shell_idx)
				imgui.set_next_item_width(calc_width * 0.2)
				changed, shell.summon_behavior_category = imgui.combo("", shell.summon_behavior_category, enemy_behaviors_imgui.categories_named); set_wc("summon_behavior_category", shell, func.find_key(enemy_behaviors_imgui.categories, ch2_name) or 1, smnodes) 
				tooltip("The type of behavior to be used")
				imgui.pop_id() 
				if changed then 
					shell.summon_behavior_type, imgui_shell.summon_behavior_list = 1
				end
				imgui.same_line()
				imgui.set_next_item_width(calc_width * 0.79)
				local bhv_cat = enemy_behaviors_imgui.categories[shell.summon_behavior_category]
				expand_as_listbox(imgui_shell, "summon_behavior_type", shell, "summon_behavior_type", "Summon Behavior", enemy_behaviors_imgui[bhv_cat], nil, nil, "The behavior that the enemy will perform when spawned\nRight click to show/hide list box", smnodes)
				
				if ch2_name=="ch230" then
					imgui.push_id(1423526+shell_idx)
					changed, shell.partswap_data = expand_as_text_box(imgui_data, smnode_key.."hmdata", "", shell.partswap_data); set_wc()
					imgui.same_line()
					imgui.text("Summon Human Data")
					tooltips.parts_data = tooltips.parts_data or "Input the contents of a Lua table specifying the armor and weapons to be used by the humanoid. Strings, ID's and indexes are accepted\n"
					.."You can use REFramework's 'DeveloperTools' type search to search for 'app.CharacterEditDefine.MetaData' to see which fields you can set,\nand you can search for 'Style' to find the names of values in each enum (as their TDB fields). Separate entries with commas.\n"
					.."'Styles.json' from Mesh Mod Enabler's 'Json Style Database' is also helpful for finding armors\n	Example:\n		_RightWeapon='wp08_009_00', _Gender='Female', \n		_BeardStyle='None', \n		_HeadStyle=({1,8,17,18,22,23,25})[math.random(1,7)], "
					.."\n		_SkinStyle='Skin_002', \n		_HairStyle='Style_001'\n		_HelmStyle=0, \n		_MantleStyle='None', \n		_TopsStyle='Tops_023', \n		_PantsStyle='Pants_023', \n		_FacewearStyle='Facewear_304', \n		_Locked='None'"
					.."\nAlternatively, you can put a code block in here that returns the table contents described above (as a table)"
					tooltip(tooltips.parts_data)
					imgui.pop_id()
				end
			end
			
			changed, shell.summon_timer = imgui.drag_float("Summon Time Limit", shell.summon_timer, 0.1, 0.0, 10000.0, "%.2f seconds"); set_wc("summon_timer", shell, 1, smnodes)
			tooltip("How long the summon can exist, or how long possession will last")
			
			if not shell.do_possess_enemy then
				changed, shell.summon_scale = imgui.drag_float("Summon Scale", shell.summon_scale, 0.01, 0.01, 100.0, "%.2fx"); set_wc("summon_scale", shell, 1, smnodes)
				tooltip("How large or small the summon will be, relative to its normal size")
			end
			
			changed, shell.summon_attack_rate = imgui.drag_float("Summon Attack Rate", shell.summon_attack_rate, 0.01, 0.01, 100.0, "%.2fx"); set_wc("summon_attack_rate", shell, 1, smnodes)
			tooltip("Multiplier for how much damage the summon will deal with its attacks")
			
			changed, shell.summon_hp_rate = imgui.drag_float("Summon HP Rate", shell.summon_hp_rate, 0.01, 0.01, 100.0, "%.2fx"); set_wc("summon_hp_rate", shell, 1, smnodes)
			tooltip("Multiplier for how much health the summon will have")
			
			changed, shell.summon_speed = imgui.drag_float("Summon Speed", shell.summon_speed, 0.01, 0.01, 100.0, "%.2fx"); set_wc("summon_speed", shell, 1, smnodes)
			tooltip("Multiplier for how fast the summon will be")
			
			changed, shell.summon_color = ui.table_vec(imgui.color_edit3, "Summon Color", shell.summon_color, {17301504}); 
			set_wc("summon_color", shell, {1.0,1.0,1.0}, smnodes, "The color of the summon's meshes. Changes 'BaseColor' by default, but can change other fields using 'Summon Color Search Terms'")
			
			if table.concat(shell.summon_color) ~= "1.01.01.0" then
				imgui.push_id(9564841 + shell_idx)
				imgui.set_next_item_width(calc_width * 0.4955)
				changed, shell.summon_col_mat_term = ui.imgui_safe_input(imgui.input_text, smnode_key.."smatvars", "", shell.summon_col_mat_term); set_wc("summon_col_mat_term", shell, "", smnodes)
				tooltip("Material name search\nWhen changing summon color, different materials will be changed based on the search term in this box. Lua patterns (similar to regex) are accepted\nFor example, [Bb]ody will change every material with 'body' or 'Body' in the name"
					.."\nUse EMV Engine, MDF-XL or any MDF file tools to find parameter names and test values")
				imgui.same_line()
				imgui.set_next_item_width(calc_width * 0.4955)
				changed, shell.summon_col_var_term = ui.imgui_safe_input(imgui.input_text, smnode_key.."scolvars", "Summon Color Mat/Var Search", shell.summon_col_var_term); set_wc("summon_col_var_term", shell, "", smnodes)
				tooltip("Variable name search\nWhen changing summon color, different variables will be changed based on the search term in this box. Lua patterns (similar to regex) are accepted\nFor example, .*olor.* will change every variable with 'color' in the name"
					.."\nUse EMV Engine, MDF-XL or any MDF file tools to find parameter names and test values")
				imgui.pop_id()
			end
			imgui.push_id(-3245346 + shell_idx)
			changed, shell.summon_var_tblstr = expand_as_text_box(imgui_data, smnode_key.."sumvar", "", shell.summon_var_tblstr); set_wc()
			imgui.same_line()
			imgui.text("Summon Variable Lua Table")
			tooltips.summon_matvars = tooltips.summon_matvars or "A list of specific material parameters can be changed by inputting a list of Lua tables in this box.\nThe text will be wrapped into a larger Lua table and treated as table contents, so separate with commas.\n"
			.."For example, this would enable bright red emission on all materials, make the left eye solid white,\n	and disable a cloth material (while ignoring the commented-out color entry):\n\n	{EmissiveColor2={1,0,0,1}, Emissive_Intensity=50.0, Emissive_Enable=1.0},\n	l_eye_mat={BaseColor={100,100,100}},"
			.."\n	am_023_0_0_Canvas_mat={\n		Enabled=false,\n		--BaseColor={1,1,1},\n	},\n\nChange params in specific materials by including tables like [Mat name]={ParamName=Value}"
			.."\nChange for all materials by using a table with no name.\nAlternatively, you can put a code block in here that returns the table contents described above (as a table)"
			.."\nUse EMV Engine, MDF-XL or any MDF file tools to find parameter names and test values\n"
			tooltip(tooltips.summon_matvars)
			imgui.pop_id()
		end
		
		if not enemy_name then			
			drag_float_neg_one("Camera Distance", shell, "camera_dist", 0.01, 100.0, "%.2f meters"); set_wc("camera_dist", shell, -1.0, smnodes)
			tooltip("How far the camera will be from the player\nSet to -1 to leave unmodified")
		end
		
		imgui.set_next_item_width(calc_width*0.24)
		imgui.push_id(-23543456 + shell_idx)
		changed, shell.action_vfx_color_time = imgui.drag_float("", shell.action_vfx_color_time, 0.001, 0, 1000, "%.3f seconds"); set_wc("action_vfx_color_time", shell, 0, smnodes)
		imgui.pop_id()
		tooltip("For this many seconds after this node starts, created player visual effects will be colored")
		imgui.same_line()
		imgui.set_next_item_width(calc_width*0.75)
		changed, shell.action_vfx_color = ui.table_vec(imgui.color_edit4, "Action VFX Coloring", shell.action_vfx_color, {17301504}); set_wc("action_vfx_color", shell, {1.0,1.0,1.0,1.0}, smnodes, "The color any player-owned VFX objects that appear in the moment after the node starts")
		
		changed, shell.boon_type = imgui.combo("Boon Type", shell.boon_type, {"None", "Fire", "Ice", "Thunder"}); set_wc("boon_type", shell, 1.0, smnodes)
		tooltip("Your weapon will have this boon applied during this node")
		
		if shell.boon_type > 1 then
			changed, shell.boon_color = ui.table_vec(imgui.color_edit4, "Boon Coloring", shell.boon_color, {17301504}); set_wc("boon_color", shell, {1.0,1.0,1.0,1.0}, smnodes, "The color of the boon's visual effects (Red / Blue / Green / Alpha)")
			
			drag_float_neg_one("Boon Time", shell, "boon_time", 0.01, 10000.0, "%.2f seconds"); set_wc("boon_time", shell, -1.0, smnodes)
			tooltip("How long the boon will last\nSet to -1 to last as long as the current node")
		end
	
		
		changed, shell.pl_velocity_type = imgui.combo("Pl Velocity Type", shell.pl_velocity_type, {"No Velocity", "Owner Direction", "Towards Crosshair", "Towards Shell", "Towards Camera", "Towards Analog Stick", shell.turn_idx==4 and "Towards Turn Target"}); set_wc("pl_velocity_type", shell, 1, smnodes)
		tooltip("The direction that velocity and/or movespeed will be applied to the player during this node")
		
		if shell.pl_velocity_type > 1 then
			
			changed, shell.pl_velocity = ui.table_vec(imgui.drag_float3, "Pl Velocity Vector", shell.pl_velocity, shell.do_constant_speed and {0.01, -50.0, 50.0} or {0.001, -1.0, 1.0}); set_wc("pl_velocity", shell, {0.0,0.0,0.0}, smnodes)
			tooltip(shell.do_constant_speed and "The directional movement speed of the player, applied constantly (X | Y | Z)" or "This force vector will be applied once to the player with physics (X | Y | Z , works best in midair)\nUse a positive value on the Z axis to go forward")
			
			
			changed, shell.do_constant_speed = imgui.checkbox("Constant Speed", shell.do_constant_speed); set_wc("do_constant_speed", shell, false, smnodes)
			tooltip("If checked, the player will move in the direction constantly and without physics, rather than a single push")
		end
		
		if not enemy_chr then
			
			changed, shell.dmg_type_owner = imgui.combo("Pl Damage Type", shell.dmg_type_owner, enums.dmgs_melee); set_wc("dmg_type_owner", shell, 1, smnodes)
			tooltip("The type of damage attacks during this node will do\n'Force Finishing Move' will pick a random finishing move when using an attack that can trigger one")
			
			changed, shell.attack_rate_pl = imgui.drag_float("Pl Attack Rate", shell.attack_rate_pl, 0.1, 0.0, 1000.0, "%.2fx"); set_wc("attack_rate_pl", shell, 1.0, smnodes)
			tooltip("The amount of damage this shell deals")	
		end
		
		
		changed, shell.world_speed = imgui.drag_float("World Speed", shell.world_speed, 0.01, 0, 10.0, "%.2fx"); set_wc("world_speed", shell, 1.0, smnodes)
		tooltip("The game will be set to this speed during this node")
		
		
		changed, shell.anim_speed = imgui.drag_float("Action Speed", shell.anim_speed, 0.01, 0, 10, "%.2fx"); set_wc("anim_speed", shell, 1.0, smnodes)
		tooltip("The speed of the animation playing for this node")
		
		changed, shell.custom_motion = ui.imgui_safe_input(imgui.input_text, smnode_key.."cmot", "Custom Motion/Frame", shell.custom_motion); set_wc("custom_motion", shell, "", smnodes)
		tooltips.custom_mot = tooltips.custom_mot or "Play this action using a custom animation\nFormat:\n	[Motlist File], [Bank ID], [Motion ID], [Layer Index], [Frame], [Num Interpolation Frames]\nExample:\n	animation\\ch\\ch26\\motlist\\ch26_003_atk.motlist, 7777, 169, 0.0, 15.0"
		.."\n\n- The motlist file should exist in the PAK or in your natives folder, or you can put 'nil' if it's already loaded\n- Make up a unique Bank ID to always use with this motlist\n- The Motion ID must be the ID of an animation in a motlist file"
		.."\n- The Layer Index is 0 for body and 1 for upper body\n- The frame is the frame the animation will start on, with a decimal (i.e. '4.5'). It can be omitted to start at 0.0\n- The number of interpolation frames determines how quickly the animation transitions"
		.."\n\nAlternatively, this field can be used to set the frame on the current action\nAlt Format:\n	[Frame], [Layer Index] [Num Interpolation Frames]"
		tooltip(tooltips.custom_mot)
		
		local opened_func = imgui.tree_node("Custom Function")
		tooltip("Repeat a Lua function as long as this skill or its shells/summons exist (while the 'Node' text is colored white)\nAll changes made to skill json data ('smnode' and 'Skill.skill') from here will only affect the running skill instance")
		tooltips.custom_fn = tooltips.custom_fn or "Given variables:"
		.."\n	'_G' - All global variables are accessible from Custom Function"
		.."\n	'Skill' - Lua table of data about this skill"
		.."\n	'Node' - Lua table of data about this node"
		.."\n	'Player' - The player's [app.Character]"
		.."\n	'Owner' - The skill user's [app.Character]"
		.."\n	'Summon' - The [app.Character] belonging to this node's summon"
		.."\n	'Target' - The [app.AITarget] targeted by the owner, if available"
		.."\n	'Shell' - Shell's [app.Shell]"
		.."\n	'ActName' - Owner's current action (String)"
		.."\n	'ActName2' - Owner's current UpperBody action (String)"
		.."\n	'ActiveSummons' - All active summons table (Nodes)"
		.."\n	'ActiveSkills' - Dictionary of current running Skills by Skill name"
		.."\n	'GameTime' - The clock of the game, accounting for pause"
		.."\n	'SkillThisFrame' - If the owner executed another skill, its json data will be available here for one frame"
		.."\n	'Crosshair' - A Lua table with [1] being the GameObject hit by the crosshair and [2] being the coordinates of the crosshair"
		.."\n\n	'Hold()' - Call to prevent the timeline from moving beyond this node for a frame"
		.."\n	'RepeatNode()' - Call to replay the current node"
		.."\n	'Stop()' - Call to end the function (stop repeating)"
		.."\n	'Kill(SkillName)' - Call to end a Skill. Omit 'SkillName' to kill this skill"
		.."\n	'Exec(SkillName, ForSummon, AllowMultiple)' - Call to force-start another skill by name. Runs on the node's summon if 'ForSummon' is true. Allows multiple of the same skill to run with 'AllowMultiple' true"
		.."\n	'ReachedEnemy(Distance, via.Transform)' - Becomes true when the owner becomes within [Distance] of the either Soft-Lock target. Optionally takes a via.Transform to compare instead of the owner"
		.."\n	'RunLuaFile(Filepath)' - The text for each use of 'RunLuaFile' will be replaced with the code from the lua file it points to at [Filepath], literally."
		.."\n											  Lua files should be in the [reframework/data/SkillMaker/CustomFn] folder and formatted just like this text box"
		.."\n\n	'func' - Table of functions from Functions.lua (from _ScriptCore)"
		.."\n	'hk' - Table of functions and hotkeys from Hotkeys.lua (from _ScriptCore)"
		.."\n	'Callbacks' - Table of functions that will be executed every frame at specific times during the frame"
		.."\n		Timings are: [OnPreUpdateBehavior] == [Custom Function] -> [Callbacks.OnUpdateBehavior] -> [Callbacks.OnUpdateMotion] -> [Callbacks.OnLateUpdateBehavior] -> [Callbacks.OnFrame]"
		.."\n		Note that several volatile given variables (ActName, Actname2, Summon, Owner) are only given during the main function and will not be updated during any Callback functions"
		.."\n		Example: This would create a function that would execute every frame during UpdateBehavior and then delete itself + set a position after 1 second:"
		.."\n\n		local start = GameTime"
		.."\n		Callbacks.OnUpdateBehavior[key] = function()"
		.."\n			if GameTime - start > 1.0 then"
		.."\n				Callbacks.OnUpdateBehavior[key] =  nil"
		.."\n				Summon:set_AimTargetPosition(nposition)"
		.."\n			end"
		.."\n		end"
		
		if opened_func then
			imgui.begin_rect()
			imgui.set_next_item_width(calc_width * 1.5)
			changed, shell.custom_fn = ui.imgui_safe_input(imgui.input_text_multiline, smnode_key.."cfunc", "Function", shell.custom_fn); set_wc()
			if imgui_shell.error_txt then 
				imgui.text_colored("Last Error: "..string.format("%.02f", (os.clock() - imgui_shell.error_txt[2])).."s ago\n	"..imgui_shell.error_txt[1], 0xFF0000FF)
			end
			imgui.indent(calc_width*0.5)
			imgui.text("Mouse here for info")
			tooltip(tooltips.custom_fn)
			imgui.unindent(calc_width*0.5)
			
			local storage = imgui_shell.last_store
			local ld = imgui_shell.last_data
			ld.Player = player
			if storage then 
				ld.Skill, ld.Node, ld.Summon, ld.Shell, ld.Owner = storage.parent, storage, storage.summon_inst, storage.final_instance, storage.parent.owner
			end
			disp_imgui_element("Vars", ld, "View a list of variables from this node while it is active\nInstall EMV Engine to browse objects with more detail")
			
			imgui.end_rect(1)
			imgui.tree_pop()
		end
		
		if was_changed and not was_changed_before_node then
			temp.selected_shell = shell
			zaa = {imgui_data, imgui_data.running_shell, shell, shell_idx}
			if imgui_data.running_shell and imgui_data.running_shell.smnode_idx == shell_idx then --update live
				local merge_fn = hk.merge_tables_recursively or hk.merge_tables
				merge_fn(imgui_data.running_shell, shell)
			end
		end
		
		imgui.unindent(60)
		imgui.pop_id()
		imgui.end_rect(2)
		imgui.spacing()
	end
	
	if is_smnode_running then imgui.end_rect(1); imgui.end_rect(3) end
	if sms.use_colored_nodes then imgui.pop_style_color(1) end
	--imgui.pop_item_width()
end

local function skill_file_picker(imgui_data, save_text, is_em_skillsets)
	local pkey = (save_text and "picker_saver") or "picker"
	imgui.same_line()
	if imgui.button(save_text and "Save As " or "Pick File") then
		imgui_data[pkey] = ui.FilePicker:new({
			filters = {"json"}, 
			currentDir = (imgui_data.enemy_name and not imgui_data.do_browse_pl_skills and "SkillMaker\\"..(is_em_skillsets and "EnemySkillsets\\" or "EnemySkills\\")..imgui_data.enemy_name.."\\") or "SkillMaker\\Skills\\", 
			selectedPathText = save_text,
			doReset = true,
		})
	end
	local path = imgui_data[pkey] and imgui_data[pkey]:displayPickerWindow(not not save_text)
	if path then
		local name_ready = not imgui_data.enemy_name or enemies_map[path:match("SkillMaker\\.-Skill.-\\(.-)[\\%.].-$") or -1]
		if name_ready and path:find("SkillMaker\\"..(is_em_skillsets and "EnemySkillsets\\" or ".*Skills\\")) then
			return path
		end
		disp_message_box("Could not "..(save_text and "save" or "load").." file due to invalid location or filename")
	end
end

local function disp_skill_header_imgui(skill_tbl, imgui_data, i, enemy_name, running_skill_tbl)
	
	local default_tbl = enemy_name and default_sms.enemyskills[enemy_name].skills[1] or default_sms.skills[1]
	local save_path = (not enemy_name or imgui_data.do_browse_pl_skills) and "SkillMaker\\Skills\\" or "SkillMaker\\EnemySkills\\"..enemy_name.."\\"
	local cur_presets_glob = (not enemy_name or imgui_data.do_browse_pl_skills) and presets_glob or em_presets_glob[enemy_name]
	local skill_names = enemy_name and sms.last_sel_em_spells[enemy_name] or sms.last_sel_spells
	local skill_key = tostring(skill_tbl)
	
	--imgui.push_style_color(5, 0xFFE0853D)
	imgui.begin_rect()
	
	if enemy_name then
		changed, imgui_data.do_browse_pl_skills = imgui.checkbox("Player Skills", imgui_data.do_browse_pl_skills)
		tooltip("Load skills for this slot from the main Player skills list")
	else	
		changed, imgui_data.do_load_controls = imgui.checkbox("Load Controls", imgui_data.do_load_controls)
		tooltip("Load skills for this slot using the hotkeys and activation controls they were saved with")
	end
	
	if not enemy_name then
		imgui.same_line()
		changed, skill_tbl.use_modifier2 = imgui.checkbox("Use Modifier (2nd)", skill_tbl.use_modifier2); set_wc("use_modifier2", skill_tbl, false, sms.skills)
		tooltip("Make it so you have to hold down a second button along with the inhibit modifier to trigger the skill")
	end
	
	imgui.same_line()
	if imgui.button("Copy") then
		clipboard.spell = hk.recurse_def_settings({}, skill_tbl)
		clipboard.name = skill_names[i]
	end
	tooltip("Copy Skill to clipboard")
	
	if clipboard.spell then 
		if not imgui.same_line() and imgui.button("Paste") then
			local skills = enemy_name and sms.enemyskills[enemy_name].skills or sms.skills
			skills[i] = hk.recurse_def_settings({}, clipboard.spell)
			skill_names[i] = clipboard.name
			if func.find_key(skills, clipboard.name, "name") then
				skill_names[i] = skill_names[i] .. " (Copy)"
			end
		end
		tooltip("Paste Skill from clipboard")
	end
	
	if enemy_name then
		imgui.same_line()
		if imgui.button("Add Skill") then
			table.insert(sms.enemyskills[enemy_name].skills, i+1, hk.recurse_def_settings({}, default_tbl))
			table.insert(imgui_em_skills[enemy_name], i+1, hk.merge_tables({}, imgui_data))
			was_changed = true
		end
		tooltip("Insert a new skill after this one")
		imgui.same_line()
		if imgui.button("Delete Skill") and #sms.enemyskills[enemy_name].skills > 1 then
			table.remove(sms.enemyskills[enemy_name].skills, i)
			table.remove(imgui_em_skills[enemy_name], i)
			was_changed = true
		end
		tooltip("Remove this skill from this enemy type")
	end
	
	local clicked_save = imgui.button(" Save Skill  ") 
	tooltip("Input new skill name and save the current settings to a json file in\n[DD2 Game Directory]\\reframework\\data\\"..save_path)
	
	imgui.same_line(); imgui.push_id(75752 + i)
	changed, imgui_data.preset_text = imgui.input_text(" ", imgui_data.preset_text); imgui.pop_id()
	tooltip("Right click to set description\nUse a '\\' in the name (to save to a folder) or a ' - ' and only the text after that delimiter will be displayed as the title for the in-game GUI")
	
	if imgui.begin_popup_context_item("desc") then  
		if imgui.menu_item(imgui_data.show_desc_editor and "Hide Desciption" or "Edit description") then
			imgui_data.show_desc_editor = not imgui_data.show_desc_editor
		end
		imgui.end_popup() 
	end
	
	local picked_save_path = ui.FilePicker and skill_file_picker(imgui_data, imgui_data.preset_text)
	
	if (clicked_save and imgui_data.preset_text:len() > 0) or picked_save_path then
		picked_save_path = picked_save_path and (picked_save_path:match("(.+)%.[Jj][Ss][Oo][Nn]") or picked_save_path)..".json"
		local txt = imgui_data.preset_text:gsub("%.json", "") .. ".json"
		local to_dump = hk.merge_tables({}, skill_tbl)
		to_dump.hotkey = sms.hotkeys["Use Skill "..i]
		if json.dump_file(picked_save_path or save_path..txt, to_dump) then
			local picked_name = (picked_save_path and picked_save_path:match(".+\\(.+)%.json"))
			skill_tbl.name = picked_name or imgui_data.preset_text
			skill_names[i] = picked_name or txt:sub(1, -6)
			presets_glob = false
			was_changed = true
			disp_message_box("Saved to\n" .. (picked_path or "reframework\\data\\"..save_path..txt))
			--re.msg("Saved to\n" .. (picked_path or "reframework\\data\\"..save_path..txt))
		end
	end
	
	if imgui_data.show_desc_editor then
		imgui.indent(86)
		changed, skill_tbl.desc = ui.imgui_safe_input(imgui.input_text_multiline, skill_key.."desc", "Description", skill_tbl.desc); set_wc()
		imgui.unindent(86)
	end
	
	local clicked_button = imgui.button(" Load Skill  ")
	tooltip("Load settings from a json file in\n[DD2 Game Directory]\\reframework\\data\\"..save_path)
	imgui.same_line()
	
	if expand_as_listbox(imgui_data, "preset", imgui_data, "preset_idx", " ", cur_presets_glob or {}, nil, not enemy_name and sms.skill_descs, "Right click to show/hide list box", nil, true, 88) then	
		imgui_data.precached_json = imgui_data.preset_idx > 1 and json.load_file(save_path..cur_presets_glob[imgui_data.preset_idx]..".json") or {} --or imgui_data.precached_json
	end
	
	local picked_path = ui.FilePicker and skill_file_picker(imgui_data)
	
	if clicked_button or picked_path then
		if imgui_data.preset_idx == 1 and not picked_path then
			if enemy_name then
				sms.enemyskills[enemy_name].skills[i] = hk.recurse_def_settings({}, default_tbl)
			else
				sms.skills[i] = hk.recurse_def_settings({}, default_tbl)
			end
			skill_names[i] = nil
			imgui_data.preset_text = ""
		else
			local sp_name = picked_path and picked_path:match(".+\\(.+)%.json") or cur_presets_glob[imgui_data.preset_idx]
			local precached_json = json.load_file(picked_path or (save_path..sp_name..".json")) or {}
			if precached_json.duration then
				imgui_data.precached_json = precached_json
				load_skill(imgui_data.precached_json, i, sp_name, imgui_data.do_load_controls, enemy_name and default_tbl, enemy_name, enemy_name and not imgui_data.do_browse_pl_skills)
				imgui_data.preset_text = sp_name
				if next(imgui_data.precached_json) then update_skill(imgui_data.precached_json, i, enemy_name) end
				if enemy_name then 
					sms.enemyskills[enemy_name].enabled = true
					imgui_data.spell_to_load = imgui_data.precached_json 
				end
			else
				disp_message_box("Invalid or corrupt Skill file")
			end
		end
		was_changed = true
	end
	
	imgui.indent(86)
	changed, imgui_data.time_slider = ui.imgui_safe_input(imgui.slider_float, skill_key.."Time", "Time", running_skill_tbl and game_time - running_skill_tbl.storage.start or -1, {0.0, skill_tbl.duration, "%.2f seconds"})
	tooltip("Seek bar for the skill while it is executing")
	
	if changed then-- or (imgui.is_item_active() and imgui_data.time_slider == 0) then 
		if running_skill_tbl then
			running_skill_tbl.storage.start = running_skill_tbl.storage.start + ((game_time - running_skill_tbl.storage.start) - imgui_data.time_slider)
			for s = #running_skill_tbl.storage, 1, -1 do
				if running_skill_tbl.storage[s].start > game_time - running_skill_tbl.storage.start then
					running_skill_tbl.storage[s] = nil
				end
			end
		elseif enemy_name then
			if imgui_data.dummy_enemy then enemy_casts[imgui_data.dummy_enemy:get_ActionManager()] = {sp_tbl=skill_tbl, em_chr=imgui_data.dummy_enemy, name=enemy_name} end
		else
			forced_skill = {i, imgui_data.time_slider}
		end
	end

	changed, skill_tbl.duration = ui.imgui_safe_input(imgui.drag_float, skill_key.."dur", "Skill Duration", skill_tbl.duration, {0.01, 0.0, 100.0, "%.2f seconds"}); set_wc("duration", skill_tbl, 1.0, sms.skills)
	tooltip("The duration of the skill in seconds")
	
	if not enemy_name then
		local press_type = skill_tbl.button_press_type
		imgui.set_next_item_width(imgui.calc_item_width()*(skill_tbl.button_press_type==3 and 0.263 or 0.43)); imgui.push_id(894651+i)
		changed, skill_tbl.button_press_type = imgui.combo("", skill_tbl.button_press_type, {"Single Press", "Double Tap", "Hold"}); set_wc("button_press_type", skill_tbl, 1, sms.skills)
		tooltip("The way you have to press the button to activate the skill"); imgui.pop_id()
		
		if press_type==3 then
			imgui.same_line()
			imgui.set_next_item_width(imgui.calc_item_width()*0.15); imgui.push_id(800001+i)
			changed, skill_tbl.button_hold_time = imgui.drag_float("", skill_tbl.button_hold_time, 0.01, 0.0, 60.0, "%.3fs"); set_wc("button_hold_time", skill_tbl, 0.5, sms.skills)
			tooltip("How long you have to hold the button"); imgui.pop_id()
		end
		
		imgui.same_line()
		imgui.set_next_item_width(imgui.calc_item_width()*0.56)
		changed, skill_tbl.state_type_idx = imgui.combo("Activation Controls", skill_tbl.state_type_idx, {"Activate always", "When holding Modifier", "When holding 'Switch Weapon Skill'", "When not holding 'Switch Weapon Skill'"}); set_wc("state_type_idx", skill_tbl, 2, sms.skills)
		tooltip("Specify if you have to press one of these buttons to perform this skill")
	end
	imgui.unindent(86)
	imgui.end_rect(2)
	--imgui.pop_style_color(1)
end

local function disp_action_info_imgui(chara, do_return, nname, bank, mot_id, frame, endframe, anim_name, nname2, bank2, mot_id2, frame2, endframe2, anim_name2, bhv_name)
	local dec
	if chara then
		if not chara.FullBodyLayer then return end
		local upperlayer = chara.UpperBodyLayer
		local mot_info, mot_info2 = chara and chara.FullBodyLayer:get_HighestWeightMotionNode(), upperlayer and upperlayer:get_HighestWeightMotionNode()
		anim_name, anim_name2 = mot_info and mot_info:get_MotionName(), mot_info2 and mot_info2:get_MotionName()
		bank, bank2 = mot_info and mot_info:get_MotionBankID(), mot_info2 and mot_info2:get_MotionBankID()
		mot_id, mot_id2 = mot_info and mot_info:get_MotionID(), mot_info2 and mot_info2:get_MotionID()
		frame, frame2 = chara.FullBodyLayer:get_Frame(), upperlayer and upperlayer:get_Frame()
		endframe, endframe2 = chara.FullBodyLayer:get_EndFrame(), upperlayer and upperlayer:get_EndFrame()
		local layer2 = chara:get_ActionManager().CurrentActionList._items[1]
		nname, nname2 = chara:get_ActionManager().CurrentActionList._items[0].Name, layer2 and layer2.Name
		local dec = chara:get_AIDecisionMaker() and chara:get_AIDecisionMaker():get_DecisionModule()
		local bhv_pack = dec and dec._ExecuteActInter and dec._ExecuteActInter:get_ActInterPackData()
		bhv_name = bhv_pack and bhv_pack:get_Path():match("PackData/(.+)")
	end
	if do_return then
		return nname, bank, mot_id, frame, endframe, anim_name, nname2, bank2, mot_id2, frame2, endframe2, anim_name2, bhv_name
	end
	
	imgui.begin_rect()
	if dec then 
		if bhv_name then 
			imgui.text("Current Behavior:"); imgui.same_line(); imgui.text_colored(bhv_name, 0xFFAAFFFF) 
		else
			imgui.text("")
		end
	end
	imgui.text("Current Action:"); imgui.same_line(); imgui.text_colored(nname, 0xFFAAFFFF)
	imgui.text("Current Anim:"); imgui.same_line(); imgui.text_colored(bank, 0xFF00FF00); imgui.same_line(); tooltip("BankID")
	imgui.text_colored(mot_id, 0xFFFFFFAA); imgui.same_line(); tooltip("MotionID")
	imgui.text_colored(string.format("%3.02f", frame or 0).." / "..string.format("%3.02f", endframe or 0), 0xFFE0853D); imgui.same_line(); tooltip("Frame")
	imgui.text_colored(anim_name, 0xFFAAFFFF)
	
	if anim_name2 then 
		imgui.text("Current Upper Body Action:"); imgui.same_line() 
		imgui.text_colored(nname2, 0xFFAAFFFF)
		imgui.text("Current Upper Body Anim:"); imgui.same_line()
		imgui.text_colored(bank2, 0xFF00FF00); imgui.same_line(); tooltip("BankID")
		imgui.text_colored(mot_id2, 0xFFFFFFAA); imgui.same_line(); tooltip("MotionID")
		imgui.text_colored(string.format("%3.02f", frame2 or 0).." / "..string.format("%3.02f", endframe2 or 0), 0xFFE0853D); imgui.same_line(); tooltip("Frame")
		imgui.text_colored(anim_name2, 0xFFAAFFFF)
	else
		imgui.text("")
		imgui.text("")
	end
	imgui.end_rect()
end

local function disp_player_skill_imgui(skill_tbl, imgui_data, i, running_skill_tbl)
	imgui.begin_rect()
	if imgui_data.use_window then 
		imgui.text_colored(skill_tbl.name, 0xFFE0853D)
	end
	disp_skill_header_imgui(skill_tbl, imgui_data, i, nil, running_skill_tbl)
	local skill_key = tostring(skill_tbl)
	
	local opened_ssettings = imgui.tree_node("Skill Settings")
	tooltip("Basic settings for this skill")
	if opened_ssettings then
		imgui.begin_rect()
		changed, skill_tbl.stam_cost = imgui.slider_int("Stamina Cost", skill_tbl.stam_cost, 0, 1000); set_wc("stam_cost", skill_tbl, 0, sms.skills)
		tooltip("The amount of stamina lost by performing this skill\nStamina will be subtracted on the first node with a shell")
		
		changed, skill_tbl.damage_multiplier = imgui.drag_float("Damage Multiplier", skill_tbl.damage_multiplier, 0.1, 0, 1000); set_wc("damage_multiplier", skill_tbl, 1.0, sms.skills)
		tooltip("The overall amount of damage dealt by the skill will be multiplied by this number")
		
		changed, skill_tbl.job_idx = imgui.combo("Vocation", skill_tbl.job_idx, vocation_names); set_wc("job_idx", skill_tbl, 1, sms.skills)
		tooltip("The vocation required to use this skill")
		
		changed, skill_tbl.wp_idx = imgui.combo("Weapon", skill_tbl.wp_idx, weps.types); set_wc("wp_idx", skill_tbl, 1, sms.skills)
		tooltip("The weapon required to use this skill")
		
		changed, skill_tbl.require_weapon = imgui.checkbox("Require Weapon Drawn", skill_tbl.require_weapon); set_wc("require_weapon", skill_tbl, false, sms.skills)
		tooltip("If checked, you must have unsheathed your weapon to use this skill")
		
		imgui.same_line()
		changed, skill_tbl.hide_ui = imgui.checkbox("Hide in UI", skill_tbl.hide_ui); set_wc("hide_ui", skill_tbl, false, sms.skills)
		tooltip("If checked, this skill will not be displayed in the game's D-pad or face buttons UI")
		
		imgui.same_line()
		changed, skill_tbl.do_move_cam = imgui.checkbox("Move Camera		", skill_tbl.do_move_cam); set_wc("do_move_cam", skill_tbl, false, sms.skills)
		tooltip("If checked, the camera will move right while this skill is active if the global mod option 'Move Cam for Crosshair' is set to move for Skills")
		
		imgui.same_line()
		changed, skill_tbl.do_auto = imgui.checkbox("Automatic", skill_tbl.do_auto); set_wc("do_auto", skill_tbl, false, sms.skills)
		tooltip("If checked, this skill will be performed automatically, without pressing any buttons")
		
		imgui.same_line()
		changed, skill_tbl.do_hold_button = imgui.checkbox("Hold Button", skill_tbl.do_hold_button); set_wc("do_hold_button", skill_tbl, false, sms.skills)
		tooltip("If checked, the skill will cancel if the hotkey is released")
		
		local opened_func = imgui.tree_node("Activation Function")
		tooltips.act_fn = tooltips.act_fn or "Use a custom Lua function to check if this Skill can execute"
		.."\nReturn 'true' to allow skill activation\nVariables:"
		.."\n	'Player' - the player's [app.Character]"
		.."\n	'ActName' - Owner's current action (String)"
		.."\n	'ActName2' - Owner's current UpperBody action (String)"
		.."\n	'ActiveSkills' - Dictionary of current running Skills by Skill name"
		.."\n	'Skill' - A storage table that will be available as 'Skill' in Custom Function later"
		.."\n	'SkillData' - This Skill's saved json data"
		.."\n	'GameTime' - A clock for the game in seconds, ignoring pause"
		.."\n	'Crosshair' - A Lua table with [1] being the GameObject hit by the crosshair and [2] being the coordinates of the crosshair"
		.."\n	'Kill(SkillName)' - Call to end a Skill by name"
		.."\n	'Exec(SkillName)' - Call to start a Skill by name"
		.."\n	'func' - Table of functions from Functions.lua (from _ScriptCore)"
		.."\n	'hk' - Table of functions from Hotkeys.lua (from _ScriptCore)"
		tooltip(tooltips.act_fn)
		
		imgui.same_line()
		imgui.text_colored(skill_tbl.activate_fn~="" and "*" or "", 0xFFAAFFFF)
		
		if opened_func then
			imgui.begin_rect()
			imgui.set_next_item_width(imgui.calc_item_width() * 1.35)
			changed,  skill_tbl.activate_fn = ui.imgui_safe_input(imgui.input_text_multiline, skill_key.."cfunc", "Function", skill_tbl.activate_fn); set_wc()
			if imgui_data.error_txt then 
				imgui.text_colored("Last Error: "..string.format("%.02f", (os.clock() - imgui_data.error_txt[2])).."s ago\n	"..imgui_data.error_txt[1], 0xFF0000FF)
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
		
		disp_action_info_imgui(nil, nil, table.unpack(imgui_data.action_info))
		
		--[[imgui.text("Current Action:"); imgui.same_line(); imgui.same_line(); imgui.text_colored(node_name, 0xFFAAFFFF)
		imgui.text("Current Anim:"); imgui.same_line(); imgui.text_colored(mfsm2 and string.format("%3.02f", player.FullBodyLayer:get_Frame()), 0xFFE0853D); imgui.same_line(); imgui.text_colored(anim_name2, 0xFFAAFFFF)
		imgui.text("Current Upper Body Anim:"); imgui.same_line(); imgui.same_line(); imgui.text_colored(anim_name, 0xFFAAFFFF)
		imgui.text("Current Upper Body Action:"); imgui.same_line(); imgui.text_colored(mfsm2 and string.format("%3.02f", player.UpperBodyLayer:get_Frame()), 0xFFE0853D); imgui.same_line(); imgui.text_colored(node_name2, 0xFFAAFFFF)]]
		
		changed, skill_tbl.spell_states = ui.imgui_safe_input(imgui.input_text, skill_key.."sstates", "Skill States", skill_tbl.spell_states); set_wc("spell_states", skill_tbl, "", sms.skills)
		tooltip("The skill can only be used if one of these other skills is running\nSeparate different skill names with ', ' commas\nCombine different skill names with '+' plus signs (no spaces around '+')\n"
		.."Add parenthesis with a time range (in seconds) to count it only during specific time of that skill, with a SPACE between numbers, like: MySkill(55 100.5)\nType a '*' at the start of a skill name to search for it, rather than needing an exact match\nInsert a '%%' in front of a skill name to allow it to be its own requirement")
		
		changed, skill_tbl.custom_states = ui.imgui_safe_input(imgui.input_text, skill_key.."cstates", "Action States", skill_tbl.custom_states); set_wc("custom_states", skill_tbl, "", sms.skills)
		tooltip("Keywords to search the player's current Action name for to see if the skill can be used\n	Separate different keywords with ', ' commas\n	Add a '`' (backtick) to any keyword to make all keywords only required if no checkbox states are fulfilled"
		.."\n	Add parenthesis with a frame range to count it only during specific frame of the animation during that action, with a SPACE between numbers, like: DragonStinger(55 100.5)\n	Use brackets for Upper Body actions, like: Job03_ReadyHolyGlare[40 999]")
		
		changed, skill_tbl.anim_states = ui.imgui_safe_input(imgui.input_text, skill_key.."astates", "Anim States", skill_tbl.anim_states); set_wc("anim_states", skill_tbl, "", sms.skills)
		tooltip("Keywords to search the player's current animation name for to see if the skill can be used\n	Separate different keywords with ', ' commas\n	Add a '`' (backtick) to any keyword to make all keywords only required if no checkbox states are fulfilled"
		.."\n	Add parenthesis with a frame range to count it only during specific frame of the animation, with a SPACE between numbers, like: ch00_005_atk_NB_normal_long(0 25.5)\n	Use brackets for Upper Body animations, like: add_loop_dash[850 900]")
		
		changed, skill_tbl.frame_range = ui.table_vec(imgui.drag_float2, "Frame Range", skill_tbl.frame_range, {1.0, -1.0, 10000, "%3.02f frames"}); set_wc("frame_range", skill_tbl, {-1.0, -1.0}, sms.skills)
		tooltip("[start frame] [end frame]\nThe current frame of the player's body animation must be between the start and end frames of this range for this skill to trigger\nSet to -1.0 to leave unmodified")
		
		changed, skill_tbl.frame_range_upper = ui.table_vec(imgui.drag_float2, "Frame Range (Upper Body)", skill_tbl.frame_range_upper, {1.0, -1.0, 10000, "%3.02f frames"}); set_wc("frame_range_upper", skill_tbl, {-1.0, -1.0}, sms.skills)
		tooltip("[start frame] [end frame]\nThe current frame of the player's upper body animation must be between the start and end frames of this range for this skill to trigger\nSet to -1.0 to leave unmodified")
		
		imgui.begin_rect()
		local sz = imgui.calc_item_width()
		imgui.begin_table("states boxes", 2, 0, Vector2f.new(sz*1, 160), nil)
		imgui.table_setup_column(" ", 0, sz*0.3, 0)
		imgui.table_setup_column("  ", 0, sz*0.3, 0)
		imgui.table_headers_row()
		imgui.table_set_column_index(0)
		if sms.theme_type == 1 then imgui.table_set_bg_color(3, 0xFF1a1b19, 0) end
		
		for i, state_name in ipairs(state_names) do 
			if i == 5 then
				changed, skill_tbl.require_hitbox = imgui.checkbox("Hitbox Frame", skill_tbl.require_hitbox); set_wc("require_hitbox", skill_tbl, false, sms.skills)
				tooltip("If checked, this Skill can only activate on a frame where you are actively projecting a hitbox (capable of damaging the enemy)")
				if skill_tbl.require_hitbox then
					changed, skill_tbl.require_hitbox_contact = imgui.checkbox("Hit Contact", skill_tbl.require_hitbox_contact); set_wc("require_hitbox_contact", skill_tbl, false, sms.skills)
					tooltip("If checked, this Skill can only activate on a frame where you are actively hitting your target")
				end
				imgui.table_next_column()
				imgui.table_set_column_index(1)
				if sms.theme_type == 1 then imgui.table_set_bg_color(3, 0xFF1a1b19, 1) end
			end
			changed, skill_tbl.states[state_name] = imgui.checkbox(state_name, skill_tbl.states[state_name]); set_wc(state_name, skill_tbl.states, default_sms.skills[1].states[state_name], sms.skills)
			tooltip("Scans the current action name with a list of keywords related to the "..state_name.." state")
		end
		imgui.end_table()
		
		imgui.end_rect(0)
		imgui.end_rect(1)
		imgui.tree_pop()
	end
	
	local smnodes = skill_tbl.smnodes
	imgui_data.last_start = 0
	imgui_data.shift_amt = 0
	local opened_nodes = imgui.tree_node("Nodes")
	tooltip("The sequence of actions and shells that make up the skill")
	imgui_data.running_shell = running_skill_tbl and running_skill_tbl.storage[#running_skill_tbl.storage] and running_skill_tbl.storage[#running_skill_tbl.storage].shell
	
	if opened_nodes then
		
		imgui.indent()
		
		imgui_data.clicked_expand = imgui.button((imgui_data.nodes_expanded and "Collapse" or "Expand").." All Nodes")
		if imgui_data.clicked_expand then imgui_data.nodes_expanded = not imgui_data.nodes_expanded end
		--imgui.text_colored("*Hold ["..sms.hotkeys["UI Modifier"].."] while changing a setting to change that setting for all enabled nodes below the node being changed", 0xFFAAFFFF)
		
		for s, shell in pairs(smnodes) do
			disp_smnode_imgui(shell, s, skill_tbl, imgui_data, smnodes, running_skill_tbl)
		end
		
		imgui.unindent()
		imgui.tree_pop()
	end
	
	imgui.spacing()
	imgui.end_rect(1)
end

local function disp_em_skill_imgui(em_skill_tbl, i, imgui_data, running_skill_tbl, name)
	local imgui_enemy = imgui_data.parent
	local em_name_key = name --em_skill_tbl.em_job_idx > 1 and ((imgui_enemy.is_skel and "Skel " or "")..vocation_names[em_skill_tbl.em_job_idx]) or name
	imgui_data.enemy_act_list = enemy_action_names[em_name_key] or enemy_action_names[name]
	imgui_data.last_start = 0
	imgui_data.shift_amt = 0
	local skill_key = tostring(em_skill_tbl)
	local was_was_changed = was_changed
	
	if imgui_data.use_window then 
		local calc = imgui.calc_item_width()
		imgui.indent(calc * 0.5)
		imgui.text_colored(em_skill_tbl.name, 0xFFAAFFFF)
		imgui.unindent(calc * 0.5)
	end
	imgui.begin_rect()
	
	disp_skill_header_imgui(em_skill_tbl, imgui_data, i, name, running_skill_tbl)
	
	if imgui.tree_node("Skill Settings") then
		
		changed, em_skill_tbl.odds_to_replace = imgui.slider_float("Odds of Replacement", em_skill_tbl.odds_to_replace, 0.0, 1.0, "%.3fx"); set_wc("odds_to_replace", em_skill_tbl, 1.0, sms.enemyskills[name].skills)
		tooltip("The chance that the enemy's action will be replaced by this skill")
		
		if not em_skill_tbl.do_replace_enemy then
			local last_interval = em_skill_tbl.activate_interval
			changed, em_skill_tbl.activate_interval = imgui.drag_float("Interval", em_skill_tbl.activate_interval, 0.01, -1.0, 1000.0, "%.2f seconds"); set_wc("activate_interval", em_skill_tbl, -1.0, sms.enemyskills[name].skills)
			tooltip("The skill will have a chance to activate every x seconds (using Odds of Replacement) as long as the enemy is still doing the desired action.\nMultiple interval skills can be activated on a single frame\nSet to -1 to not use an interval")
			if changed and em_skill_tbl.activate_interval < 0 and em_skill_tbl.activate_interval > last_interval then em_skill_tbl.activate_interval = 0 end
			if em_skill_tbl.activate_interval < 0 then em_skill_tbl.activate_interval = -1 end
		end
		
		changed, em_skill_tbl.min_player_lvl = imgui.drag_int("Required Player Level", em_skill_tbl.min_player_lvl, 1, 0, 1000); set_wc("min_player_lvl", em_skill_tbl, 0, sms.enemyskills[name].skills)
		tooltip("The chance that the enemy's action will be replaced by this skill")
		
		if imgui_enemy.is_jobber then
			changed, em_skill_tbl.em_job_idx = imgui.combo("Vocation", em_skill_tbl.em_job_idx, vocation_names); set_wc("em_job_idx", em_skill_tbl, 1, sms.enemyskills[name])
			tooltip("The vocation required for a human enemy to use this skill")
		end
		
		changed, em_skill_tbl.delay_time = imgui.drag_float("Delay Time", em_skill_tbl.delay_time, 0.01, 0.0, 10000.0, "%.2f seconds"); set_wc("delay_time", em_skill_tbl, 1.0, sms.enemyskills[name].skills)
		tooltip("The amount of time between when the replace action is detected and when the skill can first be executed")
		
		local do_play
		if not em_skill_tbl.do_replace_enemy then
			changed, em_skill_tbl.summon_skill_name = ui.imgui_safe_input(imgui.input_text, skill_key.."sumskill", "Summoning Skill", em_skill_tbl.summon_skill_name); set_wc("summon_skill_name", em_skill_tbl, "", sms.enemyskills[name])
			tooltip("Input a skill name to only affect summons summoned by that skill\nLeave blank to affect all enemies of this type")
			
			local em_name_for_acts = name --em_skill_tbl.em_job_idx > 1 and vocation_names[em_skill_tbl.em_job_idx] or name
			do_play = expand_as_listbox(imgui_enemy, "replace"..i, em_skill_tbl, "replace_idx", "Replaced Action", enemy_action_names[em_name_for_acts].names, nil, nil, "This skill can execute when the enemy performs this action", nil, nil)
			
			if em_skill_tbl.replace_idx == 2 then
				changed, em_skill_tbl.act_name = ui.imgui_safe_input(imgui.input_text, skill_key.."actname", "Action Name", em_skill_tbl.act_name); set_wc("act_name", em_skill_tbl, "", sms.enemyskills[name])
				tooltip("Search the enemies current action name for this text and execute the skill if found\nSeparate multiple action strings with commas"
				.."\nFor example, type .* to accept any text between keywords in your search\n'Ch223.*Attack' will find any actions with 'Ch223' before 'Attack' with anything in between in the name")
			else
				em_skill_tbl.act_name = enemy_action_names[em_name_for_acts][em_skill_tbl.replace_idx]
			end
			
			changed, em_skill_tbl.search_txt = ui.imgui_safe_input(imgui.input_text, skill_key.."actsrch", "Action Search Text", em_skill_tbl.search_txt); set_wc("search_txt", em_skill_tbl, "", sms.enemyskills[name])
			tooltip("Search the enemies current action name for this text and execute the skill if found\nSeparate multiple keywords with commas\nYou can use Lua pattern matching to search\nFor example, type .* to accept any text between keywords in your search")
			
			if  em_skill_tbl.replace_idx > 1 or em_skill_tbl.search_txt ~= "" then
				changed, em_skill_tbl.anim_search_txt = ui.imgui_safe_input(imgui.input_text, skill_key.."animsrch", "Replaced Animation", em_skill_tbl.anim_search_txt); set_wc("anim_search_txt", em_skill_tbl, "", sms.enemyskills[name])
				tooltip("The skill will trigger when an animation with this name or satisfying this search term is found as the selected 'Replaced Action' is being performed\nLua pattern matching is accepted")	
				
				changed, em_skill_tbl.do_upperbody = imgui.checkbox("Upper Body Action", em_skill_tbl.do_upperbody); set_wc("do_upperbody", em_skill_tbl, false, sms.enemyskills[name].skills)
				tooltip("If checked, the skill will search through the character's Upper Body actions rather than full body ones")
				
				imgui.same_line()
				changed, em_skill_tbl.require_hitbox = imgui.checkbox("Hitbox Frame", em_skill_tbl.require_hitbox); set_wc("require_hitbox", em_skill_tbl, false, sms.enemyskills[name].skills)
				tooltip("If checked, this Skill can only activate on a frame where the enemy is actively projecting a hitbox (capable of damaging the enemy)")
				
				if em_skill_tbl.require_hitbox then
					imgui.same_line()
					changed, em_skill_tbl.require_hitbox_contact = imgui.checkbox("Hit Contact", em_skill_tbl.require_hitbox_contact); set_wc("require_hitbox_contact", em_skill_tbl, false, sms.enemyskills[name].skills)
					tooltip("If checked, this Skill can only activate on a frame where the enemy is actively hitting its target")
				end
			end
		end
		changed, em_skill_tbl.do_replace_enemy = imgui.checkbox("Replace Enemy With Summon", em_skill_tbl.do_replace_enemy); set_wc("do_replace_enemy", em_skill_tbl, false, sms.enemyskills[name].skills)
		tooltip("If checked, the enemy performing this skill will be changed into the first summon within the skill\nThis will only be evaluated one time per enemy as soon as the enemy spawns"
		.."\nUse an invisible shell and set the summon Cast Type to 'Owner' to make it spawn covertly on the location\n  of the replaced enemy. Add a small positive Y offset position to prevent ever falling through the earth")
		
		if em_skill_tbl.do_replace_enemy and not imgui.same_line() then 
			changed, em_skill_tbl.do_replace_dont_respawn = imgui.checkbox("Keep Original Enemy", em_skill_tbl.do_replace_dont_respawn); set_wc("do_replace_dont_respawn", em_skill_tbl, false, sms.enemyskills[name].skills)
			tooltip("The enemy being replaced will be converted into the summon without respawning it, if it is the same type of enemy as the summon\nUseful for preserving original details such as armor and equipment")
			
			local pos = pl_xform and pl_xform:get_UniversalPosition()
			local current_location = pos and wgraph_mgr:call("findNearNodeID(via.Position, System.Int32)", pos, 0).blockId
			imgui.same_line()
			imgui.text_colored("Current Location:", 0xFFAAFFFF); 
			tooltip("The region of the map that the player is currently in, as a number")
			imgui.same_line(); imgui.text(tostring(current_location))

			changed, em_skill_tbl.locations = imgui.input_text("Locations", em_skill_tbl.locations); set_wc()
			tooltip("Specify if the enemy can only be replaced in specific locations using a list of numbers\nLocations are evaluated as strings, so you can use patterns like '80[128]' to detect 801, 802 and 808\nSeparate locations with commas")
		end
		
		if imgui_enemy.dummy_enemy then
			
			local function play_action()
				imgui_data.parent.dummy_tbl = imgui_data.parent.dummy_tbl or sm_summons[imgui_enemy.dummy_enemy] or em_summons[imgui_enemy.dummy_enemy]
				temp_fns.play_dummy_action = function()
					temp_fns.play_dummy_action = nil --needs a frame to reset
					imgui_data.parent.dummy_tbl.forced_action = {em_skill_tbl.act_name, em_skill_tbl.do_upperbody and 1 or 0}
				end
			end
			
			if em_skill_tbl.replace_idx > 2 then 
				if not imgui.same_line() and (imgui.button("Play Action") or do_play) then 
					play_action()
				end
			end
			
			if (em_skill_tbl.replace_idx == 1 or not imgui.same_line()) and imgui.button("Run Skill") and em_skill_tbl.replace_idx > 1 then
				reset_character(true, imgui_enemy.dummy_enemy)
				temp.force_dummy_action, was_changed = true, true
			end
			tooltip("Make the dummy enemy (or last enemy) perform this skill\nHotkey:  "..sms.hotkeys["Run Enemy Skill Test"])
			imgui.same_line()
			changed = hk.hotkey_setter("Run Enemy Skill Test", nil, nil, "Runs the last edited enemy skill on the last managed dummy enemy"); set_wc()
		end
		
		local opened_func = imgui.tree_node("Activation Function")
		tooltips.em_act_fn = tooltips.em_act_fn or "Use a custom Lua function to check if this Skill can execute"
		.."\nReturn 'true' to allow skill activation\nVariables:"
		.."\n	'Player' - the player's [app.Character]"
		.."\n	'Owner' - Skill owner's [app.Character]"
		.."\n	'Target' - Skill owner's current AI Target"
		.."\n	'ActName' - Owner's current action (String)"
		.."\n	'ActName2' - Owner's current UpperBody action (String)"
		.."\n	'ActiveSkills' - Dictionary of current running Skills by Skill name"
		.."\n	'Skill' - A storage table that will be available as 'Skill' in Custom Function later"
		.."\n	'SkillData' - This Skill's saved json data"
		.."\n	'GameTime' - A clock for the game in seconds, ignoring pause"
		.."\n	'Crosshair' - A Lua table with [1] being the GameObject hit by the crosshair and [2] being the coordinates of the crosshair"
		.."\n	'Kill(SkillName)' - Call to end a Skill by name"
		.."\n	'Exec(SkillName)' - Call to start a Skill by name"
		.."\n	'Stop()' - Stops the activation function from continuing to repeat on an interval"
		.."\n	'func' - Table of functions from Functions.lua (from _ScriptCore)"
		.."\n	'hk' - Table of functions from Hotkeys.lua (from _ScriptCore)"
		tooltip(tooltips.em_act_fn)
		imgui.same_line()
		imgui.text_colored(em_skill_tbl.activate_fn~="" and "*" or "", 0xFFAAFFFF)
		
		if opened_func then
			imgui.begin_rect()
			imgui.set_next_item_width(imgui.calc_item_width() * 1.35)
			changed,  em_skill_tbl.activate_fn = ui.imgui_safe_input(imgui.input_text_multiline, skill_key.."cfunc", "Function", em_skill_tbl.activate_fn); set_wc()
			if imgui_data.error_txt then 
				imgui.text_colored("Last Error: "..string.format("%.02f", (os.clock() - imgui_data.error_txt[2])).."s ago\n	"..imgui_data.error_txt[1], 0xFF0000FF)
			end
			imgui.end_rect(1)
			
			local ld = {}
			ld.Player = player
			local storage = imgui_data.last_data
			if storage then 
				ld.SkillData, ld.Skill, ld.Owner, ld.Target = storage.skill, storage, storage.owner, storage.target
			end
			disp_imgui_element("Vars", ld, "View a list of variables from this node while it is active\nInstall EMV Engine to browse objects with more detail")
			imgui.tree_pop()
		end
		imgui.tree_pop()
	end
	imgui_data.running_shell = running_skill_tbl and running_skill_tbl.storage[#running_skill_tbl.storage] and running_skill_tbl.storage[#running_skill_tbl.storage].shell
	
	local opened_nodes = imgui.tree_node("Nodes")
	tooltip("The sequence of actions and shells that make up the skill")
	if opened_nodes then
		imgui.indent()
		
		imgui_data.clicked_expand = imgui.button((imgui_data.nodes_expanded and "Collapse" or "Expand").." All Nodes")
		if imgui_data.clicked_expand then imgui_data.nodes_expanded = not imgui_data.nodes_expanded end
		
		for i, shell in ipairs(em_skill_tbl.smnodes) do
			disp_smnode_imgui(shell, i, em_skill_tbl, imgui_data, em_skill_tbl.smnodes, running_skill_tbl, name, imgui_enemy.dummy_enemy or player)
		end
		imgui.unindent()
		imgui.tree_pop()
	end
	
	if was_changed and not was_was_changed then
		if imgui_enemy.dummy_enemy then
			temp.last_dummy_skill = {sp_tbl=em_skill_tbl, em_chr=imgui_enemy.dummy_enemy, act_mgr=imgui_enemy.dummy_enemy:get_ActionManager(), name=name, key=imgui_enemy.dummy_enemy:get_address()..(em_skill_tbl.name~="" and em_skill_tbl.name or i), idx=i} 
		end
		if em_skill_tbl.unedited then
			em_skill_tbl.unedited, em_skill_tbl.enabled, sms.enemyskills[name].enabled = false, true, true
		end
	end
	
	imgui.spacing()
	imgui.end_rect(1)
end

local function disp_enemy_skillset_loader_imgui(name, imgui_enemy, do_all)
	
	local saved = imgui.button(do_all and "Save Skillset List" or "Save Skillset")
	tooltip("Save settings to a json file in\n		[DD2 Game Directory]\\reframework\\"..name.."\\")
	
	imgui.same_line()
	local calc_width = imgui.calc_item_width()
	imgui.set_next_item_width(calc_width * 0.8)
	changed, imgui_enemy.skillset_txt = imgui.input_text(do_all and "Skillset List Name" or "Skillset Name  ", imgui_enemy.skillset_txt)
	tooltip("Input the name of the "..(do_all and "skillset list" or "skillset").." to be saved")
	
	local picked_save_path = ui.FilePicker and skill_file_picker(imgui_enemy, imgui_enemy.skillset_txt, true)
	
	if saved or picked_save_path then 
		local em_skillsetlist = {}
		for em_name, list in pairs(enemy_action_names) do
			if em_name == name or (do_all and sms.enemyskills[em_name].enabled) then
				local new_skillset = {skill_list={}, redirect_idx=sms.enemyskills[em_name].redirect_idx}
				for s, skill_tbl in ipairs(sms.enemyskills[em_name].skills) do
					if skill_tbl.name ~= "" then 
						table.insert(new_skillset.skill_list, skill_tbl.name)
					end
				end
				new_skillset.skill_list = next(new_skillset.skill_list) and new_skillset.skill_list
				em_skillsetlist[em_name] = (new_skillset.skill_list or new_skillset.redirect_idx > 1) and new_skillset
			end
		end
		picked_save_path = picked_save_path and (picked_save_path:match("(.+)%.[Jj][Ss][Oo][Nn]") or picked_save_path)..".json"
		if not (picked_save_path and picked_save_path:find("\\%.")) then
			local save_path = picked_save_path or "SkillMaker\\EnemySkillsets\\"..name.."\\"..imgui_enemy.skillset_txt..".json"
			json.dump_file(save_path, em_skillsetlist)
			presets_glob, skillsets_glob = nil
			disp_message_box("Saved to\n"..save_path)
		end
	end
	
	local loaded = imgui.button(do_all and "Load Skillset List" or "Load Skillset")
	tooltip("Load settings from a json file in\n		[DD2 Game Directory]\\reframework\\"..name.."\\")
	imgui.same_line()
	imgui.set_next_item_width(calc_width * 0.8)
	expand_as_listbox(imgui_enemy, "skillset", imgui_enemy, "skillset_idx", do_all and "Enemy Skillset List" or "Enemy Skillset", enemy_skillsets[name].names, 
		nil, nil, "Load a list of enemy "..(do_all and "skillsets" or "skills").." together\nRight click to show/hide list box", nil, true, do_all and 120 or 95, 0.8)
	
	local picked_path = ui.FilePicker and skill_file_picker(imgui_enemy, nil, true)
	
	local owner_tbl = do_all and sms or sms.enemyskills[name]
	changed, owner_tbl.do_clear_spells_on_em_cfg_load = imgui.checkbox("Clear Skills on Load", owner_tbl.do_clear_spells_on_em_cfg_load)
	tooltip("If checked, all enemy skills will be reset before loading any Skillset or Skillset List")
	
	if do_all and not imgui.same_line() and imgui.button("Unsummon Dummies") then
		for em_name, imgui_enemy in pairs(imgui_em_skills) do
			if imgui_enemy.dummy_enemy then
				if imgui_enemy.dummy_enemy:get_Valid() then imgui_enemy.dummy_enemy:get_GameObject():destroy(imgui_enemy.dummy_enemy:get_GameObject()) end
				imgui_enemy.dummy_tbl, imgui_enemy.dummy_enemy = nil
			end
		end
	end
	
	if (loaded and imgui_enemy.skillset_idx > 1) or picked_path then
		local do_clear_skills = (do_all and sms.do_clear_spells_on_em_cfg_load) or (not do_all and sms.enemyskills[name].do_clear_spells_on_em_cfg_load)
		local skillset = json.load_file(picked_path or enemy_skillsets[name][imgui_enemy.skillset_idx-2]) or {}
		if (picked_path or imgui_enemy.skillset_idx > 2) and not (next(skillset) and (enemies_map[next(skillset)] or next(skillset) == "All Enemies")) then
			disp_message_box("Invalid or corrupt Skillset file")
			goto exit
		end
		if do_clear_skills or imgui_enemy.skillset_idx == 2 then
			for em_name, spellslist_tbl in pairs(sms.enemyskills) do
				if do_all or em_name == name then
					sms.enemyskills[em_name] = hk.recurse_def_settings({}, default_sms.enemyskills[em_name])
					sms.enemyskills[em_name].skills = {hk.recurse_def_settings({}, default_sms.enemyskills[em_name].skills[1])}
				end
			end
		end
		if imgui_enemy.skillset_idx > 2 or picked_path then
			local skillset_list = {}
			if picked_path then
				local old_name = next(skillset)
				skillset[name], skillset[old_name] = skillset[old_name], nil
				skillset[name].old_name = old_name
			end
			for em_name, list in pairs(skillset) do 
				table.insert(skillset_list, em_name) 
			end
			for i, em_name in ipairs(skillset_list) do
				local em_skillset = skillset[em_name]
				local filtered_skills = {}
				for i, skill_tbl in ipairs(sms.enemyskills[em_name].skills) do 
					if not skill_tbl.unedited then table.insert(filtered_skills, skill_tbl) end
				end
				sms.enemyskills[em_name].skills = filtered_skills
				local add_amt = #sms.enemyskills[em_name].skills
				sms.enemyskills[em_name].redirect_idx = em_skillset.redirect_idx or 1
				sms.enemyskills[em_name].enabled = true
				imgui_enemy.skillset_idx = 1
				
				for s, skill_name in ipairs(em_skillset.skill_list or {}) do
					s = s + add_amt
					imgui_enemy[s] = imgui_enemy[s] or hk.merge_tables({shell_datas={}}, imgui_enemy[1])
					imgui_enemy[s].preset_idx = 1
					json_data = json.load_file("SkillMaker\\EnemySkills\\"..(em_skillset.old_name or em_name).."\\"..skill_name..".json") or json.load_file("SkillMaker\\Skills\\"..skill_name..".json")
					if json_data then
						load_skill(json_data, s, skill_name, nil, {}, em_name, true)
					end
				end
				sms.enemyskills[em_name].skills[1] = sms.enemyskills[em_name].skills[1] or hk.recurse_def_settings({}, default_sms.enemyskills[em_name].skills[1])
				sms.enemyskills[em_name].enabled = true
			end
		end
		was_changed = true
		::exit::
	end
end

local function disp_enemy_skills_imgui()
	if not temp.use_emsk_window then 
		imgui.begin_rect()
	end
	
	temp.imgui_all_enemies = temp.imgui_all_enemies or {skill_counts={All={}}} 
	local scounts = temp.imgui_all_enemies.skill_counts
	disp_enemy_skillset_loader_imgui("All Enemies", temp.imgui_all_enemies, true)
	
	for n, species_name in ipairs(em_groups.names) do
		scounts[species_name] = {__total=0}
		for g, name in ipairs(em_groups.groups[species_name]) do
			scounts[species_name][name] = 0
			if sms.enemyskills[name].enabled then
				for i, em_skill_tbl in ipairs(sms.enemyskills[name].skills) do
					if em_skill_tbl.enabled then
						scounts[species_name][name] = scounts[species_name][name] + 1
						scounts[species_name].__total = scounts[species_name].__total + 1
					end
				end
			end
		end
	end
	for c, category_name in ipairs(em_groups.cat_names) do
		scounts.All[category_name] = {__cat_total=0}
		local cat_list = em_groups.categories[category_name]
		for i, species_name in pairs(cat_list) do
			scounts.All[category_name].__cat_total = scounts.All[category_name].__cat_total + scounts[species_name].__total
		end
	end
	
	for c, category_name in ipairs(em_groups.cat_names) do
		local cat_num = scounts.All[category_name].__cat_total > 0 and "["..scounts.All[category_name].__cat_total.."]" or "" 
		if ui.tree_node_colored(category_name, category_name, cat_num, c==1 and 0xFFAAFFAA or 0xFFAAFFFF) then
			local cat_list = em_groups.categories[category_name]
			for n, species_name in ipairs(cat_list) do
				local num = scounts[species_name].__total > 0 and "["..scounts[species_name].__total.."]" or ""
				if ui.tree_node_colored(species_name, species_name, num, 0xFFE0853D) then
					for g, name in ipairs(em_groups.groups[species_name]) do
						local em_skillslist = sms.enemyskills[name]
						imgui.push_id(name.."Enbl")
						changed, em_skillslist.enabled = imgui.checkbox("", em_skillslist.enabled); set_wc("enabled", em_skillslist, true, sms.enemyskills)
						tooltip("Enable/Disable the replacement of enemy skills for this enemy")
						imgui.pop_id()
						imgui.same_line()
						local num2 = scounts[species_name][name] > 0 and "["..scounts[species_name][name].."]" or ""
						local opened_em_skillslist = ui.tree_node_colored(name, name, num2, 0xFFE0853D, "Enemy Skills are evaluated from top to bottom of the list whenever the enemy performs a\nnew action, with only one being allowed to run per-enemy per-frame (unless it uses an interval)")
						
						if opened_em_skillslist then
							imgui.begin_rect()
							changed,  em_skillslist.redirect_idx = imgui.combo("Redirect Skills", em_skillslist.redirect_idx, redirect_names); set_wc("redirect_idx", em_skillslist, 1, sms.enemyskills)
							tooltip("Use this to make this enemy type use the skills list of a similar enemy type")
							
							if em_skillslist.redirect_idx == 1 then
								local imgui_enemy = imgui_em_skills[name]
								
								disp_enemy_skillset_loader_imgui(name, imgui_enemy)
								
								imgui.same_line()
								imgui.set_next_item_width(imgui.calc_item_width() * 0.5)
								changed, imgui_enemy.filter_text = imgui.input_text("Filter Skills", imgui_enemy.filter_text)
								tooltip("Filter "..name.." skills by name. Use a space to view unnamed skills")
								local filter_text_lower = imgui_enemy.filter_text:lower()
								
								if imgui.tree_node("Enemy Testing") then
									if imgui.button(imgui_enemy.use_testing_window and "Close Window" or "Open Window") then
										imgui_enemy.use_testing_window = not imgui_enemy.use_testing_window
									end
								
									window_fns[name.."_enemytest_window"] = function()
										local used_window = imgui_enemy.use_testing_window
										
										if used_window then 
											imgui.set_next_window_size({temp.disp_sz.x * 0.25, temp.disp_sz.y * 0.15}, 2)
											imgui.set_next_window_pos({temp.disp_sz.x / 10 , 0}, 2, {0,0})
										
											local clicked_x = imgui.begin_window("Skill Maker - "..name.." Enemy Testing", true, 0) == false
											if clicked_x or not imgui_enemy.use_testing_window then 
												imgui_enemy.use_testing_window = false
												window_fns[name.."_enemytest_window"] = nil
											end
										end
										
										local last_dummy = imgui_enemy.dummy_enemy
										local last_chr, do_unsummon
										
										if is_summoning and not imgui_enemy.dummy_enemy then 
											local dist = 9999
											local pl_pos = pl_xform:get_Position()
											for chr, nstore in pairs(sm_summons) do
												local ch2_name = enums.chara_id_enum[chr:get_CharaID()]
												local em_pos = chr:get_Valid() and (enemy_list[ch2_name] and enemy_list[ch2_name].name == name) and chr:get_Transform():get_Position()
												local em_dist_to_pl = em_pos and (em_pos - pl_pos):length()
												if em_dist_to_pl and em_dist_to_pl < dist then 
													last_chr, dist = chr, em_dist_to_pl
												end
											end
										end
										
										if not imgui_enemy.summon_names then 
											imgui_enemy.summon_names = {}
											for i, em_name in pairs(enemy_names.short.no_parens) do
												if em_name == name then 
													table.insert(imgui_enemy.summon_names, enemy_names[i+1]:match(".+/(.+)%.pfb") .. " - " .. enemy_names.short[i+1])
												end
											end
										end
										
										if imgui_enemy.summon_names[1] then
											changed, imgui_enemy.dummy_select_idx = imgui.combo("Dummy Select", imgui_enemy.dummy_select_idx, imgui_enemy.summon_names)
											tooltip("Choose a dummy type to spawn")
											
											if (imgui.button(imgui_enemy.dummy_enemy and "Unsummon Dummy" or "Summon Dummy") or do_unsummon) and player and not is_paused then
												if imgui_enemy.dummy_enemy then
													imgui_enemy.dummy_enemy:get_GameObject():destroy(imgui_enemy.dummy_enemy:get_GameObject())
													imgui_enemy.dummy_tbl, imgui_enemy.dummy_enemy, temp.summon_dummies[imgui_enemy.dummy_enemy] = nil
												else
													imgui_enemy.dummy_tbl = {
														is_dummy = true,
														num_living_children = 1,
														spell = {damage_multiplier=1.0},
														shell = {
															summon_idx = func.find_index(enemy_names.short, imgui_enemy.summon_names[imgui_enemy.dummy_select_idx]:match(" %- (.+)$")),
															summon_timer = 99999.0,
															summon_hostile = imgui_enemy.dummy_hostile,
															summon_attack_rate = 0.000000001,
															summon_hp_rate = 999999999.0,
															is_dummy = true,
														}
													}
													hk.recurse_def_settings(imgui_enemy.dummy_tbl.spell, default_sms.enemyskills[name].skills[1])
													hk.recurse_def_settings(imgui_enemy.dummy_tbl.shell, default_sms.enemyskills[name].skills[1].smnodes[1])
													imgui_enemy.dummy_reset_pos = pl_xform:get_Position()
													imgui_enemy.summon_dummy_ticks = ticks
													
													temp_fns.dummy_summon_fn = function() 
														temp_fns.dummy_summon_fn = nil
														local eul = pl_xform:get_EulerAngle()
														summon(imgui_enemy.dummy_tbl, imgui_enemy.dummy_reset_pos, euler_to_quat:call(nil, Vector3f.new(0, eul.y+math.pi, 0), 0)) 
													end
												end
											end
											tooltip("Summon a dummy version of this enemy to test with\nYou can also 'adopt' a nearby summon of the correct type")
											
											if last_chr and last_chr ~= imgui_enemy.dummy_enemy then 
												imgui.same_line()
												if imgui.button("Adopt as Dummy") then
													if imgui_enemy.dummy_enemy then
														imgui_enemy.dummy_enemy:get_GameObject():destroy(imgui_enemy.dummy_enemy:get_GameObject())
														temp.summon_dummies[imgui_enemy.dummy_enemy] = nil
													end
													imgui_enemy.dummy_enemy = last_chr
													imgui_enemy.dummy_tbl = sm_summons[last_chr] or em_summons[last_chr]
													imgui_enemy.dummy_tbl.is_dummy = 1
													imgui_enemy.dummy_think_on = last_chr:get_AIDecisionMaker():get_Enabled()
													imgui_enemy.dummy_reset_pos = last_chr:get_Transform():get_Position()
													imgui_enemy.do_dummy_reset = false
												end
												tooltip("Makes the closest summoned instance of this enemy into the dummy")
											elseif imgui_enemy.dummy_tbl and imgui_enemy.dummy_tbl.is_dummy == 1 then
												imgui.same_line()
												if imgui.button("Dismiss Dummy") then
													temp.summon_dummies[imgui_enemy.dummy_enemy] = nil
													imgui_enemy.dummy_enemy, imgui_enemy.dummy_tbl.is_dummy, imgui_enemy.dummy_tbl, imgui_enemy.do_dummy_lookat = nil
												end
												tooltip("Release the adopted dummy")
											end
												
											if not imgui_enemy.dummy_enemy then
												imgui.same_line()
												changed, imgui_enemy.dummy_hostile = imgui.checkbox("Spawn as Hostile", imgui_enemy.dummy_hostile)
												tooltip("The next spawned dummy will be hostile to the player if this is checked") 
											end
										end
										
										local em_chr, just_spawned_dummy = imgui_enemy.dummy_enemy
										if imgui_enemy.dummy_tbl then
											imgui_enemy.dummy_enemy = imgui_enemy.dummy_tbl.summon_inst and sdk.is_managed_object(imgui_enemy.dummy_tbl.summon_inst) and imgui_enemy.dummy_tbl.summon_inst:get_Valid() and imgui_enemy.dummy_tbl.summon_inst
											if em_chr and not (sdk.is_managed_object(em_chr) and em_chr:get_Valid()) then imgui_enemy.dummy_enemy, em_chr = nil end
											just_spawned_dummy = em_chr and not last_dummy
											if just_spawned_dummy then temp.last_dummy_enemy = em_chr end
										end
										
										if em_chr then 
											temp.summon_dummies[em_chr] = imgui_enemy.dummy_tbl
										
											imgui.same_line()
											if (imgui.button("Reset Dummy") or hk.check_hotkey("SM Clean Up")) and em_chr:get_Valid() then
												reset_character(false, em_chr)
											end
											tooltip("Resets the current action and behavior of the dummy")
											
											--[[imgui.same_line()
											if imgui.button("Dump Action Names") then
												local node_names = {}
												for i=0, 1 do
													local tree = em_chr:get_ActionManager().Fsm:getLayer(i):get_tree_object()
													local printed = false
													for j = 0, tree:get_node_count() do
														local node = tree:get_node(j)
														if node and not node:get_children()[1] then
															local actions = node:get_actions(); if not actions[1] then actions = node:get_unloaded_actions() end
															for k, action in ipairs(actions) do
																local td = action:get_type_definition()
																if td:is_a("app.JobActionMotion") or td:is_a("via.motion.Fsm2ActionPlayMotion") or td:is_a("app.UseHumanAction") then
																	if not printed then print(i, node:get_name()) end
																	printed = true
																	table.insert(node_names, node:get_name())
																	break
																end
															end
														end
													end
												end
												em_act_names_json = json.load_file("SkillMaker\\EnemyActionNames NEW.json") or json.load_file("SkillMaker\\EnemyActionNames.json")
												local new_name = imgui_enemy.summon_names[imgui_enemy.dummy_select_idx]:match(".+%((.+)%)") or name
												em_act_names_json[new_name] = node_names
												local dumping = hk.merge_tables(json.load_file("SkillMaker\\EnemyActionNames.json") or {}, em_act_names_json)
												json.dump_file("SkillMaker\\EnemyActionNames NEW.json", dumping)
											end]]
											
											local em_entry = enemy_list[enums.chara_id_enum[em_chr:get_CharaID()] ]
											if em_entry and em_entry.can_fly and not imgui.same_line() and imgui.button(em_chr:get_IsFlight() and "Land" or "Take Off") then
												em_chr:get_ActionManager():requestActionCore(0, em_chr:get_IsFlight() and "TakeOffLanding" or "Takeoff", 0)
											end
											
											imgui.same_line()
											changed, imgui_enemy.dummy_think_on = imgui.checkbox("Think", imgui_enemy.dummy_think_on)
											tooltip("Allow the enemy to think and perform actions on its own") 
											if changed then 
												
												temp_fns.disable_think = function()
													temp_fns.disable_think = not imgui_enemy.dummy_think_on and em_chr:get_Valid() and temp_fns.disable_think or nil
													if em_chr:get_Valid() then em_chr:get_AIDecisionMaker():set_Enabled(imgui_enemy.dummy_think_on) end --if this is turned off too early it CTDs
												end
												temp_fns.disable_think()
												em_chr.EnemyCtrl.Ch2._TargetController:changeTarget()
												em_chr:get_ActionManager().Fsm:restartTree()
											end
											
											imgui.same_line()
											changed, imgui_enemy.do_dummy_lookat = imgui.checkbox("Look at Dummy", imgui_enemy.do_dummy_lookat)
											tooltip("Make the camera follow the dummy") 
											if changed then
												
												frame_fns.dummy_lookat_fn = imgui_enemy.do_dummy_lookat and function()
													frame_fns.dummy_lookat_fn = reframework:is_drawing_ui() and em_chr:get_Valid() and frame_fns.dummy_lookat_fn or nil
													imgui_enemy.do_dummy_lookat = not not frame_fns.dummy_lookat_fn
													if frame_fns.dummy_lookat_fn and not is_paused then
														local dummy_pos = temp.chest_joint_mth:call(nil, em_chr:get_Transform()):get_Position()
														local cam_joint = camera:get_GameObject():get_Transform():getJointByName("Camera")
														local diff = cam_joint:get_Position() - temp.chest_joint_mth:call(nil, pl_xform):get_Position()
														local cam_pos = dummy_pos + diff
														cam_joint:set_Position(cam_pos)
														local lookat_quat = lookat_method:call(nil, cam_pos, dummy_pos, Vector3f.new(0,1,0)):inverse():to_quat() 
														cam_joint:set_Rotation(lookat_quat)
													end
												end or nil
											end
											
											changed, imgui_enemy.do_dummy_reset = imgui.checkbox("Freeze Position", imgui_enemy.do_dummy_reset)
											tooltip("Keep the dummy in the position it was when this box was checked") 
											
											imgui.same_line()
											local reset_position_once = imgui.button("Reset Position")
											tooltip("Move the dummy back to the saved position")
											
											if imgui_enemy.summon_dummy_ticks and not em_chr:get_GameObject():get_DrawSelf() then imgui_enemy.summon_dummy_ticks = ticks end
											if changed or reset_position_once or (imgui_enemy.summon_dummy_ticks and ticks - imgui_enemy.summon_dummy_ticks > (species_name == "Bandits" and 60 or 30)) then 
												imgui_enemy.summon_dummy_ticks = nil
												imgui_enemy.dummy_reset_pos = (reset_position_once and imgui_enemy.dummy_reset_pos) or em_chr:get_Transform():get_Position()
												
												temp_fns.reset_dummy_pos = function()
													temp_fns.reset_dummy_pos = imgui_enemy.do_dummy_reset and em_chr:get_Valid() and temp_fns.reset_dummy_pos or nil
													if temp_fns.reset_dummy_pos or reset_position_once then --and not temp_fns[act_mgr] then
														em_chr:get_Transform():set_Position(imgui_enemy.dummy_reset_pos)
													end
												end
											end
											
											disp_action_info_imgui(em_chr)
											
											if imgui.tree_node("Data") then 
												disp_imgui_element("Enemy", em_chr)
												if EMV and imgui.tree_node("Enemy GameObject") then 
													disp_imgui_element("EnemyGameObject", em_chr:get_Transform())
													imgui.tree_pop()
												end
												disp_imgui_element("Node", imgui_enemy.dummy_tbl)
												imgui.tree_pop()
											end
										end
										if used_window then imgui.end_window() end
									end
									
									if not imgui_enemy.use_testing_window then
										window_fns[name.."_enemytest_window"]()
										window_fns[name.."_enemytest_window"] = nil
									end
									imgui.tree_pop()
								end
								
								if not presets_glob then 
									setup_presets_glob()
									setup_skillsets_glob()
								end
								
								for i, em_skill_tbl in ipairs(em_skillslist.skills) do
									imgui_enemy[i] = imgui_enemy[i] or hk.recurse_def_settings({}, imgui_enemy[1]) --FIXME
									local imgui_data = imgui_enemy[i]
									local key = imgui_enemy.dummy_enemy and (imgui_enemy.dummy_enemy:get_address() .. (em_skill_tbl.name~="" and em_skill_tbl.name or i)) or -123
									local running_skill_tbl = casted_spells[key] and casted_spells[key].storage.skill.real_skill == em_skill_tbl and casted_spells[key]
									em_skill_tbl.name = em_skill_tbl.preset_idx > 1 and (imgui_data.do_browse_pl_skills and presets_glob[em_skill_tbl.preset_idx] or em_presets_glob[name][em_skill_tbl.preset_idx]) or em_skill_tbl.name
									local search_name = em_skill_tbl.name == "" and "Skill "..i or em_skill_tbl.name:lower()
									local pattern_success, filter_ready = pcall(function()  return (filter_text_lower == "" or search_name:find(filter_text_lower))  end)
									
									if filter_ready or not pattern_success then
										imgui.push_id(i + 33332)
										changed, em_skill_tbl.enabled = imgui.checkbox("", em_skill_tbl.enabled); set_wc("enabled", em_skill_tbl, true, em_skillslist.skills)
										drag_and_drop_skill_swapper(i, em_skill_tbl, imgui_data, em_skillslist.skills, imgui_enemy)
										tooltip("Enable/Disable the skill\nDrag and drop this checkbox onto another skill's Enable/Disable checkbox to move this skill\nHold "..sms.hotkeys["UI Modifier"].." while dragging to copy the skill as a duplicate"
										.."\nHold "..sms.hotkeys["UI Modifier2"].." while dragging to swap skills")
										imgui.pop_id()
										local was_swapping = temp.swap_skill_data
										imgui.same_line()
										
										local opened = imgui.tree_node_str_id("EmSkill"..i, "")
										imgui.same_line(); imgui.text_colored("Skill "..i, (running_skill_tbl and 0xFFAAFFFF) or (em_skill_tbl.enabled and 0xFFFFFFFF) or 0xFF999999)
										imgui.same_line(); imgui.text_colored(em_skill_tbl.name ~= "Skill "..i and em_skill_tbl.name or "", 0xFFE0853D)
										if em_skill_tbl.desc and em_skill_tbl.desc ~= "" then tooltip(em_skill_tbl.desc) end
										
										if opened then
											if imgui.button(imgui_data.use_window and "Close Window" or "Open Window") then imgui_data.use_window = not imgui_data.use_window end
											if imgui_data.use_window then 
												imgui.set_next_window_size({temp.disp_sz.x * 0.15, temp.disp_sz.y * 0.25}, 2) 
												imgui.set_next_window_pos({temp.disp_sz.x / 2 - temp.disp_sz.x * 0.075, temp.disp_sz.y / 2 - temp.disp_sz.y * 0.125}, 2, {0,0})
											end
											
											if imgui_data.use_window then
												window_fns[imgui_data] = function()
													imgui.set_next_window_size({temp.disp_sz.x * 0.33, temp.disp_sz.y * 0.4}, 2)
													imgui.set_next_window_pos({temp.disp_sz.x / 2 - temp.disp_sz.x * 0.165, temp.disp_sz.y / 2 - temp.disp_sz.y * 0.2}, 2, {0,0})
													
													local clicked_x = imgui.begin_window("Skill Maker - "..name.." Enemy Skill "..i, true, 0) == false
													if clicked_x or not imgui_data.use_window then 
														imgui_data.use_window = false
														window_fns[imgui_data] = nil
													else
														imgui.push_id(-99999 + i)
														disp_em_skill_imgui(em_skill_tbl, i, imgui_data, running_skill_tbl, name)
														imgui.pop_id()
													end
													imgui.end_window()
												end
											else
												disp_em_skill_imgui(em_skill_tbl, i, imgui_data, running_skill_tbl, name)
											end
											imgui.tree_pop()
										end
										imgui.spacing()
									end
								end
							end
							imgui.end_rect(2)
							imgui.tree_pop()
						end
					end
					imgui.tree_pop()
				end
			end
			imgui.tree_pop()
		end
	end
	if not temp.use_emsk_window then 
		imgui.end_rect(3)
	end
end

local function display_mod_imgui(is_window)
	
	local calc_width = imgui.calc_item_width()
	if not is_window then
		changed, sms.use_window = imgui.checkbox("Use Window", sms.use_window); set_wc("use_window")
		tooltip("Display this menu in its own window")
		imgui.begin_rect()
	end
	
	if imgui.button("Reset to Defaults") then
		was_changed = true
		setup_default_lists()
		local load_gamepad = sms.use_gamepad_defaults
		sms = hk.recurse_def_settings({}, default_sms)
		sms.use_gamepad_defaults = load_gamepad
		skillset_txt = ""
	end
	tooltip("Set all mod settings and skills back to their defaults")
	
	imgui.same_line()
	if imgui.button("Reset Hotkeys") then
		was_changed = true
		setup_gamepad_specific_defaults()
		hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
		hk.reset_from_defaults_tbl(default_sms.hotkeys)
	end
	tooltip("Reset all hotkeys to their default keybinds")
	
	imgui.same_line()
	if imgui.button("Rescan Files") then
		presets_glob, skillsets_glob = false
	end
	tooltip("Reloads the list of skill and skillset json files from [DD2 Game Directory]\\reframework\\data\\SkillMaker\\")
	
	if player then 
		imgui.same_line()
		if imgui.button("Reset Player State") or hk.check_hotkey("Reset Player State") then
			reset_character()
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
	tooltip("- Read every tooltip\n- Right click on any option to reset it\n- Ctrl + click on any slider to type-in a number, or double click on a drag-float\n- Press "..hk.get_button_string("UI Modifier").." + "..hk.get_button_string("Undo").." to undo"
	.."\n- Press "..hk.get_button_string("UI Modifier").." + "..hk.get_button_string("Redo").." to redo\n- Drag and drop a skill's 'Enabled' checkbox onto another 'Enabled' checkbox to move a skill"
	.."\n- Right click on certain drop-down menus to open a list box with which you can scroll and search. In some cases you can double click on entries to test them"
	.."\n- Hold ["..hk.get_button_string("UI Modifier").."] while changing a setting to change that setting for all enabled nodes (or skills, depending on the setting changed) below the node being changed"
	.."\n- Press the 'SM Clean Up' and 'Reset Player State' hotkeys (default Backspace) to quickly reset while testing\n- Skill descriptions can be created by right clicking on the 'Save Skill' text box"
	.."\n- If a problem happens with your controls, try resetting them in the game's Options menu\n- Press Shift+Tab to quickly switch between windows"
	.."\n- Skills are evaluated from last to first, so skills further in the list can override ones earlier that use the same input\n- Install EMV Engine + Console to research the game and make custom functions:\n					https://github.com/alphazolam/EMV-Engine")
	
	local opened_mod_options = imgui.tree_node("Mod Options")
	tooltip("Basic settings for Skill Maker")
	if opened_mod_options then
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
		changed, sms.max_skills = ui.imgui_safe_input(imgui.drag_int, "MaxSkills", "Max Skills", sms.max_skills, {1, 0, 9999}); set_wc("max_skills")
		tooltip("The maximum number of Skills available in the mod\nNewly added Skill slots will take controls settings from the previous slot")
		
		changed, sms.max_skillsets = ui.imgui_safe_input(imgui.drag_int, "MaxSkillsets", "Max Skillsets", sms.max_skillsets, {1, 0, 9999}); set_wc("max_skillsets")
		tooltip("The maximum number of Skillsets available in the mod")
		if was_changed and not was_was_changed then 
			setup_default_lists()
			hk.recurse_def_settings(sms, default_sms)
			hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
		end
		
		local prev_theme_type = sms.theme_type
		changed, sms.theme_type = imgui.combo("Theme", sms.theme_type, ui.themes.theme_names); set_wc("theme_type")
		tooltip("Set a color scheme for the mod windows")
		if changed then 
			ui.themes.pop_theme(ui.themes.theme_names[prev_theme_type])
		end
		
		imgui.same_line()
		if imgui.button("Fix Colors") then
			imgui.pop_style_color(999999999)
		end
		tooltip("Click this if your theme colors have spread to the main REFramework window or other windows outside of Skill Maker")
		
		imgui.begin_table("mod options", 2, 0, Vector2f.new(calc_width*1.3, 200), nil)
		imgui.table_setup_column(" ", 0, calc_width*0.5, 0)
		imgui.table_setup_column("  ", 0, calc_width*0.4, 0)
		imgui.table_headers_row()
		imgui.table_set_column_index(0)
		if sms.theme_type == 1 then imgui.table_set_bg_color(3, 0xFF1a1b19, 0) end
		
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
		
		changed, sms.use_colored_nodes = imgui.checkbox("Colored Node Borders", sms.use_colored_nodes); set_wc("use_colored_nodes")
		tooltip("Makes the rectangles around each node be a random color")
		
		changed, sms.show_boss_hp_bars = imgui.checkbox("Show Summon Boss HP Bars", sms.show_boss_hp_bars); set_wc("show_boss_hp_bars")
		tooltip("Display a custom blue health bar over summoned bosses")
		
		changed, sms.summons_lead_projectiles = imgui.checkbox("Summons Lead Projectiles", sms.summons_lead_projectiles); set_wc("summons_lead_projectiles")
		tooltip("Summons that fire projectiles at a target (using Skills) will attempt to lead their aim in front of the target if it is moving")
		
		changed, sms.use_gamepad_defaults = imgui.checkbox("Gamepad Button Defaults", sms.use_gamepad_defaults); set_wc("use_gamepad_defaults")
		tooltip("Makes it so when you reset to default controls, the default buttons will be for gamepad rather than keyboard")
		
		imgui.table_next_column()
		imgui.table_set_column_index(1)
		if sms.theme_type == 1 then imgui.table_set_bg_color(3, 0xFF1a1b19, 1) end
		
		imgui.text_colored("Hotkeys:", 0xFFAAFFFF)
		imgui.spacing()
		changed = hk.hotkey_setter("Modifier / Inhibit", nil, nil, "Hold this button to control other skill hotkeys and prepare-spellcasting animations.\nCan optionally disable the face buttons while held down"); set_wc()
		changed = hk.hotkey_setter("SM Modifier2", nil, "2nd Modifier", "Hold this button along with 'Modifier / Inhibit' to trigger even more skills"); set_wc()
		changed = hk.hotkey_setter("UI Modifier", nil, nil, "Hold this button to change functionalities in the UI"); set_wc()
		changed = hk.hotkey_setter("UI Modifier2", nil, nil, "Hold this button to change other functionalities in the UI"); set_wc()
		changed = hk.hotkey_setter("Undo", "UI Modifier2", nil, "Go back one state"); set_wc()
		changed = hk.hotkey_setter("Redo", "UI Modifier2", nil, "Go forward one state"); set_wc()
		changed = hk.hotkey_setter("Reset Player State", nil, nil, "Return the player to the normal walking state"); set_wc()
		changed = hk.hotkey_setter("SM Clean Up", nil, nil, "Remove all spawned shells and summons from the scene"); set_wc()
		
		imgui.end_table()
		imgui.end_rect(1)
		imgui.tree_pop()
		
	end
	imgui.spacing()
	
	local opened_ss_menu = imgui.tree_node("Skillsets")
	tooltip("Load lists of skills together as SkillSets")
	if opened_ss_menu then
		imgui.begin_rect()
		
		changed, sms.do_clear_spells_on_skset_load = imgui.checkbox("Clear Skills on Load", sms.do_clear_spells_on_skset_load)
		tooltip("If checked, all skills will be reset before loading any Skillset")
		
		imgui.same_line()
		changed, sms.load_sksets_w_sksets_modifier = imgui.checkbox("Skillset Modifier", sms.load_sksets_w_sksets_modifier); set_wc("load_sksets_w_sksets_modifier")
		tooltip("Require holding the Skillset Modifier down when selecting Skillsets via hotkey")
		
		imgui.same_line()
		changed, sms.load_sksets_w_modifier = imgui.checkbox("Modifier", sms.load_sksets_w_modifier); set_wc("load_sksets_w_modifier")
		tooltip("Require holding the Modifier down when selecting Skillsets via hotkey")
		
		if imgui.button("Save") then
			local controls = {}
			local used_skills = {}
			for i, skill_tbl in ipairs(sms.skills) do
				used_skills[i] = skill_tbl.enabled and sms.last_sel_spells[i] or nil
				controls[i] = used_skills[i] and {state_type_idx=skill_tbl.state_type_idx, hotkey=sms.hotkeys["Use Skill "..i], use_modifier2=skill_tbl.use_modifier2, button_press_type=skill_tbl.button_press_type, button_hold_time=skill_tbl.button_hold_time}
			end
			json.dump_file("SkillMaker\\Skillsets\\"..skillset_txt..".json", {last_sel_spells=used_skills, controls=controls})
			skillsets_glob = nil
		end
		tooltip("Save the current skill configuration as a Skillset to [DD2 Game Folder]\\reframework\\data\\SkillMaker\\Skillsets\\")
		imgui.same_line()
		
		imgui.set_next_item_width(calc_width * 0.5)
		changed, skillset_txt = imgui.input_text(" ", skillset_txt)
		tooltip("Type the name of the new Skillset in which to save the current list of skills")
		
		imgui.same_line()
		imgui.text("Controls:				Skillset Hotkey:")
		
		for i=1, sms.max_skillsets do 
			imgui.push_id(124235+i)
			local clicked_load = imgui.button("Load") and #skillsets_glob > 0; imgui.same_line()
			tooltip("Load a Skillset")
			
			imgui.set_next_item_width(calc_width * 0.5)
			changed, sms.skillsets.idxes[i] = imgui.combo("", sms.skillsets.idxes[i], skillsets_glob and skillsets_glob.short); set_wc(); imgui.same_line()
			tooltip("The name of the Skillset configuration file to load. A list of skills from it will replace the current skills")
			
			imgui.push_id(224235+i)
			changed, sms.skillsets.loadcontrols[i] = imgui.checkbox("Load	", sms.skillsets.loadcontrols[i]); imgui.same_line()
			tooltip("Load controls from this Skillset")
			imgui.pop_id()
			
			if sms.load_sksets_w_sksets_modifier then
				changed = hk.hotkey_setter("SM Config Modifier", nil, ""); set_wc() 
				imgui.same_line(); imgui.text("+"); imgui.same_line()
			end
			changed = hk.hotkey_setter("Load Skillset "..i, sms.load_sksets_w_modifier and "Modifier / Inhibit", ""); set_wc()
			
			if clicked_load and sms.skillsets.idxes[i] > 1 then
				load_skillset(skillsets_glob[sms.skillsets.idxes[i] ], i)
				skillset_txt = skillsets_glob.short[sms.skillsets.idxes[i] ]
				was_changed = true
			end
			imgui.pop_id()
		end
		
		imgui.end_rect(1)
		imgui.tree_pop()
	end

	local opened_enemyskill = imgui.tree_node("Enemy Skill")
	tooltip("Enable skills for enemies that activate when they do certain actions")
	
	if opened_enemyskill then
		if imgui.button(temp.use_emsk_window and "Close Window" or "Open Window") then temp.use_emsk_window = not temp.use_emsk_window end
		if temp.use_emsk_window then
			window_fns.enemy_skill = window_fns.enemy_skill or function()
				imgui.set_next_window_size({temp.disp_sz.x * 0.33, temp.disp_sz.y * 0.4}, 2)
				imgui.set_next_window_pos({temp.disp_sz.x / 2 - temp.disp_sz.x * 0.165, temp.disp_sz.y / 2 - temp.disp_sz.y * 0.2}, 2, {0,0})
				
				local clicked_x = imgui.begin_window("Skill Maker - Enemy Skill", true, 0) == false
				if clicked_x or not temp.use_emsk_window then 
					window_fns.enemy_skill = nil
					temp.use_emsk_window = false
				else
					imgui.push_id(88887)
					disp_enemy_skills_imgui()
					imgui.pop_id()
				end
				imgui.end_window()
			end
		else
			disp_enemy_skills_imgui()
		end
		imgui.tree_pop()
	end
	
	if sms.max_skills ~= #sms.skills then
		setup_default_lists()
		hk.recurse_def_settings(sms, default_sms)
		hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
	end
	
	imgui.set_next_item_width(calc_width * 0.5)
	changed, imgui_skills.filter_text = imgui.input_text("Filter Skills", imgui_skills.filter_text)
	tooltip("Filter player skills by name")
	local filter_text_lower = imgui_skills.filter_text:lower()
	
	local action_info = table.pack(disp_action_info_imgui(player, true))
	if is_window then imgui.begin_child_window(nil, true, 0) end
	
	for i, skill_tbl in ipairs(sms.skills) do
		local was_changed_before_skill = was_changed
		local imgui_data = imgui_skills[i]
		
		imgui_data.action_info = action_info
		local running_skill_tbl = casted_spells[i]
		if not imgui_data.precached_json and imgui_data.preset_idx > 1 then
			imgui_data.precached_json = json.load_file("SkillMaker\\Skills\\"..presets_glob[imgui_data.preset_idx]..".json") or {}
			imgui_data.precached_json.name = imgui_data.precached_json.name or (next(imgui_data.precached_json) and presets_glob[imgui_data.preset_idx])
		end
		local search_name = skill_tbl.name == "" and "Skill "..i or skill_tbl.name:lower()
		local pattern_success, filter_ready = pcall(function() return (search_name == "" or search_name:find(filter_text_lower)) end)
		
		if filter_ready or not pattern_success then
			imgui.push_id(i + 44432)
			changed, skill_tbl.enabled = imgui.checkbox("", skill_tbl.enabled); set_wc("enabled", skill_tbl, true, sms.skills)
			tooltip("Enable/Disable the skill\nDrag and drop this checkbox onto another skill's checkbox to move this skill\nHold "..sms.hotkeys["UI Modifier"].." while dragging to copy the skill as a duplicate"
			.."\nHold "..sms.hotkeys["UI Modifier2"].." while dragging to swap skills")
			imgui.pop_id()
			imgui.same_line()
			
			drag_and_drop_skill_swapper(i, skill_tbl, imgui_data, sms.skills, imgui_skills)
			
			local opened = imgui.tree_node_str_id("Skill"..i, ""); imgui.same_line(); imgui.text_colored("Skill "..i, running_skill_tbl and 0xFFAAFFFF or (skill_tbl.enabled and 0xFFFFFFFF or 0xFF999999))
			imgui.same_line(); imgui.text_colored(sms.last_sel_spells[i] ~= "Skill "..i and sms.last_sel_spells[i] or "", running_skill_tbl and 0xFFAAFFFF or 0xFFE0853D)
			local glob_idx = presets_map[sms.last_sel_spells[i] ]
			local skill_desc = glob_idx and sms.skill_descs[glob_idx] and sms.skill_descs[glob_idx] 
			if skill_desc and skill_desc ~= "" then tooltip(skill_desc:gsub("%%", "%%%%")) end 
			
			if not skill_tbl.do_auto then
				if skill_tbl.use_modifier2 and not imgui.same_line() then
					imgui.push_id(i + 34543674)
					changed = hk.hotkey_setter("SM Modifier2", nil, "", nil); set_wc()
					imgui.pop_id()
					imgui.same_line()
					imgui.text("+")
				end
				
				if skill_tbl.state_type_idx == 3 and not imgui.same_line() then
					imgui.push_id(i + 34543675)
					imgui.button("Switch Weapon Skill")
					imgui.pop_id()
					imgui.same_line()
					imgui.text("+")
				end
				imgui.same_line()
				changed = hk.hotkey_setter("Use Skill "..i, skill_tbl.state_type_idx == 2 and "Modifier / Inhibit", "", "Creates a shell for skill "..i); set_wc()
			end
			
			if opened then
				if imgui.button(imgui_data.use_window and "Close Window" or "Open Window") then imgui_data.use_window = not imgui_data.use_window end
				if imgui_data.use_window then
					
					window_fns[imgui_data] = function()
						imgui.set_next_window_size({temp.disp_sz.x * 0.33, temp.disp_sz.y * 0.4}, 2)
						imgui.set_next_window_pos({temp.disp_sz.x / 2 - temp.disp_sz.x * 0.165, temp.disp_sz.y / 2 - temp.disp_sz.y * 0.2}, 2, {0,0})
						
						local clicked_x = imgui.begin_window("Skill Maker - Skill "..i, true, 0) == false
						if clicked_x or not imgui_data.use_window then 
							imgui_data.use_window = false
							window_fns[imgui_data] = nil
						else
							imgui.push_id(88888 + i)
							disp_player_skill_imgui(skill_tbl, imgui_data, i, running_skill_tbl)
							imgui.pop_id()
						end
						imgui.end_window()
					end
				else
					disp_player_skill_imgui(skill_tbl, imgui_data, i, running_skill_tbl)
				end
				imgui.tree_pop()
			end
			
			if skill_tbl.unedited and was_changed and not was_changed_before_skill and was_changed ~= "skillswap" and was_changed ~= "cross_skillswap" then
				skill_tbl.unedited, skill_tbl.enabled = false, true
			end
			imgui.spacing()
		end
	end
	
	imgui.indent(calc_width * 0.5)
	imgui.text_colored("v"..version.."  |  By alphaZomega", 0xFFAAFFFF)
	imgui.unindent(calc_width * 0.5)
	
	imgui.spacing()
	if is_window then 
		imgui.end_child_window() 
	else
		imgui.end_rect(2)
	end
end

temp_fns.last_dummy_skill_runner = function()
	local dummy = temp.last_dummy_skill and temp.last_dummy_skill.em_chr
	if dummy and dummy:get_Valid() and (temp.force_dummy_action or hk.check_hotkey("Run Enemy Skill Test"))  then
		temp.force_dummy_action = nil
		enemy_casts[dummy:get_ActionManager()] = temp.last_dummy_skill
	end
end

local function reset_fall_height(seconds, owner)
	owner = owner or player
	local f_param = owner["<FallDamageParamCalc>k__BackingField"]["<Param>k__BackingField"]
	f_param.HeightDamageForHuman, f_param.HeightDamageForSmall, f_param.HeightDamageForLarge = 1000, 1000, 1000
	local start = game_time
	
	temp_fns.fix_fall_height = function()
		if game_time - start > seconds then --game tries admirably hard to remember your last freefall state
			temp_fns.fix_fall_height = nil
			f_param.HeightDamageForHuman, f_param.HeightDamageForSmall, f_param.HeightDamageForLarge = 8.0, 3.5, 10.0
		end
	end
end

local function nearest_enemy_fn(compare_pos, extra_fn, do_add_player, owner, do_necro)
	owner = owner or player
	local dist = 999999
	local closest_pos
	local closest_em
	local is_pl_side = (owner == player or sm_summons[owner])
	local targ_list = is_pl_side and func.lua_get_array(em_mgr._EnemyList._items, true) or func.lua_get_array(owner:get_HateSystem()._Ranking, true)
	if do_add_player then table.insert(targ_list, 1, owner) end
	
	for i, enemy in ipairs(targ_list) do
		local chara = enemy._Chara or (enemy.get_TargetCharacter and enemy:get_TargetCharacter())
		if chara then
			local em_pos = (chara.Hip or chara["<Transform>k__BackingField"]):get_Position()
			local this_dist = (em_pos - compare_pos):length()
			local hp = chara["<Hit>k__BackingField"]:get_Hp()
			local dead_ready = do_necro == 1 or (do_necro and hp <= 0) or (not do_necro and hp > 0)
			if ((do_add_player and i == 1) or dead_ready) and this_dist < dist and (not extra_fn or extra_fn(this_dist)) then
				dist, closest_pos, closest_em = this_dist, em_pos, chara
			end
		end
	end
	return closest_pos, closest_em
end

local ai_data = {
	exec_mth = sdk.find_type_definition("app.AIBlackBoardExtensions"):get_method("setBBValuesToExecuteActInter(app.AIBlackBoardController, app.ActInterPackData, app.AITarget)"),
	monster = {
		dash = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/Common/Monster_Dash.user"),
		run = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/Common/Monster_Run.user"),
		walk = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/Common/Monster_Walk.user"),
		common_wait = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/Common/Monster_Wait.user"),
		fly = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/FlightCommon/Monster_AirPathTraceTarget.user"),
		fly_coords = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/FlightCommon/Monster_AirPathTrace.user"),
		hover = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/FlightCommon/monster_hoverwait.user"),
		hover_fwd = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/FlightCommon/monster_hoverforward.user"),
		land = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/FlightCommon/monster_hoverlanding.user"),
		air_wait = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/FlightCommon/monster_airwait.user"),
		common_die = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Common/Die.user"),
		common_idle = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Common/Idle.user"),
		common_run = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Common/Move_Run_Target.user"),
		common_walk = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Common/Move_Walk_Target.user"),
		common_dash = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Common/Move_Dash_Target.user"),
		wait = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Common/Move_FinishWait.user"),
		common_takeoff = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/Monster/FlightCommon/Monster_TakeOff.user"),
	},
	human = {
		common_run = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch226/uniquelocomotion/ch226_move_run.user"),
		common_walk = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch226/uniquelocomotion/ch226_move_walk.user"),
		common_dash = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch226/uniquelocomotion/ch226_move_dash.user"),
		common_wait = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch230/Common/ch230_wait.user"),
	},
	cant_dash = {ch255=true, ch253=true, ch256=true},
	can_fly = {ch222=true, ch253=true, ch253=true, ch257=true, ch258=true},
	backup = {},
}

ai_data.custom = {
	ch221 = {run = ai_data.monster.run, dist = 10.0}, --rattler types
	ch252 = {run = ai_data.monster.run, dist = 15.0}, --golem
	ch254 = {run = ai_data.monster.run, dist = 10.0}, --chimera
	ch259 = {run = sdk.create_userdata("app.ActInterPackData", "AppSystem/ai/actioninterface/actinterpackdata/ch259/common/ch259com_walk.user"), dist=10.0},
	ch227 = { --Lich/Wight 
		run = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch227/hover/ch227_hoverforward_fast.user"),--ai_data.monster.hover_fwd,
		wait =  ai_data.monster.hover, 
		dist = 10.0,
	}, 
	ch224 = { --slimes (doesnt work?)
		run =  sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch224/common/ch224com_walk.user"),  
		wait = ai_data.monster.wait,--sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch224/role/ch224rol_appearwait.user"),
		dist = 10.0,
	},
	ch229 = {run = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch229/Common/ch229com_warptotarget.user"),dist = 20.0}, --dullahan warp
	ch255 = { --medusa / sacred arbor + Volcanic Island purgener
		run = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch255/uniquelocomotion/ch255run.user"),
		wait = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch255/uniquelocomotion/ch255wait.user"),
		dist = 10.0,
	}, 
	--ch256 = {run = sdk.create_userdata("app.ActInterPackData", "AppSystem/AI/ActionInterface/ActInterPackData/ch256/common/ch256_jumptarget_nofalldamage.user"), dist = 5.0}, --minotaur
}

--Spawn and manage sm_summons
summon = function(nstore, position, rotation, existing_gameobj, owner)
	
	local shell = nstore.shell	
	local exist_name = existing_gameobj and existing_gameobj:get_Name():sub(1,8)
	exist_name = exist_name and (enemy_list[exist_name] or enemy_list[exist_name:sub(1,3)]).name
	local summon_idx = (not existing_gameobj and shell.summon_idx) or (exist_name and func.find_key(enemy_names.short.no_parens, exist_name))+1
	local pfb_path = summon_idx and enemy_names[summon_idx]:match("(AppSys.+)")
	if not pfb_path then return end
	
	owner = owner or player
	local tics = 0
	local enemy, chara, em_xform, em_ui, did_poof, ran_once, mult
	local aibb, executor, exec_actinter, ch2, t_ctrl, corrupt_ctrl, act_mgr
	local pfb = sdk.create_instance("via.Prefab"):add_ref()
	local i_info = sdk.create_instance("app.InstanceInfo"):add_ref()
	local g_info = sdk.create_instance("app.GenerateInfo.GenerateInfoContainer"):add_ref()
	local chara_id_name = pfb_path:match(".+/(.+)%.pfb")
	local ch2_name = chara_id_name:sub(1,5)
	local do_set_color = shell.summon_var_tblstr or table.concat(shell.summon_color):sub(1,9) ~= "1.01.01.0"
	local is_replaced = (nstore.parent and nstore.parent.spell.do_replace_enemy and not nstore.parent.spell.do_replace_dont_respawn)
	local is_hostile = shell.summon_hostile or is_replaced
	local em_tbl = enemy_list[chara_id_name]
	temp.summoned_medusa = ch2_name == "ch255" or nil
	nstore.owner = owner
	nstore.hostile_to_all = is_hostile and shell.summon_hostile_to_all
	nstore.summon_em_tbl = em_tbl
	nstore.is_replaced = is_replaced
	nstore.is_possessed = ((shell.do_possess_enemy and shell.enemy_soft_lock) or owner:get_GameObject() == existing_gameobj) and not not existing_gameobj
	nstore.summon_start = game_time
	nstore.running_skills = {}
	nstore.hp = 1
	rel_db = {} --clear relationships cache
	
	local sz_ratio = 1.0
	local is_dhan, is_cyclops, is_sphinx, is_mino, is_medusa, is_jobber = (ch2_name=="ch229"), (ch2_name=="ch250" or ch2_name=="ch252"), (ch2_name=="ch253"), (ch2_name=="ch256"), (ch2_name=="ch255"), (ch2_name=="ch230" or ch2_name=="ch226")
	local is_em_targer = is_cyclops or is_sphinx or is_mino or em_tbl.is_human or is_medusa 
	local can_reset_act = not (em_tbl.can_fly or em_tbl.can_float or is_medusa or is_dhan)
	local ai_tbl = (em_tbl.is_human or em_tbl.name == "Skeleton") and ai_data.human or ai_data.monster
	local custom_pack = ai_data.custom[ch2_name]
	local is_stuck, stuck_timer, is_fly, hover_start, ground_height, prev_pos
	local dist_lvl, last_dist_lvl, dist_to_target = 99, 99, 999.0
	local wait_pack = ai_tbl.common_wait
	local walk_pack = ai_tbl.walk or ai_tbl.common_walk
	local run_pack = ai_tbl.common_run
	local dash_pack = (not ai_data.cant_dash[ch2_name] and ai_tbl.common_dash) or run_pack
	
	local function update_ai_data(position, enemy_ai_targ)
		mult = (nstore.summon_follow_dist_multiplier or 1.0) * sz_ratio
		if position or (owner and owner:get_Valid()) then
			local em_pos, owner_pos = em_xform:get_Position(), (position or owner:get_Transform():get_Position()) 
			dist_to_target = (Vector3f.new(em_pos.x, owner_pos.y, em_pos.z) - owner_pos):length()
		end
		last_dist_lvl = dist_lvl
		dist_lvl = dist_to_target > 20.0*mult and 3 or dist_to_target > 15.0*mult and 2 or dist_to_target > 10.0*mult and 1 or 0
		is_fly = chara:get_IsFlight()
		ground_height = is_fly and chara:get_Transform():get_Position().y - chara:get_FlightCtrl():get_NowLandPos().y
		stuck_timer = is_fly and (chara:get_CharaController():get_NumGroundContactPoints() + chara:get_CharaController():get_NumWallContactPoints()) > 0 and (stuck_timer or game_time) or nil
		is_stuck = stuck_timer and game_time - stuck_timer > 2.0
		nstore.target_type = nstore.target_type or (is_battling or enemy_ai_targ or is_em_targer) and 9 or (is_fly or is_dhan) and 46 or 34
		nstore.current_pack = exec_actinter and exec_actinter:get_ActInterPackData()
		if is_fly and nstore.current_pack == ai_data.monster.fly and ground_height < 3.0 then 
			em_xform:set_Position(nstore.summon_pos.x, prev_pos.y, nstore.summon_pos.z) 
			is_fly = 1
		end
	end
	
	local function get_pack(do_move, given_dist_lvl)
		if do_move then
			local dist_lvl = given_dist_lvl or dist_lvl
			return (is_stuck and ai_data.common_takeoff) or (custom_pack and dist_to_target > (custom_pack.dist or 15.0) and custom_pack.run) 
				or (dist_lvl==3 and ((is_fly and ai_tbl.fly) or (em_tbl.can_fly and ai_data.monster.common_takeoff) or dash_pack)) 
				or dist_lvl==2 and (is_fly and ai_tbl.hover_fwd or run_pack) or dist_lvl==1 and (is_fly and ai_tbl.hover or run_pack) or (is_fly and ai_tbl.hover or walk_pack)
		else
			return (custom_pack and custom_pack.wait) or (is_fly and ai_tbl.hover) or wait_pack
		end
	end
	
	local function set_act_inter(pack_data, ai_target, do_reset_action)
		if do_reset_action then 
			act_mgr:endAction(0); act_mgr:endAction(1) 
			act_mgr:requestActionCore(0, "NormalLocomotion", 0)
		end
		--print("Set Action Interface:", pack_data:get_Path())
		if is_fly == 1 and pack_data == ai_data.monster.fly then pack_data = ai_tbl.hover_fwd end
		executor:forceEndActionForState()
		executor:setBBActInterEnd()
		ai_data.exec_mth:call(nil, aibb, pack_data, ai_target)
		if exec_actinter then
			exec_actinter:set_ActInterPackData(bhv)
			exec_actinter:set_Target(pl_targ)
		end
		aibb:set_ReqMainActInterPackData(pack_data)
		if t_ctrl then t_ctrl:changeTarget() end
	end
	
	local function find_em(max_dist)
		local targ = t_ctrl and t_ctrl:getTarget(9):get_Character()
		return targ and targ:get_Hp() > 0 and (targ:get_Transform():get_Position() - em_xform:get_Position()):length() < max_dist and targ
	end
	
	nstore.command_summon_fn = function(coords) --moves the monster towards the given coordinate (or to the crosshair if none given) and lets them fight there
		if not coords then 
			local gresults = func.cast_ray(cam_matrix[3], cam_matrix[3] + cam_matrix[2] * -300, 2, 0, 0, 0)[1]
			coords = gresults and gresults[2]
			if not coords then print("No Results") return end
		end
		local was_climbing, start, is_waiting, found_em = nstore.player_climbing, game_time
		local ai_pos = sdk.create_instance("app.AITargetPosition", true):add_ref()
		ai_pos._Position = scene:toUniversalPosition(coords)
		
		nstore.following = nil
		update_ai_data(coords)
		if (coords - owner:get_Transform():get_Position()):length() < 7.5 then late_fns[i_info] = nil;	return end --cancel all commands if you make one right next to yourself
		set_act_inter(get_pack(true), ai_pos, can_reset_act)
		nstore.following = is_fly or is_cyclops or em_tbl.is_human  --or is_medusa
		nstore.command_coords = coords
		
		late_fns[i_info] = function() --this function's existence prevents following updating
			local is_force_time, had_em = (game_time - start < 3.0), found_em
			if not chara:get_Valid() or not pre_fns[g_info] or (is_battling and not is_force_time) then print("cancel") late_fns[i_info] = nil; return end
			found_em = not is_force_time and find_em(15.0)
			update_ai_data(coords, found_em)
			
			if found_em then 
				nstore.following, temp_fns[ch2] = nil
				if not had_em then executor:forceEndActionForState() end
			elseif is_waiting then 
				if (game_time - start > 5.0) then 
					late_fns[i_info] = nil 
					executor:forceEndActionForState()
				end
			elseif (Vector3f.new(nstore.summon_pos.x, coords.y, nstore.summon_pos.z) - coords):length() < 5.0 then
				start, is_waiting, nstore.following = game_time, true
				set_act_inter(get_pack(false), ai_pos, can_reset_act)
			elseif (was_climbing and not nstore.player_climbing) or game_time - start > 30.0 then
				late_fns[i_info] = nil
			--elseif tics % 60 == 0 and (prev_pos - nstore.summon_pos):length() < 0.1 then
			--	set_act_inter(get_pack(not is_waiting), ai_pos, can_reset_act) 
			end
		end
	end	
				
	_G.Node = nstore
	local custom_parts_tbl = shell.partswap_data ~= "" and get_table_load_fn(shell.partswap_data)() or {}
	_G.Node = nil
	
	if not nstore.is_possessed then
		pfb:set_Path(pfb_path)
		pfb:set_Standby(true)
		g_info._CommonInfo._ContextPosition = scene:toUniversalPosition(position)
		g_info._CommonInfo._ContextAngle = rotation
        g_info._CommonInfo._Category = 3
		g_info._StatusInfo["<ScaleRate>k__BackingField"] = shell.summon_scale
		g_info._StatusInfo._CustomCharaStatusID = 0
		g_info._CharaInfo._IsWanderMode = true
		local new_ch_id = custom_parts_tbl._CharaID or enums.chara_id_enum[chara_id_name]
		g_info._CommonInfo._ObjectID._SelectedCharacterID = new_ch_id
		g_info._CommonInfo._RequestID:setCharacterID(new_ch_id)
	end
	
	pre_fns[g_info] = function(do_force_kill) --runs every frame
		local prev_enemy = enemy
		enemy = enemy or existing_gameobj or i_info["<Instance>k__BackingField"]
		
		if enemy and not enemy:get_Valid() or not player then --abandon
			pre_fns[g_info], sm_summons[chara or -1], em_summons[chara or -1], active_summons[chara or -1] = nil
			
		elseif game_time - nstore.summon_start > shell.summon_timer or do_force_kill or (tics == 300 and enemy and not enemy:get_UpdateSelf()) then --destroy
			pre_fns[g_info], sm_summons[chara], active_summons[chara], em_summons[chara] = nil
			if not nstore.is_possessed and not is_replaced then 
				gen_mgr:call("requestDestroy(app.GenerateInfo.GenerateInfoContainer, System.Boolean, System.Boolean, System.Boolean, System.Boolean)", g_info, false, false, false, false)
				enemy:destroy(enemy)
			end
		elseif not enemy and not nstore.is_possessed and pfb and pfb:get_Ready() then --spawn
			local pfb_ctrl = sdk.create_instance("app.PrefabController"):add_ref(); pfb_ctrl._Item = pfb
            chr_mgr["<CustomCharaStatusParam>k__BackingField"]._CustomCharaParams[1]._AttackRate = shell.summon_attack_rate * nstore.spell.damage_multiplier
			gen_mgr:call("requestCreateInstance(app.PrefabController, app.GenerateInfo.GenerateInfoContainer, System.Int32, app.InstanceInfo, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>)", 
				pfb_ctrl, g_info, 0, i_info, 0, 0)
		elseif enemy and not prev_enemy then --setup
			enemy:set_FolderSelf(scene:call("findFolder(System.String)", "Enemy"))
			chara = existing_gameobj and func.getC(existing_gameobj, "app.Character") or i_info["<Chara>k__BackingField"]
			nstore.old_nstore = summon_record[chara] 
			if nstore.old_nstore then
				nstore = hk.merge_tables(nstore, nstore.old_nstore, true)
			end
			summon_record[chara] = summon_record[chara] or nstore
			em_xform = enemy:get_Transform()
			nstore.summon_inst = chara
			sm_summons[chara] = ((not is_hostile and owner == player) or sm_summons[owner]) and nstore or false
			active_summons[chara] = nstore
			em_ui = func.getC(em_xform:find("ui020601"):get_GameObject(), "app.ui020601")
			em_ui.IsHostile = true
			aibb = chara:get_AIBlackBoardController()
			act_mgr = chara:get_ActionManager()
			--nstore.following = true
			
			if custom_parts_tbl._CharaID then
				g_info._CommonInfo._ObjectID._SelectedCharacterID = enums.chara_id_enum[chara_id_name] 
				g_info._CommonInfo._RequestID:setCharacterID(enums.chara_id_enum[chara_id_name])
				chara.CharaIDContext.CharacterID = enums.chara_id_enum[chara_id_name]
			end
			
			local bounding_box = func.getC(chara:get_GameObject(), "via.render.Mesh"):get_ModelLocalAABB()
			local scale = em_xform:get_Scale().y
			sz_ratio = normalize_single((bounding_box:getCenter():length()/2)*scale, 0.7, 10.0*scale, 1.0, 4.0) --FIXME
			
			if sm_summons[chara] then 
				chara:get_GroupContext():setDefaultGroup("StrayPawn")
				chara:get_GroupContext():setTempGroup("StrayPawn")
				chara:get_GroupContext():changeGroup("StrayPawn")
			else
				em_summons[chara] = nstore
			end
			
			if shell.summon_no_dissolve then
				chara.CharaDissolveCtrl["<IsDisableStartDissolve>k__BackingField"] = true
			end
			
			--if chara:get_LightDarkSensor() then
			--	chara:get_LightDarkSensor():set_Enabled(false)
			--end
			
			if not nstore.is_possessed then
                gen_mgr:call("app.GenerateManager.prepareSound(app.Character)", chara)
				local parts = func.getC(enemy, "app.PartSwapper")
				local human = chara:get_Human()
				local warp = chara.CharaEditWarpCtrl
					
				if ch2_name == "ch220" then
					warp:call("buildPartsFromCh220(System.UInt16, System.UInt16, System.UInt16)", math.random(0, 5), 0, 0) --goblins
				elseif ch2_name =="ch230" then
					warp:call("buildPartsFromCh230(System.Byte, System.Byte)", math.random(1,255), math.random(1,255)) --humans
				end
				
				if parts then
					--randomize skills:
					pre_fns[warp] = human and function()
						if not chara:get_Valid() then pre_fns[warp] = nil; return end
						local human_enemy = human.HumanEnemyController
						
						if human_enemy and human_enemy.JobContext then
							pre_fns[warp] = nil
							local job_id = human_enemy.JobContext.CurrentJob
							local range = temp.job_mixup_ranges[job_id]
							if range then
								local used = {}
								local skills = human_enemy.SkillContext.EquipedSkills[job_id].Skills
								for j=0, 3 do
									skills[j] = math.random(range[1], range[2])
									while used[ skills[j] ] do
										skills[j] = math.random(range[1], range[2])
									end
									used[ skills[j] ] = true
								end
							end
						end
					end
                    
					local body_editor = func.getC(chara:get_GameObject(), "app.BodyEditor")

					pre_fns[parts] = function()
						if not chara:get_Valid() then pre_fns[parts] = nil; return end 
						if not chara:get_GameObject():get_DrawSelf() or parts:get_BodyBeingSwapping()  then return end --
						pre_fns[parts] = nil	
						
						if next(custom_parts_tbl) then
							local td = parts._Meta:get_type_definition()
							for field_name, value in pairs(custom_parts_tbl) do
								local f_td = parts._Meta[field_name] and td:get_field(field_name):get_type()
								if f_td and f_td:is_a("System.Enum") then
									local f_td_name = f_td:get_full_name()
									if not enums[f_td_name] then
										enums[f_td_name], enums[f_td_name.."names"] = func.generate_statics(f_td_name, true)
									end
									value = tonumber(value) and value < 1000 and value > 0 and enums[f_td_name][enums[f_td_name.."names"][value] ] or enums[f_td_name][value]
									parts._Meta[field_name] = value or parts._Meta[field_name]
								end
							end
						end
						
						if ch2_name == "ch230" then
							local is_male = parts._Meta._Gender == 2776536455
							if not custom_parts_tbl._TopsStyle then
								local new_top = enums.tops_enum[enums.tops[math.random(1, 101)] ]
								while (is_male and fem_tops[new_top]) do new_top = enums.tops_enum[enums.tops[math.random(1, 101)] ] end
								parts._Meta._TopsStyle = new_top
							end
							if not custom_parts_tbl._PantsStyle then
								local new_pants = enums.pants_enum[enums.pants[math.random(1, 75)] ]
								while (is_male and fem_pants[new_pants]) do new_pants = enums.pants_enum[enums.pants[math.random(1, 75)] ] end
								parts._Meta._PantsStyle = new_pants
							end
							if not custom_parts_tbl._HelmStyle and math.random(1,2) == 1  then parts._Meta._HelmStyle = enums.helms_enum[enums.helms[math.random(1, 91)] ] end
							if not custom_parts_tbl._MantleStyle and math.random(1,2) == 1 then parts._Meta._MantleStyle = enums.mantles_enum[enums.mantles[math.random(1, 54)] ] end
						end
						
						if body_editor then body_editor:call("rebinding()") end
						parts:call("requestSwap()")

						if custom_parts_tbl._LeftWeapon or custom_parts_tbl._RightWeapon then
							local wep_holder = chara:get_WeaponAndItemHolder()
							wep_holder:setEmpty()
							local function set_wp(side_str, wp_id)
								wp_id = enums.wp_enum[wp_id] or enums.wp_enum[enums.wps[wp_id] ] or wp_id
								chara.WeaponContext[side_str.."Weapon"] = wp_id or chara.WeaponContext[side_str.."Weapon"]
							end
							if custom_parts_tbl._LeftWeapon then set_wp("Left", custom_parts_tbl._LeftWeapon) end
							if custom_parts_tbl._RightWeapon then set_wp("Right", custom_parts_tbl._RightWeapon) end
						end
					end
					pre_fns[warp]()
					pre_fns[parts]()
				end
			end
			
			if ch2_name == "ch255" then 
				nstore.medusa_action = act_mgr.Fsm:getLayer(0):get_tree_object():get_node_by_name("Ch255Wait"):get_unloaded_actions()[1]
				nstore.medusa_action.BeadsModelMode = 4 --prevents medusa from snaking into the air
			end
			
			local workrate = chara.WorkRate
			if chara.WorkRate and shell.summon_speed ~= 1.0 then
			
				temp_fns[workrate] =  function()
					temp_fns[workrate] = pre_fns[key] and temp_fns[workrate]
					if temp_fns[chara.WorkRate] then
						workrate.NextRateValue = shell.summon_speed
						workrate.NextApplyRate = shell.summon_speed
					end
				end
			end
			if not enemy:get_Name():find("___") then
				enemy:set_Name(enemy:get_Name().."___"..nstore.parent.skill.name.."_"..nstore.idx)
			end
		elseif em_ui and em_ui.HP then --every frame
			ch2 = ch2 or chara.EnemyCtrl.Ch2
			t_ctrl = ch2._TargetController
			nstore.current_target = t_ctrl and t_ctrl._AITarget
			prev_pos = nstore.summon_pos or em_xform:get_Position()
			nstore.summon_pos = em_xform:get_Position()
			nstore.num_living_children = nstore.num_living_children + 1
			executor = executor or ch2:get_ActInter():get_Executor()
			nstore.hp = chara:get_Hp()
			nstore.player_climbing = (sm_summons[chara] and chara.ClimbersInfo._items[0] and temp.pos_sub_mth:call(nil, pl_xform:get_UniversalPosition(), chara.ClimbersInfo._items[0].ClimbUniversalPosition):length() < 3.0) or nil
			nstore.command_coords = late_fns[i_info] and nstore.command_coords
			
			for key, skill_storage in pairs(nstore.running_skills) do
				nstore.running_skills[key] = active_skills[key] and nstore.running_skills[key]
			end
			
			if nstore.hp > 0 and not is_hostile then
				if em_tbl.is_boss and sms.show_boss_hp_bars then
					if not nstore.overhead_pos_ctrl then
						local o_go = em_xform:find("OverHead"):get_GameObject()
						o_go:set_UpdateSelf(true)
						nstore.overhead_pos_ctrl = func.getC(o_go, "app.OverHeadPosCtrl")
						nstore.overhead_pos_ctrl.HeadJoint = em_xform:getJointByName(nstore.overhead_pos_ctrl.HeadJointName)
					end
					local pos_3d = scene:fromUniversalPosition(nstore.overhead_pos_ctrl._Position)
					local pos_2d = draw.world_to_screen(Vector3f.new(pos_3d.x, pos_3d.y+0.33, pos_3d.z))
					if pos_2d then
						local sz = temp.disp_sz
						pos_2d.x = pos_2d.x * 0.925
						
						frame_fns[em_ui] = function()
							frame_fns[em_ui] = nil
							imgui.set_next_window_pos(pos_2d, 1, {0,0})
							imgui.set_next_window_size({sz.x * 0.18, sz.y * 0.01}, 1)
							imgui.begin_window(em_ui:get_address(), true, 129)
							imgui.push_style_color(7, 0xAA666666)
							imgui.push_style_color(40, 0xFFFF0000)
							imgui.progress_bar(nstore.hp / chara:get_ReducedMaxHp(), Vector2f.new(sz.x * 0.07, sz.y * 0.005))
							imgui.pop_style_color(2)
							imgui.end_window()
						end
					end
				else
					em_ui:get_GameObject():set_DrawSelf(true)
					em_ui:get_GameObject():set_UpdateSelf(true)
					em_ui.IsReqDisp = true
					em_ui.IsHostile = true
				end
			end
			
			local targ_idx = t_ctrl and func.find_key(t_ctrl._TargetArray, owner, "<Character>k__BackingField")
			local pl_targ = t_ctrl and ((targ_idx and t_ctrl._TargetArray[targ_idx]) or t_ctrl._ManualPalyerTarget) or aibb:get_PlayerOfAITarget()
			--nstore.current_target = t_ctrl and (t_ctrl:getTarget(nstore.target_type) or t_ctrl._AITarget)
			
			if pl_targ then
				if nstore.summon_behavior then 
					update_ai_data()
					local bhv = nstore.summon_behavior
					nstore.summon_behavior = nil
					set_act_inter(bhv, pl_targ, false)
					local start = game_time
					
					pre_fns[aibb] = function()
						pre_fns[aibb] = game_time - start < 2.0 and pre_fns[aibb] or nil --just a timer, prevents setBBValuesToExecuteActInter from running by existing
					end
				elseif not is_hostile and not nstore.is_dummy and not nstore.command_coords and not pre_fns[aibb] and not temp_fns[nstore] then
					update_ai_data()
					local is_loco = act_mgr.Fsm and act_mgr.Fsm:getCurrentNodeName(0); is_loco = is_loco and is_loco:find("Locomotion")
					if not is_loco and next(nstore.running_skills) then goto skip end
					
					--travel to player:
					if (tics == 30 and not is_battling and not nstore.was_dead) or is_stuck or ((not nstore.following or (last_dist_lvl < dist_lvl) or (tics % 120 == 0)) and (not is_battling or dist_to_target > 20.0*mult) and (dist_to_target > 11.0*mult) and (is_loco or dist_lvl==3)) then --
						local au_udata = get_pack(true)
						set_act_inter(au_udata, pl_targ, can_reset_act)
						nstore.following = true
						temp.summoned_medusa = is_medusa or nil
						print("started following", tics)
					--wait at player:
					elseif nstore.following then 
						if ((is_battling or dist_to_target < 10.0*mult) and dist_to_target < 20.0*mult) and (not hover_start or game_time - hover_start > 10.0*mult) then --or tics % 240 == 120 then
							hover_start = nil
							local au_udata = get_pack(false)
							nstore.following = nil
							set_act_inter(au_udata, pl_targ, can_reset_act)
							if t_ctrl then t_ctrl:changeTarget() end
							print("stopped following", tics)
						elseif em_tbl.is_human then
							chara:get_AIDecisionMaker():get_DecisionModule():requestSkipThink()
						end
					elseif is_fly and not em_tbl.can_float and nstore.current_pack and not is_battling then --make flyers land when they're close for a while
						hover_start = nstore.current_pack:get_Path():find("Hover") and (hover_start or game_time) or nil
						if hover_start and game_time - hover_start > 5.0 and ground_height < 10.0 * sz_ratio then 
							set_act_inter(ai_data.monster.land, pl_targ, can_reset_act)
							nstore.following = true
						end
					end
					::skip::
				end
			end
			
			if shell.summon_hp_rate ~= 1.0 then
				chara:get_Hit():set_DamageRate((shell.summon_hp_rate == 0 and 999999) or 1 / shell.summon_hp_rate)
			end
			
			nstore.start_tic = do_set_color and (nstore.start_tic or (chara:get_GameObject():get_DrawSelf() and tics))
			if nstore.start_tic and tics - nstore.start_tic > 2 and not nstore.old_nstore then
				do_set_color, nstore.start_tic = nil
				local mesh = ch2:get_Mesh()
				local col = Vector4f.new(shell.summon_color[1], shell.summon_color[2], shell.summon_color[3], 1.0)
                _G.Node = nstore
				change_material_float4(mesh, col, (shell.summon_col_var_term=="" and shell.summon_var_tblstr=="") and "BaseColor", true, shell.summon_col_mat_term ~= "" and shell.summon_col_mat_term, shell.summon_col_var_term ~= "" and shell.summon_col_var_term, shell.summon_var_tblstr, true) 
                _G.Node = nil
			end

			if (nstore.forced_action or (shell.summon_action_idx > 1 and not ran_once)) and not temp_fns[nstore] then --sm_summons[chara] ~= 1 and
				local nfa = nstore.forced_action
				local act_name = (nfa and nfa[1]) or enemy_action_names[em_tbl.name][shell.summon_action_idx]
				local tics_start = tics
				
				temp_fns[nstore] = function()
					if tics - tics_start >= 10 then
						temp_fns[nstore], nstore.forced_action = nil
						act_mgr:requestActionCore(0, act_name, (nfa and nfa[2]) or 0)
					end
				end
			end
			
			if not ran_once then
				ran_once = true
				exec_actinter = chara:get_AIDecisionMaker():get_DecisionModule() and chara:get_AIDecisionMaker():get_DecisionModule()._ExecuteActInter
				executor:setBBActInterEnd()
				corrupt_ctrl = nstore.was_dead and chara:get_CorpseCtrl() and chara:get_CorpseCtrl():get_CorruptionController()
				local ud_light_sensor = chara:get_LightDarkSensor()
				if ud_light_sensor and em_tbl.is_undead then ud_light_sensor:set_Enabled(false) end
				
				if sm_summons[chara] then
					em_mgr:removeEnemy(ch2)
					if owner == player then
						em_ui.HP:set_ColorScale(Vector4f.new(0,0.25,1,1)) --blue HP bar
					end
				else
					em_mgr:registerEnemy(ch2)
				end
				if ch2_name == "ch230" or ch2_name == "ch226" and not nstore.is_possessed then
					enable_pl_fsm_on_em(chara)
				end
				if not nstore.is_possessed then
					em_xform:set_Position(position)
					em_xform:set_Rotation(rotation)
				end
			end
			
			if nstore.hp <= 0 and not nstore.dying then 
				nstore.dying = true
				nstore.summon_start = game_time - shell.summon_timer + 5.0 --extra time to fall over
			end 
			
			if ch2_name == "ch255" and sm_summons[chara] then --medusa
				ch2._Ch255LookAtCtrl._Ch255LookAtTrack._TargetType = 9
				ch2._Ch255LookAtCtrl.Ch255UpperLookAtTrack._TargetType = 9
			end
			
			if nstore.was_dead and nstore.corpse_start then
				local nname = act_mgr.Fsm:getCurrentNodeName(0)
				--if game_time - nstore.summon_start < 5.0 or nname:find("DmgStandUp") or nname:find("Ragdoll") then
				--	chara:get_AIDecisionMaker():get_DecisionModule():requestSkipThink()
				--else
				if corrupt_ctrl and game_time - nstore.corpse_start > (shell.summon_timer / 3) then --get more rotten every 1/4th of the summon duration
					nstore.corpse_start = game_time
					nstore.corpse_lvl = (nstore.corpse_lvl < 3) and nstore.corpse_lvl+1 or 3
					corrupt_ctrl._BaseElapsedSeconds = corrupt_ctrl["_InGameCorruptionLv"..nstore.corpse_lvl.."FinishHour"] * 2500
				end
			end
			
			if nstore.following  then
				if ch2_name == "ch227" then --lich
					local rot, old_eul = lookat_method:call(nil, nstore.summon_pos, owner:get_Transform():get_Position(), Vector3f.new(0,1,0)):inverse():to_quat() * Quaternion.new(0,0,1,0), em_xform:get_EulerAngle() --lich normally wont rotate when following, just flies into the wall
					em_xform:set_EulerAngle(Vector3f.new(old_eul.x, em_xform:get_Rotation():slerp(rot, 0.15):to_euler().y, old_eul.z))
					local new_pos, mat = prev_pos:lerp(nstore.summon_pos, 1.5), chara:get_Transform():get_WorldMatrix(); mat[3].y = mat[3].y - 1.0 --faster
					if not chara:get_GroundDetector():call("checkAroundStandable(via.mat4, System.Single)", mat, 180.0) then
						new_pos = nstore.summon_pos:lerp(Vector3f.new(new_pos.x, prev_pos.y+0.125, new_pos.z), 0.5) --sinks like a stone when over water
					end
					em_xform:set_Position(new_pos)
				elseif ch2_name == "ch259" or ch2_name == "ch224"  then --talos / slimes
					local rot, old_eul = lookat_method:call(nil, nstore.summon_pos, owner:get_Transform():get_Position(), Vector3f.new(0,1,0)):inverse():to_quat() * Quaternion.new(0,0,1,0), em_xform:get_EulerAngle()
					local new_yaw = em_xform:get_Rotation():slerp(rot, (ch2_name == "ch224") and 1.0 or 0.0033):to_euler().y
					
					temp_fns[rot] = function()
						temp_fns[rot] = nil
						em_xform:set_EulerAngle(Vector3f.new(old_eul.x, new_yaw, old_eul.z))
						if ch2_name == "ch224" then 
							local wm = em_xform:get_WorldMatrix()
							em_xform:set_Position(wm[3] + wm[2] * 0.03)
						end
					end
				end
			end
			
			if nstore.old_nstore and nstore.old_nstore.manager_fn and nstore.old_nstore.finished  then
				nstore.old_nstore.manager_fn(nstore) --this is for summons who get resurrected / possessed so that their custom fn can keep running
			end
			
			if not nstore.is_dummy and (game_time - nstore.summon_start > shell.summon_timer - 0.125) and not did_poof then
				did_poof = true
				em_ui.HP:set_ColorScale(Vector4f.new(1,1,1,1))
				local owner_go = ((nstore.hp <= 0 or nstore.was_dead) and (owner:get_Valid() and owner:get_Hp() > 0 and owner:get_Transform() or pl_xform) or em_xform):get_GameObject()
				local base = nstore.sparam._ShellParameterBase.ShellBaseParam
				change_shell_udata(base, shell)
				
				local req_id = shell_mgr:call("requestCreateShell(via.GameObject, via.vec3, via.Quaternion, app.ShellRequest.ShellCreateInfo, app.ShellParamData, app.ShellRequest.EventCreateShellSuccess, app.ShellRequest.EventBeforeShellInstantiate)", 
					owner_go, (em_xform:getJointByName("Spine_2") or em_xform):get_Position(),  em_xform:get_Rotation(), nstore.shell_req, nstore.udata, nil, nil)
				
				if nstore.is_possessed or is_replaced then 
					em_mgr:registerEnemy(ch2)
					if shell.do_possess_enemy and nstore.was_dead then
						local d_info = sdk.create_instance("app.HitController.DamageInfo"):add_ref()
						d_info.Damage = 999999999.0
						chara:get_ActionManager():requestActionCore(0, "DmgRagdollFall", 0)
						sdk.get_managed_singleton("app.HitManager"):directDamage(d_info, chara:get_Hit(), 0, false, 0)
						if corrupt_ctrl then
						
							pre_fns[corrupt_ctrl] = function()
								pre_fns[corrupt_ctrl] = nil
								corrupt_ctrl._BaseElapsedSeconds = corrupt_ctrl["_InGameCorruptionLv"..nstore.corpse_lvl.."FinishHour"] * 2500
							end
						end
					end
				end
			end
		end
		if not pre_fns[g_info] then rel_db = {} end
		tics = tics + 1
	end
	nstore.summon_updater = pre_fns[g_info]
end

function cast_shell(smnode, nstore, owner, is_test)
	
	local udata_path = user_paths[smnode.udata_idx]
	udatas[udata_path] = udatas[udata_path] or sdk.create_userdata("app.ShellParamData", udata_path)
	nstore.udata = udatas[udata_path]
	nstore.shell_req = sdk.create_instance("app.ShellRequest.ShellCreateInfo"):add_ref()
	nstore.shell_req.ShellParamIdHash = nstore.udata.ShellParams._items[smnode.shell_id]._ShellParamIdHash
	
	nstore.sparam = nstore.udata.ShellParams._items[smnode.shell_id]
	local owner_xform = owner:get_Transform()
	local cast_type = is_test and 3 or smnode.cast_type
	local pl_mat = owner_xform:get_WorldMatrix()
	local attach_joint = cast_type == 3 and (owner_xform:getJointByName(smnode.joint_name) or owner_xform:getJointByName("Spine_2"))
	local ray_targ_pos = (_G.lock_on_target and owner==player and lock_on_target.lock_pos) or (nstore.ray and nstore.ray[2]) or (owner_xform:get_Position() + Vector3f.new(0,5,0) + owner_xform:get_WorldMatrix()[2] * 3)
	local is_ray_type = cast_type == 2 or (cast_type == 3 and (smnode.rot_type_idx == 3 or (smnode.do_aim_up_down and smnode.enemy_soft_lock and (_G.lock_on_target or (ray_targ_pos - pl_mat[3]):dot(pl_mat[2]) >= 5.5) and 1))) --Soft-lock + Aim up/down on 'Player' cast-type will use rays to softlock projectiles to aligned enemies:
	local not_pl_owner = (owner ~= player)
	local crosshair_frozen = (nstore.parent and nstore.parent[nstore.idx-1] and nstore.parent[nstore.idx-1].smnode.freeze_crosshair)
	
	if cast_type == 2 then 
		ray_targ_pos = ray_targ_pos + transform_method:call(nil, Vector3f.new(smnode.skyfall_dest_offs[1], smnode.skyfall_dest_offs[2], smnode.skyfall_dest_offs[3]), owner_xform:get_Rotation())
	end
	
	nstore.pos = (cast_type == 1 and ray_targ_pos + transform_method:call(nil, Vector3f.new(smnode.attach_pos[1], smnode.attach_pos[2], smnode.attach_pos[3]), owner_xform:get_Rotation())) --Target
		or  (cast_type == 2 and (smnode.skyfall_cam_relative and cam_matrix[3] or owner_xform:get_Position())) --Skyfall
		or  (cast_type == 3 and attach_joint:get_Position() + transform_method:call(nil, Vector3f.new(smnode.attach_pos[1], smnode.attach_pos[2], smnode.attach_pos[3]), owner_xform:get_Rotation()))  --Player
		or  (cast_type == 4 and nstore.p_instance_pos + transform_method:call(nil, Vector3f.new(smnode.attach_pos[1], smnode.attach_pos[2], smnode.attach_pos[3]), nstore.p_instance_rot)) --Prev Shell
		--or  cam_matrix[3] --Camera
	
	if cast_type == 2 then
		local offs = Vector3f.new(smnode.skyfall_pos_offs[1], smnode.skyfall_pos_offs[2], smnode.skyfall_pos_offs[3]) * 1000
		if smnode.skyfall_random_xz then
			local floor_x, floor_z = math.floor(offs.x), math.floor(offs.z)
			offs.x = (floor_x == 0 and offs.x) or offs.x > 0 and (math.random(-floor_x, floor_x)) or (math.random(floor_x, -floor_x))
			offs.z = (floor_z == 0 and offs.z) or offs.z > 0 and (math.random(-floor_z, floor_z)) or (math.random(floor_z, -floor_z))
		end
		nstore.pos = nstore.pos + (transform_method:call(nil, offs, smnode.skyfall_cam_relative and (camera:get_WorldMatrix()[2] * -1):to_quat() or owner_xform:get_Rotation()) * 0.001)
	end
	
	nstore.em_soft_lock_pos = nil
	if smnode.enemy_soft_lock then
		nstore.em_soft_lock_pos, nstore.em_soft_lock_enemy = nearest_enemy_fn(is_ray_type and ray_targ_pos or nstore.pos, function(this_dist)
			return this_dist < smnode.soft_lock_range
		end, nil, owner, smnode.soft_lock_type == 2 and true or smnode.soft_lock_type == 3 and 1 or nil)
		
		if nstore.em_soft_lock_pos then
			--if cast_type == 3 or cast_type == 4 then  nstore.em_soft_lock_pos = nstore.em_soft_lock_pos + transform_method:call(nil, Vector3f.new(smnode.attach_pos[1], smnode.attach_pos[2], smnode.attach_pos[3]), owner_xform:get_Rotation()) end
			if is_ray_type then
				ray_targ_pos = nstore.em_soft_lock_pos
			else
				nstore.pos = nstore.em_soft_lock_pos
			end
			if smnode.do_possess_enemy then 
				if nstore.em_soft_lock_enemy:get_Hp() <= 0 then
					local chr = nstore.em_soft_lock_enemy
					local em_tbl = enemy_list[enums.chara_id_enum[chr:get_CharaID()] ]
					local corpse_ctrl = chr:get_CorpseCtrl()
					if corpse_ctrl then
						nstore.corpse_start = game_time
						local cstep = corpse_ctrl:get_CorpseStep()
						nstore.corpse_lvl = cstep > 3 and 3 or cstep  --make/keep rotten
						corpse_ctrl:get_CorruptionController()._BaseElapsedSeconds = corpse_ctrl:get_CorruptionController()["_InGameCorruptionLv"..nstore.corpse_lvl.."FinishHour"] * 2500
					end
					chr:get_Hit():setHpValue(chr:get_Hit():get_ReducedMaxHp(), true)
					--if chr:get_Human() then
					--	enable_pl_fsm_on_em(chr)
					--end
					chr:reviveFromFallDead(true) --raise the dead
					chr:get_ActionManager():requestActionCore(0, "DmgRagdollFall", 0)
					local ud_light_sensor = chr:get_LightDarkSensor()
					if ud_light_sensor and em_tbl.is_undead then ud_light_sensor:set_Enabled(false) end
					nstore.was_dead = true
				end 
				summon(nstore, nil, nil, nstore.em_soft_lock_enemy:get_GameObject(), owner)
			end
		elseif is_ray_type == 1 then
			is_ray_type = false --it's conditional that an enemy must be soft-locked when using up/down ray soft-lock
		end
	end
	
	local velocity_add = sms.summons_lead_projectiles and is_ray_type and not crosshair_frozen and not_pl_owner and owner.EnemyCtrl.Ch2 and owner.EnemyCtrl.Ch2:getAttackTarget()
	velocity_add = velocity_add and velocity_add:get_Character() and velocity_add:get_Character().SpeedMeterForFall:get_FrameSpeedVector()  * 60 * delta_time
	if velocity_add then
		local speed_multip = (projectile_speeds[nstore.udata] or 1.0)
		local dist_miltip = (nstore.pos - ray_targ_pos):length()
		velocity_add = velocity_add * speed_multip * dist_miltip * smnode.speed * 1.2 --at 2.0 this is frustratingly accurate
	end
	
	local rot_mat = (is_ray_type and lookat_method:call(nil, nstore.pos, ray_targ_pos + (velocity_add or Vector3f.new(0,0,0)), (attach_joint or owner_xform):get_AxisY()):inverse()) 
		or (attach_joint and  (smnode.rot_type_idx < 3 or not_pl_owner) and attach_joint:get_WorldMatrix()) or cam_matrix
	local p_shell_eul = cast_type == 4 and nstore.p_instance_rot and nstore.p_instance_rot:to_euler()
	
	if attach_joint and not is_ray_type and smnode.do_aim_up_down then
		local eul = attach_joint:get_EulerAngle()
		nstore.add_cam_rot = Vector3f.new(-(camera:get_GameObject():get_Transform():get_EulerAngle().x * 1.0), eul.y, eul.z)
		rot_mat = euler_to_quat:call(nil, nstore.add_cam_rot, 0):to_mat4()
	end
	
	nstore.is_in_range = (owner_xform:get_Position() - nstore.pos):length() < sms.maximum_range
	nstore.rot = (p_shell_eul and euler_to_quat:call(nil, p_shell_eul, 0)) or (rot_mat[2] * ((cam_matrix==rot_mat or is_ray_type) and -1 or 1)):to_quat():normalized()
	
	if cast_type == 4 and smnode.rot_type_idx <= 2 then --or cast_type == 3 then --
		nstore.rot = nstore.rot * euler_to_quat:call(nil, Vector3f.new(smnode.attach_euler[1], smnode.attach_euler[2], smnode.attach_euler[3]), 0)
	end
	
	if is_ray_type == 1 then
		nstore.add_cam_rot = nstore.rot:to_euler()
	end
	
	local base = nstore.sparam._ShellParameterBase.ShellBaseParam
	change_shell_udata(base, smnode)
	
	if smnode.summon_idx > 1 and not is_test then
		local spawn_pos = (cast_type == 3 and smnode.rot_type_idx == 3) and ray_targ_pos or nstore.pos
		local corrected = p_shell_eul and Vector3f.new(p_shell_eul.x, p_shell_eul.y, 0)
		local closest_em_pos = (table.concat(smnode.attach_euler):gsub("%.0", "") == "000") and nearest_enemy_fn(is_ray_type and ray_targ_pos or nstore.pos, function(this_dist) return this_dist < 100.0 end, true, owner)
		local lookat_mat = closest_em_pos and spawn_pos ~= closest_em_pos and lookat_method:call(nil, spawn_pos, closest_em_pos, Vector3f.new(0,1,0))
		local eul = lookat_mat and Vector3f.new(0, lookat_mat:inverse():to_quat():to_euler().y + math.pi, 0) or nstore.rot:to_euler()
		local self_owner
		
		if nstore.parent.spell.do_replace_enemy and not nstore.parent.did_replace_em and (not nstore.parent.spell.do_replace_dont_respawn or (enums.chara_id_enum[owner:get_CharaID()]:sub(1,5) == enemy_names[smnode.summon_idx]:match("ch%d%d%d"))) then
			nstore.parent.did_replace_em = true
			spawn_pos = owner_xform:get_Position()
			
			if nstore.parent.spell.do_replace_dont_respawn  then
				self_owner = owner:get_GameObject() --the original is converted to the summon
			else
				owner:get_GameObject():set_DrawSelf(false)
				owner:get_GameObject():set_UpdateSelf(false)
				pre_fns[owner] = function() 
					if not casted_spells[nstore.parent.idx] then
						pre_fns[owner] = nil
						if owner:get_Valid() and nstore.summon_inst then owner:get_GameObject():destroy(owner:get_GameObject()) end --the original is replaced by the summon
					end
				end
			end
		end
		summon(nstore, spawn_pos, euler_to_quat:call(nil, Vector3f.new(smnode.attach_euler[1], smnode.attach_euler[2] + eul.y, smnode.attach_euler[3]), 0), self_owner, owner)
	end

	if smnode.do_teleport_player and (not smnode.enemy_soft_lock or nstore.em_soft_lock_pos ~= nil) then
		owner_xform:set_Position(nstore.pos)
		mot_fns[owner_xform] = function()
			mot_fns[owner_xform] = nil
			owner_xform:set_Position(nstore.pos)
		end
	end
	
	return shell_mgr:call("requestCreateShell(via.GameObject, via.vec3, via.Quaternion, app.ShellRequest.ShellCreateInfo, app.ShellParamData, app.ShellRequest.EventCreateShellSuccess, app.ShellRequest.EventBeforeShellInstantiate)", 
		owner:get_GameObject(), nstore.pos, nstore.rot, nstore.shell_req, nstore.udata, nil, nil)
end

local function cast_spell(skill_tbl_real, i, em_tbl, forced_start_time, skill_storage)
	
	--deep-copy the skill so it can be edited by random other scripts per-instance:
	local skill_tbl = hk.recurse_def_settings({real_skill=skill_tbl_real}, skill_tbl_real)
	
	forced_start_time = forced_start_time or 0
	local is_enemy = not not em_tbl
	local owner = is_enemy and em_tbl.em_chr or player
	temp.last_cast_skills[owner] = skill_tbl
	local target_pos
	local owner_xform = owner:get_Transform()
	local own_mfsm2 = owner:get_ActionManager().Fsm
	local imgui_skillslist = is_enemy and imgui_em_skills[em_tbl.redir_name or em_tbl.name] or imgui_skills
	local imgui_skill = imgui_skillslist[em_tbl and em_tbl.idx or i]
	local imgui_shell_list = imgui_skill and imgui_skill.shell_datas or imgui_skill
	
	local em_target
	local function get_this_ray_result()
		em_target = is_enemy and owner.EnemyCtrl.Ch2 and owner.EnemyCtrl.Ch2:getAttackTarget()
		em_target = em_target and em_target:get_Character()
		local lockon_work = em_target and em_target:get_LockOnTarget():get_work()
		return lockon_work and {em_target, lockon_work.LockOnJoint:get_Position()} or ray_result
	end
	
	local storage = {
		owner = owner,
		skill = skill_tbl,
		em_tbl = em_tbl,
		subbed_stamina = false,
		start = game_time - forced_start_time,
		og_start = game_time - forced_start_time,
		sm_store = is_enemy and (sm_summons[owner] or em_summons[owner]) or nil,
		key = i,
	}
	
	if skill_storage then hk.merge_tables(storage, skill_storage) end
	local smt = {spell = skill_tbl, idx = i}
	setmetatable(storage, smt) --bwd compatibility
	smt.__index = smt
	
	local summon_store = sm_summons[owner] or em_summons[owner]
	if summon_store then
		summon_store.running_skills[i] = storage
	end
	
	local hold_start
	local parsed_smnodes = {}
	for s, smnode in ipairs(skill_tbl.smnodes) do
		smnode.smnode_idx = s
		if smnode.enabled then table.insert(parsed_smnodes, smnode) end
	end
	
	temp_fns[i] = function()
		if (game_time - storage.start > skill_tbl.duration + 0.25) or (skill_tbl.do_hold_button and not hk.check_hotkey("Use Skill "..i, true)) then --slight delay
			temp_fns[i] = nil
			casted_spells[i] = nil
			is_casting = not not next(casted_spells)
		end
	end
	
	local status_ctrl = owner["<StatusConditionCtrl>k__BackingField"]
	local boon_flag = temp_fns[status_ctrl] and 0 or status_ctrl.ActiveStatusConditionFlag
	local boon_time_remain = status_ctrl.NeedUpdateStatusConditionInfoList._items[0] 
	boon_time_remain = boon_time_remain and boon_time_remain["<ActiveRemainTime>k__BackingField"]
	
	casted_spells[i] = {
		
		name = skill_tbl.name,
		
		storage = storage,
		
		fn = function(storage)
			is_casting = (not is_enemy and skill_tbl.do_move_cam and 1) or true
			if not owner:get_Valid() then 
				print("Could not activate skill", skill_tbl.name, "due to deleted owner") 
				casted_spells[i] = nil
				return nil
			end
			
			for s, smnode in ipairs(parsed_smnodes) do
				local nstore = storage[s]
				local stopped_fn = false
				local is_holding = false 
				
				if owner == player then
					local prev_shell = storage[s-1] and parsed_smnodes[s-1] --
					local this_act_name = prev_shell and own_mfsm2:getCurrentNodeName(prev_shell.layer_idx); this_act_name = this_act_name and this_act_name:match(".+%.(.+)")
					local is_prep = prev_shell and prev_shell.do_true_hold and this_act_name and (this_act_name:find("Prepare"))
					local is_hold = prev_shell and prev_shell.do_hold and (is_prep or hk.check_hotkey("Modifier / Inhibit", true))
					local same_node = prev_shell and (prev_shell.action_name == this_act_name or prev_shell.action_name:gsub("Prepare", "Ready") == this_act_name)		
					if is_hold and (same_node or is_prep) and game_time - storage.start >= smnode.start then
						hold_start = hold_start or game_time
						storage.start = storage.og_start + (game_time - hold_start)
					end
					is_holding = is_hold and same_node
				end
				
				if pressed_cancel then
					casted_spells[i] = nil
					is_casting = not not next(casted_spells)
					print("Pressed Cancel", i)
					return nil
				elseif ((is_enemy or not is_holding) and not storage[s] and game_time - storage.start >= smnode.start and not pressed_cancel) then
					
					if not is_enemy then 
						do_inhibit_all_buttons = smnode.do_inhibit_buttons
					end
					hold_start = nil
					storage[s] = {
						idx = s,
						start = game_time, 
						ray = (smnode.freeze_crosshair and storage[s-1] and storage[s-1].ray) or get_this_ray_result(),
						smnode = smnode,
						skill = skill_tbl,
						pstore = storage[s-1], 
						num_living_children = 1,
						children = {},
						parent = storage,
					}

					--hidden old variable names for compatibility w/ older skills custom functions:
					local mt = {shell = smnode, spell = skill_tbl}
					setmetatable(storage[s], mt)
					mt.__index = mt
					
					nstore = nstore or storage[s]
					local prev_store = nstore.pstore
					local ticks_st = ticks
					
					while prev_store and prev_store.smnode.cast_type == 4 and prev_store.smnode.do_carryover_prev do
						prev_store = prev_store.pstore
						nstore.carryover_pstore = prev_store or nstore.carryover_pstore
					end
					
					prev_store = nstore.carryover_pstore or nstore.pstore
					nstore.p_instance_pos = prev_store and (prev_store.instance_pos or prev_store.pos)
					nstore.p_instance_rot = prev_store and (prev_store.instance_rot or prev_store.rot)
					
					if smnode.do_inhibit_buttons and is_enemy then
						local ai = owner:get_AIDecisionMaker()
						
						temp_fns[ai] = function()
							temp_fns[ai] = owner and casted_spells[i] and s == #storage and temp_fns[ai] or nil
							if owner and owner:get_Valid() then 
								ai:set_Enabled(not temp_fns[ai])
							end
						end
					end
					
					if smnode.world_speed ~= 1.0 and not is_enemy then
						sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "set_GlobalSpeed", smnode.world_speed)
						local old_wspeed_fn = temp_fns.fix_world_speed
						
						temp_fns.fix_world_speed = function()
							if not casted_spells[i] or s ~= #storage then
								temp_fns.fix_world_speed = old_wspeed_fn or nil
								sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "set_GlobalSpeed", 1.0)
							else
								sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "set_GlobalSpeed", is_paused and 1.0 or smnode.world_speed) 
							end
						end
					end
					
					if smnode.do_iframes then
						owner["<Hit>k__BackingField"]["<IsInvincible>k__BackingField"] = true
						
						temp_fns.fix_iframes = function()
							if not casted_spells[i] or s ~= #storage then
								temp_fns.fix_iframes = nil
								owner["<Hit>k__BackingField"]["<IsInvincible>k__BackingField"] = false
							end
						end
					end
					
					if smnode.attack_rate_pl ~= 1.0 then
						local hit = owner:get_Hit()
						
						temp_fns[hit] = function()
							temp_fns[hit] = casted_spells[i] and s == #storage and temp_fns[hit] or nil
							if temp_fns[hit] then
								hit["<AttackRate>k__BackingField"] = smnode.attack_rate_pl
							end
						end
					end
					
					local human = owner["<Human>k__BackingField"]
					if smnode.boon_type ~= 1 and human then
						local backup = {}
						local ran_once = false
						local old_fn = late_fns[status_ctrl]
						local do_color = (table.concat(smnode.boon_color) ~= "1.01.01.01.0")
						local use_boon_time = (smnode.boon_time ~= -1.0)
						local wep_holder = owner:get_WeaponAndItemHolder()
						local r_wp_obj = owner_xform:find(enums.wp_enum[human.PrevRightWeapon])
						local l_wp_obj = owner_xform:find(enums.wp_enum[human.PrevLeftWeapon])

						local boon_col, wp_obj2 = Vector4f.new(smnode.boon_color[1], smnode.boon_color[2], smnode.boon_color[3], smnode.boon_color[4])
						local go_name = "effect_"..owner:get_GameObject():get_Name()
						col:call(".ctor(via.vec4)", boon_col)
						for i, child in ipairs(func.get_children(owner_xform)) do 
							if child ~= r_wp_obj and child:get_GameObject():get_Name() == r_wp_obj:get_GameObject():get_Name() then wp_obj2 = child; break end 
						end
						status_ctrl:reqStatusConditionApplyCore(smnode.boon_type==2 and 15 or smnode.boon_type==3 and 16 or 17, nil, nil, false)
						
						late_fns[status_ctrl] = function()
							if not status_ctrl:get_Valid() then late_fns[status_ctrl] = nil; return end
							if (not use_boon_time and (not casted_spells[i] or #storage ~= s)) or (use_boon_time and (game_time - nstore.start > smnode.boon_time)) then
								late_fns[status_ctrl] = old_fn
								status_ctrl:call("reqStatusConditionCure(app.StatusConditionDef.StatusConditionFlag)", smnode.boon_type==2 and 32768 or smnode.boon_type==3 and 65536 or 131072)
								if ((boon_flag | 32768 == boon_flag) or (boon_flag | 65536 == boon_flag) or (boon_flag | 131072 == boon_flag)) then
									status_ctrl:reqStatusConditionApplyCore((boon_flag | 32768 == boon_flag) and 15 or (boon_flag | 65536 == boon_flag) and 16 or 17, nil, nil, false)
									local action_item = status_ctrl.NeedUpdateStatusConditionInfoList._items[0].ActionList._items[0]
									if action_item.ActiveTimer then action_item.ActiveTimer = boon_time_remain end
								end
								for i, tbl in pairs(backup) do
									for v, var in pairs(tbl.def_list) do
										if var then var._Value = tbl[v] end
									end
								end
							else
								if do_color then
									local pl_children = func.get_children(owner_xform) or {}
									for i, child in ipairs(pl_children) do
										if child:get_GameObject():get_Name() == go_name then
											local sparks =  func.getC(child:get_GameObject(), "via.effect.EffectPlayer")
											if sparks and (sparks:get_Resource() or sparks):ToString():find("wp_") then sparks:set_Color(col) end
										end
									end
									for i, wp_obj in pairs({l_wp_obj, r_wp_obj, wp_obj2}) do
										if not sdk.is_managed_object(wp_obj) or not wp_obj:get_Valid() then late_fns[status_ctrl] = old_fn return end
										if not ran_once then
											local mat_list = func.getC(wp_obj:get_GameObject(), "app.MaterialInterpolationEnchant")._DefaultModeData._MaterialList._items[0]
											backup[wp_obj] = {def_list = mat_list and mat_list._VariableF4List._items or {}}
											for v, var in pairs(backup[wp_obj].def_list) do
												if var then backup[wp_obj][v] = var._Value;		var._Value = boon_col * 255 end
											end
										end
										local mesh = func.getC(wp_obj:get_GameObject(), "via.render.Mesh")
										if mesh then
											change_material_float4(mesh, boon_col, "Enchant_Color1")
											change_material_float4(mesh, boon_col, "Enchant_Color2")
										end
										local children = func.get_children(wp_obj) or {}
										local efx_obj, base_amt = owner_xform:find("effect_"..wp_obj:get_GameObject():get_Name()), 0
										if efx_obj then 
											local efx_obj2
											for i, child in ipairs(pl_children) do 
												if child ~= efx_obj and child:get_GameObject():get_Name() == efx_obj:get_GameObject():get_Name() then efx_obj2 = child; break end 
											end
											if efx_obj2 then table.insert(children, 1, efx_obj2) end
											table.insert(children, 1, efx_obj) 
											base_amt = 1 + (efx_obj2 and 1 or 0)
										end
										for i, child in ipairs(children) do
											local efx_player = func.getC(child:get_GameObject(), "via.effect.EffectPlayer")
											if i <= base_amt and owner["<SheatheDrawController>k__BackingField"]["<IsDraw>k__BackingField"] then efx_player:set_Color(col) end
											for i, param_name in ipairs({"ParticleColor", "BaseColor", "FireColor", "LightningColor"}) do
												local extern = efx_player and efx_player:getExternParameter(param_name); if extern then extern:set_Color(col) end
											end
										end
									end
								end
								ran_once = true
							end
						end
					end

					if smnode.camera_dist ~= -1 and not is_enemy then
						local pl_cam_settings, dist_name = get_cam_dist_info()
						if pl_cam_settings then
							local timer_start
							
							temp_fns.fix_cam_dist = function(finish)
								old_cam_dist = old_cam_dist or (sms.do_force_cam_dist and 5.5 or pl_cam_settings[dist_name])
								timer_start = timer_start or (not casted_spells[i] or (s ~= #storage)) and game_time
								damp_float02._Source, damp_float02._Target = damp_float02._Current, timer_start and old_cam_dist or smnode.camera_dist
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
						
					if smnode.anim_speed ~= 1.0 then
						local old_speed_fn = temp_fns[owner.WorkRate]
						local wr = owner.WorkRate
						
						temp_fns[wr] = function()
							temp_fns[wr] = casted_spells[i] and s == #storage and temp_fns[wr] or nil
							if not owner:get_Valid() then return end
							owner.WorkRate.NextRateValue = smnode.anim_speed
							owner.WorkRate.NextApplyRate = smnode.anim_speed
							temp_fns[wr] = temp_fns[wr] or old_speed_fn
						end
					end
					
					if smnode.enemy_behavior_type > 1 and is_enemy and storage.sm_store then
						local udata = sdk.create_userdata("app.ActInterPackData", "AppSystem\\ai\\actioninterface\\actinterpackdata\\"..enemy_behaviors[enemy_behaviors_imgui.categories[smnode.enemy_behavior_category] ][smnode.enemy_behavior_type-1])
						storage.sm_store.summon_behavior = udata
					end
					
					if smnode.summon_idx > 1 and smnode.summon_behavior_type > 1 then
						local udata = sdk.create_userdata("app.ActInterPackData", "AppSystem\\ai\\actioninterface\\actinterpackdata\\"..enemy_behaviors[enemy_behaviors_imgui.categories[smnode.summon_behavior_category] ][smnode.summon_behavior_type-1])
						nstore.summon_behavior = udata
					end
					
					if smnode.turn_idx > 1 then
						local turn_ctrl = owner:get_TurnController()
						
						turn_fns[turn_ctrl] = function()
							turn_fns[turn_ctrl] = (smnode.do_turn_constantly and is_casting and casted_spells[i] and (s == #storage or (parsed_smnodes[#storage] and parsed_smnodes[#storage].do_turn_constantly))) and turn_fns[turn_ctrl] or nil
							local cam_yaw = camera:get_GameObject():get_Transform():get_EulerAngle().y + math.pi
							local input_yaw = cam_yaw + (real_rad_l or owner:get_Input():get_AngleRadL())
							if  smnode.turn_idx == 4 then
								if is_enemy then 
									local target = owner.EnemyCtrl.Ch2 and (owner.EnemyCtrl.Ch2._TargetController and owner.EnemyCtrl.Ch2._TargetController._AITarget or owner.EnemyCtrl.Ch2:getAttackTarget())
									target = (target and target:get_Character()) or em_target
									if target and target:get_LockOnTarget() then
										local lockon_work = target:get_LockOnTarget():get_work()
										nstore.pl_soft_lock_pos, nstore.pl_soft_lock_enemy = lockon_work and lockon_work.LockOnJoint:get_Position() or target:get_Transform():get_Position(), target
									end
									nstore.pl_soft_lock_pos = (storage.sm_store and storage.sm_store.command_coords) or nstore.pl_soft_lock_pos
								else
									nstore.pl_soft_lock_pos, nstore.pl_soft_lock_enemy = nearest_enemy_fn((owner.Hip or owner_xform):get_Position() + rotate_yaw_method:call(nil, cam_matrix[2] * 3.0, owner:get_Input():get_AngleRadL() + math.pi), function(this_dist)
										return this_dist < (active_states.Airborne and 10.0 or 5.0)
									end, nil, owner)
								end
							end
							if nstore.pl_soft_lock_pos then
								local pl_lock_yaw = lookat_method:call(nil, owner_xform:get_Position(), nstore.pl_soft_lock_pos, Vector3f.new(0,1,0)):inverse():to_quat():to_euler().y + math.pi
								if is_enemy or math.abs(pl_lock_yaw - input_yaw) < 2.0 then 
									input_yaw = pl_lock_yaw
								end
							end
							local target_yaw = (smnode.turn_idx == 3 and cam_yaw) or input_yaw
							local target_yaw_deg = target_yaw  * 57.2958
							
							if smnode.turn_idx == 3 or input_yaw ~= cam_yaw or (is_enemy and nstore.pl_soft_lock_pos) then
								owner:setVariableTurnAngleDeg(target_yaw_deg)
								owner:set_TargetFrontAngleDeg(target_yaw_deg)
								owner:set_TargetMoveAngleDeg(target_yaw_deg)
								local t_ang_ctrl = owner["<TargetAngleCtrl>k__BackingField"]
								
								late_fns[turn_ctrl] = function()
									late_fns[turn_ctrl] = game_time - nstore.start < 0.2 and late_fns[turn_ctrl] or nil
									local eul = owner_xform:get_EulerAngle()
									local new_quat = euler_to_quat:call(nil, Vector3f.new(eul.x, target_yaw, eul.z), 0)
									t_ang_ctrl.Move["<AngleDeg>k__BackingField"] = target_yaw_deg
									t_ang_ctrl.Front["<AngleDeg>k__BackingField"] = target_yaw_deg
									owner_xform:set_Rotation(owner_xform:get_Rotation():slerp(new_quat, 0.5 * smnode.turn_speed)) 
								end
								late_fns[turn_ctrl]()
							end
						end
						turn_fns[turn_ctrl]()
					end
					
					local node, actions
					if smnode.action_idx > 1 then
						local tree = own_mfsm2:getLayer(0):get_tree_object()
						node = tree and tree:get_node_by_name(smnode.action_name)
						
						if not node then 
							tree = own_mfsm2:getLayerCount() > 1 and own_mfsm2:getLayer(1):get_tree_object() --UpperBody
							node = tree and tree:get_node_by_name(smnode.action_name)
							
							if node then
								nstore.layer_idx = 1
								
								temp_fns.set_strafe = smnode.do_hold and function()
									if game_time - nstore.start > 0.1 then temp_fns.set_strafe = nil end
									interper:set_InterpolationFrame(12.0)
									set_node_method:call(own_mfsm2:getLayer(0), "Locomotion.Strafe", setn, interper)
								end or nil
								
								local concat = table.concat(smnode.hold_color)
								if concat ~= "1.01.01.01.0" and concat ~= "1111" and (node:get_name():find("Prepare") or node:get_name():find("Ready")) then
									temp_fns.hold_effect_color_fn = function()
										temp_fns.hold_effect_color_fn = is_casting and temp_fns.hold_effect_color_fn or nil
										local node2 = tree:get_node_by_name(own_mfsm2:getCurrentNodeName(1):match(".+%.(.+)"))
										local actions2 = node2:get_actions(); if not actions2[1] then actions2 = node2:get_unloaded_actions() end
										local action2 = actions2[5] and actions2[5].EffectElementID and actions2[5] or actions2[2]
										
										if action2 and action2.Effect and action2.Effect.CreatedEffects._entries[0].value then
											if node2:get_name():find("Ready") then temp_fns.hold_effect_color_fn = nil end
											local effect = action2.Effect.CreatedEffects._entries[0].value._items[0]
											col:call(".ctor(via.vec4)", Vector4f.new(smnode.hold_color[1], smnode.hold_color[2], smnode.hold_color[3], smnode.hold_color[4]))
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
							nstore.layer_idx = 0
						end
						
						if smnode.action_name:lower() == "reset" then 
							local act_mgr = owner:get_ActionManager()
							act_mgr.Fsm:restartTree(); act_mgr.Fsm:resetTree()
							act_mgr:endAction(0); act_mgr:endAction(1) 
							if owner.EnemyCtrl.Ch2 then owner.EnemyCtrl.Ch2:get_ActInter():get_Executor():forceEndActionForState() end
							act_mgr:requestActionCore(0, "NormalLocomotion", 0)
						end
						
						if node then
							nstore.is_unloaded = not not node:get_actions()[1]
							actions = node.is_unloaded and node:get_unloaded_actions() or node:get_actions()
							nstore.actions = actions
							
							if smnode.do_simplify_action and nstore.layer_idx == 0 then
								for a, action in ipairs(actions) do action:set_Enabled(a==1) end
							end
							
							storage.last_node_name = node:get_full_name()
							local layer = nstore.layer_idx==0 and owner.FullBodyLayer or owner.UpperBodyLayer
							
							temp_fns[node] = function()
								local nname = own_mfsm2:get_Valid() and own_mfsm2:getCurrentNodeName(add_layer_idx or nstore.layer_idx)
								temp_fns[node] = nname and temp_fns[node] or nil
								
								if nname and game_time - nstore.start > 0.1 and nname:match(".+%.(.+)") ~= node:get_name() then
									temp_fns[node] = nil
									for a, action in ipairs(actions or {}) do action:set_Enabled(true) end
									local is_current_node = s == #storage
									local is_damaged = nname:find("Damage") and not storage.last_node_name:find("Damage")
									layer:set_MirrorSymmetry(false)
									local hold_interrupted = not is_enemy and (nstore.layer_idx == 1 and is_current_node and (not smnode.do_hold or (nname:gsub("Ready", "Prepare"):match(".+%.(.+)") ~= node:get_name() and not nname:find("Shoot"))))
									
									if is_damaged or pressed_cancel or hold_interrupted then
										casted_spells = {} --cancel skills due to interruption
										print("Cancelled Skill ", i, skill_tbl.name, is_damaged, pressed_cancel, hold_interrupted)
										is_casting = false
										if own_mfsm2:getCurrentNodeName(0) == "Locomotion.Strafe" then
											owner:get_ActionManager():requestActionCore(0, "NormalLocomotion", 0)
										end
									end
								end
							end
						end
					end
					
					local splitted_cmotion = smnode.custom_motion ~= "" and split(smnode.custom_motion, ",", true)
					if splitted_cmotion then
						local layer = splitted_cmotion[4] == 1 and owner.UpperBodyLayer or owner.FullBodyLayer
						if tonumber(splitted_cmotion[1]) then
							mot_fns.change_frame = function()
								if ticks - ticks_st == 1 then
									mot_fns.change_frame = nil
									local mnode = layer:get_HighestWeightMotionNode()
									if mnode then
										layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
											mnode:get_MotionBankID(), mnode:get_MotionID(), tonumber(splitted_cmotion[1]) or layer:get_Frame(), tonumber(splitted_cmotion[3]) or 20.0, 2, 0)
									end
								end
							end
						elseif #splitted_cmotion >= 3 then
							if splitted_cmotion[1]:find("motlist") then
								add_dynamic_motionbank(owner:get_Motion(), splitted_cmotion[1], tonumber(splitted_cmotion[2]))
							end
							if actions then actions[1]:set_Enabled(false) end
							
							temp_fns.change_motion = function()
								temp_fns.change_motion = nil
								layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
									tonumber(splitted_cmotion[2]), tonumber(splitted_cmotion[3]), tonumber(splitted_cmotion[5]) or 0.0, tonumber(splitted_cmotion[6]) or 20.0, 2, 0)
							end
						end
					end
					
					if table.concat(smnode.action_vfx_color) ~= "1.01.01.01.0" then
						local old_vfx, vfx_name = {}, "effect_"..owner:get_GameObject():get_Name()
						for i, child in pairs(func.get_children(owner_xform)) do
							old_vfx[child] = (child:get_GameObject():get_Name() == vfx_name)
						end
						
						pre_fns[old_vfx] = function()
							pre_fns[old_vfx] = owner_xform:get_Valid() and game_time - nstore.start < smnode.action_vfx_color_time and pre_fns[old_vfx] or nil
							if pre_fns[old_vfx] then
								col:call(".ctor(via.vec4)", Vector4f.new(smnode.action_vfx_color[1], smnode.action_vfx_color[2], smnode.action_vfx_color[3], smnode.action_vfx_color[4]))
								for i, child in pairs(func.get_children(owner_xform)) do
									if not old_vfx[child] and child:get_GameObject():get_Name() == vfx_name then
										old_vfx[child] = true
										func.getC(child:get_GameObject(), "via.effect.EffectPlayer"):set_Color(col)
									end
								end
							end
						end
					end
					
					local l_prop_a = owner_xform:getJointByName("L_PropA")
					if (smnode.do_mirror_action or smnode.do_mirror_wp) and l_prop_a then
						local paired_fn = temp_fns[node or 0]
						local mirror_st = smnode.mirror_time > -1 and game_time
						local layer = nstore.layer_idx==1 and owner.UpperBodyLayer or owner.FullBodyLayer
						
						mot_fns.mirror_fn = function()
							local should_run = not mirror_st and casted_spells[i] and (temp_fns[node or 0]==paired_fn or s == #storage) or mirror_st and (game_time - mirror_st < smnode.mirror_time) 
							mot_fns.mirror_fn = should_run and mot_fns.mirror_fn or nil
							
							if mot_fns.mirror_fn and smnode.do_mirror_wp then
								local l_wp_a, l_wp_b = l_prop_a, owner_xform:getJointByName("L_PropB")
								local r_wp_a, r_wp_b = owner_xform:getJointByName("R_PropA"), owner_xform:getJointByName("R_PropB")
								local l_wp_a_pos, l_wp_a_rot = l_wp_a:get_Position(), l_wp_a:get_Rotation()
								local l_wp_b_pos, l_wp_b_rot = l_wp_b:get_Position(), l_wp_b:get_Rotation()
								l_wp_a:set_Position(r_wp_a:get_Position()); l_wp_a:set_Rotation(r_wp_a:get_Rotation())
								r_wp_a:set_Position(l_wp_a_pos); r_wp_a:set_Rotation(l_wp_a_rot)
								l_wp_b:set_Position(r_wp_b:get_Position()); l_wp_b:set_Rotation(r_wp_b:get_Rotation())
								r_wp_b:set_Position(l_wp_b_pos); r_wp_b:set_Rotation(l_wp_b_rot)
							elseif not mot_fns.mirror_fn then 
								layer:call("set_InterpolationCountDownFrame(System.Single)", 60.0)
							end
							layer:set_MirrorSymmetry(smnode.do_mirror_action and not not mot_fns.mirror_fn)
						end
					end
					
					if smnode.udata_idx > 1 and casted_spells[i] then
						local stam_mgr = owner:get_StaminaManager()
						if not storage.subbed_stamina and stam_mgr and not is_enemy then
							storage.subbed_stamina = true
							stam_mgr["<RemainingAmount>k__BackingField"] = stam_mgr["<RemainingAmount>k__BackingField"] - skill_tbl.stam_cost
						end
						nstore.req_id = cast_shell(smnode, nstore, owner) --fire the shell
					end
					
					--setup custom_fn vars
					local fn_env, lua_fn
					local cust_fn_text = smnode.custom_fn
					local imgui_shell = imgui_shell_list and imgui_shell_list[func.find_key(skill_tbl.smnodes, smnode)] or {enabled=true, opened=false, last_data={}}
					
					if cust_fn_text ~= "" then 
						local em_name = is_enemy and (storage.em_tbl.redir_name or storage.em_tbl.name)
						
						fn_env = {
							Node = nstore, 
							Skill = storage, 
							Owner = owner, 
							ReachedEnemy = function(dist, xform) 
								local pos = nstore.pl_soft_lock_pos or nstore.em_soft_lock_pos or (is_enemy and nstore.parent.sm_store and nstore.parent.sm_store.current_target and scene:fromUniversalPosition(nstore.parent.sm_store.current_target:get_Position()))
								return pos and ((pos - (xform or owner_xform):get_Position()):length() <= (dist or 1.33)) 
							end,
							Hold = function() 
								if s == #storage then storage.start = storage.start + skill_delta_time end 
							end,
							RepeatNode = function() 
								storage[s], pre_fns[nstore] = nil 
								storage.start = storage.start + skill_delta_time
							end,
							Stop = function() stopped_fn = true end,
							Exec = function(skill_name, from_summon, allow_multiple) 
								local summon_name = from_summon and nstore.summon_em_tbl and nstore.summon_em_tbl.name
								local em_skill_idx = (is_enemy or summon_name) and func.find_key(sms.last_sel_em_spells[summon_name or em_name], skill_name)
								local skill_idx = em_skill_idx or func.find_key(sms.last_sel_spells, skill_name)
								if skill_idx then 
									if summon_name then
										local key = nstore.summon_inst:get_address()..(skill_name~="" and skill_name or skill_idx)
										enemy_casts[nstore.summon_inst:get_ActionManager()] = {sp_tbl=em_skill_idx and sms.enemyskills[summon_name].skills[em_skill_idx] or sms.skills[skill_idx], 
											em_chr=nstore.summon_inst, name=nstore.summon_em_tbl.name, idx=skill_idx, key=ActiveSkills[key] and allow_multiple and key..GameTime or key}
									elseif is_enemy then
										local key = owner:get_address()..(skill_name~="" and skill_name or skill_idx)
										enemy_casts[owner:get_ActionManager()] = {sp_tbl=em_skill_idx and sms.enemyskills[em_name].skills[em_skill_idx] or sms.skills[skill_idx],
											em_chr=owner, name=em_tbl.name, redir_name=em_tbl.redir_name, idx=skill_idx, key=ActiveSkills[key] and allow_multiple and key..GameTime or key}
									else
										forced_skill = {skill_idx, 0.0} 
									end
								end
							end,
							Kill = function(skill_name) 
								if skill_name then
									if active_skills[skill_name] then casted_spells[active_skills[skill_name].storage.key] = nil end
								else
									casted_spells[i] = nil 
								end
							end,
						}
						cust_fn_text = cust_fn_text:gsub("RunLuaFile%(['\"].-['\"]%)", function(found_call)
							local path = found_call:match("RunLuaFile%(['\"](.-)['\"]%)")
							local file = io.input("SkillMaker\\CustomFn\\"..path:lower():gsub("%.lua", "")..".lua")
							local file_text = file:read("*a")
							file:close()
							return file_text
						end)
						if cust_fn_text:find("Callbacks") then --declares local variable copies of fn_env globals so they can be used in 'Callbacks' later without being nil
							local local_txt = ""; for key, value in pairs(fn_env) do local_txt = local_txt .. key..", " end
							local_txt = "local "..local_txt.."Summon = "..local_txt.."Summon\n"
							cust_fn_text = local_txt..cust_fn_text
						end
						nstore.cust_fn_text = {"\n"..cust_fn_text}
						local fn, failed = load(cust_fn_text, nil, "t", _G)
						lua_fn = not failed and fn
						if imgui_shell then imgui_shell.error_txt = failed and {failed, os.clock()} or imgui_shell.error_txt end
					end
					
					local req_tracks
					local hit = owner:get_Hit()
					dmg_tbl[hit] = nstore
					if imgui_shell_list then imgui_shell_list[s] = imgui_shell end --FIXME
					local died, did_velocity, had_fn = false, false
					
					-- manage every frame:
					pre_fns[nstore] = function(given_nstore) 
						nstore = given_nstore or nstore
						died = nstore.num_living_children == 0 and (died and 1 or true) or false
						if died == 1 and not casted_spells[i] then pre_fns[nstore] = nil end --kill after 2 frames of no children
						nstore.num_living_children = 0
						nstore.final_instance = nstore.children[#nstore.children] or (nstore.instance and nstore.instance["<Shell>k__BackingField"]) --we only want the position of the final child smnode
						nstore.finished = not pre_fns[nstore] or nil
						local prev_store = (nstore.carryover_pstore or nstore.pstore)
						
						if nstore.final_instance and nstore.final_instance.get_Valid and nstore.final_instance:get_Valid() then
							local xform = nstore.final_instance:get_GameObject():get_Transform()
							nstore.instance_pos = xform:get_Position()
							nstore.instance_rot = xform:get_Rotation()
							nstore.hit_substance = nstore.final_instance.HitSubstance or nstore.final_instance["<TerrainHitResult>k__BackingField"]
						end
						
						nstore.instance_pos = nstore.summon_pos or nstore.instance_pos --sm_summons just override shells
						nstore.p_instance_pos = prev_store and prev_store.instance_pos
						nstore.p_instance_rot = prev_store and prev_store.instance_rot
						req_tracks = req_tracks or get_req_tracks(owner)
						nstore.last_hitbox = req_tracks and (req_tracks.ReqId1 >= 0 or req_tracks.ReqId2 >= 0 or req_tracks.ReqId3 >= 0 or req_tracks.ReqId4 >= 0 or req_tracks.ReqId5 >= 0 
							or req_tracks.ReqId6 >= 0 or req_tracks.ReqId7 >= 0 or req_tracks.ReqId8 >= 0 or req_tracks.ReqId9 >= 0) and game_time or nstore.last_hitbox
						
						if s == #storage and smnode.pl_velocity_type > 1 then
							local pl_pos = owner_xform:get_Position()
							local shell_pos = nstore.pos or nstore.p_instance_pos
							local em_pos = nstore.pl_soft_lock_pos
							
							if smnode.pl_velocity_type ~= 7 or (em_pos and (em_pos - pl_pos):length() > 1.33) then
								local cam_eul = smnode.pl_velocity_type == 6 and camera:get_GameObject():get_Transform():get_EulerAngle()
								local input_rot = cam_eul and euler_to_quat:call(nil, Vector3f.new(cam_eul.x, cam_eul.y + math.pi + (real_rad_l or owner:get_Input():get_AngleRadL()), cam_eul.z), 0)
								local base_rot = input_rot or ((smnode.pl_velocity_type == 2) and owner_xform:get_Rotation()) or (smnode.pl_velocity_type == 5 and (cam_matrix[2] * -1):to_quat())
									or (lookat_method:call(nil, pl_pos, (smnode.pl_velocity_type == 4 and shell_pos ~= pl_pos and shell_pos) or em_pos or nstore.ray[2], Vector3f.new(0,1,0))[2] * -1):to_quat():conjugate()
								
								if smnode.do_constant_speed then
									local mat = base_rot:to_mat4()
									owner_xform:set_Position(owner_xform:get_Position() + ((mat[2] * smnode.pl_velocity[3]) + (mat[1] * smnode.pl_velocity[2]) + (mat[0] * smnode.pl_velocity[1])) * skill_delta_time * timescale_mult)
								elseif not did_velocity then
									did_velocity = true
									reset_fall_height(0.5)
									owner:get_FreeFallCtrl():call("startWithFrame(via.vec3, System.Single)", transform_method:call(nil, Vector3f.new(smnode.pl_velocity[1], smnode.pl_velocity[2], smnode.pl_velocity[3]), base_rot), -9.8) 
									--owner:onRootApply( Vector3f.new(smnode.pl_velocity[1], smnode.pl_velocity[2], smnode.pl_velocity[3]), base_rot)
								end
							end
						end
						
						if lua_fn and not stopped_fn then
							local nname, nname2 = own_mfsm2:getCurrentNodeName(0) or "", own_mfsm2:getCurrentNodeName(1) or ""
							fn_env.Shell = (nstore.final_instance and sdk.is_managed_object(nstore.final_instance) and nstore.final_instance:get_Valid()) and nstore.final_instance or nil
							fn_env.Summon = nstore.summon_inst and sdk.is_managed_object(nstore.summon_inst) and nstore.summon_inst:get_Valid() and nstore.summon_inst
							fn_env.ActName = nname:match(".+%.(.+)") or nname
							fn_env.ActName2 = nname2 and nname2:match(".+%.(.+)") or nname2
							fn_env.SkillThisFrame = temp.last_cast_skills[owner]
							fn_env.Crosshair = ray_result
							local t_ctrl = is_enemy and owner.EnemyCtrl and owner.EnemyCtrl.Ch2 and owner.EnemyCtrl.Ch2._TargetController
							fn_env.Target = nstore.current_target or t_ctrl and t_ctrl:getTarget(t_ctrl._TargetType)
							
							hk.merge_tables(_G, fn_env)
							local success, result
							if lua_fn then 
								success, result = pcall(lua_fn) 
							end
							imgui_shell.error_txt = not success and {result, os.clock()} or imgui_shell.error_txt
							for key, value in pairs(fn_env) do _G[key] = nil end
						end
					end
					nstore.manager_fn = pre_fns[nstore]
					pre_fns[nstore]()
					
					if actions then --Action is executed after custom function has a chance to run once
						owner:get_ActionManager():requestActionCore(0, smnode.action_name, nstore.layer_idx)
					end
					
				elseif nstore and nstore.req_id and not nstore.instance then --manage the current smnode
					local dict = shell_mgr["<InstantiatedShellDict>k__BackingField"]
					nstore.instance = nstore.req_id and dict:ContainsKey(nstore.req_id) and dict[nstore.req_id] --
					
					local imgui_shell = imgui_skills[i] and imgui_skills[i].shell_datas[s]
					if imgui_shell then 
						imgui_shell.last_store = nstore
					end
					local counter = 0
					
					local found_shell_inst = nstore.instance and nstore.instance["<Shell>k__BackingField"]
					if found_shell_inst then
						
						local function make_temp_fn(shell_inst, is_child)
							counter = counter + 1
							local gameobj = shell_inst:get_GameObject()
							gameobj:set_Name(skill_tbl.name .. "_" .. counter)
							local work_rate = func.getC(gameobj, "app.WorkRate")
							local xform = gameobj:get_Transform()
							local summon_joint = nstore.pstore and nstore.pstore.summon_inst and nstore.pstore.summon_inst:get_Transform():getJointByName(smnode.joint_name)
							local pl_joint = summon_joint or owner_xform:getJointByName(smnode.joint_name)
							local rot_euler = nstore.rot:to_euler()
							local add_param_ids = {}
							nstore.add_param_ids = add_param_ids
							
							
							--Find child shells
							for a, aparam in pairs(nstore.sparam._ShellAdditionalParameter._items) do
								table.insert(add_param_ids, aparam._ShellParamIDHash)
								local arr = aparam._ShellGeneratorConditionInfos or aparam._ShellGeneratorTimerInfos or aparam._GenerationDatas
								arr = arr and (arr._items or arr)
								
								for e, element in pairs(arr or {}) do
									local hash_obj = (element._ShellParamIDHash or aparam._ShellParamIDHash)
									local hash = element._ShellIDHash or ((hash_obj and hash_obj._HasValue and hash_obj._Value)  or nil) or nil
									table.insert(add_param_ids, hash)
									local aparam_idx = func.find_key(nstore.udata.ShellParams._items, hash, "_ShellParamIdHash")
									if aparam_idx then 
										local aparam2 = nstore.udata.ShellParams._items[aparam_idx]
										local base = aparam2._ShellParameterBase.ShellBaseParam
										change_shell_udata(base, smnode)
									end
								end
							end
							
							local efx2 = shell_inst["<EffectManager2>k__BackingField"]
							local use_omen = efx2 and shell_inst:get_ShellParameter().ShellBaseParam.UseOmenPhase
							temp.omen_reqs[shell_inst] = use_omen and nstore or nil
							
							if efx2 and not use_omen then 
								change_efx2_color(efx2, nstore) --color now if no omen, otherwise color in omen hook
							end
							
							if not smnode.do_sfx then 
								local go, wwise = gameobj, shell_inst["<WwiseContainer>k__BackingField"]
								for i, entry in pairs(wwise and func.lua_get_array(wwise._TriggerInfoList._items, true) or {}) do
									if entry then wwise:stopTriggered(entry._TriggerId, go, 0.0) end
								end
								shell_inst["<WwiseContainer>k__BackingField"]:call(".cctor()") 
								shell_inst["<WwiseContainer>k__BackingField"]:call(".ctor()") 
							end
							
							if smnode.is_decorative then
								shell_inst["<ColliderStep>k__BackingField"] = 99999
								shell_inst:get_HitCtrl():get_CachedRequestSetCollider():set_Enabled(false)
							end
							
							--if smnode.enchant_type > 1 then 
							--	shell_inst["<EnchantElementType>k__BackingField"] = smnode.enchant_type - 2
							--end
							
							if smnode.dmg_type_shell > 1 then 
								local hit = shell_inst:get_HitCtrl()
								dmg_tbl[hit], prev_tbl = nstore, dmg_tbl[hit]
								dmg_tbl[hit].last_hit = prev_tbl and prev_tbl.last_hit
							end
							
							local attached_only_once = false
							local cant_search_children = false
							local shell_pos
							
							--manage the current shell's speed and damage every frame
							temp_fns[shell_inst] = function() 
								if not shell_inst:get_Valid() or (game_time - storage.start > sms.shell_lifetime_limit) or (storage.did_replace_em and (not owner:get_Valid() or owner:get_Hp() <= 0))
								or (smnode.do_abs_lifetime and game_time - nstore.start > smnode.lifetime) or (smnode.lifetime == -2.0 and (#storage > s+1)) then
									temp_fns[shell_inst] = nil
								end
								nstore.num_living_children = nstore.num_living_children + 1
								
								if temp_fns[shell_inst] and xform:get_Valid()  then
									active_shells[shell_inst] = nstore
									cant_search_children = cant_search_children or (casted_spells[i] == nil) or (s ~= #storage and storage[s+1])
									shell_inst["<HitCtrl>k__BackingField"]["<AttackRate>k__BackingField"] = nstore.is_in_range and (smnode.attack_rate * skill_tbl.damage_multiplier) or 0 
									work_rate.NextRateValue = smnode.speed
									work_rate.NextApplyRate = smnode.speed
									
									if not nstore.children[1] then
										for i, child in pairs(func.get_children(xform:get_Children()) or {}) do
											local child_shell = getC(child:get_GameObject(), "app.Shell")
											if not temp_fns[child_shell] and child_shell["<RequestId>k__BackingField"] > nstore.req_id and (s == #storage or (storage[s+1] and storage[s+1].cast_type ~= 4)) then 
												table.insert(nstore.children, child_shell)
												make_temp_fn(child_shell, true)
												temp_fns[child_shell]()
											end
										end
									end
									
									if not projectile_speeds[nstore.udata] and game_time - nstore.start > 0.1 then
										local last_pos = shell_pos
										shell_pos = xform:get_Position()
										projectile_speeds[nstore.udata] = last_pos and ((last_pos - shell_pos):length() * (1 / smnode.speed))
									end
									
									if not is_child or smnode.pshell_attach_type > 3 then
										if pl_joint and pl_joint:get_Valid() and not attached_only_once and (smnode.cast_type == 3 or (smnode.cast_type == 4 and summon_joint)) then
											attached_only_once = not smnode.attach_to_joint --or (smnode.rot_type_idx == 3)
											smnode.attach_pos = smnode.attach_pos or {0,0,0}
											local rotated_offset = transform_method:call(nil, Vector3f.new(smnode.attach_pos[1], smnode.attach_pos[2], smnode.attach_pos[3]), smnode.rot_type_idx == 1 and pl_joint:get_Rotation() or owner_xform:get_Rotation())
											xform:set_Position(pl_joint:get_Position() + rotated_offset)
											if not smnode.do_no_attach_rotate then
												if nstore.add_cam_rot then 
													xform:set_EulerAngle(nstore.add_cam_rot + Vector3f.new(smnode.attach_euler[1], smnode.attach_euler[2], smnode.attach_euler[3])) -- 
												elseif smnode.rot_type_idx == 3 then
													xform:set_EulerAngle(rot_euler + Vector3f.new(smnode.attach_euler[1], smnode.attach_euler[2], smnode.attach_euler[3])) -- 
												elseif smnode.rot_type_idx == 2 then
													local pl_eul = owner_xform:get_EulerAngle() 
													xform:set_EulerAngle(Vector3f.new(smnode.attach_euler[1] + pl_eul.x, smnode.attach_euler[2] + pl_eul.y, smnode.attach_euler[3] + pl_eul.z))
												elseif smnode.rot_type_idx == 1 then
													xform:set_EulerAngle(pl_joint:get_EulerAngle() + Vector3f.new(smnode.attach_euler[1], smnode.attach_euler[2], smnode.attach_euler[3])) -- 
												end
											end
										elseif smnode.cast_type == 4 and nstore.p_instance_pos then
											if not attached_only_once then
												local eul = nstore.p_instance_rot:to_euler()
												xform:set_Position(nstore.p_instance_pos + transform_method:call(nil, Vector3f.new(smnode.attach_pos[1], smnode.attach_pos[2], smnode.attach_pos[3]), nstore.p_instance_rot))
												local new_eul = Vector3f.new(eul.x, eul.y, 0) + Vector3f.new(smnode.attach_euler[1], smnode.attach_euler[2], smnode.attach_euler[3])
												xform:set_EulerAngle(new_eul)
												shell_inst["<MoveVector>k__BackingField"] = Vector3f.new(math.cos(new_eul.x) * math.sin(new_eul.y), -math.sin(new_eul.x), math.cos(new_eul.x) * math.cos(new_eul.y))
											end
											attached_only_once = (smnode.pshell_attach_type == 1) or ((smnode.pshell_attach_type == 3 or smnode.pshell_attach_type == 5) and (nstore.carryover_pstore or nstore.pstore).hit_substance)
										end
									end
									
									if not cant_search_children then
										local slist_copy = func.lua_get_array(shell_mgr.ShellList._items)
										slist_copy2 = hk.merge_tables({}, slist_copy)
										
										for p, param_hash in pairs(add_param_ids) do
											local idx = func.find_key(slist_copy, param_hash, "<ShellParamId>k__BackingField")
											while idx do
												local child_shell = slist_copy[idx]
												slist_copy[idx] = nil
												idx = func.find_key(slist_copy, param_hash, "<ShellParamId>k__BackingField")
												
												if not temp_fns[child_shell] and child_shell["<RequestId>k__BackingField"] > nstore.req_id and (s == #storage or (storage[s+1] and storage[s+1].cast_type ~= 4)) then 
													table.insert(nstore.children, child_shell)
													make_temp_fn(child_shell, true)
													temp_fns[child_shell]()
												end
											end
										end
									end
								elseif shell_inst:get_Valid() then
									gameobj:destroy(gameobj)
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

local function test_animactions_ready(states_tbl, body_word, upperbody_word, body_frame, upperbody_frame)
	for k, keyword in ipairs(split(states_tbl, ",", true)) do
		local kw = keyword:gsub("`", "")
		local kw_only = kw:match("(.*)%(")
		local search_kw = kw_only or kw
		local state_ready = body_word:find(search_kw) or upperbody_word:find(search_kw)
		if state_ready and kw_only then
			state_ready = false
			local frames_body = kw:match("%((.+)%)")
			if frames_body then
				local frames = split(frames_body, " ", true)
				state_ready = body_frame > tonumber(frames[1]) and body_frame < tonumber(frames[2])
			else
				local frames_upper = kw:match("%[(.+)%]") 
				if frames_upper then
					local frames = split(frames_upper, " ", true)
					state_ready = upperbody_frame > tonumber(frames[1]) and upperbody_frame < tonumber(frames[2])
				end
			end
		end
		if state_ready then return true end
	end
end

re.on_script_reset(function()
	cleanup(true, true)
	if player then reset_character(true) end
	game_time, ticks, player, is_paused = 99999999999, 99999999999, nil, false --this will trigger most delayed functions to clean up
	for i, fn in pairs(hk.merge_tables({}, mot_fns)) do pcall(fn) end
	for i, fn in pairs(hk.merge_tables({}, pre_fns)) do pcall(fn) end
	for i, fn in pairs(hk.merge_tables({}, temp_fns)) do pcall(fn) end
	for i, fn in pairs(hk.merge_tables({}, late_fns)) do pcall(fn) end
end)

re.on_pre_application_entry("UpdateBehavior", function() 

	timescale_mult = 1 / sdk.call_native_func(sdk.get_native_singleton("via.Application"), sdk.find_type_definition("via.Application"), "get_GlobalSpeed")
	delta_time = os.clock() - last_time
	last_time = os.clock()
	ticks = ticks + 1
	
	if not is_paused then
		skill_delta_time = delta_time -- * (temp_fns.fix_world_speed and  or timescale_mult) * ((not player or temp_fns.player_speed_fn) and 1.0 or player.WorkRate:get_Rate()) --account for hitstop and natural slo mo
		game_time = game_time + skill_delta_time
	else
		skill_delta_time = 0.0
	end
	
	local last_pl_xform = pl_xform
	player = chr_mgr:get_ManualPlayer()
	pl_xform = player and player:get_Valid() and player:get_GameObject():get_Transform()
	camera = sdk.get_primary_camera()
	cam_matrix = camera and camera:get_WorldMatrix()
	is_casting = next(casted_spells) and (is_casting or true)
	do_inhibit_all_buttons = is_casting and do_inhibit_all_buttons
	old_cam_dist = (is_casting or temp_fns.fix_cam_dist) and old_cam_dist
	mfsm2 = pl_xform and player["<ActionManager>k__BackingField"].Fsm
	node_name = mfsm2 and mfsm2:getCurrentNodeName(0) or ""
	needs_setup = needs_setup or (pl_xform and not last_pl_xform)
	gamepad_button_guis = mfsm2 and gamepad_button_guis
	is_battling = battle_mgr._BattleMode == 2
	last_loco_time = node_name:sub(1,10) == "Locomotion" and last_loco_time or game_time
	if not keybinds then 
		keybinds = sdk.get_managed_singleton("app.UserInputManager")["<KeyBindController>k__BackingField"]
		if not keybinds then return nil else keybinds = keybinds._KeyBindSettingTables[0] end
	end
	active_shells = {}
	
	if not presets_glob or not em_presets_glob then
		setup_presets_glob()
	end
	
	if not enemy_skillsets or not skillsets_glob then
		setup_skillsets_glob()
	end
	
	if last_pl_xform and not pl_xform then
		cleanup(true, true)
	end
	
	local pressed_redo = ui_mod2_down and hk.check_hotkey("Redo")
	local pressed_undo = not pressed_redo and ui_mod2_down and hk.check_hotkey("Undo")
	
	if (pressed_undo and undo[undo.idx-1]) or (pressed_redo and undo[undo.idx+1]) then
		was_changed = 1
		undo.idx = undo.idx + (pressed_redo and 1 or -1)
		sms = hk.recurse_def_settings({}, undo[undo.idx][1])
		if undo[undo.idx][2] then imgui_skills = hk.recurse_def_settings({}, undo[undo.idx][2]) end
		if undo[undo.idx][3] then imgui_em_skills = hk.recurse_def_settings({}, undo[undo.idx][3]) end
		hk.setup_hotkeys(sms.hotkeys, default_sms.hotkeys)
	end
	
	is_modifier_down = hk.check_hotkey("Modifier / Inhibit", true)
	is_modifier2_down = hk.check_hotkey("SM Modifier2", true)
	is_cfg_modifier_down = hk.check_hotkey("SM Config Modifier", true)
	do_show_crosshair = (sms.crosshair_type == 2 or (sms.crosshair_type == 3 and is_modifier_down))
	
	for i, sks_idx in ipairs(sms.skillsets.idxes) do
		if sks_idx ~= 1 and (not sms.load_sksets_w_modifier or is_modifier_down) and (not sms.load_sksets_w_sksets_modifier or is_cfg_modifier_down) and hk.check_hotkey("Load Skillset "..i, 1) then
			load_skillset(skillsets_glob[sms.skillsets.idxes[i] ], i)
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
			player:get_ActionManager():requestActionCore(0, "DefaultCancelAction", 0)
		end
	end
	
	if (was_changed or needs_setup) then
		needs_setup = false
		
		assign_list[32].PreInput = sms.do_shift_sheathe and 15 or 0
		assign_list[33].PreInput = sms.do_shift_sheathe and 15 or 0
		assign_list[57].Action = sms.do_swap_lshoulders and 14 or 60
		assign_list[57].Button = sms.do_swap_lshoulders and 512 or 0
		
		skills_by_hotkeys, skills_by_hotkeys2, skills_by_hotkeys_sws, skills_by_hotkeys_no_sws = {}, {}, {}, {}
		for i, skill_tbl in ipairs(sms.skills) do
			if skill_tbl.enabled and not skill_tbl.hide_ui then
				local hotkey = sms.hotkeys["Use Skill "..i]
				if skill_tbl.state_type_idx == 2 then skills_by_hotkeys[hotkey] = skills_by_hotkeys[hotkey] or i end
				if skill_tbl.use_modifier2 then skills_by_hotkeys2[hotkey] = skills_by_hotkeys2[hotkey] or i end
				if skill_tbl.state_type_idx == 3 then skills_by_hotkeys_sws[hotkey] = skills_by_hotkeys_sws[hotkey] or i end
				if skill_tbl.state_type_idx == 4 then skills_by_hotkeys_no_sws[hotkey] = skills_by_hotkeys_no_sws[hotkey] or i end
			end
		end
		
		for i, skset_idx in ipairs(sms.skillsets.idxes) do
			sksets_by_hotkeys[sms.hotkeys["Load Skillset "..i] ] = sksets_by_hotkeys[sms.hotkeys["Load Skillset "..i] ] or i
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
		check_skillset_name()
	end

	if (do_inhibit_all_buttons or (is_modifier_down and sms.modifier_inhibits_buttons) or temp.do_start_buttons) and not temp_fns.fix_buttons then
		temp.do_start_buttons = nil
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
	
	--Global vars for custom function, get removed at the end of LateUpdateBehavior:
	_G.GameTime = game_time
	_G.Crosshair = ray_result
	_G.Player = player
	_G.ActiveSkills = active_skills
	_G.ActiveSummons = active_summons
	_G.Callbacks = temp.callbacks
	
	if not is_paused then
		for name, fn in pairs(pre_fns) do
			fn()
		end
	end
	
	for chr, tbl in pairs(rel_db) do
		if not chr:get_Valid() then 
			rel_db[chr] = nil
		elseif math.random(1, 100) == 1 then
			for chr2, num in pairs(tbl) do 
				if not (sdk.is_managed_object(chr2) and chr2.get_Valid and chr2:get_Valid()) then rel_db[chr] = nil end
			end
		end		
	end
	if math.random(1, 60) == 1 then
		for hit, nstore in pairs(dmg_tbl) do
			if not hit:get_Valid() then 
				dmg_tbl[hit] = nil
			elseif not nstore.shell then --dummy ones for detecting enemy hitbox contacts
				if not temp_fns[hit:get_CachedCharacter():get_ActionManager()] then dmg_tbl[hit] = nil end
			elseif hit:get_CachedCharacter() then
				if #nstore.parent > nstore.idx or not casted_spells[nstore.parent.key] then dmg_tbl[hit] = nil end
			elseif hit:get_CachedShell() then
				if not nstore.final_instance then dmg_tbl[hit] = nil end -- or nstore.hit_substance
			end
		end
	end
	if math.random(1, 1000) == 1 and pl_xform then
		local pl_pos = pl_xform:get_Position()
		for chr, nstore in pairs(replaced_enemies) do 
			if not (sdk.is_managed_object(chr) and chr.get_Valid and chr:get_Valid()) then replaced_enemies[chr] = nil end
		end
		for chr, skill_name in pairs(summon_record) do 
			if not (sdk.is_managed_object(chr) and chr.get_Valid and chr:get_Valid()) then 
				summon_record[chr] = nil 
			elseif (pl_pos - chr:get_Transform():get_Position()):length() > 300.0 and not draw.world_to_screen(chr:get_Transform():get_Position()) then
				summon_record[chr] = nil 
				chr:get_GameObject():destroy(chr:get_GameObject())
			end
		end
	end
	is_paused = true
end)

re.on_application_entry("UpdateBehavior", function() 
	
	for name, fn in pairs(hk.merge_tables({}, temp_fns)) do
		fn()
	end
	local input_proc = player and player:get_InputProcessor()
	if not input_proc then return end
	
	local casted_this_frame = {}
	local is_wp_drawn = player["<SheatheDrawController>k__BackingField"]["<IsDraw>k__BackingField"] --or node_name2:find( "Draw") or node_name2:find( "Sheathe")
	local is_hitbox_frame = false
	local stam_mgr = player:get_StaminaManager()
	local cast_tbl = enemy_casts[next(enemy_casts)]
	temp.last_cast_skills = {}
	active_states = {Sprinting=input_proc.DashSwitch and node_name:find("NormalLocomotion"), Airborne=player:get_IsJumpCtrlActive()}
	local should_move_cam = not _G.lock_on_target and ((sms.move_cam_for_crosshair >= 3 and is_casting == 1) or ((sms.move_cam_for_crosshair == 2 or sms.move_cam_for_crosshair == 4) and is_modifier_down))
	
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
	
	if cast_tbl then
		enemy_casts[next(enemy_casts)] = nil
		if not casted_spells[cast_tbl.key] then 
			cast_spell(cast_tbl.sp_tbl, cast_tbl.key, cast_tbl, nil, cast_tbl.storage)
		end
	end
	
	for i = #sms.skills, 1, -1 do --reversed since people put the hotkeys with more modifiers at the bottom
		if is_paused then break end 
		local skill_tbl = sms.skills[i]
		local mod2_ready = not skill_tbl.use_modifier2 or is_modifier2_down
		local are_mods_down = is_modifier_down and mod2_ready
		local modf_ready = mod2_ready and (skill_tbl.state_type_idx ~= 2 or is_modifier_down) 
		local hotkey_ready = skill_tbl.do_auto or ((skill_tbl.button_press_type == 1 and hk.check_hotkey("Use Skill "..i, 1)) 
			or (skill_tbl.button_press_type == 2 and hk.check_doubletap("Use Skill "..i)) or (skill_tbl.button_press_type == 3 and hk.check_hold("Use Skill "..i, false, skill_tbl.button_hold_time))) 
		
		if forced_skill and forced_skill[1] == i then
			local copy_skill = hk.recurse_def_settings({}, skill_tbl)
			for i, node in ipairs(copy_skill.smnodes) do
				if node.start < forced_skill[2] then
					node.enabled = false
				end
			end
			cast_spell(copy_skill, forced_skill[1], nil, forced_skill[2])
			
		elseif hotkey_ready and skill_tbl.enabled and modf_ready and (not casted_spells[i] or (skill_tbl.spell_states:find("%%"..skill_tbl.name))) then --"[^%a%c]"..skill_tbl.name.."$?[^%a]"
			local is_correct_vocation = (skill_tbl.job_idx == 1 or player["<Human>k__BackingField"]["<JobContext>k__BackingField"].CurrentJob == skill_tbl.job_idx - 1)
			local body_frame, upperbody_frame = player.FullBodyLayer:get_Frame(), player.UpperBodyLayer:get_Frame()
			local is_action_ready = (skill_tbl.custom_states == "") or test_animactions_ready(skill_tbl.custom_states, node_name, node_name2, body_frame, upperbody_frame)
			local is_state_ready = false
			for name, state in pairs(skill_tbl.states) do
				for k, keyword in ipairs(state_keywords[name] or {}) do
					active_states[name] = active_states[name] or node_name:find(keyword)
					is_state_ready = is_state_ready or (state and active_states[name])
				end
			end
			
			if skill_tbl.custom_states:find("`") then
				is_state_ready = is_state_ready or is_action_ready
				is_action_ready = is_action_ready or is_state_ready
			end
			
			local is_anim_ready = (skill_tbl.anim_states == "")
			if not is_anim_ready then
				local mot_info, mot_info2 = player.FullBodyLayer:get_HighestWeightMotionNode(), player.UpperBodyLayer:get_HighestWeightMotionNode()
				local anim_name, anim_name2 = mot_info and mot_info:get_MotionName() or "", mot_info2 and mot_info2:get_MotionName() or ""
				is_anim_ready = test_animactions_ready(skill_tbl.anim_states, anim_name, anim_name2, body_frame, upperbody_frame)
			end
			
			if is_correct_vocation and is_action_ready and is_state_ready and is_anim_ready and (skill_tbl.stam_cost == 0 or stam_mgr["<RemainingAmount>k__BackingField"] > 0) and not casted_this_frame[hk.hotkeys["Use Skill "..i] ] then
				local curr_r_weapon = not is_wp_drawn and "Unarmed" or weps.getWeaponJob(player:get_WeaponAndItemHolder():get_RightWeapon(), weps.job_to_wp_map)
				local curr_l_weapon = weps.getWeaponJob(player:get_WeaponAndItemHolder():get_LeftWeapon(), weps.job_to_sub_wp_map)
				local is_correct_weapon = skill_tbl.wp_idx == 1 or (skill_tbl.wp_idx == 2 and curr_r_weapon == "Unarmed") or weps.types[skill_tbl.wp_idx] == curr_r_weapon or weps.types[skill_tbl.wp_idx] == curr_l_weapon or (skill_tbl.wp_idx == 14 and curr_l_weapon:find("Bow")) 
					or (skill_tbl.wp_idx == 15 and curr_r_weapon:find("Staff")) or (skill_tbl.wp_idx == 13 and (curr_r_weapon == "Sword" or curr_r_weapon == "Two-Hander" or curr_r_weapon == "Dagger" or curr_r_weapon == "Duospear"))
				local is_basic_ready = (skill_tbl.state_type_idx ~= 4 or not (is_sws_down and not are_mods_down)) and (skill_tbl.state_type_idx ~= 3 or (is_sws_down and not are_mods_down))
				local is_body_frame_ready = (skill_tbl.frame_range[1] == -1.0 or body_frame >= skill_tbl.frame_range[1]) and (skill_tbl.frame_range[2] == -1.0 or body_frame <= skill_tbl.frame_range[2])
				local is_upperbody_frame_ready = (skill_tbl.frame_range_upper[1] == -1.0 or upperbody_frame >= skill_tbl.frame_range_upper[1]) and (skill_tbl.frame_range_upper[2] == -1.0 or upperbody_frame <= skill_tbl.frame_range_upper[2])
				local wep_ready = (not skill_tbl.require_weapon or is_wp_drawn)
				
				local hitbox_ready = not skill_tbl.require_hitbox or is_hitbox_frame
				if not hitbox_ready then
					local hit = player:get_Hit()
					local req_tracks = get_req_tracks(player)
					is_hitbox_frame = is_hitbox_frame or req_tracks.ReqId1 >= 0 or req_tracks.ReqId2 >= 0 or req_tracks.ReqId3 >= 0 or req_tracks.ReqId4 >= 0 or req_tracks.ReqId5 >= 0 or req_tracks.ReqId6 >= 0 or req_tracks.ReqId7 >= 0 or req_tracks.ReqId8 >= 0 or req_tracks.ReqId9 >= 0
					hitbox_ready = is_hitbox_frame and (not skill_tbl.require_hitbox_contact or (game_time - temp.last_pl_hit_landed) < 0.05)
				end
				
				if not getmetatable(skill_tbl) then
					local mt = {shells = skill_tbl.smnodes}
					setmetatable(skill_tbl, mt)
					mt.__index = mt
				end
				
				local skill_storage = {}
				local custom_fn_ready = skill_tbl.activate_fn == ""
				if not custom_fn_ready then
					local fn_env = {ActName=node_name:match(".+%.(.+)"), ActName2=node_name2 and node_name2:match(".+%.(.+)"), SkillData=skill_tbl, Skill=skill_storage}
					fn_env.Exec = function(skill_name) 
						local skill_idx = func.find_key(sms.last_sel_spells, skill_name)
						if skill_idx then forced_skill = {skill_idx, 0.0} end
					end
					fn_env.Kill = function(skill_name) 
						if active_skills[skill_name] then casted_spells[active_skills[skill_name].idx] = nil end
					end
					local try, output = pcall(load(skill_tbl.activate_fn, nil, "t", hk.merge_tables(_G, fn_env)))
					for key, value in pairs(fn_env) do _G[key] = nil end
					if imgui_skills[i] then imgui_skills[i].error_txt = not try and {output, os.clock()} or imgui_skills[i].error_txt end
					custom_fn_ready = try and output
				end
				
				local required_skill_active = skill_tbl.spell_states == ""
				if not required_skill_active then
					for n, skill_name in ipairs(split(skill_tbl.spell_states, ",", true)) do
						skill_name = skill_name:gsub("^%%", "")
						local sub_state = true
						for s, sub_name in ipairs(split(skill_name, "+", true)) do
							local sname = sub_name:match("(.*)%(") or sub_name
							local do_search, found_idx = (sub_name:sub(1,1) == "*")
							if do_search then 
								sname = sname:sub(2,-1)
								for key, tbl in pairs(casted_spells) do 
									found_idx = tonumber(key) and tbl.name and tbl.name:find(sname) and key --FIXME
									if found_idx then break end
								end
							else
								found_idx = func.find_key(casted_spells, sname, "name")
							end
							sub_state = found_idx and sub_state
							if sub_state then
								local stime = game_time - casted_spells[found_idx].storage.start
								local range = sub_name:match("%((.+)%)"); range = range and split(range, " ")
								sub_state = stime >= (range and tonumber(range[1]) or 0.0) and stime <= (range and tonumber(range[2]) or 999999.0)
							end
						end
						required_skill_active = required_skill_active or sub_state
					end
				end
				
				if not wep_ready then
					player["<ActionManager>k__BackingField"]:requestActionCore(0, "DrawWeapon", 1)
					goto exit
				elseif required_skill_active and cast_prep_type == 0 and is_correct_weapon and is_body_frame_ready and is_upperbody_frame_ready and is_basic_ready and hitbox_ready then
					if not custom_fn_ready then goto next_skill end
					
					casted_this_frame[hk.hotkeys["Use Skill "..i] ] = true
					if active_states.Falling and skill_tbl.states.Falling then --reset fall on midair cast
						reset_fall_height(3.0)
					end
					cast_spell(skill_tbl, i, nil, nil, skill_storage)
				end
			end
		end
		::next_skill::
	end

	::exit::
	active_skills = {}
	local tmp_skills = {}; 
	for key, tbl in pairs(casted_spells) do 
		active_skills[tbl.name] = tbl
		active_skills[key] = tbl
		tbl.idx = tonumber(key)
		tmp_skills[key] = tbl 
	end 
	
	for idx, cast_spell_tbl in pairs(tmp_skills) do
		cast_spell_tbl.fn(cast_spell_tbl.storage)
	end
	
	pressed_cancel = false
	forced_skill = nil
end)

re.on_application_entry("UpdateMotion", function() 
	for name, fn in pairs(mot_fns) do
		fn()
	end
end)

re.on_application_entry("LateUpdateBehavior", function() 
	if was_changed then
		hk.update_hotkey_table(sms.hotkeys)
		json.dump_file("SkillMaker\\SkillMaker.json", sms)
		
		if was_changed ~= 1 then
			local not_dragged = not imgui.is_mouse_down()
			
			temp_fns.set_undo = function()
				if not_dragged or imgui.is_mouse_released() then
					temp_fns.set_undo = nil
					undo.idx = undo.idx + 1
					table.insert(undo, undo.idx, {
						hk.recurse_def_settings({}, sms),
						was_changed == "cross_skillswap" and hk.recurse_def_settings({}, imgui_skills),
						was_changed == "cross_skillswap" and hk.recurse_def_settings({}, imgui_em_skills),
					})
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
	
	if is_paused then return end
	
	if sms.ingame_ui_buttons and sms.modifier_inhibits_buttons and gamepad_button_guis and gamepad_button_guis.face_obj:get_DrawSelf() then	
		local hotkey_arr =  hk.buttons[sms.hotkeys["Modifier / Inhibit"] ] and gamepad_button_guis.face_arr or gamepad_button_guis.face_arr_kb
		gamepad_button_guis.face_obj:set_DrawSelf(true)
		gamepad_button_guis.face_obj:set_UpdateSelf(true)
		local swap_cancel_prep = sms.do_swap_lshoulders and cast_prep_type == 2
		
		for j, hotkey_str in ipairs(gamepad_button_guis.face_arr) do
			local hotkey = hotkey_arr[j]
			local cfg_idx = sksets_by_hotkeys[hotkey]
			local skill_idx = (is_modifier2_down and ((is_modifier_down and skills_by_hotkeys2[hotkey]) or (is_sws_down and skills_by_hotkeys_sws[hotkey]) or (not is_sws_down and skills_by_hotkeys_no_sws[hotkey]))) 
				or (is_modifier_down and (((is_sws_down and skills_by_hotkeys_sws[hotkey]) or (not is_sws_down and skills_by_hotkeys_no_sws[hotkey])) or ((skills_by_hotkeys[hotkey] and not sms.skills[skills_by_hotkeys[hotkey] ].use_modifier2) and skills_by_hotkeys[hotkey])))
				or (is_sws_down and skills_by_hotkeys_sws[hotkey]) or (not is_sws_down and skills_by_hotkeys_no_sws[hotkey])
			local txt_obj = gamepad_button_guis[hotkey_str]
			local panel = txt_obj:get_Parent()
			local old_col, old_button_col, old_cs
			
			if hotkey_str == sms.hotkeys["Modifier / Inhibit"] then
				local msg = cast_prep_type == 1 and sms.do_swap_lshoulders and "Cancel" or (hk.gp_state.down[256] and not is_modifier_down and sms.do_shift_sheathe and "Sheathe/Draw") or ((sms.last_skset and sms.last_skset.has_skillset_name and (sms.last_skset.name.." Skill"))) or "Skill Maker" 
				txt_obj:set_Message("<COLOR preset=\"arrow\"></COLOR>"..msg)
				if is_modifier_down then 
					old_cs = {Vector4f.new(1,1,1,1), Vector3f.new(0,0,0)}
				end
				old_col = txt_obj:get_Color()
				if cast_prep_type then txt_obj:set_Visible(true) end
			elseif hotkey_str == sms.hotkeys["SM Modifier2"] and (is_modifier_down or swap_cancel_prep) then
				txt_obj:set_Message("<COLOR preset=\"arrow\"></COLOR>"..((swap_cancel_prep and "Cancel") or (is_modifier_down and ((sms.last_skset and sms.last_skset.has_skillset_name and ("Switch "..sms.last_skset.name.." Skill")) or "Switch SM Skill"))))
				txt_obj:set_Visible(true)
				old_col = txt_obj:get_Color()
				if is_modifier2_down then 
					old_cs = {Vector4f.new(1,1,1,1), Vector3f.new(0,0,0)}
				end
			elseif cfg_idx and sms.skillsets.idxes[cfg_idx] > 1 and (not sms.load_sksets_w_modifier or is_modifier_down) and (not sms.load_sksets_w_sksets_modifier or is_cfg_modifier_down) then
				local txt = skillsets_glob.short[sms.skillsets.idxes[cfg_idx] ]
				txt = "["..(txt:match(".+ %- (.+)") or txt:match(".+%\\(.+)") or txt):gsub("_", " ").."]"
				txt_obj:set_Message("<COLOR preset=\"arrow\"></COLOR>"..txt)
				txt_obj:set_Visible(true)
				old_cs = hk.gp_state.down[hk.buttons[hotkey_str] ] and {Vector4f.new(1,1,1,1), Vector3f.new(0,0,0)}
				old_col = txt_obj:get_Color()
			elseif (skill_idx and ((is_modifier_down and skills_by_hotkeys[hotkey]) or (is_sws_down and skills_by_hotkeys_sws[hotkey]) or (not is_sws_down and skills_by_hotkeys_no_sws[hotkey]))) or (not skill_idx and sms.modifier_inhibits_buttons and is_modifier_down) then
				local txt = not skill_idx and " " or sms.last_sel_spells[skill_idx] ~= "" and sms.last_sel_spells[skill_idx] or (skill_idx and "Skill "..skill_idx) or " " --txt_obj:get_Message()
				txt = (txt:match(".+ %- (.+)") or txt:match(".+%\\(.+)") or txt):gsub("_", " ")
				old_cs = casted_spells[skill_idx] and {Vector4f.new(1,1,1,1), Vector3f.new(0,0,0)}--{panel:get_ColorScale(), panel:get_ColorOffset()}
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
	
	for name, fn in pairs(hk.merge_tables({}, late_fns)) do
		fn()
	end
	is_summoning = player and not not next(sm_summons)
	_G.GameTime, _G.ActiveSkills, _G.Crosshair, _G.ActiveSummons, _G.Player, _G.Callbacks = nil
end)

re.on_frame(function()
	math.randomseed(math.floor(os.clock()*1000))
	ui_mod_down = reframework:is_drawing_ui() and (hk.check_hotkey("UI Modifier", true) or ((imgui.is_mouse_down() or imgui.is_mouse_released() or imgui.is_mouse_clicked()) and ui_mod_down))
	ui_mod2_down = reframework:is_drawing_ui() and (hk.check_hotkey("UI Modifier2", true))
	temp.disp_sz = imgui.get_display_size()
	
	if ray_result and do_show_crosshair then
		local pos_2d = draw.world_to_screen(ray_result[2])
		if pos_2d then draw.filled_circle(pos_2d.x, pos_2d.y, 2.5, 0xAAFFFFFF, 0) end
		
		for key, cast_tbl in pairs(casted_spells) do
			local current = cast_tbl.storage[#cast_tbl.storage]
			if current and current.shell.freeze_crosshair and current.shell.cast_type <= 2 and current.shell.udata_idx > 1 then
				local pos_2d = draw.world_to_screen(current.ray[2])
				if pos_2d then draw.filled_circle(pos_2d.x, pos_2d.y, 2.5, 0xFF0000FF, 0) end
			end
		end
	end
	
	for key, fn in pairs(frame_fns) do
		fn()
	end
	
	if reframework:is_drawing_ui() then
		local using_window = sms.use_window
		
		ui.themes.push_theme(ui.themes.theme_names[sms.theme_type])
		
		local clicked_x = sms.use_window and imgui.begin_window("Skill Maker", true, 0) == false
		if clicked_x or not sms.use_window then 
			sms.use_window = false
		else
			imgui.push_id(91724)
			display_mod_imgui(true)
			imgui.pop_id()
		end
		if using_window then 
			imgui.end_window()
		end
		
		for key, fn in pairs(window_fns) do
			fn()
		end
		ui.themes.pop_theme(ui.themes.theme_names[sms.theme_type])
	end
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

--
sdk.hook(sdk.find_type_definition("app.StaminaManager"):get_method("add"), function(args)
    if is_casting and game_time - last_loco_time < 1.0 then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end)

--Face buttons GUI modding:
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
				local cfg_idx = sksets_by_hotkeys[hotkey]
				local skill_idx = (is_modifier2_down and ((is_modifier_down and skills_by_hotkeys2[hotkey]) or (is_sws_down and skills_by_hotkeys_sws[hotkey]) or (not is_sws_down and skills_by_hotkeys_no_sws[hotkey]))) 
					or (is_modifier_down and (((is_sws_down and skills_by_hotkeys_sws[hotkey]) or (not is_sws_down and skills_by_hotkeys_no_sws[hotkey])) or ((skills_by_hotkeys[hotkey] and not sms.skills[skills_by_hotkeys[hotkey] ].use_modifier2) and skills_by_hotkeys[hotkey])))
					or (is_sws_down and skills_by_hotkeys_sws[hotkey]) or (not is_sws_down and skills_by_hotkeys_no_sws[hotkey])
				local txt_obj = gamepad_button_guis[hotkey_str]
				local txt
				
				if cfg_idx and sms.skillsets.idxes[cfg_idx] > 1 and (not sms.load_sksets_w_modifier or is_modifier_down) and (not sms.load_sksets_w_sksets_modifier or is_cfg_modifier_down) then
					txt = skillsets_glob.short[sms.skillsets.idxes[cfg_idx] ]
					txt = "["..(txt:match(".+ %- (.+)") or txt:match(".+%\\(.+)") or txt):gsub("_", " ").."]"
				elseif (skill_idx and ((is_modifier_down and skills_by_hotkeys[hotkey]) or (is_sws_down and skills_by_hotkeys_sws[hotkey]) or (not is_sws_down and skills_by_hotkeys_no_sws[hotkey]))) or (not skill_idx and sms.modifier_inhibits_buttons and is_modifier_down) then
					txt = not skill_idx and " " or sms.last_sel_spells[skill_idx] ~= "" and sms.last_sel_spells[skill_idx] or "Skill "..skill_idx
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
						local old_cs = (casted_spells[skill_idx] or hk.gp_state.down[hk.buttons[hotkey_str] ]) and {panel:get_ColorScale(), panel:get_ColorOffset()}
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
		if sdk.to_int64(args[4]) == 0 then return end
		thread.get_hook_storage().args = args
	end,
	function(retval)
		local args = thread.get_hook_storage().args
		if args and (is_summoning or (is_casting and is_battling and sdk.to_int64(args[3]) == player:get_address())) then
			local cha1 = sdk.to_managed_object(args[3])
			local cha2 = sdk.to_managed_object(args[4])
			if cha1 == cha2 then return retval end
			if cha1 == player then 
				if is_battling and sdk.to_int64(retval) == 0 and func.getC(cha2:get_GameObject(), "app.NPCBehavior") then return sdk.to_ptr(2) end --Spells wont hit neutral NPCs during combat
				if sm_summons[cha2] then return sdk.to_ptr(is_battling and 2 or 0) end
			end
			local rels = rel_db[cha1]
			if rels and rels[cha2] ~= nil then 
				if not rels[cha2] then return retval end
				retval = sdk.to_ptr(rels[cha2])
			else
				local out
				local summon_1 = sm_summons[cha1]
				local summon_2 = sm_summons[cha2]
				local em_summon_1 = em_summons[cha1]
				local em_summon_2 = em_summons[cha2]
				local both_tbl_1 = summon_1 or em_summon_1
				local both_tbl_2 = summon_2 or em_summon_2
				
				if (em_summon_1 and cha2 == player) or (em_summon_2 and cha1 == player) then
					out = 1
				elseif (both_tbl_2 and both_tbl_2.owner == cha1) or (both_tbl_1 and both_tbl_1.owner == cha2) then
					out = 2 --Summons and summoners friendly with eachother
				elseif (em_summon_1 and em_summon_1.hostile_to_all) or (em_summon_2 and em_summon_2.hostile_to_all)  then 
					out = 1
				elseif both_tbl_1 and rel_db[both_tbl_1.owner] and rel_db[both_tbl_1.owner][cha2] then
					out = rel_db[both_tbl_1.owner][cha2] --inherited hostilities from owner
				elseif both_tbl_2 and rel_db[both_tbl_2.owner] and rel_db[both_tbl_2.owner][cha1] then
					out = rel_db[both_tbl_2.owner][cha1]
				elseif summon_1 then
					local em_tbl = enemy_list[enums.chara_id_enum[cha2:get_CharaID()] ]
					out = ((em_tbl and em_tbl.is_animal) or cha2 == player or sm_summons[cha2] or func.getC(cha2:get_GameObject(), "app.NPCBehavior")) and 2 or 1 --friendly with animals, player, other summons and NPCs
				elseif summon_2 then
					local em_tbl = enemy_list[enums.chara_id_enum[cha1:get_CharaID()] ]
					out = ((em_tbl and em_tbl.is_animal) or cha1 == player or sm_summons[cha1] or func.getC(cha1:get_GameObject(), "app.NPCBehavior")) and 2 or 1
				elseif (em_summon_1 and cha2.EnemyCtrl and cha2.EnemyCtrl._IsEnemyCharacter) or (em_summon_2 and cha1.EnemyCtrl and cha1.EnemyCtrl._IsEnemyCharacter) then
					out = 2 --hostile summons are friendly with real enemies / eachother
				end
				if not rels then rel_db[cha1] = {} end
				if out then 
					rel_db[cha1][cha2] = out
					retval = sdk.to_ptr(out)
				else
					rel_db[cha1][cha2] = false --don't re-evaluate, let the game do these
				end
			end
		end
		return retval
	end
)

sdk.hook(sdk.find_type_definition("app.AIBlackBoardExtensions"):get_method("setBBValuesToExecuteActInter(app.AIBlackBoardController, app.ActInterPackData, app.AITarget)"), function(args)
	if not is_summoning then return end
	local aibb = sdk.to_managed_object(args[2])
	if pre_fns[aibb] then return 1 end
	local chr = aibb:get_Character()
	local nstore = sm_summons[chr]
	local pack = sdk.to_managed_object(args[3])
	if nstore then
		if nstore.following then return sdk.PreHookResult.SKIP_ORIGINAL end
	elseif not is_battling and pack:get_Path():find("NPC_Combat[MC]") then
		local enemy_xform = sdk.to_managed_object(args[4]):get_GameObject():get_Transform():get_Parent()
		local enemy_chr = enemy_xform and func.getC(enemy_xform:get_GameObject(), "app.Character")
		if sm_summons[enemy_chr] then return sdk.PreHookResult.SKIP_ORIGINAL end
	end
end)

sdk.hook(sdk.find_type_definition("app.Human"):get_method("isEnableFriendOrNeutralHitForPlayer"), 
	function(args)
		local victim = sdk.to_managed_object(args[3])
		if not is_battling and not (sm_summons[victim] and sm_summons[victim].do_no_friendlyfire) then return end
		if (sm_summons[victim] or (func.getC(victim:get_GameObject(), "app.NPCBehavior") and rel_holder:call("getRelationshipFromTo(app.Character, app.Character)", victim, player) ~= 1)) and thread.get_hook_storage() then
			thread.get_hook_storage().retval = sdk.to_ptr(false)
		end
	end,
	function(retval)
		return thread.get_hook_storage().retval or retval
	end
)

sdk.hook(sdk.find_type_definition("app.HumanDefaultCancelAction"):get_method("start"), function(args)
	pressed_cancel = (cast_prep_type > 0)
end)

sdk.hook(sdk.find_type_definition("app.ResetCameraToLockOnTarget"):get_method("start"), function(args)
	if is_casting then return sdk.PreHookResult.SKIP_ORIGINAL end
end)

sdk.hook(sdk.find_type_definition("app.ResetCameraToLockOnTarget"):get_method("setCameraAngle"), function(args)
	if is_casting then return sdk.PreHookResult.SKIP_ORIGINAL end
end)

sdk.hook(sdk.find_type_definition("app.HumanShootArrow"):get_method("start(via.behaviortree.ActionArg)"), function(args)
	if cast_prep_type == 2 and sdk.to_managed_object(args[2]).Chara == player then return sdk.PreHookResult.SKIP_ORIGINAL end
end)

sdk.hook(sdk.find_type_definition("app.TurnController"):get_method("updateAngle"), function(args)
	if is_paused then return end
	local turn_ctrl = sdk.to_managed_object(args[2])
	if turn_fns[turn_ctrl] then
		turn_fns[turn_ctrl]()
	end
end)

sdk.hook(sdk.find_type_definition("app.Shell"):get_method("checkFinish"), 
	function(args)
		local shell = sdk.to_managed_object(args[2])
		local nstore = active_shells[shell]
		local timer = nstore and nstore.shell.do_abs_lifetime and not shell["<TerrainHitResult>k__BackingField"] and not nstore.children[1] and shell["<LiveTimer>k__BackingField"]
		if timer and timer._FinishFrame ~= math.huge and timer._ElapsedFrame < timer._FinishFrame then 
			thread.get_hook_storage().retval = sdk.to_ptr(false)
		end
	end,
	function(retval)
		return thread.get_hook_storage().retval or retval
	end
)

sdk.hook(sdk.find_type_definition("app.WorkRate"):get_method("setHitStop(System.Single, System.Single, System.Boolean)"), function(args)
	if temp_fns.player_speed_fn and sdk.to_managed_object(args[2]) == player.WorkRate then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end)

sdk.hook(sdk.find_type_definition("app.TargetController"):get_method("setTarget"),
	function(args)
		if temp.targ_hooked then return 1 end  --this method seems to call itself
		local nstore = is_summoning and sm_summons[sdk.to_managed_object(args[2])._Chara]
		if nstore then
			args[3] = sdk.to_ptr(nstore.target_type or 9)
			temp.targ_hooked, nstore.target_type = true, false
		end
	end, 
	function(retval)
		temp.targ_hooked = false
		return retval
	end,
	true
)

local function em_activate_fn_checker(sp_tbl, em_chr, em_act, em_tbl, redir_name, final_name, skill_idx, actname1, skill_storage)
	if sp_tbl.activate_fn == "" then return true end
	local fn_env = {
		ActName=actname1 or em_act.Fsm:getCurrentNodeName(0):match(".+%.(.+)"), 
		SkillData=sp_tbl, 
		Skill=skill_storage, 
		Owner=em_chr, 
		Player=player,
		Exec = function(skill_name) 
			local skill_idx2 = func.find_key(sms.enemyskills[final_name].skills, skill_name, "name")
			if skill_idx2 then 
				enemy_casts[em_act] = {sp_tbl=sms.enemyskills[final_name].skills[skill_idx2], em_chr=em_chr, act_mgr=em_act, name=em_tbl.name, idx=skill_idx2, redir_name=redir_name}
				enemy_casts[em_act].key = em_chr:get_address()..skill_name
			end
		end,
		Stop = function()
			skill_storage.killed = true
		end,
		Kill = function(skill_name) 
			if active_skills[skill_name] then casted_spells[active_skills[skill_name].idx] = nil end
		end,
	}
	fn_env.ActName2 = em_act.Fsm:getCurrentNodeName(1)
	fn_env.ActName2 = fn_env.ActName2 and fn_env.ActName2:match(".+%.(.+)")
	
	local t_ctrl = em_chr.EnemyCtrl.Ch2 and em_chr.EnemyCtrl.Ch2._TargetController
	fn_env.Target = t_ctrl and t_ctrl._AITarget or t_ctrl:getTarget(t_ctrl._TargetType)
	local try, output = pcall(load(sp_tbl.activate_fn, nil, "t", hk.merge_tables(_G, fn_env)))
	for key, value in pairs(fn_env) do _G[key] = nil end
	local imgui_em_skill = imgui_em_skills[final_name][skill_idx]
	if imgui_em_skill then 
		imgui_em_skill.error_txt = not try and {output, os.clock()} or imgui_em_skill.error_txt 
		imgui_em_skill.last_data = {target=fn_env.Target, owner=em_chr, skill=sp_tbl}
	end
	return try and output
end

--Enemy Skills are evaluated and launched here
sdk.hook(sdk.find_type_definition("app.ActionManager"):get_method("requestActionCore(app.ActionManager.Priority, System.String, System.UInt32)"), function(args)
	if player and not is_paused and not next(enemy_casts) then
		local em_act = sdk.to_managed_object(args[2])
		local gameobj = em_act:get_GameObject()
		local em_chr = func.getC(gameobj, "app.Character")
		local em_ch_name = enums.chara_id_enum[em_chr:get_CharaID()] or ""
		local em_tbl = enemy_list[em_ch_name] or enemy_list[em_ch_name:sub(1,3)]
		if not em_tbl or em_tbl.is_animal then return end
		local em_skills_data_og = em_tbl and sms.enemyskills[em_tbl.name]
		if not em_skills_data_og or not em_skills_data_og.enabled then return end
		local redir_name = em_skills_data_og.redirect_idx > 1 and redirect_names[em_skills_data_og.redirect_idx]
		local em_skills_data = sms.enemyskills[redir_name] or em_skills_data_og
		
		if em_skills_data then
			local human = em_chr:get_Human() 
			local em_node_name = sdk.to_managed_object(args[4]):ToString() or ""
			local is_pawn = human and func.getC(gameobj, "app.SpecialPawn")
			local player_level = player:get_Human():get_StatusContext()._Level
			local final_name = redir_name or em_tbl.name
			
			local function found_keyword(to_search, keywords)
				for i, keyword in ipairs(split(keywords, ",", true)) do if to_search:find(keyword) then return true end end
			end
			
			for i, sp_tbl in ipairs(em_skills_data.skills) do
				local sp_act_name = sp_tbl.act_name ~= "" and sp_tbl.act_name
				local key = em_chr:get_address()..(sp_tbl.name~="" and sp_tbl.name or i)
				sp_tbl.min_player_lvl = sp_tbl.min_player_lvl or 0 --FIXME
				
				if sp_tbl.enabled and sp_tbl.min_player_lvl <= player_level then
					if sp_tbl.do_replace_enemy and sm_summons[em_chr] == nil then
						local em_xform = em_chr:get_Transform()
						local em_pos = em_xform:get_Position()
						local dist = (pl_xform:get_Position() - em_pos):length()
						if (not replaced_enemies[em_chr] or not replaced_enemies[em_chr].replaced) and dist > 10.0 and dist < 90.0 then
							replaced_enemies[em_chr] = replaced_enemies[em_chr] or {spawn_time = game_time}
							if not replaced_enemies[em_chr][sp_tbl.name] and game_time - replaced_enemies[em_chr].spawn_time > 2.0 and not is_visible(em_chr:get_Transform()) then
								local try, location_ready = pcall(function()
									if sp_tbl.locations == "" then return true end
									local locs = {}
									for i, loc_number in ipairs(split(sp_tbl.locations, ",", true)) do
										if tostring(wgraph_mgr:call("findNearNodeID(via.Position, System.Int32)", em_xform:get_UniversalPosition(), 0).blockId):find(loc_number) then
											return true
										end
									end
								end)
								if try and location_ready and 1000 * sp_tbl.odds_to_replace >= math.random(0, 1000) then
									local skill_storage = {}
									if em_activate_fn_checker(sp_tbl, em_chr, em_act, em_tbl, redir_name, final_name, i, nil, skill_storage) then
										replaced_enemies[em_chr].replaced = true
										print("Replacing enemy", em_tbl.name, "using spell", sp_tbl.name, draw.world_to_screen(em_pos), dist)
										log.info("Replacing enemy "..em_tbl.name.." using spell "..sp_tbl.name.." at distance "..dist)
										enemy_casts[em_act] = {sp_tbl=sp_tbl, em_chr=em_chr, act_mgr=em_act, name=em_tbl.name, key=key, idx=i, redir_name=redir_name, storage=skill_storage}
										return nil
									end
								end
								replaced_enemies[em_chr][sp_tbl.name] = true --only try once
							end
						end
					else
						local is_req_skill_ready = (sp_tbl.summon_skill_name == "") or (summon_record[em_chr] and summon_record[em_chr].parent.skill.name == sp_tbl.summon_skill_name)
						if is_req_skill_ready and not casted_spells[key] and not temp_fns[key] and ((sp_tbl.search_txt ~= "" and found_keyword(em_node_name, sp_tbl.search_txt)) or (sp_tbl.replace_idx > 1 and sp_act_name == em_node_name)) then
							local layer_idx = sp_tbl.do_upperbody and 1 or 0
							local is_job_ready = not human or sp_tbl.em_job_idx == 1 or human.HumanEnemyController.JobContext.CurrentJob == sp_tbl.em_job_idx-1
							local are_odds_ready = sp_tbl.odds_to_replace >= 1 or sp_tbl.activate_interval ~= -1 or 1000 * sp_tbl.odds_to_replace >= math.random(0, 1000)
							
							if is_job_ready and are_odds_ready then
								print("Detected enemy skill candidate:", em_tbl.name, "Action name:", em_node_name, "Key:", key)
								log.info("Detected enemy skill candidate: " .. em_tbl.name .. "	" .. em_node_name .. "	" .. sp_tbl.act_name .. "	" .. sp_tbl.name .. "	" .. layer_idx)
								local sp_anim_txt = sp_tbl.anim_search_txt ~= "" and sp_tbl.anim_search_txt
								local hit = em_chr:get_Hit()
								local delay_time = sp_tbl.delay_time
								local skill_storage = {}
								local start, ticks_start = game_time, ticks
								
								if (em_tbl.is_human or em_tbl.name:sub(1,4)=="Skel") and sm_summons[em_chr] == nil then 
									local tree, tree2, pl_tree, pl_tree2 = em_act.Fsm:getLayer(0):get_tree_object(), em_act.Fsm:getLayer(1):get_tree_object(), mfsm2:getLayer(0):get_tree_object(), mfsm2:getLayer(1):get_tree_object()
									for s, smnode in ipairs(sp_tbl.smnodes) do
										if smnode.action_idx > 1 and not (tree:get_node_by_name(smnode.action_name) or tree2:get_node_by_name(smnode.action_name)) and (pl_tree:get_node_by_name(smnode.action_name) or pl_tree2:get_node_by_name(smnode.action_name)) then 
											enable_pl_fsm_on_em(em_chr) --add missing actions to skeletons and bandits if needed
											break
										end
									end
								end
								
								--this function watches every frame while the action is playing and runs the skill if the conditions are met:
								temp_fns[key] = function() 
									
									if not em_act.Fsm or ticks - ticks_start < 3 then return end --has to load a bunch of shit for the new action first
									local nname = em_act.Fsm:getCurrentNodeName(layer_idx); nname = nname:match(".+%.(.+)") or nname
									local past_delay = game_time - start >= delay_time
									if not em_chr:get_Valid() or (past_delay and nname ~= em_node_name and (sp_tbl.search_txt == "" or not found_keyword(nname, sp_tbl.search_txt))) then 
										temp_fns[key] = nil 
									end
									
									if temp_fns[key] then 
										local mnode = sp_anim_txt and em_chr:get_Motion():getLayer(layer_idx):get_HighestWeightMotionNode()
										local hitbox_ready = not sp_tbl.require_hitbox
										if not hitbox_ready then
											dmg_tbl[hit] = dmg_tbl[hit] or {last_hit=0}
											local req_tracks = get_req_tracks(em_chr)
											hitbox_ready = req_tracks and (req_tracks.ReqId1 >= 0 or req_tracks.ReqId2 >= 0 or req_tracks.ReqId3 >= 0 or req_tracks.ReqId4 >= 0 or req_tracks.ReqId5 >= 0 
												or req_tracks.ReqId6 >= 0 or req_tracks.ReqId7 >= 0 or req_tracks.ReqId8 >= 0 or req_tracks.ReqId9 >= 0)
											if sp_tbl.require_hitbox_contact then 
												hitbox_ready = game_time - dmg_tbl[hit].last_hit < 0.05
											end
										end
										
										local interval_ready = (sp_tbl.activate_interval == -1)
										if not interval_ready and game_time - start > sp_tbl.activate_interval and past_delay then 
											interval_ready = (1000 * sp_tbl.odds_to_replace >= math.random(0, 1000)) and 1
											delay_time = 0
											start = game_time
										end
										
										if past_delay and hitbox_ready and interval_ready and (not mnode or mnode:get_MotionName():find(sp_anim_txt)) then 
											temp_fns[key] = (interval_ready == 1) and temp_fns[key] or nil
											if (interval_ready == 1) then start = start + sp_tbl.activate_interval end --reset interval
											
											local activate_fn_ready = em_activate_fn_checker(sp_tbl, em_chr, em_act, em_tbl, redir_name, final_name, i, nname, skill_storage)
											if skill_storage.killed then  temp_fns[key] = nil end
											if activate_fn_ready then
												enemy_casts[em_act] = {sp_tbl=sp_tbl, em_chr=em_chr, act_mgr=em_act, name=em_tbl.name, key=key, idx=i, redir_name=redir_name, storage=skill_storage}
											end
										end
									end
								end
								temp_fns[key]()
								
								if sp_tbl.activate_interval == -1 then
									return nil --activate only one skill per enemy per frame, unless it uses an interval
								end
							end
						end
					end
				end
			end
		end
	end
end)

sdk.hook(sdk.find_type_definition("app.CharacterManager"):get_method("getCharacterExp(app.Character)"), 
	function(args)
		local chr =  sdk.to_managed_object(args[3])
		if temp.skip_exp_gain or sm_summons[chr] then 
			temp.skip_exp_gain = nil
			thread.get_hook_storage().ret = sdk.to_ptr(0) 
		end
	end,
	function(retval)
		return thread.get_hook_storage().ret or retval
	end
)

sdk.hook(sdk.find_type_definition("app.Ch255BattleWayPointCtrl"):get_method("nodeFindBattlePosition"), nil, function(retval)
	if ticks % 120 == 0 or temp.summoned_medusa then 
		temp.summoned_medusa = nil
		return sdk.to_ptr(true) 
	end
	return retval
end)

sdk.hook(sdk.find_type_definition("app.Ch227"):get_method("update"), function(args)
	if is_battling and sm_summons[sdk.to_managed_object(args[2])._Chara] then 
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end)

sdk.hook(sdk.find_type_definition("app.actinter.Executor"):get_method("forceEndAction"), function(args)
	local chr = is_summoning and sdk.to_managed_object(args[2])._ActInter:get_Character()
	if chr and pre_fns[chr:get_AIBlackBoardController()] then 
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end, nil, true)

--Hitbox and damage-type related stuff is evaluated here
sdk.hook(sdk.find_type_definition("app.HitController"):get_method("getReactionDamageType(app.HitController.DamageInfo)"), 
	function(args)
		local hit_info = sdk.to_managed_object(args[3])
		hit = hit_info:get_AttackHitController()
		if hit == player:get_Hit() then temp.last_pl_hit_landed = game_time end
		local nstore = dmg_tbl[hit]
		
		if nstore then 
			nstore.last_hit = game_time
			local node_json = nstore.shell
			if not node_json then return end
			
			local is_shell = hit:get_CachedShell()
			if not is_shell and node_json.dmg_type_owner == #enums.dmgs then  --forced finishing moves
				local owner_chr = hit:get_CachedCharacter()
				local victim_chr = hit_info:get_DamageOwnerHitController():get_CachedCharacter()
				local owner_fsm = owner_chr:get_ActionManager().Fsm
				local owner_anode = owner_fsm:getLayer(0):get_tree_object():get_node_by_name(owner_fsm:getCurrentNodeName(0):match(".+%.(.+)"))
				local owner_actions = owner_anode:get_actions()[1] and owner_anode:get_actions() or owner_anode:get_unloaded_actions()
				local catch_act; for i, action in pairs(owner_actions) do if action.ActionDownPrevActionOtherDown then catch_act = action; break end end
				
				if catch_act then
					local dmg_react = victim_chr.DmgReaction
					dmg_react["<FinishedMoveBlowActived>k__BackingField"] = true
					
					pre_fns[dmg_react] = function()
						pre_fns[dmg_react] = nil
						local is_down = victim_chr:get_ActionManager().Fsm:getCurrentNodeName(0):find("[DL]own?")
						local fields = catch_act:get_type_definition():get_fields()
						local idx = math.random(1,9); while (not is_down and (idx == 3 or idx==9)) or fields[idx]:get_data(catch_act)=="" do idx = math.random(1,9) end
						local rand_catchname = fields[idx]:get_data(catch_act)
						local caught_action_name = is_down and "Caught_AttackDownWithAllStrength" or "Caught_AttackWithAllStrength"
						
						local catch_interp = sdk.create_instance("app.FinishAttackInterpolator"):add_ref()
						catch_interp:call("initialize(via.Transform, via.Transform, System.Int32)", owner_chr:get_Transform(), victim_chr:get_Transform(), 1)
						catch_interp:calcTargetTransform()
						
						local catch_setting = sdk.create_instance("app.CatchController.Setting"):add_ref()
						func.edit_obj(catch_setting, {
							CatchType = 1, 
							ParentJointName = "C_Prop_GroundA", 
							InterpolationFrame = 2.0,
							CatchStartAction = rand_catchname, 
							CaughtStartAction = caught_action_name, 
							CatchCancelAction = "DmgShrinkS",
							CaughtCancelAction = is_down and "DmgDownDamage" or "DmgShrinkS", 
							CaughtCancelActionForDead = "Caught_AttackWithAllStrength", 
							CaughtDieAction = caught_action_name, 
							CaughtDamageAction = caught_action_name,
						})
						owner_chr:get_CatchController():startCatch(victim_chr, catch_setting, catch_interp) --force finishing move
					end
				end
			elseif (node_json.dmg_type_owner > 1 or node_json.dmg_type_shell > 1) then
				local dmg_type = is_shell and node_json.dmg_type_shell-3 or node_json.dmg_type_owner-3
				hit_info.DamageType, hit_info.DamageActType, hit_info.OverwriteBlownType = dmg_type, dmg_type, dmg_type
				thread.get_hook_storage().retval = dmg_type
			end
		end
	end,
	function(retval)
		return thread.get_hook_storage().retval or retval
	end
)

sdk.hook(sdk.find_type_definition("app.CorpseController"):get_method("setCorpseStep"), function(args)
	if not is_summoning then return end
	local chr = sdk.to_managed_object(args[2]):get_Chara()
	local nstore = sm_summons[chr] or em_summons[chr]
	if nstore and nstore.corpse_lvl then
		args[3] = sdk.to_ptr(nstore.corpse_lvl)
	end
end)

sdk.hook(sdk.find_type_definition("app.Ch253001SubdueCtrl"):get_method("onAtkCalcDamageEnd"), function(args)
	if sm_summons[sdk.to_managed_object(args[2]).Ch253001._Chara] ~= nil then 
		return sdk.PreHookResult.SKIP_ORIGINAL --lets summoned sphinxes die
	end
end)

sdk.hook(sdk.find_type_definition("app.Shell"):get_method("requestOmenEffect"), 
	function(args)
		local hstore = thread.get_hook_storage()
		hstore.shell = sdk.to_managed_object(args[2])
		hstore.nstore = temp.omen_reqs[hstore.shell]
	end,
	function(retval)
		local hstore = thread.get_hook_storage() 
		if hstore.nstore then 
			temp.omen_reqs[hstore.shell] = nil
			change_efx2_color(hstore.shell["<EffectManager2>k__BackingField"], hstore.nstore)
		end
		return retval
	end
)

sdk.hook(sdk.find_type_definition("app.Ch229"):get_method("tryGetWarpPosition"), function(args)
	local chara = sdk.to_managed_object(args[2])._Chara
	local nstore = sm_summons[chara]
	if nstore and nstore.command_coords then 
		local coords = nstore.command_coords
		local pos = sdk.to_valuetype(args[3], "via.vec3")
		pos.x, pos.y, pos.z = coords.x, coords.y, coords.z
		args[3] = sdk.to_ptr(pos:get_address())
		local pos2 = sdk.to_valuetype(args[5], "via.vec3")
		local pl_pos = pl_xform:get_Position()
		pos2.x, pos2.y, pos2.z = coords.x + (pl_pos.x - pos2.x), coords.y + (pl_pos.y - pos2.y), coords.z + (pl_pos.z - pos2.z)
		args[5] = sdk.to_ptr(pos2:get_address())
	end
end)

sdk.hook(sdk.find_type_definition("app.FilterParamRadialBlur"):get_method("copyTo"), function(args)
	if is_casting then return sdk.PreHookResult.SKIP_ORIGINAL end --this shit is not even noticeable, blur is always lame and all it does is make colored shells turn into this nasty opaque blob on your screen
end)