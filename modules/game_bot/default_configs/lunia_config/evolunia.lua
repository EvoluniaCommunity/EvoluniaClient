local walk_button = modules.game_luniabot.walkButton;
 
function hasEffect(tile, effect)
  for i, fx in ipairs(tile:getEffects()) do
    if fx:getId() == effect then
      return true
    end
  end
  return false
end

macro(500, "Collect essences", function()
  for _, tile in pairs(g_map.getTiles(posz())) do
    if (hasEffect(tile, 56)) then
      walk_button:setChecked(false);
      autoWalk(tile:getPosition(), 100, { ignoreNonPathable = true });
      schedule(2000, function() walk_button:setChecked(true); end);
    end
  end
end, toolsTab)

onAddThing(function(tile, thing)
  if thing:isItem() and thing:getId() == 2129 then
    local pos = tile:getPosition().x .. "," .. tile:getPosition().y .. "," .. tile:getPosition().z
    if not storage[pos] or storage[pos] < now then
      storage[pos] = now + 20000
    end
    tile:setTimer(storage[pos] - now)
  end
end)

macro(2000, "Open monsterboxes",  function()
  for i, tile in ipairs(g_map.getTiles(posz())) do
    for u,item in ipairs(tile:getItems()) do
      if (item and item:getId() == 9586) then
        walk_button:setChecked(false);
        g_game.use(item)
        schedule(2000, function() walk_button:setChecked(true); end);
        return
      end
    end  
  end
end)

macro(1000, "Collect monsterflames",  function()
  for i, tile in ipairs(g_map.getTiles(posz())) do
      for u,item in ipairs(tile:getItems()) do
          if (item:getId() == 21463) then
            walk_button:setChecked(false);
            autoWalk(tile:getPosition(), 100, {ignoreNonPathable = true})
            schedule(2000, function() walk_button:setChecked(true); end);
          end
        end
    end
end)

macro(1000, "Enter Invasion Portals",  function()
  for i, tile in ipairs(g_map.getTiles(posz())) do
      for u,item in ipairs(tile:getItems()) do
          if (item:getId() == 25058) then
              walk_button:setChecked(false);
              autoWalk(tile:getPosition(), 100, {ignoreNonPathable = true})
              schedule(3000, function() walk_button:setChecked(true); end);
          end
        end
    end
end)

local oldTarget
macro(100, "Hold Target",  function()
    if g_game.isAttacking() then
        oldTarget = g_game.getAttackingCreature()
    end
    if (oldTarget and oldTarget:getPosition()) then
      if (not g_game.isAttacking() and getDistanceBetween(pos(), oldTarget:getPosition()) <= 9) then
          g_game.attack(oldTarget)
      end
    end
end)




macro(1000, "Auto Activate Follow", function() g_game.setChaseMode(1) end)