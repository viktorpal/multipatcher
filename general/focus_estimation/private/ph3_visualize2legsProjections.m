function h = ph3_visualize2legsProjections( xax, yax, zax, R,z1rot,yrot,z2rot,zeta1,r,eta,alpha,len,zScale, color)
%PH3_VISUALIZE2LEGSPROJECTIONS Visualize pipette detection in projections
%   

if nargin < 14
    color = 'red';
end

s1 = sin(z1rot);
c1 = cos(z1rot);
s2 = sin(yrot);
c2 = cos(yrot);
s3 = sin(z2rot);
c3 = cos(z2rot);

R1 = [ c1, -s1,  0; ...
       s1,  c1,  0; ...
       0,    0,  1];
R2 = [ c2,   0, s2; ...
        0,   1,  0; ...
      -s2,   0, c2];
R3 = [ c3, -s3,  0; ...
       s3,  c3,  0; ...
        0,   0,  1];
R12 = R1*R2;
Rall = R12*R3;
e1 = Rall(:,1);
e2 = Rall(:,2);
n  = Rall(:,3);

l1off = +e2*eta.*[1;1;zScale];
l2off = -e2*eta.*[1;1;zScale];
l1vec = Rall*[0; sin(alpha); cos(alpha)];
l2vec = Rall*[0; sin(-alpha); cos(-alpha)];

l1start = R' + l1off + l1vec*zeta1.*[1;1;zScale];
l1end   = R' + l1off + l1vec*len.*[1;1;zScale];
l2start = R' + l2off + l2vec*zeta1.*[1;1;zScale];
l2end   = R' + l2off + l2vec*len.*[1;1;zScale];

h = [];
h = [h, plot(zax, [l1start(1), l1end(1)], [l1start(2), l1end(2)], 'Color', color)];
h = [h, plot(zax, [l2start(1), l2end(1)], [l2start(2), l2end(2)], 'Color', color)];
h = [h, plot(yax, [l1start(3), l1end(3)], [l1start(1), l1end(1)], 'Color', color)];
h = [h, plot(yax, [l2start(3), l2end(3)], [l2start(1), l2end(1)], 'Color', color)];
h = [h, plot(xax, [l1start(3), l1end(3)], [l1start(2), l1end(2)], 'Color', color)];
h = [h, plot(xax, [l2start(3), l2end(3)], [l2start(2), l2end(2)], 'Color', color)];

end

