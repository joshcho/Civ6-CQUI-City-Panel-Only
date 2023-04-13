-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_OnActivateIntelRelationshipPanel = OnActivateIntelRelationshipPanel;
BASE_AutoSizeGrid = AutoSizeGrid;


-- ===========================================================================
--  CQUI modified OnActivateIntelGossipHistoryPanel functiton
--  Trim the gossip message
--  Integration of Simplified Gossip mod
--  230413 no longer needed; ipairs are working from 0 and messages are already trimmed
-- ===========================================================================


-- ===========================================================================
--  CQUI modified AutoSizeGrid functiton
-- ===========================================================================
function AutoSizeGrid(gridControl:table, labelControl:table, padding:number, minSize:number)
	BASE_AutoSizeGrid(gridControl, labelControl, 15, 30); -- values adjusted to the new frame and font size
end


-- ===========================================================================
--  CQUI modified OnActivateIntelRelationshipPanel functiton
--  Added a total row to the relationship detail tab
-- ===========================================================================
function OnActivateIntelRelationshipPanel(relationshipInstance : table)
    local intelSubPanel = relationshipInstance;

    -- Check to make sure the XML wasn't overwritten by another mod
    local cquiXmlActive:boolean = true;
    cquiXmlActive = cquiXmlActive and (intelSubPanel.RelationshipScore ~= nil);
    cquiXmlActive = cquiXmlActive and (intelSubPanel.RelationshipReasonsTotal ~= nil);
    cquiXmlActive = cquiXmlActive and (intelSubPanel.RelationshipReasonsTotalScorePerTurn ~= nil);
    if not cquiXmlActive then
        BASE_OnActivateIntelRelationshipPanel(intelSubPanel);
        return
    end

    -- Get the selected player's Diplomactic AI
    local selectedPlayerDiplomaticAI = ms_SelectedPlayer:GetDiplomaticAI();
    -- What do they think of us?
    local iState = selectedPlayerDiplomaticAI:GetDiplomaticStateIndex(ms_LocalPlayerID);
    local kStateEntry = GameInfo.DiplomaticStates[iState];

    local relationshipScore = kStateEntry.RelationshipLevel;
    local relationshipScoreText = Locale.Lookup("{1_Score : number #,###.##;#,###.##}", relationshipScore);

    if (relationshipScore > 50) then
        relationshipScoreText = "[COLOR_Civ6Green]" .. relationshipScoreText .. "[ENDCOLOR]";
    elseif (relationshipScore < 50) then
        relationshipScoreText = "[COLOR_Civ6Red]" .. relationshipScoreText .. "[ENDCOLOR]";
    else
        relationshipScoreText = "[COLOR_Grey]" .. relationshipScoreText .. "[ENDCOLOR]";
    end

    intelSubPanel.RelationshipScore:SetText(relationshipScoreText);

    local toolTips = selectedPlayerDiplomaticAI:GetDiplomaticModifiers(ms_LocalPlayerID);
    local reasonsTotalScore = 0;
    local hasReasonEntries = false;

    if (toolTips) then
        table.sort(toolTips, function(a,b) return a.Score > b.Score; end);

        for i, tip in ipairs(toolTips) do
            local score = tip.Score;
            reasonsTotalScore = reasonsTotalScore + score;

            if (score ~= 0) then
                hasReasonEntries = true;
            end
        end
    end

    local reasonsTotalScoreText = Locale.Lookup("{1_Score : number +#,###.##;-#,###.##}", reasonsTotalScore);
    if (reasonsTotalScore > 0) then
        reasonsTotalScoreText = "[COLOR_Civ6Green]" .. reasonsTotalScoreText .. "[ENDCOLOR]";
    elseif (reasonsTotalScore < 0) then
        reasonsTotalScoreText = "[COLOR_Civ6Red]" .. reasonsTotalScoreText .. "[ENDCOLOR]";
    else
        reasonsTotalScoreText = "[COLOR_Grey]" .. reasonsTotalScoreText .. "[ENDCOLOR]";
    end

    if (hasReasonEntries) then
        intelSubPanel.RelationshipReasonsTotal:SetHide(false);
        intelSubPanel.RelationshipReasonsTotalScorePerTurn:SetText(reasonsTotalScoreText);
    else
        intelSubPanel.RelationshipReasonsTotal:SetHide(true);
    end

    BASE_OnActivateIntelRelationshipPanel(intelSubPanel);
end

print("CQUI-Lite: loaded diplomacyactionview_CQUI.lua");
