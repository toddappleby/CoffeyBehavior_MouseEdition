function [g] = gramm_GroupSubplot(xvar, yvar, colorGroup, colorLab, lightGroup, lightLab, subset, xlab, ylab, leg)
    g(1,1)=gramm('x',xvar,'y',yvar,'color',colorGroup, 'lightness', lightGroup, 'subset', subset);
    g(1,1).set_color_options('hue_range',[0 360],'lightness_range',[85 35],'chroma_range',[30 70]);
    g(1,1).stat_summary('geom',{'black_errorbar','point','line'},'type','sem','dodge',0,'setylim',1,'width',1);
    g(1,1).set_point_options('markers',{'o','s'},'base_size',10);
    g(1,1).set_text_options('font','Helvetica','base_size',13,'legend_scaling',.75,'legend_title_scaling',.75);
    g(1,1).axe_property('LineWidth',1.5,'XLim',[1.5 6], 'tickdir','out');
    g(1,1).set_names('x',xlab,'y',ylab,'color', colorLab, 'lightness', lightLab);
    if ~leg
        g(1,1).no_legend();
    end
end