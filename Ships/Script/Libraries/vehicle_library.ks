GLOBAL g0 IS 9.80665.



//		vehicle performance functions



//measures current total engine thrust vector and isp of running engines

FUNCTION get_current_thrust_isp {
	
	LOCAL thrvec IS v(0,0,0).
	LOCAL thr IS 0.
	LOCAL isp_ IS 0.
	
	list ENGINES in all_eng.
	FOR e IN all_eng {
		IF e:ISTYPE("engine") {
			IF e:IGNITION {
				LOCAL e_thr IS (e:THRUST * 1000).
				SET thr TO thr + e_thr.
				SET isp_ TO isp_ + e:vacuumisp*e_thr.
				set thrvec to thrvec -e:POSITION:NORMALIZED*e_thr.
			}
		}
	}	
	
	RETURN LIST(thrvec, isp_).
}


//measures theoretical max engine thrust and isp at this altitude
FUNCTION get_max_thrust_isp{

	LOCAL thrvec IS v(0,0,0).
	LOCAL thr IS 0.
	LOCAL isp_ IS 0.
	
	list ENGINES in all_eng.
	FOR e IN all_eng {
		IF e:ISTYPE("engine") {
			IF e:IGNITION {
				LOCAL e_thr IS (e:AVAILABLETHRUST * 1000).
				SET thr TO thr + e_thr.
				SET isp_ TO isp_ + e:vacuumisp*e_thr.
				set thrvec to thrvec -e:POSITION:NORMALIZED*e_thr.
			}
		}
	}	
	
	RETURN LIST(thrvec, isp_).
}

//time to burn at constant thrust given engines
FUNCTION burnDT {
	PARAMETER dV.
	
	
	LOCAL out IS get_max_thrust_isp().
	LOCAL iisp IS out[1].
	LOCAL thr IS out[0]:MAG.
	
	LOCAL vex IS g0*iisp.
	
	LOCAL mdot IS thr/vex.
	
	RETURN (SHIP:MASS*1000/(mdot))*( 1 - CONSTANT:E^(-dV/vex) ).
}



//		vehicle control functions

//compute net thrust vector as thrust-weighted average of engines position 
//relative to the ship raw frame
//obtain the difference between fore vector and thrust vector.
//the 'running_thrust' parameter determined if we measure only the current thrust or 
//the maximum engine thrust regardless of whether it's running or not 
FUNCTION thrustrot {
	PARAMETER ref_fore.
	PARAMETER ref_up.
	PARAMETER running_thrust is TRUE.
	
	local norm is VCRS(ref_fore,ref_up).

	LOCAL thrvec IS v(0,0,0).
	local offs is v(0,0,0).
	LOCAL thr is 0.
	
	list ENGINES in all_eng.
	FOR e IN all_eng {
		IF e:ISTYPE("engine") {
			IF e:IGNITION {
				LOCAL e_thr IS e:MAXTHRUST.
				
				IF (running_thrust) {
					SET e_thr TO e:THRUST.
				}
				
				SET thr TO thr + e_thr.
				//set x to x + 1.
				local vel is -e:POSITION:NORMALIZED*e_thr.
				set offs to offs + vel.
			}
		}
	}	
	set thrvec to (offs/thr):NORMALIZED .
	local ship_fore IS SHIP:FACING:VECTOR:NORMALIZED.
	
	LOCAL newthrvec IS rodrigues(ref_fore,norm,-VANG(ship_fore,thrvec)):NORMALIZED*thrvec:MAG.
	
	RETURN ref_fore - newthrvec.
}


//	Returns a kOS direction for given aim vector, reference up vector and roll angle.
//corrects for thrust offset
FUNCTION aimAndRoll {
	PARAMETER aimVec.
	PARAMETER refVec.
	PARAMETER tgtRollAng.
	PARAMETER running_thrust is TRUE.
		
	LOCAL steerVec IS aimVec.
	
	LOCAL topVec IS VXCL(steerVec,refVec):NORMALIZED.
	SET topVec TO rodrigues(topVec, steerVec, tgtRollAng).
	
	LOCAL thrustCorr IS thrustrot(steerVec, topVec, running_thrust).
	
	LOCAL outdir IS LOOKDIRUP(steerVec + thrustCorr, topVec).

	//clearvecdraws().
	//arrow_ship(topVec,"topVec").
	//arrow_ship(aimVec,"aimVec").
	//arrow_ship(steerVec,"steerVec").
	//arrow_ship(thrustCorr,"thrustCorr").

	RETURN outdir.
}

//converts between absolute throttle value (percentage of max thrust)
//and throttle percentage relative to the range min-max which KSP uses
FUNCTION throtteValueConverter {
	PARAMETER abs_throt.
	PARAMETER minthrot IS 0.

	RETURN CLAMP((abs_throt - minthrot)/(1 - minthrot),0.005,1).
}

//given current vehicle fore vector, computes where the thrust is pointing
FUNCTION thrust_vec {
	RETURN SHIP:FACING:VECTOR:NORMALIZED - thrustrot(SHIP:FACING:FOREVECTOR,SHIP:FACING:TOPVECTOR).
}