function [spectrogram_data, f, t_s] = computeSpectrogram(data, t, options)
%COMPUTESPECTROGRAM Calculates a spectrogram with specific toolbox defaults.
%
%   [spectrogram_data, f, t_s] = mlt.util.computeSpectrogram(data, t, ...)
%
%   This is the core spectrogram calculation engine for the toolbox. It serves
%   as a wrapper around MATLAB's built-in `spectrogram` function, providing
%   convenient handling of time vectors (including datetime and datenum) and
%   conversion of the output power to decibels.
%
%   Inputs:
%       data - A numeric column vector of time-series data.
%       t    - A numeric or datetime column vector of timestamps for the data.
%
%   Optional Name-Value Pair Arguments:
%       frequencies (1,:) double = 0.1:0.1:10
%           A vector of frequencies (Hz) to evaluate in the spectrogram.
%       windowSizeTime (1,1) double = 10
%           The duration of the sliding window in seconds.
%       useDecibels (1,1) logical = true
%           If true, converts the output power spectrogram to decibels (10*log10(P)).
%       timeIsDatenum (1,1) logical = false
%           If true, the input time vector 't' is treated as MATLAB datenum values
%           instead of seconds.
%
%   Outputs:
%       spectrogram_data - The computed spectrogram data matrix ([frequency x time]).
%       f                - The frequency vector (Hz) corresponding to the rows.
%       t_s              - The time vector for the columns. Its type (numeric or
%                          datetime) matches the input time vector 't'.
%
%   Example:
%       % Create a sample signal: 2 Hz sine wave for 60 seconds
%       fs = 100; % 100 Hz sampling rate
%       t = (0:1/fs:60-1/fs)';
%       data = sin(2*pi*2*t) + 0.5*randn(size(t));
%       freqs_of_interest = 0:0.5:10;
%
%       [spec, f, ts] = mlt.util.computeSpectrogram(data, t, ...
%           'frequencies', freqs_of_interest, 'windowSizeTime', 5);
%
%   See also spectrogram, datetime, log10

arguments
    data (:,1) double
    t (:,1)
    options.frequencies (1,:) double = 0.1:0.1:10
    options.windowSizeTime (1,1) double = 10
    options.useDecibels (1,1) logical = true
    options.timeIsDatenum (1,1) logical = false
end

% --- Prepare Time and Sampling Rate ---
is_datetime = isa(t, 'datetime');
if options.timeIsDatenum
    t = datetime(t, 'ConvertFrom', 'datenum');
    is_datetime = true; % Treat it as datetime for output conversion
end

if is_datetime
    sr = 1 / seconds(t(2) - t(1));
else
    sr = 1 / (t(2) - t(1));
end
sr
% Calculate the window size in samples
windowSizeSamples = round(options.windowSizeTime * sr);

% --- Core Calculation ---
% This now safely calls MATLAB's built-in spectrogram function
[spectrogram_data, f, t_s] = spectrogram(data, windowSizeSamples, 0, options.frequencies, sr);

% --- Post-Processing ---
% Convert to decibels if requested
if options.useDecibels
    % Add a small epsilon to avoid log(0) which is -Inf
    epsilon = 1e-10;
    spectrogram_data = 10 * log10(abs(spectrogram_data).^2 + epsilon);
end

% Convert output time vector t_s to the same type as the input t
if is_datetime
    t_s = t(1) + seconds(t_s);
end

end