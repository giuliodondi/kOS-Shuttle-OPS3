CLEARSCREEN.
SET CONFIG:IPU TO 1800. 

RUNPATH("0:/Shuttle_OPS3/constants").

//hard-coded check to run the script only in atmosphere
If (SHIP:ALTITUDE >= constants["interfalt"]) {
	PRINT "Not yet below Entry Interface (122km),  aborting." .
	return.
}


RUNPATH("0:/Libraries/misc_library").   
RUNPATH("0:/Libraries/maths_library").  
RUNPATH("0:/Libraries/navigation_library"). 
RUNPATH("0:/Libraries/aerosim_library").    

RUNPATH("0:/Shuttle_OPS3/landing_sites").

RUNPATH("0:/Shuttle_OPS3/src/ops3_entry_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").

RUNPATH("0:/Shuttle_OPS3/src/entry_guid.ks").
RUNPATH("0:/Shuttle_OPS3/src/taem_guid.ks").

GLOBAL quit_program IS FALSE.

//main guidance phase counter
GLOBAL guid_id IS 0.

//did we come from an RTLS abort? 
LOCAL grtls_flag IS (DEFINED grtls_skip_to_TAEM).
//tal abort flag 
LOCAL tal_flag IS (DEFINED tal_abort).

//initialise touchdown points for all landing sites
define_td_points().

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().

//setup main gui and hud 
//after the td points but before anything that modifies the default button selections
make_main_ops3_gui().
make_hud_gui().
local hud_datalex IS get_hud_datalex().

//setup dap and aerosurface controllers

LOCAL dap IS dap_controller_factory().
LOCAL aerosurfaces_control IS aerosurfaces_control_factory().

LOCAL dap_engaged Is is_dap_engaged().
local css_flag is is_dap_css().
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
				set css_flag to is_dap_css().
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

local guidance_timer IS timer_factory().

if (NOT grtls_flag) {
	//entry guidance loop
	
	LOCAL eg_exit_flag IS FALSE.
	
	local initial_roll IS 
	
	UNTIL (quit_program or eg_exit_flag) {
		clearvecdraws().
		
		guidance_timer:update().
		
		local ve is SHIP:VELOCITY:SURFACE.
		local vi is SHIP:VELOCITY:ORBIT.
		
		local entry_state IS get_reentry_state(
			-SHIP:ORBIT:BODY:POSITION,
			SHIP:GEOPOSITION,
            ve,
            tgtrwy,
			LIST(dap:prog_pitch, dap:prog_roll)
		).
		
		if (is_guid_reset()) {
			entryg_reset().
		}

		//call entry guidance here
		LOCAL entryg_out is entryg_wrapper(
									lexicon(
											"iteration_dt", guidance_timer:last_dt,
											"tgtsite", ,
											"tgt_range", entry_state["tgt_range"],
											"delaz", entry_state["delaz"],   
											"ve", ve:MAG,
											"vi", vi:MAG,
											"hls", entry_state["hls"],	
											"hdot", entry_state["hdot"],  
											"alpha", dap:prog_pitch,      
											"roll", dap:prog_roll,  
											"drag", entry_state["drag"],
											"xlfac", entry_state["xlfac"],     	
											"lod", entry_state["lod"],
											"egflg", 0, 
											"ital", tal_flag,
											"debug", TRUE
									)
		).
		
		set eg_exit_flag to entryg_out["eg_end"].
		
		set guid_id to entryg_out["guid_id"].
		
		IF (is_autoairbk()) {
			SET aerosurfaces_control:spdbk_defl TO entryg_out["spdbcmd"].
		}
		
		SET dap:pitch_lims to LIST(entryg_out["aclim"], entryg_out["aclam"]).
		SET dap:roll_lims to LIST(-entryg_out["rlm"], entryg_out["rlm"]).
		IF (dap_engaged) AND (NOT css_flag) {
			SET dap:tgt_pitch tO entryg_out["alpcmd"].
			SET dap:tgt_roll tO entryg_out["rolcmd"].
			SET dap:tgt_yaw tO 0.
		}
		
		
		//gui outputs
		SET hud_datalex["phase"] TO guid_id.
		SET hud_datalex["altitude"] TO entry_state["hls"].
		SET hud_datalex["hdot"] TO entry_state["hdot"].
		SET hud_datalex["distance"] TO entry_state["tgt_range"].
		set hud_datalex["delaz"] to entry_state["delaz"].
		SET hud_datalex["cur_nz"] TO dap:nz.
		SET hud_datalex["cur_pch"] TO dap:lvlh_pitch.
		SET hud_datalex["cur_roll"] TO dap:lvlh_roll.
		SET hud_datalex["flapval"] TO aerosurfaces_control["flap_defl"].
		SET hud_datalex["spdbk_val"] TO aerosurfaces_control["spdbk_defl"].
		
		SET hud_datalex["pipper_deltas"] TO LIST(
												entryg_out["rolcmd"] - dap:prog_roll, 
												entryg_out["alpcmd"] -  dap:prog_pitch
		).
        
        update_hud_gui(hud_datalex).
		
		local gui_data is lexicon(
								"iter", step_c,
								"range",entry_state["tgt_range"],
								"vi",vi:MAG,
								"xlfac",entry_state["xlfac"],
								"lod",entry_state["lod"],
								"drag",entry_state["drag"],
								"drag_ref",entryg_out["drag_ref"],
								"phase",entryg_out["islect"],
								"hdot_ref",entryg_out["hdot_ref"],
								"pitch",pitch_prof,
								"roll",roll_prof,
								"roll_ref",entryg_out["roll_ref"],
								"pitch_mod",entryg_out["pitch_mod"],
								"roll_rev",entryg_out["roll_rev"]
		).
		update_entry_traj_disp(gui_data).
		
	}

}


guidance_timer:reset().


make_taem_vsit_GUI().








aerosurfaces_control["set_aoa_feedback"](50).