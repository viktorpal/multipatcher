function createUIContextMenus(handles)

c = uicontextmenu(handles.mainfigure);
uimenu(c, 'Label', 'Move pipette here', 'Callback', @(src,event) clickMovePipetteCb(src, event, handles));
uimenu(c, 'Label', 'Approach cell here', 'Callback', @(src,event) clickPatchClamp(src, event, handles, true)); % approach only
uimenu(c, 'Label', 'Do patch-clamp here', 'Callback', @(src,event) clickPatchClamp(src, event, handles));
handles.mainaxes.UIContextMenu = c;

end