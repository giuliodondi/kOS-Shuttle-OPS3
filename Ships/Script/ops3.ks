CLEARSCREEN.
SET CONFIG:IPU TO 1800. 


RUNPATH("0:/Libraries/misc_library").   
RUNPATH("0:/Libraries/maths_library").  
RUNPATH("0:/Libraries/navigation_library"). 
RUNPATH("0:/Libraries/aerosim_library").    

RUNPATH("0:/Shuttle_OPS3/landing_sites").
RUNPATH("0:/Shuttle_OPS3/constants").

RUNPATH("0:/Shuttle_OPS3/src/ops3_entry_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").

RUNPATH("0:/Shuttle_OPS3/src/entry_guid.ks").
RUNPATH("0:/Shuttle_OPS3/src/taem_guid.ks").

GLOBAL quit_program IS FALSE.

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().

//initialise touchdown points for all landing sites
define_td_points().


//setup main gui and hud 
//after the td points but before anything that modifies the default button selections
make_main_ops3_gui().
make_hud_gui().


//setup dap and aerosurface controllers

LOCAL dap IS dap_controller_factory().
LOCAL aerosurfaces_control IS aerosurfaces_control_factory().

LOCAL dap_engaged Is is_dap_engaged().
ON (dap_engaged) {
	if (dap_engaged) {
		dap:reset_steering().
		LOCK STEERING TO dap:steering_dir.
		SAS OFF.
	} else {
		UNLOCK STEERING.
		SAS ON.
	}
	preserve.
}

//main control loop
local control_loop is loop_executor_factory(
        0.1,
        {
			set dap_engaged to is_dap_engaged().
			if (dap_engaged) {
				local css_flag is is_dap_css().
				if (guid_id < 20) OR (guid_id = 26) OR (guid_id = 24) {
					//reentry, alpha recovery, alpha transition
					if (css_flag) {
						dap:update_css_prograde().
					} else {
						dap:update_auto_prograde().
					}
				} else {
					if (css_flag) {
						local direct_pitch_flag is (guid_id >= 34).
						dap:update_css_lvlh(direct_pitch_flag).
					} else {
						 if (guid_id = 25) {
							//nz hold
							dap:update_auto_nz().
						} else {
							//hdot control
							if (guid_id >= 35) {
								dap:set_landing_hdot_gains().
							} else {
								dap:set_taem_hdot_gains().
							}
							
							dap:update_auto_hdot().
						}
					}
					//lock flaps after touchdown or during flare
					if (dap:wow) {
						set aerosurfaces_control:flap_engaged to FALSE.
					}
				}
			} else {
				dap:measure_cur_state().
			}
            aerosurfaces_control:update(is_autoflap(), is_autoairbk()).
        }
).

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().





make_taem_vsit_GUI().








aerosurfaces_control["set_aoa_feedback"](50).