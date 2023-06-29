

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
	
	LOCAL eta_ IS (sma * (1 - ecc^2) / h - 1) / ecc.
	
	RETURN ARCCOS(eta_).
}
	
//calculates fpa at altitude
//altitude must be measured from the body centre
function orbit_alt_fpa {
	parameter h.
	parameter sma.
	parameter ecc.
	
	LOCAL eta_ IS orbit_alt_eta(h, sma, ecc).
	
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
<<<<<<< HEAD
=======

}
>>>>>>> 5fc0ba6 (library update)

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

//returns the current flight path angle with respect to the local horizontal
function get_fpa {
	parameter vec.
	PARAMETER geopos.
	
	LOCAL upvec IS pos2vec(geopos):NORMALIZED.
	LOCAL velproj IS VXCL(upvec,vec).
	
	LOCAL rightvec IS -VCRS(velproj,vec):NORMALIZED.
	
	RETURN signed_angle(velproj:NORMALIZED,vec:NORMALIZED,rightvec,0).
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

