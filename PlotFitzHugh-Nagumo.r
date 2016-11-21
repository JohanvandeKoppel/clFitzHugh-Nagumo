# First setup of the model
remove(list=ls()) # Remove all variables from memory

on=1;off=0;
setwd('/Simulations/OpenCL/clFitzHugh-Nagumo/clFitzHugh-Nagumo')

require(fields)

FileName = "Output.dat"
cat(paste("Data file date :",file.info(FileName )$mtime ),"\n")
FID = file(FileName, "rb")

Movie=off
Wait=off
WinWidth = 960
WinHeight = 720

NX = readBin(FID, integer(), n = 1, endian = "little");
NY = readBin(FID, integer(), n = 1, endian = "little");
Length=readBin(FID,  numeric(), size=4, n = 1, endian = "little")
NumFrames = readBin(FID, integer(), n = 1, endian = "little");
EndTime=readBin(FID,  integer(), n = 1, endian = "little")

DPI=144

Sparkling.palette= colorRampPalette(c("black", "black", "green", "yellow", "red"))
UsedPalette=Sparkling.palette(255)
#UsedPalette=rainbow(255)

if (Movie==off) 
  quartz(width=WinWidth/DPI, height=WinHeight/DPI, dpi=DPI)

for (jj in 0:(NumFrames-1)){  # Here the time loop starts 
  
   if (Movie==on)
     tiff(filename = sprintf("Images/Rplot%03d.tiff",jj),
          width = WinWidth, height = WinHeight, 
          units = "px", pointsize = 24,
          compression="none",
          bg = "white", res = NA,
          type = "quartz")   
   
   V1 = matrix(nrow=NY, ncol=NX, readBin(FID, numeric(), size=4, n = NX*NY, endian = "little"));
   V2 = matrix(nrow=NY, ncol=NX, readBin(FID, numeric(), size=4, n = NX*NY, endian = "little"));
   
   par(mar=c(2, 3, 2, 5) + 0.1)
   
   MaxV=1
   MinV=-0.5
   
   V1m=pmin(pmax(V2,MinV),MaxV)
   
   image.plot(V1m, zlim=c(MinV,MaxV), xaxt="n", yaxt="n",
              bty="n", useRaster=TRUE,
              legend.shrink = 0.99, legend.width = 2,
              legend.args=list(text=expression(Voltage),
                               cex=0.8, line=0.5))  
   title("The FitzHugh-Nagumo model")   
   
#   mtext(text=paste("Time : ",sprintf("%1.0f",jj),
#                     "of" ,sprintf("%1.0f",NumFrames), "Frames"), 
#      side=1, adj=0.5, line=0.5, cex=1)

   mtext(text=sprintf("Time : %1.0f of %1.0f timesteps", (jj+1)/NumFrames*EndTime, EndTime), 
         side=1, adj=0.5, line=0.5, cex=1)   
   
  if (Movie==on) dev.off() else { 
    dev.flush()
    dev.hold()
  }
  if (Wait==on){
    cat ("Press [enter] to continue, [q] to quit")
    line <- readline()
    if (line=='q'){ stop() }
  } 
}

close(FID)

if (Movie==on) { 
  
  InFiles=paste(getwd(),"/Images/Rplot%03d.tiff", sep="")
  OutFile="FitzHugh-Nagumo.mp4"
  
  print(paste(" building :", OutFile))
  
  CmdLine=sprintf("ffmpeg -y -r 30 -i %s -c:v libx264 -pix_fmt yuv420p -b:v 2000k %s", InFiles, OutFile)
  cmd = system(CmdLine)
  
  # if (cmd==0) try(system(paste("open ", paste(getwd(),"Mussels_PDE.mp4"))))
} 

system('say All ready')

