local luniaBotWindow
local walkEvent = nil
local stop = false
local isAttacking = false
local isFollowing = false
local currentTargetPositionId = 1
local waypoints = {}
local autowalkTargetPosition = waypoints[currentTargetPositionId]
local atkLoopId = nil
local atkSpellLoopId = nil
local itemHealingLoopId = nil
local spellHealingLoopId = nil
local manaLoopId = nil
local hasteLoopId = nil
local buffLoopId = nil
local hasLured = false
local shieldLoopId = nil
local player = nil
local healingItem
local manaItem
local add_direction_button;

function init()
	luniaBotWindow = g_ui.displayUI('luniaBot')
	if luniaBotWindow then
		luniaBotWindow:lower()
		if g_configs.getSettings():getValue('layout') == 'Default' or g_configs.getSettings():getValue('layout') == 'Mobile' then
			luniaBotWindow:setHeight(740)
		end
		
		add_direction_button = luniaBotWindow:recursiveGetChildById('add_direction_button');
		add_direction_button:setTooltip(tr("Face the direction you want to put waypoint at."))
		
		player = g_game.getLocalPlayer()
		waypointList = luniaBotWindow.waypoints
		luniaBotWindow:hide()  
		luniaBotButton = modules.client_topmenu.addLeftGameButton('luniaBotButton', tr('LuniaBot'), '/otcbot-master/luniabot', toggle)
		atkButton = luniaBotWindow.autoAttack
		walkButton = luniaBotWindow.walking
		healthSpellButton = luniaBotWindow.AutoHealSpell	
		healthItemButton = luniaBotWindow.AutoHealItem
		manaRestoreButton = luniaBotWindow.AutoMana
		atkSpellButton = luniaBotWindow.AtkSpell
		manaTrainButton = luniaBotWindow.ManaTrain
		hasteButton = luniaBotWindow.AutoHaste
		buffButton = luniaBotWindow.AutoBuff
		lureButton = luniaBotWindow.LureMonsters
		manaShieldButton = luniaBotWindow.AutoManaShield
		healthItemButton.onCheckChange = autoHealPotion
		manaRestoreButton.onCheckChange = autoManaPotion
		luniaBotWindow.AtkSpellText.onTextChange = saveBotText
		luniaBotWindow.HealSpellText.onTextChange = saveBotText
		luniaBotWindow.HealthSpellPercent.onTextChange = saveBotText
		luniaBotWindow.HealItem.onTextChange = saveBotText
		luniaBotWindow.HealItemPercent.onTextChange = saveBotText
		luniaBotWindow.ManaItem.onTextChange = saveBotText
		luniaBotWindow.ManaPercent.onTextChange = saveBotText
		luniaBotWindow.WptName.onTextChange = saveBotText
		luniaBotWindow.ManaSpellText.onTextChange = saveBotText
		luniaBotWindow.ManaTrainPercent.onTextChange = saveBotText
		luniaBotWindow.HasteText.onTextChange = saveBotText
		luniaBotWindow.BuffText.onTextChange = saveBotText
		luniaBotWindow.LureMinimum.onTextChange = saveBotText
		luniaBotWindow.LureMaximum.onTextChange = saveBotText
		connect(g_game, { onGameStart = logIn})
	end
end


function saveBotText()
	g_settings.set(player:getName() .. " " .. luniaBotWindow:getFocusedChild():getId(), luniaBotWindow:getFocusedChild():getText())
end



function logIn()
	player = g_game.getLocalPlayer()

		--Fixes default values
	if(luniaBotWindow.HealItem:getText()) == ",266" then
		luniaBotWindow.HealItem:setText('266')
	end
	if(luniaBotWindow.ManaItem:getText()) == ",268" then
		luniaBotWindow.ManaItem:setText('268')
	end

	local checkButtons = {atkButton, healthSpellButton, walkButton, healthItemButton, manaRestoreButton, atkSpellButton, manaTrainButton, hasteButton, manaShieldButton, buffButton, lureButton}
	for _,checkButton in ipairs(checkButtons) do
		checkButton:setChecked(g_settings.getBoolean(player:getName() .. " " .. checkButton:getId()))
	end

	local textBoxes = {luniaBotWindow.ManaSpellText, luniaBotWindow.HasteText, luniaBotWindow.AtkSpellText, luniaBotWindow.HealSpellText, luniaBotWindow.HealthSpellPercent, luniaBotWindow.HealItem, luniaBotWindow.HealItemPercent, luniaBotWindow.ManaItem, luniaBotWindow.ManaPercent, luniaBotWindow.WptName, luniaBotWindow.BuffText, luniaBotWindow.LureMinimum, luniaBotWindow.LureMaximum, luniaBotWindow.ManaTrainPercent}
	for _,textBox in ipairs(textBoxes) do
		local storedText = g_settings.get(player:getName() .. " " .. textBox:getId())
		if (string.len(storedText) >= 1) then
			textBox:setText(g_settings.get(player:getName() .. " " .. textBox:getId()))
		end
	end
end



function terminate()
	luniaBotWindow:destroy()
	luniaBotButton:destroy()
end

function disable()
	luniaBotButton:hide()
end

function hide()
	luniaBotWindow:hide()
end

function show()
	luniaBotWindow:show()
	luniaBotWindow:raise()
	luniaBotWindow:focus()
end


function toggleLoop(key)
	--maybe remove some looops, for example healing could be done through events
	local bts = {
		autoAttack = {atkLoop, atkLoopId},
		walking = {walkToTarget, walkEvent},
		AutoHealSpell = {healingSpellLoop, spellHealingLoopId},
		AtkSpell = {atkSpellLoop, atkSpellLoopId},
		ManaTrain = {manaTrainLoop, manaLoopId},
		AutoHaste = {hasteLoop, hasteLoopId},
		AutoManaShield = {shieldLoop, shieldLoopId},
		AutoBuff = {buffLoop, buffLoopId},
	}

	local btn = luniaBotWindow:getChildById(key)
	local bt = bts[btn:getId()]
	if (btn:isChecked()) then
		g_settings.set(player:getName() .. " " .. btn:getId(), true)
		if (bt) then
			bt[1]()
		end
	else
		g_settings.set(player:getName() .. " " .. btn:getId(), false)
		if (bt) then
			removeEvent(bt[2])
		end
	end
end

function autoHealPotion()
	healingItem = healthItemButton:isChecked()
	g_settings.set(player:getName() .. " " .. healthItemButton:getId(), healthItemButton:isChecked())
	if (healingItem and itemHealingLoopId == nil) then
		itemHealingLoop()
	end
	if (not manaItem and not healingItem) then
		removeEvent(itemHealingLoopId)
		itemHealingLoopId = nil
	end
end

function autoManaPotion()
	manaItem = manaRestoreButton:isChecked()
	g_settings.set(player:getName() .. " " .. manaRestoreButton:getId(), manaRestoreButton:isChecked())
	if (manaItem and itemHealingLoopId == nil) then
		itemHealingLoop()
	end
	if (not manaItem and not healingItem) then
		removeEvent(itemHealingLoopId)
		itemHealingLoopId = nil
	end
end

function toggle()
	if luniaBotWindow:isVisible() then
		hide()
	else
		show()
	end
end

local function getDistanceBetween(p1, p2)
    return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

function Player.canAttack(self)
    return not self:hasState(16384) and not g_game.isAttacking()
end

function Creature:canReach(creature)
	--function from candybot
	if not creature then
		return false
	end
	local myPos = self:getPosition()
	local otherPos = creature:getPosition()


	local neighbours = {
		{x = 0, y = -1, z = 0},
		{x = -1, y = -1, z = 0},
		{x = -1, y = 0, z = 0},
		{x = -1, y = 1, z = 0},
		{x = 0, y = 1, z = 0},
		{x = 1, y = 1, z = 0},
		{x = 1, y = 0, z = 0},
		{x = 1, y = -1, z = 0}
	}

	for k,v in pairs(neighbours) do
	local checkPos = {x = myPos.x + v.x, y = myPos.y + v.y, z = myPos.z + v.z}
	if (myPos and otherPos) then
		if postostring(otherPos) == postostring(checkPos) then
			return true
		end
	end

	local steps, result = g_map.findPath(otherPos, checkPos, 30, 0)
		if result == PathFindResults.Ok then
			return true
		end
	end
	return false
end

function atkLoop()
	local currentTarget = g_game.getAttackingCreature()
	local pPos = player:getPosition()
	if pPos then --solves some weird bug, in the first login, the players position is nil in the start for some reason
		local findnewTarget = false
		if currentTarget then
			if (currentTarget:isPlayer()) then
				atkLoopId = scheduleEvent(atkLoop, 1000)
				return
			end
			if currentTarget:getPosition() and lureButton:isChecked() then
				local targetRange = player:getVocation() == 1 and 2 or 5
				if (getDistanceBetween(pPos, currentTarget:getPosition()) >= targetRange) then
					findnewTarget = true
				end
			end
		end
		if (player:canAttack() or findnewTarget) then
			local maxRange = 12
			local closestMob = nil
			local closestMobHealth = 0
			if pPos then --solves some weird bug, in the first login, the players position is nil in the start for some reason
				local creatures = g_map.getSpectatorsInRange(pPos, false, 6, 6)
				for _, creature in ipairs(creatures) do
					cPos = creature:getPosition()
					local distanceDifference = getDistanceBetween(pPos, cPos)
					if creature:isMonster() and player:canReach(creature) then
						if (maxRange > distanceDifference) then
							maxRange = distanceDifference
							closestMob = creature
							closestMobHealth = creature:getHealthPercent()
						end
						if (distanceDifference == maxRange and closestMobHealth > creature:getHealthPercent()) then
							closestMob = creature
							closestMobHealth = creature:getHealthPercent()
						end
					end
				end
				if (closestMob and closestMob ~= currentTarget) then
					g_game.attack(closestMob)
				end
				atkLoopId = scheduleEvent(atkLoop, 200)
				return
			end
		end
	end
	atkLoopId = scheduleEvent(atkLoop, 200)
	return
end

function fag()
	local label = g_ui.createWidget('Waypoint', waypointList)
	local pos = player:getPosition()
	label:setText(pos.x .. "," .. pos.y .. "," .. pos.z)
	table.insert(waypoints, pos)
end

function add_direction()
	local dir = Directions;
	local player_dir = player:getDirection();
	local player_pos = player:getPosition();
	
	if player_dir == dir.North then
		player_pos.y = player_pos.y - 1;
	elseif player_dir == dir.South then
		player_pos.y = player_pos.y + 1;
	elseif player_dir == dir.West then
		player_pos.x = player_pos.x - 1;
	else
		player_pos.x = player_pos.x + 1;
	end
	
	g_ui.createWidget('Waypoint', waypointList):setText(player_pos.x .. "," .. player_pos.y .. "," .. player_pos.z);
	table.insert(waypoints, player_pos);
end


function remove_last()
	local windex = #waypoints
	waypoints[windex] = nil;

	autowalkTargetPosition = currentTargetPositionId
	autowalkTargetPosition = waypoints[currentTargetPositionId]

	local child = waypointList:getLastChild()
	waypointList:removeChild(child)
end

local speedTable = {
	[1] = 600,
	[2] = 550,
	[3] = 450,
	[4] = 350,
	[5] = 220,
	[6] = 160,
}
function walkToTarget()
	--found this function made by gesior, i edited it abit, maybe there's better ways to walk?
	local runSpeed = 100
	local nearbyMonsters = 0
	local luring = lureButton:isChecked()
	local atkEnabled = atkButton:isChecked()
	autowalkTargetPosition = waypoints[currentTargetPositionId]
    if not g_game.isOnline() then
		walkEvent = scheduleEvent(walkToTarget, 500)
        return
	end

	local playerPos = player:getPosition()
	if (playerPos and autowalkTargetPosition) then
		if (getDistanceBetween(playerPos, autowalkTargetPosition) >= 150) then
			currentTargetPositionId = currentTargetPositionId + 1
			if (currentTargetPositionId > #waypoints) then
				currentTargetPositionId = 1
			end
			walkEvent = scheduleEvent(walkToTarget, 1500)
			return 
		end
	end
	-- if g_game.getLocalPlayer():getStepTicksLeft() > 0 then
	-- 	walkEvent = scheduleEvent(walkToTarget, g_game.getLocalPlayer():getStepTicksLeft())
    --     return
	-- end
	if g_game.isAttacking() and not luring  or isFollowing then
		walkEvent = scheduleEvent(walkToTarget, 100)
        return
	end

	if (luring and atkEnabled) then
		local nearbyCreatures = g_map.getSpectatorsInRange(playerPos, false, 6, 6)
		for _,nearbyCreature in ipairs(nearbyCreatures) do
			if nearbyCreature:isMonster() and player:canReach(nearbyCreature) then
				nearbyMonsters = nearbyMonsters + 1
			end
		end
		if (nearbyMonsters >= 1) then
			local lureMax = tonumber(luniaBotWindow.LureMaximum:getText()) or 6
			if (nearbyMonsters >= lureMax) then
				walkEvent = scheduleEvent(walkToTarget, 200)
				return
			end
		end
	end

	if (not walkButton:isChecked()) then
		walkEvent = scheduleEvent(walkToTarget, 200)
	end

	if not autowalkTargetPosition then
		currentTargetPositionId = currentTargetPositionId + 1
		if (currentTargetPositionId > #waypoints) then
			currentTargetPositionId = 1
		end
		walkEvent = scheduleEvent(walkToTarget, 100)
		return
	end
    -- fast search path on minimap (known tiles)
    steps, result = g_map.findPath(g_game.getLocalPlayer():getPosition(), autowalkTargetPosition, 5000, 0)
	if result == PathFindResults.Ok then
        g_game.walk(steps[1], true)
	elseif result == PathFindResults.Position then
		currentTargetPositionId = currentTargetPositionId + 1
		if (currentTargetPositionId > #waypoints) then
			currentTargetPositionId = 1
		end
    else
        -- slow search path on minimap, if not found, start 'scanning' map
        steps, result = g_map.findPath(g_game.getLocalPlayer():getPosition(), autowalkTargetPosition, 25000, 1)
        if result == PathFindResults.Ok then
            g_game.walk(steps[1], true)
		else
			-- can't reach?  so skip this waypoint. improve this somehow
			currentTargetPositionId = currentTargetPositionId + 1
		end
    end
	-- limit steps to 10 per second (100 ms between steps)
	if (luring and atkEnabled) then
		if (nearbyMonsters >= 1 and nearbyMonsters) then
			local speedSetting = tonumber(luniaBotWindow.LureMinimum:getText()) or 4
			if (speedSetting > 6) then
				speedSetting = 6
			end
			if (speedSetting < 1) then
				speedSetting = 1
			end
			local speed = speedTable[speedSetting]
			runSpeed = speed or 350
		end
	end
    walkEvent = scheduleEvent(walkToTarget, math.max(runSpeed, g_game.getLocalPlayer():getStepTicksLeft()))
end



function saveWaypoints() 
	local saveText = '{\n';
	for _,v in pairs(waypoints) do
		saveText = saveText .. '{x = '.. v.x ..', y = ' .. v.y .. ', z = ' .. v.z .. '},\n'
	end
	saveText = saveText .. '}'
	local file = io.open('modules/otcbot-master/wpts/'.. luniaBotWindow.WptName:getText() ..'.lua', 'w')
	file:write(saveText)
	file:close()
end

function loadWaypoints() 
	local f = io.open('modules/otcbot-master/wpts/'.. luniaBotWindow.WptName:getText() ..'.lua', "rb")
    local content = f:read("*all")
	f:close()
	clearWaypoints()
	waypoints = loadstring("return "..content)()
	for _,v in ipairs(waypoints) do
		local labelt = g_ui.createWidget('Waypoint', waypointList)
		labelt:setText(v.x .. "," .. v.y .. "," .. v.z)
	end
end

function clearWaypoints()
	waypoints = {}
	autowalkTargetPosition = currentTargetPositionId
	autowalkTargetPosition = waypoints[currentTargetPositionId]
	clearLabels()
	walkButton:setChecked(false)
end

function clearLabels()
	while waypointList:getChildCount() > 0 do
		local child = waypointList:getLastChild()
		waypointList:destroyChildren(child)
	end
end


function itemHealingLoop()
	-- Prioritize healing item instead of mana
	if healingItem then
		local hpItemPercentage = tonumber(luniaBotWindow.HealItemPercent:getText())
		local hpItemId = tonumber(luniaBotWindow.HealItem:getText())
		if (player:getHealth() <= (player:getMaxHealth() * (hpItemPercentage/100))) then
			g_game.useInventoryItemWith(hpItemId, player)
			-- maybe don't try using mana after healing item?
		end
	end
	if manaItem then
		local manaItemPercentage = tonumber(luniaBotWindow.ManaPercent:getText())
		local manaItemId = tonumber(luniaBotWindow.ManaItem:getText())
		if (player:getMana() <= (player:getMaxMana() * (manaItemPercentage/100))) then
			g_game.useInventoryItemWith(manaItemId, player)
		end
	end
	itemHealingLoopId = scheduleEvent(itemHealingLoop, 200)
end



function healingSpellLoop()
	local healingSpellPercentage = tonumber(luniaBotWindow.HealthSpellPercent:getText())
	local healSpell = luniaBotWindow.HealSpellText:getText()
	if (not player) then
		spellHealingLoopId = scheduleEvent(healingSpellLoop, 200)
	end
	if (player:getHealth() <= (player:getMaxHealth() * (healingSpellPercentage/100))) then
		g_game.talk(healSpell)
	end
	spellHealingLoopId = scheduleEvent(healingSpellLoop, 200)
end

function manaTrainLoop()
	local manaTrainPercentage = tonumber(luniaBotWindow.ManaTrainPercent:getText())
	local manaSpell = luniaBotWindow.ManaSpellText:getText()
	if (not player) then
		manaLoopId = scheduleEvent(manaTrainLoop, 1000)
	end
	if (player:getMana() >= (player:getMaxMana() * (manaTrainPercentage/100))) then
		g_game.talk(manaSpell)
	end
	manaLoopId = scheduleEvent(manaTrainLoop, 1000)
end

function hasteLoop()
	local hasteSpell = luniaBotWindow.HasteText:getText()
	if (not player) then
		hasteLoopId = scheduleEvent(hasteLoop, 1000)
	end
	if (player:getHealth() >= (player:getMaxHealth() * (70/100))) then -- only cast when healthy
		if (not player:hasState(PlayerStates.Haste, player:getStates())) then
			g_game.talk(hasteSpell)
		end
	end
	hasteLoopId = scheduleEvent(hasteLoop, 1000)
end

function buffLoop()
	local buffSpell = luniaBotWindow.BuffText:getText()
	if (not player) then
		buffLoopId = scheduleEvent(buffLoop, 1000)
	end
	if (player:getHealth() >= (player:getMaxHealth() * (70/100))) then -- only cast when healthy
		if (not player:hasState(PlayerStates.PartyBuff, player:getStates())) then
			g_game.talk(buffSpell)
		end
	end
	buffLoopId = scheduleEvent(buffLoop, 1000)
end

function shieldLoop()
	if (not player) then
		shieldLoopId = scheduleEvent(shieldLoop, 1000)
	end
	if (not player:hasState(PlayerStates.ManaShield, player:getStates())) then
		g_game.talk('utamo vita')
	end
	shieldLoopId = scheduleEvent(shieldLoop, 200)
end

function atkSpellLoop()
	local atkSpell = luniaBotWindow.AtkSpellText:getText()
	if (g_game.isAttacking()) then
		g_game.talk(atkSpell)
	end
	atkSpellLoopId = scheduleEvent(atkSpellLoop, 250)
end