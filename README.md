[![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/80x15.png)](https://creativecommons.org/licenses/by/4.0/)

# Kerbal Space Program Space Shuttle OPS3 Entry Guidance
Real Entry and Landing guidance for the Space Shuttle in KSP / RO

# Work In Progress, not yet functional

This will be the kOS implementation of the real-world Shuttle Entry, TAEM and Approach guidance, also including GRTLS  

Only designed to be compatible with my fork of Space Shuttle System (https://github.com/giuliodondi/Space-Shuttle-System-Expanded) with realistic aerodynamics  

## References
- [MCC level C formulation requirements. Entry guidance and entry autopilot, optional TAEM targeting](https://ntrs.nasa.gov/api/citations/19800016873/downloads/19800016873.pdf)
- [MCC level C formulation requirements. Shuttle TAEM Guidance and Flight Control, optional TAEM targeting](https://ntrs.nasa.gov/api/citations/19800016874/downloads/19800016874.pdf)
- [Space Shuttle Entry Terminal Area Energy Management](https://ntrs.nasa.gov/api/citations/19920010688/downloads/19920010688.pdf)
- [SPACE SHUTTLE ORBITER OPERATIONAL LEVEL C FUNCTIONAL SUBSYSTEM SOFTWARE REQUIREMENTS GUIDANCE, NAVIGATION AND CONTROL PART A - ENTRY THROUGH LANDING GUIDANCE](https://www.ibiblio.org/apollo/Shuttle/sts83-0001-34%20-%20Guidance%20Entry%20Through%20Landing.pdf)


# Installation

WIP


# Setup

WIP


# Deorbit planning

Entry Interface is the point at which reentry begins, defined as 122km (400kft) altitude. The goal of deorbit planning is to reach this point at the right conditions for a proper reentry.  
The critical parameters to control are velocity, range, and flight-path-angle (FPA), the angle of descent with respect to the horizontal. All these depend on the initial orbit and the placement/magnitude of the deorbit burn.

First, you need to place a deorbit manoeuvre node on the last orbital pass before the landing site, it's crucial that you use a surface-relative trajectory tool like Principia or Trajectories to pick the right orbital pass. The node need only be created coarsely at this stage, plan a periapsis of near 0km a bit downrange from the landing site.

Then run **ops3_deorbit.ks** to fire up the planning tool. Choose carefully the landing site (it will be frozen after this).  
The tool will predict your state at Entry Interface which you will use to adjust your deorbit burn. The _Ref__ numbers are your desired parameters, the actual parameters will be red if they're too far off from the reference numbers, you should try to get all numbers in the green.

![main_gui](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/deorbit_gui.png)


Rules of thumb:
- Start from a near-circular orbit if you can
- Adjust velocity at EI by changing the retrograde deltaV
- Adjust range and FPA together by changing the radial deltaV and moving the node forward and backward
- Make small adjustments as it takes a second or two for the tool to predict the new trajectory
- Expect the ref. velocity at EI to also change a little as you do this
- Make small adjustments until you converge to a good burn


# The main Entry script

The main script to run is **ops3.ks**. You need to run it below entry interface, until then it will exit without doing anything. The script will take you from Entry Interface all the way to wheels stop on the runway.  
You interact with the script using two GUIS. The **Main GUI** is a panel of buttons and a data display:

![main_gui](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/ops3_gui.png)

- _Target_ is the target site, **select and double-check this immediately after starting the program**
- _Runway_ is the runway you will land on. There are always at least two runways even if there is a single strip of tarmac (one for each side). The choice is automatic upon selecting the landing site, but you can override it here
- _Apch mode_ is a parameter used by TAEM guidance, by default is set to Overhead. Leave it be for now.
- _DAP_ selects the digital autopilot modes. **As long as you leave it OFF the program will not send any steering commands**. More on autopilot modes later on.
- _Auto Flaps_ will enable pitch trimming by moving the elevons and body flap. **99.9% of the time you want this enabled**.
- _Auto Airbk_ will toggle between manual (off) and automatic (on) rudder speedbrake functionality. **Also leave this on during Entry** and don't worry about it until TAEM
- _RESET_ allows you to completely reset the guidance algorithms during either Entry or TAEM. The program will also actuate this every time you change target, runway or approach.
- _Log Data_ will log some telemetry data to the file **Ships/Script/Shuttle_OPS3/LOGS/ops3_log.csv**
- the _Display_ will show different things depending on the flight phase. There will be plenty more about this later on.

The other GUI to look at is the **HUD**:
![hud](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/hud.png)

## Digital Autopilot modes

# Entry guidance

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/drag_vel.png" width="800">


![traj_disp](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/entry_traj_displays.png)

- Mach 12 / 1000km
- Mach 10 / 750 km
- Mach 5 / 250 km
- Mach 3 / 100 km


# TAEM guidance

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/hac.png" width="600">

![vsit_disp](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/vsit_displays.png)

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/vsit_low.png" width="350">

# GRTLS guidance

WIP

# Approach & Landing guidance

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/a_l_profile.png" width="800">


# Results from a test reentry to Edwards

![sample_traj](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/traj.png)

![entry_plots](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/entry_plots_1.png)

![entry_eow](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/eow.png)

![]()
