@LAZYGLOBAL OFF.

GLOBAL mt2ft IS 3.28084.		// ft/mt
GLOBAL km2nmi IS 0.539957.	// nmi/km
GLOBAL atm2pa IS 101325.		// atm/pascal
GLOBAL newton2lb IS 0.224809.	//	N/lb
GLOBAL kg2slug IS 14.59390.		// kg/slug
GLOBAL kg2lb IS 0.45359237.		// kg/lb
GLOBAL pa2psf IS newton2lb / (mt2ft^2).		//pascal/psf

//input variables
//		h		//ft height above rwy
//		hdot		//ft/s vert speed
//		x		//ft x component on runway coord
//		y		//ft y component on runway coord
//		surfv 		//ft/s earth relative velocity mag 			//was v
//		surfv_h		//ft/s earth relative velocity horizintal component 				//was vh
//		xdot 	//ft/s component along x direction of earth velocity in runway coord
//		ydot 	//ft/s component along y direction of earth velocity in runway coord
//		psd 		//deg course wrt runway centerline 
//		mach 
//		qbar 	//psf dynamic pressure
//		cosphi 	//cosine of roll 
//		secth 	//secant of pitch 
//		weight 	//slugs mass 
//		tas 		//ft/s true airspeed
//		gamma 	//deg earth relative fpa  

//		gi_change 	//flag indicating desired glideslope based on headwind (ignore it)
//		ovhd  		// ovhd/straight-in flag , it's a 2-elem list, one for each value of rwid 
//		orahac		//automatic downmode inhibit flag , it's a 2-elem list, one for each value of rwid 
//		rwid		//runway id flag  (	1 for primary, 2 for secondary)
//		vtogl	//fps velocity to toggle ovhd/stri hac status (to simulate manual hac toggle, initlaised to zero)



//outputs 
//		nzc 	//g-units normal load factor increment from equilibrium
//		phic_at 	//deg commanded roll 
//		delrng 	//ft range error from altitude profile 
//		dpsac 	//deg heading error to the hac tangent 
//		dsbc_at 	//deg speedbrake command (angle at the hinge line, meaning each panel is deflected by half this????)
//		emep 	//ft energy/weight at which the mep is selected 
//		eow 		//ft energy/weight
//		es 		//ft energy/weight at which the s-turn is initiated 
//		rpred 	//ft predicted range to threshold 
//		iphase 	//phase counter 
//		tg_end 	//termination flag 
//		eas_cmd 	//kn equivalent airspeed commanded 
//		herror 	//ft altitude error
//		qbarf 	//psf filtered dynamic press 
//		ohalrt	//taem automatic downmode flag 
//		mep 		//min entry point flag 


FUNCTION taemg_wrapper {
	PARAMETER taemg_input.
	
	LOCAL taemg_output IS tgexec(
	
	
	).

	RETURN LEXICON(
	
	).
}


//input constants 

//deprecated -> present in sts1 baseline and not in ott baseline
global taemg_constants is lexicon (
									"cdeqd", 0.68113143,	//gain in qbd calculation
									"cpmin", 0.707,		//cosphi min value 
									"cqdg", 0.31886860,		//gain for qbd calculation 
									"cqg", 0.5583958,		//gain for calculation of dnzcd and qbard 
									"cubic_c3", list(0, -4.7714787e-7, -4.7714787e-7),	//ft/ft^2 href curve fit quadratic term
									"cubic_c4", list(0, -2.4291527e-13, -2.4291527e-13),	//ft/ft^2 href curve fit cubic term
									"del_h1", 0.19,				//alt error coeff 
									"del_h2", 900,				//ft alt error coeff 
									"del_r_emax", list(0,54000,54000),		// -/ft/ft constant ised for computing emax 
									"dnzcg", 0.01,		//g-unit/s gain for dnzc
									"dnzlc1", -0.5,		//g-unit phase 0,1,2 nzc lower lim 
									"dnzlc2", -0.5,		//g-unit phase 3 nzc lower lim 
									"dnzuc1", 0.5,		//g-unit phase 0,1,2 nzc upper lim 
									"dnzuc2", 0.5,		//g-unit phase 3 nzc upper lim 
									"dr3", 8000,		//ft delta range val for rpred3
									"dsbcm", 0.95,		//mach at which speedbrake modulation starts 
									"dsblim", 98.6,	//deg dsbc max value 
									"dsbsup", 65,	//deg fixed spdbk deflection at supersonic 
									"dsbil", 20,	//deg min spdbk deflection 
									"dsbnom", 65,		//deg nominal spdbk deflection
									"dshply", 4000,		//ft delta range value in shplyk  	//deprecated
									"dtg", 0.96,		//s taem guid cycle interval
									"dtr", 0.0174533, 		//rad/deg deg2rad
									"edelc1", 1,			//emax calc constant 
									"edelc2", 1,			//emax calc constant 
									"edelnz", list(0, 4000, 4000),			// -/ft/ft eow delta from nominal energy line slope for s-turn
									"edrs", list(0, 0.69946182, 0.69946182),		// -/ ft^2/ft / ft^2/ft slope for s-turn energy line 
									"emep_c1", list(0, list(0,-3263, 12088), list(0, -3263, 12088)),		//all in ft mep energy line y intercept 
									"emep_c2", list(0, list(0,0.51554944, 0.265521), list(0, 0.51554944, 0.265521)),		//all in ft^2/ft mep energy line slope
									"en_c1", list(0, list(0, 949, 15360), list(0, 949, 15360)),		//all ft^2/ft nom energy line y-intercept 
									"en_c2", list(0, list(0, 0.6005, 0.46304), list(0, 0.6005, 0.46304)),		//all ft^2/ft nom energy line slope
									"es1", list(0, 4523, 4523),		//ft y-intercept of s-turn energy line 
									"eow_spt", list(0, 76068, 76068), 	//ft range at which to change slope and y-intercept on the mep and nom energy line 
									"g", 32.174,					//ft/s^2 earth gravity 
									"gamma_coef1", 0.0007,			//deg/ft fpa error coef 
									"gamma_coef2", 3,			//deg fpa error coef 
									"gamma_error", 4,			//deg fpa error band 	//deprecated
									"gamsgs", LIST(0, -22, -22),	//deg a/l steep glideslope angle	//maybe put 24 here?
									"gdhc", 2.0, 			//  constant for computing gdh 
									"gdhll", 0.3, 			//gdh lower limit 
									"gdhs", 7.0e-5,		//1/ft	slope for computing gdh 
									"gdhul", 1.0,			//gdh upper lim 
									"gehdll", 0.01, 		//g/fps  gain used in computing eownzll
									"gehdul", 0.01, 		//g/fps  gain used in computing eownzul
									"gell", 0.1, 		//1/s  gain used in computing eownzll
									"geul", 0.1, 		//1/s  gain used in computing eownzul
									"gphi", 2.5, 		//heading err gain for phic 
									"gr", 0.005,			//deg/ft gain on rcir in computing ha roll angle command 
									"grdot", 0.2,			//deg/fps  gain on drcir/dt in computing ha roll angle command 
									"gsbe", 1.5, 			//deg/psf-s 	spdbk prop. gain on qberr 
									"gsbi", 0.1, 		//deg/psf-s gain on qberr integral in computing spdbk cmd
									"gy", 0.07,			//deg/ft gain on y in computing pfl roll angle cmd 
									"gydot", 0.7,		//deg/fps gain on ydot on computing pfl roll angle cmd 
									"h_error", 1000,		//ft altitude error bound	//deprecated
									"h_ref1", 10000,			//ft alt ref 
									"h_ref2", 5000,			//ft alt ref 
									"hali", LIST(0, 10018, 10018),		//ft altitude at a/l steep gs at MEP
									"hdreqg", 0.1,				//hdreq computation gain 
									"hftc", LIST(0, 12018, 12018),		//ft altitude of a/l steep gs at nominal entry pt
									"machad", 0.75,		//mach to use air data (used in gcomp appendix)
									"mxqbwt", 0.0007368421,		// psf/lb max l/d dyn press for nominal weight		//deprecated 
									"pbgc", LISt(0, 0.1112666, 0.1112666), 		//lin coeff of range for href and lower lim of dhdrrf
									"pbhc", LIST(0, 78161.826, 78161.826), 		//ft alt ref for drpred = pbrc
									"pbrc", LISt(0, 256527.82, 256527.82), 		//ft max range for cubic alt ref 
									"pbrcq", LIST(0, 89971.082, 89971.082), 			//ft range breakpoint for qbref
									"phavgc", 63.33,			//deg constant for phavg
									"phavgll", 30,			//deg lower lim of phavg
									"phavgs", 13.33,		//deg slope for phavg 
									"phavgul", 50, 			//deg upperl im for phavg 
									"philm0", 50,			//deg sturn roll cmd lim
									"philm1", 50,			//deg acq roll cmd lim 
									"philm2", 60,			//deg heading alignment roll cmd lim 
									"philm3", 30, 			//deg prefinal roll cmd lim 
									"philmsup", 30, 		//deg supersonic roll cmd lim 
									"phim", 0.95, 				//mach at which supersonic roll lim is removed
									"phip2c", 30,			//deg constant for phase 3 roll cmd 	//deprecated
									"p2trnc1", 1.1, 		//phase 2 transition logic constant 
									"p2trnc2", 1.01, 		//phase 2 transition logic constant 	//deprecated
									"qb_error1", -1,		//psf dyn press err bound 			//deprecated
									"qb_error2", 24, 		//psf dyn press err bound 
									"qbardl", 5,			//psf/s limit on qbard 
									"qbc1", LISt(0, 3.6086999e-4, 3.6086999e-4), 		//psf/ft slope of qbref dor drpred > pbrcq
									"qbc2", LISt(0, -1.1613301e-3, -1.1613301e-3), 		//psf/ft slope of qbref dor drpred < pbrcq
									"qbg1", 0.1,				//1/s gain for qbnzul and qbnzll
									"qbg2", 0.125,				//s-g/psf gain for qbnzul and qbnzll
									"qbmxs2", 0,			//psf slope of qbmxnz when mach > qbm2	//renamed from qbmx0??
									"qbmx1", 340,			//psf constant for qbmxnz
									"qbmx2", 300,			//psf constant for qbmxnz
									"qbmx3", 300,			//psf constant for qbmxnz
									"qbm1", 1.05,				//mach breakpoint for computing qbmxnz
									"qbm2", 1.7,				//mach breakpoint for computing qbmxnz
									"qbrll", LIST(0, 180, 180),		//psf  qbref ll
									"qbrml", LIST(0, 220, 220),		//psf  qbref ml
									"qbrul", LIST(0, 285, 285),		//psf  qbref ul
									"rerrlm", 7000,			//ft limit of rerrc 		//was 50 deg????
									"rftc", 5,			//s roll fader time const 
									"rminst", LIST(0, 122204.6, 122204.6),		//ft min range allowed to initiate sturn 
									"rn1", LISt(0, 6542.886, 6542.866),			//ft range at which the gain on edelmz goes to zero 	//deprecated
									"rtbias", 3000,			//ft max value of rt for ha initiation		//deprecated
									"rtd", 	57.29578,			//deg/rad rad2teg
									"rturn", 20000,				//ft hac radius 				//deprecated
									"sbmin", 0,				//deg min sbrbk command (was 5)		//deprecated
									"tggs", LISt(0, -0.40402623, -0.40402623), 		//tan of steep gs for autoland 	-22°
									"vco", 1e20, 			//fps constant used in turn compensation 			//deprecated
									"wt_gs1", 8000, 			//slugs max orbiter weight 
									"xa", LIST(0, -5000, -5000),		//steep gs intercept 
									"yerrlm", 280,				//deg limit on yerrc 
									"y_error", 1000,			//ft xrange err bound 		//deprecated
									"y_range1", 0.18,			//xrange coeff 
									"y_range2", 800,			//ft xrange coeff 
									
									//i think the following constants were added once OTT was implemented
									"dr4", 2000,			//ft range from hac for phase 3
									"hmep", LISt(0, 6000, 6000),	//ft mep altitude
									"demxsb", 10000,			//ft max eow error for speedbrakes out 		
									"dhoh1", 0.11,			//alt ref dev/spiral slope
									"dhoh2", 35705,			//ft alt ref dev/spiral range bias
									"dhoh3", 6000,			//ft alt ref dev/spiral max shift of altitude
									"eqlowu", 85000,			//ft upper eow of region for OVHD that qhat qbmxnz is lowered
									"eshfmx", 20000,			//ft max shift of en target at hac 
									"phils", -300,			//deg constant used to calculated philimit
									"pewrr", 0.52,			//partial of en with respect to range at r2max 
									"pqbwrr", 0.006,			//psf / ft partial of qbar with respect to range with constraints of e=en and mach = phim 
									"pshars", 270,				//deg  psha reset value 
									"psrf", 90,				//deg max psha for adjusting rf 
									"psohal", 200, 			//deg min psha to issue ohalrt 
									"psohqb", 0, 			//deg min psha for which qbmxnz is lowered 
									"psstrn", 200,			//deg max psha for s-turn 
									"qbref2", LISt(0, 185, 185),		//psf qbref at r2max 
									"qbmsl1", -0.0288355,			//psf/slug slope of mxqbwt with mach 
									"qbmsl2", -0.00570829,			//psf/slug slope of mxqbwt with mach 
									"qbwt1", -0.0233521,			//psf/slug constant for computing qbll
									"qbwt2", -0.01902763,			//psf/slug constant for computing qbll
									"qbwt3", -0.03113613,			//psf/slug constant for computing qbll
									"qmach1", 0.89,				//mach breakpoint for mxqbwt 
									"qmach2", 1.15,				//mach breakpoint for mxqbwt
									"rfmn", 5000,				//ft min hac spiral radius on final 
									"rfmx", 14000,				//ft max hac spiral radius on final 
									"rf0", 14000,				//ft initial hac spiral radius on final 
									"dnzcdl", 0.1,				//g/sec nzc rate lim 
									"drfk", -3,					//rf adjust gain (-0.8/tan 15°)
									"dsblls", 650,				//deg constant for dsbcll
									"dsbuls", -336,				//deg constant for dsbcul
									"emohc1", LISt(0, -3894, -3894), 		//ft constant eow used ot compute emnoh
									"emohc2", LISt(0, 0.51464, 0.51464), 		//slope of emnoh with range 
									"enbias", 0, 					//ft eow bias for s-turn off 
									"eqlowl", 60000,			//ft lower eow of region for ovhd that wbmxnz is lowered 
									"rmoh", 273500,				//ft min rpred to issue ohalrt 
									"r1", 0, 			//ft/deg linear coeff of hac spiral 
									"r2", 0.093, 			//ft/deg quadratic coeff of hac spiral 
									"r2max", 115000,			//ft max range on hac to be subsonic with nominal qbar 
									"philm4", 60, 				//deg bank lim for large bank command 
									"philmc", 100, 				//deg bank lim for large bank command 
									"qbmxs1", -400,				//psf slope of qbmxnz with mach < qbm1 
									"hmin3", 7000				//min altitude for prefinal
).


//internal variables
global taemg_internal is lexicon(
								"delrng", 0,	//ft range error from altitude profile 
								"dnzc", 0, 
								"dnzcl", 0, 
								"dnzll", 0,
								"dnzul", 0,
								"dpsac", 0,		//deg heading error to the hac tangent 
								"dsbc_at", 0,		//deg speedbrake command (angle at the hinge line, meaning each panel is deflected by half this????)
								"dsbi", 0,	//integral component of delta speedbrake cmd
								"eas_cmd", 0, 		//kn equivalent airspeed commanded 
								"emep", 0,		//ft energy/weight at which the mep is selected 
								"eow", 0,			//ft energy/weight
								"es", 0, 		//ft energy/weight at which the s-turn is initiated 
								"herror", 0, 		//ft altitude error
								"igi", 1,			//glideslope selector from input, based on headwind (we'll ignore it then)
								"igs", 1,			//glideslope selector based on weight 
								"iphase", 0,	//phase counter 
								"ireset", FALSE,
								"isr", 0,
								"mep", FALSE,	//minimum entry point flag
								"nzc", 0, 	//g-units normal load factor increment from equilibrium
								"ohalrt", FALSE,		//one-time flag for  automatic downmoding to straight-in hac
								"ovhd", TRUE,		//overhead flag 
								"phic_at", 0,	//deg commanded roll
								"philm", 0,	//
								"psha", 0, 			//deg hac turn angle 		//moved from inputs
								"qbarf", 0,		//psf filtered dynamic press 
								"qbd", 0,
								"rpred", 0, 		//ft predicted range to threshold 
								"rpred3", 0, 		//phase 3 transition dist
								"rturn", 0,			//hac radius right now
								"rf", 0,		//spiral hac radius on final
								"rwid0", 0,
								"tg_end", FALSE,		//termination flag 
								"xali", 0,			// x coord of apch/land interface
								"xftc", 0,			//x coord where we should arrive on the final apch plane (and place the hac origin)
								"xhac", 0,			//x coord of hac centre
								"xmep", 0,			//x coord of minimum entry point
								"ysgn", 1		//r/l cone indicator (i.e. left/right hac ??)		//moved from inputs

								 	
									
								 								
								
								


).

//this is unfixangle
function res180 {
	parameter ang.
	
	local out is angle.
	
	until (out <= 180) {
		set out to out - 360.
	}
	
	until (out > -180) {
		set out to out + 360.
	}
	
	return out.

}

//phases (iphase):
// 0= s-turn,	1=hac acq,	2=hac turn (hdg),	3=pre-final 
// 4=alpha tran,	5=nz hold,	6=alpha recovery

function tgexec {
	PARAMETER taemg_input.

	if (taemg_internal["ireset"] = TRUE OR taemg_input["rwid"] <> taemg_internal["rwid0"]) {
		tginit(taemg_input).
	}
	
	tgxhac(taemg_input).
	
	gtp(taemg_input).
	
	tgcomp(taemg_input).
	
	tgtran(taemg_input).
	
	tgnzc(taemg_input).

	tgsbc(taemg_input).
	
	tgphic(taemg_input).

	//i want to return a new lexicon of internal variables
	return lexicon(
	
	).

}

FUNCTION tginit {
	PARAMETER taemg_input.
	
	IF (taemg_internal["ireset"] = TRUE) {
		SET taemg_internal["rwid0"] TO taemg_input["rwid"].
	}
	
	SET taemg_internal["iphase"] TO 1.	
	
	SET taemg_internal["isr"] TO taemg_constants["rftc"] / taemg_constants["dtg"].
	
	SET taemg_internal["rf"] TO taemg_internal["rf0"].
	SET taemg_internal["rturn"] TO taemg_internal["rf"].	//i added this bc I don't see rturn being initialised anywhere
	
	SET taemg_internal["mep"] TO FALSE.
	
	SET taemg_internal["ohalrt"] TO FALSE.
	
	SET taemg_internal["dsbi"] TO FALSE.
	
	SET taemg_internal["philm"] TO taemg_constants["philm1"].
	
	
	SET taemg_internal["dnzul"] TO taemg_constants["dnzuc1"]. 
	SET taemg_internal["dnzll"] TO taemg_constants["dnzuc1"]. 
	
	SET taemg_internal["qbarf"] TO taemg_input["qbar"].
	
	SET taemg_input["qbd"] TO 0.
	
	SET taemg_input["tg_end"] TO FALSE.
	
	SET taemg_internal["ireset"] TO FALSE.

}

//runway crs description:
//  origin is at the rwy threshold
// +x is on centreline in the runway direction
// +y is to the right of the runway looking in the +x direction 
// ysgn = +1 is a right turn around a hac placed on the positive y side
									
// these will need to be re-implemented with runway selection logic 
// thoughts:
//	- get rid of the rwid stuff altogether and force runway selection, but can we do it without messing shit up?
//  - i'd like maybe to have a gui message suggesting runway change 
//	- i don't really understand how the ysgn is assigned
FUNCTION tgxhac {
	PARAMETER taemg_input.	
	
	if (taemg_input["surfv"] <= taemg_input["vtogl"]) {
		if (taemg_internal["ovhd"][taemg_input["rwid"]]) {
			SET taemg_internal["ovhd"][taemg_input["rwid"]] TO FALSE.
		} else {
			SET taemg_internal["ovhd"][taemg_input["rwid"]] TO TRUE.
			SET taemg_internal["ysgn"] TO - 1.
		}
		
		SET taemg_internal["psha"] TO taemg_constants["pshars"] .
		
		SET taemg_input["vtogl"] TO 0.		//to disable further toggling
	}
	
	IF (taemg_input["rwid"] <> taemg_internal["rwid0"]) {
		SET taemg_internal["psha"] TO taemg_constants["pshars"] .
		
		if (taemg_internal["ovhd"][taemg_input["rwid"]]) {
			SET taemg_internal["ysgn"] TO - 1.
		}
	}
	
	SET taemg_internal["rwid0"] TO taemg_input["rwid"].
	
	IF (taemg_internal["ohalrt"] AND (NOT taemg_input["orahac"][taemg_input["rwid"]]) AND taemg_internal["ovhd"][taemg_input["rwid"]]) {
		SET taemg_internal["ovhd"][taemg_input["rwid"]] TO FALSE.
		SET taemg_internal["psha"] TO taemg_constants["pshars"] .
	}
	
	IF (NOT taemg_internal["ovhd"][taemg_input["rwid"]]) AND (taemg_internal["iphase"] < 2) {
		//change turn sign to straight-in but only before hac acquisition
		SET taemg_internal["ysgn"] TO 1.
	}
	
	if (taemg_input["weight"] > taemg_constants["wt_gs1"]) {
		set taemg_internal["igs"] to 2.
	} else {
		set taemg_internal["igs"] to 1.
	}
	
	if (taemg_input["gi_change"]) {
		set taemg_internal["igi"] to 2. 
	} ELSE {
		set taemg_internal["igs"] to 1.
	}
	
	set taemg_internal["xftc"] to taemg_constants["xa"][taemg_internal["igi"]] + taemg_constants["hftc"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].
	set taemg_internal["xali"] to taemg_constants["xa"][taemg_internal["igi"]] + taemg_constants["hali"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].

	set taemg_internal["xmep"] to taemg_constants["xa"][taemg_internal["igi"]] + taemg_constants["hmep"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].
	
	if (taemg_internal["mep"]) {
		set taemg_internal["xhac"] TO taemg_internal["xmep"].
	} ELSE {
		set taemg_internal["xhac"] TO taemg_internal["xftc"]. 
	}
	
	set taemg_internal["rpred3"] to -taemg_internal["xhac"] + taemg_constants["dr3"].
	
}	
									
	
FUNCTION gtp {
	PARAMETER taemg_input.	

	//the x-distancebetween current pos and the hac position
	LOCAL xcir IS taemg_internal["xhac"] - taemg_input["x"].
	
	LOCAL signy IS SIGN(taemg_input["y"]).
	
	//if pre-final and very close
	IF (taemg_internal["iphase"] = 3) AND (xcir < taemg_constants["dr4"]) {
		set taemg_internal["rpred"] TO SQRT(taemg_input["x"]^2 + taemg_input["y"]^2).
		RETURN.
	}
	//ELSE
	
	local ycir IS taemg_internal["ysgn"] * taemg_internal["rf"] - taemg_input["y"].
		
	//euclidean distance from orbiter to hac centre in runway coords
	local rcir is SQRT(xcir^2 + ycir^2).
	
	//distance to the tangency point
	LOCAL rtan IS 0.
	IF (rcir > taemg_internal["rturn"]) {
		SET rtan TO SQRT(rcir^2 - taemg_internal["rturn"]^2).
	}
	
	//heading to hac centre 
	local psc is ARCTAN2(ycir, xcir).
	
	//heading to hac tangency pt 
	local pst IS psc.
	if (rtan > 0) {
		set pst to pst - taemg_internal["ysgn"] * ARCTAN2(taemg_internal["rturn"] / rtan).
	}
	
	set pst to res180(pst).
	
	set taemg_internal["dpsac"] to res180(pst - taemg_input["psd"]).
	
	//calculate hac turn angle 
	local pshan is -pst * taemg_internal["ysgn"].
	if ((taemg_internal["psha"] > pshars + 1) or (pshan < -1) or (taemg_internal["ysgn"] <> signy)) and (taemg_internal["psha"] > 90) {
		set pshan to pshan + 360.
	}
	
	SET taemg_internal["psha"] TO pshan.
	SET taemg_internal["rturn"] tO taemg_internal["rf"] + (taemg_constants["r1"] + taemg_constants["r2"] * taemg_internal["psha"]) * taemg_internal["psha"].
	
	//analytical range to go around the hac
	local rpred2 IS (taemg_internal["rf"] + (0.5 * taemg_constants["r1"] + 0.333333 * taemg_constants["r2"] * taemg_internal["psha"]) * taemg_internal["psha"]) * taemg_internal["psha"] * taemg_constants["dtr"] - taemg_internal["xhac"].

	//if s-turn or acq build the hac acquisition turn circle based on velocity and average bank angle as a function of mach
	IF (taemg_internal["iphase"] < 2) {
		local phavg is midval(taemg_constants["phavgc"] - taemg_constants["phavgs"] * taemg_input["mach"], taemg_constants["phavgll"], taemg_constants["phavgul"]).
		local rtac is taemg_input["surfv"] * taemg_input["surfv_h"] / (taemg_constants["g"] * TAN(phavg)).
		local arcac is rtac * ABS(taemg_internal["dpsac"]) * taemg_constants["dtr"].
		
		local a_ IS rtac * (1 - COS(taemg_internal["dpsac"])).
		local b_ IS rtan - rtac * ABS(SIN(taemg_internal["dpsac"])).
		local rc IS SQRT(a_^2 + b_^2).
		
		SET rtan tO arcac + rc.
	}
	
	set taemg_internal["rpred"] TO  rpred2 + rtan.

}	

FUNCTION tgcomp {
	PARAMETER taemg_input.	

}	

FUNCTION tgtran {
	PARAMETER taemg_input.	

}		
	
FUNCTION tgnzc {
	PARAMETER taemg_input.	

}		
									
FUNCTION tgsbc {
	PARAMETER taemg_input.	

}	
								
FUNCTION tgphic {
	PARAMETER taemg_input.	

}								
									
									
