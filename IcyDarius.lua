if GetObjectName(GetMyHero()) ~= "Darius" then return end

local ver = "0.07"

function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/Icesythe7/GOS/master/IcyDarius.lua", SCRIPT_PATH .. "IcyDarius.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    else
        PrintChat("No updates found, IcyDarius version " .. ver .. " Loaded!")
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/Icesythe7/GOS/master/IcyDarius.version", AutoUpdate)

require "OpenPredict"

local rDebuff        = {}
local aaCD           = false
local qCasting       = false
local igniteFound    = false
local summonerSpells = {ignite = {}, flash = {}, heal = {}, barrier = {}, smite = {}}
local skinMeta       = {["Darius"] = {"Classic", "Lord", "Bioforge", "Woad King", "Dunkmaster", "Chroma Pack: Black Iron", "Chroma Pack: Bronze", "Chroma Pack: Copper", "Academy"}}
local attackItems = {
  ["Tiamat"] = {
    itemID = 3077
  },
  ["Titanic Hydra"] = {
    itemID = 3748
  },
  ["Ravenous Hydra"] = {
    itemID = 3074
  },
  ["Youmuu's Ghostblade"] = {
    itemID = 3142
  },
  ["Bilgewater Cutlass"] = {
    itemID = 3144,
    requiresTarget = true,
    spellRange = 550
  },
  ["Hextech Gunblade"] = {
    itemID = 3146,
    requiresTarget = true,
    spellRange = 550
  },
  ["Blade of the Ruined King"] = {
    itemID = 3153,
    requiresTarget = true,
    spellRange = 550
  }
}

DariusMenu = Menu("darius", "Icy Darius")
DariusMenu:SubMenu("Combo", "Combo")
DariusMenu.Combo:Boolean("useItems", "Use Items", true)
DariusMenu.Combo:Boolean("Q", "Use Q", true)
DariusMenu.Combo:Boolean("W", "Use W", true)
DariusMenu.Combo:Boolean("E", "Use Smart E", true)
DariusMenu:SubMenu("Harass", "Harass")
DariusMenu.Harass:Boolean("Q", "Use Q", true)
DariusMenu.Harass:Boolean("W", "Use W", true)
DariusMenu:SubMenu("Laneclear", "Laneclear")
DariusMenu.Laneclear:Boolean("Q", "Use Q", true)
DariusMenu.Laneclear:Boolean("W", "Use W", true)
DariusMenu:SubMenu("ksteal", "Killsteal")
DariusMenu.ksteal:Boolean("R", "Use R", true)
DariusMenu:SubMenu("misc", "Misc")
DariusMenu.misc:DropDown('skin', GetObjectName(myHero).. " Skins", 1, skinMeta[GetObjectName(myHero)], HeroSkinChanger, true)
DariusMenu.misc.skin.callback = function(model) HeroSkinChanger(GetMyHero(), model - 1) PrintChat(skinMeta[GetObjectName(myHero)][model] .." ".. GetObjectName(myHero) .. " Loaded!") end
DariusMenu:SubMenu("draws", "Drawing")
DariusMenu.draws:Boolean("qdraw", "Draw Q", true)
DariusMenu.draws:Boolean("edraw", "Draw E", true)
DariusMenu.draws:Boolean("rdraw", "Draw R", true)
DariusMenu.draws:Boolean("tdraw", "Draw Stack Text", true)
DariusMenu.draws:Boolean("rhpdraw", "Draw R Damage", true)

OnLoad (function()
  if not igniteFound then
      if GetCastName(myHero, SUMMONER_1):lower():find("summonerdot") then
          igniteFound = true
          summonerSpells.ignite = SUMMONER_1
          DariusMenu.ksteal:Boolean("ignite", "Auto Ignite", true)
      elseif GetCastName(myHero, SUMMONER_2):lower():find("summonerdot") then
          igniteFound = true
          summonerSpells.ignite = SUMMONER_2
          DariusMenu.ksteal:Boolean("ignite", "Auto Ignite", true)
      end
  end
end)

OnUpdateBuff (function(unit, buff)
  if not unit or not buff then
    return
  end
  if buff.Name:lower() == "dariushemo" and GetTeam(buff) ~= (GetTeam(myHero)) and myHero.type == unit.type then
        rDebuff[unit.networkID] = buff.Count
    end
end)

OnRemoveBuff (function(unit, buff)
  if not unit or not buff then
    return
  end
  if buff.Name:lower() == "dariushemo" and GetTeam(buff) ~= (GetTeam(myHero)) and myHero.type == unit.type then
        rDebuff[unit.networkID] = 0
    end
end)

OnProcessSpellComplete (function(unit, spell)
  if unit and spell and unit.isMe and spell.name:lower():find("attack") then
        aaCD = true
        DelayAction(function() aaCD = false end, (1/(GetBaseAttackSpeed(myHero) * GetAttackSpeed(myHero))))
    end
end)

OnAnimation (function(unit, action)
  if unit.isMe and action:lower() == "spell1windup" then
    qCasting = true
  elseif unit.isMe and action:lower() == "spell1" then
    qCasting = false
  end
end)

OnTick (function()
  Killsteal()
  if IOW_Loaded then
    if IOW:Mode() == "Combo" then
      Combo()
      Qorb()
    end
    if IOW:Mode() == "Harass" then
      Harass()
      Qorb()
    end
    if IOW:Mode() == "LaneClear" then
      Laneclear()
    end
  elseif DAC_Loaded then
    if DAC:Mode() == "Combo" then
      Combo()
      Qorb()
    end
    if DAC:Mode() == "Harass" then
      Harass()
      Qorb()
    end
    if DAC:Mode() == "LaneClear" then
      Laneclear()
    end
  elseif PW_Loaded then
    if PW:Mode() == "Combo" then
      Combo()
      Qorb()
    end
    if PW:Mode() == "Harass" then
      Harass()
      Qorb()
    end
    if PW:Mode() == "LaneClear" then
      Laneclear()
    end
  elseif GoSWalkLoaded then
    if GoSWalk:GetCurrentMode() == 0 then
        Combo()
        Qorb()
      end
      if GoSWalk:GetCurrentMode() == 1 then
        Harass()
        Qorb()
      end
      if GoSWalk:GetCurrentMode() == 2 then
        Laneclear()
      end
    end
end)

function Combo()
  local target = GetCurrentTarget()
  if ValidTarget(target, 540) and DariusMenu.Combo.E:Value() and not IsInDistance(target, GetRange(myHero)+GetHitBox(myHero)+GetHitBox(target)) and Ready(_E) then
    local Apprehend = { delay = 0.25, speed = math.huge, width = 300, range = 540, angle = 35 }
    local pI = GetConicAOEPrediction(target, Apprehend)
    if pI and pI.hitChance >= 0.25 then
        CastSkillShot(_E, pI.castPos)
      end
    end
  if ValidTarget(target, 255) and not aaCD then
    AttackUnit(target)
  elseif ValidTarget(target, 255) and aaCD and DariusMenu.Combo.W:Value() and Ready(_W) then
    CastSpell(_W)
    aaCD = false
    AttackUnit(target)
  elseif ValidTarget(target, 255) and aaCD and DariusMenu.Combo.useItems:Value() then 
    Items(nil, {["Tiamat"] = true, ["Titanic Hydra"] = true, ["Ravenous Hydra"] = true})
    aaCD = false
    AttackUnit(target)
  elseif ValidTarget(target, 425) and DariusMenu.Combo.Q:Value() and Ready(_Q) then
    CastSpell(_Q)
  end
  if ValidTarget(target, 700) and DariusMenu.Combo.useItems:Value() then
    Items(nil, {["Youmuu's Ghostblade"] = true})
  end
  if ValidTarget(target, 550) and DariusMenu.Combo.useItems:Value() then
    Items(target, {["Bilgewater Cutlass"] = true, ["Hextech Gunblade"] = true, ["Blade of the Ruined King"] = true})
  end
end

function Harass()
  local target = GetCurrentTarget()
  if ValidTarget(target, 255) and not aaCD then
    AttackUnit(target)
  elseif ValidTarget(target, 255) and aaCD and DariusMenu.Harass.W:Value() and Ready(_W) then
    CastSpell(_W)
    aaCD = false
    AttackUnit(target)
  elseif ValidTarget(target, 255) and aaCD and DariusMenu.Combo.useItems:Value() then 
    Items(nil, {["Tiamat"] = true, ["Titanic Hydra"] = true, ["Ravenous Hydra"] = true})
    aaCD = false
    AttackUnit(target)
  elseif ValidTarget(target, 425) and DariusMenu.Harass.Q:Value() and Ready(_Q) then
    CastSpell(_Q)
  end
end

function Laneclear()
  for _, minion in pairs(minionManager.objects) do
    if ValidTarget(minion, 255) and not aaCD then
      --AttackUnit(minion)
    elseif ValidTarget(minion, 255) and aaCD and DariusMenu.Laneclear.W:Value() and Ready(_W) then
      CastSpell(_W)
      aaCD = false
      --AttackUnit(minion)
    elseif ValidTarget(minion, 255) and aaCD and DariusMenu.Combo.useItems:Value() then 
      Items(nil, {["Tiamat"] = true, ["Titanic Hydra"] = true, ["Ravenous Hydra"] = true})
      aaCD = false
      --AttackUnit(minion)
    elseif ValidTarget(minion, 425) and DariusMenu.Laneclear.Q:Value() and Ready(_Q) then
      CastSpell(_Q)
    end
  end
end

function Killsteal()
  for _, enemy in pairs(GetEnemyHeroes()) do
    if rDebuff ~= nil then 
      local realHP = (GetCurrentHP(enemy) + GetDmgShield(enemy) + (GetHPRegen(enemy) * 0.25))
      local rStacks = rDebuff[enemy.networkID] or 0
      local rDamage = (((GetSpellData(myHero, _R).level * 100) + (GetBonusDmg(myHero) * 0.75)) + (rStacks * ((GetSpellData(myHero, _R).level * 20) + (GetBonusDmg(myHero) * 0.15))))
      if ValidTarget(enemy, 460) and rDamage >= realHP and Ready(_R) and DariusMenu.ksteal.R:Value() then 
        CastTargetSpell(enemy, _R)
      end
    end
    if igniteFound and DariusMenu.ksteal.ignite:Value() and Ready(summonerSpells.ignite) then
        local iDamage = (50 + (20 * GetLevel(myHero)))
        local realHPi = (GetCurrentHP(enemy) + GetDmgShield(enemy) + (GetHPRegen(enemy) * 0.05))
        if ValidTarget(enemy, 600) and realHPi <= iDamage then
          CastTargetSpell(enemy, summonerSpells.ignite)
        end
    end
  end
end

function Qorb()
  local target = GetCurrentTarget()
  if target ~= nil and qCasting then
    local pos = myHero - (Vector(target) - myHero):normalized() * 307.5 
    if GetDistance(myHero, target) >= 307.5 then
      MoveToXYZ(GetOrigin(target))
    elseif GetDistance(myHero, target) <= 307.5 then
      MoveToXYZ(pos)
    end
  end
end

function Items(target, list)
  for itemName, attackItem in pairs(attackItems) do
    if (list ~= nil) then
      if (list[itemName] == true) then
        CastItem(target, attackItem)
      end
    else
      CastItem(target, attackItem)
    end
  end
end

function CastItem(target, theItem)
  local itemSlot = GetItemSlot(myHero, theItem.itemID)
  if (itemSlot ~= 0) then
    if ((theItem.spellRange == nil) or ((target ~= nil) and (GetDistance(myHero, target) <= theItem.spellRange))) then
      if (Ready(itemSlot)) then
        if ((theItem.requiresTarget == true) and (target ~= nil)) then
          CastTargetSpell(target, itemSlot)
        else
          CastSpell(itemSlot)
        end
      end
    end
  end
end

OnDraw (function()
  if not IsDead(myHero) then
    if DariusMenu.draws.qdraw:Value() and Ready(_Q) then
      DrawCircle(GetOrigin(myHero), 425, 2, 1, ARGB(255, 255, 20, 147))
    end
    if DariusMenu.draws.edraw:Value() and Ready(_E) then
      DrawCircle(GetOrigin(myHero), 540, 2, 1, ARGB(255, 245, 86, 7))
    end
    if DariusMenu.draws.tdraw:Value() and Ready(_R) then
      DrawCircle(GetOrigin(myHero), 460, 2, 1, ARGB(255, 242, 0, 141))
    end
    if DariusMenu.draws.rhpdraw:Value()  then 
      for _, enemy in pairs(GetEnemyHeroes()) do
        local realHP = (GetCurrentHP(enemy) + GetDmgShield(enemy) + (GetHPRegen(enemy) * 0.25))
        local barPos = GetHPBarPos(enemy)
        local rStacks = rDebuff[enemy.networkID] or 0
        local rDamage = (((GetSpellData(myHero, _R).level * 100) + (GetBonusDmg(myHero) * 0.75)) + (rStacks * ((GetSpellData(myHero, _R).level * 20) + (GetBonusDmg(myHero) * 0.15)))) 
        if rDebuff[enemy.networkID] ~= nil and ValidTarget(enemy, 2000) then
          if rDebuff[enemy.networkID] == 0 then
            DrawTextA(""..rDebuff[enemy.networkID].."", 40, barPos.x+135, barPos.y-17, ARGB(255, 0, 255, 0))
          elseif rDebuff[enemy.networkID] == 1 then
            DrawTextA(""..rDebuff[enemy.networkID].."", 40, barPos.x+135, barPos.y-17, ARGB(255, 173, 255, 47))
          elseif rDebuff[enemy.networkID] == 2 then
            DrawTextA(""..rDebuff[enemy.networkID].."", 40, barPos.x+135, barPos.y-17, ARGB(255, 255, 255, 0))
          elseif rDebuff[enemy.networkID] == 3 then
            DrawTextA(""..rDebuff[enemy.networkID].."", 40, barPos.x+135, barPos.y-17, ARGB(255, 255, 165, 0))
          elseif rDebuff[enemy.networkID] == 4 then
            DrawTextA(""..rDebuff[enemy.networkID].."", 40, barPos.x+135, barPos.y-17, ARGB(255, 139, 69, 0))
          elseif rDebuff[enemy.networkID] == 5 and realHP > rDamage then
            DrawTextA("Max Stacks", 40, barPos.x+135, barPos.y-17, ARGB(255, 255, 0, 0))
          elseif realHP <= rDamage and Ready(_R) then
            DrawTextA("Finish Him!!!", 40, barPos.x+135, barPos.y-17, ARGB(255, 255, 0, 0))
          end
        end
      end 
    end
    for _, enemy in pairs(GetEnemyHeroes()) do
      local realHP = (GetCurrentHP(enemy) + GetDmgShield(enemy) + (GetHPRegen(enemy) * 0.25))
      local rStacks = rDebuff[enemy.networkID] or 0
      local rDamage = (((GetSpellData(myHero, _R).level * 100) + (GetBonusDmg(myHero) * 0.75)) + (rStacks * ((GetSpellData(myHero, _R).level * 20) + (GetBonusDmg(myHero) * 0.15)))) 
      if myHero:GetSpellData(_R).currentCd == 0 and myHero:GetSpellData(_R).level ~= 0 and DariusMenu.draws.rhpdraw:Value() and ValidTarget(enemy, 2000) then
        DrawDmgOverHpBar(enemy, realHP, rDamage, 0, ARGB(255, 0, 255, 0))
      end
    end
  end
end)