local addonName, addon = ...
local L = addon.L

if not tdBag2 then
  return
end

if not tdBag2.RegisterPlugin then
  return print(L['You must update tdBag2 to use BoE'])
end

local _G = _G
local UIParent = UIParent
local BankButtonIDToInvSlotID = BankButtonIDToInvSlotID
local Item = _G.Item

-- You may trade this item with players that were also eligible to loot this item for the next %s.
-- You may sell this item to a vendor within %s for a full refund.
local BIND_TRADE_TIME_REMAINING_CAPTURE = _G.BIND_TRADE_TIME_REMAINING:gsub('%%s', '(.+)')
local REFUND_TIME_REMAINING_CAPTURE = _G.REFUND_TIME_REMAINING:gsub('%%s', '(.+)')
local UNCOMMON = _G.LE_ITEM_QUALITY_UNCOMMON
local UPDATE = _G.TOOLTIP_UPDATE_TIME
local BANK_CONTAINER = _G.BANK_CONTAINER
local ITEM_SOULBOUND_S = _G.ITEM_SOULBOUND
local ITEM_ACCOUNTBOUND_S = _G.ITEM_ACCOUNTBOUND
local ITEM_BNETACCOUNTBOUND_S = _G.ITEM_BNETACCOUNTBOUND

local BindScanner = CreateFrame('GameTooltip', 'tdBag2BoEScaner', UIParent, 'GameTooltipTemplate')
local TimeScanner = CreateFrame('GameTooltip', 'tdBag2BoEScanner2', UIParent, 'GameTooltipTemplate')

local function GetBindTimer(item)
  local bag, slot = item.bag, item.slot
  TimeScanner:SetOwner(UIParent, 'ANCHOR_NONE')
  if bag == BANK_CONTAINER then
    TimeScanner:SetInventoryItem('player', BankButtonIDToInvSlotID(slot))
  else
    TimeScanner:SetBagItem(bag, slot)
  end

  for i = 2, TimeScanner:NumLines() do
    local line = _G['tdBag2BoEScanner2TextLeft' .. i]
    if not line then break end
    local textLeft = line:GetText()
    if not textLeft then break end
    local timeleft = textLeft:match(BIND_TRADE_TIME_REMAINING_CAPTURE)

    if timeleft then
      return timeleft:gsub(' ',''):gsub('(%d+%a)(.*)','%1%+')
    end
  end
end

local function GetRefundTimer(item)
  local bag, slot = item.bag, item.slot
  TimeScanner:SetOwner(UIParent, 'ANCHOR_NONE')
  if bag == BANK_CONTAINER then
    TimeScanner:SetInventoryItem('player', BankButtonIDToInvSlotID(slot))
  else
    TimeScanner:SetBagItem(bag, slot)
  end

  for i = 2, TimeScanner:NumLines() do
    local line = _G['tdBag2BoEScanner2TextLeft' .. i]
    if not line then break end
    local textLeft = line:GetText()
    if not textLeft then break end
    local timeleft = textLeft:match(REFUND_TIME_REMAINING_CAPTURE)

    if timeleft then
      return timeleft:gsub(' ',''):gsub('(%d+%a)(.*)','%1%+')
    end
  end
end

local function GetBindInfo(item)
  local bag, slot = item.bag, item.slot
  BindScanner:SetOwner(UIParent, 'ANCHOR_NONE')
  if bag == BANK_CONTAINER then
    BindScanner:SetInventoryItem('player', BankButtonIDToInvSlotID(slot))
  else
    BindScanner:SetBagItem(bag, slot)
  end

  for i = 2, 6 do
    local line = _G['tdBag2BoEScanerTextLeft' .. i]
    if not line then break end
    local textLeft = line:GetText()
    if not textLeft then break end
    if textLeft:find(ITEM_ACCOUNTBOUND_S) or textLeft:find(ITEM_BNETACCOUNTBOUND_S) then
      return true
    end
    if textLeft:find(ITEM_SOULBOUND_S) then
      local timeleft = GetBindTimer(item)
      if timeleft then
        return false, timeleft
      else
        return true
      end
    end
  end
  return false
end

local timers = {}
local function BindTicker(item)
  timers[item] = true
  if not addon._ticker then
    addon._ticker = C_Timer.NewTicker(10, function()
      for item,v in pairs(timers) do
        local timeleft = GetBindTimer(item)
        if timeleft then
          item.Count:SetText(timeleft)
        else
          item.Count:SetText('')
          item.BindInfo:SetText('')
          timers[item] = nil
        end
      end
    end)
  end
end

local function UpdateItem(item)
  if item.meta:IsCached() then
    return
  end

  if item.BindInfo then
    item.BindInfo:Hide()
  end

  if timers[item] then
    timers[item]=nil
  end

  local _, _, _, quality, _, _, itemLink, _, _, itemID = GetContainerItemInfo(item.bag, item.slot)
  if not itemID or quality < UNCOMMON then return end
  local _, _, _, itemEquipLoc, _, _, _ = GetItemInfoInstant(itemID)
  if not itemEquipLoc or itemEquipLoc == "" then return end
  if not item.BindInfo then
    item.BindInfo = item:CreateFontString()
    item.BindInfo:SetDrawLayer("ARTWORK",1)
    item.BindInfo:SetPoint("TOP",0,-2)
    item.BindInfo:SetFontObject(NumberFont_Outline_Med or NumberFontNormal)
    item.BindInfo:SetShadowOffset(1,-1)
    item.BindInfo:SetShadowColor(0,0,0,.5)
  end
  C_Timer.After(UPDATE, function()
    local isBound, timeleft = GetBindInfo(item)
    if isBound and not timeleft then return end

    item.BindInfo:SetFormattedText('|cffFFFF8F%s|r',(timeleft and L["BoU"] or L["BoE"]))
    if timeleft and item.Count then
      item.Count:SetText(timeleft)
      if not item.Count:IsVisible() then
        item.Count:Show()
      end
      BindTicker(item)
    end
    item.BindInfo:Show()
  end)
end

tdBag2:RegisterPlugin({type = 'Item', update = UpdateItem})
_G[addonName] = addon