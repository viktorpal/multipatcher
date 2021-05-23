function bpmodel = startBlindPatcherIfNotRunning(handles)
%STARTBLINDPATCHERIFNOTRUNNING Starts Blind Patcher gui
%   Check and start Blind Patcher gui if not running already. The patching
%   is not started, however. The AutoPatcher system should be available to
%   use in the Blind Patcher window's mainfigure element's UserData property.

model = get(handles.mainfigure, 'UserData');
bph = model.blindPatcherFigure;
if isempty(bph) || ~ishandle(bph) || ~strcmp(get(bph, 'type'), 'figure')
    [bph, bpmodel] = BlindPatcherGui('autopatcher', model.autopatcher, 'rsImprover', model.rsImprover);
    model.blindPatcherFigure = bph;
    bph.OuterPosition = bpmodel.figureOuterPosition;
end
figure(bph);
if nargout >= 1
    bpmodel = get(findobj(model.blindPatcherFigure, 'Tag', 'mainfigure'), 'UserData');
end

end

