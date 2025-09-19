function Traces(data, which_indices)
% MLT.PLOT.TRACES - Plot heart beat and spectrogram data traces
%
%   MLT.PLOT.TRACES(DATA, WHICH_INDICES)
%
%   Plots the spectrogram, raw data, instantaneous firing rate, and amplitude
%   for selected entries in the data structure returned by
%   mlt.doc.getHeartBeatAndSpectrogram.
%
%   The upper 40% of the window is the spectrogram.
%   The lower 60% of the window has several axes with line plots:
%      - Raw data (from mlt.ppg.getRawData)
%      - Instantaneous firing rate (from heart beats data)
%      - Amplitude (from heart beats data)
%      - A blank plot for temperature (for future use)
%
%   Inputs:
%      DATA - The data structure returned by mlt.doc.getHeartBeatAndSpectrogram.
%      WHICH_INDICES - A vector of indices indicating which entries of the data
%          to plot. Each index corresponds to a column of plots.
%

arguments
    data (1,1) struct
    which_indices (1,:) {mustBeInteger, mustBePositive}
end

figure;

num_plots = numel(which_indices);
column_width = 0.9 / num_plots;
column_spacing = 0.1 / (num_plots + 1);

for i = 1:num_plots
    idx = which_indices(i);

    left_pos = (i-1) * (column_width + column_spacing) + column_spacing;

    % Spectrogram (top 40%)
    ax_spec = axes('Position', [left_pos, 0.60, column_width, 0.35]);
    axes(ax_spec); % Set the current axes for the plotting function
    spec_data = data.SpectrogramData{idx};

    % Call the existing, shared plotting function
    mlt.plot.Spectrogram(spec_data.spectrogram, spec_data.f, spec_data.ts, 'drawLabels', false);

    % Customize labels for this specific plot layout
    ylabel('Frequency (Hz)');
    set(ax_spec, 'xticklabel', []);

    if i == 1
        title(ax_spec, ['Subject: ' data.subject_local_identifier ', Record: ' data.recordType]);
    else
        title(ax_spec, ['Record ' num2str(idx)]);
    end

    % Bottom 60% for other plots (4 plots)
    plot_height = 0.55 / 4;

    % Raw Data
    ax_raw = axes('Position', [left_pos, 0.05 + 3*plot_height, column_width, plot_height*0.9]);
    hb_doc = data.HeartBeatDocs{idx};
    [d, t_raw] = mlt.ppg.getRawData(hb_doc.session, data.subject_local_identifier, data.recordType);
    plot_timeseries(ax_raw, t_raw, d, 'Raw Data', false);

    % Instantaneous Firing Rate
    ax_rate = axes('Position', [left_pos, 0.05 + 2*plot_height, column_width, plot_height*0.9]);
    hb_data = data.HeartBeatData{idx};
    valid_beats = hb_data([hb_data.valid]);
    if ~isempty(valid_beats)
        plot_timeseries(ax_rate, [valid_beats.onset], [valid_beats.instant_freq], 'Rate (Hz)', false, '.-');
    else
        axis(ax_rate, 'off');
    end

    % Amplitude
    ax_amp = axes('Position', [left_pos, 0.05 + 1*plot_height, column_width, plot_height*0.9]);
    if ~isempty(valid_beats) && isfield(valid_beats, 'amplitude')
        plot_timeseries(ax_amp, [valid_beats.onset], [valid_beats.amplitude], 'Amplitude', true, '.-');
    else
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
