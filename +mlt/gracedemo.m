


beats = mlt.detectHeartBeats(seconds(T-T(1)),zscore(d),'THRESHOLD_LOW',-0.5,'THRESHOLD_HIGH',0.3,'REFRACT',0.2);


figure
ax1 = subplot(3,1,1);
plot(seconds(T-T(1)),d-mean(d),'linewidth',1);
hold on;
plot([beats.onset],0,'ko');
plot([beats.offset],0,'kx');
plot([beats.onset],[beats.amplitude],'ro');
plot([beats.onset],[beats.amplitude_high],'go');
plot([beats.onset],[beats.amplitude_low],'mo');


xlabel('Time(s)');
ylabel('PPG');

ax2 = subplot(3,1,2);
plot([beats.onset],[beats.instant_freq]);
xlabel('Time(s)');
ylabel('Beat frequency (Hz)');

ax3 = subplot(3,1,3);
plot([beats.onset],[beats.duty_cycle]);
xlabel('Time(s)');
ylabel('Duty cycle');

linkaxes([ax1 ax2 ax3],'x');