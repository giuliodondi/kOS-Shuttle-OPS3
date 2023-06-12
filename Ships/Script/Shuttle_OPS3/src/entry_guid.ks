@LAZYGLOBAL OFF.


//input variables 
global entryg_input is lexicon(
								"dtegd",,		//iteration delta-t
								"alpha",,      //aoa
								"delaz",,       //az error  
								"drag",,        //drag accel (ft/s2) 
								"egflg",,       //mode flag  
								"hls",,		   //alt above rwy (ft)
								"lod",, 		//current l/d 
								"rdot",,        //alt rate (ft/s) 
								"roll",,	   //cur bank angle 
								"trange",,     //target range (nmi)
								"ve",, 		   //earth rel velocity (ft/s)
								"vi",,		   //inertial vel (ft/s)
								"xlfac",,      //load factor acceleration (ft/s2)
								"mm304ph",,    	//preentry bank 
								"mm304al",,    	//preentry aoa 
								"mep",, 			//hac selection flag 
).




//output variables 
global entryg_output is lexicon(
								"alpcmd",, 	//aoa cmd 	//rad
								"rolcmd",,	//bank cmd  //rad
								"drefp",,	//drag ref 	//ft/s2
								"drag",,	 	//actual drag	//ft/s2
								"rolref",,	//deg 	//roll ref
								"islect",, 	//phase indicator 
								"vcg",, 		//velocity start of const drag 	//ft/s 
								"vrr",, 		//velocity first reversal //ft/s 
								"eowd",,  	//eow //ft 
								"eei",,		//entry eval indicator 
								"eg_end",,
								"rc176g",, 	//first roll after 0.176g	//deg


).


//input constants

global entryg_constants is lexicon (
									"aclam1", 15.0,	//deg
									"aclam2", 0.0025,	//deg-s/ft ??
									"aclim1", 37,	//deg
									"aclim2", 0,	//deg-s/ft ??
									"aclim3", 7.6666667,	//deg
									"aclim4", 0.00223333,	//deg-s/ft
									"acn1", 50,	//time const for hdot feedback
									"ak", -3.4573,	//temp control dD/dV factor
									"ak1", -4.76,	//temp control dD/dV factor
									"alfm", 33.0,	//ft/s2 	desired const drag 
									"alim", 70.84,	//ft/s2 max accel in transition
									"almn1", 0.7986355,	//max l/d cmd outside heading err deadband
									"almn2", 0.9659258,	//max l/d cmd inside heading err deadband
									"almn3", 0.93969,	//max l/d cmd below velmn
									"almn4", 1.0,	//max l/d cmd above vylmax
									"astart", 5.66,		//ft/s2 accel to enter phase 2
									"calp0", list(0, 19.455, -4.074, -4.2778, 16.398, 4.476, -9.9339, 40, 40, 40, 40),	//deg alpcmd constant term in ve 
									"calp1", list(0, -0.776388e-2, 8.747711e-3, 0.8875002e-2, -0.3143109e-3, 3.1875e-3, 6.887436e-3, 0, 0, 0, 0),	//deg-s/ft 	alpcmd linear term in ve
									"calp2", list(0, 0.2152776e-5, -7.44e-7, -0.7638891e-6, 0.2571456e-6, 0, -2.374978e-7, 0, 0, 0, 0 ),	//deg-s2/ft2 	alpcmd quadratic term in ve
									"cddot1", 1500,	//ft/s 	cd velocity coef 
									"cddot2", 2000,	//ft/s 	cd velocity coef 
									"cddot3", 0.15, 	// 	cd velocity coef 
									"cddot4", 0.0783,	//cd alpha coef 
									"cddot5", -8.165e-3,	// 1/deg	cd alpha coef 
									"cddot6", 6.833e-4,		// 1/deg2	cd alpha coef 
									"cddot7", 7.5e-5,	//s/ft cddot coef 
									"cddot8", 13.666e-4,	//1/deg2	cddot coef
									"cddot9", -8.165e-3,	//1/s cddot coef
									"cnmfs", 1.645788e-4,	//nmi/ft 	conversion from feet to nmi 
									"crdeaf", 4,	//roll bias modulation gain
									"ct16", list(0, 0.1354, -0.1, 0.006),	// s2/ft - nd - s2/ft	c16 coefs
									"ct17", list(0, 1.537e-2, -5.8146e-1),	//s/ft - nd 	c17 coefs
									"ct16mn", 0.025,	//s2/ft		min c16
									"ct16mx", 0.35,		//s2/ft 	max c16
									"ct17mn", 0.0025,	//s/ft 		min c17
									"ct17mx", 0.014,	//s/ft 		max c17
									"ct13m2", 0.00133,	//s/ft 		min c17 when ict=1
									"cy0", -0.1309,		//rad 	constant term heading err deadband
									"cy1", 1.0908e-4,	//rad-s/ft 	linear term heading err deadband
									"c17mp", 0.75,		//c17 mult fact when ict=1
									"c21", 0.06,		//1/deg c20 cont val
									"c22", -0.001,		//1/deg c20 const value in linear term
									"c23", 4.25e-6,		//s/ft-deg 	c20 linear term
									"c24", 0.01,	//1/deg  c20 const value 
									"c25", 0,		//1/deg	c20 const value in linear term 
									"c26", 0,		//s/ft - deg 	c20 linear val 
									"c27", 0,		//1/deg c20 const val 
									"ddlim", 2,		//ft/s2	max drag for h feedback 
									"ddmin", 0.15,	//ft/s 	max drag error 
									"delv", 2300,	//ft/s phase transfer vel bias 
									"df", 21.0,	//ft/s2 final drag in transition phase
									"dlallm", 43,	//deg max constant
									"dlalpm", 2,		//deg delalp lim
									"d23c", 19.8,	//ft/s2 etg canned d23
									"d230", 19.8,	//ft/s2 initial d23 value
									"drddl", -1.5,	//nmi/s2/ft	minimum value of drdd
									"dtegd", 1.92,	//s entry guidance computation interval
									"dt2min", 0.008,	//ft/s3 min value of t2dot
									"dtr", 0.0174532925,	//rad/deg 	degrees to radians
									"eef4", 2.0e-6,		//ft2/s2	final ref energy level in transition
									"etran", 6.002262e7,	//ft2/s2	energy at start of transition
									"e1", 0.01,		//ft/s2 	min of drefp and drefp-df in transition
									"gs", 32.174,	//ft/s2 	earth gravity
									"gs1", 0.02,	//1/s	roll cmd smoohing fac 
									"gs2", 0.02,	//1/s	roll cmd smoohing fac 
									"gs3", 0.03767,	//1/s	roll cmd smoohing fac 
									"gs4", 0.03,	//1/s	roll cmd smoohing fac 
									"hsmin", 20500,	//ft 	min scale height 
									"hs01", 18075,	//ft scale height term 
									"hs02", 27000,	//ft scale height term 
									"hs03", 45583.5,	//ft scale height term 
									"hs11", 0.725,	//s scale height slope wrt ve  
									"hs13", -0.9445,	//s scale height slope wrt ve  
									"lodmin", 0.5,	//min l/d
									"nalp", 9,	//number of alpcmd velocity segment boundaries
									"mm304phi0", 0,	//standard preentry bank
									"mm304alp0", 40,	//standard preentry aoa
									"radeg", 57.29578,	//deg/rad radians to degrees
									"rdmax", 12,	//max roll bias 
									"rlmc1", 70,	//rlm max
									"rlmc2", 70,	//coeff in first rlm seg 
									"rlmc3", 0,		//deg/ft/s
									"rlmc4", 70,		//deg
									"rlmc5", 0,		//deg/ft/s
									"rlmc6", 70,		//deg	rlm min
									"rpt1", 22.4,	//nmi range bias
									"va", 27637,	//ft/s initial vel for temp quadratic, dD/dV = 0
									"valmod", 23000,	//ft/s modulation start flag for nonconvergence
									"valp", list(0, 2850, 3200, 4500, 6809, 7789.4, 14500, 14500, 14500, 14500),	//ft/s alpcmd vs ve boundaries
									"va1", 22000,	//ft/s matching point bw phase 2 quadratic segments
									"va2", 27637,	//ft/s initial vel dor temp quadratic dD/dV = 0
									"vb1", 19000,	//ft/s phase 2/3 boundary vel 
									"vc16", 23000,	//ft/s vel to start c16 drag error term
									"vc20", 2500,	//ft/s c20 vel break point
									"velmn", 8000,	//ft/s	max vel for limiting lmn by almn3
									"verolc", 8000,	//max vel for limiting bank cmd
									"vhs1", 12310,	//ft/s scale height vs ve boundary
									"vhs2", 19675.5,	//ft/s scale hgitht vs ve boundary 
									"vnoalp", 0,	//modulation start flag
									"vq", 5000,	//ft/s predicted end vel for const drag
									"vrlmc", 2500,	//ft/s rlm seg switch vel
									"vsat", 25766.2,	//ft/s local circular orbit vel 
									"vs1", 23283.5,		//ft/s eq glide ref vel 
									"vrdt", 23000,	//ft/s hdot feedback start vel 
									"v_taem", 2500,	//ft/s entry-taem interface ref vel 
									"vtran", 10500,	//ft/s nominal vel at start of transition 
									"vylmax", 23000,	//ft/s min vel st start of alm by almn4
									"ylmn", 0.03,	//rad yl bias used in test for lmn	
									"ylmn2", 0.07,	//rad mon yl bias 
									"y1", 0.3054326,	//rad max heading err deadband before first reversal
									"y2", 0.1745329,	//rad min heading error deadband 
									"y3", 0.3054326,	//max heading err deadband after first reversal 
									"zk", 1	//s hdot feedback gain

).


//internal variables
global entryg_internal is lexicon(
									"alclam", 0,   	//max allowable alpha
									"aclim", 0,   	//min allowable alpha 
									"acmd1", 0,   	//scheduled aoa
									"aldco", 0,   	//temp variable during phase 3
									"aldref", 0,   	//vertical l/d ref
									"alpcmd", 0,   	//aoa cmd 
									"alpdot", 0,   	//aoa dot 
									"arg", list(0,0,0,0),   	//1", cos(bank cmd), 2", cos(unlimited bank), 3", cos(ref bank)
									"a", list(0,0,0),   	//temp variable in computign range 
									"cag", 0,   	//pseudoenergy / mass used in transition 
									"cq1", list(0,0,0),   	//degree 0 for temp control quadratic 
									"cq2", list(0,0,0),   	//degree 1 for temp control quadratic 
									"cq3", list(0,0,0),   	//degree 2 for temp control quadratic 
									"c1", 0,   	//dD/dE i ntransition
									"c16", 0,   		//d(l/d) / dD
									"c17", 0,   		//d(l/d) / dH
									"c2", 0,   	//component of ref l/d 
									"c4", 0,    	//ref alt term 
									"c20", 0,   		//gain for dAlpha/dCd 
									"czold", 0,			// ??????
									"d23", 0,		//drag velocity profile is anchored at d23 at velocity vb1 - the phase 2/3 boundary
									"dd", 0,   		//drag - drefp 
									"dds", 0,   		//limited dd value
									"ddp", 0,   		//ddp prev 
									"delalf", 0,   	//delta alpha from schedule 
									"delalp", 0,   	//commanded alpha incr,   
									"dlrdot", 0,   	//r feedback 
									"dlim", 0,   	//max drefp in transition 
									"dlzrl", 0,   	//test var in bank angle compuation
									"drdd", 0,   	//dRange / dD 
									"dref", list(0,0,0)	//drefp for temperature quadratic
									"drefp", 0,   	//drag ref used in controller 
									"drefpt", 0,   	//drefp/dref in transition 
									"drefp1", 0,   	//eq glide
									"drefp3", 0,   	//tets value for transition to 3 
									"drefp4", 0,   	//test value for transiton to phase 4 
									"drefp5", 0,   	//test value for transition to phase 5 
									"drf", 0,   		//test value for transition to quadratic ref params 
									"dx", list(0,0,0),   	//drefp norm 
									"dzold", 0,   	//delaz prev 
									"dzsgn", 0,   	//change in delaz 
									"eef", 0,   		//energy over mass 
									"rdtrf", 0,   	//rdot temp control
									"hs", 0,   		//scale height
									"ialp", 0,   	//alpcmd segment counter 
									"ict", 0,   		//alpha mod flag 
									"idbchg", 0, 		// ?????
									"islecp", 0,   	//past value if islect 
									"islect", 0,   	//phase counter 
									"itran", FALSE,   	//transition init flag 
									"ivrr", 0,		//??????	
									"lmflg", 0,   	//saturated roll cmd flag 
									"lmn", 0,   		//max lodv value 
									"lodv", 0,   	//vertical l/d 
									"lodx", 0,   	//unlimited vert l/d cmd 
									"q", list(0,0,0,0),   	//drefp/ve in temp control 
									"rcg", 0,   		//range const drag 
									"rcg1", 0,   	//constant comp of rcg 
									"rdealf", 0,   	//alpha mod roll bias 
									"rdtref", 0,   	//rdot ref 
									"rdtrf1", 0,   	//rdot ref in phase 3 
									"rdtrft", 0, 	//?????
									"req1", 0,   	//eq glide range x d23
									"rer1", 0,   	//trans phase range 
									"rf", list(0,0,0),   	//tmp control segments ranges x d23
									"rff1", 0,   	//tmp control predicted range 
									"rdtrf", 0,   	//rdot ref corrected for cd 
									"rk2rol", 0,   	//bank angle direction 
									"rk2rlp", 0,   	//prev val 
									"rollc", list(0,0,0,0)	//1", roll angle command 2", unlimited roll command 3", roll ref 
									"rpt", 0,   	//desired range at vq 
									"r231", 0,   	//range of phase 2+3 * d23
									"start", 0,   	//first pass flag  
									"t1", 0,   		//eq glide vertical lift accel
									"t2", 0,   		//constant drag level to target 
									"t2old", 0,   		
									"t2dot", 0,   	//rate of t2 change -à
									"v_temp", list(0,0,0,0)	//velocity points for temp control 
									"vb2", 0,   		//vb ^ 2
									"vcg", 0,   		//phase 3/4 boundary vel 
									"ve2", 0,   		//ve ^ 2 
									"vf", list(0,0,0),    	//upper vel bounds for temp control 
									"vo", list(0,0,0),    	//????
									"vq2", 0,   	//vq ^ 2
									"vsat2", 0,   	//vsat ^ 2
									"vsit2", 0,   	//vs1 ^ 2
									"vtrb", 0,   	//rdot feedback vel lockout 
									"vx", list(0,0,0),   	//velocities where dD / dV  = 0 in temp control quadratic 
									"xlod", 0,   	//limited l/d 
									"yl", 0,   	//max heading eror abs val 
									"zk", 0   	//rdot feedback gain 
).


//egflg = 0,1 is normal mode, egflg=2 is canned mode for targeting (islect will never be > 2)
//phases (islect) : 
// 1 = preentry, 2 = temp control , 3 = eq glide , 4 = const drag , 5 = transition

function egexec {

	egscaleht().

	if entryg_internal["start"] = 0 {
		set entryg_input["dtegd"] to entryg_constants["dtegd"].
		eginit().
	}
	
	egcomn().
	
	//initial transition checks
	//needed for mode 1 transition or 
	
	// preentry termination, when load fac exceeds astart
	if (entryg_internal["islect"] = 1) and (entryg_input["xlfac"] > entryg_constants["astart"]) {
		set entryg_internal["islect"] to 2.
		
		// if less than v transition
		if (entryg_input["ve"] < entryg_constants["vtran"]) {
			set entryg_internal["islect"] to 5.
		}
	}
	
	//alternate termination of temp control 
	//if bank has not been matched by velocity vb1, force switch 
	if (entryg_internal["islect"] = 2 and entryg_input["ve"] < entryg_constants["vb1"]) {
		SET entryg_internal["islect"] To 3.
	}
	
	//alternate termination if required constant drag to target exceeds the max desired const.drag
	// for extremely short range
	if (entryg_internal["islect"] = 2 or entryg_internal["islect"] = 3) and ( entryg_internal["t2"] > entryg_constants["alfm"]) {
		set entryg_internal["islect"] to 4.
	}
	
	//for reentry simulation using a canned drag profile ??
	if (entryg_input["egflg"] > 0) and (entryg_internal["islect"] > 2) {
		set entryg_internal["islect"] to 2.
	}
	
	if (entryg_internal["islect"] = 1) {
		//compute vertical l/d during preentry 
		egpep().
	} else if (entryg_internal["islect"] = 2) OR (entryg_internal["islect"] = 3) {
		//reference parameters during temperature control and eq glide 
		egrp().
		egref().
	} else if (entryg_internal["islect"] = 4) {
		//reference parameters during const drag
		egref4().
	} else if (entryg_internal["islect"] = 5) {
		//reference parameters during transition
		egtran().
	} 
	
	//aoa command
	egalpcmd().

	//vertical l/d after preentry	//can I move these before egalpcmd ?? probably not  
	if (entryg_internal["islect"] > 1) {
		eggnslct().
		eglodvcmd().
	}
	
	//roll command 
	egrolcmd().
	
	//transition checks 
	if (entryg_internal["islect"] > 1) {
		if (entryg_internal["islect"] = 2) {
			//nominal temp control termination 
			//switch occurs when temp.control bank command matches the const glide bank, to avoid jumps
			//controlled by variable gs2 inside drefp3
			if (entryg_input["ve"] < entryg_constants["va"]) and (entryg_internal["drefp"] < entryg_internal["drefp3"]) {
				set entryg_internal["islect"] to 3.
			}
			
			//short range temp control termination 
			//if required const drag is reached during temp control, skip phase 3 
			//bank smoothing is controlled by variable gs3 inside drefp4
			if (entryg_input["ve"] < (entryg_internal["vcg"] + entryg_constants["delv"])) and (entryg_internal["drefp"] > entryg_internal["drefp4"]) {
				set entryg_internal["islect"] to 4.
			}
			
		} else if (entryg_internal["islect"] = 3) {
			//this now becomes the nominal phase 3 termination
			//bank smoothing is controlled by variable gs3 inside drefp4
			if (entryg_input["ve"] < (entryg_internal["vcg"] + entryg_constants["delv"])) and (entryg_internal["drefp"] > entryg_internal["drefp4"]) {
				set entryg_internal["islect"] to 4.
			}
			
			//very long range termination of phase 3 
			//if the phase 3/4 velocity is less than the phase 4/5 vtran, skip phase 4
			//bank smoothing is controlled by variable gs4 inside drefp5
			if (entryg_input["ve"] < (entryg_constants["vcg"] + entryg_constants["delv"])) and (entryg_internal["drefp"] > entryg_internal["drefp5"]) and (entryg_internal["vcg"] < entryg_constants["vtran"]) {
				set entryg_internal["islect"] to 5.
			}
		} else if (entryg_internal["islect"] = 4) {
			//termination of phase 4 at a predetermined time before energy etran is reached 
			if (entryg_input["ve"] < (entryg_constants["vtran"] + entryg_constants["delv"])) and (entryg_internal["drefp"] > entryg_internal["drefp5"]) {
			
			}
		}
		
		//entry guidance termination 
		if (entryg_input["ve"] < entryg_constants["v_taem"]) {
			set entryg_output["eg_end"] to TRUE.
		}
	}
	
	
}

//scale height for hdot reference term
function egscaleht {

    if (entryg_input["ve"] < entryg_constants["vhs1"]) {
        set entryg_internal["hs"] to entryg_constants["hs01"] + entryg_constants["hs11"] * entryg_input["ve"].
    } else if (entryg_input["ve"] < entryg_constants["vhs2"]) {
		set entryg_internal["hs"] to entryg_constants["hs02"].
	} else {
		set entryg_internal["hs"] to entryg_constants["hs03"] + entryg_constants["hs13"] * entryg_input["ve"].
	}

	set entryg_internal["hs"] to max(entryg_internal["hs"], entryg_constants["hsmin"]).

}


function eginit {
	
	//might want to do a ve test if we resume entry halfway
	set entryg_internal["islect"] to 1.

	set entryg_internal["czold"] to 0.
	set entryg_internal["ivrr"] to 0.
	set entryg_internal["itran"] to FALSE.
	set entryg_internal["ict"] to 0.
	set entryg_internal["idbchg"] to 0.		//???
	set entryg_internal["t2"] to 0.
	set entryg_internal["drefp"] to 0.
	set entryg_internal["vq2"] to entryg_constants["vq"]*entryg_constants["vq"].
	set entryg_internal["rk2rol"] to -sign(delaz).
	set entryg_internal["dlrdot"] to 0.
	set entryg_internal["lmflg"] to 0.
	set entryg_internal["vtrb"] to 60000.	//ft/s
	set entryg_internal["ddp"] to 0.
	set entryg_internal["rk2rlp"] to rk2rol.
	
	//nominal transition range at vtran (nmi)
	//this is kept fixed for range calculations of phase 2,3,4
	set entryg_internal["rpt"] to -(( entryg_constants["etran"] - entryg_constants["eef4"] )* LN(entryg_constants["df"] / entryg_constants["alfm"]) / (entryg_constants["alfm"] - entryg_constants["df"]) + (entryg_constants["vtran"]^2 - entryg_internal["vq2"]) / (2*entryg_constants["alfm"]) ) * entryg_constants["cnmfs"] + entryg_constants["rpt1"].
	
	set entryg_internal["vsat2"] to entryg_constants["vsat"]^2.
	set entryg_internal["vsit2"] to entryg_constants["vs1"]^2.
	
	set entryg_internal["vcg"] to entryg_constants["vq"].
	set entryg_internal["d23"] to entryg_constants["d230"].
	set entryg_internal["dx"][1] to 1.
	
	set entryg_internal["vo"][1] to entryg_constants["vb1"].
	set entryg_internal["vo"][2] to entryg_constants["va1"].
	
	set entryg_internal["vx"][1] to entryg_constants["va"].
	set entryg_internal["vx"][2] to entryg_constants["va2"].
	
	set entryg_internal["vf"][1] to entryg_constants["va1"].
	
	set entryg_internal["a"][2] to entryg_constants["ak1"].
	set entryg_internal["vb2"] to entryg_constants["vb1"]^2.
	
	//component of constant drag phase 
	set entryg_internal["rcg1"] to entryg_constants["cnmfs"] * ( entryg_internal["vsit2"]  - entryg_internal["vq2"]) / (2*entryg_constants["alfm"]).
	set entryg_internal["ialp"] to entryg_constants["nalp"].
	set entryg_internal["start"] to 1.
}

function egcomn {

	set entryg_internal["xlod"] to max(entryg_input["lod"], entryg_constants["lodmin"]).
	
	set entryg_internal["t1"] to entryg_constants["gs"] * (entryg_input["vi"]^2 / entryg_internal["vsat2"] - 1).
	set entryg_internal["t2old"] to entryg_internal["t2"].
	
	set entryg_internal["ve2"] to entryg_input["ve"]^2.
	
	set entryg_internal["eef"] to entryg_constants["gs"] * entryg_input["hls"] + entryg_internal["ve2"] / 2.
	
	set entryg_output["eowd"] to entryg_internal["eef"] / entryg_constants["gs"].
	
	set entryg_internal["cag"] to 2* entryg_constants["gs"]*entryg_internal["hs"] + entryg_internal["ve2"].
	
	if (entryg_internal["islect"] < 5) {
		set entryg_internal["t2"] to entryg_constants["cnmfs"] * (entryg_internal["ve2"] - entryg_internal["vq2"]) / (2*( entryg_input["trange"] - entryg_internal["rpt"])).
		set entryg_internal["t2dot"] to (entryg_internal["t2"] - entryg_internal["t2old"]) / entryg_input["dtegd"].
		
		if ( entryg_input["ve"] < (entryg_constants["vtran"] + entryg_constants["delv"]) {
			set entryg_internal["c1"] to (entryg_internal["t2"] - entryg_constants["df"]) / ( entryg_constants["etran"] - entryg_constants["eef4"]).
			set entryg_internal["rdtrft"] to - (entryg_internal["c1"] * (entryg_constants["gs"]  * entryg_input["hls"] - entryg_constants["eef4"] ) + entryg_constants["df"] ) * 2 * entryg_input["ve"] * entryg_internal["hs"] / entryg_internal["cag"].
			
			set entryg_internal["drefp5"] to entryg_constants["df"] + (entryg_internal["eef"] - entryg_constants["eef4"]) * entryg_internal["c1"] + entryg_constants["gs4"] * (entryg_internal["rdtref"] - entryg_internal["rdtrft"])
		}
	
	}
	
}

//vertical l/d during preentry
function egpep {
	set entryg_internal["lodx"] to entryg_internal["xlod"] * COS( entryg_input["mm304ph"] / entryg_constants["radeg"] ).
	set entryg_internal["lodv"] to entryg_internal["lodx"].

}

//range prediction for phase 2 and 3 
function egrp {

	local k is 1.
	local n is 1.

	if (entryg_input["ve"] > entryg_constants["va1"]) {
		set k to 2.
		set n to 2.
	} else {
		set entryg_internal["rf"][2] to 0.
	}
	
	set entryg_internal["vf"][n] to entryg_input["ve"].
	
	if (entryg_internal["start"] = 1) {
		set entryg_internal["start"] to 2.
		set k to 1.
		
		FROM {local i is 1.} UNTIL i > 2 STEP {set i to i + 1.} DO { 
			if (i = 2) {
				entryg_internal["dx"][2] = entryg_internal["cq1"][1] + entryg_constants["va1"] * (entryg_internal["cq2"][1] + entryg_internal["cq3"][1] * entryg_constants["va1"]).
			}
			
			// DISCREPANCY IN THE DOCS - CQ3[I] HAS A MINUS SIGN OR NOT????
			set entryg_internal["cq3"][i] to -entryg_internal["a"][i]*entryg_internal["dx"][i] / (2*(entryg_internal["vx"][i] - entryg_internal["vo"][i])*entryg_internal["vo"][i]).
			set entryg_internal["cq2"][i] to -2*entryg_internal["vx"][i]*entryg_internal["cq3"][i].
			set entryg_internal["cq1"][i] to entryg_internal["dx"][i] - entryg_internal["vo"][i]*(entryg_internal["cq2"][i] + entryg_internal["cq3"][i]*entryg_internal["vo"][i]).
		
		}
	}
	
	FROM {local i is k.} UNTIL i > n STEP {set i to i + 1.} DO { 
	
		if (entryg_input["ve"] < entryg_internal["vo"][i]) {
			set entryg_internal["rf"][i] to 0.
		} else {
			set entryg_internal["v_temp"][1] to (8*entryg_internal["vo"][i] + entryg_internal["vf"][[i])/9.
			set entryg_internal["v_temp"][2] to (entryg_internal["vo"][i] + entryg_internal["vf"][[i])/2.
			set entryg_internal["v_temp"][3] to entryg_internal["vo"][i] + entryg_internal["vf"][[i] - entryg_internal["v_temp"][1].
			
			FROM {local j is 1.} UNTIL j > 3 STEP {set j to j + 1.} DO {  
				set entryg_internal["q"][j] to entryg_internal["cq1"][i]/entryg_internal["v_temp"][j] + entryg_internal["cq2"][i] + entryg_internal["cq3"][i]*entryg_internal["v_temp"][j].
			}
			
			set entryg_internal["rf"][i] to (27/entryg_internal["q"][1] + 44/entryg_internal["q"][2] + 27/entryg_internal["q"][3])*(entryg_internal["vf"][i] - entryg_internal["vo"][i])/98.
			
		}
	}
	
	set entryg_internal["rff1"] to entryg_constants["cnmfs"] * (entryg_internal["rf"][1] + entryg_internal["rf"][2]).
	
	//calculate drag d23 at vb1 
	if (entryg_internal["t2dot"] > entryg_constants["dt2min"]) or (entryg_input["ve"] > (entryg_internal["vcg"] + entryg_constants["delv"])) {
		if (entryg_input["ve"] < entryg_constants["vb1"]) {
			set entryg_internal["vb2"] to entryg_internal["ve2"].
		}
		
		set entryg_internal["vcg"] to entryg_constants["vq"].
		local d23l is entryg_constants["alfm"] * (entryg_internal["vsit2"] - entryg_internal["vb2"])/(entryg_internal["vsit2"] - entryg_internal["vq2"]).
		
		if (entryg_internal["d23"] > d23l) {
			set entryg_internal["vcg"] to SQRT( entryg_internal["vsit2"] - d23l*(entryg_internal["vsit2"] - entryg_internal["vq2"])/entryg_internal["d23"]).
		} else {
			set entryg_internal["d23"] to d23l.
		}
		
		set entryg_internal["a"][2] to entryg_constants["cnmfs"] * (entryg_internal["vsit2"] - entryg_internal["vb2"])/2.
		
		set entryg_internal["req1"] to entryg_internal["a"][2]*LN(entryg_constants["alfm"] / entryg_internal["d23"]).
		set entryg_internal["rcg"] to entryg_internal["rcg1"] - entryg_internal["a"][2] / entryg_internal["d23"].
		set entryg_internal["r231"] to entryg_internal["rff1"] + entryg_internal["req1"].
		local r23 is entryg_input["trange"] - entryg_internal["rcg"] - entryg_internal["rpt"].
		local d231 is entryg_internal["r231"] / entryg_internal["d23"].
		set entryg_internal["drdd"] to -r23 / d231.
		
		if (d231 >= d23l) {
			set entryg_internal["d23"] to d231 + entryg_internal["a"][2]*(1 - entryg_internal["d23"] / d231)^2/(2*r23).
		} else {
			set entryg_internal["d23"] to max(d231, entryg_constants["e1"]).
		}
		
		if (entryg_input["egflg"] > 1) {
			set entryg_internal["d23"] to entryg_constants["d23c"].
		}
	}


}

//reference params for temp control and eq glide 
function egref {

	//temp control 
	if (ve > vb1) {
	
	}
	
	//eq glide 
	if (ve < va) {
	
	}
	
	//test value for drefp for transition to phase 4
	set drefp4 to 
	
	set itran to TRUE.


}