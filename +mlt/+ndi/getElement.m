function elem = getElement(S, subject_name, record_type, element_label)
%GETELEMENT Finds a unique NDI element based on subject and record type.
%
%   ELEM = mlt.ndi.getElement(S, subject_name, record_type, [element_label])
%
%   Searches the NDI session S to find a single, unique ndi.element object
%   that corresponds to the given subject and record type. It performs a
%   database query to find element documents that match all criteria.
%
%   This function will raise an error if zero or more than one element matches
%   the search criteria.
%
%   Inputs:
%       S             - An ndi.session or ndi.dataset object.
%       subject_name  - The name of the subject (e.g., 'SubjectA').
%       record_type   - The type of record ('heart', 'gastric', or 'pylorus').
%       element_label - (Optional) A further label to identify the element.
%                       Defaults to 'lp_whole'.
%
%   Outputs:
%       elem          - The single matching ndi.element object.

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','gastric','pylorus'})}
    element_label (1,:) char = 'lp_whole'
end

% Step 1: Find the subject document to get the subject ID
subQ = ndi.query('','isa','subject') & ndi.query('subject.local_identifier','exact_string',subject_name);
sub = S.database_search(subQ);
if numel(sub)~=1
    error('Did not find exactly one subject match for "%s".', subject_name);
end
subject_id = sub{1}.id();

% Step 2: Build a query to find the element document directly
q_element = ndi.query('','isa','element');
q_subject = ndi.query('','depends_on','subject_id',subject_id);
q_record = ndi.query('element.name', 'contains_string', record_type);
q_label = ndi.query('element.name', 'contains_string', element_label);

final_query = q_element & q_subject & q_record & q_label;

element_docs = S.database_search(final_query);

% Step 3: Check for a unique match and convert the document to an element object
if isscalar(element_docs)
	elem = ndi.database.fun.ndi_document2ndi_object(element_docs{1}, S);
else
	error(['Expected one element match, but found ' int2str(numel(element_docs)) ' matches.']);
end

end