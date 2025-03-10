function ax = gracePlotHeartBeat(beats, d, t)
% GRACEPLOTHEARTBEATS - Plot heart beat data in a new figure
%
% AX = GRACEPLOTHEARTBEAT(BEATS, D, T)
%
% Plot heart beat stats in a new figure. T can be a numeric vector
% in seconds or a datetime vector.
% 
% AX are the axes created.
%
% Example:
%   mlt.gracePlotHeartBeats(beats,d,t);
% 

arguments
    beats (:,:) struct
    d (:,1) double
    t (:,1) {mustBeA(t,{'double','datetime'})}
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

good = ([beats.valid]);

ax1 = subplot(3,1,1);
plot(t_plot, d);
hold on;
plot([beats(good).onset], zeros(size(good)), 'ko');
plot([beats(good).offset], zeros(size(good)), 'kx');
box off;
ylabel('PPG');

ax2 = subplot(3,1,2);
plot([beats(good).onset], [beats(good).instant_freq]);
ylabel('Beat frequency (Hz)');
box off;

ax3 = subplot(3,1,3);
plot([beats(good).onset], [beats(good).duty_cycle]);
xlabel(time_unit);
ylabel('Duty cycle');
box off;

linkaxes([ax1 ax2 ax3],'x');
ax = cat(1,ax1,ax2,ax3);

end