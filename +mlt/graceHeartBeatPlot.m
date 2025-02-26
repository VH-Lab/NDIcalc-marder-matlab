function ax = graceHeartBeatPlot(S)
% GRACESPECTROGRAMSPLOT - plot all the spectrograms from an experiment
%
% AX = GRACESPECTROGRAMSPLOT(S)
%
% Plot spectrograms for ppg elements for an ndi.session or ndi.dataset S.
%
% AX are the axes generated. 
%
% One figure is made per probe.
%
% Example: 
%   mlt.graceHeartBeatPlot(S)
%

p = S.getprobes('type','ppg');

path = S.path();

ax = [];

for i=1:numel(p),
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp'],'element.reference',p{i}.reference);
    if isempty(e),
        error(['No ''_lp'' version of ' p{i}.elementstring]);
    end
    filename = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '_beats.mat'])
    load(filename,'-mat');
    ax_here = mlt.gracePlotHeartBeat(beats,d,t);
    ax = cat(1,ax,ax_here(:));
    subplot(3,1,1);
    title([e{1}.elementstring],'interp','none');
    if i==4,
        xlabel('Time from start (hr)');
    end
end

