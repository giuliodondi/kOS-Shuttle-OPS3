

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
	
	

	this["activate"]().
	
	WAIT 0.
	
	this["deflect"]().
	
	RETURN this.
}