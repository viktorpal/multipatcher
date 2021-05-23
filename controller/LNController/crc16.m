function [r, MSB, LSB] = crc16(msg)

% File CRC16.m
%**************************************************************************
% This script calculates the 16-bit ITU-T CRC, as described in 7.2.1.9 
% IEEE 802.15.4-2006 std. (ZigBee).
%
% Author: Everton Leandro Alves
% Date: 06/19/2008
% Edited: Krisztian Koos
% Date: 25/80/2016
%
% The generator polynomial is G(x)=x^16+x^12+x^5+1. The message in the
% example is [0100 0000 0000 0000 0101 0110] (b0..b23). From the given
% explanation the steps are:
% 1 - Remainder register 'r' is initialized to 0;
% 2 - The message is shifted into the divider (b0 first);
% 3 - Operations are done in the order: a) XORs, b) left shift of r 
% register and c) r3 and r10 update.
% 4 - The r register is appended to the message.
%
%**************************************************************************

% % % clear all
% % % clc

% msg=[0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 1 1 0];  % Example message

% display('Message:')
% msg

r=zeros(1,16);      % Remainder register initialization

for c3=1:length(msg)
   
    s1=bitxor(msg(c3),r(1));    % XOR between r0 and the message bit
    s2=bitxor(s1,r(12));        % XOR r11
    s3=bitxor(s1,r(5));         % XOR r4
    
    r=[r(2:16) s1];             % Left shift of r, and r15 update

    r(11)=s2;                   % r10 update
    r(4)=s3;                    % r3 update
end

if nargout == 3
    MSB = r(1:8);
    MSB = uint8(bin2dec(num2str(MSB)));
    LSB = r(9:16);
    LSB = uint8(bin2dec(num2str(LSB)));
end

% msg_FCS=[msg r];                % Message + FCS field

% display('Message + FCS field:')
% msg_FCS