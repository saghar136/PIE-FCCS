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
tnsMicro = input('Unit Bin Time(us) [10] >>');
if isempty(tnsMicro)
    tnsMicro = 10; % enter default value here
end
otherData.tns = tnsMicro * 10^(-6);        % time unit is now in sec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
insPathName=uigetdir('D:\Data\gtg2\Documents\MATLAB\Grant\2021\2021-10-13\MatOut');
outPath = uigetdir(insPathName, 'D:\Data\gtg2\Documents\MATLAB\Grant\2021\2021-10-13\MatOut');
filelistA = dir([insPathName, '\*A_ins.mat']);
filelistB = dir([insPathName, '\*B_ins.mat']);

if length(filelistA) ~= length(filelistB)
    error('Continuing not recommended, number of A and B files are different')
end

otherData.fileNum = 0;
otherData.totalFileNum = (length(filelistA) + length(filelistB))*1.5;

% Calculate Channel A autocorrelation for all files
for x = 1:length(filelistA)
    otherData.fileNum = x;
    [cort corr] = HyperCorr2([insPathName '\' filelistA(x).name],...
        [insPathName '\' filelistA(x).name], otherData);
    saving = [cort corr];
    save([outPath '\' filelistA(x).name(1:length(filelistA(x).name)-8) '.dat'],...
        'saving','-ascii')
end