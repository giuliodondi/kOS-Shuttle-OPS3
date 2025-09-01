GLOBAL g0 IS 9.80665.

STEERINGMANAGER:RESETPIDS().
STEERINGMANAGER:RESETTODEFAULT().


SET STEERINGMANAGER:PITCHTS TO 8.0.
SET STEERINGMANAGER:YAWTS TO 2.
SET STEERINGMANAGER:ROLLTS TO 5.

SET STEERINGMANAGER:PITCHPID:KD TO 0.5.
SET STEERINGMANAGER:YAWPID:KD TO 0.5.
SET STEERINGMANAGER:ROLLPID:KD TO 0.5.

IF (STEERINGMANAGER:PITCHPID:HASSUFFIX("epsilon")) {
	SET STEERINGMANAGER:PITCHPID:EPSILON TO 0.5.
	SET STEERINGMANAGER:YAWPID:EPSILON TO 0.2.
	SET STEERINGMANAGER:ROLLPID:EPSILON TO 0.6.
}

IF (STEERINGMANAGER:PITCHPID:HASSUFFIX("TORQUEEPSILONMAX")) {
	set STEERINGMANAGER:TORQUEEPSILONMAX TO 0.002.
}


//control functions



FUNCTION dap_controller_factory {
	LOCAL this IS lexicon().
	
	this:add("cur_mode", "").
	this:add("is_css", FALSE).
	
	this:add("steering_dir", SHIP:FACINg).
	
	this:add("last_time", TIME:SECONDS).
	
	this:add("iteration_dt", 0).
	
	this:add("update_time",{
		LOCAL old_t IS this:last_time.
		SET this:last_time TO TIME:SECONDS.
		SET this:iteration_dt TO this:last_time - old_t.
	}).
	
	this:add("delta_roll",0).
	
	this:add("prog_pitch",0).
	this:add("prog_yaw",0).
	this:add("prog_roll",0).
	
	this:add("lvlh_pitch",0).
	this:add("lvlh_roll",0).
	this:add("fpa",0).
	
	this:add("h", 0).
	this:add("hdot", 0).
	this:add("aero", LEXICON(
							"nz", 0,
							"drag", average_value_factory(3),
							"load", average_value_factory(3),
							"lod", average_value_factory(3)
	)).
	
	this:add("wow", FALSE).
	
	this:add("measure_cur_state", {
		this:update_time().
		SET this:prog_pitch TO get_pitch_prograde().
		SET this:prog_roll TO get_roll_prograde().
		SET this:prog_yaw TO get_yaw_prograde().
		
		SET this:lvlh_pitch TO get_pitch_lvlh().
		SET this:lvlh_roll TO get_roll_lvlh().
		set this:fpa to get_surf_fpa().
		
		set this:delta_roll to this:tgt_roll - this:prog_roll.
		
		set this:h to pos_rwy_alt(-SHIP:ORBIT:BODY:POSITION, tgtrwy).
		SET this:hdot to SHIP:VERTICALSPEED.
		
		//drag forces are alyways in imperial
		LOCAL aeroacc IS cur_aeroaccel_ld().		
		SET this:aero:nz to aeroacc["lift"] / g0.
		this:aero:drag:update(aeroacc["drag"]*mt2ft).
		this:aero:load:update(aeroacc["load"]:MAG*mt2ft).

		if (aeroacc["drag"] > 0) {
			this:aero:lod:update(aeroacc["lift"]/aeroacc["drag"]).
		} else {
			this:aero:lod:update(0).
		}

		SET this:wow to measure_wow().
	}).
	
	this:add("tgt_hdot", 0).
	this:add("tgt_nz", 0).
	this:add("tgt_pitch", 0).
	this:add("tgt_roll", 0).
	this:add("tgt_yaw", 0).
	
	this:add("steer_pitch",0).
	this:add("steer_lvlh_pitch",0).
	this:add("steer_yaw",0).
	this:add("steer_roll",0).
	
	
	
	this:add("reset_steering",{
		set this:cur_mode to "".
		set this:steer_pitch to this:prog_pitch.
		set this:steer_roll to this:prog_roll.
		set this:steer_yaw to 0.
		set this:steer_lvlh_pitch TO this:lvlh_pitch.
		set this:tgt_pitch to this:prog_pitch.
		set this:tgt_roll to this:prog_roll.
		set this:tgt_yaw to 0.
		SET this:tgt_hdot TO this:hdot.
		SET this:tgt_nz TO this:aero:nz.
		SET this:steering_dir TO SHIP:FACINg.
		SET this:wow TO FALSE.
		
		this:hdot_nz_pid:RESET.
		this:nz_pitch_pid:RESET.
	}).


	this:add("hdot_nz_pid", PIDLOOP(0, 0, 0)).	
	SET this:hdot_nz_pid:SETPOINT TO 0.
	this:add("update_hdot_pid", {
		return - this:hdot_nz_pid:UPDATE(this:last_time, this:tgt_hdot - this:hdot ).
	}).
	
	this:add("nz_pitch_pid", PIDLOOP(4,0,5.7)).
	SET this:nz_pitch_pid:SETPOINT TO 0.
	this:add("update_nz_pid", {
		return -this:nz_pitch_pid:UPDATE(this:last_time, this:tgt_nz - this:aero:nz ).
	}).
	
	this:add("set_grtls_gains", {
	
		if (this:tgt_nz > 2.2) {
			//will only be used in a contingency nzhold
			set this:nz_pitch_pid:Kp to 1.1.
			set this:nz_pitch_pid:Ki to 0.
			set this:nz_pitch_pid:Kd to 1.4.
		} else {
			set this:nz_pitch_pid:Kp to 2.2.
			set this:nz_pitch_pid:Ki to 0.
			set this:nz_pitch_pid:Kd to 2.8.
		}
	}).
	
	
	this:add("nz_mass_gain", {return 0.8 + 0.007 * (SHIP:MASS - 80).}).
	
	this:add("set_taem_gains", {
		local kc is 0.004.

		set this:hdot_nz_pid:Kp to kc.
		set this:hdot_nz_pid:Ki to kc * 0.
		set this:hdot_nz_pid:Kd to kc * 5.0.
		
		local nz_mass_gain IS this:nz_mass_gain().
		
		set this:nz_pitch_pid:Kp to nz_mass_gain * 3.3.
		set this:nz_pitch_pid:Ki to 0.
		set this:nz_pitch_pid:Kd to nz_mass_gain * 4.2.
	}).

	this:add("set_flare_gains", {
		local kc is 0.0048.

		set this:hdot_nz_pid:Kp to kc.
		set this:hdot_nz_pid:Ki to 0.
		set this:hdot_nz_pid:Kd to kc * 6.0.
		
		local nz_mass_gain IS this:nz_mass_gain().
		
		set this:nz_pitch_pid:Kp to nz_mass_gain * 3.3.
		set this:nz_pitch_pid:Ki to 0.
		set this:nz_pitch_pid:Kd to nz_mass_gain * 3.8.
	}).
	
	//should be consistent with taem nz limits
	this:add("nz_lims", LIST(-2.5, 2.5)).
	this:add("delta_pch_lims", LIST(-3, 3)).
	this:add("delta_lvlh_pch_lims", LIST(-8, 8)).
	this:add("delta_roll_lims", LIST(-8, 8)).
	
	//these are meant to be set by guidance
	this:add("roll_lims", LIST(-60, 60)).
	this:add("pitch_lims", LIST(-10, 20)).
	this:add("css_roll_lims", LIST(-180, 180)).
	this:add("css_pitch_lims", LIST(-10, 20)).
	this:add("yaw_lims", LIST(-5, 5)).
	
	// CSS steering modes
	
	//control prograde pitch and roll
	this:add("update_css_prograde", {
		set this:cur_mode to "css_prograde".
		set this:is_css to TRUE.
		this:measure_cur_state().
		
		LOCAL rollgain IS 0.45.
		LOCAL pitchgain IS 0.12.
		
		//required for continuous pilot input across several funcion calls
		LOCAL time_gain IS ABS(this:iteration_dt/0.07).
		
		LOCAL deltaroll IS time_gain * rollgain*(SHIP:CONTROL:PILOTROLL - SHIP:CONTROL:PILOTROLLTRIM).
		LOCAL deltapitch IS time_gain * pitchgain*(SHIP:CONTROL:PILOTPITCH - SHIP:CONTROL:PILOTPITCHTRIM).
		
		SET this:steer_pitch TO this:steer_pitch + deltapitch.
		SET this:steer_roll TO this:steer_roll + deltaroll.
		SET this:steer_yaw TO 0.
		
		set this:css_pitch_lims to LIST(this:pitch_lims[0]*0.8, this:pitch_lims[1]/0.8).
		
		this:update_steering().
	}).
	
	//control prograde roll and lvlh pitch
	this:add("update_css_lvlh", {
		parameter direct_pitch.
		set this:cur_mode to "css_lvlh".
		set this:is_css to TRUE.
		this:measure_cur_state().
		
		//gains suitable for manoeivrable steerign in atmosphere
		LOCAL rollgain IS 2.5.
		LOCAL yawgain IS 5.
		
		//required for continuous pilot input across several funcion calls
		LOCAL time_gain IS ABS(this:iteration_dt/0.03).
		
		//measure input minus the trim settings
		LOCAL deltaroll IS time_gain * rollgain * (SHIP:CONTROL:PILOTROLL - SHIP:CONTROL:PILOTROLLTRIM).
		LOCAL deltapitch IS time_gain * (SHIP:CONTROL:PILOTPITCH - SHIP:CONTROL:PILOTPITCHTRIM).
		LOCAL deltayaw IS yawgain * (SHIP:CONTROL:PILOTYAW - SHIP:CONTROL:PILOTYAWTRIM).
		
		LOCAL cosroll IS MAX(ABS(COS(this:steer_roll)), 0.766).
		
		IF (this:wow) {
			SET this:steer_pitch TO this:prog_pitch.
		} eLSE {
			if (direct_pitch) {
				LOCAL pitchgain IS 2.2.
				SET this:steer_lvlh_pitch TO this:lvlh_pitch + pitchgain * deltapitch * cosroll.
			} else {
				LOCAL pitchgain IS 0.6.
				SET this:steer_lvlh_pitch TO CLAMP(this:steer_lvlh_pitch + pitchgain * deltapitch * cosroll, this:lvlh_pitch + this:delta_lvlh_pch_lims[0], this:lvlh_pitch + this:delta_lvlh_pch_lims[1]).
			}
			SET this:steer_pitch TO this:steer_lvlh_pitch / cosroll - (this:fpa /cosroll).
		}
			
		SET this:steer_roll TO this:prog_roll + deltaroll.
		SET this:steer_yaw TO deltayaw.
		
		set this:css_pitch_lims to LIST(this:pitch_lims[0]*0.65, this:pitch_lims[1]/0.65).
		
		this:update_steering().
	}).
	
	// AUTO steering modes
	
	//steer directly to target prograde pitch and roll
	this:add("update_auto_prograde", {
		set this:cur_mode to "auto_prograde".
		set this:is_css to FALSE.
		this:measure_cur_state().
		
		SET this:steer_roll TO this:prog_roll + CLAMP(this:delta_roll, this:delta_roll_lims[0], this:delta_roll_lims[1]).
		SET this:steer_pitch TO this:prog_pitch + CLAMP(this:tgt_pitch - this:prog_pitch, this:delta_pch_lims[0], this:delta_pch_lims[1]).
		SET this:steer_yaw TO this:tgt_yaw.
		
		this:update_steering().
	}).
	
	//steer to target roll and keep target nz 
	this:add("update_auto_nz", {
		set this:cur_mode to "auto_nz".
		set this:is_css to FALSE.
		this:measure_cur_state().
		
		IF (NOT this:wow) {
			SET this:steer_pitch TO this:steer_pitch + CLAMP(this:update_nz_pid(), this:delta_pch_lims[0], this:delta_pch_lims[1]).
		}
		
		SET this:steer_roll TO this:prog_roll + CLAMP(this:delta_roll,this:delta_roll_lims[0], this:delta_roll_lims[1]).
		SET this:steer_yaw TO this:tgt_yaw.
		
		this:update_steering().
	}).
	
	//steer to target roll and keep target hdot 
	this:add("update_auto_hdot", {
		set this:cur_mode to "auto_hdot".
		set this:is_css to FALSE.
		this:measure_cur_state().
		
		local delta_roll is this:delta_roll.
		
		IF (NOT this:wow) {
			local roll_corr is max(abs(COS(this:prog_roll)), 0.6).
			SET this:tgt_nz TO CLAMP(this:aero:nz + (this:update_hdot_pid() / roll_corr), this:nz_lims[0], this:nz_lims[1]).
			SET this:steer_pitch TO this:steer_pitch + CLAMP(this:update_nz_pid(), this:delta_pch_lims[0], this:delta_pch_lims[1]).
		}
		
		SET this:steer_roll TO this:prog_roll + CLAMP(delta_roll, this:delta_roll_lims[0], this:delta_roll_lims[1]).
		SET this:steer_yaw TO this:tgt_yaw.
		
		this:update_steering().
	}).
	
	
	this:add("update_steering", {
		local pchlm is this:pitch_lims.
		local rllm is this:roll_lims.
		if (this:is_css) {
			set pchlm to this:css_pitch_lims.
			set rllm to this:css_roll_lims.
		}
	
		//limit absolute steering angles
		SET this:steer_roll TO CLAMP(this:steer_roll, rllm[0], rllm[1]).
		SET this:steer_pitch TO CLAMP(this:steer_pitch, pchlm[0], pchlm[1]).
		SET this:steer_yaw TO CLAMP(this:steer_yaw, this:yaw_lims[0], this:yaw_lims[1]).
		
		//update steering manager
		if (this:is_css) OR (abs(this:delta_roll) >= 8) {
			SET STEERINGMANAGER:MAXSTOPPINGTIME TO 8.
		} else {
			SET STEERINGMANAGER:MAXSTOPPINGTIME TO 0.8.
		}
		
		SET this:steering_dir TO this:create_prog_steering_dir(
			this:steer_pitch,
			this:steer_roll,
			this:steer_yaw
		).
	}).
	
	//by default do not rotate in yaw, to enforce zero sideslip
	this:add("create_prog_steering_dir",{
		PARAMETER pch.
		PARAMETER rll.
		PARAMETER yaw_.
		
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
		if (ABS(yaw_)>0) {
			SET aimv TO rodrigues(aimv, upvec, yaw_).
		}
		
		//arrow_ship(aimv, "aimv", 30, 0.02).
		
		RETURN LOOKDIRUP(aimv, upvec).
	}).
	
	this:add("print_debug",{
		PARAMETER line.
		
		
		print "mode : " + this:cur_mode + "    " at (0,line).
		
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
		print "cur nz : " + round(this:aero:nz,3) + "    " at (0,line + 17).
		
	}).
	
	IF (DEFINED SASPITCHPID) {UNSET SASPITCHPID.}
	IF (DEFINED SASROLLPID) {UNSET SASROLLPID.}
	SET STEERINGMANAGER:ROLLCONTROLANGLERANGE TO 180.
	
	this:reset_steering().
	
	this:measure_cur_state().
	
	return this.
}

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
											"flap_defl_max",22.5,
											"flap_defl_min",-25,
											"spdbk_defl_max",-6
									)
										
			)
	).
	

	local ruddermods is SHIP:PARTSDUBBED("ShuttleTailControl")[0]:MODULESNAMED("ModuleControlSurface").
	
	if (ruddermods:length < 2) {
		print "Error, not enough rudder control modules found" at (0,20).
		return 1/0.
	}
	
	this:ADD("rudders",LIST(
							 ruddermods[0],
							 ruddermods[1]
					)
	).
	
	this:ADD("max_deploy_rudder", 48).
	
	this:ADD("flap_defl", 0).
	this:ADD("spdbk_defl", 0).
	
	this:ADD("gimbal", 0).
	
	this:ADD("flap_pid", PIDLOOP(-0.0375, 0, 0.0214)).
	SET this:flap_pid:SETPOINT TO 0.
	
	
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
		
		set this["gimbal"]:LOCK to false.
		set this["gimbal"]:pitch to true.
		set this["gimbal"]:roll to true.
		set this["gimbal"]:yaw to true.
		
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
		parameter auto_flaps.
		parameter auto_airbk.

		 //read off the gimbal angle to get the pitch control input 
		this:pitch_control:update(this:gimbal:PITCHANGLE).

		LOCAL flap_incr IS 0.
		
		If auto_flaps {
			LOCAL controlavg IS this:pitch_control:average().
			SET flap_incr TO this:flap_pid:UPDATE(TIME:SECONDS,controlavg).
		} ELSE {
			SET flap_incr TO SHIP:CONTROL:PILOTPITCHTRIM.
			SET SHIP:CONTROL:PILOTPITCHTRIM TO 0.
		}
		
		if (NOT auto_airbk) {
			SET this:spdbk_defl TO THROTTLE.
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



function engines_off {
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	shutdown_all_engines().
}