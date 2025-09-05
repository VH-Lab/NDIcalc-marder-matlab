function calculateForFiles(S)
%CALCULATEFORFILES - Calculate and save heart beat data as .mat files for a session.
%
%   mlt.beats.calculateForFiles(S)
%
%   This is a high-level wrapper function that automates the process of
%   heart beat detection for all PPG (photoplethysmogram) probes within a
%   given NDI session or dataset.
%
%   For each 'ppg' probe found, the function first identifies its
%   corresponding low-pass filtered data element (e.g., 'ppg_heart_lp_whole').
%   It then calls a core processing function to perform the beat detection
%   and save the results to a standalone .mat file in the session's path.
%
%   The output files are named according to the convention:
%   'ppg_ppg_AREA_lp_whole_NUMBER_beats.mat'
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Example:
%       % Assuming 'mySession' is a valid ndi.session object with PPG data
%       mlt.beats.calculateForFiles(mySession);
%
%   See also mlt.beats.wholeDayHeartBeatFile, ndi.session

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
    
    % Find the corresponding low-pass filtered element required for beat detection
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    
    if isempty(e)
        warning(['No ''_lp_whole'' version of ' p{i}.elementstring ' was found. Skipping.']);
        continue; % Skip to the next probe
    end
    
    % Call the core function to perform the analysis and save to a .mat file
    disp(['Calling beat detection for ' e{1}.elementstring '...']);
    mlt.beats.wholeDayHeartBeatFile(S,'e_name',e{1}.name,'e_reference',e{1}.reference);
end

disp(' ');
disp('All PPG probes processed.');

end