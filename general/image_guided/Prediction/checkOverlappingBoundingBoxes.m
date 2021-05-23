function selected_cells = checkOverlappingBoundingBoxes(regprops, minimum_intersection, max_zdistance)
% AUTHOR:	Tamas Balassa
% DATE: 	Sept 20, 2017
% NAME: 	checkOverlappingBoundingBoxes
% 
% This function filters all the predicted cells. Only the most sure cells
% will be forwarded for visualization.
%
%
% INPUT:
%       * regprops                  -   All predicted bounding box
%       * minimum_intersection      -   Percentage of the minimum req intersec
%
% OUTPUT:
%       * selected_cells            -   The cells that will be visualized
%

selected_cells = [];
all_cells = [];
similar_boundingboxes = [];
numberOfImages = size(regprops,1);

for i=1:numberOfImages
   all_cells = [all_cells, regprops{i}];
end
cell_groups = zeros(size(all_cells,2),1);
counter = 0;
if ~isempty(all_cells)
    similar_boundingboxes(1).BoundingBox = all_cells(1).BoundingBox; % otherwise the 1st BB will be empty
end

% selects one cell (i) and compares it to all other ones (j), if they are
% similar (means they should be equal just on different z position) then
% they will be put into the same cell_groups
for i=1:size(all_cells,2)-1
    if cell_groups(i) == 0
        counter = counter + 1;
        base = all_cells(i);
        group_value = base;
        for j=i+1:size(all_cells,2)            
            if cell_groups(j) == 0
                compared = all_cells(j);
                [similars, correct_boundingbox_union, correct_boundingbox_intersection] = compareBoundingBoxes(group_value, compared, minimum_intersection);
                if similars && group_value.z ~= compared.z && compared.z - group_value.z <= max_zdistance

                    cell_groups(i) = counter;
                    cell_groups(j) = counter;
                    correct_boundingbox = correct_boundingbox_intersection;
                    group_value.BoundingBox = [correct_boundingbox(1), correct_boundingbox(2), correct_boundingbox(3), correct_boundingbox(4)];
                    group_value.z = compared.z;
                    similar_boundingboxes(i).BoundingBox = correct_boundingbox;
                    similar_boundingboxes(j).BoundingBox = correct_boundingbox;
                else
                    similar_boundingboxes(j).BoundingBox = all_cells(j).BoundingBox;
                end
            end
        end
    else
       similar_boundingboxes(i).BoundingBox = all_cells(i).BoundingBox; 
    end
end

group_ids = unique(cell_groups);

% selecting the cells for visualization
for i=1:length(group_ids)
    tmp_indexes = find(cell_groups == group_ids(i));
    if i==1 % the cells that occurs only once - belongs to cell_group == 0
        for t=1:length(tmp_indexes)
            selected_cells(end+1).Area = all_cells(tmp_indexes(t)).Area;
            selected_cells(end).BoundingBox = similar_boundingboxes(tmp_indexes(t)).BoundingBox;
            selected_cells(end).z = all_cells(tmp_indexes(t)).z;
            selected_cells(end).color = 0;
            selected_cells(end).ProbabilityMean = all_cells(tmp_indexes(t)).ProbabilityMean;
            selected_cells(end).ProbabilityMin = all_cells(tmp_indexes(t)).ProbabilityMin;
            selected_cells(end).ProbabilityMax = all_cells(tmp_indexes(t)).ProbabilityMax;
        end
    else
    % if they belongs to a cell_group then they will be presented by only one
    % cell
        if mod(size(tmp_indexes,1) ,2) == 1
            idx = (size(tmp_indexes, 1) + 1) / 2;
        else
            idx = size(tmp_indexes,1) / 2;
        end
        selected_cells(end+1).Area = all_cells(tmp_indexes(idx)).Area;
        selected_cells(end).BoundingBox = similar_boundingboxes(tmp_indexes(idx)).BoundingBox;
        selected_cells(end).z = all_cells(tmp_indexes(idx)).z;
        selected_cells(end).ProbabilityMean = mean([all_cells(tmp_indexes).ProbabilityMean]);
        selected_cells(end).ProbabilityMin = min([all_cells(tmp_indexes).ProbabilityMin]);
        selected_cells(end).ProbabilityMax = max([all_cells(tmp_indexes).ProbabilityMax]);
        selected_cells(end).color = 1;
    end
end