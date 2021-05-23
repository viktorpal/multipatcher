function reconstructed = reconstructDicImage(img, varargin)
%RECONSTRUCTDICIMAGE Reconstruct DIC image on GPU
%   The reconstruction algorithm is a variational framework which has a data and a smoothness term. The function calls
%   an OS dependent executable. The original algorithm is published in:
%       Koos, K., Moln�r, J., Kelemen, L., Tam�s, G. and Horvath, P., 2016. DIC image reconstruction using an energy 
%       minimization framework to visualize optical path length distribution. Scientific reports, 6, p.30420.
%

assert(~isempty(img), 'Input should not be empty!');
p = inputParser;
addParameter(p, 'iterations', 10000, @(x) ~isempty(x) && isnumeric(x));
addParameter(p, 'direction', 0, @(x) ~isempty(x) && isnumeric(x));
addParameter(p, 'wAccept', 0.25, @(x) ~isempty(x) && isnumeric(x));
addParameter(p, 'wSmooth', 0.0125, @(x) ~isempty(x) && isnumeric(x));
addParameter(p, 'locsize', 64, @(x) ~isempty(x) && isnumeric(x));
parse(p, varargin{:});
iterations = p.Results.iterations;
direction = p.Results.direction;
wAccept = p.Results.wAccept;
wSmooth = p.Results.wSmooth;
locsize = p.Results.locsize;

inputFpath = [tempname, '.png'];
outputFpath = [tempname, '.png'];
if ispc
    syscommand = ['cd .\util\DIC-reconstruction\win & dicgpu-win.exe --str-conf wAccept=', num2str(wAccept),'f,'...
        'wSmooth=', num2str(wSmooth),'f,direction=', num2str(direction),'f,nIter=', num2str(iterations),...
        ',locSize=', num2str(locsize),',kernelSrcPath=dic-rec.cl,verbose=0,input=', inputFpath, ',output=', outputFpath];
elseif isunix
    syscommand = ['cd ./util/DIC-reconstruction/linux && ./dicgpu --str-conf wAccept=', num2str(wAccept),'f,'...
        'wSmooth=', num2str(wSmooth),'f,direction=', num2str(direction),'f,nIter=', num2str(iterations),...
        ',locSize=', num2str(locsize),',kernelSrcPath=dic-rec.cl,verbose=0,input=', inputFpath, ',output=', outputFpath, ' > /dev/null'];
else
    error('Platform not supported');
end
imwrite(img, inputFpath);
status = system(syscommand);
delete(inputFpath);
if status ~= 0
    errorMsg = ['Error while reconstructing image, error code: ', num2str(status)];
    log4m.getLogger().error(errorMsg);
    error(errorMsg);
end
reconstructed = im2double(imread(outputFpath));
delete(outputFpath);

end

