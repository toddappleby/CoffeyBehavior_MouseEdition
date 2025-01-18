function [tab] = whiteOutRows(tab, vars, rows)
    for c2n = 1:length(vars)
        if isa(tab.(vars{c2n}), 'double')
            tab{rows,vars{c2n}} = NaN;
        elseif isa(tab.(vars{c2n}), 'categorical')
            tab{rows,vars{c2n}} = categorical(NaN);
        elseif isa(tab.(vars{c2n}), 'cell')
            tab{rows,vars{c2n}} = {NaN};
        else
            try
                tab{rows,vars{c2n}} = NaN;
            catch
                disp('could not assign column to NaN:')
                disp(vars{c2n})
                disp(class(tab.(vars{c2n})))
                disp('')
            end
        end   
    end
end