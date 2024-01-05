clearscreen.
close_all_GUIs().

make_global_deorbit_GUI().


FUNCTION ops3_deorbit_predict{
	GLOBAL quit_program IS FALSE.


	IF (DEFINED tgtrwy) {UNSET tgtrwy.}
	GLOBAL tgtrwy IS ldgsiteslex[ldgsiteslex:keys[0]].


	LOCAL cur_ap IS SHIP:ORBIT:aPOAPSIS/1000.
	LOCAL cur_pe IS SHIP:ORBIT:aPOAPSIS/1000.

	//test for circular enough orbit
	if (cur_ap - cur_pe)>10 {
		print "Please circularize the orbit to within +-10km".
	}

	//calculate reference circular orbit apoapsis and optimal ei parameters
	LOCAL ref_ap IS (cur_ap + cur_pe)/2.
	Local ei_ref_data is deorbit_ei_calc(ref_ap, parameters["interfalt"]/1000).

	LOCAL ei_radius IS (parameters["interfalt"] + SHIP:BODY:RADIUS).

	UNTIL (deorbit_target_selected) {
		print "Please select a deorbit target" AT (0,1).
	}

	UNTIL FALSE {

		SET shipvec TO - SHIP:ORBIT:BODY:POSITION.
		SET normvec TO VCRS(-SHIP:ORBIT:BODY:POSITION,SHIP:VELOCITY:ORBIT).

		LOCAL node_ IS 0.
		LOCAL entry_orbit IS 0.
		
		//orbital parameters of the orbit that leads to entry interface 
		//can be either the curent orbit or the orbit after the node
		LOCAL entry_orb_sma IS 0.
		LOCAL entry_orb_ecc IS 0.
		LOCAL entry_orb_start_eta IS 0.
		LOCAL time2EI IS 0.
		
		
		LOCAL cur_orb_sma IS SHIP:ORBIT:SEMIMAJORAXIS.
		LOCAL cur_orb_ecc IS SHIP:ORBIT:ECCENTRICITY.
		LOCAL cur_orb_eta IS SHIP:ORBIT:TRUEANOMALY.

		//if there is a manoeuvre node
		IF HASNODE {
			
			SET lastnode TO ALLNODES[ALLNODES:LENGTH - 1].
			
			SET time2EI TO time2EI + lastnode:ETA + burnDT(lastnode:deltav:MAG)/2.
				
			//position vector of the manoeuvre node
			LOCAL eta1 IS t_to_eta(cur_orb_eta, time2EI, cur_orb_sma, cur_orb_ecc) - cur_orb_eta.
				
			SET shipvec TO rodrigues(shipvec,normvec,eta1).
			
			SET entry_orb_sma TO lastnode:orbit:semimajoraxis.
			SET entry_orb_ecc TO lastnode:orbit:eccentricity.
			SET entry_orb_start_eta TO lastnode:orbit:trueanomaly.

			
		} ELSE {
		
			IF SHIP:ORBIT:periapsis>=parameters["interfalt"] {
				PRINT "Orbit does not have a manoeuvre node and does not re-enter the atmosphere".
				RETURN.
			}
			
			SET entry_orb_sma TO cur_orb_sma.
			SET entry_orb_ecc TO cur_orb_ecc.
			SET entry_orb_start_eta TO cur_orb_eta.
			
		}
		
		print "ei_radius: " + round(ei_radius, 0) + "   "  at (0, 8).
		print "entry_orb_sma: " + round(entry_orb_sma, 0) + "   "  at (0, 9).
		print "entry_orb_ecc: " + round(entry_orb_ecc, 3) + "   "  at (0, 10).
		
		
		//true anomaly of entry point
		LOCAL entry_eta IS 0.
		IF entry_orb_ecc>0 {		
				set entry_eta to orbit_alt_eta(ei_radius, entry_orb_sma, entry_orb_ecc).
				//we will cross the target altitude at 2 different points in the orbit
				//we are interested in the descending one i.e. before periapsis 
				//therefore compute the eta of the ascending one and subtract tit from 360
				//exploiting the symmetry of the ellipse
				
				SET entry_eta TO 360- entry_eta.
		}
		
		LOCAL eta2ei IS fixangle(entry_eta - entry_orb_start_eta).
		print "cur_eta" + entry_orb_start_eta at (1,1).
		print "entry_eta" + entry_eta at (1,2).
		
		//find the vector corresponding to entry interface
		SET shipvec TO rodrigues(shipvec,normvec,eta2ei):NORMALIZED*ei_radius.
		
		//time from periapsis of current patch to the current true anomaly
		LOCAL t_cur_eta IS eta_to_dt(entry_orb_start_eta,entry_orb_sma,entry_orb_ecc).
		//time from periapsis of next patch to the entry true anomaly
		LOCAL t_entry IS eta_to_dt(entry_eta,entry_orb_sma,entry_orb_ecc).
		//time to entry interface
		SET time2EI TO time2EI + ( t_entry - t_cur_eta).
		
		//transform the entry interface to coordinates and
		//rotate it backwards by the time to entry,
		LOCAL ei_pos IS shift_pos(shipvec,time2EI).
		LOCAL ei_posvec IS pos2vec(ei_pos):NORMALIZED*ei_radius.

		//find flight-path angle at entry interface
		LOCAL entry_fpa IS -orbit_alt_fpa(ei_radius, entry_orb_sma, entry_orb_ecc).
		LOCAL entry_vel IS orbit_alt_vel(ei_radius, entry_orb_sma).
		
		LOCAL normvec_rot IS pos2vec(shift_pos(normvec,time2EI)):NORMALIZED.
		LOCAL entry_vel_vec IS VCRS(normvec_rot,ei_posvec):NORMALIZED*entry_vel.
		SET entry_vel_vec TO rodrigues(entry_vel_vec,-normvec_rot,entry_fpa).
		
		LOCAL tgt_range IS downrangedist(tgtrwy["position"], ei_posvec).
		
		LOCAL ei_delaz IS az_error(ei_pos,tgtrwy["position"],entry_vel_vec).
		
		local ei_data is lexicon(
						"ei_vel",entry_vel,
						"ei_fpa",entry_fpa,
						"ei_range",tgt_range,
						"ei_delaz", ei_delaz
		).
		
		update_deorbit_GUI(time2EI, ei_data, ei_ref_data).
		
		clearvecdraws().
		arrow_body(ei_posvec,"ei_posvec").
		
		if (quit_program) {
			BREAK.
		}
		
		WAIT 0.5.
	}

	clearvecdraws().
	clearscreen.
	
	close_all_GUIs().

}




ops3_deorbit_predict().