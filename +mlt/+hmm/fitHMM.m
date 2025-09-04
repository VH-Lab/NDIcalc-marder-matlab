function [TRANS, EMIS, state_stats, fit_info] = fitHMM(rates, N, options)
%FITHMM Fits a discrete HMM and characterizes states by rate statistics.
%   [TRANS, EMIS, state_stats, fit_info] = mlt.hmm.fitHMM(rates, N) fits an
%   N-state HMM to the rate data. It uses a discrete emission model, which
%   is required by MATLAB's hmmtrain function.
%
%   After fitting, it characterizes each state by the mean and standard
%   deviation of the continuous rates that were assigned to it. The states
%   are then sorted and re-ordered based on this mean rate (lowest to highest).
%
%   INPUTS:
%   rates               - A vector of observed rates, e.g., from mlt.beats.beatRateBins.
%   N                   - The number of hidden states for the model.
%
%   OPTIONAL NAME-VALUE PAIR ARGUMENTS:
%   'NumSymbols'        - The number of discrete symbols to quantize the
%                         'rates' data into. Default: 10.
%   'MaxIterations'     - Maximum number of iterations for the Baum-Welch
%                         algorithm. Default: 100.
%   'Tolerance'         - Convergence tolerance for the Baum-Welch
%                         algorithm. Default: 1e-4.
%
%   OUTPUTS:
%   TRANS               - An N-by-N matrix of sorted state transition probabilities.
%   EMIS                - An N-by-NumSymbols sorted emission probability matrix.
%   state_stats         - An N-by-2 matrix where column 1 is the mean rate
%                         and column 2 is the std. dev. of the rate for each
%                         sorted state.
%   fit_info            - A struct containing information needed for decoding.

    % --- Input Argument Validation ---
    arguments
        rates {mustBeVector, mustBeNumeric, mustBeNonempty}
        N (1,1) double {mustBeInteger, mustBePositive}
        options.NumSymbols (1,1) double {mustBeInteger, mustBePositive} = 10
        options.MaxIterations (1,1) double {mustBeInteger, mustBePositive} = 100
        options.Tolerance (1,1) double {mustBePositive} = 1e-4
    end

    rates = rates(:)';
    
    % --- Step 1: Quantize Continuous Data using the helper function ---
    [discrete_seq, edges] = mlt.beats.beatRateBinQuantize(rates, options.NumSymbols);
    fit_info.Edges = edges;
    
    % --- Step 2: Generate Initial Guesses and Train the Discrete HMM ---
    M = options.NumSymbols;
    TRANS_GUESS = rand(N);
    TRANS_GUESS = TRANS_GUESS ./ sum(TRANS_GUESS, 2);
    EMIS_GUESS = rand(N, M);
    EMIS_GUESS = EMIS_GUESS ./ sum(EMIS_GUESS, 2);

    [temp_TRANS, temp_EMIS] = hmmtrain(discrete_seq, TRANS_GUESS, EMIS_GUESS, ...
        'Symbols', 1:M, ...
        'Maxiterations', options.MaxIterations, ...
        'Tolerance', options.Tolerance, ...
        'Verbose', false);

    % --- Step 3: Characterize and Sort States ---
    
    % Find the most likely state sequence for the training data using the raw model
    training_states = hmmviterbi(discrete_seq, temp_TRANS, temp_EMIS, 'Symbols', 1:M);
    
    % Calculate the mean and std dev of the original rates for each state
    temp_state_stats = zeros(N, 2);
    for i = 1:N
        rates_in_state = rates(training_states == i);
        if ~isempty(rates_in_state)
            temp_state_stats(i, 1) = mean(rates_in_state);
            temp_state_stats(i, 2) = std(rates_in_state);
        else
            % Handle case where a state is not used in the Viterbi path
            temp_state_stats(i, 1) = NaN;
            temp_state_stats(i, 2) = NaN;
        end
    end
    
    % Sort states based on the calculated mean rate (lowest to highest)
    [~, sort_order] = sort(temp_state_stats(:,1), 'ascend');
    
    % Re-order all model parameters based on the sort order
    TRANS = temp_TRANS(sort_order, sort_order);
    EMIS = temp_EMIS(sort_order, :);
    state_stats = temp_state_stats(sort_order, :);
    
    % Create a mapping to convert the original state numbers to the new sorted order.
    remap_vector = zeros(1, N);
    remap_vector(sort_order) = 1:N;
    fit_info.StateRemap = remap_vector;
end
