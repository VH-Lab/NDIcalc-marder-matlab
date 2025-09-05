function ax = HeartBeatFromDocs(S, options)
%HEARTBEATFROMDOCS - Plots beat statistics overlaid on the raw PPG signal.
%
%   AX = mlt.plot.HeartBeatFromDocs(S)
%
%   This function visualizes pre-calculated heart beat statistics by
%   overlaying them on top of the **raw, unnormalized** PPG signal.
%
%   The beat statistics (such as onset times, frequency, and duty cycle),
%   which are derived from a **normalized** version of the PPG data, are
%   loaded from an NDI document. This allows for a direct comparison
%   between the calculated beats and the original, unprocessed signal shown
%   in the plot background. A separate figure is generated for each PPG probe.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object containing the PPG data.
%
%   Optional Name-Value Pairs:
%       Linewidth (1,1) double = 1;
%           The line width to use for the plots.
%
%   Outputs:
%       AX - A column vector of axes handles. Each set of 3 axes handles
%            (corresponding to the 3 subplots in a figure) is concatenated
%            vertically.
%
%   Example 1: Basic usage
%       % Assuming 'mySession' is an ndi.session object
%       ax = mlt.plot.HeartBeatFromDocs(mySession);
%
%   Example 2: Specifying a custom line width
%       ax = mlt.plot.HeartBeatFromDocs(mySession, 'Linewidth', 2);
%
%   See also mlt.plot.HeartBeat, ndi.session, ndi.document

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.Linewidth (1,1) double = 1
end

p = S.getprobes('type','ppg');
ax = [];

for i=1:numel(p)
    % Get the specified ndi.element
    disp(['Processing element ' p{i}.elementstring '...']);
    e_cell = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e_cell)
        error(['No ''_lp_whole'' version of ' p{i}.elementstring ' found.']);
    end
    e = e_cell{1};
    et = e.epochtable();

    % Get the specified document containing beat data
    doc = ndi.database.fun.finddocs_elementEpochType(S,e.id(),et(1).epoch_id,'ppg_beats');
    if isempty(doc)
        error(['Beats document must be created for ' p{i}.elementstring ' prior to plotting.']);
    elseif isscalar(doc)
        doc = doc{1};
    else
        error('More than one beats document found for this element and epoch.');
    end

    % Determine the correct time reference (global or local)
    epoch_clocks = et(1).epoch_clock;
    ecs = cellfun(@(c) c.type, epoch_clocks, 'UniformOutput', false);
    clock_ind = find(cellfun(@(x) ndi.time.clocktype.isGlobal(x), epoch_clocks), 1);
    clock_local_ind = find(contains(ecs, 'dev_local_time'), 1);

    use_global_clock = ~isempty(clock_ind);
    if ~use_global_clock
        clock_ind = clock_local_ind;
        if isempty(clock_ind)
            error('No global or local clock found for this element.');
        end
    end

    % Get relevant time series data
    t0_t1 = et(1).t0_t1{clock_ind};
    tr = ndi.time.timereference(e, epoch_clocks{clock_ind}, [], 0);
    [d,t] = e.readtimeseries(tr, t0_t1(1), t0_t1(2));
    
    % Retrieve beats from the document
    [beats] = mlt.beats.beatsdoc2struct(S, doc);

    % Reformat onset and offset times to match the chosen clock type
    if use_global_clock
        t = datetime(t, 'ConvertFrom', 'datenum');
        beats = struct2table(beats);
        
        tr_local = ndi.time.timereference(e, epoch_clocks{clock_local_ind}, 1, 0);
        t0 = S.syncgraph.time_convert(tr_local, et(1).t0_t1{clock_local_ind}(1),...
            e.underlying_element, epoch_clocks{clock_ind});
        t0_datetime = datetime(t0, 'ConvertFrom', 'datenum');
        
        beats.onset = seconds(beats.onset) + t0_datetime;
        beats.offset = seconds(beats.offset) + t0_datetime;
        beats = table2struct(beats);
    end

    % Plot beats using the core plotting function
    ax_here = mlt.plot.HeartBeat(beats, d, t, 'Linewidth', options.Linewidth);
    ax = [ax; ax_here(:)]; % Append axes handles
    
    % Add a title to the new figure
    figure(get(ax_here(1), 'Parent'));
    sgtitle(e.elementstring, 'Interpreter', 'none');
end