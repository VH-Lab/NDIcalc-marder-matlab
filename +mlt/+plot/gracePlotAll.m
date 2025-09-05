function gracePlotAll(S, options)
%GRACEPLOTALL - Plot all summary data for an NDI session/dataset.
%
%   mlt.plot.gracePlotAll(S)
%
%   Generates a comprehensive set of plots summarizing photoplethysmogram
%   (PPG) data from an ndi.session or ndi.dataset object S. It creates
%   three separate figures:
%       1. Spectrograms of the PPG data.
%       2. Heartbeat statistics plots (raw PPG, frequency, duty cycle).
%       3. Spectrograms with overlaid heartbeat frequency.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Optional Name-Value Pairs:
%       colorbar (1,1) logical = false
%           Whether to display colorbars for the spectrogram plots.
%
%       colormapName (1,:) char = 'parula'
%           The colormap to use for the spectrogram plots.
%
%       maxColorPercentile (1,1) double = 99
%           The percentile of spectrogram data to use as the maximum
%           value for the color scale (for contrast enhancement).
%
%       Linewidth (1,1) double = 1
%           The line width for the heartbeat statistics plots.
%
%   Details:
%       This function calls three other functions to generate the plots:
%           1. mlt.plot.SpectrogramsFromFiles
%           2. mlt.plot.HeartBeatsFromFiles
%           3. mlt.plot.SpectrogramBeatsOverlayFromFiles
%
%       The function then links the x-axes across all generated figures,
%       ensuring that zooming and panning are synchronized.
%
%   Example 1: Basic Usage
%       mlt.plot.gracePlotAll(mySession);
%
%   Example 2: Name-value pair inputs
%       mlt.plot.gracePlotAll(mySession, 'colorbar', true, ...
%           'colormapName', 'hot', 'Linewidth', 1.5);
%
%   See also mlt.plot.SpectrogramsFromFiles, mlt.plot.HeartBeatsFromFiles,
%   mlt.plot.SpectrogramBeatsOverlayFromFiles, linkaxes

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.colorbar (1,1) logical = false
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99
    options.Linewidth (1,1) double = 1
end

% 1. Plot Spectrograms from Files
axS = mlt.plot.SpectrogramsFromFiles(S, ...
    'colorbar', options.colorbar, ...
    'colormapName', options.colormapName, ...
    'maxColorPercentile', options.maxColorPercentile);

% 2. Plot Heart Beat Statistics from Files
axHB = mlt.plot.HeartBeatsFromFiles(S, 'Linewidth', options.Linewidth);

% 3. Plot Spectrograms with Beat Overlay from Files
axS2 = mlt.plot.SpectrogramsBeatsOverlayFromFiles(S, ...
    'colorbar', options.colorbar, ...
    'colormapName', options.colormapName, ...
    'maxColorPercentile', options.maxColorPercentile);

% Link axes for synchronized viewing
if ~isempty(axS) && ~isempty(axHB) && ~isempty(axS2)
    linkaxes([axS; axHB; axS2], 'x');
    linkaxes([axS; axS2], 'xy');
end

end