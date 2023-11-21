@LAZYGLOBAL OFF.

GLOBAL mt2ft IS 3.28084.		// ft/mt
GLOBAL km2nmi IS 0.539957.	// nmi/km
GLOBAL atm2pa IS 101325.		// atm/pascal
GLOBAL newton2lb IS 0.224809.	//	N/lb
GLOBAL kg2slug IS 14.59390.		// kg/slug
GLOBAL kg2lb IS 0.45359237.		// kg/lb
GLOBAL pa2psf IS newton2lb / (mt2ft^2).		//pascal/psf	
GLOBAL mps2kt IS 1.94384.			//m/s / knots

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
//		secth 	//secant of pitch 			//not used???			BUT costh is used to limit nzc
//		weight 	//slugs mass 
//		tas 		//ft/s true airspeed		//deprecated, used in dap and true airspeed estimator, don't need those
//		gamma 	//deg earth relative fpa  

//		gi_change 	//flag indicating desired glideslope based on headwind 		//deprecated
//		ovhd  		// ovhd/straight-in flag , it's a 2-elem list, one for each value of rwid 			//changed into a simple flag
//		orahac		//automatic downmode inhibit flag , it's a 2-elem list, one for each value of rwid 		//deprecated
//		rwid		//runway id flag  (	1 for primary, 2 for secondary)
//		vtogl	//fps velocity to toggle ovhd/stri hac status (to simulate automatically a change of hac halfway through)		//deprecated



//outputs 
//		nzc 	//g-units normal load factor increment from equilibrium
//		phic_at 	//deg commanded roll 
//		delrng 	//ft range error from altitude profile 			//calculated as herror / dhdrrf but the calculation is not in the flowcharts nor the level-c???
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
								LEXICON(
										"h", taemg_input["h"] * mt2ft,		//ft height above rwy
										"hdot", taemg_input["hdot"] * mt2ft,	//ft/s vert speed
										"x", taemg_input["x"] * mt2ft,		//ft x component on runway coord
										"y", taemg_input["y"] * mt2ft,		//ft y component on runway coord
										"surfv", taemg_input["surfv"] * mt2ft, 		//ft/s earth relative velocity mag 			//was v
										"surfv_h", taemg_input["surfv_h"] * mt2ft,		//ft/s earth relative velocity horizintal component 				//was vh
										"xdot", taemg_input["xdot"] * mt2ft, 	//ft/s component along x direction of earth velocity in runway coord
										"ydot", taemg_input["ydot"] * mt2ft, 	//ft/s component along y direction of earth velocity in runway coord
										"psd", taemg_input["psd"], 		//deg course wrt runway centerline 
										"mach", taemg_input["mach"], 
										"qbar", taemg_input["qbar"] * atm2pa * pa2psf, 	//psf dynamic pressure
										"cosphi", COS(taemg_input["phi"]), 	//cosine of roll 
										"costh", COS(taemg_input["theta"]), 	//cosine of roll 
										"weight", taemg_input["m"] * kg2slug, 	//slugs mass 
										"gamma", taemg_input["gamma"], 	//deg earth relative fpa  
										"ovhd", taemg_input["ovhd"],  		// ovhd/straight-in flag , it's a 2-elem list, one for each value of rwid 			//changed into a simple flag
										"rwid", taemg_input["rwid"]		//runway id flag  (only needed to detect a runway change, the runway number is fine)
								)
	).

	//dsbc_at needs to be transformed to a 0-1 variable based on max deflection (halved)
	RETURN LEXICON(
					"nzc", taemg_output["nzc"], 	//g-units normal load factor increment from equilibrium
					"phic_at", taemg_output["phic_at"], 	//deg commanded roll 
					"dpsac", taemg_output["dpsac"], 	//deg heading error to the hac tangent 
					"dsbc_at", taemg_output["dsbc_at"] / taemg_constants["dsblim"], 	//deg speedbrake command (angle at the hinge line, meaning each panel is deflected by half this????)
					"emep", taemg_output["emep"] / mt2ft, 	//ft energy/weight at which the mep is selected 
					"eow", taemg_output["eow"] / mt2ft, 		//ft energy/weight
					"es", taemg_output["es"] / mt2ft, 		//ft energy/weight at which the s-turn is initiated 
					"rpred", taemg_output["rpred"] / mt2ft,	//ft predicted range to threshold 
					"iphase", taemg_output["iphase"], 	//phase counter 
					"tg_end", taemg_output["tg_end"], 	//termination flag 
					"eas_cmd", taemg_output["eas_cmd"] / mps2kt, 	//kn equivalent airspeed commanded  (not useful)
					"herror", taemg_output["herror"] / mt2ft, 	//ft altitude error
					"qbarf", taemg_output["qbarf"] / (atm2pa * pa2psf), 	//psf filtered dynamic press 
					"ohalrt", taemg_output["ohalrt"],	//taem automatic downmode flag 
					"mep", taemg_output["mep"] 		//min entry point flag 
	
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
									"h_ref1", 10000,			//ft alt for check to transition to a/l
									"h_ref2", 5000,			//ft alt to force transition to a/l
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
									"rfmin", 5000,				//ft min hac spiral radius on final 
									"rfmax", 14000,				//ft max hac spiral radius on final 
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
									"hmin3", 7000,				//min altitude for prefinal
									"nztotallim", 2,				// my addition from the taem paper
).


//internal variables
global taemg_internal is lexicon(
								"delrng", 0,	//ft range error from altitude profile 
								"dnzc", 0, 
								"dnzcl", 0, 	//limited load factor cmd
								"dnzll", 0,		//lower lim on load fac
								"dnzul", 0,		//upper lim on load fac
								"dpsac", 0,		//deg heading error to the hac tangent 
								"drpred", 0,	//ft range to go to a/l transition
								"dsbc_at", 0,		//deg speedbrake command (angle at the hinge line, meaning each panel is deflected by half this????)
								"dsbi", 0,	//integral component of delta speedbrake cmd
								"eas_cmd", 0, 		//kn equivalent airspeed commanded 
								"emep", 0,		//ft energy/weight at which the mep is selected 
								"eow", 0,			//ft energy/weight
								"en", 			//energy reference
								"es", 0, 		//ft energy/weight at which the s-turn is initiated 
								"hderr", 0, 		//ft hdot error
								"herror", 0, 		//ft altitude error
								"hdref", 0,			//ft/s hdot reference
								"href", 0,			//ft ref altitude
								"iel", 0,			//energy reference profile selector flag
								"igi", 1,			//glideslope selector from input, based on headwind 	//deprecated
								"igs", 1,			//glideslope selector based on weight 
								"iphase", 0,	//phase counter 
								"ireset", TRUE,		//initially true
								"isr", 0,		// pre-final roll fader
								"mep", FALSE,	//minimum entry point flag
								"nzc", 0, 	//g-units normal load factor increment from equilibrium	
								"nztotal", 0, 	//g-units my addition from the taem paper, total normal load factor
								"ohalrt", FALSE,		//one-time flag for  automatic downmoding to straight-in hac
								"ovhd0", TRUE,		//i introduced this to keep track of changes from overhead to straight-in
								//"phi0", 0,		//previous value of phic
								"phic", 0, 			//unlimited roll cmd
								"phic_at", 0,	//deg commanded roll
								"philim", 0,	//deg roll cmd limit
								"psha", 0, 			//deg hac turn angle 		//moved from inputs
								"qberr", 0,			//psf error on qbar
								"qbarf", 0,		//psf filtered dynamic press 
								"qbref", 0,		//psf dyn press ref 
								"qbd", 0,			// delta of qbar
								"rpred", 0, 		//ft predicted total range to threshold 
								"rpred2", 0,		//ft predicted range final + hac turn
								"rpred3", 0, 		//ft predicted range to final for prefinal transition
								"rturn", 0,			//hac radius right now
								"rf", 0,		//spiral hac radius on final
								"rwid0", 0,		//store the runway selection
								"tg_end", FALSE,		//termination flag 
								"xali", 0,			// x coord of apch/land interface	(is negative)
								"xftc", 0,			//x coord where we should arrive on the final apch plane (and place the hac origin) (is negative)
								"xhac", 0,			//x coord of hac centre		(is negative)
								"xmep", 0,			//x coord of minimum entry point	(is negative)
								"ysgn", 1		//r/l cone indicator (i.e. left/right hac ??)		//moved from inputs
								"ysturn", 0,	//sign of s-turn		//renamed from s

								"xcir", 0,		//ft hac centre x-coord
								"ycir", 0,		//ft hac centre y-coord
								"rcir", 0,		//ft ship-hac distance
									
								 								
								
								


).

//phases (iphase):
// 0= s-turn,	1=hac acq,	2=hac turn (hdg),	3=pre-final 
// 4=alpha tran,	5=nz hold,	6=alpha recovery

function tgexec {
	PARAMETER taemg_input.

	if (taemg_internal["ireset"] = TRUE) OR (taemg_input["rwid"] <> taemg_internal["rwid0"]) OR (taemg_input["ovhd"]<>taemg_internal["ovhd0"]) {
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
	RETURN LEXICON(
					"nzc", taemg_internal["nzc"],
					"phic_at", taemg_internal["phic_at"],
					"dpsac", taemg_internal["dpsac"],
					"dsbc_at", taemg_internal["dsbc_at"],
					"emep", taemg_internal["emep"],
					"eow", taemg_internal["eow"], 
					"es", taemg_internal["es"],
					"rpred", taemg_internal["rpred"],
					"iphase", taemg_internal["iphase"],
					"tg_end", taemg_internal["tg_end"],
					"eas_cmd", taemg_internal["eas_cmd"],
					"herror", taemg_internal["herror"],
					"qbarf", taemg_internal["qbarf"],
					"ohalrt", taemg_internal["ohalrt"],	
					"mep", taemg_internal["mep"]
	
	).

}

FUNCTION tginit {
	PARAMETER taemg_input.
	
	IF (taemg_internal["ireset"] = TRUE) {
		SET taemg_internal["rwid0"] TO taemg_input["rwid"].
		SET taemg_internal["ovhd0"] TO taemg_input["ovhd"].
	}
	
	SET taemg_internal["iphase"] TO 1.	
	
	SET taemg_internal["isr"] TO taemg_constants["rftc"] / taemg_constants["dtg"].
	
	SET taemg_internal["rf"] TO taemg_internal["rf0"].
	SET taemg_internal["rturn"] TO taemg_internal["rf"].	//i added this bc I don't see rturn being initialised anywhere	- or should it be initialised to zero??
	
	//moved up from tgxhac bc we want to do this at every reset
	SET taemg_internal["psha"] TO taemg_constants["pshars"] .
	
	SET taemg_internal["mep"] TO FALSE.
	
	SET taemg_internal["ohalrt"] TO FALSE.
	
	SET taemg_internal["dsbi"] TO 0.
	
	SET taemg_internal["philim"] TO taemg_constants["philm1"].
	
	
	SET taemg_internal["dnzul"] TO taemg_constants["dnzuc1"]. 
	SET taemg_internal["dnzll"] TO taemg_constants["dnzlc1"]. 
	
	SET taemg_internal["qbarf"] TO taemg_input["qbar"].
	
	SET taemg_internal["qbd"] TO 0.
	
	//moved up from tgxhac bc there's no reason to do this repeatedly
	if (taemg_input["weight"] > taemg_constants["wt_gs1"]) {
		set taemg_internal["igs"] to 2.
	} else {
		set taemg_internal["igs"] to 1.
	}
	
	
	SET taemg_input["tg_end"] TO FALSE.
	
	SET taemg_internal["ireset"] TO FALSE.

}

//runway crs description:
//  origin is at the rwy threshold
// +x is on centreline in the runway direction
// +y is to the right of the runway looking in the +x direction 
// ysgn = +1 is a right turn around a hac placed on the positive y side
									
// these will need to be re-implemented with runway selection logic in mind
// notes:
//	- get rid of the rwid stuff altogether and force runway selection, but can we do it without messing shit up?
//		- just store the runway id to detect a change, the only thing that depends on it is the overhead flag which we give as input
//  - i'd like maybe to have a gui message suggesting runway change  
//		- we can do it with the 'ohalrt' flag
//	- i don't really understand how the ysgn is assigned 
//		- I overhauled the logic based on the sign of the y coord
FUNCTION tgxhac {
	PARAMETER taemg_input.	
	
	//got rid of the vtogl block
	
	//got rid of the runway re-initialisation code which we moved up
	
	//SET taemg_internal["rwid0"] TO taemg_input["rwid"].
	
	//got rid of the automatic straight-in downmode (if I want ot do it I'll do it outside the guidance exec)
	
	//refactored this block based on the taem paper
	//determine ysgn of the hac turn, but don't change it if we're beyond phase 1
	IF (taemg_internal["iphase"] < 2) {
		
		if (taemg_input["ovhd"]) {
			//for the overhead turn we'll turn around the hac on the opposite side of the runway to our own
			//the ysgn is +1 if the hac is on the +y side so we set the sign to the opposite sign of the current y coord 
			SET taemg_internal["ysgn"] TO - SIGN(taemg_input["y"]). 
		} else {
			//else it's on our same side
			SET taemg_internal["ysgn"] TO SIGN(taemg_input["y"]). 
		}
		
	}
	
	
	set taemg_internal["xftc"] to taemg_constants["xa"][1] + taemg_constants["hftc"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].
	set taemg_internal["xali"] to taemg_constants["xa"][1] + taemg_constants["hali"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].

	set taemg_internal["xmep"] to taemg_constants["xa"][1] + taemg_constants["hmep"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].
	
	if (taemg_internal["mep"]) {
		set taemg_internal["xhac"] TO taemg_internal["xmep"].
	} ELSE {
		set taemg_internal["xhac"] TO taemg_internal["xftc"]. 
	}
	
	set taemg_internal["rpred3"] to -taemg_internal["xhac"] + taemg_constants["dr3"].
	
}	
									
//ground-track predictor
FUNCTION gtp {
	PARAMETER taemg_input.	

	//the x-distancebetween current pos and the hac position
	LOCAL taemg_internal["xcir"] IS taemg_internal["xhac"] - taemg_input["x"].
	
	LOCAL signy IS SIGN(taemg_input["y"]).
	
	//if pre-final and very close
	IF (taemg_internal["iphase"] = 3) AND (taemg_internal["xcir"] < taemg_constants["dr4"]) {
		set taemg_internal["rpred"] TO SQRT(taemg_input["x"]^2 + taemg_input["y"]^2).
		RETURN.
	}
	//ELSE
	
	local taemg_internal["ycir"] IS taemg_internal["ysgn"] * taemg_internal["rf"] - taemg_input["y"].
		
	//euclidean distance from orbiter to hac centre in runway coords
	local taemg_internal["rcir"] is SQRT(taemg_internal["xcir"]^2 + taemg_internal["ycir"]^2).
	
	//distance to the tangency point
	LOCAL rtan IS 0.
	IF (taemg_internal["rcir"] > taemg_internal["rturn"]) {
		SET rtan TO SQRT(taemg_internal["rcir"]^2 - taemg_internal["rturn"]^2).
	}
	
	//heading to hac centre 
	local psc is ARCTAN2(taemg_internal["ycir"], taemg_internal["xcir"]).
	
	//heading to hac tangency pt 
	local pst IS psc.
	if (rtan > 0) {
		set pst to pst - taemg_internal["ysgn"] * ARCTAN2(taemg_internal["rturn"] / rtan).
	}
	
	set pst to unfixangle(pst).
	
	set taemg_internal["dpsac"] to unfixangle(pst - taemg_input["psd"]).
	
	//calculate hac turn angle 
	local pshan is -pst * taemg_internal["ysgn"].
	if ((taemg_internal["psha"] > taemg_constants["pshars"] + 1) or (pshan < -1) or (taemg_internal["ysgn"] <> signy)) and (taemg_internal["psha"] > 90) {
		set pshan to pshan + 360.
	}
	SET taemg_internal["psha"] TO pshan.
	
	//hac radius
	SET taemg_internal["rturn"] tO taemg_internal["rf"] + (taemg_constants["r1"] + taemg_constants["r2"] * taemg_internal["psha"]) * taemg_internal["psha"].
	
	//analytical range to go including hac turn
	set taemg_internal["rpred2"] to - taemg_internal["xhac"] + (taemg_internal["rf"] + (0.5 * taemg_constants["r1"] + 0.333333 * taemg_constants["r2"] * taemg_internal["psha"]) * taemg_internal["psha"]) * taemg_internal["psha"] * taemg_constants["dtr"].

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
	
	set taemg_internal["rpred"] TO  taemg_internal["rpred2"] + rtan.

}	

//reference params, dyn press and spiral adjust function 
FUNCTION tgcomp {
	PARAMETER taemg_input.	
	
	//range to the a/l transition point
	set taemg_internal["drpred"] to taemg_internal["rpred"] + taemg_internal["xali"].
	set taemg_internal["eow"] to taemg_input["h"] + taemg_input["surfv"]^2 / (2 * taemg_constants["g"]).
	
	if (taemg_internal["drpred"] < taemg_constants["eow_spt"][taemg_internal["igs"]]) {
		set taemg_internal["iel"] to 2.
	} else {
		set taemg_internal["iel"] to 1.
	}
	
	set taemg_internal["en"] to taemg_constants["en_c1"][taemg_internal["igs"]][taemg_internal["iel"]] + taemg_internal["drpred"] * taemg_constants["en_c2"][taemg_internal["igs"]][taemg_internal["iel"]] - midval(taemg_constants["en_c2"][taemg_internal["igs"]][1]*(taemg_internal["rpred2"] - taemg_constants["r2max"]), 0, taemg_constants["eshfmx"]).
	
	
	if (taemg_internal["drpred"] > taemg_constants["pbrc"][taemg_internal["igs"]]) {
		//linear altitude profile at long range
		set taemg_internal["href"] to taemg_constants["pbhc"][taemg_internal["igs"]] + taemg_constants["pbgc"][taemg_internal["igs"]] * (taemg_internal["drpred"] - taemg_constants["pbrc"][taemg_internal["igs"]]).
	} else {
		//close-in linear profile with outer glideslope
		set taemg_internal["href"] to taemg_constants["hali"][taemg_internal["igs"]] - taemg_constants["tggs"][taemg_internal["igs"]] * taemg_internal["drpred"].
		//add the cubic profile for mid-ranges
		if (taemg_internal["drpred"] > 0) {
			set taemg_internal["href"] to taemg_internal["href"] + taemg_internal["drpred"]^2 * (taemg_constants["cubic_c3"][taemg_internal["igs"]] + taemg_internal["drpred"] * taemg_constants["cubic_c4"][taemg_internal["igs"]]).
		}
	}
	
	// linear profiles for qbref
	if (taemg_internal["drpred"] > taemg_constants["pbrcq"][taemg_internal["igs"]]) {
		set taemg_internal["qbref"] to midval( taemg_constants["qbrll"][taemg_internal["igs"]] + qbc1[taemg_internal["igs"]] * (taemg_internal["drpred"] - taemg_constants["pbrcq"][taemg_internal["igs"]]), taemg_constants["qbrll"][taemg_internal["igs"]], taemg_constants["qbrml"][taemg_internal["igs"]]).
	} else {
		set taemg_internal["qbref"] to midval( taemg_constants["qbrul"][taemg_internal["igs"]] + qbc2[taemg_internal["igs"]] * taemg_internal["drpred"], taemg_constants["qbrll"][taemg_internal["igs"]], taemg_constants["qbrul"][taemg_internal["igs"]]).
	}
	
	//hac spiral adjustment
	//adjust the final hac radius rf if the hac angle is large enough and if the altitude is too low
	if (taemg_internal["iphase"] = 2) and (taemg_internal["psha"] > taemg_constants["psrf"]) {
		local hrefoh is taemg_internal["href"]  - midval( taemg_constants["dhoh1"] * (taemg_internal["drpred"] - taemg_constants["dhoh2"]), 0, taemg_constants["dhoh3"]).
		local drf is taemg_constants["drfk"] * (hrefoh - taemg_input["h"])/(taemg_internal["psha"] * taemg_constants["dtr"]).
		set taemg_internal["rf"] to midval(taemg_internal["rf"] + drf, taemg_constants["rfmin"], taemg_constants["rfmax"]).
	}
	
	set taemg_internal["herror"] to taemg_internal["href"] - taemg_input["h"].
	
	//calculate tangent of ref. fpa
	local dhdrrf is 0.
	if (taemg_internal["drpred"] > taemg_constants["pbrc"][taemg_internal["igs"]]) {
		set dhdrrf to -taemg_constants["pbgc"][taemg_internal["igs"]].
	} else {
		set dhdrrf to - midval( -taemg_constants["tggs"][taemg_internal["igs"]] + taemg_internal["drpred"] * (2 * taemg_constants["cubic_c3"][taemg_internal["igs"]] + 3 * taemg_constants["cubic_c4"][taemg_internal["igs"]] * taemg_internal["drpred"]), taemg_constants["pbgc"][taemg_internal["igs"]], -taemg_constants["tggs"][taemg_internal["igs"]]).
	}
	
	//moved up from tgnzc so I can output hdref instead of dhdrrf
	set taemg_internal["hdref"] to taemg_input["surfv_h"] * dhdrrf.
	
	//rate of change of filtered dyn press 
	local qbard is midval( taemg_constants["cqg"] * (taemg_input["qbar"] - taemg_internal["qbarf"]), -taemg_constants["qbardl"], taemg_constants["qbardl"]).
	//update filtered dyn press 
	set taemg_internal["qbarf"] to taemg_internal["qbarf"] + qbard * taemg_constants["dtg"].
	set taemg_internal["qbd"] to taemg_constants["cdeqd"] * taemg_internal["qbd"] + taemg_constants["cqdg"] * qbard;
	//error on qbar 
	set taemg_internal["qberr"] to taemg_internal["qbref"] - taemg_internal["qbarf"].
	//cmd eas 
	set taemg_internal["eas_cmd"] to 17.1865 + sqrt(taemg_internal["qbref"]).

}	

//transition logic bw phases 
FUNCTION tgtran {
	PARAMETER taemg_input.	
	
	//transition to a/l 
	if (taemg_internal["iphase"] = 3) {
		if (
			(abs(taemg_internal["herror"]) < (taemg_input["h"] * taemg_constants["del_h1"] - taemg_constants["del_h2"]))
			and (abs(taemg_input["y"]) < (taemg_input["h"] * taemg_constants["y_range1"] - taemg_constants["y_range2"])) 
			and (abs(taemg_input["gamma"] - taemg_constants["gamsgs"][taemg_internal["igs"]]) < (taemg_input["h"] * taemg_constants["gamma_coef1"] - taemg_constants["gamma_coef2"]))
			and (abs(taemg_internal["qberr"]) < taemg_constants["qb_error2"])
			and (taemg_input["h"] < taemg_constants["h_ref1"])
			) or (taemg_input["h"] < taemg_constants["h_ref2"]) {
				set taemg_input["tg_end"] to TRUE.
			}
		return.
	}
	
	//transition to pre-final based on distance or altitude if on a low energy profile
	if (taemg_internal["rpred"] < taemg_internal["rpred3"]) or (taemg_input["h"] < taemg_constants["hmin3"]) {
		set taemg_internal["iphase"] to 3.
		//set taemg_internal["phi0"] to taemg_internal["phic"].
		set taemg_internal["philim"] to taemg_constants["philm3"].
		set taemg_internal["dnzul"] to taemg_constants["dnzuc2"].
		set taemg_internal["dnzll"] to taemg_constants["dnzlc2"]
		return.
	}
	
	//transition from s-turn to acq when below an energy band
	if (taemg_internal["iphase"] = 0) and (taemg_internal["eow"] < taemg_internal["en"] + taemg_constants["enbias"]) {
		set taemg_internal["iphase"] to 1.
		set taemg_internal["philim"] to taemg_constants["philm1"].
		return.
	} else if (taemg_internal["iphase"] = 1) {
		//check if we can still do an s-turn  to avoid geometry problems
		if ((taemg_internal["psha"] < taemg_constants["psstrn"]) and (taemg_internal["drpred"] > taemg_constants["rminst"][taemg_internal["igs"]])) {
			set taemg_internal["es"] to taemg_constants["es1"][taemg_internal["igs"]] + taemg_internal["drpred"] * taemg_constants["edrs"][taemg_internal["igs"]].
			//if above energy, transition to s-turn 
			if (taemg_internal["eow"] > taemg_internal["es"]) {
				set taemg_internal["iphase"] to 0.
				set taemg_internal["philim"] to taemg_constants["philm0"].
				//direction of s-turn 
				set taemg_internal["ysturn"] to -taemg_internal["ysgn"].
				local spsi is taemg_internal["ysturn"] * unfixangle(taemg_input["psd"]).
				
				if (spsi < 0) and (taemg_internal["psha"] < 90) {
					set taemg_internal["ysturn"] to -taemg_internal["ysturn"].
				}
			}
		}
		
		//a bit of confusion ensues bc the level-c ott document is ass
		
		//this is equation block 46
		//suggest downmoding to MEP 
		SET taemg_internal["emep"] TO taemg_constants["emep_c1"][taemg_internal["igs"]][taemg_internal["iel"]] + taemg_internal["drpred"] * taemg_constants["emep_c2"][taemg_internal["igs"]][taemg_internal["iel"]].
		if (taemg_internal["eow"] < taemg_internal["emep"]) and (NOT taemg_internal["mep"]) {
			set taemg_internal["mep"] to TRUE.
		}
		
		//these two blocks look like they're inside equation block 45 in the case eow > es but it doesn't make sense
		//I think these two belong outside the s-turn block
		
		//suggest downmoding to straight-in
		local emoh is taemg_constants["emohc1"][taemg_internal["igs"]] + taemg_constants["emohc2"][taemg_internal["igs"]] * taemg_internal["drpred"].
		if (taemg_internal["eow"] < emoh) and (taemg_internal["psha"] > taemg_constants["psohal"]) and (taemg_internal["rpred"] > taemg_constants["rmoh"]) {
			set taemg_internal["ohalrt"] to TRUE.
		}
		
		//transition to hac heading when close to the hac radius 
		if (taemg_internal["rcir"] < taemg_constants["p2trnc1"] * taemg_internal["rturn"]) {
			SET taemg_internal["iphase"] to 2.
			set taemg_internal["philim"] to taemg_constants["philm2"].
		}
		
	} else if (taemg_internal["iphase"] = 2) {
		return.
	}
	
	

}		
	
//calculate nz command 
FUNCTION tgnzc {
	PARAMETER taemg_input.	
	
	//gain factor on herr and hderr
	local gdh is midval(taemg_constants["gdhc"] - taemg_constants["gdhs"] * taemg_input["h"], taemg_constants["gdhll"], taemg_constants["gdhul"]).
	set taemg_internal["hderr"] to taemg_internal["hdref"] - taemg_input["hdot"].
	
	//unlimited normal accel commanded to stay on profile
	local dnzc is taemg_constants["dnzcg"] * gdh * (taemg_internal["hderr"] + taemg_constants["hdreqg"] * gdh * taemg_internal["herror"]).
	
	//qbar profile varies within an upper and a lower profile
	
	//calculate min qbar profile
	local mxqbwt is 0.
	if (taemg_input["mach"] < taemg_constants["qmach2"]) {
		set mxqbwt to midval(taemg_constants["qbwt1"] + taemg_constants["qbmsl1"] * (taemg_input["mach"] - taemg_constants["qmach1"]), taemg_constants["qbwt2"], taemg_constants["qbwt1"]).
	} else {
		set mxqbwt to midval(taemg_constants["qbwt2"] + taemg_constants["qbmsl2"] * (taemg_input["mach"] - taemg_constants["qmach2"]), taemg_constants["qbwt2"], taemg_constants["qbwt3"]).
	}
	
	local qbll is mxqbwt + taemg_input["weight"].
	local qbmnnz is qbll / max( taemg_input["cosphi"], taemg_constants["cpmin"]).
	
	//calculate max qbar profile
	local qbmxnz is 0.
	if (taemg_input["mach"] > taemg_constants["qbm1"]) {
		set qbmxnz to midval( taemg_constants["qbmx2"] + taemg_constants["qbmxs2"] * (taemg_input["mach"] - taemg_constants["qbm2"]), taemg_constants["qbmx2"], taemg_constants["qbmx3"]).
	} else {
		set qbmxnz to midval( taemg_constants["qbmx2"] + taemg_constants["qbmxs1"] * (taemg_input["mach"] - taemg_constants["qbm1"]), taemg_constants["qbmx2"], taemg_constants["qbmx1"]).
	}
	
	//limit max qbar profile to enter the hac when subsonic
	if (taemg_constants["eqlowl"] < taemg_internal["eow"]) and (taemg_internal["eow"] < taemg_constants["eqlowu"]) and (taemg_internal["psha"] > taemg_constants["psohqb"]) {
		set qbmxnz to midval(taemg_constants["qbref2"][taemg_internal["igs"]] - taemg_constants["pqbwrr"] * (taemg_internal["rpred2"] - taemg_constants["r2max"]) + (taemg_internal["eow"] - taemg_internal["en"]) / taemg_constants["pewrr"], qbmnnz, qbmxnz).
	}
	
	//limits on qbar
	local qbnzul is - (taemg_constants["qbg1"] * (qbmnnz - taemg_internal["qbarf"]) - taemg_internal["qbd"]) * taemg_constants["qbg2"].
	local qbnzll is - (taemg_constants["qbg1"] * (qbmxnz - taemg_internal["qbarf"]) - taemg_internal["qbd"]) * taemg_constants["qbg2"].
	
	if (taemg_internal["iphase"] = 3) {
		set taemg_internal["nzc"] to midval(dnzc, qbnzll, qbnzul).
	} else {
		//eow limits
		local emax is taemg_internal["en"] + taemg_constants["edelnz"][taemg_internal["igs"]] * midval( taemg_internal["drpred"] / taemg_constants["del_r_emax"][taemg_internal["igs"]] , taemg_constants["edelc1"], taemg_constants["edelc2"]).
		local emin is taemg_internal["en"] - taemg_constants["edelnz"][taemg_internal["igs"]].
		set eownzul to (taemg_constants["geul"] * gdh * (emax - taemg_internal["eow"]) + taemg_internal["hderr"]) * taemg_constants["gehdul"] * gdh.
		set eownzll to (taemg_constants["gell"] * gdh * (emin - taemg_internal["eow"]) + taemg_internal["hderr"]) * taemg_constants["gehdll"] * gdh.
		
		//cascade of filters
		//limit by eow
		set taemg_internal["dnzcl"] to midval(dnzc, eownzll, eownzul).
		//limit by qbar
		set taemg_internal["dnzcl"] to mival(taemg_internal["dnzcl"], qbnzll, qbnzul).
		
		//calculate commanded nz
		local dnzcd is midval((taemg_internal["dnzcl"] - taemg_internal["nzc"]) * taemg_constants["cqg"], -taemg_constants["dnzcdl"], taemg_constants["dnzcdl"]).
		set taemg_internal["nzc"] to taemg_internal["nzc"] + dnzcd * taemg_constants["dtg"].
	}
	
	//apply strucutral limits on nz cmd
	set taemg_internal["nzc"] to midval(taemg_internal["nzc"], taemg_internal["dnzll"], taemg_internal["dnzul"]).
	
	//my addition from 
	set taemg_internal["nztotal"] to midval(taemg_internal["nzc"] + taemg_input["costh"] / taemg_input["cosphi"], -taemg_constants["nztotallim"], taemg_constants["nztotallim"]).
}		
									
FUNCTION tgsbc {
	PARAMETER taemg_input.	
	
	//supersonic speedbrake cmd
	if (taemg_input["mach"] > taemg_constants["dsbcm"]) {
		set taemg_internal["dsbc_at"] to taemg_constants["dsbsup"].
		return.
	}
	
	//mach limits for speedbrake
	local dsbcll is midval(taemg_constants["dsbsup"] + taemg_constants["dsblls"] * (taemg_input["mach"] - taemg_constants["dsbcm"]), 0, taemg_constants["dsbsup"]).
	local dsbcul is midval(taemg_constants["dsbsup"] + taemg_constants["dsbuls"] * (taemg_input["mach"] - taemg_constants["dsbcm"]), taemg_constants["dsbsup"], taemg_constants["dsblim"]).
	
	local dsbc is 0.
	if (taemg_internal["iphase"] = 0) {
		//if s-turn set to maximum
		set dsbc to taemg_constants["dsblim"].
	} else {
		local dsbe is taemg_constants["gsbe"] * taemg_internal["qberr"].
		
		if (dsbc > dsbcll) and (dsbc < dsbcul) {
			set taemg_internal["dsbi"] to midval(taemg_internal["dsbi"] + taemg_constants["gsbi"] * taemg_internal["qberr"] * taemg_constants["dtg"], -taemg_constants["dsbil"], taemg_constants["dsbil"]).
		}
		
		set dsbc to taemg_constants["dsbnom"] - dsbe - taemg_internal["dsbi"].
		
		if ((taemg_internal["en"] - taemg_internal["eow"]) > taemg_constants["demxsb"]) {
			set dsbc to 0.
		}
	}
	
	set taemg_internal["dsbc_at"] to midval(dsbc, dsbcll, dsbcul).

}	
								
FUNCTION tgphic {
	PARAMETER taemg_input.	

	// roll cmd limit depending on mach (limited above phim) and phase (through philim)
	local philimit is midval(taemg_constants["philmsup"] + taemg_constants["phils"] * (taemg_input["mach"] - taemg_constants["phim"]), taemg_constants["philmsup"], taemg_internal["philim"]).
	
	//def moved here from tgtran
	//previous command
	LOCAL phi0 IS taemg_internal["phic"].
	
	if (taemg_internal["iphase"] = 0) {
		//s-turn bank constant in the right direction
		set taemg_internal["phic"] to taemg_internal["ysturn"] * philimit.
	} else if (taemg_internal["iphase"] = 1) {
		//acq bank proportional to heading error
		set taemg_internal["phic"] to taemg_constants["gphi"] * taemg_internal["dpsac"].
	} else if (taemg_internal["iphase"] = 2) {
		
		local rerrc is taemg_internal["rcir"] - taemg_internal["rturn"].
		if (rerrc > taemg_constants["rerrlm"]) {
			//if we're far outside the hac
			//hac bank proportional to heading error
			//apparently done to limit oscillations
			if (philimit > taemg_constants["philm1"]) {
				set philimit to taemg_constants["philm1"].
			}
			
			set taemg_internal["phic"] to taemg_constants["gphi"] * taemg_internal["dpsac"].
		} else {
			//if we're closer in or inside
			//hac bank proportional to position and rate errors relative to the hac
			local rdot is -(taemg_internal["xcir"] * taemg_input["xdot"] + taemg_internal["ycir"] * taemg_input["ydot"] ) /taemg_internal["rcir"].
			//the radial acceleration to impart with bank must account for centrifugal force
			local phip2c is (taemg_input["surfv_h"]^2 - rdot^2) * taemg_constants["rtd"] / (taemg_constants["g"] * taemg_internal["rturn"]).
			
			local rdotrf is -taemg_input["surfv_h"] * (taemg_constants["r1"] + 2 * taemg_constants["r2"] * taemg_internal["psha"]) * taemg_constants["rtd"] / taemg_internal["rturn"].
			
			set taemg_internal["phic"] to taemg_internal["ysgn"] * MAX(phip2c + taemg_constants["gr"] * rerrc + taemg_constants["grdot"] * (rdot - rdotrf), 0).
		}
		
	} else if (taemg_internal["iphase"] = 3) {
		//prefinal bank proportional to lateral (y coord) deviation and rate relative to the centreline
		local yerrc in midval ( -taemg_constants["gy"] * taemg_input["y"], -taemg_constants["yerrlm"], taemg_constants["yerrlm"]).
		set taemg_internal["phic"] to yerrc - taemg_constants["gydot"] * taemg_input["ydot"].
		
		if (abs(taemg_internal["phic"]) > taemg_constants["philmc"]) {
			set philimit to taemg_constants["philm4"].
		}
		
		//fade transition from phase 2 bank to phase 3 bank
		//it works with the counter isr as a gain, first 1/5 then 1/4 etc..
		if (taemg_internal["isr"] > 0) {
			local dphi is (taemg_internal["phic"] - phi0) / taemg_internal["isr"].
			set taemg_internal["isr"] to taemg_internal["isr"] - 1.
			set taemg_internal["phic"] to phi0 + dphi.
			//set phi0 to taemg_internal["phic"].
		}
	
	}
	
	//taken from level-c and adapted with inspiration from the taem paper 
	//limit roll not to exceed total maximum vertical acceleration
	LOCAL phinzlim IS ARCCOS( taemg_input["costh"] / (taemg_constants["nztotallim"] - taemg_internal["nzc"]) ).
	SET philimit TO MIN(philimit, phinzlim).
	
	set taemg_internal["phic_at"] to midval ( taemg_internal["phic"], -philimit, philimit).
}								
									
									
