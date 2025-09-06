function ax = subjectTrace(S, subject_name, record_type, options)
%SUBJECTTRACE Plots a detailed summary trace for a single subject and record.
%
%   AX = mlt.plot.subjectTrace(S, subject_name, record_type)
%
%   Generates a comprehensive 4-panel plot for a single recording from a
%   specific subject. It loads the pre-calculated spectrogram and heart beat
%   data from their respective NDI documents and visualizes them together.
%
%   The layout consists of:
%   - Top Panel (50%): Spectrogram.
%   - Bottom Panels: Three plots showing beat instantaneous frequency, 
%     amplitude, and duty cycle over time.
%
%   All four plot axes are linked horizontally for synchronized zooming and panning.
%
%   Inputs:
%       S             - An ndi.session or ndi.dataset object.
%       subject_name  - The name of the subject (e.g., 'SubjectA').
%       record_type   - The type of record ('heart', 'gastric', or 'pylorus').
%
%   Optional Name-Value Pair Arguments:
%       Linewidth (1,1) double = 1.5
%           Line width for the time-series plots.
%       colorbar (1,1) logical = false
%           Set to true to display a color bar for each spectrogram.
%       maxColorPercentile (1,1) double = 99
%           The percentile of the data to use as the maximum value for the
%           color scale, clipping extreme values. Must be between 0 and 100.
%       colormapName (1,:) char = 'parula'
%           The name of the colormap to use (e.g., 'jet', 'hot', 'gray').
%
%   Outputs:
%       ax - A struct containing the handles to the four subplot axes.
%
%   Example:
%       % Plot a summary for Subject A's heart recording
%       ax = mlt.plot.subjectTrace(mySession, 'SubjectA', 'heart');
%
%   See also mlt.ndi.getElement, mlt.spectrogram.readTimeWindow, mlt.beats.beatsdoc2struct

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','gastric','pylorus'})}
    options.Linewidth (1,1) double {mustBePositive} = 1.5
    options.colorbar (1,1) logical = false
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'
end

% --- Step 1: Find the element ---
disp('Finding element...');
e = mlt.ndi.getElement(S, subject_name, record_type,'lp_whole');
if isempty(e)
    error('Could not find a unique element for subject "%s" and record type "%s".', subject_name, record_type);
end

et = e.epochtable();
if isempty(et)
    error('Element %s has no epoch table.', e.elementstring);
end
epoch_id = et(1).epoch_id;

% --- Step 2: Load Spectrogram and Beats Documents ---
disp('Loading data from NDI documents...');
% Load Spectrogram
spec_doc = ndi.database.fun.finddocs_elementEpochType(S, e.id(), epoch_id, 'spectrogram');
if isempty(spec_doc), error('Could not find spectrogram document for %s.', e.elementstring); end
spec_doc = spec_doc{1};
% Load spectrogram, timestamps, and frequencies from document
ngrid = spec_doc.document_properties.ngrid;
specProp = spec_doc.document_properties.spectrogram;
specDoc = database_openbinarydoc(S, spec_doc, 'spectrogram_results.ngrid');
spec = ndi.fun.data.readngrid(specDoc,ngrid.data_dim,ngrid.data_type);
database_closebinarydoc(S, specDoc);

freqCoords = ngrid.data_dim(specProp.frequency_ngrid_dim);
timeCoords = ngrid.data_dim(specProp.timestamp_ngrid_dim);
f = ngrid.coordinates(1:freqCoords);
ts_spec = ngrid.coordinates(freqCoords + (1:timeCoords));

% Load Beats
beats_doc = ndi.database.fun.finddocs_elementEpochType(S, e.id(), epoch_id, 'ppg_beats');
if isempty(beats_doc), error('Could not find ppg_beats document for %s.', e.elementstring); end
beats = mlt.beats.beatsdoc2struct(S, beats_doc{1});

% --- Step 3: Prepare Data for Plotting ---
disp('Preparing data for plotting...');
beats_valid = beats(logical([beats.valid]));
onset_times = [beats_valid.onset];

if isa(onset_times(1),'datetime')
    % do nothing
    timeUnitsStr = '';
else
    onset_times = onset_times / 3600; % convert to hours
    timeUnitsStr = '(hours)';
end

% --- Step 4: Create Plots ---
disp('Generating plots...');
figure('Position', [100 100 1200 800]); % Create a larger figure window

% To make the top plot take up the top half and the bottom three take up the
% bottom half, we can use a 6-row subplot grid.
% Top plot will span rows 1-3. Bottom plots will be in rows 4, 5, and 6.

% PLOT 1: Spectrogram with Beat Frequency Overlay
ax.Spectrogram = subplot(6,1,1:3);
mlt.plot.Spectrogram(spec, f, ts_spec, ...
    'colorbar', options.colorbar, ...
    'maxColorPercentile', options.maxColorPercentile, ...
    'colormapName', options.colormapName);
hold on;
% % Use plot3 to overlay the frequency trace on top of the 2D image
% z_level = (max(spec(:))) * ones(size(onset_times)); % Ensure it's on top
% plot3(onset_times, [beats_valid.instant_freq], z_level, 'r-', 'LineWidth', options.Linewidth);
% hold off;
title_str = sprintf('Subject: %s, Record: %s', subject_name, record_type);
title(title_str, 'Interpreter', 'none');
grid on;

% PLOT 2: Beat Inst Freq
ax.BeatInstFreq = subplot(6,1,4);
plot(onset_times, [beats_valid.instant_freq], 'r-', 'LineWidth', options.Linewidth);
ylabel('Beat Instantaneous Frequency');
grid on;

% PLOT 3: Beat Amplitude
ax.Amplitude = subplot(6,1,5);
plot(onset_times, [beats_valid.amplitude], 'b-', 'LineWidth', options.Linewidth);
ylabel('Beat Amplitude');
grid on;

% PLOT 4: Duty Cycle
ax.DutyCycle = subplot(6,1,6);
plot(onset_times, [beats_valid.duty_cycle], 'g-', 'LineWidth', options.Linewidth);
ylabel('Duty Cycle');
grid on;

% % PLOT 4: Beat Duration
% ax.Duration = subplot(6,1,6);
% plot(onset_times, [beats_valid.up_duration], 'm-', 'LineWidth', options.Linewidth);
% ylabel('Beat Duration (s)');

xlabel(['Time' timeUnitsStr]);
grid on;

% Link all axes horizontally
linkaxes([ax.Spectrogram, ax.BeatInstFreq ax.Amplitude, ax.DutyCycle], 'x');

% Set a reasonable x-limit to start
if ~isempty(onset_times)
    xlim(ax.Spectrogram, [onset_times(1), onset_times(end)]);
end
disp('Plot generation complete.');

end

