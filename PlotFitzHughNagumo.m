clear all; clc;
on=1; off=0;

Movie = off;  % Writes a movie
PlotAll=off;  % Both state variables are shown

BarFontSize      = 18;
TitleFontSize    = 24;

FID=fopen('output.dat', 'r');

X=fread(FID, 1, 'int32');
Y=fread(FID, 1, 'int32');
Length=fread(FID, 1, 'float');
NumFrames=fread(FID, 1, 'int32');
EndTime=fread(FID, 1, 'int32');

U=zeros(X,Y,'double');
V=zeros(X,Y,'double');

% Get Screen dimensions and set Main Window Dimensions
x = get(0,'ScreenSize'); ScreenDim=x(3:4);
MainWindowDim=floor(ScreenDim.*[0.9 0.8]);

if Movie==on,
    writerObj = VideoWriter('FitzHugh-Nagumo.mp4', 'MPEG-4');
    open(writerObj);
end;

if PlotAll==on,
    MainWindowDim=[1920 818];
else
    MainWindowDim=[960 720];
end;

% The graph window is initiated, with specified dimensions.
Figure1=figure('Position',[(ScreenDim-MainWindowDim)/2 MainWindowDim],...
               'Color', 'white');

if PlotAll==on, 
    subplot('position',[0.02 0.10 0.45 0.80]);
end;
F1=imagesc(U',[-0.7 1]);
title('The FitzHugh-Nagumo model','FontSize',TitleFontSize);  
cb=colorbar('SouthOutside','FontSize',BarFontSize); 
xlabel(cb,'Voltage');
colormap('default'); axis image;axis off;

if PlotAll==on,
    subplot('position',[0.52 0.10 0.45 0.80]);
    F2=imagesc(V',[-0.5 0.5]);
    title('Recovery','FontSize',TitleFontSize);  
    cb=colorbar('SouthOutside','FontSize',BarFontSize);
    xlabel(cb,'Voltage')
    axis image; axis off; 
end

for x=1:NumFrames,
    U = reshape(fread(FID,X*Y,'float32'),X,Y);
    V = reshape(fread(FID,X*Y,'float32'),X,Y);

    set(F1,'CData',U');
    if PlotAll==on,
        set(F2,'CData',V');
    end;
    set(Figure1,'Name',['Timestep ' num2str(ceil(x/NumFrames*EndTime)) ' of ' num2str(EndTime)]); 

    drawnow; 
    
    if Movie==on,
         frame = getframe(Figure1);
         writeVideo(writerObj,frame);
    end

end;

fclose(FID);

if Movie==on,
    close(writerObj);
end;

disp('Done');beep;


