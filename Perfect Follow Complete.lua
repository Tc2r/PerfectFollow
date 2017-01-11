local version = "0.07"

--[[
Perfect Follow Script by Tc2r
]]
	_G.is_autobuy = false
	_G.is_autocombat = true
	_G.is_autolevel = true
	_G.is_followminions = true
	_G.is_followenemies = true
	_G.is_followallies = true
	_G.is_followhurtally = true
	_G.is_recalllowmp = true
	_G.is_recalllowhp= true
	_G.is_recallatgold = true
	_G.is_recallwithpartner = true
	_G.is_DrawFollowingText = false
	_G.is_Drawleashcircle = false
	_G.MIN_AT_TOWER = 3
	_G.RE_MANA_AMOUNT = 10
	_G.RE_HEALTH_AMOUNT = 13
	_G.RE_GOLD_AMOUNT = 2700
	_G.FOL_DIST = 200
	_G.LEASH_RANG = 366
	_G.LEASH_CC = 349
	_G.PRE_BEFORE_LVL = 1


local freedom = 200
disFollower = myHero
follower = nil
champion = myHero
Attacked = nil
teletarget = nil
tempFollower = nil
local allySpawn, enemySpawn
AllyTeamPosition = 0
enemyTurret = nil
lastFollow = nil
hittingYou = nil
goldswitch = false
startingTime = 0
runOnce = 0
local towerAttack
FFChamp = nil
MinLeash = 100
ForceFollowTimer = 0
ForceFollowMode = false
FollowKeysCodes = {97,98,99,100}
myHero = GetMyHero()
minionplacekeep = nil
nearEnemy = nil
nearRelic = nil
relicTimer = .5
closeEnemy = nil
closeAlly = nil
hurtAlly = nil
aaTick = 0
IsOver = 0
aaDelay = 1000
local safeTower
local LastCheck = os.clock() + 1
pRecalling = false
local towerFocused = false
local mapID = GetGame().map.index
recallStartTime = 0
recallDetected = false
shouldRecall = false
recallingNow = false
recentrecallTarget = myHero
MyTeam = {}
MinionsNearAlly = {}
GameOverNow = false
Endgame = 0
local TP_Slot = myHero:GetSpellData(SUMMONER_1).name:find("teleport") and SUMMONER_1 or myHero:GetSpellData(SUMMONER_2).name:find("teleport") and SUMMONER_2

function OnLoad()
	--print("Map ID: "..GetGame().map.index)
	runOnce1 = 0
	startingTime = GetTickCount()
	myHero = GetMyHero()
	lastFollow = myHero
	MyTeam = GetmyHeros(myHero.team, true, true)
	runonce = 0
	startingtime = os.clock()
	AllyMinions = minionManager(MINION_ALLY, 800, myHero, MINION_SORT_HEALTH_ASC)
	AllyTowerMinions = minionManager(MINION_ALLY, 900, enemyTurret, MINION_SORT_HEALTH_ASC)
	MinionsNearAlly = minionManager(MINION_ALLY, 1500, lastFollow, MINION_SORT_HEALTH_ASC)
	EnemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_HEALTH_ASC)
	drawMenu()
	for dc, _d in ipairs(GetAllyHeroes()) do
		config.Follow["followally" .. dc] = true
	end
	-------------------AUTOBUY--------------------
	AutoBuy_i = ABUY()
	if AutoBuy_i ~= nil then
		AutoBuy_i:OnLoad()
	end
	-------------------AUTOBUY--------------------
	------------------AUTOLEVEL-------------------
	AutoLvl_i = ALVL()
	if AutoLvl_i ~= nil then
		AutoLvl_i:OnLoad()
	end
	------------------AUTOLEVEL-------------------
	--------------------COMBAT--------------------
	ACombat_i = ACOMBAT()
	if ACombat_i ~= nil then
		ACombat_i:OnLoad()
	end
	--------------------COMBAT--------------------
end


function OnWndMsg(dc, _d)
	if not config.enableScript then
		return
	end
	for i = 1, #MyTeam do
		if _d == FollowKeysCodes[i] and dc == KEY_DOWN then
			FFChamp = MyTeam[i]
			--print("Perfect Force Follow: " .. MyTeam[i].charName)
			ForceFollowTimer = GetTickCount()
			ForceFollowMode = true
			FollowOn(FFChamp)
			return
		end
	end
end


function OnTick()
	if not config.enableScript then return end
	local osc = os.clock()
	if osc - startingtime < 7 then return end

	if runOnce ~= 1 then
		detectSpawnPoints()
		runOnce = 1
		return
	end
	if myHero.dead and shouldRecall then
		shouldRecall = false
	end
	-------------------AUTOBUY--------------------
	if AutoBuy_i ~= nil and config.enableAutoBuy then
		AutoBuy_i:OnTick()
	end
	-------------------AUTOBUY--------------------
	------------------AUTOLEVEL-------------------
	if AutoLvl_i ~= nil and config.enableAutoLvl then
		AutoLvl_i:OnTick()
	end
	------------------AUTOLEVEL-------------------
	--------------------COMBAT--------------------
	if ACombat_i ~= nil and config.enableAutoCombat then
		ACombat_i:OnTick()
	end
	--------------------COMBAT--------------------
	if myHero.dead then return end

	if LastCheck < osc and not myHero.dead then
		LastCheck = osc + 0.5
		if isRecalling(myHero) == true then return end
		MinLeash = config.Misc.FollowDist
		AllyMinions:update()
		Farming()
		if ForceFollowMode == true and GetTickCount() - ForceFollowTimer < 25000 then
			if shouldRecall == false then
				if FFChamp ~= nil then
					FollowOn(FFChamp)
				end
				InTurret()
				RecallNow()
			else
				RecallMode()
				RecallNow()
				if myHero.dead and shouldRecall then
					shouldRecall = false
				end
			end
			return
		else
			ForceFollowMode = false
			if GetInGameTimer() < 60 then
				BeginTower()
			elseif shouldRecall ~= true then
				CombatPos()
				ChasePartners()
				if follower ~= nil then
					FollowOn(follower)
				end
				InTurret()
				RecallNow()
			else
				RecallMode()
				RecallNow()
				if myHero.dead and shouldRecall then
					shouldRecall = false
				end
			end
		end
	end
	for i = 1, objManager.maxObjects do
		local dc = objManager:getObject(i)
		if dc ~= nil and dc.valid and dc.type == "obj_HQ" and dc.visible and dc.health < 100 then
			config.Misc.DrawFollowing = false
			config.Misc.DrawLeash = false
		end
	end
	for i=1, objManager.maxObjects, 1 do
		local nexus = objManager:getObject(i)
		if nexus ~= nil and nexus.valid and nexus.type == "obj_HQ" and nexus.visible and nexus.health < 250 and Endgame == 0 then
			GameOverNow = true
		end
	end
	if Endgame == 0 and GameOverNow == true then
		GameOverNow = false
		print("=== QUIT GAME IN 10 SECONDS ===")
		WriteFile(" ","C:\\Riot Games\\League of Legends\\RADS\\endgame.txt","w+")
		QuitGame(5)
		Endgame = 1
	end
end

function CombatPos()
	local enemycounter = 0
	local allycounter = 0
	if myHero.health/myHero.maxHealth > .20 then
		allycounter = 1
	end
	--Set Nearest Enemy
	for j, v in ipairs(GetEnemyHeroes()) do
		if v ~= nil then
			if nearEnemy == nil then
				if InSpawn(v) ~= true and GetDistance(myHero, v) < 3000 and not v.dead then
					nearEnemy = v

				else
					return
				end
			elseif GetDistance(myHero, v) < GetDistance(myHero, nearEnemy) and GetDistance(myHero, v) < 1200 and not v.dead then
				nearEnemy = v
			end
		end
	end
	-- if nearEnemy is within range set ally and enemy counters
	if nearEnemy ~= nil and GetDistance(myHero, nearEnemy) < 1600 then
		for i, v in ipairs(GetEnemyHeroes()) do
			--increase enemycounter by every enemy near our close guy
			if GetDistance(v, nearEnemy) < 700 and v.health/v.maxHealth > .20 and not v.dead then
				enemycounter = enemycounter + 1
			end
		end
		for i, v in ipairs(GetAllyHeroes()) do
			--increase enemycounter by every enemy near our close guy
			if GetDistance(v, nearEnemy) < 900 and v.health/v.maxHealth > .20 and not v.dead then
				allycounter = allycounter + 1
			end
		end
	end
	if nearEnemy ~= nil and GetDistance(nearEnemy, myHero) < 1000 then
		--print("Enemies Near: "..enemycounter.." VS Allies Near: "..allycounter)
	end
	-- if healthy enough to fight
	if nearEnemy ~= nil and (GetDistance(nearEnemy, myHero) < 1000) and (myHero.health/myHero.maxHealth > .25) and (myHero.mana/myHero.maxMana > .13) and (allycounter >= enemycounter) and (nearEnemy.visible == true) and not nearEnemy.dead and UnderTurret(myHero, true) ~= true then
		if not myHero.dead and config.enableAutoCombat then
			ACombat_i.ts.target = nearEnemy
			ACombat_i.Data[myHero.charName].Combo(nearEnemy)
			--print("Lets try attacking "..nearEnemy.name)
		end
		myHero:Attack(nearEnemy)
	end
	if nearEnemy ~= nil and ((myHero.health/myHero.maxHealth < .50) or (myHero.mana/myHero.maxMana < .13)) and (GetDistance(nearEnemy, myHero) < 1000) and (allycounter < enemycounter) and (nearEnemy.visible == true) and not nearEnemy.dead then
		if not myHero.dead and safeTower ~= nil then
			--print("Full Retreat")
			FollowOn(safeTower)
			return
		end
	end
end

function ChasePartners()
	for i = 1, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object and object.valid and object.name:find("HealthRelic") and GetDistance(myHero, object) < 900 and GetDistance(myHero,object) > 50 then
			nearRelic = object
		end
		if object and object.valid and object.name:find("HealthRelic") and GetDistance(myHero, object) < 70 then
			relicTimer = os.clock()
		end
	end
	for dc, _d in ipairs(GetEnemyHeroes()) do
		if _d ~= nil then
			if nearEnemy == nil then
				if InSpawn(_d) ~= true and GetDistance(_d) < 3000 and _d.health > 1 and _d.visible == true and _d.dead == false then
					nearEnemy = _d
				end
			elseif GetDistance(_d) < GetDistance(nearEnemy) and GetDistance(_d) < 1500 and _d.visible == true and _d.dead == false then
				nearEnemy = _d
			end
			if (GetGame().map.index == 12) then
				if InSpawn(_d) ~= true and UnderTurret(myHero, true) ~= true and GetDistance(_d) < 1200 and _d.visible == true and _d.health > 1 and _d.dead == false and _d.health / _d.maxHealth < 0.25 and 0.35 < myHero.health / myHero.maxHealth and config.Follow.Enemies then
					closeEnemy = _d

					follower = closeEnemy
					if config.enableAutoCombat then
						ACombat_i.ts.target = closeEnemy
						ACombat_i.Data[myHero.charName].Combo(closeEnemy)
						--print("Lets try attacking "..nearEnemy.name)
					end
					myHero:Attack(closeEnemy)
					return
				end
			else
				if InSpawn(_d) ~= true and UnderTurret(myHero, true) ~= true and GetDistance(_d) < 1200 and _d.visible == true and _d.health > 1 and _d.dead == false and _d.health / _d.maxHealth < 0.20 and 0.35 < myHero.health / myHero.maxHealth and config.Follow.Enemies then
					closeEnemy = _d
					follower = closeEnemy
					if closeEnemy ~= nil then
					if config.enableAutoCombat then
						ACombat_i.ts.target = closeEnemy
						ACombat_i.Data[myHero.charName].Combo(closeEnemy)
						--print("Lets try attacking "..nearEnemy.name)
					end
					myHero:Attack(closeEnemy)
					return
					end
				end
			end
		end
		if nearEnemy ~= nil and Attacked == myHero and GetDistance(nearEnemy) > 1300 then
			Attacked = nil
		end
	end
	for i, v in ipairs(GetAllyHeroes()) do
		if v ~= nil then
			-- INITATE HURT ALLY
			if not InSpawn(v) and GetDistance(v) < 4000 and v.visible == true and v.dead == false and v.health / v.maxHealth < 0.2 and myHero.mana / myHero.maxMana > 0.3 then
				hurtAlly = v
			end
			-- INITATE CLOSE ALLY
			if closeAlly == nil then
				if not InSpawn(v) and v:GetDistance(allySpawn) > 1200 and GetDistance(v) < 3300 and config.Follow["followally" .. i] and v.dead == false then
					closeAlly = v
					lastFollow = closeAlly
				end
			else
				if GetDistance(v, allySpawn) < GetDistance(closeAlly, allySpawn) and v:GetSpellData(SUMMONER_1).name:find("smite") == nil and v:GetSpellData(SUMMONER_2).name:find("smite") == nil and not InSpawn(v) and v:GetDistance(allySpawn) > 1200 and GetDistance(v) < 2300 and config.Follow["followally" .. i] and v.dead == false then
					closeAlly = v
					lastFollow = closeAlly
				end
			end
		end
	end
	safeTower = GetCloseTower(myHero, myHero.team)

	-- START HERE
	if (GetGame().map.index == 12) then
		if nearRelic ~= nil and myHero.dead ~= true and myHero.health/myHero.maxHealth < .30 and os.clock() - relicTimer > 5 then
			relicNear = nearRelic
			nearRelic = nil
			follower = relicNear
			return
		end
	else
		if safeTower ~= nil then
			if myHero.health / myHero.maxHealth < (config.Recall.HealthPercent/100 - .05) then
				follower = safeTower
				--return
			end
			if nearEnemy ~= nil and GetDistance(nearEnemy) < 700 and nearEnemy.health / nearEnemy.maxHealth > 0.4 and nearEnemy.dead ~= true then
				follower = safeTower
				--return
			end
		end
	end
	enemyTurret = GetCloseTower(myHero, TEAM_ENEMY)
	if hurtAlly ~= nil and mapID ~= 12 then
		if enemyTurret ~= nil and GetDistance(enemyTurret) < 1080 then
			return
		end
		if allySpawn ~= nil and hurtAlly:GetDistance(allySpawn) > 1800 and not UnderTurret(myHero, true) and hurtAlly.dead == false and config.Follow.LowAlly then
			follower = hurtAlly
			hurtAlly = nil
			return
		end
	end
	if closeAlly ~= nil then
		if enemyTurret ~= nil and GetDistance(enemyTurret) < 950 then
			return
		end
		if (mapID == 15 or mapID == 0) and closeAlly:GetDistance(allySpawn) > 4700 and not UnderTurret(myHero, true) and Attacked ~= myHero and closeAlly.dead == false and follower == nil and config.Follow.Champions then
			followcan = closeAlly
			closeAlly = nil
			--return
		end

		-- and not UnderTurret(myHero, true)
		if (GetGame().map.index == 10 or GetGame().map.index == 12) and closeAlly:GetDistance(allySpawn) > 1600  and Attacked ~= myHero and closeAlly.dead == false and follower == nil and config.Follow.Champions then
			followcan = closeAlly
			closeAlly = nil
			--return
		end
	end

	if not config.Follow.Minions then
	else
		local minionswitch = 0
		if Attacked ~= myHero then
			if minionplacekeep == nil or minionplacekeep.type ~= "obj_AI_Minion" or minionplacekeep == "INVALID" or minionplacekeep.dead or myHero.dead  then
				minionplacekeep = nil
				follower = nil
				AllyMinions:update()
				if minionswitch == 0 then
					for i = 1, objManager.maxObjects do
						local tempMinion = objManager:getObject(i)

						if tempMinion ~= nil and tempMinion.valid and tempMinion.team == myHero.team and tempMinion.charName and tempMinion.type == "obj_AI_Minion" and tempMinion.charName:lower():find("minion") and not tempMinion.dead and GetDistance(tempMinion, allySpawn) > 1900 and GetDistance(tempMinion) < 1200 and UnderTurret(myHero, true) ~= true then
							if closeEnemy ~= nil and closeEnemy.dead == false and GetDistance(tempMinion, closeEnemy) < 750 then
							else
							if follower == nil then
								minionplacekeep = tempMinion
								followcantwo = tempMinion
								--print("Following Minions style 1")
								--return
							end
						end
						end
					end
				end
				if UnderTurret(myHero, true) ~= true and minionswitch == 1 or minionplacekeep == nil  then
					for dc, _d in pairs(AllyMinions.objects) do
						if _d ~= nil then
							if closeEnemy ~= nil and closeEnemy.dead == false and GetDistance(tempMinion, closeEnemy) < 550 then
							else
								if myHero.level < 7 and _d:GetDistance(allySpawn) > 1900 and GetDistance(_d) < 1000 and follower == nil and _d.health / _d.maxHealth > 0.3 then
									minionplacekeep = _d
									followcantwo = _d
									--print("Following Minions style 2")
									--return
								end
								if myHero.level > 6 and _d:GetDistance(allySpawn) > 1900 and follower == nil and _d.health / _d.maxHealth > 0.15 then
									minionplacekeep = _d
									followcantwo = _d
									--print("Following Minions style 2")
									--return
								end
							end
						end
					end
				end
			else
				if minionplacekeep ~= nil and not minionplacekeep.dead and GetDistance(minionplacekeep) < 1500 then
					followcantwo = minionplacekeep
					--return
				else
					--print("Reset Minion Place Keeper")
					minionplacekeep = nil
					followcantwo = nil
				end
			end
		else
		end
	end

	compareMinion = 0
	compareAlly = 0

	--if closeEnemy ~= nil and closeEnemy.dead == false and GetDistance(tempMinion, closeEnemy) < 750 then
		--else

	if GetDistance(allySpawn) > 1500 and Attacked ~= myHero and myHero.dead == false then
		if followcantwo ~= nil and config.Follow.Minions and UnderTurret(myHero, true) ~= true then
			compareMinion = GetDistance(followcantwo, allySpawn)
		end
		if followcan ~= nil and config.Follow.Champions then
			compareAlly = GetDistance(followcan, allySpawn)
		end
		if config.Follow.Champions and config.Follow.Minions and followcan ~= nil and followcantwo ~= nil then
			if compareMinion > compareAlly and UnderTurret(myHero, true) ~= true then
				follower = followcantwo
				followcantwo = nil
				followcan = nil
				return
			else
				follower = followcan
				followcantwo = nil
				followcan = nil
				return
			end
		end
		if config.Follow.Champions and followcan ~= nil then
			follower = followcan
			followcantwo = nil
			followcan = nil
			return
		end
		if followcantwo ~= nil and config.Follow.Minions and UnderTurret(myHero, true) ~= true then
			follower = followcantwo
			followcantwo = nil
			followcan = nil
			return
		end
	end


	if allySpawn ~= nil and follower == nil then
		if (mapID == 15 or mapID == 0) and GetDistance(allySpawn) > 4700 then
			if safeTower ~= nil then
				--print("safeTower")
				follower = safeTower
			else
				follower = myHero
			end
			return
		elseif mapID == 10 and GetDistance(allySpawn) > 1600 then
			if safeTower ~= nil then
				--print("safeTower")
				follower = safeTower
			else
				follower = myHero
			end
			return
		elseif mapID == 12 and GetDistance(allySpawn) > 1100 then
			if safeTower ~= nil then
				--print("safeTower")
				follower = safeTower
			else
				follower = myHero
			end
			return
		elseif GetDistance(allySpawn) > 2000 then
			if safeTower ~= nil then
				--print("safeTower")
				follower = safeTower
			else
				follower = myHero
			end
			return
		end
	end

	if follower == nil and GetInGameTimer() > 720 then
		if AllyTeamPosition == 1 then
			if GetGame().map.index == 1 then
				myHero:MoveTo(5425, 5742)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(2348, 5303)
			end
			if GetGame().map.index == 12 then
				myHero:MoveTo(2628, 2298)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(3540, 3467)
			end
		else
			if GetGame().map.index == 1 then
				myHero:MoveTo(9584, 9720)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(13037, 5468)
			end
			if GetGame().map.index == 12 then
				myHero:MoveTo(10395, 10223)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(11346, 11119)
			end
		end
		follower = myHero
	elseif follower == nil and GetInGameTimer() > 80 and GetInGameTimer() < 720 then
		if AllyTeamPosition == 1 then
			if GetGame().map.index == 1 then
				myHero:MoveTo(2610, 1770)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(4753, 4419)
			end
			if GetGame().map.index == 12 then
				myHero:MoveTo(2628, 2298)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(6690, 1289)
			end
		else
			if GetGame().map.index == 1 then
				myHero:MoveTo(12563, 11249)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(10648, 4257)
			end
			if GetGame().map.index == 12 then
				myHero:MoveTo(10395, 10223)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(12345, 11957)
			end
		end
		follower = myHero
	end
	if follower ~= nil and (follower.dead == true or GetDistance(follower) > 2000 or UnderTurret(follower, true)) then
		follower = nil
	end
end
function FollowOn(dc)
	if dc ~= nil and UnderTurret(dc, true) ~= true then
		local _d = dc
		disFollower = dc
		if _d.charName ~= nil and _d.charName:find("HealthRelic") then
			freedom = 10
			myHero:MoveTo(_d.x, _d.z)
		else
			if _d.range < 300 then
				freedom = config.Misc.LeashMelee
			else
				freedom = config.Misc.LeashRanged
			end


			if GetDistance(_d) > freedom then
				ChaseX = (allySpawn.x - _d.x) / _d:GetDistance(allySpawn) * ((config.Misc.FollowDist - 150) / 2 + 150) + _d.x + math.random(-((config.Misc.FollowDist - 150) / 3), (config.Misc.FollowDist - 150) / 3)
				ChaseZ = (allySpawn.z - _d.z) / _d:GetDistance(allySpawn) * ((config.Misc.FollowDist - 150) / 2 + 150) + _d.z + math.random(-((config.Misc.FollowDist - 150) / 3), (config.Misc.FollowDist - 150) / 3)
				myHero:MoveTo(ChaseX, ChaseZ)
			end
		end
	end
end
function Farming()
	enemyMinions = minionManager(MINION_ENEMY, 750, player)
	if nearEnemy ~= nil and GetDistance(nearEnemy) < 900 then
		return
	end
	for index, minion in pairs(enemyMinions.objects) do
		if GetTickCount() - aaTick >= aaDelay and myHero:GetDistance(minion) < (myHero.range + 150) and myHero:CalcDamage(minion, myHero.totalDamage)*2.3 > minion.health and UnderTurret(myHero, true) ~= true then
			myHero:Attack(minion)
			aaTick = GetTickCount()
		end
	end
end

function RecallNow()
	if not InSpawn() and not myHero.dead and GetGame().map.index ~= 12 then

		if myHero.mana / myHero.maxMana < config.Recall.ManaPercent / 100 and config.Recall.Mana and myHero.level > config.Recall.BeforeLevel - 1 then
			safeTower = GetCloseTower(myHero, myHero.team)
			tempFollower = safeTower
			shouldRecall = true
		end
		if myHero.health / myHero.maxHealth < config.Recall.HealthPercent / 100 and myHero.level > config.Recall.BeforeLevel - 1 then
			safeTower = GetCloseTower(myHero, myHero.team)
			tempFollower = safeTower
			shouldRecall = true
		end
		if goldswitch == true and myHero.gold <= config.Recall.GoldAmount and os.clock() < 780 and myHero.level > config.Recall.BeforeLevel - 1 then
			goldswitch = false
		end
		if myHero.gold > config.Recall.GoldAmount and os.clock() < 1580 and goldswitch == false and config.Recall.Gold and myHero.level > config.Recall.BeforeLevel - 1 then
			tempFollower = safeTower
			shouldRecall = true
			goldswitch = true
		end

		if follower ~= nil then
			if isRecalling(follower) then
				pRecalling = true
			else
				pRecalling = false
			end
		end
		if isRecalling(myHero) and isRecalling(follower) == false and pRecalling == true then
			myHero:MoveTo(myHero.x + 3, myHero.z + 3)
			pRecalling = false
		end
		enemyTurret = GetCloseTower(myHero, TEAM_ENEMY)
		if (myHero.health / myHero.maxHealth < 0.5 or myHero.mana / myHero.maxMana < 0.3) and pRecalling == true and config.Recall.Partner and isRecalling(myHero) ~= true and enemyTurret ~= nil and UnderTurret(myHero, enemyTurret) == false then
			if nearEnemy ~= nil and GetDistance(nearEnemy) > 2300 then
				CastSpell(RECALL)
				pRecalling = false
				tempFollower = safeTower
			else
				tempFollower = safeTower
			end
			shouldRecall = true
		end
	end
	if shouldRecall == false then
		follower = nil
	end
end
function RecallMode()

	if tempFollower ~= nil and tempFollower.dead == true or tempFollower.health < 15 then
		tempFollower = GetCloseTower(myHero, myHero.team)
	end
	if tempFollower ~= nil and myHero.dead ~= true then
--RECALL CYCLE

-- END OF CYCLE
	if recallCycleEnd == true and not myHero.dead then
		if GetDistance(tempFollower) < 500 then
			shouldRecall = false
			recallCycleEnd = false
			recallingNow = false
			tempTPFollower = nil
			--print("RECALL Stage: COMPLETE")
			return
		else
			tempTPFollower = nil
			myHero:MoveTo(tempFollower.x, tempFollower.z)
			return
		end
	end
--END OF CYCLE GO TO LANE



-- START OF CYCLE, TIME TO RECALL
		-- 1) RUN TO TOWER
		if shouldRecall == true and GetDistance(tempFollower) > 400 and not InSpawn() and recallingNow == false and not myHero.dead then
			if tempTPFollower == nil then
				tempTPFollower = GetCloseTower(myHero, myHero.team)
			end
			--print("RECALL Stage: RETREAT TO SAFETY")
			local dc = tempFollower.x
			local _d = tempFollower.z
			myHero:MoveTo(dc, _d)
			RecallBroke = 0
		end

		--2) ATTEMPT RECALL ONCE AT TOWER, ELSE RUN TO BASE
		if ((nearEnemy ~= nil and GetDistance(nearEnemy) > 3000) or GetDistance(tempFollower) < 401 ) and shouldRecall == true and RecallBroke == 0 and isRecalling(myHero) == false and not InSpawn() then
			--print("RECALL Stage: ATTEMPT RECALL SPELL")
			CastSpell(13, myHero)
			CastSpell(RECALL, myHero)
			RecallBroke = 1
			recallingNow = true
		end

		if shouldRecall == true and GetDistance(tempFollower) < 401 and isRecalling(myHero) == false and InSpawn() == false and RecallBroke == 1 and myHero.dead ~= true then
			--print("RECALL Stage: PLAN B, WALK TO bASE")
			myHero:MoveTo(allySpawn.x, allySpawn.z)
			recallingNow = true
		end

		-- 3) AT Base, HEAL, ONCE HEALED RUN TO TEMP FOLLOWER
		-- 3) A. ATTEMPT TELEPORT TO TOWER OR MINION NEAR TEMP FOLLOWER

		if InSpawn() and shouldRecall and myHero.mana == myHero.maxMana and myHero.health == myHero.maxHealth and tempFollower ~= nil and GetDistance(tempFollower) > 410 then
			myHero:MoveTo(tempFollower.x, tempFollower.z)

			if TP_Slot == nil or not myHero:CanUseSpell(TP_Slot) == READY then
				recallCycleEnd = true
				--print("RECALL Stage: RETURN TO LANE")
			else
				if myHero.level < 6 or lastFollow:GetDistance(allySpawn) < 5000 and tempTPFollwer ~= nil then
					--print("RECALL Stage: USE TELEPORT")
					CastSpell(TP_Slot, tempTPFollower)
					tempTPFollower = nil
				else
					if lastFollow ~= nil then
						MinionsNearAlly:update()
						for dc, _d in pairs(MinionsNearAlly.objects) do
							if _d ~= nil and _d.health /_d.maxHealth > .50 then
								if teletarget == nil then
									teletarget = _d
								elseif lastFollow:GetDistance(teletarget) > lastFollow:GetDistance(_d) then
									teletarget = _d
								end
							end
						end
					end
					if teletarget ~= nil then
						--print("RECALL Stage: TELEPORT TO MINION")
						CastSpell(TP_Slot, teletarget)
					elseif tempTPFollwer ~= nil then
						--print("RECALL Stage: TELEPORT TO Tower")
						CastSpell(TP_Slot, tempTPFollower)
						tempTPFollower = nil
					end
				end
				shouldRecall = false
				recallCycleEnd = false
				recallingNow = false
				return
			end
		end
	end
end

function OnProcessSpell(dc, _d)
	if not config.enableScript then
		return
	end

	if _d.name:lower():find("attack") and dc.valid and dc.type == "obj_AI_Turret" and dc.visible and dc.team ~= myHero.team and GetDistance(dc) < 1100 then
		towerAttack = _d.target
		if towerAttack == myHero then
			towerFocused = true
			follower = safeTower
			FollowOn(follower)
			return
		else
			towerFocused = false
		end
	end

	--dc.type == myHero.type
	if _d.name:lower():find("attack") and dc.team == myHero.team and GetDistance(dc) < 1000 then
		local ad = _d.target
		if ad ~= nil and (ad.valid and ad.visible and ad.type == "obj_AI_Turret" or ad.charName == "Dragon" or ad.charName == "Worm" or dc.type == "obj_BarracksDampener" or dc.type == "obj_HQ") then
			if ad.GetTarget ~= myHero then
				print("ATtacking Tower")
				myHero:Attack(ad)
			else
				print("retreat")
				follower = safeTower
				FollowOn(follower)
				return
			end
		end
	end
	if _d.name:lower():find("attack") and GetDistance(dc) < 1000 and dc.valid and dc.type ~= "obj_AI_Turret" and dc.team ~= myHero.team and dc.health / dc.maxHealth > myHero.health / myHero.maxHealth then
		Attacked = _d.target
		if Attacked == myHero and myHero.dead ~= true and dc:CalcDamage(myHero, dc.totalDamage) > 0.09 * myHero.health then
			hittingYou = dc
			local ad = Vector(myHero.pos) + Vector(myHero.pos) - Vector(dc.pos):normalized() * 600
			local bd = 2 * myHero.x - dc.x
			local cd = 2 * myHero.z - dc.z

			if safeTower == nil or GetDistance(safeTower) > 3200 then
				myHero:MoveTo(ad.x, ad.z)
			else
				myHero:MoveTo(safeTower.x, safeTower.z)
				follower = safeTower
				FollowOn(follower)
				return
			end
			return
		elseif dc.valid and dc.team ~= myHero.team and dc.type == myHero.type and GetDistance(dc) < 800 and myHero.health / myHero.maxHealth > 0.45 and UnderTurret(myHero, true) ~= true and _d.target ~= myHero then
			myHero:Attack(dc)
			return
		end
	end
	if _d.name:lower():find("attack") and GetDistance(dc) < 810 and dc.type == myHero.type and dc.name ~= myHero.name and dc.team == myHero.team then
		allyAttack = _d.target
		if allyAttack ~= nil and allyAttack.type == myHero.type and allyAttack ~= hittingYou and UnderTurret(myHero, true) ~= true and 800 > GetDistance(allyAttack) and myHero.health / myHero.maxHealth > 0.4 then
			ACombat_i.ts.target = allyAttack
			ACombat_i.Data[myHero.charName].Combo(allyAttack)
			myHero:Attack(allyAttack)
		end
	end
end

function InTurret()
	enemyTurret = GetCloseTower(myHero, TEAM_ENEMY)
	if enemyTurret ~= nil and towerFocused == true and UnderTurret(myHero, true) then
		local _d = 2 * myHero.x - enemyTurret.x
		local ad = 2 * myHero.z - enemyTurret.z
		follower = nil
		myHero:MoveTo(_d, ad)
		print("time to run")
		return
	end
	local dc = 0
	if enemyTurret ~= nil and UnderTurret(myHero, true) and myHero.dead ~= true then
		AllyTowerMinions:update()
		for _d in ipairs(AllyTowerMinions.objects) do
			dc = dc + 1
		end
		if dc < config.Misc.TowerMinionLimit or towerFocused == true then
			local _d = 2 * myHero.x - enemyTurret.x
			local ad = 2 * myHero.z - enemyTurret.z
			follower = nil
			myHero:MoveTo(_d, ad)
			return
		end
	end
	for _d, ad in ipairs(GetEnemyHeroes()) do
		if enemyTurret ~= nil and UnderTurret(myHero, true) == true and GetDistance(ad) < 1100 and myHero.dead ~= true and ad.dead ~= true and ad.health / ad.maxHealth > 0.2 then
			local bd = 2 * myHero.x - enemyTurret.x
			local cd = 2 * myHero.z - enemyTurret.z
			follower = nil
			myHero:MoveTo(bd, cd)
			return
		end
		if enemyTurret ~= nil and GetDistance(enemyTurret) < 1500 and myHero.dead ~= true and towerFocused == false and dc > config.Misc.TowerMinionLimit + 1 then
			if nearEnemy == nil or (nearEnemy ~= nil and GetDistance(nearEnemy) > 1300) then
				myHero:Attack(enemyTurret)
				return
			end
		end
	end
end

function OnDraw()
	if not config.enableScript then
		return
	end
	if disFollower.charName ~= nil and config.Misc.DrawFollowing then
		DrawText(myHero .. " is currently following " .. disFollower.charName, 18, (WINDOW_W - WINDOW_X) * 0.1, (WINDOW_H - WINDOW_Y) * 0.28, RGB(0, 255, 255))
		DrawCircle(disFollower.x, disFollower.y, disFollower.z, 120, RGB(0, 255, 255))
	end
	if config.Misc.DrawLeash then
		DrawCircle(disFollower.x, disFollower.y, disFollower.z, config.Misc.FollowDist, ARGB(0, 0, 191, 255))
		DrawCircle(disFollower.x, disFollower.y, disFollower.z, freedom, ARGB(0, 0, 150, 255))
	end
	if hittingYou ~= nil and config.Misc.DrawFollowing and hittingYou.valid and GetDistance(hittingYou) < 800 then
		DrawCircle(hittingYou.x, hittingYou.y, hittingYou.z, 120, RGB(255, 0, 0))
	end
end
function OnRecvChat(dc, _d)
	if not config.enableScript then
		return
	end
	local ad = string.lower(_d)
	if string.find(ad, "raka", 1, true) ~= nil and string.find(ad, "mid", 1, true) ~= nil then
		detectSpawnPoints()
		SendChat("Ok")
		--print("Soraka Going mid")
		ForceFollowTimer = GetTickCount()
		ForceFollowMode = true
		follower = nil
		FFChamp = nil
		if AllyTeamPosition == 1 then
			if GetGame().map.index == 1 then
				myHero:MoveTo(5425, 5742)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(4853, 4695)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(6182, 6321)
			end
		else
			if GetGame().map.index == 1 then
				myHero:MoveTo(9584, 9720)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(10585, 4733)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(8668, 8882)
			end
		end
		return
	end
	if string.find(ad, "raka", 1, true) ~= nil and string.find(ad, "bot", 1, true) ~= nil then
		detectSpawnPoints()
		SendChat("Ok")
		--print("Soraka Going bot!")
		ForceFollowTimer = GetTickCount()
		ForceFollowMode = true
		follower = nil
		FFChamp = nil
		if AllyTeamPosition == 1 then
			if GetGame().map.index == 1 then
				myHero:MoveTo(5425, 5742)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(4853, 4695)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(10704, 1344)
			end
		else
			if GetGame().map.index == 1 then
				myHero:MoveTo(9584, 9720)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(10585, 4733)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(13636, 4435)
			end
		end
		return
	end
	if string.find(ad, "raka", 1, true) ~= nil and string.find(ad, "top", 1, true) ~= nil then
		detectSpawnPoints()
		SendChat("Ok")
		--print("Soraka Going top!")
		ForceFollowTimer = GetTickCount()
		ForceFollowMode = true
		follower = nil
		FFChamp = nil
		if AllyTeamPosition == 1 then
			if GetGame().map.index == 1 then
				myHero:MoveTo(5425, 5742)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(4853, 4695)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(1271, 10599)
			end
		else
			if GetGame().map.index == 1 then
				myHero:MoveTo(9584, 9720)
			end
			if GetGame().map.index == 10 then
				myHero:MoveTo(10585, 4733)
			end
			if GetGame().map.index == 15 or GetGame().map.index == 0 then
				myHero:MoveTo(4067, 13937)
			end
		end
		return
	end
end
function drawMenu()
	config = scriptConfig("Tc2r's Perfect Follow", "Tc2rPerfectFollow")
	config:addParam("enableScript", "Enable Script", SCRIPT_PARAM_ONOFF, true)
	config:addParam("enableAutoCombat", "Enable Combat", SCRIPT_PARAM_ONOFF, _G.is_autocombat)
	config:addParam("enableAutoLvl", "Enable Levelup", SCRIPT_PARAM_ONOFF, _G.is_autolevel)
	config:addParam("enableAutoBuy", "Enable BuyItems", SCRIPT_PARAM_ONOFF, _G.is_autobuy)
	config:addSubMenu("Follow Targets", "Follow")
	config:addSubMenu("Recall Options", "Recall")
	config:addSubMenu("Follow Misc", "Misc")
	config.Follow:addParam("Minions", "Follow minions?", SCRIPT_PARAM_ONOFF, _G.is_followminions)
	config.Follow:addParam("Enemies", "Low Enemies?", SCRIPT_PARAM_ONOFF, _G.is_followenemies)
	config.Follow:addParam("Champions", "Champions?", SCRIPT_PARAM_ONOFF, _G.is_followallies)
	config.Follow:addParam("LowAlly", "Low Life Ally?", SCRIPT_PARAM_ONOFF, _G.is_followhurtally)
	for dc, _d in ipairs(GetAllyHeroes()) do
		local ad = _d
		if ad.team == myHero.team then
			config.Follow:addParam("followally" .. dc, "follow " .. ad.charName, SCRIPT_PARAM_ONOFF, true)
		end
	end
	config.Recall:addParam("BeforeLevel", "Prevent Recall B4 Level", SCRIPT_PARAM_SLICE, _G.PRE_BEFORE_LVL, 1, 18, 0)
	config.Recall:addParam("Mana", "Low Mp?", SCRIPT_PARAM_ONOFF, _G.is_recalllowmp)
	config.Recall:addParam("ManaPercent", "Mana % To Recall", SCRIPT_PARAM_SLICE, _G.RE_MANA_AMOUNT, 1, 99, 0)
	config.Recall:addParam("Health", "Low Hp?", SCRIPT_PARAM_ONOFF, _G.is_recalllowhp)
	config.Recall:addParam("HealthPercent", "Health % To Recall", SCRIPT_PARAM_SLICE, _G.RE_HEALTH_AMOUNT, 1, 99, 0)
	config.Recall:addParam("Gold", "Saved Gold?", SCRIPT_PARAM_ONOFF, _G.is_recallatgold)
	config.Recall:addParam("GoldAmount", "Force Recall when Gold", SCRIPT_PARAM_SLICE, _G.RE_GOLD_AMOUNT, 500, 9000, -2)
	config.Recall:addParam("Partner", "Partner Recalls?", SCRIPT_PARAM_ONOFF, _G.is_recallwithpartner)
	config.Misc:addParam("TowerMinionLimit", "#Minions at tower", SCRIPT_PARAM_SLICE, _G.MIN_AT_TOWER, 1, 10, 0)
	config.Misc:addParam("DrawFollowing", "Draw Follow Text", SCRIPT_PARAM_ONOFF, _G.is_DrawFollowingText)
	config.Misc:addParam("DrawLeash", "Draw Leash Circle", SCRIPT_PARAM_ONOFF, _G.is_Drawleashcircle)
	config.Misc:addParam("FollowDist", "Follow Distance?", SCRIPT_PARAM_SLICE, _G.FOL_DIST, 150, 450, -1)
	MinLeash = config.Misc.FollowDist
	config.Misc:addParam("LeashRanged", "Ranged Leash?", SCRIPT_PARAM_SLICE, _G.LEASH_RANG, MinLeash, 1000, 0)
	config.Misc:addParam("LeashMelee", "Melee Leash?", SCRIPT_PARAM_SLICE, _G.LEASH_CC, MinLeash, 1000, 0)
end
function GetmyHeros(dc, _d, ad)
	local bd = {}
	local cd = {}
	if dc == myHero.team then
		bd = GetAllyHeroes()
	else
		bd = GetEnemyHeroes()
	end
	for i = 1, #bd do
		if bd[i].visible and (not bd[i].dead or bd[i].dead == _d) then
			table.insert(cd, bd[i])
		end
	end
	if ad then
		table.insert(cd, myHero)
	else
		for i = 1, #cd do
			if cd[i] == myHero then
				table.remove(cd, i)
				break
			end
		end
	end
	return cd
end
function InSpawn(ichampion)
	if ichampion == nil then
		local champion = myHero
	else
		local champion = ichampion
	end
	if champion.team == myHero.team then
		if allySpawn == nil then
			return false
		end

		if champion:GetDistance(allySpawn) < 900 then
			return true

		else
			return false
		end
	end
	if champion.team ~= myHero.team then
		if enemySpawn == nil then
			return false
		end

		if champion:GetDistance(enemySpawn) < 900 then
			return true

		else
			return false
		end
	end
end
function detectSpawnPoints()
	mapID = GetGame().map.index
	if GetGame().map.index == 1 then
		for i = 1, objManager.maxObjects do
			local dc = objManager:getObject(i)
			if dc ~= nil and dc.valid and dc.type == "obj_SpawnPoint" then
				if dc.x < 3000 then
					if myHero.team == TEAM_BLUE then
						allySpawn = dc
						AllyTeamPosition = 1
					else
						AllyTeamPosition = 2
						enemySpawn = dc
					end
				elseif myHero.team == TEAM_BLUE then
					enemySpawn = dc
				else
					allySpawn = dc
				end
			end
		end
	end
	if GetGame().map.index == 15 or GetGame().map.index == 0 then
		for i = 1, objManager.maxObjects do
			local dc = objManager:getObject(i)
			if dc ~= nil and dc.valid and dc.type == "obj_SpawnPoint" then
				if dc.x < 3000 then
					if dc.team == myHero.team then
						allySpawn = dc
						AllyTeamPosition = 1
					else
						enemySpawn = dc
						AllyTeamPosition = 2
					end
				elseif dc.team == myHero.team then
					allySpawn = dc
					AllyTeamPosition = 2
				else
					enemySpawn = dc
					AllyTeamPosition = 1
				end
			end
		end
	end
	if GetGame().map.index == 10 then
		for i = 1, objManager.maxObjects do
			local dc = objManager:getObject(i)
			if dc ~= nil and dc.valid and dc.type == "obj_SpawnPoint" then
				if dc.x < 2000 then
					if dc.team == myHero.team then
						allySpawn = dc
						AllyTeamPosition = 1
					else
						enemySpawn = dc
						AllyTeamPosition = 2
					end
				elseif dc.team == myHero.team then
					allySpawn = dc
					AllyTeamPosition = 2
				else
					enemySpawn = dc
					AllyTeamPosition = 1
				end
			end
		end
	end
	if GetGame().map.index == 12 then
		for i = 1, objManager.maxObjects do
			local dc = objManager:getObject(i)
			if dc ~= nil and dc.valid and dc.type == "obj_SpawnPoint" then
				if dc.x < 4000 then
					if dc.team == myHero.team then
						allySpawn = dc
						AllyTeamPosition = 1
					else
						enemySpawn = dc
						AllyTeamPosition = 2
					end
				elseif dc.team == myHero.team then
					allySpawn = dc
					AllyTeamPosition = 2
				else
					enemySpawn = dc
					AllyTeamPosition = 1
				end
			end
		end
	end
end

--return towers table
function GetTowers(team)
	local towers = {}
	for i=1, objManager.maxObjects, 1 do
		local tower = objManager:getObject(i)
		if tower ~= nil and tower.valid and tower.type == "obj_AI_Turret" and tower:GetDistance(allySpawn) > 1600 and tower.visible and tower.team == team then
			table.insert(towers,tower)
		end
	end
	return towers
end

function GetCloseTower(hero, team)
	local towers = GetTowers(team)
	if #towers > 0 then
		local candidate = towers[1]
		for i=2, #towers, 1 do
			if (towers[i].health/towers[i].maxHealth > 0.15) and hero:GetDistance(candidate) > hero:GetDistance(towers[i]) then candidate = towers[i] end
		end
		return candidate
	else
		return nil
	end
end
--this function tells the bot which tower to go to when game begins
function BeginTower()
	if GetGame().map.index == 1 then
		if myHero.team == TEAM_BLUE then
			myHero:MoveTo(9919, 1064)
		else
			myHero:MoveTo(13539, 4717)
		end
	end
	if GetGame().map.index == 12 then
		if AllyTeamPosition == 1 then
			myHero:MoveTo(4130, 5108)
		else
			myHero:MoveTo(7602, 8449)
		end
	end
	if GetGame().map.index == 15 or GetGame().map.index == 0 then
		if AllyTeamPosition == 1 then
			myHero:MoveTo(9340, 2130)
		else
			myHero:MoveTo(12636, 5337)
		end
	end
	if GetGame().map.index == 10 then
		if AllyTeamPosition == 1 then
			myHero:MoveTo(4753, 4419)
		else
			myHero:MoveTo(10648, 4257)
		end
	end
end
function isRecalling(dc)
	local result = false
	if GetTickCount() - recallStartTime > 8000 then
		result = false
		return result
	else
		if recentrecallTarget.name == dc.name then
			result = true
			return result
		end
		return result
	end
end
function OnCreateObj(dc)
	if not config.enableScript then
		return
	end
	if dc ~= nil and (dc.name == "TeleportHomeImproved.troy" or dc.name == "TeleportHome.troy") then
		for i = 1, #MyTeam do
			local _d = MyTeam[i]
			if _d:GetDistance(dc) <= 70 then
				recentrecallTarget = _d
			end
		end
		recallStartTime = GetTickCount()
	end
end

----------------------------------PERFECT FOLLOW CODE-------------------
----------------------------------PERFECT FOLLOW CODE-------------------
----------------------------------AUTOBUY CLASS-------------------
----------------------------------AUTOBUY CLASS-------------------
class'ABUY'
function ABUY:__init(myHero)
	self.Sequence = {1036,1053,3144,1001,1042,3006,3153,1038,1037,1018,3031,3086,3046,3035,1011,3143,3101,3172}
	self.CAdc = {}
	self.CApc = {}
	self.CBruiser = {}
	self.CSupport = {}
	self.CTank = {}
	self.IAdc = {}
	self.IApc = {}
	self.IBruiser = {}
	self.ITank = {}
	self.ITank = {}
	self.Items = {}
	self.lBy = 0
	self.bDly = 1.5
	self.nBI = 1
	self.lastUpdate = 0
	self.BuyItemIndex = 1
end


function ABUY:OnLoad()
	self:SetABUYSequence()

end

function ABUY:OnTick()
	local osc = os.clock()
	if osc - self.lastUpdate > 1 then
		self.lastUpdate = osc
		if osc > self.lBy + self.bDly and (self.Sequence[self.nBI]) ~= nil then
			if myHero.level < 6 and myHero.gold > 950 then
				BuyItem(self.Sequence[self.nBI])
				self.lBy = os.clock()
				self.sBy = 1
				self.nBI = self.nBI + 1
			end
			if myHero.level > 5 and myHero.gold > (1.3 * myHero.level * 100) then
				BuyItem(self.Sequence[self.nBI])
				self.lBy = os.clock()
				self.sBy = 1
				self.nBI = self.nBI + 1
			end
		end
		if self.Sequence[self.nBI] == nil then
			self.nBI = 2
		end
		--GetInventorySlotItem always broken
		--[[
		if osc > self.lBy + self.bDly then
			if GetInventorySlotItem(self.Sequence[self.nBI]) ~= nil then
				--Last Buy successful
				self.sBy = 1
				self.nBI = self.nBI + 1
			else
				if type(self.Sequence[self.nBI]) == "number" then
					--Last Buy unsuccessful (buy again)
					BuyItem(self.Sequence[self.nBI])
					self.lBy = os.clock()
				end
			end
		end
		--]]
	end
end

function ABUY:SetABUYSequence()
	self.CAdc = {"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "KogMaw", "MissFortune", "Quinn", "Sivir", "Talon", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Zed", "Jinx", "Yasuo", "Lucian",}
	self.CApc = {"Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus", "Kassadin", "Katarina", "Kayle", "Kennen", "Leblanc", "Lissandra", "Lux", "Malzahar", "Mordekaiser", "Morgana", "Nidalee", "Orianna", "Ryze", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath" , "Ziggs", "Zyra", "Velkoz",}
	self.CBruiser = {"Bard", "Darius", "Elise", "Evelynn", "Fiora", "Gangplank", "Gnar", "Jayce", "Pantheon", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nocturne", "Olaf", "Poppy", "Renekton", "Rengar", "Riven", "Shyvana", "Trundle", "Tryndamere", "Udyr", "Vi", "MonkeyKing", "XinZhao", "Aatrox", "Rumble", "Sion", "Shaco", "MasterYi",}
	self.CSupport = {"Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Sona", "Soraka", "Thresh", "Zilean",}
	self.CTank = {"Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Shen", "Singed", "Skarner", "Volibear", "Warwick", "Yorick", "Zac", "Nunu", "Taric", "Alistar", "Garen", "Nautilus", "Braum",}
	self.IAdc = {1001,1042,3006--[[Bers Greaves]],1038,1037,1018,3031--[[Infinity Edge]],1042,1051,3086,1042,1018,3046--[[PHantom Dancer]],1037,1036,3035--[[Last Whisper]],1036,1053,1038,3508--[[Essence Reaver]],3102--[[Banshee's]]}
	self.IApc = {1001,3020--[[Sorc Shoes]],1027,1028,3010,1026,3027--[[RoA]],1052,1029,3191,1058,3157--[[Zhonya's]],1026,1058,3089--[[Deathcap]],1026,1052,3135--[[Void Staff]],3102--[[Banshee's]]}
	self.IBruiser = {1001,1033,3111--[[Merc Treads]],1036,1053,1036,3144,1042,3153--[[BOTRK]],1028,1033,3211,1028,3102--[[Banshee's]],1029,3082,1028,1011,3143--[[Randuin's Omen]],3071--[[Black Cleaver]]}
	self.ITank = {1001,1033,3111--[[Merc Treads]],1036,3134,1028,3071--[[Black Cleaver]],1029,1031,3068--[[Sunfire Cape]],1033,1036,3155,1037,3156--[[Maw of Malmortius]],1029,3082,1028,1011,3143--[[Randuin's Omen]],3074--[[Ravenous Hydra]]}
	self.Items = table.contains(self.CAdc,myHero.charName) and self.IAdc or table.contains(self.CApc,myHero.charName) and self.IApc or table.contains(self.CBruiser,myHero.charName) and self.IBruiser or table.contains(self.CSupport,myHero.charName) and self.IApc or table.contains(self.CTank,myHero.charName) and self.ITank or self.IAdc
	self.Sequence = self.Items
end

----------------------------------AUTOBUY CLASS-------------------
----------------------------------AUTOBUY CLASS-------------------
----------------------------------AUTOLEVEL CLASS-------------------
----------------------------------AUTOLEVEL CLASS-------------------
class'ALVL'
function ALVL:__init(myHero)
	self.lastUpdate = 0
	self.Sequence = {_Q,_E,_W,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E}
end


function ALVL:OnLoad()
	self:SetALVLSequence()
end

function ALVL:OnTick()
	local osc = os.clock()
	if osc - self.lastUpdate > 10 then
		self.lastUpdate = osc
		local TrueLevel = GetHeroLeveled()
		if myHero.level > TrueLevel then
			LevelSpell(self.Sequence[TrueLevel+1])
		end
	end
end


function ALVL:SetALVLSequence()
	local PredefinedSequence = {
		["Default"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Aatrox"] =        {_W,_Q,_E,_E,_E,_R,_E,_W,_E,_Q,_R,_W,_W,_Q,_W,_R,_Q,_Q,},
		["Ahri"] =          {_Q,_E,_Q,_W,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Akali"] =         {_Q,_W,_Q,_E,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Alistar"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Amumu"] =         {_W,_E,_E,_Q,_E,_R,_E,_E,_Q,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Anivia"] =        {_Q,_E,_E,_W,_E,_R,_E,_Q,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Annie"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Ashe"] =          {_W,_Q,_E,_Q,_E,_R,_Q,_E,_Q,_E,_R,_Q,_E,_W,_W,_R,_W,_W,},
		["Azir"] =          {_W,_Q,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Bard"] =          {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Blitzcrank"] =    {_Q,_E,_W,_Q,_Q,_R,_Q,_W,_Q,_E,_R,_W,_W,_E,_W,_R,_E,_E,},
		["Brand"] =         {_W,_Q,_W,_E,_W,_R,_W,_Q,_W,_Q,_R,_Q,_Q,_E,_E,_R,_W,_W,},
		["Braum"] =         {_Q,_E,_W,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Caitlyn"] =       {_Q,_E,_W,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Cassiopeia"] =    {_Q,_E,_W,_E,_E,_R,_E,_Q,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Chogath"] =       {_E,_Q,_W,_W,_W,_R,_W,_E,_W,_E,_R,_E,_E,_Q,_Q,_R,_Q,_Q,},
		["Corki"] =         {_Q,_E,_Q,_W,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Darius"] =        {_Q,_W,_Q,_E,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Diana"] =         {_Q,_W,_Q,_E,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Draven"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["DrMundo"] =       {_Q,_E,_Q,_W,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Elise"] =         {_W,_Q,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Evelynn"] =       {_W,_E,_W,_E,_E,_R,_Q,_E,_Q,_E,_R,_Q,_W,_Q,_W,_R,_W,_W,},
		["Ezreal"] =        {_Q,_W,_Q,_W,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_E,_E,_R,_E,_E,},
		["FiddleSticks"] =  {_Q,_E,_E,_Q,_E,_R,_Q,_E,_Q,_E,_R,_Q,_W,_W,_W,_R,_W,_W,},
		["Fiora"] =         {_W,_E,_W,_E,_W,_R,_Q,_W,_E,_W,_R,_E,_E,_Q,_Q,_R,_Q,_Q,},
		["Fizz"] =          {_W,_E,_W,_E,_Q,_R,_Q,_E,_Q,_E,_R,_E,_Q,_Q,_W,_R,_W,_W,},
		["Galio"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Gangplank"] =     {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Garen"] =         {_Q,_W,_E,_W,_W,_R,_Q,_W,_W,_Q,_R,_Q,_Q,_E,_E,_R,_E,_E,},
		["Gnar"] =          {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Gragas"] =        {_Q,_W,_Q,_W,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_E,_E,_R,_E,_E,},
		["Graves"] =        {_Q,_E,_Q,_W,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Hecarim"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Heimerdinger"] =  {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Irelia"] =        {_W,_W,_E,_E,_W,_R,_Q,_W,_W,_E,_R,_E,_Q,_E,_Q,_R,_Q,_Q,},
		["Janna"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_W,_E,_W,_R,_W,_W,},
		["JarvanIV"] =      {_Q,_E,_W,_Q,_Q,_R,_Q,_E,_W,_Q,_R,_E,_E,_W,_E,_R,_W,_W,},
		["Jax"] =           {_E,_W,_E,_W,_E,_R,_Q,_E,_E,_W,_R,_W,_W,_Q,_Q,_R,_Q,_Q,},
		["Jayce"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_W,_E,_W,_R,_W,_W,},
		["Jinx"] =          {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_E,_R,_E,_W,_E,_W,_R,_W,_E,},
		["Kalista"] =       {_Q,_E,_W,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Karthus"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_W,_E,_W,_R,_W,_W,},
		["Kassadin"] =      {_Q,_W,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_W,_E,_W,_R,_W,_W,},
		["Katarina"] =      {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Kayle"] =         {_W,_E,_Q,_W,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_Q,_R,_W,_W,},
		["Kennen"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Khazix"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["KogMaw"] =        {_W,_E,_W,_E,_W,_R,_W,_E,_W,_E,_R,_E,_Q,_Q,_Q,_R,_Q,_Q,},
		["Leblanc"] =       {_Q,_E,_W,_E,_W,_R,_W,_E,_W,_E,_R,_E,_Q,_Q,_Q,_R,_Q,_W,},
		["LeeSin"] =        {_Q,_E,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_Q,_Q,_Q,_R,_E,_W,},
		["Leona"] =         {_Q,_W,_Q,_W,_Q,_R,_E,_W,_W,_W,_R,_Q,_Q,_E,_E,_R,_E,_E,},
		["Lissandra"] =     {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Lucian"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Lulu"] =          {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Lux"] =           {_E,_Q,_W,_E,_E,_R,_E,_Q,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Malphite"] =      {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Malzahar"] =      {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Maokai"] =        {_E,_Q,_E,_Q,_W,_R,_E,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["MasterYi"] =      {_Q,_W,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["MissFortune"] =   {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Mordekaiser"] =   {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Morgana"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Nami"] =          {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Nasus"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Nautilus"] =      {_W,_E,_W,_E,_W,_R,_Q,_W,_E,_W,_R,_E,_E,_Q,_Q,_R,_Q,_Q,},
		["Nidalee"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_W,_E,_W,_R,_W,_W,},
		["Nocturne"] =      {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Nunu"] =          {_Q,_W,_E,_W,_E,_R,_Q,_E,_E,_W,_R,_W,_E,_W,_Q,_R,_Q,_Q,},
		["Olaf"] =          {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Orianna"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Pantheon"] =      {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Poppy"] =         {_Q,_W,_Q,_W,_E,_R,_Q,_Q,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Quinn"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Rammus"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["RekSai"] =        {_Q,_W,_Q,_W,_E,_R,_Q,_Q,_Q,_E,_R,_E,_E,_E,_W,_R,_W,_W,},
		["Renekton"] =      {_Q,_W,_Q,_W,_E,_R,_Q,_Q,_Q,_E,_R,_E,_E,_E,_W,_R,_W,_W,},
		["Rengar"] =        {_Q,_E,_W,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Riven"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Rumble"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Ryze"] =          {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Sejuani"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Shaco"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Shen"] =          {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Shyvana"] =       {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Singed"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_E,_W,_E,_R,_E,_E,},
		["Sion"] =          {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Sivir"] =         {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Skarner"] =       {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Sona"] =          {_Q,_W,_Q,_W,_E,_R,_Q,_W,_Q,_W,_R,_Q,_W,_E,_E,_R,_E,_E,},
		["Soraka"] =        {_W,_Q,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Swain"] =         {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Syndra"] =        {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Talon"] =         {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Taric"] =         {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Teemo"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Thresh"] =        {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Tristana"] =      {_Q,_E,_E,_Q,_E,_R,_E,_W,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Trundle"] =       {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Tryndamere"] =    {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["TwistedFate"] =   {_W,_Q,_Q,_E,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Twitch"] =        {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Udyr"] =          {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Urgot"] =         {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Varus"] =         {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Vayne"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Veigar"] =        {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Velkoz"] =        {_W,_E,_Q,_W,_W,_R,_W,_Q,_W,_Q,_R,_Q,_Q,_E,_E,_R,_E,_E,},
		["Vi"] =            {_W,_E,_W,_E,_Q,_R,_E,_E,_E,_W,_R,_W,_W,_Q,_Q,_R,_Q,_Q,},
		["Viktor"] =        {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Vladimir"] =      {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Volibear"] =      {_W,_Q,_E,_W,_W,_R,_W,_E,_W,_E,_R,_E,_E,_Q,_Q,_R,_Q,_Q,},
		["Warwick"] =       {_Q,_W,_E,_Q,_Q,_R,_E,_E,_Q,_E,_R,_Q,_E,_W,_W,_R,_W,_W,},
		["MonkeyKing"] =    {_Q,_W,_Q,_W,_E,_R,_Q,_Q,_Q,_E,_R,_E,_E,_E,_W,_R,_W,_W,},
		["Xerath"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["XinZhao"] =       {_Q,_W,_Q,_W,_E,_R,_Q,_Q,_Q,_E,_R,_E,_E,_E,_W,_R,_W,_W,},
		["Yasuo"] =         {_Q,_E,_W,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Yorick"] =        {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Zac"] =           {_Q,_W,_Q,_W,_E,_R,_W,_W,_W,_Q,_R,_Q,_Q,_E,_E,_R,_E,_E,},
		["Zed"] =           {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
		["Ziggs"] =         {_Q,_W,_E,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W,},
		["Zilean"] =        {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E,},
		["Zyra"] =          {_Q,_W,_E,_E,_E,_R,_Q,_E,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W,},
	}
	if PredefinedSequence[myHero.charName] then
		self.Sequence =PredefinedSequence[myHero.charName]
	else
		self.Sequence =PredefinedSequence["Default"]
	end
end
----------------------------------AUTOLEVEL CLASS----------------
----------------------------------AUTOLEVEL CLASS----------------
----------------------------------COMBAT CLASS-------------------
----------------------------------COMBAT CLASS-------------------
class'ACOMBAT'
function ACOMBAT:__init(myHero)
	self.ts = nil
	self.Test = 0
	self.Data = {}
	self.LB_Debug = false
	self.Debug = function(msg)
	if self.LB_Debug then
		print("LegendBot DEBUG: "..tostring(msg))
	end
	end
end

function ACOMBAT:OnLoad()
	self.ts = TargetSelector(TARGET_CLOSEST, 1150, DAMAGE_PHYSICAL, false) --TARGET_LOW_HP
	self.allyMinions = minionManager(MINION_ALLY, 10000, myHero, MINION_SORT_HEALTH_ASC)
	self:ChampionData()
	self.selectedTeammate = myHero
	--AddTickCallback(function() ActiveLogic() end)
end

function ACOMBAT:OnTick()
	--[[self.ts:update()
	if self.ts.target ~= nil then
		if GetDistance(myHero,self.ts.target) > 1000 then return end
		--self.Data[myHero.charName].Combo()
	end
	]]
end
function ACOMBAT:Cast(spell,r1,r2)
		self.Debug("Attempting to Cast")
	if myHero:CanUseSpell(spell) ~= READY then return end
	if GetTickCount() < (SpellCastTick or 0) then return end
	SpellCastTick = GetTickCount() + 250
	if r1 ~= nil and r2 ~= nil then
		CastSpell(spell,r1,r2)
				self.Debug("Attempting to Cast 12")
	elseif r1 ~= nil then
		CastSpell(spell,r1)
				self.Debug("Attempting to Cast 1")
	else
		CastSpell(spell)
				self.Debug("Attempting to Cast 0")
	end
end
function ACOMBAT:CastBubbleAlly(range)
	if self.ts.target ~= nil then
		self.selectedTeammate = myHero
		for i = 1, heroManager.iCount, 1 do
			local teammates = heroManager:getHero(i)
			if teammates.health/teammates.maxHealth < self.selectedTeammate.health/self.selectedTeammate.maxHealth and teammates.dead == false and
			teammates.team == myHero.team and GetDistance(teammates,myHero) < range and GetDistance(teammates,self.ts.target) < 700 then
				self.selectedTeammate = teammates
			end
		end
		if self.selectedTeammate.health/self.selectedTeammate.maxHealth < 0.25 then
			return self.selectedTeammate
		else
			return false
		end
	end
end
function ACOMBAT:CastHealAlly(range)
	if self.ts.target ~= nil then
		self.selectedTeammate = myHero
		for i = 1, heroManager.iCount, 1 do
			local teammates = heroManager:getHero(i)
			if teammates.health/teammates.maxHealth < self.selectedTeammate.health/self.selectedTeammate.maxHealth and teammates.dead == false and
			teammates.team == myHero.team and GetDistance(teammates,myHero) < range then
				self.selectedTeammate = teammates
			end
		end
		if self.selectedTeammate.health/self.selectedTeammate.maxHealth < 0.55 then
			return self.selectedTeammate
		else
			return false
		end
	end
end


function ACOMBAT:ChampionData()
	self.Test = 5
	self.Data = {
		AP = {1001,3020,1027,1028,3010,1026,3027,1052,1029,3191,1058,3157,1026,1058,3089,1026,1052,3135,3102},
		ADC = {1001,1042,3006,1038,1037,1018,3031,1042,1051,3086,1042,1018,3046,1037,1036,3035,1036,1053,1038,3508,3102},
		ADTank = {1001,1033,3111,1036,3134,1028,3071,1028,1011,1029,1031,3068,1033,1036,3155,1037,3156,1029,3082,1028,1011,3143,3074},
		APTank = {1001,1011,3009,3068,3105,3190,3067,3050,3082,3143,1057,3065},
		Support = {1001,1033,3111,1028,1033,3211,1028,3102,1033,1028,1006,3105,1028,3067,3190,1028,3067,1036,1053,3050,3068},
		ADBruiser = {1001,1033,3111,1036,1053,1036,3144,1042,3153,1028,1033,3211,1028,3102,1029,3082,1028,1011,3143,3071},

	}
	self.Data["UNK"] = {
		SpellRange = {600,600,600,600},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Aatrox"] = {
		SpellRange = {650,450,1000,300},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then
				if myHero:GetSpellData(_W).name == "aatroxw2" and (myHero.health/myHero.maxHealth) < 0.4 then
					self:Cast(_W)
				elseif myHero:GetSpellData(_W).name == "AatroxW" and (myHero.health/myHero.maxHealth) > 0.6 then
					self:Cast(_W)
				end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,

	}
	self.Data["Ahri"] = {
		SpellRange = {880,800,975,500},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Akali"] = {

		SpellRange = {600,800,250,800},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Alistar"] = {
		SpellRange = {365,650,575,700},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if myHero.health/myHero.maxHealth < 0.8 then self:Cast(_E) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if myHero.health/myHero.maxHealth < 0.4 then self:Cast(_R) end
			end
		end,
	}
	self.Data["Amumu"] = {
		SpellRange = {1100,400,200,500},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Anivia"] = {
		SpellRange = {1100,1000,650,625},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Annie"] = {
		SpellRange = {625,600,1000,600},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Ashe"] = {
		SpellRange = {0,1100,1500,2000},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Azir"] = {
		SpellRange = {1300,1300,1300,400},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Blitzcrank"] = {
		SpellRange = {950,400,400,600},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Brand"] = {
		SpellRange = {900,900,625,750},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Braum"] = {
		SpellRange = {1000,650,500,1250},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,myHero) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Caitlyn"] = {
		SpellRange = {1300,800,1000,3000},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Cassiopeia"] = {
		SpellRange = {850,850,700,850},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Chogath"] = {
		SpellRange = {1000,700,350,500},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if myHero:CanUseSpell(_E) ~= READY then return end
				if CastEOnce ~= true then self:Cast(_E) CastEOnce = true end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if getDmg("R",self.ts.target,myHero,3) + 50 > self.ts.target.health then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
			end
		end,
	}
	self.Data["Corki"] = {
		SpellRange = {600,800,600,1225},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Darius"] = {
		SpellRange = {425,250,550,475},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if getDmg("R",self.ts.target,myHero,3) then self:Cast(_R,self.ts.target) end
			end
		end,
	}
	self.Data["Diana"] = {
		SpellRange = {830,400,400,825},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["DrMundo"] = {
		SpellRange = {1000,325,325,1000},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if myHero.health/myHero.maxHealth <= 0.4 then self:Cast(_R) end
			end
		end,
	}
	self.Data["Draven"] = {
		SpellRange = {580,700,1050,5000},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Elise"] = {
		SpellRange = {625,950,1075,600},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetSpellData(_E).name == "EliseHumanE" then
				Human = true
			else
				Human = false
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then
				if Human then self:Cast(_W,self.ts.target.x,self.ts.target.z) else self:Cast(_W) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if Human then self:Cast(_E,self.ts.target.x,self.ts.target.z) else self:Cast(_E,self.ts.target) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then if math.random(1,10) > 5 then self:Cast(_R) end end
		end,
	}
	self.Data["Evelynn"] = {
		SpellRange = {500,300,225,650},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Ezreal"] = {
		SpellRange = {1100,900,750,5000},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Fiddlesticks"] = {
		SpellRange = {575,475,750,800},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Fiora"] = {
		SpellRange = {600,400,400,450},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Fizz"] = {
		SpellRange = {550,550,700,650},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Galio"] = {
		SpellRange = {940,800,1100,540},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,myHero) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Gangplank"] = {
		SpellRange = {650,625,649,5000},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Garen"] = {
		SpellRange = {400,0,350,400},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if GetTickCount() < (GarenSpinningTick or 0) then return end
				GarenSpinningTick = GetTickCount() + 2600
				self:Cast(_E,self.ts.target.x,self.ts.target.z)
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if getDmg("R",self.ts.target,myHero) > self.ts.target.health then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
			end
		end,
	}
	self.Data["Gnar"] = {
		SpellRange = {1100,525,475,490},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Gragas"] = {
		SpellRange = {1110,1500,800,1050},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Graves"] = {
		SpellRange = {550,850,425,900},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Hecarim"] = {
		SpellRange = {400,525,400,1000},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Heimerdinger"] = {
		SpellRange = {525,1100,925,1000},
		ItemOrder = self.Data["AP"],
		Combo = function()
		if GetDistance(self.ts.target) < 900 then
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q, myHero.x, myHero.z) end
		end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_R) self:Cast(_E,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Irelia"] = {
		SpellRange = {650,625,425,1000},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Janna"] = {
		SpellRange = {1100,600,800,700},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,myHero) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if myHero.health/myHero.maxHealth < 0.6 then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
			end
		end,
	}
	self.Data["JarvanIV"] = {
		SpellRange = {750,300,800,650},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Jax"] = {
		SpellRange = {700,300,300,550},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Jayce"] = {
		SpellRange = {1000,700,600,500},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetSpellData(_E).name == "jayceaccelerationgate" then
				RangedForm = true
			else
				RangedForm = false
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then
				if RangedForm then self:Cast(_Q,self.ts.target.x,self.ts.target.z) else self:Cast(_Q,self.ts.target) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then
				if RangedForm then self:Cast(_W,self.ts.target.x,self.ts.target.z) else CastSpell(_W) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if RangedForm then self:Cast(_E,self.ts.target.x,self.ts.target.z) else self:Cast(_E,self.ts.target) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Jinx"] = {
		SpellRange = {600,1500,900,5000},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Kalista"] = {
		SpellRange = {1100,0,1000,1500},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Karma"] = {
		SpellRange = {950,650,800,1000},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_R) self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if myHero.health/myHero.maxHealth < 0.3 then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			end
		end,
	}
	self.Data["Karthus"] = {
		SpellRange = {875,1000,550,2000},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) > self.Data[myHero.charName]["SpellRange"][4] then
				if getDmg("R",self.ts.target,myHero) > self.ts.target.health then self:Cast(_R) end
			end
		end,
	}
	self.Data["Kassadin"] = {
		SpellRange = {650,300,400,700},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Katarina"] = {
		SpellRange = {675,375,700,500},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if GetTickCount() < (KatarinaSpinTick or 0) then return end
				KatarinaSpinTick = GetTickCount() + 3000
				self:Cast(_R)
			end
		end,
	}
	self.Data["Kayle"] = {
		SpellRange = {650,625,649,900},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then
				if myHero.health/myHero.maxHealth < 0.6 then self:Cast(_W,myHero) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			local BubbleAlly = self:CastBubbleAlly( self.Data[myHero.charName]["SpellRange"][4])
			if CastBubbleAlly ~= false then self:Cast(_R,BubbleAlly) end
		end,
	}
	self.Data["Kennen"] = {
		SpellRange = {1000,600,600,550},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Khazix"] = {
		SpellRange = {325,1000,600,400},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Kogmaw"] = {
		SpellRange = {625,0,1000,0},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Leblanc"] = {
		SpellRange = {700,600,900,700},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) self:Cast(_R,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["LeeSin"] = {
		SpellRange = {975,700,550,375},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then
				if myHero.health/myHero.maxHealth < 0.7 then self:Cast(_W,myHero) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Leona"] = {
		SpellRange = {250,400,700,1200},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Lissandra"] = {
		SpellRange = {725,450,1050,550},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if GetTickCount() < (LissandraClawTick or 0) then return end
				LissandraClawTick = GetTickCount() + 750
				self:Cast(_E,self.ts.target.x,self.ts.target.z)
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Lucian"] = {
		SpellRange = {550,1000,425,1200},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if GetTickCount() < (LucianUltiTick or 0) then return end
				LucianUltiTick = GetTickCount() + 2500
				self:Cast(_R,self.ts.target.x,self.ts.target.z)
			end
		end,
	}
	self.Data["Lulu"] = {
		SpellRange = {925,650,650,900},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			local BubbleAlly = self:CastBubbleAlly( self.Data[myHero.charName]["SpellRange"][4])
			if CastBubbleAlly ~= false then self:Cast(_R,BubbleAlly) end
		end,
	}
	self.Data["Lux"] = {
		SpellRange = {1175,1075,1100,3000},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then
				if myHero.health/myHero.maxHealth < 0.7 then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Malphite"] = {
		SpellRange = {625,625,200,1000},
		ItemOrder = self.Data["APTank"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Malzahar"] = {
		SpellRange = {900,800,650,700},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if GetTickCount() < (MalzaharUltiTick or 0) then return end
				MalzaharUltiTick = GetTickCount() + 2500
				self:Cast(_R,self.ts.target)
			end
		end,
	}
	self.Data["Maokai"] = {
		SpellRange = {600,650,1100,625},
		ItemOrder = self.Data["APTank"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if GetTickCount() < (MaokaiUltiTick or 0) then return end
				MaokaiUltiTick = GetTickCount() + 3000
				self:Cast(_R,self.ts.target.x,self.ts.target.z)
			end
		end,
	}
	self.Data["MasterYi"] = {
		SpellRange = {600,800,200,610},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then
				if myHero.health/myHero.maxHealth < 0.5 then self:Cast(_W) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["MissFortune"] = {
		SpellRange = {650,650,800,1400},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Mordekaiser"] = {
		SpellRange = {300,800,650,700},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,myHero) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if getDmg("R",self.ts.target,myHero,3) > self.ts.target.health then self:Cast(_R,self.ts.target) end
			end
		end,
	}
	self.Data["Morgana"] = {
		SpellRange = {1300,900,750,500},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,myHero) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Nami"] = {
		SpellRange = {900,800,650,700},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,myHero) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Nasus"] = {
		SpellRange = {650,700,650,0},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if myHero.health/myHero.maxHealth < 0.6 then self:Cast(_R) end
			end
		end,
	}
	self.Data["Nautilus"] = {
		SpellRange = {950,700,600,850},
		ItemOrder = self.Data["APTank"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Nidalee"] = {
		SpellRange = {1500,500,300,375},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetSpellData(_Q).name == "JavelinToss" then
				Human = true
			else
				Human = false
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then
				if Human then self:Cast(_Q,self.ts.target.x,self.ts.target.z) else self:Cast(_Q) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if Human then if myHero.health/myHero.maxHealth < 0.6 then self:Cast(_E,myHero) end else self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then if math.random(1,10) > 6 then self:Cast(_R,self.ts.target.x,self.ts.target.z) end end
		end,
	}
	self.Data["Nocturne"] = {
		SpellRange = {1200,700,450,1500},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Nunu"] = {
		SpellRange = {150,700,550,500},
		ItemOrder = self.Data["APTank"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if GetTickCount() < (NunuUltiTick or 0) then return end
				NunuUltiTick = GetTickCount() + 5000
				self:Cast(_R) end
		end,
	}
	self.Data["Olaf"] = {
		SpellRange = {1000,250,325,550},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Orianna"] = {
		SpellRange = {815,800,1100,800},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,myHero) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Pantheon"] = {
		SpellRange = {600,600,600,2000},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if GetTickCount() < (PantheonUltiTick or 0) then return end
				PantheonUltiTick = GetTickCount() + 5000
				self:Cast(_R,self.ts.target.x,self.ts.target.z)
			end
		end,
	}
	self.Data["Poppy"] = {
		SpellRange = {650,700,650,350},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Quinn"] = {
		SpellRange = {1025,2100,750,700},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then if math.random(1,10) < 6 then self:Cast(_R,self.ts.target.x,self.ts.target.z) end end
		end,
	}
	self.Data["Rammus"] = {
		SpellRange = {650,700,325,350},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then
				if GetTickCount() < (RammusBallTick or 0) then return end
				RammusBallTick = GetTickCount() + 10000
				self:Cast(_Q,self.ts.target.x,self.ts.target.z)
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["RekSai"] = {
		SpellRange = {500,500,450,8000},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetSpellData(_Q).name == "reksaiqburrowed" then
				Burrowed = true
			else
				Burrowed = false
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then
				if Burrowed then self:Cast(_Q,self.ts.target.x,self.ts.target.z) else self:Cast(_Q) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if Burrowed then self:Cast(_E,self.ts.target.x,self.ts.target.z) else self:Cast(_E,self.ts.target) end
			end
		end,
	}
	self.Data["Renekton"] = {
		SpellRange = {250,460,450,800},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Rengar"] = {
		SpellRange = {300,500,575,700},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Riven"] = {
		SpellRange = {300,150,325,900},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Rumble"] = {
		SpellRange = {600,800,850,1700},
		ItemOrder = self.Data["APTank"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Ryze"] = {
		SpellRange = {600,600,600,425},
		ItemOrder = self.Data["APTank"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Sejuani"] = {
		SpellRange = {700,350,900,1100},
		ItemOrder = self.Data["APTank"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Shaco"] = {
		SpellRange = {400,425,625,800},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Shen"] = {
		SpellRange = {475,800,575,10000},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			local BubbleAlly = self:CastBubbleAlly( self.Data[myHero.charName]["SpellRange"][4])
			if CastBubbleAlly ~= false then self:Cast(_R,BubbleAlly) end
		end,
	}
	self.Data["Shyvana"] = {
		SpellRange = {300,200,925,1000},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Singed"] = {
		SpellRange = {500,1000,150,1000},
		ItemOrder = self.Data["APTank"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Sion"] = {
		SpellRange = {550,550,300,600},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
		   if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
		   if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
		   if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
		   -- if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Sivir"] = {
		SpellRange = {1000,550,550,600},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Skarner"] = {
		SpellRange = {550,600,400,300},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Sona"] = {
		SpellRange = {700,1000,1000,1000},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			local HealAlly = self:CastHealAlly( self.Data[myHero.charName]["SpellRange"][2])
			if HealAlly ~= false then self:Cast(_W, HealAlly) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Soraka"] = {
		SpellRange = {970,550,925,10000},
		ItemOrder = self.Data["Support"],
		Combo = function()
		local HealAlly = self:CastHealAlly( self.Data[myHero.charName]["SpellRange"][2])
		local UltAlly = self:CastHealAlly( self.Data[myHero.charName]["SpellRange"][4])
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then CastSpell(_Q,self.ts.target.x,self.ts.target.z) end
			if HealAlly ~= false and HealAlly ~= myHero then CastSpell(_W, HealAlly) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if UltAlly ~= false and UltAlly.health/UltAlly.maxHealth < 0.25 then self:Cast(_R) end
		end,
	}
	self.Data["Swain"] = {
		SpellRange = {625,900,625,700},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Syndra"] = {
		SpellRange = {800,925,600,675},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Talon"] = {
		SpellRange = {300,600,700,500},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Taric"] = {
		SpellRange = {750,400,625,200},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,myHero) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Teemo"] = {
		SpellRange = {580,450,0,230},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Thresh"] = {
		SpellRange = {1075,950,500,400},
		ItemOrder = self.Data["Support"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Tristana"] = {
		SpellRange = {650,900,800,700},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Trundle"] = {
		SpellRange = {250,900,1000,700},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Tryndamere"] = {
		SpellRange = {500,400,660,800},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then
				if myHero.health/myHero.maxHealth < 0.6 then self:Cast(_Q) end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then
				if myHero.health/myHero.maxHealth < 0.3 then self:Cast(_R) end
			end
		end,
	}
	self.Data["TwistedFate"] = {
		SpellRange = {1450,650,0,0},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"]["SpellRange"][2] then
				if myHero:GetSpellData(_W).name == "redcardlock" and (myHero.mana / myHero.maxMana) > 0.8 then
					CastSpell(_W)
				elseif myHero:GetSpellData(_W).name == "goldcardlock" and (myHero.mana / myHero.maxMana) > 0.4 then
					CastSpell(_W)
				elseif myHero:GetSpellData(_W).name == "bluecardlock" and (myHero.mana / myHero.maxMana) < 0.4 then
					CastSpell(_W)
				else
					CastSpell(_W)
				end
			end
		end,
	}
	self.Data["Twitch"] = {
		SpellRange = {1200,950,1200,850},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Udyr"] = {
		SpellRange = {300,800,300,300},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Urgot"] = {
		SpellRange = {1000,800,900,600},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Varus"] = {
		SpellRange = {850,0,925,800},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then CastSpell2(_Q,self.ts.target.x,self.ts.target.y,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Vayne"] = {
		SpellRange = {580,0,650,650},
		ItemOrder = self.Data["ADC"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Veigar"] = {
		SpellRange = {650,900,600,650},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Velkoz"] = {
		SpellRange = {1075,1075,850,1575},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Vi"] = {
		SpellRange = {725,0,400,700},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then CastSpell2(_Q,self.ts.target.x,self.ts.target.y,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Viktor"] = {
		SpellRange = {600,625,540,700},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Vladimir"] = {
		SpellRange = {600,500,610,700},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Volibear"] = {
		SpellRange = {500,400,425,300},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R) end
		end,
	}
	self.Data["Warwick"] = {
		SpellRange = {400,600,0,700},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then
				if myHero:CanUseSpell(_E) ~= READY then return end
				if CastEOnce ~= true then self:Cast(_E) CastEOnce = true end
			end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Wukong"] = {
		SpellRange = {300,500,625,300},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Xerath"] = {
		SpellRange = {900,900,600,3200},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then CastSpell2(_Q,self.ts.target.x,self.ts.target.y,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["XinZhao"] = {
		SpellRange = {300,300,600,500},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Yasuo"] = {
		SpellRange = {950,750,475,1500},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Yorick"] = {
		SpellRange = {300,600,550,900},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,myHero) end
		end,
	}
	self.Data["Zac"] = {
		SpellRange = {550,350,900,400},
		ItemOrder = self.Data["APTank"],
		 Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Zed"] = {
		SpellRange = {900,550,300,625},
		ItemOrder = self.Data["ADBruiser"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target) end
		end,
	}
	self.Data["Ziggs"] = {
		SpellRange = {850,1000,900,5300},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	self.Data["Zilean"] = {
		SpellRange = {700,500,700,900},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:CanUseSpell(_Q) ~= READY then self:Cast(_W) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E, self.ts.target) end
			local BubbleAlly = self:CastBubbleAlly( self.Data[myHero.charName]["SpellRange"][4])
			if CastBubbleAlly ~= false then self:Cast(_R,BubbleAlly) end
		end,
	}
	self.Data["Zyra"] = {
		SpellRange = {825,825,1000,700},
		ItemOrder = self.Data["AP"],
		Combo = function()
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][1] then self:Cast(_Q,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][2] then self:Cast(_W,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][3] then self:Cast(_E,self.ts.target.x,self.ts.target.z) end
			if myHero:GetDistance(self.ts.target) < self.Data[myHero.charName]["SpellRange"][4] then self:Cast(_R,self.ts.target.x,self.ts.target.z) end
		end,
	}
	if self.Data[myHero.charName] == nil then
		self.Data[myHero.charName] = self.Data["UNK"]
	end
end

----------------------------------COMBAT CLASS-------------------
----------------------------------COMBAT CLASS-------------------