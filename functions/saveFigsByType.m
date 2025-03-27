function saveFigsByType(f, path, figsave_type)
    for fst = 1:length(figsave_type)
        if strcmp(figsave_type{fst}, '.pdf')
            exportgraphics(f,[path, figsave_type{fst}], 'ContentType','vector')
        elseif strcmp(figsave_type{fst}, '.fig')
            savefig(f,[path, figsave_type{fst}]);
        else
            exportgraphics(f,[path, figsave_type{fst}]);
        end
        disp(['saved figure: ', path, figsave_type{fst}])
    end
end