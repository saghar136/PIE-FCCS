% This script reads a PicoHarp T3 Mode data file (*.pt3 or *.ptu)
%% Run after transfering data
%% Do not have pt3 and ptu files in the same folder
% generates ' _pt3.mat' or '_ptu.mat' files and saves them to MatOut folder

clear all; clc


while 1
    pathname = uigetdir('D:\Data\gtg2\Documents\MATLAB\Grant\2021\2021-10-12'); %%%%%%Customize 
 
    
    if any(size(dir([pathname, '\*.pt3']),1))       
        filelist = dir([pathname, '\*.pt3']);
        disp('pt3 files located. wont look for (or process) ptu files')
        pt3=1; ptu=0;
    else
        filelist = dir([pathname, '\*.ptu']);
        disp('ptu files located. wont look for (or process) pt3 files')
        ptu=1; pt3=0;
    end   
    
    filelist = dir([pathname, '\*.ptu']);
    pathname = strcat(pathname, '\');
    numFiles = length(filelist);
    if numFiles > 0
        break
    else
        disp('Please choose a directory containing ptu files')
    end
end

if exist([pathname 'MatOut'], 'dir')
    disp('Using existing matout directory')
else
    disp('Making new MatOut directory')
    mkdir([pathname '\MatOut\']);
end



%% this for loop is used if ptu files are in the folder
if ptu
waitb = waitbar(0); tic
for a = 1:numFiles

    waitbar(a/numFiles, waitb, 'Converting from ptu to mat')
    filename = filelist(a).name;
    fid=fopen(filename,'r');
    fseek(fid,0,1);
    filesize = ftell(fid);
    fseek(fid,0,-1);
    
% some constants (converting the text representation of hexadecimal number
% to decimal numers)
    tyEmpty8      = hex2dec('FFFF0008');
    tyBool8       = hex2dec('00000008');
    tyInt8        = hex2dec('10000008');
    tyBitSet64    = hex2dec('11000008');
    tyColor8      = hex2dec('12000008');
    tyFloat8      = hex2dec('20000008');
    tyTDateTime   = hex2dec('21000008');
    tyFloat8Array = hex2dec('2001FFFF');
    tyAnsiString  = hex2dec('4001FFFF');
    tyWideString  = hex2dec('4002FFFF');
    tyBinaryBlob  = hex2dec('FFFFFFFF');
    % RecordTypes
    rtPicoHarpT3     = hex2dec('00010303');
    rtPicoHarpT2     = hex2dec('00010203');
    rtHydraHarpT3    = hex2dec('00010304');
    rtHydraHarpT2    = hex2dec('00010204');
    rtHydraHarp2T3   = hex2dec('01010304');
    rtHydraHarp2T2   = hex2dec('01010204');
    rtTimeHarp260NT3 = hex2dec('00010305');
    rtTimeHarp260NT2 = hex2dec('00010205');
    rtTimeHarp260PT3 = hex2dec('00010306');
    rtTimeHarp260PT2 = hex2dec('00010206');
    rtMultiHarpNT3   = hex2dec('00010307');
    rtMultiHarpNT2   = hex2dec('00010207');
    % Globals for subroutines
    TTResultFormat_TTTRRecType = 0;
    TTResult_NumberOfRecords = 0;
    
    Header = struct;
    Header.MeasDesc_Resolution = 0;
    Header.MeasDesc_GlobalResolution = 0;
    
    Magic = fread(fid, 8, '*char');
    if not(strcmp(Magic(Magic~=0)','PQTTTR'))
        error('Magic invalid, this is not an PTU file.');
        return;
    end
    Version = fread(fid, 8, '*char');
    while 1
% incrementally read entire ptu file, detect and organize data type each
% step
        % read Tag Head
        TagIdent = fread(fid, 32, '*char'); % TagHead.Ident
        TagIdent = (TagIdent(TagIdent ~= 0))'; % remove #0 and more more readable
        TagIdx = fread(fid, 1, 'int32');    % TagHead.Idx
        TagTyp = fread(fid, 1, 'uint32');   % TagHead.Typ
        % TagHead.Value will be read in the
        % right type function
        if TagIdx > -1
            EvalName = [TagIdent '(' int2str(TagIdx + 1) ')'];
        else
            EvalName = TagIdent;
        end
        if strcmp(EvalName(1),'$')
            EvalName = EvalName(2:end);
        end
        % check Typ of Header
        switch TagTyp
            case tyEmpty8
                fread(fid, 1, 'int64');
% % cases with commented out caseChoices indicate repetitive reads in current path
% caseChoice = 'tyEmpty8'                      
            case tyBool8
                TagInt = fread(fid, 1, 'int64');
% caseChoice = 'tyBool8'                
                if TagInt==0; eval([EvalName '=false;']);else; eval([EvalName '=true;']);end
            case tyInt8
                TagInt = fread(fid, 1, 'int64');
                eval([EvalName '=TagInt;']);
% caseChoice = 'tyInt8'                
            case tyBitSet64
                TagInt = fread(fid, 1, 'int64');
                eval([EvalName '=TagInt;']);
caseChoice = 'tyBitSet64'                  
            case tyColor8
                TagInt = fread(fid, 1, 'int64');
                eval([EvalName '=TagInt;']);
caseChoice = 'tyColor8'                  
            case tyFloat8
                TagFloat = fread(fid, 1, 'double');
                eval([EvalName '=TagFloat;']);
% caseChoice = 'tyFloat8'                  
            case tyFloat8Array
                TagInt = fread(fid, 1, 'int64');
                fseek(fid, TagInt, 'cof');
caseChoice = 'tyFloat8Array'                  
            case tyTDateTime
                TagFloat = fread(fid, 1, 'double');
                eval([EvalName '=datenum(1899,12,30)+TagFloat;']); % but keep in memory as Matlab Date Number
% caseChoice = 'tyTDateTime'                  
            case tyAnsiString
                TagInt = fread(fid, 1, 'int64');
                TagString = fread(fid, TagInt, '*char');
                TagString = (TagString(TagString ~= 0))';
                if TagIdx > -1
                    EvalName = [TagIdent '(' int2str(TagIdx + 1) ',:)'];
                end
                if strcmp(TagIdent,'UsrHeadName') && exist('UsrHeadName','var')
                    %%% Catch case where length of TagString exceeds length of
                    %%% UsrHeadName character array
                    if eval(['size(' TagIdent ',2) < numel(TagString)'])
                        eval([TagIdent '(:,end:numel(TagString)) = '' '';']);
                    end
                end
% caseChoice = 'tyAnsiString'                  
                try;eval([EvalName '=TagString;']);end;
            case tyWideString
                % Matlab does not support Widestrings at all, just read and
                % remove the 0's (up to current (2012))
                TagInt = fread(fid, 1, 'int64');
                TagString = fread(fid, TagInt, '*char');
                TagString = (TagString(TagString ~= 0))';
                if TagIdx > -1
                    EvalName = [TagIdent '(' int2str(TagIdx + 1) ',:)'];
                end
                eval([EvalName '=TagString;']);
caseChoice = 'tyWideString'                  
            case tyBinaryBlob
                TagInt = fread(fid, 1, 'int64');
%                 fprintf(1,'<Binary Blob with %d Bytes>', TagInt);
                fseek(fid, TagInt, 'cof');
caseChoice = 'tyBinaryBlob'                  
            otherwise
caseChoice = 'otherwise'                  
                error('Illegal Type identifier found! Broken file?');                
        end
        if strcmp(TagIdent, 'Header_End')
            break
        end
    end
    
%% Smith Group --> following are important for ptu reading    
    %%% Assign values from header to output variables
    MeasDesc_GlobalResolution;
    Header.SyncRate = 1/MeasDesc_GlobalResolution;
    MeasDesc_Resolution;
%     Header.Resolution = MeasDesc_Resolution./1E-12; % give in picoseconds
    Header.Resolution = MeasDesc_Resolution./1E-9; % give in nanoseconds
    Header.MeasurementTime = MeasDesc_AcquisitionTime; % in milliseconds
    nRecords = TTResult_NumberOfRecords;
    %%% empty assignments for image-related fields
    Header.FrameStart = [];
    Header.LineStart = [];
    Header.LineStop = [];
    
    SyncPeriod = 1E9/Header.SyncRate;   % in nanoseconds
    if any(TTResultFormat_TTTRRecType == [rtTimeHarp260PT3,rtHydraHarpT3,rtHydraHarp2T3,rtMultiHarpNT3])  % read out the number of microtime bins
        Header.MI_Bins = ceil(MeasDesc_GlobalResolution./Resolution);
    end
    
    T3WRAPAROUND=65536;  % was same in original p2mat code           
    T3Record = fread(fid, nRecords, 'ubit32'); % read everything else in the binary file                   
    nsync = bitand(T3Record,65535);            
    dtime = bitand(bitshift(T3Record,-16),4095);

    chan = bitand(bitshift(T3Record,-28),15);  

    markers = (bitand(bitshift(T3Record,-16),15));   % the last bit:    
    clear T3Record
            
    ofltime = zeros(1,nRecords);
    ofltime( (markers == 0) & (chan == 15)) = 1;
    ofltime = T3WRAPAROUND.*cumsum(ofltime);
    ofltimeCt = length(find((markers == 0) & (chan == 15)));
    markerCt = length(find((markers ~= 0) & (chan == 15)));    
      
    ValidIndices = ((chan >= 1) & (chan <= 4));  
    TimeTag = double(nsync(ValidIndices))' + ofltime(ValidIndices);

    Resolution = Header.Resolution;

    truensync = ofltime + nsync';

%     truensyncEqlsCtNum = (length(truensync)==nRecords)
%     dbl_dtimeEqlsCtNum = (length(dtime)==nRecords)
%     TmpEnd = min([length(truensync), length(dtime)]);  

    A=truensync*SyncPeriod;
    B=(dtime*Resolution);
    TruerTime = A+B';        
    



    truetime = TruerTime';

    cnt_1=length(chan(chan==1));
    cnt_2=length(chan(chan==2));
    cnt_3=length(chan(chan==3));
    cnt_4=length(chan(chan==4));
    cnt_Ofl = ofltimeCt;
    cnt_M = markerCt;
    cnt_Err =length(find((chan(:)~=1)&(chan(:)~=2)&(chan(:)~=3)&(chan(:)~=4)&(chan(:)~=15)));
    
    save([pathname,'MatOut\',filename(1:end-4),'_ptu.mat'], 'chan', 'dtime', 'truetime')        
    fclose(fid);
    fprintf(1,'Ready!  \n');
    fprintf(1,'\nStatistics obtained from the data:\n');
    fprintf(1,'\nLast True Sync = %-14.0f, Last t = %14.3f ns,',truensync(end), truetime(end));
    fprintf(1,'\nRtCh1: %i counts, RtCh2: %i counts, RtCh3: %i counts, RtCh4: %i counts',cnt_1,cnt_2,cnt_3,cnt_4);
    fprintf(1,'\n%i overflows, %i markers, %i illegal events. Total: %i records read.',cnt_Ofl,cnt_M,cnt_Err,cnt_1+cnt_2+cnt_3+cnt_4+cnt_Ofl+cnt_M+cnt_Err);
    fprintf(1,'\n');    
end
close(waitb); toc
end

%% this for loop is used if pt3 files are in the folder
if pt3
waitb = waitbar(0);    
fprintf(1,'\n'); tic;
for a = 1:numFiles
    waitbar(a/numFiles, waitb, 'Converting from pt3 to mat')
    filename = filelist(a).name;
    fid=fopen([pathname filename]);
    
    % The following represents the readable ASCII file header portion 
    Ident = char(fread(fid, 16, 'char'));
    FormatVersion = deblank(char(fread(fid, 6, 'char')'));
    if not(strcmp(FormatVersion,'2.0'))
        fprintf(1,'\n\n      Warning: This program is for version 2.0 only. Aborted.');
        STOP;
    end
    CreatorName = char(fread(fid, 18, 'char'));
    CreatorVersion = char(fread(fid, 12, 'char'));
    FileTime = char(fread(fid, 18, 'char'));
    CRLF = char(fread(fid, 2, 'char'));
    CommentField = char(fread(fid, 256, 'char'));

    % The following is binary file header information
    Curves = fread(fid, 1, 'int32');
    BitsPerRecord = fread(fid, 1, 'int32')
    RoutingChannels = fread(fid, 1, 'int32')
    NumberOfBoards = fread(fid, 1, 'int32');
    ActiveCurve = fread(fid, 1, 'int32');
    MeasurementMode = fread(fid, 1, 'int32')
    SubMode = fread(fid, 1, 'int32');
    RangeNo = fread(fid, 1, 'int32');
    Offset = fread(fid, 1, 'int32');
    AcquisitionTime = fread(fid, 1, 'int32')
    StopAt = fread(fid, 1, 'int32');
    StopOnOvfl = fread(fid, 1, 'int32');
    Restart = fread(fid, 1, 'int32');
    DispLinLog = fread(fid, 1, 'int32');
    DispTimeFrom = fread(fid, 1, 'int32');
    DispTimeTo = fread(fid, 1, 'int32');
    DispCountFrom = fread(fid, 1, 'int32');
    DispCountTo = fread(fid, 1, 'int32');
    for i = 1:8
        DispCurveMapTo(i) = fread(fid, 1, 'int32');
        DispCurveShow(i) = fread(fid, 1, 'int32');
    end;

    for i = 1:3
        ParamStart(i) = fread(fid, 1, 'float');
        ParamStep(i) = fread(fid, 1, 'float');
        ParamEnd(i) = fread(fid, 1, 'float');
    end;

    RepeatMode = fread(fid, 1, 'int32');
    RepeatsPerCurve = fread(fid, 1, 'int32');
    RepeatTime = fread(fid, 1, 'int32');
    RepeatWait = fread(fid, 1, 'int32');
    ScriptName = char(fread(fid, 20, 'char'));

    % The next is a board specific header
    HardwareIdent = char(fread(fid, 16, 'char'));
    HardwareVersion = char(fread(fid, 8, 'char'));
    HardwareSerial = fread(fid, 1, 'int32');
    SyncDivider = fread(fid, 1, 'int32');
    CFDZeroCross0 = fread(fid, 1, 'int32');
    CFDLevel0 = fread(fid, 1, 'int32');
    CFDZeroCross1 = fread(fid, 1, 'int32');
    CFDLevel1 = fread(fid, 1, 'int32');
    Resolution = fread(fid, 1, 'float');

    % below is new in format version 2.0
    RouterModelCode      = fread(fid, 1, 'int32');
    RouterEnabled        = fread(fid, 1, 'int32');
    % Router Ch1
    RtChan1_InputType    = fread(fid, 1, 'int32');
    RtChan1_InputLevel   = fread(fid, 1, 'int32');
    RtChan1_InputEdge    = fread(fid, 1, 'int32');
    RtChan1_CFDPresent   = fread(fid, 1, 'int32');
    RtChan1_CFDLevel     = fread(fid, 1, 'int32');
    RtChan1_CFDZeroCross = fread(fid, 1, 'int32');
    % Router Ch2
    RtChan2_InputType    = fread(fid, 1, 'int32');
    RtChan2_InputLevel   = fread(fid, 1, 'int32');
    RtChan2_InputEdge    = fread(fid, 1, 'int32');
    RtChan2_CFDPresent   = fread(fid, 1, 'int32');
    RtChan2_CFDLevel     = fread(fid, 1, 'int32');
    RtChan2_CFDZeroCross = fread(fid, 1, 'int32');
    % Router Ch3
    RtChan3_InputType    = fread(fid, 1, 'int32');
    RtChan3_InputLevel   = fread(fid, 1, 'int32');
    RtChan3_InputEdge    = fread(fid, 1, 'int32');
    RtChan3_CFDPresent   = fread(fid, 1, 'int32');
    RtChan3_CFDLevel     = fread(fid, 1, 'int32');
    RtChan3_CFDZeroCross = fread(fid, 1, 'int32');
    % Router Ch4
    RtChan4_InputType    = fread(fid, 1, 'int32');
    RtChan4_InputLevel   = fread(fid, 1, 'int32');
    RtChan4_InputEdge    = fread(fid, 1, 'int32');
    RtChan4_CFDPresent   = fread(fid, 1, 'int32');
    RtChan4_CFDLevel     = fread(fid, 1, 'int32');
    RtChan4_CFDZeroCross = fread(fid, 1, 'int32');

    % The next is a T3 mode specific header
    ExtDevices = fread(fid, 1, 'int32');
    Reserved1 = fread(fid, 1, 'int32');
    Reserved2 = fread(fid, 1, 'int32');
    CntRate0 = fread(fid, 1, 'int32');
    CntRate1 = fread(fid, 1, 'int32');
    StopAfter = fread(fid, 1, 'int32');
    StopReason = fread(fid, 1, 'int32');
    Records = fread(fid, 1, 'uint32');
    ImgHdrSize = fread(fid, 1, 'int32');

    %Special header for imaging 
    ImgHdr = fread(fid, ImgHdrSize, 'int32');

    %  This reads the T3 mode event records
    ofltime = 0;
    cnt_1=0; cnt_2=0; cnt_3=0; cnt_4=0; cnt_Ofl=0; cnt_M=0; cnt_Err=0; % just counters
    WRAPAROUND=65536;       %%%%%%%%%%%%<--- is this supposed to be 65535??????????????????

    syncperiod = 1E9/CntRate0   % in nanoseconds
    fprintf(1,'Sync Rate = %d / second\n',CntRate0);
    fprintf(1,'Sync Period = %5.4f ns\n',syncperiod);
    fprintf(1,'\nThis may take a while...');

    chan = zeros(Records,1);
    dtime = zeros(Records,1);
    truetime = zeros(Records,1);
 
 
    T3Record = fread(fid, Records, 'ubit32');     % all 32 bits:
    nsync = bitand(T3Record,65535);       % the lowest 16 bits:
%% NOTE this is manipulating the binary values of the given integers... the binary values are in 32x1 arrays (of 1s and 0s)        
    chan = bitand(bitshift(T3Record,-28),15);    % the upper 4 bits:

    dtime = bitand(bitshift(T3Record,-16),4095);

    markers = (bitand(bitshift(T3Record,-16),15));   % the last bit:  % equivalent to 'markers' from original p2mat         
    clear T3Record

    ofltime= zeros(1,Records);
    ofltime( (markers == 0) & (chan == 15)) = 1;   % from original code
    ofltimeCt = length(find((markers == 0) & (chan == 15)));
    markerCt = length(find((markers ~= 0) & (chan == 15)));
    ofltime = WRAPAROUND*cumsum(ofltime);

    ValidIndices = ((chan >= 1) & (chan <= 4));  
    TimeTag = double(nsync(ValidIndices))' + ofltime(ValidIndices);

    truensync = ofltime + nsync';        
    A=truensync*syncperiod;
    B=(dtime*Resolution);
    truetime = A+B';            

    cnt_1=length(chan(chan==1));
    cnt_2=length(chan(chan==2));
    cnt_3=length(chan(chan==3));
    cnt_4=length(chan(chan==4));

    cnt_Ofl = ofltimeCt;
    cnt_M = markerCt;
    cnt_Err =length(find((chan(:)~=1)&(chan(:)~=2)&(chan(:)~=3)&(chan(:)~=4)&(chan(:)~=15)));
        
    truetime=truetime';
    
    save([pathname,'MatOut\',filename(1:end-4),'_pt3.mat'], 'chan', 'dtime', 'truetime')
    fclose(fid);
    fprintf(1,'Ready!  \n');
    fprintf(1,'\nStatistics obtained from the data:\n');
    fprintf(1,'\nLast True Sync = %-14.0f, Last t = %14.3f ns,',truensync(end), truetime(end));
    fprintf(1,'\nRtCh1: %i counts, RtCh2: %i counts, RtCh3: %i counts, RtCh4: %i counts',cnt_1,cnt_2,cnt_3,cnt_4);
    fprintf(1,'\n%i overflows, %i markers, %i illegal events. Total: %i records read.',cnt_Ofl,cnt_M,cnt_Err,cnt_1+cnt_2+cnt_3+cnt_4+cnt_Ofl+cnt_M+cnt_Err);
    fprintf(1,'\n');
    
end
close(waitb); toc
end    
