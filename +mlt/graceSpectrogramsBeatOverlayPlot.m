function ax = graceSpectrogramsBeatOverlayPlot(S)
% GRACESPECTROGRAMSBEATOVERLAYPLOT - plot all the spectrograms from an experiment with heart beat overlayed
%
% AX = GRACESPECTROGRAMSBEATOVERLAYPLOT(S)
%
% Plot spectrograms for ppg elements for an ndi.session or ndi.dataset S.
% The plots are made in a new figure.
%
% Returns the axes for the plots.

p = S.getprobes('type','ppg');

path = S.path();

f = figure;

ax = [];

for i=1:numel(p),
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e),
        error(['No ''_lp'' version of ' p{i}.elementstring]);
    end
    filenameSG = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '.mat'])
    load(filenameSG,'-mat');
    ax(end+1,1) = subplot(4,1,i);
    filenameB = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '_beats.mat'])
    load(filenameB,'-mat');
    mlt.gracePlotSpectrogram(spec,f,ts);
    hold on;
    good = find(~isnan([beats.instant_freq]));
    if isa(beats(1).onset,'datetime')
        plot3([beats(good).onset],[beats(good).instant_freq],2e15*ones(size(good)),...
            'k-','linewidth',2);
        if i==4,
            xlabel('Time');
        end;                
    else    
        plot3([beats(good).onset]/(60*60),[beats(good).instant_freq],2e15*ones(size(good)),...
            'k-','linewidth',2);
        if i==4,
            xlabel('Time from start (hr)');
        end;        
    end
    title([e{1}.elementstring],'interp','none');
end

linkaxes(ax,'x');

