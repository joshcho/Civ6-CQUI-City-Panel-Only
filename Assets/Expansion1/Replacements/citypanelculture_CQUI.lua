-- ===========================================================================
-- Base File
-- ===========================================================================
include("CityPanelCulture");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnRefresh = OnRefresh;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_ShowCityDetailAdvisor :boolean = false;

function CQUI_OnSettingsUpdate()
    CQUI_ShowCityDetailAdvisor = GameConfiguration.GetValue("CQUI_ShowCityDetailAdvisor") == 1
end

local m_kLoyaltyBreakdownIM:table = InstanceManager:new( "LoyaltyLineInstance", "Top", Controls.LoyaltyBreakdownStack );

-- ===========================================================================
--  CQUI modified OnRefresh functiton
--  Hide 
-- ===========================================================================
function OnRefresh()
    if ContextPtr:IsHidden() then
        return;
    end
    
    local localPlayerID = Game.GetLocalPlayer();
    local pPlayer = Players[localPlayerID];
    if (pPlayer == nil) then
        return;
    end
    local pCity = UI.GetHeadSelectedCity();
    if (pCity == nil) then
        return;
    end

    BASE_CQUI_OnRefresh();

  -- AZURENCY : hide the advisor if option is disabled
  if not Controls.CulturalIdentityAdvisor:IsHidden() then
    Controls.CulturalIdentityAdvisor:SetHide( CQUI_ShowCityDetailAdvisor == false );
  end
  
	-- CQUI Infixo loyalty pressure breakdown
	-- based on https://forums.civfanatics.com/resources/civ-vi-loyalty-guide.27114/
	local tPressureFromCities:table = {}; -- 1:civ id, 2:city id, 3:value
	local pressureLocal:number, pressureForeign:number = 0, 0;
	local cityOwner:number = pCity:GetOwner();

	-- Sum up the pressure from population all the cities
	for _,city in pairs(pCity:GetCulturalIdentity():GetCityIdentityPressures()) do
		local pressure:number = city.IdentityPressureTotal;
		if pressure ~= 0 then
			-- calculate foreign and domestic pressure
			if city.CityOwner == cityOwner then
				pressureLocal = pressureLocal + pressure;
				table.insert(tPressureFromCities, {city.CityOwner, city.CityID, pressure});
			else
				pressureForeign = pressureForeign + pressure; 
				table.insert(tPressureFromCities, {city.CityOwner, city.CityID, -pressure}); -- foreign cities exert negative pressure
			end
		end
	end

	-- Calculate actual loyalty pressure values and sort descending
	local basePressure:number = math.min(pressureLocal, pressureForeign)+ 0.5;
	for _,city in ipairs(tPressureFromCities) do
		city[3] = 10.0 * city[3] / basePressure;
	end
	table.sort(tPressureFromCities, function (a,b) return a[3] > b[3]; end );

	-- summary line
	local totalPressure:number = 10.0 * (pressureLocal-pressureForeign) / basePressure;
	table.insert(tPressureFromCities, {cityOwner, -1, totalPressure});
	
	-- Generate Instances
	m_kLoyaltyBreakdownIM:ResetInstances();
	for _,city in ipairs(tPressureFromCities) do
		local lineInstance:table = m_kLoyaltyBreakdownIM:GetInstance();
		local pPlayerConfig = PlayerConfigurations[city[1]];
		local sCivName = Locale.Lookup(pPlayerConfig:GetCivilizationShortDescription());
		local sCivIcon = "ICON_" .. pPlayerConfig:GetCivilizationTypeName();
		local backColor:number, frontColor:number = UI.GetPlayerColors(city[1]);
		lineInstance.LineBack:SetColor(backColor);
		lineInstance.LineIcon:SetColor(frontColor);
		lineInstance.LineIcon:SetIcon(sCivIcon);
		lineInstance.LineIcon:SetToolTipString(sCivName);
		local cityName:string = "LOC_HUD_CITY_TOTAL";
		if city[2] ~= -1 then 
			cityName = Players[city[1]]:GetCities():FindID(city[2]):GetName();
		end
		cityName = Locale.Lookup(cityName);
		if city[3] > 0 then
			lineInstance.LineTitle:SetText(cityName);
			lineInstance.LineValue:SetText( string.format("%.1f", city[3]) );
		else
			lineInstance.LineTitle:SetText("[COLOR_RED]" .. cityName .. "[ENDCOLOR]");
			lineInstance.LineValue:SetText( string.format("[COLOR_RED]%.1f[ENDCOLOR]", city[3]) );
		end
	end
	
	-- resize
	Controls.LoyaltyBreakdownStack:CalculateSize();
	Controls.LoyaltyBreakdownBox:SetSizeY(Controls.LoyaltyBreakdownStack:GetSizeY() + 10);
end


-- ===========================================================================
function Initialize_CityPanelCulture_CQUI()
    LuaEvents.CityPanelTabRefresh.Remove(BASE_CQUI_OnRefresh);
    Events.GovernorAssigned.Remove( BASE_CQUI_OnRefresh );
    Events.GovernorChanged.Remove( BASE_CQUI_OnRefresh );
    Events.CitySelectionChanged.Remove( BASE_CQUI_OnRefresh );
    Events.CityLoyaltyChanged.Remove( BASE_CQUI_OnRefresh );
    LuaEvents.CityPanelTabRefresh.Add(OnRefresh);
    Events.GovernorAssigned.Add( OnRefresh );
    Events.GovernorChanged.Add( OnRefresh );
    Events.CitySelectionChanged.Add( OnRefresh );
    Events.CityLoyaltyChanged.Add( OnRefresh );

    LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);
end
Initialize_CityPanelCulture_CQUI();