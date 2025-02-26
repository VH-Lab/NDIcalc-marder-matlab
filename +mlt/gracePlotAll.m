function gracePlotAll(S)
% GRACEPLOTALL - plot all of Grace's summary data for a session
%
% GRACEPLOTALL(S)
%
% Plot all of Grace's summary data for a session
%
% Example:
%    mlt.gracePlotAll(S)
%
% 


axS = mlt.graceSpectrogramsPlot(S)

axHB = mlt.graceHeartBeatPlot(S);

axS2 = mlt.graceSpectrogramsBeatOverlayPlot(S)

linkaxes(cat(1,axS,axHB,axS2),'x');


