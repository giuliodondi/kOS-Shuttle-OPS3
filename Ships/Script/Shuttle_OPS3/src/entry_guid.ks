@LAZYGLOBAL OFF.

GLOBAL mt2ft IS 3.28084.		// ft/mt
GLOBAL km2nmi IS 0.539957.	// nmi/km

//input variables 
//global entryg_input is lexicon(
//								"dtegd",,		//iteration delta-t
//								"alpha",,      //aoa
//								"delaz",,       //az error  
//								"drag",,        //drag accel (ft/s2) 
//								"egflg",,       //mode flag  
//								"hls",,		   //alt above rwy (ft)
//								"lod",, 		//current l/d 
//								"rdot",,        //alt rate (ft/s) 
//								"roll",,	   //cur bank angle 
//								"trange",,     //target range (nmi)
//								"ve",, 		   //earth rel velocity (ft/s)
//								"vi",,		   //inertial vel (ft/s)
//								"xlfac",,      //load factor acceleration (ft/s2)
//								"mm304ph",,    	//preentry bank 
//								"mm304al",,    	//preentry aoa 
//								"mep",, 			//hac selection flag 
//).


//wrapper for the entry function, to transform the input and output units 



FUNCTION entryg_wrapper {
	PARAMETER entryg_input.
	
	LOCAL eg_input IS lexicon(
							"dtegd", entryg_input["iteration_dt"],		//iteration delta-t
							"tgtsite",  entryg_input["tgtsite"],      //name of the tgt site, my addition
							"alpha", entryg_input["alpha"],      //aoa
							"delaz", entryg_input["delaz"],       //az error
							"drag", entryg_input["drag"],        //drag accel (ft/s2) 
							"egflg", entryg_input["egflg"],       //mode flag  
							"hls", entryg_input["hls"]*mt2ft,		   //alt above rwy (ft)
							"lod", entryg_input["lod"], 		//current l/d 
							"rdot", entryg_input["hdot"]*mt2ft,        //alt rate (ft/s) 
							"gamma", entryg_input["gamma"],			//deg current fpa
							"roll", entryg_input["roll"],	   //cur bank angle 
							"trange", entryg_input["tgt_range"]*km2nmi,     //target range (nmi)
							"ve", entryg_input["ve"]*mt2ft, 		   //earth rel velocity (ft/s)
							"vi", entryg_input["vi"]*mt2ft,		   //inertial vel (ft/s)
							"xlfac", entryg_input["xlfac"],      //load factor acceleration (ft/s2)
							"cd", entryg_input["cd"],      //drag coef from FAR
							"mm304ph", entryg_constants["mm304phi0"],    	//preentry bank 
							"mm304al", entryg_constants["mm304alp0"],    	//preentry aoa ,
							"ital", entryg_input["ital"]				//is tal abort flag
	).
	
	local dump_overwrite is (NOT entryg_internal["fpflag"]).

	egexec(eg_input).
	
	if (entryg_input["debug"]) {
		entryg_dump(eg_input, dump_overwrite).
	}
	
	//work out the guidance mode - needs to be consistent with the hud string mappings
	local guid_id is 10 + entryg_internal["islect"].
	
	//i want to return a new lexicon of internal variables
	return lexicon(
								"guid_id", guid_id,					//counter to signal the current mode to the hud 
								"alpcmd", entryg_internal["alpcmd"],
								"aclam", entryg_internal["aclam"],		//my addition, required by the dap
								"aclim", entryg_internal["aclim"],		//my addition, required by the dap
								"rolcmd", entryg_internal["rolcmd"],
								"spdbcmd", entryg_internal["spdbcmd"] / entryg_constants["dsblim"], 	//deg speedbrake command (angle at the hinge line, meaning each panel is deflected by half this????)
								"drag_ref", entryg_internal["drefp"],
								"drag", entryg_input["drag"],
								"unl_roll", entryg_internal["rk2rol"] * entryg_internal["rollc"][2],
								"roll_ref", entryg_internal["rk2rol"] * entryg_internal["rollc"][3],
								"rlm", entryg_internal["rlm"],		//my addition, required by the dap
								"hdot_ref", entryg_internal["rdtrf"]/mt2ft,
								"islect", entryg_internal["islect"],
								"roll_rev", entryg_internal["rrflag"],
								"pitch_mod", entryg_internal["ict"],
								"vcg", entryg_internal["vcg"]/mt2ft,
								"eowd", entryg_internal["eowd"],
								"ileflg", entryg_internal["ileflg"],
								"eg_end", entryg_internal["eg_end"],
								"eg_conv", (entryg_internal["n_iter"] = 0)		//my addition: signal that enough iterations have been done
	).
}


//input constants

global entryg_constants is lexicon (
									"aclam1", 9.59,	//deg
									"aclam2", 3.3e-3,	//deg / (ft/s)
									"aclim1", 37,	//deg
									"aclim2", 25,	//deg
									"aclim3", -18.5,	//deg
									"aclim4", 2.5e-3,	//deg / (ft/s)
									"aclim5", 10,	//deg
									"aclim6", 5.95,	//deg
									"aclim7", 3e-3,	//deg / (ft/s)
									"vaclim", 12000,	//ft/s
									
									"acn1", 50,	//time const for hdot feedback
									//"ak", -3.4573,	//temp control dD/dV factor	STS_1
									"ak", -3.5,	//temp control dD/dV factor	
									"ak1", -5.5,	//temp control dD/dV factor
									//"alfm", 33.0,	//ft/s2 	desired const drag STS-1
									"alfmax", 43,	//ft/s2 	maximum allowable drag
									"alfm", 33,	//ft/s2 	desired const drag
									"tal_alfm", 35,	//ft/s2 	my addition: desired const drag for tal
									"alim", 70.84,	//ft/s2 max accel in transition
									"almn1", 0.7986355,	//max l/d cmd outside heading err deadband
									"almn2", 0.9659258,	//max l/d cmd inside heading err deadband
									"almn3", 0.93969,	//max l/d cmd below velmn
									"almn4", 1.0,	//max l/d cmd above vylmax
									"astart", 3,		//ft/s2 accel to enter phase 2	//was 5.66
									
									//"valp", list(0, 500, 7500, 8500, 18000, 19000, 22000, 23000),	//ft/s alpcmd vs ve boundaries 	//38-28 profile
									//"calp0", list(3, 1.333333, -92.4166, 28, 433 , -18.25, -623.25, 38),	//deg alpcmd constant term in ve 	//38-28 profile
									//"calp1", list(0, 3.333333e-3, 0.0283333, 0, -0.045, 2.5e-3, 0.0575, 0),	//deg-s/ft 	alpcmd linear term in ve 	//38-28 profile
									//"calp2", list(0, 0, -1.66667e-6, 0, 1.25e-6, 0, -1.25e-6, 0),	//deg-s2/ft2 	alpcmd quadratic term in ve 	//38-28 profile
									
									//3B profile
									"valp", list(0, 500, 7070, 8070, 18000, 19000, 22000, 23000),	//ft/s alpcmd vs ve boundaries 	//38-28 profile
									"calp0", list(5, 7.285, -67.4424, 30, 435, -16.25, -646.55, 40),	//deg alpcmd constant term in ve 	//40-30 profile
									"calp1", list(0, 0.003, 0.02414, 0, -0.045, 0.0025, 0.05975, 0),	//deg-s/ft 	alpcmd linear term in ve 	//40-30 profile
									"calp2", list(0, 0, -1.495e-6, 0, 1.25e-6, 0, -0.13e-5, 0),	//deg-s2/ft2 	alpcmd quadratic term in ve 	//40-30 profile
									
									//TAL profile 
									"tal_valp", list(0, 500, 7070, 8070, 17500, 18500, 20000, 21000),
									"tal_calp0", list(5, 7.285, -67.4424, 30, 826.25, -63.6, -1103.6, 43),
									"tal_calp1", list(0, 0.003, 0.02414, 0, -0.091, 0.0052, 0.1092, 0),
									"tal_calp2", list(0, 0, -1.495e-6, 0, 2.6e-6, 0, -2.6e-6, 0),
									

									//original cd coefficients
									//"cddot1", 1500,	//ft/s 	cd velocity coef 
									//"cddot2", 2000,	//ft/s 	cd velocity coef 
									//"cddot3", 0.15, 	// 	cd velocity coef 
									//"cddot4", 0.0783,	//cd alpha coef 
									//"cddot5", -8.165e-3,	// 1/deg	cd alpha coef 
									//"cddot6", 6.833e-4,		// 1/deg2	cd alpha coef 
									//"cddot7", 7.5e-5,	//s/ft cddot coef 
									
									//my own fitted coefficients from FAR
									"cddot1", 1918.42,	//ft/s 	cd velocity coef 
									"cddot2", 2195.26,	//ft/s 	cd velocity coef 
									"cddot3", 0.24511, 	// 	cd velocity coef 
									"cddot4", 0.08497,	//cd alpha coef 
									"cddot5", -1.594487e-2,	// 1/deg	cd alpha coef 
									"cddot6", 9.71138e-4,		// 1/deg2	cd alpha coef 
									"cddot7", 9.5e-5,	//s/ft cddot coef 
									
									"cddot8", 13.666e-4,	//1/deg2	cddot coef
									"cddot9", -8.165e-3,	//1/s cddot coef
									"cnmfs", 1.645788e-4,	//nmi/ft 	conversion from feet to nmi 
									"crdeaf", 4,	//roll bias due to pitch modulation gain	//was 4
									"c16_kd", 0.8, 			//my addition: c16 gain factor to control derivative damping term
									//"ct16", list(0, 0.1354, -0.1, 0.006),	// s2/ft - nd - s2/ft	c16 coefs STS-1
									"ct16", list(0, 0.27, -0.2, 0.018),	// s2/ft - nd - s2/ft	c16 coefs
									//"ct17", list(0, 1.537e-2, -5.8146e-1),	//s/ft - nd 	c17 coefs STs-1
									"ct17", list(0, 6.148e-3, -5.8146e-1),	//s/ft - nd 	c17 coefs
									"ct16mn", 0.025,	//s2/ft		min c16
									"ct16mx", 0.36,		//s2/ft 	max c16
									"ct17mn", 0.0025,	//s/ft 		min c17
									"ct17mx", 0.014,	//s/ft 		max c17
									"ct17m2", 0.00133,	//s/ft 		min c17 when ict=1
									"cy0", -7.5,		//deg 	constant term heading err deadband
									"cy1", 0.0062498,	//deg-s/ft 	linear term heading err deadband
									"c17mp", 0.75,		//c17 mult fact when ict=1
									"c21", 1.5 * 0.06,		//1/deg c20 cont val
									"c22", 1.5 * -0.001,		//1/deg c20 const value in linear term
									"c23", 1.5 * 4.25e-6,		//s/ft-deg 	c20 linear term
									"c24", 1.5 * 0.01,	//1/deg  c20 const value 
									"c25", 1.5 * 0.01,		//1/deg	c20 const value in linear term 		//altered to make alp moduln less violent
									"c26", 0,		//s/ft - deg 	c20 linear val 
									"c27", 0,		//1/deg c20 const val 
									"ddlim", 2,		//ft/s2	max drag for h feedback 
									"ddmin", 0.05,	//ft/s 	min drag error to toggle alpha mod
									"delv", 2300,	//ft/s phase transfer vel bias - STS-1
									//"df", 21.0,	//ft/s2 final drag in transition phase	STS-1
									"df", 19.09,	//ft/s2 final drag in transition phase	STS-1
									"dlallm", 43,	//deg max constant
									"dlaplm", 2,		//deg delalp lim
									"dlrdotl", 150,		//ft/s???? clamp value for rdot feedback 
									"d23c", 15.5,	//ft/s2 etg canned d23
									"d230", 15.5,	//ft/s2 initial d23 value
									"drddl", -1.5,	//nmi/s2/ft	minimum value of drdd
									"dtegd", 1.92,	//s entry guidance computation interval
									"dt2min", 0.008,	//ft/s3 min value of t2dot
									"dtr", 0.0174532925,	//rad/deg 	degrees to radians
									"eef4", 2.5e6,		//ft2/s2	final ref energy level in transition
									//"etran", 6.502262e7,	//ft2/s2	energy at start of transition	STS-1
									"etran", 7.002262e7,	//ft2/s2	energy at start of transition
									"e1", 0.01,		//ft/s2 	min of drefp and drefp-df in transition
									"gs", 32.174,	//ft/s2 	earth gravity
									"gs1", 0.02,	//1/s	roll cmd smoohing fac 
									"gs2", 0.02,	//1/s	roll cmd smoohing fac 
									//"gs3", 0.03767,	//1/s	roll cmd smoohing fac 	STS-1
									"gs3", 0,	//1/s	roll cmd smoohing fac 
									"gs4", 0.03,	//1/s	roll cmd smoohing fac 
									"hsmin", 20500,	//ft 	min scale height 
									"hs01", 21075,	//ft scale height term 
									"hs02", 27000,	//ft scale height term 
									"hs03", 45583.5,	//ft scale height term 
									"hs11", 0.725,	//s scale height slope wrt ve  
									"hs13", -0.9445,	//s scale height slope wrt ve  
									"lodmin", 0.5,	//min l/d
									"nalp", 7,	//number of alpcmd velocity segment boundaries
									"mm304phi0", 0,	//standard preentry bank
									"mm304alp0", 40,	//standard preentry aoa
									"radeg", 57.29578,	//deg/rad radians to degrees
									"rdmax", 12,	//max roll bias 
									"rlmndzfac", 2.2,	//min roll delaz gain 
									"rlmc0", 95,	//rlm max above verolc
									"tal_rlmc0", 120,	//rlm max above tal_verolc for tal
									"rlmdz", 70,		//max roll delaz limiting
									"rlmc1", 70,	//rlm max
									"rlmc2", -47,	//coeff in first rlm seg 
									"rlmc3", 0.03,		//deg/ft/s
									"rlmc4", -47,		//deg
									"rlmc5", 0.03,		//deg/ft/s
									"rlmc6", 30,		//deg	rlm min
									//"rpt1", 22.4,	//nmi phase 5 range bias during previous phases	//OTT
									"rpt1", 8,	//nmi phase 5 range bias during previous phases	//OTT
									//"va", 27637,	//ft/s initial vel for temp quadratic, dD/dV = 0	STS-1
									"va", 29000,	//ft/s initial vel for temp quadratic, dD/dV = 0	
									"valmod", 23000,	//ft/s modulation start flag for nonconvergence
									//"va1", 22000,	//ft/s matching point bw phase 2 quadratic segments	STS-1
									"va1", 23500,	//ft/s matching point bw phase 2 quadratic segments	STS-1
									//"va2", 27637,	//ft/s initial vel dor temp quadratic dD/dV = 0		STS-1
									"va2", 17000,	//ft/s initial vel dor temp quadratic dD/dV = 0
									"vb1", 19000,	//ft/s phase 2/3 boundary vel STS-1
									"vc16", 23000,	//ft/s vel to start c16 drag error term
									"vc20", 2500,	//ft/s c20 vel break point
									"velmn", 8000,	//ft/s	max vel for limiting lmn by almn3
									"verolc", 8000,	//max vel for limiting bank cmd
									"verlmndz", 18000,	//max vel for delaz min bank
									"tal_verolc", 18000,	//max vel for limiting bank cmd by tal_rlmc0
									"vhs1", 12310,	//ft/s scale height vs ve boundary
									"vhs2", 19675.5,	//ft/s scale hgitht vs ve boundary 
									//"vnoalp", 20500,	//pch mod start velocity//	//took the value from the sts-1 paper
									"vnoalp", 22000,	//pch mod start velocity//
									"tal_vnoalp", 19000,	//pch mod start velocity for tal//	
									"vq", 10499,	//ft/s predicted end vel for const drag			//changed for consistency with vtran
									"vrlmc", 2750,	//ft/s rlm seg switch vel
									"vsat", 25766.2,	//ft/s local circular orbit vel 
									"vs1", 23283.5,		//ft/s eq glide ref vel 
									"vrdt", 23000,	//ft/s hdot feedback start vel 
									"vrr", 0, 		//velocity first reversal //ft/s 
									"v_taem", 2500,	//ft/s entry-taem interface ref vel 
									"v_taem_high", 4000,	//ft/s my addition: high-energy taem velocity
									"r_taem", 45,	//nm my addition: force transition below this range
									"r_taem_high", 75,	//nm my addition: high-energy transition range
									"vtrb0", 60000,	//ft/s initial value of vtrb
									//"vtran", 10500,	//ft/s nominal vel at start of transition STS-1
									"vtran", 9000,	//ft/s nominal vel at start of transition
									"vylmax", 23000,	//ft/s min vel to limit lmn by almn4
									"ylmin", 1.72,	//deg yl bias used in test for lmn	
									"ylmn2", 4.01,	//deg mon yl bias 
									"y1", 12,	//deg max heading err deadband before first reversal	//was 17.5 deg
									"y2", 9.97,	//deg min heading error deadband 
									"y3", 17.5,	//deg max heading err deadband after first reversal 
									//"zk1", 1,	//s hdot feedback gain		//OTT and STS-1
									"zk1", 0,	//s hdot feedback gain		//try to disable it as in theory we shouldn't need it in ksp
									
									//my addition: speedbrake constants ported form taem
									"dsblim", 98.6,	//deg dsbc max value 
									"del1sb", 3.125,		//speedbrake open rate
									"vsbsw", 6000,			// ft/s velocity for switching speedbrake segment
									"egsbl1", 0,			//upper speedbrake limit
									"egsbu1", 81,			//upper speedbrake limit
									"vesbs1", -0.081,			//linear coef for speedbrake
									"vesbi1", 810,			//constant coef for speedbrake
									"egsbl2", 65,			//upper speedbrake limit
									"egsbu2", 81,			//upper speedbrake limit
									"vesbs2", 0.02,			//linear coef for speedbrake
									"vesbi2", -1,			//constant coef for speedbrake
									
									//other misc stuff added by me 
									"drolcmdfil", 15,	//° roll cmd value band to apply filtering
									"rolcmdfildt", 10,	//° roll cmd value filtering time const
									"n_iter", 10,		// guidance iterations before steering commands should be accepted
									
									// low energy logic
									"alpwle_c1", 16.45,		//° wle alpha const coef
									"alpwle_c2", 0.0018,		//°/(ft/s) wle alpha linear coef
									"alpwle_c3", -2.58e-8,		//°/(ft/s2) wle alpha linear coef
									"rtbfac", 0.05,		//Low–energy logic: range bias factor
									"dzbias", 8,		//° Low–energy logic: DELAZ value for range biasing
									"dzfdel", 0.003,	//1/s Low–energy logic: constant for  DZFCTR increment / decrement
									"beqglmbs", 1,		//ft/s2 bias for beqglm check
									"eqglm1", list(0, 46.341, 26.129, 8.1893),		//ft/s2 beqglm const terms
									"eqglm2", list(0, -0.0019, -0.0008, 0.0013),		//ft/s2 beqglm linear terms
									"veeqglm", list(0, 30000, 18375, 8543),		//ft/s2 ve to switch beqglm segments
									"cnvtst", 0.5,		//° Low–energy logic: alpha profile convergence test criterion
									"rdotpo", 200,		//ft/s Low–energy logic: pullout altitude rate
									"dlzdb1", 3,		//° Low–energy logic: delaz limit for zero roll if delaz increasing
									"dlzdb2", 5,		//° Low–energy logic: delaz limit for zero roll if delaz decreasing
									"rolmn1", 11,		//° Low–energy logic: roll command lower limit
									"rolmn2", 70,		//° Low–energy logic: roll command upper limit
									"dlzlm1", 17,		//° Low–energy logic: DELAZ limit for DZFCTR incrementing
									"dlzlm2", 17,		//° Low–energy logic: DELAZ limit for DZFCTR decrementing
									"alprddot", 0.04,		// Low–energy logic: alpha ramp rddot gain
									"alpdragdot", 0.35,		// Low–energy logic: alpha ramp dragdot gain	- needs testing
									"alprat", 0.5,		//°/s Low–energy logic: alpha convergence rate
									"alphmx", 31,		//° Low–energy logic: contingency abort alpha command – maximum L/D
									"valpmx", 9000,		//ft/s Low–energy logic: velocity to begin contingency abort alpha command ramp

									"dummy", 0
).


//internal variables
//I made some variables local and removed them from this global lexicon
global entryg_internal is lexicon(
									"aclam", 0, 	//upper pitch limit
									"aclim", 0,  	//lower pitch limit
									"acmd1", 0,   	//scheduled aoa
									"aldref", 0,   	//vertical l/d ref
									"alpcmd", 0,   	//aoa cmd (deg)
									"rolcmd", 0,   	//roll cmd 	(deg)
									"spdbcmd", 0,	//my addition: speedbrake cmd
									"alpdot", 0,   	//aoa dot 
									"a", list(0,0,0),   	//temp variable in computign range 
									"cag", 0,   	//pseudoenergy / mass used in transition 
									"cdcal", 0, 		//calculated cd 
									"cq1", list(0,0,0),   	//degree 0 for temp control quadratic 
									"cq2", list(0,0,0),   	//degree 1 for temp control quadratic 
									"cq3", list(0,0,0),   	//degree 2 for temp control quadratic 
									"c16", 0,   		//d(l/d) / dD
									"c17", 0,   		//d(l/d) / dH
									"c2", 0,   	//component of ref l/d 
									"d23", 0,		//drag velocity profile is anchored at d23 at velocity vb1 - the phase 2/3 boundary
									"d231", 0,		//initial value in the expansion of d23
									"d23l", 0,		//lower limit on d23
									"ddp", 0,   		//ddp prev 
									"delalp", 0,   	//commanded alpha incr,   
									"dlrdot", 0,   	//r feedback 
									"dlzrl", 0,		//deg negative if we're rolling towards the site, positive if heading aways
									"dragdot", 0,	//(ft/s2)/s 	derivative of drag
									"dragp", 0,		//ft/s2 drag previous
									"drdd", 0,   	//dRange / dD 
									"drefp", 0,   	//drag ref used in controller 
									"drefp1", 0,   	//eq glide
									"drefp3", 0,   	//tets value for transition to 3 
									"drefp4", 0,   	//test value for transiton to phase 4 
									"drefp5", 0,   	//test value for transition to phase 5 
									"dx", list(0,0,0),   	//drefp norm 		//candidate for local var
									"dzold", 0,   	//delaz prev 
									"eef", 0,   		//energy over mass 
									"eg_end", FALSE,		//toggles transition to taem and we stop calling this function
									"eowd", 0, 			//energy over weight (ft)
									"hs", 0,   		//scale height
									"ialp", 0,   	//alpcmd segment counter 
									"ict", FALSE,   		//alpha mod flag 
									"idbchg", FALSE, 		// flag to signal first roll reversal performed
									"islect", 0,   	//phase counter 
									"itran", FALSE,   	//transition init flag
									"lmflg", FALSE,   	//saturated roll cmd flag 
									"lmn", 0,   		//max lodv value 
									"lodv", 0,   	//vertical l/d 
									"lodx", 0,   	//unlimited vert l/d cmd 
									"n_quad_seg", 0,		//which phase 2 quadratic segment we are in
									"q", list(0,0,0,0),   	//drefp/ve in temp control 
									"rcg", 0,   		//range const drag 
									"rcg1", 0,   	//constant comp of rcg 
									"rddot", 0,		//ft/s2 altitude acceleration, my addition
									"rdotp", 0,		//ft/s previous rdot
									"rdealf", 0,   	//alpha mod roll bias 
									"rdtref", 0,   	//rdot ref 
									"rdtrf1", 0,   	//rdot ref in phase 3 
									"rdtrft", 0, 	//rdot ref but different?
									"r23", 0,		//actual range to fly in phases 2 and 3
									"r231", 0,		//predicted range to fly in phases 2 and 3 times d23
									"req1", 0,   	//eq glide range x d23
									"rer1", 0,   	//trans phase range 
									"rf", list(0,0,0),   	//tmp control segments ranges x d23
									"rff1", 0,   	//tmp control predicted range 
									"rdtrf", 0,   	//rdot ref corrected for cd 
									"rk2rol", 0,   	//bank angle direction 
									"rk2rlp", 0,   	//prev val 
									"rlm", 0,		//roll limit
									"rlmndz", 0, 	//min roll based on delaz
									"rollc", list(0,0,0,0),	//1: roll angle command,  2: unlimited roll command,  3: roll ref //deg
									"rolref", 0,	//deg 	//roll ref
									"rpt", 0,   	//desired range at vq 
									"rrflag", FALSE,		//roll reversal flag
									"start", 0,   	//guidance initialised flag  
									"fpflag", FALSE,		//my addition - separate flag for first pass
									"t2", 0,   		//constant drag level to target 	
									"t2dot", 0,   	//rate of t2 change -à
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
									"zk", 0,   	//rdot feedback gain 
									
									//my addition: transition flags 
									"tran2f_nom", FALSE,
									"tran3f_nom", FALSE,
									"tran4f_nom", FALSE,
									"tran5f_nom", FALSE,
									"tran5f_vtran", FALSE,
									"tran3f_vb1", FALSE,
									"tran3f_drefp4", FALSE,
									"tran4f_alfm", FALSE,
									"tran4f_drefp4", FALSE,
									
									"tgtsite0", 0,		//my addition, keep track of the tgt site to reset guidance
									"n_iter", -1, 		//do not initialise to zero
									
									
									// low energy logic
									"ileflg", false,		//low-energy enable flag
									"icntal", false,		//Low–energy logic engagement discrete
									"ileint", false,		//Low–energy logic first pass flag
									"trngle", 0,		//Low–energy logic: biased range to the runway threshold
									"alpca1", 0,		//Low–energy logic: filtered alpha command limit to protect thermal
									"alpca2", 0,		//Low–energy logic: unfiltered alpha command
									"ialcnv", FALSE,		//Low–energy logic: alpha profile convergence flag
									"dzfctr", 0,		//Low–energy logic: variable DELAZ factor for roll command computation
									"vi_init", 0,			//ft/s Low-energy logic: initial value of inertial velocity
									"alp_wle", 0,			//° Low-energy logic:  angle-of-attack command limit to protect wing leading edge thermal
									"irdot", 0,			//Low–energy logic: pullout completion indicator
									"beqglm", 0,		//ft/s2 Low–energy logic: biased equilibrium glide boundary
									"rollmn", 0,		//° Low–energy logic: roll command
									
									
									
									"dummy", 0
).

function entryg_dump {
	parameter entryg_input.
	parameter overwrite.
	
	local entryg_dumplex is lexicon().
	
	for k in entryg_input:keys {
		entryg_dumplex:add(k, entryg_input[k]). 
	}
	
	for k in entryg_internal:keys {
		LOCAL val IS entryg_internal[k].
		
		IF val:ISTYPE("List") {
			LOCAL c_ IS 0.
			for v_ in val {
				LOCAL v_k IS k + "_" + c_.
				entryg_dumplex:add(v_k, v_). 
				set c_ to c_ + 1.
			}
		} ELSE {
			entryg_dumplex:add(k, val). 
		}
	}
	
	log_data(entryg_dumplex,"0:/Shuttle_OPS3/LOGS/entry_dump", overwrite).
}


//egflg = 0,1 is normal mode, egflg=2 is canned mode for targeting (islect will never be > 2)
//phases (islect) : 
// 1 = preentry, 2 = temp control , 3 = eq glide , 4 = const drag , 5 = transition

function egexec {
	PARAMETER entryg_input.

	egscaleht(entryg_input).

	//this also needs to be called whenever site is changed
	if (entryg_internal["start"] = 0) or (entryg_input["tgtsite"] <> entryg_internal["tgtsite0"]) {
		set entryg_input["dtegd"] to entryg_constants["dtegd"].
		eginit(entryg_input).
	}
	
	//low energy guidance stuff 	
	//stuff that needs to be re-initialised at every re-engagement of low-energy logic
	if (NOT entryg_internal["ileflg"]) {
		set entryg_internal["icntal"] to false.
		set entryg_internal["ileint"] to false.
	} else if (not entryg_internal["ileint"]) {
		set entryg_internal["icntal"] to true.
		set entryg_internal["alpca1"] to entryg_input["alpha"].
		set entryg_internal["ialcnv"] to FALSE.
		set entryg_internal["dzfctr"] to entryg_constants["rlmndzfac"].
		
		set entryg_internal["ileint"] to true.
	}
	
	//keep for legacy but biasing is disabled
	if (entryg_internal["icntal"]) {
		local rtbias is 0.
		local dzabs is abs(entryg_input["delaz"]).
		if (dzabs > entryg_constants["dzbias"]) and (dzabs < 90) {
			set rtbias to entryg_input["trange"] * sin(dzabs)*tan(dzabs).
		} 
		set entryg_internal["trngle"] to entryg_input["trange"] + entryg_constants["rtbfac"] * rtbias.
	}
	
	egcomn(entryg_input).
	
	//aoa command
	egalpcmd(entryg_input).
	
	//refactored transition checks from level-c doc
	
	// preentry nominal termination, when load fac exceeds astart
	if (entryg_internal["islect"] = 1) and (entryg_input["xlfac"] > entryg_constants["astart"]) {
		set entryg_internal["islect"] to 2.
		set entryg_internal["tran2f_nom"] to TRUE.
	}
	
	//used to transition from 1 to 5 if we resume entryg when ve less than v transition
	//also do this regardless of phase if low-energy
	if (entryg_internal["islect"] = 1 or entryg_internal["icntal"]) and (entryg_input["ve"] < entryg_constants["vtran"]) {
		set entryg_internal["islect"] to 5.
		set entryg_internal["tran5f_vtran"] to TRUE.
	}
	
	//alternate termination of temp control 
	//if bank angle has not been matched by velocity vb1, force switch 
	if (entryg_internal["islect"] = 2) and (entryg_input["ve"] < entryg_constants["vb1"]) {
		SET entryg_internal["islect"] To 3.
		set entryg_internal["tran3f_vb1"] to TRUE.
	}
	
	//for reentry simulation using a canned drag profile ??
	//if (entryg_input["egflg"] > 0) and (entryg_internal["islect"] > 2) {
	//	set entryg_internal["islect"] to 2.
	//}
	
	if (entryg_internal["islect"] = 1) {
		//compute vertical l/d during preentry 
		egpep(entryg_input).
	} else if (entryg_internal["islect"] = 2) OR (entryg_internal["islect"] = 3) {
		//reference parameters during temperature control and eq glide 
		egrp(entryg_input).
		egref(entryg_input).
		
		//transition checks
		
		//alternate termination if required constant drag to target exceeds the max desired const.drag
		// for extremely short range and both cases 
		if ( entryg_internal["t2"] > entryg_constants["alfm"]) {
			set entryg_internal["islect"] to 4.
			set entryg_internal["tran4f_alfm"] to TRUE.
		}
		
		//nominal temp control termination 
		//switch occurs when temp.control and eqgl drag profiles match
		//but there is more logic to only switch when the bank command is the same to avoid discontinuities
		//controlled by variable gs2 inside drefp3
		if (entryg_internal["islect"] = 2) and (entryg_input["ve"] < entryg_constants["va"]) and (entryg_internal["drefp"] < entryg_internal["drefp3"]) {
			//disabled, use alternate
			//set entryg_internal["islect"] to 3.
			set entryg_internal["tran3f_nom"] to TRUE.
		}
		
		//short range temp control termination 
		//if required const drag is reached during temp control, skip phase 3 
		//bank smoothing is controlled by variable gs3 inside drefp4
		if (entryg_internal["islect"] = 2) and (entryg_input["ve"] < (entryg_internal["vcg"] + entryg_constants["delv"])) and (entryg_internal["drefp"] > entryg_internal["drefp4"]) {
			set entryg_internal["islect"] to 4.
			set entryg_internal["tran4f_drefp4"] to TRUE.
		} 
		
		//this now becomes the nominal phase 3 termination
		//bank smoothing is controlled by variable gs3 inside drefp4
		if (entryg_internal["islect"] = 3) and (entryg_input["ve"] < (entryg_internal["vcg"] + entryg_constants["delv"])) and (entryg_internal["drefp"] > entryg_internal["drefp4"]) {
			set entryg_internal["islect"] to 4.
			set entryg_internal["tran4f_nom"] to TRUE.
		}
		
		//very long range termination of phase 3 
		//if the phase 3/4 velocity is less than the phase 4/5 vtran, skip phase 4
		//bank smoothing is controlled by variable gs4 inside drefp5
		if (entryg_internal["islect"] = 3) and (entryg_input["ve"] < (entryg_internal["vcg"] + entryg_constants["delv"])) and (entryg_internal["drefp"] > entryg_internal["drefp5"]) and (entryg_internal["vcg"] < entryg_constants["vtran"]) {
			set entryg_internal["islect"] to 5.
			set entryg_internal["tran5f_vtran"] to TRUE.
			
		}
		
	} else if (entryg_internal["islect"] = 4) {
		//reference parameters during const drag
		egref4(entryg_input).
		
		//termination of phase 4 at a predetermined time before energy etran is reached 
		if (entryg_input["ve"] < (entryg_constants["vtran"] + entryg_constants["delv"])) and (entryg_internal["drefp"] > entryg_internal["drefp5"]) {
			set entryg_internal["islect"] to 5.
			set entryg_internal["tran5f_nom"] to TRUE.
		}
		
	} else if (entryg_internal["islect"] = 5) {
		//reference parameters during transition
		egtran(entryg_input).
	} 

	//vertical l/d after preentry	//can I move these before egalpcmd ?? probably not  - yeah definitely can't
	if (entryg_internal["islect"] > 1) {
		eggnslct(entryg_input).
		eglodvcmd(entryg_input).
	}
	
	//roll command 
	egrolcmd(entryg_input).
	
	//my addition : speedbrake command
	egsbcmd(entryg_input).
	
	//entry guidance termination 
	//check this regardless of the value of islect
	//addition: early exit if very high energy
	if (entryg_input["ve"] < entryg_constants["v_taem"])
		OR (entryg_input["trange"] <= entryg_constants["r_taem"]) 
		or (
			(entryg_input["trange"] <= entryg_constants["r_taem_high"])
			and (entryg_input["ve"] >= entryg_constants["v_taem_high"])
	) {		
		set entryg_internal["eg_end"] to TRUE.
	}
}

FUNCTION entryg_reset {
	SET entryg_internal["start"] TO 0.
}

//scale height for hdot reference term
function egscaleht {
	PARAMETER entryg_input.

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
	PARAMETER entryg_input.
	
	set entryg_internal["tgtsite0"] to entryg_input["tgtsite"].
	
	//might want to do a ve test if we resume entry halfway
	set entryg_internal["islect"] to 1.

	set entryg_internal["itran"] to FALSE.
	set entryg_internal["ict"] to FALSE.
	set entryg_internal["idbchg"] to FALSE.
	set entryg_internal["t2"] to 0.
	set entryg_internal["vq2"] to entryg_constants["vq"]^2.
	set entryg_internal["rk2rol"] to sign(entryg_input["delaz"]).
	set entryg_internal["dlrdot"] to 0.
	set entryg_internal["lmflg"] to FALSE.
	set entryg_internal["vtrb"] to entryg_constants["vtrb0"].
	set entryg_internal["ddp"] to 0.
	set entryg_internal["rk2rlp"] to entryg_internal["rk2rol"]. 
	
	set entryg_internal["rrflag"] to FALSE. 
	
	set entryg_internal["rdotp"] to entryg_input["rdot"].
	set entryg_internal["dragp"] to entryg_input["drag"].
	
	//in case of a tal abort 
	//refactored before the calculations that use alfm
	IF (entryg_input["ital"]) {
		set entryg_constants["alfm"] to entryg_constants["tal_alfm"].
		
		set entryg_constants["valp"] to entryg_constants["tal_valp"].
		set entryg_constants["calp0"] to entryg_constants["tal_calp0"].
		set entryg_constants["calp1"] to entryg_constants["tal_calp1"].
		set entryg_constants["calp2"] to entryg_constants["tal_calp2"].
		
		set entryg_constants["vnoalp"] to entryg_constants["tal_vnoalp"].
	}
	
	//low-energy init 
	if (entryg_internal["ileflg"]) {
		//removed vturn logic
		set entryg_internal["vi_init"] to entryg_input["vi"].
		
		//removed alphpo_hi logic
		
		set entryg_internal["ileint"] to false.
	}
	
	//initialise pullout indicator
	if (entryg_input["rdot"] > 0) {
		set entryg_internal["irdot"] to 0.
	} else {
		set entryg_internal["irdot"] to 1.
	}
	
	//nominal transition range at vtran (nmi)
	//this is kept fixed for range calculations of phase 2,3,4
	//changed the sign of rpt and tmp1 from the papers
	local tmp1 is -((entryg_constants["etran"] - entryg_constants["eef4"])* LN(entryg_constants["df"] / entryg_constants["alfm"])) / (entryg_constants["alfm"] - entryg_constants["df"]).
	local tmp2 is (entryg_constants["vtran"]^2 - entryg_internal["vq2"]) / (2*entryg_constants["alfm"]).
	set entryg_internal["rpt"] to (tmp1 + tmp2) * entryg_constants["cnmfs"] + entryg_constants["rpt1"].
	
	set entryg_internal["vsat2"] to entryg_constants["vsat"]^2.
	set entryg_internal["vsit2"] to entryg_constants["vs1"]^2.
	
	set entryg_internal["vcg"] to entryg_constants["vq"].
	set entryg_internal["d23"] to entryg_constants["d230"].
	set entryg_internal["dx"][1] to 1.
	
	set entryg_internal["vo"][1] to entryg_constants["vb1"].
	set entryg_internal["vx"][1] to entryg_constants["va"].
	set entryg_internal["vf"][1] to entryg_constants["va1"].
	set entryg_internal["a"][1] to entryg_constants["ak"].
	
	set entryg_internal["vo"][2] to entryg_constants["va1"].
	set entryg_internal["vx"][2] to entryg_constants["va2"].
	set entryg_internal["a"][2] to entryg_constants["ak1"].
	
	set entryg_internal["vb2"] to entryg_constants["vb1"]^2.
	
	//component of constant drag phase 
	set entryg_internal["rcg1"] to entryg_constants["cnmfs"] * (entryg_internal["vsit2"]  - entryg_internal["vq2"]) / (2*entryg_constants["alfm"]).
	set entryg_internal["ialp"] to entryg_constants["nalp"].
	
	//my addition: do stuff if we resume entry halfway and in transition phase
	if (entryg_input["ve"] <= entryg_constants["vtran"]) {
		//use the upper delaz limits
		set entryg_internal["idbchg"] to TRUE.
		//other stuff??
	}
	
	set entryg_internal["start"] to 1.
	set entryg_internal["fpflag"] to TRUE.
	set entryg_internal["n_iter"] to entryg_constants["n_iter"].
}

function egcomn {
	PARAMETER entryg_input.
	
	//my addition, keep track of iterations 
	if (entryg_internal["n_iter"] > 0) {
		set entryg_internal["n_iter"] to entryg_internal["n_iter"] - 1.
	}
	
	//my addition - measure rddot and drag dot 
	set entryg_internal["rddot"] to (entryg_input["rdot"] - entryg_internal["rdotp"]) / entryg_input["dtegd"].
	set entryg_internal["rdotp"] to entryg_input["rdot"].
	set entryg_internal["dragdot"] to (entryg_input["drag"] - entryg_internal["dragp"]) / entryg_input["dtegd"].
	set entryg_internal["dragp"] to entryg_input["drag"].
	

	set entryg_internal["xlod"] to max(entryg_input["lod"], entryg_constants["lodmin"]).
	
	//moved t1 to eglodvcmd
	
	set entryg_internal["ve2"] to entryg_input["ve"]^2.
	
	set entryg_internal["eef"] to entryg_constants["gs"] * entryg_input["hls"] + entryg_internal["ve2"] / 2.
	
	set entryg_internal["eowd"] to entryg_internal["eef"] / entryg_constants["gs"].
	
	set entryg_internal["cag"] to 2* entryg_constants["gs"]*entryg_internal["hs"] + entryg_internal["ve2"].
	
	if (entryg_internal["islect"] < 5) {
		
		local t2old is entryg_internal["t2"].
		
		//calculate constant drag level to reach phase 5 at range rtp
		//my modification: only update t2 before phase 4 so it's constant
		if (entryg_internal["islect"] < 4) {
			set entryg_internal["t2"] to entryg_constants["cnmfs"] * (entryg_internal["ve2"] - entryg_internal["vq2"]) / (2*( entryg_input["trange"] - entryg_internal["rpt"])).
			//my addition- limit t2, effectively disables early transition to phase 4
			set entryg_internal["t2"] to min(entryg_internal["t2"], entryg_constants["alfm"]).
		}
		
		set entryg_internal["t2dot"] to (entryg_internal["t2"] - t2old) / entryg_input["dtegd"].
		
		//stuff for transition to phase 5
		if (entryg_input["ve"] < (entryg_constants["vtran"] + entryg_constants["delv"])) {
			local c1 is (entryg_internal["t2"] - entryg_constants["df"]) / ( entryg_constants["etran"] - entryg_constants["eef4"]).
			set entryg_internal["rdtrft"] to - (c1 * (entryg_constants["gs"]  * entryg_input["hls"] - entryg_constants["eef4"]) + entryg_constants["df"]) * 2 * entryg_input["ve"] * entryg_internal["hs"] / entryg_internal["cag"].
			
			set entryg_internal["drefp5"] to entryg_constants["df"] + (entryg_internal["eef"] - entryg_constants["eef4"]) * c1 + entryg_constants["gs4"] * (entryg_internal["rdtref"] - entryg_internal["rdtrft"]).
		}
	
	}
}

//vertical l/d during preentry
function egpep {
	PARAMETER entryg_input.
	
	set entryg_internal["lodx"] to entryg_internal["xlod"] * COS( entryg_input["mm304ph"] ).
	set entryg_internal["lodv"] to entryg_internal["lodx"].
	//added this one 
	set entryg_internal["aldref"] to entryg_internal["lodx"].
}

//range prediction for phase 2 and 3 	//d23
function egrp {
	PARAMETER entryg_input.

	local k is 1.
	set entryg_internal["n_quad_seg"] to 1.
	
	//2 temp control drag-vel quadratics 
	//#2 is from vf (=ve) to va1, #1 is from va1 to vb1, the phase 3 transition vel
	
	//in the paper it is > va1, this way we use the second quadratic for the entire temp control phase?
	//no bc quadratic #2 is at higher velocities than quadratic #1
	if (entryg_input["ve"] > entryg_constants["va1"]) {
		set k to 2.
		set entryg_internal["n_quad_seg"] to 2.
	} else {
		set entryg_internal["rf"][2] to 0.
	}
	
	set entryg_internal["vf"][entryg_internal["n_quad_seg"]] to entryg_input["ve"].
	
	//the quadratics are D = c + c' * ve + c'' * ve2
	//the coefs are calculated pretending d23 = 1 bc it simplifies the calculation for d23
	// cq1 = c / d23		cq2 = c' / d23		cq3 = c'' / d23
	
	if (entryg_internal["start"] = 1) {
		//bc these should be initialised just once when we first call egrp
		set entryg_internal["start"] to 2.
		set k to 1.
		
		FROM {local i is 1.} UNTIL i > 2 STEP {set i to i + 1.} DO { 
			if (i = 2) {
				//this is an auxiliary variable corresponding to d24 / d23, still pretending d23 = 1
				set entryg_internal["dx"][2] to entryg_internal["cq1"][1] + entryg_constants["va1"] * (entryg_internal["cq2"][1] + entryg_internal["cq3"][1] * entryg_constants["va1"]).
			}
			
			// DISCREPANCY IN THE DOCS !! - CQ3[I] HAS A MINUS SIGN OR NOT????
			set entryg_internal["cq3"][i] to -entryg_internal["a"][i]*entryg_internal["dx"][i] / (2*(entryg_internal["vx"][i] - entryg_internal["vo"][i])*entryg_internal["vo"][i]).
			set entryg_internal["cq2"][i] to -2*entryg_internal["vx"][i]*entryg_internal["cq3"][i].
			set entryg_internal["cq1"][i] to entryg_internal["dx"][i] - entryg_internal["vo"][i]*(entryg_internal["cq2"][i] + entryg_internal["cq3"][i]*entryg_internal["vo"][i]).
		
		}
	}
	
	//algoritm for the range integral of the quadratics
	FROM {local i is k.} UNTIL i > entryg_internal["n_quad_seg"] STEP {set i to i + 1.} DO { 
	
		if (entryg_input["ve"] < entryg_internal["vo"][i]) {
			set entryg_internal["rf"][i] to 0.
		} else {
			
			local v_temp is list(0,0,0,0).	//velocity points for temp control 
		
			set v_temp[1] to (8*entryg_internal["vo"][i] + entryg_internal["vf"][i]) / 9.
			set v_temp[2] to (entryg_internal["vo"][i] + entryg_internal["vf"][i]) / 2.
			set v_temp[3] to entryg_internal["vo"][i] + entryg_internal["vf"][i] - v_temp[1].
			
			FROM {local j is 1.} UNTIL j > 3 STEP {set j to j + 1.} DO {  
				set entryg_internal["q"][j] to (entryg_internal["cq1"][i]/v_temp[j]) + entryg_internal["cq2"][i] + entryg_internal["cq3"][i]*v_temp[j].
			}
			
			set entryg_internal["rf"][i] to (27/entryg_internal["q"][1] + 44/entryg_internal["q"][2] + 27/entryg_internal["q"][3])*(entryg_internal["vf"][i] - entryg_internal["vo"][i])/98.
			
		}
	}
	
	//from the level-c document : set temp control phase range to zero if ve < vb1
	if (entryg_input["ve"] < entryg_constants["vb1"]) {
		set entryg_internal["rff1"] to 0.
	} else {
		//temp control range in nautical miles, valid for both quadratic segments bc we can set rf[2] to zero
		set entryg_internal["rff1"] to entryg_constants["cnmfs"] * (entryg_internal["rf"][1] + entryg_internal["rf"][2]).
	}
	
	
	//calculate drag d23 at vb1 
	if (entryg_internal["t2dot"] > entryg_constants["dt2min"]) or (entryg_input["ve"] > (entryg_internal["vcg"] + entryg_constants["delv"])) {
	
		if (entryg_input["ve"] < entryg_constants["vb1"]) {
			set entryg_internal["vb2"] to entryg_internal["ve2"].
		}
		
		set entryg_internal["vcg"] to entryg_constants["vq"].
		set entryg_internal["d23l"] to entryg_constants["alfm"]*(entryg_internal["vsit2"] - entryg_internal["vb2"]) / (entryg_internal["vsit2"] - entryg_internal["vq2"]).
		
		if (entryg_internal["d23"] > entryg_internal["d23l"]) {
			set entryg_internal["vcg"] to SQRT(entryg_internal["vsit2"] - entryg_internal["d23l"]*(entryg_internal["vsit2"] - entryg_internal["vq2"]) / entryg_internal["d23"]).
		} else {
			set entryg_internal["d23"] to entryg_internal["d23l"].
		}
		
		//aux var
		set entryg_internal["a"][2] to entryg_constants["cnmfs"]*(entryg_internal["vsit2"] - entryg_internal["vb2"])/2.
		
		//range during eqgl, more precisely it's d23 * req
		set entryg_internal["req1"] to entryg_internal["a"][2]*LN(entryg_constants["alfm"] / entryg_internal["d23"]).
		//range during constdrag
		set entryg_internal["rcg"] to entryg_internal["rcg1"] - entryg_internal["a"][2] / entryg_internal["d23"].
		
		// phases 2-3 predicted tange * d23
		set entryg_internal["r231"] to entryg_internal["rff1"] + entryg_internal["req1"].
		//the actual range we must fly during phases 2 and 3
		//added phase-dependent bias 
		set entryg_internal["r23"] to  entryg_input["trange"] - entryg_internal["rcg"] - entryg_internal["rpt"].
		
		//first updated value of d23
		set entryg_internal["d231"] to entryg_internal["r231"] / entryg_internal["r23"].
		set entryg_internal["drdd"] to - entryg_internal["r23"] / entryg_internal["d231"].
		
		//second order expansion dor d23, e
		if (entryg_internal["d231"] >= entryg_internal["d23l"]) {
			set entryg_internal["d23"] to entryg_internal["d231"] + entryg_internal["a"][2]*((1 - entryg_internal["d23"] / entryg_internal["d231"])^2) / (2*entryg_internal["r23"]).
		} else {
			set entryg_internal["d23"] to max(entryg_internal["d231"], entryg_constants["e1"]).
		}
		
		if (entryg_input["egflg"] > 1) {
			set entryg_internal["d23"] to entryg_constants["d23c"].
		}
	}


}

//reference params for temp control and eq glide 
function egref {
	PARAMETER entryg_input.

	//temp control 
	if (entryg_input["ve"] > entryg_constants["vb1"]) {
	
		local dref is list(0,0,0).	//drefp for temperature quadratic
		local hdtrf is list(0,0,0).   	//rdot ref intermediate var
		
		FROM {local i is 1.} UNTIL i > entryg_internal["n_quad_seg"] STEP {set i to i + 1.} DO { 
			//this is the drag quadratic for temp control, remember the coefs are divided by r23
			set dref[i] to entryg_internal["cq1"][i] + entryg_input["ve"] * (entryg_internal["cq2"][i] + entryg_internal["cq3"][i] * entryg_input["ve"]).
			set hdtrf[i] to -entryg_internal["hs"] * (2* dref[i] / entryg_input["ve"] - entryg_internal["cq2"][i] - 2*entryg_internal["cq3"][i]*entryg_input["ve"]).
		}
		
		//bank angle smothing between quadratics, but it doesn't work all that well, disable it 
		//if (entryg_input["ve"] > entryg_constants["va1"]) {
		//	local drf is dref[2] -  dref[1].
		//	set drf to drf*(drf + (hdtrf[1] - hdtrf[2])*entryg_constants["gs1"]).
		//	
		//	if (drf < 0) {
		//		set entryg_internal["n_quad_seg"] to 1.
		//	}
		//}
		
		set entryg_internal["drefp"] to entryg_internal["d23"] * dref[entryg_internal["n_quad_seg"]].
		set entryg_internal["rdtref"] to entryg_internal["d23"] * hdtrf[entryg_internal["n_quad_seg"]].
		set entryg_internal["c2"] to entryg_internal["d23"] * entryg_internal["cq2"][entryg_internal["n_quad_seg"]].
	} else {
		//my modification: do this only below vb1
		//eq glide 
		local aldco is (1 - entryg_internal["vb2"] / entryg_internal["vsit2"] ) / entryg_internal["d23"].
		set entryg_internal["drefp1"] to (1 - entryg_internal["ve2"] / entryg_internal["vsit2"] ) / aldco.
		set entryg_internal["rdtrf1"] to -2*entryg_internal["hs"]/(entryg_input["ve"] * aldco).
		set entryg_internal["drefp3"] to entryg_internal["drefp1"] + entryg_constants["gs2"] * (entryg_internal["rdtref"] - entryg_internal["rdtrf1"]).
		
		//use phase 3 parameters and turn off roll smoothing, this happens at the nominal phase 2-3 transition
		if (entryg_internal["drefp3"] > entryg_internal["drefp"]) or (entryg_input["ve"] < entryg_constants["vb1"]) {
			set entryg_internal["drefp"] to entryg_internal["drefp1"].
			set entryg_internal["rdtref"] to entryg_internal["rdtrf1"].
			set entryg_internal["c2"] to 0.
		}
	}
	
	//my addition - drefp is never negative
	set entryg_internal["drefp"] to MAX(0, entryg_internal["drefp"]).
	
	//test value for drefp for transition to phase 4
	set entryg_internal["drefp4"] to entryg_constants["gs3"] * (entryg_internal["rdtref"] + 2*entryg_internal["hs"]*entryg_internal["t2"] / entryg_input["ve"]) + entryg_internal["t2"].
	
	set  entryg_internal["itran"] to TRUE.
}

//reference params during constant drag-vel
//some refactoring
function egref4 {
	PARAMETER entryg_input.
	
	set entryg_internal["drefp"] to entryg_internal["t2"].
	set entryg_internal["rdtref"] to -2*entryg_internal["hs"]*entryg_internal["drefp"]/entryg_input["ve"].
	//DISCREPANCY!! sign of drdd
	//phase 3 range to go
	set entryg_internal["drdd"] to -(entryg_input["trange"] -  entryg_internal["rpt"]) / entryg_internal["drefp"].
	set entryg_internal["c2"] to 0.
	
	//my addition - drefp is never negative
	set entryg_internal["drefp"] to MAX(0, entryg_internal["drefp"]).
	
	set entryg_internal["itran"] to TRUE.
}

//reference params during transition 
function egtran {
	PARAMETER entryg_input.

	
	if (entryg_internal["itran"] = FALSE) {
		SET entryg_internal["itran"] TO TRUE.
		set entryg_internal["drefp"] to entryg_constants["alfm"].
	}
	
	local drefpt is entryg_internal["drefp"] - entryg_constants["df"].
	
	if (abs(drefpt) < entryg_constants["e1"]) {
		set entryg_internal["drefp"] to entryg_constants["df"] + entryg_constants["e1"]*sign(drefpt).
	}
	
	//all the checks on drefp are needed bc there is a logarithm that might explode if we end up here directly from egexec
	
	if (entryg_internal["drefp"] < entryg_constants["e1"]) {
		set entryg_internal["drefp"] to entryg_constants["e1"].
	}
	
	set drefpt to entryg_internal["drefp"] - entryg_constants["df"].
	//slope of drag energy profile in phase 5
	local c1 is drefpt / (entryg_internal["eef"] - entryg_constants["eef4"]).
	
	//phase 5 range to go
	set entryg_internal["rer1"] to entryg_constants["cnmfs"] * ln(entryg_internal["drefp"] / entryg_constants["df"]) / c1.
	set entryg_internal["drdd"] to min(entryg_constants["cnmfs"] * 1/(c1 * entryg_internal["drefp"]) - entryg_internal["rer1"] / drefpt , entryg_constants["drddl"]).
	
	//update reference drag but ensure it doesn't exceed elevon higne moment limits through alim, I assume
	set entryg_internal["drefp"] to entryg_internal["drefp"] + (entryg_input["trange"] - entryg_internal["rer1"] - entryg_constants["rpt1"]) / entryg_internal["drdd"].
	local dlim is entryg_constants["alim"] * entryg_input["drag"] / entryg_input["xlfac"].
	if (entryg_internal["drefp"] > dlim) {
		set entryg_internal["drefp"] to dlim.
		set c1 to 0.
	}
	
	if (entryg_internal["drefp"] < entryg_constants["e1"]) {
		set entryg_internal["drefp"] to entryg_constants["e1"].
	}
	
	//my addition
	//in any case do not exceed the previous constant drag
	//no, very bad
	
	//my addition - drefp is never negative
	set entryg_internal["drefp"] to MAX(0, entryg_internal["drefp"]).
	
	set entryg_internal["rdtref"] to -entryg_internal["hs"]*entryg_input["ve"]*(2*entryg_internal["drefp"] - c1*entryg_internal["ve2"]) / entryg_internal["cag"].
	
	set entryg_internal["c2"] to 4*entryg_input["ve"]*entryg_internal["drefp"]*(1 - (entryg_internal["ve2"]/entryg_internal["cag"])^2) / entryg_internal["cag"].
}

//aoa command 
function egalpcmd {
	PARAMETER entryg_input.

	//simple check, guaranteed at most one decrement per pass
	if ((entryg_input["ve"] < entryg_constants["valp"][entryg_internal["ialp"]]) and (entryg_internal["ialp"] > 0)) {
		set entryg_internal["ialp"] to entryg_internal["ialp"] - 1.
	}
	
	set entryg_internal["alpcmd"] to entryg_constants["calp0"][entryg_internal["ialp"]] + entryg_input["ve"]*(entryg_constants["calp1"][entryg_internal["ialp"]] + entryg_input["ve"] * entryg_constants["calp2"][entryg_internal["ialp"]]).
	
	if (entryg_internal["islect"] = 1) {
		set entryg_internal["alpcmd"] to entryg_constants["calp0"][entryg_constants["nalp"]].
	}
	
	set entryg_internal["alpdot"] to (entryg_internal["alpcmd"] - entryg_internal["acmd1"]) / entryg_input["dtegd"].
	//save the "virgin" commanded alpha to apply alpha mod properly
	set entryg_internal["acmd1"] to entryg_internal["alpcmd"].

}

//controller gains 
function eggnslct {
	PARAMETER entryg_input.
	
	//calculate coefficients for the l/d controller that tracks the drag profile 
	//lodcmd = lodref + c16 * (drag - drefp) - c17(rdot - rdtref)
	
	set entryg_internal["c16"] to entryg_constants["ct16"][1]*entryg_input["drag"]^(entryg_constants["ct16"][2]).
	
	if (entryg_input["ve"] < entryg_constants["vc16"]) {
		set entryg_internal["c16"] to entryg_internal["c16"] + entryg_constants["ct16"][3]*(entryg_input["drag"] - entryg_internal["drefp"]).
	}
	
	set entryg_internal["c16"] to midval(entryg_internal["c16"], entryg_constants["ct16mn"], entryg_constants["ct16mx"]).
	
	if (entryg_internal["ict"]) {
		set entryg_constants["ct17mn"] to entryg_constants["ct17m2"].
	}
	
	set entryg_internal["c17"] to entryg_constants["ct17"][1]*entryg_input["drag"]^(entryg_constants["ct17"][2]).
	set entryg_internal["c17"] to midval(entryg_internal["c17"], entryg_constants["ct17mn"], entryg_constants["ct17mx"]).
	
	if (entryg_internal["ict"]) {
		set entryg_internal["c17"] to entryg_constants["c17mp"] * entryg_internal["c17"].
	}
}


//lateral logic and vertical l/d cmd
function eglodvcmd {
	PARAMETER entryg_input.
	
	//this is a numerical equation for Cd(alpha,mach) is it not?
	//comaprison bw the level-c and the entry paper 
	//cddot1: k5 , cddot2: k6, cddot4 : k1, cddot5 : k2, cddot6:k3, cddot3 : k4
	local a44 is constant:e^(-(entryg_input["ve"] - entryg_constants["cddot1"]) / entryg_constants["cddot2"]).
	local cdcal is entryg_constants["cddot4"] + entryg_internal["alpcmd"]*(entryg_constants["cddot5"] + entryg_constants["cddot6"]* entryg_internal["alpcmd"]) + entryg_constants["cddot3"] * a44.
	local cddotc is entryg_constants["cddot7"]*(entryg_input["drag"] + entryg_constants["gs"]*entryg_input["rdot"] / entryg_input["ve"])*a44 + entryg_internal["alpdot"]*(entryg_constants["cddot8"]*entryg_internal["alpcmd"] + entryg_constants["cddot9"]).
	
	
	if (entryg_input["cd"] <> 0) {
		set entryg_internal["cdcal"] to entryg_input["cd"].
	} else {
		set entryg_internal["cdcal"] to cdcal.
	}
	local c4 is entryg_internal["hs"]*cddotc/entryg_internal["cdcal"]. 
	
	//limit drag values based on max allowable drag alfmax
	//modification - do not limit input drag so that error terms are accurate
	local d1 is min(entryg_internal["drefp"], entryg_constants["alfmax"]).
	local d2 is entryg_input["drag"].
	local dd is d2 - d1.
	
	//test for alpha modulation
	if (entryg_input["ve"] < entryg_constants["vnoalp"]) {
		//re-working of alpha modularion logic
		//modification - no alpmod in low energy
		set entryg_internal["ict"] to (abs(dd) > entryg_constants["ddmin"]) and (not entryg_internal["icntal"]).
		
		if (entryg_internal["ict"]) {
			local c20 is midval(entryg_constants["c21"], entryg_constants["c22"] + entryg_constants["c23"]*entryg_input["ve"], entryg_constants["c24"]).
			
			if (entryg_input["ve"] < entryg_constants["vc20"]) {
				set c20 to max(entryg_constants["c25"] + entryg_constants["c26"]*entryg_input["ve"], entryg_constants["c27"]).
			}
			
			//delta alpha based on max drag allowable
			set entryg_internal["delalp"] to midval(entryg_internal["cdcal"]*(d1/d2 - 1)/c20, entryg_constants["dlaplm"], -entryg_constants["dlaplm"]).
			
		}
	}
	
	//changed to minus this
	//vertical lift accel for eq glide condition
	local t1 is entryg_constants["gs"] * (1 - entryg_input["vi"]^2 / entryg_internal["vsat2"]).
	
	if (entryg_internal["islect"] = 5) {
		//again, changed to minus this
		set t1 to entryg_constants["gs"] * (1 - entryg_internal["ve2"]/entryg_internal["vsat2"]).
	}
	
	//changed sign of t1 term since we changed its sign
	set entryg_internal["aldref"] to t1 / entryg_internal["drefp"] + (2*entryg_internal["rdtref"] + entryg_internal["c2"]*entryg_internal["hs"]) / entryg_input["ve"].
	//my modification: limit delta given by c4 if we resume entry halfway 
	set entryg_internal["rdtrf"] to entryg_internal["rdtref"] + midval(c4, entryg_internal["rdtref"], -entryg_internal["rdtref"]).
	
	//hdot feedback
	if (entryg_input["ve"] < entryg_constants["vrdt"]) {
		local dds is midval(dd, -entryg_constants["ddlim"], entryg_constants["ddlim"]).
		set entryg_internal["zk"] to entryg_constants["zk1"].
		
		if (entryg_internal["rk2rlp"] * entryg_internal["rk2rol"] < 0) {
			set entryg_internal["vtrb"] to entryg_input["ve"] - entryg_constants["acn1"] * entryg_internal["drefp"].
		}
		
		if (abs(dd) <= abs(entryg_internal["ddp"])) or (entryg_input["ve"] > entryg_internal["vtrb"]) or (entryg_internal["lmflg"]) {
			set entryg_internal["zk"] to 0.
		}
		
		//clamped from the entry handbook
		//this should be resettable in theory
		set entryg_internal["dlrdot"] to midval(entryg_internal["dlrdot"] + entryg_internal["zk"] * dds, -entryg_constants["dlrdotl"], entryg_constants["dlrdotl"]).
		
	}
	
	//my addition: damping term with the derivative of drag error
	//if dd is positive we have more drag than we need and we need to increase lodv 
	//if dd is decreasing, dd_dot is negative 
	//if the dd_dot coef is pisitive this will dampen the rise in lodv
	local dd_dot is (dd - entryg_internal["ddp"])/entryg_input["dtegd"].
	
	set entryg_internal["ddp"] to dd.
	
	//delta drag correction corrected for max drag alfm 
	//the main vertical l/d equation
	//added derivative of dd damping term
	set entryg_internal["lodx"] to entryg_internal["aldref"] + entryg_internal["c16"]*(dd + entryg_constants["c16_kd"]*dd_dot) + entryg_internal["c17"]*(entryg_internal["rdtrf"] + entryg_internal["dlrdot"] - entryg_input["rdot"]).
	set entryg_internal["lodv"] to entryg_internal["lodx"].
	
	//this is where we calculate delaz limits
	//slight modification so that constant stay in fact constant 
	LOCAL delaz_upper is entryg_constants["y1"].
	if (entryg_internal["idbchg"]) {
		set delaz_upper to entryg_constants["y3"].
	}
	LOCAL delaz_lower IS entryg_constants["y2"].
	
	local yl is midval(entryg_constants["cy0"] + entryg_constants["cy1"]*entryg_input["ve"], delaz_upper, delaz_lower).
	
	set entryg_internal["lmn"] to entryg_constants["almn2"].
	
	local dzabs is abs(entryg_input["delaz"]).
	
	local dzsgn is dzabs - abs(entryg_internal["dzold"]).
	set entryg_internal["dzold"] to entryg_input["delaz"].
	
	//calculate l/d limits given whether delaz is increasing or decreasing
	if (dzsgn > 0) {
		if ((yl - entryg_constants["ylmin"]) < dzabs)  {
			set entryg_internal["lmn"] to entryg_constants["almn1"].
		}
	} else {
		if ((yl - entryg_constants["ylmn2"]) < dzabs) {
			set entryg_internal["lmn"] to entryg_constants["almn1"].
		}
	}
	
	//low-energy roll command
	//needs to be here because we override rk2rol
	if (entryg_internal["icntal"]) {
		//modification: removed vturn check and no roll before pullout
		if (entryg_internal["irdot"] < 2) 
			or ((dzsgn > 0) and (dzabs <= entryg_constants["dlzdb1"]))
			or ((dzsgn <= 0) and (dzabs <= entryg_constants["dlzdb2"])) {
			//zero roll if too fast or delaz too small
			set entryg_internal["rollmn"] to 0. 
		} else {
			set entryg_internal["rk2rol"] to sign(entryg_input["delaz"]).
			//removed beqglm test
			
			//increase the delaz roll factor if delaz increasing and not too small or large
			if (entryg_internal["dzfctr"]*dzabs < entryg_constants["rolmn2"])
				and (dzabs >= entryg_constants["dlzlm1"]) and (dzsgn > 0) {
				set entryg_internal["dzfctr"] to  entryg_internal["dzfctr"] * (1 + entryg_constants["dzfdel"] * entryg_input["dtegd"]).
			}
			
			//decrease the delaz roll factor if delaz decreasing 
			if (dzabs < entryg_constants["dlzlm2"]) and (dzsgn < 0) {
				set entryg_internal["dzfctr"] to  max(entryg_constants["rlmndzfac"], entryg_internal["dzfctr"] * (1 - entryg_constants["dzfdel"] * entryg_input["dtegd"])).
			}
			
			set entryg_internal["rollmn"] to midval(entryg_internal["dzfctr"] * dzabs , entryg_constants["rolmn1"], entryg_constants["rolmn2"]).
		}
	}
	
	//added a check?
	if (entryg_input["ve"] > entryg_constants["vylmax"]) {
		set entryg_internal["lmn"] to entryg_constants["almn4"].
	}
	
	if (entryg_input["ve"] < entryg_constants["velmn"]) {
		set entryg_internal["lmn"] to entryg_constants["almn3"].
	}
	
	set entryg_internal["lmn"] to entryg_internal["xlod"]*entryg_internal["lmn"].
	
	set entryg_internal["dlzrl"] to -entryg_input["delaz"]*entryg_internal["rk2rol"].
	
	//apply the l/d limtis and finally calculate if we do the roll reversal
	//dlzrl should first be negative as we reduce crossrange then positive
	if (abs(entryg_internal["lodv"]) >= entryg_internal["lmn"] and entryg_internal["dlzrl"] <= 0) {
		set entryg_internal["lmflg"] to TRUE.
		set entryg_internal["lodv"] to entryg_internal["lmn"]*sign(entryg_internal["lodv"]).
	} else {
		set entryg_internal["lmflg"] to FALSE.
		set entryg_internal["lmn"] to entryg_internal["xlod"].
		
		//should do the roll reversal
		//added condition on abs(delaz) plus flag to track reversal start and end
		//added rr flag check to avoid resetting the flag immediately 
		if (not entryg_internal["rrflag"]) and (entryg_internal["dlzrl"] > 0) and (dzabs >= yl) {
			//refactoring of roll reversal logic 
			//outside the limits always bank towards the site 
			// rr flag is enabled if rk2rol changes 
			set entryg_internal["rk2rol"] to sign(entryg_input["delaz"]).
			SET entryg_internal["rrflag"] TO (entryg_internal["rk2rlp"] * entryg_internal["rk2rol"] < 0).
			
		} else if (entryg_internal["rrflag"]) and (dzabs < yl) {
			SET entryg_internal["rrflag"] TO FALSE.
			//moved it there so delaz limits are changed after the roll is complete
			set entryg_internal["idbchg"] to TRUE.
		}
	}
	
	set entryg_internal["rk2rlp"] to entryg_internal["rk2rol"].
}

function egrolcmd {
	PARAMETER entryg_input.
	
	 //1", cos(bank cmd), 2", cos(unlimited bank), 3", cos(ref bank)
	local arg is list(0, entryg_internal["lodv"]/entryg_internal["xlod"], entryg_internal["lodx"]/entryg_internal["xlod"], entryg_internal["aldref"]/entryg_internal["xlod"] ).
	
	local rollcp1 IS entryg_internal["rollc"][1].
	
	FROM {local i is 1.} UNTIL i > 3 STEP {set i to i + 1.} DO { 
		//I think this limits the bank angle to +-90?
		if (abs(arg[i]) >= 1) {
			set arg[i] to sign(arg[i]*entryg_internal["xlod"]).
		}
		
		//CAREFUL : KOS will give the arccos in degrees but the HAL-S manual says that all angles are supplied or delivered in radians
		//we divide by deg2rad to transform it from rad to degrees so theoretically I should just remove the factor
		set entryg_internal["rollc"][i] to ARCCOS(arg[i]).	// / entryg_constants["dtr"].
	}
	
	// here we bias roll if we are deviating from the pitch profile 
	//and we apply the alpha modulation if needed 
	//disable roll bias
	if (entryg_internal["ict"]) {
		local delalf is (entryg_input["alpha"] - entryg_internal["acmd1"]).
		set entryg_internal["rdealf"] to midval(entryg_constants["crdeaf"]*delalf, entryg_constants["rdmax"], -entryg_constants["rdmax"]).
		
		//again skip conversion to degrees
		local almnxd is ARCCOS(entryg_internal["lmn"]/entryg_internal["xlod"]).	// / entryg_constants["dtr"].
		
		//modification
		//set entryg_internal["rollc"][1] to (abs(entryg_internal["rollc"][2]) + midval(entryg_internal["rdealf"], almnxd, -almnxd)) * entryg_internal["rk2rol"].
		
		//refactored pitch limits calculation
		//apply pitch modulation
		set entryg_internal["alpcmd"] to entryg_internal["acmd1"] + entryg_internal["delalp"].
	}
	
	//calculate absolute pitch limits 
	set entryg_internal["aclam"] to min(entryg_constants["dlallm"], entryg_constants["aclam1"] + entryg_constants["aclam2"]*entryg_input["ve"]).
	if (entryg_input["ve"] >= entryg_constants["vaclim"]) {
		set entryg_internal["aclim"] to midval(entryg_constants["aclim3"] + entryg_constants["aclim4"]*entryg_input["ve"], entryg_constants["aclim1"], entryg_constants["aclim2"]).
	} else {
		set entryg_internal["aclim"] to midval(entryg_constants["aclim6"] + entryg_constants["aclim7"]*entryg_input["ve"], entryg_constants["aclim2"], entryg_constants["aclim5"]).
	}
	
	//calculate absolute roll angle limits
	//refactored this block 
	//modification: check if tal and above tal_verolc
	IF (entryg_input["ital"]) and (entryg_input["ve"]  > entryg_constants["tal_verolc"]) { 
		set entryg_internal["rlm"] to entryg_constants["tal_rlmc0"].
	} else {
		set entryg_internal["rlm"] to entryg_constants["rlmc0"].
	} 
	
	if (entryg_input["ve"]  < entryg_constants["verolc"]) {
		if (entryg_input["ve"] > entryg_constants["vrlmc"]) {
			set entryg_internal["rlm"] to min(entryg_constants["rlmc1"], entryg_constants["rlmc2"] + entryg_constants["rlmc3"]*entryg_input["ve"]).	//entry 70°
		} else {
			set entryg_internal["rlm"] to max(entryg_constants["rlmc6"], entryg_constants["rlmc4"] + entryg_constants["rlmc5"]*entryg_input["ve"]).	//ramp down to 30° for taem
		}
	}
	
	//my addition: min roll logic 
	if (entryg_internal["dlzrl"] < 0) and (entryg_input["ve"] < entryg_constants["verlmndz"])  {
		set entryg_internal["rlmndz"] to MIN(entryg_constants["rlmndzfac"] * abs(entryg_input["delaz"]), entryg_constants["rlmdz"]).
	} else {
		set entryg_internal["rlmndz"] to 0.
	}
	
	//pullout tests 
	//refactoring
	if (entryg_internal["irdot"]< 2) {
		if (entryg_input["rdot"] < 0) {
			set entryg_internal["irdot"] to 0.
		}
		if (entryg_input["rdot"]>0) and ((entryg_input["rdot"] > entryg_constants["rdotpo"]) or (entryg_input["ve"] < entryg_constants["vnoalp"])) {
			set entryg_internal["irdot"] to 2.
		}		
	}
	
	//refactored calculation of eq glide boundary plus do it every time 
	local k is entryg_constants["veeqglm"]:length - 1.
	until (k = 0) {
		if (entryg_input["ve"] <= entryg_constants["veeqglm"][k]) {
			set entryg_internal["beqglm"] to max(entryg_constants["eqglm1"][k] + entryg_constants["eqglm2"][k]*entryg_input["ve"], 0).
			break.
		}
		set k to k - 1.
	}
	
	//my addition: use beqglm to engage low energy logic automatically on the next pass
	if (not entryg_internal["ileflg"]) and (entryg_internal["islect"] > 1) {
		if (entryg_internal["beqglm"] > 0) and (entryg_internal["drefp"] < (entryg_internal["beqglm"] - entryg_constants["beqglmbs"])) {
			set entryg_internal["ileflg"] to true.
		}
	}
	
	LOCAL rollc1 IS entryg_internal["rollc"][1].
	
	//low-energy stuff 
	if (entryg_internal["icntal"]) {
		//disengagement test if pullout is complete
		if (entryg_internal["irdot"] > 1) {
			//moved beqglm logic as well
			
			if (entryg_internal["drefp"] > (entryg_internal["beqglm"] + entryg_constants["beqglmbs"])) {
				set entryg_internal["icntal"] to false.
			}
		}
		
		//low energy roll cmd 
		set rollc1 to entryg_internal["rollmn"].
		
		//wle thermal alpha command - simple quadratic
		set entryg_internal["alp_wle"] to min(entryg_constants["alpwle_c1"] + entryg_input["ve"] * (entryg_constants["alpwle_c2"] + entryg_input["ve"] * entryg_constants["alpwle_c3"]), entryg_internal["aclam"]).
	
		if (entryg_internal["irdot"] < 2) {
			//alpha cmd for initial pullout
			
			set entryg_internal["alpcmd"] to entryg_internal["alp_wle"].
			
			//skip vi_alp_lo/hi checks
			
			set entryg_internal["alpca1"] to entryg_input["alpha"].
		} else {
			//alpha cmd for the subsequent phugoids
			
			//contingency alpha rampdown
			if (entryg_input["ve"] < entryg_constants["valpmx"]) {
				//this is alpha min from contingency abort
				//moved to aclim
				set entryg_internal["alpcmd"] to entryg_internal["aclim"].
			} else {
				//skip all the alp_vt calculations
				
				//refactored to implement the rddot based rampdown from the procedures
				//modifiction - use drag dot 
				set entryg_internal["alpca1"] to entryg_internal["alpca1"]  + entryg_internal["dragdot"] * entryg_constants["alpdragdot"] * entryg_input["dtegd"].
				set entryg_internal["alpca1"] to midval(entryg_internal["alpca1"], entryg_internal["aclim"] , entryg_internal["alp_wle"]).
					
				set entryg_internal["alpcmd"] to entryg_internal["alpca1"].
			}
		}
	} else {
		if (entryg_internal["ileflg"]) {
			//convergence to nominal alpha profile
			if (not entryg_internal["ialcnv"]) {
				local dalp_ is entryg_internal["alpcmd"] - entryg_input["alpha"].
				if (abs(dalp_) < entryg_constants["cnvtst"]) {
					set entryg_internal["ialcnv"] to true.
				} else {
					set entryg_internal["alpcmd"] to entryg_input["alpha"] + entryg_constants["alprat"] * entryg_input["dtegd"] * sign(dalp_).
				}
			} else {
				//if low energy disabled and alpha converged, signal low energy flag off 
				set entryg_internal["ileflg"] to false.
			}
			
			//skip drag convergence checks
		}
		
		//don't do these in low-energy logic 
		//my modification: limit the new roll command from above by the unlimited roll 
		set rollc1 to MIN(rollc1, ABS(entryg_internal["rollc"][2])).
		//my modification: limit the new roll command from below by the min delaz roll
		SET rollc1 TO MAX(rollc1, entryg_internal["rlmndz"]).
	}
	
	//apply pitch limits in any case
	set entryg_internal["alpcmd"] to midval(entryg_internal["alpcmd"], entryg_internal["aclam"], entryg_internal["aclim"]).
	
	//my addition: fiter changes in roll cmd if they are below a threshold enough
	LOCAL delrollc IS rollc1 - rollcp1.
	
	IF (ABS(delrollc) < entryg_constants["drolcmdfil"]) {
		SET rollc1 TO rollcp1 + delrollc * (entryg_input["dtegd"] / entryg_constants["rolcmdfildt"]).
	}
	
	set entryg_internal["rolcmd"] to midval(rollc1 * entryg_internal["rk2rol"], -entryg_internal["rlm"], entryg_internal["rlm"]).
}

//my addition : deflect speedbrake on a fixed mach schedule 
//logic adapted from taem grtls and implemented from the workbooks, modified to use ve instead of mach
//in reality it was part of the DAP??
function egsbcmd {
	PARAMETER entryg_input.
	
	if (entryg_internal["icntal"]) {
		return.
	}
	
	if (entryg_input["ve"]  >=  entryg_constants["vsbsw"]) {
		set entryg_internal["spdbcmd"] to midval(entryg_constants["vesbs1"] * entryg_input["ve"] + entryg_constants["vesbi1"], entryg_constants["egsbl1"], entryg_constants["egsbu1"]).
	} else {
		set entryg_internal["spdbcmd"] to midval(entryg_constants["vesbs2"] * entryg_input["ve"] + entryg_constants["vesbi2"], entryg_constants["egsbl2"], entryg_constants["egsbu2"]).
	}
}