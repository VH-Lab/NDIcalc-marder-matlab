function timeData = kathleenTime2(intervalWidthSeconds)
% kathleenTime2 defines datetime intervals and returns them in a structure.
% The structure array contains the interval and a temperature field.
%
% Syntax:
%   timeData = kathleenTime2()
%   timeData = kathleenTime2(intervalWidthSeconds)
%
% Description:
%   timeData = kathleenTime2() returns datetime intervals with a default
%   width of 180 seconds (3 minutes).
%
%   timeData = kathleenTime2(intervalWidthSeconds) returns datetime intervals
%   with a specified width in seconds.
%
% Example:
%   % Get time intervals for a 1-minute (60 second) window
%   myData = kathleenTime2(60);
%
% See also: kathleenTime1

arguments
    % The total width of the time interval in seconds.
    intervalWidthSeconds (1,1) {mustBeNumeric, mustBePositive} = 180
end

% --- Define Center Datetimes ---
% The year is assumed to be 2025. Please adjust if needed.
% Case 1: 11 degrees, 7/2 at 12am (file: 994_23)
center_time_1 = datetime('2025-07-02 00:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
% Case 2: 15 degrees, 7/10 at 12am (file: 994_29)
center_time_2 = datetime('2025-07-10 00:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
% Case 3: 19 degrees, 7/21 at 12am (file: 994_35)
center_time_3 = datetime('2025-07-21 00:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');


% --- Calculate Intervals ---
% The interval is centered, so we go half the width before and after the
% center time.
half_interval = seconds(intervalWidthSeconds / 2);

% Calculate the start and end of the interval for each case
interval_1 = [center_time_1 - half_interval, center_time_1 + half_interval];
interval_2 = [center_time_2 - half_interval, center_time_2 + half_interval];
interval_3 = [center_time_3 - half_interval, center_time_3 + half_interval];


% --- Create Structure Array ---
% Create a structure array to hold the output data.
timeData(1).interval = interval_1;
timeData(1).temperature = 11;

timeData(2).interval = interval_2;
timeData(2).temperature = 15;

timeData(3).interval = interval_3;
timeData(3).temperature = 19;

end
