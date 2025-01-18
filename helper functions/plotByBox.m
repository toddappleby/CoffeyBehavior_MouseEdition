function [grammPlots] = plotByBox(mT, metric, subset, figFold)
    
    grammPlots = gramm.empty;
    numplot = length(subset);
    numcol = floor(sqrt(numplot));
    row = 1; col = 1;
    ymax = getYmax(mT.(metric));

    for s = 1:length(subset)
        
        subind = getSubInds(mT, subset{s});
        ymax = getYmax(mT.(metric)(subind));
        uni_sess = unique(mT.Session(subind));

        for u = 1:length(uni_sess); disp(length(find(mT.Session(subind)==uni_sess(u)))); end
        
        if ~length(find(subind)) == 0        
            tit = [];
            for el = 1:length(subset{s})
                for o = 1:length(subset{s}{el}{2})
                    tit = [tit, '_', subset{s}{el}{2}{o}];
                end
            end
            
            g = subplotBox(mT, mT.Session, mT.(metric), subind, metric, tit, ymax);
            % g.facet_grid(rowVar, colVar);
            grammPlots = [grammPlots, g];
        end

        if col == numcol; row = row + 1; col = 1; else; col = col +1; end
    end

    f = figure('Position',[1 1 1080 540]);
    grammPlots.draw();

    % Export Figure
    if ~strcmp(figFold,'')
        figName=fullfile(figFold,[tit, '.png']);
        exportgraphics(f,figName);
    end


    function [g] = subplotBox(tab, x, y, subset, metric, tit, ymax)
        g=gramm('x', x, 'y', y, 'color', tab.Box, 'group', tab.sessionType, 'subset', subset);
        g.set_color_options('hue_range', [90 450], 'lightness_range', [85 35], 'chroma_range', [30 70]);
        % why the hell won't it draw without the stat_summary line???
        g.stat_summary('geom',{'black_errorbar','point','line'}, 'type', 'sem', 'dodge', .1, 'setylim', 1);
        g.set_point_options('markers',{'o','s'},'base_size',10);
        g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
        g.axe_property('LineWidth',1.5,'XLim',[0 30], 'YLim', [0, ymax + (ymax * .05)], 'TickDir','out');
        g.set_names('x','Session','y',metric,'color','Box');
        g.set_title(tit);

    end
end