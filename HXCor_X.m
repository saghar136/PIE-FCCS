clear all;
%%%%%%%%%%%%%%%%%%%%%%%%
% Version 2.0
% Multi-Tau strategy Xcorrelation function with symmetric normalization.
% This function calculates Xcorrelation curve using multiple-tau
% algorithm with moving average for very long lag time.
% This software correlator does (almost..) what hardware correlators do
% according to Wholand et al., Biophysical journal June 2001 1987-2999
% Later modified to have more channels. Strategy is just same.

%%%%MANUAL%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Run HyperXCor in Matlab
% 2. Output is a correlation graph and a txt output file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%What it does%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do linear calculation for first 32 data. then 16 data with bin size 2.
% then another 16 data with bin size 4. then 16 with bin 16 ... and so on..
% It calculate till about 10^4 ms lag time.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('****** Multiple Tau Cross Correlator!!! ******');
tnsMicro = input('Unit Bin Time(us) [1] >>');
if isempty(tnsMicro)
    tnsMicro = 1; % enter default value here
end
otherData.tns = tnsMicro * 10^(-6);        % time unit is now in sec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
insPathName=uigetdir('E:\Data\2021\2021-07-09\Alignment\MatOut_div10s_FLCS');
outPath = uigetdir(insPathName, 'E:\Data\2021\2021-07-09\Alignment\MatOut_div10s_FLCS');
filelistA = dir([insPathName, '\*A_ins.mat']);
filelistB = dir([insPathName, '\*B_ins.mat']);

if length(filelistA) ~= length(filelistB)
    error('Continuing not recommended, number of A and B files are different')
end

otherData.fileNum = 0;
otherData.totalFileNum = (length(filelistA) + length(filelistB))*1.5;

% Calculate Channel AxB  cross-correlation for all files
for x = 1:length(filelistA)
    if strcmp(filelistA(x).name(1:length(filelistA(x).name)-9),...
            filelistB(x).name(1:length(filelistB(x).name)-9));
        otherData.fileNum = x;
        [cort corr] = HyperCorr2([insPathName '\' filelistA(x).name],...
            [insPathName '\' filelistB(x).name], otherData);
        saving = [cort corr];
        save([outPath '\' filelistA(x).name(1:length(filelistA(x).name)-9) 'X.dat'],...
            'saving','-ascii')
    else
        disp(['non-identical file error: ' filelistA(x).name filelistB(x).name]);
    end
end