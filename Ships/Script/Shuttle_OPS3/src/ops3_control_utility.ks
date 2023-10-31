


//control functions




FUNCTION dap_controller_factory{

	LOCAL this IS lexicon().

	this:add("enabled", TRUE).
	
	this:add("steering_dir", SHIP:FACINg).
	
	this:add("reset_steering",{
		SET this:steering_dir TO SHIP:FACINg.
	}).
	
	this:add("last_time", TIME:SECONDS).
	
	this:add("iteration_dt", 0).
	
	this:add("update_time",{
		LOCAL old_t IS this:last_time.
		SET this:last_time TO TIME:SECONDS.
		SET this:iteration_dt TO this:last_time - old_t.
	}).
	
	this:add("prog_pitch",0).
	this:add("prog_yaw",0).
	this:add("prog_roll",0).
	
	this:add("update_prog_angles", {
		SET this:prog_pitch TO get_pitch_prograde().
		SET this:prog_roll TO get_roll_prograde().
		SET this:prog_yaw TO get_yaw_prograde().
	}).
	
	this:update_prog_angles().
	
	this:add("nz", 0).
	
	this:add("update_nz", {
		LOCAL aeroacc IS cur_aeroaccel_ld().
		
		LOCAL g0 IS 9.80665.
		
		SET this:nz to aeroacc["lift"] / g0.
	}).
	
	this:update_nz().
	
	this:add("tgt_nz", 0).
	
	SET this:tgt_nz TO this:nz.
	
	this:add("nz_pitch_pid", PIDLOOP(3.8,0,0.8)).
	
	SET this:nz_pitch_pid:SETPOINT TO 0.
	
	
	this:add("update_nz_pid", {
		return -this:nz_pitch_pid:UPDATE(this:last_time, this:tgt_nz - this:nz ).
	}).
	
	this:add("steer_pitch",0).
	this:add("steer_yaw",0).
	this:add("steer_roll",0).
	
	//by default do not rotate in yaw, to enforce zero sideslip
	this:add("create_prog_steering_dir",{
		PARAMETER pch.
		PARAMETER rll.
		PARAMETER yaw IS 0.
		
		//reference prograde vector about which everything is rotated
		LOCAL progvec is SHIP:srfprograde:vector:NORMALIZED.
		//vector pointing to local up and normal to prograde
		LOCAL upvec IS -SHIP:ORBIT:BODY:POSITION:NORMALIZED.
		
		SET upvec TO VXCL(progvec,upvec):NORMALIZED.
		
		//rotate the up vector by the new roll anglwe
		SET upvec TO rodrigues(upvec, progvec, -rll).
		//create the pitch rotation vector
		LOCAL nv IS VCRS(progvec, upvec).
		//rotate the prograde vector by the pitch angle
		SET upvec TO rodrigues(upvec, nv, pch).
		LOCAL aimv IS rodrigues(progvec, nv, pch).
		
		//clearvecdraws().
		//arrow_ship(upvec, "upvec", 30, 0.02).
		//arrow_ship(aimv, "aimv", 30, 0.02).
		
		//rotate the aim vector by the yaw
		if (ABS(yaw)>0) {
			SET aimv TO rodrigues(aimv, upvec, yaw).
		}
		
		//arrow_ship(aimv, "aimv", 30, 0.02).
		
		RETURN LOOKDIRUP(aimv, upvec).
	}).
	
	this:add("atmo_nz_css", {
	
		this:update_time().
		this:update_prog_angles().
		this:update_nz().
		
		//gains suitable for manoeivrable steerign in atmosphere
		LOCAL rollgain IS 6.
		LOCAL nzgain IS 0.04.
		LOCAL yawgain IS 2.
		
		//required for continuous pilot input across several funcion calls
		LOCAL time_gain IS ABS(this:iteration_dt/0.03).
		
		//measure input minus the trim settings
		LOCAL deltaroll IS time_gain * rollgain * (SHIP:CONTROL:PILOTROLL - SHIP:CONTROL:PILOTROLLTRIM).
		LOCAL deltanz IS time_gain * nzgain * (SHIP:CONTROL:PILOTPITCH - SHIP:CONTROL:PILOTPITCHTRIM).
		LOCAL deltayaw IS time_gain * yawgain * (SHIP:CONTROL:PILOTYAW - SHIP:CONTROL:PILOTYAWTRIM).
		
		SET this:tgt_nz TO this:tgt_nz + deltanz.
		
		SET this:steer_pitch TO this:steer_pitch + this:update_nz_pid().
		
		//apply the deltas to the current angles so the inputs will tend to "ndge" the nose around and then leave it where it is when the controls are released
		SET this:steer_roll TO this:prog_roll + deltaroll.
		SET this:steer_yaw TO 0 + deltayaw.
		
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll,
			this:steer_yaw
		).
		
		RETURN this:steering_dir.
	
	}).

	this:add("atmo_css", {
	
		this:update_time().
		this:update_prog_angles().
		
		//gains suitable for manoeivrable steerign in atmosphere
		LOCAL rollgain IS 6.
		LOCAL pitchgain IS 2.
		LOCAL yawgain IS 2.
		
		//required for continuous pilot input across several funcion calls
		LOCAL time_gain IS ABS(this:iteration_dt/0.03).
		
		//measure input minus the trim settings
		LOCAL deltaroll IS time_gain * rollgain * (SHIP:CONTROL:PILOTROLL - SHIP:CONTROL:PILOTROLLTRIM).
		LOCAL deltapitch IS time_gain * pitchgain * (SHIP:CONTROL:PILOTPITCH - SHIP:CONTROL:PILOTPITCHTRIM).
		LOCAL deltayaw IS time_gain * yawgain * (SHIP:CONTROL:PILOTYAW - SHIP:CONTROL:PILOTYAWTRIM).
		
		//apply the deltas to the current angles so the inputs will tend to "ndge" the nose around and then leave it where it is when the controls are released
		SET this:steer_pitch TO this:prog_pitch + deltapitch.
		SET this:steer_roll TO this:prog_roll + deltaroll.
		SET this:steer_yaw TO this:prog_yaw*0.3 + deltayaw.
		
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll,
			this:steer_yaw
		).
		
		RETURN this:steering_dir.
	
	}).
	
	this:add("reentry_css", {
	
		this:update_time().
		this:update_prog_angles().
		
		LOCAL rollgain IS 1.0.
		LOCAL pitchgain IS 0.4.
		
		//required for continuous pilot input across several funcion calls
		LOCAL time_gain IS ABS(this:iteration_dt/0.07).
		
		LOCAL deltaroll IS time_gain * rollgain*(SHIP:CONTROL:PILOTROLL - SHIP:CONTROL:PILOTROLLTRIM).
		LOCAL deltapitch IS time_gain * pitchgain*(SHIP:CONTROL:PILOTPITCH - SHIP:CONTROL:PILOTPITCHTRIM).
		
		SET this:steer_pitch TO this:prog_pitch + deltapitch.
		SET this:steer_roll TO this:prog_roll + deltaroll.
	
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll
		).
		
		RETURN this:steering_dir.
		
	}).
	
	this:add("reentry_auto",{
		PARAMETER rollguid.
		PARAMETER pitchguid.
		
		this:update_time().
		this:update_prog_angles().
		
		LOCAL pitch_tol IS 8.
		LOCAL roll_tol IS 8.
	
		SET this:steer_roll TO this:prog_roll + CLAMP(rollguid - this:prog_roll,-roll_tol,roll_tol).
		SET this:steer_pitch TO this:prog_pitch + CLAMP(pitchguid - this:prog_pitch,-pitch_tol,pitch_tol).
		
		
		
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll
		).
		
		RETURN this:steering_dir.
	}).
	
	
	this:add("print_debug",{
		PARAMETER line.
		
		print "loop dt : " + round(this:iteration_dt(),3) + "    " at (0,line + 1).
		
		print "prog pitch : " + round(this:prog_pitch,3) + "    " at (0,line + 2).
		print "prog roll : " + round(this:prog_roll,3) + "    " at (0,line + 3).
		print "prog yaw : " + round(this:prog_yaw,3) + "    " at (0,line + 4).
		
		
		print "steer pitch : " + round(this:steer_pitch,3) + "    " at (0,line + 5).
		print "steer roll : " + round(this:steer_roll,3) + "    " at (0,line + 6).
		print "steer yaw : " + round(this:steer_yaw,3) + "    " at (0,line + 7).
		
		print "tgt nz : " + round(this:tgt_nz,3) + "    " at (0,line + 9).
		print "cur nz : " + round(this:nz,3) + "    " at (0,line + 10).
		
	}).
	
	IF (DEFINED SASPITCHPID) {UNSET SASPITCHPID.}
	IF (DEFINED SASROLLPID) {UNSET SASROLLPID.}
	SET STEERINGMANAGER:ROLLCONTROLANGLERANGE TO 180.
	
	this:reset_steering().
	
	return this.

}



FUNCTION reset_pids {
	
	IF (DEFINED FLAPPID) {UNSET FLAPPID.}
	//initialise the flap control pid loop, pid gains rated for deflection as percentage of maximum
	LOCAL Kp IS -0.0375.
	LOCAL Ki IS 0.
	LOCAL Kd IS 0.0214.

	GLOBAL FLAPPID IS PIDLOOP(Kp,Ki,Kd).
	SET FLAPPID:SETPOINT TO 0.
	
	IF (DEFINED BRAKESPID) {UNSET BRAKESPID.}
	//initialise the air brake control pid loop 		
	LOCAL Kp IS -0.004.
	LOCAL Ki IS 0.
	LOCAL Kd IS -0.02.

	GLOBAL BRAKESPID IS PIDLOOP(Kp,Ki,Kd).
	SET BRAKESPID:SETPOINT TO 0.
}

//automatic speedbrake control
FUNCTION speed_control {
	PARAMETER auto_flag.
	PARAMETER aerosurfaces_control.
	PARAMETER mode.
	
	LOCAL previous_val IS aerosurfaces_control["spdbk_defl"].
	
	LOCAL newval IS previous_val.
	
	//automatic speedbrake control
	If auto_flag {

		//above 3000 m/s the autobrake is disabled
		IF SHIP:VELOCITy:SURFACE:MAG<3000 {
			LOCAL tgtspeed IS 0.
			LOCAL delta_spd IS 0.
			LOCAL airspd IS SHIP:VELOCITy:SURFACE:MAG.
			
			IF (mode=1 OR mode=2) {
				LOCAL tgt_rng IS greatcircledist(tgtrwy["position"], SHIP:GEOPOSITION).
				SET tgtspeed TO MAX(250,51.48*tgt_rng^(0.6)).
				SET delta_spd TO airspd - tgtspeed.
			}
			ELSE {
				IF mode=3 {
					SET delta_spd TO airspd - 220.
				}
				ELSE IF mode=4 {
					SET delta_spd TO airspd - 185.
				}
				ELSE IF mode=5 {
					SET delta_spd TO airspd - 150.
				}
				ELSE IF (mode=6 OR mode = 7) {
					SET delta_spd TO airspd - 130.
				}
				ELSE IF mode=8 {
					SET delta_spd TO airspd.
						
					IF airspd < 65 {
						BRAKES ON.
					}
				}
			}
			
			LOCAL delta_spdbk IS CLAMP(BRAKESPID:UPDATE(TIME:SECONDS,delta_spd), -2, 2).
			
			SET newval TO newval + delta_spdbk.
		}
		
	}
	ELSE {
		SET newval TO THROTTLE.

	}
	
	SET aerosurfaces_control["spdbk_defl"] TO CLAMP(newval,0,1).
}


//automatic flap control
FUNCTION  flaptrim_control{
	PARAMETER auto_flag.
	PARAMETER aerosurfaces_control.
	PARAMETER control_deadband IS 0.
	
	//read off the gimbal angle to get the pitch control input 
	aerosurfaces_control["pitch_control"]:update(aerosurfaces_control["gimbal"]:PITCHANGLE).

	LOCAL flap_incr IS 0.
	
	If auto_flag {
		LOCAL controlavg IS aerosurfaces_control["pitch_control"]:average().
		
		IF (ABS(controlavg)>control_deadband) {
			SET flap_incr TO FLAPPID:UPDATE(TIME:SECONDS,controlavg).
		}
		
	} ELSE {
		SET flap_incr TO SHIP:CONTROL:PILOTPITCHTRIM.
		SET SHIP:CONTROL:PILOTPITCHTRIM TO 0.
		
	}
	
	SET aerosurfaces_control["flap_defl"] TO CLAMP(aerosurfaces_control["flap_defl"] + flap_incr,-1,1).
}