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

//		dtg		// loop execution delta-t measured outside
//		wow		// weight-on-wheels measured outside

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
//    	geardown		//flag to command gear down
//		guid_id		//number to signal the hud the mode string 


FUNCTION taemg_wrapper {
	PARAMETER taemg_input.
	
	LOCAL tg_input IS LEXICON(
										"dtg", taemg_input["dtg"],
										"wow", taemg_input["wow"],
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
										"alpha", taemg_input["alpha"], 	//deg angle of attack 
										"nz", taemg_input["nz"], 	//gs load factor 
										"ovhd", taemg_input["ovhd"],  		// ovhd/straight-in flag , it's a 2-elem list, one for each value of rwid 			//changed into a simple flag
										"rwid", taemg_input["rwid"],		//runway id flag  (only needed to detect a runway change, the runway number is fine)
										"grtls", taemg_input["grtls"]		//grtls flag
								).
	
	local dump_overwrite is tgexec(tg_input).
	
	if (taemg_input["debug"]) {
		taemg_dump(tg_input, dump_overwrite).
	}
	
	//work out the guidance mode - needs to be consistent with the hud string mappings
	local guid_id is 0.
	if (taemg_internal["tg_end"]) {
		set guid_id to  30 + taemg_internal["p_mode"].
	} else {
		set  guid_id to 20 + taemg_internal["iphase"].
		
		//set guid mode to s-turn during phase 4 
		if (taemg_internal["iphase"] = 4) and (taemg_internal["istp4"] = 0) {
			set  guid_id to 20.
		}
	}

	//dsbc_at needs to be transformed to a 0-1 variable based on max deflection (halved)
	RETURN LEXICON(
					"guid_id", guid_id,					//counter to signal the current mode to the hud 
					//geometric outputs
					"rpred", taemg_internal["rpred"] / mt2ft,	//ft predicted range to threshold 
					"herror", taemg_internal["herror"] / mt2ft, 	//ft altitude error
					"hdref", taemg_internal["hdref"] / mt2ft, 	//ft reference hdot
					"hderrc", taemg_internal["hderrc"] / mt2ft, 	//ft/s hdot erorr corrected
					"psha", taemg_internal["psha"], 	//deg hac turn angle
					"dpsac", taemg_internal["dpsac"], 	//deg heading error to the hac tangent 
					"xhac", taemg_internal["xhac"] / mt2ft, 	//ft x coordinate of hac centre
					"yhac", taemg_internal["yhac"] / mt2ft, 	//ft y coordinate of hac centre
					"xaim", taemg_internal["xaim"] / mt2ft, 	//ft x coordinate of touchdown aiming point
					"rturn", taemg_internal["rturn"] / mt2ft, 	//ft hac radius
					"ysgn", taemg_internal["ysgn"], 	//ft hac turn direction (+1 is a right-handed hac)
					
					
					//commands
					"alpcmd", taemg_internal["alpcmd"],			//grtls commanded alpha 
					"alpll", taemg_internal["alpll"],			//lower alpha limit
					"alpul", taemg_internal["alpul"],			//upper alpha limit
					"nztotal", taemg_internal["nztotal"], 	//g-units normal load factor
					"hdrefc", taemg_internal["hdrefc"] / mt2ft, 	//ft/s reference hdot commanded
					"phic_at", taemg_internal["phic_at"], 	//deg commanded roll 
					"betac_at", taemg_internal["betac_at"], 	//deg commanded yaw 
					"philim", taemg_internal["philim"],		//deg phase-dependent roll limit
					"dsbc_at", taemg_internal["dsbc_at"] / taemg_constants["dsblim"], 	//deg speedbrake command (angle at the hinge line, meaning each panel is deflected by half this????)
					
					//energy and other stuff
					"eow", taemg_internal["eow"] / mt2ft, 		//ft energy/weight
					"eowerror", taemg_internal["eowerror"] / mt2ft, 		//ft energy/weight error
					"es", taemg_internal["es"] / mt2ft, 		//ft energy/weight at which the s-turn is initiated 
					"en", taemg_internal["en"] / mt2ft, 	//ft energy/weight nominal
					"emep", taemg_internal["emep"] / mt2ft, 	//ft energy/weight at which the mep is selected 
					"eas_cmd", taemg_internal["eas_cmd"] / mps2kt, 	//kn equivalent airspeed commanded  (not useful)
					"qbarf", taemg_internal["qbarf"] / (atm2pa * pa2psf), 	//psf filtered dynamic press 
					
					//flags
					"ohalrt", taemg_internal["ohalrt"],	//taem automatic downmode flag 
					"mep", taemg_internal["mep"], 		//min entry point flag 
					"itran", taemg_internal["itran"], 	//phase transition flag 
					"tg_end", taemg_internal["tg_end"], 	//termination flag 
					"al_end", taemg_internal["al_end"], 	//termination flag 
					"freezetgt", taemg_internal["freezetgt"],	
					"freezeapch", taemg_internal["freezeapch"],	
					"geardown", taemg_internal["geardown"],	
					"brakeson", taemg_internal["brakeson"],
					"dapoff", taemg_internal["dapoff"]
	
	).
}


//input constants 

//deprecated -> present in sts1 baseline and not in ott baseline - also disabled from ott
global taemg_constants is lexicon (
									//my addition: alpha upper and lower limit - simplified from level-C
									"alpulc1", 3.4637,		//linear coef of upper alpha limit with mach
									"alpulc2", 9.2353,		//° constant coef of upper alpha limit with mach
									"alpulc3", 13.7,		//° max upper alpha limit
									"alpulc4", 17.8,		//° min upper alpha limit							
									"alpllcm1", 1.3,		// mach breakpoint for lower alpha limit vs mach 
									"alpllcm2", 2.25,		// mach breakpoint for lower alpha limit vs mach 
									"alpllc1", 1.4706,		//linear coef of lower alpha limit with mach 
									"alpllc2", -1.0096,		//° constant coef of lower alpha limit with mach
									"alpllc3", 2.3918,		//linear coef of lower alpha limit with mach 
									"alpllc4", -2.1873,		//° constant coef of lower alpha limit with mach
									"alpllc5", 4.84,		//linear coef of lower alpha limit with mach 
									"alpllc6", -7.7031,		//° constant coef of lower alpha limit with mach
									"alpllc7", 7,		//° max lower alpha limit
									"alpllc8", 0,		//° min lower alpha limit
									
									
									"cdeqd", 0.68113143,	//gain in qbd calculation
									"cpmin", 0.707,		//cosphi min value 
									"cqdg", 0.31886860,		//gain for qbd calculation 
									"cqg", 0.7583958,		//gain for calculation of dnzcd and qbard 
									"del_h1", 0.19,				//alt error coeff 
									"del_h2", 900,				//ft alt error coeff 
									"del_r_emax", list(0,54000,54000),		// -/ft/ft constant ised for computing emax 	//deprecated
									//"dnzcg", 0.01,		//g-unit/s gain for dnzc	OTT
									"dnzcg", 0.01,		//g-unit/s gain for dnzc
									"dnzlc1", -0.7,		//g-unit phase 0,1 nzc lower lim 
									"dnzlc2", -1,		//g-unit phase 2, 3 nzc lower lim 
									"dnzuc1", 0.7,		//g-unit phase 0,1 nzc upper lim 
									"dnzuc2", 1,		//g-unit phase 2, 3 nzc upper lim 
									"dr3", 8000,		//ft delta range val for rpred3
									"dsbcm", 1.5,		//mach at which speedbrake modulation starts 
									"dsblim", 98.6,	//deg dsbc max value 
									"dsbsup", 65,	//deg fixed spdbk deflection at supersonic 		//ott
									//"dsbsup", 98.6,	//deg fixed spdbk deflection at supersonic 
									"dsbil", 20,	//deg min spdbk deflection 
									"dsbnom", 65,		//deg nominal spdbk deflection
									"dshply", 4000,		//ft delta range value in shplyk  	//deprecated
									"dtg", 0.96,		//s taem guid cycle interval
									"dtr", 0.0174533, 		//rad/deg deg2rad
									"edelc1", 1,			//emax calc constant 		//deprecated
									"edelc2", 1,			//emax calc constant  		//deprecated
									"edelnz", list(0, 4000, 4000),			// -/ft/ft eow delta from nominal energy line slope for s-turn  	//OTT paper			//deprecated
									"edelnzu", 4000,			//eow delta from nominal energy line for emax
									"edelnzl", 4000,			//eow delta from nominal energy line for emin
									
									//"edrs", list(0, 0.69946182, 0.69946182),		// -/ ft^2/ft / ft^2/ft slope for s-turn energy line   	//OTT paper
									//"emep_c1", list(0, list(0,-3263, 12088), list(0, -3263, 12088)),		//all in ft mep energy line y intercept  	//OTT paper
									//"emep_c2", list(0, list(0,0.51554944, 0.265521), list(0, 0.51554944, 0.265521)),		//all in ft^2/ft mep energy line slope 	//OTT paper
									//"en_c1", list(0, list(0, 949, 15360), list(0, 949, 15360)),		//all ft^2/ft nom energy line y-intercept 	//OTT paper
									//"en_c2", list(0, list(0, 0.6005, 0.46304), list(0, 0.6005, 0.46304)),		//all ft^2/ft nom energy line slope 	//OTT paper
									//"es1", list(0, 4523, 4523),		//ft y-intercept of s-turn energy line   	//OTT paper
									//"eow_spt", list(0, 76068, 76068), 	//ft range at which to change slope and y-intercept on the mep and nom energy line  	//OTT paper
									
									//my modification: single set of energy profiles, 3-point piecewise lines
									"emep_c1", list(-15256.6, -31586, 10018),		//all in ft mep energy line y intercept 
									"emep_c2", list(0.69517, 0.7871, 0.4404),		//all in ft^2/ft mep energy line slope
									"en_c1", list(-6052, -52852, 15500),		//all ft^2/ft nom energy line y-intercept 
									"en_c2", list(0.75, 1.01, 0.4404),		//all ft^2/ft nom energy line slope
									"es_c1", list(9296.6, -74192.8, 15500),		//all ft^2/ft s-turn energy line y-intercept 		//my addition
									"es_c2", list(0.8615, 1.32533, 0.57789),		//all ft^2/ft s-turn energy line slope			//my addition
									"eow_spt", list(180000, 120000, -100000), 	//ft range at which to change slope and y-intercept on the mep and nom energy line 
									

									"g", 32.174,					//ft/s^2 earth gravity 
									"gamma_coef1", 0.0007,			//deg/ft fpa error coef 
									"gamma_coef2", 3,			//deg fpa error coef 
									"gamma_error", 4,			//deg fpa error band 	//deprecated
									"gamsgs", LIST(0, -24, -22),	//deg a/l steep glideslope angle	//maybe put 24 here	
									"gdhc", 0.55, 			//  constant for computing gdh 		//ott
									"gdhll", 0.1, 			//gdh lower limit 	//OTT
									"gdhs", 0.9e-5,		//1/ft	slope for computing gdh 		//ott
									"gdhul", 0.5,			//gdh upper lim 
									"gehdll", 0.02, 		//g/fps  gain used in computing eownzll
									"gehdul", 0.02, 		//g/fps  gain used in computing eownzul
									"gell", 0.02, 		//1/s  gain used in computing eownzll
									"geul", 0.02, 		//1/s  gain used in computing eownzul
									"geownzc", 0.0005, 		//1/s  gain used to correct eow error
									"gphi", 2.5, 		//heading err gain for phic 
									"gr", 0.005,			//deg/ft gain on rcir in computing ha roll angle command 
									"grdot", 0.2,			//deg/fps  gain on drcir/dt in computing ha roll angle command 
									"gsbe", 1.5, 			//deg/psf-s 	spdbk prop. gain on qberr 
									"gsbi", 0.1, 		//deg/psf-s gain on qberr integral in computing spdbk cmd
									"gy", 0.075,			//deg/ft gain on y in computing pfl roll angle cmd 
									"gydot", 0.50,		//deg/fps gain on ydot on computing pfl roll angle cmd 
									"h_error", 1000,		//ft altitude error bound	//deprecated
									"hdherrcmax", 50,		//ft/s max herror correction to ref. hdot //my addition
									"hderr_lag_k", 0.7,		//ft/s lag filter gain for hderr feedback	//my addition
									"h_ref1", 8000,			//ft alt to force transition to a/l 		//modified from OTT
									"h_ref2", 5000,			//ft alt to force transition to ogs		//modified from OTT
									"hali", LIST(0, 10018, 10018),		//ft altitude at a/l for reference profiles
									//"hdreqg", 0.1,				//hdreq computation gain 		//OTT
									"hdreqg", 0.3,				//hdreq computation gain 		//OTT
									"hftc", LIST(0, 12018, 12018),		//ft altitude of a/l steep gs at nominal entry pt
									"machad", 0.75,		//mach to use air data (used in gcomp appendix)
									"mxqbwt", 0.0007368421,		// psf/lb max l/d dyn press for nominal weight		//deprecated 
									"pbgc", LISt(0, TAN(6), TAN(6)), 		//lin coeff of range for href and lower lim of dhdrrf	//6° of glideslope OTT
									"pbhc", LISt(0, 81161.826, 81161.826),				//ft altitude ref for drpred = pbrc
									"pbrc", LISt(0, 237527.82, 237527.82),				//ft drpred value for splicing of cubuc alt ref with pbgc
									//"pbrcq", LIST(0, 89971.082, 89971.082), 			//ft range breakpoint for qbref 	//OTT paper
									"pbrcq", LIST(0, 121522, 121522), 			//ft range breakpoint for qbref
									"phavgc", 63.33,			//deg constant for phavg
									"phavgll", 30,			//deg lower lim of phavg
									"phavgs", 13.33,		//deg slope for phavg 
									"phavgul", 50, 			//deg upperl im for phavg 
									"philm0", 50,			//deg sturn roll cmd lim
									"philm1", 50,			//deg acq roll cmd lim 
									"philm2", 60,			//deg heading alignment roll cmd lim 
									"philm3", 35, 			//deg prefinal roll cmd lim 
									"philmsup", 30, 		//deg supersonic roll cmd lim 		//OTT
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
									//"qbrll", LIST(0, 180, 180),		//psf  qbref ll 	//OTT paper
									//"qbrml", LIST(0, 220, 220),		//psf  qbref ml 	//OTT paper
									//"qbrul", LIST(0, 285, 285),		//psf  qbref ul 	//OTT paper
									"qbrll", LIST(0, 225, 225),		//psf  qbref ll
									"qbrml", LIST(0, 247, 247),		//psf  qbref ml
									"qbrul", LIST(0, 305, 305),		//psf  qbref ul
									"rerrlm", 7000,			//ft limit of rerrc 		//was 50 deg????
									"rftc", 5,			//s roll fader time const 
									//"rminst", LIST(0, 122204.6, 122204.6),		//ft min range allowed to initiate sturn
									"rminst", LIST(0, 180000, 180000),		//ft min range allowed to initiate sturn 	//OTT
									"rn1", LISt(0, 6542.886, 6542.866),			//ft range at which the gain on edelmz goes to zero 	//deprecated
									"rtbias", 3000,			//ft max value of rt for ha initiation		//deprecated
									"rtd", 	57.29578,			//deg/rad rad2teg
									"rturn", 20000,				//ft hac radius 				//deprecated
									"sbmin", 0,				//deg min sbrbk command (was 5)		//deprecated
									"tggs", LISt(0, TAN(24), TAN(22)), 		//tan of steep gs for autoland 	// I refactored everything so they're positive
									"vco", 1e20, 			//fps constant used in turn compensation 			//deprecated
									//"wt_gs1", 8000, 			//slugs max orbiter weight 
									"wt_gs1", 6837, 			//slugs max orbiter weight 
									"xa", LIST(0, -5000, -5000),		//steep gs intercept 				//deprecated
									"yerrlm", 300,				//deg limit on yerrc 
									"y_error", 1000,			//ft xrange err bound 		//deprecated
									"y_range1", 0.18,			//xrange coeff 
									"y_range2", 800,			//ft xrange coeff 
									
									//i think the following constants were added once OTT was implemented
									"dr4", 2000,			//ft range from hac for phase 3
									"hmep", LISt(0, 8018, 8018),	//ft altitude at a/l steep gs at MEP
									"demxsb", 10000,			//ft max eow error for speedbrakes out 		
									"dhoh1", 0.11,			//alt ref dev/spiral slope
									"dhoh2", 35705,			//ft alt ref dev/spiral range bias
									"dhoh3", 6000,			//ft alt ref dev/spiral max shift of altitude
									"eqlowu", 85000,			//ft upper eow of region for OVHD that qhat qbmxnz is lowered
									//"eshfmx", 20000,			//ft max shift of en target at hac  	//OTT paper
									"eshfmx", 10000,			//ft max shift of en target at hac 
									"phils", -300,			//deg constant used to calculated philimit
									"pewrr", 0.52,			//partial of en with respect to range at r2max 
									"pqbwrr", 0.006,			//psf / ft partial of qbar with respect to range with constraints of e=en and mach = phim 
									"pshars", 270,				//deg  psha reset value 
									"psrf", 90,				//deg max psha for adjusting rf 
									"psohal", 200, 			//deg min psha to issue ohalrt 
									"psohqb", 0, 			//deg min psha for which qbmxnz is lowered 
									//"psstrn", 200,			//deg max psha for s-turn //OTT
									"psstrn", 300,			//deg max psha for s-turn 
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
									"dnzcdl", 0.2,				//g/sec nzc rate lim 
									"drfk", -3,					//rf adjust gain (-0.8/tan 15°)
									"dsblls", 650,				//deg constant for dsbcll
									"dsbuls", -336,				//deg constant for dsbcul
									"emohc1", LISt(0, -3894, -3894), 		//ft constant eow used ot compute emnoh
									"emohc2", LISt(0, 0.51464, 0.51464), 		//slope of emnoh with range 
									//"enbias", 0, 					//ft eow bias for s-turn off 		//OTT
									//"enbias", 10000, 					//ft eow bias for s-turn off 		//deprecated
									"eqlowl", 60000,			//ft lower eow of region for ovhd that wbmxnz is lowered 
									"rmoh", 273500,				//ft min rpred to issue ohalrt 
									"r1", 0, 			//ft/deg linear coeff of hac spiral 
									"r2", 0.093, 			//ft/deg quadratic coeff of hac spiral 
									"r2max", 115000,			//ft max range on hac to be subsonic with nominal qbar 
									//"philm4", 35, 				//deg bank lim for large bank command - deprecated
									"philmc", 100, 				//deg bank lim for large bank command 
									"qbmxs1", -400,				//psf slope of qbmxnz with mach < qbm1 
									"hmin3", 7000,				//min altitude for prefinal
									"nztotallim", 2.5,				// my addition from the taem paper
									"rtanmin", 328,				//ft my own addition, empirical
									
									//A/L guidance stuff 
									"tgsh", TAN(3.1),			//tangent of shallow gs
									"xaim", 2300,			//ft aim point distance from threshold		
									"hflare", 2000,			//ft transition to open loop flare
									"hcloop", 1670,			//ft transition to closed loop flare
									"rflare", 17000,		//ft flare circle radius
									"hdecay", 2,			//ft exponential decay gain
									"sigma_exp", 500,		//ft exp decay characteristic distance
									"al_capt_herrlim", 50, 	//ft altitude error for steep gs capture
									"al_capt_gammalim", 1, 	//deg fpa error for steep gs capture
									"al_capt_interv_s", 3, 	//s time interval for errors to be within tolerance to toggle capture
									"al_fnlfl_herrexpmin", 1, //ft alt delta on exponential decay for final flare toggle
									"hfnlfl", 200,			//ft alt at which to force transition to final flare
									"h0_hdfnlfl", 80,			//ft reference altitude for hdot exp decay during final flare
									"max_hdfnlfl", 0.1,			//ft maximum hdot during finalflare
									"philm4", 15, 				//deg bank lim for flare and beyond
									"phi_beta_gain", 3, 			//gain for yaw during rollout
									"surfv_h_brakes", 140,		//ft/s trigger for braking outside executive
									"surfv_h_dapoff", 80,		//ft/s trigger for dap off outside executive
									"surfv_h_exit", 15,		//ft/s trigger for termination
									
									//GRTLS guidance stuff
									"gralpul", 50,		//° grtls upper lim on aoa
									"gralpll", 0,		//° grtls lower lim on aoa
									"msw1", 3.2, 		//mach to switch from grtls phase 4 to taem phase 1
									"msw3", 7.0, 		//upper mach to enable phase 4 s-turns
									"nzsw1", 1.85,		//gs initial value of nzsw
									"gralps", 1.365,	//linear coef of alpha transition aoa vs mach
									"gralpi",9.6482,	//° constant coef of alpha transition aoa vs mach
									"gralpl", 14,	//° min alpha transition aoa
									"gralpu", 17.55,	//° max alpha transition aoa
									"hdtrn", -347.5,	//ft/s hdot for transition to phase 4
									"smnzc1", 0.125,		//gs initial value of smnz1
									"smnzc2", 0.258,		//gs initial value of smnz2
									"smnzc3", 0.7314,		//coefficient for smnz1
									"smnzc4", 0.0086956,		//gs constant nz value for computing smnz2
									"smnz2l", -0.05,
									"grnzc1", 1.2,		//gs desired normal accel for nz hold 
									"alprec", 50,		//° aoa during alpha recovery
									"hdnom", -1558, 	//Nominal maximum sink rate during alpha recovery
									"dhdnz", 0.002, 		//Gain on max sink rate difference to compute DGRNZ
									"dhdll", -0.3, 			//Lower limit on DGRNZ
									"dhdul", 0.2,			//Upper limit on DGRNZ
									"grall", -1,			//° limit on dgralp
									"gralu", 1,			//° limit on dgralp
									"sbq", 20,			//qbar to trigger speedbrake deflection
									"del1sb", 3.125,		//speedbrake open rate
									"grsbl1", 80.6,			//upper grtls speedbrake limit
									"grsbl2", 65,			//lower grtls speedbrake limit
									"machsbs", 19.5,			//linear coef for speedbrake
									"machsbi", 2.6,			//constant coef for speedbrake
									"grpsstrn", 1000,		//° pshac limit for s-turns, high so that s-turns are always performed
									
									
									"dummy", 0			//can't be arsed to add commas all the time
									
).


//internal variables
global taemg_internal is lexicon(
								//moved from constants to variables that are calculated based on glideslopes
								"cubic_c3", 0,	//ft/ft^2 href curve fit quadratic term
								"cubic_c4", 0,	//ft/ft^2 href curve fit cubic term
								"pbhc", LIST(70000, 0), 		//ft href for drpred = pbrc[i]
								"pbrc", LIST(0, 0), 		//ft ranges for different href segments
								
								"alpul", 0,		//° upper limit on aoa
								"alpll", 0,		//° lower limit on aoa
								
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
								"eowerror", 0,			//ft energy/weight error
								"eowhdul", 0,			//ft energy/weight hdot upper limit
								"eowhdll", 0,			//ft energy/weight hdot lower limit
								"en", 0,			//energy/weight reference
								"emax", 0,			//energy/weight to constrain nzc above nominal ref
								"emin", 0,			//energy/weight to constrain nzc below nominal ref
								"es", 0, 		//ft energy/weight at which the s-turn is initiated 
								"est", 0, 		//ft energy/weight at which the s-turn is terminated		//my addition from grtls 
								"gdhfit", LIST(0, 0), 		// coefficients for hdot gain for nzc	//my addition
								"gdh", 0, 		// hdot gain for nzc
								"hdreqg", 0, 		//gain for herror in nzc
								"hderr", 0, 		//ft hdot error
								"herror", 0, 		//ft altitude error
								"hdref", 0,			//ft/s hdot reference
								"hderrc", 0,			//ft/s hdot error corrected - my addition
								"hderrcl", 0,			//ft/s hdot error corrected and limited - my addition
								"hdrefc", 0,			//ft/s hdot reference corrected - my addition
								"href", 0,			//ft ref altitude
								"iel", 0,			//energy reference profile selector flag
								"igi", 1,			//glideslope selector from input, based on headwind 	//deprecated
								"igs", 1,			//glideslope selector based on weight 
								"iphase", -1,	//phase counter 
								"itran", FALSE,		//signal that a phase transition has occured
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
								"betac_at", 0,	//deg commanded sideslip
								"philim", 0,	//deg roll cmd limit
								"psha", 0, 			//deg hac turn angle 		//moved from inputs
								"psc", 0, 			//deg heading to hac centre 
								"pst", 0, 			//deg heading to hac tangency pt 
								"qberr", 0,			//psf error on qbar
								"qbarf", 0,		//psf filtered dynamic press 
								"qbref", 0,		//psf dyn press ref 
								"qbd", 0,			// delta of qbar
								"rtan", 0, 		//ft distance to hac tangent point 
								"rpred", 0, 		//ft predicted total range to threshold 
								"rpred2", 0,		//ft predicted range final + hac turn
								"rpred3", 0, 		//ft predicted range to final for prefinal transition
								"rturn", 0,			//hac radius right now
								"rf", 0,		//spiral hac radius on final
								"rwid0", 0,		//store the runway selection
								"tg_end", FALSE,		//termination flag 
								"xali", 0,			// x coord of a/l interface for reference profiles
								"xftc", 0,			//x coord of nominal entry point (and place the hac origin) (is negative)
								"xhac", 0,			//x coord of hac centre		(is negative)
								"xmep", 0,			//x coord of minimum entry point	(is negative)
								"ysgn", 1,		//r/l cone indicator (i.e. left/right hac ??)		//moved from inputs
								"ysturn", 0,	//sign of s-turn		//renamed from s

								"xcir", 0,		//ft ship-hac centre distance component along x
								"ycir", 0,		//ft ship-hac centre distance component along y
								"xaim", 0,		//ft touchdown aiming point
								"yhac", 0,		//ft x coord of hac centre
								"rcir", 0,		//ft ship-hac distance
								"xa", 0,		//ft steep gs intercept, turned into a variable that is calculated from the a/l flare circle
								
								"freezetgt", FALSE,
								"freezeapch", FALSE,
								
								//A/L guidance stuff 
								"al_end", FALSE,		//termination flag 
								"p_mode", 0,		//a/l mode flag 
								"f_mode", 0,		//a/l flare mode flag during p_mode=3
								"al_capt_count", 0,		//a/l iteration counter for capture
								"geardown", FALSE,	//flag to command gear down to outside executive
								"brakeson", FALSE,	//flag to command brakes on to outside executive
								"dapoff", FALSE,	//flag to command dap off to outside executive
								"tgstp", 0,			//steep gs tangent (set to tggs)
								"tgsh", 0,			//shallow gs tangent
								"gsstp", 0,			//° steep glideslope
								"gssh", 0,			//° shallow glideslope
								"hk", 0,			//ft altitude of flare circle centre
								"xk", 0,			//ft x-coordinate of flare circle centre
								"xexp", 0,			//ft x-coordinate of transition from flare circle to exp decay
								"herrexp", 0,		//ft flare exponential error 
								"nzc1", 0, 		//nzc hdot error contribution
								"nzc2h", 0, 		//nzc h error contribution
								"nzc2i", 0, 		//nzc h error integral contribution
								
								
								// GRTLS stuff 
								"dgrnz", 0,			//gs phase 5 nzc increment based on maximum hdot
								"dgrnzt", 0,			//gs phase 5 target nzc
								"nzsw", 0, 			//gs Nz level at which Phase 6 to Phase 5 transition occurs
								"smnz1", 0, 		//gs exponential nz lead term
								"smnz2", 0, 		//gs linear nz lead term
								"gralpr", 0,		//° reference aoa
								"alpcmd", 0, 		//° commanded alpha
								"hdmax", 0, 		//ft/s maximum negative hdot reached during alpha recovery
								"igra", 0,			//alpha transition aoa index
								"dsbc_at1", 0,		//incremented speedbrake command
								"istp4", 1,		//phase 4 s-turn variable, will match phase at taem transition 
								
								
								"dummy", 0			//can't be arsed to add commas all the time
).

function taemg_dump {
	parameter taemg_input.
	parameter overwrite.
	
	local taemg_dumplex is lexicon().
	
	for k in taemg_input:keys {
		taemg_dumplex:add(k, taemg_input[k]). 
	}
	
	for k in taemg_internal:keys {
		LOCAL val IS taemg_internal[k].
		
		IF val:ISTYPE("List") {
			LOCAL c_ IS 0.
			for v_ in val {
				LOCAL v_k IS k + "_" + c_.
				taemg_dumplex:add(v_k, v_). 
				set c_ to c_ + 1.
			}
		} ELSE {
			taemg_dumplex:add(k, val). 
		}
	}
	
	log_data(taemg_dumplex,"0:/Shuttle_OPS3/LOGS/taem_dump", overwrite).
}


//phases (iphase):
// 0= s-turn,	1=hac acq,	2=hac turn (hdg),	3=pre-final 
// 4=alpha tran,	5=nz hold,	6=alpha recovery

//a/l phases (p_mode):
// 1= pitch capture,	2 and 3=steep gs,	4=pull up,	5=shallow gs, final flare 6=rollout	
// we have the ogs phase twice because of hud decluttering below h_ref2 ft

//a/l flare modes (f_mode):
// 1= open-loop pullup, 2= closed-loop circular pullup, 3= exponential decay onto shallow gs


//grtls phases (iphase) 
// 6= alpha recovery,	5=nz hold,	4=alpha transition and s-turns

function tgexec {
	PARAMETER taemg_input.
	
	local reset_flag is FALSE.

	if (taemg_internal["ireset"] = TRUE) OR (taemg_input["rwid"] <> taemg_internal["rwid0"]) OR (taemg_input["ovhd"]<>taemg_internal["ovhd0"]) {
		set reset_flag to TRUE.
		tginit(taemg_input).
	}
	
	tgxhac(taemg_input).
	
	gtp(taemg_input).
	
	if (taemg_internal["iphase"] >= 4) {
		
		//refactoring of this block to remove call to tgnzc
		grtrn(taemg_input).
	
		if (taemg_internal["iphase"] = 4){
			tgcomp(taemg_input).
		}
		
		if (taemg_internal["iphase"] = 5){
			grnzc(taemg_input).
		} else {
			gralpc(taemg_input).
		}
		
		grsbc(taemg_input).
		
		grphic(taemg_input).
	
	} else {
		tgcomp(taemg_input).
	
		tgtran(taemg_input).
		
		tgnzc(taemg_input).

		tgsbc(taemg_input).
		
		tgphic(taemg_input).
	}
		
	return reset_flag.

}

FUNCTION taemg_reset {
	SET taemg_internal["ireset"] TO TRUE.
}

FUNCTION tginit {
	PARAMETER taemg_input.
	
	//a/l stuff first because now we calculate xa
	//glideslopes
	set taemg_internal["tgsh"] to taemg_constants["tgsh"].
	set taemg_internal["tgstp"] to taemg_constants["tggs"][taemg_internal["igs"]].
	set taemg_internal["gsstp"] to ARCTAN(taemg_internal["tgstp"]).
	set taemg_internal["gssh"] to ARCTAN(taemg_internal["tgsh"]).
	set taemg_internal["xaim"] to taemg_constants["xaim"].
	//flare circle coordinates
	set taemg_internal["hk"] to taemg_constants["hcloop"] + taemg_constants["rflare"] * COS(taemg_internal["gsstp"]). 
	
	local he is taemg_internal["hk"] - taemg_constants["rflare"] * COS(taemg_internal["gssh"]) - taemg_constants["hdecay"].
	set taemg_internal["xexp"] to - he/taemg_internal["tgsh"] + taemg_internal["xaim"].
	set taemg_internal["xk"] to taemg_internal["xexp"] + taemg_constants["rflare"] * SIN(taemg_internal["gssh"]).
	
	set taemg_internal["xa"] TO taemg_internal["xk"] - taemg_constants["rflare"] * SIN(taemg_internal["gsstp"]) + taemg_constants["hcloop"] / taemg_internal["tgstp"].
	
	
	SET taemg_internal["rwid0"] TO taemg_input["rwid"].
	SET taemg_internal["ovhd0"] TO taemg_input["ovhd"].
	
	//requirements:
	//on first pass, set to 1 if normal taem and 6 if grtls 
	//after first pass, we only want to reset the phase if we're in an s-turn
	//don't reset phase during phases 2 and 3 i.e. after hac turn 
	//and don't reset during grtls phases 6 through 4
	local firstpassflag is (taemg_internal["iphase"] = -1).
	if (firstpassflag) {
		if (taemg_input["grtls"]) {
			SET taemg_internal["iphase"] TO 6.
		} else {
			SET taemg_internal["iphase"] TO 1.	
		}
	} else {
		if (taemg_internal["iphase"] < 2) {
			SET taemg_internal["iphase"] TO 1.
		}
	}
	
	SET taemg_internal["rf"] TO taemg_constants["rf0"].
	SET taemg_internal["rturn"] TO taemg_internal["rf"].	//i added this bc I don't see rturn being initialised anywhere	- or should it be initialised to zero??
	
	//moved up from tgxhac bc we want to do this at every reset
	SET taemg_internal["psha"] TO taemg_constants["pshars"] .
	
	SET taemg_internal["mep"] TO FALSE.
	
	SET taemg_internal["ohalrt"] TO FALSE.
	
	SET taemg_internal["dsbi"] TO 0.
	
	SET taemg_internal["philim"] TO taemg_constants["philm1"].
	
	SET taemg_internal["qbarf"] TO taemg_input["qbar"].
	
	SET taemg_internal["qbd"] TO 0.
	
	//moved up from tgxhac bc there's no reason to do this repeatedly
	if (taemg_input["weight"] > taemg_constants["wt_gs1"]) {
		set taemg_internal["igs"] to 2.
	} else {
		set taemg_internal["igs"] to 1.
	}
	
	set taemg_internal["xftc"] to taemg_internal["xa"] - taemg_constants["hftc"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].
	set taemg_internal["xali"] to taemg_internal["xa"] - taemg_constants["hali"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].
	set taemg_internal["xmep"] to taemg_internal["xa"] - taemg_constants["hmep"][taemg_internal["igs"]] / taemg_constants["tggs"][taemg_internal["igs"]].
	
	//my modification:
	//href is now a 3 segment profile: 
	//	linear with slope tggs when drpred bw 0 and pbrc[0]
	//	cubic when drpred bw pbrc[0] and pbrc[1]
	//	linear with slope pbgc when drpred above pbrc[1]
	//pbrc[1] and pbhc[1] are now linear fit functions of tggs 
	//the cubic coefficients are calculated to match altitude and fpa at both pbrc[0] and pbrc[1]
	
	set taemg_internal["pbhc"][0] to taemg_constants["hali"][taemg_internal["igs"]] + taemg_internal["pbrc"][0] * taemg_constants["tggs"][taemg_internal["igs"]].

	set taemg_internal["pbrc"][1] TO taemg_constants["pbrc"][taemg_internal["igs"]].
	set taemg_internal["pbhc"][1] TO taemg_constants["pbhc"][taemg_internal["igs"]].
	
	local dpbrc is taemg_internal["pbrc"][1] - taemg_internal["pbrc"][0].
	local dpbhc is taemg_internal["pbhc"][1] - taemg_internal["pbhc"][0].

	local chi is dpbhc / (dpbrc^2) - taemg_constants["tggs"][taemg_internal["igs"]] / dpbrc.
	local th is (taemg_constants["pbgc"][taemg_internal["igs"]] - taemg_constants["tggs"][taemg_internal["igs"]]) / (2 * dpbrc).
	
	set taemg_internal["cubic_c3"] to 3*chi - 2*th.
	set taemg_internal["cubic_c4"] to 2*(th - chi) / dpbrc.
	
	//moved up from tgxhac because if we don't trigger phase 2 before we cross the runway centreline 
	//the ysign will flip and mess everything up
	//refactored this block based on the taem paper
	//determine ysgn of the hac turn
	if (taemg_input["ovhd"]) {
		//for the overhead turn we'll turn around the hac on the opposite side of the runway to our own
		//the ysgn is +1 if the hac is on the +y side so we set the sign to the opposite sign of the current y coord 
		SET taemg_internal["ysgn"] TO - SIGN(taemg_input["y"]). 
	} else {
		//else it's on our same side
		SET taemg_internal["ysgn"] TO SIGN(taemg_input["y"]). 
	}
	
	if (firstpassflag) {
		set taemg_internal["nzsw"] to taemg_constants["nzsw1"].
		set taemg_internal["smnz1"] to taemg_constants["smnzc1"].
		set taemg_internal["smnz2"] to taemg_constants["smnzc2"].
		set taemg_internal["istp4"] to 1.
		//for grtls they won't be touched until taem is triggered
		 set taemg_internal["alpul"] to taemg_constants["gralpul"].
		 set taemg_internal["alpll"] to taemg_constants["gralpll"].
	}
	
	SET taemg_internal["tg_end"] TO FALSE.
	
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
	
	//moved ysgn calculations to the init block 
	
	//moved to tginit everything that won't change between iterations
	
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
	SET taemg_internal["xcir"] TO taemg_internal["xhac"] - taemg_input["x"].
	//my addition
	SET taemg_internal["yhac"] TO taemg_internal["ysgn"] * taemg_internal["rf"].
	
	LOCAL signy IS SIGN(taemg_input["y"]).
	
	//if a/l or pre-final and very close
	IF (taemg_internal["p_mode"] > 0) OR ((taemg_internal["iphase"] = 3) AND (taemg_internal["xcir"] < taemg_constants["dr4"])) {
		set taemg_internal["rpred"] TO SQRT(taemg_input["x"]^2 + taemg_input["y"]^2).
		RETURN.
	}
	//ELSE
	
	set taemg_internal["ycir"] to taemg_internal["yhac"] - taemg_input["y"].
		
	//euclidean distance from orbiter to hac centre in runway coords
	set taemg_internal["rcir"] to SQRT(taemg_internal["xcir"]^2 + taemg_internal["ycir"]^2).
	
	//distance to the tangency point
	set taemg_internal["rtan"] to 0.
	IF (taemg_internal["rcir"] > taemg_internal["rturn"]) {
		SET taemg_internal["rtan"] TO SQRT(taemg_internal["rcir"]^2 - taemg_internal["rturn"]^2).
	}
	
	//my own modification 
	//rtan will never be less than some constant 
	SET taemg_internal["rtan"] TO MAX(taemg_internal["rtan"], taemg_constants["rtanmin"]).
	
	//heading to hac centre 
	set taemg_internal["psc"] to ARCTAN2(taemg_internal["ycir"], taemg_internal["xcir"]).
	
	//heading to hac tangency pt 
	set taemg_internal["pst"] to taemg_internal["psc"] - taemg_internal["ysgn"] * ARCTAN2(taemg_internal["rturn"], taemg_internal["rtan"]).
	
	set taemg_internal["pst"] to unfixangle(taemg_internal["pst"]).

	set taemg_internal["dpsac"] to unfixangle(taemg_internal["pst"] - taemg_input["psd"]).
	
	//calculate hac turn angle 
	local pshan is -taemg_internal["pst"] * taemg_internal["ysgn"].
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
		//my modification, use supersonic roll instead
		//local phavg is midval(taemg_constants["phavgc"] - taemg_constants["phavgs"] * taemg_input["mach"], taemg_constants["phavgll"], taemg_constants["phavgul"]).
		local phavg is taemg_constants["philmsup"].
		local rtac is taemg_input["surfv"] * taemg_input["surfv_h"] / (taemg_constants["g"] * TAN(phavg)).
		local arcac is rtac * ABS(taemg_internal["dpsac"]) * taemg_constants["dtr"].
		
		local a_ IS rtac * (1 - COS(taemg_internal["dpsac"])).
		local b_ IS taemg_internal["rtan"] - rtac * ABS(SIN(taemg_internal["dpsac"])).
		local rc IS SQRT(a_^2 + b_^2).
		
		SET taemg_internal["rtan"] tO arcac + rc.
	}
	
	set taemg_internal["rpred"] TO  taemg_internal["rpred2"] + taemg_internal["rtan"].

}	

//reference params, dyn press and spiral adjust function 
FUNCTION tgcomp {
	PARAMETER taemg_input.	
	
	//range to the a/l transition point
	set taemg_internal["drpred"] to taemg_internal["rpred"] + taemg_internal["xali"].
	set taemg_internal["eow"] to taemg_input["h"] + taemg_input["surfv"]^2 / (2 * taemg_constants["g"]).
	
	//my own modification to the way energy profiles are calculated
	local iel is 0.
	until (taemg_internal["drpred"] >= taemg_constants["eow_spt"][iel]) {
		set iel to iel + 1.
	}
	set taemg_internal["iel"] to iel.
	
	LOCAL en_shift IS midval(taemg_constants["en_c2"][taemg_internal["iel"]]*(taemg_internal["rpred2"] - taemg_constants["r2max"]), 0, taemg_constants["eshfmx"]).
	set taemg_internal["en"] to taemg_constants["en_c1"][taemg_internal["iel"]] + taemg_internal["drpred"] * taemg_constants["en_c2"][taemg_internal["iel"]] - en_shift.
	
	SET taemg_internal["emep"] TO taemg_constants["emep_c1"][taemg_internal["iel"]] + taemg_internal["drpred"] * taemg_constants["emep_c2"][taemg_internal["iel"]].
	SET taemg_internal["es"] TO taemg_constants["es_c1"][taemg_internal["iel"]] + taemg_internal["drpred"] * taemg_constants["es_c2"][taemg_internal["iel"]].
	
	SET taemg_internal["est"] TO taemg_internal["en"] + 0.9 * (taemg_internal["es"] - taemg_internal["en"]).
	
	set taemg_internal["eowerror"] to taemg_internal["eow"] - taemg_internal["en"].
	
	//calculate ref altitude profile
	//calculate tangent of ref. fpa
	local dhdrrf is 0.
	
	if (taemg_internal["p_mode"] = 0) {
		//taem altitude profiles
	
		if (taemg_internal["drpred"] > taemg_internal["pbrc"][1]) {
			//linear altitude profile at long range
			set taemg_internal["href"] to taemg_internal["pbhc"][1] + taemg_constants["pbgc"][taemg_internal["igs"]] * (taemg_internal["drpred"] - taemg_internal["pbrc"][1]).
			set dhdrrf to -taemg_constants["pbgc"][taemg_internal["igs"]].
		} else if (taemg_internal["drpred"] < taemg_internal["pbrc"][0]) {
			//close-in linear profile with outer glideslope
			set taemg_internal["href"] to taemg_constants["hali"][taemg_internal["igs"]] + taemg_constants["tggs"][taemg_internal["igs"]] * taemg_internal["drpred"].
			set dhdrrf to -taemg_constants["tggs"][taemg_internal["igs"]].
		} else {
			//cubic profile for mid-ranges
			local drpred1 is taemg_internal["drpred"] - taemg_internal["pbrc"][0].
			set taemg_internal["href"] to taemg_internal["pbhc"][0] + (taemg_constants["tggs"][taemg_internal["igs"]] + (taemg_internal["cubic_c3"] + drpred1 * taemg_internal["cubic_c4"]) * drpred1) * drpred1.
			set dhdrrf to - midval( taemg_constants["tggs"][taemg_internal["igs"]] + drpred1 * (2 * taemg_internal["cubic_c3"] + 3 * taemg_internal["cubic_c4"] * drpred1), taemg_constants["pbgc"][taemg_internal["igs"]], taemg_constants["tggs"][taemg_internal["igs"]]).
		}
	} else if (taemg_internal["p_mode"] >= 5) {
		//a/l inner gs
		set taemg_internal["href"] to (taemg_internal["xaim"] - taemg_input["x"]) * taemg_internal["tgsh"].
		
		//final flare
		set dhdrrf to - taemg_internal["tgsh"] * midval((taemg_input["h"]/taemg_constants["h0_hdfnlfl"])^2, 1, taemg_constants["max_hdfnlfl"]).
	
	} else if (taemg_internal["p_mode"] = 4) {
		//a/l pullup
		if (taemg_internal["f_mode"] < 3) {
			//flare circle
			local xflarecir IS taemg_internal["xk"] - taemg_input["x"].
			local yflarecir is SQRT(taemg_constants["rflare"]^2 - xflarecir^2).
			set taemg_internal["href"] to taemg_internal["hk"] - yflarecir.
			//dhref/dx clamped
			set dhdrrf to - midval( xflarecir/yflarecir , taemg_internal["tgsh"], taemg_internal["tgstp"]).
		} else {
			//exponential decay
			set taemg_internal["herrexp"] to taemg_constants["hdecay"] * constant:e^((taemg_internal["xexp"] - taemg_input["x"])/taemg_constants["sigma_exp"]).
			//add on top of shallow gs 
			set taemg_internal["href"] to (taemg_internal["xaim"] - taemg_input["x"]) * taemg_constants["tgsh"] + taemg_internal["herrexp"].
			//dhref/dx clamped
			set dhdrrf to - (taemg_internal["tgsh"] + taemg_internal["herrexp"]/taemg_constants["sigma_exp"]).
		}
	} else {
		//a/l outer gs
		set taemg_internal["href"] to (taemg_internal["xa"] - taemg_input["x"]) * taemg_internal["tgstp"].
		set dhdrrf to -taemg_internal["tgstp"].
	}
	
	// linear profiles for qbref
	if (taemg_internal["drpred"] > taemg_constants["pbrcq"][taemg_internal["igs"]]) {
		set taemg_internal["qbref"] to midval( taemg_constants["qbrll"][taemg_internal["igs"]] + taemg_constants["qbc1"][taemg_internal["igs"]] * (taemg_internal["drpred"] - taemg_constants["pbrcq"][taemg_internal["igs"]]), taemg_constants["qbrll"][taemg_internal["igs"]], taemg_constants["qbrml"][taemg_internal["igs"]]).
	} else {
		set taemg_internal["qbref"] to midval( taemg_constants["qbrul"][taemg_internal["igs"]] + taemg_constants["qbc2"][taemg_internal["igs"]] * taemg_internal["drpred"], taemg_constants["qbrll"][taemg_internal["igs"]], taemg_constants["qbrul"][taemg_internal["igs"]]).
	}
	
	//hac spiral adjustment
	//adjust the final hac radius rf if the hac angle is large enough and if the altitude is too low
	if (taemg_internal["iphase"] = 2) and (taemg_internal["psha"] > taemg_constants["psrf"]) {
		local hrefoh is taemg_internal["href"]  - midval( taemg_constants["dhoh1"] * (taemg_internal["drpred"] - taemg_constants["dhoh2"]), 0, taemg_constants["dhoh3"]).
		local drf is taemg_constants["drfk"] * (hrefoh - taemg_input["h"])/(taemg_internal["psha"] * taemg_constants["dtr"]).
		set taemg_internal["rf"] to midval(taemg_internal["rf"] + drf, taemg_constants["rfmin"], taemg_constants["rfmax"]).
	}
	
	set taemg_internal["herror"] to taemg_internal["href"] - taemg_input["h"].
	
	//moved dhdrrf calculation up together with href
	
	//moved up from tgnzc so I can output hdref instead of dhdrrf
	set taemg_internal["hdref"] to taemg_input["surfv_h"] * dhdrrf.
	
	//rate of change of filtered dyn press 
	local qbard is midval( taemg_constants["cqg"] * (taemg_input["qbar"] - taemg_internal["qbarf"]), -taemg_constants["qbardl"], taemg_constants["qbardl"]).
	//update filtered dyn press 
	set taemg_internal["qbarf"] to taemg_internal["qbarf"] + qbard * taemg_input["dtg"].
	set taemg_internal["qbd"] to taemg_constants["cdeqd"] * taemg_internal["qbd"] + taemg_constants["cqdg"] * qbard.
	//error on qbar 
	set taemg_internal["qberr"] to taemg_internal["qbref"] - taemg_internal["qbarf"].
	//cmd eas 
	set taemg_internal["eas_cmd"] to 17.1865 * sqrt(taemg_internal["qbref"]).

}	

//transition logic bw phases 
FUNCTION tgtran {
	PARAMETER taemg_input.	

	//my addition: signal when a phase transition occurs to the hud
	if (taemg_internal["itran"]) {
		set taemg_internal["itran"] to FALSE.
	}
	
	//a/l transitions
	if (taemg_internal["tg_end"]) {
		//capture steep gs when errors small enough
		//CAREFUL: gamma is negative but gsstp is positive!
		if (taemg_internal["p_mode"] = 1) {
			if (abs(taemg_internal["herror"]) < taemg_constants["al_capt_herrlim"] and abs(taemg_input["gamma"] + taemg_internal["gsstp"]) < taemg_constants["al_capt_gammalim"] ) or (taemg_input["h"] < taemg_constants["h_ref2"]) {
				//measure the capture condition for enough time and then switch
				set taemg_internal["al_capt_count"] TO taemg_internal["al_capt_count"] - 1.
				if (taemg_internal["al_capt_count"] <= 0) {
					set taemg_internal["p_mode"] to 2.
					set taemg_internal["itran"] to TRUE.
				}
			}
			return.
		}
		
		//for hud decluttering 
		if (taemg_internal["p_mode"] = 2) and (taemg_input["h"] < taemg_constants["h_ref2"]) {
			set taemg_internal["p_mode"] to 3.
			set taemg_internal["itran"] to TRUE.
			return.
		}
		
		if (taemg_internal["p_mode"] = 3) and (taemg_input["h"] <= taemg_constants["hflare"]) {
			//transitio to flare
			set taemg_internal["p_mode"] to 4.
			set taemg_internal["f_mode"] to 1.
			set taemg_internal["itran"] to TRUE.
			return.
		}
		
		if (taemg_internal["p_mode"] = 4) {
			//toggle closed-loop flare
			if (taemg_internal["f_mode"] = 1) and (taemg_input["h"] <= taemg_constants["hcloop"]) {
				set taemg_internal["f_mode"] to 2.
				return.
			}
			
			//toggle exp decay 
			if (taemg_internal["f_mode"] = 2) and (taemg_input["x"] >= taemg_internal["xexp"]) {
				set taemg_internal["f_mode"] to 3.
				return.
			}
			
			//toggle shallow gs and final flare 
			if (taemg_internal["f_mode"] = 3) {
				if (abs(taemg_internal["herrexp"]) <= taemg_constants["al_fnlfl_herrexpmin"]) or (taemg_input["h"] <= taemg_constants["hfnlfl"]) {
					set taemg_internal["p_mode"] to 5.
					//command gear down 
					set taemg_internal["geardown"] to TRUE.
					set taemg_internal["itran"] to TRUE.
					return.
				}
			}
		}
		
		//toggle rollout
		if (taemg_internal["p_mode"] = 5) and (taemg_input["wow"]) {
			set taemg_internal["p_mode"] to 6.
			set taemg_internal["itran"] to TRUE.
			return.
		}
		
		//braking and termination
		if (taemg_internal["p_mode"] >= 6) {
			if (taemg_input["surfv_h"] <= taemg_constants["surfv_h_brakes"] ) {
				set taemg_internal["brakeson"] to TRUE.
			}
			
			if (taemg_input["surfv_h"] <= taemg_constants["surfv_h_dapoff"] ) {
				set taemg_internal["dapoff"] to TRUE.
			}
			
			if (taemg_input["surfv_h"] <= taemg_constants["surfv_h_exit"] ) {
				set taemg_internal["al_end"] to TRUE.
			}		
	
			return.
		}
	} else {
		//just to make sure we don't end up here during a/l and vice-versa
	
		//transition to a/l 
		if (taemg_internal["iphase"] = 3) {
			//modifications to transition criteria
			if (
				(taemg_input["h"] <= taemg_constants["hali"][taemg_internal["igs"]])
				and (abs(taemg_internal["herror"]) < (taemg_input["h"] * taemg_constants["del_h1"] - taemg_constants["del_h2"]))
				and (abs(taemg_input["y"]) < (taemg_input["h"] * taemg_constants["y_range1"] - taemg_constants["y_range2"]))
				and (abs(taemg_input["gamma"] - taemg_constants["gamsgs"][taemg_internal["igs"]]) < (taemg_input["h"] * taemg_constants["gamma_coef1"] - taemg_constants["gamma_coef2"]))
			) or (taemg_input["h"] < taemg_constants["h_ref1"]) {
					set taemg_internal["tg_end"] to TRUE.
					set taemg_internal["p_mode"] to 1.
					set taemg_internal["itran"] to TRUE.
					set taemg_internal["philim"] to taemg_constants["philm4"].
					SET taemg_internal["al_capt_count"] TO CEILING(taemg_constants["al_capt_interv_s"] / taemg_input["dtg"]).
				}
			return.
		}
		
		//transition to pre-final based on distance or altitude if on a low energy profile
		if (taemg_internal["rpred"] < taemg_internal["rpred3"]) or (taemg_input["h"] < taemg_constants["hmin3"]) {
			set taemg_internal["iphase"] to 3.
			set taemg_internal["itran"] to TRUE.
			set taemg_internal["phic"] to taemg_internal["phic_at"].
			set taemg_internal["philim"] to taemg_constants["philm3"].
			//moved from init so we have an updated value of dtg
			SET taemg_internal["isr"] TO CEILING(taemg_constants["rftc"] / taemg_input["dtg"]).
			return.
		}
		
		//my modification, turn off s-turn when below es
		
		//transition from s-turn to acq when below an energy band
		if (taemg_internal["iphase"] = 0) and (taemg_internal["eow"] < taemg_internal["est"]) {
			set taemg_internal["iphase"] to 1.
			set taemg_internal["itran"] to TRUE.
			set taemg_internal["philim"] to taemg_constants["philm1"].
			return.
		} else if (taemg_internal["iphase"] = 1) {
			//check if we can still do an s-turn  to avoid geometry problems
			//refactoring if we came in from grtls
			local pshalim is taemg_constants["psstrn"].
			if (taemg_input["grtls"]) {
				set pshalim to taemg_constants["grpsstrn"].	
			}
			//slight refactoring 
			if (taemg_internal["drpred"] > taemg_constants["rminst"][taemg_internal["igs"]]) {
				if (taemg_internal["psha"] < pshalim) {
					
					//moved es calculation to tgcomp
					
					//if above energy, transition to s-turn 
					if (taemg_internal["eow"] > taemg_internal["es"]) {
						set taemg_internal["iphase"] to 0.
						set taemg_internal["itran"] to TRUE.
						set taemg_internal["philim"] to taemg_constants["philm0"].
						//direction of s-turn 
						set taemg_internal["ysturn"] to -taemg_internal["ysgn"].
						local spsi is taemg_internal["ysturn"] * unfixangle(taemg_input["psd"]).
						
						if (spsi < 0) and (taemg_internal["psha"] < 90) {
							set taemg_internal["ysturn"] to -taemg_internal["ysturn"].
						}
					}
				}
			} else {
				set taemg_internal["freezetgt"] to TRUE.
				set taemg_internal["freezeapch"] to TRUE.
			}
			
			//a bit of confusion ensues bc the level-c ott document is ass
			
			//this is equation block 46
			//suggest downmoding to MEP 
			//moved emep calculation to tgcomp
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
				set taemg_internal["itran"] to TRUE.
				set taemg_internal["philim"] to taemg_constants["philm2"].
				
				//my addition: calculate gdh coefficients to interpolate between gdhll at current altitude and gdhul at a/l interface
				local gdhlin is (taemg_constants["gdhll"] - taemg_constants["gdhul"]) / (taemg_input["h"] - taemg_constants["hali"][taemg_internal["igs"]]).
				set taemg_internal["gdhfit"][0] to taemg_constants["gdhul"] - gdhlin * taemg_constants["hali"][taemg_internal["igs"]].
				set taemg_internal["gdhfit"][1] to gdhlin.
				
			}
			
		}
	
	}

}		
	
//calculate nz command 
// my modification - vertical guidance now is commanded hdot and not nz, but do it here regardless
FUNCTION tgnzc {
	PARAMETER taemg_input.	
	
	set taemg_internal["hderr"] to taemg_internal["hdref"] - taemg_input["hdot"].
	
	set taemg_internal["gdh"] to midval(taemg_internal["gdhfit"][0] + taemg_internal["gdhfit"][1] * taemg_input["h"], taemg_constants["gdhll"], taemg_constants["gdhul"]).

	local hderrcn is taemg_internal["hderr"].

	//do not correct for altitude error during or after flare
	if (taemg_internal["p_mode"] < 4) {
		set hderrcn to hderrcn + midval(taemg_internal["gdh"] * taemg_constants["hdreqg"] * taemg_internal["herror"], -taemg_constants["hdherrcmax"], taemg_constants["hdherrcmax"]) .
	}

	//filter changes to hderrc
	//try lag filtering 
	set taemg_internal["hderrcl"]  to (1 - taemg_constants["hderr_lag_k"]) * taemg_internal["hderrc"] + taemg_constants["hderr_lag_k"] *  hderrcn.

	//unlimited normal accel commanded to stay on profile
	set taemg_internal["dnzc"] to taemg_constants["dnzcg"] * taemg_internal["gdh"] * taemg_internal["hderrcl"].
	
	
	//qbar profile varies within an upper and a lower profile
	
	//calculate min qbar profile
	local mxqbwt is 0.
	if (taemg_input["mach"] < taemg_constants["qmach2"]) {
		set mxqbwt to midval(taemg_constants["qbwt1"] + taemg_constants["qbmsl1"] * (taemg_input["mach"] - taemg_constants["qmach1"]), taemg_constants["qbwt2"], taemg_constants["qbwt1"]).
	} else {
		set mxqbwt to midval(taemg_constants["qbwt2"] + taemg_constants["qbmsl2"] * (taemg_input["mach"] - taemg_constants["qmach2"]), taemg_constants["qbwt2"], taemg_constants["qbwt3"]).
	}
	
	local qbll is mxqbwt * taemg_input["weight"].
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

	set taemg_internal["dnzcl"] to taemg_internal["dnzc"].

	//my modification: transform energy nz filters into hdot error filters
	//don't do energy filtering beyond acq phase
	if (taemg_internal["iphase"] <= 1) {
		//eow limits
		SET taemg_internal["emax"] TO taemg_internal["en"] + taemg_constants["edelnzu"].
		SET taemg_internal["emin"] TO taemg_internal["en"] - taemg_constants["edelnzl"].
		
		local eownzul is (taemg_constants["geul"] * taemg_internal["gdh"] * (taemg_internal["emax"] - taemg_internal["eow"]) + taemg_internal["hderr"]) * taemg_constants["gehdul"] * taemg_internal["gdh"].
		local eownzll is (taemg_constants["gell"] * taemg_internal["gdh"] * (taemg_internal["emin"] - taemg_internal["eow"]) + taemg_internal["hderr"]) * taemg_constants["gehdll"] * taemg_internal["gdh"].
		
		//alpha limits for taem
		set taemg_internal["alpul"] to midval(taemg_constants["alpulc1"] * taemg_input["mach"] + taemg_constants["alpulc2"], taemg_constants["alpulc3"], taemg_constants["alpulc4"]).
		if (taemg_input["mach"] < taemg_constants["alpllcm1"]) {
			set taemg_internal["alpll"] to midval(taemg_constants["alpllc1"] * taemg_input["mach"] + taemg_constants["alpllc2"], taemg_constants["alpllc7"], taemg_constants["alpllc8"]).
		} else if (taemg_input["mach"] < taemg_constants["alpllcm2"]) {
			set taemg_internal["alpll"] to midval(taemg_constants["alpllc3"] * taemg_input["mach"] + taemg_constants["alpllc4"], taemg_constants["alpllc7"], taemg_constants["alpllc8"]).
		} else {
			set taemg_internal["alpll"] to midval(taemg_constants["alpllc5"] * taemg_input["mach"] + taemg_constants["alpllc6"], taemg_constants["alpllc7"], taemg_constants["alpllc8"]).
		}
		
		//cascade of filters
		//limit by eow
		set taemg_internal["dnzcl"] to midval(taemg_internal["dnzcl"], eownzll, eownzul).
		
		//calculate commanded nz by limiting delta
		local dnzcd is midval((taemg_internal["dnzcl"] - taemg_internal["nzc"]) * taemg_constants["cqg"], -taemg_constants["dnzcdl"], taemg_constants["dnzcdl"]).
		//apply structural limits on nz cmd
		set taemg_internal["nzc"] to midval(taemg_internal["nzc"] + dnzcd * taemg_input["dtg"], taemg_internal["dnzll"], taemg_internal["dnzul"]).

		local dnz2ddh is 1 / (taemg_internal["gdh"] * taemg_constants["dnzcg"]).

		SET taemg_internal["eowhdul"] TO eownzul * dnz2ddh.
		SET taemg_internal["eowhdll"] TO eownzll * dnz2ddh.

		set taemg_internal["hderrcl"] to midval(taemg_internal["hderrcl"], taemg_internal["eowhdll"], taemg_internal["eowhdul"]).
		
		local dhdcd is midval((taemg_internal["hderrcl"] - taemg_internal["hderrc"]) * taemg_constants["cqg"], -taemg_constants["hdherrcmax"], taemg_constants["hdherrcmax"]).
		set taemg_internal["hderrc"] to taemg_internal["hderrc"] + dhdcd * taemg_input["dtg"].
		
		
	} else {
		set taemg_internal["hderrc"] to taemg_internal["hderrcl"].
		set taemg_internal["nzc"] to taemg_internal["dnzcl"].
	}

	set taemg_internal["hdrefc"] to taemg_input["hdot"] + taemg_internal["hderrc"].
	
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
			set taemg_internal["dsbi"] to midval(taemg_internal["dsbi"] + taemg_constants["gsbi"] * taemg_internal["qberr"] * taemg_input["dtg"], -taemg_constants["dsbil"], taemg_constants["dsbil"]).
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
		local yerrc is -taemg_constants["gy"] * midval(taemg_input["y"], -taemg_constants["yerrlm"], taemg_constants["yerrlm"]).
		set taemg_internal["phic"] to yerrc - taemg_constants["gydot"] * taemg_input["ydot"].
			
		//if a/l and final flare or rollout, turn the roll command into a yaw command	
		if (taemg_internal["p_mode"] >= 5)	{
			set taemg_internal["phic_at"] to 0.
			set taemg_internal["betac_at"] to taemg_constants["phi_beta_gain"] * midval ( taemg_internal["phic"], -philimit, philimit).
			return.
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
	LOCAL phinzlim IS ARCCOS( limitarg(taemg_input["costh"] / (taemg_constants["nztotallim"] - taemg_internal["nzc"])) ).
	SET philimit TO MIN(philimit, phinzlim).
	
	set taemg_internal["phic_at"] to midval ( taemg_internal["phic"], -philimit, philimit).
	set taemg_internal["betac_at"] to 0.

}								
								
								
								
								//GRTLS stuff 
//grtls transitions								
function grtrn {
	PARAMETER taemg_input.	
	
	//my addition: signal when a phase transition occurs to the hud
	if (taemg_internal["itran"]) {
		set taemg_internal["itran"] to FALSE.
	}
	
	if (taemg_internal["iphase"] = 6) {
		if (taemg_input["nz"] > taemg_internal["nzsw"] + taemg_internal["dgrnz"]) {
			set taemg_internal["iphase"] to 5.
			set taemg_internal["itran"] to TRUE.
		}
		return.
	}
	
	//alpha recovery aoa profile
	set taemg_internal["gralpr"] to midval(taemg_constants["gralps"] * taemg_input["mach"] + taemg_constants["gralpi"], taemg_constants["gralpl"], taemg_constants["gralpu"]).
	//skip amaxld limitation
	set taemg_internal["gralpr"] to taemg_internal["gralpr"] / abs(taemg_input["cosphi"]).
	
	if (taemg_internal["iphase"] = 5) { 
		if (
			(taemg_input["hdot"] > taemg_constants["hdtrn"])
			and (taemg_input["alpha"] > taemg_internal["gralpr"])
		) {
			set taemg_internal["iphase"] to 4.
			set taemg_internal["itran"] to TRUE.
			SET taemg_internal["qbarf"] TO taemg_input["qbar"].
			
			//removed call to tgcomp
		}
		return.
	}
	
	if (taemg_internal["iphase"] = 4) and (taemg_input["mach"] < taemg_constants["msw1"]) { 
		//the idea is to maintain the s-turn status when transitioning from grtls to taem
		set taemg_internal["iphase"] to taemg_internal["istp4"].
		set taemg_internal["itran"] to TRUE.
	}
}

//nz command during nz hold 
function grnzc {
	PARAMETER taemg_input.	
	
	//correct coefficients for different iteration time 
	set taemg_internal["smnz1"] to taemg_internal["smnz1"] * (taemg_constants["smnzc3"]^taemg_input["dtg"]).
	set taemg_internal["smnz2"] to MAX(taemg_internal["smnz2"] - (taemg_constants["smnzc4"] * taemg_input["dtg"]), taemg_constants["smnz2l"]).
	
	// constant value minus linear and exponential terms that ramp down with time 
	//remmeber that nzc is increment over equilibrium
	set taemg_internal["nzc"] to taemg_constants["grnzc1"] - taemg_internal["smnz1"] - taemg_internal["smnz2"] + taemg_internal["dgrnz"].
	set taemg_internal["nztotal"] to midval(taemg_internal["nzc"] + 1, -taemg_constants["nztotallim"], taemg_constants["nztotallim"]).
}

// alpha recovery and transition aoa command
function gralpc {
	PARAMETER taemg_input.	
	
	if (taemg_internal["iphase"] = 6) {
		set taemg_internal["alpcmd"] to taemg_constants["alprec"].
		
		if (taemg_input["hdot"] < taemg_internal["hdmax"]) {
			set taemg_internal["hdmax"] to taemg_input["hdot"].
		} else {
			set taemg_internal["dgrnz"] to midval(( taemg_constants["hdnom"] - taemg_internal["hdmax"]) * taemg_constants["dhdnz"], taemg_constants["dhdll"], taemg_constants["dhdul"]).
			set taemg_internal["dgrnzt"] to taemg_constants["grnzc1"] + taemg_internal["dgrnz"] + 1.
		}
	} else {
		//igra = 0 : first pass, =1 : smooth transition to reference aoa, =2: reference aoa
		if (taemg_internal["igra"] = 0) {
			set taemg_internal["alpcmd"] to taemg_input["alpha"].
			set taemg_internal["igra"] to 1.
		} else if (taemg_internal["igra"] = 1) {
			local dgralp is midval(taemg_internal["gralpr"] - taemg_input["alpha"],  taemg_constants["grall"], taemg_constants["gralu"]).
			
			set taemg_internal["alpcmd"] to taemg_internal["alpcmd"] - dgralp.
			
			if 
				((dgralp < 0) and (taemg_internal["alpcmd"] <= taemg_internal["gralpr"]))
				or ((dgralp > 0) and (taemg_internal["alpcmd"] >= taemg_internal["gralpr"]))
			{
				set taemg_internal["igra"] to 2.
			}
		}
		
		if (taemg_internal["igra"] = 2) {
			set taemg_internal["alpcmd"] to taemg_internal["gralpr"].
		}
	}
}

//grtls speedbrake command 
function grsbc {
	PARAMETER taemg_input.
	
	//closed until qbar 20, then ramp up to grsbl1, then at mach 4 down to grsbl2
	
	if (taemg_input["qbar"] <= taemg_constants["sbq"]) {
		set taemg_internal["dsbc_at"] to 0.
		return.
	}
	
	set taemg_internal["dsbc_at1"] to taemg_internal["dsbc_at1"] + taemg_constants["del1sb"].
	local dsbc_at2 is midval(taemg_constants["machsbs"] * taemg_input["mach"] + taemg_constants["machsbi"], taemg_constants["grsbl1"], taemg_constants["grsbl2"]).
	
	set taemg_internal["dsbc_at"] to min(taemg_internal["dsbc_at1"], dsbc_at2).
}

//grtls lateral guidance 
function grphic {
	PARAMETER taemg_input.
	
	//my addition
	set taemg_internal["betac_at"] to 0.
	
	//zero roll before  alpha tran 
	if (taemg_internal["iphase"] > 4) {
		set taemg_internal["phic_at"] to 0.
		return.
	}
	
	if (taemg_internal["istp4"] = 0) {
		//grtls s-turn termination check
		if (taemg_internal["eow"] < taemg_internal["est"]) {
			set taemg_internal["istp4"] to 1.
		}	
	} else if (taemg_internal["istp4"] = 1) {
		if (taemg_internal["eow"] >= taemg_internal["est"]) and (taemg_input["mach"] < taemg_constants["msw3"]) and (taemg_internal["psha"] < taemg_constants["grpsstrn"]) {
			//direction of s-turn 
			set taemg_internal["istp4"] to 0.
			set taemg_internal["ysturn"] to -taemg_internal["ysgn"].
			local spsi is taemg_internal["ysturn"] * unfixangle(taemg_input["psd"]).
			
			if (spsi < 0) and (taemg_internal["psha"] < 90) {
				set taemg_internal["ysturn"] to -taemg_internal["ysturn"].
			}
		}
	}
	
	//these are equations 1.4 and 1.5 of grphic from the level-c document
	//to me they make sense after the if block so that a roll command is generated for either case
	if (taemg_internal["istp4"] = 0) {
		//higher s-turn bank angle
		set taemg_internal["phic"] to taemg_internal["ysturn"] * taemg_internal["philim"].
	} else if (taemg_internal["istp4"] = 1) {
		//acq bank proportional to heading error
		set taemg_internal["phic"] to taemg_constants["gphi"] * taemg_internal["dpsac"].
	}
	
	set taemg_internal["phic_at"] to midval ( taemg_internal["phic"], -taemg_internal["philim"], taemg_internal["philim"]).
}