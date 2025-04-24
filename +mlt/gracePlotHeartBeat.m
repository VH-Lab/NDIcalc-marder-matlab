function ax = gracePlotHeartBeat(beats, d, t, options)
% GRACEPLOTHEARTBEATS - Plot heart beat data in a new figure
%
%   AX = GRACEPLOTHEARTBEAT(BEATS, D, T) plots heart beat statistics
%   derived from PPG (photoplethysmogram) data.  It generates a figure
%   with three subplots: the raw PPG signal, the instantaneous beat
%   frequency, and the duty cycle of the heartbeat.
%
%   Inputs:
%       BEATS - A structure array containing heartbeat information. Each
%               element of the array should represent a single heartbeat
%               and must include the following fields:
%               .onset      - Time of the heartbeat onset.
%               .offset     - Time of the heartbeat offset.
%               .valid      - Logical (true/false) indicating if the beat
%                             is valid.
%               .instant_freq - Instantaneous frequency of the heartbeat
%                             (in Hz).
%               .duty_cycle - Duty cycle of the heartbeat.
%       D     - A numeric vector containing the raw PPG signal data.  The
%               length of D should match the length of T.
%       T     - A numeric vector (in seconds) or a datetime vector
%               representing the time corresponding to the PPG data in D.
%
%   Optional Input:
%       options.Linewidth - Scalar numeric value specifying the linewidth
%                           of the plotted lines (PPG, frequency, and duty
%                           cycle).
%                           Default: 1
%
%   Outputs:
%       AX    - A 3x1 vector of axes handles corresponding to the three
%               subplots (PPG, beat frequency, duty cycle).
%
%   Example 1: Basic usage with numeric time vector (seconds)
%       % Assuming 'beats', 'd', and 't' are already defined:
%       ax = gracePlotHeartBeat(beats, d, t);
%
%   Example 2: Using a datetime vector for time
%       % Assuming 'beats', 'd', and 't_datetime' (a datetime vector) are
%       % defined:
%       ax = gracePlotHeartBeat(beats, d, t_datetime);
%
%   Example 3: Specifying a custom linewidth
%       ax = gracePlotHeartBeat(beats, d, t, 'Linewidth', 2);
%
%   See also PLOT, SUBPLOT, LINKAXES.


arguments
    beats (:,:) struct
    d (:,1) double
    t (:,1) {mustBeA(t,{'double','datetime'})}
    options.Linewidth (1,1) double = 1
end

figure;

% Time handling for plotting
if isa(t, 'datetime')
    t_plot = t; % Use datetime values directly
    time_unit = 'Time'; % X-axis label for datetime
else
    t_plot = t * 1/(60*60); % Convert seconds to hours
    time_unit = 'Time (hr)'; % X-axis label for hours
end

good = logical([beats.valid]);

ax1 = subplot(3,1,1);
plot(t_plot, d);
hold on;
plot([beats(good).onset], mean(d)*ones(size(good)), 'ko');
plot([beats(good).offset], mean(d)*ones(size(good)), 'kx');
% plot([beats(good).onset], interp1(t,d,[beats(good).onset]), 'ko');
% plot([beats(good).offset], interp1(t,d,[beats(good).offset]), 'kx');
box off;
ylabel('PPG');

ax2 = subplot(3,1,2);
plot([beats(good).onset], [beats(good).instant_freq], 'LineWidth', options.Linewidth); % Apply linewidth
ylabel('Beat frequency (Hz)');
box off;

ax3 = subplot(3,1,3);
plot([beats(good).onset], [beats(good).duty_cycle], 'LineWidth', options.Linewidth); % Apply linewidth
xlabel(time_unit);
ylabel('Duty cycle');
box off;

linkaxes([ax1 ax2 ax3],'x');
ax = cat(1,ax1,ax2,ax3);

end