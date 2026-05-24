%% Same as original m2Ft, but divides longer ACQs into smaller ACQs of specified time lengths
% m2Ft v2, DPM 4/4/19
%% Run after p2mat script
% generates ' _A_ins.mat', ' _B_ins.mat', & 'Convert to F(t)
% log.txt' files and saves them to MatOut folder


clear all;
clc;
fprintf(1,'\r');
mainPath='D:\Data\gtg2\Documents\MATLAB\Grant\2021\2021-10-12\MatOut';
while 1
    pathname = uigetdir(mainPath);
    if any(size(dir([pathname, '\*pt3.mat']),1))
        filelist = dir([pathname, '\*pt3.mat']);
    else
        filelist = dir([pathname, '\*ptu.mat']);
    end
    pathname = strcat(pathname, '\');
    numFiles = length(filelist);
    if numFiles > 0       
        break
    else
        disp('Please choose a directory containing *.mat files')
    end
end

%**************************************************************************
% set pathnameOut as desired output folder, or as zero to keep same as
% pathname
pathnameOut = input('Save output files to a different folder? (0 = no [default], 1 = yes)'); 
if ~isempty(pathnameOut)  
    pathnameOut = uigetdir('D:\Data\gtg2\Documents\MATLAB\Pradeep\2020\02.04.20\MatOut'); 
end

if ~ischar(pathnameOut)
    pathnameOut = pathname;
else
    pathnameOut = strcat(pathnameOut, '\');
end
%**************************************************************************
divTimePrompt = input('Would you like to divide any ACQ into smallers ACQs? (0 = no, 1 = yes [default])');
if isempty(divTimePrompt)    
    divTimePrompt = 1; 
end
if divTimePrompt
 disp('Which ACQ(s) would you like to divide?')
 [filelist2,~,~] = uigetfile(mainPath,'MultiSelect','on');
 fl2cell=strtrim(filelist2'); [fl2R,fl2C]=size(fl2cell);
 if iscell(filelist2)
     filelist2=char(filelist2(:));
 end
 divTime = input('Time length of smaller ACQs to be generated? (s) [10]');
 if isempty(divTime)    
     divTime = 10; 
 end
end
logOut = fopen([pathname 'Convert to F(t) log.txt'], 'w');

%**********************
% ask user for bin size
binSize = input('Enter bin size (µs) [10] ');
if isempty(binSize)  
    binSize = 10; % enter default value here
end

%*******************
% convert to NANOseconds
binSize = binSize*(1e3); 

%********************************
% log some things in the log file
fprintf(logOut, ['\r Bin size = ' num2str(binSize) ' nanoseconds']);

%***********
% Load files
waitb = waitbar(0);tic;
for a = 1:numFiles
    filename = filelist(a).name;
    fprintf(logOut,  ['\r Converting file: ' filename ]);
    waitbar(a/numFiles, waitb, ['On file ' filename])
 % each pt3.mat file contains the three vectors: chan (channel that detected photon), 
 %      dtime (time of detection wrt syc pulse),
 %      and truetime (time of detection wrt total ACQ time)   
    load([pathname,filename])   
    totaltime = max(truetime);
    numPoints = length(truetime);
    fprintf(logOut,  ['\r Total time in file: ' num2str(totaltime) ' nanoseconds \r']);
    fprintf(logOut,  ['Total photons in file: ' num2str(numPoints) '\r']);
    numBins = totaltime/binSize;
    fprintf(logOut,  ['Total bins in file: ' num2str(numBins) '\r']);
    master = horzcat(truetime, chan, dtime);
   
    clear T3Record truensync nsync truetime chan dtime;

    %**********************
    % Define Channel Limits
    if a==1
        countsAIdx = find(master(:,2) == 1);
        countsBIdx = find(master(:,2) == 2);
        figure(1);clf;
        ha = hist(master(countsAIdx, 3), 1:4095); 
        hb = hist(master(countsBIdx, 3), 1:4095); 
        plot(1:length(ha),ha,'r',1:length(hb),hb,'g');
        legend('A','B');
        
        clear countsBIdx;
 %       lowerA = input('lower gate A? [2350] ');
        %************************************************ changes made
        %4/13/17
  %      if isempty(lowerA)
            lowerA = 2350; % enter default value here
   %     end
  %      upperA = input('upper gate A? [4095] ');
  %      if isempty(upperA)
            upperA = 3100; % enter default value here
  %      end
  %      lowerB = input('lower gate B? [1] ');
  %      if isempty(lowerB)
            lowerB = 1; % enter default value here
  %      end
   %     upperB = input('upper gate B? [2150] ');
   %     if isempty(upperB)
          upperB = 600; % enter default value here
   %     end
        %***************************************************
        tic;
    end

    fprintf(logOut,  ['Gates A: ' num2str(lowerA) '-' num2str(upperA) '\r']);
    fprintf(logOut,  ['Gates B: ' num2str(lowerB) '-' num2str(upperB) '\r']);  

multACQs=strcmp(cellstr(filelist2),filename);
multACQsIdx=find(multACQs==1);

%have to make dummy string for filename2 elements to account for varying
%filname lengths
FL2=char(cellstr(filelist2(multACQsIdx,:)));

 

%*****************************
    % find photons in each channel
    % use hist to calculate MCS (Multi-Channel Scaling), and then
    % save files and clear variables
    
for k=1:fl2R; cellCont=fl2cell{k,:}; fl2cell{k,:}=cellCont(1:end-12);end

if divTimePrompt        
    if sum(strcmp(cellstr(FL2),filename))       
    hitsA = find((master(:,2) == 1 & master(:,3) < upperA & master(:,3) > lowerA));
    photons1 = hist(master(hitsA,1), numBins);
    x=divTime*1e6*(1/(binSize*1e-3)); numACQs = numBins/x; numACQs=round(numACQs)
    divACQs= 0:x:numBins;    
    divACQs(end+1)=length(photons1);  
    divACQs(:)=divACQs(:)+1;
  for i = 1:numACQs
      photons=photons1(divACQs(i):divACQs(i+1)-1);
      if  sum(strcmp(cellstr(fl2cell),cellstr(fl2cell(multACQsIdx,:))))>1
%********** THIS PART WONT WORK IF THE ins.mat FILES ALREADY EXIST!!!
%********** HAVE TO DELETE SAID FILES FIRST
                tstStr1 = [FL2(1,1:end-12),'_','*_A_ins.mat'];
               fl2=dir([FL2(1,1:end-12),'_','*_A_ins.mat']);
               if ~isempty(fl2) 
%           tstChar ='if=1'                     
               fln2 = fl2(end).name;
               flnNum = str2double(fln2(end-11:end-10));
                 if flnNum>i
                     ii = flnNum+2;
                 else                    
                     ii = i;
                 end
               else
%           tstChar ='if=0'                    
                   ii=i;
               end
          if ii>10;idx=10;else;idx=9;end
      else            
          if i>10;idx=10;else;idx=9;end
          ii=i;
      end
       outputFileName=[filename(1:end-idx),num2str(ii-1),'_A_ins.mat']
      save([pathnameOut,filename(1:end-idx),num2str(ii-1),'_A_ins.mat'],'photons','-mat');     
  end
    clear hitsA photons reSzphotons i x  numACQs divACQs idx fl2 
    
    hitsB = find((master(:,2) == 2 & master(:,3) < upperB & master(:,3) > lowerB));
    photons1 = hist(master(hitsB,1), numBins);
    x=divTime*1e6*(1/(binSize*1e-3));  numACQs = numBins/x; numACQs=round(numACQs);
    divACQs= 0:x:numBins;    
    divACQs(end+1)=length(photons1); 
    divACQs(:)=divACQs(:)+1;
 for i = 1:numACQs
      photons=photons1(divACQs(i):divACQs(i+1)-1);
      if  sum(strcmp(cellstr(fl2cell),cellstr(fl2cell(multACQsIdx,:))))>1
               fl2=dir([FL2(1,1:end-12),'_','*_B_ins.mat']);
               if ~isempty(fl2)
               fln2 = fl2(end).name; flnNum = str2double(fln2(end-11:end-10));
                 if flnNum>i; ii = flnNum+2;else;ii = i;end
               else
                   ii=i;
               end
          if ii>10;idx=10;else;idx=9;end
      else
          if i>10;idx=10;else;idx=9;end
          ii=i;
      end
      save([pathnameOut,filename(1:end-idx),num2str(ii-1),'_B_ins.mat'],'photons','-mat');     
  end
    clear hitsB photons reSzphotons i x  numACQs divACQs idx fl2 
    else
    hitsA = find((master(:,2) == 1 & master(:,3) < upperA & master(:,3) > lowerA));
    photons = hist(master(hitsA,1), numBins); 
    save([pathnameOut,filename(1:end-8),'_A_ins.mat'],'photons','-mat');
    clear hitsA photons reSzphotons i x  numACQs divACQs idx
  
    hitsB = find((master(:,2) == 2 & master(:,3) < upperB & master(:,3) > lowerB));
    photons = hist(master(hitsB,1), numBins); 
    save([pathnameOut,filename(1:end-8),'_B_ins.mat'],'photons','-mat');
    clear hitsB photons reSzphotons i x  numACQs divACQs idx       
    end
else 
    hitsA = find((master(:,2) == 1 & master(:,3) < upperA & master(:,3) > lowerA));
    photons = hist(master(hitsA,1), numBins); 
    save([pathnameOut,filename(1:end-8),'_A_ins.mat'],'photons','-mat');
    clear hitsA photons reSzphotons i x  numACQs divACQs idx
  
    hitsB = find((master(:,2) == 2 & master(:,3) < upperB & master(:,3) > lowerB));
    photons = hist(master(hitsB,1), numBins); 
    save([pathnameOut,filename(1:end-8),'_B_ins.mat'],'photons','-mat');
    clear hitsB photons reSzphotons i x  numACQs divACQs idx   
    
    end
end

close(waitb);
fclose(logOut);
toc
