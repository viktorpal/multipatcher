function moments = imageMoment(img, qRange, pRange, centralized)
%IMAGEMOMENT Calculates image moments
%   The function calculates raw or centralized image moments. qRange and
%   pRange are vectors of length n and m containing the orders in y and x directions,
%   respectively, to calculate the moments for. Parameter centralized is a
%   logical variable to calculate raw (false) or centralized (true,
%   default) moments. Output variable moments is an n by m matrix
%   containing the moments of the requested orders.

assert(ismatrix(img));
assert(isvector(qRange));
assert(isvector(pRange));
if nargin < 4
    centralized = true;
end

moments = zeros(numel(qRange),numel(pRange));
[n,m] = size(img);

if centralized
    xhat = imageMoment(img, 0, [0, 1], false);
    xhat = xhat(2)/xhat(1);
    yhat = imageMoment(img, 1, 0, false)/imageMoment(img, 0, 0, false);
end

for i = 1:numel(qRange)
    q = qRange(i);
    if centralized
        Y = repmat(((1:n)-yhat)'.^q, 1, m);
    else
        Y = repmat((1:n)'.^q, 1, m);
    end
    for j = 1:numel(pRange)
        p = pRange(j);
        if centralized
            X = repmat(((1:m)-xhat).^p, n, 1);
        else
            X = repmat((1:m).^p, n, 1);
        end
        
        moments(i, j) = sum(sum(X.*Y.*img));
    end
end

end

