-- thanks the coed author gmacro and Lombra's support
-- http://www.wowinterface.com/forums/showthread.php?t=55021
local L = LibStub("AceLocale-3.0"):GetLocale("LootWhisper")
local ADDON = ...
-- default font style
local fontName, fontHeight, fontFlags = GameFontNormal:GetFont()
-- button height
local buttonHeight = fontHeight + 4
-- report tbl
local LOOT_REPORT = {}
-- loot filter
local LOOT_CFG = {
		maxloots = 20,    
		-- menu shows max limit
		myself = true,   
		-- show or not show player self loots
		minquality = 0,   
		-- minquality comes from http://wowwiki.wikia.com/wiki/API_TYPE_Quality
		equiponly = false,
		-- show equiponly items
		samearmor = true,
		-- same armor
		ilvFilter = true
		-- itemLevel filter
	}
-- colors 
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
	-- default hide
	Menu:Hide()
	-- couldnt drag out of the game window
	Menu:SetClampedToScreen(true)
	-- default strata
	Menu:SetFrameStrata("DIALOG")
	-- enable move
	Menu:SetMovable(true)
	-- enable mouse interact
	Menu:EnableMouse(true)
	-- register events
	Menu:RegisterEvent('PLAYER_LOGIN')
	Menu:RegisterEvent('CHAT_MSG_LOOT')
	-- register drag
	Menu:RegisterForDrag("LeftButton")
	Menu:SetScript("OnDragStart", Menu.StartMoving)
	Menu:SetScript("OnDragStop", Menu.StopMovingOrSizing)
	-- background info
	Menu:SetBackdrop({
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		title = true, titleSize = 32, edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	})
	Menu:SetBackdropColor(.75, .75, .75)
	Menu:SetBackdropBorderColor(0, 1, 1, 1)
	-- initMenu
local function initMenu()
	LOOT_REPORT = {}
	for index = 1, LOOT_CFG["maxloots"] do
		Menu[index]:SetText("")
		Menu[index]:Hide()
	end
	Menu:SetSize(450, (10 * 5) + (fontHeight * 3) + 1 + ((buttonHeight + 0) - 0))
end
-- menu button and text
local reset_Close = CreateFrame("Button", "resetClose", Menu, "UIPanelCloseButton")
	reset_Close:SetSize(24, 24)
	reset_Close:SetPoint("TOPRIGHT", -5, -5)
		resetClose:SetScript('OnMouseUp', function(self, button) 		 
		if button == "LeftButton" then 
			initMenu()
			Menu:Hide()
		elseif button == "RightButton" then 
			initMenu()
		end 
	end)
-- title text
local header_text = Menu:CreateFontString()
	header_text:SetPoint("TOPLEFT", Menu, "TOPLEFT", 10, -10)
	header_text:SetFont(fontName, fontHeight)
	header_text:SetTextColor(0, 1, 1, 1)
	header_text:SetText(L["LootWhisper"])
-- patch text
local patch_text = Menu:CreateFontString()
	patch_text:SetPoint("TOP", Menu, "TOP", 0, -10)
	patch_text:SetFont(fontName, fontHeight)
	patch_text:SetTextColor(0, 1, 1, 1)
	patch_text:SetText('8.3.0')
-- vision text
local vision_text = Menu:CreateFontString()
	vision_text:SetPoint("TOPRIGHT", Menu, "TOPRIGHT", -30, -10)
	vision_text:SetFont(fontName, fontHeight)
	vision_text:SetTextColor(0, 1, 1, 1)
	vision_text:SetText(L["RETAIL"])
-- bottom left text
local click_text = Menu:CreateFontString()
	click_text:SetPoint("BOTTOMLEFT", Menu, "BOTTOMLEFT", 10, 10)
	click_text:SetFont(fontName, fontHeight)
	click_text:SetTextColor(0, 1, 1, 1)
	click_text:SetText(L["ClickForIt"])
-- bottom right text
local reset_text = Menu:CreateFontString()
	reset_text:SetPoint("BOTTOMRIGHT", Menu, "BOTTOMRIGHT", -15, 10)
	reset_text:SetFont(fontName, fontHeight)
	reset_text:SetTextColor(0, 1, 1, 1)
	reset_text:SetText(L["CloseReset"])
-- click button shows whisper msg
local function Button_OnClick(self, button, down)
	if button == "RightButton" or "LeftButton" then
		SendChatMessage(L["Hi, Do U need the"] .. LOOT_REPORT[self.index]["loot"] .. L["? I really need it if U dont, ty!"], "WHISPER", nil, LOOT_REPORT[self.index]["player"])				
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
				button:SetPoint("TOPLEFT", Menu[index - 1], "BOTTOMLEFT", 0, -0)
			else
				button:SetPoint("TOPLEFT", header_text, "BOTTOMLEFT", 0, -10)
			end
			button:SetPoint("RIGHT", -10, 0)
			button:SetHeight(buttonHeight)
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
		if itemLink then 
			local itemString = string.match(itemLink, "item[%-?%d:]+")
			local _, _, quality, _, _, class, subclass, _, equipSlot, texture, _, ClassID, SubClassID = GetItemInfo(itemString)
			-- itemfilter
			local Disabled = 0
			if LOOT_CFG["myself"] == false and UnitInParty('player') == false then 
				Disabled = 1
			end
			if LOOT_CFG['equiponly'] == true and (ClassID <= 1 or ClassID > 4 or ClassID == 3) then
				Disabled = 1
			end
			if LOOT_CFG["minquality"] > quality then 
				Disabled = 1
			end
			if LOOT_CFG['ilvFilter'] == true then
				for i = 1, 17 do
					local itemLinkPlayer = GetInventoryItemLink('player', i)
					if itemLinkPlayer then
						local itemInfoPlayer = {GetItemInfo(itemLinkPlayer)} 
						local itemInfo = {GetItemInfo(itemString)}
						--local 1, 2, 3, 4, p, m = Name, Ilv, Slot, ItemType, player, msg
						for kp1, vp1 in pairs(itemInfoPlayer)do
							for k1, v1 in pairs(itemInfo) do
								if kp1 == 1  and k1 == 1 then
									if vp1 ~= v1 then 
										for kp3, vp3 in pairs(itemInfoPlayer) do
											for k3, v3 in pairs(itemInfo) do
												if kp3 == 9 and k3 == 9 then 
													if vp3 == v3 then
														for kp2, vp2 in pairs(itemInfoPlayer) do
															for k2, v2 in pairs(itemInfo) do
																if kp2 == 4 and k2 == 4 then
																	if vp2 - 5 > v2 then
																		Disabled = 1
																		--print(kp2..'-'..vp2..'-'..k2..'-'..v2..'-'..Disabled)
																	end
																end
															end
														end
													end
												end
											end
										end
									elseif vp1 == v1 then
										for kp2, vp2 in pairs(itemInfoPlayer) do
											for k2, v2 in pairs(itemInfo) do
												if kp2 == 4 and k2 == 4 then
													if vp2 > v2 then 
														Disabled = 1
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
			if LOOT_CFG['samearmor'] == true then
				local slotsTab = {
					'INVTYPE_HEAD',
					'INVTYPE_SHOULDER',
					'INVTYPE_CHEST',
					'INVTYPE_WAIST',
					'INVTYPE_LEGS',
					'INVTYPE_FEET',
					'INVTYPE_WRIST',
					'INVTYPE_HAND'
				}	
				local playerItemLink = GetInventoryItemLink('player', 1)
				if playerItemLink then 
					local playerItemType = select(7, GetItemInfo(playerItemLink))
					if subclass ~= playerItemType then 
						for _, v in pairs(slotsTab) do
							if v == equipSlot then 
								Disabled = 1
							end
						end
					end
				end
			end	
			-- filter test
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
					Menu:SetSize(450, (10 * 5) + (fontHeight * 3) + 1 + ((buttonHeight + 0) * numButtons - 0))
				end
				Menu:Show()
			end
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
	local t0 = L['Welcome to use the LootWhisper, there is some tips you need to know:']
	local t1 = L['EQUIPMENTS - Left/Right Clicked will send the whisper message to the owner.']
	local t2 = L['RESET AND CLOESED - It will reset and close the menu if you leftclicked the close button.']
	local t3 = L['RESET ONLY - It only reset if you rightclicked the close button.']
	print( t0..'\n'..'|cFF00FFFF'..t1..'\n'..t2..'\n'..t3..'|r')
end
--end
