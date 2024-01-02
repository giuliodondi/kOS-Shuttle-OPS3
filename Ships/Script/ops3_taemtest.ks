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

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().

//initialise touchdown points for all landing sites
define_td_points().

//after the td points but before anything that modifies the default button selections
make_main_ops3_gui().
make_taem_vsit_GUI().
make_hud_gui().

ops3_taem_test().



close_all_GUIs().




FUNCTION ops3_taem_test {
    SET CONFIG:IPU TO 1800. 
    
    
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
			}
            aerosurfaces_control:update(is_autoflap(), is_autoairbk()).
        }
    ).
    
	local debug_flag is true.
    LOCAL last_iter Is TIMe:SECONDS.
    until false{
        clearvecdraws().
        
        if (quit_program) {
            break.
        }
        
        local rwystate is get_runway_rel_state(
            -SHIP:ORBIT:BODY:POSITION,
            SHIP:VELOCITY:SURFACE,
            tgtrwy
        ).
		
		LOCAL cur_iter IS TIMe:SECONDS.
		local guid_loop_dt is cur_iter - last_iter.
		SET last_iter TO cur_iter.
        
        local taemg_in is LEXICON(
                                            "dtg", guid_loop_dt,
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
											"nz", dap:nz,
                                            "ovhd", tgtrwy["overhead"],
                                            "rwid", tgtrwy["name"],
											"grtls", FALSE,
											"debug", debug_flag
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


        IF (RCS) and (ADDONS:FAR:MACH < 0.9) {
            RCS OFF.
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
													taemg_out["nztotal"] -  dap:nz

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
		SET hud_datalex["cur_nz"] TO dap:nz.
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
        
		if (debug_flag) {
		
			build_taemg_guid_points(taemg_out, tgtrwy).
        
			//GLOBAL loglex IS LEXICON(
			//                  "iphase",1,
			//                  "time",0,
			//                  "alt",0,
			//                  "speed",0,
			//                  "mach",0,
			//                  "hdot",0,
			//                  "lat",0,
			//                  "long",0,
			//                  "psd", 0,
			//                  
			//                  "x",0,
			//                  "y",0,
			//                  
			//                  "rpred", 0,
			//                  "herror", 0,
			//                  "psha", 0,
			//                  "dpsac", 0,
			//                  
			//                  "nzc", 0,
			//                  "nztotal", 0,
			//                  "phic_at", 0,
			//                  "dsbc_at", 0,
			//                  
			//                  "eow",0,
			//                  "es",0,
			//                  "en",0,
			//                  "emep",0
			//).
			//
			//SET loglex["iphase"] TO taemg_out["iphase"].
			//SET loglex["time"] TO TIME:SECONDS.
			//SET loglex["alt"] TO taemg_in["h"].
			//SET loglex["speed"] TO taemg_in["surfv"]. 
			//SET loglex["mach"] TO taemg_in["mach"]. 
			//SET loglex["hdot"] TO taemg_in["hdot"].
			//SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
			//SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
			//SET loglex["psd"] TO taemg_in["psd"].
			//
			//SET loglex["x"] TO taemg_in["x"].
			//SET loglex["y"] TO taemg_in["y"].
			//
			//SET loglex["rpred"] TO taemg_out["rpred"].
			//SET loglex["herror"] TO taemg_out["herror"].
			//SET loglex["hdref"] TO taemg_out["hdref"].
			//SET loglex["psha"] TO taemg_out["psha"].
			//SET loglex["dpsac"] TO taemg_out["dpsac"].
			//
			//SET loglex["dnzc"] TO taemg_out["dnzc"].
			//SET loglex["nzc"] TO taemg_out["nzc"].
			//SET loglex["nztotal"] TO taemg_out["nztotal"].
			//SET loglex["phic_at"] TO taemg_out["phic_at"].
			//SET loglex["dsbc_at"] TO taemg_out["dsbc_at"].
			//
			//SET loglex["eow"] TO taemg_out["eow"].
			//SET loglex["es"] TO taemg_out["es"].
			//SET loglex["en"] TO taemg_out["en"].
			//SET loglex["emep"] TO taemg_out["emep"].
			//
			//log_data(loglex,"0:/Shuttle_OPS3/LOGS/taem_log", TRUE).
        
			dap:print_debug(2).
		}
		
		if (taemg_out["al_end"] = TRUE) {
			set quit_program to TRUE.
		}
        
        WAIt 0.
    }
    
    
    control_loop:stop_execution().
    clearscreen.
}