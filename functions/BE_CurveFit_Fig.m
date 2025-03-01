function BE_CurveFit_Fig(fit_tab, colors, figpath, figsave_type)
    yMax = max(arrayfun(@(x) max(fit_tab.modY{x}), 1:height(fit_tab))) + .5;
    yMin = min(arrayfun(@(x) min(fit_tab.modY{x}), 1:height(fit_tab))) - .5;
    fit_lw = 1.5; % line width (not applied to error bars or marker edge)
    font_size = 13; % font size (everything but legend)
    leg_text_scale = .75; % scale of legend font relative to the rest
    leg_line_length = 10;
    marker_size = 75;
    marker_lw = 1;
    error_lw = marker_lw;
    error_capsize = 3;
    ax_lw = .5;

    for i = 1:height(fit_tab)
        if ~isempty(fit_tab.modY{i})

            f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
            hold on;
            plot(log(fit_tab.modX{i}), fit_tab.modY{i}, 'LineWidth', fit_lw, 'Color', colors{i});
            e = errorbar(log(fit_tab.fitX{i}), fit_tab.fitY{i}, fit_tab.semY{i}, 'k', 'LineStyle', "none");
            e.LineWidth = error_lw;
            e.CapSize = error_capsize;
            p = scatter(log(fit_tab.fitX{i}), fit_tab.fitY{i}, marker_size, colors{i}, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', marker_lw);
            % plot([log(fit_tab.knee_x(i)), log(fit_tab.knee_x(i))], [min(fit_tab.modY{i}) max(fit_tab.modY{i})],'--k');
            xlim([-.25 4.25]);
            ylim([yMin, yMax])
            set(gca,'LineWidth',ax_lw,'tickdir','out','box',0);
            xt=log([2.71 5 10 25 50]);
            set(gca,'XTick',[0 xt],'XTickLabels',{'0' '1' '5' '10' '25' '50'});
            xlabel('Log Cost (Response/Unit Dose)');
            ylabel('Log Fentanyl Intake (μg/kg)');
            % title(char(strrep(fit_tab.ID(i), '_', ' ')));
            
            % Update all text elements in the figure
            set(findall(f, '-property', 'FontSize'), 'FontSize', font_size);
            set(findall(f, '-property', 'FontName'), 'FontName', 'Helvetica');
            lgd = legend(p, [' ', char(strrep(fit_tab.ID(i), '_', ' '))]);
            lgd.IconColumnWidth = leg_line_length;
            lgd.FontSize = font_size * leg_text_scale;
            
            legend('boxoff')
            saveFigsByType(f, [figpath, 'BE_curvefit_', char(fit_tab.ID(i))], figsave_type);

            close(f)
        else
            disp(['no fit data for TagNumber ' char(fit_tab.ID(i)), 'skipping curve-fit plot...']);
        end
    end
end