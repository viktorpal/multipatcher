imgFolder = '/home/koosk/data/images/AP_stacks_for_cell_tracking';
fnameStartsWith = '9_'; % e.g. 1_6_L1int.tif means 1st series, 6th stack, cortical region
numStacks = 10; % should not change for the current dataset
diameter = 120*2+1;
corrZsameMultiplier = 0.95;
% corrZsameMultiplier = 1;

%%
if imgFolder(end) ~= filesep
    imgFolder = [imgFolder, filesep];
end
templateFile = dir([imgFolder, fnameStartsWith,'1_*.tif']);
templateStack = ImageStack.load(fullfile(templateFile.folder, templateFile.name));
stack = templateStack.getStack();
if ~bitget(size(stack,3), 1)
    error('stack size should be odd')
end
[sy,sx,sz] = size(stack);
refSlice = round(sz/2);
templateImage = stack(:,:,refSlice );

fig = figure;
imshow(templateImage)

[xRef, yRef] = ginput(1);
xRef = round(xRef);
yRef = round(yRef);
% % 721,527
% xRef = 718;
% yRef = 530;

close(fig)
result = []; % zeros(numel(stacks),0);
for iStack = 2:numStacks
    stackFile = dir([imgFolder, fnameStartsWith, num2str(iStack),'_*.tif']);
    imgstack = ImageStack.load(fullfile(stackFile.folder, stackFile .name));
    stack = imgstack.getStack();
    values = zeros(1,sz);
    windows = zeros([diameter,diameter,3]);
    for iz = 1:sz
        currentImage = (stack(:,:,iz));
%         currentImage = mat2gray(currentImage);
        [values(iz), wref, wcurr] = calculateZSimilarity(yRef, xRef, yRef, xRef, templateImage, currentImage, floor(diameter/2));
        if iz == refSlice
            values(iz) = values(iz)*corrZsameMultiplier;
        end
        windows(:,:,iz) = wcurr;
    end
    
%     figure,
%     subplot(1,3,1),
%     imshow(mat2gray(wref)),
%     subplot(1,3,2),
%     [~, minpos] = min(values,[],2);
%     imshow(mat2gray(windows(:,:,minpos))),
%     subplot(1,3,3),
%     imshow(mat2gray(windows(:,:,refSlice))),
%     drawnow
    
    result(iStack-1,:) = values; %#ok<SAGROW>
end
% figure, plot(result'), legend('show')
[minval,bestZ] = min(result,[],2);
bestZ'
numRemainedSame = nnz(bestZ == 3);
numTotalCases = numel(bestZ);
numAbove = nnz(bestZ > 3);
numBelow = nnz(bestZ < 3);
accuracy = numRemainedSame/numTotalCases * 100;

disp(' ')
fprintf('fname\txRef\tyRef\tnumRemainedSame\tnumTotalCases\tnumAbove\tnumBelow\taccuracy\n')
fprintf('%s\t%d\t%d\t%d\t%d\t%d\t%d\t%2.2f\n', templateFile.name, xRef, yRef, numRemainedSame, numTotalCases, numAbove, numBelow, accuracy)

