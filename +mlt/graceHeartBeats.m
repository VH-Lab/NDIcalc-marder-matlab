function graceHeartBeats(S)
% GRACEHEARTBEATS - detect heart beats for Grace's experiments
%
% GRACEHEARTBEATS(S)
%
% Create and save heart beat data all ppg elements for an ndi.session or ndi.dataset S.
%

p = S.getprobes('type','ppg');

path = S.path();

for i=1:numel(p),
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp'],'element.reference',p{i}.reference);
    if isempty(e),
        error(['No ''_lp'' version of ' p{i}.elementstring]);
    end
    [beats,d,t]=mlt.wholeDayHeartBeat(S,'e_name',e{1}.name,'e_reference',e{1}.reference);
    filename = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '_beats.mat']);
    save(filename,'beats','d','t','-mat');
end


