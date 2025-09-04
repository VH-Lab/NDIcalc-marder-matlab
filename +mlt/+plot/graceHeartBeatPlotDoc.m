function ax = graceHeartBeatPlotDoc(S, options)
% GRACEHEARTBEATPLOT - Plot heart beat statistics for PPG elements in an NDI session/dataset.
%
%   AX = GRACEHEARTBEATPLOT(S) plots heart beat statistics (raw PPG signal,
%   instantaneous beat frequency, and duty cycle) for all 'ppg' probes found
%   within the ndi.session or ndi.dataset object S.  A separate figure is
%   created for *each* 'ppg' probe.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object containing the PPG data.
%
%   Optional Inputs:
%       options.Linewidth (1,1) double = 1;
%           The line width to use for the plots (PPG signal, beat
%           frequency, and duty cycle).
%
%   Outputs:
%       AX - A column vector of axes handles.  Each set of 3 axes handles
%            (corresponding to the 3 subplots in a figure) is concatenated
%            vertically.  So, if there are two 'ppg' probes, AX will be a
%            6x1 vector.
%
%   Example 1: Basic usage
%       % Assuming 'mySession' is an ndi.session object
%       ax = graceHeartBeatPlot(mySession);
%
%   Example 2: Specifying a custom line width
%       ax = graceHeartBeatPlot(mySession, 'Linewidth', 2);
%
%   See also gracePlotHeartBeat, ndi.session, ndi.dataset

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.Linewidth (1,1) double = 1
end

p = S.getprobes('type','ppg');

path = S.path();

ax = [];

for i=1:numel(p)

    % Get the specified ndi.element
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e)
        error(['No ''_lp'' version of ' p{i}.elementstring]);
    end
    e = e{1};
    et = e.epochtable();

    % Get the specified document
    doc = ndi.database.fun.finddocs_elementEpochType(S,e.id(),et(1).epoch_id,'ppg_beats');
    if isempty(doc)
        error(['Beats document needs to be created for this session ' ...
            'prior to plotting.'])
    elseif isscalar(doc)
        doc = doc{1};
    else
        error(['More than one beats document found matching the ' ...
            'element and epoch id.'])
    end

    % Check if there is a global clock, if not, use dev_local_time
    epoch_clocks = et(1).epoch_clock;
    ecs = cellfun(@(c) c.type,epoch_clocks,'UniformOutput',false);
    clock_ind = find(cellfun(@(x) ndi.time.clocktype.isGlobal(x),epoch_clocks),1);
    clock_local_ind = find(contains(ecs,'dev_local_time'));
    if isempty(clock_ind)
        clock_ind = clock_local_ind;
        clock_global = false;
        if isempty(clock_ind)
            error('No global or local clock found in this elements epochtable.')
        end
    else
        clock_global = true;
    end

    % Get relevant time series
    t0_t1 = et(1).t0_t1{clock_ind};
    tr = ndi.time.timereference(e,epoch_clocks{clock_ind},[],0);
    [d,t] = e.readtimeseries(tr,t0_t1(1),t0_t1(2));
    if clock_global
        t = datetime(t,'convertFrom','datenum');
    end

    % Retrieve beats
    [beats] = mlt.beatsdoc2struct(S,doc);

    % Reformat onset and offset times to match clocktype
    if clock_global
        beats = struct2table(beats);
        tr_local = ndi.time.timereference(e,epoch_clocks{clock_local_ind},1,0);
        t0 = S.syncgraph.time_convert(tr_local,et(1).t0_t1{clock_local_ind}(1),...
            e.underlying_element,epoch_clocks{clock_ind});
        t0 = datetime(t0,'ConvertFrom','datenum');
        beats.onset = seconds(beats.onset) + t0;
        beats.offset = seconds(beats.offset) + t0;
        beats = table2struct(beats);
    end

    % Plot beats
    ax_here = mlt.gracePlotHeartBeat(beats, d, t, 'Linewidth', options.Linewidth);
    ax = cat(1,ax,ax_here(:));
    figure(get(ax_here(1), 'Parent'));
    sgtitle([e.elementstring],'interp','none');
end