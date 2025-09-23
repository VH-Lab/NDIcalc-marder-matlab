function p = toolboxdir()
% TOOLBOXDIR - return the full path of the mlt-matlab toolbox
%
% P = mlt.util.toolboxdir()
%
% Returns the full path to the mlt-matlab toolbox.
%
% It is assumed that this function is in the folder
% [TOOLBOXDIR]/+mlt/+util/
%

[p,~,~] = fileparts(mfilename('fullpath'));

% now we have to go back three directories
p = fileparts(p); % now we are in +mlt
p = fileparts(p); % now we are in the parent of +mlt
