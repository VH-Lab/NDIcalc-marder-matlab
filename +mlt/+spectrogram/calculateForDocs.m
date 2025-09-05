function calculateForDocs(S)
%CALCULATEFORDOCS - Calculate and save PPG spectrograms as NDI documents.
%
%   mlt.spectrogram.calculateForDocs(S)
%
%   This is a high-level wrapper function that automates the process of
%   calculating spectrograms for all PPG (photoplethysmogram) probes within
%   a given NDI session or dataset.
%
%   For each 'ppg' probe found, the function first identifies its
%   corresponding low-pass filtered data element (e.g., 'ppg_heart_lp_whole').
%   It then calls the core processing function, mlt.wholeDaySpectrogramDoc,
%   to perform the spectrogram calculation and save the results as a
%   'spectrogram' NDI document.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Example:
%       % Assuming 'mySession' is a valid ndi.session object with PPG data
%       mlt.spectrogram.calculateForDocs(mySession);
%
%   See also mlt.wholeDaySpectrogramDoc, ndi.session

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
    
    % Find the corresponding low-pass filtered element required for calculation
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    
    if isempty(e)
        warning(['No ''_lp_whole'' version of ' p{i}.elementstring ' was found. Skipping.']);
        continue; % Skip to the next probe
    end
    
    % Call the core function to perform the analysis and create the NDI document
    disp(['Calculating spectrogram and creating document for ' e{1}.elementstring '...']);
    mlt.spectrogram.wholeDaySpectrogramDoc(S,'e_name',e{1}.name,'e_reference',e{1}.reference);
end

disp(' ');
disp('All PPG probes processed.');

end