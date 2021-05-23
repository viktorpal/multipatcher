classdef SM8Controller < SM5Controller & handle
    %SM5CONTROLLER Matlab implementation for controlling L&N SM8 devices
    %   
    
    
    methods
        function this = SM8Controller(comPort, timeout)
            if nargin < 2
                timeout = SM5Controller.defaultTimeout;
            end
            this = this@SM5Controller(comPort, timeout);
        end
    end
 
    methods (Access = protected)
        function b = checkResponse(~, response, ~)
            b = false;
%             if response(1) == 6 && response(end-1) == 0 && response(end) == 0
            if response(1) == 6 %&& response(end-1) == 0 && response(end) == 0
                b = true;
            end
        end
    end
end

