-- thanks the coed author gmacro and Lombra's support
-- http://www.wowinterface.com/forums/showthread.php?t=55021

local ADDON = ...
local fontName, fontHeight, fontFlags = GameFontNormal:GetFont()
local BUTTON_HEIGHT = fontHeight + 4
local BUTTON_SPACING = 0
local MENU_BUFFER = 10
local MENU_SPACING = 1
local MENU_WIDTH_EMPTY = 190
local MENU_WIDTH = 450
local LOOT_REPORT = {}
local LOOT_CFG = {
		maxloots = 20,    
		-- menu shows max limit
		myself = false,   
		-- show or not show player self loots
		minquality = 3,   
		-- minquality comes from http://wowwiki.wikia.com/wiki/API_TYPE_Quality
		equiponly = true
		-- show equiponly items
	}
-- colors 
local string_format = string.format
local string_find = string.find
local string_sub = string.sub
local function color(String)
	if not UnitExists(String) then 
		return string.format("\124cffff0000%s\124r", String) 
	end
	local _, class = UnitClass(String)
	local color = _G["RAID_CLASS_COLORS"][class]
	return string.format("\124cff%02x%02x%02x%s\124r", color.r*255, color.g*255, color.b*255, String)
end
-- main frame settings
local Menu = CreateFrame("Frame", "LootWhisper", UIParent)
	Menu:Hide()
	Menu:SetClampedToScreen(true)
	Menu:SetFrameStrata("DIALOG")
	Menu:SetMovable(true)
	Menu:SetToplevel(true)
	Menu:SetUserPlaced(true)
	Menu:EnableMouse(true)
	Menu:RegisterEvent('PLAYER_LOGIN')
	Menu:RegisterEvent('CHAT_MSG_LOOT')
	Menu:RegisterForDrag("LeftButton")
	Menu:SetScript("OnDragStart", Menu.StartMoving)
	Menu:SetScript("OnDragStop", Menu.StopMovingOrSizing)
	Menu:SetBackdrop({
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		title = true, titleSize = 32, edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	})
	Menu:SetBackdropColor(.75, .75, .75)
	Menu:SetBackdropBorderColor(0, 1, 1, 1)
	--tinsert(UISpecialFrames, Menu:GetName())
-- menu button and text
local resetClose = CreateFrame("Button", "resetClose", Menu, "UIPanelCloseButton")
	resetClose:SetSize(24, 24)
	resetClose:SetPoint("TOPRIGHT", -5, -5)
local header_desc = Menu:CreateFontString()
	header_desc:SetPoint("TOPLEFT", Menu, "TOPLEFT", MENU_BUFFER, -MENU_BUFFER)
	header_desc:SetFont(fontName, fontHeight)
	header_desc:SetTextColor(0, 1, 1, 1)
	header_desc:SetText("毛装助手" .. "     " .. "8.0" .. "     " .. "LIVE版")
local click_desc = Menu:CreateFontString()
	click_desc:SetPoint("BOTTOMLEFT", Menu, "BOTTOMLEFT", MENU_BUFFER, MENU_BUFFER)
	click_desc:SetFont(fontName, fontHeight)
	click_desc:SetTextColor(0, 1, 1, 1)
	click_desc:SetText("单击装备:毛装")

local reset_desc = Menu:CreateFontString()
	reset_desc:SetPoint("BOTTOMRIGHT", Menu, "BOTTOMRIGHT", -MENU_BUFFER, MENU_BUFFER)
	reset_desc:SetFont(fontName, fontHeight)
	reset_desc:SetTextColor(0, 1, 1, 1)
	reset_desc:SetText("单击关闭:重置")
----------------------------------------------------------- functions -----------------------------------------------------------
-- initMenu
local function initMenu()
	LOOT_REPORT = {}
	for index = 1, LOOT_CFG["maxloots"] do
		Menu[index]:SetText("")
		Menu[index]:Hide()
	end
	Menu:SetSize(MENU_WIDTH, (MENU_BUFFER * 5) + (fontHeight * 3) + MENU_SPACING + ((BUTTON_HEIGHT + BUTTON_SPACING) - BUTTON_SPACING))
	resetClose:SetScript('OnMouseUp', function(self, button) 		 
		if button == "LeftButton" then 
			initMenu()
			Menu:Hide()
		elseif button == "RightButton" then 
			initMenu()
		end 
	end)
end

-- click button shows whisper msg
local function Button_OnClick(self, button, down)
	if button == "RightButton" or "LeftButton" then
		SendChatMessage("大佬你好，这东西 " .. LOOT_REPORT[self.index]["loot"] .. " 你要吗？不要的话，我跪求一发，非常感谢！", "WHISPER", nil, LOOT_REPORT[self.index]["player"])				
	end
end
-- cursor enter button shows tips
local function Button_OnEnter(self, button)
	ShowUIPanel(GameTooltip)
	if not GameTooltip:IsShown() then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	GameTooltip:SetHyperlink(LOOT_REPORT[self.index]["loot"])
end
-- cursor leave button hide tips
local function Button_OnLeave()
	local focus = GetMouseFocus() or WorldFrame
	if focus ~= GameTooltip and focus:GetParent() ~= GameTooltip then
		GameTooltip:Hide()
	end
end
-- main loot msg settings
Menu:SetScript("OnEvent", function(self, event, ...) 
	if event == "PLAYER_LOGIN" then	
		Menu:UnregisterEvent(event)
		for index = 1, LOOT_CFG["maxloots"] do
			local button = CreateFrame("Button", nil, Menu)		
			if index ~= 1 then
				button:SetPoint("TOPLEFT", Menu[index - 1], "BOTTOMLEFT", 0, -BUTTON_SPACING)
			else
				button:SetPoint("TOPLEFT", header_desc, "BOTTOMLEFT", 0, -MENU_BUFFER)
			end
			button:SetPoint("RIGHT", -MENU_BUFFER, 0)
			button:SetHeight(BUTTON_HEIGHT)
			button:SetNormalFontObject("GameFontNormal")
			button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			button.index = index
			button:RegisterForClicks("AnyDown")
			button:SetScript("OnClick", Button_OnClick)
			button:SetScript("OnEnter", Button_OnEnter)
			button:SetScript("OnLeave", Button_OnLeave)
			local text = button:CreateFontString(ADDON .. "btn_font", nil, "GameFontNormal")
			text:SetAllPoints()
			text:SetJustifyH("LEFT")
			text:SetJustifyV("MIDDLE")
			text:SetTextColor(1, 1, 1, 1)
			button:SetFontString(text)
			Menu[index] = button
		end
	initMenu()
	elseif event == "CHAT_MSG_LOOT" then
		local lootstring, _, _, _, player = ...
		local itemLink = string.match(lootstring,"|%x+|Hitem:.-|h.-|h|r")
		local itemString = string.match(itemLink, "item[%-?%d:]+")
		local _, _, quality, _, _, class, subclass, _, equipSlot, texture, _, ClassID, SubClassID = GetItemInfo(itemString)
		local Disabled = 0		
		if LOOT_CFG["myself"] == false and UnitName("player") == player then 
			Disabled = 1
		end
		if LOOT_CFG["minquality"] > quality then 
			Disabled = 1
		end
		if LOOT_CFG["equiponly"] == true and (ClassID <= 1 or ClassID > 4 ) then 
			Disabled = 1
		end
		if LOOT_CFG['equiponly'] == true then
			local playerItemLink = GetInventoryItemLink('player', 1)
			if playerItemLink then 
				local itemType = select(7, GetItemInfo(playerItemLink))
				if subclass == itemType and (ClassID <= 1 or ClassID > 4) == false then 
					Disabled = 0
				else
					if subclass == 'Miscellaneous' and (ClassID <= 1 or ClassID > 4) == false then 
						Disabled = 0
					else
						Disabled = 1
					end
					if equipSlot == 'INVTYPE_CLOAK' then 
						Disabled = 0
					else
						if equipSlot == 'INVTYPE_WEAPON' then 
							Disabled = 0
						else 
							Disabled = 1
						end
					end
				end
			end
		end
		if player and Disabled == 0 then 
			if #LOOT_REPORT >= LOOT_CFG["maxloots"] then 
				table.remove(LOOT_REPORT, 1)
			end
			LOOT_REPORT[#LOOT_REPORT + 1] = {
				player = player,
				loot = itemLink,
				ilv	= GetDetailedItemLevelInfo(itemLink),
				slot = _G[equipSlot] or subclass
				}				
			local h,m = GetGameTime()
			local numButtons = #LOOT_REPORT
			for index = 1, numButtons do	
				Menu[index]:SetText( h .. ":".. m .. " " .. color(LOOT_REPORT[index]["player"]) .. " " ..  LOOT_REPORT[index]["loot"] .. "<" .. LOOT_REPORT[index]["ilv"].. "-" .. LOOT_REPORT[index]["slot"].. ">")					
				Menu[index]:Show()
				Menu:SetSize(MENU_WIDTH, (MENU_BUFFER * 5) + (fontHeight * 3) + MENU_SPACING + ((BUTTON_HEIGHT + BUTTON_SPACING) * numButtons - BUTTON_SPACING))
			end
			Menu:Show()
		end	
	end
end)
-- short cmd code '/lw'
SLASH_LOOTWHISPER1 = "/lw"
SlashCmdList["LOOTWHISPER"] = function(args) 
	if not Menu:IsShown() then
		Menu:ClearAllPoints()
		Menu:SetPoint('CENTER',0,0)
		Menu:Show()
	end
end
