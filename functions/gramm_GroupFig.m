function gramm_GroupFig(tab, xvar, yvar, xlab, ylab, figpath, figsave_type, varargin)
    
    p = inputParser;
    addParameter(p, 'GrammOptions', {});            
    addParameter(p, 'OrderOptions', {});           
    addParameter(p, 'LegOptions', {});
    addParameter(p, 'ColorOptions', {});
    addParameter(p, 'StatOptions', {});
    addParameter(p, 'AxOptions', {});
    addParameter(p, 'PointOptions', {});
    
    parse(p, varargin{:});

    f = figure('Position',[100, 100, 500*length(yvar), 500],'Color',[1 1 1]);
    clear g
    for sp = 1:length(yvar)
        % leg = sp == 1;
        g(1,sp) = gramm_GroupSubplot(tab.(xvar(sp)), tab.(yvar(sp)), ...
                             xlab(sp), ylab(sp), 1, ...
                             varargin);
    end
    g.draw;

    str_inds = arrayfun(@(x) ischar(p.Results.StatOptions{x}), 1:length(p.Results.StatOptions));
    if any(ismember(p.Results.StatOptions(str_inds), 'cumcount'))
        stat_field = 'stat_bin';
        stat_yvar = 'counts';
        update_marker = false;
    elseif any(ismember(p.Results.StatOptions(str_inds), 'area'))
        stat_field = 'stat_summary';
        stat_yvar = 'yci';
        update_marker = true; 
    else
        stat_field = 'stat_summary';
        stat_yvar = 'y';
        update_marker = false;
    end

    for sp = 1:length(yvar)
       yMax = -1000;
       set(g(1,sp).facet_axes_handles, p.Results.AxOptions{:});
      
       for ss = 1:length(g(1,sp).results.(stat_field))
           if update_marker
               set(g(1,sp).results.(stat_field)(ss).point_handle,'MarkerEdgeColor',[0 0 0]);  
           end
           maxStat = nanmax(g(1,1).results.(stat_field)(ss).(stat_yvar)(:));
           if maxStat > yMax
               yMax = maxStat;
           end       
       end

       yMax = 1.05 * yMax;
       g(1,sp).axe_property('YLim', [0 yMax], 'TickDir','out');
    end

    saveFigsByType(f, figpath, figsave_type);
    close(f);
end