function [p, penalty] = ph3_validatePoint(p, sx, sy, sz)
%PH3_VALIDATEPOINT Check and convert 3D point
%   

if isvector(p)
    penalty = false;
    if p(1) < 1
        p(1) = 1;
        penalty = true;
    elseif p(1) > sx
        p(1) = sx;
        penalty = true;
    end
    if p(2) < 1
        p(2) = 1;
        penalty = true;
    elseif p(2) > sy
        p(2) = sy;
        penalty = true;
    end
    if p(3) < 1
        p(3) = 1;
        penalty = true;
    elseif p(3) > sz
        p(3) = sz;
        penalty = true;
    end
    p = [p(2), p(1), p(3)];
else
    n = size(p,1);
    penalty = false(n,1);
    
    penalty(p(:,1)<1) = true;
    p(p(:,1)<1,1) = 1;
    penalty(p(:,1)>sx) = true;
    p(p(:,1)>sx,1) = sx;
    
    penalty(p(:,2)<1) = true;
    p(p(:,2)<1,2) = 1;
    penalty(p(:,2)>sy) = true;
    p(p(:,2)>sy,2) = sy;
    
    penalty(p(:,3)<1) = true;
    p(p(:,3)<1,3) = 1;
    penalty(p(:,3)>sz) = true;
    p(p(:,3)>sz,3) = sz;
    p = p(:,[2 1 3]);
end

end

