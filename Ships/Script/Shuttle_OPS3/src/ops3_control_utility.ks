IF (DEFINED BRAKESPID) {UNSET BRAKESPID.}
IF (DEFINED FLAPPID) {UNSET FLAPPID.}

STEERINGMANAGER:RESETPIDS().
STEERINGMANAGER:RESETTODEFAULT().

SET STEERINGMANAGER:MAXSTOPPINGTIME TO 5.
SET STEERINGMANAGER:PITCHTS TO 8.0.
SET STEERINGMANAGER:YAWTS TO 3.
SET STEERINGMANAGER:ROLLTS TO 2.

SET STEERINGMANAGER:PITCHPID:KD TO 0.5.
SET STEERINGMANAGER:YAWPID:KD TO 0.5.
SET STEERINGMANAGER:ROLLPID:KD TO 0.2.

IF (STEERINGMANAGER:PITCHPID:HASSUFFIX("epsilon")) {
	SET STEERINGMANAGER:PITCHPID:EPSILON TO 0.1.
	SET STEERINGMANAGER:YAWPID:EPSILON TO 0.1.
	SET STEERINGMANAGER:ROLLPID:EPSILON TO 0.25.
}


//control functions




FUNCTION dap_nz_controller_factory{

	LOCAL this IS lexicon().

	this:add("enabled", TRUE).
	
	this:add("mode", "atmo_pch_css").
	
	this:add("steering_dir", SHIP:FACINg).
	
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
	
	this:add("lvlh_pitch",0).
	this:add("fpa",0).
	
	this:add("nz", 0).
	
	this:add("measure_cur_state", {
		SET this:prog_pitch TO get_pitch_prograde().
		SET this:prog_roll TO get_roll_prograde().
		SET this:prog_yaw TO get_yaw_prograde().
		
		SET this:lvlh_pitch TO get_pitch_lvlh().
		set this:fpa to get_surf_fpa().
		
		SET this:nz to get_current_nz().
	}).
	
	this:measure_cur_state().
	
	this:add("tgt_nz", 0).
	this:add("tgt_pitch", 0).
	this:add("tgt_roll", 0).
	this:add("tgt_yaw", 0).
	
	this:add("nz_pitch_pid", PIDLOOP(1.95,0,0.08)).
	
	SET this:nz_pitch_pid:SETPOINT TO 0.
	
	
	this:add("update_nz_pid", {
		return -this:nz_pitch_pid:UPDATE(this:last_time, this:tgt_nz - this:nz ).
	}).
	
	this:add("css_roll_lims", LIST(-55, 55)).
	this:add("css_pitch_lims", LIST(-10, 20)).
	
	this:add("steer_pitch",0).
	this:add("steer_lvlh_pitch",0).
	this:add("steer_yaw",0).
	this:add("steer_roll",0).
	
	this:add("reset_steering_angles", {
		set this:steer_pitch to this:prog_pitch.
		set this:steer_roll to this:prog_roll.
		set this:steer_yaw to 0.
	}).
	
	this:add("reset_pch_css", {
		this:reset_steering_angles().
		set this:steer_lvlh_pitch TO this:lvlh_pitch.
	}).
	
	this:add("reset_nz_auto", {
		SET this:tgt_nz TO this:nz.
		this:reset_steering_angles().
	}).
	
	

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
	
	this:add("update", {
		IF (this:mode = "atmo_pch_css") {
			return this:atmo_pch_css().
		} ELSe IF (this:mode = "atmo_nz_auto") {
			return this:atmo_nz_auto().
		}
	}).
	
	this:add("reset_steering",{
		SET this:steering_dir TO SHIP:FACINg.
		IF (this:mode = "atmo_pch_css") {
			this:reset_pch_css().
		} ELSe IF (this:mode = "atmo_nz_auto") {
			this:reset_nz_auto().
		}
	}).
	
	this:add("atmo_nz_auto", {
	
		this:update_time().
		this:measure_cur_state().
		
		
		LOCAL roll_tol IS 8.
		
		SET this:steer_pitch TO this:steer_pitch + this:update_nz_pid().
		
		SET this:steer_roll TO this:prog_roll + CLAMP(this:tgt_roll - this:prog_roll,-roll_tol,roll_tol).
		SET this:steer_yaw TO this:tgt_yaw.
		
		SET this:steer_roll TO CLAMP(this:steer_roll, this:css_roll_lims[0], this:css_roll_lims[1]).
		SET this:steer_pitch TO CLAMP(this:steer_pitch, this:css_pitch_lims[0], this:css_pitch_lims[1]).
		
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll,
			this:steer_yaw
		).
		
		RETURN this:steering_dir.
	
	}).

	this:add("atmo_pch_css", {
	
		this:update_time().
		this:measure_cur_state().
		
		//gains suitable for manoeivrable steerign in atmosphere
		LOCAL rollgain IS 2.
		LOCAL pitchgain IS 0.3.
		LOCAL yawgain IS 2.
		
		//required for continuous pilot input across several funcion calls
		LOCAL time_gain IS ABS(this:iteration_dt/0.03).
		
		//measure input minus the trim settings
		LOCAL deltaroll IS time_gain * rollgain * (SHIP:CONTROL:PILOTROLL - SHIP:CONTROL:PILOTROLLTRIM).
		LOCAL deltapitch IS time_gain * pitchgain * (SHIP:CONTROL:PILOTPITCH - SHIP:CONTROL:PILOTPITCHTRIM).
		LOCAL deltayaw IS time_gain * yawgain * (SHIP:CONTROL:PILOTYAW - SHIP:CONTROL:PILOTYAWTRIM).
		
		LOCAL cosroll IS MAX(ABS(COS(this:steer_roll)), 0.5).
		
		SET this:steer_lvlh_pitch TO this:steer_lvlh_pitch + deltapitch * cosroll.
		
		SET this:steer_pitch TO this:steer_lvlh_pitch / cosroll - (this:fpa /cosroll).
		
		SET this:steer_roll TO this:prog_roll + deltaroll.
		SET this:steer_yaw TO 0 + deltayaw.
		
		SET this:steer_roll TO CLAMP(this:steer_roll, this:css_roll_lims[0], this:css_roll_lims[1]).
		SET this:steer_pitch TO CLAMP(this:steer_pitch, this:css_pitch_lims[0], this:css_pitch_lims[1]).
		
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll,
			this:steer_yaw
		).
		
		RETURN this:steering_dir.
	
	}).
	
	this:add("reentry_css", {
	
		this:update_time().
		this:measure_cur_state().
		
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
		this:measure_cur_state().
		
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
		
		
		print "mode : " + this:mode + "    " at (0,line).
		
		print "loop dt : " + round(this:iteration_dt(),3) + "    " at (0,line + 1).
		
		print "prog pitch : " + round(this:prog_pitch,3) + "    " at (0,line + 2).
		print "prog roll : " + round(this:prog_roll,3) + "    " at (0,line + 3).
		print "prog yaw : " + round(this:prog_yaw,3) + "    " at (0,line + 4).
		print "lvlh pitch : " + round(this:lvlh_pitch,3) + "    " at (0,line + 5).
		print "fpa : " + round(this:fpa,3) + "    " at (0,line + 6).
		
		
		print "steer pitch : " + round(this:steer_pitch,3) + "    " at (0,line + 8).
		print "steer lvlh pitch : " + round(this:steer_lvlh_pitch,3) + "    " at (0,line + 9).
		print "steer roll : " + round(this:steer_roll,3) + "    " at (0,line + 10).
		print "steer yaw : " + round(this:steer_yaw,3) + "    " at (0,line + 11).
		
		print "tgt nz : " + round(this:tgt_nz,3) + "    " at (0,line + 13).
		print "cur nz : " + round(this:nz,3) + "    " at (0,line + 14).
		
	}).
	
	IF (DEFINED SASPITCHPID) {UNSET SASPITCHPID.}
	IF (DEFINED SASROLLPID) {UNSET SASROLLPID.}
	SET STEERINGMANAGER:ROLLCONTROLANGLERANGE TO 180.
	
	this:reset_steering().
	
	return this.

}



FUNCTION dap_hdot_nz_controller_factory{

	LOCAL this IS lexicon().

	this:add("enabled", TRUE).

	this:add("pitch_channel_engaged", TRUE).
	
	this:add("mode", "atmo_pch_css").
	
	this:add("steering_dir", SHIP:FACINg).
	
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
	
	this:add("lvlh_pitch",0).
	this:add("fpa",0).
	
	this:add("hdot", 0).
	this:add("nz", 0).
	
	this:add("measure_cur_state", {
		SET this:prog_pitch TO get_pitch_prograde().
		SET this:prog_roll TO get_roll_prograde().
		SET this:prog_yaw TO get_yaw_prograde().
		
		SET this:lvlh_pitch TO get_pitch_lvlh().
		set this:fpa to get_surf_fpa().
		
		SET this:hdot to SHIP:VERTICALSPEED.
		SET this:nz to get_current_nz().
	}).
	
	this:measure_cur_state().
	
	this:add("tgt_hdot", 0).
	this:add("tgt_nz", 0).
	this:add("tgt_pitch", 0).
	this:add("tgt_roll", 0).
	this:add("tgt_yaw", 0).

	
	
	this:add("hdot_nz_pid", PIDLOOP(0, 0, 0)).
	
	SET this:hdot_nz_pid:SETPOINT TO 0.
	
	//this:add("nz_pitch_pid", PIDLOOP(2.5,0,0.15)).
	this:add("nz_pitch_pid", PIDLOOP(4,0,5.7)).
	
	SET this:nz_pitch_pid:SETPOINT TO 0.
	
	
	this:add("update_hdot_pid", {
		return - this:hdot_nz_pid:UPDATE(this:last_time, this:tgt_hdot - this:hdot ).
	}).
	
	this:add("update_nz_pid", {
		return -this:nz_pitch_pid:UPDATE(this:last_time, this:tgt_nz - this:nz ).
	}).
	
	this:add("nz_lims", LIST(-2.2, 2.2)).
	
	this:add("css_roll_lims", LIST(-55, 55)).
	this:add("css_pitch_lims", LIST(-10, 20)).
	
	this:add("steer_pitch",0).
	this:add("steer_lvlh_pitch",0).
	this:add("steer_yaw",0).
	this:add("steer_roll",0).
	
	this:add("reset_steering_angles", {
		set this:steer_pitch to this:prog_pitch.
		set this:steer_roll to this:prog_roll.
		set this:steer_yaw to 0.
	}).
	
	this:add("reset_pch_css", {
		this:reset_steering_angles().
		set this:steer_lvlh_pitch TO this:lvlh_pitch.
	}).
	
	this:add("reset_hdot_auto", {
		SET this:tgt_hdot TO this:hdot.
		SET this:tgt_nz TO this:nz.
		this:reset_steering_angles().
	}).
	
	this:add("set_taem_pid_gains", {
		local kc is 0.004.

		set this:hdot_nz_pid:Kp to kc.
		set this:hdot_nz_pid:Ki to 0.
		set this:hdot_nz_pid:Kd to kc * 2.9.
	}).

	this:add("set_landing_pid_gains", {
		local kc is 0.003.

		set this:hdot_nz_pid:Kp to kc.
		set this:hdot_nz_pid:Ki to 0.
		set this:hdot_nz_pid:Kd to kc * 4.8.
	}).
	

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
	
	this:add("update", {
		IF (this:mode = "atmo_pch_css") {
			return this:atmo_pch_css().
		} ELSe IF (this:mode = "atmo_hdot_auto") {
			return this:atmo_hdot_auto().
		}
	}).
	
	this:add("reset_steering",{
		SET this:steering_dir TO SHIP:FACINg.
		IF (this:mode = "atmo_pch_css") {
			this:reset_pch_css().
		} ELSe IF (this:mode = "atmo_hdot_auto") {
			this:reset_hdot_auto().
		}
	}).
	
	this:add("atmo_hdot_auto", {
	
		this:update_time().
		this:measure_cur_state().
		
		
		LOCAL roll_tol IS 14.
		
		if (this:pitch_channel_engaged) {
			SET this:tgt_nz TO CLAMP(this:nz + (this:update_hdot_pid()) / COS(this:prog_roll), this:nz_lims[0], this:nz_lims[1]).
			SET this:steer_pitch TO this:steer_pitch + this:update_nz_pid().
		} else {
			SET this:steer_pitch TO this:prog_pitch.
		}
		
		SET this:steer_roll TO this:prog_roll + CLAMP(this:tgt_roll - this:prog_roll,-roll_tol,roll_tol).
		SET this:steer_yaw TO this:tgt_yaw.
		
		SET this:steer_roll TO CLAMP(this:steer_roll, this:css_roll_lims[0], this:css_roll_lims[1]).
		SET this:steer_pitch TO CLAMP(this:steer_pitch, this:css_pitch_lims[0], this:css_pitch_lims[1]).
		
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll,
			this:steer_yaw
		).
		
		RETURN this:steering_dir.
	
	}).

	this:add("atmo_pch_css", {
	
		this:update_time().
		this:measure_cur_state().
		
		//gains suitable for manoeivrable steerign in atmosphere
		LOCAL rollgain IS 2.
		LOCAL pitchgain IS 0.3.
		LOCAL yawgain IS 2.
		
		//required for continuous pilot input across several funcion calls
		LOCAL time_gain IS ABS(this:iteration_dt/0.03).
		
		//measure input minus the trim settings
		LOCAL deltaroll IS time_gain * rollgain * (SHIP:CONTROL:PILOTROLL - SHIP:CONTROL:PILOTROLLTRIM).
		LOCAL deltapitch IS time_gain * pitchgain * (SHIP:CONTROL:PILOTPITCH - SHIP:CONTROL:PILOTPITCHTRIM).
		LOCAL deltayaw IS time_gain * yawgain * (SHIP:CONTROL:PILOTYAW - SHIP:CONTROL:PILOTYAWTRIM).
		
		LOCAL cosroll IS MAX(ABS(COS(this:steer_roll)), 0.5).
		
		SET this:steer_lvlh_pitch TO this:steer_lvlh_pitch + deltapitch * cosroll.
		
		SET this:steer_pitch TO this:steer_lvlh_pitch / cosroll - (this:fpa /cosroll).
		
		SET this:steer_roll TO this:prog_roll + deltaroll.
		SET this:steer_yaw TO 0 + deltayaw.
		
		SET this:steer_roll TO CLAMP(this:steer_roll, this:css_roll_lims[0], this:css_roll_lims[1]).
		SET this:steer_pitch TO CLAMP(this:steer_pitch, this:css_pitch_lims[0], this:css_pitch_lims[1]).
		
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll,
			this:steer_yaw
		).
		
		RETURN this:steering_dir.
	
	}).
	
	this:add("reentry_css", {
	
		this:update_time().
		this:measure_cur_state().
		
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
		this:measure_cur_state().
		
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
		
		
		print "mode : " + this:mode + "    " at (0,line).
		
		print "loop dt : " + round(this:iteration_dt(),3) + "    " at (0,line + 1).
		
		print "prog pitch : " + round(this:prog_pitch,3) + "    " at (0,line + 2).
		print "prog roll : " + round(this:prog_roll,3) + "    " at (0,line + 3).
		print "prog yaw : " + round(this:prog_yaw,3) + "    " at (0,line + 4).
		print "lvlh pitch : " + round(this:lvlh_pitch,3) + "    " at (0,line + 5).
		print "fpa : " + round(this:fpa,3) + "    " at (0,line + 6).
		
		
		print "steer pitch : " + round(this:steer_pitch,3) + "    " at (0,line + 8).
		print "steer lvlh pitch : " + round(this:steer_lvlh_pitch,3) + "    " at (0,line + 9).
		print "steer roll : " + round(this:steer_roll,3) + "    " at (0,line + 10).
		print "steer yaw : " + round(this:steer_yaw,3) + "    " at (0,line + 11).
		
		print "tgt hdot : " + round(this:tgt_hdot,3) + "    " at (0,line + 13).
		print "cur hdot : " + round(this:hdot,3) + "    " at (0,line + 14).
		
		print "tgt nz : " + round(this:tgt_nz,3) + "    " at (0,line + 16).
		print "cur nz : " + round(this:nz,3) + "    " at (0,line + 17).
		
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


//automatic flap control
FUNCTION  flaptrim_control{
	PARAMETER auto_flag.
	PARAMETER aerosurfaces_control.
	PARAMETER control_deadband IS 0.
	
	
}

reset_pids().


FUNCTION aerosurfaces_control_factory {

	LOCAL this IS LEXICON().
	
	this:ADD(
			"ferram_surfaces", LIST(
									LEXICON(
											"mod",SHIP:PARTSDUBBED("ShuttleElevonL")[0]:getmodule("FARControllableSurface"),
											"flap_defl_max",40,
											"flap_defl_min",-25,
											"spdbk_defl_max",0
									),
									LEXICON(
											"mod",SHIP:PARTSDUBBED("ShuttleElevonR")[0]:getmodule("FARControllableSurface"),
											"flap_defl_max",40,
											"flap_defl_min",-25,
											"spdbk_defl_max",0
									),
									LEXICON(
											"mod",SHIP:PARTSDUBBED("ShuttleBodyFlap")[0]:getmodule("FARControllableSurface"),
											"flap_defl_max",12,
											"flap_defl_min",-22.5,
											"spdbk_defl_max",-8
									)
										
			)
	).
	
	this:ADD("rudders",LIST(
						SHIP:PARTSDUBBED("ShuttleTailControl")[0]:MODULESNAMED("ModuleControlSurface")[0],
						SHIP:PARTSDUBBED("ShuttleTailControl")[0]:MODULESNAMED("ModuleControlSurface")[1]
					)
	).
	
	this:ADD("max_deploy_rudder", 48).
	
	this:ADD("flap_defl", 0).
	this:ADD("spdbk_defl", 0).
	
	this:ADD("gimbal", 0).
	
	this:ADD("activate", {
		FOR bmod IN this["rudders"] {
			bmod:SETFIELD("deploy",TRUE).
		}
		
		for f IN this["ferram_surfaces"] {
			LOCAL fmod IS f["mod"].
			IF NOT fmod:GETFIELD("Flp/Splr"). {
				fmod:SETFIELD("Flp/Splr",TRUE).
			}
			wait 0.
			fmod:SETFIELD("Flap", FALSE).
			WAIT 0.
			fmod:SETFIELD("Spoiler", TRUE).
			WAIT 0.
			fmod:DOACTION("Activate Spoiler", TRUE).
			WAIT 0.
		}
		
		LOCAL found Is FALSE.
		LISt ENGINES IN englist.
		FOR e IN englist {
			IF (e:HASSUFFIX("gimbal")) {
				SET found TO TRUE.
				SET this["gimbal"] TO e:GIMBAL.
				BREAK.
			}
		}
		
		this["gimbal"]:DOACTION("free gimbal", TRUE).
		//gg:DOEVENT("Show actuation toggles").
		this["gimbal"]:DOACTION("toggle gimbal roll", TRUE).
		this["gimbal"]:DOACTION("toggle gimbal yaw", TRUE).
		
	}).
	
	this:ADD("deflect",{
		
		FOR bmod IN this["rudders"] {
			bmod:SETFIELD("Deploy Angle",this["max_deploy_rudder"]*this["spdbk_defl"]). 
		}
		
		for f IN this["ferram_surfaces"] {
			LOCAL flap_defl IS 0.
			
			//invert flap deflection so it's positive upwards
			
			IF (this["flap_defl"] > 0) {
				SET flap_defl TO this["flap_defl"] * f["flap_defl_max"].
			} ELSE {
				SET flap_defl TO ABS(this["flap_defl"]) * f["flap_defl_min"].
			}
			
			LOCAL spdbk_defl IS this["spdbk_defl"] * f["spdbk_defl_max"].
			
			LOCAL fmod IS f["mod"].
			fmod:SETFIELD("Flp/Splr dflct",midval(flap_defl + spdbk_defl, spdbk_defl, flap_defl)).
		}
		
		
	}).
	
	this:ADD("deactivate",{
		FOR bmod IN this["rudders"] {
			bmod:SETFIELD("deploy",FALSE).
		}
		
		for f IN this["ferram_surfaces"] {
			f["mod"]:DOACTION("Activate Spoiler", FALSE).
		}
		
	}).

	this:add("flap_engaged", TRUE).
	
	this:ADD("set_aoa_feedback",{
		PARAMETER feedback_percentage.
		
		FOR f in this["ferram_surfaces"] {
			LOCAL fmod IS f["mod"].
			IF NOT fmod:GETFIELD("std. ctrl"). {fmod:SETFIELD("std. ctrl",TRUE).}
			wait 0.
			fmod:SETFIELD("aoa %",feedback_percentage).  	
		}
		
	}).
	
	this:ADD("pitch_control", average_value_factory(5)).
	
	this:ADD("update", {
		parameter auto_flag.

		 //read off the gimbal angle to get the pitch control input 
		this:pitch_control:update(this:gimbal:PITCHANGLE).

		LOCAL flap_incr IS 0.
		
		If auto_flag {
			LOCAL controlavg IS this:pitch_control:average().
			SET flap_incr TO FLAPPID:UPDATE(TIME:SECONDS,controlavg).
		} ELSE {
			SET flap_incr TO SHIP:CONTROL:PILOTPITCHTRIM.
			SET SHIP:CONTROL:PILOTPITCHTRIM TO 0.
			
		}
		
		if (this:flap_engaged) {
			SET this:flap_defl TO CLAMP(this:flap_defl + flap_incr,-1,1).
		}

		this:deflect().
	}).

	this["activate"]().
	
	WAIT 0.
	
	this["deflect"]().
	
	RETURN this.
}