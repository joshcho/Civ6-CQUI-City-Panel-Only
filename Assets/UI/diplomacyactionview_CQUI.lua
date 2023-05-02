print("CQUI-Lite: Loading diplomacyactionview_CQUI.lua");

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

function GetFormattedNumber(value: number, treshold: number)
	if treshold == nil then treshold = 0; end
	if value > treshold then return "[COLOR_Civ6Green]"..toPlusMinusString(value).."[ENDCOLOR]"; end
	if value < treshold then return "[COLOR_Civ6Red]"  ..toPlusMinusString(value).."[ENDCOLOR]"; end
	return "[COLOR_Grey]"..toPlusMinusString(value).."[ENDCOLOR]";
end

-- TODO: this table can be created based on DB data, but I am lazy atm...
local m_kStateTransitions: table = {
	DIPLO_STATE_ALLIED       = { Expire = true,  Up = nil,                      Down ="DIPLO_STATE_FRIENDLY" },
	DIPLO_STATE_DECLARED_FRIEND = { Expire = true, Up = "DIPLO_STATE_ALLIED",   Down = "DIPLO_STATE_FRIENDLY" },
	DIPLO_STATE_FRIENDLY     = { Expire = false, Up = "DIPLO_STATE_DECLARED_FRIEND", Down = "DIPLO_STATE_NEUTRAL" },
	DIPLO_STATE_NEUTRAL      = { Expire = false, Up = "DIPLO_STATE_FRIENDLY",   Down = "DIPLO_STATE_UNFRIENDLY" },
	DIPLO_STATE_UNFRIENDLY   = { Expire = false, Up = "DIPLO_STATE_NEUTRAL",    Down = "DIPLO_STATE_DENOUNCED" },
	DIPLO_STATE_DENOUNCED    = { Expire = true,  Up = "DIPLO_STATE_UNFRIENDLY", Down = "DIPLO_STATE_WAR" },
	DIPLO_STATE_WAR          = { Expire = true,  Up = "DIPLO_STATE_UNFRIENDLY", Down = nil },
};

function GetStateTransitionLabels(fromState: number)
    local kState: table = GameInfo.DiplomaticStates[fromState];
	if kState == nil then return nil, nil; end
	
	local upString: string, downString: string = nil, nil; -- nil means 'transition not possible'
	local kTran: table = m_kStateTransitions[kState.StateType];
	if kTran == nil then return nil, nil; end
	
	-- up logic
	if kTran.Up then
		upString = Locale.Lookup( GameInfo.DiplomaticStates[kTran.Up].Name ).."[NEWLINE]";
		local results: table = DB.Query("SELECT * FROM DiplomaticStateTransitions WHERE BaseState = ? AND TransitionState = ? LIMIT 1", kState.StateType, kTran.Up);
		if results[1] then -- there is a possible transition
			local row: table = results[1];
			upString = upString..GetFormattedNumber(row.AllowTransitionMin).." .. "..GetFormattedNumber(row.RequireTransitionMax);
		else -- is it time based?
			if kTran.Expire then upString = upString.."[ICON_Turn]"; end
		end
	end
	
	-- down logic
	if kTran.Down then
		downString = Locale.Lookup( GameInfo.DiplomaticStates[kTran.Down].Name ).."[NEWLINE]";
		local results: table = DB.Query("SELECT * FROM DiplomaticStateTransitions WHERE BaseState = ? AND TransitionState = ? LIMIT 1", kState.StateType, kTran.Down);
		if results[1] then -- there is a possible transition
			local row: table = results[1];
			downString = downString..GetFormattedNumber(row.RequireTransitionMin).." .. "..( row.AllowTransitionMax and GetFormattedNumber(row.AllowTransitionMax) or Locale.Lookup("LOC_WORLDBUILDER_ANY") );
		else -- is it time based?
			if kTran.Expire then downString = downString.."[ICON_Turn]"; end
		end
	end
	
	return downString, upString;
end

function OnActivateIntelRelationshipPanel(intelSubPanel: table)
    -- Check to make sure the XML wasn't overwritten by another mod
    if intelSubPanel.RelationshipDown == nil or intelSubPanel.RelationshipUp == nil then
        BASE_OnActivateIntelRelationshipPanel(intelSubPanel);
        return;
    end

    -- Get the selected player's Diplomactic AI
    local selectedPlayerDiplomaticAI = ms_SelectedPlayer:GetDiplomaticAI();
    -- What do they think of us?
    local iState = selectedPlayerDiplomaticAI:GetDiplomaticStateIndex(ms_LocalPlayerID);
    local relationshipScore = selectedPlayerDiplomaticAI:GetDiplomaticScore(ms_LocalPlayerID);
    intelSubPanel.RelationshipScore:SetText(GetFormattedNumber(relationshipScore)); -- 230502 #31
	
	-- 230502 #31 State transitions info
	local downLabel: string, upLabel: string = GetStateTransitionLabels(iState);
	if downLabel then intelSubPanel.RelationshipDownText:SetText(downLabel); end
	intelSubPanel.RelationshipDown:SetHide(downLabel == nil);
	if upLabel then intelSubPanel.RelationshipUpText:SetText(upLabel); end
	intelSubPanel.RelationshipUp:SetHide(upLabel == nil);

	-- Calculate and display total score from modifiers
    local toolTips: table = selectedPlayerDiplomaticAI:GetDiplomaticModifiers(ms_LocalPlayerID);
    local reasonsTotalScore: number = 0;
    local hasReasonEntries: boolean = false;

    if (toolTips) then
        for _,tip in ipairs(toolTips) do
            reasonsTotalScore = reasonsTotalScore + tip.Score;
            hasReasonEntries = true;
        end
    end

    if (hasReasonEntries) then
        intelSubPanel.RelationshipReasonsTotal:SetHide(false);
        intelSubPanel.RelationshipReasonsTotalScorePerTurn:SetText( GetFormattedNumber(reasonsTotalScore) );
    else
        intelSubPanel.RelationshipReasonsTotal:SetHide(true);
    end

    BASE_OnActivateIntelRelationshipPanel(intelSubPanel);
end

print("CQUI-Lite: Loaded  diplomacyactionview_CQUI.lua OK");
