function elem_out_o = downsampple(S, p_in)
% DOWNSAMPLE - downsample PPG data for Marder experiments
%
% DOWNSAMPLE(S)
%
% Downsample all ppg probes for an ndi.session or ndi.dataset S.
%
% Downsamples probes of type 'ppg' by adding '_lp' to their name.
%
% After downsampling, an element with a single epoch of the ppg record is made
% by adding '_lp_whole' to the element name. This element is returned in 
% ELEM_OUT_O.
%
% 
%

if nargin<2
    p_in = [];
end

if isempty(p_in)
    p = S.getprobes('type','ppg');
else
    p = p_in;
end

for i=1:numel(p)
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp'],'element.reference',p{i}.reference);
    if isempty(e)
        disp('Downsampling all elements...will take several minutes. Check out log file to see progress.');
        elem_out_ds = ndi.element.downsample(S,p{i},50,[p{i}.name '_lp'],p{i}.reference);
        S.cache.clear(); % rebuild cache after new epochs
    elseif ndi.element.missingepochs(p{i},e{1})
        disp('Downsampling new elements only. Check out log file to see progress.');
        elem_out_ds = ndi.element.downsample(S,p{i},50,[p{i}.name '_lp'],p{i}.reference);
        S.cache.clear(); % rebuild cache after new epochs
    else
        disp('Elements have already been downsampled.');
        elem_out_ds = e{1};
    end
    elem_out_o = ndi.element.oneepoch(S,elem_out_ds,[p{i}.name '_lp_whole'],p{i}.reference);
end


