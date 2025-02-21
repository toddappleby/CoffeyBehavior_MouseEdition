function BE_CurveFit_Fig(fit_tab, figpath, figsave_type)
    
    for i = 1:height(fit_tab)
        if length(fit_tab.fitY{i}) > 10
            alf = .25;
        else
            alf = 1;
        end

        if ~isempty(fit_tab.modY{i})

            f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
            hold on;
            plot(log(fit_tab.modX{i}), fit_tab.modY{i}, 'LineWidth', 1.5, 'Color', [.95 .39 .13]);
            scatter(log(fit_tab.fitX{i}), fit_tab.fitY{i}, 36, [.95 .39 .13], 'filled', 'MarkerFaceAlpha', alf);
            plot([log(fit_tab.knee_x(i)) log(fit_tab.knee_x(i))],[min(fit_tab.modY{i}) max(fit_tab.modY{i})],'--k');
            xlim([-.25 4.25]);
            set(gca,'LineWidth',1.5,'tickdir','out','FontSize',16,'box',0);
            xt=log([2.71 5 10 25 50]);
            set(gca,'XTick',[0 xt],'XTickLabels',{'0' '1' '5' '10' '25' '50'});
            xlabel('Log Cost (Response/Unit Dose)');
            ylabel('Log Fentanyl Intake (μg/kg)');
            title(char(strrep(fit_tab.ID(i), '_', ' ')));
    
            saveFigsByType(f, [figpath, 'BE_curvefit_', char(fit_tab.ID(i))], figsave_type);
            
            close(f)
        else
            disp(['no fit data for TagNumber ' char(fit_tab.ID(i)), 'skipping curve-fit plot...']);
        end
    end
end