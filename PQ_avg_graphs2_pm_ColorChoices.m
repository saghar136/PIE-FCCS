%*************************************************************************
% sin2dat uses fsin2dat.m to read the sin files and create an averaged
% correlation function
%*************************************************************************
clear all;
tic;

global tau idx CorrFA CorrFB CorrFAB ymax

% Choose either single colors for FCS (one variable equals 1), or both
% for FCCS (both equal 1) 

SCG = 1; %SCG = single color, green   [enter 0 for red ONLY]                           %%%%%%Customize 
SCR = 1;  %SCR = single color, red    [enter 0 for green ONLY]                         %%%%%%Customize 

% numA=1:10;
% 
% for a=1:length(numA)
%********************
% Load Data
    % _A, _B, and _X.dat files in the MatOut folder
% rootf = ['10.03.17_T40Fds_37C_9.26.17-DPM_488.8uW_561.6uW_a', num2str(numA(1,a)) ,'_']; 
rootf = '02.16.25_COS7_Src16-GFP_Src16-mCh_488_0.2uW_561_0.8uW_C43_'; %%%%%%Customize 
% idx = [0 1 2 3 4 5 6 7 8];                                                                     %%%%%%Customize 
 idx = [0 1 2 3 4 5];  
%idx = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]; fdx = '0'; 
fdx = '0';      %Customize if two populations present
binSz =1;                                                                                 %%%%%%Customize 
timelapse = [1:length(idx)];
% timelapse = load('filetimes.txt');timelapse(length(idx)+1:end) = [];
savefigs = 'on';

manualyminX =0;     % manual y axis minimum limit for cross-corr 
                          % set equal to, 0, to turn off  

% CorrF = zeros(240,3,length(idx));
for k=1:length(idx)
    num = ['000',int2str(idx(k))];
   
    if SCR==1   
      tmp = load([rootf,num(end-2:end),'_A.dat']);  
      %IndivACQlength=length(tmp(:,2))
      CorrFA(:,k) = tmp(:,2); % choose correlator channel: A == 2, B==3
      lolz=1;
    end
    if SCG==1
      tmp = load([rootf,num(end-2:end),'_B.dat']);
      CorrFB(:,k) = tmp(:,2); % choose correlator channel: A == 2, B==3
      lolz=2;
    end
    if (SCG + SCR)==2
      tmp = load([rootf,num(end-2:end),'_X.dat']);
      CorrFAB(:,k) = tmp(:,2); % choose correlator channel: A == 2, B==3
    % CorrFAB is matrix of cross corr points for each ACQ, where k = ACQ # 
    % and for 10s ACQ times, the column length is 256
    lolz=3;
    end    
%     CorrFAB(:,k) = tmp(1:length(CorrF),2);
    [cpsA(k) cpsB(k)] = cps_read([rootf,num(end-2:end)],binSz);
end
tau = tmp(:,1)*1000; clear tmp;

ymax = 0.05;
ymin = -0.01;

switch lolz
    case 1
        CorrMax=max(CorrFA);  CorrMin=min(CorrFA);
    case 2
        CorrMax=max(CorrFB);  CorrMin=min(CorrFB);
    case 3
        CorrMax=max([CorrFA,CorrFB]); CorrMin=min([CorrFA,CorrFB]);
end
    ymax = (max(CorrMax)-1)*1.1;            % remove this if processing after 8/31/17 
    ymin = (median(CorrMin)-1)*1.5;    % remove this if processing after 8/31/17 


ymaxX = (max(max(CorrFAB))-1)*1.1;    
yminX = (median(min(CorrFAB(:,:)))-1)*1.5; 

if manualyminX < 0
    yminX = manualyminX;
end
 %yminX = -0.001

%dump2plotQ5;

%*******************
% Save Averaged file
% 
% jnk = [tau mean(CorrFA,2) mean(CorrFB,2) mean(CorrFAB,...
%             2) std(CorrFA,0,2) std(CorrFB,0,2) std(CorrFAB,0,2)];

 if SCR == 1
      jnk = [tau mean(CorrFA,2), std(CorrFA,0,2)]; 
 end
 if SCG == 1
      jnk = [tau mean(CorrFB,2), std(CorrFB,0,2)]; 
 end
 if (SCG + SCR)==2
      jnk = [tau mean(CorrFA,2) mean(CorrFB,2) mean(CorrFAB,...
          2) std(CorrFA,0,2) std(CorrFB,0,2) std(CorrFAB,0,2)];
 end
%jnk = [tau  CorrFA   CorrFB   CorrFAB   CorrFBA];
save([rootf,fdx,'_CorrQ.dat'],'jnk','-ascii');

%****************************
% Plot intensity versus time.
FA = mean(cpsA);
FB = mean(cpsB);
jnk = [FA;FB]';
save([rootf,fdx,'_IntH.dat'],'jnk','-ascii');

% figure(1); clf;
% plot(IntH_A); hold on;
% plot(IntH_B); hold on;
% plot(mIntHA,'k','LineWidth',3); hold on;
% plot(mIntHB,'k','LineWidth',3);
% legend(int2str([1:length(idx)]'));

%**************************
% Plot correlation function
  
 if SCR == 1
      figure(1);clf;
      semilogx(tau,(CorrFA - 1)); 
      axis([tau(1)/1.1 tau(end)*1.5,((median(min(CorrFA(:,:)))-1)*1.5),...
          ((max(max(CorrFA))-1)*1.1)]);
      % axis([1e-2 1e4 ymin ymax]);
      xlabel('\it{\tau}','Fontsize', 16);
      ylabel('G(\it{\tau})','Fontsize', 16);
      title('Channel A Correlation', 'Fontsize', 20)
      legend(int2str(idx'),'Location','northeast');
      line([tau(1)/1.5 tau(end)*1.5],[0 0], 'LineWidth', 1, 'LineStyle','- -'...
                          ,'Color', [0.3 0.3 0.3]);
 end
 if SCG == 1
%**************************
      figure(2);clf;
      semilogx(tau,(CorrFB - 1));
      axis([tau(1)/1.1 tau(end)*1.5,((median(min(CorrFB(:,:)))-1)*1.5),...
          ((max(max(CorrFB))-1)*1.1)]);
      % axis([1e-2 1e4 ymin ymax]);
      xlabel('\it{\tau}','Fontsize', 12);
      ylabel('G(\it{\tau})','Fontsize', 12);
      title('Channel B Correlation', 'Fontsize', 16)
      legend(int2str(idx'),'Location','northeast');
      line([tau(1)/1.5 tau(end)*1.5],[0 0], 'LineWidth', 1, 'LineStyle','- -'...
                          ,'Color', [0.3 0.3 0.3]);
 end
 if (SCG + SCR) == 2
%**************************

      figure(3);clf;
      semilogx(tau,(CorrFAB - 1));
      axis([tau(1)/1.1 tau(end)*1.5 yminX ymaxX]);
      % axis([1e-2 1e4 ymin ymax]);
      xlabel('\it{\tau}','Fontsize', 16);
      ylabel('G(\it{\tau})','Fontsize', 16);
      title('A-B Cross-Correlation', 'Fontsize', 16)
      legend(int2str(idx'),'Location','northeast');
      line([tau(1)/1.5 tau(end)*1.5],[0 0], 'LineWidth', 1, 'LineStyle','- -'...
                          ,'Color', [0.3 0.3 0.3]);
 end
%**************************
figure(4);clf;

  if SCR==1
    semilogx(tau,mean((CorrFA - 1),2),'r');hold on;
%     lgnd = 'CorrA';
  end
  if SCG==1
    semilogx(tau,mean((CorrFB - 1),2),'g');hold on;
%     lgnd = 'CorrB';
  end
  if (SCR+SCG)==2
    semilogx(tau,mean((CorrFAB - 1),2),'b');hold on;
    lgnd = {'CorrA', 'CorrB', 'Cross-Corr'};
    legend(lgnd,'Location','northeast');
  end
xlabel('\it{\tau}','Fontsize', 16);
ylabel('G(\it{\tau})','Fontsize', 16);
title('Average of Each Correlation Curve', 'Fontsize', 16)
axis([tau(1)/1.1 tau(end)*1.5 ymin ymax]);
% axis([1e-2 1e4 ymin ymax]);
% legend(lgnd,'Location','northwest');
%lgnd4.Position = [0.75 0.8 .1 .1];
line([tau(1)/1.5 tau(end)*1.5],[0 0], 'LineWidth', 1, 'LineStyle','- -'...
                    ,'Color', [0.3 0.3 0.3]);
                
%****************************
% Data Processing Details txt

fid = fopen([rootf,fdx,'_Details.dat'],'wt'); 
fprintf(fid,'Load ');
fprintf(fid,'%c',rootf');
fprintf(fid,'\n');

fprintf(fid,'File subscripts 0 to %i \n',idx(end));
%fprintf(fid,'Excluding file subscript %i \n',dump);

fclose(fid);
%end
toc
