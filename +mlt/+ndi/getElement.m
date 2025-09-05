function elem = getElement(S, subject_name, record_type, element_label)
%GETPROBE Finds a unique NDI element based on subject and record type.
%
%   PROBE = mlt.ndi.getElement(S, subject_name, record_type)
%
%   This is a user-specific function that must be implemented. It should
%   search the NDI session S and return the single, unique ndi.element object
%   that corresponds to the given subject and record type.
%
%   Inputs:
%       S             - An ndi.session or ndi.dataset object.
%       subject_name  - The name of the subject (e.g., 'SubjectA').
%       record_type   - The type of record ('heart', 'gastric', or 'pylorus').
%
%   Outputs:
%       elem         - The single matching ndi.element object. Returns empty
%                       if no unique match is found.


subQ = ndi.query('','isa','subject') & ndi.query('subject.local_identifier','exact_string',subject_name);
sub = S.database_search(subQ);
if numel(sub)~=1
    error('Did not find exactly one subject match.')
end

e = S.getelements();

tf = cellfun(@(x) strcmp(x.subject_id,sub{1}.id()) && contains(x.name,record_type) && contains(x.name,element_label),e,'UniformOutput',true);

index = find(tf);

if isscalar(index)
	elem = e{index};
else
	error(['Expected one match, but found ' int2str(numel(index)) ' matches.']);
end

