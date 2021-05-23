function [similars, boundingbox_union, boundingbox_intersection] = compareBoundingBoxes(base, compared, minimum_intersection)
% AUTHOR:	Tamas Balassa
% DATE: 	Sept 19, 2017
% NAME: 	compareBoundingBoxes
% 
% This function compares two bounding boxes, and based on the intersection
% percentage parameter they can be similars or not.
%
%
% INPUT:
%       * base                  -   Bounding box of the 1st object [x, y, w, h]
%       * compared              -   Bounding box of the 2nd object [x, y, w, h]
%       * minimum_intersection  -   Percentage of the minimum req intersec
%
% OUTPUT:
%       * similars                      -   1 if they are similars,0 if not
%       * boundingbox_union             -   [x, y, w, h]
%       * boundingbox_intersection      -   [x, y, w, h]
%
    similars = 0;    
    boundingbox_union = [];
    boundingbox_intersection = [];
    
    A_x1 = base.BoundingBox(1);
    A_y1 = base.BoundingBox(2);
    w1 = base.BoundingBox(3);
    h1 = base.BoundingBox(4);
    A_x2 = base.BoundingBox(1) + w1;
    A_y2 = base.BoundingBox(2) + h1;
    
    B_x1 = compared.BoundingBox(1);
    B_y1 = compared.BoundingBox(2);
    w2 = compared.BoundingBox(3);
    h2 = compared.BoundingBox(4);
    B_x2 = compared.BoundingBox(1) + w2;
    B_y2 = compared.BoundingBox(2) + h2;
    
    if A_x1 <= B_x1
        intersection_x1 = B_x1;
        union_x1 = A_x1;
    else
        intersection_x1 = A_x1;
        union_x1 = B_x1;
    end
    
    if A_x2 <= B_x2
        intersection_x2 = A_x2;
        union_x2 = B_x2;
    else
        intersection_x2 = B_x2;
        union_x2 = A_x2;
    end
    
    if A_y1 <= B_y1
        intersection_y1 = B_y1;
        union_y1 = A_y1;
    else
        intersection_y1 = A_y1;
        union_y1 = B_y1;
    end
    
    if A_y2 <= B_y2
        intersection_y2 = A_y2;
        union_y2 = B_y2;
    else
        intersection_y2 = B_y2;
        union_y2 = A_y2;
    end
    
    if intersection_x1 < intersection_x2 && intersection_y1 < intersection_y2
        intersection_w = intersection_x2 - intersection_x1;
        intersection_h = intersection_y2 - intersection_y1;
        intersection_region = abs(intersection_w * intersection_h);    

        region1 = h1 * w1;
        region2 = h2 * w2;

        if intersection_region >= region1 * minimum_intersection || intersection_region >= region2 * minimum_intersection
            similars = 1;
            boundingbox_union = [union_x1, union_y1, union_x2-union_x1, union_y2-union_y1];
            boundingbox_intersection = [intersection_x1, intersection_y1, intersection_w, intersection_h];
        end
    end
