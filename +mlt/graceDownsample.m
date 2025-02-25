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

for i=1:numel(p),
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp'],'element.reference',p{i}.reference);
    if isempty(e),
        disp(['Creating downsampled element...will take several minutes. Check out log file to see progress.']);
        ndi.element.downsample(S,p{i},100,[p{i}.name '_lp'],p{i}.reference);
    end
end


