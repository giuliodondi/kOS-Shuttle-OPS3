@LAZYGLOBAL OFF.


//input constants


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
global dds is 0.		//



//flag for regular or canned reenty guidance 
//egflg = 0 is bank modulation guidance
//egflg = 2 is is for simulations and terminates at mach 23?
global egflg is 0.

global islect is 1.

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