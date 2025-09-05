function [states, timestamps, rates, state_stats] = Analysis(beat_times, options)
%ANALYSIS Performs a full HMM analysis pipeline on beat time data.
%
%   [states, timestamps, rates, state_stats] = mlt.hmm.Analysis(beat_times)
%
%   This high-level function runs a complete Hidden Markov Model (HMM)
%   pipeline. It takes a vector of beat times, calculates a continuous
%   beat rate signal, fits an HMM to this signal, and decodes the most
%   likely sequence of hidden states.
%
%   Inputs:
%       beat_times      - A vector of beat times (numeric seconds or datetime).
%
%   Optional Name-Value Pair Arguments:
%       N (1,1) double = 2
%           Number of hidden states.
%       ModelType (1,1) string = "gaussian"
%           Model to use: "discrete" or "gaussian". The "gaussian" model
%           requires Kevin Murphy's Bayes Net Toolbox (BNT).
%       InitialModel (1,1) struct = struct()
%           A pre-trained model struct (from mlt.hmm.fit or mlt.hmm.fitGauss).
%           If provided, the fitting step is skipped and this model is used
%           directly for decoding.
%       deltaT (1,1) double = 0.5
%           Time step for rate binning (seconds).
%       W (1,1) double = 5
%           Window size for rate binning (seconds).
%       (And other model-specific options for fitting...)
%
%   Outputs:
%       states          - Vector of the most likely (sorted) state for each bin.
%       timestamps      - Timestamps for the center of each bin.
%       rates           - The calculated beat rate (Hz) for each bin.
%       state_stats     - N-by-2 matrix of [mean_rate, std_dev_rate] for each state.
%
%   Example 1: Standard Fitting and Visualization
%       % First, load the beat times from a pre-processed _beats.mat file
%       L = load('ppg_ppg_heart_lp_whole_1_beats.mat');
%       beat_times = [L.beats.onset];
%
%       % Perform a 2-state Gaussian HMM analysis using default settings
%       [states, ts, rates, stats] = mlt.hmm.Analysis(beat_times);
%
%       % Visualize the state sequence overlaid on the beat rate
%       mlt.plot.HMMStates(states, ts, rates);
%
%       % Optionally, calculate and plot dwell time distributions
%       DwellStats = mlt.hmm.StateDwellTimes(states, ts);
%       mlt.plot.HMMStateDwellTimes(DwellStats);
%
%   Example 2: Using a Pre-Defined 'InitialModel' to Decode
%       % Define a fixed 2-state Gaussian model struct
%       myFixedModel.prior = [0.2; 0.8];
%       myFixedModel.transmat = [0.9 0.1; 0.1 0.9];
%       % BNT requires specific dimensions: [ObsDim x NumStates x NumMixes]
%       myFixedModel.mu = reshape([0 1], [1 2 1]);
%       % BNT requires specific dimensions: [ObsDim x ObsDim x NumStates x NumMixes]
%       myFixedModel.Sigma = reshape([0.05, 1], [1 1 2 1]);
%       myFixedModel.mixmat = ones(2, 1); % For a single Gaussian per state
%       myFixedModel.StateRemap = [1 2];
%
%       % Run analysis, which will now skip the fitting step
%       [states, ts, rates, stats] = mlt.hmm.Analysis(beat_times, ...
%           'ModelType', 'gaussian', ...
%           'InitialModel', myFixedModel);
%
%   See also mlt.hmm.fit, mlt.hmm.decode, mlt.hmm.fitGauss, mlt.hmm.decodeGauss, mlt.plot.HMMStates

    % --- Input Argument Validation ---
    arguments
        beat_times {mustBeVector, mustBeNonempty, mustBeSorted, mustBeA(beat_times, ["double", "datetime"])}
        options.N (1,1) double {mustBeInteger, mustBePositive} = 2
        options.ModelType (1,1) string {mustBeMember(options.ModelType, ["discrete", "gaussian"])} = "gaussian"
        options.InitialModel (1,1) struct = struct()
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
    [rates, timestamps] = mlt.beats.beatRateBins(beat_times, ...
        'deltaT', options.deltaT, 'W', options.W);

    % --- Step 2 & 3: Fit Model (if necessary) and Decode ---
    model_provided = ~isempty(fieldnames(options.InitialModel));

    if strcmpi(options.ModelType, "discrete")
        if model_provided
            fprintf('Step 2: Using provided DISCRETE HMM for decoding.\n');
            TRANS = options.InitialModel.TRANS;
            EMIS = options.InitialModel.EMIS;
            fit_info = options.InitialModel.fit_info;
            state_stats = options.InitialModel.state_stats;
        else
            fprintf('Step 2: Fitting %d-state DISCRETE HMM...\n', options.N);
            [TRANS, EMIS, state_stats, fit_info] = mlt.hmm.fit(rates, options.N, ...
                'NumSymbols', options.NumSymbols, ...
                'MaxIterations', options.MaxIterations, 'Tolerance', options.Tolerance);
        end
        fprintf('Step 3: Decoding state sequence...\n');
        states = mlt.hmm.decode(rates, TRANS, EMIS, fit_info);

    elseif strcmpi(options.ModelType, "gaussian")
        if model_provided
            fprintf('Step 2: Using provided GAUSSIAN HMM for decoding.\n');
            model = options.InitialModel;
        else
            fprintf('Step 2: Fitting %d-state GAUSSIAN HMM (using BNT)...\n', options.N);
            model = mlt.hmm.fitGauss(rates, options.N, ...
                'MaxIterations', options.MaxIterations);
        end
        fprintf('Step 3: Decoding state sequence...\n');
        states = mlt.hmm.decodeGauss(rates, model);

        % Construct state_stats output for consistency
        state_stats = [squeeze(model.mu)', sqrt(squeeze(model.Sigma))];
    end

    fprintf('HMM analysis complete.\n');
    % Display the final state statistics
    disp('Final Sorted State Statistics:');
    disp('State | Mean Rate | Std Dev Rate');
    disp('----------------------------------');
    for i = 1:size(state_stats, 1)
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