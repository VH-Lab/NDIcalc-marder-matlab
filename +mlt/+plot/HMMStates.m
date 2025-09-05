function ax = HMMStates(states, timestamps, rates, options)
%HMMSTATES Plots HMM states and beat rates on a dual-y-axis plot.
%
%   AX = mlt.plot.HMMStates(states, timestamps, rates)
%
%   Creates a plot that visualizes the output of an HMM analysis. It plots
%   the continuous beat rate signal on the left y-axis and the corresponding
%   discrete HMM state sequence on the right y-axis.
%
%   The y-axes are scaled relative to each other for intuitive comparison:
%   - The value '1' on the right (State) axis aligns with '0' on the left
%     (Rate) axis.
%   - The highest state number on the right axis aligns with the maximum
%     value of the plotted rate data on the left axis.
%
%   Inputs:
%       states          - A vector of integer HMM state assignments.
%       timestamps      - A vector of time values (numeric or datetime)
%                         corresponding to the states and rates.
%       rates           - A vector of beat rates (Hz) corresponding to the
%                         timestamps.
%
%   Optional Name-Value Pair Arguments:
%       Linewidth (1,1) double = 1.5
%           Line width for both the rate and state plots.
%       RateColor (1,3) double = [0 0.4470 0.7410] (MATLAB blue)
%           Color for the beat rate plot.
%       StateColor (1,3) double = [0.8500 0.3250 0.0980] (MATLAB orange)
%           Color for the HMM state plot.
%
%   Outputs:
%       ax              - A struct containing the handles to the two axes
%                         (ax.RateAxis and ax.StateAxis).
%
%   Example:
%       % First, run the main analysis pipeline to get the required inputs
%       L = load('ppg_ppg_heart_lp_whole_1_beats.mat');
%       beat_times = [L.beats.onset];
%       [states, timestamps, rates, ~] = mlt.hmm.Analysis(beat_times);
%
%       % Now, generate the specialized plot
%       ax = mlt.plot.HMMStates(states, timestamps, rates);
%
%   See also mlt.hmm.Analysis, yyaxis

% --- Input Argument Validation ---
arguments
    states {mustBeVector, mustBeInteger, mustBeNonempty}
    timestamps {mustBeVector, mustBeNonempty, mustHaveSameSize(states, timestamps), mustBeA(timestamps, ["double", "datetime"])}
    rates {mustBeVector, mustBeNonempty, mustHaveSameSize(rates, timestamps)}
    options.Linewidth (1,1) double {mustBePositive} = 1.5
    options.RateColor (1,3) double {mustBeInRange(options.RateColor, 0, 1)} = [0 0.4470 0.7410]
    options.StateColor (1,3) double {mustBeInRange(options.StateColor, 0, 1)} = [0.8500 0.3250 0.0980]
end

% --- Plotting ---
figure;

% --- Left Y-Axis: Beat Rate ---
yyaxis left;
plot(timestamps, rates, 'LineWidth', options.Linewidth, 'Color', options.RateColor);
ylabel('Beat Rate (Hz)');
ax.RateAxis = gca;
ax.RateAxis.YColor = options.RateColor;

% Get the limits of the rate axis to scale the state axis
ylim_left = ylim(ax.RateAxis);
y_min_left = ylim_left(1);
y_max_left = ylim_left(2);

% --- Right Y-Axis: HMM State ---
yyaxis right;
% Use stairs for a clear, discrete representation of state changes
stairs(timestamps, states, 'LineWidth', options.Linewidth, 'Color', options.StateColor);
ylabel('HMM State');
ax.StateAxis = gca;
ax.StateAxis.YColor = options.StateColor;

num_states = max(states);

% --- Custom Axis Scaling ---
% This logic rescales the right axis to align with the left as specified.
if y_max_left > 0
    % Calculate the slope (m) and intercept (c) of the linear mapping:
    % y_right = m * y_left + c
    % We know: 1 = m*0 + c  => c = 1
    % And: num_states = m*y_max_left + c => m = (num_states - 1) / y_max_left
    m = (num_states - 1) / y_max_left;
    c = 1;
    
    % Now find the right-axis y-min that corresponds to the left-axis y-min
    y_min_right = m * y_min_left + c;
    
    % Set the right-axis limits and ticks
    ylim([y_min_right, num_states]);
    yticks(1:num_states);
else
    % Fallback for unusual data (e.g., all rates are zero or negative)
    ylim([0.5, num_states + 0.5]);
    yticks(1:num_states);
end

% --- Final Touches ---
if isdatetime(timestamps)
    xlabel('Time');
else
    xlabel('Time (seconds)');
end
title('HMM States and Beat Rate Over Time');
grid on;

end

function mustHaveSameSize(a, b)
    % Custom validation function to ensure inputs have the same number of elements
    if numel(a) ~= numel(b)
        eid = 'mlt:sizeMismatch';
        msg = 'Inputs must have the same number of elements.';
        throwAsCaller(MException(eid, msg));
    end
end