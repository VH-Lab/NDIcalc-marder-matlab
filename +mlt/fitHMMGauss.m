function model = fitHMMGauss(rates, N, options)
%FITHMMGAUSS Fits a Hidden Markov Model with Gaussian emissions using BNT.
%   model = mlt.fitHMMGauss(rates, N) fits an N-state HMM to the
%   continuous rate data using Gaussian distributions for the emissions.
%
%   *** REQUIRES KEVIN MURPHY'S BAYES NET TOOLBOX (BNT) ***
%   Download from: https://github.com/bayesnet/bnt
%   And add to your MATLAB path using: addpath(genpath('path/to/bnt'))
%
%   The states are sorted by their mean emission rate (lowest to highest).
%
%   INPUTS:
%   rates               - A vector of observed continuous rates.
%   N                   - The number of hidden states for the model.
%
%   OPTIONAL NAME-VALUE PAIR ARGUMENTS:
%   'MaxIterations'     - Maximum number of iterations for the EM algorithm.
%                         Default: 100.
%
%   OUTPUTS:
%   model               - A struct containing the trained HMM parameters.

    % --- Input Argument Validation ---
    arguments
        rates {mustBeVector, mustBeNumeric, mustBeNonempty}
        N (1,1) double {mustBeInteger, mustBePositive}
        options.MaxIterations (1,1) double {mustBeInteger, mustBePositive} = 100
    end

    if ~exist('mhmm_em', 'file')
        error('mlt:bntNotFound', ...
            ['Kevin Murphy''s BNT not found or path is incorrect. Please check setup.\n' ...
             'See: https://github.com/bayesnet/bnt']);
    end

    % Ensure rates is a column vector for consistency within this function
    rates = rates(:);

    % BNT expects data in a cell array of sequences, with dimensions [ObsDim x T]
    data = {rates'};
    O = 1; % Observation dimension (1D rates)
    M = 1; % Number of mixtures per state (we use a single Gaussian)
    Q = N; % Number of hidden states

    % --- Add specific check for number of data points vs. states ---
    if numel(rates) <= Q
        error('mlt:insufficientDataForStates', ...
            ['The number of binned rates (%d) is not greater than the number of requested HMM states (%d).\n\n' ...
             'This is likely caused by one of two things:\n' ...
             '1) The total time duration of your beat data is too short.\n' ...
             '2) The ''deltaT'' parameter for binning is too large relative to the total duration.\n\n' ...
             'Please check the duration of your data (e.g., beat_times(end)-beat_times(1)) and your ''deltaT'' setting.'], ...
             numel(rates), Q);
    end

    % --- Step 1: Initialize Model Parameters ---
    
    % Use k-means to get a good initial guess for the means.
    % kmeans expects each row to be an observation, so rates must be a column vector.
    [idx, mu0] = kmeans(rates, Q, 'Replicates', 5);
    
    % Initialize covariance for each state based on kmeans clusters
    Sigma0 = zeros(O, O, Q, M);
    for i=1:Q
        rates_in_state = rates(idx == i);
        if numel(rates_in_state) > 1
            Sigma0(:,:,i,1) = cov(rates_in_state);
        else
            Sigma0(:,:,i,1) = cov(rates); % Fallback to overall variance
        end
    end

    % Prevent covariance from being singular
    Sigma0(Sigma0 < 1e-6) = 1e-6;

    prior0 = normalise(rand(Q,1));
    transmat0 = mk_stochastic(rand(Q,Q));
    mixmat0 = mk_stochastic(rand(Q,M));

    % --- Step 2: Train the Model using BNT's mhmm_em ---
    % Note: mhmm_em expects mu0 to be [ObsDim x NumStates x NumMixes]
    [~, prior1, transmat1, mu1, Sigma1, mixmat1] = ...
        mhmm_em(data, prior0, transmat0, mu0', Sigma0, mixmat0, ...
                   'max_iter', options.MaxIterations);

    % --- Step 3: Sort States by Mean Rate ---
    [~, sort_order] = sort(mu1, 'ascend');
    
    % --- Step 4: Create the final model struct with correctly shaped parameters ---
    model.prior = prior1(sort_order);
    model.transmat = transmat1(sort_order, sort_order);
    
    % Reshape mu and Sigma to the shape BNT's other functions expect
    % mu should be [ObsDim x NumStates x NumMixes]
    % Sigma should be [ObsDim x ObsDim x NumStates x NumMixes]
    model.mu = reshape(mu1(:, sort_order), [O, Q, M]);
    model.Sigma = reshape(Sigma1(:,:, sort_order), [O, O, Q, M]);
    model.mixmat = mixmat1(sort_order,:);

    % Create the remapping vector for the decoder
    remap_vector = zeros(1, N);
    remap_vector(sort_order) = 1:N;
    model.StateRemap = remap_vector;
end
