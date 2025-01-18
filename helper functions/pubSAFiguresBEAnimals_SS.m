function pubSAFiguresBEAnimals(mT,dt,figFold)
% pubSAFigures Generate Clean Subset of Figures for Publication
% mT = the master behavior table from main_MouseSABehavior
% dt = current date time variable
% figFold = Name of the daily figure folder 'Daily Figure'; Path is
% relative so name of the folder is suffiecient

    titles = {'Self-Administration', 'Days 13-15'}; % titles of subplots 1-2 for each figure
    colorOptions = {'hue_range',[0 360],'lightness_range',[85 35],'chroma_range',[30 70]};
    figType = '.png'; % image save type

    %% Active Lever CD1 Aquirers
    fnum = 1;
    figNames{fnum} = fullfile(figFold,[dt, '_BE_ActiveLeverCD1.png']);
    subset = {{'Strain', {'CD1'}};
              {'Acquire', {'Acquire'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'ActiveLever';
    yLabs{fnum} = 'Active Lever';
    grammOptions{fnum} = {'color', mT.Sex};        
    orderOptions{fnum} = {'color', {'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};

    %% Earned Infusions CD1 Aquirers
    fnum = 2;
    figNames{fnum} = fullfile(figFold,[dt, '_BE_EarnedInfusionsCD1.png']);
    subset = {{'Strain', {'CD1'}};
              {'Acquire', {'Acquire'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'EarnedInfusions';
    yLabs{fnum} = 'Earned Infusions';
    grammOptions{fnum} = {'color', mT.Sex};        
    orderOptions{fnum} = {'color', {'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};

    %% LatencyInfusions CD1 Aquirers
    fnum = 3;
    figNames{fnum} = fullfile(figFold,[dt, '_BE_LatencyCD1.png']);
    subset = {{'Strain', {'CD1'}};
              {'Acquire', {'Acquire'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'lastLatency';
    yLabs{fnum} = 'Head Entry Latency';
    grammOptions{fnum} = {'color', mT.Sex};        
    orderOptions{fnum} = {'color', {'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};

    %% Infusions CD1 Aquirers
    fnum = 4;
    figNames{fnum} = fullfile(figFold,[dt, '_BE_IntakeCD1.png']);
    subset = {{'Strain', {'CD1'}};
              {'Acquire', {'Acquire'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'Intake';
    yLabs{fnum} = 'Intake (ug/kg)';
    grammOptions{fnum} = {'color', mT.Sex};        
    orderOptions{fnum} = {'color', {'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};

    %% plotting loop
    
    for y = 1:length(yVars)
        if ~isempty(subInds{y})
            plotPubFig(mT, yVars{y}, yLabs{y}, subInds{y}, titles, figNames{y}, figType, ...
                        'GrammOptions', grammOptions{y}, 'ColorOptions', colorOptions, ...
                        'OrderOptions', orderOptions{y}, 'LegendOptions', legendOptions{y});
        end
    end
end

function [g] = plotPubFig(mT, yVar, yLab, subInd, titles, figName, figType, varargin)
% why am I parsing it this way? this is dumb    
p = inputParser;
    addParameter(p, 'GrammOptions', {});             % For gramm initial options
    addParameter(p, 'ColorOptions', {})
    addParameter(p, 'OrderOptions', {});             % For set_order_options
    addParameter(p, 'LegendOptions', {});

    parse(p, varargin{:});

    sp_subInd = {subInd & (mT.sessionType=='PreTraining' | mT.sessionType=='Training'), ...
                 subInd & (mT.sessionType=='PreTraining' | mT.sessionType=='Training') & mT.Session>12};
    xLim = {[0, 15.5], [0.5 2.5]};

    stat_set = {{'geom',{'black_errorbar','point','line'},'type','sem','dodge',0,'setylim',1,'width',1}, ...
                {'geom',{'black_errorbar','bar'},'type','sem','dodge',1.75,'width',1.5}};
    point_set = {{'base_size', 10}, {'base_size', 6}};

    f1 = figure('Position',[1 300 700 350]);
    clear g;
    yMax = 0;
    for sp = 1:2        
        if mod(sp,2) == 1
            g(1,sp)=gramm('x',mT.Session,'y',mT.(yVar),'subset', sp_subInd{sp}, p.Results.GrammOptions{:});
            g(1,sp).stat_summary(stat_set{1}{:});
            g(1,sp).set_point_options('markers',{'o','s'}, point_set{1}{:});  
            g(1,sp).set_names('x','Session','y', yLab,'color','Sex');
            g(1,sp).no_legend;
        elseif mod(sp,2) == 0
            g(1,sp)=gramm('x', mT.Sex,'y', mT.(yVar), 'subset', sp_subInd{sp}, p.Results.GrammOptions{:});
            g(1,sp).stat_summary(stat_set{2}{:});
            g(1,sp).set_point_options('markers',{'o','s'}, point_set{2}{:});
            g(1,sp).geom_jitter('alpha',.6,'dodge',1.75,'width',0.05);
            g(1,sp).set_names(p.Results.LegendOptions{:});
        end
        g(1,sp).set_text_options('font','Helvetica','base_size',13,'legend_scaling',.75,'legend_title_scaling',.75);
        g(1,sp).set_color_options(p.Results.ColorOptions{:});
        g(1,sp).set_order_options(p.Results.OrderOptions{:});
        g(1,sp).set_title(titles{sp});
    end

    g.draw;
    
    for sp = 1:2
        for s = 1:length(g(1,sp).results.stat_summary)
            disp("STAT")
            disp(g(1,sp).results.stat_summary(s).y)
            maxStat = nanmax(g(1,sp).results.stat_summary(s).yci(:));
            disp(maxStat)
            if maxStat > yMax
                yMax = maxStat;
                disp(yMax)
            end
        end
    end
    yMax = yMax + (.05 * yMax);
    disp('YMAX')
    disp(yMax)
    for sp = 1:2
        g(1,sp).axe_property('LineWidth', 1.5, 'XLim', xLim{sp}, 'YLim', [0 yMax], 'TickDir','out');

        % Title
        set(g(1,sp).title_axe_handle.Children ,'FontSize',12);
        
        if mod(sp,2) == 1
            % Marker Manipulation
            set(g(1,sp).results.stat_summary(1).point_handle,'MarkerEdgeColor',[0 0 0]);  
            set(g(1,sp).results.stat_summary(2).point_handle,'MarkerEdgeColor',[0 0 0]);  
        elseif mod(sp,2) == 0
            % Marker Manipulation
            set(g(1,sp).results.geom_jitter_handle(1),'MarkerEdgeColor',[0 0 0]);  
            set(g(1,sp).results.geom_jitter_handle(2),'MarkerEdgeColor',[0 0 0]);  
            set(g(1,sp).results.stat_summary(1).bar_handle,'EdgeColor',[0 0 0]);
            set(g(1,sp).results.stat_summary(2).bar_handle,'EdgeColor',[0 0 0]);
        end
    end

    % Remove & Move Axes
    set(g(1,2).facet_axes_handles,'YColor',[1 1 1]);
    set(g(1,2).facet_axes_handles,'YLabel',[],'YTick',[]);
    pos1=g(1,2).facet_axes_handles.OuterPosition;
    set(g(1,2).facet_axes_handles,'OuterPosition',[pos1(1)-.04,pos1(2),pos1(3)-.04,pos1(4)]);
    pos2=g(1,2).title_axe_handle.OuterPosition;
    set(g(1,2).title_axe_handle,'OuterPosition',[pos2(1)-.05,pos2(2),pos2(3),pos2(4)]);

    % Axes Limits
    set(g(1,1).facet_axes_handles,'YLim',[0 yMax],'XLim',[0 15.5]);
    set(g(1,2).facet_axes_handles,'YLim',[0 yMax],'XTickLabel',{char(9792),char(9794)});

    % Export Figure
    exportgraphics(f1,[figName, figType],'ContentType','vector');
end