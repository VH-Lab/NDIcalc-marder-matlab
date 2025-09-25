function d = marderprobe2uberon(S)
    % MARDERPROBE2UBERON - Add probe location information based on Marder probe data.
    %
    % D = MARDERPROBE2UBERON(S)
    %
    % Creates 'probe_location' NDI documents by mapping probe names in an NDI
    % session to anatomical locations defined in the UBERON ontology.
    %
    % The function retrieves all 'n-trode', 'sharp-Vm', 'sharp-Im', and 'ppg'
    % probes from the session. It then uses a lookup table,
    % 'marderprobe2uberontable.txt', to find the corresponding UBERON anatomical
    % term for each probe.
    %
    % For each match found, it creates a 'probe_location' document that links
    % the probe's ID to the UBERON identifier.
    %
    % INPUTS:
    %   S: (ndi.session) The NDI session object.
    %
    % OUTPUTS:
    %   d: (cell array of ndi.document) A cell array of the newly created
    %      'probe_location' documents. Note: These documents are NOT automatically
    %      added to the database.
    %
    % REQUIRED FILES:
    %   - [toolbox_path]/+ndi/+setup/+conv/+marder/+probeMap/marderprobe2uberontable.txt:
    %     A tab-delimited file that maps probe names to UBERON anatomical terms.
    %     It must contain "probe" and "name" columns.
    %
    % EXAMPLE:
    %   % Assuming S is a valid NDI session with defined probes
    %   location_docs = ndi.setup.conv.marder.probeMap.marderprobe2uberon(S);
    %   S.database_add(location_docs); % Add the new documents to the database
    %
    % See also: ndi.database.fun.uberon_ontology_lookup, readtable

    p = S.getprobes('type','n-trode');
    p1 = S.getprobes('type','sharp-Vm');
    p2 = S.getprobes('type','sharp-Im');
    p3 = S.getprobes('type','ppg');
    p = cat(1,p,p1,p2,p3);

    filepath = fileparts(mfilename('fullpath'));

    t = readtable([filepath filesep 'marderprobe2uberontable.txt'],'delimiter','\t');

    d = {};

    for i=1:numel(p)
        index = find(strcmp(p{i}.name,t.("probe")));
        if ~isempty(index)
            disp(['Found entry for ' p{i}.name '...']);
            ontol = ndi.database.fun.uberon_ontology_lookup('Name',t{index,"name"}{1});
            if isempty(ontol)
                error(['Could not find entry ' char(t{index,"name"}{1}) '.']);
            end
            identifier = ['UBERON:' int2str(ontol(1).Identifier)];
            pl.ontology_name = identifier;
            pl.name = t{index,"name"}{1};
            d_here = ndi.document('probe_location','probe_location',pl) + S.newdocument();
            d_here = d_here.set_dependency_value("probe_id",p{i}.id());
            d{end+1} = d_here;
        end
    end
