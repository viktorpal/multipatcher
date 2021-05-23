classdef SM7Controller < SM8Controller & handle
    %SM7CONTROLLER Untested Matlab implementation for controlling L&N SM7 devices
    %
    
    methods
        function this = SM7Controller(comPort, device, timeout)
            if nargin < 3
                timeout = SM8Controller.defaultTimeout;
            end
            this = this@SM8Controller(comPort, device, timeout);
        end
    end
    
end

