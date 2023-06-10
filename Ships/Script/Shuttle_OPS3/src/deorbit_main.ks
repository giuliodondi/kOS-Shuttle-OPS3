GLOBAL g0 IS 9.80665.


FUNCTION plot_traj_vectors {
	PARAMETER poslist.

	CLEARVECDRAWS().

	IF poslist:LENGTH>0 {
	
		LOCAL oldpos IS poslist[0].
		
		FROM {LOCAL k IS 1.} UNTIL k >= poslist:LENGTH STEP { SET k TO k+1.} DO{
			
			//LOCAL adjustPos IS simstate["position"] + ((simstate["position"] - SHIP:BODY:POSITION):NORMALIZED * 20) - .
			//LOCAL adjold_pos IS old_pos + ((old_pos - SHIP:BODY:POSITION):NORMALIZED * 20).

			LOCAL newpos IS poslist[k].
			LOCAL adjustPos IS newpos   + ((newpos - SHIP:BODY:POSITION):NORMALIZED * 20) .
			LOCAL adjold_pos IS oldpos  + ((oldpos - SHIP:BODY:POSITION):NORMALIZED * 20).
			
			
			LOCAL vecWidth IS 0.02.//200.
			//IF MAPVIEW { SET vecWidth TO 0.2. }
		
			//changed trajectory colour from red to green to avoid confusion with the Trajectories mod
			VECDRAW(adjold_pos,(adjustPos - adjold_pos),green,"",1,TRUE,vecWidth).

			SET oldpos TO newpos.
		
		}
	
	}
}


FUNCTION deorbit_main {

	IF (DEFINED tgtrwy) {UNSET tgtrwy.}
	GLOBAL tgtrwy IS ldgsiteslex[ldgsiteslex:keys[0]].
	
	//add prebank constant 
	constants:ADD("prebank_angle",0).
	
	make_global_deorbit_GUI().
	
	//flag to stop the program entirely
	GLOBAL quitflag IS FALSE.

	GLOBAL plot_trajectory IS TRUE.
	
	//flag to reset entry guidance to initial values (e.g. when the target is switched)

	GLOBAL reset_entry_flag Is FALSE.


	//initialise the bank control value
	GLOBAL roll_ref IS vehicle_params["rollguess"].
	

	LOCAL pitch_ref IS pitchprof_segments[pitchprof_segments:LENGTH-1][1].
	


	//initialise global internal variables
	
	//initialise gains for PID
	GLOBAL gains_log_path IS "0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/gains.ks".
	IF EXISTS(gains_log_path) {RUNPATH(gains_log_path).}
	ELSE {GLOBAL gains IS LEXICON(	"rangeKP",0.008,
									"rangeKD",0.001,
									"Khdot",2,
									"strmgr",60,
									"pitchKD",0.05,
									"yawKD",0.05,
									"rollKD",0.05
								).
	}

	
	LOCAL entry_radius IS (constants["interfalt"] + SHIP:BODY:RADIUS).
	
	LOCAL range_err IS 0.
	
	LOCAL last_T Is TIME:SECONDS.
	

	//define the delegate to the integrator function, saves an if check per integration step
	IF sim_settings["integrator"]= "rk2" {
		SET sim_settings["integrator"] TO rk2@.
	}
	ELSE IF sim_settings["integrator"]= "rk3" {
		SET sim_settings["integrator"] TO rk3@.
	}
	ELSE IF sim_settings["integrator"]= "rk4" {
		SET sim_settings["integrator"] TO rk4@.
	}


	
	//initialise the position points list
	//inisialise as zero to avoid plotting the trajecory before at least one pass
	//through the simulation loop is made
	LOCAL poslist IS LIST().
	
	//add the faster outer loop plotting the trajectory data
	//GLOBAL trajplot_upd IS TRUE.
	//LOCAL i IS 0.
	//IF plot_trajectory {
	//	WHEN trajplot_upd THEN {
	//		SET trajplot_upd TO FALSE.	//so that the plotting will pause until the variable is updated
	//		
	//		SET i TO i + 1.
	//		
	//		print i at (10,10).
	//		
	//		
	//		
	//		SET trajplot_upd TO TRUE.
	//		PRESERVE.
	//
	//	}
	//}
	
	//reset guidance automatically once every few guidance cycles
	//to unstuck roll-ref
	LOCAL auto_reset_counter IS 0.
	
	UNTIL FALSE{
	
		SET auto_reset_counter TO auto_reset_counter + 1.
		
		IF reset_entry_flag OR (auto_reset_counter = 10) {
			SET auto_reset_counter TO 0.
			SET reset_entry_flag TO FALSE.
			SET roll_ref TO vehicle_params["rollguess"]. 
		}
	
		SET shipvec TO - SHIP:ORBIT:BODY:POSITION.
		SET normvec TO VCRS(-SHIP:ORBIT:BODY:POSITION,SHIP:VELOCITY:ORBIT).
		
		//implement two cases based on whether there's a manoeuvre node or not
		//just duplicate the code, no need todo fancier things
	
		//if there is a manoeuvre node
		IF HASNODE {
			
			LOCAL nodeslist IS ALLNODES.
			
			SET lastnode TO ALLNODES[ALLNODES:LENGTH - 1].
		
			IF (lastnode:orbit:periapsis<constants["interfalt"]) {
			
				local normvec IS VCRS(-SHIP:ORBIT:BODY:POSITION,SHIP:VELOCITY:ORBIT).
		
				//time to the node
				LOCAL shipvec IS - SHIP:ORBIT:BODY:POSITION.
				LOCAL t2entry IS  lastnode:ETA + burnDT(lastnode:deltav:MAG)/2.
				
				//position vector of the manoeuvre node
				LOCAL eta1 IS t_to_eta(SHIP:ORBIT:TRUEANOMALY,t2entry,SHIP:ORBIT:SEMIMAJORAXIS,SHIP:ORBIT:ECCENTRICITY) - SHIP:ORBIT:TRUEANOMALY.
				
				SET shipvec TO rodrigues(shipvec,normvec,eta1).
				
				//next patch parameters + altitude at the node
				LOCAL node_radius IS SHIP:ORBIT:SEMIMAJORAXIS*(1-SHIP:ORBIT:ECCENTRICITY^2)/(1 + SHIP:ORBIT:ECCENTRICITY*COS(eta1)).	
				LOCAL nxtorb_sma IS lastnode:orbit:semimajoraxis.
				LOCAL nxtorb_ecc IS lastnode:orbit:eccentricity.
				
				//true anomalies of node and entry point
				LOCAL node_eta IS 0.
				LOCAL entry_eta IS 0.
				IF nxtorb_ecc>0 {		
						//set node_eta to (nxtorb_sma*(1-nxtorb_ecc^2)/node_radius - 1)/nxtorb_ecc.
						//print node_eta at (1,10).
						//set node_eta to ARCCOS(node_eta).
						set node_eta to lastnode:orbit:trueanomaly.
						set entry_eta to (nxtorb_sma*(1-nxtorb_ecc^2)/entry_radius - 1)/nxtorb_ecc.
						set entry_eta to ARCCOS(limitarg(entry_eta)).
						//we will cross the target altitude at 2 different points in the orbit
						//we are interested in the descending one i.e. before periapsis 
						//therefore compute the eta of the ascending one and subtract tit from 360
						//exploiting the symmetry of the ellipse
						
						SET entry_eta TO 360- entry_eta.
				}

				LOCAL eta2 IS fixangle(entry_eta - node_eta).
				print "node_eta" + node_eta at (1,11).
				print "entry_eta" + entry_eta at (1,12).
				//find the vector corresponding to entry interface
				SET shipvec TO rodrigues(shipvec,normvec,eta2):NORMALIZED*entry_radius.
				
				//time from periapsis of next patch to the node true anomaly
				LOCAL t_node IS eta_to_dt(node_eta,nxtorb_sma,nxtorb_ecc).
				//time from periapsis of next patch to the entry true anomaly
				LOCAL t_entry IS eta_to_dt(entry_eta,nxtorb_sma,nxtorb_ecc).
				//time to entry interface
				SET t2entry TO t2entry + ( t_entry - t_node).
				
				
				//find flight-path angle at entry interface
				local phi is nxtorb_ecc*sin(entry_eta)/(1 + nxtorb_ecc*COS(entry_eta)).
				set phi to ARCTAN(phi).
				
				
				//transform the entry interface to coordinates and
				//rotate it backwards by the time to entry,
				LOCAL interfpos IS pos2vec(shift_pos(shipvec,t2entry)):NORMALIZED*entry_radius.
				
					
				
				
				
				//setup the trajectory simulation
				
				
				
				//rotate backwards the normal vector as well
				SET normvec TO pos2vec(shift_pos(normvec,t2entry)):NORMALIZED.
				
				//find the orbital velocity vector at entry interface
				LOCAL interfvel IS VCRS(normvec,interfpos):NORMALIZED.
				LOCAL orbvmag IS SQRT(  BODY:MU*(2/entry_radius - 1/(nxtorb_sma) ) ).
				SET interfvel TO interfvel*orbvmag.
				SET interfvel TO rodrigues(interfvel,-normvec,phi).
				

				//initialise the internal variables
				LOCAL ICS IS LEXICON(
								 "position",interfpos,
								 "velocity",interfvel
				).
				
				LOCAL simstate IS blank_simstate(ICS).

				
				//run the vehicle simulation
				
				SET simstate TO  simulate_reentry(
								sim_settings,
								simstate,
								LEXICON("position",tgtrwy["position"],"elevation",tgtrwy["elevation"]),
								sim_end_conditions,
								roll_ref,
								pitch_ref,
								pitchroll_profiles_entry@,
								plot_trajectory
				).
				

				//fetch the position list for plotting
				IF plot_trajectory {
					SET poslist TO simstate["poslist"].
					plot_traj_vectors(poslist).
				}
				
				//calculate the range error for bank optimisation
				LOCAL delta_t IS  TIME:SECONDS - last_T.
				SET last_T TO  TIME:SECONDS.
			
				
				//calculate range error//difference of dist bw interf and target 
				//and interf and end point
				LOCAL tgt_range IS downrangedist(tgtrwy["position"], interfpos).
				LOCAL end_range IS downrangedist(simstate["latlong"], interfpos).
				LOCAL range_err_p IS range_err.
				SET range_err TO end_range - tgt_range. 
				
				//adjust the bank with PID
				
				//PID stuff
				LOCAL P IS range_err.
				LOCAL D IS (range_err - range_err_p)/delta_t.
					
				LOCAL delta_roll IS P*gains["rangeKP"] + D*gains["rangeKD"].
				
				SET roll_ref TO MAX(0,MIN(120,roll_ref + delta_roll)).
				
				update_deorbit_GUI(
									t2entry,
									az_error(interfpos,tgtrwy["position"],interfvel),
									tgt_range,
									interfvel:MAG,
									phi,
									downrangedist(tgtrwy["position"], simstate["latlong"]),
									range_err,
									roll_ref
				).
				
			}	

		//if there is no manoeuvre
		} ELSE IF SHIP:orbit:periapsis<constants["interfalt"] {
		
			print "no node" at (0,10).
		
			local normvec IS VCRS(-SHIP:ORBIT:BODY:POSITION,SHIP:VELOCITY:ORBIT).
	
			//time to the node
			LOCAL shipvec IS - SHIP:ORBIT:BODY:POSITION.

			
			//current orbital parameters	
			LOCAL orb_sma IS SHIP:ORBIT:SEMIMAJORAXIS.
			LOCAL orb_ecc IS SHIP:ORBIT:ECCENTRICITY.
			LOCAL cur_eta IS SHIP:ORBIT:TRUEANOMALY.
			
			//true anomaly of entry point
			LOCAL entry_eta IS 0.
			IF orb_ecc>0 {		
					set entry_eta to (orb_sma*(1-orb_ecc^2)/entry_radius - 1)/orb_ecc.
					set entry_eta to ARCCOS(limitarg(entry_eta)).
					//we will cross the target altitude at 2 different points in the orbit
					//we are interested in the descending one i.e. before periapsis 
					//therefore compute the eta of the ascending one and subtract tit from 360
					//exploiting the symmetry of the ellipse
					
					SET entry_eta TO 360- entry_eta.
			}
			
			

			LOCAL eta2 IS fixangle(entry_eta - cur_eta).
			print "cur_eta" + cur_eta at (1,11).
			print "entry_eta" + entry_eta at (1,12).
			//find the vector corresponding to entry interface
			SET shipvec TO rodrigues(shipvec,normvec,eta2):NORMALIZED*entry_radius.
			
			//time from periapsis of current patch to the current true anomaly
			LOCAL t_cur_eta IS eta_to_dt(cur_eta,orb_sma,orb_ecc).
			//time from periapsis of next patch to the entry true anomaly
			LOCAL t_entry IS eta_to_dt(entry_eta,orb_sma,orb_ecc).
			//time to entry interface
			SET t2entry TO ( t_entry - t_cur_eta).
			
			
			//find flight-path angle at entry interface
			local phi is orb_ecc*sin(entry_eta)/(1 + orb_ecc*COS(entry_eta)).
			set phi to ARCTAN(phi).
			
			
			//transform the entry interface to coordinates and
			//rotate it backwards by the time to entry,
			LOCAL interfpos IS pos2vec(shift_pos(shipvec,t2entry)):NORMALIZED*entry_radius.
			
				
			
			
			
			//setup the trajectory simulation
			
			
			
			//rotate backwards the normal vector as well
			SET normvec TO pos2vec(shift_pos(normvec,t2entry)):NORMALIZED.
			
			//find the orbital velocity vector at entry interface
			LOCAL interfvel IS VCRS(normvec,interfpos):NORMALIZED.
			LOCAL orbvmag IS SQRT(  BODY:MU*(2/entry_radius - 1/(orb_sma) ) ).
			SET interfvel TO interfvel*orbvmag.
			SET interfvel TO rodrigues(interfvel,-normvec,phi).
			

			//initialise the internal variables
			LOCAL ICS IS LEXICON(
							 "position",interfpos,
							 "velocity",interfvel
			).
			
			LOCAL simstate IS blank_simstate(ICS).

			
			//run the vehicle simulation
			
			SET simstate TO  simulate_reentry(
							sim_settings,
							simstate,
							tgtrwy,
							sim_end_conditions,
							roll_ref,
							pitch_ref,
							pitchroll_profiles_entry@,
							TRUE
			).
			

			//fetch the position list for plotting
			SET poslist TO simstate["poslist"].
			
			//fetch the position list for plotting
			IF plot_trajectory {
				SET poslist TO simstate["poslist"].
				plot_traj_vectors(poslist).
			}
			
			//calculate the range error for bank optimisation
			LOCAL delta_t IS  TIME:SECONDS - last_T.
			SET last_T TO  TIME:SECONDS.
		
			
			//calculate range error//difference of dist bw interf and target 
			//and interf and end point
			LOCAL tgt_range IS downrangedist(tgtrwy["position"], interfpos).
			LOCAL end_range IS downrangedist(simstate["latlong"], interfpos).
			LOCAL range_err_p IS range_err.
			SET range_err TO end_range - tgt_range. 
			
			//adjust the bank with PID
			
			//PID stuff
			LOCAL P IS range_err.
			LOCAL D IS (range_err - range_err_p)/delta_t.
				
			LOCAL delta_roll IS P*gains["rangeKP"] + D*gains["rangeKD"].
			
			SET roll_ref TO MAX(0,MIN(120,roll_ref + delta_roll)).
			
			update_deorbit_GUI(
								t2entry,
								az_error(interfpos,tgtrwy["position"],interfvel),
								tgt_range,
								interfvel:MAG,
								phi,
								downrangedist(tgtrwy["position"], simstate["latlong"]),
								range_err,
								roll_ref
			).


		
		} ELSE {
			PRINTPLACE("Orbit periapsis is not low enough",30,1,1).
		}
		
		
		IF quitflag {BREAK.}
	}
	close_global_GUI().
	clearvecdraws().
	clearscreen.
}



FUNCTION get_thrust_isp {


	LOCAL thr is 0.
	LOCAL iisspp IS 0.		   
	
	list ENGINES in all_eng.
	FOR e IN all_eng {
		IF e:ISTYPE("engine") {
			IF e:IGNITION {
				SET thr TO thr + (e:AVAILABLETHRUST * 1000).
				SET iisspp TO iisspp + e:vacuumisp*(e:AVAILABLETHRUST * 1000).								
			}
		}
	}	
	
	RETURN LIST(thr,iisspp).
}

FUNCTION burnDT {
	PARAMETER dV.
	
	
	LOCAL out IS get_thrust_isp().
	LOCAL iisp IS out[1].
	LOCAL thr IS out[0].
	
	LOCAL vex IS g0*iisp.
	
	LOCAL mdot IS thr/vex.
	
	RETURN (SHIP:MASS*1000/(mdot))*( 1 - CONSTANT:E^(-dV/vex) ).
}

