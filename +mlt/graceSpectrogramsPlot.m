function graceSpectrogramsPlot(S)
% GRACESPECTROGRAMSPLOT - plot all the spectrograms from an experiment
%
% GRACESPECTROGRAMSPLOT(S)
%
% Plot spectrograms for ppg elements for an ndi.session or ndi.dataset S.
%

p = S.getprobes('type','ppg');

path = S.path();

f = figure;

for i=1:numel(p),
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp'],'element.reference',p{i}.reference);
    if isempty(e),
        error(['No ''_lp'' version of ' p{i}.elementstring]);
    end
    filename = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '.mat'])
    load(filename,'-mat');
    subplot(4,1,i);
    mlt.gracePlotSpectrogram(spec,f,ts);
    title([e{1}.elementstring],'interp','none');
    if i==4,
        xlabel('Time from start (s)');
    end;
end

