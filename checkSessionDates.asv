%% checkSessionDates - 
% SS 2025

%% USER SETTINGS
main_folder = 'C:\Users\schle\Documents\GitHub\CoffeyBehavior';
masterKey_flnm = [main_folder, '\Golden R01 Behavior Master Key.xlsx'];
sessionDateKey_flnm = [main_folder, '\Session Date Key.xlsx'];
createNewMasterTable = false;
correctMedPCFiles = true;

runType = 'all'; % 'ER' (Extinction Reinstatement) or 'BE' (Behavioral Economics) or 'SA' (Self Administration) or 'E-BE-PR (Extinction, Beh)
runNum = -1; % if runNum == -1, get all runs


masterTable_flnm = [main_folder, '\22-Jan-2025_masterTable.mat']; % used if createNewMasterTable == false 
beh_datapath = [main_folder, '\All Behavior'];

%% EXPERIMENT TYPE DEFINITIONS FOR LOGICAL INDEXING
ER_types = {'SelfAdministration', 'Extinction', 'Reinstatement'};
BE_types = {'SelfAdministration', 'BehavioralEconomics'};
SA_types = {'SelfAdministration'};
E_BE_PR_types = {'SelfAdministration', 'Extinction', 'ProgressiveRatio', 'BehavioralEconomics'};

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
sessTypes = {};
if strcmp(runType, 'ER')
    sessTypes = ER_types;
end
if strcmp(runType, 'BE')
    sessTypes = BE_types;
end
if strcmp(runType, 'SA')
    sessTypes = SA_types; 
end
if strcmp(runType, 'E_BE_PR')
    sessTypes = E_BE_PR_types;
end

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
    d = string(d(1:end-1));
    temp{kd} = d;
end
sdKey.Date = temp;

%% CHECK 1:1 for date, session num, and session type
sessDate = checkUnique('session', sess, 'date', date);
dateSess = checkUnique('date', date, 'session', sess);
sessType = checkUnique('session', sess, 'type', type);
dateType = checkUnique('date', date, 'type', type);

%% FIND FILES THAT NEED TO BE CORRECTED
incorrect_session = [];
incorrect_type = [];

for d = 1:length(sdKey.Date)
    key_date = sdKey.Date(d);
    key_session = sdKey.Session(d);
    key_type = sdKey.SessionType(d);

    dat_ind = find(string(date) == key_date{1});
    
    wrong_session = find((string(date) == key_date{1}) .* (dT.Session ~= key_session));
    wrong_type = find((string(date) == key_date{1}) .* (dT.sessionType ~= key_type{1}));

    incorrect_session = [incorrect_session; wrong_session];
    incorrect_type = [incorrect_type; wrong_type];
    
    if ~isempty(wrong_session)
        disp(strcat("Incorrect Sessions logged for ", key_date{1}, "(Session = ", string(num2str(key_session)), ") :"))
        for is = 1:length(wrong_session)
            disp(strcat("     Tag ", string(dT.TagNumber(wrong_session(is))), " labeled as Session ", string(num2str(sess(wrong_session(is))))));
        end
        disp(' ')
    end

    if ~isempty(wrong_type)
        disp(strcat("Incorrect Session Types logged for ", key_date{1},"(Session Type = ", key_type{1}, ") :"))
        for is = 1:length(wrong_session)
            disp(strcat("     Tag ", string(dT.TagNumber(wrong_type(is))), " labeled as Session Type ", string(type(wrong_type(is)))));
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
title(['Check: Run', num2str(runNum), ' ', runType])
xlabel('Date')
ylabel('Session #')

hold off

%% CORRECT MEDPC FILES
if correctMedPCFiles
    if ~isempty(incorrect_session) || ~isempty(incorrect_type)
        corrections(beh_datapath, dT, incorrect_sessions, incorrect_type, sdKey, main_folder)
    else
        disp('No corrections to be made!')
    end
end


%%
function corrections(beh_datapath, dT, incorrect_sessions, incorrect_typse, sdKey, main_folder, masterKey_flnm)
    disp('BEEP')
    if ~isempty(incorrect_sesions)
        % correct incorrect sessions in medPC data files
        correctSessions(beh_datapath, dT, incorrect_sessions, sdKey)
        % create new master table
        mT = createMasterTable(main_folder, beh_datapath, masterKey_flnm);
    end
    
   if ~isempty(incorrect_type)
       % correct incorrect session types in master table
       mT = correctTypes(mT, dT, incorrect_types, sdKey);
       % save new table
       today = datetime('today');
       save([main_folder, char(today), '_masterTable'], 'mT')
   end
end


function correctSessions(beh_datapath, dT, incorrect_sessions, sdKey)
    data_fls = 
    for is = 1:length(incorrect_sessions)
        this_date =
        this_tag =
        corr_sess =

        % find the file to be updated

    end    
end


function [mT] = correctTypes(mT, dT, incorrect_types, sdKey)
    for it = 1:length(incorrect_types)
        this_date =
        this_tag =
        corr_type = 
        
        % find the row to be updated

    end
end


function [cat1_cat2s] = checkUnique(cat1, var1, cat2, var2)
    uni_cat1 = unique(var1);
    cat1_cat2s = cell([length(uni_cat1), 1]);
    for uni = 1:length(uni_cat1)
        this_uni_cat2 = unique(var2(var1 == uni_cat1(uni)));
        cat1_cat2s{uni} = this_uni_cat2;
        num_uni_cat2 = height(this_uni_cat2);

        % disp([cat1, ' ', char(categorical(uni_cat1(uni))), ':'])
        % disp(['    ', cat2, ':'])
        % for ud = 1:num_uni_cat2
        %     disp(['    ', char(categorical(this_uni_cat2(ud)))])
        % end
        % disp(' ')

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