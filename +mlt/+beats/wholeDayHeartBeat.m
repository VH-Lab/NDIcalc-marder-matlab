function [beats, d, t] = wholeDayHeartBeat(S, options)
%WHOLEDAYHEARTBEAT Generate heartbeat record for a whole day's recording.
%
%   [BEATS, D, T] = WHOLEDAYHEARTBEAT(S, OPTIONS) computes heart beat 
%   analysis for an entire day's worth of data from an ndi.element, 
%   typically 'ppg_heart_lp'. The function reads the data from the 
%   specified element and performs heart beat detection.
%
%   Inputs:
%       S: An ndi.session or ndi.dataset object containing the data.
%       OPTIONS: A structure containing optional parameters.
%           e_name: The name of the ndi.element to analyze (default: 'ppg_heart_lp').
%           e_reference: The reference number of the ndi.element (default: 1).
%           zscoreWindowTime: The z-score time window in seconds (default: 3600).
%
%   Outputs:
%       BEATS: A vector of heart beat timestamps.
%       D: The data stream used for heart beat detection.
%       T: The timestamps corresponding to the data stream.

% Validate input type
arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.e_name (1,:) char {mustBeTextScalar} = 'ppg_heart_lp'
    options.e_reference (1,1) double {mustBePositive, mustBeInteger} = 1
    options.zscoreWindowTime (1,1) double {mustBeNonnegative} = 3600
end

% Get the specified ndi.element
e = S.getelements('element.name',options.e_name,'element.reference',options.e_reference);

if numel(e)~=1
    error(['Could not find a single element.name ' options.e_name ' with reference ' int2str(options.e_reference) '.']);
end

e = e{1};
et = e.epochtable();

d = [];
t = [];
nextTime = 0;

wb = waitbar(0,"Working on whole day heart beat");

% Check for 'exp_global_time'
idx = cellfun(@(x) eq(x,ndi.time.clocktype('exp_global_time')),et(1).epoch_clock);

if isempty(idx) % No global time, process epochs individually
    for i=1:numel(et)
        [d_here,t_here] = e.readtimeseries(et(i).epoch_id,-inf,inf);
        d = cat(1,d,zscore(d_here));
        t = cat(1,t,nextTime+t_here(:));
        nextTime = max(t) + (t_here(2)-t_here(1)); % Update nextTime based on concatenated t
    end
else % 'exp_global_time' exists, read a single epoch
    t0t1 = et(1).t0_t1{idx};
    tr = ndi.time.timereference(e,ndi.time.clocktype('exp_global_time'),[],0);
    [d,t] = e.readtimeseries(tr,t0t1(1),t0t1(2));
    t = datetime(t,'convertFrom','datenum');
    if options.zscoreWindowTime == 0
        d = zscore(d);
    else
        d = mlt.movzscore(d,seconds(options.zscoreWindowTime),'SamplePoints',t);
    end
end

waitbar(1,wb,"Now will detect heart beats across the day (hang on...)");

beats = mlt.detectHeartBeatsImproved(t,d);

close(wb);

end


