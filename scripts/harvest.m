stepSize = 2;
movementWaitTime = 3; % seconds

pipette = model.microscope.getPipette(model.activePipetteID);
previousAutomaticSlowSpeed = pipette.automaticSlowSpeed;
pipette.automaticSlowSpeed = 1;
try
    pipette.switchToAutomaticSlowSpeed();
    %% pull back a bit
%     pipette.move(-pipette.x_forward*1, [], [], 'speed', 'slow');
    %% vacuum and movement for 1 min
    model.autopatcher.pressureController.setPressure(-50);
    while model.autopatcher.pressureController.getPressure() > -50
        pause(1);
    end
    directions = ['x', 'y', 'z'];
    for i = 1:2
        randDirections = directions(randperm(3));
        randSign = randi(2)-1;
        if randSign == 0
            randSign = -1;
        end
        for j = 1:numel(randDirections)
            direction = randDirections(j);
            if direction == 'x'
                pipette.move(pipette.x_forward*stepSize, [], [], 'speed', 'slow');
                pause(movementWaitTime);
                pipette.move(-pipette.x_forward*stepSize, [], [], 'speed', 'slow');
                pause(movementWaitTime);
            elseif direction == 'y'
                pipette.move([], randSign*pipette.y_forward*stepSize, [], 'speed', 'slow');
                pause(movementWaitTime);
                pipette.move([], -randSign*pipette.y_forward*stepSize*2, [], 'speed', 'slow');
                pause(movementWaitTime*2);
                pipette.move([], randSign*pipette.y_forward*stepSize, [], 'speed', 'slow');
                pause(movementWaitTime);
            else % z
                pipette.move([], [], randSign*pipette.z_forward*stepSize, 'speed', 'slow');
                pause(movementWaitTime);
                pipette.move([], [], -randSign*pipette.z_forward*stepSize*2, 'speed', 'slow');
                pause(movementWaitTime*2);
                pipette.move([], [], randSign*pipette.z_forward*stepSize, 'speed', 'slow');
                pause(movementWaitTime);
            end
        end
    end
    
    
    %% retraction
    button = questdlg('Continue with retraction?', 'Harvesting', 'Yes', 'No', 'No');
    if strcmp(button, 'Yes')
        model.autopatcher.pressureController.setPressure(-80);
        while model.autopatcher.pressureController.getPressure() > -80
            pause(1);
        end
        pipette.move(-pipette.x_forward*200, [], [], 'speed', 'slow');
    end
    
    %% try to suck the nuclei into the pipette
    if strcmp(button, 'Yes')
        button = questdlg('Continue with strong sucction?', 'Harvesting', 'Yes', 'No', 'No');
        if strcmp(button, 'Yes')
            model.autopatcher.pressureController.setPressure(-100);
            pause(60);
            model.autopatcher.pressureController.setPressure(0);
        end
    end
catch ex
    ex.message
end
pipette.automaticSlowSpeed = previousAutomaticSlowSpeed;
pipette.switchToAutomaticSlowSpeed();