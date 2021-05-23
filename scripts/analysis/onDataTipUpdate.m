function displayText = onDataTipUpdate(~,eventData, dList)
    pos = get(eventData,'Position'); % the new position of the datatip
    displayText = {['X: ',num2str(pos(1))], ...
                   ['Y: ',num2str(pos(2))]}; % construct the datatip text
    for id = 1:numel(dList)
        dList(id).Position(1) = pos(1); % update the location of the other datatip.
    end
end