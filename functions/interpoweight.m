function [mT] = interpoweight(mT, interp_sessions)
    tags = unique(mT.TagNumber);
    for t = 1:length(tags)
        % disp(tags(t))
        weights = mT.Weight(mT.TagNumber == tags(t));
        sessions = mT.Session(mT.TagNumber == tags(t));
        % figure
        % hold on
        % plot(sessions, weights)
        % title(tags(t))
        % hold off
        temp = weights;
        for s = 1:length(interp_sessions)-1
            first = weights(sessions == interp_sessions(s));
            last = weights(sessions == interp_sessions(s+1));
            if ~isempty(last)
                num = interp_sessions(s+1) - interp_sessions(s) + 1;
                interp = linspace(first, last, num);
                for n = 1:num
                    temp(sessions == interp_sessions(s) + n - 1) = interp(n);
                end
            end
        end
        mT.Weight(mT.TagNumber == tags(t)) = temp;
        
        % hold on
        % plot(sessions, temp)
        % hold off
    end
end