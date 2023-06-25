

									//	MATHS FUNCTIONS

//ARITHMETIC FUNCTIONS

FUNCTION SIGN{
	DECLARE PARAMETER var.
	IF var=0 {RETURN 1.}
	LOCAL a IS var/ABS(var).
	IF a>0 {
		RETURN 1.
	} ELSE IF a<0 {
		RETURN -1.
	}
}


//Factorial, calculates a factorial
FUNCTION FACT {
	PARAMETER x.
	
	LOCAL y IS 1.
	
	UNTIL x = 1 OR x = 0 {
		SET y TO y * x.
		SET x TO x - 1.	
	}

	RETURN y.
}

//limits the input between -1 and 1, useful for arguments of trg functions.
FUNCTION limitarg{
	parameter in.
	return MAX(-1,MIN(1,in)).
}


//limits the imput within the range specified by two numbers 
function clamp {
	PARAMETER val.
	PARAMETER minn.
	PARAMETER maxx.
	
	IF maxx>minn {
		RETURN MAX(minn, MIN( maxx, val ) ).
	} ELSE {
		RETURN MAX(maxx, MIN( minn, val ) ).
	}


}

//the value of the argument which is algebraically between the other two
function midval {
	parameter x_.
	parameter y_.
	parameter z_.
	
	local maxx is max(max(x_, y_), z_).
	local minn is min(min(x_, y_), z_).
	
	return x_ + y_ + z_ - maxx - minn.
	
	//if ((x_ >= y_ AND x_ <= z_) OR (x_ <= y_ AND x_ >= z_)) {
	//	return x_.
	//} else if ((y_ >= x_ AND y_ <= z_) OR (y_ <= x_ AND y_ >= z_)) {
	//	return y_.
	//} else {
	//	return z_.
	//}
}

//keeps a value within the interval starting from lower_val and lower_val + int_width, wrapping around if it falls outside
FUNCTION wraparound {
	PARAMETER val.
	PARAMETER lower_val.
	PARAMETER int_width.
	if val <lower_val {set val to val + int_width. }
	else if val >=(lower_val + int_width) {set val to val - int_width. }	
	RETURN val.
}

//prevents angles from being either negative or greater than 360.
FUNCTION fixangle {
	parameter angle.
	if angle <0 {set angle to angle + 360. }
	else if angle >=360 {set angle to angle - 360. }	
	RETURN angle.
}

//prevents angles from being less than -180 or greater than 180
FUNCTION unfixangle {
	parameter angle.
	IF angle <= -180{set angle to angle + 360.}
	ELSE IF angle>180 {set angle to angle - 360.}
	RETURN angle.
}


//radians to degrees
FUNCTION deg2rad {
	PARAMETER deg.
	
	RETURN deg*CONSTANT:PI/180.
}

//degrees to radians
FUNCTION rad2deg {
	PARAMETER rad.
	
	RETURN rad*180/CONSTANT:PI.
}







//linear interpolation of a list of points 
//expects a list of lists with x,y values 
//and the x value 
FUNCTION INTPLIN {
	PARAMETER points.
	PARAMETER x0.
	
	LOCAL listlen IS points:LENGTH.
	
	//if the x point is outside the points tange, clamp it to the nearest y value
	IF (x0 < points[0][0]) {RETURN points[0][1].}
	ELSE IF (x0 > points[listlen-1][0]) {RETURN points[listlen-1][1].}
	
	LOCAL k IS 1.
	FROM {SET k TO 1.} UNTIL k >= (listlen) STEP {set k to k+1.} DO {
		IF ( x0 < points[k][0] ) {BREAK.}
	}	
	
	SET k TO MIN(k,listlen-1).

	LOCAL alph IS (points[k][1] - points[k-1][1])/(points[k][0] - points[k-1][0]).
	RETURN alph*(x0 - points[k-1][0]) + points[k-1][1].


}






//VECTOR FUNCTIONS


// right-handed rotation by angle alph of inVector about the axis defined by zvec
// the function assumes right-handed reference frame
//if left-handed vectors (stock KSP) are passed the rotation is LEFT-handed .
//if a parameter swch is passed with values !=1 the function assumes a left-handed frame 
//and will produce a correct right-handed rotation
FUNCTION rodrigues {
	DECLARE PARAMETER inVector.	//	Expects a vector
	DECLARE PARAMETER zvec.		//	Expects a vector
	DECLARE PARAMETER alph.	//	Expects a scalar
	DECLARe PARAMETER swch IS 1.
	
	SET zvec TO zvec:NORMALIZED.
	
	LOCAL outVector IS inVector*COS(alph).
	IF (swch=1) {
		SET outVector TO outVector + VCRS(zvec, inVector)*SIN(alph).
	}
	ELSE {
		SET outVector TO outVector + CROSS(zvec, inVector)*SIN(alph).
	}
	SET outVector TO outVector + zvec*VDOT(zvec, inVector)*(1-COS(alph)).
	
	RETURN outVector.
}


//	KSP-MATLAB-KSP vector conversion
FUNCTION vecYZ {
	DECLARE PARAMETER input.	//	Expects a vector
	LOCAL output IS V(input:X, input:Z, input:Y).
	RETURN output.
}

//implements right-handed cross-product in a left-handed reference frame
//only use on KSP vectors
FUNCTION CROSS {
	DECLARE PARAMETER v1.
	DECLARE PARAMETER v2.
	
	LOCAL out IS VCRS(vecYZ(v1), vecYZ(v2)).
	RETURN vecYZ(out).
}

// computes signed angle between two vectors using a reference third vector.
//switch = -1 just returns the raw angle
// switch = 0 returns it in the range -180 - 180
// switch = 1 returns it in the range 0 - 360

FUNCTION signed_angle {
	parameter vec1.
	parameter vec2.
	parameter zvec.
	parameter sw.
	
	SET vec1 TO VXCL(zvec,vec1).
	SET vec2 TO VXCL(zvec,vec2).
	
	local A is vec1:MAG.
	local B is vec2:MAG.
	
	local coss is VDOT(vec1,vec2)/(A*B).
	
	local norm1 IS VCRS(vec1,vec2).
	local norm2 is VCRS(zvec,vec1).
	
	local sinn is ABS(norm1:MAG/(A*B)).
	
	IF VDOT(vec2,norm2)<0 {
		set sinn to -sinn.
	} 
	
	LOCAL out IS ARCTAN2(sinn,coss).
	

	IF sw=0 {RETURN unfixangle(out).}
	ELSE IF sw=1 {RETURN fixangle(out).}
	ELSE IF sw=-1 {RETURN out.}

}


//projects an angle alpha onto a plane inclined relative to the first one by angle beta 

FUNCTION project_angle {
	parameter alphaa.
	parameter betaa.
	
	LOCAL sig IS SIGN(alphaa).

	//LOCAL out IS SIN(ABS(alphaa)/2)/COS(betaa).
	//SET out TO 2*ARCSIN( limitarg(out) ).
	
	
	LOCAL out IS TAN(ABS(alphaa))*COS(ABS(betaa)).
	//SET out TO ARCTAN(limitarg(out)).
	SET out TO ARCTAN(out).
	
	RETURN sig*ABS(out).
}


//extracts the component of a vector a along a unit vector b
FUNCTION vec_comp {
	PARAMETER a.
	PARAMETER b.
	
	SET b TO b:NORMALIZED.
	
	RETURN a - VXCL(b,a).
}






//SPHERICAL TRIGONOMETRY FUNCTIONS


//given a,B and assuming C=90, computes  A.
FUNCTION get_AA_aBB {
	parameter a.
	parameter BB.	
	local AA is ARCCOS( limitarg(SIN(BB)*COS(a)) ).
	RETURN AA.
}



//given b,B and assuming C=90, computes a.
FUNCTION get_a_bBB {
	parameter b.
	parameter BB.
	
	local c is get_c_bBB(b,BB).
	RETURN ARCCOS(limitarg(COS(c)/COS(b))).
}


//given c,B and assuming C=90, computes a.
FUNCTION get_a_cBB {
	parameter c.
	parameter BB.

	local a is 0.
	
	if c<90 {
		set a to ARCSIN( limitarg(SIN(BB)*SIN(c)) ).
		SET a TO ARCCOS( limitarg(COS(c)/COS(a)) ).	
	}
	ELSE if c<180{
		set c to 180 - c.
		set a to ARCSIN( limitarg(SIN(BB)*SIN(c))). 
		set a to 180 - ARCCOS( limitarg(COS(c)/COS(a)) ).
	
	
	
		//set BB to get_A_compl(a,BB).
		//set c to c-90.
		//set a to ARCSIN( limitarg(SIN(BB)*SIN(c)) ).
		//SET a TO 90 + ARCCOS( limitarg(COS(c)/COS(a)) ).	
	}
	return a.
}

//given b,c, and assuming C=90, computes a.
FUNCTION get_a_bc {
	parameter b.
	parameter c.
	
	
	if c>90{ set c to 180 - c.}
	local a IS limitarg(COS(c)/COS(b)).
	SET a TO ARCCOS(a).
	
	
	return a.
}

//given c,B and assuming C=90, computes b.
FUNCTION get_b_cBB {
	parameter c.
	parameter BB.
	
	local b is 0.
	
	if c>90{ set c to 180 - c.}
	
	set b TO limitarg(SIN(BB)*SIN(c)).
	SET b TO ARCSIN(b).

	return b.


}

//given a,b, and assuming C=90, computes c.
FUNCTION get_c_ab {
	parameter a.
	parameter b.
	
	local c is 0.
	
	if a<90 {
		set c to ARCCOS( limitarg(COS(a)*COS(b)) ).
	}
	ELSE if a<180{
		local x is 180 - a.
		set x to ARCCOS( limitarg(COS(x)*COS(b)) ).
		set c to 180 - x.
	}
	ELSE {
		local x is a - 180.
		set x to ARCCOS( limitarg(COS(x)*COS(b)) ).
		set c to 180 + x.
	
	}
	RETURN c.
}


//given a,B, and assuming C=90, computes c.
FUNCTION get_c_aBB {
	parameter a.
	parameter B.
	
	local c is 0.
	
	if a<90 {
		set c to ARCTAN2( TAN(a),COS(B) ).
	}
	ELSE if a<180{
		set B to ABS(B).
		set B to 90 - get_AA_aBB(180 - a,B).	
		set c to 90 + ARCTAN2( TAN(a - 90),COS(B) ).
	}
	ELSE {
		set B to ABS(B).
		set c to 180 + ARCTAN2( TAN(a - 180),COS(B) ).
	
		}
	return c.
}

//given b,B and assuming C=90, computes c.
FUNCTION get_c_bBB {
	parameter b.
	parameter BB.
	
	local c is ARCSIN( limitarg(SIN(b)/SIN(BB)) ).
	RETURN c.

}



//dot product of two vectors in spherical coordinates
FUNCTION spherical_dot {
	parameter v1.
	parameter v2.
	RETURN v1:x*v2:x*(COS(v1:y)*COS(v2:y) + COS(v1:z - v2:z)*SIN(v1:y)*SIN(v2:y)). 
}

//cross product of two vectors in spherical coordinates
FUNCTION spherical_cross {
	parameter vin1.
	parameter vin2.

	local i1 is sphetocart(vin1).
	local i2 is sphetocart(vin2).
	local out is VCRS(i1,i2).
	RETURN carttosphe(out).
}

//convert from spherical coordinates in degrees to cartesian
FUNCTION sphetocart{
	PARAMETER vin.
	
	local x IS vin:x*SIN(vin:z)*COS(vin:y).
	local y is vin:x*SIN(vin:z)*SIN(vin:y).
	local z is vin:x*COS(vin:z).
	RETURN v(x,y,z).
}

//convert from cartesian coordinates to spherical in degrees.
FUNCTION carttosphe {
	PARAMETER vin.
	
	local r_ is SQRT( vin:x^2 + vin:y^2 + vin:z^2 ).
	local t is 0.
	local p is 0.
	
	IF vin:x=0 {
		IF vin:y>0 {
			set t to 90.
		}
		ELSE IF vin:y>0 {
			set t to 0.
		}		
		ELSE {
			set t to 270.
		}
	}
	ELSE {
		set t to fixangle(ARCTAN( vin:y/vin:x )).
	}
	
	IF vin:z=0 {
		set p to 90.
	}
	ELSE {
		set p to fixangle(ARCTAN( SQRT( vin:x^2 + vin:y^2 )/vin:z )).
	}
	
	RETURN v(r_,t,p).
}

//normalises a vector in spherical coordinates
FUNCTION spherical_normalise {
	PARAMETER vin.
	RETURN v(1,vin:y,vin:z).
}



