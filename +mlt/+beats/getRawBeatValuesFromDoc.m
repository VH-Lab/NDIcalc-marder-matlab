function beats_with_raw = getRawBeatValuesFromDoc(S, name, number)
%GETRAWBEATVALUESFROMDOC Loads beat data and adds raw amplitude values.
%
%   beats_out = mlt.beats.getRawBeatValuesFromDoc(S, name, number)
%
%   This is a high-level function that loads a 'ppg_beats' NDI document
%   for a specified element, reads the corresponding raw (un-normalized)
%   time series data, and then calls mlt.beats.getRawBeatValues to add
%   raw amplitude information to the beats structure.
%
%   Inputs:
%       S       - An ndi.session object.
%       name    - The record name ('pylorus', 'heart', or 'gastric').
%       number  - The record number (a positive integer).
%
%   Outputs:
%       beats_with_raw - The 'beats' structure from the document, with the
%                        new raw amplitude fields (.rawPeak, .rawTrough,
%                        .rawAmplitude) added.
%
%   Example:
%       % Get beats with raw amplitudes for the 'pylorus' element, record 1
%       b_raw = mlt.beats.getRawBeatValuesFromDoc(mySession, 'pylorus', 1);
%
%   See also mlt.beats.getRawBeatValues, mlt.beats.beatsdoc2struct

arguments
    S (1,1) ndi.session
    name (1,1) string {mustBeMember(name, ["pylorus", "heart", "gastric"])}
    number (1,1) double {mustBeInteger, mustBePositive}
end

% --- Find the NDI element ---
e_name = ['ppg_' name '_lp_whole'];
disp(['Searching for element: ' e_name ', reference ' int2str(number) '...']);
e = S.getelements('element.name', e_name, 'element.reference', number);
if isempty(e)
    error('Could not find element with name %s and reference %d.', e_name, number);
end
e = e{1};

% --- Load the 'beats' struct from the NDI document ---
et = e.epochtable();
if isempty(et)
    error('Element %s has no epochs.', e.elementstring());
end
disp(['Searching for ''ppg_beats'' document for epoch ' et(1).epoch_id '...']);
doc = ndi.database.fun.finddocs_elementEpochType(S, e.id(), et(1).epoch_id, 'ppg_beats');
if isempty(doc)
    error('No ''ppg_beats'' document found for element %s.', e.elementstring());
end
doc = doc{1};
beats = mlt.beats.beatsdoc2struct(S, doc);
disp('Successfully loaded beats from document.');

% --- Read the raw (un-normalized) time series data ---
disp('Reading raw time series data...');
[d_raw, t_raw] = e.readtimeseries(et(1).epoch_id, -inf, inf);

% --- Call the core calculator to add raw values ---
disp('Calculating raw amplitude values...');
beats_with_raw = mlt.beats.getRawBeatValues(beats, t_raw, d_raw);
disp('Done.');

end

