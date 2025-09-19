function [doc_out] = beatsstruct2doc(doc_in,beats)
%ADDBEATS2DOC Adds PPG beat data from a structure to an NDI document.
%
%   DOC_OUT = BEATSSTRUCT2DOC(DOC_IN, BEATS) takes photoplethysmogram (PPG)
%   beat information stored in a structure array BEATS and writes it to a
%   binary file ('beats.vhsb'). It then associates this file with the
%   provided NDI document object DOC_IN.
%
%   Inputs:
%       DOC_IN  - An NDI document object (`ndi.document`) to which the beat
%                 data file will be added.
%       BEATS   - A structure array where each element represents a single
%                 PPG beat. The fields of the structure include:
%                   - onset: Beat onset time.
%                   - offset: Beat offset time.
%                   - peak_time: Time of the beat's peak.
%                   - peak_val: Signal value at the beat's peak.
%                   - valley_time: Time of the beat's valley (trough).
%                   - valley_val: Signal value at the beat's valley.
%                   - up_time: Time of the upward slope.
%                   - down_time: Time of the downward slope.
%                   - duty_cycle: Ratio of beat duration to the period between beats.
%                   - period: Time between consecutive beats.
%                   - instant_freq: Instantaneous heart rate (beats per second).
%                   - amplitude: Peak-to-peak amplitude.
%                   - amplitude_high: Amplitude above a high threshold.
%                   - amplitude_low: Amplitude below a low threshold.
%                   - valid: Boolean indicating if the beat meets validity criteria.
%                   - up_duration: Duration of the upward slope of the beat.
%
%   Outputs:
%       DOC_OUT - The updated NDI document object (`ndi.document`) that now
%                 includes a reference to the newly created 'beats.vhsb' file
%                 containing the beat data.
%
%   See also: mlt.beats.detectHeartBeatsImproved, mlt.beats.beatsdoc2struct,
%       vlt.file.custom_file_formats.vhsb_write

% Input argument validation
arguments
    doc_in (1,1) {mustBeA(doc_in,'ndi.document')}
    beats {mustBeA(beats,'struct')}
end

% Convert beat time to datenum if necessary
beats = struct2table(beats);
ind = varfun(@isdatetime,beats,'OutputFormat','uniform');
beats = convertvars(beats,ind,'datenum');
beats = table2array(beats);

% Write beats data to binary file
filePath = ndi.file.temp_name;           
vlt.file.custom_file_formats.vhsb_write(filePath,beats(:,1),beats(:,2:end),'use_filelock',0);

doc_out = doc_in.add_file('beats.vhsb',filePath);

end
