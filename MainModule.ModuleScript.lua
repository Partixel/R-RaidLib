if _G.RaidLib then
	warn("RaidLib already required, using existing running RaidLib:\n" .. debug.traceback())
	return _G.RaidLib
end

script.Parent = game:GetService("ServerStorage")

local CollectionService, TweenService, Debris, Players, GroupService, HttpService, RunService = game:GetService("CollectionService"), game:GetService("TweenService"), game:GetService("Debris"), game:GetService("Players"), game:GetService("GroupService"), game:GetService("HttpService"), game:GetService("RunService")

local LoaderModule = require(game:GetService("ServerStorage"):FindFirstChild("LoaderModule") and game:GetService("ServerStorage").LoaderModule:FindFirstChild("MainModule") or 03593768376)("RaidLib")

if not game:GetService("ServerStorage"):FindFirstChild("VH_Command_Modules") then
	local Folder = Instance.new("Folder")
	Folder.Name = "VH_Command_Modules"
	Folder.Parent = game:GetService("ServerStorage")
end
script.VH_Command_Modules.RaidLib.RaidLib.Value = script
LoaderModule(script:WaitForChild("VH_Command_Modules"), game:GetService("ServerStorage").VH_Command_Modules)

local RaidLib = {
	
	RaidLimit = 60 * 60 * 2.5, -- How long a raid can go before the away team lose, 2.5 hours
	
	HomeTeams = {}, -- Teams that can capture for the home group
	
	HomeRequired = 1, -- How many of the home teams are required for capturepoints to be taken
	
	AwayTeams = {}, -- Teams that can raid
	
	AwayRequired = 1, -- How many of the home teams are required for capturepoints to be taken
	
	RespawnAllPlayers = true, -- Respawns all the players at the start of the raid if this is true
	
	EqualTeams = false, -- If true, raid will only be started if teams are equal
	
	LockTeams = false, -- If true, teams will be limited to the same size when people leave
	
	ManualStart = false, -- If true, raid can only be started by command
	
	SingleSpawnPoints = true, -- If true any spawn points at capture points required by the captured point will be disabled
	
	GracePeriod = 15, -- The away team won't be able to move when the raid starts for this period of time
	
	BanWhenWinOrLoss = false, -- Do the away team get banned when raid limit is reached or they win? (Require V-Handle admin)
	
	CaptureSpeed = 1, -- The speed at which points are captured as a percentage of the normal speed (1 = 100%, 0.5 = 50%)
	
	AwayCaptureSpeed = 1, -- The speed at which points are captured relative to CaptureSpeed (1 = 100% of normal speed, 0.5 = 50% normal)
	
	MaxPlrMultiplier = 100, -- Up to this many players will increase the speed of capturing a capture point

	-- NO TOUCHY --
	
	GameTick = 1,
	
	CapturePoints = {},
	
	RequiredCapturePoints = {},
	
	Event_PreMatchStarted = Instance.new("BindableEvent"),
	
	Event_RaidEnded = Instance.new("BindableEvent"),
	
	Event_WinChanged = Instance.new("BindableEvent"),
	
	Event_OfficialCheck = Instance.new("BindableEvent"),
	
	Event_CapturePointAdded = Instance.new("BindableEvent"),
	
	Event_ResetAll = Instance.new("BindableEvent"),
	
}

_G.RaidLib = RaidLib

local RFolder = Instance.new("Folder")

RFolder.Name = "RaidLib"

RFolder.Parent = game:GetService("ReplicatedStorage")

local VHMain

RaidLib.MaxPlayers = Players.MaxPlayers

RaidLib.OfficialRaid = Instance.new("BoolValue")
	
RaidLib.OfficialRaid.Name = "OfficialRaid"

RaidLib.OfficialRaid.Parent = RFolder

RaidLib.RaidID = Instance.new("StringValue")
	
RaidLib.RaidID.Name = "RaidID"

RaidLib.RaidID.Parent = RFolder

RaidLib.AwayWinAmount = Instance.new("NumberValue")
	
RaidLib.AwayWinAmount.Name = "AwayWinAmount"

RaidLib.AwayWinAmount.Parent = RFolder

RaidLib.HomeWinAmount = Instance.new("NumberValue")
	
RaidLib.HomeWinAmount.Name = "HomeWinAmount"

local RaidStarted = Instance.new("RemoteEvent")

RaidStarted.Name = "RaidStarted"

RaidStarted.Parent = RFolder

local RaidEnded = Instance.new("RemoteEvent")

RaidEnded.Name = "RaidEnded"

RaidEnded.Parent = RFolder

local RaidTimerEvent = Instance.new("RemoteEvent")

RaidTimerEvent.Name = "RaidTimerEvent"

RaidTimerEvent.OnServerEvent:Connect(function(Plr)
	if RaidLib.RaidStart then
		RaidTimerEvent:FireClient(Plr, RaidLib.RaidStart, RaidLib.CurRaidLimit)
	end
end)

RaidTimerEvent.Parent = RFolder

RaidLib.Captured = Instance.new("RemoteEvent")
RaidLib.Captured.Name = "Captured"
RaidLib.Captured.Parent = RFolder

RaidLib.CheckpointReached = Instance.new("RemoteEvent")
RaidLib.CheckpointReached.Name = "CheckpointReached"
RaidLib.CheckpointReached.Parent = RFolder

local Ran, PlaceName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name:gsub("%b()", ""):gsub("%b[]", ""):gsub("^%s*(.+)%s*$", "%1") end)
RaidLib.PlaceName = Ran and PlaceName or "TestPlace"

RaidLib.PlaceAcronym = RaidLib.PlaceName:sub(1, 1):upper() .. RaidLib.PlaceName:sub(2):gsub(".", {a = "", e = "", i = "", o = "", u = ""}):gsub(" (.?)", function(a) return a:upper() end)

RaidLib.DefaultAwayEmblemUrl = "https://i.imgur.com/cYesNvI.png"

function RaidLib.FormatTime(Time)
	return ("%.2d:%.2d:%.2d"):format(Time / (60 * 60), Time / 60 % 60, Time % 60)
end

local function HandleRbxAsync(DefualtValue, Function, ...)
	local Result = {pcall(Function, ...)}
	if Result[1] then
		return select(2, unpack(Result))
	else
		warn(Result[2] .. "\n" .. debug.traceback(nil,2))
		return DefualtValue
	end
end

local function HandleGrace(Plr, Cur)
	
	local Event, Event3, Event4
	
	if RaidLib.AwayTeams[Plr.Team] then
		
		Event = Plr.CharacterAdded:Connect(function(Char)
			
			Char:WaitForChild("Humanoid").PlatformStand = true
			
			Event4 = Char.ChildAdded:Connect(function(Obj)
				
				if Obj:IsA("Tool") then
					
					wait()
					
					Obj.Parent = Plr.Backpack
					
				end
				
			end)
			
		end)
		
	end
	
	local Event2 = Plr:GetPropertyChangedSignal("Team"):Connect(function()
		
		if RaidLib.AwayTeams[Plr.Team] then
			
			if not Event then
				
				Event = Plr.CharacterAdded:Connect(function(Char)
					
					Char:WaitForChild("Humanoid").PlatformStand = true
					
					Event4 = Char.ChildAdded:Connect(function(Obj)
						
						if Obj:IsA("Tool") then
							
							Obj.Parent = Plr.Backpack
							
						end
						
					end)
					
				end)
				
				Plr:LoadCharacter()
				
			end
			
		else
			
			if Event then
				
				Event:Disconnect()
				
				Event4:Disconnect()
				
				Event = nil
				
				if Plr.Character and Plr.Character:FindFirstChild("Humanoid") then
					
					Plr.Character.Humanoid.PlatformStand = false
					
				end
				
			end
			
		end
		
	end)
	
	Event3 = RaidLib.OfficialRaid:GetPropertyChangedSignal("Value"):Connect(function()
		
		if not RaidLib.OfficialRaid.Value then
			
			if Event then
				
				Event:Disconnect()
				
				Event = nil
				
				Event2:Disconnect()
				
				Event3:Disconnect()
				
				Event4:Disconnect()
				
				if Plr.Character and Plr.Character:FindFirstChild("Humanoid") then
					
					Plr.Character.Humanoid.PlatformStand = false
					
				end
				
			end
			
		end
		
	end)
	
	delay(RaidLib.GracePeriod - (tick() - Cur), function()
		
		Event2:Disconnect()
		
		Event3:Disconnect()
		
		if Event then
			
			Event:Disconnect()
			
			Event = nil
			
			Event4:Disconnect()
			
			if Plr.Character and Plr.Character:FindFirstChild("Humanoid") then
				
				Plr.Character.Humanoid.PlatformStand = false
				
			end
			
		end
		
	end)
	
end

function RaidLib.CheckRequired(CapturePoint)
	if CapturePoint.Required and (CapturePoint.ShouldRequireCheck == nil or CapturePoint:ShouldRequireCheck()) then
		for _, Required in ipairs(CapturePoint.Required) do
			if Required:RequireCheck() then
				return false
			end
		end
	end
	
	return true
end

local RunningGameLoop
local function RunGameLoop()
	RunningGameLoop = true
	
	local Time = wait(0.1)
	while RaidLib.RaidStart do
		for _, CapturePoint in ipairs(RaidLib.CapturePoints) do
			if CapturePoint.Tick then
				local Active
				if CapturePoint.ShouldTick then
					Active = CapturePoint:ShouldTick()
				else
					Active = CapturePoint.Active
				end
				
				if Active and RaidLib.CheckRequired(CapturePoint) then
					if CapturePoint.TickWithNear then
						local Home, Away = RaidLib.GetSidesNear(CapturePoint.MainPart.Position, CapturePoint.Dist)
						local CaptureSpeed = 0
						if Home ~= 0 or Away ~= 0 or CapturePoint.PassiveCapture then
							local BonusSpeed = 1
							if CapturePoint.BonusSpeeds then
								for _, Speed in pairs(CapturePoint.BonusSpeeds) do
									BonusSpeed = BonusSpeed * Speed
								end
							end
							
							CaptureSpeed = ((CapturePoint.PassiveCapture or 0) + (Home == Away and 0 or math.min(Home > Away and Home - Away or Away - Home, CapturePoint.MaxPlrMultiplier))) ^ 0.5 * (Away > Home and CapturePoint.AwayCaptureSpeed or CapturePoint.CaptureSpeed) * BonusSpeed
						end
						
						CapturePoint:Tick(CaptureSpeed, Home, Away)
					else
						CapturePoint:Tick()
					end
				end
			end
		end
		
		local Result = RaidLib.GameMode.Function(RaidLib, Time, (#RaidLib.RequiredCapturePoints == 0 and #RaidLib.CapturePoints == 1) and RaidLib.CapturePoints or RaidLib.RequiredCapturePoints)
		if Result then
			RaidLib.EndRaid(Result)
		end
		
		Time = wait(RaidLib.GameTick)
		
	end
	
	RunningGameLoop = nil
	
end

function RaidLib.GetAwayGroup()
	
	local Highest, HighestGroup
	
	local AllGroups = {}
	
	local Away = 0
	
	for _, Plr in ipairs(Players:GetPlayers()) do
		
		if RaidLib.AwayTeams[Plr.Team] then
			
			for _, Group in ipairs(GroupService:GetGroupsAsync(Plr.UserId)) do
				
				AllGroups[Group.Id] = (AllGroups[Group.Id] or 0) + (Group.IsPrimary and 2 or 1)
				
				if not Highest or AllGroups[Group.Id] > AllGroups[Highest] then
					
					Highest = Group.Id
					
					HighestGroup = Group
					
				end
				
			end
			
		end
		
	end
	
	if not Highest or AllGroups[Highest] <= Away * 0.35 then
		
		return {Name = (RaidLib.DefaultAwayName or next(RaidLib.AwayTeams).Name), EmblemUrl = RaidLib.DefaultAwayEmblemUrl or "", EmblemId = RaidLib.DefaultAwayEmblemId or "", Id = RaidLib.DefaultAwayId or 0}
		
	end
	
	return HighestGroup
	
end

function RaidLib.GroupPagesToArray(Pages)
	
	local Array = {}
	
	while true do
		
		local Page = Pages:GetCurrentPage()
		
		for _, Group in ipairs(Page) do
			
			Array[#Array + 1] = Group.Id
			
		end
		
		if Pages.isFinished then break end
		
		Pages:AdvanceToNextPageAsync()
		
	end
	
	return Array
	
end

local IDWords = {"Roblox", "Robloxian", "TRA", "Observation", "Jumpy", "Books", "Level", "Fast", "Loud", "Wheel", "Abandoned", "Deliver", "Rock", "Rub", "Tame", "Muscle", "Frighten", "Sore", "Number", "Dress", "Lucky", "Love", "Roomy", "Rambunctious", "Tiger", "Group", "Flame", "Gullible", "Obtainable", "Trail", "Brake", "Famous", "Perform", "Idea", "Mix", "Graceful", "Cub", "Argument", "Male", "Trust", "Gigantic", "Pump", "Move", "Ear", "Paddle", "Tall", "Feigned", "Toad", "Public", "Delightful", "Test", "Sponge", "Regular", "Marry", "Grotesque", "Stop", "Walk", "Memorise", "Spectacular", "Giants", "Drawer", "Cloudy", "Pies", "Cheap", "Woozy", "Dinner", "Guide", "Rabid", "Statement", "Four", "Pipe", "Crate", "Paper", "Seemly", "Old", "Heal", "Base", "Marked", "Disturbed", "Shiny", "Boiling", "Wary", "Bone", "Play", "Copy", "Toys", "Mourn", "Support", "Haircut", "Downtown", "Closed", "Film", "Stiff", "Murky", "Frantic", "Juvenile", "Disagreeable", "Madly", "Unsuitable", "Nonstop", "Grab", "Wrong", "Melt", "Anxious", "Clip", "Weary", "Crow", "Refuse", "Frightened", "Fluffy", "Breezy", "Pizzas", "Right", "Tangy", "Toy", "Bizarre", "Concentrate", "Pocket", "Fork", "Push", "Quick", "Miniature", "Abusive", "Carry", "Heavenly", "Better", "Silent", "Few", "Versed", "Receipt", "Tug", "Matter", "Excuse", "Sore", "Practise", "Brown", "Clear", "Gamy", "Increase", "Subsequent", "Connect", "Careful", "Attraction", "Silk", "Vessel", "Plant", "Summer", "North", "Deeply", "Able", "Fresh", "Splendid", "True", "Bag", "Fixed", "Damaged", "Manage", "General", "Thoughtless", "Nappy", "Breakable", "Disagree", "Curious", "Learned", "Zippy", "Understood", "Fascinated", "Meaty", "Jaded", "Regret", "Switch", "House", "Torpid", "Neat", "String", "Top", "Literate", "Actually", "Things", "Girls", "Voiceless", "Delicious", "Check", "Aspiring", "Decorate", "Allow", "Oatmeal", "Massive", "Spiky", "Towering", "Horrible", "Many", "Education", "Scrape", "Moan", "Regret", "Head", "Decorous", "Weight", "Rain", "Hill", "Determined", "Smooth", "Lake", "Hideous", "Clever", "Average", "Discovery", "Squirrel", "Husky", "Flow", "Probable", "Illegal", "Imaginary", "Quill", "Start", "Laughable", "Temper", "Wool", "Smash", "Lopsided", "Shelf", "Premium", "Stem", "Zipper", "Used", "Receptive", "Hat", "Rush", "Example", "Knotty", "Heartbreaking", "Drip", "Part", "Succinct", "Amusement", "Sprout", "Late", "Scintillating", "Fairies", "Willing", "Unnatural", "Terrific", "Maniacal", "Glove", "Devilish", "Callous", "Liquid", "Mute", "Fry", "Tightfisted", "Accidental", "Coal", "Ancient", "Simplistic", "Tempt", "Shrug", "Tax", "Calendar", "Reaction", "Trade", "Drop", "Tickle", "Kindly", "Hop", "Town", "License", "Scold", "Obey", "Ambitious", "Book", "Itch", "Reminiscent", "Argue", "Cup", "Separate", "Meek", "Worthless", "Disillusioned", "Brick", "Innate", "Scare", "Macho", "Harbor", "Flowers", "Arm", "Advice", "Voyage", "Suffer", "Quixotic", "Dirty", "Thaw", "Malicious", "Impress", "Prevent", "Watch", "Stew", "Upset", "Green", "Adjustment", "Smart", "Land", "Caring", "Slow", "Purple", "Remove", "Nest", "Wash", "Attack", "Swift", "Low", "Squalid", "Labored", "Sticky", "Kindhearted", "Milk", "Bruise", "Bear", "Offer", "Even", "Juice", "Place", "End", "Flower", "Terrible", "Disgusting", "Veil", "Hard", "Whistle", "Exchange", "Surprise", "Fancy", "Pen", "Army", "Dazzling", "Harsh", "Knowledgeable", "Unhealthy", "Root", "Puny", "Oval", "Cows", "Juicy", "Daughter", "Dirt", "Low", "Slippery", "Agree", "Shoe", "Cattle", "Rebel", "Sparkle", "Adhesive", "Duck", "Warm", "Lowly", "Parsimonious", "Arrive", "Camp", "Join", "Thread", "Paste", "Drag", "Kind", "Impolite", "Steady", "Spoon", "Rose", "Curve", "Coach", "Sidewalk", "Panicky", "Rejoice", "Hand", "Settle", "Suspend", "Hope", "Foregoing", "Sound", "Preserve", "Scatter", "Carpenter", "Boast", "Good", "Poised", "Risk", "Nifty", "Beautiful", "Pinch", "Gruesome", "Alluring", "Amuse", "Sticks", "Request", "Unadvised", "Meddle", "Unpack", "Knit", "Smell", "Screeching", "Perfect", "Crazy", "Hapless", "Dolls", "Coach", "Cakes", "Gray", "Level", "Roasted", "Naughty", "Nation", "Bird", "Equable", "Stamp", "Button", "Quiet", "Butter", "Helpless", "Store", "Box", "Debonair", "Dispensable", "Desk", "Head", "Bolt", "Push", "Homely", "Picayune", "Demonic", "Rely", "Obscene", "Defeated", "Safe", "Fear", "Domineering", "Long", "Erect", "Produce", "Jellyfish", "End", "Rabbits", "Violet", "Sophisticated", "Scattered", "Swing", "Tart", "Government", "Silver", "Shame", "Wholesale", "Detail", "Minister", "Holistic", "Mate", "Fragile", "Lackadaisical", "Control", "Steadfast", "Ugliest", "Yellow", "Seat", "Future", "Engine", "Icy", "Gate", "Acidic", "Capricious", "Abaft", "Telephone", "Question", "False", "Sneaky", "Enormous", "Spray", "Exclusive", "Run", "Scene", "Inform", "Fail", "Uncle", "Ablaze", "Trousers", "Wanting", "Surround", "Grandmother", "Stop", "Slip", "Reply", "Vegetable", "Hulking", "Confused", "Sheet", "Coil", "Whisper", "Last", "Person", "Jeans", "Smoggy", "Gratis", "Search", "Partixel", "CodeNil", "Antyronio", "Peekay"}

local PracticeWords = {"Test", "Debug", "Fake", "Tryhard", "Learn", "Lesson", "Usage", "Action", "Discipline", "Drill", "Experience", "Study", "Training", "Assignment", "Homework", "Recitation", "Rehearsal", "Prepping"}

local IDRandom = Random.new()

function RaidLib.StartRaid()
	RaidLib.Practice = RaidLib.Practice or game.PrivateServerId ~= ""
	
	if RaidLib.GameMode then
		local MyId
		if RaidLib.Practice then
			local Pos = math.random(1, 3)
			if Pos == 1 then
				MyId = "Practice" .. PracticeWords[IDRandom:NextInteger(1, #PracticeWords)] .. PracticeWords[IDRandom:NextInteger(1, #PracticeWords)]
			elseif Pos == 2 then
				MyId = PracticeWords[IDRandom:NextInteger(1, #PracticeWords)] .. "Practice" .. PracticeWords[IDRandom:NextInteger(1, #PracticeWords)]
			else
				MyId = PracticeWords[IDRandom:NextInteger(1, #PracticeWords)] .. PracticeWords[IDRandom:NextInteger(1, #PracticeWords)] .. "Practice"
			end
		else
			MyId = IDWords[IDRandom:NextInteger(1, #IDWords)] .. IDWords[IDRandom:NextInteger(1, #IDWords)] .. IDWords[IDRandom:NextInteger(1, #IDWords)]
		end
		RaidLib.RaidID.Value = MyId
		
		RaidLib.AwayGroup = RaidLib.GetAwayGroup()
		RaidLib.TeamLog = {}
		
		if RaidLib.PreMatchTime then
			RaidLib.Event_PreMatchStarted:Fire()
			
			wait(RaidLib.PreMatchTime)
		end
		
		if MyId == RaidLib.RaidID.Value then
			local Cur = tick()
			
			RaidLib.RaidStart = Cur
			RaidLib.CurRaidLimit = RaidLib.RaidLimit
			RaidLib.OfficialRaid.Value = true
			
			RaidTimerEvent:FireAllClients(RaidLib.RaidStart, RaidLib.CurRaidLimit, RaidLib.GameMode.WinTime or RaidLib.GameMode.WinPoints)
			RaidStarted:FireAllClients(RaidLib.RaidID.Value, RaidLib.AwayGroup)
			
			for _, Plr in ipairs(Players:GetPlayers()) do
				RaidLib.TeamLog[tostring(Plr.UserId)] = {{Cur, Plr.Team}}
				
				if RaidLib.GracePeriod and RaidLib.GracePeriod > 0 then
					HandleGrace(Plr, Cur)
				end
				
				if RaidLib.RespawnPlayers ~= false and (RaidLib.RespawnAllPlayers or RaidLib.AwayTeams[Plr.Team]) then
					Plr:LoadCharacter()
				end
			end
			
			for a = 1, #RaidLib.CapturePoints do
				if not RaidLib.CapturePoints[a].ManualActivation then
					if RaidLib.CapturePoints[a].Required then
						local Active = true
						for b = 1, #RaidLib.CapturePoints[a].Required do
							if not RaidLib.CapturePoints[a].Required[b].Active then
								Active = false
								
								break
							end
						end
						
						if Active then
							RaidLib.CapturePoints[a].Active = true
						end
					elseif RaidLib.CapturePoints[a].DefaultActive ~= nil then
						RaidLib.CapturePoints[a].Active = RaidLib.CapturePoints[a].DefaultActive
					else
						RaidLib.CapturePoints[a].Active = true
					end
				end
			end
			
			if not RunningGameLoop then
				coroutine.wrap(RunGameLoop)()
			end
		end
	end
end

function RaidLib.EndRaid(Result)
	RaidLib.Event_RaidEnded:Fire(RaidLib.RaidID.Value, RaidLib.AwayGroup, Result, RaidLib.TeamLog, RaidLib.RaidStart)
	RaidEnded:FireAllClients(RaidLib.RaidID.Value, RaidLib.AwayGroup, Result)
	
	local Practice = RaidLib.Practice or not RaidLib.RaidStart
	RaidLib.ResetAll()
	
	if not Practice and Result ~= "Forced" and Result ~= "Left" and RaidLib.KickOnEnd ~= false then
		wait(20)
		
		for _, Plr in ipairs(Players:GetPlayers()) do
			if RaidLib.AwayTeams[Plr.Team] then
				if RaidLib.BanWhenWinOrLoss and VHMain then
					VHMain.ParseCmdStacks(nil, "permban/" .. Plr.UserId .. "/30m")
				else
					Plr:Kick("Raid is over, please rejoin to raid again")
				end
			end
		end
	end
end

game:BindToClose(function()
	if RaidLib.RaidID.Value then
		RaidLib.EndRaid("Left")
	end
end)

function RaidLib.ResetAll()
	RaidLib.HomeMax, RaidLib.AwayMax = nil, nil
	RaidLib.Practice = nil
	RaidLib.RallyMessage = nil
	RaidLib.Forced = nil
	RaidLib.RaidStart = nil
	RaidLib.CurRaidLimit = nil
	RaidLib.TeamLog = nil
	RaidLib.AwayGroup = nil
	RaidLib.RaidID.Value = ""
	RaidLib.AwayWinAmount.Value = 0
	RaidLib.HomeWinAmount.Value = 0
	
	RaidTimerEvent:FireAllClients()
	
	RaidLib.OfficialRaid.Value = false
	
	for _, CapturePoint in ipairs(RaidLib.CapturePoints) do
		CapturePoint:Reset()
	end
	
	RaidLib.Event_ResetAll:Fire()
end

function RaidLib.GetCountFor(Side, Plr)
	
	local Team = Side[Plr.Team]
	
	if Team then
		
		local CountsFor = Team.CountsFor
		
		for _, Counts in ipairs(Team) do
			
			if Counts.CountsFor then
				
				for _, Count in ipairs(Counts) do
					
					if HandleRbxAsync(false, Plr.IsInGroup, Plr, Count) then
						
						return Counts.CountsFor
						
					end
					
				end
				
			end
			
		end
		
		return CountsFor
		
	end
	
	return 0
	
end

function RaidLib.SetWinTimer(Val)
	
	if RaidLib.AwayWinAmount.Value ~= Val then
		
		local Old = RaidLib.AwayWinAmount.Value
		
		RaidLib.AwayWinAmount.Value = Val
		
		RaidLib.Event_WinChanged:Fire(Old)
		
	end
	
end

function RaidLib.CountTeams()
	
	local Home, Away = 0, 0
	
	for _, Plr in ipairs(Players:GetPlayers()) do
		
		Home = Home + RaidLib.GetCountFor(RaidLib.HomeTeams, Plr)
		
		Away = Away + RaidLib.GetCountFor(RaidLib.AwayTeams, Plr)
		
	end
	
	return Home, Away
	
end

local TimeCheck

function RaidLib.OfficialCheck(Manual)
	
	local Home, Away = RaidLib.CountTeams()
	
	if RaidLib.RaidID.Value ~= "" then
		
		if Away == 0 and not RaidLib.Forced then
			
			RaidLib.EndRaid("Left")
			
		end
		
	else
		
		local Result
		
		if Manual == true or not RaidLib.ManualStart then
			
			local BST = HttpService:GetAsync("https://rbxapi.v-handle.com/?type=4"):sub(1, 1) == "1"
			local InTime
			if RaidLib.MinTime and RaidLib.MaxTime then
				local MinTime, MaxTime = RaidLib.MinTime - (BST and 1 or 0), RaidLib.MaxTime - (BST and 1 or 0)
				InTime = false
				
				local Time = os.date("!*t").hour + (os.date("!*t").min / 60)
				
				if MaxTime > MinTime then
					
					if Time >= MinTime and Time < MaxTime then
						
						InTime = true
						
					end
					
				elseif Time < MaxTime or Time >= MinTime then
					
					InTime = true
										
				end
				
			end
			
			if InTime == false then
				
				local MinTime, MaxTime = RaidLib.MinTime, RaidLib.MaxTime
				
				MinTime = math.floor(MinTime) .. ":" .. math.floor((MinTime - math.floor(MinTime) * 60) + 0.5)
				
				MaxTime = math.floor(MaxTime) .. ":" .. math.floor((MaxTime - math.floor(MaxTime) * 60) + 0.5)
				
				Result = "Must raid between the times of " .. MinTime .. " and " .. MaxTime
				
				if not TimeCheck then
					
					TimeCheck = true
					
					coroutine.wrap(function()
						
						while wait(1) and not RaidLib.RaidStart do
							
							RaidLib.OfficialCheck()
							
						end
						
						TimeCheck = nil
						
					end)()
					
				end
				
			elseif Away < RaidLib.AwayRequired or Away == 0 then
				
				Result = "Must be at least " .. math.max(RaidLib.AwayRequired, 1) .. " players on the away teams"
				
			elseif Home < RaidLib.HomeRequired then
				
				Result = "Must be at least " .. RaidLib.HomeRequired .. " players on the home teams"
				
			elseif RaidLib.EqualTeams and (Home ~= Away) then
				
				Result = "Teams must be equal to start"
				
			else
				
				coroutine.wrap(RaidLib.StartRaid)()
						
			end
			
		end
		
		RaidLib.Event_OfficialCheck:Fire(Home, Away, Result)
		
		return Result
		
	end
	
end

function PlayerAdded(Plr)
	
	local Found
	
	for Team, CountsFor in pairs(RaidLib.HomeTeams) do
		
		for _, Counts in ipairs(CountsFor) do
			
			for _, Count in ipairs(Counts) do
				
				if HandleRbxAsync(false, Plr.IsInGroup, Plr, Count) then
					
					Plr.Team = Team
					
					Plr:LoadCharacter()
					
					Found = true
					
					break
					
				end
				
			end
			
		end
		
		if Found then break end
		
	end
	
	if not Found then
		
		for Team, CountsFor in pairs(RaidLib.AwayTeams) do
			
			for _, Counts in ipairs(CountsFor) do
				
				for _, Count in ipairs(Counts) do
					
					if HandleRbxAsync(false, Plr.IsInGroup, Plr, Count) then
						
						Plr.Team = Team
						
						Found = true
						
						break
						
					end
					
				end
				
			end
			
			if Found then break end
			
		end
		
	end
	
	local Home, Away = RaidLib.CountTeams()
	
	if not RaidLib.RaidStart and RaidLib.AwayTeams[Plr.Team] then
		
		if RaidLib.MaxPlayers - Away < RaidLib.HomeRequired then
			
			Plr:Kick("You were kicked to make room for " .. (RaidLib.HomeRequired - (RaidLib.MaxPlayers - Away)) .. " more " .. next(RaidLib.HomeTeams).Name)
			return
			
		elseif RaidLib.EqualTeams and Away > RaidLib.MaxPlayers / 2  then
			
			Plr:Kick("You were kicked to make room for " .. (RaidLib.MaxPlayers / 2 - Home) .. " more " .. next(RaidLib.HomeTeams).Name)
			return
			
		end
		
	end
	
	if RaidLib.RaidStart then
		
		if RaidLib.LockTeams then
			
			if RaidLib.HomeTeams[Plr.Team] and Home > Away + 1 then
				
				Plr:Kick(next(RaidLib.HomeTeams).Name .. " is full, please wait for more " .. next(RaidLib.AwayTeams).Name)
				return
			
			elseif RaidLib.AwayTeams[Plr.Team] and Away > Home + 1 then
				
				Plr:Kick(next(RaidLib.AwayTeams).Name .. " is full, please wait for more " .. next(RaidLib.HomeTeams).Name)
				return
				
			end
			
		end
		
		if RaidLib.GracePeriod and RaidLib.GracePeriod > 0 and tick() - RaidLib.RaidStart < RaidLib.GracePeriod then
				
			if RaidLib.AwayTeams[Plr.Team] then
				
				HandleGrace(Plr)
				
			end
			
		end
		
		RaidLib.TeamLog[tostring(Plr.UserId)] = RaidLib.TeamLog[tostring(Plr.UserId)] or {}
		
		RaidLib.TeamLog[tostring(Plr.UserId)][#RaidLib.TeamLog[tostring(Plr.UserId)] + 1] = {tick(), Plr.Team  }
		
	end
	
	RaidLib.OfficialCheck()
	
	local Team = Plr.Team
	
	Plr:GetPropertyChangedSignal("Team"):Connect(function()
		
		if RaidLib.RaidStart then
			
			if RaidLib.LockTeams then
				
				local Home, Away = RaidLib.CountTeams()
				
				if RaidLib.HomeTeams[Plr.Team] and (Home > Away + 1 or (not RaidLib.EqualTeams or Home > RaidLib.MaxPlayers / 2)) then
					
					Plr.Team = Team
					
					return
				
				elseif RaidLib.AwayTeams[Plr.Team] and (Away > Home + 1 or (not RaidLib.EqualTeams or Home > RaidLib.MaxPlayers / 2)) then
					
					Plr.Team = Team
					
					return
					
				end
				
			end
			
			RaidLib.TeamLog[tostring(Plr.UserId)][#RaidLib.TeamLog[tostring(Plr.UserId)] + 1] = {tick(), Plr.Team}
			
		end
		
		Team = Plr.Team
		
		RaidLib.OfficialCheck()
		
	end)
	
end

Players.PlayerRemoving:Connect(function(Plr)
	
	RaidLib.OfficialCheck()
	
	if RaidLib.RaidStart then
		
		RaidLib.TeamLog[tostring(Plr.UserId)] = RaidLib.TeamLog[tostring(Plr.UserId)] or {}
		
		RaidLib.TeamLog[tostring(Plr.UserId)][#RaidLib.TeamLog[tostring(Plr.UserId)] + 1] = {tick()}
		
	end
	
end)

Players.PlayerAdded:Connect(PlayerAdded)
for _, Plr in ipairs(Players:GetPlayers()) do
	PlayerAdded(Plr)
end

function RaidLib.OldFlagCompat()
	
	local Message
	
	RaidLib.OfficialRaid:GetPropertyChangedSignal("Value"):Connect(function()
		
		if RaidLib.OfficialRaid.Value then
			
			if Message then Message:Destroy() end
			
			Message = Instance.new("Message", workspace)
			
			Message.Text = RaidLib.AwayGroup.Name .. " have started raiding"
			
			Debris:AddItem(Message, 5)
			
		end
		
	end)
	
	RaidLib.Event_CapturePointAdded.Event:Connect(function(Num)
		
		local CapturePoint = RaidLib.CapturePoints[Num]
		
		CapturePoint.Event_Captured.Event:Connect(function()
			
			local Hint = Instance.new("Hint", workspace)
			
			Hint.Text = "The flag at the " .. CapturePoint.Name .. " is now owned by " .. next(CapturePoint.CurOwner).Name
			
			Debris:AddItem(Hint, 5)
			
		end)
		
	end)
	
	for _, CapturePoint in ipairs(RaidLib.CapturePoints) do
		
		CapturePoint.Event_Captured.Event:Connect(function()
			
			local Hint = Instance.new("Hint", workspace)
			
			Hint.Text = "The flag at the " .. CapturePoint.Name .. " is now owned by " .. next(CapturePoint.CurOwner).Name
			
			Debris:AddItem(Hint, 5)
			
		end)
		
	end
	
	RaidLib.Event_RaidEnded.Event:Connect(function(ID, AwayGroup, Result, RaidStart)
		
		if not RaidStart then return end
		
		if Message then Message:Destroy() end
		
		Message = Instance.new("Message", workspace)
		
		if Result ~= "Forced" and Result ~= "Left" then
			
			local Name
			
			if Result == "Lost" then
				
				Name = AwayGroup.Name
				
			else
				
				Name = RaidLib.HomeGroup.Name
				
			end
			
			Message.Text = Name .. " has won! ID: " .. ID .. " - " .. AwayGroup.Name .. " get kicked in 20s"
			
			Debris:AddItem(Message, 20)
			
			for a = 19, 0, -1 do
				
				wait(1)
				
				Message.Text = Name .. " has won! ID: " .. ID .. " - " .. AwayGroup.Name .. " get kicked in " .. a .. "s"
				
			end
			
		else
			
			local Txt = Result == "Left" and AwayGroup.Name .. " have left, raid over!" or Result == "Forced" and "An admin has force ended the raid!"
			
			Message.Text = Txt
			
			Debris:AddItem(Message, 5)
			
		end
		
	end)
	
end

function RaidLib.GetSidesNear(Point, Dist)
	
	local Home, Away = 0, 0
	
	for _, Plr in ipairs(Players:GetPlayers()) do
		
		local b = Plr
		
		if b.Character and b.Character:FindFirstChild("Humanoid") and b.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead and b:DistanceFromCharacter(Point) < Dist then
			
			if RaidLib.HomeTeams[b.Team] then
				
				Home = Home + 1
			
			elseif RaidLib.AwayTeams[b.Team]then
				
				Away = Away + 1
				
			end
			
		end
		
	end
	
	return Home, Away
	
end

function RaidLib.Clear(Destroy)
	while next(RaidLib.CapturePoints) do
		select(2, next(RaidLib.CapturePoints)):Destroy(Destroy)
	end
	
	RaidLib.GameMode = nil
	setmetatable(RaidLib, {})
	
	RaidLib.ResetAll()
end

function RaidLib.SetGameMode(GameMode)
	if GameMode.WinPoints then
		RaidLib.HomeWinAmount.Parent = RFolder
	else
		RaidLib.HomeWinAmount.Parent = nil
	end
	
	RaidLib.Allies = {}
	local Pages = GroupService:GetAlliesAsync(RaidLib.HomeGroup.Id)
	while true do
		for _, Group in ipairs(Pages:GetCurrentPage()) do
			RaidLib.Allies[#RaidLib.Allies + 1] = Group.Id
		end
		if Pages.IsFinished then
			break
		end
		Pages:AdvanceToNextPageAsync()
	end
	
	RaidLib.GameMode = GameMode
	setmetatable(RaidLib, {__index = RaidLib.GameMode})
	
	RaidLib.ResetAll()
end

RaidLib.GameModeFunctions = {}

function RaidLib.SetRaidLimit(Time)
	RaidLib.CurRaidLimit = tick() - RaidLib.CurRaidLimit + Time
	RaidTimerEvent:FireAllClients(RaidLib.RaidStart, RaidLib.CurRaidLimit)
end

function RaidLib.AddTimeToRaidLimit(Time)
	RaidLib.CurRaidLimit = math.max(tick() - RaidLib.RaidStart + Time, RaidLib.CurRaidLimit + Time)
	RaidTimerEvent:FireAllClients(RaidLib.RaidStart, RaidLib.CurRaidLimit)
end

function RaidLib.SetSpawns(SpawnClones, Model, Side)
	
	if SpawnClones then
		
		for k, Spawn in ipairs(SpawnClones) do
			
			Spawn:Destroy()
			
			SpawnClones[k] = nil
			
		end
		
	end
	
	for _, Kid in ipairs(Model:GetDescendants()) do
		
		if Kid:IsA("SpawnLocation") then
			
			if CollectionService:HasTag(Kid, "HomeSpawn") then
				
				if Side == RaidLib.HomeTeams then
					
					Kid.Enabled = true
					
				else
					
					Kid.Enabled = false
					
				end
				
			elseif CollectionService:HasTag(Kid, "AwaySpawn") then
				
				if Side == RaidLib.AwayTeams then
					
					Kid.Enabled = true
					
				else
					
					Kid.Enabled = false
					
				end
				
			end
			
			local First
			
			for b, c in pairs(Side) do
				
				if not First then
					
					First = true
					
					Kid.TeamColor = b.TeamColor
					
					Kid.BrickColor = b.TeamColor
					
				elseif Kid.Enabled then
					
					local Clone = Kid:Clone()
					
					SpawnClones = SpawnClones or {}
					
					SpawnClones[#SpawnClones + 1] = Clone
					
					Clone.Transparency = 1
					
					Clone.CanCollide = false
					
					Clone:ClearAllChildren()
					
					Clone.TeamColor = b.TeamColor
					
					Clone.BrickColor = b.TeamColor
					
					Clone.Parent = Kid
					
				end
				
			end
			
		end
		
	end
	
end

function RaidLib.GetWorldPos(Inst)
	
	return Inst:IsA("Attachment") and Inst.WorldPosition or Inst.Position
	
end

function RaidLib.OrderedPointsToPayload(StartPoint, Checkpoints, TurnPoints)
	
	local Ordered = {}
	
	for i, TurnPoint in ipairs(TurnPoints) do
		
		if TurnPoint ~= StartPoint and not table.find(Checkpoints, TurnPoint) then
			
			Ordered[#Ordered + 1] = TurnPoint
			
		end
		
		TurnPoints[i] = nil
		
	end
	
	for i, Checkpoint in ipairs(Checkpoints) do
		
		Ordered[#Ordered + 1] = Checkpoint
		
		Checkpoints[Checkpoint] = true
		
		Checkpoints[i] = nil
		
	end
	
	table.sort(Ordered, function(a, b) return tonumber(a.Name) < tonumber(b.Name) end)
	
	local Total = 0
	
	for i, Checkpoint in ipairs(Ordered) do
		
		local Dist = (RaidLib.GetWorldPos(Checkpoint) - RaidLib.GetWorldPos(i == 1 and StartPoint or Ordered[i - 1])).magnitude
		
		Total = Total + Dist
		
		if Checkpoints[Checkpoint] then
			
			Checkpoints[#Checkpoints + 1] = {Total, Checkpoint}
			
			Checkpoints[Checkpoint] = nil
			
		else
			
			TurnPoints[#TurnPoints + 1] = {Total, Checkpoint}
			
		end
		
	end
	
	return Checkpoints, TurnPoints, Total
	
end

RaidLib.DiscordCharacterLimit = 2000

RaidLib.Event_OfficialCheck.Event:Connect(function(Home, Away)
	
	if not RaidLib.RallyMessage and Home < RaidLib.HomeRequired and Away >= RaidLib.AwayRequired * (RaidLib.RallyMessagePct or 0.5) then
		
		RaidLib.RallyMessage = true
		
		if not RaidLib.Practice and game.PrivateServerId == "" and RaidLib.DiscordMessages and (RaidLib.AllowDiscordInStudio or not RunService:IsStudio()) then

			local AwayGroup = RaidLib.GetAwayGroup()
			
			if AwayGroup.Id ~= RaidLib.HomeGroup.Id and not table.find(RaidLib.Allies, AwayGroup.Id) then
				
				AwayGroup = AwayGroup.Id and ("[" .. AwayGroup.Name .. "](<https://www.roblox.com/groups/" .. AwayGroup.Id .. "/a#!/about>)") or RaidLib.AwayGroup.Name
				
				local HomeGroup = RaidLib.HomeGroup and ("[" .. RaidLib.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. RaidLib.HomeGroup.Id .. "/a#!/about>)")
				
				local PlaceAcronym = "[" .. RaidLib.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
				
				local PlaceName = "[" .. RaidLib.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
				
				local Home, Away = {}, {}
				
				for _, Plr in ipairs(Players:GetPlayers()) do
					
					if RaidLib.HomeTeams[Plr.Team] then
						
						Home[#Home + 1] = "[" .. Plr.Name .. "](<https://www.roblox.com/users/" .. Plr.UserId .. "/profile>) - " .. HandleRbxAsync("Guest", Plr.GetRoleInGroup, Plr, RaidLib.HomeGroup.Id)
						
					elseif RaidLib.AwayTeams[Plr.Team] then
						
						Away[#Away + 1] = "[" .. Plr.Name .. "](<https://www.roblox.com/users/" .. Plr.UserId .. "/profile>)" .. (AwayGroup.Id and (" - " .. HandleRbxAsync("Guest", Plr.GetRoleInGroup, Plr, AwayGroup.Id)) or "")
						
					end
					
				end
				
				if #Home == 0 then Home[1] = "None" end
				
				if #Away == 0 then Away[1] = "None" end
				
				for a = 1, #RaidLib.DiscordMessages do
					
					if RaidLib.DiscordMessages[a].Rallying then
						
						local Msg = RaidLib.DiscordMessages[a].Rallying:gsub("%%(%w*)%%", {["PlaceAcronym"] = PlaceAcronym, ["PlaceName"] = PlaceName, ["RaidID"] = RaidLib.RaidID.Value, ["AwayGroup"] = AwayGroup, ["AwayList"] = table.concat(Away, ", "), ["AwayListNewline"] = table.concat(Away, "\n"), ["HomeGroup"] = HomeGroup, ["HomeList"] = table.concat(Home, ", "), ["HomeListNewline"] = table.concat(Home, "\n")})
						
						while true do
							
							local LastNewLine = #Msg <= RaidLib.DiscordCharacterLimit and RaidLib.DiscordCharacterLimit or Msg:sub(1, RaidLib.DiscordCharacterLimit):match("^.*()[\n]")
							
							local Ran, Error = pcall(HttpService.PostAsync, HttpService, RaidLib.DiscordMessages[a].Url, HttpService:JSONEncode{avatar_url = RaidLib.HomeGroup.EmblemUrl, username = RaidLib.PlaceAcronym .. " Raid Bot", content = Msg:sub(1, LastNewLine and LastNewLine - 1 or RaidLib.DiscordCharacterLimit)})
							
							if not Ran then warn(Error) end
							
							if #Msg <= (LastNewLine or RaidLib.DiscordCharacterLimit) then break end
							
							Msg = Msg:sub((LastNewLine or RaidLib.DiscordCharacterLimit) + 1)
							
						end
						
					end
					
				end
				
			end
			
		end
		
	end
	
end)

RaidLib.OfficialRaid:GetPropertyChangedSignal("Value"):Connect(function()
	
	if not RaidLib.OfficialRaid.Value then return end
	
	if not RaidLib.Practice and RaidLib.DiscordMessages and (RaidLib.AllowDiscordInStudio or not RunService:IsStudio()) then
		
		local AwayGroup = RaidLib.AwayGroup.Id and ("[" .. RaidLib.AwayGroup.Name .. "](<https://www.roblox.com/groups/" .. RaidLib.AwayGroup.Id .. "/a#!/about>)") or RaidLib.AwayGroup.Name
		
		local HomeGroup = RaidLib.HomeGroup and ("[" .. RaidLib.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. RaidLib.HomeGroup.Id .. "/a#!/about>)")
		
		local PlaceAcronym ="[" .. RaidLib.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local PlaceName = "[" .. RaidLib.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local Home, Away = {}, {}
		
		for _, Plr in ipairs(Players:GetPlayers()) do
			
			if RaidLib.HomeTeams[Plr.Team] then
				
				Home[#Home + 1] = "[" .. Plr.Name .. "](<https://www.roblox.com/users/" .. Plr.UserId .. "/profile>) - " .. HandleRbxAsync("Guest", Plr.GetRoleInGroup, Plr, RaidLib.HomeGroup.Id)
				
			elseif RaidLib.AwayTeams[Plr.Team] then
				
				Away[#Away + 1] = "[" .. Plr.Name .. "](<https://www.roblox.com/users/" .. Plr.UserId .. "/profile>)" .. (RaidLib.AwayGroup.Id and (" - " .. HandleRbxAsync("Guest", Plr.GetRoleInGroup, Plr, RaidLib.AwayGroup.Id)) or "")
				
			end
			
		end
		
		if #Home == 0 then Home[1] = "None" end
		
		if #Away == 0 then Away[1] = "None" end
		
		for a = 1, #RaidLib.DiscordMessages do
			
			if RaidLib.DiscordMessages[a].Start then
				
				local Msg = RaidLib.DiscordMessages[a].Start:gsub("%%(%w*)%%", {["PlaceAcronym"] = PlaceAcronym, ["PlaceName"] = PlaceName, ["RaidID"] = RaidLib.RaidID.Value, ["AwayGroup"] = AwayGroup, ["AwayList"] = table.concat(Away, ", "), ["AwayListNewline"] = table.concat(Away, "\n"), ["HomeGroup"] = HomeGroup, ["HomeList"] = table.concat(Home, ", "), ["HomeListNewline"] = table.concat(Home, "\n")})
				
				while true do
					
					local LastNewLine = #Msg <= RaidLib.DiscordCharacterLimit and RaidLib.DiscordCharacterLimit or Msg:sub(1, RaidLib.DiscordCharacterLimit):match("^.*()[\n]")
					
					local Ran, Error = pcall(HttpService.PostAsync, HttpService, RaidLib.DiscordMessages[a].Url, HttpService:JSONEncode{avatar_url = RaidLib.HomeGroup.EmblemUrl, username = RaidLib.PlaceAcronym .. " Raid Bot", content = Msg:sub(1, LastNewLine and LastNewLine - 1 or RaidLib.DiscordCharacterLimit)})
					
					if not Ran then warn(Error) end
					
					if #Msg <= (LastNewLine or RaidLib.DiscordCharacterLimit) then break end
					
					Msg = Msg:sub((LastNewLine or RaidLib.DiscordCharacterLimit) + 1)
					
				end
				
			end
			
		end
		
	end
	
end)

RaidLib.Event_RaidEnded.Event:Connect(function(RaidID, AwayGroupTable, Result, TeamLog, RaidStart) 
	
	if RaidStart and not RaidLib.Practice and RaidLib.DiscordMessages and (RaidLib.AllowDiscordInStudio or not RunService:IsStudio()) then
		
		local EndTime = tick()
		
		local AwayGroup = AwayGroupTable.Id and ("[" .. AwayGroupTable.Name .. "](<https://www.roblox.com/groups/" .. AwayGroupTable.Id .. "/a#!/about>)") or AwayGroupTable.Name
		
		local HomeGroup = RaidLib.HomeGroup and ("[" .. RaidLib.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. RaidLib.HomeGroup.Id .. "/a#!/about>)")
		
		local PlaceAcronym ="[" .. RaidLib.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local PlaceName = "[" .. RaidLib.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local Home, Away = {}, {}
		
		for UserId, Logs in pairs(TeamLog) do
			
			local Teams = {}
			
			local Max
			
			if #Logs == 1 and Logs[1][1] == RaidStart then
				
				Teams[Logs[1][2]] = true
				
				Max = Logs[1][2]
				
			else
			
				for Key, Log in ipairs(Logs) do
					
					if Log[2] then
						
						Teams[Log[2]] = Teams[Log[2]] or 0
						
						local Next = Logs[Key + 1]
						
						Teams[Log[2]] = Teams[Log[2]] + (Next and Next[1] or EndTime) - Log[1]
						
						if not Max or Teams[Max] < Teams[Log[2]] then
							
							Max = Log[2]
							
						end
						
					end
					
				end
				
			end
			
			if Max then
				
				if RaidLib.HomeTeams[Max] then
					
					local Role
					
					for _, Group in ipairs(GroupService:GetGroupsAsync(UserId)) do
						
						if Group.Id == RaidLib.HomeGroup.Id then
							
							Role = Group.Role
							
							break
							
						end
						
					end
					
					local Time = " - helped for " .. (Teams[Max] == true and "the entire raid" or RaidLib.FormatTime(Teams[Max]))
					
					Home[#Home + 1] = "[" .. Players:GetNameFromUserIdAsync(UserId) .. "](<https://www.roblox.com/users/" .. UserId .. "/profile>) - " .. (Role or "Guest") .. Time
					
				elseif RaidLib.AwayTeams[Max] then
					
					local Role
					
					if AwayGroupTable.Id then
						
						for _, Group in ipairs(GroupService:GetGroupsAsync(UserId)) do
							
							if Group.Id == AwayGroupTable.Id then
								
								Role = Group.Role
								
								break
								
							end
							
						end
						
						Role = Role or "Guest"
						
					end
					
					local Time = " - helped for " .. (Teams[Max] == true and "the entire raid" or RaidLib.FormatTime(Teams[Max]))
					
					Away[#Away + 1] = "[" .. Players:GetNameFromUserIdAsync(UserId) .. "](<https://www.roblox.com/users/" .. UserId .. "/profile>) " .. (Role and (" - " .. (Role or "Guest")) or "") .. Time
					
				end
				
			end
			
		end
		
		if #Home == 0 then Home[1] = "None" end
		
		if #Away == 0 then Away[1] = "None" end
		
		local EmblemUrl = Result == "Lost" and AwayGroupTable.EmblemUrl or RaidLib.HomeGroup.EmblemUrl
		
		for a = 1, #RaidLib.DiscordMessages do
			
			if RaidLib.DiscordMessages[a][Result] then
				
				local Msg = RaidLib.DiscordMessages[a][Result]:gsub("%%(%w*)%%", {["PlaceAcronym"] = PlaceAcronym, ["PlaceName"] = PlaceName, ["RaidID"] = RaidID, ["RaidTime"] = RaidLib.FormatTime(EndTime - RaidStart), ["AwayGroup"] = AwayGroup, ["AwayList"] = table.concat(Away, ", "), ["AwayListNewline"] = table.concat(Away, "\n"), ["HomeGroup"] = HomeGroup, ["HomeList"] = table.concat(Home, ", "), ["HomeListNewline"] = table.concat(Home, "\n")})
				
				while true do
					
					local LastNewLine = #Msg <= RaidLib.DiscordCharacterLimit and RaidLib.DiscordCharacterLimit or Msg:sub(1, RaidLib.DiscordCharacterLimit):match("^.*()[\n]")
					
					local Ran, Error = pcall(HttpService.PostAsync, HttpService, RaidLib.DiscordMessages[a].Url, HttpService:JSONEncode{avatar_url = EmblemUrl, username = RaidLib.PlaceAcronym .. " Raid Bot", content =  Msg:sub(1, LastNewLine and LastNewLine - 1 or RaidLib.DiscordCharacterLimit)})
					
					if not Ran then warn(Error) end
					
					if #Msg <= (LastNewLine or RaidLib.DiscordCharacterLimit) then break end
					
					Msg = Msg:sub((LastNewLine or RaidLib.DiscordCharacterLimit) + 1)
					
				end
				
			end
			
		end
		
	end
	
end)

local function LoadPoints(Modules)
	for _, Module in ipairs(Modules) do
		RaidLib[Module.Name .. "Point"] = require(Module)(RaidLib)
	end
end
LoadPoints(script.DefaultPointTypes:GetChildren())

local function LoadGameModes(Modules)
	for _, Module in ipairs(Modules) do
		RaidLib.GameModeFunctions[Module.Name] = require(Module)
	end
end
LoadGameModes(script.DefaultGameModes:GetChildren())

return RaidLib