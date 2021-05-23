function tmin = time2min( time )
%TIME2MIN Converts Matlab timestamp to minutes
%   This function is useful when the time passed between two timestamps has
%   to be expressed in minutes.
%
%   See also TIME2SEC

tmin = time * 1440; % 1440 = 24*60

end

