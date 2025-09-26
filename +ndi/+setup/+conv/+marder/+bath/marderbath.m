function d = marderbath(S)
% MARDERBATH - Create NDI documents for bath stimulation information.
%
% D = MARDERBATH(S)
%
% Creates NDI documents of type 'stimulus_bath' for a Marder Lab session.
% This function reads a 'bath_table.csv' file from the session directory, which
% specifies the chemical mixtures applied to the bath and the epochs during
% which they were active.
%
% It uses helper JSON files ('marder_mixtures.json' and 'marder_bathtargets.json')
% to look up detailed information about the mixtures and their target locations.
%
% The function generates a 'stimulus_bath' document for each epoch and stimulus
% combination defined in the bath table, linking them to the appropriate
% stimulus elements and anatomical locations (via UBERON ontology).
%
% INPUTS:
%   S: (ndi.session) The NDI session object.
%
% OUTPUTS:
%   d: (cell array of ndi.document) A cell array of the newly created
%      'stimulus_bath' documents. Note: These documents are NOT automatically
%      added to the database.
%
% REQUIRED FILES:
%   - [session_path]/bath_table.csv: A table defining bath applications.
%     Columns should include "firstFile", "lastFile", "bathTargets", "mixtures".
%   - [toolbox_path]/+ndi/+setup/+conv/+marder/+bath/marder_mixtures.json: Defines the
%     composition of chemical mixtures.
%   - [toolbox_path]/+ndi/+setup/+conv/+marder/+bath/marder_bathtargets.json: Maps
%     target names to UBERON ontology identifiers.
%
% EXAMPLE:
%   % Assuming S is a valid NDI session object and bath_table.csv exists
%   bath_docs = ndi.setup.conv.marder.bath.marderbath(S);
%   S.database_add(bath_docs); % Add the new documents to the database
%
% See also: ndi.setup.conv.marder.bath.mixtureStr2mixtureTable, ndi.database.fun.uberon_ontology_lookup

arguments 
	S (1,1) ndi.session 
end

d = {};

stim = S.getprobes('type','stimulator');

et = stim{1}.epochtable();

marderFolder = fullfile(fileparts(mfilename('fullpath')));

mixtureInfo = jsondecode(fileread(fullfile(marderFolder,"marder_mixtures.json")));

bathTargets = jsondecode(fileread(fullfile(marderFolder,"marder_bathtargets.json")));

bath_table_path = fullfile(S.getpath(), 'bath_table.csv');
if ~exist(bath_table_path, 'file')
    warning(['The file ' bath_table_path ' was not found. No bath information will be loaded.']);
    d = {};
    return;
end
bathTable = readtable(bath_table_path, "Delimiter", ',');

locTable = vlt.data.emptystruct('Identifier','bathLoc');


for i=1:numel(et)
    eid = et(i).epoch_id;
    epochid.epochid = eid;
    for j=1:numel(stim)
        stimid = stim{j}.id();
        disp(['Working on stimulator ' int2str(j) ' of ' int2str(numel(stim)) ', epoch ' int2str(i) ' of ' int2str(numel(et)) '.']);
        for k=1:size(bathTable,1)
            tokensFirst = regexp(bathTable{k,"firstFile"}, '_(\d+)\.', 'tokens');
            tokensLast = regexp(bathTable{k,"lastFile"}, '_(\d+)\.', 'tokens');
            firstFile = str2double(tokensFirst{1}{1});
            lastFile = str2double(tokensLast{1}{1});
            if (i>=firstFile && i<=lastFile) 
                % if we are in range, add it
                % step 1: loop over bathTargets
                bT = bathTable{k,"bathTargets"};
                for b=1:numel(bT)
                    locList = bathTargets.(bT{b});
                    for l=1:numel(locList)
                        index = find(strcmp(locList(l).location,{locTable.Identifier}));
                        if isempty(index)
                            bathLoc = ndi.database.fun.uberon_ontology_lookup("Identifier",locList(l).location);
                            locTable(end+1) = struct('Identifier',locList(l).location,'bathLoc',bathLoc);
                        else
                            bathLoc = locTable(index).bathLoc;
                        end
                        mixTable = ndi.setup.conv.marder.bath.mixtureStr2mixtureTable(bathTable{k,"mixtures"}{1},mixtureInfo);
                        mixTableStr = ndi.database.fun.writetablechar(mixTable);
                        stimulus_bath.location.ontologyNode = locList(l).location;
                        stimulus_bath.location.name = bathLoc.Name;
                        stimulus_bath.mixture_table = mixTableStr;
                        d{end+1}=ndi.document('stimulus_bath','stimulus_bath',stimulus_bath,'epochid',epochid)+...
                            S.newdocument();
                        d{end} = d{end}.set_dependency_value('stimulus_element_id',stimid);
                    end
                end
            end
        end
    end
end
