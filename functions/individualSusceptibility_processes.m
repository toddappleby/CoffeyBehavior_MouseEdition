function [ivT] = individualSusceptibility_processes(mT, dex, runType, sub_dir, saveTabs, tabs_savepath, groupOralFentOutput_figs, groupOralFentOutput_savepath, figsave_type)

    [ivT] = GetMetrics(mT(dex.all, :));

    if saveTabs
        save([sub_dir, tabs_savepath, 'IndividualVariabilityMetrics', '.mat'], 'ivT');
    end

    % run Z scores separately for animals that lack ER sessions & associated metrics
    if ~any(ismember(runType, 'ER'))
        zGroups = {ones([height(ivT), 1])};
        includeER = false;
        z_suff = {'_noER'};
    elseif (length(runType) > 1) & any(ismember(runType, 'ER'))
        ER_IDs =  unique(mT.TagNumber(dex.ER));
        ivT_ER_ind = ismember(unique(mT.TagNumber(dex.all)), ER_IDs);
        zGroups = {ones([height(ivT), 1]), ivT_ER_ind};
        includeER = [false, true];
        z_suff = {'_noER', '_withER'};
    else % only 'ER' in runType
        zGroups = {ones([height(ivT), 1])};
        includeER = true;
        z_suff = {'_withER'};
    end
    
    % subgroups of z-scored data to run correlatins across
    corrGroups = {{{'all'}}, ...
                  {{'Strain', 'c57'}}, ...
                  {{'Strain', 'CD1'}}, ...
                  {{'Sex', 'Male'}}, ...
                  {{'Sex', 'Female'}}, ...
                  {{'Strain', 'c57'}, {'Sex', 'Male'}}, ...
                  {{'Strain', 'c57'}, {'Sex', 'Female'}}, ...
                  {{'Strain', 'CD1'}, {'Sex', 'Male'}}, ...
                  {{'Strain', 'CD1'}, {'Sex', 'Female'}}}; 

    % violin groups
    violSubsets = {{'all'}, {'all'}, {'Strain', 'c57'}, {'Strain', 'CD1'}};
    violGroups = {'Strain', 'Sex', 'Sex', 'Sex'};
    violLabels = {'Strain', 'Sex', 'c57 Sex', 'CD1 Sex'};
    
    for zg = 1:length(zGroups)
        [ivZT] = SeverityScore(ivT(find(zGroups{zg}),:), includeER(zg));
        if saveTabs
            save([sub_dir, tabs_savepath, 'IndividualVariabilityZscores', char(z_suff{zg}), '.mat'], 'ivZT');
        end
        [correlations] = GetCorr(ivZT, z_suff{zg}, corrGroups, sub_dir, groupOralFentOutput_figs, groupOralFentOutput_savepath, figsave_type);
        if groupOralFentOutput_figs     
            for vg = 1:length(violSubsets)
                thistab = ivT(find(zGroups{zg}),:);
                thistab.Severity = ivZT.Severity;
                subset = ones([height(thistab), 1]);
                if ~strcmp(violSubsets{vg}{1}, 'all')
                    subset = subset & (thistab.(violSubsets{vg}{1}) == violSubsets{vg}{2});
                end
                ViolinFig(thistab(find(subset), :), violGroups{vg}, [z_suff{zg}, '_', violLabels{vg}], includeER(zg), sub_dir, groupOralFentOutput_savepath, figsave_type)
            end
            PCA_fig(ivZT, correlations.([z_suff{zg}(2:end),'_all']).prednames, ...
                    sub_dir, groupOralFentOutput_savepath, z_suff{zg}, figsave_type);
        end
    end
end