function tsec = time2sec( time )
%TIME2SEC Converts Matlab timestamp to seconds
%   This function is useful when the time passed between two timestamps has
%   to be expressed in seconds.
%
%   See also TIME2MIN

tsec = time * 86400; % 86400 = 24*3600

end

