function ax = gracePlotHeartBeat(beats, d, t)
% GRACEPLOTHEARTBEATS - Plot heart beat data in a new figure
%
% AX = GRACEPLOTHEARTBEAT(BEATS, D, T)
%
% Plot heart beat stats in a new figure.
% 
% AX are the axes created.
%
% Example:
%   mlt.gracePlotHeartBeats(beats,d,t);
% 

figure

sec2hr = 1/(60*60);

ax1 = subplot(3,1,1);
plot(t*sec2hr, d);
hold on;
plot([beats.onset]*sec2hr,0,'ko');
plot([beats.offset]*sec2hr,0,'kx');
%plot([beats.onset],[beats.amplitude],'ro');
%plot([beats.onset],[beats.amplitude_high],'go');
%plot([beats.onset],[beats.amplitude_low],'mo');
box off;

ylabel('PPG');

ax2 = subplot(3,1,2);
plot([beats.onset]*sec2hr,[beats.instant_freq]);
ylabel('Beat frequency (Hz)');
box off;

ax3 = subplot(3,1,3);
plot([beats.onset]*sec2hr,[beats.duty_cycle]);
xlabel('Time(hr)');
ylabel('Duty cycle');
box off;

linkaxes([ax1 ax2 ax3],'x');

ax = cat(1,ax1,ax2,ax3);

