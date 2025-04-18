function [validBeats] = filterBeats(beats,options)
%FILTERBEATS detects valid beats based on user inputs and removes invalid events.
%
% See also MLT.DETECTBEATS

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