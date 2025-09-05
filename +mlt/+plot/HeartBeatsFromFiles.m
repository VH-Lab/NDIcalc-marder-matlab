function ax = HeartBeatsFromFiles(S, options)
%HEARTBEATSFROMFILES - Plots beat statistics overlaid on the raw PPG signal.
%
%   AX = mlt.plot.HeartBeatsFromFiles(S)
%
%   This function visualizes pre-calculated heart beat statistics by
%   overlaying them on top of the **raw, unnormalized** PPG signal.
%
%   It loads data from pre-processed MAT-files found within the NDI session
%   path. These files are expected to contain the beat statistics (e.g.,
%   onset, frequency), which were derived from a **normalized** version of
%   the data, as well as the original raw PPG signal for the plot background.
%
%   The MAT-files are assumed to follow the naming convention:
%   'ppg_ppg_AREA_lp_whole_NUMBER_beats.mat'
%   ...where AREA is the recording site (e.g., 'heart', 'pylorus') and
%   NUMBER is the element's reference number.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object containing the PPG data.
%
%   Optional Name-Value Pairs:
%       Linewidth (1,1) double = 1;
%           The line width for the plotted lines.
%
%   Outputs:
%       AX - A column vector of axes handles. Each set of 3 axes handles
%            (for the 3 subplots in a figure) is concatenated vertically.
%
%   Example 1: Basic usage
%       % Assuming 'mySession' is an ndi.session object
%       ax = mlt.plot.HeartBeatsFromFiles(mySession);
%
%   Example 2: Specifying a custom line width
%       ax = mlt.plot.HeartBeatsFromFiles(mySession, 'Linewidth', 2);
%
%   See also mlt.plot.HeartBeat, ndi.session, ndi.dataset

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.Linewidth (1,1) double = 1
end

p = S.getprobes('type','ppg');
path = S.path();
ax = [];

for i=1:numel(p)
    disp(['Checking for processed beat file for ' p{i}.elementstring '...']);
    
    % Find the corresponding low-pass filtered element
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    
    if isempty(e)
        error(['No ''_lp_whole'' version of ' p{i}.elementstring ' found.']);
    end
    
    filename = fullfile(path, ['ppg_' e{1}.name '_' int2str(e{1}.reference) '_beats.mat']);
    
    if ~exist(filename, 'file')
        warning(['Could not find beat file: ' filename '. Skipping.']);
        continue;
    end
    
    load(filename,'-mat'); % loads variables: beats, d, t
    
    % Call the core plotting function
    ax_here = mlt.plot.HeartBeat(beats, d, t, 'Linewidth', options.Linewidth);
    ax = cat(1, ax, ax_here(:));
    
    % Add a title to the figure
    figure(get(ax_here(1), 'Parent'));
    sgtitle([e{1}.elementstring], 'Interpreter', 'none');
end