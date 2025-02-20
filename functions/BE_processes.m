function BE_processes(mT, expKey, BE_intake_canonical_flnm, sub_dir, indivIntake_figs, groupIntake_figs, saveTabs, indivIntakefigs_savepath, groupIntakefigs_savepath, tabs_savepath, figsave_type)
    
    [beT, beiT, BE_IndivFit, BE_GroupFit] = BE_Analysis(mT, expKey, BE_intake_canonical_flnm);
    
    if saveTabs
        writeTabs(beT, [sub_dir, tabs_savepath], 'BE_data', {'.mat', '.xlsx'})
        writeTabs(beiT, [sub_dir, tabs_savepath], 'BE_allIntake', {'.mat', '.xlsx'})
        writeTabs(BE_IndivFit, [sub_dir, tabs_savepath], 'BE_indivCurveFit', {'.mat', '.xlsx'})
        writeTabs(BE_GroupFit.subgroup_curveFIts, [sub_dir, tabs_savepath], 'BE_groupCurveFit', {'.mat', '.xlsx'})
    end
    
    if indivIntake_figs
        BE_CurveFit_Fig(BE_IndivFit, [sub_dir, indivIntakefigs_savepath], figsave_type);
    end

    if groupIntake_figs

        % GROUP CURVE FIT FIGS
        BE_CurveFit_Fig(BE_GroupFit.subgroup_curveFits, [sub_dir, groupIntakefigs_savepath], figsave_type);
        

        % GROUP BEHAVIOR FIGS
        xvar = ["unitPrice_log", "unitPrice_log"];
        xlab = ["Fentanyl Concentration (ug/mL)", "Fentanyl Concentration (ug/mL)"];
        xtick = log2([4.5 8 14.3 25 45.5]); % SSnote: unhardcode
        xticklab = {'220','125','70','40','10'}; % SSnote: unhardcode
        colorGroup = ["Sex", "Sex"];
        lightGroup = ["Strain", "Strain"];
        
        % yvar, ylab, subset, and figname define the different group figures 
        % that will be generated (the rest of the figure parameters are shared
        % across them)
        yvar = {["measuredIntake", "ActiveLever"], ...
                ["Latency", "EarnedInfusions"], ...
                ["measuredIntake", "ActiveLever"], ...
                ["Latency", "EarnedInfusions"]};

        ylab = {["Fentanyl Intake (μg/kg)", "Active Lever Presses"], ...
                ["Head Entry Latency", "Rewards"], ...
                ["Fentanyl Intake (μg/kg)", "Active Lever Presses"], ...
                ["Head Entry Latency", "Rewards"]};
        
        subset = {beT.Acquire=='Acquire', ...
                  beT.Acquire=='Acquire', ...
                  beT.Acquire=='NonAcquire', ...
                  beT.Acquire=='NonAcquire'};

        figname = {'BE Intake and Active Lever Grouped by Sex and Strain Acquirers', ...
                   'BE Latency and Rewards Grouped by Sex and Strain Acquirers', ...
                   'BE Intake and Active Lever Grouped by Sex and Strain NonAcquirers', ...
                   'BE Latency and Rewards Grouped by Sex and Strain NonAcquirers'};
        
        for i = 1:length(yvar)
            gramm_GroupFig(beT, xvar, yvar{i},xlab, ylab{i}, colorGroup, lightGroup, subset{i}, ...
                        [sub_dir, groupIntakefigs_savepath, figname{i}], figsave_type, xtick, xticklab);
        end

    end
end