function [validBeats] = filterBeats(beats,options)
%UNTITLED Summary of this function goes here
%       OPTIONS: (Optional) A structure specifying detection parameters:
%           MinBeatMax: Minimum value for beat amplitude (default: -Inf).
%           MaxBeatMax: Maximum value for beat amplitude
%           BeatMin: Lower threshold for beat amplitude (def
%           MinPeakProminence: Lower threshold for beat detection (default: -0.75).
%           MinPeakDistance: Minimum time between consecutive beats (refractory period, default: 0.2).
%           amplitude_high_min: Minimum amplitude above THRESHOLD_HIGH (default: 0).
%           amplitude_low_min: Minimum amplitude below THRESHOLD_LOW (default: 0).
%           amplitude_min: Minimum peak-to-peak amplitude (default: 0).
%           MinPeakDuration: Minimum beat duration (default: 0).
%           MaxPeakDuration: Maximum beat duration

% Validate input type
arguments
    beats {mustBeA(beats,{'struct'})}
    options.MinBeatAmplitude (1,1) double {mustBeReal,mustBeNonnegative} = 0
    options.MaxBeatAmplitude (1,1) double {mustBeReal,mustBeNonnegative} = Inf
    options.MinBeatDuration (1,1) double {mustBeReal,mustBeNonnegative} = 0
    options.MinPeakHeight (1,1) double {mustBeReal} = -Inf
    options.MaxPeakHeight (1,1) double {mustBeReal} = Inf
    options.MinTroughHeight (1,1) double {mustBeReal} = -Inf
    options.MaxTroughHeight (1,1) double {mustBeReal} = Inf
end

% Find valid beats given filtering criteria
beats = struct2table(beats);
valid = beats.amplitude >= options.MinBeatAmplitude & ...
    beats.amplitude <= options.MaxBeatAmplitude & ...
    seconds(diff([NaT;beats.onset])) >= options.MinBeatDuration & ...
    beats.beat_max >= options.MinPeakHeight & ...
    beats.beat_max <= options.MaxPeakHeight & ...
    beats.beat_min >= options.MinTroughHeight & ...
    beats.beat_max <= options.MaxTroughHeight;

% Update beat values
% How to combine beats? Maybe need more values saved from detectBeats in
% order to determine which go together
validBeats = beats(valid,:);

end