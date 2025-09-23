function t = mixtureStr2mixtureTable(str,mixtureStruct)
% MIXTURESTR2MIXTURETABLE - Convert a mixture string to a detailed mixture table.
%
% T = MIXTURESTR2MIXTURETABLE(STR, MIXTURESTRUCT)
%
% Converts a compact mixture string into a detailed table of chemical components
% and their concentrations. The function parses the string, looks up component
% definitions in a provided structure, and calculates final concentrations.
%
% INPUTS:
%   str: (string) A comma-separated string describing the mixture.
%        Each element can be a mixture name (e.g., 'normal_saline') or a
%        mixture name with a multiplier (e.g., '2*picrotoxin').
%
%   mixtureStruct: (struct) A structure where each field is a mixture name
%                  (e.g., 'normal_saline'). The value of each field is a
%                  structure array defining the components of that mixture,
%                  with the following fields:
%     - ontologyName: The ontology identifier for the compound (e.g., 'CHEBI:28997').
%     - name: The common name of the compound (e.g., 'picrotoxin').
%     - value: The base concentration of the compound.
%     - ontologyUnit: The ontology identifier for the unit (e.g., 'OM:MolarVolumeUnit').
%     - unitName: The common name of the unit (e.g., 'Molar').
%
% OUTPUTS:
%   t: (table) A table listing all components from the resolved mixture string,
%      with columns: "ontologyName", "name", "value" (final calculated
%      concentration), "ontologyUnit", and "unitName".
%
% EXAMPLE:
%    str = 'normal_saline,2*picrotoxin';
%    marderFolder = fullfile(mlt.util.toolboxdir(),'+ndi','+setup','+conv','+marder');
%    mixtureStruct = jsondecode(fileread(fullfile(marderFolder,"marder_mixtures.json")));
%    t = ndi.setup.conv.marder.mixtureStr2mixtureTable(str,mixtureStruct);
%    % t will be a table containing all components of normal_saline and
%    % picrotoxin at twice its base concentration.
%
% See also: jsondecode, readtable

t = vlt.data.emptytable("ontologyName","string","name","string","value",...
	"double","ontologyUnit","string","unitName","string");

f = fieldnames(mixtureStruct);

tokens = extractTokens(str);
for i=1:numel(tokens)
    coef = tokens{i}{1};
    name = tokens{i}{2};
    index = find(strcmp(name,f));
    assert(~isempty(index),["No name " + name + " found."]);
    v = getfield(mixtureStruct,f{index});
    for j=1:numel(v)
        v(j).value = coef * v(j).value;
        t(end+1,:) = struct2cell(v(j))';
    end
end

function tokens = extractTokens(text)
  % Splits the text by commas
 % Example usage:
  %text = 'apple,3*banana,pear,3e-3*apple';
  %tokens = extractTokens(text); 
  %disp(tokens)
 parts = strsplit(text, ','); 
  tokens = {};
  
  for i = 1:length(parts)
    part = parts{i};
    % Extracts the numeric coefficient and the string part
    match = regexp(part, '(?<coeff>[\d\.\-\+eE]+)?\*?(?<str>\w+)', 'names'); 
    
    if isempty(match) 
        continue; 
    end
    
    coeff = str2double(match.coeff); 
    if isnan(coeff)
      coeff = 1;  % Default to 1 if no coefficient is found
    end
    
    tokens{end+1} = {coeff, match.str}; 
  end

