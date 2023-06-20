clearscreen.

RUNPATH("0:/Libraries/misc_library").	
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	

RUNPATH("0:/Shuttle_OPS3/landing_sites").
RUNPATH("0:/Shuttle_OPS3/constants").

RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").

RUNPATH("0:/Shuttle_OPS3/src/sample_traj_data.ks").

GLOBAL quit_program IS FALSE.

//initialise touchdown points for all landing sites
define_td_points().

make_main_GUI().

//ths lexicon contains all the necessary guidance objects 
IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS refresh_runway_lex(ldgsiteslex[select_tgt:VALUE]).




make_entry_traj_GUI().

local sample_data is sample_traj_data().
local sample_data_count is 0.


until false {

	if (ship:control:pilotpitch > 0) {
		set sample_data_count to sample_data_count + 2.
	} else if (ship:control:pilotpitch < 0) {
		set sample_data_count to max(0, sample_data_count - 2).
	}
	
	local rng_ is sample_data[sample_data_count][1].
	local vel_ is sample_data[sample_data_count][0].
	

	update_traj_disp(rng_, vel_).
	
	print sample_data_count at (0, 1).
	print "rng: " + rng_ + " vel: " + vel_ at (0, 2).
	

	if (quit_program) {
		BREAK.
	}
	
	wait 0.01.
}

close_all_GUIs().