function [mT] = createMasterTable(main_folder, beh_datapath, masterKey_flnm, experimentKey_flnm)
    % Import Master Key
    addpath(genpath(main_folder))
    opts = detectImportOptions(masterKey_flnm);
    opts = setvartype(opts,{'TagNumber','ID','Cage','Sex','Strain','TimeOfBehavior'},'categorical'); % Must be variables in the master key
    mKey=readtable(masterKey_flnm,opts);
    
    % Import Experiment Key
    expKey = readtable(experimentKey_flnm);
    % annoying formatting problems pulling dates from sheet
    keyDate = expKey.Date;
    temp = cell([height(expKey), 1]);
    for kd = 1:length(keyDate)
        d = char(keyDate{kd});
        d = char(strrep(d, "'", ''));
        temp{kd} = d;
    end
    expKey.Date = temp;

    %% Import & process MedPC data
    mT=table; % Initialize Master Table
    
    for bd = 1:length(beh_datapath) % SS edit to pull data from multiple folders
        Files = dir(beh_datapath{bd});
        Files = Files(1:height(Files));
        startIdx = 1; % Current Wave Only
        disp(['Pulling ', num2str(length(Files)), '...']) % height(Files)-i);
        wb = waitbar(0, ['Importing data... (0/', num2str(height(Files)), ')']);
        
        
        for i=startIdx:height(Files) % Loop all behavior files
            waitmessage = ['Importing data... (', num2str(i),'/',num2str(height(Files)),')'];
            waitbar(i/height(Files), wb, waitmessage);
            
            if contains(Files(i).name, '_Subject') || contains(Files(i).name, '.Subject') % SS edit to avoid invalid filenames
                % Import Data Geterated By MED-PC Code
                [varTable, eventCode, eventTime] = importMouseOralSA(fullfile(Files(i).folder, Files(i).name));
                
                % Calculate Variables Using Raw Data
                [varTable] = rawVariableExtractor(varTable, eventCode, eventTime);
               
                % Add experiment type, session type, fentanyl concentration, and intake
                tag = varTable.TagNumber(height(varTable));
                mKey_ind = find(mKey.TagNumber==tag);
                
                if mKey.Extinction(mKey_ind) && mKey.Reinstatement(mKey_ind) && ~mKey.BehavioralEconomics(mKey_ind)
                    expType = 'ER';
                elseif mKey.BehavioralEconomics(mKey_ind) % don't exclude extinction and reinstatement so we can keep the BE data from run 2
                    expType = 'BE';
                else
                    expType = 'undefined';
                end

                fl_date = varTable.Date(height(varTable));
                expKey_ind = find(strcmp(expKey.Date, string(fl_date)) & strcmp(expKey.Experiment,expType)); % both cases necessary for when multiple experiments are run on the same day (run 4)
                if isempty(expKey_ind) | length(expKey_ind) > 1
                    disp(['cannot add session type or intake data for ', fullfile(Files(i).folder, Files(i).name)])
                    
                    Intake = NaN;
                    totalIntake = NaN;
                    Concentration = NaN;
                    DoseVolume = NaN;
                    SessionType = NaN;
                else
                    Concentration = expKey.FentanylConcentration_ug_ml_(expKey_ind);
                    DoseVolume = expKey.VolumePerDose_mL_(expKey_ind);
                    Intake = DoseVolume * Concentration * varTable.EarnedInfusions(height(varTable));
                    totalIntake = DoseVolume * Concentration * varTable.TotalInfusions(height(varTable));
                    SessionType = expKey.SessionType(expKey_ind);
                end
                drugIntakeTab = table(SessionType,Concentration, DoseVolume, Intake, totalIntake);

                % Concatonate the Master Table
                mT=[mT; [varTable, drugIntakeTab]];
            end
        end
        close(wb)
    end
    
    % Join Master Variable Table with Key to Include Grouping Variables
    mT=innerjoin(mT,mKey,'Keys',{'TagNumber'},'RightVariables',{'Sex','Strain','TimeOfBehavior','Chamber'});
    
    %%
    dt = date;
    save([dt, '_masterTable'],'mT');
end