----------------
---AutoFollow---
----------------
--Novaspark-Arugal OCE (classic) / Venomisto-Frostmourne OCE (retail).
--https://www.curseforge.com/members/venomisto/projects
--Spams /follow <name> every 2 seconds.
--Use /af playername to start it, or just /af with a player target selected.
--Use /af stop to end it.

AutoFollow = LibStub("AceAddon-3.0"):NewAddon("AutoFollow");
local L = LibStub("AceLocale-3.0"):GetLocale("AutoFollow");
if (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	AutoFollow.isClassic = true;
elseif (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
	AutoFollow.isTBC = true;
elseif (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) then
	AutoFollow.isRetail = true;
end

function AutoFollow:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AFOptions", AutoFollow.optionDefaults, "Default");
    LibStub("AceConfig-3.0"):RegisterOptionsTable("AutoFollow", AutoFollow.options);
	self.AFOptions = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoFollow", "AutoFollow");
end

local controlled, afEnabled, followTarget, casting;
local function startControl()
	controlled = true;
end

local function stopControl()
	controlled = false;
end

hooksecurefunc("TurnLeftStop", function(...)
	if (not IsPlayerMoving()) then
		stopControl();
	end
end)

hooksecurefunc("TurnRightStop", function(...)
	if (not IsPlayerMoving()) then
		stopControl();
	end
end)

local f = CreateFrame("Frame");
f:SetScript("OnKeyDown", function(self, key)
	if (afEnabled) then
		local f, f2 = GetBindingKey("MOVEFORWARD");
		local b, b2 = GetBindingKey("MOVEBACKWARD");
		local l, l2 = GetBindingKey("TURNLEFT");
		local r, r2 = GetBindingKey("TURNRIGHT");
		if (key == f or key == f2 or key == b or key == b2 or key == l
				or key == l2 or key == r or key == r2) then
			startControl();
		end
	end
end)
f:SetPropagateKeyboardInput(true);

local function castInfo()
	if (UnitCastingInfo) then
		return UnitCastingInfo("player");
	elseif (CastingInfo) then
		return CastingInfo();
	end
end

local function channelInfo()
	if (UnitChannelInfo) then
		return UnitChannelInfo("player");
	elseif (ChannelInfo) then
		return ChannelInfo();
	end
end

local f = CreateFrame("Frame");
f:RegisterEvent("UNIT_AURA");
f:RegisterEvent("UNIT_SPELLCAST_START");
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
f:RegisterEvent("UNIT_SPELLCAST_STOP");
f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
f:RegisterEvent("PLAYER_STOPPED_MOVING");
local isDrinking;
f:SetScript("OnEvent", function(self, event, ...)
	if (event == "UNIT_AURA") then
		local found;
		for i = 1, 32 do
			local name = UnitBuff("player", i);
			if (name and (name == L["Drink"] or name == L["Food"] or name == L["Refreshment"])) then
				found = true;
			end
		end
		if (found) then
			if (afEnabled and not isDrinking) then
				--Drinking started, cancel current follow incase leader moves.
				if (AutoFollow.db.global.stayWhileDrinkEat) then
					FollowUnit("player");
				end
			end
			isDrinking = true;
		else
			if (afEnabled and isDrinking) then
				--Drinking stopped, refollow.
				FollowUnit(followTarget, true);
			end
			isDrinking = false;
		end
	elseif (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START") then
		local unit, GUID, spellID = ...;
		if (unit == "player") then
			--If there is actual cast info and it's not an instantcast spell.
			if (castInfo() or channelInfo()) then
				casting = true;
			end
			if (afEnabled and casting and AutoFollow.db.global.pauseCasting) then
				--Cast started, cancel current follow incase leader moves;
				FollowUnit("player");
			end
		end
	elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_STOP"
			or event == "UNIT_SPELLCAST_CHANNEL_STOP") then
		local unit, GUID, spellID = ...;
		if (unit == "player") then
			casting = false;
			if (afEnabled) then
				--Requires a delay (You are too busy to follow), with a backup for ping.
				C_Timer.After(0.1, function()
					FollowUnit(followTarget, true);
				end)
				C_Timer.After(0.3, function()
					FollowUnit(followTarget, true);
				end)
				C_Timer.After(0.6, function()
					FollowUnit(followTarget, true);
				end)
			end
		end
	elseif (event == "PLAYER_STOPPED_MOVING") then
		stopControl();
	end
end)

local function isDrinkingOrEating()
	for i = 1, 32 do
		local name = UnitBuff("player", i);
		if (name and (name == L["Drink"] or name == L["Food"] or name == L["Refreshment"])) then
			return true;
		end
	end
end

local function doAutoFollow()
	if (afEnabled) then
		C_Timer.After(AutoFollow.db.global.interval, function()
			if (afEnabled) then
				if ((not isDrinkingOrEating() or not AutoFollow.db.global.pauseDrinkEat)
						and (not casting or not AutoFollow.db.global.pauseCasting)
						and (not controlled or not AutoFollow.db.global.pauseControlled)
						and (not IsShiftKeyDown() or not AutoFollow.db.global.pauseShift)) then
					FollowUnit(followTarget, true);
				end
			end
			doAutoFollow();
		end)
	end
end

local function startAutoFollow(msg)
	print("|cffff6900AutoFollowing " .. msg .. " every " .. AutoFollow.db.global.interval .. " seconds. (Type \"/af stop\" to stop)");
	FollowUnit(msg, true); --/run FollowUnit(Ambiguate("Rentok-Thaurissan", "none"), true)
	afEnabled = true;
	followTarget = msg;
	doAutoFollow();
end

local function printHelp(msg)
	print("|cffff6900AutoFollow Help:");
	print("|cffff6900Config \"/af config\".");
	print("|cffff6900Type \"/af playername\" to start following every 2 seconds.");
	print("|cffff6900Or just type \"/af\" with a player targeted.");
	print("|cffff6900To stop type \"/af stop\".");
end

SLASH_AFOLLOW1, SLASH_AFOLLOW2 = '/autofollow', '/af';
function SlashCmdList.AFOLLOW(msg, editBox)
	if (msg == "") then
		if (UnitIsPlayer("target")) then
			if (UnitName("target") == UnitName("player")) then
				print("|cffff6900You can't follow yourself.");
				return;
			else
				if (AutoFollow.isRetail) then
					local name, realm = UnitFullName("target");
					if (realm) then
						startAutoFollow(name .. "-" .. realm);
					else
						startAutoFollow(name);
					end
				elseif (AutoFollow.isTBC) then
					startAutoFollow(UnitName("target"));
				else
					startAutoFollow(UnitName("target"));
				end
				return;
			end
		elseif UnitExists("target") then
			print("|cffff6900Current target is not a player, target a player first or type \"/af playername\".");
			return;
		end
		print("|cffff6900You need to specify a target name to follow. Example: /autofollow Joe");
	elseif (msg == "help") then
		printHelp();
	elseif (msg == "stop" or msg == "end" or msg == "cancel" or msg == "off") then
		afEnabled = false;
		print("|cffff6900Stopping autofollow.");
	elseif (msg == "config" or msg == "options" or msg == "option" or msg == "menu") then
		InterfaceOptionsFrame_OpenToCategory("AutoFollow");
		InterfaceOptionsFrameAddOnsListScrollBar:SetValue(0);
		InterfaceOptionsFrame_OpenToCategory("AutoFollow");
	else
		if (string.lower(msg) == string.lower(UnitName("player"))) then
			print("|cffff6900You can't follow yourself.");
			return;
		end
		if (AutoFollow.isClassic and string.find(msg, "%-")) then
			print("|cffff6900You can't specify realm name in classic.");
			return;
		end
		if (AutoFollow.isTBC and string.find(msg, "%-")) then
			print("|cffff6900You can't specify realm name in TBC.");
			return;
		end
		startAutoFollow(msg);
    end
end

AutoFollow.options = {
	name = "",
	handler = AutoFollow,
	type = 'group',
	args = {
		titleText = {
			type = "description",
			name = "        |cffff6900AutoFollow (v" .. GetAddOnMetadata("AutoFollow", "Version") .. ")",
			fontSize = "large",
			order = 1,
		},
		authorText = {
			type = "description",
			name = "|TInterface\\AddOns\\AutoFollow\\Media\\logo32:32:32:0:20|t |cFF9CD6DEby Novaspark-Arugal\n",
			fontSize = "medium",
			order = 2,
		},
		topHeader = {
			type = "description",
			name = "|CffDEDE42Options (You can type /af config to open this)\n\n",
			fontSize = "medium",
			order = 3,
		},
		pauseDrinkEat = {
			type = "toggle",
			name = L["pauseDrinkEatTitle"],
			desc = L["pauseDrinkEatDesc"],
			order = 10,
			get = "getPauseDrinkEat",
			set = "setPauseDrinkEat",
		},
		pauseCasting = {
			type = "toggle",
			name = L["pauseCastingTitle"],
			desc = L["pauseCastingDesc"],
			order = 12,
			get = "getPauseCasting",
			set = "setPauseCasting",
		},
		pauseControlled = {
			type = "toggle",
			name = L["pauseControlledTitle"],
			desc = L["pauseControlledDesc"],
			order = 13,
			get = "getPauseControlled",
			set = "setPauseControlled",
		},
		pauseShift = {
			type = "toggle",
			name = L["pauseShiftTitle"],
			desc = L["pauseShiftDesc"],
			order = 14,
			get = "getPauseShift",
			set = "setPauseShift",
		},
		stayWhileDrinkEat = {
			type = "toggle",
			name = L["stayWhileDrinkEatTitle"],
			desc = L["stayWhileDrinkEatDesc"],
			order = 15,
			get = "getStayWhileDrinkEat",
			set = "setStayWhileDrinkEat",
		},
		interval = {
			type = "range",
			name = L["intervalTitle"],
			desc = L["intervalDesc"],
			order = 16,
			get = "getInterval",
			set = "setInterval",
			min = 0.5,
			max = 10,
			softMin = 0.5,
			softMax = 10,
			step = 0.5,
			width = 2,
		},
	},
};

------------------------
--Load option defaults--
------------------------
AutoFollow.optionDefaults = {
	global = {
		pauseDrinkEat = true,
		pauseCasting = true,
		pauseControlled = true,
		pauseShift = true,
		stayWhileDrinkEat = false,
		interval = 2,
	},
};

-------------------------------------------------------
--Below are the set and get functions for all options--
-------------------------------------------------------

--Pause while drinking or eating.
function AutoFollow:setPauseDrinkEat(info, value)
	self.db.global.pauseDrinkEat = value;
end

function AutoFollow:getPauseDrinkEat(info)
	return self.db.global.pauseDrinkEat;
end

--Stay while drinking or eating.
function AutoFollow:setStayWhileDrinkEat(info, value)
	self.db.global.stayWhileDrinkEat = value;
end

function AutoFollow:getStayWhileDrinkEat(info)
	return self.db.global.stayWhileDrinkEat;
end

--Pause while casting.
function AutoFollow:setPauseCasting(info, value)
	self.db.global.pauseCasting = value;
end

function AutoFollow:getPauseCasting(info)
	return self.db.global.pauseCasting;
end

--Pause while moving.
function AutoFollow:setPauseControlled(info, value)
	self.db.global.pauseControlled = value;
end

function AutoFollow:getPauseControlled(info)
	return self.db.global.pauseControlled;
end

--Pause while shift down.
function AutoFollow:setPauseShift(info, value)
	self.db.global.pauseShift = value;
end

function AutoFollow:getPauseShift(info)
	return self.db.global.pauseShift;
end

--Follow interval.
function AutoFollow:setInterval(info, value)
	self.db.global.interval = value;
end

function AutoFollow:getInterval(info)
	return self.db.global.interval;
end