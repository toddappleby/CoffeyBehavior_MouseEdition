function [eventCode,eventTime] = eventFilterHE(eventCode,eventTime)
% Filters Oral SA events to allow for photometry analysis
% Removes duplicate events (rapid levers, head entires, etc.)
% Determines if head entries are rewarded or unrewarded

% INPUT EVENT CODES
% Event Code 13 = Infusion, Tone, Light, Etc (No need for filtering)
% Event Code 22 = Active Lever Press
% Rewarded Press 3 = Active Lever Press Followed by Tone etc.
% Event Code 23 = Inactive Lever Press (Filter out presses within 10s)
% Event Code 6 = Head Entry (Filter withing 10s & Rewarded vs Unrewarded)

% OUTPUT EVENT CODES
% Event Code 13 = Infusion, Rewareded Press, Tone, Light, Etc (No need for filtering)
% Rewarded Press 3 = Active Lever Press Followed by Tone etc.
% Event Code 97 = Unrewarded Active Lever Press (Filter out presses within 10s)
% Event Code 23 = Inactive Lever Press (Filter out presses within 10s)
% Event Code 96 = Head Entry Filtered Within 2s
% Event Code 98 = Rewarded Head Entry (Filter withing 10s)
% Event Code 99 = Unrewarded Head Entry (Filter withing 10s)

eventTime = round(eventTime,1);

rewLP=eventTime(eventCode==3);
cue=eventTime(eventCode==13);
actLP=eventTime(eventCode==22);
inactLP=eventTime(eventCode==23);
HE=eventTime(eventCode==6);
rewHE=[];
unrewHE=[];
unrewLP=[];
inLP=[];
filtHE=[];

c=0;
curHE=0;
for i=1:height(cue)
    if ~isempty(HE(find(HE>cue(i),1,'first'))) & HE(find(HE>cue(i),1,'first'))~=curHE
    c=c+1;    
    rewHE(c,1)=HE(find(HE>cue(i),1,'first'));
    curHE=HE(find(HE>cue(i),1,'first'));
    end
end
HE = setdiff(HE,rewHE);

for i=1:height(HE)
idx(i,1)=~any(abs(rewHE-HE(i)) <= 5);
end
HE=HE(idx);

c=0;
for i=2:height(HE)
    if ~sum(HE(i)==rewHE)
        if HE(i)-HE(i-1)>5
        c=c+1;
        unrewHE(c,1)=HE(i);
        end
    end
end

c=0;
for i=2:height(actLP)
    if ~sum(actLP(i)==rewLP)
        if actLP(i)-actLP(i-1)>10
        c=c+1;
        unrewLP(c,1)=actLP(i);
        end
    end
end

if ~isempty(inactLP)
c=1;
inLP(c,1)=inactLP(1);
for i=2:height(inactLP)
    if inactLP(i)-inactLP(i-1)>10
        c=c+1;
        inLP(c,1)=inactLP(i);
    end
end
end

if ~isempty(HE)
c=1;
C(c,1)=HE(1);
for i=2:height(HE)
    if HE(i)-HE(i-1)>5
        c=c+1;
        filtHE(c,1)=HE(i);
    end
end
end

eventCode=[repmat(3,[height(rewLP),1]);...
    repmat(13,[height(cue),1]);...
    repmat(97,[height(unrewLP),1]);...
    repmat(23,[height(inLP),1]);...
    repmat(96,[height(filtHE),1]);...
    repmat(98,[height(rewHE),1]);...
    repmat(99,[height(unrewHE),1])];

eventTime=[rewLP;...
    cue;...
    unrewLP;...
    inLP;...
    filtHE;...
    rewHE;...
    unrewHE];
end