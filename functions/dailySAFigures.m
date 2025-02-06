function dailySAFigures(mT,runType, dt,figFold)
    % dailySAFigures generates a set of figures to explore oral SA data dily
    % mT = the master behavior table from main_MouseSABehavior
    % dt = current date time variable
    % figFold = Name of the daily figure folder 'Daily Figure'; Path is
    % relative so name of the folder is suffiecient
    
    yVals = {'ActiveLever', 'InactiveLever', 'EarnedInfusions', 'Intake', 'HeadEntries', 'Latency' };
    yLabs = {'Active Lever Presses', 'Inactive Lever Presses', 'Earned Rewards', 'Estimated Fentanyl Intake (μg/Kg)', 'Head Entries', 'Latency to Head Entry (s)'};

    % fig 1: all animals grouped by sex and strain
    figName{1} = fullfile(figFold,[dt '_GroupBehaviorFig.jpg']);
    grammOptions{1} = {'color', mT.Strain, 'lightness', mT.Sex, 'group', mT.sessionType};
    orderOptions{1} = {'lightness',{'Female','Male'}, 'color',{'c57','CD1'}};
    legOptions{1} = {'color', 'Strain', 'lightness', 'Sex'};
    
    % fig 2: all animals grouped by acquisition
    figName{2} = fullfile(figFold,[dt '_AquiredBehaviorFig.jpg']);
    grammOptions{2} = {'color',mT.Strain,'lightness',mT.Acquire,'group',mT.sessionType};
    orderOptions{2} = {'lightness', {'NonAcquire','Acquire'}, 'color',{'c57','CD1'}};
    legOptions{2} = {'color', 'Strain', 'lightness', 'Acquire'};

    % fig 3: acquirer animals grouped by strain
    figName{3} = fullfile(figFold,[dt '_StrainCollapsedBehaviorAcquirersOnlyFigFig.jpg']);
    grammOptions{3} = {'color',mT.Strain,'group',mT.sessionType,'subset',mT.Acquire=='Acquire'};
    orderOptions{3} = {'color',{'c57','CD1'}};
    legOptions{3} = {'color', 'Strain'};

    % fig 4: acquirer animals grouped by sex
    figName{4} = fullfile(figFold,[dt '_SexCollapsedBehaviorAcquirersOnlyFigFig.jpg']);
    grammOptions{4} = {'lightness',mT.Sex,'group',mT.sessionType,'subset',mT.Acquire=='Acquire'};
    orderOptions{4} = {'lightness',{'Female','Male'}};
    legOptions{4} = {'lightness', 'Sex'};

    % fig 5: acquirer animals grouped by sex and strain
    figName{5} = fullfile(figFold,[dt '_GroupBehaviorAcquirersOnlyFig.jpg']);
    grammOptions{5} = {'color',mT.Strain,'lightness',mT.Sex,'group',mT.sessionType,'subset',mT.Acquire=='Acquire'};
    orderOptions{5} = {'lightness',{'Female','Male'},'color',{'c57','CD1'}};
    legOptions{5} = {'color', 'Strain', 'lightness', 'Sex'};

    % fig 6: all animals grouped by Morning/Afternoon session
    figName{6} = fullfile(figFold,[dt '_TimeOfBehaviorCollapsedFig.jpg']);
    grammOptions{6} = {'color', mT.TimeOfBehavior, 'lightness', mT.Strain};
    orderOptions{6} = {'color',{'Morning','Afternoon'}, 'lightness', {'c57', 'CD1'}};
    legOptions{6} = {'color', 'Time of Session', 'lightness', 'Strain'};

    % fig 7: all animals individually
    figName{7} = fullfile(figFold,[dt '_IndividualBehaviorAllFig.jpg']);
    grammOptions{7} = {'color', mT.TagNumber, 'lightness', mT.Acquire};
    orderOptions{7} = {'lightness', {'NonAcquire','Acquire'}};
    legOptions{7} = {'color', 'TagNumber', 'lightness', 'Acquire'};

    % % fig 8: acquirers individually
    % figName{8} = fullfile(figFold,[dt '_IndividualBehaviorAcquireFig.jpg']);
    % grammOptions{8} = {'color', mT.TagNumber, 'lightness', mT.Strain, 'subset', mT.Acquire=='Acquire'};
    % orderOptions{8} = {'lightness',{'c57','CD1'}};
    % legOptions{8} = {'color', 'TagNumber', 'lightness', 'Strain'};
    % 
    % % fig 9: non acquirers individually
    % figName{9} = fullfile(figFold,[dt '_IndividualBehaviorNonacquireFig.jpg']);
    % grammOptions{9} = {'color', mT.TagNumber, 'lightness', mT.Strain, 'subset', mT.Acquire=='NonAcquire'};
    % orderOptions{9} = {'lightness',{'c57','CD1'}};
    % legOptions{9} = {'color', 'TagNumber', 'lightness', 'Strain'};
    % 
    % % fig 10: all animals grouped by chamber
    % figName{10} = fullfile(figFold,[dt '_BoxBehaviorAllFig.jpg']);
    % grammOptions{10} = {'color', mT.Chamber, 'lightness', mT.Acquire};
    % orderOptions{10} = {'lightness',{'NonAcquire','Acquire'}};
    % legOptions{10} = {'color', 'Chamber', 'lightness', 'Acquire'};
    % 
    % % fig 11: acquirers grouped by chamber
    % figName{11} = fullfile(figFold,[dt '_BoxBehaviorAcquireFig.jpg']);
    % grammOptions{11} = {'color', mT.Chamber, 'lightness', mT.TimeOfBehavior, 'subset', mT.Acquire=='Acquire'};
    % orderOptions{11} = {'lightness',{'Morning','Afternoon'}};
    % legOptions{11} = {'color', 'Chamber', 'lightness', 'Time of Session'};
    % 
    % % fig 12: nonacquirers grouped by chamber
    % figName{12} = fullfile(figFold,[dt '_BoxBehaviorNonacquireFig.jpg']);
    % grammOptions{12} = {'color', mT.Chamber, 'lightness', mT.TimeOfBehavior, 'subset', mT.Acquire=='NonAcquire'};
    % orderOptions{12} = {'lightness',{'Morning','Afternoon'}};
    % legOptions{12} = {'color', 'Chamber', 'lightness', 'Time of Session'};



    

    %% figure generation
    for f = 1:length(figName)
        if ~isempty(figName{f})
            plotDailies(mT, runType, yVals, yLabs, figName{f}, 'GrammOptions', grammOptions{f}, 'OrderOptions', orderOptions{f}, 'LegOptions', legOptions{f});
        end
    end
    
end

function plotDailies(mT, runType, yVals, yLabs, figName, varargin)
    
    p = inputParser;
    addParameter(p, 'GrammOptions', {});             % For gramm initial options
    addParameter(p, 'OrderOptions', {});             % For set_order_options
    addParameter(p, 'LegOptions', {});
    parse(p, varargin{:});

    f = figure('units','normalized','outerposition',[0 0 1 1]);   
    row = 1; 
    col = 1;
    for y = 1:length(yVals)
        g(row,col)=gramm('x',mT.slideSession,'y',mT.(yVals{y}), p.Results.GrammOptions{:});
        if contains(figName, 'Individual')
            g(row,col).geom_jitter('alpha',.6); % note: why do geom_jitter and geom_line lines undo collapsing data by group?
            g(row,col).geom_line('alpha',.6);
        end
        g(row,col).stat_summary('geom',{'black_errorbar','point','line'},'type','sem','dodge',.1,'setylim',1);
        g(row,col).set_point_options('markers',{'o','s'},'base_size',10);
        g(row,col).set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
        g(row,col).axe_property('LineWidth',1.5,'XLim',[0 max(mT.slideSession) + 1],'TickDir','out');
        g(row,col).set_order_options(p.Results.OrderOptions{:});
        g(row,col).set_names('x','Session','y', yLabs{y}, p.Results.LegOptions{:});
        [row, col] = updateRowCol(row, col, 3);
    end

    try
        g.draw();
        row = 1;
        col = 1;
        if strcmp(runType, 'ER')
            for y = 1:length(yVals)
                set(g(row,col).facet_axes_handles,'XTick',[3 9 14 22.5 29],'XTickLabels',{'PreT' 'W1' 'W2' 'Ext.' 'Rei.'});
                [row, col] = updateRowCol(row, col, 3);
            end
        elseif strcmp(runType, 'BE')
            for y = 1:length(yVals)
                set(g(row,col).facet_axes_handles,'XTick',[3 9 14 20 24],'XTickLabels',{'PreT' 'W1' 'W2' 'BeE.' 'ReT'});
                [row, col] = updateRowCol(row, col, 3);
            end
        end
        g(1,2).facet_axes_handles.YLim=g(1,1).facet_axes_handles.YLim;
        exportgraphics(f,figName);
        disp(['saved figure: ', figName])
    catch
        disp(['error encountered drawing figure: ', figName, ', aborted'])
    end

end

function [row, col] = updateRowCol(row, col, colMax)
    if col == colMax
        row = row + 1;
        col = 1;
    else
        col = col + 1;
    end
end