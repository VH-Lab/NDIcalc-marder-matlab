function graceHeartBeatsDoc(S)
% GRACEHEARTBEATS - detect heart beats for Grace's experiments
%
% GRACEHEARTBEATS(S)
%
% Create and save heart beat data all ppg elements for an ndi.session or ndi.dataset S.
%

p = S.getprobes('type','ppg');

path = S.path();

for i=1:numel(p)
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e)
        error(['No ''_lp_whole'' version of ' p{i}.elementstring]);
    end
    mlt.wholeDayHeartBeatDoc(S,'e_name',e{1}.name,'e_reference',e{1}.reference);
end


