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

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().

//initialise touchdown points for all landing sites
define_td_points().


make_main_ops3_gui().



make_entry_traj_GUI().

local sample_data is sample_traj_data().
local sample_data_count is 0.


until false {

	if (ship:control:pilotpitch > 0) {
		set sample_data_count to sample_data_count + 2.
	} else if (ship:control:pilotpitch < 0) {
		set sample_data_count to max(0, sample_data_count - 2).
	}
	
	
	
	print sample_data_count at (0, 1).
	

	if (quit_program) {
		BREAK.
	}
	
	wait 0.01.
}

clear_ops3_disp().

wait 1.

close_all_GUIs().