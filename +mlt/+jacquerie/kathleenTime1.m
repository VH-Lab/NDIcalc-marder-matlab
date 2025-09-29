function timeData = kathleenTime1(intervalWidthSeconds)
% kathleenTime1 defines datetime intervals and returns them in a structure.
% The structure array contains the interval and a temperature field.
%
% Syntax:
%   timeData = kathleenTime1()
%   timeData = kathleenTime1(intervalWidthSeconds)
%
% Description:
%   timeData = kathleenTime1() returns datetime intervals with a default
%   width of 180 seconds (3 minutes).
%
%   timeData = kathleenTime1(intervalWidthSeconds) returns datetime intervals
%   with a specified width in seconds.
%
% Example:
%   % Get time intervals for a 5-minute (300 second) window
%   myData = kathleenTime1(300);
%
% See also: kathleenTime2

arguments
    % The total width of the time interval in seconds.
    intervalWidthSeconds (1,1) {mustBeNumeric, mustBePositive} = 180
end

% --- Define Center Datetimes ---
% The year is assumed to be 2025. Please adjust if needed.
% Case 11: Corresponds to 8/19 at 12am (file: 994_52)
center_time_11 = datetime('2025-08-19 00:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
% Case 15: Corresponds to 8/27 at 12am (file: 994_60)
center_time_15 = datetime('2025-08-27 00:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
% Case 19: Corresponds to 9/3 at 12am (file: 994_62)
center_time_19 = datetime('2025-09-03 00:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');


% --- Calculate Intervals ---
% The interval is centered, so we go half the width before and after the
% center time.
half_interval = seconds(intervalWidthSeconds / 2);

% Calculate the start and end of the interval for each case
interval_11 = [center_time_11 - half_interval, center_time_11 + half_interval];
interval_15 = [center_time_15 - half_interval, center_time_15 + half_interval];
interval_19 = [center_time_19 - half_interval, center_time_19 + half_interval];


% --- Create Structure Array ---
% Create a structure array to hold the output data.
timeData(1).interval = interval_11;
timeData(1).temperature = 11;

timeData(2).interval = interval_15;
timeData(2).temperature = 15;

timeData(3).interval = interval_19;
timeData(3).temperature = 19;

end
