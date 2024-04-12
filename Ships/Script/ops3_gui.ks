clearscreen.

RUNPATH("0:/Libraries/misc_library").	
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	

RUNPATH("0:/Shuttle_OPS3/landing_sites").

RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").

RUNPATH("0:/Shuttle_OPS3/src/sample_traj_data.ks").
RUNPATH("0:/Shuttle_OPS3/src/sample_taem_data.ks").

GLOBAL quit_program IS FALSE.

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().

//initialise touchdown points for all landing sites
define_td_points().


make_main_ops3_gui().


force_target_selection("Vandenberg").


make_taem_vsit_GUI().

local sample_data is sample_taem_data().
local sample_data_count is 500.

local herror is 0.

local mepflag is false.
ON (AG8) {
	set mepflag to (NOT mepflag).
	PRESERVE.
}
local stinflag is false.
ON (AG9) {
	set stinflag to (NOT stinflag).
	PRESERVE.
}

local guid_id is 21.

ON (ag7) {
	set guid_id to guid_id + 1.
	PRESERVE.
}


local horizslval is 0.
local sliderswitchflag is TRUE.

until false {

	if (ship:control:pilotpitch > 0) {
		set sample_data_count to sample_data_count + 2.
	} else if (ship:control:pilotpitch < 0) {
		set sample_data_count to max(0, sample_data_count - 2).
	}
	
	set herror to herror + (10 * ship:control:pilotroll).
	
	local rpred is sample_data[sample_data_count][0].
	local eow is sample_data[sample_data_count][1].
	
	local gui_data is lexicon(
							"guid_id", guid_id,
							"rpred",rpred,
							"eow",eow,
							"pred_rpred",rpred - 3000,
							"pred_eow",eow - 3000,
							"herror", herror,
							"ottstin", stinflag,
							"mep", mepflag,
							"tgthdot", -100,
							"tgtnz", 0.75,
							"xlfac", 1.8,
							"spdbkcmd", 0.25,
							"alpll", 2.5,
							"alpul", 16.5,
							"prog_pch", 8.3,
							"prog_roll", 34.3,
							"prog_yaw", 0.2
	).
	
	if (sliderswitchflag AND sample_data_count > 750) {
		make_xtrackerr_slider().
		set sliderswitchflag to FALSE.
	} else if ((NOT sliderswitchflag) and sample_data_count < 750) {
		make_time2hac_slider().
		set sliderswitchflag to TRUE.
	}
	
	set horizslval to horizslval + ship:control:pilotyaw * 0.05.
	
	if (guid_id >= 23) {
		gui_data:ADD("xtrack_err",  horizslval * 10).
	} else if (guid_id = 22) {
		gui_data:ADD("xtrack_err",  horizslval * 10).
	} else if (guid_id <= 21) {
		gui_data:ADD("hac_entry_t",  horizslval).
	}
	
	update_taem_vsit_disp(gui_data).
	
	print sample_data_count at (0, 1).
	print "rpred: " + rpred + " eow: " + eow + " herror:" + herror + "   "at (0, 2).
	
	print "guid_id : " + guid_id + "  " at (0,3).
	print "horizslval : " + round(horizslval, 1) + "  " at (0,4).
	
	local reset_guid is is_guid_reset().
	
	print "reset_guid : " + reset_guid + "  " at (0, 8).
	

	if (quit_program) {
		BREAK.
	}
	
}

clear_ops3_disp().

wait 1.

close_all_GUIs().