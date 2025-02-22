function [ivZT] = SeverityScore(ivT, includeER)
    % Z-Score & Severity Score
    ivZT = ivT(:, {'ID', 'Sex', 'Strain', 'Acquire'});
    ivZT.Intake = zscore(ivT.Intake);
    ivZT.Seeking = zscore(ivT.Seeking);
    ivZT.Association = zscore(ivT.Association);
    ivZT.Escalation = zscore(ivT.Escalation);
    if includeER
        ivZT.Extinction = zscore(ivT.Extinction);
        ivZT.Relapse = zscore(ivT.Relapse);
        ivZT.Recall = zscore(ivT.Recall(~isnan(ivT.Recall)));
    end

    varnames = ivZT.Properties.VariableNames;
    prednames = varnames(varnames ~= "ID" & varnames ~= "Sex" & varnames ~= "Strain" & varnames ~= "Acquire");

    % Severity
    Severity = nansum(ivZT{:, prednames}')';
    Class = cell([height(Severity) 1]);
    Class(Severity>1.5) = {'High'};
    Class(Severity>-1.5 & Severity<1.5) = {'Mid'};
    Class(Severity<-1.5) = {'Low'};
    Class = categorical(Class);
    ivZT.Severity = Severity;
    ivZT.Class = Class;
end
