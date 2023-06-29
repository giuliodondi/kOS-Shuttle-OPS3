



//fancy function to print stuff to screen in a consistent format
//prints a fixed width of screen in characters at a specified position 
//given by leftcolumn and line .
//pads with blank spaces as needed
FUNCTION PRINTPLACE{
	parameter string.
	parameter width.
	parameter leftcolumn.
	parameter line.
	
	set string to string + "".

	local x is width - string:LENGTH.
	
	IF x<0 {RETURN.}
	
	set x to FLOOR(x/2).
	if x=0 {set x to 0.}
	
	LOCAL blankstr IS "".
	
	FROM {LOCAL k IS 1.} UNTIL k > width STEP { SET k TO k+1.} DO{
		SET blankstr TO blankstr + " ".
	}
	
	PRINT blankstr AT (leftcolumn,line).
	PRINT string AT (leftcolumn + x,line).

}




//log handler function, takes a lexicon as imput
//creates a log file, deleting the file by the same name if it exists
//then creates the column headers by dumping the lexicon keys
//if the log file has already been created just logs the lexicon to file
FUNCTION log_data {
	
	//logs to a file specified by filename the values of a lexicon log_lex
	FUNCTION dataLog {
		DECLARE PARAMETER filename.
		PARAMETER log_lex.
		
		LOCAL str IS "".
		
		//append to the string the numbers in sequence separated by four spaces
		FOR val IN log_lex:VALUES {
			SET str TO str + val + ",".
		}

		LOG str TO filename.
	}

	PARAMETER log_lex.
	PARAMETER logname_string IS "".
	PARAMETER overwrite IS FALSE.
	
	if not (defined logname) {
	
		IF overwrite {
			GLOBAL logname is logname_string  + ".csv".
			IF EXISTS(logname)=TRUE {
				MOVEPATH(logname,logname_string + "_old" + ".csv").
			}
		} ELSE {
			local logcount is 0.
			GLOBAL logname is logname_string + "_" + logcount + ".csv".
			until false {
				set logname to logname_string + "_" + logcount + ".csv".
				IF EXISTS(logname)=TRUE {
					set logcount to logcount + 1.
				}
				ELSE {break.}
				
				
			}
		}
		
		LOCAL titlestr IS "".
		
		FOR key IN log_lex:KEYS {
			SET titlestr TO titlestr + key + ",".
		}
		
		log titlestr to logname.

	} ELSE { 	
		dataLog(logname,log_lex).
	}
}





//draw a vector  with label, by default its centered on the ship and scaled to 10 times its length
FUNCTION arrow {
	PARAMETER vec.
	PARAMETER lab.
	PARAMETER vec_centre IS v(0,0,0).
	PARAMETER scl IS 10.
	PARAMETER wdh IS 0.5.
	
	VECDRAW(
      vec_centre,
      vec,
      RGB(1,0,0),
      lab,
      scl,
      TRUE,
      wdh
    ).

}

//draw a vector  with label, by default its centered on the body and scaled to 2 times its length
FUNCTION arrow_body {
	PARAMETER vec.
	PARAMETER lab.
	PARAMETER scl IS 2.
	PARAMETER wdh IS 0.5.
	
	VECDRAW(
      SHIP:ORBIT:BODY:POSITION,
      vec,
      RGB(1,0,0),
      lab,
      scl,
      TRUE,
      wdh
    ).

}

//draw a vector  with label centered on the ship and scaled to 30 times its length
FUNCTION arrow_ship {
	PARAMETER vec.
	PARAMETER lab.
	
	VECDRAW(
      v(0,0,0),
      vec,
      RGB(1,0,0),
      lab,
      30,
      TRUE,
      0.02
    ).

}


//draw a vector centered on geolocation for target redesignation
//scales with distance from ship for visibility
FUNCTION pos_arrow {
	PARAMETER pos.
	PARAMETEr stringlabel.
	
	LOCAL start IS pos:POSITION.
	LOCAL end IS (pos:POSITION - SHIP:ORBIT:BODY:POSITION).
	
	VECDRAW(
      start,//{return start.},
      end:NORMALIZED*5000,//{return end.},
      RGB(1,0,0),
      stringlabel,
      1,
      TRUE,
      3
    ).

}



//converts the universal clock in seconds
FUNCTION utc_time_seconds {
	LOCAL utc_time Is TIME.
	RETURN utc_time:SECOND + 60*utc_time:MINUTE + 3600*utc_time:HOUR.
}

//givne a longitude from 0 long. gives the local clock in seconds
FUNCTION local_time_seconds {
	PARAMETER long.

	LOCAL utc_time IS utc_time_seconds().
	
	LOCAL degree_shift IS BODY:ROTATIONPERIOD/360.

	RETURN wraparound(utc_time + long*degree_shift, 0, BODY:ROTATIONPERIOD).
}


//converts a time value into a hours,minutes,seconds string
declare function sectotime {
	parameter t.
	parameter space is " ".
	
	local string is "".
	if t<0 {
		set t to ABS(t).
		set string to string + "-".
	}
	if t<60 {
		set string to string + FLOOR(t) + space + "s".	
	}
	else {
		local minutes is FLOOR(t/60).
		if minutes<60 {
			local sec is FLOOR(t - minutes*60).
			set string to string + minutes + space + "m " + sec + space + "s".
		}
		else {
			local sec is FLOOR(t - minutes*60).	
			local hr is FLOOR(minutes/60).
			set minutes to minutes - hr*60.
			set string to string + hr + space + "h " + minutes + space + "m " + sec + space + "s".
		}
	}
	return string.
}



//select a random element from a list
FUNCTION select_rand{
	PARAMETER lst.
	
	LOCAL len IS lst:LENGTH.
	
	RETURN lst[FLOOR(len*RANDOM())].
}



// object that implements a fixed-size list where elements are added at the front
FUNCTION fixed_list_factory {
	PARAMETER len.

	local this is lexicon().
	
	this:add(
			"list", LIST()
	).
	
	this:add(
			"maxlength", len
	).
	
	this:add("trim", {
		if (this:list:length > this:maxlength) {
			local sublist is this:list:sublist(0,this:maxlength).
			set this:list to sublist.
		}
	}
	).
	
	this:add("push", {
		parameter newval.
		this:list:insert(0, newval).
		this:trim().
	}
	).
	
	this:add("printat", {
		parameter col.
		parameter line.
		
		local c is col.
		for v in this:list {
			local str_v is v + ",".
			print v at (c,line).
			set c to c + str_v:length + 1.
		}
		//get rid of the last comma
		print " " at (c - 1,line).
	}
	).

	return this.
}

//object that keeps track of the last x values inserted and calculates the running average of them
FUNCTION average_value_factory {
	parameter avgcount.

	local this is lexicon().
	
	this:add(
			"numvalues", avgcount
	).
	
	this:add(
			"list", fixed_list_factory(this["numvalues"])
	).
	
	
	
	this:add("reset", {
		set this:list to fixed_list_factory(this["numvalues"]).
	}
	).
	
	
	this:add("update", {
		parameter newval.
		this:list:push(newval).
	}
	).
	
	this:add("average", {
		
		local avg is 0.
		
		local values is this:list:list.
		local len is values:length.
		
		if (len=0) {return 0.}
		
		for v in values {
			set avg to avg + v.
		}
		
		return avg/len.
	}
	).

	return this.
}


//object that executes a piece of code in a loop
FUNCTION loop_executor_factory {
	parameter dt.
	parameter runnable.

	LOCAL this IS LEXICON().
	
	this:add("runnable", runnable).
	
	this:add("last_execution_t", TIME:SECONDS).
	this:add("min_exec_time", dt).
	this:add("preserve_", TRUE).
	
	this:add("stop_execution", {
		SET this:preserve_ TO FALSE.
	}).
	
	WHEN TIME:SECONDS>(this:last_execution_t + this:min_exec_time) THEN {
		//DROPPRIORITY().
		runnable().
		
		SET this:last_execution_t TO TIME:SECONDS.
		IF (this:preserve_) {
			PRESERVE.
		}
	}
	
	return this.
}


//given a lapse of time to wait, manages ksp warp
FUNCTION warp_controller {
	PARAMETER time_span.
	PARAMETER auto_warp.
	PARAMETER final_wait IS 30.
	
	LOCAL cur_warp IS warp.
	
	LOCAL new_warp IS cur_warp.
	
	IF time_span > (3600 + final_wait) or time_span < 0 {
		set new_warp to 4.
	}
	ELSE IF time_span > (400 + final_wait) {
		set new_warp to 3.
	}
	ELSE IF time_span > (60 + final_wait) {
		set new_warp to 2.
	}
	ELSE IF time_span > final_wait {
		set new_warp to 1.
	}
	ELSE {
		set new_warp to 0.
	}
	
	IF NOT auto_warp {
		set new_warp to MIN(new_warp, cur_warp).
	}
	
	IF warp <> new_warp {
		set warp to new_warp.
	}
	
	
}

