function selected_cells = predictStack(imgstack, params, statusCb)
% AUTHOR:	Tamas Balassa, Krisztian Koos
% DATE: 	Sept 15, 2017
% NAME: 	predictStack
% 
% This function 
%
%
% INPUT:
%       * imgstack            - ImageStack object which will be predicted
%       * params              - struct or class containing the required parameters for detection. In the GUI it comes
%                               from GeneralParameters object.
%       * statusCb (optional) - function handle with one input, which is the status in percentage of the process
%
% OUTPUT:
%       * selected_cells     -   The cells that will be visualized
%
    
if nargin < 3
    statusCb = [];
end

minimum_intersection = params.predictionMinOverlapToUnite;
max_zdistance = params.predictionMaxZdistanceToUnite;
s = size(imgstack.getStack(),3);

regprops = cell(s,1);
for z = 1:s
    img = imgstack.getLayer(z);
    cells = params.predictor.predictImage(img);
    for i = 1:numel(cells)
        w = cells(i).BoundingBox(3);
        h = cells(i).BoundingBox(4);

        if h <= params.predictionMaxObjectDimension(2) ...
                && w <= params.predictionMaxObjectDimension(1) ...
                && h >= params.predictionMinObjectDimension(2) ...
                && w >= params.predictionMinObjectDimension(1)
            cells(i).z = z;
            regprops{z}(end+1) = cells(i);
        end
    end
    if ~isempty(statusCb)
        statusCb(z/(s+1));
    end
end

selected_cells = checkOverlappingBoundingBoxes(regprops, minimum_intersection, max_zdistance);
if ~isempty(statusCb)
    statusCb(1);
end
end

