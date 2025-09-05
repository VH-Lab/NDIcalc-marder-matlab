function [doc, beats, d, t] = wholeDayHeartBeatDoc(S, options)
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
%       DOC: A document containing the saved beats data
%       BEATS: A structure of heart beat data.
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

% Get time series
[d,t] = e.readtimeseries(1,-Inf,Inf);

% Z-Score data
if options.zscoreWindowTime == 0
    d = zscore(d);
else
    d = mlt.util.movzscore(d,options.zscoreWindowTime,'SamplePoints',t);
end

waitbar(1,wb,"Now will detect heart beats across the day (hang on...)");

% Detect beats
[beats,detection_parameters] = mlt.beats.detectHeartBeatsImproved(t,d);

% Collect metadata
beats_fields = strjoin(fieldnames(beats),',');
ppg_beats = struct('detection_parameters',detection_parameters,'fields',beats_fields);
epoch_id = struct('epochid',et(1).epoch_id);

% Check if document already exists, if so, remove from database
doc_old = ndi.database.fun.finddocs_elementEpochType(S,e.id(),et(1).epoch_id,'ppg_beats');
if ~isempty(doc_old)
    S.database_rm(doc_old);
end

% Make ndi document and add beats
doc = ndi.document('ppg_beats','ppg_beats',ppg_beats,'epochid',epoch_id) + ...
    S.newdocument();
doc = doc.set_dependency_value('element_id',e.id());
doc = mlt.beats.beatsstruct2doc(doc,beats);

% Add document to database
S.database_add(doc);
if ~isempty(doc_old)
    disp('Replaced "ppg_beats" document in database.')
else
    disp('Added "ppg_beats" document to database.')
end

close(wb);

end
