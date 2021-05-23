if ~exist('multiStackPositions', 'var')
    multiStackPositions = zeros(0,3);
end
more = true;
while more
    button = questdlg('More top positions?',['Multi stack #', num2str(size(multiStackPositions,1))],...
        'Add current','No more', 'Add current');
    if strcmp(button, 'Add current')
        try
            multiStackPositions(end+1,:) = model.microscope.stage.getPosition();
        catch ex
            h = warndlg('Could not add current position! Try again!');
            waitfor(h);
        end
    else
        more = false;
    end
end
save('multiStackPositions.mat', 'multiStackPositions');

namePrefix = 'tissue';

i = 1;
while i <= size(multiStackPositions,1)
    try
        model.microscope.stage.moveTo(multiStackPositions(i,1), multiStackPositions(i,2), multiStackPositions(i,3), 'speed', 'fast');
        waiting = true;
        while waiting
            try
                model.microscope.stage.waitForFinished();
                waiting = false;
            catch ex
            end
        end
        imgstack = model.microscope.captureStack(100, 1, 'top');
        c = clock;
        idx = sprintf('%04d', i);
        name = strcat(namePrefix, idx, '_', num2str(c(1)), num2str(c(2)), num2str(c(3)), num2str(c(4)), num2str(c(5)), num2str(round(c(6))), '.tif');
        imgstack.save(name);
    catch ex
        c = clock;
        disp([num2str(c(4)), ':', num2str(c(5)), ':', num2str(c(6)), ' Error while creating stack: ', ex.message]);
        i = i-1;
        pause(1);
    end
    i = i + 1;
end
previousMultiStackPositions = multiStackPositions;
clear multiStackPositions

msgbox('Multi stack finished!');