function enableDrawArea(handles)
cla(handles.mainaxes);
set(handles.mainaxes, 'HitTest', 'on');
set(handles.zSlider, 'Visible', 'on');
set(handles.zsliceText, 'Visible', 'on');
end
