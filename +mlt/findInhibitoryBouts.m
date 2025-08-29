function bouts = findInhibitoryBouts(beat_times, options)
%MLT.FINDINHIBITORYBOUTS Identifies inhibitory bouts from beat time data.
%   bouts = mlt.findInhibitoryBouts(beat_times) analyzes a vector of beat
%   times to identify periods of significant heart rate slowdown (inhibition)
%   and the subsequent recovery.
%
%   The function first calculates the beat rate in sliding time windows. It
%   then iterates through the rate data to find onsets and offsets.
%
%   SYNTAX:
%   bouts = mlt.findInhibitoryBouts(beat_times)
%   bouts = mlt.findInhibitoryBouts(beat_times, Name, Value, ...)
%
%   INPUTS:
%   beat_times          - A vector of beat times (numeric seconds or datetime).
%
%   OPTIONAL NAME-VALUE PAIR ARGUMENTS:
%   'deltaT'            - The time step (in seconds) for rate binning.
%                         Default: 0.5 seconds.
%   'W'                 - The total width of the sliding window (in seconds)
%                         for rate binning.
%                         Default: 5 seconds.
%   'InhibitoryBoutSlowDownOnsetThreshold' - The fractional threshold for
%                         detecting an inhibitory bout onset.
%                         Default: 0.5 (i.e., a 50% slowdown).
%   'InhibitoryBoutEndOnsetThreshold' - The fractional threshold for
%                         detecting the end of a bout.
%                         Default: 1.5 (i.e., a 150% speedup).
%   'InhibitoryBoutOnsetOffsetTimeWindow' - The duration (in seconds) over
%                         which the rate change is evaluated.
%                         Default: 1 second.
%
%   OUTPUTS:
%   bouts               - A structure with four fields:
%                         .inhibitoryBoutOnset: A vector of timestamps for
%                           the start of each detected inhibitory bout.
%                         .inhibitoryBoutOffset: A vector of timestamps for
%                           the end of each detected inhibitory bout.
%                         .beatRate: The vector of binned beat rates (Hz).
%                         .beatRateTimes: The timestamps for each binned rate.
%
%   EXAMPLE:
%       beat_times = [ (0:0.4:10), (10.5:1:20), (20.4:0.4:30) ]';
%       bouts = mlt.findInhibitoryBouts(beat_times);
%       % The 'bouts' struct now contains onsets, offsets, and the rate data.

% --- Input Argument Validation ---
arguments
    beat_times {mustBeVector, mustBeNonempty, mustBeSorted, mustBeA(beat_times, ["double", "datetime"])}
    options.deltaT (1,1) double {mustBePositive} = 0.5
    options.W (1,1) double {mustBePositive} = 5
    options.InhibitoryBoutSlowDownOnsetThreshold (1,1) double {mustBePositive} = 0.5
    options.InhibitoryBoutEndOnsetThreshold (1,1) double {mustBePositive} = 1.5
    options.InhibitoryBoutOnsetOffsetTimeWindow (1,1) double {mustBePositive} = 1
end

% --- Step 1: Calculate Binned Beat Rate ---
[rates, bin_centers] = mlt.beatRateBins(beat_times, ...
    'deltaT', options.deltaT, 'W', options.W);

% --- Step 2: Initialize Output and Find Bouts ---

% Initialize output structure
bouts.inhibitoryBoutOnset = [];
bouts.inhibitoryBoutOffset = [];
if isdatetime(bin_centers)
    bouts.inhibitoryBoutOnset = NaT(0,1);
    bouts.inhibitoryBoutOffset = NaT(0,1);
end
% Add the binned rate data to the output structure
bouts.beatRate = rates;
bouts.beatRateTimes = bin_centers;

% Convert time window to an index step for iteration
index_step = round(options.InhibitoryBoutOnsetOffsetTimeWindow / options.deltaT);
if index_step == 0
    warning('The OnsetOffsetTimeWindow is smaller than deltaT, using an index step of 1.');
    index_step = 1;
end

in_bout = false; % State variable

% Iterate through the rate data
for i = 1:(length(rates) - index_step)
    
    rate_initial = rates(i);
    rate_final = rates(i + index_step);
    
    if rate_initial > 1e-9 % Avoid division by zero
        rate_change_ratio = rate_final / rate_initial;
    else
        rate_change_ratio = inf;
    end
    
    if ~in_bout % Look for an onset
        if rate_change_ratio <= options.InhibitoryBoutSlowDownOnsetThreshold
            bouts.inhibitoryBoutOnset(end+1,1) = bin_centers(i);
            in_bout = true;
        end
    else % Look for an offset
        if rate_change_ratio >= options.InhibitoryBoutEndOnsetThreshold
            bouts.inhibitoryBoutOffset(end+1,1) = bin_centers(i + index_step);
            in_bout = false;
        end
    end
end

% --- Final Cleanup ---
% Ensure we only return matched pairs of onsets and offsets
if length(bouts.inhibitoryBoutOnset) > length(bouts.inhibitoryBoutOffset)
    bouts.inhibitoryBoutOnset(end) = [];
end

end

function mustBeSorted(a)
    % Custom validation function
    if ~issorted(a)
        eid = 'mlt:notStrictlySorted';
        msg = 'Input beat_times vector must be strictly increasing.';
        throwAsCaller(MException(eid, msg));
    end
end

