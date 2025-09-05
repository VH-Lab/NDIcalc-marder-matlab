function ax = SpectrogramsFromFiles(S, options)
%SPECTROGRAMSFROMFILES - Plot spectrograms for PPG elements from pre-calculated files.
%
%   AX = mlt.plot.SpectrogramsFromFiles(S)
%
%   Plots spectrograms for all 'ppg' probes found within an ndi.session or
%   ndi.dataset object S. The spectrograms for all probes are plotted as
%   subplots within a single figure.
%
%   This function searches the NDI session's path for pre-calculated MAT-files
%   that contain spectrogram data. These files are assumed to be named
%   according to the convention:
%
%   'ppg_ppg_AREA_lp_whole_NUMBER.mat'
%
%   ...where AREA is the recording site (e.g., 'heart', 'pylorus') and
%   NUMBER is the element's reference number. Each file must contain the
%   variables: 'spec' (the spectrogram data), 'f' (frequency vector), and
%   'ts' (time vector).
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Optional Name-Value Pairs:
%       colorbar (1,1) logical = false
%           Set to true to display a color bar for each spectrogram.
%       maxColorPercentile (1,1) double = 99
%           The percentile of the data to use as the maximum value for the
%           color scale, clipping extreme values. Must be between 0 and 100.
%       colormapName (1,:) char = 'parula'
%           The name of the colormap to use (e.g., 'jet', 'hot', 'gray').
%       numSubplots (1,1) double = 10
%           The number of vertical subplots to prepare in the figure.
%
%   Outputs:
%       ax - A column vector of axes handles for the generated subplots.
%
%   Example 1: Basic usage
%       % Assuming 'mySession' is an ndi.session object
%       ax = mlt.plot.SpectrogramsFromFiles(mySession);
%
%   Example 2: Plot with color bars and a different colormap
%       ax = mlt.plot.SpectrogramsFromFiles(mySession, 'colorbar', true, 'colormapName', 'hot');
%
%   See also mlt.plot.gracePlotSpectrogram, imagesc, colormap

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.colorbar (1,1) logical = false
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'
    options.numSubplots (1,1) double = 10
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

    filename = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '.mat']);
    if ~exist(filename, 'file')
        warning(['Spectrogram file not found: ' filename '. Skipping.']);
        continue;
    end

    load(filename,'-mat'); % Expected to load spec, f, ts

    figure(fig);
    ax(end+1,1) = subplot(options.numSubplots, 1, i);
    
    mlt.plot.Spectrogram(spec, f, ts, ...
        'colorbar', options.colorbar, ...
        'maxColorPercentile', options.maxColorPercentile, ...
        'colormapName', options.colormapName);
        
    title(e{1}.elementstring, 'Interpreter', 'none');
end

if ~isempty(ax)
    linkaxes(ax,'xy');
end

end