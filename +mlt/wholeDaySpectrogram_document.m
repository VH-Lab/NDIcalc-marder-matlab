function [doc] = wholeDaySpectrogram_document(S, options)
% WHOLEDAYSPECTROGRAM - generate a spectrogram for a whole day's recording from ppg_heart_lp
% 
% [SPEC, F, TS] = WHOLEDAYSPECTROGRAM(S, ...)
%
% Computes a spectrogram for an entire ndi.element's worth of data.
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
% | f (0.1:0.1:10)            | The frequencies to examine               |
% | windowTime (10)           | The window time in seconds               |
% | downSample (2)            | Take every 'downSample' sample in answer |
% | zscoreWindowTime (3600)   | The z-score time window in seconds       |
% |----------------------------------------------------------------------|
%

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})} 
    options.e_name (1,:) char {mustBeTextScalar} = 'ppg_heart_lp_whole'
    options.e_reference (1,1) double {mustBePositive, mustBeInteger} = 1
    options.f (1,:) double = 0.1:0.1:10
    options.windowTime (1,1) double = 10
    options.downSample (1,1) double = 2
    options.zscoreWindowTime (1,1) double {mustBeNonnegative} = 3600
end

e = S.getelements('element.name',options.e_name,'element.reference',options.e_reference);

if numel(e)~=1
    error(['Could not find a single element.name ' options.e_name ' with reference ' int2str(options.e_reference) '.']);
end

e = e{1};

et = e.epochtable();

spec = [];
ts = [];

nextTime = 0;

wb = waitbar(0,"Working on whole day spectrogram");

idx = cellfun(@(x) eq(x,ndi.time.clocktype('dev_local_time')),et(1).epoch_clock);

if isempty(idx) % no local time
    for i=1:numel(et)
        [sd,f,ts_here] = mlt.makeSpectrogram(e,et(i).epoch_id, options.f, options.windowTime);
        waitbar(i/numel(et),wb,['Working on whole day spectrogram: ' int2str(i) ' of ' int2str(numel(et))]);
        spec = cat(2,spec,sd(:,1:options.downSample:end));
        ts = cat(2,ts,nextTime + ts_here(1:options.downSample:end)); % make a giant row
        nextTime = nextTime + ts_here(end) + (ts_here(2)-ts_here(1)); 
    end
else
    t0t1 = et(1).t0_t1{idx};
    tr = ndi.time.timereference(e,ndi.time.clocktype('dev_local_time'),et(1).epoch_id,0);
    [d,t] = e.readtimeseries(tr,t0t1(1),t0t1(2));
    if options.zscoreWindowTime == 0
        d = zscore(d);
    else
        d = mlt.movzscore(d,options.zscoreWindowTime,'SamplePoints',t);
    end
    [spec,f,ts] = mlt.spectrogram(d,t,'frequencies',options.f, ...
        'windowSizeTime', options.windowTime,'timeIsDatenum',false);
end

% Write spectrogram data to binary file
ngrid = mlt.mat2ngrid(spec,f,ts);
spect = struct('frequency_ngrid_dim',1,'timestamp_ngrid_dim',2,'decibels',true);
epoch_id = struct('epochid',et(1).epoch_id);
filePath = fullfile(S.path,[e(1).name '_' int2str(e(1).reference) '.ngrid']);
mlt.writengrid(spec,filePath,ngrid.data_type);
% spec2 = mlt.readngrid(filePath,ngrid.data_dim,ngrid.data_type);

% Save spectrogram to ndi document
doc = ndi.document('spectrogram','spectrogram',spect,'epoch_id',epoch_id,...
    'ngrid',ngrid) + S.newdocument(); % takes info from S and adds to the new ndi document
doc = doc.set_dependency_value('element_id',e.id());
doc = doc.add_file(options.e_name,filePath);
% Do we need to add epoch_clocktimes as a superclass?

waitbar(1,wb,"Working on whole day spectrogram")

close(wb);
