function graceAnalysisAll(S)
%GRACEANALYSISALL Runs the complete pre-processing and analysis pipeline for a session.
%
%   mlt.graceAnalysisAll(S)
%
%   This is the main, top-level wrapper function that executes the entire
%   pre-processing and analysis pipeline for all PPG (photoplethysmogram)
%   probes in a given NDI session.
%
%   It performs the following steps in order:
%   1.  Downsamples the raw PPG data to create the '_lp_whole' elements.
%   2.  Calculates spectrograms and saves them as .mat files.
%   3.  Calculates spectrograms and saves them as NDI documents.
%   4.  Detects heart beats and saves them as .mat files.
%   5.  Detects heart beats and saves them as NDI documents.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Example:
%       % Run the entire analysis pipeline on a session
%       mlt.graceAnalysisAll(mySession);
%
%   See also mlt.ppg.downsampleAll, mlt.spectrogram.calculateForFiles,
%   mlt.spectrogram.calculateForDocs, mlt.beats.calculateForFiles,
%   mlt.beats.calculateForDocs

% --- Input Validation ---
arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
end

disp('--- Starting Full Analysis Pipeline ---');

% Step 1: Downsample data (Assumed new name)
disp('Step 1/5: Downsampling raw PPG data...');
mlt.ppg.downsample(S);

% Step 2: Calculate spectrograms and save to .mat files
disp('Step 2/5: Calculating spectrograms for .mat files...');
mlt.spectrogram.calculateForFiles(S);

% Step 3: Calculate spectrograms and save to NDI documents
disp('Step 3/5: Calculating spectrograms for NDI documents...');
mlt.spectrogram.calculateForDocs(S);

% Step 4: Detect heart beats and save to .mat files
disp('Step 4/5: Detecting heart beats for .mat files...');
mlt.beats.calculateForFiles(S);

% Step 5: Detect heart beats and save to NDI documents
disp('Step 5/5: Detecting heart beats for NDI documents...');
mlt.beats.calculateForDocs(S);

disp('--- Full Analysis Pipeline Complete ---');

end