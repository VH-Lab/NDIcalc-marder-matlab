function probe = getProbe(S, subject_name, record_type)
%GETPROBE Finds a unique NDI probe based on subject and record type.
%
%   PROBE = mlt.probe.getProbe(S, subject_name, record_type)
%
%   This is a user-specific function that must be implemented. It should
%   search the NDI session S and return the single, unique ndi.probe object
%   that corresponds to the given subject and record type.
%
%   A typical implementation might construct a probe name from the inputs
%   (e.g., 'ppg_SubjectA_heart') and use S.getprobes() to find it.
%
%   Inputs:
%       S             - An ndi.session or ndi.dataset object.
%       subject_name  - The name of the subject (e.g., 'SubjectA').
%       record_type   - The type of record ('heart', 'gastric', or 'pylorus').
%
%   Outputs:
%       probe         - The single matching ndi.probe object. Returns empty
%                       if no unique match is found.


subQ = ndi.query('','isa','subject') & ndi.query('subject.local_identifier','exact_string',subject_name);
sub = S.database_search(subQ);
if numel(sub)~=1
    error(['Did not find exactly one subject match.'])
end;

p = S.getprobes('subject_id',sub{1}.id())

tf = cellfun(@(x) contains(x.name,record_type) && contains(x.name,'lp_whole'),p,'UniformOutput',false)

index = find(tf);

if numel(index)==1,
	probe = p{index};
else
	error(['Expected one match, but found ' int2str(numel(index)) ' matches.']);
end;

