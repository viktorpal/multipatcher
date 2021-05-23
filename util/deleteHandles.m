function deleteHandles( hList )
%DELETEHANDLES Deletes nonempty, valid handles, graphical handles or java objects in the list
%   

if ~isempty(hList) && (any(ishandle(hList)) || (any(isgraphics(hList)) && any(isvalid(hList(isgraphics(hList)))) )) % if not empty and (if handle object or if graphics/java object)
    if any(ishandle(hList))
        hList = hList(ishandle(hList));
    else
        hList = hList(isvalid(hList(isgraphics(hList))));
    end
    if ~all(hList==0)
        delete(hList);
    end
end

end

