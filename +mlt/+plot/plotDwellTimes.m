function fig_handle = plotDwellTimes(DwellStats)
%PLOTDWELLTIMES Plots dwell time histograms for up to 4 HMM states.
%   fig_handle = mlt.plotDwellTimes(DwellStats) creates a figure with a
%   2x2 subplot layout, showing the dwell time distribution for each state.
%
%   This function is designed to work directly with the output structure
%   from the mlt.StateDwellTimes function.
%
%   INPUTS:
%   DwellStats      - The structure array output from mlt.StateDwellTimes.
%
%   OUTPUTS:
%   fig_handle      - A handle to the created figure.
%
%   EXAMPLE:
%       % First, run the analysis pipeline and calculate dwell times
%       [states, timestamps] = mlt.hmmAnalysis(beat_times);
%       DwellStats = mlt.StateDwellTimes(states, timestamps);
%
%       % Now, generate the plot with a single command
%       mlt.plotDwellTimes(DwellStats);

    % --- Input Argument Validation ---
    arguments
        DwellStats (1,:) struct {mustContainFields(DwellStats, ["state", "histBinTimes", "histBinCount"])}
    end

    fig_handle = figure;
    
    num_states_to_plot = min(numel(DwellStats), 4);
    
    if num_states_to_plot == 0
        warning('mlt:noDataToPlot', 'DwellStats structure is empty. Nothing to plot.');
        return;
    end
    
    if num_states_to_plot > 4
        warning('mlt:tooManyStates', 'This function only plots up to 4 states. Plotting the first 4.');
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
        if ~isempty(DwellStats(i).histBinTimes)
            min_time = min(DwellStats(i).histBinTimes) / 2;
            max_time = max(DwellStats(i).histBinTimes) * 2;
            xlim([min_time, max_time]);
        end
    end
    
    % Add a main title to the figure if there are multiple subplots
    if num_states_to_plot > 1
        sgtitle('HMM State Dwell Time Distributions');
    end

end

function mustContainFields(s, fields)
    % Custom validation function to ensure struct has the required fields
    if ~isfield(s, fields)
        eid = 'mlt:missingFields';
        msg = sprintf('Input struct must contain the fields: %s.', strjoin(fields, ', '));
        throwAsCaller(MException(eid, msg));
    end
end
