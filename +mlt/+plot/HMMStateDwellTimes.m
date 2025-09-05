function fig_handle = HMMStateDwellTimes(DwellStats)
%HMMSTATEDWELLTIMES Plots dwell time histograms for Hidden Markov Model (HMM) states.
%
%   FIG_HANDLE = mlt.plot.HMMStateDwellTimes(DwellStats)
%
%   Creates a figure with up to a 2x2 subplot layout, showing the dwell
%   time distribution for each HMM state on a logarithmic time axis. This
%   function is designed to work directly with the output structure from
%   the mlt.hmm.StateDwellTimes function.
%
%   Inputs:
%       DwellStats - A structure array output from mlt.hmm.StateDwellTimes.
%                    It must contain the fields "state", "histBinTimes",
%                    and "histBinCount".
%
%   Outputs:
%       fig_handle - A handle to the created figure.
%
%   Example:
%       % First, run the HMM analysis pipeline and calculate dwell times
%       [states, timestamps] = mlt.hmm.Analysis(beat_times);
%       DwellStats = mlt.hmm.StateDwellTimes(states, timestamps);
%
%       % Now, generate the plot with a single command
%       fig_handle = mlt.plot.HMMStateDwellTimes(DwellStats);
%
%   See also mlt.hmm.Analysis, mlt.hmm.StateDwellTimes

% --- Input Argument Validation ---
arguments
    DwellStats (1,:) struct {mustContainFields(DwellStats, ["state", "histBinTimes", "histBinCount"])}
end

fig_handle = figure;

num_states_to_plot = min(numel(DwellStats), 4);

if num_states_to_plot == 0
    warning('mlt:noDataToPlot', 'DwellStats structure is empty. Nothing to plot.');
    close(fig_handle); % Close the empty figure
    fig_handle = gobjects(0); % Return an empty handle
    return;
end

if numel(DwellStats) > 4
    warning('mlt:tooManyStates', 'Input has %d states; this function only plots the first 4.', numel(DwellStats));
end

for i = 1:num_states_to_plot
    % Create a subplot in a 2x2 grid
    subplot(2, 2, i);
    
    % Use a bar plot for the histogram. '1' makes the bars touch.
    bar(DwellStats(i).histBinTimes, DwellStats(i).histBinCount, 1);
    
    % Set the x-axis to a logarithmic scale to see the full range
    set(gca, 'XScale', 'log');
    
    title(sprintf('State %d Dwell Time Distribution', DwellStats(i).state));
    xlabel('Dwell Duration (seconds)');
    ylabel('Count');
    grid on;
    
    % Set x-limits based on the histogram bin range
    if ~isempty(DwellStats(i).histBinTimes) && numel(DwellStats(i).histBinTimes) > 1
        min_time = min(DwellStats(i).histBinTimes(DwellStats(i).histBinTimes>0)) / 2;
        max_time = max(DwellStats(i).histBinTimes) * 2;
        xlim([min_time, max_time]);
    end
end

% Add a main title to the figure
sgtitle('HMM State Dwell Time Distributions');

end

function mustContainFields(s, fields)
    % Custom validation function to ensure struct has the required fields
    if ~isfield(s, fields)
        eid = 'mlt:missingFields';
        msg = sprintf('Input struct must contain the fields: %s.', strjoin(fields, ', '));
        throwAsCaller(MException(eid, msg));
    end
end