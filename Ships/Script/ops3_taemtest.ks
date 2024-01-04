CLEARSCREEN.


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

RUNPATH("0:/Shuttle_OPS3/src/taem_guid.ks").

GLOBAL quit_program IS FALSE.

//initialise touchdown points for all landing sites
define_td_points().

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().

//after the td points but before anything that modifies the default button selections
make_main_ops3_gui().
make_hud_gui().

ops3_taem_test().



close_all_GUIs().




FUNCTION ops3_taem_test {
    SET CONFIG:IPU TO 1800. 
	
	make_taem_vsit_GUI().
    
    
    LOCAL dap IS dap_controller_factory().
    
    dap:set_taem_hdot_gains().
    
    LOCAL aerosurfaces_control IS aerosurfaces_control_factory().
    aerosurfaces_control["set_aoa_feedback"](50).

    
    //dap:reset_steering().
	//LOCK STEERING TO dap:steering_dir.
	
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
    

	GLOBAL hud_datalex IS get_hud_datalex().
    
    GLOBAL guid_id IS 0.
    
    local control_loop is loop_executor_factory(
        constants["control_loop_dt"],
        {
			IF (ADDONS:FAR:MACH < constants["mach_rcs_off"]) {
				RCS OFF.
			} else {
				RCS ON.
			}
			
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
	
	local guidance_timer IS timer_factory().
	
    until false{
        clearvecdraws().
		
		guidance_timer:update().
        
        if (quit_program) {
            break.
        }
        
        local rwystate is get_runway_rel_state(
            -SHIP:ORBIT:BODY:POSITION,
            SHIP:VELOCITY:SURFACE,
            tgtrwy
        ).
		
		if (is_guid_reset()) {
			taemg_reset().
		}
        
        local taemg_in is LEXICON(
                                            "dtg", guidance_timer:last_dt,
                                            "wow", dap:wow,
                                            "h", rwystate["h"],
                                            "hdot", rwystate["hdot"],
                                            "x", rwystate["x"], 
                                            "y", rwystate["y"], 
                                            "surfv", rwystate["surfv"],
                                            "surfv_h", rwystate["surfv_h"],
                                            "xdot", rwystate["xdot"], 
                                            "ydot", rwystate["ydot"], 
                                            "psd", rwystate["rwy_rel_crs"], 
											"m", SHIP:MASS,
                                            "mach",  ADDONS:FAR:MACH,
                                            "qbar", SHIP:Q,
                                            "phi",  dap:lvlh_roll,
                                            "theta", dap:lvlh_pitch,
                                            "gamma", dap:fpa,
											"alpha", dap:prog_pitch,
											"nz", dap:aero:nz,
                                            "ovhd", tgtrwy["overhead"],
                                            "rwid", tgtrwy["name"],
											"grtls", FALSE,
											"debug", TRUE
                                    ).
        
        //call taem guidance here
        local taemg_out is taemg_wrapper(
                                        taemg_in                        
        ).
        
		set guid_id to taemg_out["guid_id"].
		
		IF (is_autoairbk()) {
			SET aerosurfaces_control:spdbk_defl TO taemg_out["dsbc_at"].
		}
		
		SET dap:pitch_lims to LIST(taemg_out["alpll"], taemg_out["alpul"]).
		SET dap:roll_lims to LIST(-taemg_out["philim"], taemg_out["philim"]).
		IF (dap_engaged) AND (NOT is_dap_css()) {
			SET dap:tgt_roll tO taemg_out["phic_at"].
			SET dap:tgt_yaw tO taemg_out["betac_at"].
			
			if (guid_id = 26) OR (guid_id = 24) {
				SET dap:tgt_pitch tO taemg_out["alpcmd"].
			} else if (guid_id = 25) {
				SET dap:tgt_nz tO taemg_out["nztotal"].
			} else {
				SET dap:tgt_hdot tO taemg_out["hdrefc"].
			}
		}
		
		if (guid_id <= 21) and taemg_internal["freezetgt"] {
			freeze_target_site().
		}
		
		if (guid_id <= 21) and taemg_internal["freezeapch"] {
			freeze_apch().
		}

        if (NOT GEAR) and (taemg_out["geardown"]) {
            GEAR ON.
        }
        
        if (NOT BRAKES) and (taemg_out["brakeson"]) {
            BRAKES ON.
        }

        if (taemg_out["itran"]) {
            dap:reset_steering().
        }

		//gui outputs
		
		if (guid_id = 26) OR (guid_id = 24) {
			SET hud_datalex["pipper_deltas"] TO LIST(
													taemg_out["phic_at"] - dap:prog_roll, 
													taemg_out["alpcmd"] -  dap:prog_pitch

			).
		} else if (guid_id = 25) {
			SET hud_datalex["pipper_deltas"] TO LIST(
													taemg_out["phic_at"] - dap:prog_roll, 
													taemg_out["nztotal"] -  dap:aero:nz

			).
		} else {
			SET hud_datalex["pipper_deltas"] TO LIST(
													taemg_out["phic_at"] - dap:prog_roll, 
													taemg_out["hdrefc"] -  rwystate["hdot"]

			).
		}
		
		if (taemg_out["itran"]) {
            hud_decluttering(guid_id).
		}

		SET hud_datalex["phase"] TO guid_id.
		
		SET hud_datalex["altitude"] TO rwystate["h"].
		SET hud_datalex["hdot"] TO rwystate["hdot"].
		SET hud_datalex["distance"] TO taemg_out["rpred"] / 1000.
		SET hud_datalex["cur_nz"] TO dap:aero:nz.
		SET hud_datalex["cur_pch"] TO dap:lvlh_pitch.
		SET hud_datalex["cur_roll"] TO dap:lvlh_roll.
		SET hud_datalex["flapval"] TO aerosurfaces_control["flap_defl"].
		SET hud_datalex["spdbk_val"] TO aerosurfaces_control["spdbk_defl"].

		if (guid_id >= 23) {
			set hud_datalex["delaz"] to - rwystate["rwy_rel_crs"].
		} else if (guid_id = 22) {
            set hud_datalex["delaz"] to taemg_out["ysgn"] * taemg_out["psha"].
        } else if (guid_id <= 21) {
            set hud_datalex["delaz"] to taemg_out["dpsac"].
        }
        
        update_hud_gui(hud_datalex).
		
		local gui_data is lexicon(
								"rpred",taemg_out["rpred"],
								"eow",taemg_out["eow"],
								"herror", taemg_out["herror"],
								"ottstin", taemg_out["ohalrt"],
								"mep", taemg_out["mep"],
								"tgthdot", taemg_out["hdref"],
								"tgtnz", dap:tgt_nz,
								"spdbkcmd", taemg_out["dsbc_at"],
								"alpll", taemg_out["alpll"],
								"alpul", taemg_out["alpul"],
								"prog_pch", dap:prog_pitch,
								"prog_roll", dap:prog_roll,
								"prog_yaw", dap:prog_yaw
		).
		update_taem_vsit_disp(gui_data).
		
		//debug
		dap:print_debug(2).
		
		if is_log() {
			SET loglex["guid_id"] TO guid_id.
			SET loglex["loop_dt"] TO guidance_timer:last_dt.
			SET loglex["rwy_alt"] TO taemg_in["h"].
			SET loglex["vel"] TO SHIP:VELOCITY:ORBIT.
			SET loglex["surfv"] TO taemg_in["surfv"]. 
			SET loglex["mach"] TO taemg_in["mach"]. 
			SET loglex["hdot"] TO taemg_in["hdot"].
			SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
			SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
			SET loglex["range"] TO hud_datalex["distance"].
			SET loglex["delaz"] TO hud_datalex["delaz"].
			SET loglex["nz"] TO dap:aero:nz.
			SET loglex["drag"] TO dap:aero:drag.
			SET loglex["eow"] TO taemg_out["eow"]
			SET loglex["prog_pch"] TO dap:prog_pitch.
			SET loglex["prog_roll"] TO dap:prog_roll. 
			SET loglex["prog_yaw"] TO dap:prog_yaw.
			SET loglex["flap_defl"] TO aerosurfaces_control["flap_defl"].
			SET loglex["spdbk_defl"] TO aerosurfaces_control["spdbk_defl"].
			
			log_data(loglex,"0:/Shuttle_OPS3/LOGS/ops3_log").
		}
		
		if (taemg_out["al_end"] = TRUE) {
			set quit_program to TRUE.
		}
        
        WAIT constants["taem_loop_dt"].
    }
    
    
    control_loop:stop_execution().
    clearscreen.
}