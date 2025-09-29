function makeFigure2(dataPrefix)
% makeFigure1 Generates a figure from session data.
%   makeFigure1(dataPrefix) takes the directory path 'dataPrefix' 
%   where session data is stored and creates a figure.

arguments
    % dataPrefix is the path to the directory where the session data is stored.
    dataPrefix (1,1) string {mustBeFolder} 
end

% Function body to be implemented.

S1 = ndi.session.dir(fullfile(dataPrefix,"994_23"));
S2 = ndi.session.dir(fullfile(dataPrefix,"994_29"));
S3 = ndi.session.dir(fullfile(dataPrefix,"994_35"));

S1.getprobes();
S2.getprobes();
S3.getprobes(); % cache all the epochs

S = {S1; S2; S3};

subjects{1} = 'gdy_0014@marderlab.brandeis.edu';
subjects{2} = 'gdy_0015@marderlab.brandeis.edu';
subjects{3} = 'gdy_0016@marderlab.brandeis.edu';
recordingArea{1} = 'heart';
recordingArea{2} = 'heart';
recordingArea{3} = 'heart';

t = mlt.jacquerie.kathleenTime2(30);

times = reshape([t.interval],2,3)';

data = cell(1,numel(subjects));
for i=1:numel(subjects)
    data{i} = mlt.doc.getHeartBeatAndSpectrogram(S,subjects{i},recordingArea{i});
end

for i=1:numel(subjects)
    mlt.plot.Traces(data{i},times)
end