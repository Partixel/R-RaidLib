local Players = game:GetService("Players")

local Core = require(game:GetService("ReplicatedStorage"):WaitForChild("S2"):WaitForChild("Core"))
local RaidLib = require(script.RaidLib.Value)

local CurrentMap
local function LoadMap(Map)
	if CurrentMap then
		CurrentMap:Destroy()
	end
	
	CurrentMap = Map:Clone()
	CurrentMap.Parent = workspace
	
	for _, Obj in ipairs(CurrentMap:GetChildren()) do
		if Obj:IsA("TerrainRegion") then
			local Corner = Obj:FindFirstChild("Corner") and Obj.Corner.Value or workspace.Terrain.MaxExtents.Min
			Corner = Vector3int16.new(Corner.X, Corner.Y, Corner.Z)
			workspace.Terrain:PasteRegion(Obj, Corner, true)
		end
	end
end

return function(Main, ModFolder, VH_Events)
	
	if Main.Config.ReservedFor then
		
		RaidLib.MaxPlayers = Players.MaxPlayers - (Main.Config.ReservedSlots or 1)
		
	end
	
	Main.Commands["ForceOfficial"] = {
		
		Alias = {Main.TargetLib.AliasTypes.Toggle(1, 6, "forceofficial", "forceraid")},
		
		Description = "Forces the raid official/unofficial",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = {{Func = Main.TargetLib.ArgTypes.Boolean, Default = Main.TargetLib.Defaults.Toggle, ToggleValue = function() return RaidLib.OfficialRaid.Value end}},
		
		Callback = function(self, Plr, Cmd, Args, NextCmds, Silent)
			
			if RaidLib.OfficialRaid.Value == Args[1] then return false, "Already " .. (Args[1] and "official" or "unofficial") end
			
			if Args[1] then
				
				RaidLib.Forced = true
				
				RaidLib.StartRaid()
				
			else
				
				RaidLib.EndRaid("Forced")
				
			end
			
			return true
			
		end
		
	}
	
	Main.Commands["Official"] = {
		
		Alias = {"official", "raid"},
		
		Description = "Makes the raid official",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = {},
		
		Callback = function(self, Plr, Cmd, Args, NextCmds, Silent)
			
			if not RaidLib.ManualStart then return false, "Raid will automatically start\nUse 'forceofficial/true' to force start the raid" end
			
			if RaidLib.OfficialRaid.Value == true then return false, "Already official" end
			
			local Ran = RaidLib.OfficialCheck(true)
			
			if Ran then
				
				return false, Ran
				
			end
			
			return true
			
		end
		
	}
	
	Main.Commands["PracticeOfficial"] = {
		
		Alias = {"practiceofficial", "practiceraid", "pr"},
		
		Description = "Makes the raid official",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = {},
		
		Callback = function(self, Plr, Cmd, Args, NextCmds, Silent)
			
			if RaidLib.OfficialRaid.Value == true then return false, "Already official" end
			
			if not RaidLib.GameMode then return false, "RaidLib hasn't loaded yet" end
			
			RaidLib.Forced = true
			
			RaidLib.Practice = true
			
			RaidLib.StartRaid()
			
			return true
			
		end
		
	}
	
	Main.Commands["AddOvertime"] = {
		
		Alias = {"addovertime"},
		
		Description = "Adds the specified amount of overtime",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = {{Func = Main.TargetLib.ArgTypes.Time, Required = true}},
		
		Callback = function(self, Plr, Cmd, Args, NextCmds, Silent)
			
			if not RaidLib.RaidStart then return false, "Raid isn't official" end
			
			RaidLib.AddTimeToRaidLimit(Args[1])
			
			return true
			
		end
		
	}
	
	Main.Commands["SetOvertime"] = {
		
		Alias = {"setovertime"},
		
		Description = "Sets the overtime to the specified value",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = {{Func = Main.TargetLib.ArgTypes.Time, Required = true}},
		
		Callback = function(self, Plr, Cmd, Args, NextCmds, Silent)
			
			if not RaidLib.RaidStart then return false, "Raid isn't official" end
			
			RaidLib.SetRaidLimit(Args[1])
			
			return true
			
		end
		
	}
	
	
	local Current
	Main.Commands["Difficulty"] = {
		
		Alias = {"difficulty", "setdifficulty", "dif"},
		
		Description = "Sets the difficulty of the raid",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = {{Func = function(self, Strings, Plr)
					local String = string.lower(table.remove(Strings, 1))
					
					if String == Main.TargetLib.ValidChar then
						return  RaidLib.Difficulties[RaidLib.Difficulties[1]]
					else
						local Found, Exact
						for k, v in pairs(RaidLib.Difficulties) do
							if k ~= 1 then
								if string.lower(k) == String then
									Found, Exact = k, true
									break
								elseif not Exact and string.sub(k, 1, #String):lower() == String then
									Found = k
								end
							end
						end
						
						if Found then
							return RaidLib.Difficulties[Found]
						end
					end
				end, Name = "Difficulty", Required = true}},
		
		Callback = function(self, Plr, Cmd, Args, NextCmds, Silent)
			
			if not RaidLib.Difficulties then return false, "No difficulty options available" end
			
			if RaidLib.RaidStart then return false, "Cannot change difficulty once raid has started" end
			
			if Args[1] == Current then return false, "Already that difficulty" end
			
			Current = Args[1]
			local Map = Current()
			if Map then
				LoadMap(Map)
			end
			
			return true
			
		end
		
	}
	
	if RaidLib.Difficulties then
		Current = RaidLib.Difficulties[RaidLib.Difficulties[1]]
		local Map = Current()
		if Map then
			LoadMap(Map)
		end
		
		Main.Commands.Difficulty.ArgTypes[1].Name = (function() local t = {} for k, _ in pairs(RaidLib.Difficulties) do if k ~= 1 then t[#t + 1] = k end end return table.concat(t, "_") end)()
	end
	RaidLib.Event_ResetAll.Event:Connect(function()
		if RaidLib.Difficulties then
			Current = RaidLib.Difficulties[RaidLib.Difficulties[1]]
			local Map = Current()
			if Map then
				LoadMap(Map)
			end
			
			Main.Commands.Difficulty.ArgTypes[1].Name = (function() local t = {} for k, _ in pairs(RaidLib.Difficulties) do if k ~= 1 then t[#t + 1] = k end end return table.concat(t, "_") end)()
		end
	end)
end