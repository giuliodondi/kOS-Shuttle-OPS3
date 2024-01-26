clearscreen.
close_all_GUIs().
SET CONFIG:IPU TO 1000. 

make_global_deorbit_GUI().
	
	
ops3_deorbit_predict().

close_all_GUIs().



FUNCTION ops3_deorbit_predict{
	GLOBAL quit_program IS FALSE.

	if (ALLNODES:LENGTH>1) {
		print "Can handle at most one manoeuvre node".
		return.
	}

	IF (DEFINED tgtrwy) {UNSET tgtrwy.}
	GLOBAL tgtrwy IS LEXICON().
	
	//initialise touchdown points for all landing sites
	define_td_points().
	
	UNTIL (deorbit_target_selected) {
		print "Please select a deorbit target" AT (0,1).
		WAIT 0.1.
	}
	
	freeze_target_site().

	UNTIL FALSE {
		clearscreen.
		clearvecdraws().
	
		LOCAL simstate IS current_simstate().
		
		LOCAL deorbit_base_dt IS 60.
		//should cover half a revolution at a timestep of 30
		LOCAL max_steps IS 90.
		
		LOCAL ei_ETA IS 0.
	
		IF HASNODE {
			//predict trajectory from now up to the manoeuvre node 
			//then add the delta-v increment 
			
			LOCAL lastnode IS ALLNODES[0].
			
			LOCAL node_dv IS lastnode:deltav.
			
			LOCAL node_dt IS burnDT(node_dv:MAG).
			
			LOCAL node_ETA IS lastnode:ETA + node_dt/2.
			
			LOCAL patch1_steps IS CEILING(node_ETA/deorbit_base_dt).
			
			LOCAL patch1_dt IS node_ETA/patch1_steps.
			
			FROM {local s is 1.} UNTIL (s > patch1_steps) STEP {set s to s+1.} DO {
				SET simstate TO coast_rk4(patch1_dt, simstate).
			}
			
			SET simstate["velocity"] TO simstate["velocity"] + node_dv.
			
			local burn_pos IS shift_pos(simstate["position"], node_ETA).
			
			arrow_body(burn_pos,"burn").
			
			SET ei_ETA tO ei_ETA + node_ETA.
			
			print "patch 1 steps: " + patch1_steps at (0,2).
			print "time to node: " + round(node_ETA, 1) at (0,3).
			print "node burn dt: " + round(node_dt, 1) at (0,4).
			print "node burn Dv: " + round(node_dv:MAG, 1) at (0,5).
		
		} ELSE {
			IF SHIP:ORBIT:periapsis>=parameters["interfalt"] {
				PRINT "Orbit does not have a manoeuvre node and does not re-enter the atmosphere".
				RETURN.
			}
		}
		
		//now simulate until below entry interface 
		
		LOCAL ei_simstate IS simstate.
		local step_c is 0.
		UNTIL((ei_simstate["altitude"]< parameters["interfalt"]) OR (step_c >= max_steps)) {
			SET step_c TO step_c + 1.
			
			SET ei_simstate TO clone_simstate(coast_rk4(deorbit_base_dt, simstate)).
		
			SET ei_simstate["altitude"] TO bodyalt(ei_simstate["position"]).
			SET ei_simstate["surfvel"] TO surfacevel(ei_simstate["velocity"],ei_simstate["position"]).
			
			SET ei_ETA tO ei_ETA + deorbit_base_dt. 
		}
		
		//entry interface calculations
		LOCAL ei_orb_elems IS state_vector_orb_elems(ei_simstate["position"], ei_simstate["velocity"]).
		Local ei_ref_data is deorbit_ei_calc(ei_orb_elems["ap"], ei_orb_elems["incl"], ei_simstate["altitude"]/1000).
		
		LOCAL ei_fpa IS get_fpa(ei_simstate["position"], ei_simstate["velocity"]).
		
		//shift ei state forwards by the time to ei 
		LOCAL ei_posvec IS shift_pos(ei_simstate["position"], ei_ETA).
		
		LOCAL ei_normvec IS VCRS(ei_simstate["position"], ei_simstate["velocity"]).
		LOCAL normvec_rot IS shift_pos(ei_normvec,ei_ETA):NORMALIZED.
		LOCAL ei_vel_vec IS VCRS(normvec_rot,ei_posvec):NORMALIZED*ei_simstate["velocity"]:MAG.
		SET ei_vel_vec TO rodrigues(ei_vel_vec,-normvec_rot,ei_fpa).
		
		
		LOCAL ei_range IS downrangedist(tgtrwy["position"], ei_posvec).
		LOCAL ei_delaz IS az_error(ei_posvec, tgtrwy["position"], ei_simstate["velocity"]).
		
		local ei_data is lexicon(
						"ei_vel", ei_vel_vec:MAG,
						"ei_fpa", ei_fpa,
						"ei_range", ei_range,
						"ei_delaz", ei_delaz
		).
		 
		update_deorbit_GUI(ei_ETA, ei_data, ei_ref_data).
		
		
		
		arrow_body(ei_posvec,"entry_interface").
		
		if (quit_program) {
			BREAK.
		}
		
		WAIT 0.5.
	}

	clearvecdraws().
	clearscreen.
}




