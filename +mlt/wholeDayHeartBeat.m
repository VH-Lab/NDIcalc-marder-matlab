function [beats, d, t] = wholeDayHeartBeat(S, options)
% WHOLEDAYHEARTBEAT - generate heartbeat record for a whole day's recording from ppg_heart_lp
% 
% [BEATS, D, T] = WHOLEDAYHEARTBEAT(S, ...)
%
% Computes heart beat analysis for an entire ndi.element's worth of data.
%
% D is the data stream and t the time values.
%
% Inputs:
%   S - an ndi.session or ndi.dataset object
%
% The function takes options as name/value pairs that modify the behavior:
% ------------------------------------------------------------------------
% | Parameter (default)       | Description                              |
% |---------------------------|------------------------------------------|
% | e_name ('ppg_heart_lp')   | The ndi.element name to examine          |
% | e_reference (1)           | The ndi.element reference to examine     |
% |----------------------------------------------------------------------|
%

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})} 
    options.e_name (1,:) char {mustBeTextScalar} = 'ppg_heart_lp'
    options.e_reference (1,1) double {mustBePositive, mustBeInteger} = 1
end

e = S.getelements('element.name',options.e_name,'element.reference',options.e_reference);

if numel(e)~=1,
    error(['Could not find a single element.name ' options.e_name ' with reference ' int2str(options.e_reference) '.']);
end

e = e{1};

et = e.epochtable();

d = [];
t = [];

nextTime = 0;

wb = waitbar(0,"Working on whole day heart beat");

for i=1:numel(et)
    [d_here,t_here] = e.readtimeseries(i,-inf,inf);
    waitbar(i/numel(et),wb,['Working on whole day heart beat: ' int2str(i) ' of ' int2str(numel(et))]);
    d = cat(1,d,zscore(d_here));
    t = cat(1,t,nextTime+t_here(:));
    nextTime = t_here(end) + (t_here(2)-t_here(1)); 
end

waitbar(1,wb,"Now will detect heart beats across the day (hang on...)")

beats = mlt.detectHeartBeats(t,d);

close(wb);


