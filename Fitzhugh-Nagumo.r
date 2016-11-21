# The Fitzhugh-Nagumo model of nerve dynamics
# Following FitzHugh R. (1955) Mathematical models of threshold phenomena in 
# the nerve membrane. Bull. Math. Biophysics, 17:257—278

# First setup of the model

remove(list=ls())     # Remove all variables from memory
on=1; off=0;

require('rootSolve')
require("fields")

PlotTimeRec = off
PlotPhasePlane = on

# Algal exchange parameters
Epsilon =  0.3        # Non-dimensional model parameter
a1      =  1.4        # Non-dimensional model parameter
a0      =  0.0        # Non-dimensional model parameter
D       =  2          # Non-dimensional model parameter

# Simulation parameters
Length  =  100        # m    The length of the simulated landscape, in meters
m       =  100        # #    gridcells

dT      =  0.1        # timestep 
EndTime =  500        # end time 
NoFrames=  250        # Number of frames displayed during the entire simulation

frac    =  0.05      # Initial settings: fraction of area filled with mussels
mp      =  m+1        # mp is used in specific array designations

WinWidth=12           #      - Width of the simulation window 
WinHeight=5           #      - Height of the simulation window

WinWidthPP=13         #      - Width of the simulation window 
WinHeightPP=4         #      - Height of the simulation window

Scale=3
Res=100

# Initialisation: declaring variable and setting up initial values
# All arrays of dimension m x m
u = v = du = dv = matrix(nrow=m,ncol=m) 
 
TimeRec=MusselRec=vector(length=NoFrames) 

dx=Length/m        # The size of a grid cell in X direction
dy=Length/m        # The size of a grid cell in Y direction

#------ Gradient and Laplacian operators --------------------------------------

# The gradient operator
d_dy = function (w) { # fluxes in y-direction, backwards difference scheme
  # Flux = (middle cell - left side cell) / cell size in y dimension
  fy = (w[c(1:m),] - w[c(m,1:(m-1)),]) / dy
  return(fy)
}

# The laplacian operator
d2_dxy2 = function (w) { # Diffusion terms in x and y dimensions
  # Flux = Right + Left -2*middle cells +
  fxy = (w[1:m,c(2:m,1)] + w[1:m,c(m,1:m-1)] - 2*w[1:m,1:m])/dy/dy +
  #        Above + Below - 2*middle cells        
        (w[c(2:m,1),1:m] + w[c(m,1:m-1),1:m] - 2*w[1:m,1:m])/dx/dx;
  return(fxy)
}

#------ Window function ------------------------------------------------

OpenWindow = function (WinWidth,WinHeight) {
  if (Sys.info()["sysname"]=="Darwin"){
    quartz(width=WinWidth, height=WinHeight, 
           title="The Fitzhugh-Nagumo model")
  } else
    windows(width = WinWidth, height = WinHeight,
            title="The Fitzhugh-Nagumo model")
}

#------ Model definition -----------------------------------------------

f = function (u,v) { u - u^3 - v }
g = function (u,v) { Epsilon*(u - a1*v - a0) }

fwrapper = function (x, u) { f(u,x) }
gwrapper = function (x, v) { g(x,v) }

ui = vi = uj = vj = NULL

for(i in 1:Res) { 
  
  ui[i]=-Scale/2+i/100*Scale; 
  vi[i]=uniroot(fwrapper, u=ui[i], interval=c(-10,10))$root
  
  vj[i]=-Scale/2+i/100*Scale; 
  uj[i]=uniroot(gwrapper, v=vj[i], interval=c(-100,100))$root
}

#------ Initial setup and calculation ----------------------------------

# initial state of A and M at the start of the run
#u=-0.53*-(matrix(ncol=m,nrow=m,data=runif(m*m))<=frac*0)
u[]=0.535
u[(m/2-2):(m/2+2),(m/2-2):(m/2+2)]=-0.53
v[]=(u-a0)/a1


Time =  0          # Begin time 
ii   =  1e6        # Setting the plot counter to max, so that drawing start immediately
jj   =  0          # The counter needed for recording data during the run

# ------- Setting up the figure ------------------------------------------
## Open a graphics window (Darwin stands for a Mac computer)

if(PlotPhasePlane==on){
  OpenWindow(WinWidthPP,WinHeightPP)
  par(mfrow=c(1,3), mar=c(3, 4, 2, 6) + 0.1)
} else {
  OpenWindow(WinWidth,WinHeight)
  par(mfrow=c(1,2), mar=c(3, 4, 2, 6) + 0.1)
}

# ------------ The simulation loop ---------------------------------------
 
print(system.time(
while (Time<=EndTime){   # Here the time loop starts   
   
  # Calculating local input, uptake, growth and mortality
  du = f(u,v) + d2_dxy2(u)   
  dv = g(u,v) + D*d2_dxy2(v)
  
  # Summing up local processes and lateral flow to calculate new A and M
  u = u + du*dT 
  v = v + dv*dT 
  
  # Graphic representation of the model every now and then
  if (ii>=EndTime/NoFrames/dT)
      {image.plot(u, zlim=c(-1,1), xaxt="n", yaxt="n",
             asp=1, bty="n",
             legend.shrink = 0.99, legend.width = 1.8)
       title("Voltage (volts)")      

       image.plot(v, zlim=c(-1,1), xaxt="n", yaxt="n",
             asp=1, bty="n",
             legend.shrink = 0.99, legend.width = 1.8)
       title("Current (ampere)")
       
       mtext(text=paste("Time : ",sprintf("%1.0f",Time),
                        "of" ,sprintf("%1.0f",EndTime), "timesteps"), 
       side=1, adj=-0.9, line=1.5, cex=1)
       
       if(PlotPhasePlane==on){
         plot(ui,vi, col="blue", type="l")
         lines(uj,vj, col="red")
         points(u[m/3,m/3], v[m/3,m/3])
       }
       
       # The following two lines prevent flickering of the screen
       dev.flush() # Force the model to update the graphs
       dev.hold()  # Put all updating on hold  

       ii=0    # Resetting the plot counter 
       jj=jj+1 # Increasing the Recorder counter
       
       TimeRec[jj]=Time # The time in days
       MusselRec[jj]=mean(v)  # Mean mussel biomass 
      } 

  Time=Time+dT  # Incrementing time with one
  ii=ii+1       # Incrementing the plot counter with one
 
} ))  # Here the time loop ends

# This last part shows a figure with the change in average biomass
if (PlotTimeRec==on){
  # Open a graphics window (Darwin stands for a Mac computer)
  if (Sys.info()["sysname"]=="Darwin"){
     quartz(width=WinWidth, height=WinHeight, 
           title="Mussel bed patterns model")
  } else
     windows(width = WinWidth, height = WinHeight,
            title="Mussel bed patterns model")

  plot(TimeRec,MusselRec, xlab="Time (days)", ylab="Mussel biomass")
}



 
 
