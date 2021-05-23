function deleteFigure(fh)
%DELETEFIGURE Checks if input handle is figure and deletes it
%   

if ~isempty(fh) && isvalid(fh) && strcmp(get(fh, 'type'), 'figure')
    close(fh);
	delete(fh);
end


end

