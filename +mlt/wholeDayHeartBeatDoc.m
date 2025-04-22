function [beats, d, t] = wholeDayHeartBeatDoc(S, options)
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

% Check that there is only one element containing only one epoch
if numel(e)~=1
    error(['Could not find a single element.name ' options.e_name ...
        ' with reference ' int2str(options.e_reference) '.']);
elseif numel(e{1}.epochtable)~=1
    error(['Combine all epochs from a single element.name ' options.e_name ...
        ' with reference ' int2str(options.e_reference) ' prior to beat detection.'])
end

e = e{1};
et = e.epochtable();

wb = waitbar(0,"Working on whole day heart beat");

% Check if there is a global clock, if not, use dev_local_time
epoch_clocks = et(1).epoch_clock;
ecs = cellfun(@(c) c.type,epoch_clocks,'UniformOutput',false);
clock_ind = find(cellfun(@(x) ndi.time.clocktype.isGlobal(x),epoch_clocks),1);
if isempty(clock_ind)
    clock_ind = find(contains(ecs,'dev_local_time'));
    clock_global = false;
    if isempty(clock_ind)
        error('No global or local clock found in this elements epochtable.')
    end
else
    clock_global = true;
end

% Get relevant time series
t0_t1 = et(1).t0_t1{clock_ind};
tr = ndi.time.timereference(e,epoch_clocks{clock_ind},[],0);
[d,t] = e.readtimeseries(tr,t0_t1(1),t0_t1(2));
if clock_global
    t = datetime(t,'convertFrom','datenum');
end

% Z-Score data
if options.zscoreWindowTime == 0
    d = zscore(d);
else
    d = mlt.movzscore(d,seconds(options.zscoreWindowTime),'SamplePoints',t);
end

waitbar(1,wb,"Now will detect heart beats across the day (hang on...)");

% Detect beats
[beats,detection_parameters] = mlt.detectHeartBeatsImproved(t,d);

% Collect metadata
beats_fields = strjoin(fieldnames(beats),',');
ppg_beats = struct('detection_parameters',detection_parameters,'fields',beats_fields);
epoch_id = struct('epochid',et(1).epoch_id);
epochclocktimes = struct('clocktype',epoch_clocks{clock_ind}.type,'t0_t1',t0_t1);

% Check if document already exists, if so, remove from database
doc_old = mlt.findDocs(S,e.id(),et(1).epoch_id,'ppg_beats');
if ~isempty(doc_old)
    S.database_rm(doc_old);
end

% Make ndi document and add beats
doc = ndi.document('ppg_beats','ppg_beats',ppg_beats,'epochid',epoch_id,...
    'epochclocktimes',epochclocktimes) + S.newdocument();
doc = doc.set_dependency_value('element_id',e.id());
doc = mlt.addbeats2doc(doc,beats);

% Add document to database
S.database_add(doc);
if ~isempty(doc_old)
    disp('Replaced "ppg_beats" document in database.')
else
    disp('Added "ppg_beats" document to database.')
end

close(wb);

end