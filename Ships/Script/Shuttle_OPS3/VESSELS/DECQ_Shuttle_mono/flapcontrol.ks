
FUNCTION flap_control_factory {

	LOCAL this IS LEXICON().
	
	//specify here the part modules to be used as flaps
	//need to be FAR control surface modules 
	//positive deflection means flaps down
	LOCAL flap_parts IS LIST(
						LEXICON(
								"flapmod",SHIP:PARTSDUBBED("ShuttleElevonL")[0]:getmodule("FARControllableSurface"),
								"min_defl",-35,
								"max_defl",20
						),
						LEXICON(
								"flapmod",SHIP:PARTSDUBBED("ShuttleElevonR")[0]:getmodule("FARControllableSurface"),
								"min_defl",-35,
								"max_defl",20
						),
						LEXICON(
								"flapmod",SHIP:PARTSDUBBED("ShuttleBodyFlap")[0]:getmodule("FARControllableSurface"),
								"min_defl",-12,
								"max_defl",22
						)
					).
	
	this:ADD("parts", flap_parts).
	
	this:ADD("activate",{
		
		FOR f in this["parts"] {
			LOCAL fmod IS f["flapmod"].
			IF NOT fmod:GETFIELD("Flp/Splr"). {fmod:SETFIELD("Flp/Splr",TRUE).}
			wait 0.
			fmod:SETFIELD("Flp/Splr Dflct",0). 
			IF NOT fmod:GETFIELD("Flap"). {fmod:SETFIELD("Flap",TRUE).}
			wait 0.
			LOCAL flapset IS fmod:GETFIELD("Flap Setting").
			FROM {local k is flapset.} UNTIL k>3  STEP {set k to k+1.} DO {
				fmod:DOACTION("Increase Flap Deflection", TRUE).
			}
		}
	
	}).
	
	this:ADD("deactivate",{
		
		FOR f in this["parts"] {
			LOCAL fmod IS f["flapmod"].
			LOCAL flapset IS fmod:GETFIELD("Flap Setting").
			LOCAL flapset IS fmod:GETFIELD("Flap Setting").
			FROM {local k is flapset.} UNTIL k=0  STEP {set k to k -1.} DO {
				fmod:DOACTION("Decrease Flap Deflection", TRUE).
			}
		}
	
	}).
	
	this:ADD("deflection", 0).
	
	this:ADD("aoa_feedback", 0).
	
	this:ADD("deflect",{
		PARAMETER deflection.
		
		SET this["deflection"] TO deflection.
		
		FOR f in this["parts"] {
			LOCAL defl IS -this["deflection"]*ABS(f["max_defl"]).
			IF (this["deflection"]<0) {
				SET defl TO -this["deflection"]*ABS(f["min_defl"]).
			}
		
			f["flapmod"]:SETFIELD("Flp/Splr dflct",CLAMP(defl,f["min_defl"],f["max_defl"])).
			
		}
	
	}).
	
	this:ADD("null_deflection",{
		this["deflect"](0).
	}).
	
	this:ADD("set_aoa_feedback",{
		PARAMETER feedback_percentage.
		
		FOR f in this["parts"] {
			LOCAL fmod IS f["flapmod"].
			IF NOT fmod:GETFIELD("std. ctrl"). {fmod:SETFIELD("std. ctrl",TRUE).}
			wait 0.
			fmod:SETFIELD("aoa %",feedback_percentage).  	
		}
		
	}).
	
	this:ADD("pitch_control", average_value_factory(5)).
	
	LISt ENGINES IN englist.
	LOCAL gimbal_ IS 0.
	FOR e IN englist {
		IF e:HASSUFFIX("gimbal") {
			SET gimbal_ TO e:GIMBAL.
			BREAK.
		}
	}
	
	gimbal_:DOACTION("free gimbal", TRUE).
	//gg:DOEVENT("Show actuation toggles").
	gimbal_:DOACTION("toggle gimbal roll", TRUE).
	gimbal_:DOACTION("toggle gimbal yaw", TRUE).
	
	this:ADD("gimbal", gimbal_).
	
	this["activate"]().
	
	RETURN this.

}

//initialise the flap control params
//initialise flaps parts, (body flap + elevons for the Space Shuttle)
//DO NOT CHANGE ANYTHING OTHER THAN THE "parts" SUFFIX!!!
//FLAP PARTS MUST BE FAR CONTROLLABLE SURFACES
//deflection is defined positive downwards
