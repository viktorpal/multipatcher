function [x, y, z] = estimateFocusPipeline( imgstack, pipette, pixelSizeX, varargin )
%ESTIMATEFOCUSPIPELINE Pipette detection pipeline
%   Rough line profile estimation and then fine tuning with Pipette Hunter 3D 2 wands.

p = inputParser;
addParameter(p, 'show', false, @islogical);
parse(p, varargin{:});
show = p.Results.show;

%% setup
ph = PipetteHunter2wands();
ph.show = show;
ph.bgCorrection = true;
ph.phiStepsizeDeg = 7.5;%7.5;
ph.rhoStepsize = 2;%2;
ph.numiter = 5000;
ph.zScale = pixelSizeX;
ph.tolerance = 1; %10^1;
ph.estimatedTipSizeUm = 2.3;
ph.zetaStepsize = 5;
ph.gaussFilter = true; % true
ph.invert = true; %false;
ph.deltaRho = 2; % 15 
ph.zeta1 = 0;
ph.zeta2 = 1200;
ph.phi1 = pi+deg2rad(pipette.orientation);%-12.5
ph.phi2 = pi/2+deg2rad(pipette.angle);
ph.phi3 = 0+deg2rad(0); % yaw
ph.eta = 10;
ph.alpha = deg2rad(6);%6, 15;
ph.alphaShrink = 0;%10^-3;% 10^-3;
ph.xMult = 10^-3; %10^-3
ph.phiMult = 10^-8;
ph.etaMult = 10^-4; %10^-4
ph.alphaMult = 10^-9; %10^-8;
ph.penaltyValue = 0;
ph.checkTermination = 100;

%% detection
[x, y, z] = estimateFocusByLineProfiles(imgstack, pipette.orientation, 'show', show);
log4m.getLogger().warn('Only line profile estimation is used to increase speed.');
% ph.center = [x, y, z];
% ph.imgTarget = imgstack;
% ph.run();
% x = ph.center(1);
% y = ph.center(2);
% z = ph.center(3);
log4m.getLogger().info(['Final detected pipette tip position: (', num2str(x), ', ', num2str(y), ', ', num2str(z), ')']);

end

