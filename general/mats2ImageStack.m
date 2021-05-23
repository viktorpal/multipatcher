function imageStack = mats2ImageStack( folder, fnameregexp, varname )
%MATS2IMAGESTACK Creates an ImageStack object of mat files
%   The function creates and outputs an ImageStack object from the content
%   of .mat files in a folder. 
%   fnameregexp - used as ['*', fnameregexp, '*'], can define a regexp or
%   part of filename. Intended for exclusion of files (optional, default = []).
%   varname - variable name to look for in the mat files. (optional, default = 'image')

if nargin < 2
    fnameregexp = [];
else
    assert(ischar(fnameregexp) || isempty(fnameregexp), '''fnameregexp'' should be a character array or empty.');
end
if nargin < 3 || isempty(varname)
    varname = 'image';
elseif ~ischar(varname)
    error('''varname'' should be a character array.');
end
assert(~isempty(folder), 'Input ''folder'' cannot be empty.');
assert(exist(folder, 'dir')>0, 'The folder does not exist.');
files = dir(fullfile(folder, ['*', fnameregexp, '*.mat']));
assert(~isempty(files), 'No .mat files found in the given folder.');

numfiles = numel(files);
for i = 1:numfiles
    content = load(fullfile(folder, files(i).name));
    assert(isfield(content, varname), strcat('The mat file ''', files(i).name, ''' does not contain a variable called ''', varname,'''.'));
    img = content.(varname);
    assert(ismatrix(img), 'Only 2D images can be concatenated!');
    [n,m] = size(img);
    if i == 1
        imageStack = ImageStack(zeros(n, m, numfiles));
    end
    imageStack.setSlice(img, i);
end

end

