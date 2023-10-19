@LAZYGLOBAL OFF.

GLOBAL mt2ft IS 3.28084.		// ft/mt
GLOBAL km2nmi IS 0.539957.	// nmi/km

//input variables
h		//ft height above rwy
hdot		//ft/s vert speed
x		//ft x component on runway coord
y		//ft y component on runway coord
v 		//ft/s earth relative velocity mag 
vh		//ft/s earth relative velocity horizintal component 
xdot 	//ft/s component along x direction of earth velocity in runway coord
ydot 	//ft/s component along y direction of earth velocity in runway coord
psd 		//deg course wrt runway centerline 
mach 
qbar 	//psf dynamic pressure
cosphi 	//cosine of roll 
secth 	//secant of pitch 
weight 	//lb-mass mass 
tas 		//ft/s true airspeed
gamma 	//deg earth relative fpa  
gi_change 	//flag indicating desired glideslope 
mep 			//flag indicating left handed hac 


//outputs 
nzc 	//g-units normal load factor increment from equilibrium
phic_at 	//deg commanded roll 
delrng 	//ft range error from altitude profile 
dpsac 	//deg heading error to the hac tangent 
dsbc_at 	//deg speedbrake command (angle at the hinge line, meaning each panel is deflected by half this????)
emep 	//ft energy/weight at which the mep is selected 
eow 		//ft energy/weight
es 		//ft energy/weight at which the s-turn is initiated 
rpred 	//ft predicted range to threshold 
phase 	//phase counter 
tg_end 	//termination flag 
eas_cmd 	//kn equivalent airspeed commanded 
herror 	//ft altitude error
qbarf 	//psf filtered dynamic press 



//input constants 


global taemg_constants is lexicon (
									"cdeqd", 0.68113130,	//gain in qbd calculation
									"cpmin", 0.707,		//cosphi min value 
									"cqdg", 0.31886860,		//gain for qbd calculation 
									"cqg", 0.5583958,		//gain for calculation of dnzcd and qbard 
									"cubic_c3", list(0, -0.3641168e-6, -0.3641168e-6),	//ft/ft^2 href curve fit quadratic term
									"cubic_c4", list(0, -0.9481026e-13, -0.9481026e-13),	//ft/ft^2 href curve fit cubic term
									"del_h1", 0.19,				//alt error coeff 
									"del_h2", 900,				//ft alt error coeff 
									"del_r_emax", list(0,54000,54000),		// -/ft/ft constant ised for computing emax 
									"dnzcg", 0.01,		//g-unit/s gain for dnzc
									"dnzlc1", -0.5,		//g-unit phase 0,1,2 nzc lower lim 
									"dnzlc2", -0.75,		//g-unit phase 3 nzc lower lim 
									"dnzuc1", 0.5,		//g-unit phase 0,1,2 nzc upper lim 
									"dnzuc2", 1.5,		//g-unit phase 3 nzc upper lim 
									"dsbcm", 0.9,		//mach at which speedbrake modulation starts 
									"dsblim", 98.6,	//deg dsbc max value 
									"dsbsup", 65,	//deg fixed spdbk deflection at supersonic 
									"dsbil", 20,	//deg min spdbk deflection 
									"dsbnom", 65,		//deg nominal spdbk deflection 
									"dshply", 4000,		//ft delta range value in shplyk 
									"dtg", 0.96,		//s taem guid cycle interval
									"dtr", 0.0174533 		//rad/deg deg2rad
									"edelc1", 1,			//emax calc constant 
									"edelc2", 1,			//emax calc constant 
									"edelnz", list(0, 4000, 4000),			// -/ft/ft eow delta from nominal energy line slope for s-turn
									"edrs", list(0, 0.6089492, 0.6089492),		// -/ ft^2/ft / ft^2/ft slope for s-turn energy line 
									"emep_c1", list(0, list(0,-371.3797, 14604.87), list(0, -371.3797, 14604.87)),		//all in ft mep energy line y intercept 
									"emep_c2", list(0, list(0,0.4168274, 0.2821187), list(0, 0.4168274, 0.2821187)),		//all in ft^2/ft mep energy line slope
									"en_c1", list(0, list(0, -254.2395, 17645.34), list(0, -254.2395, 17645.34)),		//all ft^2/ft nom energy line y-intercept 
									"en_c2", list(0, list(0, 0.5500275, 0.3890240), list(0, 0.5500275, 0.3890240)),		//all ft^2/ft nom energy line slope
									"es1", list(0, 90000, 90000),		//ft y-intercept of s-turn energy line 
									"eow_spt", list(0, 117718, 117718), 	//ft range at which to change slope and y-intercept on the mep and nom energy line 
									"g", 32.174,					//ft/s^2 earth gravity 
									"gamma_coef1", 0.0007,			//deg/ft fpa error coef 
									"gamma_coef2", 3,			//deg fpa error coef 
									"gamma_error", 4,			//deg fpa error band 
									"gamsgs", LIST(0, -20, -20),	//deg a/l steep glideslope angle
									"gdhc", 2.0, 			//  constant for computing gdh 
									"gdhll", 0.3, 			//gdh lower limit 
									"gdhs", 0.00007,		//1/ft	slope for computing gdh 
									"gdhul", 1.0,			//gdh upper lim 
									"gehdll", 0.01, 		//g/fps  gain used in computing eownzll
									"gehdul", 0.01, 		//g/fps  gain used in computing eownzul
									"gell", 0.1, 		//1/s  gain used in computing eownzll
									"geul", 0.1, 		//1/s  gain used in computing eownzul
									"gphi", 2.5, 		//heading err gain for phic 
									"gr", 0.02,			//deg/ft gain on rcir in computing ha roll angle command 
									"grdot", 0.2,			//deg/fps  gain on drcir/dt in computing ha roll angle command 
									"gsbe", 1.5, 			//deg/psf-s 	spdbk prop. gain on qberr 
									"gsbi", 0.1, 		//deg/psf-s gain on qberr integral in computing spdbk cmd
									"gy", 0.05,			//deg/ft gain on y in computing pfl roll angle cmd 
									"gydot", 0.6,		//deg/fps gain on ydot on computing pfl roll angle cmd 
									"h_error", 1000,		//ft altitude error bound
									"h_ref1", 2000,			//ft alt ref 
									"h_ref2", 2000,			//ft alt ref 
									"hali", LIST(0, 10018, 10018),		//ft altitude at a/l steep gs at MEP
									"hdreqg", 0.1,				//hdreq computation gain 
									"hftc", LIST(0, 12018, 12018),		//ft altitude of a/l steep gs at nominal entry pt
									"machad", 2.5,		//mach to use air data (used in gcomp appendix)
									"mxqbwt", 0.0007368421,		// psf/lb max l/d dyn press for nominal weight 
									"pbgc", LISt(0, 0.1125953, 0.1125953), 		//lin coeff of range for href and lower lim of dhdrrf
									"pbhc", LIST(0, 84821.29, 84821.29), 		//ft alt ref for drpred = pbrc
									"pbrc", LISt(0, 308109.5, 308109.5), 		//ft max range for cubic alt ref 
									"pbrcq", LIST(0, 122000, 122000), 			//ft range breakpoint for qbref
									"phavgc", 63.33,			//deg constant for phavg
									"phavgll", 30,			//deg lower lim of phavg
									"phavgs", 13.33,		//deg slope for phavg 
									"phavgul", 50, 			//deg upperl im for phavg 
									"philm0", 50,			//deg sturn roll cmd lim
									"philm1", 50,			//deg acq roll cmd lim 
									"philm2", 60,			//deg heading alignment roll cmd lim 
									"philm3", 30, 			//deg prefinal roll cmd lim 
									"philmsup", 30, 		//deg supersonic roll cmd lim 
									"phim", 1, 				//mach at which supersonic roll lim is removed
									"phip2c", 30,			//deg constant for phase 3 roll cmd 
									"p2trnc1", 1.1, 		//phase 2 transition logic constant 
									"p2trnc2", 1.01, 		//phase 2 transition logic constant 
									"qb_error1", -1,		//psf dyn press err bound 
									"qb_error2", 24, 		//psf dyn press err bound 
									"qbardl", 20,			//psf/s limit on qbard 
									"qbc1", LISt(0, 0.0005869565, 0.0005869565), 		//psf/ft slope of qbref dor drpred > pbrcq
									"qbc1", LISt(0, -0.001031695, -0.001031695), 		//psf/ft slope of qbref dor drpred < pbrcq
									"qbg1", 0.1,				//1/s gain for qbnzul and qbnzll
									"qbg2", 0.125,				//s-g/psf gain for qbnzul and qbnzll
									"qbmx0", 20,			//psf slope of qbmxnz when mach > qbm2
									"qbmx1", 340,			//psf constant for qbmxnz
									"qbmx2", 220,			//psf constant for qbmxnz
									"qbmx3", 250,			//psf constant for qbmxnz
									"qbm1", 1,				//mach breakpoint for computing qbmxnz
									"qbm2", 1,				//mach breakpoint for computing qbmxnz
									"qbrll", LIST(0, 153, 153),		//psf  qbref ll
									"qbrml", LIST(0, 180, 180),		//psf  qbref ml
									"qbrul", LIST(0, 265.43, 265.43),		//psf  qbref ul
									"rerrlm", 50,			//deg limit of rerrc 
									"rftc", 5,			//s roll fader time const 
									"rminst", LIST(0, 122204.6, 122204.6),		//ft min range allowed to initiate sturn 
									"rn1", LISt(0, 6542.886, 6542.866),			//ft range at which the gain on edelmz goes to zero 
									"rtbias", 3000,			//ft max value of rt for ha initiation
									"rtd", 	57.29578,			//deg/rad rad2teg
									"rturn", 20000,				//ft hac radius 
									"sbmin", 0,				//deg min sbrbk command (was 5)
									"tggs", LISt(0, -0.363978, 0.363978), 		//tan of steep gs for autoland 
									"vco", 1e20, 			//fps constant used in turn compensation 
									"wt_gs1", 250000, 			//lb max orbiter weight 
									"xa", LIST(0, -6500, -6500),		//steep gs intercept 
									"yerrlm", 120,				//deg limit on yerrc 
									"y_error", 1000,			//ft xrange err bound 
									"y_range1", 0.18,			//xrange coeff 
									"y_range2", 800			//ft xrange coeff 
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
							



).


global taemg_internal is lexicon(






).



function tgexec {
	PARAMETER taemg_input.
	
	if (irest=1) {
		tginit(taemg_input).
	}
	
	tgxhac(taemg_input).
	
	gtp(taemg_input).
	
	tgcomp(taemg_input).
	
	tgtran(taemg_input).
	
	tgnzc(taemg_input).
	
	tgsbc(taemg_input).
	
	tgphic(taemg_input).
	
	set iphase to 1.
	set isr 
	
	
	
	



}