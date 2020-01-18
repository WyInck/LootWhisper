-- thanks the coed author gmacro and Lombra's support
-- http://www.wowinterface.com/forums/showthread.php?t=55021
local L = LibStub('AceLocale-3.0'):GetLocale('LootWhisper')
local LootWhisper = LibStub('AceAddon-3.0'):NewAddon('LootWhisper')
local fName, fHeight = GameFontNormal:GetFont()
local btnHeight = fHeight + 4
local fx, fy = 400, btnHeight * 5 
local Loot = {}
local function color(String)
	if not UnitExists(String) then 
		return string.format('\124cffff0000%s\124r', String) 
	end
	local _, class = UnitClass(String)
	local str = _G['RAID_CLASS_COLORS'][class]
	return string.format('\124cff%02x%02x%02x%s\124r', str.r * 255, str.g * 255, str.b * 255, String)
end
local f = CreateFrame('Frame', 'LootWhisper', UIParent)
	f:Hide()
	f:SetClampedToScreen(true)
	f:SetFrameStrata('DIALOG')
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag('LeftButton')
	f:RegisterEvent('PLAYER_LOGIN')
	f:RegisterEvent('CHAT_MSG_LOOT')
	f:SetScript('OnDragStart', f.StartMoving)
	f:SetScript('OnDragStop', f.StopMovingOrSizing)
	f:SetBackdrop({
		bgFile = 'Interface/DialogFrame/UI-DialogBox-Background',
		edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
		title = true, 
		titleSize = 32, 
		edgeSize = 16,
		insets = { 
			left = 3, 
			right = 3, 
			top = 3, 
			bottom = 3 
		}
	})
	f:SetBackdropColor(0, 0, 0, 1)
	f:SetBackdropBorderColor(0, 1, 1, 1)
local function Init()
	Loot = {}
	for i = 1, config.MAX_LOOTS do
		f[i]:Hide()
	end
	f:SetSize(fx, fy)
end
local resClose = CreateFrame('Button', 'resClose', f, 'UIPanelCloseButton')
	resClose:SetSize(24, 24)
	resClose:SetPoint('TOPRIGHT', -5, -5)
	resClose:SetScript('OnMouseUp', function(self, button) 		 
		if button == 'LeftButton' then 
			Init()
			f:Hide()
		elseif button == 'RightButton' then 
			Init()
		end 
	end)
local title = f:CreateFontString()
	title:SetPoint('TOPLEFT', 10, -10)
	title:SetFont(fName, fHeight)
	title:SetTextColor(0, 1, 1, 1)
	title:SetText(L['LootWhisper 8.3.0 Retail'])
f:SetScript('OnEvent', function(self, event, ...) 
	if event == 'PLAYER_LOGIN' then	
		f:UnregisterEvent(event)
		for i = 1, config.MAX_LOOTS do
			local btn = CreateFrame('Button', nil, f)		
			if i ~= 1 then
				btn:SetPoint('TOPLEFT', f[i - 1], 'BOTTOMLEFT', 0, -0)
			else
				btn:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -10)
			end
			btn:SetPoint('RIGHT', 0, 0)
			btn:SetHeight(btnHeight)
			btn:SetNormalFontObject('GameFontNormal')
			btn:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
			btn.i = i
			btn:RegisterForClicks('AnyDown')
			btn:SetScript('OnClick', function()
					if button == 'RightButton' or 'LeftButton' then
						SendChatMessage(L['Hi, Do U need the'] .. Loot[i]['info'] .. L['? I really need it if U dont, ty!'], 'WHISPER', nil, Loot[i]['player'])				
					end
			end)
			btn:SetScript('OnEnter', function(self)
					ShowUIPanel(GameTooltip)
					if not GameTooltip:IsShown() then
						GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
					end
					GameTooltip:SetHyperlink(Loot[i]['info'])
			end)
			btn:SetScript('OnLeave', function()
					local focus = GetMouseFocus() or WorldFrame
					if focus ~= GameTooltip and focus:GetParent() ~= GameTooltip then
						GameTooltip:Hide()
					end
			end)
			local txt = btn:CreateFontString(nil, nil, 'GameFontNormal')
			txt:SetAllPoints()
			txt:SetJustifyH('LEFT')
			txt:SetJustifyV('MIDDLE')
			btn:SetFontString(txt)
			btn:Hide()
			f[i] = btn
		end
		f:SetSize(fx, fy)
	elseif event == 'CHAT_MSG_LOOT' then
		local strLoot, _, _, _, player = ...
		if not player then return end
		local itemLink = string.match(strLoot,'|%x+|Hitem:.-|h.-|h|r')
		if itemLink then 
			local itemString = string.match(itemLink, 'item[%-?%d:]+')
			local _, _, quality, _, _, class, subClass, _, equipSlot, _, _, classId,  subClassId = GetItemInfo(itemString)
			local limit = 1
			if config.SHOW_SELVES == false and UnitInParty('player') == false then 
				limit = 0
			end
			if config.EQUIP_ONLY == true and (classId <= 1 or classId > 4 or classId == 3) then
				limit = 0
			end
			if config.MIN_QUALITY > quality then 
				limit = 0
			end
			if config.ILV_FILTER == true then
				for i = 1, 17 do
					local itemLinkPlayer = GetInventoryItemLink('player', i)
					if itemLinkPlayer then
						local itemInfoPlayer = {GetItemInfo(itemLinkPlayer)} 
						local itemInfo = {GetItemInfo(itemString)}
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
																		limit = 0
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
														limit = 0
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
			if config.SAME_ARMOR == true then
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
					if subClass ~= playerItemType then 
						for _, v in pairs(slotsTab) do
							if v == equipSlot then 
								limit = 0
							end
						end
					end
				end
			end
			if player and limit == 1 then
				if #Loot >= config.MAX_LOOTS then 
					table.remove(Loot, 1)
				end
				Loot[#Loot + 1] = {
					player = player,
					info = itemLink,
					ilv	= GetDetailedItemLevelInfo(itemLink),
					slot = _G[equipSlot] or subClass
					}				
				local h, m = GetGameTime()
				local loots = #Loot
				for i = 1, loots do
					f[i]:SetText(h ..':'.. m .. ' ' .. color(Loot[i]['player']) .. ' ' .. Loot[i]['info'] .. '<' .. Loot[i]['ilv'] .. '-' .. Loot[i]['slot'] .. '>')					
					f[i]:Show()
					f:SetSize(fx, btnHeight * loots + fy / 2)
				end
				f:Show()
			end
		end
	end
end)
SLASH_LOOTWHISPER1 = '/lw'
SlashCmdList['LOOTWHISPER'] = function()
	if not f:IsShown() then
		f:ClearAllPoints()
		f:SetPoint('TOP', 0, 0)
		f:Show()
	end
	local t0 = L['Welcome to use the LootWhisper, there is some tips you need to know:']
	local t1 = L['EQUIPMENTS - Left/Right Clicked will send the whisper message to the owner.']
	local t2 = L['RESET AND CLOESED - It will reset and close the menu if you leftclicked the close button.']
	local t3 = L['RESET ONLY - It only reset if you rightclicked the close button.']
	print( t0..'\n'..'|cFF00FFFF'..t1..'\n'..t2..'\n'..t3..'|r')
end
