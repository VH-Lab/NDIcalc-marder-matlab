function ax = graceSpectrogramsPlot(S)
%GRACESPECTROGRAMSPLOT Plot spectrograms for PPG elements.
%
%   AX = GRACESPECTROGRAMSPLOT(S) plots spectrograms for all PPG elements 
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
%
%   Output Arguments:
%       AX: An array of axes handles for the generated subplots.

% Verify input type
arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
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
    filename = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '.mat']);
    load(filename,'-mat');
    ax(end+1,1) = subplot(4,1,i);
    mlt.gracePlotSpectrogram(spec,f,ts);
    title([e{1}.elementstring],'interp','none');
end

linkaxes(ax,'x');

end
