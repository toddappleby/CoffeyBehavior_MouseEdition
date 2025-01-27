function [varTable] = rawVariableExtractor_SS(varTable, eventCode, eventTime)
% rawVariableExtractor takes the raw event times for mouse oral SA and
% calculates variables of interest and adds them to the varTable
%
% INPUTS: varTable, eventCode, eventTime - Direct outputs of "importMouseOralSA"
%
% OUTPUTS: varTable (Updated with variables calculated or cleaned below)
%
% VARIABLES CALULATED OR CLEANED:
%
% filteredHeadEntries = head entries that are seperated by >5s
% hourHeadEntries = head entries seperated by >5s and in the first hour
% EarnedInfusions = Fixed to remove infusions from Reinstatement Day and random -1s
% Intake = Total self administered intake in ug/kg
% sessionType = PreTraining (S1-5); Training (S6-15); Extinction (S16-25); Reinstatement (S26)
% allLatency = Avg. time from each rewarded lever press to first head entry
% lastLatency = Avg. time from last rewarded lever press before a head entry
% itiActiveLever = Active lever presses in the 10s following reward
% itiInactiveLaver = Inactive lever presses in the 10s following reward
% slideSession = Seperate each session type by 1 day to help with graphing
% hourActiveLever = Active lever presses in the first hour
% hourInactiveLaver = Inactive lever presses in the first hour

    % Change Subject to TagNumber to Match the Key
    varTable.Properties.VariableNames{'Subject'} = 'TagNumber';
    
    % filteredHeadEntries
    % UPDATE currently doesn't work with PR data -- array length of eventCode >
    % eventTime, so I just made a small work around so I can see ~how the
    % animals are doing during PR
    % HE=eventTime(eventCode==6);
    ldiff=length(eventCode)-length(eventTime);
    if ldiff > 0
        eventCode = eventCode(1:end-ldiff);
    end
    HE=eventTime(eventCode==6);
    hourHE=HE(HE<3600);
    varTable.filteredHeadEntries=sum(diff(HE)>5); % head entries that are seperated by >5s
    varTable.hourHeadEntries=sum(diff(hourHE)>5); % head entries in the first hour that are seperated by >5s
    
    % % EarnedInfusion
    varTable.EarnedInfusions(varTable.Session==26 | varTable.EarnedInfusions<0)=0; % remove infusions from Reinstatement Day and random -1s
    % SS added first hour earned infusions
    timeEI = eventTime(eventCode==17);
    hourEI = timeEI(timeEI<3600);
    varTable.hourEarnedInfusions = length(hourEI);
    
    % Intake
    varTable.Intake=(varTable.EarnedInfusions*1.575)/(varTable.Weight/1000); % 1.575ug/dose*infusions / weight in kg = (ug/kg)
    varTable.hourIntake=(varTable.hourEarnedInfusions*1.575)/(varTable.Weight/1000); %SS added first hour intake
    
    % sessionType
    varTable.sessionType(varTable.Session<6)=categorical({'PreTraining'});
    varTable.sessionType(varTable.Session>5 & varTable.Session<16)=categorical({'Training'});
    varTable.sessionType(varTable.Session>15 & varTable.Session<26)=categorical({'Extinction'});
    varTable.sessionType(varTable.Session==26)=categorical({'Reinstatement'});
    % varTable.sessionType(varTable.Session>31)=categorical({'Progressive Ratio'}); % SS note - need for BE?
    
    % slideSession - Slide Days for looks
    if varTable.Session<6
        varTable.slideSession=varTable.Session;
    elseif varTable.Session>5 && varTable.Session<16
        varTable.slideSession=varTable.Session+1;
    elseif varTable.Session>15 && varTable.Session<26
        varTable.slideSession=varTable.Session+2;
    elseif varTable.Session>25
        varTable.slideSession=varTable.Session+3;
    end
    
    % allLatency
    % SS added first hour
    varTable.Latency(varTable.Latency==0)=NaN; % Fix Latency where no presses occur
    rewLP=eventTime(eventCode==13);
    hour_allLat = [];
    if ~isempty(rewLP)
        for j=1:height(rewLP) % SS removed requirement for this to have at least 3 rewLPs, because needed all and last latencies for later calcs in place of regular latency
            if ~isempty(HE(find(HE>rewLP(j))))
                allLat(j,1) = HE(find(HE>rewLP(j),1,'first'))-rewLP(j); % Latency from every lever press to next head entry
                latHEidx(j,1) = find(HE>rewLP(j),1,'first'); % Index of first head entries following each lever press
                if rewLP(j) < 3600
                    hour_allLat = [hour_allLat; allLat(j,1)];
                end
            else
                allLat(j,1) = NaN;
                latHEidx(j,1) = NaN;
            end
        end
        varTable.allLatency = nanmean(allLat);
        varTable.hourAllLatency = nanmean(hour_allLat);
    else
        varTable.allLatency = NaN;
        varTable.hourAllLatency = NaN;
    end

    % lastLatency 
    % SS added first hour
    if ~isempty(rewLP)
        uniHEidx=unique(latHEidx); % Unique first head entries after lever presses SS note: why isn't this used for allLat too?
        hour_lastLat = [];
        for j = 1:height(uniHEidx)
            HEidx=find(latHEidx==uniHEidx(j),1,'last'); % Which is the last lever press before a head entry
            if ~isempty(HE(latHEidx(HEidx)))
                lastLat(j,1)=HE(latHEidx(HEidx))-rewLP(HEidx); % If two LPs are followed by the same HE, only calculate latency from the last one).
            else
                lastLat(j,1) = NaN;
            end
            if rewLP(HEidx) < 3600
                hour_lastLat = [hour_lastLat; lastLat(j,1)];
            end
        end
        varTable.lastLatency = nanmean(lastLat);
        varTable.hourLastLatency = nanmean(hour_lastLat);
    else
        varTable.lastLatency = NaN;
        varTable.hourLastLatency = NaN;
    end
    
    % itiActiveLever & hourActiveLever
    % 22  = Active Lev press
    actLP=eventTime(eventCode==22);
    varTable.itiActiveLever=varTable.ActiveLever-varTable.TotalInfusions; % Which Active LPs were not rewarded
    varTable.hourActiveLever=sum(actLP<3600); % Active Lever Presses in First Hour 
    
    % itiInactiveLever & hourActiveLaver
    % 23  = Inactive Lev press
    inLP=eventTime(eventCode==23);
    
    % SS hack for absent inactive lever event codes...
    % HARDCODED TO READ RIGHT LEVER AS INACTIVE LEVER
    if isempty(inLP)
        inLP = eventTime(eventCode==1);
        % if isempty(inLP)
        %     disp(['no inactive lever press data for ', char(varTable.TagNumber), ' on ', char(varTable.Date)]);
        % end
    end
    
    inITI=[]; % Initialize in case there are no inLPs
    
    for j = 1:height(rewLP)
        inITI(j,1)=sum(inLP>rewLP(j) & inLP<(rewLP(j)+10)); % Which inactive LPs occur in the 10s following a reward (the ITI)
    end
    
    varTable.itiInactiveLever=sum(inITI);
    varTable.hourInactiveLever=sum(inLP<3600);% Inactive Lever Presses in First Hour 
    varTable.eventCode={eventCode};
    varTable.eventTime={eventTime};
end