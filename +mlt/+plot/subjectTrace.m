function [ax, data] = subjectTrace(S, subject_name, record_type, options)
%SUBJECTTRACE Plots a detailed summary trace for a single subject and record.
%
%   [AX, DATA] = mlt.plot.subjectTrace(S, subject_name, record_type, ...)
%
%   Generates a comprehensive multi-panel plot for a single recording from a
%   specific subject. It loads the raw data, pre-calculated spectrogram, and
%   heart beat data and visualizes them together.
%
%   The layout consists of:
%   - Panel 1 (Top, 25%): Spectrogram.
%   - Panel 2: Raw data trace.
%   - Panel 3: Normalized (z-scored) data trace.
%   - Panels 4-6: Beat instantaneous frequency, amplitude, and duty cycle.
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
%       zscoreWindowTime (1,1) double = 3600
%           The time window in seconds for the moving z-score calculation on the raw data.
%       showBeats (1,1) logical = false
%           If true, overlays beat onset (blue circles) and offset (red 'x') markers
%           on the raw and normalized data plots.
%       markBeats (1,1) logical = false
%           If true, displays buttons to interactively mark bad and missing beats.
%           Instructions:
%           - Bad: Click near detected beats to mark them as bad (gray 'X').
%           - Missing: Click to add new, missing beats (green '+').
%           - Save: Saves the curated beat list to a .mat file.
%           A dialog will appear with instructions. Press Enter after you are done clicking.
%       Linewidth (1,1) double = 1.5
%           Line width for the time-series plots.
%       colorbar (1,1) logical = false
%           Set to true to display a color bar for each spectrogram.
%       maxColorPercentile (1,1) double = 99
%           The percentile of the data to use for the color scale maximum.
%       colormapName (1,:) char = 'parula'
%           The name of the colormap to use.
%
%   Outputs:
%       ax   - A struct containing the handles to the subplot axes.
%       data - The data structure (either passed in or loaded).
%
%   Example:
%       % Interactively mark beats
%       [ax, data] = mlt.plot.subjectTrace(mySession, 'SubjectA', 'heart', 'markBeats', true);
%
%   See also mlt.doc.getHeartBeatAndSpectrogram, mlt.ppg.getRawData, mlt.util.movzscore

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','gastric','pylorus'})}
    options.data (1,1) struct = struct()
    options.zscoreWindowTime (1,1) double {mustBeNonnegative} = 3600
    options.showBeats (1,1) logical = false
    options.markBeats (1,1) logical = false
    options.Linewidth (1,1) double {mustBePositive} = 1.5
    options.colorbar (1,1) logical = false
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'
    options.ylimSpectrogram (1,2) double = [0 5];
end

% --- Step 1: Load or Fetch Data ---
if isempty(fieldnames(options.data))
    disp('Fetching HeartBeat and Spectrogram data...');
    data = mlt.doc.getHeartBeatAndSpectrogram(S, subject_name, record_type);
else
    disp('Using pre-fetched data structure.');
    data = options.data;
end

S = data.session; % Use the session from the data struct for consistency

% --- Step 2: Load Raw and Processed Data ---
disp('Loading raw and processed data...');
[raw_data, raw_time] = mlt.ppg.getRawData(S, subject_name, record_type);

% Calculate normalized data
t_seconds = seconds(raw_time - raw_time(1));
normalized_data = mlt.util.movzscore(raw_data, options.zscoreWindowTime, 'SamplePoints', t_seconds);

% --- Step 3: Prepare Data for Plotting ---
disp('Preparing data for plotting...');
spec_data = data.SpectrogramData{1};
spec = spec_data.spec;
f = spec_data.f;
ts_spec = spec_data.ts;

beats = data.HeartBeatData{1};
beats_valid = beats(logical([beats.valid]));
onset_times = [beats_valid.onset];

% --- Step 4: Create Plots ---
disp('Generating plots...');
fig = figure('Position', [100 100 1200 900]);

% Layout: 6 panels. Spectrogram top 25% (2/8), 5 traces bottom 75% (5/8 + space)
ax.Spectrogram = subplot(8,1,1:2);
ax.RawData = subplot(8,1,3);
ax.NormalizedData = subplot(8,1,4);
ax.BeatInstFreq = subplot(8,1,5);
ax.Amplitude = subplot(8,1,6);
ax.DutyCycle = subplot(8,1,7:8);

% PLOT 1: Spectrogram
subplot(ax.Spectrogram);
if isdatetime(ts_spec)
    mlt.plot.Spectrogram(spec, f, ts_spec, ...
        'colorbar', options.colorbar, 'maxColorPercentile', options.maxColorPercentile, ...
        'colormapName', options.colormapName, 'ylim', options.ylimSpectrogram);
    title_str = sprintf('Subject: %s, Record: %s', data.subject_local_identifier, data.recordType);
    title(title_str, 'Interpreter', 'none');
    grid on; box off;
end

% PLOT 2: Raw Data
subplot(ax.RawData);
if isdatetime(raw_time)
    plot(raw_time, raw_data, 'k-', 'LineWidth', 1);
    ylabel('Raw Data');
    grid on; box off;
end

% PLOT 3: Normalized Data
subplot(ax.NormalizedData);
if isdatetime(raw_time)
    plot(raw_time, normalized_data, 'k-', 'LineWidth', 1);
    ylabel({'Normalized', '(z-score)'});
    grid on; box off;
end

% PLOT 4-6: Beat-related data
if ~isempty(onset_times) && isdatetime(onset_times)
    subplot(ax.BeatInstFreq);
    plot(onset_times, [beats_valid.instant_freq], 'r-', 'LineWidth', options.Linewidth);
    ylabel({'Beat Inst Freq', '(Hz)'});
    grid on; box off;

    subplot(ax.Amplitude);
    plot(onset_times, [beats_valid.amplitude], 'b-', 'LineWidth', options.Linewidth);
    ylabel('Amplitude');
    grid on; box off;

    subplot(ax.DutyCycle);
    plot(onset_times, [beats_valid.duty_cycle], 'g-', 'LineWidth', options.Linewidth);
    ylabel('Duty Cycle');
    grid on; box off;
end

xlabel('Time');

% --- Step 5: Overlay Beat Markers if requested ---
if options.showBeats && ~isempty(onset_times) && isdatetime(onset_times)
    beat_onsets = [beats_valid.onset];
    beat_offsets = [beats_valid.offset];
    y_onsets_raw = interp1(raw_time, raw_data, beat_onsets, 'linear', 'extrap');
    y_offsets_raw = interp1(raw_time, raw_data, beat_offsets, 'linear', 'extrap');
    y_onsets_norm = interp1(raw_time, normalized_data, beat_onsets, 'linear', 'extrap');
    y_offsets_norm = interp1(raw_time, normalized_data, beat_offsets, 'linear', 'extrap');

    hold(ax.RawData, 'on');
    plot(ax.RawData, beat_onsets, y_onsets_raw, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
    plot(ax.RawData, beat_offsets, y_offsets_raw, 'rx', 'MarkerSize', 5);
    hold(ax.RawData, 'off');

    hold(ax.NormalizedData, 'on');
    plot(ax.NormalizedData, beat_onsets, y_onsets_norm, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
    plot(ax.NormalizedData, beat_offsets, y_offsets_norm, 'rx', 'MarkerSize', 5);
    hold(ax.NormalizedData, 'off');
end

% --- Step 6: Interactive Beat Marking ---
if options.markBeats
    % Store data for callbacks
    beat_marking_data.beats = beats_valid;
    beat_marking_data.markedBad = datetime.empty(0,1);
    beat_marking_data.markedMissing = datetime.empty(0,1);
    beat_marking_data.axNorm = ax.NormalizedData;
    beat_marking_data.axRaw = ax.RawData;
    beat_marking_data.normalized_data = normalized_data;
    beat_marking_data.raw_data = raw_data;
    beat_marking_data.raw_time = raw_time;

    % Pre-plot empty marker series and store handles
    hold(ax.RawData, 'on');
    beat_marking_data.h_bad_raw = plot(ax.RawData, NaT, NaN, 'x', 'MarkerSize', 15, 'MarkerEdgeColor', [0.5 0.5 0.5], 'LineWidth', 2);
    beat_marking_data.h_missing_raw = plot(ax.RawData, NaT, NaN, '+', 'MarkerSize', 15, 'MarkerEdgeColor', 'g', 'LineWidth', 2);
    hold(ax.RawData, 'off');

    hold(ax.NormalizedData, 'on');
    beat_marking_data.h_bad_norm = plot(ax.NormalizedData, NaT, NaN, 'x', 'MarkerSize', 15, 'MarkerEdgeColor', [0.5 0.5 0.5], 'LineWidth', 2);
    beat_marking_data.h_missing_norm = plot(ax.NormalizedData, NaT, NaN, '+', 'MarkerSize', 15, 'MarkerEdgeColor', 'g', 'LineWidth', 2);
    hold(ax.NormalizedData, 'off');

    set(fig, 'UserData', beat_marking_data);

    % Create buttons
    pos = get(ax.NormalizedData, 'Position');
    btn_y = pos(2) - 0.06;
    btn_w = 0.1;
    btn_h = 0.04;
    btn_x_start = pos(1) + pos(3)/2 - 1.5*btn_w;

    uicontrol('Style', 'pushbutton', 'String', 'Bad', 'Units', 'normalized', ...
        'Position', [btn_x_start, btn_y, btn_w, btn_h], 'Callback', @markBadCallback);
    uicontrol('Style', 'pushbutton', 'String', 'Missing', 'Units', 'normalized', ...
        'Position', [btn_x_start + btn_w, btn_y, btn_w, btn_h], 'Callback', @markMissingCallback);
    uicontrol('Style', 'pushbutton', 'String', 'Save', 'Units', 'normalized', ...
        'Position', [btn_x_start + 2*btn_w, btn_y, btn_w, btn_h], 'Callback', @saveCallback);
end


% --- Step 7: Finalize Axes ---
all_axes = [ax.Spectrogram, ax.RawData, ax.NormalizedData, ax.BeatInstFreq, ax.Amplitude, ax.DutyCycle];
all_times_cell = {};
if isdatetime(raw_time) && ~isempty(raw_time), all_times_cell{end+1} = raw_time(:); end
if isdatetime(ts_spec) && ~isempty(ts_spec), all_times_cell{end+1} = ts_spec(:); end

master_xlim = [];
if ~isempty(all_times_cell)
    all_times = vertcat(all_times_cell{:});
    if ~isempty(all_times)
        min_t = min(all_times); max_t = max(all_times);
        if min_t == max_t, max_t = min_t + seconds(1); end
        master_xlim = [min_t max_t];
    end
end

if ~isempty(master_xlim)
    for i = 1:numel(all_axes), xlim(all_axes(i), master_xlim); end
end

linkaxes(all_axes, 'x');
if ~isempty(master_xlim), xlim(ax.Spectrogram, master_xlim); end

disp('Plot generation complete.');

end

% --- Callback Functions for Interactive Marking ---
function markBadCallback(hObject, ~)
    fig = ancestor(hObject, 'figure');
    data = get(fig, 'UserData');

    msgbox('Click near bad beats. Press Enter when done.', 'Mark Bad Beats', 'modal');

    while true
        figure(fig);
        axes(data.axNorm);
        [x, ~, button] = ginput(1); % Changed from [x, y, ~]
        if isempty(x) || isempty(button)
            break;
        end

        clicked_time = datetime(x, 'ConvertFrom', 'datenum');
        [~, idx] = min(abs(data.beats.onset - clicked_time));
        marked_time = data.beats.onset(idx);

        if ~ismember(marked_time, data.markedBad)
            data.markedBad = [data.markedBad; marked_time];

            y_norm = interp1(data.raw_time, data.normalized_data, marked_time);
            set(data.h_bad_norm, 'XData', [get(data.h_bad_norm, 'XData') marked_time], 'YData', [get(data.h_bad_norm, 'YData') y_norm]);

            y_raw = interp1(data.raw_time, data.raw_data, marked_time);
            set(data.h_bad_raw, 'XData', [get(data.h_bad_raw, 'XData') marked_time], 'YData', [get(data.h_bad_raw, 'YData') y_raw]);

            disp(['Marked bad beat at ' datestr(marked_time) '. Y-norm: ' num2str(y_norm)]);
            drawnow;
        end
    end

    set(fig, 'UserData', data);
    disp('Finished marking bad beats.');
end

function markMissingCallback(hObject, ~)
    fig = ancestor(hObject, 'figure');
    data = get(fig, 'UserData');

    msgbox('Click to add missing beats. Press Enter when done.', 'Mark Missing Beats', 'modal');

    while true
        figure(fig);
        axes(data.axNorm);
        [x, ~, button] = ginput(1);
        if isempty(x) || isempty(button)
            break;
        end

        clicked_time = datetime(x, 'ConvertFrom', 'datenum');
        data.markedMissing = [data.markedMissing; clicked_time];

        % Interpolate y-value for both plots
        y_norm = interp1(data.raw_time, data.normalized_data, clicked_time);
        y_raw = interp1(data.raw_time, data.raw_data, clicked_time);

        % Update normalized plot
        set(data.h_missing_norm, 'XData', [get(data.h_missing_norm, 'XData') clicked_time], 'YData', [get(data.h_missing_norm, 'YData') y_norm]);

        % Update raw plot
        set(data.h_missing_raw, 'XData', [get(data.h_missing_raw, 'XData') clicked_time], 'YData', [get(data.h_missing_raw, 'YData') y_raw]);

        disp(['Marked missing beat at ' datestr(clicked_time) '. Y-norm: ' num2str(y_norm)]);
        drawnow;
    end

    set(fig, 'UserData', data);
    disp('Finished marking missing beats.');
end

function saveCallback(hObject, ~)
    fig = ancestor(hObject, 'figure');
    data = get(fig, 'UserData');

    % Create table
    all_onsets = [data.beats.onset]';
    status = repmat({'detected'}, numel(all_onsets), 1);

    if ~isempty(data.markedBad)
        [~, bad_indices] = ismember(data.markedBad, all_onsets);
        bad_indices(bad_indices==0) = []; % remove not found
        status(bad_indices) = {'marked bad'};
    end

    T = table(all_onsets, status, 'VariableNames', {'Time', 'Status'});

    if ~isempty(data.markedMissing)
        missing_times = data.markedMissing(:); % Ensure column vector
        missing_status = repmat({'marked missing'}, numel(missing_times), 1);
        missing_table = table(missing_times, missing_status, 'VariableNames', {'Time', 'Status'});
        T = [T; missing_table];
    end

    T = sortrows(T, 'Time');

    [file, path] = uiputfile('*.mat', 'Save Curated Beats');
    if isequal(file,0) || isequal(path,0)
       disp('Save cancelled.');
    else
       full_path = fullfile(path, file);
       save(full_path, 'T');
       disp(['Saved curated beats to ' full_path]);
    end
end