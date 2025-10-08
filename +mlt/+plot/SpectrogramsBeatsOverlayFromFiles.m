function ax = SpectrogramsBeatsOverlayFromFiles(S, options)
%MLT.PLOT.SPECTROGRAMSBEATSOVERLAYFROMFILES - Plots spectrograms with a heart beat frequency overlay.
%
%   AX = mlt.plot.SpectrogramsBeatsOverlayFromFiles(S)
%
%   This function visualizes the relationship between instantaneous heart beat
%   frequency and the spectral content of a PPG signal. For each PPG probe in
%   the NDI session, it plots a spectrogram and overlays the beat frequency
%   trace on top.
%
%   The function loads data from two separate, pre-calculated MAT-files for
%   each probe. It searches for these files in the NDI session's path using
%   the following naming conventions:
%
%   1. Spectrogram File: 'ppg_ppg_AREA_lp_whole_NUMBER.mat'
%      (Must contain 'spec', 'f', and 'ts' variables)
%   2. Beats File: 'ppg_ppg_AREA_lp_whole_NUMBER_beats.mat'
%      (Must contain a 'beats' struct)
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Optional Name-Value Pairs:
%       colorbar (1,1) logical = false
%           Set to true to display a color bar for each spectrogram.
%       maxColorPercentile (1,1) double = 99
%           The percentile of the spectrogram data to use as the maximum
%           value for the color scale (0-100).
%       colormapName (1,:) char = 'parula'
%           The name of the colormap to use (e.g., 'jet', 'hot').
%       numSubplots (1,1) double = 10
%           The number of vertical subplots to prepare in the figure.
%
%   Outputs:
%       ax - A column vector of axes handles for the generated subplots.
%
%   Example:
%       % Assuming 'mySession' is an ndi.session object
%       ax = mlt.plot.SpectrogramsBeatsOverlayFromFiles(mySession);
%
%   See also mlt.plot.Spectrogram, mlt.plot.HeartBeatFromFiles

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.colorbar (1,1) logical = false
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'
    options.numSubplots (1,1) double = 10
    options.ylimSpectrogram (1,2) double = [0 5];
end

p = S.getprobes('type','ppg');
path = S.path();

if isempty(p)
    disp('No PPG probes found in the session.');
    ax = [];
    return;
end

fig = figure;
ax = [];

for i=1:numel(p)
    disp(['Processing element ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e)
        warning(['No ''_lp_whole'' version of ' p{i}.elementstring ' found. Skipping.']);
        continue;
    end
    
    % --- Load data from the two required files ---
    filenameSG = fullfile(path, ['ppg_' e{1}.name '_' int2str(e{1}.reference) '.mat']);
    filenameB = fullfile(path, ['ppg_' e{1}.name '_' int2str(e{1}.reference) '_beats.mat']);

    if ~exist(filenameSG, 'file')
        warning(['Spectrogram file not found: ' filenameSG '. Skipping.']);
        continue;
    end
    if ~exist(filenameB, 'file')
        warning(['Beats file not found: ' filenameB '. Skipping.']);
        continue;
    end
    
    % Load spectrogram data (spec, f, ts) and beats data (beats)
    sg_data = load(filenameSG, '-mat');
    b_data = load(filenameB, '-mat');
    
    % --- Plotting ---
    ax(end+1,1) = subplot(options.numSubplots, 1, i);
    
    % Plot the base spectrogram
    mlt.plot.Spectrogram(sg_data.spec, sg_data.f, sg_data.ts, ...
        'colorbar', options.colorbar, ...
        'maxColorPercentile', options.maxColorPercentile, ...
        'colormapName', options.colormapName, ...
        'ylim', options.ylimSpectrogram);
    hold on;
    
    % Overlay the instantaneous beat frequency
    good = find(~isnan([b_data.beats.instant_freq]));
    beats_struct = b_data.beats(good);
    
    % Use a large Z value to ensure the line plots on top of the 2D image
    z_level = 2e15 * ones(size(beats_struct)); 
    
    if isa(beats_struct(1).onset, 'datetime')
        plot3([beats_struct.onset], [beats_struct.instant_freq], z_level, ...
            'k-', 'linewidth', 2);
        if i == options.numSubplots, xlabel('Time'); end
    else    
        plot3([beats_struct.onset]/(60*60), [beats_struct.instant_freq], z_level, ...
            'k-', 'linewidth', 2);
        if i == options.numSubplots, xlabel('Time from start (hr)'); end
    end
    
    title(e{1}.elementstring, 'Interpreter', 'none');
    hold off;
end

if ~isempty(ax)
    linkaxes(ax,'xy');
end