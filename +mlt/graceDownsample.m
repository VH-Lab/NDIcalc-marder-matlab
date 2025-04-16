function graceDownsample(S)
% GRACEDOWNSAMPLE - downsample data for Grace's experiments
%
% GRACEDOWNSAMPLE(S)
%
% Downsample all ppg probes for an ndi.session or ndi.dataset S.
%
% Downsamples probes of type 'ppg' by adding '_lp' to their name.
%

p = S.getprobes('type','ppg');

for i=1:numel(p)
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp'],'element.reference',p{i}.reference);
    downsample = false;
    if isempty(e)
        disp('Downsampling all elements...will take several minutes. Check out log file to see progress.');
        downsample = true;
    elseif mlt.missingEpochs(p{i},e{1})
        disp('Downsampling new elements only. Check out log file to see progress.');
        downsample = true;
    else
        disp('Elements have already been downsampled.');
    end
    if downsample
        elem_out_ds = ndi.element.downsample(S,p{i},100,[p{i}.name '_lp'],p{i}.reference);
        elem_out_o = ndi.element.oneepoch(S,elem_out_ds,[p{i}.name '_lp_whole'],p{i}.reference);
        S.cache.clear(); % for the moment, stop the syncgraph from getting too big
    end
end


