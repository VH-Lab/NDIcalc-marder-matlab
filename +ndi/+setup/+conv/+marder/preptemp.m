function [out] = preptemp(t, d, temp_table, options)
    % PREPTEMP - Identify temperature parameters from a temperature recording.
    %
    % OUT = PREPTEMP(T, D, TEMP_TABLE, [OPTIONS])
    %
    % Analyzes a temperature recording to determine if it represents a constant
    % temperature or a temperature change. It matches the observed temperatures
    % to a provided table of command temperatures.
    %
    % INPUTS:
    %   t: (array) A vector of timestamps for the temperature data.
    %   d: (array) A vector of temperature data in degrees Celsius.
    %   temp_table: (array) A vector of possible command temperatures.
    %   OPTIONS: (Optional) A struct with the following fields:
    %     change_threshold: (double) The temperature range threshold to classify
    %                       a recording as a 'change'. Default is 3.
    %     beginning_time: (double) The duration in seconds at the start of the
    %                     record to average for the initial temperature. Default is 2.
    %     ending_time: (double) The duration in seconds at the end of the record
    %                  to average for the final temperature. Default is 2.
    %     filter: (array) A convolution filter to smooth the temperature data.
    %             Default is `ones(5,1)/5`.
    %     interactive: (logical) If true, prompts the user for input. Default is false.
    %
    % OUTPUTS:
    %   out: (struct) A structure containing the analysis results, with fields:
    %     type: ('constant' or 'change') The classification of the recording.
    %     temp: (array) The matching command temperature(s) from temp_table.
    %           One value for 'constant', two for 'change' (start and end).
    %     raw: (array) The raw (averaged) temperature value(s).
    %     range: (double) The observed temperature range in the recording.
    %
    % EXAMPLE:
    %   t = 0:0.1:10;
    %   d = 10 + 15 * (t/10); % Ramp from 10 to 25 degrees
    %   temp_table = [10, 15, 20, 25];
    %   out = ndi.setup.conv.marder.preptemp(t, d, temp_table);
    %   % out.type will be 'change'
    %   % out.temp will be [10 25]
    %
    % See also: ndi.setup.conv.marder.preptemptable, conv, vlt.data.findclosest

    arguments
        t
        d
        temp_table
        options.change_threshold = 3
        options.beginning_time = 2
        options.ending_time = 2
        options.filter = ones(5,1)/5;
        options.interactive = false
    end

    % filter the signal

    fs = numel(options.filter);
    pad0 = repmat(d(1),fs,1);
    pad1 = repmat(d(end),fs,1);

    filtered_signal = conv( [pad0; d(:); pad1], options.filter,'same');
    filtered_signal = filtered_signal(fs+1:end-fs);

    range = max(filtered_signal(:)) - min(filtered_signal(:));

    if range<options.change_threshold
        type = 'constant';
        raw = mean(filtered_signal);
        [i,temp] = vlt.data.findclosest(temp_table,raw);
    else
        type = 'change';
        i0 = find(t<=options.beginning_time);
        i1 = find(t>=(t(end)-options.ending_time));
        i1(i1>numel(filtered_signal)) = [];
        raw = [ mean(filtered_signal(i0)) mean(filtered_signal(i1)) ];
        [i,temp0] = vlt.data.findclosest(temp_table,raw(1));
        [i,temp1] = vlt.data.findclosest(temp_table,raw(2));
        temp = [ temp0 temp1 ];
    end

    out = vlt.data.var2struct('type','temp','raw','range');
