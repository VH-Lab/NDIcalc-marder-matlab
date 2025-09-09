function [doc] = wholeDaySpectrogramDoc(S, options)
%WHOLEDAYSPECTROGRAMDOC Computes and saves a spectrogram as an NDI document.
%
%   [DOC] = mlt.spectrogram.wholeDaySpectrogramDoc(S, Name, Value, ...)
%
%   Calculates a spectrogram for the entire duration of a specified
%   ndi.element and saves the result as an NDI document in the session's
%   database. This function is a key step in pre-processing data for later
%   analysis.
%
%   The function has two primary modes of operation based on the time clocks
%   available for the element's first epoch:
%
%   1.  **Continuous Mode**: If a 'dev_local_time' clock is found, the
%       function reads the entire time series for that epoch at once. It
%       then applies a Z-score normalization before computing the spectrogram.
%
%   2.  **Epoch-by-Epoch Mode**: If no local clock is found, the function
%       iterates through each epoch of the element individually, computes a
%       spectrogram for each, and concatenates the results.
%
%   After calculation, the function creates an 'spectrogram' type NDI document,
%   writes the spectrogram data to a binary .ngrid file, links the file to
%   the document, and adds the document to the database. **Note:** If a
%   spectrogram document for this element's first epoch already exists, it
%   will be removed and replaced.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Optional Name-Value Pairs:
%       e_name ('ppg_heart_lp_whole')
%           The name of the ndi.element to analyze.
%       e_reference (1)
%           The reference number of the ndi.element.
%       f (0.1:0.1:10)
%           A vector of frequencies (Hz) to analyze in the spectrogram.
%       windowTime (10)
%           The duration of the sliding window (in seconds) for the calculation.
%       downSample (2)
%           (Epoch-by-Epoch Mode Only) The factor by which to downsample the
%           time dimension of the spectrogram.
%       zscoreWindowTime (3600)
%           (Continuous Mode Only) The duration of the moving window (in
%           seconds) for z-score normalization. If set to 0, a global z-score
%           is applied across the entire signal.
%
%   Outputs:
%       doc - The ndi.document object that was created and added to the database.
%
%   Example:
%       % Calculate a spectrogram and save it as a document for a specific element
%       doc = mlt.spectrogram.wholeDaySpectrogramDoc(mySession, ...
%           'e_name', 'ppg_pylorus_lp_whole', 'e_reference', 1);
%
%   See also mlt.spectrogram.wholeDaySpectrogram, ndi.document, ndi.session.database_add

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
        [sd,f,ts_here] = mlt.util.makeSpectrogram(e,et(i).epoch_id, options.f, options.windowTime);
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
        d = mlt.util.movzscore(d,options.zscoreWindowTime,'SamplePoints',t);
    end
    [spec,f,ts] = mlt.util.computeChunkedSpectrogram(d,t,'frequencies',options.f, ...
        'windowSizeTime', options.windowTime,'timeIsDatenum',false);
end

% Collect metadata
ngrid = ndi.fun.data.mat2ngrid(spec,f,ts);
spect = struct('frequency_ngrid_dim',1,'timestamp_ngrid_dim',2,'decibels',true);
epoch_id = struct('epochid',et(1).epoch_id);

% Check if document already exists, if so, remove from database
doc_old = ndi.database.fun.finddocs_elementEpochType(S,e.id(),et(1).epoch_id,'spectrogram');
if ~isempty(doc_old)
    S.database_rm(doc_old);
end

% Make ndi document
doc = ndi.document('spectrogram','spectrogram',spect,'epochid',epoch_id,...
    'ngrid',ngrid) + S.newdocument();
doc = doc.set_dependency_value('element_id',e.id());

% Write spectrogram data to binary file
filePath = fullfile(S.path,[options.e_name '_' int2str(options.e_reference) '.ngrid']);
ndi.fun.data.writengrid(spec,filePath,ngrid.data_type);

% Add file to ndi document
doc = doc.add_file('spectrogram_results.ngrid',filePath);

% Add document to database
S.database_add(doc);

if ~isempty(doc_old)
    disp('Replaced "spectrogram" document in database.')
else
    disp('Added "spectrogram" document to database.')
end

waitbar(1,wb,"Working on whole day spectrogram");
close(wb);