@LAZYGLOBAL OFF.


//input variables 
//keep these here till i figure out how to structure the flow
alpha //aoa
delaz 	//az error 
drag 	//drag accel (ft/s2)
egflg 	//mode flag 
hls 		//alt above rwy (ft)
lod 		//current l/d 
rdot 	//alt rate (ft/s)
roll	//cur bank angle 
start 	//init flag 
trange 	//target range (nmi)
ve 		//earth rel velocity (ft/s)
vi		//inertial vel (ft/s)
xlfac 	//load factor acceleration (ft/s2)
mm304phi		//preentry bank 
mm304alp		//preentry aoa 
mep 			//hac selection flag 



//input constants

global entryg_constants is lexicon (
									"aclam1", 15.0,	//deg
									"aclam2", 0.0025,	//deg-sec/ft ??
									"aclim1", 37,	//deg
									"aclim2", 0,	//deg-sec/ft ??
									"aclim3", 7.6666667,	//deg
									"aclim4", 0.00223333,	//deg-sec/ft
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
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,
									"", ,

).


//internal variables
global alclam is 0.	//max allowable alpha
global aclim is 0.	//min allowable alpha 
global acmd1 is 0.	//scheduled aoa
global aldco is 0.	//temp variable during phase 3
global aldref is 0.	//vertical l/d ref
global alpcmd is 0.	//aoa cmd 
global alpdot is 0.	//aoa dot 
global arg is list(0,0,0,0).	//1 is cos(bank cmd), 2 is cos(unlimited bank), 3 is cos(ref bank)
global a2 is 0.	//temp variable in computign range 
global cag is 0.	//pseudoenergy / mass used in transition 
global cq1 is list(0,0,0).	//degree 0 for temp control quadratic 
global cq2 is list(0,0,0).	//degree 1 for temp control quadratic 
global cq3 is list(0,0,0).	//degree 2 for temp control quadratic 
global c1 is 0.	//dD/dE i ntransition
global c16 is 0.		//d(l/d) / dD
global c17 is 0.		//d(l/d) / dH
global c2 is 0.	//component of ref l/d 
global c4 is 0. 	//ref alt term 
global c20 id 0.		//gain for dAlpha/dCd 
global dd is 0.		//drag - drefp 
global dds is 0.		//limited dd value
global ddp is 0.		//ddp prev 
global delalf is 0.	//delta alpha from schedule 
global delalp is 0.	//commanded alpha incr.
global dlrot is 0.	//r feedback 
global dlim is 0.	//max drefp in transition 
global dlzrl is 0.	//test var in bank angle compuation
global drdd is 0.	//dRange / dD 
global dref is list(0,0,0)	//drefp for temperature quadratic
global drefp is 0.	//drag ref used in controller 
global drefpt is 0.	//drefp/dref in transition 
global drefp1 is 0.	//eq glide
global drefp3 is 0.	//tets value for transition to 3 
global drefp4 is 0.	//test value for transiton to phase 4 
global drefp5 is 0.	//test value for transition to phase 5 
global drf is 0.		//test value for transition to quadratic ref params 
global dx is list(0,0,0).	//drefp norm 
global dzold is 0.	//delaz prev 
global dzsgn is 0.	//change in delaz 
global d231 is 0.	//first updated value of d23 
global eef is 0.		//energy over mass 
global rdtrf is 0.	//rdot temp control
global ialp is 0.	//alpcmd segment counter 
global ict is 0.		//alpha mod flag 
global islecp is 0.	//past value if islect 
global islect is 0.	//phase counter 
global itran is 0.	//transition init flag 
global lmflg is 0.	//saturated roll cmd flag 
global lmn is 0.		//max lodv value 
global lodv os 0.	//vertical l/d 
global lodx is 0.	//unlimited vert l/d cmd 
global q is list(0,0,0,0).	//drefp/ve in temp control 
global rcg is 0.		//range const drag 
global rcg1 is 0.	//constant comp of rcg 
global rdealf is 0.	//alpha mod roll bias 
global rdtref is 0.	//rdot ref 
global rdtrf1 is 0.	//rdot ref in phase 3 
global req1 is 0.	//eq glide range x d23
global rer1 is 0.	//trans phase range 
global rf is list(0,0,0).	//tmp control segments ranges x d23
global rff1 is 0.	//tmp control range 
global rdtrf is 0.	//rdot ref corrected for cd 
global rollc is list(0,0,0,0)	//1 is roll angle command 2 is unlimited roll command 3 is roll ref 
global rpt is 0.	//desired range at vq 
global r231 is 0.	//range of phase 2+3 * d23
global start is 0.	//first pass flag  
global t1 is 0.		//eq glide vertical lift accel
global t2 is 0.		//constant drag level to target 
global t2dot is 0.	//rate of t2 change -à
global v_temp is list(0,0,0,0)	//velocity points for temp control 
global vb2 is 0.		//vb ^ 2
global vcg is 0.		//phase 3/4 boundary vel 
global ve2 is 0.		//ve ^ 2 
global vf is list(0,0,0). 	//upper vel bounds for temp control 
global vsat2 is 0.	//vsat ^ 2
global vtrb is 0.	//rdot feedback vel lockout 
global vx is list(0,0,0).	//velocities where dD / dV  = 0 in temp control quadratic 
global xlod is 0.	//limited l/d 
global yl is 0.	//max heading eror abs val 
global zk is 0.	//rdot feedback gain 







//flag for regular or canned reenty guidance 
//egflg = 0 is bank modulation guidance
//egflg = 2 is is for simulations and terminates at mach 23?
global egflg is 0.


function egexec {

	if start = 0 {
		eginit().
	}
	
	egccmn().
	
	// preentry termination, when load fac exceeds astart
	if (islect = 1) and (xlfac > astart) {
		set islect to 2.
		set dtegd to 1.92.
		
		// if less than v transition
		if (ve < vtran) {
			set islect to 5.
		}
	}
	
	//alternate termination if desired constant drag to target exceeds the ref. const.drag
	// for extremely short range
	if (islect = 2 or islect = 3) and ( t2 > alfm) {
		set islect to 4.
	}
	
	//for reentry simulation using a canned drag profile ??
	if (egflg > 0) and (islect > 2) {
		set islect to 2.
	}
	
	if (islect = 1) {
		//compute vertical l/d during preentry 
		egpep().
	} else if (islect = 2) {
		//reference parameters during temperature control
		egrp().
		egref().
	} else if (islect = 3) {
		//reference parameters during equilibrium glide
		egrp().
		egref().
	} else if (islect = 4) {
		//reference parameters during const drag
		egref4().
	} else if (islect = 5) {
		//reference parameters during transition
		egtran().
	} 
	
	//aoa command
	egalpcmd().

	//vertical l/d after preentry
	if (islect > 1) {
		eggnslct().
		eglodvcmd().
	}
	
	//roll command 
	egrolcmd().
	
	//transition checks 
	if (islect = 2) {
		if (ve < va) and (drefp < drefp3) {
			set islect to 3.
		}
	} else if (islect = 3) {
		if (ve < (vcg + delv)) and (drefp > drefp4) {
			set islect to 4.
		}
		
		if (ve < (vtran + delv)) and (drefp > drefp5) and (vcg < vtran) {
			set islect to 5.
		}
	} else if (islect = 4) {
		if (ve < (vtran + delv)) and (drefp > drefp5) {
		
		}
	}
}


function egscalht {

    if (ve < vhs1) {
        set hs to hs01 + hs11 * ve.
    } else if (ve < vhs2) {
		set hs to hs02.
	} else {
		set hs to hs03 + hs13 * ve.
	}

	set hs to max(hs, hsmin).

}

function eginit {
	set czold to 0.
	set ivrr to 0.
	set itran to 0.
	set islect to 1.
	set ict to 0.
	set idbchg to 0.
	set t2 to 0.
	set crefp to 0.
	set vq2 to 0.
	set rk2rol to -sign(delaz).
	set dlrdot to 0.
	set lmflg to 0.
	set vtrb to 60000.
	set ddp to 0.
	set rk2rlp to rk2rol.
	
	//nominal transition range at vtran
	set rpt to -(( etran - eef4 )* LN(df / alfm) / (alfm - df) + (vtran^2 - vq2) / (2*alfm) ) * cnmfs + rpt1.
	
	set vsat2 to vsat^2.
	set vsit2 to vs1^2.
	
	set vcg to vq.
	set d23 to d230.
	set dx[0] to 1.
	
	set v0[0]
}