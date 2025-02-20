function PCA_fig(ivZT, prednames, sub_dir, subfolder, suffix, figsave_type)
    [coeff,score,latent] = pca(ivZT{:,prednames});
    PC1=score(:,1);
    PC2=score(:,2);

    f1=figure('color','w','position',[100 100 800 650]);
    h1 = biplot(coeff(:,1:3),'Scores',score(:,1:3),...
        'Color','b','Marker','o','VarLabels',prednames);
    % set metric vectors' appearance
    for i = 1:length(prednames) 
        h1(i).Color=[.5 .5 .5];    
        h1(i).LineWidth=1.5;
        h1(i).LineStyle=':';
        h1(i).MarkerSize=4;
        h1(i).MarkerFaceColor=[.0 .0 .0];
        h1(i).MarkerEdgeColor=[0 .0 0];
    end
    % remove extra line objects (not sure why these exist) 
    for i = length(prednames) + 1 : length(prednames) * 2
        h1(i).Marker='none';
    end
    % format text for metric vector labels
    for i = 1 + (length(prednames) * 2) : 3 * length(prednames)
        h1(i).FontSize = 11;
        h1(i).FontWeight = 'bold';
    end
    data_ind1 = length(h1) - height(ivZT);
    R = rescale(ivZT.Severity,4,18);
    for i=data_ind1:length(h1)-1
        h1(i).MarkerEdgeColor=[0 .0 0];
        h1(i).MarkerSize=R(i-data_ind1 + 1);
        if ivZT.Sex(i - data_ind1 + 1) == 'Male' % SSnote: the heck is this part for
            h1(i).MarkerFaceColor = [.46 .51 1];
        else
            h1(i).MarkerFaceColor = [.95 .39 .13];
        end
        if ivZT.Strain(i - data_ind1 + 1) == 'c57' % SSnote: the heck is this part for
            h1(i).Marker='o';
        else
            h1(i).Marker='s';
        end

    end
    pbaspect([1,1,1])
    set(gca,'LineWidth',1.5,'TickDir','in','FontSize',14);
    grid off
    saveas(f1,[sub_dir, subfolder 'PCA_Vectors', suffix]);
    
    pcTable = [ivZT, table(PC1, PC2)];
    f1 = figure('color','w','position',[100 100 800 650]);
    g = gramm('x', pcTable.PC1, 'y', pcTable.PC2, 'color', pcTable.Sex, 'marker', pcTable.Strain, 'lightness', pcTable.Class);
    g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
    g.geom_point();
    g.set_names('x','PC1','y','PC2','color','Sex', 'marker', 'Strain', 'lightness', 'Class');
    g.axe_property('FontSize',12,'LineWidth',1.5,'TickDir','out');
    g.set_order_options('lightness',{'High','Mid','Low'});
    g.set_point_options('base_size',8);
    g.draw;
    for i = 1:height(g.results.geom_point_handle)
        g.results.geom_point_handle(i)
       g.results.geom_point_handle(i).MarkerEdgeColor = [0 0 0];
    end
    saveFigsByType(f, [sub_dir, subfolder, PC1_PC2', suffix], figsave_type)
end