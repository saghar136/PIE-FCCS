function [cort corr] = HyperCorr2(FileName, FileName3, otherData)
tic;
% HyperCorr v2.0 / aws 7/19/2013
load(FileName,'-mat');
insA = photons; clear photons;
load(FileName3,'-mat');
insB = photons; clear photons;

corSum = 0;
summation = 0;
tau=0;     % Lag time
bin=1;     % Size of time bin
sumA = 0;
sumB = 0;

%Let's get <I1> and <I2> first%%%%%%%%%%%%%%%%%%Intensity average%%
sizeA = length(insA);
meanA = mean(insA);
disp(['Channel A mean : ', num2str(meanA)]);
disp(['Size of the file A : ', num2str(sizeA)]);

sizeB = length(insB);
meanB = mean(insB);
disp(['Channel B mean : ', num2str(meanB)]);
disp(['Size of the file B : ', num2str(sizeB)]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numOfCalc = (floor(log2(sizeB))-4)*16+16; % Number of calculation. Can be varied.
disp(['Number of Caculation will be ',num2str(numOfCalc)]);
% wh = waitbar(otherData.fileNum/((numOfCalc)*otherData.totalFileNum),...
%     ['On file : ' num2str(otherData.fileNum)]);

for i=1:numOfCalc
%     waitbar((otherData.fileNum + i)/((numOfCalc)*otherData.totalFileNum), wh, ['On file : ' num2str(otherData.fileNum) ', calculation ' num2str(i)]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % First 32 linear calculations%%%%%%%%%
    if(i<=32)
        tau=i;
        corSum = sum(insA(1:end-tau).*insB(tau+1:end));
        sumA = sum(insA(1:end-tau));
        sumB = sum(insB(tau:end));
        corr(i,1) = (corSum*(min(sizeA,sizeB-tau)))/(sumA*sumB);
        cort(i,1) = tau * otherData.tns;
        corSum = 0; sumA = 0; sumB = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% MultiTau region. This complicated algorithm occurs because
    %% computer memory size is limited and also due to computation
    %% time problem.%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        bin = 2^((floor((i-33)/16)+1));
        tau = tau + bin;
      
        loaderA = insA(1:end-tau);
        loaderB = insB(tau+1:end);
        for index = bin:bin:length(loaderA)
            a = loaderA(index-bin+1:index);
            b = loaderB(index-bin+1:index);
            corSum = corSum + sum(a) * sum(b);
            sumA = sumA + sum(a);
            sumB = sumB + sum(b);
        end
        corr(i,1) = corSum*min(floor(sizeA/bin),floor((sizeB-tau)/bin))/(sumA*sumB);
        cort(i,1) = tau * otherData.tns;
        corSum = 0; sumA = 0; sumB = 0;
    end
    
end
% close(wh)
toc