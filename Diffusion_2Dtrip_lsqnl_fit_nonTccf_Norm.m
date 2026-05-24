%% Same code as 'Diffusion_2Dtrip_lsqnl_fit_nonTccf_noComms', but with 
%   - majority of original comments removed (noComms)
%   - capability of distinguishing single color data from dual color data 
% (Single and dual color data must be stored in/called from separate folders)
%   - normalized ACF/CCF curves [option] based on component of code provide by shaun, 'Ftrip_Ops_SubplotRes_Short'


clear all;tic;
global weight; 

%**********
% Load data
datecollected = '10.02.19';
savefigs = 'on';
subplotsOn = 1;  % 1, includes residual as subplot. 0, only correlation function is plotted 
NewFits = 1;
titlesOn = 1; % 1, includes file name as plot title. 0, no title
normOn = 0; % 1, normalize plots. 0, don't normalize 
showExtrap = 0; % 1, includes extrapolated fits without trip component, 0, doesn't
plotRd = 1;% 1, include red ACF data in figures. 0, don't
plotGd = 1; % 1, include green ACF data in figures. 0, don't 
plotXd = 1; % 1, include CCF data in figures. 0, don't include CCF
plotRf = 1;% 1, include red ACF fit in figures. 0, don't
plotGf = 1; % 1, include green ACF fit in figures. 0, don't 
plotXf = 1; % 1, include CCF fit in figures. 0, don't include CCF


% have ForExcel table give NaNs for certain values when FCCS wasn't being
% used...
%[beta(1,:) betaX(1,:) beta(2,:) betaX(2,:) cps beta(3,1:2) beta(4,1:2)]
% dataMat = NaN(1,12);
% cps = NaN(1,2);

if NewFits
    while 1
        filelistA = dir('*_CorrQ.dat');
        numFiles = length(filelistA);
        if numFiles > 0
            break
        else
            disp('Please choose a directory containing hist3.mat files')
        end
    end
SumSq=zeros(numFiles,3);
%                 dataMat = NaN(1,12);
%                 cps = NaN(1,2);
    for k = 1:numFiles
                dataMat = NaN(1,12);
                cps = NaN(1,2);
        
        %waitbar(k/numFiles, waitb, 'Just wait')
        filenameA = filelistA(k).name;
        tmp = load(filenameA); % tmp from CorrQ %
         % choose correlator channel: A == 2, B==3
   % automated defining of CorrF and CorrFstd based on number of channel
   % data inputs (number of columns) of tmp
        [~,ChnCt]=size(tmp);
        pjk=1;
        for jk = 1:((ChnCt-1)/2)
                pjk = pjk+1;  
                CorrF(:,jk) = tmp(:,pjk);
                CorrFstd(:,jk)=tmp(:,(pjk+(floor(ChnCt/2))));        
        end
         
         
%         CorrF(:,1) = tmp(:,2);  %collected red channel data
%         CorrFstd(:,1) = tmp(:,5); 
%         CorrF(:,2) = tmp(:,3);  %collected green channel data
%         CorrFstd(:,2) = tmp(:,6);
%         CorrF(:,3) = tmp(:,4);  %calculated crossed channels data
%         CorrFstd(:,3) = tmp(:,7); 
        

        t = tmp(:,1); 
%         l=length(t);
%         var = load([filenameA(1:end-9),'IntH.dat'])
%         cps=var(1:2)

        cps = load([filenameA(1:end-9),'IntH.dat']);

%*************************************************************************
%######################################################################################

    tauS = 5; %use tauS=30 to eliminate extreme negative Xcorr amplitudes   

%######################################################################################
        % Fit Correlation
        tl = [tauS length(t)];  
        %%If acquisition time is less than 30s.. will decrease data points.
%         tl = [3 224]; 
        % Only 224 data points for 15s acquistion
        % Time limit for fit & Display: 1e-1 = 112, 1e-2 = 85, 1e-3 = 58, 1e-4 =25
   
        tau = t(tl(1):tl(2));
        dof=length(tau)-1;
        g = CorrF(tl(1):tl(2),:);
        std= CorrFstd(tl(1):tl(2),:);
        index=find(tau >= 10,1);
        stdShort=std(index:end,:);

        %%%%Initial guesses = take average of initial points%%%%
%         
%----------------------- RED ---------------------------------------------%
dn = 0;
tauRI = 0;
if ~isempty(dir('*_A.dat'))
    %color = 'Red!'
            dn = dn+1; 
            SumR=0;
            nr=1;
            for x=1:5
                SumR = (g(x,dn)-1)+SumR;
            end
            AvgSumR=SumR/5;
            fwhmR=(AvgSumR/2)+1;
            NrI=5/SumR;
            indexR=find(g(:,dn)< fwhmR);
       g1=(find(g(:,dn)< fwhmR))';
       g10=[g1 0]; g01=[0 g1]; g101=g10-g01; g101=g101(1,2:end);
       g1=g1(1,find(abs(g101)==1,1));
            tauRI=tau(g1);
            if isempty(tauRI)
                tauRI=5;
            end
%%%      Initial (calculated) guesses for fcs2DTrip function fitting parameters            
     beta0(:,dn) = [NrI tauRI .25 .4 1];
     disp(' WARNING, fitting parameter bounds are based on eGFP.');
     disp('You may need to adjust them due to mCherrys different blinking characteristics');
end
clear g10 g1 g01 g101 
%         
%----------------------- GREEN -------------------------------------------%
tauGI = 0; % allows for defining of ub and lbs for red channel if there isn't a green channel 
if ~isempty(dir('*_B.dat'))
    %color = 'Green!'
            dn = dn+1; 
            SumG=0;
             for x=1:5
                SumG = (g(x,dn)-1)+SumG;
             end
            AvgSumG=SumG/5;
            fwhmG=(AvgSumG/2)+1;
            NgI=5/SumG;
    % make tauD guess less vulnerable to high noise during earlier times
            g1=(find(g(:,dn)< fwhmG))';
       g10=[g1 0]; g01=[0 g1]; g101=g10-g01; g101=g101(1,2:end);
           % oldtauGI=tau(g1(1,1))  %uncomment to see original code's
           % selection for 1st guess..
%            g1tauGI=tau(g1)
       g1=g1(1,find(abs(g101)==1,1));
            tauGI=tau(g1);
            if isempty(tauGI)
                tauGI=5;
            end
%%%      Initial (calculated) guesses for fcs2DTrip function fitting parameters
      beta0(:,dn) = [NgI tauGI .12 .1 1];
      % beta0 individual indices are as follows
      % for beta0(:,dn), 
%             dn=1 --> N_eff, avg population #
%             dn=2 --> tau_D, avg dwell time
%             dn=3 --> T, triplet fraction
%             dn=4 --> tau_T, triplet relaxation
%             dn=5 --> normalization factor?
end
% %             
%----------------------- CROSS -------------------------------------------%
if ~isempty(dir('*_X.dat'))
            dn = dn+1;
            SumRG=0;
            for x=1:25
                SumRG= (g(x,dn)-1)+SumRG;
            end
            AvgSumRG=SumRG/25;
            fwhmRG=(AvgSumRG/2)+1;
            NrgI=25/SumRG;
            indexRG=find(g(:,dn)< fwhmRG,1);
            tauRGI=tau(indexRG);
            if isempty(tauRGI)
                tauRGI=5;
            end
      beta1 = [NrgI tauRGI 1];
end

dev=0.1; %acceptable level of sum(abs(residual)) for the fits to the raw data

autoBounds=0;
% define fitting bounds based on original guesses
if dn>1
    % data in folder is 2 color if dn>1
       % define single color bounds
       
       %--------RED
           lb(:,1) = [.000001  0.5    0   .0001   .999];
           ub(:,1) = [100000   100     1     9     1.001];          
       %--------GREEN   
           lb(:,2) = [.000001  0.5    0   .0001   .999];
           ub(:,2) = [100000   50     1     9     1.001];                  
       %--------CROSS           
           lb(:,3) =  [0.001 0 0 0 .995];
           ub(:,3)=ub(:,1);
       
        % adjust guesses if necessary
         if NrgI<lb(3,1) || NrgI>ub(3,1)
            beta0(3,1)=(ub(3,1)+lb(3,1))/2;
         end
         if tauRGI<lb(3,2) || tauRGI>ub(3,2)
            beta0(3,2)=(ub(3,2)+lb(3,2))/2;
         end
else
    lb =  [.000001  0.5    0   .0001   .999];
    ub =  [100000   50   1   9    1.001];
end
           % original bounds
%            lb =  [.000001 5.5 0 .0001 .999];
%            ub =  [100000 3000 1.0 1 1.001];

%%%********************** 2D Triplet FITTING ***********************%%%%%%%          
%%%      Fit red and green curves, respectively
          for n=1:dn
              if n<3 
%             [beta(:,n),resnorm,residual] = lsqnonlin(@fcs2DTrip,beta0(:,n),lb,ub,[],tau,g(:,n));
%         Optimize fit by lowering, smallestchange, the potential size of the difference between each fitting iteration, 
%                   |f(xi) – f(xi+1)| < FunctionTolerance
            smallestchange=1e-10;
            options = optimoptions(@lsqnonlin,'FunctionTolerance',smallestchange);
            [beta(:,n),resnorm,residual] = lsqnonlin(@fcs2DTrip,beta0(:,n),lb,ub,options,tau,g(:,n));
            % [] = options ;   tau = real_x ;   g(:,n) = real_y
            
            % original eqn before you reorganized the components
%        G(:,n) = ((1+(beta(3,n)./(1-beta(3,n))).*exp(-tau./beta(4,n))).*((1./beta(1,n)).*(1./(1+(tau./beta(2,n))))))+beta(5,n);

            G(:,n) = ((1./beta(1,n)).*(1+(beta(3,n)./(1-beta(3,n))).*exp(-tau./beta(4,n))).*(1./(1+(tau./beta(2,n)))))+beta(5,n);
       % G(:,n) =
  %         {[1/Neff] * [1+(T/(1-T))*exp(-tau/tauT)] * [(1/(1+(tau/tauD)))]}+norm
  %       = {[trip comp]*[p     
       
         residualShort=residual(index:end);                      
            nn=n;
        if ~exist('nr','var'); nn=n+1; end
            dataMat(1,nn)=beta(1,n); 
            dataMat(1,nn+3)=beta(2,n);
            dataMat(1,nn+8)=beta(3,n);
            dataMat(1,nn+10)=beta(4,n);
          else
%%%      Initial (calculated) guesses for fcs2D_lsq function fitting parameters          
%         beta1 = [NrgI tauRGI 1];
            lbX =  [.000001 1 .999];
            ubX =  [100000 2000 1.001];
        % adjust guesses if necessary
         if NrgI<lbX(1) || NrgI>ubX(1)
            beta1(1)=(ubX(1)+lbX(1))/2;
         end
         if tauRGI<lbX(2) || tauRGI>ubX(2)
            beta1(2)=(ubX(2)+lbX(2))/2;
         end
%%%      Fit cross curve         
       
            j=0;    j=j+1;
            [betaX(:,j),resnorm,residual] = lsqnonlin(@fcs2D_lsq,beta1,lbX,ubX,[],tau,g(:,n));
            G(:,n) = ((1./betaX(1,j)).*(1./(1+(tau./betaX(2,j)))))+betaX(3,j);            
            residualShort=residual(index:end);
          
            dataMat(1,3) = betaX(1,1); dataMat(1,6) = betaX(2,1);
              end
          end
% %                      
    dataMat(1,7:8)=cps(1,:);

        if savefigs=='on'

            if k == 1
                % make distance between base line (at y=0) and x-axis the
                % same length for all curves in given folder (normalize
                % each cell w.r.t. the 1st)
                ymin0=-0.0025;  %<-- this value (ymin of 1st cell) determines the relative ymin for the remaining cells
                ymax=(max(max(g))-1)*1.05;
                R1=ymax ;
                R2=-ymin0;
                % x max same for all curves in given folder
                tauEnd = tau(end)*1.005;
                format long
%---debugging start---                
                tau;
                length(tau);
                save(['TAU_',datecollected,'-tauS ',num2str(tauS),'.mat'], 'tau');
%---debugging end---                 

            end
            ymax=(max(max(g))-1)*1.05;
            ymin=-(ymax*(R2/R1));
                     
            figure(k);clf;
    STau=tauS;
%#######################################################################################################    
 
    if ~STau; STau=find(tau==0.03,1); end %******** choose x axis upper limit for plots   
    tauE=find(tau>30000,1);  %******** choose x axis upper limit for plots

%#######################################################################################################   
      if isempty(tauE) == 1; tauE=length(tau); end
      if isempty(STau) == 1; STau=1; end
      
 if ~subplotsOn
     % settings for plots WITHOUT subplots
     plotspace = [1,2,3,4];
     opHeight = 0.70;
     opWidth = 0.50;
     pbaDims = [1.5 1 1];
 else
%% SUBPLOT (RESIDUAL) PARAMETERS
     % settings for plots WITH subplots
     plotspace = [1,2,3];
     opHeight = 0.75;
     opWidth = 0.55;
     pbaDims = [2 1 1];

            subplot(4,1,[4]);
          if ~isempty(dir('*_X.dat'))
              if plotRd; semilogx(tau,g(:,1)-G(:,1), 'Color', [.85 .16 0],'LineWidth',1.5);hold on; end
              if plotGd; semilogx(tau,g(:,2)-G(:,2), 'Color', [0 .5 0],'LineWidth',1.5);hold on; end
              if plotXd; semilogx(tau,g(:,3)-G(:,3),'b','LineWidth',1.5);hold on; end
          else; if ~isempty(dir('*_A.dat'))
                  MrkColor = [.85 .16 0];
              else
                  MrkColor = [0 .5 0];
                end                
              semilogx(tau,g(:,1)-G(:,1), 'Color', MrkColor,'LineWidth',1.5);hold on;     
          end
                
%                 axis([tau(1)/1.5, tau(end)*1.5, -0.001, 0.001]); %2.3
%                 line([tau(1)/1.5, tau(end)*1.5],[0 0]);            
                axis([tau(STau)/1.5 tau(tauE) -.001 .001]); %2.3
                line([tau(STau)/1.5 tau(tauE)],[0 0],'LineStyle',':',...
                    'LineWidth',1.5,'Color',[0.5 0.5 0.5]);
 %               axis([tau(1)/1.5 tau(tauE) -.0025 .0025]);
                
                set (gca, 'TickLength', [0.02 0.02], 'TickDir', 'in',...
                    'FontSize', 14, 'FontName', 'Arial',...
                    'XTick',[10^(-2) 10^(-1) 10^(0) 10^(1) 10^2 10^3 10^4]);
                set(gcf, 'Renderer', 'painters');
                set(gcf, 'units','normalized','outerposition',[0.1 0.1 0.55 0.75]);  %  [x-location y-location Width Height]
                ylabel('Residual','FontSize', 14,'FontName', 'Arial', 'FontWeight', 'bold');
                xlabel('\it{\tau}, ms','FontSize', 14, 'FontName', 'Arial', 'FontWeight', 'bold');

                pbaspect([8.5 1 1]);

%                 correlation=corr(g,G);
%                 saveas(gca, [filenameA(1:end-10) '_2DTripletFit.png']);

%         clear CorrF CorrFstd G tau
 end
%% MAIN PLOT PARAMETERS
             subplot(4,1,plotspace);
            if ~isempty(dir('*_X.dat'))
                % % parameters for 2 color
      if normOn
        if beta(1,1)<beta(1,2) 
            fmin(k) = beta(1,2)/betaX(1,1); 
        else
            fmin(k) = beta(1,1)/betaX(1,1); 
        end
%         rNorm=(beta(1,1).*(1-beta(3,1))); %rNorm = Nr*(1-Tr)
        rgMax=max((g(:,1)-1)); rgMin=min((g(:,1)-1)); %rGMax=max((G(:,1)-1)); rGMin=min((G(:,1)-1));
%         gNorm=(beta(1,2).*(1-beta(3,2)));
        ggMax=max((g(:,2)-1)); ggMin=min((g(:,2)-1)); %gGMax=max((G(:,2)-1)); gGMin=min((G(:,2)-1));
        xNorm=betaX(1,1).*fmin(k);
        ymax = 1.1;
        ymin = -0.05;
      else
        rgMax=1; rgMin=0;   %rGMax=1; rGMin=0; 
        ggMax=1; ggMin=0;   %gGMax=1; gGMin=0;
        xNorm=1;
      end  
        if plotRd; semilogx(tau,((g(:,1)-1)-rgMin)./(rgMax-rgMin),'Color', [.85 .16 0],'LineWidth',1,'LineStyle',':');hold on; end
        if plotGd; semilogx(tau,((g(:,2)-1)-ggMin)./(ggMax-ggMin),'Color', [0 .5 0],'LineWidth',1,'LineStyle',':');hold on; end
%         if plotXd; semilogx(tau,(g(:,3)-1).*xNorm,'b','LineWidth',0.15);hold on; end
        if plotXd; semilogx(tau,(g(:,3)-1).*xNorm,'b','LineWidth',1,'LineStyle',':');hold on; end
        if plotRf; semilogx(tau,((G(:,1)-1)-rgMin)./(rgMax-rgMin),'Color', [.85 .16 0],'LineWidth',2);hold on; end
        if plotGf; semilogx(tau,((G(:,2)-1)-ggMin)./(ggMax-ggMin),'Color', [0 .5 0],'LineWidth',2);hold on; end
%         if plotXf; semilogx(tau,(G(:,3)-1).*xNorm,'k-'); hold on; end
        if plotXf; semilogx(tau,(G(:,3)-1).*xNorm,'b','LineWidth',2); hold on; end
      if showExtrap
        semilogx(tau,((GnoT(:,1)-1)-rgMin)./(rgMax-rgMin),'Color', [.85 .16 0],'LineWidth',2,'LineStyle',':');hold on;
        semilogx(tau,((GnoT(:,2)-1)-ggMin)./(ggMax-ggMin),'Color', [0 .5 0],'LineWidth',2,'LineStyle',':');hold on;
      end
% huge if statement for automatic legend (probably a better way, but lazy)      
        if plotRf
            if plotGf
                if plotXf; lgndName={'ACF red', 'ACF green', 'CCF'}; else; lgndName={'ACF red', 'ACF green'}; end
            else if plotXf; lgndName={'ACF red','CCF'}; else; lgndName={'ACF red'}; end
                end
         else if plotGf
                 if plotXf;lgndName={'ACF green','CCF'};else;lgndName={'ACF green'};end
             else if plotXf; lgndName={'CCF'}; end
             end
         end 

            else; if ~isempty(dir('*_A.dat'))                    
             % % parameters for single color, red
                        MrkColor = [.85 .16 0];
                        lgndName='ACF red';
                else                  
             % % parameters for single color, green
                        MrkColor = [0 .5 0];
                        lgndName='ACF green';                
                end
      if normOn
        ggMax=max((g(:,1)-1)); ggMin=min((g(:,1)-1)); %gGMax=max((G(:,1)-1)); gGMin=min((G(:,1)-1));     
        ymax = 1.1;   ymin = -0.05;
      else
        ggMax=1; ggMin=0; % gGMax=1; gGMin=0;
      end    
      if ~isempty(dir('*_A.dat')); plotColor=[.85 .16 0]; else; plotColor=[0 .5 0];end
        semilogx(tau,((g(:,1)-1)-ggMin)./(ggMax-ggMin),'Color', plotColor,'LineWidth',1,'LineStyle',':');hold on;       
        semilogx(tau,((G(:,1)-1)-ggMin)./(ggMax-ggMin),'Color', plotColor,'LineWidth',2);hold on; 
            end


                line([tau(1)/1.5 tau(tauE)*1.5],[0,0],'LineStyle',':',...
                    'LineWidth',1.5,'Color',[0.5 0.5 0.5]);
                axis([tau(1) tau(tauE) ymin ymax]); %2.3
                set (gca, 'TickLength', [0.02 0.02], 'TickDir', 'in','FontSize', 14, 'FontName', 'Arial', 'XTick',[10^(-1) 10^(0) 10^(1) 10^2 10^3 10^4]);
                set(gcf, 'units','normalized','outerposition',[0.25 0.25 opWidth opHeight]);

                pbaspect(pbaDims);

                ylabel('G(\it{\tau})','FontName', 'Arial', 'FontWeight', 'bold');
                 legend(lgndName);
               if titlesOn
                title({'\fontsize{10}', strrep(filenameA(1:end-9),'_',' ')});
               end
                correlation=corr(g,G);
                saveas(gca, [filenameA(1:end-10) '_2DTripletFit.png']);
                saveas(gca, [filenameA(1:end-10) '_2DTripletFit.fig']);
                saveas(gcf, [filenameA(1:end-10) '_2DTripletFit.eps'],'epsc');
               
                       clear CorrF CorrFstd G tau
        end
        
%              dataMat = [beta(1,:) betaX(1,:) beta(2,:) betaX(2,:) cps beta(3,1:2) beta(4,1:2)]
            ForExcel(k,:) = dataMat;   % Chi2]; 
            ForTitles{k,1} = filenameA(1:end-10);
    end
    save(['Fpt3m_all_results_',datecollected,'.mat'], 'ForExcel', 'ForTitles', 'filelistA');
%     save([datecollected,'.mat'], 'ForExcel', 'ForTitles', 'filelistA');
else
    load(['Fpt3m_all_results_',datecollected,'.mat']);
%     load([datecollected,'.mat']);
end
Nr = ForExcel(:,1);
Ng = ForExcel(:,2);
w = 0.205; % in um
RecDens = (Nr+Ng)./(pi*w*w);
Ngr = ForExcel(:,1).*ForExcel(:,2)./ForExcel(:,3);
Fmin = Ngr./min(Ng,Nr);
Fgr = Ngr./(Nr+Ng-Ngr);
