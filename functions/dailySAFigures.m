function dailySAFigures(mT,runType, dex, figFold, figsave_type)
    % dailySAFigures generates a set of figures to explore oral SA data dily
    % pT = the master behavior table from main_MouseSABehavior
    % dt = current date time variable
    % figFold = Name of the daily figure folder 'Daily Figure'; Path is
    % relative so name of the folder is suffiecient
    
    yVals = {'ActiveLever', 'InactiveLever', 'EarnedInfusions', 'Intake', 'HeadEntries', 'Latency' };
    yLabs = {'Active Lever Presses', 'Inactive Lever Presses', 'Earned Rewards', 'Estimated Fentanyl Intake (μg/Kg)', 'Head Entries', 'Latency to Head Entry (s)'};
    gramm_C57_Sex_colors = {'hue_range',[40 310],'lightness_range',[95 65],'chroma_range',[50 90]};
    gramm_CD1_Sex_colors = {'hue_range',[85 -200],'lightness_range',[85 75],'chroma_range',[75 90]};
    gramm_Strain_Acq_colors = {'hue_range',[25 385],'lightness_range',[95 60],'chroma_range',[50 70]};     
    for rt = 1:length(runType)
        expStr = char(string(runType(rt)));

        pT = mT(dex.(string(expStr)),:);
        % fig 1: all animals grouped by sex and strain
        figName{1} = fullfile(figFold,[expStr, '_GroupBehaviorFig']);
        grammOptions{1} = {'color', pT.Strain, 'lightness', pT.Sex, 'group', pT.sessionType};
        orderOptions{1} = {'lightness',{'Female','Male'}, 'color',{'c57','CD1'}};
        legOptions{1} = {'color', 'Strain', 'lightness', 'Sex'};
        
        % fig 2: all animals grouped by acquisition
        figName{2} = fullfile(figFold,[expStr, '_AquiredBehaviorFig']);
        grammOptions{2} = {'color', pT.Strain, 'lightness', pT.Acquire, 'group',pT.sessionType};
        orderOptions{2} = {'lightness', {'NonAcquire','Acquire'}, 'color',{'c57','CD1'}};
        legOptions{2} = {'color', 'Strain', 'lightness', 'Acquire'};
    
        % fig 3: acquirer animals grouped by strain
        figName{3} = fullfile(figFold,[expStr, '_StrainCollapsedBehaviorAcquirersOnlyFig']);
        grammOptions{3} = {'color', pT.Strain,'group', pT.sessionType, 'subset', pT.Acquire=='Acquire'};
        orderOptions{3} = {'color',{'c57','CD1'}};
        legOptions{3} = {'color', 'Strain'};

        % fig 4: acquirer animals grouped by sex
        figName{4} = fullfile(figFold,[expStr, '_SexCollapsedBehaviorAcquirersOnlyFig']);
        grammOptions{4} = {'lightness', pT.Sex, 'group', pT.sessionType, 'subset', pT.Acquire=='Acquire'};
        orderOptions{4} = {'lightness', {'Female','Male'}};
        legOptions{4} = {'lightness', 'Sex'};
    
        % fig 5: acquirer animals grouped by sex and strain
        figName{5} = fullfile(figFold,[expStr, '_GroupBehaviorAcquirersOnlyFig']);
        grammOptions{5} = {'color', pT.Strain, 'lightness', pT.Sex, 'group', pT.sessionType, 'subset', pT.Acquire=='Acquire'};
        orderOptions{5} = {'lightness',{'Female','Male'},'color',{'c57','CD1'}};
        legOptions{5} = {'color', 'Strain', 'lightness', 'Sex'};
    
        % fig 6: all animals grouped by Morning/Afternoon session
        figName{6} = fullfile(figFold,[expStr, '_TimeOfBehaviorCollapsedFig']);
        grammOptions{6} = {'color', pT.TimeOfBehavior, 'lightness', pT.Strain, 'group', pT.sessionType,};
        orderOptions{6} = {'color',{'Morning','Afternoon'}, 'lightness', {'c57', 'CD1'}};
        legOptions{6} = {'color', 'Time of Session', 'lightness', 'Strain'};
    
        % % fig 7: all animals individually
        % figName{7} = fullfile(figFold,[expStr, '_IndividualBehaviorAllFig']);
        % grammOptions{7} = {'color', pT.TagNumber, 'lightness', pT.Acquire, 'group', pT.sessionType};
        % orderOptions{7} = {'lightness', {'NonAcquire','Acquire'}};
        % legOptions{7} = {'color', 'TagNumber', 'lightness', 'Acquire'};
    
        % % fig 8: acquirers individually
        % figName{8} = fullfile(figFold,[expStr, '_IndividualBehaviorAcquireFig']);
        % grammOptions{8} = {'color', pT.TagNumber, 'lightness', pT.Strain, 'subset', pT.Acquire=='Acquire', 'group', pT.sessionType};
        % orderOptions{8} = {'lightness',{'c57','CD1'}};
        % legOptions{8} = {'color', 'TagNumber', 'lightness', 'Strain'};
        % 
        % % fig 9: non acquirers individually
        % figName{9} = fullfile(figFold,[expStr, '_IndividualBehaviorNonacquireFig']);
        % grammOptions{9} = {'color', pT.TagNumber, 'lightness', pT.Strain, 'subset', pT.Acquire=='NonAcquire', 'group', pT.sessionType};
        % orderOptions{9} = {'lightness',{'c57','CD1'}};
        % legOptions{9} = {'color', 'TagNumber', 'lightness', 'Strain'};
         
        % % fig 10: all animals grouped by chamber
        % figName{10} = fullfile(figFold,[expStr, '_BoxBehaviorAllFig']);
        % grammOptions{10} = {'color', pT.Chamber, 'lightness', pT.Acquire, 'group', pT.sessionType,};
        % orderOptions{10} = {'lightness',{'NonAcquire','Acquire'}};
        % legOptions{10} = {'color', 'Chamber', 'lightness', 'Acquire'};
        
        % % fig 11: acquirers grouped by chamber
        % figName{11} = fullfile(figFold,[expStr, '_BoxBehaviorAcquireFig']);
        % grammOptions{11} = {'color', pT.Chamber, 'lightness', pT.TimeOfBehavior, 'subset', pT.Acquire=='Acquire', 'group', pT.sessionType};
        % orderOptions{11} = {'lightness',{'Morning','Afternoon'}};
        % legOptions{11} = {'color', 'Chamber', 'lightness', 'Time of Session'};
        % 
        % % fig 12: nonacquirers grouped by chamber
        % figName{12} = fullfile(figFold,[expStr, '_BoxBehaviorNonacquireFig']);
        % grammOptions{12} = {'color', pT.Chamber, 'lightness', pT.TimeOfBehavior, 'subset', pT.Acquire=='NonAcquire', 'group', pT.sessionType};
        % orderOptions{12} = {'lightness',{'Morning','Afternoon'}};
        % legOptions{12} = {'color', 'Chamber', 'lightness', 'Time of Session'};
        
    
        %% figure generation
    
        for f = 1:length(figName)
            if ~isempty(figName{f})
                plotDailies(pT, expStr, yVals, yLabs, figName{f}, figsave_type, 'GrammOptions', grammOptions{f}, 'OrderOptions', orderOptions{f}, 'LegOptions', legOptions{f}, 'ColorOptions', gramm_Strain_Acq_colors);
            end
        end
    end
    
end

function plotDailies(pT, runType, yVals, yLabs, figName, figsave_type, varargin)
    
    p = inputParser;
    addParameter(p, 'GrammOptions', {});             % For gramm initial options
    addParameter(p, 'OrderOptions', {});             % For set_order_options
    addParameter(p, 'LegOptions', {});
    addParameter(p, 'ColorOptions', {});
    parse(p, varargin{:});

    f = figure('units','normalized','outerposition',[0 0 1 1]);   
    row = 1; 
    col = 1;
    for y = 1:length(yVals)
        g(row,col)=gramm('x',pT.slideSession,'y',pT.(yVals{y}), p.Results.GrammOptions{:});
        if contains(figName, 'Individual')
            g(row,col).geom_jitter('alpha',.6); % SSnote: why do geom_jitter and geom_line lines undo collapsing data by group?
            g(row,col).geom_line('alpha',.6);
        end
        g(row,col).set_color_options(p.Results.ColorOptions{:});
        g(row,col).stat_summary('geom',{'black_errorbar','point','line'},'type','sem','dodge',.1,'setylim',1);
        g(row,col).set_point_options('markers',{'o','s'},'base_size',10);
        g(row,col).set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
        g(row,col).axe_property('LineWidth',1.5,'XLim',[0 max(pT.slideSession) + 1],'TickDir','out');
        g(row,col).set_order_options(p.Results.OrderOptions{:});
        g(row,col).set_names('x','Session','y', yLabs{y}, p.Results.LegOptions{:});
        [row, col] = updateRowCol(row, col, 3);
    end

    try
        g.draw();
        row = 1;
        col = 1;
        for y = 1:length(yVals)
            if strcmp(runType, 'ER') 
                set(g(row,col).facet_axes_handles, 'XTick', [3 9 14 22.5 29], 'XTickLabels', {'PreT' 'W1' 'W2' 'Ext.' 'Rei.'});
            elseif strcmp(runType, 'BE')
                set(g(row,col).facet_axes_handles, 'XTick', [3 9 14 20 24], 'XTickLabels', {'PreT' 'W1' 'W2' 'BeE.' 'ReT'});
            elseif strcmp(runType, 'SA')
                set(g(row,col).facet_axes_handles, 'XTick', [3 9 14], 'XTickLabels', {'PreT' 'W1' 'W2'});
            end
            [row, col] = updateRowCol(row, col, 3);
            yMax = 0;
            for ss = 1:length(g(y).results.stat_summary)
                maxStat = nanmax(g(y).results.stat_summary(ss).yci(:));
               if maxStat > yMax
                   yMax = maxStat;
               end      
            end
            yMax = (ceil(yMax/10)*10)+10;
            g(y).facet_axes_handles.YLim = [-.05 * yMax, yMax];
        end
        g(1,2).facet_axes_handles.YLim=g(1,1).facet_axes_handles.YLim;
        
        for fst = 1:length(figsave_type)
            if strcmp(figsave_type{fst}, '.pdf')
                exportgraphics(f,[figName, figsave_type{fst}], 'ContentType','vector')
            else
                exportgraphics(f,[figName, figsave_type{fst}]);
            end
            disp(['saved figure: ', figName, figsave_type{fst}])
        end
    catch
        disp(['error encountered drawing or saving figure: ', figName, ', aborted'])
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