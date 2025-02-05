clearscreen.
close_all_GUIs().
SET CONFIG:IPU TO 1500. 

make_global_deorbit_GUI().
	
ops3_deorbit_predict().

close_all_GUIs().

clearvecdraws().



FUNCTION ops3_deorbit_predict{
	GLOBAL quit_program IS FALSE.
	
	//check engines 
	IF (get_running_engines():LENGTH = 0) {
		PRINT "No active engines,  aborting." .
		RETURN.
	}
	
	if (ALLNODES:LENGTH = 0) {
		print "There is no KSP manoeuvre node,  aborting.".
		return.
	}

	if (ALLNODES:LENGTH>1) {
		print "Can handle at most one manoeuvre node,  aborting.".
		return.
	}

	IF (DEFINED tgtrwy) {UNSET tgtrwy.}
	GLOBAL tgtrwy IS LEXICON().
	
	//initialise touchdown points for all landing sites
	define_td_points().
	
	UNTIL (deorbit_target_selected) {
		print "Please select a deorbit target" AT (0,1).
		if (quit_program) {
			return.
		}
		WAIT 0.1.
	}
	
	freeze_target_site().
	
	local drawburnvec IS false.
	local burn_pos IS 0.
	local burn_dv IS v(0,0,0).
	
	LOCAL deorbit_base_dt IS 5.
	//cover half a revolution
	LOCAL max_steps IS FLOOR(45 * 60 / deorbit_base_dt).
	local burn_steps is 30.
	
	LOCAL initial_simstate IS current_simstate().
	LOCAL initial_t IS TIME:SECONDS.
	
	LOCAL ei_radius IS BODY:RADIUS + ops3_parameters["interfalt"].

	UNTIL FALSE {
	
		LOCAL simstate IS clone_simstate(initial_simstate).
		LOCAL dt_from_initial IS (TIME:SECONDS - initial_t).
		
		LOCAL ei_ETA IS 0.
	
		IF HASNODE {
			SET drawburnvec TO TRUE.
			//predict trajectory from now up to the manoeuvre node 
			//then add the delta-v increment 
			
			LOCAL lastnode IS ALLNODES[0].
			
			set burn_dv to lastnode:deltav.
			
			LOCAL node_dt IS burnDT(burn_dv:MAG).
			
			LOCAL node_ETA IS dt_from_initial + lastnode:ETA.
			
			LOCAL patch1_steps IS CEILING(node_ETA/deorbit_base_dt).
			
			LOCAL patch1_dt IS node_ETA/patch1_steps.
			
			LOCAL burn_simstate IS clone_simstate(simstate).
			
			FROM {local s is 1.} UNTIL (s > patch1_steps) STEP {set s to s+1.} DO {
				SET burn_simstate TO clone_simstate(coast_rk4(patch1_dt, burn_simstate)).
			}
			
			LOCAL burn_patch_dt IS node_dt/burn_steps.
			LOCAL burn_step_dv IS burn_dv/burn_steps.
			FROM {local s is 1.} UNTIL (s > burn_steps) STEP {set s to s+1.} DO {
				SET burn_simstate["velocity"] TO burn_simstate["velocity"] + burn_step_dv. 
				SET burn_simstate TO clone_simstate(coast_rk3(burn_patch_dt, burn_simstate)).
			}
			
			
			SET burn_simstate["altitude"] TO bodyalt(burn_simstate["position"]).
			
			set burn_pos to pos2vec(shift_pos(burn_simstate["position"], node_ETA)).
			
			SET simstate TO burn_simstate.
			
			SET ei_ETA tO ei_ETA + node_ETA.
			
			print "patch 1 steps: " + patch1_steps + "  " at (0,2).
			print "time to node: " + round(node_ETA, 1) + "  "  at (0,3).
			print "node burn dt: " + round(node_dt, 1) + "  "  at (0,4).
			print "node burn Dv: " + round(burn_dv:MAG, 1) + "  "  at (0,5).
		
		} ELSE {
			SET drawburnvec TO FALSE.
			IF SHIP:ORBIT:periapsis>=ops3_parameters["interfalt"] {
				PRINT "Orbit does not have a manoeuvre node and does not re-enter the atmosphere".
				RETURN.
			}
		}
		
		//now simulate until below entry interface 
		
		LOCAL ei_simstate IS clone_simstate(simstate).
		
		print "patch 2 initial alt: " + round(ei_simstate["altitude"], 0) + "  "  at (0,7).
		print "patch 2 initial vel: " + round(ei_simstate["velocity"]:mag, 1) + "  "  at (0,8).
		
		local patch2_steps is 0.
		local patch2_dt is deorbit_base_dt.
		LOCAL patch2_simtime IS 0.
		
		UNTIL(patch2_steps >= max_steps) {
			SET patch2_steps TO patch2_steps + 1.
			
			SET ei_simstate TO clone_simstate(coast_rk4(patch2_dt, ei_simstate)).
			
			SET patch2_simtime tO patch2_simtime + patch2_dt. 
			
			LOCAL simstate_dr IS ei_simstate["position"]:MAG - ei_radius.
			
			//finer simulation step
			IF (simstate_dr < 5000) {
				SET patch2_dt TO 5.
			} ELSe IF (simstate_dr < 1000) {
				SET patch2_dt TO 1.
			}
			
			IF (ABS(simstate_dr) < 100 OR simstate_dr < 0) {
				BREAK.
			}
		}
		
		SET ei_ETA tO ei_ETA + patch2_simtime. 
		
		SET ei_simstate["altitude"] TO bodyalt(ei_simstate["position"]).
		
		LOCAL ei_fpa IS get_fpa(ei_simstate["position"], ei_simstate["velocity"]).
		
		//shift ei state forwards by the time to ei 
		//modification: add reentry time bias
		local ei_bias_t is ei_ETA + 30 * 60.
		LOCAL ei_posvec IS pos2vec(shift_pos(ei_simstate["position"], ei_bias_t)).
		
		LOCAL ei_normvec IS VCRS(ei_simstate["position"], ei_simstate["velocity"]).
		LOCAL normvec_rot IS pos2vec(shift_pos(ei_normvec, ei_bias_t)):NORMALIZED.
		LOCAL ei_vel_vec IS VCRS(normvec_rot,ei_posvec):NORMALIZED*ei_simstate["velocity"]:MAG.
		SET ei_vel_vec TO rodrigues(ei_vel_vec,-normvec_rot,ei_fpa).
		
		
		LOCAL ei_range IS downrangedist(tgtrwy["position"], ei_posvec).
		LOCAL ei_delaz IS az_error(ei_posvec, tgtrwy["position"], ei_vel_vec).
		
		local ei_data is lexicon(
						"ei_vel", ei_vel_vec:MAG,
						"ei_fpa", ei_fpa,
						"ei_range", ei_range,
						"ei_delaz", ei_delaz
		).
		
		//entry interface calculations
		LOCAL ei_orb_elems IS state_vector_orb_elems(ei_simstate["position"], ei_simstate["velocity"]).
		Local ei_ref_data is deorbit_ei_calc(ei_orb_elems["ap"], ei_orb_elems["incl"], ei_delaz, ei_simstate["altitude"]/1000).
		 
		update_deorbit_GUI(ei_ETA, ei_data, ei_ref_data).
		
		print "patch 2 steps: " + patch2_steps + "  "  at (0,10).
		print "patch 2 dt: " + round(patch2_simtime, 1) + "  "  at (0,11).
		print "EI alt: " + round(ei_simstate["altitude"], 0) + "  "  at (0,12).
		
		clearvecdraws().
		arrow_body(ei_posvec,"entry_interface").
		if (drawburnvec) {
			arrow_body(burn_pos,"deorbit_burn").
			arrow_bodyvec(burn_dv * 10000,"deltaV", burn_pos).
		}
		
		if (quit_program) {
			return.
		}
		
		WAIT 0.5.
	}
	
	clearscreen.
}




