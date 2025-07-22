function [states, timestamps, rates, state_stats] = hmmAnalysis(beat_times, options)
%HMMANALYSIS Performs a full HMM analysis pipeline on beat time data.
%   ... = mlt.hmmAnalysis(beat_times, 'ModelType', type) allows choosing
%   between a 'discrete' model (using MATLAB's built-in tools) or a
%   'gaussian' model (requires Kevin Murphy's BNT).
%
%   SYNTAX:
%   [states, timestamps, rates] = mlt.hmmAnalysis(beat_times)
%   [states, timestamps, rates, state_stats] = mlt.hmmAnalysis(beat_times, 'N', 3, 'ModelType', 'gaussian')
%
%   INPUTS:
%   beat_times          - A vector of beat times (numeric seconds or datetime).
%
%   OPTIONAL NAME-VALUE PAIR ARGUMENTS:
%   'N'                 - Number of hidden states. Default: 2.
%   'ModelType'         - 'discrete' or 'gaussian'. Default: 'discrete'.
%                         'gaussian' requires Kevin Murphy's BNT.
%   'deltaT'            - Time step for rate binning (s). Default: 0.5.
%   'W'                 - Window size for rate binning (s). Default: 5.
%
%   (For 'discrete' model only)
%   'NumSymbols'        - Number of discrete symbols for quantization. Default: 10.
%   'Tolerance'         - Convergence tolerance for HMM training. Default: 1e-4.
%
%   (For 'gaussian' model only)
%   'MaxIterations'     - Max iterations for EM training. Default: 100.
%
%   OUTPUTS:
%   states              - Vector of the most likely (sorted) state for each bin.
%   timestamps          - Timestamps for the center of each bin.
%   rates               - The calculated beat rate (Hz) for each bin.
%   state_stats         - (Optional) N-by-2 matrix of [mean_rate, std_rate]
%                         for each sorted state.

    % --- Input Argument Validation ---
    arguments
        beat_times {mustBeVector, mustBeNonempty, mustBeSorted, mustBeA(beat_times, ["double", "datetime"])}
        options.N (1,1) double {mustBeInteger, mustBePositive} = 2
        options.ModelType (1,1) string {mustBeMember(options.ModelType, ["discrete", "gaussian"])} = "discrete"
        options.deltaT (1,1) double {mustBePositive} = 0.5
        options.W (1,1) double {mustBePositive} = 5
        % Options for discrete model
        options.NumSymbols (1,1) double {mustBeInteger, mustBePositive} = 10
        options.Tolerance (1,1) double {mustBePositive} = 1e-4
        % Options for gaussian model
        options.MaxIterations (1,1) double {mustBeInteger, mustBePositive} = 100
    end

    % --- Step 1: Calculate Binned Beat Rate ---
    fprintf('Step 1: Calculating binned beat rates...\n');
    [rates, timestamps] = mlt.beatRateBins(beat_times, ...
        'deltaT', options.deltaT, 'W', options.W);

    % --- Step 2 & 3: Fit Model and Decode based on selected type ---
    if strcmpi(options.ModelType, "discrete")
        fprintf('Step 2: Fitting %d-state DISCRETE HMM...\n', options.N);
        [TRANS, EMIS, state_stats, fit_info] = mlt.fitHMM(rates, options.N, ...
            'NumSymbols', options.NumSymbols, ...
            'MaxIterations', options.MaxIterations, 'Tolerance', options.Tolerance);
        
        fprintf('Step 3: Decoding state sequence...\n');
        states = mlt.decodeHMM(rates, TRANS, EMIS, fit_info);

    elseif strcmpi(options.ModelType, "gaussian")
        fprintf('Step 2: Fitting %d-state GAUSSIAN HMM (using BNT)...\n', options.N);
        model = mlt.fitHMMGauss(rates, options.N, ...
            'MaxIterations', options.MaxIterations);
        
        fprintf('Step 3: Decoding state sequence...\n');
        states = mlt.decodeHMMGauss(rates, model);
        
        % Construct state_stats output for consistency
        % Squeeze removes singleton dimensions, ensuring vectors are correct shape for concatenation
        state_stats = [squeeze(model.mu)', sqrt(squeeze(model.Sigma))];
    end
    
    fprintf('HMM analysis complete.\n');
    % Display the final state statistics
    disp('Final Sorted State Statistics:');
    disp('State | Mean Rate | Std Dev Rate');
    disp('----------------------------------');
    for i = 1:options.N
        fprintf('%5d | %9.3f | %12.3f\n', i, state_stats(i,1), state_stats(i,2));
    end
end

function mustBeSorted(a)
    if ~issorted(a)
        eid = 'mlt:notSorted';
        msg = 'Input beat_times vector must be chronologically sorted.';
        throwAsCaller(MException(eid, msg));
    end
end
