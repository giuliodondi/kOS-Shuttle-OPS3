

									//	NAVIGATION FUNCTIONS


//GENERAL NAVIGATION FUNCTIONS 

//converts a distance between two points on the surface of the body from km into degrees
FUNCTION dist2degrees {
	PARAMETER dist.

	RETURN rad2deg(dist*1000/BODY:RADIUS).
}

//converts a distance between two points on the surface of the body from degrees into km
FUNCTION degrees2dist {
	PARAMETER deg_.
	
	RETURN deg2rad(deg_) * BODY:RADIUS / 1000.

}

//given a position vector returns altitude above the body datum
FUNCTION bodyalt {
	PARAMETER pos.
	
	RETURN pos:MAG - BODY:RADIUS.

}

//converts an inertial velocity into a body-relative velocity
//alos needs the current position vector
FUNCTION surfacevel {
	PARAMETER orbvel.
	PARAMETER pos.

	RETURN orbvel -  vcrs(BODY:angularvel, pos).
}

//converts position and velocity into vertical speed
FUNCTION vspd {
	PARAMETER vel.
	PARAMETER pos.

	RETURN VDOT(pos:NORMALIZED,vel).
}


//get gravitational acceleration
FUNCTION bodygravacc {
	RETURN BODY:MU/(BODY:RADIUS^2).
}



//convert earth-fixed longitude TO celestial longitude
FUNCTION convert_long {
	parameter earthlong.
	parameter mode.

	if mode=1 {
	set earthlong TO earthlong + BODY:ROTATIONANGLE.
	}
	ELSE if mode=0 {
	set earthlong TO earthlong +360 - BODY:ROTATIONANGLE.
	}
	RETURN fixangle(earthlong).
}

//converts Geocoordinates to a position vector 
FUNCTION pos2vec {
	PARAMETER pos.

	RETURN pos:POSITION - SHIP:ORBIT:BODY:POSITION.
}

//converts a position vector to Geocoordinates
function vec2pos {
	parameter posvec.
	//sphere coordinates relative to xyz-coordinates
	local lat is 90 - vang(v(0,1,0), posvec).
	//circle coordinates relative to xz-coordinates
	local equatvec is v(posvec:x, 0, posvec:z).
	local phi is vang(v(1,0,0), equatvec).
	if equatvec:z < 0 {
		set phi to 360 - phi.
	}
	//angle between x-axis and geocoordinates
	local alpha is vang(v(1,0,0), latlng(0,0):position - ship:body:position).
	if (latlng(0,0):position - ship:body:position):z >= 0 {
		set alpha to 360 - alpha.
	}
	return latlng(lat, phi + alpha).
}



//moves a position along the surface of the body by a given time 
//mimics the body's rotation on its axis
//positive time values rotate the position due WEST
FUNCTION shift_pos {
	PARAMETER pos.
	PARAMETER dt.
	
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	
	LOCAL out IS R(0, BODY:angularvel:mag * dt* constant:RadToDeg, 0)*pos.
	
	RETURN vec2pos(out).
}


//given current position, target position, and current vleocity, calculate the azimuth error
//simply calculate the angle between velocity vector and vector pointing to the target
FUNCTION az_error {
	PARAMETEr pos.
	PARAMETER tgt_pos.
	PARAMETER surfv.
	
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	IF tgt_pos:ISTYPE("geocoordinates") {
		SET tgt_pos TO pos2vec(tgt_pos).
	}

		
	//vector normal to vehicle vel and in the same plane as vehicle pos
	//defines the "plane of velocity"
	LOCAL n1 IS VXCL(surfv,pos):NORMALIZED.
	
	//vector pointing from vehicle pos to target, projected "in the plane of velocity"
	LOCAL dr IS VXCL(n1,tgt_pos - pos):NORMALIZED.
	
	//clamp to -180 +180 range
	RETURN signed_angle(
		surfv:NORMALIZED,
		dr,
		n1,
		0
	).
}

// converts azimuth error into distance error given distance, using spherical trig
FUNCTION cross_error {
	PARAMETEr pos.
	PARAMETER tgt_pos.
	PARAMETER surfv.
	PARAMETER  _range. //this is the c side
	
	//this is the B spherical angle
	LOCAL az_err IS az_error(pos,tgt_pos,surfv).
	
	LOCAL p2 IS 180/((SHIP:ORBIT:BODY:RADIUS/1000)*CONSTANT:PI).
	
	RETURN get_b_cBB(_range*p2,az_err)/p2.
	
}



//great-circle distance between two positions
FUNCTION greatcircledist {
	parameter tgt_pos.
	parameter pos.
	
	IF tgt_pos:ISTYPE("geocoordinates") {
		SET tgt_pos TO pos2vec(tgt_pos).
	}
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	
	LOCAL angle IS deg2rad(VANG(tgt_pos,pos)).
	return angle*(BODY:RADIUS/1000).
	
}


//haverrsne formula for the distance between two 
FUNCTION downrangedist{
	parameter tgt_pos.
	parameter pos.
	
	IF tgt_pos:ISTYPE("Vector") {
		SET tgt_pos TO vec2pos(tgt_pos).
	}
	IF pos:ISTYPE("Vector") {
		SET pos TO vec2pos(pos).
	}
	
	
	local deltalong is abs(pos:LNG - tgt_pos:LNG )/2.
	local deltalat is abs(pos:LAT - tgt_pos:LAT)/2.

	local x is SIN(deltalat)^2 + COS(pos:LAT)*COS(tgt_pos:LAT)*SIN(deltalong)^2.
	set x to deg2rad(ARCSIN(SQRT(x))).
	return x*2*(BODY:RADIUS/1000).
}

//azimuth angle from current position to target position
FUNCTION bearingg{
	parameter tgt_pos.
	parameter pos.
	
	IF tgt_pos:ISTYPE("Vector") {
		SET tgt_pos TO vec2pos(tgt_pos).
	}
	IF pos:ISTYPE("Vector") {
		SET pos TO vec2pos(pos).
	}
	
	set dl TO fixangle(tgt_pos:LNG - pos:LNG).

	return 	fixangle(ARCTAN2( SIN(dl)*COS(tgt_pos:LAT), COS(pos:LAT)*SIN(tgt_pos:LAT) - SIN(pos:LAT)*COS(tgt_pos:LAT)*COS(dl) )).
}



//returns geolocation of point at given distance & bearing from position
FUNCTION new_position {
	PARAMETER pos.
	PARAMETER dist.
	PARAMETER bng.
	
	IF pos:ISTYPE("Vector") {
		SET pos TO vec2pos(pos).
	}
	
	
	LOCAL alpha1 IS dist2degrees(dist).
	
	LOCAL lat2 IS ARCSIN( SIN(pos:LAT)*COS(alpha1) + COS(pos:LAT)*SIN(alpha1)*COS(bng) ).
	LOCAL lng2 IS pos:LNG + ARCTAN2( SIN(bng)*SIN(alpha1)*COS(pos:LAT) , COS(alpha1) - SIN(pos:LAT)*SIN(lat2) ).
	
	RETURN LATLNG(lat2,lng2).

}

//returns a vector centered at a position and pointing towards a given azimuth
FUNCTION vector_pos_bearing {
	PARAMETER pos.
	PARAMETER az.
	
	LOCAL northpole IS V(0,1,0).
	LOCAL east_ IS -VCRS(northpole, pos:NORMALIZED).
	LOCAL north_ IS -VCRS(pos:NORMALIZED, east_).
	
	RETURN rodrigues(north_, pos:NORMALIZED, az).

}


//determine which site is the closest to the current position.
// takes in a lexicon of sites which are themselves lexicons
// each must have at least the "position" field defined
FUNCTION get_closest_site {
	PARAMETER sites_lex.

	LOCAL pos IS SHIP:GEOPOSITION.

	LOCAL min_dist IS 0.
	LOCAL closest_site IS 0.
	LOCAL closest_site_idx IS 0.
	LOCAL k IS 0.

	FOR s in sites_lex:KEYS {
		
		LOCAL site IS sites_lex[s].
		LOCAL sitepos IS site["position"].
		
		LOCAL sitedist IS downrangedist(pos,sitepos).

		IF (min_dist = 0) {
			SET min_dist TO sitedist.
			SET closest_site TO sitepos.
			SET closest_site_idx TO k.
		} ELSE {
			IF (min_dist > sitedist) {
				SET min_dist TO sitedist.
				SET closest_site TO sitepos.
				SET closest_site_idx TO k.
			}
		}
		SET k TO k + 1.
	}
	RETURN LIST(closest_site_idx,closest_site).
}


//surface azimuth for an orbit with given inclination and direction at latitude
FUNCTION get_orbit_azimuth {
	PARAMETEr incl.
	PARAMETER lat.
	PARAMETER southerly.
	
	LOCAL retro IS (abs(incl) > 90).
	
	LOCAL equatorial_angle IS incl.
	IF retro {
		SET equatorial_angle TO 180 - equatorial_angle.
	}
	
	LOCAL azimuth IS ABS(COS(equatorial_angle)/COS(lat)).
	SET azimuth TO ARCSIN(limitarg(azimuth)).
	
	//mirror the angle w.r.t. the local north direction for retrograde launches
	IF retro {
		SET azimuth TO - azimuth.
	}
	
	//mirror the angle w.r.t the local east direction for southerly launches
	IF southerly {
		SET azimuth TO 180 - azimuth.
	}
	
	RETURN fixangle(azimuth).	//get the inertial launch hazimuth
}


//ORBITAL MECHANICS FUNCTIONS

// compute all the keplerian orbital elements given the state vector in KSP frame 
function state_vector_orb_elems {
	parameter posvec.
	parameter velvec.
	
	LOCAL rad_vel IS VDOT(velvec, posvec:NORMALIZEd).
	
	LOCAL horiz_vel IS SQRT(velvec:MAG ^ 2 - rad_vel ^ 2 ).
	
	LOCAL ang_mom_vec IS - VCRS(posvec, velvec).	//left-handed
	
	LOCAL incl IS ARCCOS(limitarg(ang_mom_vec:Y / ang_mom_vec:MAG)).
	
	LOCAL north_pole_vec IS V(0, 1, 0).
	
	LOCAL nodevec IS - VCRS(north_pole_vec, ang_mom_vec):NORMALIZED.
	
	LOCAL lan_ IS signed_angle(SOLARPRIMEVECTOR, nodevec, north_pole_vec, 1).
	
	LOCAL ecc_vec IS - VCRS(velvec, ang_mom_vec) / BODY:MU - posvec:NORMALIZED.
	LOCAL ecc_ IS ecc_vec:MAG.
	
	LOCAL periarg IS signed_angle(ecc_vec, nodevec, ang_mom_vec, 1).
	
	LOCAL eta_ IS signed_angle(posvec, ecc_vec, ang_mom_vec, 1).
	
	LOCAL sma_ IS 1/(2/posvec:MAG - velvec:MAG^2/BODY:MU).
	
	LOCAL ap IS (sma_*(1 + ecc_) - BODY:RADIUS)/1000.
	LOCAL pe IS (sma_*(1 - ecc_) - BODY:RADIUS)/1000.
	
	RETURN LEXICON(
			"ap", ap,
			"pe", pe,
			"ecc_", ecc_,
			"incl", incl,
			"lan_", lan_,
			"periarg", periarg,
			"eta_", eta_
	).

}

// compute sma given ap and pe in kilometres
FUNCTION orbit_appe_sma {
	PARAMETER ap_.
	PARAMETER pe_.
	
	return (ap_*1000 + pe_*1000 + 2*BODY:RADIUS)/2.
}

// compute eccentricity given ap and pe in kilometers
FUNCTION orbit_appe_ecc {
	PARAMETER ap_.
	PARAMETER pe_.
	
	RETURN (ap_*1000 - pe_*1000) / (ap_*1000 + pe_*1000 + 2*BODY:RADIUS).

}

//computes time taken from periapsis to given true anomaly
//for differences of true anomalies call twice and subtract times
function eta_to_dt {
	parameter eta_.
	parameter sma.
	parameter ecc.

	local COS_ee IS (ecc + COS(fixangle(eta_)))/(1 + ecc*COS(fixangle(eta_))).

	LOCAL ee IS ARCCOS(limitarg(COS_ee)).			

	LOCAL mean_an IS deg2rad(ee)  - ecc*SIN(ee).
	
	IF eta_>180 { SET mean_an TO 2*CONSTANT:PI - mean_an.}
	
	LOCAL n IS SQRT(sma^3/(SHIP:ORBIT:BODY:MU)).
	

	RETURN n*mean_an.
}

//given true anomaly at t0 and a time interval, computes new true anomaly
//approximation correct at ecc^3

function t_to_eta {
	parameter eta_.
	parameter dt.
	parameter sma.
	parameter ecc.
	
	
	local COS_ee IS (ecc + COS(fixangle(eta_)))/(1 + ecc*COS(fixangle(eta_))). 
	LOCAL ee IS ARCCOS(limitarg(COS_ee)).

	LOCAL mean_an IS deg2rad(ee)  - ecc*SIN(ee).
	
	IF eta_>180 { SET mean_an TO 2*CONSTANT:PI - mean_an.}
	

	LOCAL n IS SQRT(sma^3/(SHIP:ORBIT:BODY:MU)).
	
	SET mean_an TO mean_an + dt/n.
	
	local out is mean_an.
	
	SET mean_an TO  fixangle(rad2deg(mean_an)).

	SET out TO out + ecc*(2*SIN(mean_an) + 1.25*ecc*SIN(2*mean_an)).
	
	RETURN fixangle(rad2deg(out)).

}

//calculates velocity at altitude
//altitude must be measured from the body centre
function orbit_alt_vel {
	parameter h.
	parameter sma.
	
	RETURN SQRT( BODY:MU * ( 2/h - 1/sma  ) ).
}

//calculates eta at altitude
//altitude must be measured from the body centre
function orbit_alt_eta {
	parameter h.
	parameter sma.
	parameter ecc.
	
	IF (ecc = 0) {
		RETURN 0.
	}
	
	LOCAL eta_ IS (sma * (1 - ecc^2) / h - 1) / ecc.
	
	RETURN ARCCOS(limitarg(eta_)).
}

//calculates fpa at altitude
//altitude must be measured from the body centre
function orbit_alt_fpa {
	parameter h.
	parameter sma.
	parameter ecc.
	
	LOCAL eta_ IS orbit_alt_eta(h, sma, ecc).

	RETURN orbit_eta_fpa(eta_, sma, ecc).
}
	
//calculates fpa at given eta
function orbit_eta_fpa {
	parameter eta_.
	parameter sma.
	parameter ecc.
	
	LOCAL gamma IS ecc * SIN(eta_) / (1 + ecc * COS(eta_) ).
	
	//assumed upwards
	RETURN ARCTAN(gamma).
}	

//calculates alttude at given eta
//altitude will be measured from the body centre
FUNCTION orbit_eta_alt {
	parameter eta_.
	parameter sma.
	parameter ecc.
	
	return sma*(1 - ecc^2)/(1 + ecc*COS(eta_)).

}



//VEHICLE-SPECIFIC FUNCTIONS


//get current vehicle roll angle around the surface prograde vector 
FUNCTION get_roll_prograde {
	LOCAL progvec IS SHIP:VELOCITY:SURFACE:NORMALIZED.
	LOCAL shiptopvec IS VXCL(progvec,SHIP:FACING:TOPVECTOR:NORMALIZED):NORMALIZED.
	LOCAL surftopvec IS VXCL(progvec,-SHIP:ORBIT:BODY:POSITION:NORMALIZED):NORMALIZED.
	RETURN signed_angle(shiptopvec,surftopvec,progvec,0).
}

//get current pitch angles from the surface prograde vector
FUNCTION get_pitch_prograde {
	
	//LOCAL topvec IS -SHIP:ORBIT:BODY:POSITION:NORMALIZED.
	LOCAL progvec IS SHIP:VELOCITY:SURFACE:NORMALIZED.
	LOCAL shiptopvec IS VXCL(progvec,SHIP:FACING:TOPVECTOR:NORMALIZED):NORMALIZED.
	LOCAL facingvec IS SHIP:FACING:FOREVECTOR:NORMALIZED.
	LOCAL sidevec IS VCRS(progvec,shiptopvec).

	RETURN signed_angle(
						progvec,
						facingvec,
						sidevec,
						0
	).
}

//get current yaw angle (sideslip) with repsect to the ship vertical
FUNCTION get_yaw_prograde {

	LOCAL progvec IS SHIP:VELOCITY:SURFACE:NORMALIZED.
	LOCAL shiptopvec IS VXCL(progvec,SHIP:FACING:TOPVECTOR:NORMALIZED):NORMALIZED.
	LOCAL facingvec IS SHIP:FACING:FOREVECTOR:NORMALIZED.
	SET facingvec TO VXCL(shiptopvec, facingvec).
	
	RETURN signed_angle(
							progvec,
							facingvec,
							shiptopvec,
							0
		).
}

//legacy wrapper
FUNCTION get_roll{
	RETURN get_roll_prograde().
}

//legacy wrapper
FUNCTION get_pitch {
	RETURN get_pitch_prograde().
}

//get current vehicle roll angle wrt local horizontal and vertical
FUNCTION get_roll_lvlh {
	LOCAL topvec IS -SHIP:ORBIT:BODY:POSITION:NORMALIZED.
	LOCAL horiz_facing IS VXCL(topvec,SHIP:FACING:FOREVECTOR:NORMALIZED):NORMALIZED.
	LOCAL shiptopvec IS VXCL(horiz_facing,SHIP:FACING:TOPVECTOR:NORMALIZED):NORMALIZED.
	
	RETURN signed_angle(shiptopvec,topvec,horiz_facing,0).
}


//get current vehicle pitch angle wrt local horizontal and vertical
FUNCTION get_pitch_lvlh {
	LOCAL topvec IS -SHIP:ORBIT:BODY:POSITION:NORMALIZED.
	LOCAL facingvec IS SHIP:FACING:FOREVECTOR:NORMALIZED.
	LOCAL horiz_facing IS VXCL(topvec,facingvec):NORMALIZED.
	LOCAL sidevec IS VCRS(horiz_facing,topvec).
	RETURN signed_angle(
						horiz_facing,
						facingvec,
						sidevec,
						0
	).
}

//returns the current surface flight path angle with respect to the local horizontal
function get_surf_fpa {
	LOCAL surfv IS SHIP:srfprograde:vector.
	
	LOCAL upvec IS -SHIP:ORBIT:BODY:POSITION.
	
	return get_fpa(upvec, surfv).
}

//calculate generic fpa 
FUNCTION get_fpa {
	PARAMETER pos.
	parameter vel.
	
	LOCAL pos_norm IS pos:NORMALIZED.
	
	LOCAL vel_h IS VXCL(pos_norm,vel).
	
	LOCAL v_rad IS VDOT(vel, pos_norm).
	
	RETURN ARCTAN2(v_rad, vel_h:MAG).
	
}

//returns the vehicle azimuth angle, north is 0 and east is 90
//function compass_for {
//	parameter vec.
//	PARAMETER geopos.
//	
//	LOCAL upp IS pos2vec(geopos).
//	
//	LOCAL eastt IS VCRS(upp,V(0,1,0)):NORMALIZED.
//
//	//LOCAL pointing IS SHIP:facing:forevector.
//	LOCAL northh IS vcrs(eastt,upp):NORMALIZED.
//	
//	LOCAL trig_x IS vdot(northh, vec).
//	LOCAL trig_y IS vdot(eastt, vec).
//	
//	LOCAL result IS arctan2(trig_y, trig_x).
//	
//	RETURN fixangle(result).
//	
//}


function compass_for {
	parameter vel.
	PARAMETER pos.
	
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	
	LOCAL pos IS pos:NORMALIZED.
	
	LOCAL norm IS VCRS(pos,vel):NORMALIZED.
	
	LOCAL newpos IS rodrigues(pos,norm,0.5).
	
	RETURN bearingg(newpos, pos).
	
}




// TARGETING FUNCTIONS

FUNCTION targetLANvec {
	PARAMETER tgtLAN.
	
	return rodrigues(SOLARPRIMEVECTOR, V(0,1,0), - tgtLAN).
}

FUNCTION targetPerivec {
	PARAMETER tgtIncl.
	PARAMETER tgtLAN.
	PARAMETER tgtPeriarg.
	
	LOCAL lanvec IS targetLANvec(tgtLAN).
	LOCAL normvec IS targetNormal(tgtIncl, tgtLAN).
	
	RETURN rodrigues(lanvec, normvec, -tgtPeriarg).

}

//orbital plane vector given inclination and lan 
FUNCTION targetNormal {
	PARAMETER tgtIncl.
	PARAMETER tgtLAN.
	
	//LOCAL highPoint IS rodrigues(SOLARPRIMEVECTOR, V(0,1,0), 90 - tgtLAN).
	//LOCAL rotAxis IS V(-highPoint:Z, highPoint:Y, highPoint:X).
	//RETURN rodrigues(highPoint, rotAxis, 90-tgtIncl):NORMALIZED.
	
	LOCAL lanvec IS targetLANvec(tgtLAN).
	
	return rodrigues(V(0,1,0), lanvec, -tgtIncl).
}

//	Ascending node vector of the orbit passing right over the launch site
FUNCTION node_vector_overhead {
	PARAMETER tgtIncl.
	PARAMETER southerly.
	
	LOCAL shiplngvec IS VXCL(V(0,1,0), -SHIP:ORBIT:BODY:POSITION):NORMALIZED.
	
	LOCAL retro IS (tgtIncl >= 90).
	IF retro {
		SET tgtIncl TO 180 - tgtIncl.
	}
	
	LOCAL dlng IS get_a_bBB(SHIP:GEOPOSITION:LAT, tgtIncl).
	
	IF (southerly) {
		SET dlng TO fixangle(180-dlng).
	}
	
	IF (retro) {
		SET dlng TO fixangle(360-dlng).
	}
	
	return rodrigues(shiplngvec, V(0,1,0), dlng).
}

//calculates the lan of an orbit overhead a certain time in the future
FUNCTION LAN_orbit_overhead {
	PARAMETER tgtIncl.
	PARAMETER southerly.
	PARAMETER time_for.

	LOCAL currentNode IS node_vector_overhead(tgtIncl, southerly).
	
	//arrow_body(SOLARPRIMEVECTOR, "prime").
	//arrow_body(currentNode, "currentNode").
	
	LOCAL currentLan IS signed_angle(currentNode, SOLARPRIMEVECTOR, V(0,1,0), 1).
	
	RETURN currentLan + time_for * 360 / SHIP:ORBIT:BODY:ROTATIONPERIOD.
	 
}

//	Time to next launch opportunity in given direction
FUNCTION orbitInterceptTime {
	PARAMETER tgtIncl.
	PARAMETER tgtLAN.
	PARAMETER southerly.
	
	//	lan vector of the orbit overhead right now
	LOCAL nodevec_now IS node_vector_overhead(tgtIncl, southerly).
	
	//lan vector of the target orbit 
	LOCAL nodevec_tgt IS targetLANvec(tgtLAN).
	
	//arrow_body(nodevec_now, "now").
	//arrow_body(nodevec_tgt, "tgt").
	
	LOCAL dlan IS signed_angle(nodevec_tgt, nodevec_now, V(0,1,0), 1).
	
	RETURN dlan * SHIP:ORBIT:BODY:ROTATIONPERIOD / 360.

}

//	Launch azimuth to a given orbit
FUNCTION launchAzimuth {
	PARAMETER tgtIncl.
	PARAMETER tgtVel.
	PARAMETER southerly.
	PARAMETER override_az_limits IS FALSE.

	//	Expects global variables "target_orbit" as lexicons
	LOCAL shippos IS SHIP:GEOPOSITION.
	LOCAL shiplat IS shippos:LAT.
	
	LOCAL Binertial IS get_orbit_azimuth(tgtIncl, shiplat, southerly).
	
	//get launch azimuth angle wrt due east=0
	LOCAL Vbody IS (2*CONSTANT:PI*SHIP:BODY:RADIUS/SHIP:BODY:ROTATIONPERIOD)*COS(shiplat).
	LOCAL VrotX IS tgtVel*SIN(Binertial)-Vbody.
	LOCAL VrotY IS tgtVel*COS(Binertial).
	LOCAL azimuth IS ARCTAN2(VrotY, VrotX).
	
	//azimuth is the angle wrt the due east direction
	//transform it into an azimuth wrt the north direction
	//this will subtract from 90° if it's a positive angle, due north, and add to 90° if it's due south. wrap around 360°
	LOCAL azimuth IS fixangle(90 - azimuth).
	
	IF (NOT override_az_limits) {
		//implement range azimuth limitation
		//if the launchsite is within 50km of a known site
		//apply its range restrictions
		LOCAL site_azrange IS LEXICON(
							"KSC",LEXICON(
									"position",LATLNG(28.61938,-80.70092),
									"min_az",35,
									"max_az",120
							),
							"Vandenberg",LEXICON(
									"position",LATLNG(34.67974,-120.53102),
									"min_az",147,
									"max_az",220
							)
		
		).
		
		FOR s IN site_azrange:VALUES{
			LOCAL sitepos IS s["position"].
			
			IF downrangedist(sitepos,shippos) < 50 {
				SET azimuth TO CLAMP(azimuth, s["min_az"], s["max_az"]).
				BREAK.
			}
		}
	}
	
	RETURN azimuth.
}