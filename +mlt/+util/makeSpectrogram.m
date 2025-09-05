function [spectrogram_data, f, t_s] = makeSpectrogram(ndi_element_obj, epoch_id, frequencies, windowSizeTime)
%MAKESPECTROGRAM Computes a spectrogram for a single NDI element epoch.
%
%   [spectrogram_data, f, t_s] = mlt.util.makeSpectrogram(ndi_element_obj, ...
%       epoch_id, frequencies, windowSizeTime)
%
%   This function serves as a convenient wrapper to compute a spectrogram for
%   the entire time series of a single, specified epoch from an NDI element.
%   It reads the data, normalizes it with a global z-score, and then calls
%   the core `mlt.util.spectrogram` function to perform the calculation.
%
%   Inputs:
%       ndi_element_obj - An ndi.element object.
%       epoch_id        - The character vector or string ID for the epoch to
%                         be analyzed.
%       frequencies     - A vector of frequencies (Hz) to be used in the
%                         spectrogram calculation.
%       windowSizeTime  - The desired window size in seconds.
%
%   Outputs:
%       spectrogram_data - The spectrogram data matrix ([frequency x time]).
%       f                - The frequency vector (Hz) used in the calculation.
%       t_s              - The time vector (seconds) for the spectrogram output.
%
%   Example:
%       % Assume 'my_element' is a valid ndi.element and 'epoch001' is an
%       % ID from its epoch table.
%       freqs = 0.1:0.1:10; % 0.1 to 10 Hz
%       win_sec = 10;       % 10-second window
%       [spec, f, t] = mlt.util.makeSpectrogram(my_element, 'epoch001', freqs, win_sec);
%
%   See also mlt.util.spectrogram, ndi.element.readtimeseries, zscore

% --- Input Validation ---
arguments
    ndi_element_obj (1,1) ndi.element
    epoch_id (1,:) char
    frequencies (1,:) double
    windowSizeTime (1,1) double
end

% --- Read and Prepare Data ---
% Read in the data for the entire specified epoch
[data, t] = ndi_element_obj.readtimeseries(epoch_id, -inf, inf);

% Z-score the data to normalize it
data = zscore(data);

% --- Calculate Spectrogram ---
% Call the core spectrogram function with desired options
[spectrogram_data, f, t_s] = mlt.util.computeSpectrogram(data, t, ...
    'frequencies', frequencies, ...
    'windowSizeTime', windowSizeTime, ...
    'useDecibels', true, ...
    'timeIsDatenum', false);

end