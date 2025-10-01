function Traces(data, time_intervals, options)
% MLT.PLOT.TRACES - Plot heart beat and spectrogram data traces for specific time intervals.
%
%   MLT.PLOT.TRACES(DATA, TIME_INTERVALS, Name, Value)
%
%   Plots spectrogram, raw data, instantaneous firing rate, and amplitude for
%   specified time intervals. The function searches through an array of data
%   structures to find the appropriate record that contains the requested time
%   interval.
%
%   The upper 40% of the window is the spectrogram.
%   The lower 60% of the window has several axes with line plots:
%      - Raw data (from mlt.ppg.getRawData)
%      - Instantaneous firing rate (from heart beats data)
%      - Amplitude (from heart beats data)
%      - A blank plot for temperature (for future use)
%
%   Inputs:
%      DATA - An array of data structures returned by mlt.doc.getHeartBeatAndSpectrogram.
%      TIME_INTERVALS - An Nx2 matrix of datetime objects, where each row
%          represents a [t0, t1] interval to be plotted.
%
%   Name-Value Pairs:
%      'TitleInterpreter' - The interpreter for the plot titles ('none', 'tex', 'latex').
%                           Default is 'none'.
%      'timePrePostWindow' - The time in seconds to extend the data window
%                            before and after the specified interval.
%                            Default is 180 seconds.
%

arguments
    data (1,:) struct
    time_intervals (:,2) datetime
    options.TitleInterpreter (1,:) char {mustBeMember(options.TitleInterpreter, {'none', 'tex', 'latex'})} = 'none'
    options.timePrePostWindow (1,1) double = 180
end

figure;

% HORIZONTAL LAYOUT
num_plots = size(time_intervals, 1);
column_width = 0.75 / num_plots;
column_spacing = 0.25 / (num_plots + 1);

% VERTICAL LAYOUT
top_margin = 0.10;
bottom_margin = 0.05;
spectrogram_height = 0.35;
total_plot_height = 1 - top_margin - bottom_margin;
other_plots_total_height = total_plot_height - spectrogram_height;
spectrogram_y_pos = bottom_margin + other_plots_total_height;
plot_height = other_plots_total_height / 3;
plot_y_base = bottom_margin;

all_ax_raw = cell(1, num_plots);
all_ax_rate = cell(1, num_plots);
all_ax_amp = cell(1, num_plots);

for i = 1:num_plots
    t0 = time_intervals(i, 1);
    t1 = time_intervals(i, 2);

    t0_window = t0 - seconds(options.timePrePostWindow);
    t1_window = t1 + seconds(options.timePrePostWindow);

    % Search for data records that overlap with the time interval
    overlapping_records = {};
    for data_idx = 1:numel(data)
        current_data = data(data_idx);
        for spec_idx = 1:numel(current_data.SpectrogramData)
            spec_data = current_data.SpectrogramData{spec_idx};

            if isdatetime(spec_data.ts) && ~isempty(spec_data.ts)
                interval_start = spec_data.ts(1);
                interval_end = spec_data.ts(end);

                % Check for overlap
                if t0_window <= interval_end && t1_window >= interval_start
                    overlapping_records{end+1} = {current_data, spec_idx};
                end
            end
        end
    end

    % Check the number of overlapping records found
    if isempty(overlapping_records)
        error('Could not find any data record containing the time interval [%s, %s].', string(t0), string(t1));
    elseif numel(overlapping_records) > 1
        error('The time interval [%s, %s] is ambiguous because it overlaps with %d data records.', ...
            string(t0), string(t1), numel(overlapping_records));
    end

    % Exactly one record found, proceed
    found_record = overlapping_records{1};
    data_struct_found = found_record{1};
    idx_found = found_record{2};

    % Plotting
    left_pos = (i-1) * (column_width + column_spacing) + column_spacing;

    % Spectrogram
    ax_spec = axes('Position', [left_pos, spectrogram_y_pos, column_width, spectrogram_height]);
    spec_data = data_struct_found.SpectrogramData{idx_found};

    % Find indices that bracket the requested time interval to avoid whitespace
    start_idx = find(spec_data.ts <= t0_window, 1, 'last');
    if isempty(start_idx)
        start_idx = 1;
    end

    end_idx = find(spec_data.ts >= t1_window, 1, 'first');
    if isempty(end_idx)
        end_idx = numel(spec_data.ts);
    end

    plot_indices = start_idx:end_idx;

    mlt.plot.Spectrogram(spec_data.spec(:, plot_indices), spec_data.f, spec_data.ts(plot_indices), 'drawLabels', false);
    if i == 1
        ylabel('Frequency (Hz)');
        title_lines = { ...
            data_struct_found.subject_local_identifier, ...
            sprintf('Record: %s', data_struct_found.recordType) ...
        };
        title(ax_spec, title_lines, 'Interpreter', options.TitleInterpreter);
    else
        set(ax_spec, 'yticklabel', []);
    end
    set(ax_spec, 'xticklabel', []);

    % Raw Data
    ax_raw = axes('Position', [left_pos, plot_y_base + 3*plot_height, column_width, plot_height*0.9]);
    S_found = data_struct_found.session;
    [d, t_raw] = mlt.ppg.getRawData(S_found, data_struct_found.subject_local_identifier, data_struct_found.recordType);
    if isdatetime(t_raw)
        raw_mask = t_raw >= t0_window & t_raw <= t1_window;
        plot_timeseries(ax_raw, t_raw(raw_mask), d(raw_mask), false);
        if i == 1
            ylabel(ax_raw, 'Raw Data');
        else
            set(ax_raw, 'yticklabel', []);
        end
        current_ylim = ylim(ax_raw);
        ylim(ax_raw, [0, current_ylim(2)]);
    else
        axis(ax_raw, 'off');
    end
    all_ax_raw{i} = ax_raw;

    % Instantaneous Firing Rate & Amplitude
    ax_rate = axes('Position', [left_pos, plot_y_base + 2*plot_height, column_width, plot_height*0.9]);
    ax_amp = axes('Position', [left_pos, plot_y_base + 1*plot_height, column_width, plot_height*0.9]);
    hb_data = data_struct_found.HeartBeatData{idx_found};
    valid_beats = hb_data(logical([hb_data.valid]));

    if ~isempty(valid_beats) && isdatetime([valid_beats.onset])
        beat_onsets = [valid_beats.onset];
        beat_mask = beat_onsets >= t0_window & beat_onsets <= t1_window;
        beats_in_interval = valid_beats(beat_mask);

        if ~isempty(beats_in_interval)
            plot_timeseries(ax_rate, [beats_in_interval.onset], [beats_in_interval.instant_freq], false, '.-');
            if i == 1
                ylabel(ax_rate, 'Rate (Hz)');
            else
                set(ax_rate, 'yticklabel', []);
            end
            current_ylim = ylim(ax_rate);
            ylim(ax_rate, [0, current_ylim(2)]);

            if isfield(beats_in_interval, 'amplitude')
                plot_timeseries(ax_amp, [beats_in_interval.onset], [beats_in_interval.amplitude], true, '.-');
                 if i == 1
                    ylabel(ax_amp, 'Amplitude');
                else
                    set(ax_amp, 'yticklabel', []);
                end
                current_ylim = ylim(ax_amp);
                ylim(ax_amp, [0, current_ylim(2)]);
            else
                axis(ax_amp, 'off');
            end
        else
            axis(ax_rate, 'off');
            axis(ax_amp, 'off');
        end
    else
        axis(ax_rate, 'off');
        axis(ax_amp, 'off');
    end
    all_ax_rate{i} = ax_rate;
    all_ax_amp{i} = ax_amp;


    column_axes = [ax_spec, ax_raw, ax_rate, ax_amp];
    linkaxes(column_axes, 'x');

    % Generate and apply regular ticks across the entire data window, then zoom
    if isgraphics(ax_amp, 'axes') && strcmp(get(ax_amp, 'Visible'), 'on')
        % Ticks every 10 seconds
        tick_times = t0_window:seconds(10):t1_window;

        % Labels every 20 seconds (every other tick)
        tick_labels = cell(size(tick_times));
        [tick_labels{:}] = deal(''); % Fill with empty strings
        for k = 1:2:numel(tick_times) % Label every second tick
            tick_labels{k} = datestr(tick_times(k), 'mm/dd/yy\nHH:MM:SS');
        end

        set(ax_amp, 'XTick', tick_times);
        set(ax_amp, 'XTickLabel', tick_labels);

        xlim(ax_amp, [t0, t1]); % Zoom after setting ticks
    end
end

% Link Y-axis limits across columns for each data type
valid_raw_axes = [all_ax_raw{:}];
if numel(valid_raw_axes) > 1, linkaxes(valid_raw_axes, 'y'); end

valid_rate_axes = [all_ax_rate{:}];
if numel(valid_rate_axes) > 1, linkaxes(valid_rate_axes, 'y'); end

valid_amp_axes = [all_ax_amp{:}];
if numel(valid_amp_axes) > 1, linkaxes(valid_amp_axes, 'y'); end

end

function plot_timeseries(ax, t, d, show_xlabel, plot_style)
    if nargin < 5
        plot_style = '-';
    end
    axes(ax);

    if isa(t, 'datetime')
        t_plot = t;
        xlabel_str = 'Time';
    else
        t_plot = t / 3600; % convert seconds to hours
        xlabel_str = 'Time (hours)';
    end

    plot(t_plot, d, plot_style);
    box off;

    if show_xlabel
        xlabel(xlabel_str);
    else
        set(ax,'xticklabel',[]);
    end
end
