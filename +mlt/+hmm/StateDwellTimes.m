function DwellStats = StateDwellTimes(states, timestamps, options)
%STATEDWELLTIMES Calculates and histograms the dwell time for each HMM state.
%   DwellStats = mlt.hmm.StateDwellTimes(states, timestamps) takes the output
%   from mlt.hmm.hmmAnalysis and calculates the duration of each consecutive
%   period spent in a given state. It then computes a histogram of these
%   durations for each state.
%
%   SYNTAX:
%   DwellStats = mlt.hmm.StateDwellTimes(states, timestamps)
%   DwellStats = mlt.hmm.StateDwellTimes(states, timestamps, 'timeBins', my_bins)
%
%   INPUTS:
%   states              - A vector of integer state assignments, e.g., from
%                         mlt.hmm.hmmAnalysis.
%   timestamps          - A vector of timestamps corresponding to each state
%                         assignment. Can be numeric (seconds) or datetime.
%                         Must be evenly spaced.
%
%   OPTIONAL NAME-VALUE PAIR ARGUMENTS:
%   'timeBins'          - A vector of bin edges for the histogram.
%                         Default: 100 log-spaced bins from 0.1s to 3600s.
%
%   OUTPUTS:
%   DwellStats          - A structure array with one entry for each state.
%                         Each element has the fields:
%                         - .state: The state number.
%                         - .histBinTimes: The center time of each histogram bin (s).
%                         - .histBinCount: The number of dwells in each bin.
%
%   EXAMPLE & PLOTTING:
%       % First, run the main analysis pipeline
%       [states, timestamps] = mlt.hmm.hmmAnalysis(beat_times);
%
%       % Now, calculate the dwell time statistics
%       DwellStats = mlt.hmm.StateDwellTimes(states, timestamps);
%
%       % Finally, generate the plot with the dedicated plotting function
%       mlt.plot.plotDwellTimes(DwellStats);

    % --- Input Argument Validation ---
    arguments
        states (:,1) {mustBeVector, mustBeInteger, mustBePositive}
        timestamps {mustBeVector, mustBeNonempty, mustHaveSameSize(states, timestamps)}
        options.timeBins (1,:) double = logspace(log10(0.1), log10(3600), 100)
    end

    % --- Calculate Time Step ---
    % Determine the time difference between consecutive bins in seconds.
    if isdatetime(timestamps)
        if numel(timestamps) > 1
            dt = seconds(timestamps(2) - timestamps(1));
        else
            dt = 1; % Assume 1s if only one timestamp
        end
    else
        if numel(timestamps) > 1
            dt = timestamps(2) - timestamps(1);
        else
            dt = 1;
        end
    end
    
    % --- Calculate Durations of Consecutive States (Run-Length Encoding) ---
    
    % Find indices where the state changes
    change_indices = [true; diff(states) ~= 0];
    
    % Get the length of each run of consecutive identical states
    run_lengths = diff(find([change_indices; true]));
    
    % Get the state value for each run
    run_values = states(change_indices);
    
    % Calculate the duration in seconds for each run
    run_durations_sec = run_lengths * dt;

    % --- Compute Histogram for Each State ---
    num_states = max(states);
    
    % Pre-allocate the output structure array
    DwellStats = struct('state', cell(1, num_states), ...
                        'histBinTimes', cell(1, num_states), ...
                        'histBinCount', cell(1, num_states));

    for i = 1:num_states
        % Get all dwell durations for the current state
        state_durations = run_durations_sec(run_values == i);
        
        % Compute the histogram using the specified bins
        [counts, edges] = histcounts(state_durations, options.timeBins);
        
        % Calculate the center of each bin for plotting
        bin_centers = edges(1:end-1) + diff(edges)/2;
        
        % Store results in the output structure
        DwellStats(i).state = i;
        DwellStats(i).histBinTimes = bin_centers;
        DwellStats(i).histBinCount = counts;
    end
end

function mustHaveSameSize(a, b)
    % Custom validation function to ensure inputs have the same number of elements
    if numel(a) ~= numel(b)
        eid = 'mlt:sizeMismatch';
        msg = 'Inputs ''states'' and ''timestamps'' must have the same number of elements.';
        throwAsCaller(MException(eid, msg));
    end
end
