function clickMovePipetteCb(~, ~, handles)
%UICONTEXTMENUCBTEST Move pipette action on mouse click
%   Forwards the call whether it is a mouse click on the live image or a
%   loaded stack.

if get(handles.liveViewButton, 'Value')
    liveViewClickMovePipette(handles);
else
    stackClickedMovePipette(handles);
end

end

