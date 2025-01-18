% Title: main_MouseSABehavior_20240429
% Author: Kevin Coffey, Ph.D.
% Affiliation: University of Washington, Psychiatry
% email address: mrcoffey@uw.edu  
% Last revision: 22-May 2024
% On 08/14/24 LKM edited rawVariableExtractor to show PR data
% SS revisions: 11/5/24 - 

% ------------- Description --------------
% This is the main analysis script for Golden Oral Fentanyl SA Behavior.
% ----------------------------------------

%% ------------- BEGIN CODE --------------
% Import sheet paths
main_folder = 'C:\Users\schle\Documents\Golden Local';
cd(main_folder)
beh_datapath = {'.\Behavior Data\R4 ER'}; % can add multiple data folders to cell array, data will be combined into one table
masterSheet_flnm = 'Golden R01 Behavior Master Key.xlsx';
BE_intake_canonical_flnm = '.\Import Sheets\2024.12.09.BE Intake Canonical.xlsx'; % only used if runtype == 'BE'

% Misc. Settings
runtype = 'ER'; % 'ER' (Extinction Reinstatement) or 'BE' (Behavioral Economics). SS note: add SA
firstHour = true; % separately run the first-hour of data (in addition to the full session)
excludeData = true; % whether or not to exclude data (based on info in excludeData_flmn)
% checkDateSessions = false; % [broken w/ new exclude-data system] date/session check only run if excludeData is also true (because it uses the excludeData sheet)

%  Figure Options
dailyData = false; % Should you run the daily figures
pubFigs = true; % Should you run the final publication figures
indivIntake_figs = true; 
groupIntake_figs = true; 
groupOralFentOutput_figs = true; 

% Save paths (these subfolders will be created in the "main_folder" if not
% already present, with subfolders in each for each dataset run with this code
dailyfigs_savepath = '.\Daily Figures\';
pubfigs_savepath = '.\Publication Figures\';
indivIntakefigs_savepath = '.\Individual Intake Figures\';
groupIntakefigs_savepath = '.\Group Intake Figures\'; 
groupOralFentOutput_savepath = '.\Combined Oral Fentanyl Output\';
tabs_savepath = '.\Behavior Tables\';

% Depricate
% run_indiff=false; % run individual differences analysis
% indifffigs_savepath = '.\Individual Differences Figures\';

%% Initial housekeeping

dt = date; % (datetime('today'))

% Import Master Key
addpath(genpath(main_folder))
opts = detectImportOptions(masterSheet_flnm);
opts = setvartype(opts,{'TagNumber','ID','Cage','Sex','Strain','TimeOfBehavior'},'categorical'); % Must be variables in the master key
mKey=readtable('Golden R01 Behavior Master Key.xlsx',opts);

% Create subdirectories
% SS added this subfolder system to sort saved elements
toMake = {tabs_savepath, dailyfigs_savepath, pubfigs_savepath, ...
          indivIntakefigs_savepath, groupIntakefigs_savepath, groupOralFentOutput_savepath};
new_dirs = makeSubFolders(beh_datapath, toMake, excludeData, firstHour);
sub_dir = new_dirs{1};
if firstHour
    fH_sub_dir = new_dirs{2};
end

%% Import SA Data

mT=table; % Initialize Master Table

for bd = 1:length(beh_datapath) % SS edit to pull data from multiple folders
    Files = dir(beh_datapath{bd});
    Files = Files(1:height(Files));
    startIdx = 1; % Current Wave Only
    disp(['Pulling ', num2str(length(Files)), '...']) % height(Files)-i);
    for i=startIdx:height(Files) % Loop all behavior files
        if contains(Files(i).name, '_Subject') || contains(Files(i).name, '.Subject') % SS edit to avoid invalid filenames
            % Import Data Geterated By MED-PC Code
            [varTable, eventCode, eventTime] = importMouseOralSA(fullfile(Files(i).folder, Files(i).name));
            % Calculate Variables Using Raw Data
            [varTable] = rawVariableExtractor_SS(varTable, eventCode, eventTime);
            % Concatonate the Master Table
            mT=[mT; varTable];
        end
    end
end

% Join Master Variable Table with Key to Include Grouping Variables
mT=innerjoin(mT,mKey,'Keys',{'TagNumber'},'RightVariables',{'Sex','Strain','TimeOfBehavior','Chamber'});

%% EXCLUSIONS
if excludeData
    mT = removeExcludedData(mT, mKey);
end

%% Determine Acquire vs Non-acquire
% Animals who do not average at least 10 rewards on week 2 of training
% This is a bimodal distribution and 10 is a clean cuttoff

ids=unique(mT.TagNumber);
Acquire=table; 
mT = sortrows(mT,'TagNumber','ascend');
Acq = nan(size(ids));

for l=1:height(ids)
    idx = mT.TagNumber==ids(l) & mT.Session>9 & mT.Session <16;
    Acq(l,1) = mean(mT.EarnedInfusions(idx)) > 10;
    if Acq(l) == 0 && sum(idx) ~= 0
        tmp = repmat(categorical({'NonAcquire'}), sum(mT.TagNumber == ids(l)), 1);
        Acquire = [Acquire; table(tmp)];
    else
        tmp=repmat(categorical({'Acquire'}), sum(mT.TagNumber == ids(l)), 1);
        Acquire = [Acquire; table(tmp)];
    end
end

Acquire.Properties.VariableNames{'tmp'} = 'Acquire';
mT=[mT Acquire];

%% FIRST HOUR
% SS updated to make the first-hour data its own table, which is separately
% analyzed from the full dataset if firstHour is set to true at the top 
% of the script
if firstHour
    addVars = {'TagNumber', 'Session', 'sessionType', 'slideSession', ...
               'Strain', 'Sex', 'TimeOfBehavior', 'Chamber', 'Acquire', ...
               'hourHeadEntries', 'hourActiveLever', 'hourInactiveLever', ...
               'hourEarnedInfusions', 'hourIntake', 'hourLastLatency'}; 
    renameFrom = {'hourHeadEntries', 'hourActiveLever', 'hourInactiveLever', ...
                  'hourEarnedInfusions', 'hourIntake', 'hourLastLatency'}; 
    renameTo = {'filteredHeadEntries', 'ActiveLever', 'InactiveLever', ...
                'EarnedInfusions', 'Intake', 'lastLatency'}; % SS note: switched this to lastLatency to avoid artifact. same change made in figure generation.
    hmT = mT(:, addVars);
    hmT = renamevars(hmT, renameFrom, renameTo);
end

%% check # data files per group
% numtab is a table that shows the number of data files for C57 and CD1
% males and females
numtab = numFilesPerGroup(mT);

%% Save Master Table and generate figures for spot checks daily

if dailyData
    % Save daily copy of the master table in .mat and xlsx format and save groups stats  
    mTname = [tabs_savepath, sub_dir, dt, '_MasterBehaviorTable.mat'];
    sub_mT = removevars(mT,{'eventCode', 'eventTime'});
    writetable(sub_mT,[tabs_savepath, sub_dir dt, '_MasterBehaviorTable.xlsx'], 'Sheet', 1);
    groupStats = grpstats(mT,["Sex", "Strain", "Session"], ["mean", "sem"], ...
        "DataVars",["ActiveLever", "InactiveLever", "EarnedInfusions", "filteredHeadEntries", "Latency", "Intake"]);
    writetable(groupStats, [tabs_savepath, sub_dir, dt, '_GroupStats.xlsx'], 'Sheet', 1);
    save(mTname,'mT');
    %Generate a set of figures to spotcheck data daily
    dailySAFigures_SS(mT,dt,[dailyfigs_savepath, sub_dir]);
    close all
    if firstHour
        dailySAFigures_SS(hmT,dt,[dailyfigs_savepath, fH_sub_dir])
        close all
    end
end

%% Generate Clean Subset of Figures for Publication

if pubFigs && strcmp(runtype, 'ER')
    pubSAFigures_SS(mT, dt, [pubfigs_savepath, sub_dir]);
    if firstHour 
        pubSAFigures_SS(hmT, dt, [pubfigs_savepath, fH_sub_dir]); 
    end
    close all;
   
elseif pubFigs && strcmp(runtype, 'BE')
    pubSAFiguresBEAnimals_SS(mT, dt, [pubfigs_savepath, sub_dir]);
    if firstHour
        pubSAFiguresBEAnimals_SS(hmT, dt, [pubfigs_savepath, fH_sub_dir]); 
    end
    close all;
    
end

%% ********** Behavioral Economics Analysis *************************************

if strcmp(runtype, 'BE')
    beT=mT; % Initialize Master Table
    
    % SS note: made Dose an array of nans instead of zeros to avoid divide-by-zeros errors
    Dose=nan([height(beT),1]);
    Dose(beT.Session==51 | beT.Session==16)=222; % SS note: the right side of every or statement was "beT.Session==x,1" which seemed wrong, dropped the ',1'
    Dose(beT.Session==52 | beT.Session==17)=125;
    Dose(beT.Session==53 | beT.Session==18)=70; 
    Dose(beT.Session==54 | beT.Session==19)=40;
    Dose(beT.Session==55 | beT.Session==20)=22;
    beT=[beT table(Dose)];
    unitPrice=(1000./beT.Dose);
    beT=[beT table(unitPrice)];
    
    % Import Measured Intake Data
    opts = detectImportOptions(BE_intake_canonical_flnm); 
    beiT=readtable(BE_intake_canonical_flnm, opts);
    beiT.TagNumber=categorical(beiT.TagNumber); %% SS: redundant?
    Day=beiT.Day;
    measuredIntake=beiT.measuredIntake;
    beT=[beT; table(Day, measuredIntake)];
    
    % Curve Fit Each Animals Intake over Dose
    TagNumber = unique(beT.TagNumber);
    aT=table(TagNumber,Acq);
    beT=innerjoin(beT,aT,'Keys',{'TagNumber'},'RightVariables',{'Acq'});
    IDs=unique(beT.TagNumber);
    
    for i=1:height(IDs)
        tmp=beT(beT.TagNumber==IDs(i),23);
        Sex(i,1)=tmp{1,1};
        tmp=beT(beT.TagNumber==IDs(i),24);
        Strain(i,1)=tmp{1,1};
        in=beT{beT.TagNumber==IDs(i),29};
        in=in(1:5);
        
        price=beT{beT.TagNumber==IDs(i),27};
        price=price(1:5);
        price(in == 0) = []; % SS added to avoid fit error when in == 0)
        in(in == 0) = []; % SS added to avoid fit error when in == 0)
        price=price-price(1)+1;
        
        if height(in) > 1
            myfittype = fittype('log(b)*(exp(1)^(-1*a*x))',...
            'dependent',{'y'},'independent',{'x'},...
            'coefficients',{'a','b'});
        
            f=fit(price,log(in),myfittype,'StartPoint', [.003, 200],'lower',[.0003 100],'upper',[.03 1500]);
            
            f1=figure;
            plot(log(1:50),f(1:50));
            hold on;
            scatter(log(price),log(in),10);
            [res_x, idx_x]=knee_pt(log(1:500),f(1:500));
            plot([log(idx_x) log(idx_x)],[min(f(1:50)) max(f(1:50))],'--k');
            xlim([-1 5]);
            title(IDs(i))
            Alpha(i,1)=f.a;
            Elastic(i,1)=idx_x;
        end
        close(f1);
    end
    
    % aT=table(IDs,Sex,Strain,Alpha,Elastic);
    
    f=figure('Position',[100 100 350 500],'Color',[1 1 1]);
    clear g
    g(1,1)=gramm('x',log2(beT.unitPrice),'y',beT.measuredIntake,'color',beT.Sex,'subset', beT.Strain=='c57' & beT.Acq==1);
    g(1,1).set_color_options('hue_range',[0 360],'lightness_range',[85 35],'chroma_range',[30 70]);
    g(1,1).stat_summary('geom',{'black_errorbar','point','line'},'type','sem','dodge',0,'setylim',1,'width',1);
    % g(1,1).geom_jitter();
    g(1,1).set_point_options('markers',{'o','s'},'base_size',10);
    g(1,1).set_text_options('font','Helvetica','base_size',13,'legend_scaling',.75,'legend_title_scaling',.75);
    g(1,1).axe_property('LineWidth',1.5,'XLim',[1.5 6],'YLim',[0 4000],'tickdir','out');
    g(1,1).set_names('x','Fentnayl Concentration (ug/mL)','y','Fentanyl Intake (μg/kg)','color','Sex');
    %g(1,1).no_legend();
    
    g(2,1)=gramm('x',log2(beT.unitPrice),'y',beT.ActiveLever,'color',beT.Sex,'subset', beT.Strain=='c57' & beT.Acq==1);
    g(2,1).set_color_options('hue_range',[0 360],'lightness_range',[85 35],'chroma_range',[30 70]);
    g(2,1).stat_summary('geom',{'black_errorbar','point','line'},'type','sem','dodge',0,'setylim',1,'width',1);
    g(2,1).set_point_options('markers',{'o','s'},'base_size',10);
    g(2,1).set_text_options('font','Helvetica','base_size',13,'legend_scaling',.75,'legend_title_scaling',.75);
    g(2,1).axe_property('LineWidth',1.5,'XLim',[1.5 6],'YLim',[0 200],'tickdir','out');
    g(2,1).set_names('x','Fentnayl Concentration (ug/mL)','y','Active Lever Presses','color','Sex');
    g.draw;
    
    % Marker Manipulation
    set(g(1,1).results.stat_summary(1).point_handle,'MarkerEdgeColor',[0 0 0]);  
    set(g(1,1).results.stat_summary(2).point_handle,'MarkerEdgeColor',[0 0 0]);  
    set(g(2,1).results.stat_summary(1).point_handle,'MarkerEdgeColor',[0 0 0]); 
    set(g(2,1).results.stat_summary(2).point_handle,'MarkerEdgeColor',[0 0 0]);
    set(g(1,1).facet_axes_handles,'Xtick',log2([4.5 8 14.3 25 45.5]),'XTickLabel',{'220','125','70','40','10'});
    set(g(2,1).facet_axes_handles,'Xtick',log2([4.5 8 14.3 25 45.5]),'XTickLabel',{'220','125','70','40','10'});
    
    exportgraphics(f,[figs_savepath, sub_dir, 'c57BE_1.png']);
    
    f=figure('Position',[100 100 350 500],'Color',[1 1 1]);
    clear g
    g(1,1)=gramm('x',log2(beT.unitPrice),'y',beT.Latency,'color',beT.Sex,'subset', beT.Strain=='c57' & beT.Acq==1);
    g(1,1).set_color_options('hue_range',[0 360],'lightness_range',[85 35],'chroma_range',[30 70]);
    g(1,1).stat_summary('geom',{'black_errorbar','point','line'},'type','sem','dodge',0,'setylim',1,'width',1);
    g(1,1).set_point_options('markers',{'o','s'},'base_size',10);
    g(1,1).set_text_options('font','Helvetica','base_size',13,'legend_scaling',.75,'legend_title_scaling',.75);
    g(1,1).axe_property('LineWidth',1.5,'XLim',[1.5 6],'YLim',[0 150],'tickdir','out');
    g(1,1).set_names('x','Fentnayl Concentration (ug/mL)','y','Head Entry Latency (s)','color','Sex');
    %g(1,1).no_legend();
    
    g(2,1)=gramm('x',log2(beT.unitPrice),'y',beT.EarnedInfusions,'color',beT.Sex,'subset', beT.Strain=='c57' & beT.Acq==1);
    g(2,1).set_color_options('hue_range',[0 360],'lightness_range',[85 35],'chroma_range',[30 70]);
    g(2,1).stat_summary('geom',{'black_errorbar','point','line'},'type','sem','dodge',0,'setylim',1,'width',1);
    g(2,1).set_point_options('markers',{'o','s'},'base_size',10);
    g(2,1).set_text_options('font','Helvetica','base_size',13,'legend_scaling',.75,'legend_title_scaling',.75);
    g(2,1).axe_property('LineWidth',1.5,'XLim',[1.5 6],'YLim',[0 80],'tickdir','out');
    g(2,1).set_names('x','Fentnayl Concentration (ug/mL)','y','Rewards','color','Sex');
    g.draw;
    
    % Marker Manipulation
    set(g(1,1).results.stat_summary(1).point_handle,'MarkerEdgeColor',[0 0 0]);  
    set(g(1,1).results.stat_summary(2).point_handle,'MarkerEdgeColor',[0 0 0]);  
    set(g(2,1).results.stat_summary(1).point_handle,'MarkerEdgeColor',[0 0 0]); 
    set(g(2,1).results.stat_summary(2).point_handle,'MarkerEdgeColor',[0 0 0]);
    set(g(1,1).facet_axes_handles,'Xtick',log2([4.5 8 14.3 25 45.5]),'XTickLabel',{'220','125','70','40','10'});
    set(g(2,1).facet_axes_handles,'Xtick',log2([4.5 8 14.3 25 45.5]),'XTickLabel',{'220','125','70','40','10'});
    
    exportgraphics(f,[figs_savepath, sub_dir, 'c57BE_2.png']);
end

%% Within Session Behavioral Analysis
% Event Codes
% 3 = Rewarded Press
% 13 = Tone On
% 97 = ITI Press
% 23 = Inactive Press
% 96?
% 97?
% 98 = Rewarded Head Entry
% 99 = Unrewarded Head Entry

% SS note: how much of the code from here is usable for BE

    
mTDL = mT(mT.Acquire=='Acquire' & mT.EarnedInfusions>10,:); % SS note: - why are we limiting the analysis here to sessions w/ >10 infusions
mPressT = table;
mDrugLT = table;

disp(['Running individual within-session intake analysis for ' num2str(height(mTDL)) ' sessions...']);  
for i=1:height(mTDL)
    disp(i)
    eventCode = mTDL.eventCode{i};
    eventTime = mTDL.eventTime{i};
    % get filtered head entry event codes and times
    [eventCodeFilt,eventTimeFilt] = eventFilterHE(eventCode,eventTime); 
    
    % Analyze Rewarded Lever Pressing Across the Session
    rewLP=eventTimeFilt(eventCodeFilt==13);
    rewHE=eventTimeFilt(eventCodeFilt==98);

    doseHE=[];

    for j=1:height(rewHE)
        if j==1
            doseHE(j,1)=sum(rewLP<rewHE(j,1));
        else
            doseHE(j,1)=sum(rewLP<rewHE(j,1))-sum(doseHE(1:j-1,1));
        end
    end
    cumulDoseHE = cumsum(doseHE);

     % SS added because rewHE is not always the same length as rewLP 
    if length(rewLP) ~= length(doseHE)
        adj_rewLP = [];
        for z = 1:length(rewHE)
            adj_rewLP = [adj_rewLP; rewLP(find(rewLP < rewHE(z), 1, 'last'))];
            if i == 12
                disp(z)
                disp(adj_rewLP);
                disp(' ')
            end
        end
    else
        adj_rewLP = rewLP;
    end

    TagNumber=repmat([mTDL.TagNumber(i)],length(adj_rewLP),1);
    Session=repmat([mTDL.Session(i)],length(adj_rewLP),1);
    Sex =repmat([mTDL.Sex(i)],length(adj_rewLP),1);
    Strain =repmat([mTDL.Strain(i)],length(adj_rewLP),1);

    if i==1
        mPressT=table(TagNumber, Session, adj_rewLP, cumulDoseHE, Sex, Strain);
    else
        mPressT=[mPressT; table(TagNumber, Session, adj_rewLP, cumulDoseHE, Sex, Strain)];
    end
    
    % SS note: hard-coded drug intake, not ideal
    [DL, DLTime] = pharmacokineticsMouseOralFent('infusions',[rewHE*1000 (rewHE+(4*doseHE))*1000],'duration',180,'type',4,'weight',mT.Weight(i)./1000,'mg_mL',0.07,'mL_S',.005);
    DL = DL';
    DLTime=(.1:.1:180)';
    DL = imresize(DL, [length(DLTime),1]);
    
    TagNumber = repmat([mTDL.TagNumber(i)],length(DL),1);
    Session = repmat([mTDL.Session(i)],length(DL),1);
    Sex = repmat([mTDL.Sex(i)],length(DL),1);
    Strain = repmat([mTDL.Strain(i)],length(DL),1);
    sessionType = repmat([mTDL.sessionType(i)],length(DL),1);
    
    if i==1
        mDrugLT = table(TagNumber, Session, DL, DLTime, Sex, Strain, sessionType);
    else
        mDrugLT = [mDrugLT; table(TagNumber, Session, DL, DLTime, Sex, Strain, sessionType)];
    end
    
    if indivIntake_figs
    % SS note: a bunch missing to run this and there was seemingly a duplicate figure below it...
    %          ...check Kevin's file  
        % SS note: y was missing for g(1,1), filled it in with what I thought made sense
        g(1,1)=gramm('x',adj_rewLP/60, 'y', cumulDoseHE); %color',cat); SS note: cat var missing
        g(1,1).stat_bin('normalization','cumcount','geom','stairs','edges',0:1:180);
        g(2,1)=gramm('x',DLTime(:), 'y', DL(:)*1000); % ,'color',cat2); % SS note: what's this *1000 for?
        g(2,1).geom_line();
        g(1,1).axe_property('LineWidth',1.5,'FontSize',13,'XLim',[0 180],'tickdir','out');
        g(1,1).set_names('x','Session Time (m)','y','Cumulative Infusions');
        g(2,1).axe_property('LineWidth',1.5,'FontSize',13,'XLim',[0 180],'tickdir','out');
        g(2,1).set_names('x','Session Time (m)','y','Brain Fentanyl Concentration pMOL');
        f=figure('Position',[100 100 400 800]);
    
        g.draw;
        exportgraphics(f,fullfile([indivIntakefigs_savepath, sub_dir, ...
                       'Tag', num2str(double(mTDL.TagNumber(i))), ...
                       '_Session', num2str(double(mTDL.Session(i))), ...
                       '_estBrainFent.pdf']),'ContentType','vector');
        close(f);
    end
end

if indivIntake_figs
    IDs=unique(mPressT.TagNumber);
    for j=1:length(IDs)
        f=figure('Position',[1 1 1920 1080]);
        g=gramm('x', mPressT.adj_rewLP/60,'y', mPressT.cumulDoseHE, 'subset', mPressT.TagNumber==IDs(j));
        g.set_color_options('hue_range',[-65 265],'chroma',80,'lightness',70,'n_color',2);
        g.facet_wrap(mPressT.Session,'scale','independent','ncols',4,'force_ticks',1,'column_labels',1);
        g.stat_bin('normalization','cumcount','geom','stairs','edges',0:1:180);
        g.axe_property('LineWidth',1.5,'FontSize',12,'XLim',[0 180],'tickdir','out');
        g.set_names('x',' Time (m)','y','Cumulative Responses');
        g.set_title(['ID: ' char(IDs(j))]);
        g.draw;
        for i=1:length(g.facet_axes_handles)
            % g.facet_axes_handles(i).Title.String=['Day ' num2str(i)];
            g.facet_axes_handles(i).Title.FontSize=12;
            set(g.facet_axes_handles(i),'XTick',[0 90 180]);
        end
        exportgraphics(f,[indivIntakefigs_savepath, sub_dir, 'Tag', char(IDs(j)), '_All_Session_Infusions.png']);
        close(f)
    end
        
    for j=1:length(IDs)
        f=figure('Position',[1 1 1920 1080]);
        g=gramm('x',mDrugLT.DLTime,'y',mDrugLT.DL,'subset', mDrugLT.TagNumber==IDs(j));
        g.set_color_options('hue_range',[-65 265],'chroma',80,'lightness',70,'n_color',1);
        g.facet_wrap(mDrugLT.Session,'scale','independent','ncols',4,'force_ticks',1,'column_labels',1);
        g.geom_line();
        g.axe_property('LineWidth',1.5,'FontSize',12,'XLim',[0 180],'tickdir','out');
        g.set_names('x',' Time (m)','y','Estimated Brain Fentanyl (pMOL)');
        g.set_title(['ID: ' char(IDs(j))]);
        g.draw;
        for i=1:length(g.facet_axes_handles)
            %g.facet_axes_handles(i).Title.String=['Day ' num2str(i)];
            g.facet_axes_handles(i).Title.FontSize=12;
            set(g.facet_axes_handles(i),'XTick',[0 90 180]);
        end
        exportgraphics(f, [indivIntakefigs_savepath, sub_dir, 'Tag', char(IDs(j)), 'All_Session_Drug_Level.png']);
        close(f)
    end
end


%% Grouped intake-across-session figures
if groupIntake_figs
    % Drug Level by Strain and Sex 
    g=gramm('x',mDrugLT.DLTime,'y',mDrugLT.DL,'color',mDrugLT.Strain,'lightness',mDrugLT.Sex); %,'subset',mDrugLT.Strain=='CD1');
    g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
    g.facet_wrap(mDrugLT.Session,'scale','independent','ncols',3,'force_ticks',1,'column_labels',1);
    g.stat_summary('geom','area','setylim',1);
    g.axe_property('LineWidth',1.5,'FontSize',10,'XLim',[0 180],'tickdir','out');
    g.set_names('x',' Time (m)','y','Estimated Brain Fentanyl (pMOL)','column','Session');
    f = figure('units','normalized','outerposition',[0 0 .5 1]);
    g.draw;
    for i=1:length(g.facet_axes_handles)
        g.facet_axes_handles(i).YLim=[0 500];
    end
    exportgraphics(f, [groupIntakefigs_savepath, sub_dir,'Drug Level Grouped Sex and Strain.png']);
    close(f)

    % Drug Level by Sex during Training
    g=gramm('x',mDrugLT.DLTime,'y',mDrugLT.DL,'color',mDrugLT.Sex,'subset',mDrugLT.sessionType=='Training');
    g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
    g.facet_wrap(mDrugLT.Session,'scale','independent','ncols',5,'force_ticks',1,'column_labels',0);
    g.stat_summary('geom','area','setylim',1);
    g.axe_property('LineWidth',1.5,'FontSize',13,'XLim',[0 180],'tickdir','out');
    g.set_names('x',' Time (m)','y','Brain DL (pMOL)');
    g.set_title('Average Drug Level (Training)');
    f=figure('Position',[100 100 1200 800]);
    g.draw;
    for i=1:length(g.facet_axes_handles)
        g.facet_axes_handles(i).Title.String=['Day ' num2str(i)];
        g.facet_axes_handles(i).Title.FontSize=12;
        g.facet_axes_handles(i).YLim=[0 300];
    end
    exportgraphics(f,[groupIntakefigs_savepath, sub_dir,'Drug Level Grouped Sex.pdf'],'ContentType','vector');
    close(f)

    % Drug Level by Sex and Session during Training Sessions 5, 10, 15
    g=gramm('x',mDrugLT.DLTime,'y',mDrugLT.DL,'color',mDrugLT.Sex,'lightness',mDrugLT.Session,'subset',(mDrugLT.Session==5 | mDrugLT.Session==10 | mDrugLT.Session==15));
    %g=gramm('x',mDrugLT.DLTime,'y',mDrugLT.DL*1000);
    g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
    g.stat_summary('geom','line','setylim',1);
    g.set_text_options('font','Helvetica','base_size',12,'legend_scaling',.75,'legend_title_scaling',.75);
    g.axe_property('LineWidth',1.5,'XLim',[0 180],'YLim',[0 200],'tickdir','out');
    g.set_names('x',' Time (m)','y','Estimated Brain Fentanyl');
    g.set_title('Average Drug Level (Training days 1, 5, and 10)');
    % g.no_legend();
    f=figure('Position',[100 100 450 400]);
    g.draw;
    set(g.facet_axes_handles,'YTick', 0:50:200, 'XTick', [0 90 180]);
    exportgraphics(f,[groupIntakefigs_savepath, sub_dir,'Mean Drug Level Grouped by Sex and Session 5 10 15.pdf'],'ContentType','vector');
    close(f)

    % Cumulative responses (rewarded head entries) by Sex and Session during Training Sessions 5, 10, 15
    % SS note: modded x and added missing y values again
    g=gramm('x',mPressT.adj_rewLP/60, 'y', mPressT.cumulDoseHE, 'color', mPressT.Sex, 'lightness', mPressT.Session, 'subset', (mPressT.Session==5 | mPressT.Session==10 | mPressT.Session==15));
    g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
    g.stat_bin('normalization','cumcount','geom','stairs','edges',0:1:180);
    g.set_text_options('font','Helvetica','base_size',12,'legend_scaling',.75,'legend_title_scaling',.75);
    g.axe_property('LineWidth',1.5,'XLim',[0 180],'YLim',[0 300],'tickdir','out');
    g.set_names('x',' Time (m)','y','Cumulative Responses');
    g.set_title('Average Cumulative Responses');
    
    % g.no_legend();
    f=figure('Position',[100 100 450 400]);
    g.draw;
    set(g.facet_axes_handles, 'YTick', 0:50:300, 'XTick', [0 90 180]);
    exportgraphics(f,[groupIntakefigs_savepath, sub_dir,'Mean Responses Grouped by Sex and Session 5 10 15.pdf'],'ContentType','vector');
    close(f)

end

%% Statistic Linear Mixed Effects Models
load(['.\Behavior Tables\', sub_dir, dt, '_MasterBehaviorTable.mat']); % SS note: what var is this? 
% SS note: commented out errors, come back to it. 
% Training
IntakeTrainLME = fitlme(mT(mT.sessionType=='Training',:),'Intake ~ Sex*Session + (1|ID)');
InfusionsTrainLME = fitlme(mT(mT.sessionType=='Training',:),'Infusions ~ Sex*Session + (1|ID)');
HeadTrainLME = fitlme(mT(mT.sessionType=='Training',:),'HeadEntries ~ Sex*Session + (1|ID)');
LatencyTrainLME = fitlme(mT(mT.sessionType=='Training',:),'Latency ~ Sex*Session + (1|ID)');
ActiveTrainLME = fitlme(mT(mT.sessionType=='Training',:),'ActiveLever ~ Sex*Session + (1|ID)');
InactiveTrainLME = fitlme(mT(mT.sessionType=='Training',:),'InactiveLever ~ Sex*Session + (1|ID)');

IntakeTrainF = anova(IntakeTrainLME,'DFMethod','satterthwaite');
InfusionsTrainF = anova(InfusionsTrainLME,'DFMethod','satterthwaite');
HeadTrainF = anova(HeadTrainLME,'DFMethod','satterthwaite');
LatencyTrainF = anova(LatencyTrainLME,'DFMethod','satterthwaite');
ActiveTrainF = anova(ActiveTrainLME,'DFMethod','satterthwaite');
InactiveTrainF = anova(InactiveTrainLME,'DFMethod','satterthwaite');

% Extinction
HeadExtLME = fitlme(mT(mT.sessionType=='Extinction',:),'HeadEntries ~ Sex*Session + (1|ID)');
LatencyExtLME = fitlme(mT(mT.sessionType=='Extinction',:),'Latency ~ Sex*Session + (1|ID)');
ActiveExtLME = fitlme(mT(mT.sessionType=='Extinction',:),'ActiveLever ~ Sex*Session + (1|ID)');
InactiveExtLME = fitlme(mT(mT.sessionType=='Extinction',:),'InactiveLever ~ Sex*Session + (1|ID)');

HeadExtF = anova(HeadExtLME,'DFMethod','satterthwaite');
LatencyExtF = anova(LatencyExtLME,'DFMethod','satterthwaite');
ActiveExtF = anova(ActiveExtLME,'DFMethod','satterthwaite');
InactiveExtF = anova(InactiveExtLME,'DFMethod','satterthwaite');

% Reinstatement
HeadReinLME = fitlme(mT(mT.Session>22,:),'HeadEntries ~ Sex*Session + (1|ID)');
LatencyReinLME = fitlme(mT(mT.Session>22,:),'Latency ~ Sex*Session + (1|ID)');
ActiveReinLME = fitlme(mT(mT.Session>22,:),'ActiveLever ~ Sex*Session + (1|ID)');
InactiveReinLME = fitlme(mT(mT.Session>22,:),'InactiveLever ~ Sex*Session + (1|ID)');

HeadReinF = anova(HeadReinLME,'DFMethod','satterthwaite');
LatencyReinF = anova(LatencyReinLME,'DFMethod','satterthwaite');
ActiveReinF = anova(ActiveReinLME,'DFMethod','satterthwaite');
InactiveReinF = anova(InactiveReinLME,'DFMethod','satterthwaite');

statsname=fullfile('Statistics','Oral SA Group Stats.mat');
save(statsname,'IntakeTrainF','InfusionsTrainF','HeadTrainF','LatencyTrainF','ActiveTrainF','InactiveTrainF',...
    'HeadExtF','LatencyExtF','ActiveExtF','InactiveExtF',...
    'HeadReinF','LatencyReinF','ActiveReinF','InactiveReinF');


%% Individual Variability Suseptibility Modeling
% INDIVIDUAL VARIABLES
% Intake = total fentanyl consumption in SA (ug/kg)
% Seeking = total head entries in SA
% Cue Association = HE Latency in SA (Invert?) SS note: Could, but it would need to be inverted again for the Severity score
% Escalation = Slope of intake in SA
% Extinction = total active lever presses during extinction
% Persistance = slope of extinction active lever presses
% Flexibility = total inactive lever presses during extinction (Invert?)
% Relapse = total presses during reinstatement
% Cue Recall = HE Latency in reinstatement (invert?)tmpT

% SS note: keep commented, all this is imported prior. 
% Completely Raw Behavior Intake (Possible Fix to Minor Acq Issues)
% for i=1:height(mT)
% disp(num2str(height(mT)-i));    
% raw=importOralSA(fullfile(mT.folder{i}, mT.name{i}));
% [eventCode,eventTime] = EventExtractor(raw);
% [eventCode,eventTime] = eventFilter(eventCode,eventTime);
% end

ID = unique(mT.TagNumber);
[Dummy, Intake, Seeking, Association, Escalation, Extinction,  ...
 Persistence, Flexibility, Relapse, Recall] = deal([]);

Sex = categorical([]);

for i=1:length(ID)
    Dummy(i,1)=1;       
    Intake(i,1)= mean(mT.Intake(mT.TagNumber==ID(i) & mT.Session>5 & mT.sessionType=='Training'));
    % SS note: changed this to filteredHeadEntries
    Seeking(i,1)= mean(mT.filteredHeadEntries(mT.TagNumber==ID(i) & mT.Session>5 & mT.sessionType=='Training'));
    % SS note: made this nanmax and nanmean so it wouldn't break for animals that had no active-lever press sessions during training
    % SS note: changed this to lastLatency
    Association(i,1)= nanmean(mT.lastLatency(mT.TagNumber==ID(i) & mT.Session>5 & mT.sessionType=='Training')); 
    % SS changed the x-value to polyfit from 1:1:10 to account for excluded session cases
    e = polyfit(double(mT.Session(mT.TagNumber==ID(i) & mT.sessionType=='Training')),mT.TotalInfusions(mT.TagNumber==ID(i) & mT.Session>5 & mT.sessionType=='Training'),1);
    Escalation(i,1)=e(1);
    % SS note: made this nanmean so it wouldn't break for animals that had no active-lever press sessions during training
    Extinction(i,1)= nanmean(mT.ActiveLever(mT.TagNumber==ID(i) & mT.sessionType=='Extinction'));
    % SS changed the x-value to polyfit from 1:1:10 to account for excluded session cases
    p = polyfit(double(mT.Session(mT.TagNumber==ID(i) & mT.sessionType=='Extinction')),mT.ActiveLever(mT.TagNumber==ID(i) & mT.sessionType=='Extinction'),1);
    Persistence(i,1)=0-p(1);
    Flexibility(i,1)=mean(mT.InactiveLever(mT.TagNumber==ID(i) & mT.sessionType=='Extinction'));
    Relapse(i,1)=mT.ActiveLever(mT.TagNumber==ID(i) & mT.sessionType=='Reinstatement');
    Recall(i,1)=mT.Latency(mT.TagNumber==ID(i) & mT.sessionType=='Reinstatement');
    s=mT.Sex(mT.TagNumber==ID(i) & mT.sessionType=='Training');
    Sex(i,1)=s(1);
end

% SS note: why log? 
Association=log(Association);
Recall=log(Recall);

% SS note: sup with this bit? overwrite self, just for side checks? 
% % Tests of Normality vs Bimodal
% [hIn pIn]=kstest(zscore(Intake));
% [hIn pIn]=kstest(zscore(Seeking));
% [hIn pIn]=kstest(zscore(Association));
% [hIn pIn]=kstest(zscore(Escalation));
% [hIn pIn]=kstest(zscore(Extinction));
% [hIn pIn]=kstest(zscore(Relapse));

% SS note: what is this showing
% figure
% hold on
% cdfplot(zscore(Extinction))
% x_values = linspace(min(zscore(Extinction)),max(zscore(Extinction)));
% plot(x_values,normcdf(x_values,0,1),'r-')
% legend('Empirical CDF','Standard Normal CDF','Location','best')
% hold off

% Individual Variable Table
ivT=table(ID,Sex,Intake,Seeking,Association,Escalation,Extinction,Relapse);

% SS note: what was ivT? what is .S? keeping commented for now..
% corrMat=corr([ivT.Intake,ivT.S]); % Slope Calculation & IV Extraction

% % Z-Score & Severity Score
ivZT=ivT;
ivZT.Intake=zscore(ivZT.Intake);
ivZT.Seeking=zscore(ivZT.Seeking);
ivZT.Association=zscore(nanmax(ivZT.Association)-ivZT.Association);
ivZT.Escalation=zscore(ivZT.Escalation);
ivZT.Extinction=zscore(ivZT.Extinction);
ivZT.Relapse=zscore(ivZT.Relapse);

% % Correlations
varnames = ivZT.Properties.VariableNames;
prednames = varnames(varnames ~= "ID" & varnames ~= "Sex");
ct=corr(ivZT{:,prednames},Type='Pearson');

if groupOralFentOutput_figs
    f=figure('Position',[1 1 700 600]);
    imagesc(ct,[0 1]); % Display correlation matrix as an image
    colormap('hot');
    a = colorbar();
    a.Label.String = 'Rho';
    a.Label.FontSize = 12;
    a.FontSize = 12;
    set(gca, 'XTickLabel', prednames, 'XTickLabelRotation',45, 'FontSize', 12); % set x-axis labels
    set(gca, 'YTickLabel', prednames, 'YTickLabelRotation',45, 'FontSize', 12); % set x-axis labels
    box off
    set(gca,'LineWidth',1.5,'TickDir','out')
    % SS commented out bc I don't hav corrplotKC.m
    % [corrs,~,h2] = corrplotKC(ivZT,DataVariables=prednames,Type="Spearman",TestR="on");
    exportgraphics(f,[groupOralFentOutput_savepath, sub_dir, 'Individual Differences_Correlations.pdf'],'ContentType','vector');
    close(f)
end

Severity = sum(ivZT{:, prednames}')';
Class = cell([height(Severity) 1]);
Class(Severity>1.5) = {'High'};
Class(Severity>-1.5 & Severity<1.5) = {'Mid'};
Class(Severity<-1.5) = {'Low'};
Class = categorical(Class);
ivT=[ivT table(Severity, Class)];

[hIn, pIn] = kstest(zscore(Severity));

save(".\Behavior Tables\Master Behavior Table.mat","mT",'ivT','ivZT');

yVars = {'Intake', 'Seeking', 'Association', 'Escalation', 'Extinction', 'Relapse', 'Severity'};
yLabs = {' Fentanyl Intake (mg/kg)', 'Seeking (Head Entries)', 'Association (Latency)', ...
         'Escalation (slope Training Intake)', 'Extinction Responses', 'Relapse (Reinstatement Responses)', 'Severity' };
f = plotViolins(ivT, yVars, yLabs);
exportgraphics(f,[groupOralFentOutput_savepath, sub_dir, 'Individual Differences_Violin.pdf'],'ContentType','vector');
close(f)

%% TSNE
varnames = ivZT.Properties.VariableNames;
prednames = varnames(varnames ~= "ID" & varnames ~= "Sex" & varnames ~= "Class");
Y = tsne(ivZT{:,prednames},'Algorithm','exact','Distance','cosine','Perplexity',15);
[coeff,score,latent] = pca(ivZT{:,prednames});
PC1=score(:,1);
PC2=score(:,2);

f1=figure('color','w','position',[100 100 400 325]);
h1 = biplot(coeff(:,1:3),'Scores',score(:,1:3),...
    'Color','b','Marker','o','VarLabels',prednames);
for i=1:6
    h1(i).Color=[.5 .5 .5];    
    h1(i).LineWidth=1.5;
    h1(i).LineStyle=':';
    h1(i).Marker='o';
    h1(i).MarkerSize=4;
    h1(i).MarkerFaceColor=[.5 .5 .5];
    h1(i).MarkerEdgeColor=[0 .0 0];
end
for i=7:12
    h1(i).Marker='none';
end

R = rescale(Severity,4,18);
for i=19:40
    if Sex(i-18)=='Male'
        h1(i).MarkerFaceColor=[.46 .51 1];
        h1(i).MarkerEdgeColor=[0 .0 0];
        h1(i).MarkerSize=R(i-18);
    else
        h1(i).MarkerFaceColor=[.95 .39 .13];
        h1(i).MarkerEdgeColor=[0 .0 0];
        h1(i).MarkerSize=R(i-18);
    end
end
for i=13:18
h1(i).FontSize=11;
h1(i).FontWeight='bold';
end
h1(13).Position=[.535 .185];
h1(14).Position=[.435 .625];
h1(15).Position=[.4 -.265];
h1(16).Position=[.485 .285];
h1(17).Position=[.435 -.41];
h1(18).Position=[.435 -.515];
set(gca,'LineWidth',1.5,'TickDir','in','FontSize',14);
grid off
xlabel('');
ylabel('');
zlabel('');
exportgraphics(f1,[groupOralFentOutput_savepath, sub_dir, 'Individual Differences PCA Vectors.pdf'],'ContentType','vector');

% SS uncommented, don't have the CaptureFigVid function and am not needing
% this with code currently uncommented...
% % Set up recording parameters (optional), and record
% OptionX.FrameRate=30;OptionX.Duration=20;OptionX.Periodic=true;
% CaptureFigVid([-180,0;0,90], 'PCA',OptionX)

pcTable=table(Class,PC1,PC2);
f1=figure('color','w','position',[100 100 300 225]);
g=gramm('x',pcTable.PC1,'y',pcTable.PC2,'color',ivT.Sex,'marker',ivT.Class);
g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
g.geom_point();
g.set_names('x','PC1','y','PC2','color','Class');
g.axe_property('FontSize',12,'LineWidth',1.5,'TickDir','out');
g.set_order_options('marker',{'High','Mid','Low'});
g.set_point_options('base_size',8);
g.draw;
for i=1:height(g.results.geom_point_handle)
   g.results.geom_point_handle(i).MarkerEdgeColor = [0 0 0];
end
exportgraphics(f1,[groupOralFentOutput_savepath, sub_dir, 'Individual Differences TSNE.pdf'],'ContentType','vector');


%% BE Battery & Hot Plate
% 
% % Hot Plate
% % clear all;
% opts = detectImportOptions('2022.02.28 LHb Oral Fentanyl\2022.09.29 Oral SA Round 4 BE Battery\HP Master Sheet.xlsx');
% opts = setvartype(opts,{'ID','Sex'},'categorical');
% hpT=readtable('2022.02.28 LHb Oral Fentanyl\2022.09.29 Oral SA Round 4 BE Battery\HP Master Sheet.xlsx'),opts;
% hpT.ID = categorical(hpT.ID);
% hpT.Sex = categorical(hpT.Sex);
% hpT.Session = categorical(hpT.Session);
% 
% clear g
% g(1,1)=gramm('x',hpT.Session,'y',hpT.Latency,'color',hpT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_violin('normalization','width','half',0,'fill','transparent','dodge',.75)
% g(1,1).geom_jitter('width',.1,'dodge',.75,'alpha',.5);
% g(1,1).stat_summary('geom',{'black_errorbar'},'type','sem','dodge',.75);
% g(1,1).axe_property('LineWidth',1.5,'FontSize',16,'Font','Helvetica','YLim',[20 80],'XLim',[.5 2.5],'TickDir','out');
% g(1,1).set_order_options('x',{'Pre' 'Post'});
% g(1,1).set_names('x',[],'y','Paw Lick Latency (s)','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Hot Plate.pdf'),'ContentType','vector');
% 
% HP_LME = fitlme(hpT,'Latency ~ Sex*Session + (1|ID)');
% HP_F = anova(HP_LME,'DFMethod','satterthwaite');
% statsna=fullfile('Statistics','Oral SA Hoteplate Stats.mat');
% save(statsna,'HP_F');
% 
% % Behavioral Economics (Dose Response)
% % Hot Plate
% % clear all;
% opts = detectImportOptions('2022.02.28 LHb Oral Fentanyl\2022.09.29 Oral SA Round 4 BE Battery\Oral Fentanyl Behavioral Economics Data.xlsx');
% opts = setvartype(opts,{'ID','Sex'},'categorical');
% beT=readtable('2022.02.28 LHb Oral Fentanyl\2022.09.29 Oral SA Round 4 BE Battery\Oral Fentanyl Behavioral Economics Data.xlsx'),opts;
% beT.Sex = categorical(beT.Sex);
% beT.ID = categorical(beT.ID);
% responses=ceil((beT.mLTaken./.05));
% unitPrice=(1000./beT.Dose__g_ml_);
% beT=[beT table(responses,unitPrice)];
% 
% % Curve Fit Each Animals Intake over Dose
% IDs = unique(beT.ID);
% for i=1:height(IDs)
%     tmp=beT(beT.ID==IDs(i),2);
%     Sex(i,1)=tmp{1,1};
%     in=beT{beT.ID==IDs(i),10};
%     in=in(1:5);
%     price=beT{beT.ID==IDs(i),12};
%     price=price(1:5);
%     price=price-price(1)+1;
% 
%     myfittype = fittype('log(b)*(exp(1)^(-1*a*x))',...
%     'dependent',{'y'},'independent',{'x'},...
%     'coefficients',{'a','b'})
% 
%     f=fit(price,log(in),myfittype,'StartPoint', [.003, 200],'lower',[.0003 100],'upper',[.03 1500]);
%     
%     figure;
%     plot(log(1:50),f(1:50));
%     hold on;
%     scatter(log(price),log(in),10);
%     [res_x, idx_x]=knee_pt(log(1:50),f(1:50));
%     plot([log(idx_x) log(idx_x)],[min(f(1:50)) max(f(1:50))],'--k')
%     xlim([-1 5]);
%     title(IDs(i))
%     
%     Alpha(i,1)=f.a;
%     Elastic(i,1)=idx_x
% end
% 
% aT=table(IDs,Sex,Alpha,Elastic);
% clear g
% g(1,1)=gramm('x',aT.Sex,'y',aT.Alpha,'color',aT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_violin('normalization','width','half',0,'fill','transparent','dodge',.75)
% g(1,1).geom_jitter('width',.1,'dodge',.75,'alpha',.5);
% g(1,1).stat_summary('geom',{'black_errorbar'},'type','sem','dodge',.75);
% g(1,1).axe_property('LineWidth',1.5,'FontSize',16,'Font','Helvetica','TickDir','out');
% g(1,1).set_order_options('x',{'Female' 'Male'});
% g(1,1).set_names('x','Sex','y','Demand Elasticity','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Alpha.pdf'),'ContentType','vector');
% 
% clear g
% g(1,1)=gramm('x',aT.Sex,'y',aT.Elastic,'color',aT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_violin('normalization','width','half',0,'fill','transparent','dodge',.75)
% g(1,1).geom_jitter('width',.1,'dodge',.75,'alpha',.5);
% g(1,1).stat_summary('geom',{'black_errorbar'},'type','sem','dodge',.75);
% g(1,1).axe_property('LineWidth',1.5,'FontSize',16,'Font','Helvetica','TickDir','out');
% g(1,1).set_order_options('x',{'Female' 'Male'});
% g(1,1).set_names('x','Sex','y','Demand Elasticity','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Elastic.pdf'),'ContentType','vector');
% 
% clear g
% g(1,1)=gramm('x',beT.Dose__g_ml_,'y',beT.Intake__g_kg_,'color',beT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_summary('geom',{'area','point'},'type','sem','setylim',1);
% g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
% g.axe_property('LineWidth',1.5,'XLim',[0 250],'YLim',[0 800],'tickdir','out');
% g(1,1).set_names('x','Unit Dose (μg)','y','Fentanyl Intake (μg/kg)','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Intake.pdf'),'ContentType','vector');
% 
% clear g
% g(1,1)=gramm('x',beT.Dose__g_ml_,'y',responses,'color',beT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_summary('geom',{'area','point'},'type','sem','setylim',1);
% g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
% g.axe_property('LineWidth',1.5,'XLim',[-5 250],'tickdir','out');
% g(1,1).set_names('x','Dose (μg/mL)','y','Responses','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Responses.pdf'),'ContentType','vector');
% 
% clear g
% g(1,1)=gramm('x',beT.unitPrice,'y',beT.Intake__g_kg_,'color',beT.Sex,'subset',beT.Dose__g_ml_~=0);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_summary('geom',{'area','point'},'type','sem','setylim',1);
% %g(1,1).stat_smooth('geom',{'area_only'});
% g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
% g.axe_property('LineWidth',1.5,'tickdir','out');
% g(1,1).set_names('x','Unit Price (responses/mg)','y','Fentanyl Intake (μg/kg)','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% set(g.facet_axes_handles,'YScale','log','XScale','log')
% set(g.facet_axes_handles,'XTick',[1 10 20 40])
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Unit Price Intake.pdf'),'ContentType','vector');
% 
% BE_LME = fitlme(beT,'responses ~ Sex*Dose__g_ml_ + (1|ID)');
% BE_F = anova(BE_LME,'DFMethod','satterthwaite');
% statsna=fullfile('Statistics','Oral SA BE Stats.mat');
% save(statsna,'BE_F');
% 
% 
% % Group BE Demand Curve
% myfittype = fittype('log(b)*(exp(1)^(-1*a*x))',...
%     'dependent',{'y'},'independent',{'x'},...
%     'coefficients',{'a','b'})
% 
% x=g.results.stat_summary.x
% [y z]=g.results.stat_summary.y
% x=x-x(1)+exp(1);
% 
% ff=fit(x,log(y),myfittype,'StartPoint', [.003, 200],'lower',[.0003 100],'upper',[.03 1500]);
% fm=fit(x,log(z),myfittype,'StartPoint', [.003, 200],'lower',[.0003 100],'upper',[.03 1500]);
% 
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% hold on;
% plot(log(1:50),ff(1:50),'LineWidth',1.5,'Color',[.95 .39 .13]);
% plot(log(1:50),fm(1:50),'LineWidth',1.5,'Color',[.46 .51 1]);
% scatter(log(x),log(y),36,[.95 .39 .13],'filled');
% scatter(log(x),log(z),36,[.46 .51 1],'filled');
% xlim([-.25 4.25]);
% set(gca,'LineWidth',1.5,'tickdir','out','FontSize',16,'box',0);
% xt=log([2.71 5 10 25 50]);
% set(gca,'XTick',[0 xt],'XTickLabels',{'0' '1' '5' '10' '25' '50'});
% xlabel('Cost (Response/Unit Dose)');
% set(gca,'YTick',[5 5.85843 6.28229],'YTickLabels',{'148' '350' '535'});
% ylabel('Fentanyl Intake (μg/kg)');
% 
% fAlpha=ff.a;
% fQ0=exp(ff(1));
% mAlpha=fm.a;
% mQ0=exp(fm(1));
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','True BE Figure.pdf'),'ContentType','vector');
% save('Statistics\BE_Stats.m','fAlpha','mAlpha','fQ0','mQ0');
% 
% clear g
% g(1,1)=gramm('x',beT.unitPrice,'y',beT.responses,'color',beT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_summary('geom',{'area','point'},'type','sem','setylim',1);
% g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
% g.axe_property('LineWidth',1.5,'tickdir','out');
% g(1,1).set_names('x','Unit Price (responses/mg)','y','Responses','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% set(g.facet_axes_handles,'XScale','log')
% set(g.facet_axes_handles,'XTick',[1 10 20 40])
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Unit Price Response.pdf'),'ContentType','vector');
% 
% close all;

% %% A-F individual differences
% % *** SS Move
% 
% % A) fentanyl intake, 
% % B) fentanyl seeking (defined as total head entries), 
% % C) cue-association (defined as head entry latency), 
% % D) escalation (defined as slope of total intake), 
% % E) persistence in extinction (defined as total presses during extinction)
% % F) relapse (defined as total pressed during cued reinstatement)
% 
% % SS to-add metrics
% % relapse / intake mean?
% % relapse / mean-last-two-intake-mean?
% % relapse / mean-first-two-intake-mean?
% % mean active lever / mean inactive lever?
% 
% if run_indiff
% 
%     % qualitatively assigned escalation behavior categories for Run 4 IO12Q specifically...
%     esctypes = {{'high_intake_descalator', [665, 660, 658]}, ...
%                 {'basic_acquirer', [1, 3, 7, 9, 10, 11, 15, 653, 661, 663]}, ...
%                 {'high_plateau', [7, 13, 15, 656, 657, 12, 654, 664]}};
% 
%     individual_differences_escalation(mT, [figs_savepath, sub_dir], esctypes, [indifffigs_savepath, subdir])
%     individual_differences_escalation(hmT, [figs_savepath, fH_sub_dir], esctypes, [indifffigs_savepath, fH_sub_dir])
% 
%     % calculate escalation 
%     ids=unique(mT.TagNumber);
%     subTab=table; 
%     SA_days = (mT.Session>= 6 & mT.Session <= 15);
%     subTab.TagNumber = ids;
%     % get intake data ordered by session for sessions between day 6-15 
%     tmp = mT(SA_days,{'TagNumber', 'Session', 'Intake', 'Sex', 'Strain', 'Acquire'});
%     tmp = sortrows(tmp,'Session','ascend');
% 
%     esc = table;
%     sex = table;
%     cxx = table;
%     acq = table; 
%     % rme = table;
%     intk = table;
% 
%     for l=1:height(ids)
%         idx=tmp.TagNumber==ids(l); % these will already be in order by session
%         coefs=polyfit((tmp.Session(idx))', tmp.Intake(idx), 1);
%         this_sex = tmp.Sex(find(idx,1));
%         this_strain = tmp.Strain(find(idx,1));
%         this_acquire = tmp.Acquire(find(idx,1));
% 
%         if indiff_figs
%             f = figure;
%             hold on
%             scatter(tmp.Session(idx), tmp.Intake(idx));
%             plot(tmp.Session(idx), polyval(coefs,tmp.Session(idx)))
%             title_str = sprintf('ID: %s %s %s %s esc: %.2f', ids(l), this_strain, this_sex, this_acquire, coefs(1));
%             title(title_str)
% 
%             figName=fullfile([figs_savepath, sub_dir,'Tag#',char(ids(l)),'_intakeXsession', '.jpg']);
%             exportgraphics(f,figName);
%         end
% 
%         tot_intake = sum(tmp.Intake(idx));
%         esc = [esc; table(coefs(1))];
%         sex = [sex; table(this_sex)];
%         cxx = [cxx; table(this_strain)];
%         acq = [acq; table(this_acquire)];
%         intk = [intk; table(tot_intake)];
%     end
% 
%     if indiff_figs
%         close all
%     end
% 
%     esc.Properties.VariableNames{'Var1'} = 'Escalation';
%     sex.Properties.VariableNames{'this_sex'} = 'Sex';
%     cxx.Properties.VariableNames{'this_strain'} = 'Strain';
%     acq.Properties.VariableNames{'this_acquire'} = 'Acquire';
%     intk.Properties.VariableNames{'tot_intake'} = 'Intake';
%     subTab = [subTab, esc, sex, cxx, acq, intk];
% 
%     if indiff_figs
%         catMet(subTab, 'Escalation', [indifffigs_savepath, sub_dir])
%         catMet(subTab, 'Intake', [indifffigs_savepath, sub_dir])
%     end
% 
%     subgroups = {{'Strain', 'c57', 'CD1', 'O', 's'}, ...
%                  {'Sex', 'Female','Male', 'b', 'o'}, ...
%                  {'Acquisition','Acquire', 'Nonacquire', 'filled', ''},
%                  };
%     if indiff_figs
%         cat2DcatMet(subTab, {'Escalation', 'Intake'}, subgroups, [indifffigs_savepath, sub_dir])
%     end
% 
%     hid = table;
%     ba = table;
%     hp = table; 
%     tmp = {hid, ba, hp};
% 
%     for et = 1:numel(esctypes)
%         idx = ismember(subTab.TagNumber, categorical(esctypes{et}{2}));
%         tmp{et} = [tmp{et} table(idx)];
%         tmp{et}.Properties.VariableNames{'idx'} = esctypes{et}{1};
%         subTab = [subTab, tmp{et}];
%     end
%     if indiff_figs
%         escTypeIntake(mT, subTab, esctypes, [indifffigs_savepath, sub_dir])
%     end
% end

function [f] = plotViolins(ivT, yVars, yLabs)
    % SS added
    clear g
    f = figure('units','normalized','outerposition',[0 0 1 .4]);
    numDat = length(ivT.Intake); 
    x = nan([1,numDat]);
    x(ivT.Sex == categorical({'Female'})) = .8;
    x(ivT.Sex == categorical({'Male'})) = 1.2; 

    for y = 1:length(yVars)
        g(1,y)=gramm('x',x,'y',ivT.(yVars{y}),'color',ivT.Sex);
        g(1,y).set_order_options('color', {'Female', 'Male'})
        g(1,y).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
        g(1,y).stat_violin('normalization', 'width', 'fill', 'transparent'); %'extra_y', 0, 'half', 1, 
        g(1,y).geom_jitter('width',.05,'dodge',-.5,'alpha',.75);
        g(1,y).axe_property('LineWidth',1.5,'FontSize',14,'Font','Helvetica','XLim',[0.5 1.5],'TickDir','out'); %'YLim',[0 1200]
        g(1,y).set_names('x','','y', yLabs{y},'color','');
        g(1,y).set_point_options('base_size',6);
        % g(1,y).no_legend();
        g(1,y).set_title(' ');
    end
    
     g.draw;

    for i=1:width(g)
       g(1,i).results.geom_jitter_handle(1).MarkerEdgeColor = [0 0 0]; 
       g(1,i).results.geom_jitter_handle(2).MarkerEdgeColor = [0 0 0];
    end

    % set(g(1,1).facet_axes_handles,'XTick',1,'XTickLabels',{'Intake'});
    % set(g(1,1).facet_axes_handles,'YTick',[0 600 1200]);
    % 
    % set(g(1,2).facet_axes_handles,'XTick',1,'XTickLabels',{'Seeking'});
    % set(g(1,2).facet_axes_handles,'YTick',[0 100 200]);
    % set(g(1,5).facet_axes_handles,'XTick',1,'XTickLabels',{'Extinction'});
    % 
    % set(g(1,3).facet_axes_handles,'XTick',1,'XTickLabels',{'Association'});
    % set(g(1,3).facet_axes_handles,'YTick',[0 3 6]);
    % 
    % set(g(1,4).facet_axes_handles,'XTick',1,'XTickLabels',{'Escalation'});
    % set(g(1,4).facet_axes_handles,'YTick',[0 5 10]);
    % 
    % set(g(1,5).facet_axes_handles,'YTick',[0 8 16]);
    % 
    % % set(g(1,6).facet_axes_handles,'XTick',1,'XTickLabels',{'Persistence'});
    % % set(g(1,6).facet_axes_handles,'YTick',[0 3 6]);
    % 
    % set(g(1,6).facet_axes_handles,'XTick',1,'XTickLabels',{'Relapse'});
    % set(g(1,6).facet_axes_handles,'YTick',[0 60 120]);
    % 
    % set(g(1,7).facet_axes_handles,'XTick',1,'XTickLabels',{'Severity'});
    % set(g(1,7).facet_axes_handles,'YTick',[-12 0 12]);
end


function [new_dirs] = makeSubFolders(beh_datapath, toMake, excludeData, firstHour)
    % SS added
    for bd = 1:length(beh_datapath)
        split = strsplit(beh_datapath{bd}, '\');
        sub_dir = [split{length(split)}];
        if bd < length(beh_datapath)
            sub_dir = [sub_dir, '_']; 
        else
            if excludeData
                sub_dir = [sub_dir, '_exclusions'];
            end
            sub_dir = [sub_dir, '\'];
        end
    end

    new_dirs = {sub_dir};
    if firstHour
        fH_sub_dir = [sub_dir(1:length(sub_dir)-1), '_firstHour', '\'];
        new_dirs = {new_dirs{1}, fH_sub_dir};
    end
    
    for tm = 1:length(toMake)
        mkdir([toMake{tm}, sub_dir])
        if firstHour
            mkdir([toMake{tm}, fH_sub_dir])
        end
    end
end



function [mT] = removeExcludedData(mT, mKey)
    % SS added
    RemoveSession = zeros([length(mT.Chamber),1]);
    sub_RemSess = mKey.RemoveSession;
    for sub = 1:length(sub_RemSess)
        sess = sub_RemSess{sub}(2:end-1);
        if ~isempty(sess)
            sess = strsplit(sess, ' ');
            tag = mKey.TagNumber(sub);
            for s = 1:length(sess)
                ind = find((mT.TagNumber == tag) .* (mT.Session == str2double(sess{1})));
                RemoveSession(ind) = 1;
            end
        end      
    end
    mT(find(RemoveSession),:) = [];
    % mT=[mT table(RemoveSession)];
end