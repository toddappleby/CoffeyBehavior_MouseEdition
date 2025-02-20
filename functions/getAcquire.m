function [Acquire] = getAcquire(mT, dex, acquisition_thresh)
    IDs=unique(mT.TagNumber(dex.all));
    mT = sortrows(mT,'TagNumber','ascend');
    Acq = nan(size(IDs));
    Acquire = categorical(nan([height(mT), 1]));
    for id=1:height(IDs)
        % SSnote: this should be using sessionType instead of the Session#
        idx = mT.TagNumber==IDs(id) & mT.Session>9 & mT.Session <16;
        Acq(id,1) = mean(mT.EarnedInfusions(idx)) > acquisition_thresh;
        if Acq(id) == 0 && sum(idx) ~= 0
            status = 'NonAcquire';
        else
            status = 'Acquire';
        end
        tmp=repmat(categorical({status}), sum(mT.TagNumber == IDs(id)), 1);
        Acquire(mT.TagNumber == IDs(id)) = tmp;
    end
end