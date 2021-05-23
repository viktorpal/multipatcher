fig = visualizationTool();
mainaxes = findobj(fig, 'Tag', 'mainaxes');
model = fig.UserData;
% fig.OuterPosition = model.figureOuterPosition;