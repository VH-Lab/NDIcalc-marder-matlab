function ax = graceSpectrogramsBeatOverlayPlot(S,options)
% GRACESPECTROGRAMSBEATOVERLAYPLOT - Plot spectrograms with heart beat overlay.
%
% AX = GRACESPECTROGRAMSBEATOVERLAYPLOT(S)
%
% Plots spectrograms for all 'ppg' (photoplethysmogram) elements found within
% the ndi.session or ndi.dataset object S.  The function overlays heart beat
% information on top of each spectrogram. The plots are generated in a new figure
% window, arranged as a 4x1 subplot grid (4 rows, 1 column).
%
%   Input Arguments:
%       S - An ndi.session or ndi.dataset object.  This object contains the
%           data and metadata required to locate and load the spectrogram and
%           beat data.
%
%   Options:
%       options.colorbar (1,1) logical = false;  
%           Whether to display a colorbar alongside each spectrogram.
%           Default: false.
%
%       options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99;
%           The percentile of the spectrogram data to use as the maximum
%           value for the color scale. This helps to improve contrast by
%           clipping outliers.  Values should be between 0 and 100.
%           Default: 99.
%
%       options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula';
%           The name of the colormap to use for the spectrogram.  Must be
%           one of the following: 'parula', 'jet', 'hsv', 'hot', 'cool',
%           'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper',
%           or 'pink'.
%           Default: 'parula'.
%
%   Output Arguments:
%       ax - A column vector of axes handles.  Each element in `ax`
%            corresponds to one of the subplots (spectrograms) created by
%            the function.  This allows for further customization of the
%            plots after they have been generated.
%
%   Example:
%       % Assuming 'mySession' is an ndi.session object
%       ax = graceSpectrogramsBeatOverlayPlot(mySession); % Use default options
%
%       % Use custom options:
%       ax = graceSpectrogramsBeatOverlayPlot(mySession, ...
%                                            'colorbar', true, ...
%                                            'maxColorPercentile', 95, ...
%                                            'colormapName', 'jet');
%
%   See Also: gracePlotSpectrogram, ndi.session, ndi.dataset


arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.colorbar (1,1) logical = false;
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99;
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula';
    options.numSubplots = 10;
end


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
    ax(end+1,1) = subplot(options.numSubplots,1,i);
    filenameB = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '_beats.mat'])
    load(filenameB,'-mat');
    mlt.gracePlotSpectrogram(spec, f, ts, ...
        'colorbar', options.colorbar, ...
        'maxColorPercentile', options.maxColorPercentile, ...
        'colormapName', options.colormapName);
    hold on;
    good = find(~isnan([beats.instant_freq]));
    if isa(beats(1).onset,'datetime')
        plot3([beats(good).onset],[beats(good).instant_freq],2e15*ones(size(good)),...
            'k-','linewidth',2);
        if i==options.numSubplots,
            xlabel('Time');
        end;                
    else    
        plot3([beats(good).onset]/(60*60),[beats(good).instant_freq],2e15*ones(size(good)),...
            'k-','linewidth',2);
        if i==options.numSubplots,
            xlabel('Time from start (hr)');
        end;        
    end
    title([e{1}.elementstring],'interp','none');
end

linkaxes(ax,'xy');

