function calculateForFiles(S)
%CALCULATEFORFILES - Calculate and save PPG spectrograms as .mat files.
%
%   mlt.spectrogram.calculateForFiles(S)
%
%   This is a high-level wrapper function that automates the process of
%   calculating spectrograms for all PPG (photoplethysmogram) probes within
%   a given NDI session or dataset.
%
%   For each 'ppg' probe found, the function first identifies its
%   corresponding low-pass filtered data element (e.g., 'ppg_heart_lp_whole').
%   It then calls a core processing function to perform the spectrogram
%   calculation and saves the results to a standalone .mat file in the
%   session's path.
%
%   The output files are named according to the convention:
%   'ppg_ELEMENT-NAME_REFERENCE.mat'
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Example:
%       % Assuming 'mySession' is a valid ndi.session object with PPG data
%       mlt.spectrogram.calculateForFiles(mySession);
%
%   See also mlt.wholeDaySpectrogram, ndi.session

% --- Input Argument Validation ---
arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
end

p = S.getprobes('type','ppg');

if isempty(p)
    disp('No PPG probes found in the session. Nothing to do.');
    return;
end

disp(['Found ' int2str(numel(p)) ' PPG probes to process...']);

for i=1:numel(p)
    disp(' '); % Add a blank line for readability
    disp(['Processing probe ' p{i}.elementstring '...']);
    
    % Find the corresponding low-pass filtered element
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    
    if isempty(e)
        warning(['No ''_lp_whole'' version of ' p{i}.elementstring ' was found. Skipping.']);
        continue; % Skip to the next probe
    end
    
    % Call the core function to calculate the spectrogram
    disp(['Calculating spectrogram for ' e{1}.elementstring '...']);
    [spec,f,ts] = mlt.wholeDaySpectrogram(S,'e_name',e{1}.name,'e_reference',e{1}.reference);
    
    % Construct filename and save the results
    filename = fullfile(S.path(), ['ppg_' e{1}.name '_' int2str(e{1}.reference) '.mat']);
    disp(['Saving data to ' filename]);
    save(filename,'spec','f','ts','-mat');
end

disp(' ');
disp('All PPG probes processed.');

end