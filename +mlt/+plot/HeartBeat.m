function ax = HeartBeat(beats, d, t, options)
%HEARTBEAT - Plot PPG signal and derived heart beat data in a new figure.
%
%   AX = mlt.plot.HeartBeat(BEATS, D, T)
%
%   Plots heart beat statistics derived from a photoplethysmogram (PPG).
%   It generates a new figure with three stacked and linked subplots:
%   1) The PPG signal with beat onsets/offsets marked.
%   2) The instantaneous beat frequency over time.
%   3) The duty cycle of each beat over time.
%
%   Inputs:
%       beats - A structure array containing heartbeat information. Each
%               element must have the following fields:
%               .onset      (double | datetime) Time of the heartbeat onset.
%               .offset     (double | datetime) Time of the heartbeat offset.
%               .valid      (logical) True if the beat is valid.
%               .instant_freq (double) Instantaneous frequency (Hz).
%               .duty_cycle (double) Duty cycle of the heartbeat.
%       d     - A column vector of the PPG signal data.
%       t     - A column vector of time values for the PPG data. This can
%               be numeric (in seconds) or a datetime vector. Note: If
%               numeric, the x-axis of the plot will be converted to hours.
%
%   Optional Name-Value Pairs:
%       Linewidth (1,1) double = 1
%           Specifies the line width for the frequency and duty cycle plots.
%
%   Outputs:
%       ax    - A 3x1 vector of axes handles for the three subplots
%               (PPG, beat frequency, duty cycle).
%
%   Example 1: Basic usage with numeric time vector
%       % Assuming 'beats', 'd', and 't' (in seconds) are defined:
%       ax = mlt.plot.HeartBeat(beats, d, t);
%
%   Example 2: Specifying a custom linewidth
%       ax = mlt.plot.HeartBeat(beats, d, t, 'Linewidth', 2);
%
%   See also PLOT, SUBPLOT, LINKAXES.

arguments
    beats (:,:) struct
    d (:,1) double
    t (:,1) {mustBeA(t,{'double','datetime'})}
    options.Linewidth (1,1) double = 1
end

figure;
good_beats = beats(logical([beats.valid]));

% --- Time handling for plotting ---
if isa(t, 'datetime')
    t_plot = t;
    onset_plot = [good_beats.onset];
    offset_plot = [good_beats.offset];
    time_unit_label = 'Time';
else
    % Convert seconds to hours for a more readable axis
    t_plot = t / 3600;
    onset_plot = [good_beats.onset] / 3600;
    offset_plot = [good_beats.offset] / 3600;
    time_unit_label = 'Time (hours)';
end

% --- Plot 1: Raw PPG Signal ---
ax1 = subplot(3,1,1);
plot(t_plot, d, 'LineWidth', options.Linewidth);
hold on;
plot(onset_plot, mean(d)*ones(size(onset_plot)), 'g^', 'MarkerFaceColor', 'g'); % Onsets
plot(offset_plot, mean(d)*ones(size(offset_plot)), 'rv', 'MarkerFaceColor', 'r'); % Offsets
hold off;
box off;
ylabel('PPG Signal');
legend('Signal', 'Onset', 'Offset', 'Location', 'northeast');
title('Heart Beat Analysis');

% --- Plot 2: Instantaneous Frequency ---
ax2 = subplot(3,1,2);
plot(onset_plot, [good_beats.instant_freq], '.-', 'LineWidth', options.Linewidth, 'MarkerSize', 10);
ylabel('Beat Frequency (Hz)');
box off;

% --- Plot 3: Duty Cycle ---
ax3 = subplot(3,1,3);
plot(onset_plot, [good_beats.duty_cycle], '.-', 'LineWidth', options.Linewidth, 'MarkerSize', 10);
xlabel(time_unit_label);
ylabel('Duty Cycle');
box off;

% --- Final Touches ---
linkaxes([ax1 ax2 ax3], 'x');
ax = [ax1; ax2; ax3];

end