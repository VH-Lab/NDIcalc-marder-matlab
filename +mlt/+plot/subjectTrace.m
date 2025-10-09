function [ax, data] = subjectTrace(S, subject_name, record_type, options)
%SUBJECTTRACE Plots a detailed summary trace for a single subject and record.
%
%   [AX, DATA] = mlt.plot.subjectTrace(S, subject_name, record_type)
%
%   Generates a comprehensive 5-panel plot for a single recording from a
%   specific subject. It loads the raw data, pre-calculated spectrogram, and
%   heart beat data and visualizes them together.
%
%   The layout consists of:
%   - Panel 1 (Top): Spectrogram.
%   - Panel 2: Raw data trace.
%   - Panels 3-5: Beat instantaneous frequency, amplitude, and duty cycle.
%
%   All plot axes are linked horizontally for synchronized zooming and panning.
%
%   Inputs:
%       S             - An ndi.session or ndi.dataset object.
%       subject_name  - The name of the subject (e.g., 'SubjectA').
%       record_type   - The type of record ('heart', 'gastric', or 'pylorus').
%
%   Optional Name-Value Pair Arguments:
%       data (1,1) struct = struct()
%           A pre-fetched data structure from mlt.doc.getHeartBeatAndSpectrogram.
%           If provided, the function will not re-load the data.
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
%       ax   - A struct containing the handles to the subplot axes.
%       data - The data structure (either passed in or loaded).
%
%   Example:
%       % Plot a summary for Subject A's heart recording
%       [ax, data] = mlt.plot.subjectTrace(mySession, 'SubjectA', 'heart');
%
%   See also mlt.doc.getHeartBeatAndSpectrogram, mlt.plot.Spectrogram

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','gastric','pylorus'})}
    options.data (1,1) struct = struct()
    options.Linewidth (1,1) double {mustBePositive} = 1.5
    options.colorbar (1,1) logical = false
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'
    options.ylimSpectrogram (1,2) double = [0 5];
end

% --- Step 1: Load or Fetch Data ---
if isempty(fieldnames(options.data))
    disp('Fetching data using getHeartBeatAndSpectrogram...');
    data = mlt.doc.getHeartBeatAndSpectrogram(S, subject_name, record_type);
else
    disp('Using pre-fetched data structure.');
    data = options.data;
end

S = data.session; % Use the session from the data struct for consistency

% --- Step 2: Find the element for raw data ---
disp('Finding element for raw data...');
e = mlt.ndi.getElement(S, data.subject_local_identifier, data.recordType,'lp_whole');
if isempty(e)
    error('Could not find a unique element for subject "%s" and record type "%s".', data.subject_local_identifier, data.recordType);
end

et = e.epochtable();
if isempty(et)
    error('Element %s has no epoch table.', e.elementstring);
end
epoch_id = et(1).epoch_id;
t0_utc = et(1).t0_t1{1};

% --- Step 3: Load Raw Data ---
disp('Loading raw data...');
[raw_data, raw_time] = e.readtimeseries(epoch_id, -Inf, Inf);
raw_time = t0_utc + seconds(raw_time); % Convert to datetime

% --- Step 4: Prepare Data for Plotting ---
disp('Preparing data for plotting...');

% Extract from data structure
spec_data = data.SpectrogramData{1};
spec = spec_data.spectrogram;
f = spec_data.f;
ts_spec = t0_utc + seconds(spec_data.t); % Convert to datetime

beats = data.HeartBeatData{1};
beats_valid = beats(logical([beats.valid]));
onset_times = t0_utc + seconds([beats_valid.onset]); % Convert to datetime

% --- Step 5: Create Plots ---
disp('Generating plots...');
figure('Position', [100 100 1200 900]); % Create a larger figure window

% Using a 8-row grid for 5 plots
% - Spectrogram: 1-4
% - Raw Data: 5
% - Beat Freq: 6
% - Amplitude: 7
% - Duty Cycle: 8

% PLOT 1: Spectrogram
ax.Spectrogram = subplot(8,1,1:4);
mlt.plot.Spectrogram(spec, f, ts_spec, ...
    'colorbar', options.colorbar, ...
    'maxColorPercentile', options.maxColorPercentile, ...
    'colormapName', options.colormapName, ...
    'ylim', options.ylimSpectrogram);
title_str = sprintf('Subject: %s, Record: %s', data.subject_local_identifier, data.recordType);
title(title_str, 'Interpreter', 'none');
grid on;

% PLOT 2: Raw Data
ax.RawData = subplot(8,1,5);
plot(raw_time, raw_data, 'k-', 'LineWidth', 1);
ylabel('Raw Data');
grid on;

% PLOT 3: Beat Inst Freq
ax.BeatInstFreq = subplot(8,1,6);
plot(onset_times, [beats_valid.instant_freq], 'r-', 'LineWidth', options.Linewidth);
ylabel({'Beat Inst Freq', '(Hz)'});
grid on;

% PLOT 4: Beat Amplitude
ax.Amplitude = subplot(8,1,7);
plot(onset_times, [beats_valid.amplitude], 'b-', 'LineWidth', options.Linewidth);
ylabel('Amplitude');
grid on;

% PLOT 5: Duty Cycle
ax.DutyCycle = subplot(8,1,8);
plot(onset_times, [beats_valid.duty_cycle], 'g-', 'LineWidth', options.Linewidth);
ylabel('Duty Cycle');
grid on;

xlabel('Time');
grid on;

% Link all axes horizontally
linkaxes([ax.Spectrogram, ax.RawData, ax.BeatInstFreq, ax.Amplitude, ax.DutyCycle], 'x');

% Set a reasonable x-limit to start, using datetime
if ~isempty(onset_times)
    xlim(ax.Spectrogram, [onset_times(1), onset_times(end)]);
else
    if ~isempty(ts_spec)
        xlim(ax.Spectrogram, [ts_spec(1), ts_spec(end)]);
    end
end
disp('Plot generation complete.');

end