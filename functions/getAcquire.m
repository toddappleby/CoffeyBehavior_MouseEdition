function [Acquire] = getAcquire(mT, acquisition_thresh, pAcq)
    IDs=unique(mT.TagNumber);
    mT = sortrows(mT,'TagNumber','ascend');
    Acq = nan(size(IDs));
    Acquire = categorical(nan([height(mT), 1]));
    for id=1:height(IDs)
        % SSnote: this should be using sessionType instead of the Session#
        % idx = mT.TagNumber==IDs(id) & mT.Session>9 & mT.Session <16;
        idx = mT.TagNumber==IDs(id) & mT.sessionType == 'Training';
        Acq(id,1) = mean(mT.EarnedInfusions(idx)) > acquisition_thresh;
        acqDist(id,1) = mean(mT.EarnedInfusions(idx));
        if Acq(id) == 0 && sum(idx) ~= 0
            status = 'NonAcquire';
        else
            status = 'Acquire';
        end
        tmp=repmat(categorical({status}), sum(mT.TagNumber == IDs(id)), 1);
        Acquire(mT.TagNumber == IDs(id)) = tmp;
    end
    if pAcq
       figure('Position',[1 300 275 250],'color','w'); histogram(acqDist,50);
       box off; hold on;
       plot([acquisition_thresh acquisition_thresh],[0 15],'--r')
       ylabel('Number of Animals');
       xlabel('Rewards Earned (Training Avg)');
       set(gca,'LineWidth',1.5,'TickDir','out','FontSize',12);
    end
end