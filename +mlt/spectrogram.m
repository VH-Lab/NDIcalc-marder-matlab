function [spectrogram_data, f, t_s] = spectrogram(data, t, options)
%MLT.SPECTROGRAM Calculate the spectrogram of time-series data.
%
%   [spectrogram_data, f, t_s] = MLT.SPECTROGRAM(data, t, options)
%   calculates the spectrogram of the input time-series data using options.
%
%   Input arguments:
%       data: Time-series data (vector).
%       t: Time vector corresponding to the data.
%       options: (Optional) Structure containing optional parameters.
%           options.frequencies: An array of frequencies to be used in the spectrogram calculation. Default 0.1:0.1:10.
%           options.windowSizeTime: The desired window size in units of time. Default 10.
%           options.useDecibels: Logical, whether to return spectrogram in decibels (default: true).
%           options.timeIsDatenum: Logical, whether the time vector is in datenum format (default: false).
%
%   Output arguments:
%       spectrogram_data: The spectrogram data.
%       f: The frequencies used in the spectrogram calculation.
%       t_s: The times used in the spectrogram calculation.

arguments
    data (:,1) double;
    t (:,1);
    options.frequencies (1,:) double = 0.1:0.1:10;
    options.windowSizeTime (1,1) double = 10;
    options.useDecibels (1,1) logical = true;
    options.timeIsDatenum (1,1) logical = false;
end

% Convert time to datetime if needed
if options.timeIsDatenum
    t = datetime(t, 'ConvertFrom', 'datenum');
end

% Calculate sampling rate
if isa(t, 'datetime')
    sr = 1 / seconds(t(2) - t(1));
else
    sr = 1 / (t(2) - t(1));
end

% Calculate the window size in samples
windowSizeSamples = round(options.windowSizeTime * sr);

% Calculate the spectrogram
[spectrogram_data, f, t_s] = spectrogram(data, windowSizeSamples, 0, options.frequencies, sr);

% Convert to decibels if requested
if options.useDecibels
    spectrogram_data = 10 * log10(abs(spectrogram_data).^2);
end

% convert t_s to the same time type as t.
if isa(t, 'datetime')
    t_s = t(1) + seconds(t_s);
end

