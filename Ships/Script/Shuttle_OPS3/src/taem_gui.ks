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
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
							



).