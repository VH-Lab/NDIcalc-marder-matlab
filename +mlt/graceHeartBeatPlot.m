function ax = graceHeartBeatPlot(S, options)
% GRACEHEARTBEATPLOT - Plot heart beat statistics for PPG elements in an NDI session/dataset.
%
%   AX = GRACEHEARTBEATPLOT(S) plots heart beat statistics (raw PPG signal,
%   instantaneous beat frequency, and duty cycle) for all 'ppg' probes found
%   within the ndi.session or ndi.dataset object S.  A separate figure is
%   created for *each* 'ppg' probe.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object containing the PPG data.
%
%   Optional Inputs:
%       options.Linewidth (1,1) double = 1;
%           The line width to use for the plots (PPG signal, beat
%           frequency, and duty cycle).
%
%   Outputs:
%       AX - A column vector of axes handles.  Each set of 3 axes handles
%            (corresponding to the 3 subplots in a figure) is concatenated
%            vertically.  So, if there are two 'ppg' probes, AX will be a
%            6x1 vector.
%
%   Example 1: Basic usage
%       % Assuming 'mySession' is an ndi.session object
%       ax = graceHeartBeatPlot(mySession);
%
%   Example 2: Specifying a custom line width
%       ax = graceHeartBeatPlot(mySession, 'Linewidth', 2);
%
%   See also gracePlotHeartBeat, ndi.session, ndi.dataset

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.Linewidth (1,1) double = 1
end

p = S.getprobes('type','ppg');

path = S.path();

ax = [];

for i=1:numel(p),
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e),
        error(['No ''_lp'' version of ' p{i}.elementstring]);
    end
    filename = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '_beats.mat'])
    load(filename,'-mat');
    ax_here = mlt.gracePlotHeartBeat(beats, d, t, 'Linewidth', options.Linewidth); % Pass Linewidth
    ax = cat(1,ax,ax_here(:));
    subplot(3,1,1);
    sgtitle([e{1}.elementstring],'interp','none');
end

