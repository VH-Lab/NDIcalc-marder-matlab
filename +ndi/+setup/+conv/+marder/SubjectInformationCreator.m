% file: +ndi/+setup/+conv/+marder/SubjectInformationCreator.m
classdef SubjectInformationCreator < ndi.setup.NDIMaker.SubjectInformationCreator
    % MARDER.SUBJECTINFORMATIONCREATOR - Creates NDI subject information for the Marder Lab.
    %
    % This class implements the 'create' method to generate subject identifiers
    % and species/strain objects based on the specific subject naming convention used in the
    % Marder Lab.
    %
    methods
        function [subjectIdentifier, strain, species, biologicalSex] = create(obj, tableRow)
            % CREATE - Generates subject data from a Marder Lab subject string.
            %
            %   [SUBJECTIDENTIFIER, STRAIN, SPECIES, BIOLOGICALSEX] = CREATE(OBJ, TABLEROW)
            %
            %   This method processes a single row from a table to generate a unique
            %   subject identifier and associated species information. The subject ID is
            %   read from the 'subject_id' column of the table row.
            %
            %   Inputs:
            %       obj (ndi.setup.conv.marder.SubjectInformationCreator) - The instance of this creator class.
            %       tableRow (table) - A single row from a MATLAB table. It must contain the column 'subject_id'.
            %
            %   Outputs:
            %       subjectIdentifier (char) - The unique local identifier for the subject. Returns NaN on failure.
            %       strain (NaN) - Not used for this creator; returns NaN.
            %       species (openminds.controlledterms.Species) - The species object. Returns NaN on failure.
            %       biologicalSex (NaN) - Not used for this creator; returns NaN.
            %
            %   See also: ndi.setup.NDIMaker.SubjectInformationCreator
            %

                % --- Initialize Outputs ---
                subjectIdentifier = NaN;
                strain = NaN;
                species = NaN;
                biologicalSex = NaN;

                % --- Extract Values from Table Row ---
                try
                    subjectIdentifier = ndi.util.unwrapTableCellContent(tableRow.subject_id);
                catch ME
                    warning('Could not extract subject_id from the table row. Error: %s', ME.message);
                    return;
                end

                % --- Validate and Process Data ---
                if ischar(subjectIdentifier) && ~isempty(subjectIdentifier)
                    % Check for crab
                    if ~isempty(regexp(subjectIdentifier, '^gdy_\d{4}@marderlab.brandeis.edu$', 'once'))
                        try
                            species = openminds.controlledterms.Species('name', 'Cancer borealis', ...
                                'preferredOntologyIdentifier', 'NCBITaxon:39395');
                        catch ME
                            warning(['Failed to create openminds Species object for Cancer borealis: ' ME.message]);
                            species = NaN;
                        end
                    % Check for lobster
                    elseif ~isempty(regexp(subjectIdentifier, '^gdy_lobster\d{3}@marderlab.brandeis.edu$', 'once'))
                        try
                            species = openminds.controlledterms.Species('name', 'Homarus americanus', ...
                                'preferredOntologyIdentifier', 'NCBITaxon:6706');
                        catch ME
                            warning(['Failed to create openminds Species object for Homarus americanus: ' ME.message]);
                            species = NaN;
                        end
                    else
                        warning('Subject ID "%s" does not match a known Marder Lab format.', subjectIdentifier);
                        subjectIdentifier = NaN; % Invalidate if format is unknown
                    end
                else
                    warning('Invalid subject_id data type in table row. Could not determine species.');
                    subjectIdentifier = NaN;
                    return;
                end
        end
    end % methods
end % classdef
