%% checkSessionDates - 
% SS 2025

%% USER SETTINGS
main_folder = 'C:\Users\schle\Documents\GitHub\CoffeyBehavior';
masterKey_flnm = [main_folder, '\Golden R01 Behavior Master Key.xlsx'];
sessionDateKey_flnm = [main_folder, '\Session Date Key.xlsx'];
createNewMasterTable = false; % if session numbers need to beupdated and correctFiles is true, a new master table will be created after updating medPC files regardless of this setting
correctFiles = true;

runType = 'all'; % 'ER' (Extinction Reinstatement) or 'BE' (Behavioral Economics) or 'SA' (Self Administration) or 'E-BE-PR (Extinction, Beh)
runNum = -1; % if runNum == -1, get all runs

masterTable_flnm = [main_folder, '\27-Jan-2025_masterTable.mat']; % used if createNewMasterTable == false 
beh_datapath = {[main_folder, '\All Behavior']};

%% EXPERIMENT TYPE DEFINITIONS FOR LOGICAL INDEXING
% need to updating the indexing from this to exclude things that include
% these session types but also include unstated session types. works for
% now. 
exp_types = dictionary(["ER", "BE", "E_BE_PR"], ...
                        { ...
                        {'SelfAdministration', 'Extinction', 'Reinstatement'}, ...
                        {'SelfAdministration', 'BehavioralEconomics'}, ...
                        {'SelfAdministration', 'Extinction', 'ProgressiveRatio', 'BehavioralEconomics'} ...
                        });

%% GET DATA
cd(main_folder)
addpath(genpath(main_folder))

opts = detectImportOptions(masterKey_flnm);
opts = setvartype(opts,{'TagNumber','ID','Cage','Sex','Strain','TimeOfBehavior'},'categorical'); % Must be variables in the master key
mKey=readtable(masterKey_flnm, opts);
sessDatKey = readtable(sessionDateKey_flnm);

if createNewMasterTable
    mT = createMasterTable(main_folder, beh_datapath, masterKey_flnm);
else
    load(masterTable_flnm)
end

%% PULL SPECIFIC RUN & EXPERIMENT TYPE TO CHECK

% determine session types to use for logical indexing experiments fro master sheet if runType ~= 'all'
mKey = setExperiment_mKey(mKey, exp_types);

% indexing of data to include in checks
key_ind = ones([length(sessDatKey.Run), 1]);
if runNum ~= -1
    runInd = mKey.Run == runNum;
    key_ind = key_ind .* (sessDatKey.Run == runNum);
else
    runInd = ones([length(mKey.Run), 1]); 

end
if ~strcmp(runType, 'all')
    expInd = ones([length(runInd), 1]);
    sessTypes = exp_types(runType);
    sessTypes = sessTypes{1};
    for typ = 1:length(sessTypes)
        expInd = expInd .* mKey.(sessTypes{typ});
    end
    key_ind = key_ind .* (categorical(sessDatKey.Experiment) == categorical(string(runType)));
else
    expInd = ones([length(mKey.Run), 1]);
end
key_ind = find(key_ind);

% pull out data
tagNum = mKey.TagNumber(find(runInd .* expInd));
mT_ind = find(ismember(mT.TagNumber, tagNum));

dT = mT(mT_ind,:);
dT = setExperiment_dT(dT, mKey);
sdKey = sessDatKey(key_ind,:);
date = dT.Date;
sess = dT.Session;
type = dT.sessionType;

% avoid bugs if session type is undefined
type(find(isundefined(type))) = categorical("undefined");

% annoying formatting problems pulling dates from sheet
keyDate = sdKey.Date;
temp = cell ([length(keyDate), 1]);
for kd = 1:length(keyDate)
    d = keyDate(kd);
    d = d{1};
    d = char(d(1:end-1));
    temp{kd} = d;
end
sdKey.Date = temp;

%% CHECK 1:1 for date, session num, and session type
% sessDate = checkUnique('session', sess, 'date', date);
% dateSess = checkUnique('date', date, 'session', sess);
% sessType = checkUnique('session', sess, 'type', type);
% dateType = checkUnique('date', date, 'type', type);

%% FIND FILES THAT NEED TO BE CORRECTED
incorrect_session = [];
incorrect_type = [];

for d = 1:length(sdKey.Date)
    key_date = sdKey.Date(d);
    key_session = sdKey.Session(d);
    key_type = sdKey.SessionType(d);
    key_exp = sdKey.Experiment(d);
    
    wrong_session = find((string(date) == string(key_date{1})) .* (dT.Session ~= key_session) .* strcmp(dT.Experiment, key_exp{1}));
    wrong_type = find((string(date) == string(key_date{1})) .* (dT.sessionType ~= key_type{1}) .* strcmp(dT.Experiment, key_exp{1}));

    incorrect_session = [incorrect_session; wrong_session];
    incorrect_type = [incorrect_type; wrong_type];
    
    if ~isempty(wrong_session)
        disp(['Incorrect Sessions logged for ', key_date{1}, '(Session = ', num2str(key_session), ') :'])
        for is = 1:length(wrong_session)
            disp(['     Tag ', char(dT.TagNumber(wrong_session(is))), ' labeled as Session ', num2str(sess(wrong_session(is)))]);
        end
        disp(' ')
    end

    if ~isempty(wrong_type)
        disp(['Incorrect Session Types logged for ', key_date{1}, '(Session Type = ', key_type{1}, ') :'])
        for is = 1:length(wrong_type)
            disp(['     Tag ', char(dT.TagNumber(wrong_type(is))), ' labeled as Session Type ', char(type(wrong_type(is)))]);
        end
        disp(' ')
    end

end

%% PLOT DATE AGAINST SESSION # BY SESSION TYPE
figure
hold on

uniType = unique(type);
leg = uniType;

for uni = 1:length(uniType)
    ind = find(type == uniType(uni));
    scatter(date(ind), sess(ind));
end

if ~isempty(incorrect_session)
    scatter(date(incorrect_session), sess(incorrect_session), '+k')
    leg = [leg; categorical("incorrect session #")];
end
if ~isempty(incorrect_type)
    scatter(date(incorrect_type), sess(incorrect_type), 'xk')
    leg = [leg; categorical("incorrect session type")];
end

ylim([nanmin(sess) - 1, nanmax(sess) + ((nanmax(sess)-nanmin(sess))/2)])
legend(leg, 'Location', 'northwest')
if runNum == -1
    run_str = 'all runs';
else
    run_str = ['Run ' num2str(runNum)];
end

if strcmp(runType, 'all')
    type_str = 'all experiments';
else
    type_str = runType;
end

title(['Check: ', run_str, ', ', type_str])
xlabel('Date')
ylabel('Session #')

hold off

%% CORRECT MEDPC FILES
if correctFiles
    if ~isempty(incorrect_session) || ~isempty(incorrect_type)
        dT = corrections(beh_datapath, dT, mKey, incorrect_session, incorrect_type, sdKey, main_folder, masterKey_flnm);
    else
        disp('No corrections to be made!')
        disp(' ')
    end
   % save new table
   today = datetime('today');
   mT = dT;
   save([main_folder, '\', char(today), '_masterTable'], 'mT')
   disp('saved updated masterTable with Experiment column')
   disp(' ')
end


%%
function [dT] = corrections(beh_datapath, dT, mKey, incorrect_session, incorrect_type, sdKey, main_folder, masterKey_flnm)
    
    if ~isempty(incorrect_session)
        % correct incorrect sessions in medPC data files
        correctSessions(dT, mKey, incorrect_session, sdKey)
        % create new master table
        dT = createMasterTable(main_folder, beh_datapath, masterKey_flnm);
    end
    
   if ~isempty(incorrect_type)
       % correct incorrect session types in master table
       dT = correctTypes(dT, mKey, incorrect_type, sdKey);
   end
end


function correctSessions(dT, mKey, incorrect_session, sdKey)
    strStart = 15;
    strEnd = 20;
    template = '    15:       ';
    disp('updating incorrect session numbers in medPC files...')
    for is = 1:length(incorrect_session)
        this_date = char(dT.Date(incorrect_session(is)));
        this_file = dT.FileName{incorrect_session(is)};
        this_tag = dT.TagNumber(incorrect_session(is));
        mKey_ind = (mKey.TagNumber==this_tag);
        this_exp = mKey.Experiment(mKey_ind);
        this_exp = this_exp{1};
        this_run = mKey.Run(mKey_ind);

        sdKey_ind = find(strcmp(sdKey.Date,char(this_date)) .* (sdKey.Run == this_run) .* strcmp(sdKey.Experiment, this_exp));
        corr_sess = sdKey.Session(sdKey_ind);
        char_sess = [num2str(corr_sess), '.000'];
        if corr_sess/10 < 1
            char_sess = [' ', char_sess];
        end
        fileContent = fileread(this_file);
        lines = splitlines(fileContent);
        
        % can't hardcode the line to change bc different number of blank lines in some files
        chng_line = 0;
        ln = 1;
        while chng_line == 0
            if contains(lines{ln}, template)
                chng_line = ln;
            else
                ln = ln + 1;
            end
        end

        tmp = lines{chng_line};
        tmp(strStart:strEnd) = char_sess;
        lines{chng_line} = tmp;
        
        fid = fopen(this_file, 'w');
        for i = 1:length(lines)
            fprintf(fid, '%s\n', lines{i});
        end
        fclose(fid);
        disp(['updated file: ' this_file])
    end    
    disp(' ')
end

function [dT] = correctTypes(dT, mKey, incorrect_type, sdKey)
    disp('updating incorrect session types in masterTable...')
    for it = 1:length(incorrect_type)
        this_date = char(dT.Date(incorrect_type(it)));
        this_tag = dT.TagNumber(incorrect_type(it));
        mKey_ind = (mKey.TagNumber==this_tag);
        this_exp = mKey.Experiment(mKey_ind);
        this_exp = this_exp{1};
        this_run = mKey.Run(mKey_ind);

        sdKey_ind = find(strcmp(sdKey.Date,char(this_date)) .* (sdKey.Run == this_run) .* strcmp(sdKey.Experiment, this_exp));
        corr_type = categorical(string(sdKey.SessionType{sdKey_ind}));
        dT.sessionType(incorrect_type(it)) = corr_type;
    end
    disp(['updated session types for ', num2str(length(incorrect_type)), ' sessions'])
    disp(' ')
end


function [cat1_cat2s] = checkUnique(cat1, var1, cat2, var2)
    uni_cat1 = unique(var1);
    cat1_cat2s = cell([length(uni_cat1), 1]);
    for uni = 1:length(uni_cat1)
        this_uni_cat2 = unique(var2(var1 == uni_cat1(uni)));
        cat1_cat2s{uni} = this_uni_cat2;
        num_uni_cat2 = height(this_uni_cat2);

        if num_uni_cat2 > 1
            disp(strcat(string(num2str(num_uni_cat2)), " ", string(cat2), "s for ", string(cat1), " ", string(uni_cat1(uni)), ":"))
            for ud = 1:num_uni_cat2
                disp(['     ', char(categorical(this_uni_cat2(ud)))])
            end
            disp('  ')
            disp('  ')
        end
    end

end


function [mKey] = setExperiment_mKey(mKey, exp_types)
    
    Experiment = cell([length(mKey.Run), 1]);
    dict_keys = keys(exp_types);
    for exp = 1:length(dict_keys)
        sessTypes = exp_types(dict_keys(exp));
        sessTypes = sessTypes{1};
        inds = ones([length(mKey.Run), 1]);

        for st = 1:length(sessTypes)
            inds = inds .* mKey.(string(sessTypes{st}));
        end

        Experiment(find(inds)) = {dict_keys(exp)};
    end
    mKey = [mKey, table(Experiment)];
end


function [dT] = setExperiment_dT(dT, mKey)
    Experiment = cell([length(mKey.Run), 1]);
    for tn = 1:length(mKey.TagNumber)
        this_exp = mKey.Experiment(tn);
        this_exp = this_exp{1};
        tn_inds = (dT.TagNumber == mKey.TagNumber(tn));
        Experiment(find(tn_inds)) = {char(this_exp)};
    end
    if any(ismember(dT.Properties.VariableNames, 'Experiment'))
        dT = removevars(dT,{'Experiment'});
    end
    dT = [dT, table(Experiment)];
end