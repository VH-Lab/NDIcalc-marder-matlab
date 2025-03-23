function gracePlotAll(S,options)
% GRACEPLOTALL - Plot all of Grace's summary data for an NDI session/dataset.
%
%   GRACEPLOTALL(S) generates a comprehensive set of plots summarizing
%   photoplethysmogram (PPG) data from an ndi.session or ndi.dataset object S.
%   It creates three sets of plots:
%       1. Spectrograms of the PPG data.
%       2. Heartbeat statistics plots (raw PPG, frequency, duty cycle).
%       3. Spectrograms with overlaid heartbeat events.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object containing the PPG data.
%
%   Options:
%       options.colorbar (1,1) logical = false;
%           Whether to display colorbars for the spectrogram plots.
%           Default: false
%
%       options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula';
%           The colormap to use for the spectrogram plots.
%           Default: 'parula'
%
%       options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99;
%           The percentile of the spectrogram data to use as the maximum
%           value for the color scale (for contrast enhancement).
%           Default: 99
%
%       options.heartBeatLineWidth (1,1) double = 1;
%           The line width to use for the heartbeat statistics plots (PPG
%           signal, beat frequency, and duty cycle).
%           Default: 1
%
%   Details:
%       This function calls three other functions to generate the plots:
%           1. `mlt.graceSpectrogramsPlot`: Generates the basic spectrograms.
%           2. `mlt.graceHeartBeatPlot`: Generates the heartbeat statistics plots.
%           3. `mlt.graceSpectrogramsBeatOverlayPlot`: Generates spectrograms
%              with heartbeat events overlaid.
%
%       The function then links the x-axes of all generated plots using
%       `linkaxes`. This ensures that zooming and panning in any plot will
%       synchronize the view across all plots.
%       
%       Each called function creates figures independently, and those are
%       preserved.
%
%   Example 1: Basic Usage (all default options)
%       gracePlotAll(mySession);
%
%   Example 2: Customizing Options
%       options.colorbar = true;
%       options.colormapName = 'jet';
%       options.maxColorPercentile = 95;
%       options.heartBeatLineWidth = 2;
%       gracePlotAll(mySession, options);
%
%   Example 3: Name-value pair inputs
%       gracePlotAll(mySession, 'colorbar', true, 'colormapName', 'hot', ...
%                    'maxColorPercentile', 90, 'heartBeatLineWidth', 1.5);
%
%   See also: graceSpectrogramsPlot, graceHeartBeatPlot,
%             graceSpectrogramsBeatOverlayPlot, linkaxes

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.colorbar (1,1) logical = false;
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula';
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99;
    options.heartBeatLineWidth (1,1) double = 1;
end

axS = mlt.graceSpectrogramsPlot(S, ...
    'colorbar', options.colorbar, ...
    'colormapName', options.colormapName, ...
    'maxColorPercentile', options.maxColorPercentile);

axHB = mlt.graceHeartBeatPlot(S, 'Linewidth', options.heartBeatLineWidth);

axS2 = mlt.graceSpectrogramsBeatOverlayPlot(S, ...
    'colorbar', options.colorbar, ...
    'colormapName', options.colormapName, ...
    'maxColorPercentile', options.maxColorPercentile);

linkaxes(cat(1,axS,axHB,axS2),'x');
linkaxes(cat(1,axS,axS2),'xy');

end
