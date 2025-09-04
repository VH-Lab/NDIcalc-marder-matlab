function [spectrogram_data, f, t_s] = makeSpectrogam(ndi_element_obj, epoch_id, frequencies, windowSizeTime)
% MAKESPECTROGRAM - Calculate the spectrogram of an ndi.element
%
% [spectrogram_data, f, t_s] = MAKESPECTROGRAM(ndi_element_obj, epoch_id, frequencies, windowSizeTime)
%
% Given an ndi.element object and an epoch_id, this function calculates the spectrogram of the
% data and returns the spectrogram data, frequencies, and times.
%
% Input arguments:
%   ndi_element_obj: An ndi.element object.
%   epoch_id: The epoch ID for the data to be used.
%   frequencies: An array of frequencies to be used in the spectrogram calculation.
%   windowSizeTime: The desired window size in units of time.
%
% Output arguments:
%   spectrogram_data: The spectrogram data.
%   f: The frequencies used in the spectrogram calculation.
%   t_s: The times used in the spectrogram calculation.

% Verify inputs
arguments
    ndi_element_obj (1,1) ndi.element
    epoch_id (1,:) char
    frequencies (1,:) double
    windowSizeTime (1,1) double
end

% Read in the data
[data, t] = ndi_element_obj.readtimeseries(epoch_id, -inf, inf);

% Z-score the data
data = zscore(data);

% Call the mlt.spectrogram function with desired options using name/value pairs
[spectrogram_data, f, t_s] = mlt.spectrogram(data, t, ...
    'frequencies', frequencies, ...
    'windowSizeTime', windowSizeTime, ...
    'useDecibels', true, ...
    'timeIsDatenum', false); % Assumes time is not datenum

