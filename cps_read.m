function [meanA,meanB] = cps_read(rootf,tbin)

load([rootf,'_A_ins.mat']);
% load([rootf,'_A_ins'],'-mat');
insA = photons; clear photons;
load([rootf,'_B_ins.mat']);
% load([rootf,'_B_ins'],'-mat');
insB = photons; clear photons;

tbins = tbin*1e-6; % convert to seconds


%Calculate <I1> and <I2> first then cps
ttime = tbins*length(insA);
sizeA = sum(insA);
meanA = sizeA/ttime;
% disp(['____________________________']);
% disp(['Channel A collection time : ', num2str(ttime), ' seconds']);
% disp(['Total number of photons   : ', num2str(sizeA)]);
% disp(['Counts per second         : ', num2str(meanA)]);

ttime = tbins*length(insB);
sizeB = sum(insB);
meanB = sizeB/ttime;
% disp(['Channel B collection time : ', num2str(ttime), ' seconds']);
% disp(['Total number of photons   : ', num2str(sizeB)]);
% disp(['Counts per second         : ', num2str(meanB)]);

