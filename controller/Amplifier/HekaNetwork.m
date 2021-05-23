classdef HekaNetwork < AbstractHeka & handle
    %HEKANETWORK Non blocking network communication with HEKA
    %   The giveOrder method just sends the command to the server and is not waiting for answer. The server should put
    %   the command in a queue and process later.
    
    properties (SetAccess = protected)
        host
    end
    
    methods
        function this = HekaNetwork(host)
            javaaddpath('./HekaNetworkCommunicator.jar');
            this.host = host;
        end
        
        function answer = giveOrder(this, order)
            try
                client = com.biomag.heka.HNCClient(this.host);
                client.sendMessage(order);
                client.close();
                answer = 'sent';
            catch ex
                log4m.getLogger().error(ex.message);
                answer = ['failed', ex.message];
            end
            
        end
    end
    
end

