function gracePlotSpectrogram(spec,f,ts)
% GRACEPLOTSPECTROGRAM
%
% gracePlotSpectrogram(SPEC, F, TS)
%
% Plots a spectrogram in the current axes.
% 
% Plots the raw spectrogram, assuming input is in DB.
% Plots time in hours, assuming input is in seconds.
%

surf(ts/(60*60),f,10.^(spec/10));
view(0,90);
shading interp;


