



//main loop
FUNCTION entry_main_loop {

SAS OFF.

ON SAS {
	SAS OFF.
}

vehicle_params:ADD("hac_h_cub0",0).
vehicle_params:ADD("hac_h_cub1",0).
vehicle_params:ADD("hac_h_cub2",0).
vehicle_params:ADD("hac_h_cub3",0).
vehicle_params["glideslope"]:ADD("taem",0).

STEERINGMANAGER:RESETPIDS().
STEERINGMANAGER:RESETTODEFAULT().


SET STEERINGMANAGER:PITCHTS TO 8.0.
SET STEERINGMANAGER:YAWTS TO 3.
SET STEERINGMANAGER:ROLLTS TO 3.

IF (STEERINGMANAGER:PITCHPID:HASSUFFIX("epsilon")) {
	SET STEERINGMANAGER:PITCHPID:EPSILON TO 0.1.
	SET STEERINGMANAGER:YAWPID:EPSILON TO 0.1.
	SET STEERINGMANAGER:ROLLPID:EPSILON TO 0.1.
}



//unset the PIDs that may still be in memory 
IF (DEFINED BRAKESPID) {UNSET BRAKESPID.}
IF (DEFINED FLAPPID) {UNSET FLAPPID.}
IF (DEFINED AUTOLPITCHPID) {UNSET AUTOLPITCHPID.}
IF (DEFINED AUTOLROLLPID) {UNSET AUTOLROLLPID.}

//prepare steering 
GLOBAL P_att IS SHIP:FACING.

//initialise touchdown points for all landing sites
define_td_points().


//initialised by default to first landing site 
//can be changed with the GUI
make_global_entry_GUI().


//ths lexicon contains all the necessary guidance objects 
IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS refresh_runway_lex(ldgsiteslex[select_tgt:VALUE]).

//this must be called after the GUI and the tgtrwy lexicon have been initialised
select_random_rwy().
SET tgtrwy["heading"] TO ldgsiteslex[select_tgt:VALUE]["rwys"][select_rwy:VALUE]["heading"].
SET tgtrwy["td_pt"] TO ldgsiteslex[select_tgt:VALUE]["rwys"][select_rwy:VALUE]["td_pt"].
SET tgtrwy["hac_side"] TO select_side:VALUE.

define_hac(SHIP:GEOPOSITION, tgtrwy, vehicle_params).



GLOBAL mode IS 1.

//flag to stop the program entirely
GLOBAL quitflag IS FALSE.


//Initialise log lexicon 
GLOBAL loglex IS LEXICON(
									"mode",1,
									"time",0,
									"alt",0,
									"speed",0,
									"mach",0,
									"hdot",0,
									"range",0,
									"lat",0,
									"long",0,
									"pitch",0,
									"roll",0,
									"tgt_range",0,
									"range_err",0,
									"az_err",0,
									"roll_ref",0,
									"l_d",0
).



//flag to reset entry guidance to initial values (e.g. when the target is switched)

GLOBAL reset_entry_flag Is FALSE.


//initialise all pids
reset_pids().


GLOBAL airbrake_control IS airbrake_control_factory().

GLOBAL flap_control IS flap_control_factory().

//activate fbw
SET fbwb:PRESSED to TRUE.

//if conducting an ALT this will prevent the entry guidance from running
IF SHIP:ALTITUDE>constants["apchalt"] {

	make_entry_GUI().

	
	//SHUTDOWN ALL engines and initalise gimbals parts
	//don't necessarily want to do this for an alt
	FOR eng in englist {
		IF (eng:IGNITION) {
			eng:SHUTDOWN.
		}
	}

	IF (NOT check_pitch_prof()) {
		PRINT "Illegal pitch profile detected." at (0,1).
		PRINT "You may only specify positive pitch values to positive velocity values" AT (0,2). 
		RETURN.
	}
	
	//activate auto flaps 
	SET flptrm:PRESSED TO TRUE.

	entry_loop().
	
	//remove entry GUI sections
	clean_entry_gui().

}

SET mode TO 3.
SET CONFIG:IPU TO 800.


LOCAL closest_out IS get_closest_site(ldgsiteslex).
SET select_tgt:INDEX TO closest_out[0].


SET loglex["range"] TO 0.
SET loglex["range_err"] TO 0.
SET loglex["az_err"] TO 0.
SET loglex["roll_ref"] TO 0. 

flap_control["null_deflection"]().

approach_loop().

flap_control["deactivate"]().
airbrake_control["deactivate"]().

close_all_GUIs().
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
clearscreen.
//remove the global pitch profile so next time we run entyr guidance we reset to the default one 
IF EXISTS(pitchprof_log_path) {DELETEPATH(pitchprof_log_path).}
 
}






FUNCTION entry_loop{

IF quitflag {RETURN.}

//this flag signals if entry guidance was halted automatically bc of taem transition
//or because approach guidance was called manually, in which case skip TAEM
LOCAL TAEM_flag IS FALSE.

//flag to signal that roll guidance has converged
GLOBAL guid_converged_flag IS FALSE.

//flag to stop the entry loop and transition to approach
GLOBAL stop_entry_flag IS FALSE.

//null feedback to help keep high pitch
flap_control["set_aoa_feedback"](0).

//dap controller object
LOCAL dap IS dap_controller_factory().


//initialise pitch and roll guidance values .
LOCAL pitchguid IS pitch_profile(pitchprof_segments[pitchprof_segments:LENGTH-1][1],SHIP:VELOCITY:SURFACE:MAG).
LOCAL rollguid IS 0.


//initalise pitch and roll values to guidance steering
LOCAL pitchsteer IS pitchguid.
LOCAL rollsteer IS rollguid.

IF SHIP:ALTITUDE < constants["firstrollalt"] {	
	//override to current measured attitude
	SET pitchsteer TO get_pitch_prograde().
	SET rollsteer TO get_roll_prograde().
}

//first steering command 
SET P_att TO dap:create_prog_steering_dir(pitchguid, rollguid).

//add prebank constant 
constants:ADD("prebank_angle",rollsteer).

//initialise gains for PID
GLOBAL gains_log_path IS "0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/gains.ks".
IF EXISTS(gains_log_path) {RUNPATH(gains_log_path).}
ELSE {GLOBAL gains IS LEXICON(	"rangeKP",0.008,
								"rangeKD",0.001,
								"Khdot",2,
								"Roll_ramp",3,
								"pchmod",0.1,
								"taemKP",0.15,
								"taemKD",0.14,
								"strmgr",60,
								"pitchKD",0.05,
								"yawKD",0.05,
								"rollKD",0.05
							).
}
SET STEERINGMANAGER:MAXSTOPPINGTIME TO gains["strmgr"].
SET STEERINGMANAGER:PITCHPID:KD TO gains["pitchKD"].
SET STEERINGMANAGER:YAWPID:KD TO gains["yawKD"].
SET STEERINGMANAGER:ROLLPID:KD TO gains["rollKD"].



//trajectory simulation variables
LOCAL step_num IS 0.

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



//navigation variables
LOCAL az_err IS az_error(SHIP:GEOPOSITION,tgtrwy["position"],SHIP:VELOCITY:SURFACE).
LOCAL tgt_range IS greatcircledist(tgtrwy["hac_entry"], SHIP:GEOPOSITION).



//roll ref is the base roll value that gets updated by guidance 
//the actual roll value is determined by the roll profile routine
//it's zero above 90 km and it's roll_ref plus hdot modulation below that.
//initialise it to 45 arbitrarily
LOCAL roll_ref IS vehicle_params["rollguess"].


// control variables
//initialise the roll sign to the azimuth error sign
LOCAL roll_sign IS SIGN(az_err).
LOCAL pitch_ref IS pitchguid.


local control_loop is loop_executor_factory(
								0.3,
								{
									//calculte azimuth error
									SET az_err TO az_error(SHIP:GEOPOSITION,tgtrwy["hac_entry"],SHIP:VELOCITY:SURFACE).
									
									//distance to target
									set tgt_range to greatcircledist(tgtrwy["hac_entry"], SHIP:GEOPOSITION).
	
									//update the flaps trim setting and airbrakes IF WE'RE BELOW FIRST ROLL ALT
									IF SHIP:ALTITUDE < constants["firstrollalt"] {	
										flaptrim_control(flptrm:PRESSED, flap_control).
										speed_control(arbkb:PRESSED, airbrake_control, mode).
									}

									print "roll_ref : " + ROUND(roll_ref,1) + "    " at (0,4).
									print "rollguid : " + ROUND(rollguid,1) + "    " at (0,5).
									print "pitchguid : " + ROUND(pitchguid,1) + "    " at (0,6).
									
									IF is_auto_steering() {
										SET P_att TO dap:reentry_auto(rollguid,pitchguid).
									} ELSE {
										SET P_att TO dap:reentry_css().
									}
									
									LOCAL pipper_deltas IS LIST(
																rollguid - dap:prog_roll, 
																pitchguid -  dap:prog_pitch
									).
									
									update_entry_GUI(
													mode,
													pipper_deltas,
													az_err,
													tgt_range,
													airbrake_control["deflection"],
													flap_control["deflection"],
													update_nz(
														-SHIP:ORBIT:BODY:POSITION,
														SHIP:VELOCITY:SURFACE,
														LIST(dap:steer_pitch,dap:steer_roll)
													
													)	
									).
								}
).



// loop-specific stuff
LOCAL last_T Is TIME:SECONDS.
LOCAL last_hdot IS 0.
LOCAL range_err IS 0.
LOCAL first_reversal_done IS FALSE.


//reentry loop
UNTIL FALSE {
		
	IF reset_entry_flag {
		SET auto_reset_counter TO 0.
		SET reset_entry_flag TO FALSE.
		SET roll_ref TO vehicle_params["rollguess"]. 
	}
	
	//put TAEM transition calculation here 
	IF TAEM_transition(tgt_range) {
		SET TAEM_flag TO TRUE.
		BREAK.
	}
	
	IF ( NOT is_auto_steering() AND SHIP:ALTITUDE > constants["firstrollalt"]) {
		SET constants["prebank_angle"] TO rollsteer.
	}
	
	
		
	//run the vehicle simulation
	LOCAL ICS IS LEXICON(
					 "position",-SHIP:ORBIT:BODY:POSITION,
	                 "velocity",SHIP:VELOCITY:ORBIT
	).
	LOCAL simstate IS blank_simstate(ICS).
		
	SET simstate TO  simulate_reentry(
					sim_settings,
					simstate,
					LEXICON("position",tgtrwy["hac"],"elevation",tgtrwy["elevation"]),
					sim_end_conditions,
					roll_ref,
					pitch_ref,
					pitchroll_profiles_entry@
	).
	
	
	//get great-circle distance from current position to impact pt
	LOCAL end_range IS greatcircledist(simstate["latlong"], SHIP:GEOPOSITION).
	
	

	//calculate the range error
	LOCAL range_err_p IS range_err.
	SET range_err TO end_range - tgt_range - sim_end_conditions["range_bias"]. 
	
	
	//calculate time elapsed since last cycle
	LOCAL delta_t IS  TIME:SECONDS - last_T.
	SET last_T TO TIME:SECONDS.
	
	
	//adjust the timestep adaptively
	//the idea is to keep the number of steps roughly constant
	//and to account for the fact that the simulation time
	//becomes shorter and shorter as we fly the reentry profile.
	
	//first compute the number of steps of last simulation.
	SET step_num TO clamp(ROUND(simstate["simtime"]/sim_settings["deltat"],0),50,100).
	
	//predict the next simulation time by reducing it by the cycle time
	LOCAL next_simtime IS simstate["simtime"] - delta_t.
	//obtain the new timestep , only update is it's smaller
	LOCAL new_timestep IS next_simtime/step_num.
	IF sim_settings["deltat"]>new_timestep {
		SET sim_settings["deltat"] TO new_timestep.
	}
	
	clearscreen.
	print "mode: " + mode at (1,1).
	print "simulation steps: " + step_num at (1,2).
	print "timestep: " + sim_settings["deltat"] at (1,3).
		
	
	IF is_guidance() {
	
		//Roll ref PID stuff
		LOCAL P IS range_err.
		LOCAL D IS (range_err - range_err_p)/delta_t.

		LOCAL delta_roll IS  P*gains["rangeKP"] + D*gains["rangeKD"].
		
		LOCAL roll_ref_p IS roll_ref.
		//update the reference roll value and clamp it
		SET roll_ref TO clamp( roll_ref + delta_roll, 0, 120) .
		
		//measure vertical acceleration
		//will be used for roll modulation
		local hddot is (SHIP:VERTICALSPEED - last_hdot)/delta_t.	
		SET last_hdot TO SHIP:VERTICALSPEED.
		
		//get updated pitch and roll from the profiles
		LOCAL out IS pitchroll_profiles_entry(LIST(roll_ref,pitch_ref),LIST(rollguid,pitchguid),current_simstate(),hddot,az_err,first_reversal_done).
		LOCAL new_roll IS out[0].
		SET pitch_ref TO out[1].
		SET pitchguid TO pitch_ref.
		
		//see if ref roll has converged 
		IF (ABS(roll_ref - roll_ref_p) <constants["rolltol"]) {
			SET guid_converged_flag TO TRUE.
		} ELSE {
			SET guid_converged_flag TO FALSE.
		}
		
		
		//use it only if the reference roll value is converged
		IF guid_converged_flag {
			LOCAL rollguid_p IS rollguid.
		
			SET rollguid TO new_roll.
			
			IF (NOT first_reversal_done AND  rollguid*rollguid_p < 0 AND rollguid*az_err > 0 ) {
				SET first_reversal_done TO TRUE.
			}
			
			//only if guidance is converged and if we're below first roll alt do pitch modulation
			//only use the updated roll value as steering if we're below first roll, else use the slider value
			IF SHIP:ALTITUDE < constants["firstrollalt"] {		
				SET pitchguid TO pitch_modulation(range_err,pitch_ref).
			}
		}
	
	} ELSE {
		//in this case we use the current commanded roll value for the trajectory prediction
		SET roll_ref TO ABS(rollguid).
		//reset the start guidance flag 
		SET guid_converged_flag TO FALSE.
	}
	
	
	
	if is_log() {
	
		LOCAL outforce IS aeroforce_ld(simstate["position"], simstate["velocity"], LIST(pitchguid, rollguid)).
		
		//prepare list of values to log.
		
		SET loglex["mode"] TO mode.
		SET loglex["time"] TO TIME:SECONDS.
		SET loglex["alt"] TO SHIP:ALTITUDE/1000.
		SET loglex["speed"] TO SHIP:VELOCITY:SURFACE:MAG. 
		SET loglex["mach"] TO ADDONS:FAR:MACH. 
		SET loglex["hdot"] TO SHIP:VERTICALSPEED.
		SET loglex["range"] TO tgt_range + estimate_range_hac_landing(tgtrwy,vehicle_params).
		SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
		SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
		SET loglex["pitch"] TO get_pitch_prograde().
		SET loglex["roll"] TO get_roll_prograde().
		SET loglex["tgt_range"] TO tgt_range.
		SET loglex["range_err"] TO range_err.
		SET loglex["az_err"] TO az_err.
		SET loglex["roll_ref"] TO roll_ref. 
		SET loglex["l_d"] TO outforce["lift"] / outforce["drag"].
			
			

		log_data(loglex,"0:/Shuttle_entrysim/LOGS/entry_log").
	}
	
	IF quitflag OR stop_entry_flag {
		SET TAEM_flag TO FALSE.
		BREAK.
	}
	wait 0.
}

select_opposite_hac().
define_hac(SHIP:GEOPOSITION,tgtrwy,vehicle_params).

//positive aoa feedback to help keep stability
flap_control["set_aoa_feedback"](25).

//if we broke out manually before TAEM conditions go directly to approach 
IF (NOT TAEM_flag) { 
	control_loop:stop_execution().
	RETURN.
}


// put TAEM stuff here bc it has much infrastructure in common with entry guidance

//TAEM is a different form of simulation guidance for low velocity (mach <3)
//the idea is to no longer control drag through bank angle because @ low pitch and velocity we are in high L/D
//instead we control altitude with pitch directly (we can do this in high L/D) and drag indirectly through distance to fly 

//we no longer target the runway centre but the HAC entrance point and altitude (re-calculated @every loop)
//roll is commanded to guide the simulated state to the HAC entrance point,
//bank angle is proportional to the heading error in some way and velocity
//pitch is the control value but it's modulated by both the reference vertical speed
//calculated from the altitude difference between now and target and the time of simulation
//and thebank angle to keep the vertical component of lift consistent
//simulation terminates when we are close to the hac entry point and we overtake it
//outside the simulation loop, we adjust pitch based on altitude errors

//we aLso check the velocity at simulation termination 
//if it's higher than the initial approach acquire phase target velocity (need to make the profile visible) we 
//do an S-TURN : bank away from the HAC entrance point at a constant bank angle, the direction depends on HAC position
//the simulation will always guide towards the HAC as if the S-turn were to stop immediately
//when the final speed is low enough we stop the S-turn and start tracking the HAC 


make_TAEM_GUI().

//force a lower deltat 
SET sim_settings["deltat"] TO 10.

LOCAL alt_err IS 0.


//force auto speedbrakes 
TAEM_spdbk().

//keep track of whether we are in an s-turn or not
LOCAL is_s_turn IS FALSE.
LOCAL s_turn_tgt_vel IS vehicle_params["TAEMtgtvel"].

//guesstimate of the reference hdot value
LOCAL hdot_ref IS -50.

//TAEM loop
UNTIL FALSE {

	IF reset_entry_flag {
		SET reset_entry_flag TO FALSE.
		SET pitch_ref TO pitchsteer. 
	}
	
	//check if we should switch to approach 
	apch_transition(tgt_range).
	
	//update HAC entry 
	update_hac_entry_pt(SHIP:GEOPOSITION, tgtrwy, vehicle_params). 
	
	//calculate the target altitude 
	LOCAL alt_err_p IS alt_err.
	LOCAL tgtalt IS taem_profile_alt(tgtrwy, vehicle_params).
		
	//run the vehicle simulation
	LOCAL ICS IS LEXICON(
					 "position",-SHIP:ORBIT:BODY:POSITION,
	                 "velocity",SHIP:VELOCITY:ORBIT
	).
	LOCAL simstate IS blank_simstate(ICS).
	
	//calculate deltah now while we have the simstate set at the initial conditions
	LOCAL deltah IS bodyalt(simstate["position"]) - tgtalt.
		
	SET simstate TO  simulate_TAEM(
					sim_settings,
					simstate,
					tgtrwy,
					vehicle_params,
					roll_ref,
					pitch_ref,
					hdot_ref
	).
	
	//update hdotref with the new simulation time
	SET hdot_ref TO -deltah/simstate["simtime"].
	
	//calculate altitude error in km (to keep the order of magnitude of the gains)
	LOCAL finalalt IS simstate["altitude"].
	SET alt_err TO ( finalalt - tgtalt )/1000. 
		
	//calculate time elapsed since last cycle
	LOCAL delta_t IS  TIME:SECONDS - last_T.
	SET last_T TO TIME:SECONDS.
		
	//adjust the timestep adaptively
	//the idea is to keep the number of steps roughly constant
	//and to account for the fact that the simulation time
	//becomes shorter and shorter as we fly the reentry profile.
	
	//first compute the number of steps of last simulation.
	SET step_num TO clamp(ROUND(simstate["simtime"]/sim_settings["deltat"],0),25,50).
	
	//predict the next simulation time by reducing it by the cycle time
	LOCAL next_simtime IS simstate["simtime"] - delta_t.
	SET sim_settings["deltat"] TO  next_simtime/step_num.

	
	clearscreen.
	print "mode: " + mode at (1,1).
	print "simulation steps: " + step_num at (1,2).
	print "timestep: " + sim_settings["deltat"] at (1,3).
	
	print "tgtalt : " + tgtalt at (0,8).
	print "finalalt : " + finalalt at (0,9).
	print "hdotref : " + hdot_ref at (0,10).
	
	
	IF is_guidance() {
	
		//Pitch ref PID stuff
		//invert signs to keep the signs of the gains consistent with entry guidance
		LOCAL P IS -alt_err.
		LOCAL D IS (alt_err_p - alt_err)/delta_t.

		LOCAL delta_pitch IS  P*gains["taemKP"] + D*gains["taemKD"].
		
		SET pitch_ref_p TO pitch_ref.
		//update the reference roll value and clamp it
		SET pitch_ref TO CLAMP(pitch_ref + delta_pitch,0.5,20).
		
		//determine if s-turn is to be commanded
		LOCAL is_s_turn_p IS is_s_turn.
		SET is_s_turn TO s_turn(
			tgt_range,
			az_err,
			s_turn_tgt_vel,
			simstate["surfvel"]:MAG
		).
		
		//when we exit an s-turn we raise the target velocity so we prevent re-trigger unless the velocity is way too big
		IF (is_s_turn_p AND (NOT is_s_turn)) {
			SET s_turn_tgt_vel TO s_turn_tgt_vel*1.1.
		}
		
		LOCAL hdoterr IS SHIP:VERTICALSPEED - hdot_ref.

		//get updated roll from the profiles
		SET roll_ref TO TAEM_bank_angle(az_err, hdoterr, is_s_turn, tgtrwy["hac_side"]).
		SET rollguid TO roll_ref.
		
		SET pitchguid TO TAEM_pitch_roll_cor(
			TAEM_pitch_profile(pitch_ref, roll_ref,SHIP:VELOCITY:SURFACE:MAG,  hdoterr ),
			get_roll_prograde()
		).

	
	} ELSE {
		//in this case we use the current commanded roll value for the trajectory prediction
		SET pitch_ref TO pitchsteer.
	}

	
	
	if is_log() {
	
		
		//prepare list of values to log.
		
		SET loglex["mode"] TO mode.
		SET loglex["time"] TO TIME:SECONDS.
		SET loglex["alt"] TO runway_alt(SHIP:ALTITUDE)/1000.
		SET loglex["speed"] TO SHIP:VELOCITY:SURFACE:MAG. 
		SET loglex["mach"] TO ADDONS:FAR:MACH. 
		SET loglex["hdot"] TO SHIP:VERTICALSPEED.
		SET loglex["range"] TO tgt_range + estimate_range_hac_landing(tgtrwy,vehicle_params).
		SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
		SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
		SET loglex["pitch"] TO get_pitch_prograde().
		SET loglex["roll"] TO get_roll_prograde().
		SET loglex["tgt_range"] TO tgt_range.
		SET loglex["range_err"] TO range_err.
		SET loglex["az_err"] TO az_err.
		SET loglex["roll_ref"] TO roll_ref. 
		
		LOCAL outforce IS aeroforce_ld(simstate["position"], simstate["velocity"], LIST(pitchguid, rollguid)).
		SET loglex["l_d"] TO outforce["lift"] / outforce["drag"].
			
		log_data(loglex,"0:/Shuttle_entrysim/LOGS/entry_log").
	}
	
	IF quitflag OR stop_entry_flag {
		SET TAEM_flag TO FALSE.
		BREAK.
	}
	wait 0.
}



control_loop:stop_execution().
UNLOCK STEERING.

}





FUNCTION approach_loop {

IF quitflag {RETURN.}

clearscreen.

make_apch_GUI().

//for testing only
//hud_declutter5_gui().
//hud_declutter6_gui().
//hud_declutter7_gui().


define_flare_circle(vehicle_params).


GLOBAL sim_settings IS LEXICON(
					"deltat",1.2,//was 2, set to 1.2 to try and make the pipper less jumpy
					"integrator","rk3",
					"log",FALSE 
).


LOCAL pitchprog IS get_pitch_prograde().
LOCAL rollprog IS get_roll_prograde().

LOCAL dap IS dap_controller_factory().

//strong positive aoa feedback to help keep stability
flap_control["set_aoa_feedback"](50).

//reduce KP on the flaps PID so that auto flaps are nto so aggressive 
SET FLAPPID:KP TO FLAPPID:KP/3.

local exec is loop_executor_factory(
								0.15,
								{
									SET P_att TO dap:atmo_css().

								}
).

UNTIL FALSE{
	
	SET pitchprog TO get_pitch_prograde().
	SET rollprog TO get_roll_prograde().
	
	
	//predict vehicle position some time ahead
	
	LOCAL ICS IS LEXICON(
					 "position",-SHIP:ORBIT:BODY:POSITION,
	                 "velocity",SHIP:VELOCITY:ORBIT
	).
	LOCAL simstate IS blank_simstate(ICS).
	SET simstate TO rk3(sim_settings["deltat"],simstate,LIST(pitchprog,rollprog)).
	
	
	SET simstate["altitude"] TO bodyalt(simstate["position"]).
	SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).
	SET simstate["latlong"] TO shift_pos(simstate["position"],simstate["simtime"]).
	
	SET mode tO mode_switch(simstate,tgtrwy,vehicle_params).
	
	LOCAL deltas IS LIST(0,0).
	
	
	IF mode=3 {
		SET deltas TO mode3(simstate,tgtrwy,vehicle_params).
	}
	ELSE IF mode=4 {
		
		SET deltas TO mode4(simstate,tgtrwy,vehicle_params).
	}
	ELSE IF mode=5  {
		SET sim_settings["delta_t"] TO 1.
		SET deltas TO mode5(simstate,tgtrwy,vehicle_params).
	}
	ELSE IF mode=6 {
		SET sim_settings["delta_t"] TO 1.
		SET deltas TO mode6(simstate,tgtrwy,vehicle_params).
	}
	
	speed_control(is_autoairbk(),airbrake_control,mode).
	
	flaptrim_control(flptrm:PRESSED, flap_control).
	
	


	update_apch_GUI(
		mode,
		deltas,
		mode_dist(simstate,tgtrwy,vehicle_params),
		airbrake_control["deflection"],
		flap_control["deflection"],
		update_nz(
						-SHIP:ORBIT:BODY:POSITION,
						SHIP:VELOCITY:SURFACE,
						LIST(pitchprog,rollprog)
					
					)
	).
	


	if is_log() {

		//prepare list of values to log.
		
		SET loglex["mode"] TO mode.
		SET loglex["time"] TO TIME:SECONDS.
		SET loglex["alt"] TO runway_alt(SHIP:ALTITUDE)/1000.
		SET loglex["speed"] TO SHIP:VELOCITY:SURFACE:MAG. 
		SET loglex["mach"] TO ADDONS:FAR:MACH. 
		SET loglex["hdot"] TO SHIP:VERTICALSPEED.
		SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
		SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
		SET loglex["pitch"] TO get_pitch_lvlh().
		SET loglex["roll"] TO get_roll_lvlh().
		SET loglex["range"] TO total_range_hac_landing(simstate["latlong"],tgtrwy,vehicle_params).
		
		LOCAL outforce IS aeroforce_ld(simstate["position"], simstate["velocity"], LIST(pitchprog, rollprog)).
		SET loglex["l_d"] TO outforce["lift"] / outforce["drag"].

		log_data(loglex,"0:/Shuttle_entrysim/LOGS/entry_log").
	}

	IF quitflag OR (mode>=7 AND SHIP:VELOCITY:SURFACE:MAG < 1) {BREAK.}
	wait 0.

}


}

