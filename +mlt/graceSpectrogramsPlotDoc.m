function ax = graceSpectrogramsPlotDoc(S, options)
%GRACESPECTROGRAMSPLOTDOC Plot spectrograms for PPG elements.
%
%   AX = GRACESPECTROGRAMSPLOTDOC(S) plots spectrograms for all PPG elements 
%   found in the ndi.session or ndi.dataset object S.
%
%   The spectrograms are generated from pre-calculated data files 
%   (assumed to be named 'ppg_[element_name]_[element_reference].mat')
%   located in the session/dataset path. Each file is expected to 
%   contain variables 'spec', 'f', and 'ts'.
%
%   The plots are arranged in a new figure with 4 rows and 1 column,
%   with each row displaying the spectrogram of one PPG element.
%
%   Input Arguments:
%       S: An ndi.session or ndi.dataset object.
%   Options:
%       options.colorbar (1,1) logical = false;  Whether to draw the color bar.
%       options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99; The percentile of data to use as the max value for the color scale.
%       options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'; Name of the colormap to use.
%
%   Output Arguments:
%       AX: An array of axes handles for the generated subplots.

% Verify input type
arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.colorbar (1,1) logical = false;    
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99;
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula';
end

p = S.getprobes('type','ppg');

path = S.path();

f = figure;

ax = [];

for i=1:numel(p)
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e)
        error(['No ''_lp'' version of ' p{i}.elementstring]);        
    end
    e = e{1};
    et = e.epochtable();

    % Find spectrogram document
    q1 = ndi.query('','isa','spectrogram');
    q2 = ndi.query('','depends_on','element_id',e.id());
    q3 = ndi.query('epochid.epochid','exact_string',et(1).epoch_id);
    doc = S.database_search(q1&q2&q3);
    if isempty(doc)
        error(['Spectrogram document needs to be created for this session ' ...
            'prior to plotting.'])
    elseif length(doc) > 1
        error(['More than one spectrogram document found matching the ' ...
            'element and epoch id.'])
    end
    filePath = doc{1}.document_properties.files.file_info.locations.location;
    
    % Load spectrogram, timestamps, and frequencies
    ngrid = doc{1}.document_properties.ngrid;
    spec = mlt.readngrid(filePath,ngrid.data_dim,ngrid.data_type);
    specProp = doc{1}.document_properties.spectrogram;
    freqCoords = ngrid.data_dim(specProp.frequency_ngrid_dim);
    timeCoords = ngrid.data_dim(specProp.timestamp_ngrid_dim);
    f = ngrid.coordinates(1:freqCoords);
    ts = ngrid.coordinates(freqCoords + (1:timeCoords));

    % Plot spectrogram
    ax(end+1,1) = subplot(4,1,i);
    mlt.gracePlotSpectrogram(spec, f, ts, ...
        'colorbar', options.colorbar, ...
        'maxColorPercentile', options.maxColorPercentile, ...
        'colormapName', options.colormapName);  % Pass as name-value pairs
    title([e.elementstring],'interp','none');
end

linkaxes(ax,'xy');

end