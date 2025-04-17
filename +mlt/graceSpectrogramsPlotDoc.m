function ax = graceSpectrogramsPlotDoc(S, options)
%GRACESPECTROGRAMSPLOTDOC Plot spectrograms for PPG elements.
%
%   AX = GRACESPECTROGRAMSPLOTDOC(S) plots spectrograms for all PPG elements 
%   found in the ndi.session or ndi.dataset object S.
%
%   The spectrograms are generated from pre-calculated document files using
%   GRACESPECTROGRAMDOC.
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

fig = figure;

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
    doc = mlt.findDocs(S,e.id(),et(1).epoch_id,'spectrogram');
    if isempty(doc)
        error(['Spectrogram document needs to be created for this session ' ...
            'prior to plotting.'])
    elseif isscalar(doc)
        doc = doc{1};
    else
        error(['More than one spectrogram document found matching the ' ...
            'element and epoch id.'])
    end
    
    
    % Load spectrogram, timestamps, and frequencies
    ngrid = doc.document_properties.ngrid;
    specProp = doc.document_properties.spectrogram;
    specDoc = database_openbinarydoc(S, doc, 'spectrogram_results.ngrid');
    spec = mlt.readngrid(specDoc,ngrid.data_dim,ngrid.data_type);
    database_closebinarydoc(S, specDoc);
    freqCoords = ngrid.data_dim(specProp.frequency_ngrid_dim);
    timeCoords = ngrid.data_dim(specProp.timestamp_ngrid_dim);
    f = ngrid.coordinates(1:freqCoords);
    ts = ngrid.coordinates(freqCoords + (1:timeCoords));

    % Plot spectrogram
    figure(fig);
    ax(end+1,1) = subplot(4,1,i);
    mlt.gracePlotSpectrogram(spec, f, ts, ...
        'colorbar', options.colorbar, ...
        'maxColorPercentile', options.maxColorPercentile, ...
        'colormapName', options.colormapName);
    title([e.elementstring],'interp','none');
end

linkaxes(ax,'xy');

end