GLOBAL g0 IS 9.80665.



//		vehicle performance functions

// stg parameters needs to be compatible with the upfg vehicle struct 

//calculates final mass of a constant thrust stage burning for a specific time 
FUNCTION const_f_dt_mfinal {
	PARAMETER stg.
	
	LOCAL red_flow IS stg["engines"]["flow"] * stg["throttle"].
	
	RETURN stg["m_initial"] - red_flow * stg["Tstage"].
}

//calculates burn time for a constant thrust stage 
FUNCTION const_f_t {
	PARAMETER stg.

	LOCAL red_flow IS stg["engines"]["flow"] * stg["throttle"].
	IF (red_flow = 0) {
		RETURN 0.
	}
	RETURN stg["m_burn"]/red_flow.	
}


//calculates when the g limit will be violated and the vehicle mass at that moment
//returns (0,0) if the g-lim is never reached
FUNCTION glim_t_m {
	PARAMETER stg.
	local out is LIST(0,0).
	
	local mbreak is stg["engines"]["thrust"] * stg["Throttle"]/(stg["glim"]*g0).
	LOCAL red_flow IS stg["engines"]["flow"] * stg["throttle"].
	
	IF (red_flow > 0) AND (mbreak > stg["m_final"])  {
		SET out[1] TO mbreak.
		SET out[0] TO (stg["m_initial"] - mbreak)/red_flow.
	}
	
	RETURN out.
}

//given a constant g stage calculates the burn time until the lower throttle limit will be reached and the vehicle mass at that moment
FUNCTION const_G_t_m {
	PARAMETER stg.
	local out is LIST(0,0).
	
	//calculate mass of the vehicle at throttle violation 
	LOCAL mviol IS stg["engines"]["thrust"] * stg["engines"]["minThrottle"]/( stg["glim"] * g0 ).
	
	//initialise final mass to stage final mass
	LOCAL m_final IS stg["m_final"].
	
	IF mviol > m_final  {
		SET m_final TO mviol.
	}
	
	SET out[1] TO m_final.
	
	local red_isp is stg["engines"]["isp"]/stg["glim"].
		
	//calculate burn time until we reach the final mass 
	SET out[0] TO red_isp * LN( stg["m_initial"]/m_final ).
		
	RETURN out.
}


//calculates new stage burn time  as a sum of constant g burn time
//and constant t burn time at minimum throttle
FUNCTION glim_stg_time {
	PARAMETER stg_lex.
	
	local glim is stg_lex["glim"].
	LOCAL tt Is 0.
	
	//compute burn time until  we deplete the stage.	
	
	LOCAL maxtime IS (stg_lex["engines"]["isp"]/glim) * LN(1 + stg_lex["m_burn"]/stg_lex["m_final"] ).

	//compute burn time until  we reach minimum throttle.	
	LOCAL limtime IS - stg_lex["engines"]["isp"]/glim * LN(stg_lex["engines"]["minThrottle"]).
	LOCAL constThrustTime IS 0.
	IF limtime < maxtime {
		//	First we calculate mass of the fuel burned until violation
		LOCAL burnedFuel IS stg_lex["m_initial"]*(1 - CONSTANT:E^(-glim*limtime/stg_lex["engines"]["isp"])).
		//	Then, time it will take to burn the rest on constant minimum throttle
		LOCAL minflow IS stg_lex["engines"]["minThrottle"]*stg_lex["engines"]["flow"].
		IF (minflow > 0) {
			SET constThrustTime TO (stg_lex["m_burn"] - burnedFuel  )/minflow.
		}
		SET tt TO limtime + constThrustTime.
	}
	ELSE {
		SET tt TO maxtime.
	}
	SET stg_lex["throt_mult"] TO glim*g0/stg_lex["engines"]["thrust"].
	
	RETURN tt.								
}


FUNCTION get_stg_tanks_res {

	//climb the part tree upwards until we find the part with all the resources
	FUNCTION parts_tree {
		parameter part0.
		parameter partlist.
		parameter resnameslist.
	
		LOCAL parentpart IS part0.
		local breakflag IS FALSE.
		UNTIL FALSE {
		
			LOCAL partresnames IS LIST().
			FOR partres IN parentpart:RESOURCES {
				partresnames:ADD(partres:NAME).
			}
			
			LOCAL foundres IS TRUE.
			FOR resname IN resnameslist {
				SET foundres TO (foundres AND partresnames:CONTAINS(resname)).
			}
			
			IF foundres OR parentpart=CORE:PART OR parentpart=SHIP:ROOTPART { 
				BREAK.
			}
			
			SET parentpart TO parentpart:PARENT.
		}
		
		IF NOT partlist:CONTAINS(parentpart) {
			partlist:ADD( parentpart ).
		}
		
		return partlist.
	}


	PARAMETER stg.
	
	local reslex is LEXICON().
	local tanklist IS LIST().
	
	FOR e in get_running_engines() {		
		LOCAL eng_res IS e:consumedresources:VALUES.
		LOCAL eng_res_names IS LIST().
	
		FOR res IN eng_res {
			eng_res_names:ADD(res:name).
			IF NOT reslex:HASKEY(res:name) {
				reslex:ADD(res:name, res).
			}
		}
		
		SET tanklist TO parts_tree(e:PARENT,tanklist,eng_res_names).
	}
	
	stg:ADD("resources", reslex).
	
	//ignore fuel ducts if already found parts
	IF tanklist:LENGTH=0 {
		LOCAL duct_list IS SHIP:PARTSDUBBED("fuelLine").
		FOR d IN duct_list {
			SET tanklist TO parts_tree(d:PARENT,tanklist,reslex:KEYS).
		}
	}
	stg:ADD("tankparts", tanklist).	
	
}

FUNCTION get_prop_mass {
	PARAMETER stg.
	
	local tanklist is stg["tankparts"].
	local reslex is stg["resources"].
	local prop_mass IS 0.
	
	FOR tk IN tanklist {
		FOR tkres In tk:RESOURCES {
			FOR res IN reslex:VALUES {
				IF tkres:NAME = res:NAME {
					set prop_mass TO prop_mass + tkres:amount * res:DENSITY.
				}
		
			}
		}
	}
	
	set prop_mass to prop_mass*1000.
    RETURN prop_mass.
}


FUNCTION get_running_engines {
	LOCAL running_eng_list Is LIST().
	
	LIST ENGINES IN all_eng.
	FOR e IN all_eng {
		IF e:ISTYPE("engine") {
			IF e:IGNITION {
				running_eng_list:ADD(e).
			}
		}
	}	
	
	RETURN running_eng_list.
}

FUNCTION shutdown_running_engines {
	FOR e IN get_running_engines() {
		e:SHUTDOWN.
	}
}

FUNCTION shutdown_all_engines {
	LIST ENGINES IN all_eng.
	FOR e IN all_eng {
		e:shutdown.
	}	
}

//measures current total engine thrust vector and isp of running engines

FUNCTION get_current_thrust_isp {
	
	LOCAL thrvec IS v(0,0,0).
	LOCAL thr IS 0.
	LOCAL isp_ IS 0.
	
	FOR e IN get_running_engines() {
		LOCAL e_thr IS (e:THRUST * 1000).
		SET thr TO thr + e_thr.
		SET isp_ TO isp_ + e:ISP*e_thr.
		set thrvec to thrvec -e:POSITION:NORMALIZED*e_thr.
	}	
	
	if (thr=0) {
		SET isp_ TO 0.
	} ELSE {
		SET isp_ TO isp_/thr.
	}
	
	RETURN LIST(thrvec, isp_).
}


//measures theoretical max engine thrust and isp at this altitude
FUNCTION get_max_thrust_isp{

	LOCAL thrvec IS v(0,0,0).
	LOCAL thr IS 0.
	LOCAL isp_ IS 0.
	
	FOR e in get_running_engines() {
		LOCAL e_thr IS (e:MAXTHRUSTAT(0) * 1000).
		SET thr TO thr + e_thr.
		SET isp_ TO isp_ + e:ISPAT(0)*e_thr.
		set thrvec to thrvec -e:POSITION:NORMALIZED*e_thr.
	}	
	
	if (thr=0) {
		SET isp_ TO 0.
	} ELSE {
		SET isp_ TO isp_/thr.
	}
	
	RETURN LIST(thrvec, isp_).
}

//time to burn at constant thrust given active engines
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
	
	FOR e in get_running_engines() {
		LOCAL e_thr IS e:MAXTHRUST.
		
		IF (running_thrust) {
			SET e_thr TO e:THRUST.
		}
		
		SET thr TO thr + e_thr.
		//set x to x + 1.
		local vel is -e:POSITION:NORMALIZED*e_thr.
		set offs to offs + vel.
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