
//piecewise reentry pitch profile
//the pitch value of the highest velocity point does not matter 
//it will be updated if the velocity is higher than 
// its vel value and the update_reference flag is true 

//	38/28


GLOBAL pitchprof_segments IS LIST(
							LIST(250,3),
							LIST(2400,28),
							LIST(5400,28),
							LIST(6400,38)
							).




