function [mT] = createMasterTable(main_folder, beh_datapath, masterKey_flnm)

    % main_folder = 'C:\Users\schle\Documents\GitHub\CoffeyBehavior';
    % cd(main_folder)
    % beh_datapath = {'.\All Behavior'}; % can add multiple data folders to cell array, data will be combined into one table
    % masterKey = 'Golden R01 Behavior Master Key.xlsx';
    % 
    % Import Master Key
    addpath(genpath(main_folder))
    opts = detectImportOptions(masterKey);
    opts = setvartype(opts,{'TagNumber','ID','Cage','Sex','Strain','TimeOfBehavior'},'categorical'); % Must be variables in the master key
    mKey=readtable(masterKey,opts);
    
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
    
    %%
    dt = date;
    save([dt, '_masterTable'],'mT');
end