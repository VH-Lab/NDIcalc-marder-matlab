function Traces(data, time_intervals)
% MLT.PLOT.TRACES - Plot heart beat and spectrogram data traces for specific time intervals.
%
%   MLT.PLOT.TRACES(DATA, TIME_INTERVALS)
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

arguments
    data (1,:) struct
    time_intervals (:,2) datetime
end

figure;

num_plots = size(time_intervals, 1);
column_width = 0.9 / num_plots;
column_spacing = 0.1 / (num_plots + 1);

for i = 1:num_plots
    t0 = time_intervals(i, 1);
    t1 = time_intervals(i, 2);

    found_interval = false;
    data_struct_found = [];
    idx_found = -1;

    % Search for the data entry that contains the time interval
    for data_idx = 1:numel(data)
        current_data = data(data_idx);
        for spec_idx = 1:numel(current_data.SpectrogramData)
            spec_data = current_data.SpectrogramData{spec_idx};

            % Assuming spec_data.ts are datetime objects for comparison
            if isdatetime(spec_data.ts) && ~isempty(spec_data.ts)
                interval_start = spec_data.ts(1);
                interval_end = spec_data.ts(end);

                if t0 >= interval_start && t1 <= interval_end
                    found_interval = true;
                    data_struct_found = current_data;
                    idx_found = spec_idx;
                    break;
                end
            end
        end
        if found_interval
            break;
        end
    end

    if ~found_interval
        error('Could not find any data record containing the time interval [%s, %s].', string(t0), string(t1));
    end

    % Plotting
    left_pos = (i-1) * (column_width + column_spacing) + column_spacing;

    % Spectrogram (top 40%)
    ax_spec = axes('Position', [left_pos, 0.60, column_width, 0.35]);
    spec_data = data_struct_found.SpectrogramData{idx_found};
    time_mask = spec_data.ts >= t0 & spec_data.ts <= t1;
    mlt.plot.Spectrogram(spec_data.spec(:, time_mask), spec_data.f, spec_data.ts(time_mask), 'drawLabels', false);
    xlim([t0, t1]);
    ylabel('Frequency (Hz)');
    set(ax_spec, 'xticklabel', []);
    title_str = sprintf('Subject: %s, Record: %s, Interval %d', ...
        data_struct_found.subject_local_identifier, data_struct_found.recordType, i);
    title(ax_spec, title_str);

    % Bottom 60% for other plots (4 plots)
    plot_height = 0.55 / 4;

    % Raw Data
    ax_raw = axes('Position', [left_pos, 0.05 + 3*plot_height, column_width, plot_height*0.9]);
    S_found = data_struct_found.session;
    [d, t_raw] = mlt.ppg.getRawData(S_found, data_struct_found.subject_local_identifier, data_struct_found.recordType);
    if isdatetime(t_raw)
        raw_mask = t_raw >= t0 & t_raw <= t1;
        plot_timeseries(ax_raw, t_raw(raw_mask), d(raw_mask), 'Raw Data', false);
        xlim(ax_raw, [t0, t1]);
    else
        axis(ax_raw, 'off');
    end

    % Instantaneous Firing Rate & Amplitude
    ax_rate = axes('Position', [left_pos, 0.05 + 2*plot_height, column_width, plot_height*0.9]);
    ax_amp = axes('Position', [left_pos, 0.05 + 1*plot_height, column_width, plot_height*0.9]);
    hb_data = data_struct_found.HeartBeatData{idx_found};
    valid_beats = hb_data(logical([hb_data.valid]));

    if ~isempty(valid_beats) && isdatetime([valid_beats.onset])
        beat_onsets = [valid_beats.onset];
        beat_mask = beat_onsets >= t0 & beat_onsets <= t1;
        beats_in_interval = valid_beats(beat_mask);

        if ~isempty(beats_in_interval)
            plot_timeseries(ax_rate, [beats_in_interval.onset], [beats_in_interval.instant_freq], 'Rate (Hz)', false, '.-');
            xlim(ax_rate, [t0, t1]);

            if isfield(beats_in_interval, 'amplitude')
                plot_timeseries(ax_amp, [beats_in_interval.onset], [beats_in_interval.amplitude], 'Amplitude', true, '.-');
                xlim(ax_amp, [t0, t1]);
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

    % Temperature (blank)
    ax_temp = axes('Position', [left_pos, 0.05 + 0*plot_height, column_width, plot_height*0.9]);
    axis(ax_temp, 'off');
    text(ax_temp, 0.5, 0.5, 'Temperature (Future)', 'HorizontalAlignment', 'center');

    column_axes = [ax_spec, ax_raw, ax_rate, ax_amp];
    linkaxes(column_axes, 'x');
end

end

function plot_timeseries(ax, t, d, ylabel_str, show_xlabel, plot_style)
    if nargin < 6
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
    ylabel(ylabel_str);
    box off;

    if show_xlabel
        xlabel(xlabel_str);
    else
        set(ax,'xticklabel',[]);
    end
end
