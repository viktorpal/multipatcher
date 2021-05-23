function deleteTimer(t)
%UNTITLED Deletes a timer object, stops it before if it is running
%   

if ~isempty(t) && isvalid(t) && isa(t, 'timer')
    if strcmp('on', t.Running)
        stop(t);
    end
    delete(t);
end

end

