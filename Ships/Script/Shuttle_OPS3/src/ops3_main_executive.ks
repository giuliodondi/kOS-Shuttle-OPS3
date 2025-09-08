
//			MAIN EXECUTIVE OF OPS3 REENTRY, TAEM AND LANDING
FUNCTION ops3_main_exec {
	parameter nominal_flag.
	parameter tal_flag.
	parameter grtls_flag.
	parameter cont_flag.
	parameter ecal_flag.
	parameter force_tgt_select is "".
	
	clearscreen.
	SAS ON.
	
	GLOBAL quit_program IS FALSE.

	//main guidance phase counter
	GLOBAL guid_id IS 0.

	//initialise touchdown points for all landing sites
	define_td_points().
	IF (DEFINED tgtrwy) {UNSET tgtrwy.}
	GLOBAL tgtrwy IS LEXICON().
	
	//setup main gui and hud 
	//after the td points but before anything that modifies the default button selections
	make_main_ops3_gui().
	make_hud_gui().
	
	local eng_off_f is false.
	if (nominal_flag) {
		engines_off().
		set eng_off_f to true.
	}
	
	//force target selection logic goes here
	if (not nominal_flag) and (force_tgt_select <> "") {
		force_target_selection(force_tgt_select, FALSE).
	}
	
	local skip_2_taem_flag is false.
	
	//if skip to taem select first target ahead 
	if (SHIP:VELOCITY:SURFACE:MAG < ops3_parameters["surfv_skip_to_taem"]) {
		set skip_2_taem_flag to true.
		
		local closest_site is get_closest_site(ldgsiteslex)[0].
		
		force_target_selection(closest_site,FALSE,TRUE).
	}
	
	local hud_datalex IS get_hud_datalex().
	
	local guidance_timer IS timer_factory().
	//necessary so the timer updates once 
	wait 0.1.
	
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
			ops3_parameters["control_loop_dt"],
			{
				IF (ADDONS:FAR:MACH < ops3_parameters["mach_rcs_off"]) and (not grtls_flag) {
					RCS OFF.
				} else {
					RCS ON.
				}
				
				//oms dump timer 
				if (not eng_off_f) {
					if (guidance_timer:elapsed >= ops3_parameters["oms_dump_timer"]) {
						engines_off().
						set eng_off_f to true.
					}
				}
				
				set dap_engaged to is_dap_engaged().
				if (dap_engaged) {
					set css_flag to is_dap_css().
					if (guid_id < 20) OR (guid_id = 26) OR (guid_id = 24) OR (guid_id = 27) OR (guid_id = 36) {
						aerosurfaces_control["set_aoa_feedback"](ops3_parameters["entry_aoa_feedback"]).
						//reentry, alpha recovery, alpha transition, slapdown/rollout
						if (css_flag) {
							dap:update_css_prograde().
						} else {
							dap:update_auto_prograde().
						}
					} else {
						aerosurfaces_control["set_aoa_feedback"](ops3_parameters["taem_aoa_feedback"]).
						
						if (css_flag) {
							local direct_pitch_flag is (guid_id >= 34).
							dap:update_css_lvlh(direct_pitch_flag).
						} else {
							 if (guid_id = 25) {
								//nz hold
								dap:set_grtls_gains().
								dap:update_auto_nz().
							} else {
								//hdot control
								if (guid_id >= 34) {
									dap:set_flare_gains().
								} else {
									dap:set_taem_gains().
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
				
				if (SHIP:ALTITUDE <= ops3_parameters["alt_trim_on"]) OR (dap:aero:load:latest_value >= ops3_parameters["xlfac_trim_on"]) {
					aerosurfaces_control:update(is_autoflap(), is_autoairbk()).
				}
				
				if (guid_id < 20) OR (guid_id = 26) OR (guid_id = 24) OR (guid_id = 27) OR (guid_id = 36) {
					SET hud_datalex["pipper_deltas"] TO LIST(
															dap:tgt_roll - dap:prog_roll, 
															dap:tgt_pitch -  dap:prog_pitch

					).
				} else if (guid_id = 25) {
					SET hud_datalex["pipper_deltas"] TO LIST(
															dap:tgt_roll - dap:prog_roll, 
															dap:tgt_nz -  dap:aero:nz

					).
				} else {
					SET hud_datalex["pipper_deltas"] TO LIST(
															dap:tgt_roll - dap:prog_roll, 
															dap:tgt_hdot -  dap:hdot

					).
				}
				
				SET hud_datalex["cur_nz"] TO dap:aero:nz.
				SET hud_datalex["cur_pch"] TO dap:prog_pitch.
				SET hud_datalex["cur_roll"] TO dap:prog_roll.
				
				update_hud_gui(hud_datalex).
			}
	).

	if (NOT (grtls_flag OR cont_flag)) AND (NOT skip_2_taem_flag) {
		//entry guidance loop
		
		make_entry_traj_GUI().
		
		LOCAL eg_end_flag IS FALSE.
		
		local entry_state is blank_reentry_state().
		
		UNTIL (quit_program OR eg_end_flag) {
			clearvecdraws().
			
			guidance_timer:update().
			
			local ve is SHIP:VELOCITY:SURFACE.
			local vi is SHIP:VELOCITY:ORBIT.
			
			set entry_state to get_reentry_state(
				-SHIP:ORBIT:BODY:POSITION,
				SHIP:GEOPOSITION,
				ve,
				tgtrwy,
				entry_state
			).
			
			if (is_guid_reset()) {
				entryg_reset().
			}

			//call entry guidance here
			local entryg_in is lexicon(
									"iteration_dt", guidance_timer:last_dt,
									"tgtsite", get_selected_tgt(),
									"tgt_range", entry_state["tgt_range"],
									"delaz", entry_state["delaz"],   
									"ve", ve:MAG,
									"vi", vi:MAG,
									"hls", entry_state["hls"],	
									"hdot", entry_state["hdot"], 
									"gamma", entry_state["fpa"], 							
									"alpha", dap:prog_pitch,      
									"roll", dap:prog_roll,  
									"drag", dap:aero:drag:average(),
									"xlfac", dap:aero:load:average(),  
									"cd", ADDONS:FAR:CD,												
									"lod", dap:aero:lod:average(),
									"egflg", 0, 
									"ital", tal_flag,
									"css", css_flag,
									"debug", ops3_parameters["full_debug"]
			).
			LOCAL entryg_out is entryg_wrapper(entryg_in).
			
			set guid_id to entryg_out["guid_id"].
			
			IF (is_autoairbk()) {
				SET aerosurfaces_control:spdbk_defl TO entryg_out["spdbcmd"].
			}
			
			SET dap:pitch_lims to LIST(entryg_out["aclim"], entryg_out["aclam"]).
			SET dap:roll_lims to LIST(-entryg_out["rlm"], entryg_out["rlm"]).
			
			if (entryg_out["eg_conv"]) {
				SET dap:tgt_pitch tO entryg_out["alpcmd"].
				SET dap:tgt_roll tO entryg_out["rolcmd"].
			}
			SET dap:tgt_yaw tO 0.
			
			//gui outputs
			SET hud_datalex["phase"] TO guid_id.
			SET hud_datalex["altitude"] TO entry_state["hls"].
			SET hud_datalex["hdot"] TO entry_state["hdot"].
			SET hud_datalex["distance"] TO entry_state["tgt_range"].
			set hud_datalex["delaz"] to entry_state["delaz"].
			
			SET hud_datalex["flapval"] TO aerosurfaces_control["flap_defl"].
			SET hud_datalex["spdbk_val"] TO aerosurfaces_control["spdbk_defl"].
			
			
			
			local gui_data is lexicon(
									"time", guidance_timer:last_sampled_t,
									"range",entry_state["tgt_range"],
									"ve",ve:MAG,
									"xlfac",entryg_in["xlfac"] / entryg_constants["gs"],
									"lod",entryg_in["lod"],
									"drag",entryg_in["drag"],
									"drag_ref",entryg_out["drag_ref"],
									"phase",entryg_out["islect"],
									"hdot", entry_state["hdot"],
									"hddot", entry_state["hddot"],
									"hdot_ref",entryg_out["hdot_ref"],
									"pitch_cmd",entryg_out["alpcmd"],
									"roll_cmd",entryg_out["rolcmd"],
									"roll_ref",entryg_out["roll_ref"],
									"pitch_mod",entryg_out["pitch_mod"],
									"roll_rev",entryg_out["roll_rev"],
									"ileflg", entryg_out["ileflg"],
									"prog_pch", dap:prog_pitch,
									"prog_roll", dap:prog_roll,
									"prog_yaw", dap:prog_yaw
			).
			update_entry_traj_disp(gui_data).
			
			if (ops3_parameters["dap_debug"]) {
				dap:print_debug(2).
			}
			
			if is_log() {
				SET loglex["guid_id"] TO guid_id.
				SET loglex["loop_dt"] TO guidance_timer:last_dt.
				SET loglex["rwy_alt"] TO entry_state["hls"].
				SET loglex["vel"] TO vi:MAG.
				SET loglex["surfv"] TO ve:MAG. 
				SET loglex["mach"] TO ADDONS:FAR:MACH. 
				SET loglex["hdot"] TO entry_state["hdot"].
				SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
				SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
				SET loglex["range"] TO hud_datalex["distance"].
				SET loglex["delaz"] TO hud_datalex["delaz"].
				SET loglex["nz"] TO dap:aero:nz.
				SET loglex["drag"] TO entryg_in["drag"].
				SET loglex["eow"] TO entryg_out["eowd"].
				SET loglex["prog_pch"] TO dap:prog_pitch.
				SET loglex["prog_roll"] TO dap:prog_roll. 
				SET loglex["prog_yaw"] TO dap:prog_yaw.
				SET loglex["flap_defl"] TO aerosurfaces_control["flap_defl"].
				SET loglex["spdbk_defl"] TO aerosurfaces_control["spdbk_defl"].
				
				log_data(loglex,"0:/Shuttle_OPS3/LOGS/ops3_log").
			}
			
			if (entryg_out["eg_end"] = TRUE) {
				set eg_end_flag to TRUE.
			}
			
			WAIT ops3_parameters["entry_loop_dt"].
		}
		
		clear_ops3_disp().
	}

	if (NOT quit_program) {
		//TAEM and A/L loop

		make_taem_vsit_GUI().
		
		if (grtls_flag) or (cont_flag) {
			set_dap_auto().
		}
		
		LOCAL al_end_flag Is FALSE.
		
		until (quit_program OR al_end_flag) {
			clearvecdraws().
			
			guidance_timer:update().
		
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
									"rwy_r", rwystate["rwy_r"], 
									"rwy_rdot", rwystate["rwy_rdot"], 
									"xdot", rwystate["xdot"], 
									"ydot", rwystate["ydot"], 
									"psd", rwystate["rwy_rel_crs"], 
									"m", SHIP:MASS,
									"mach",  ADDONS:FAR:MACH,
									"qbar", SHIP:Q,
									"phi",  dap:prog_roll,
									"theta", dap:lvlh_pitch,
									"gamma", dap:fpa,
									"alpha", dap:prog_pitch,
									"nz", dap:aero:nz,
									"drag", dap:aero:drag:average(),
									"xlfac", dap:aero:load:average(), 
									"ovhd", tgtrwy["overhead"],
									"rwid", tgtrwy["name"],
									"grtls", grtls_flag,
									"cont", cont_flag,
									"ecal", ecal_flag,
									"debug", ops3_parameters["full_debug"]
			).

			//call taem guidance here
			local taemg_out is taemg_wrapper(taemg_in).
			
			set guid_id to taemg_out["guid_id"].
			set grtls_flag to taemg_out["grtls_flag"].
			set cont_flag to taemg_out["cont_flag"].
			set ecal_flag to taemg_out["ecal_flag"].
			
			IF (is_autoairbk()) {
				SET aerosurfaces_control:spdbk_defl TO taemg_out["dsbc_at"].
			}
			
			SET dap:pitch_lims to LIST(taemg_out["alpll"], taemg_out["alpul"]).
			SET dap:roll_lims to LIST(-taemg_out["philim"], taemg_out["philim"]).

			SET dap:tgt_roll tO taemg_out["phic_at"].
			SET dap:tgt_yaw tO taemg_out["betac_at"].
			
			if (guid_id = 26) OR (guid_id = 24) OR (guid_id = 27) OR (guid_id = 36) {
				SET dap:tgt_pitch tO taemg_out["alpcmd"].
			} else if (guid_id = 25) {
				SET dap:tgt_nz tO taemg_out["nztotal"].
			} else {
				SET dap:tgt_hdot tO taemg_out["hdrefc"].
			}

			
			if (guid_id <= 21) and taemg_internal["freezetgt"] {
				freeze_target_site().
			}
			
			if (guid_id <= 21) and taemg_internal["freezeapch"] {
				freeze_apch().
			}
			
			if (taemg_internal["al_resetpids"]) {
				dap:reset_steering().
			}

			if (NOT GEAR) and (taemg_out["geardown"]) {
				GEAR ON.
			}
			
			if (NOT BRAKES) and (taemg_out["brakeson"]) {
				BRAKES ON.
			}
			
			IF (dap_engaged) and (taemg_out["dapoff"]) {
				disengage_dap().
			}

			if (taemg_out["itran"]) {
				dap:reset_steering().
			}

			//gui outputs
			
			if (taemg_out["itran"]) {
				hud_decluttering(guid_id).
				if (guid_id = 22) {
					make_xtrackerr_slider().
				}
			}

			SET hud_datalex["phase"] TO guid_id.
			
			SET hud_datalex["altitude"] TO rwystate["h"].
			SET hud_datalex["hdot"] TO rwystate["hdot"].
			SET hud_datalex["distance"] TO taemg_out["rpred"] / 1000.
			SET hud_datalex["flapval"] TO aerosurfaces_control["flap_defl"].
			SET hud_datalex["spdbk_val"] TO aerosurfaces_control["spdbk_defl"].
			
			local gui_data is lexicon(
									"guid_id", guid_id,
									"rpred",taemg_out["rpred"],
									"eow",taemg_out["eow"],
									"herror", taemg_out["herror"],
									"ottstin", taemg_out["ohalrt"],
									"mep", taemg_out["mep"],
									"eowlof", taemg_out["eowlof"],
									"tgthdot", taemg_out["hdref"],
									"xlfac", taemg_in["xlfac"] / taemg_constants["g"], 
									"spdbkcmd", taemg_out["dsbc_at"],
									"alpll", taemg_out["alpll"],
									"alpul", taemg_out["alpul"],
									"mach", taemg_in["mach"],
									"prog_pch", dap:prog_pitch,
									"prog_roll", dap:prog_roll,
									"prog_yaw", dap:prog_yaw,
									"xtrack_err", 0,
									"hac_entry_t", 0,
									"grtls_flag", taemg_out["grtls_flag"],
									"cont_flag", taemg_out["cont_flag"],
									"ecal_flag", taemg_out["ecal_flag"]
			).
			
			if (guid_id >= 30 OR guid_id=23) {
				set hud_datalex["delaz"] to - rwystate["rwy_rel_crs"].
				set gui_data["xtrack_err"] to -taemg_out["yerrc"].
			} else if (guid_id = 22) {
				set hud_datalex["delaz"] to taemg_out["ysgn"] * taemg_out["psha"].
				set gui_data["xtrack_err"] to taemg_out["ysgn"] * taemg_out["rerrc"] / 50.
			} else if (guid_id <= 21 OR guid_id>23) {
				set hud_datalex["delaz"] to taemg_out["dpsac"].
				set gui_data["hac_entry_t"] to taemg_out["tth"].
			}
			
			update_taem_vsit_disp(gui_data).
			
			if (ops3_parameters["dap_debug"]) {
				dap:print_debug(2).
			}
			
			if is_log() {
				SET loglex["guid_id"] TO guid_id.
				SET loglex["loop_dt"] TO guidance_timer:last_dt.
				SET loglex["rwy_alt"] TO taemg_in["h"].
				SET loglex["vel"] TO SHIP:VELOCITY:ORBIT:MAG.
				SET loglex["surfv"] TO taemg_in["surfv"]. 
				SET loglex["mach"] TO taemg_in["mach"]. 
				SET loglex["hdot"] TO taemg_in["hdot"].
				SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
				SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
				SET loglex["range"] TO hud_datalex["distance"].
				SET loglex["delaz"] TO hud_datalex["delaz"].
				SET loglex["nz"] TO dap:aero:nz.
				SET loglex["drag"] TO taemg_in["drag"].
				SET loglex["eow"] TO taemg_out["eow"].
				SET loglex["prog_pch"] TO dap:prog_pitch.
				SET loglex["prog_roll"] TO dap:prog_roll. 
				SET loglex["prog_yaw"] TO dap:prog_yaw.
				SET loglex["flap_defl"] TO aerosurfaces_control["flap_defl"].
				SET loglex["spdbk_defl"] TO aerosurfaces_control["spdbk_defl"].
				
				log_data(loglex,"0:/Shuttle_OPS3/LOGS/ops3_log").
			}
			
			if (taemg_out["al_end"] = TRUE) {
				set al_end_flag to TRUE.
			}
			
			WAIT ops3_parameters["taem_loop_dt"].
		}
		
		clear_ops3_disp().
	}

	disengage_dap().
	control_loop:stop_execution().
	close_all_GUIs().
	clearscreen.
	wait 0.2.

}