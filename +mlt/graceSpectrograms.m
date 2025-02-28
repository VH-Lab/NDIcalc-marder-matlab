function graceSpectrograms(S)
% GRACESPECTROGRAMS - downsample data for Grace's experiments
%
% GRACESPECTROGRAMS(S)
%
% Create and save spectrograms all ppg elements for an ndi.session or ndi.dataset S.
%

p = S.getprobes('type','ppg');

path = S.path();

for i=1:numel(p),
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e),
        error(['No ''_lp'' version of ' p{i}.elementstring]);
    end
    [spec,f,ts]=mlt.wholeDaySpectrogram(S,'e_name',e{1}.name,'e_reference',e{1}.reference);
    filename = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '.mat'])
    save(filename,'spec','f','ts','-mat');
end


