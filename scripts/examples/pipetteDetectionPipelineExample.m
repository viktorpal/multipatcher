pipette = model.microscope.getPipette(this.activePipetteId);

ph = PipetteHunter2wands();
ph.show = true;
ph.bgCorrection = true;
ph.phiStepsizeDeg = 7.5;%7.5;
ph.rhoStepsize = 2;%2;
ph.numiter = 5000;
ph.zScale = 0.115;
ph.tolerance = 1; %10^1;
ph.estimatedTipSizeUm = 2.3;
ph.zetaStepsize = 5;
ph.gaussFilter = true; % true
ph.invert = true; %false;
ph.deltaRho = 2; % 15 
ph.zeta1 = 0;
ph.zeta2 = 1200;
ph.phi1 = pi+deg2rad(-12.5);%-12.5,%-17.5
% ph.phi2 = pi/3+deg2rad(-1.5);
ph.phi2 = pi/2+deg2rad(pipette.angle);
ph.phi3 = 0+deg2rad(0); % yaw?
ph.eta = 10;
ph.alpha = deg2rad(6);%6, 15;
ph.alphaShrink = 0;%10^-3;% 10^-3;
ph.xMult = 10^-3; %10^-3
ph.phiMult = 10^-8;
ph.etaMult = 10^-4; %10^-4
ph.alphaMult = 10^-9; %10^-8;
ph.penaltyValue = 0;
ph.checkTermination = 100;

%% filepaths and possible parameter alterations
% filepath = '/home/koosk/Data-linux/images/stack_images/pipette_stacks/Marci_setup/pipette4.tif';
% ph.phi1 = pi+deg2rad(0);
% % xStart = 1100; yStart = 520; percentile = 50; percentDropCheck = 40;

% filepath = '/home/koosk/Data-linux/images/stack_images/pipette_stacks/3d_setup_20180412/pipette01.tif';
% % xStart = 750; yStart = 490; percentile = 90; percentDropCheck = 25;

% filepath = '/home/koosk/Data-linux/images/stack_images/pipette_stacks/3d_setup_20180412/pipette03.tif';
% % xStart = 1120; yStart = 430; percentile = 90; percentDropCheck = 40;

% filepath = '/home/koosk/Data-linux/images/stack_images/pipette_stacks/3d_setup_20180412/pipette04.tif';


% filepath = '/home/koosk/Data-linux/images/stack_images/pipette_stacks/3d_setup_20180412/pipette08.tif';
% % xStart = 800; yStart = 465; percentile = 90; percentDropCheck = 40;

% filepath = '/home/koosk/Data-linux/images/stack_images/pipette_stacks/3d_setup_20180412/pipette11.tif';
% % xStart = 870; yStart = 475; percentile = 90; percentDropCheck = 40;1

filepath = '/home/koosk/Data-linux/images/stack_images/pipette_stacks/3d_setup_20180412/pipette14.tif';
% % xStart = 870; yStart = 475; percentile = 90; percentDropCheck = 40;

imgstack = ImageStack.load(filepath);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[x, y, z] = estimateFocusByLineProfiles(imgstack, pipette.orientation, 'show', true)
ph.center = [x, y, z];
ph.imgTarget = imgstack;
ph.run();
disp(['Line profile estimation: ', num2str([x, y, z])]);
disp(['Model center point: ', num2str(ph.center)]);
disp(['Estimated tip point: ', num2str(ph.estimatedTipPosition)]);








