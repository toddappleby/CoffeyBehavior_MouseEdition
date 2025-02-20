function [new_dirs] = makeSubFolders(allfig_savefolder, runNum, runType, toMake, excludeData, firstHour)
    if length(runType) > 1
        runTypeStr = 'all';
    else
        runTypeStr = char(string(runType));
    end
    
    if length(runNum) > 1
        runNumStr = 'all';
    else
        runNumStr = char(string(runNum));
    end
    
    sub_dir = ['Run_', runNumStr, '_', runTypeStr];
    if excludeData
        sub_dir = [sub_dir, '_exclusions'];
    end
    sub_dir = [allfig_savefolder, sub_dir, '\'];

    new_dirs = {sub_dir};
    if firstHour
        fH_sub_dir = [sub_dir(1:length(sub_dir)-1), '_firstHour', '\'];
        new_dirs = {new_dirs{1}, fH_sub_dir};
    end
    
    for tm = 1:length(toMake)
        mkdir([sub_dir, toMake{tm}])
        if firstHour
            mkdir([fH_sub_dir, toMake{tm}])
        end
    end
end
