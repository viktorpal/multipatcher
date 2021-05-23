function [dec1,dec2,dec3,dec4,floatbin2] = float2dec(pos,order,isUint)

% This function converts float numbers to decimal representation in Matlab.
% 
% 22.02.2009 P. Schnepel, University of Freiburg, Germany
% mail to: philipp.schnepel@biologie.uni-freiburg.de


if nargin < 3
    isUint = false;
end

if ~isUint
    % -------- Bit-wise representation of IEEE-754 Standard 32bit float -------

    % Print 'single'-precision (32bit) decimal number as hex; this gives the
    % easiest way of 'decoding' a float in matlab, since it cannot display it
    % in a binary fashion
    hex_c = sprintf('%tx',pos);
else
    hex_c = sprintf('%08x', pos);
end

% Initialise vars
tpl = zeros(1,4);
floatbin = [];

% Loop through single hex-values and convert them to 4bit binaries
for hh = 1:length(hex_c)
    
    tmp1 = dec2bin(hex2dec(hex_c(hh)),4);   % 4bits of hex-value
    
    % single-file conversion to 1's and 0's (as e.g. leading 0 would be
    % omitted otherwise...
    for n=1:4
        tpl(n) = str2num(tmp1(n));          % convert to num
    end
    
    floatbin = [floatbin tpl];              % build 32bit float
    
end

switch order
    
    case 'normal'
        
    % Normal byte-order, NOT IEEE-754 Standard!!!!
    floatbin2 = [floatbin(1:8),floatbin(9:16),...
    floatbin(17:24),floatbin(25:32)];

    case 'swap'
        
    % Reverse byte-order because: <LSB><Byte2><Byte3><MSB>, so LSB first
    % This seems to be IEEE-754 Standard for sending float data...
    floatbin2 = [floatbin(25:32),floatbin(17:24),...
                 floatbin(9:16),floatbin(1:8)];

end

% Convert to uint8-decimal representation
dec1 = uint8(bin2dec(num2str(floatbin2(1:8))));
dec2 = uint8(bin2dec(num2str(floatbin2(9:16))));
dec3 = uint8(bin2dec(num2str(floatbin2(17:24))));
dec4 = uint8(bin2dec(num2str(floatbin2(25:32))));

