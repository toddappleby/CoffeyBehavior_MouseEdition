function gramm_GroupFig(tab, xvar, yvar, xlab, ylab, colorGroup, lightGroup, subset, figpath, figsave_type, xtick, xticklab)

    f=figure('Position',[100, 100, 500*length(yvar), 500],'Color',[1 1 1]);
    clear g
    for sp = 1:length(yvar)
        % leg = sp == 1;
        g(1,sp) = gramm_GroupSubplot(tab.(xvar(sp)), tab.(yvar(sp)), ...
                             tab.(colorGroup(sp)), colorGroup(sp), ...
                             tab.(lightGroup(sp)), lightGroup(sp), ...
                             subset, xlab(sp), ylab(sp), 1);
    end
    g.draw

    for sp = 1:length(yvar)
       set(g(1,sp).facet_axes_handles,'Xtick',xtick,'XTickLabel',xticklab);
       yMax = -1000;
       for ss = 1:length(g(1,sp).results.stat_summary)
           set(g(1,sp).results.stat_summary(ss).point_handle,'MarkerEdgeColor',[0 0 0]);  
           maxStat = nanmax(g(1,1).results.stat_summary(ss).yci(:));
           if maxStat > yMax
               yMax = maxStat;
           end
       end
       yMax = 1.05 * yMax;
       g(1,sp).axe_property('YLim', [0 yMax], 'TickDir','out');
    end
    saveFigsByType(f, figpath, figsave_type)
    close(f);
end