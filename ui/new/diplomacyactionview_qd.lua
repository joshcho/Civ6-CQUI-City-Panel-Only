--[[
230413 This file is taken from Quick Deals mod
It provides compatibility between CQUI-Lite and Quick Deals
DiplomacyActionView is getting really crowded... The flow for XP2 is as follows.
(*) marks the context // files not used
Base:
- DiplomacyActionView
XP1:
- DiplomacyActionView_Expansion1
		=> include DiplomacyActionView
XP2
- (*)DiplomacyActionView_Expansion2
		=> include DiplomacyActionView_Expansion1
CQUI-Lite @200
- diplomacyactionview_CQUI
- diplomacyactionview_CQUI_basegame
- diplomacyactionview_CQUI_expansion1
- (*)diplomacyactionview_CQUI_expansion2
		=> include DiplomacyActionView_Expansion2
		=> include diplomacyactionview_CQUI
BLI @520
- DiplomacyActionView_Expansion1_BLI
- (*)DiplomacyActionView_Expansion2_BLI
		=> if CQUI then include diplomacyactionview_CQUI_expansion2
		=> else DiplomacyActionView_Expansion2
QD @99999
- (*)diplomacyactionview_qd.lua
		=> if BLI then DiplomacyActionView_Expansion2_BLI
		=> if CQUI then diplomacyactionview_CQUI_expansion2
		=> else DiplomacyActionView_Expansion2
--]]

-- =================================================================================
-- Import base file
-- =================================================================================
local files = {
	-- XP2
	"DiplomacyActionView_Expansion2_BLI",
	"diplomacyactionview_CQUI_expansion2",
    "DiplomacyActionView_Expansion2",
	-- XP1
	"DiplomacyActionView_Expansion1_BLI",
	"diplomacyactionview_CQUI_expansion1",
    "DiplomacyActionView_Expansion1",
	-- BASE
	"diplomacyactionview_CQUI_basegame",
    "DiplomacyActionView"
}

for _, file in ipairs(files) do
    include(file);
    if Initialize then
        print("QD_DiplomacyActionView loading " .. file .. " as base file");
        break;
    end
end

-- =================================================================================
-- Cache base functions
-- =================================================================================
QD_BASE_LateInitialize = LateInitialize;
QD_BASE_OnDiplomacyStatement = OnDiplomacyStatement;

-- ===========================================================================
local m_QDPopupShowing = false;

-- ===========================================================================
function OnDiplomacyStatement(fromPlayer:number, toPlayer:number, kVariants:table)
    -- print("OnDiplomacyStatement: ", kVariants.StatementType, kVariants.RespondingToDealAction, kVariants.DealAction, kVariants.SessionID, fromPlayer, toPlayer, m_QDPopupShowing);
    if m_QDPopupShowing then
        local statementTypeName = DiplomacyManager.GetKeyName(kVariants.StatementType);
        if statementTypeName == "MAKE_DEAL" then
            return;
        else
            LuaEvents.QD_OnSurpriseSession(kVariants.SessionID);
            LuaEvents.QD_CloseDealPopupSilently();
        end
    end
    QD_BASE_OnDiplomacyStatement(fromPlayer, toPlayer, kVariants);
end

function OnDealPopupOpened()
    m_QDPopupShowing = true;
end

function OnDealPopupClosed()
    m_QDPopupShowing = false;
end

function LateInitialize()
	QD_BASE_LateInitialize();

    Events.DiplomacyStatement.Remove(QD_BASE_OnDiplomacyStatement);
    Events.DiplomacyStatement.Add(OnDiplomacyStatement);
    
    LuaEvents.QDDealPopup_Closed.Add(OnDealPopupClosed);
    LuaEvents.QDDealPopup_Opened.Add(OnDealPopupOpened);
end

print("CQUI-Lite: loaded diplomacyactionview_qd.lua");
