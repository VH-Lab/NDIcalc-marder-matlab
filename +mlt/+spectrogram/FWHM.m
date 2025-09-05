function [specData_avg, f, fwhm_val, low_cutoff, high_cutoff] = FWHM(e, t0, t1)
%FWHM Calculates time-averaged spectrogram and its Full Width at Half Maximum.
%
%   [specData_avg, f, fwhm_val, low_cutoff, high_cutoff] = ...
%       mlt.spectrogram.FWHM(e, t0, t1)
%
%   Calculates the time-averaged power spectrum and its full width at half
%   maximum (FWHM) for a given ndi.element 'e' within a specified time
%   window [t0, t1].
%
%   This function first retrieves the spectrogram data for the specified
%   window and then performs the FWHM calculation on the time-averaged result.
%
%   Inputs:
%       e  - An ndi.element object that has associated 'spectrogram' documents.
%       t0 - A datetime object representing the start of the analysis window.
%       t1 - A datetime object representing the end of the analysis window.
%
%   Outputs:
%       specData_avg - A column vector of the power spectrum averaged over time.
%                      Returns empty if no data is found in the window.
%       f            - The corresponding frequency vector (column vector).
%       fwhm_val     - The full width at half maximum (FWHM) of the spectrum (Hz).
%                      Returns NaN if FWHM cannot be calculated.
%       low_cutoff   - The lower frequency cutoff at half maximum height (Hz).
%       high_cutoff  - The upper frequency cutoff at half maximum height (Hz).
%
%   Example:
%       % Assuming 'my_element' is a valid ndi.element with spectrograms
%       t_start = datetime('2025-09-05 10:00:00');
%       t_end = datetime('2025-09-05 10:05:00');
%       [spec_avg, f, fwhm] = mlt.spectrogram.FWHM(my_element, t_start, t_end);
%
%       % Plot the time-averaged spectrum and its FWHM
%       if ~isempty(spec_avg)
%           figure;
%           plot(f, spec_avg);
%           title(['FWHM: ' num2str(fwhm, '%.2f') ' Hz']);
%           xlabel('Frequency (Hz)');
%           ylabel('Average Power');
%           grid on;
%       end
%
%   See also mlt.spectrogram.readTimeWindow, vlt.signal.fwhm

% --- Input Validation ---
arguments
    e (1,1) {mustBeA(e,'ndi.element')}
    t0 (1,1) {mustBeA(t0,'datetime')}
    t1 (1,1) {mustBeA(t1,'datetime')}
end

% --- Initialize Outputs ---
specData_avg = [];
f = [];
fwhm_val = NaN;
low_cutoff = NaN;
high_cutoff = NaN;

% --- Step 1: Read Spectrogram Data for the Time Window ---
% Helper function handles the complex database search and data extraction.
% We only need the first two outputs for this calculation.
[spectrogram_data, f] = mlt.spectrogram.readTimeWindow(e, t0, t1);

if isempty(spectrogram_data)
    disp('No spectrogram data found in the specified time window.');
    return;
end

% --- Step 2: Calculate Time-Averaged Spectrum ---
try
    % Spectrogram data is expected as [frequency x time]
    specData_avg = mean(spectrogram_data, 2);
    specData_avg = specData_avg(:); % Ensure column vector
catch ME_avg
    warning('Error calculating time-averaged spectrum: %s', ME_avg.message);
    return; % Cannot proceed
end

% --- Step 3: Calculate FWHM ---
% Check if we have enough valid data to proceed
if numel(f) == numel(specData_avg) && numel(f) >= 2
    try
        % Use vlt.signal.fwhm to calculate FWHM and cutoffs
        [~, fwhm_val, low_cutoff, high_cutoff] = vlt.signal.fwhm(f, specData_avg);
        
        % Replace Inf with NaN for consistency
        if isinf(fwhm_val), fwhm_val = NaN; end
        if isinf(low_cutoff), low_cutoff = NaN; end
        if isinf(high_cutoff), high_cutoff = NaN; end
        
    catch ME_fwhm
        warning('Error calculating FWHM using vlt.signal.fwhm: %s', ME_fwhm.message);
    end
else
    warning('Not enough data or dimension mismatch; cannot calculate FWHM.');
end

end