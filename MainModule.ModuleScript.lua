local CollectionService, TweenService, Debris, Players, GroupService, HttpService, RunService = game:GetService( "CollectionService" ), game:GetService( "TweenService" ), game:GetService( "Debris" ), game:GetService( "Players" ), game:GetService( "GroupService" ), game:GetService( "HttpService" ), game:GetService("RunService")

local Module = {
	
	RaidLimit = 60 * 60 * 2.5, -- How long a raid can go before the away team lose, 2.5 hours
	
	HomeTeams = { }, -- Teams that can capture for the home group
	
	HomeRequired = 1, -- How many of the home teams are required for capturepoints to be taken
	
	AwayTeams = { }, -- Teams that can raid
	
	AwayRequired = 1, -- How many of the home teams are required for capturepoints to be taken
	
	RespawnAllPlayers = true, -- Respawns all the players at the start of the raid if this is true
	
	EqualTeams = false, -- If true, raid will only be started if teams are equal
	
	LockTeams = false, -- If true, teams will be limited to the same size when people leave
	
	ManualStart = false, -- If true, raid can only be started by command
	
	SingleSpawnPoints = true, -- If true any spawn points at capture points required by the captured point will be disabled
	
	GracePeriod = 15, -- The away team won't be able to move when the raid starts for this period of time
	
	BanWhenWinOrLoss = false, -- Do the away team get banned when raid limit is reached or they win? ( Require V-Handle admin )
	
	CaptureSpeed = 1, -- The speed at which points are captured as a percentage of the normal speed ( 1 = 100%, 0.5 = 50% )
	
	AwayCaptureSpeed = 1, -- The speed at which points are captured relative to CaptureSpeed ( 1 = 100% of normal speed, 0.5 = 50% normal )
	
	MaxPlrMultiplier = 100, -- Up to this many players will increase the speed of capturing a capture point

	-- NO TOUCHY --
	
	GameTick = 1,
	
	CapturePoints = { },
	
	RequiredCapturePoints = { },
	
	Event_RaidEnded = Instance.new( "BindableEvent" ),
	
	Event_WinChanged = Instance.new( "BindableEvent" ),
	
	Event_OfficialCheck = Instance.new( "BindableEvent" ),
	
	Event_CapturePointAdded = Instance.new( "BindableEvent" ),
	
	Event_ResetAll = Instance.new( "BindableEvent" ),
	
}

local RFolder = Instance.new( "Folder" )

RFolder.Name = "RaidLib"

RFolder.Parent = game:GetService( "ReplicatedStorage" )

local VHMain

local MaxPlayers = Players.MaxPlayers

Module.OfficialRaid = Instance.new( "BoolValue" )
	
Module.OfficialRaid.Name = "OfficialRaid"

Module.OfficialRaid.Parent = RFolder

Module.RaidID = Instance.new( "StringValue" )
	
Module.RaidID.Name = "RaidID"

Module.RaidID.Parent = RFolder

Module.AwayWinAmount = Instance.new( "NumberValue" )
	
Module.AwayWinAmount.Name = "AwayWinAmount"

Module.AwayWinAmount.Parent = RFolder

Module.HomeWinAmount = Instance.new( "NumberValue" )
	
Module.HomeWinAmount.Name = "HomeWinAmount"

local RaidStarted = Instance.new( "RemoteEvent" )

RaidStarted.Name = "RaidStarted"

RaidStarted.Parent = RFolder

local RaidEnded = Instance.new( "RemoteEvent" )

RaidEnded.Name = "RaidEnded"

RaidEnded.Parent = RFolder

local RaidTimerEvent = Instance.new( "RemoteEvent" )

RaidTimerEvent.Name = "RaidTimerEvent"

RaidTimerEvent.OnServerEvent:Connect( function ( Plr )
	
	if Module.RaidStart then
		
		RaidTimerEvent:FireClient( Plr, Module.RaidStart, Module.CurRaidLimit )
		
	end
	
end )

RaidTimerEvent.Parent = RFolder

local Ran, PlaceName = pcall(function() return game:GetService( "MarketplaceService" ):GetProductInfo( game.PlaceId ).Name:gsub( "%b()", "" ):gsub("%b[]", "" ):gsub("^%s*(.+)%s*$", "%1") end)
Module.PlaceName = Ran and PlaceName or "TestPlace"

Module.PlaceAcronym = Module.PlaceName:sub( 1, 1 ):upper( ) .. Module.PlaceName:sub( 2 ):gsub( ".", { a = "", e = "", i = "", o = "", u = "" } ):gsub( " (.?)", function ( a ) return a:upper( ) end )

Module.DefaultAwayEmblemUrl = "https://i.imgur.com/cYesNvI.png"

local function FormatTime(Time)
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

local function HandleGrace( Plr, Cur )
	
	local Event, Event3, Event4
	
	if Module.AwayTeams[ Plr.Team ] then
		
		Event = Plr.CharacterAdded:Connect( function ( Char )
			
			Char:WaitForChild( "Humanoid" ).PlatformStand = true
			
			Event4 = Char.ChildAdded:Connect( function ( Obj )
				
				if Obj:IsA( "Tool" ) then
					
					wait( )
					
					Obj.Parent = Plr.Backpack
					
				end
				
			end )
			
		end )
		
	end
	
	local Event2 = Plr:GetPropertyChangedSignal( "Team" ):Connect( function ( )
		
		if Module.AwayTeams[ Plr.Team ] then
			
			if not Event then
				
				Event = Plr.CharacterAdded:Connect( function ( Char )
					
					Char:WaitForChild( "Humanoid" ).PlatformStand = true
					
					Event4 = Char.ChildAdded:Connect( function ( Obj )
						
						if Obj:IsA( "Tool" ) then
							
							Obj.Parent = Plr.Backpack
							
						end
						
					end )
					
				end )
				
				Plr:LoadCharacter( )
				
			end
			
		else
			
			if Event then
				
				Event:Disconnect( )
				
				Event4:Disconnect( )
				
				Event = nil
				
				if Plr.Character and Plr.Character:FindFirstChild( "Humanoid" ) then
					
					Plr.Character.Humanoid.PlatformStand = false
					
				end
				
			end
			
		end
		
	end )
	
	Event3 = Module.OfficialRaid.Changed:Connect( function ( )
		
		if not Module.OfficialRaid.Value then
			
			if Event then
				
				Event:Disconnect( )
				
				Event = nil
				
				Event2:Disconnect( )
				
				Event3:Disconnect( )
				
				Event4:Disconnect( )
				
				if Plr.Character and Plr.Character:FindFirstChild( "Humanoid" ) then
					
					Plr.Character.Humanoid.PlatformStand = false
					
				end
				
			end
			
		end
		
	end )
	
	delay( Module.GracePeriod - ( tick( ) - Cur ), function ( )
		
		Event2:Disconnect( )
		
		Event3:Disconnect( )
		
		if Event then
			
			Event:Disconnect( )
			
			Event = nil
			
			Event4:Disconnect( )
			
			if Plr.Character and Plr.Character:FindFirstChild( "Humanoid" ) then
				
				Plr.Character.Humanoid.PlatformStand = false
				
			end
			
		end
		
	end )
	
end

function Module.CheckRequired(CapturePoint)
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
	
	local Time = wait( 0.1 )
	while Module.RaidStart do
		for _, CapturePoint in ipairs(Module.CapturePoints) do
			if CapturePoint.Tick then
				local Active
				if CapturePoint.ShouldTick then
					Active = CapturePoint:ShouldTick()
				else
					Active = CapturePoint.Active
				end
				
				if Active and Module.CheckRequired(CapturePoint) then
					if CapturePoint.TickWithNear then
						local Home, Away = Module.GetSidesNear(CapturePoint.MainPart.Position, CapturePoint.Dist)
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
		
		local Result = Module.GameMode.Function(Time, (#Module.RequiredCapturePoints == 0 and #Module.CapturePoints == 1 ) and Module.CapturePoints or Module.RequiredCapturePoints)
		if Result then
			Module.EndRaid(Result)
		end
		
		Time = wait( Module.GameTick )
		
	end
	
	RunningGameLoop = nil
	
end

function Module.GetAwayGroup( )
	
	local Highest, HighestGroup
	
	local AllGroups = { }
	
	local Away = 0
	
	for _, Plr in ipairs(Players:GetPlayers()) do
		
		if Module.AwayTeams[ Plr.Team ] then
			
			for _, Group in ipairs(GroupService:GetGroupsAsync(Plr.UserId)) do
				
				AllGroups[ Group.Id ] = ( AllGroups[ Group.Id ] or 0 ) + ( Group.IsPrimary and 2 or 1 )
				
				if not Highest or AllGroups[ Group.Id ] > AllGroups[ Highest ] then
					
					Highest = Group.Id
					
					HighestGroup = Group
					
				end
				
			end
			
		end
		
	end
	
	if not Highest or AllGroups[ Highest ] <= Away * 0.35 then
		
		return { Name = ( Module.DefaultAwayName or next( Module.AwayTeams ).Name ), EmblemUrl = Module.DefaultAwayEmblemUrl or "", EmblemId = Module.DefaultAwayEmblemId or "", Id = Module.DefaultAwayId or 0 }
		
	end
	
	return HighestGroup
	
end

function Module.GroupPagesToArray( Pages )
	
	local Array = { }
	
	while true do
		
		local Page = Pages:GetCurrentPage( )
		
		for _, Group in ipairs(Page) do
			
			Array[ #Array + 1 ] = Group.Id
			
		end
		
		if Pages.isFinished then break end
		
		Pages:AdvanceToNextPageAsync( )
		
	end
	
	return Array
	
end

local IDWords = { "Roblox", "Robloxian", "TRA", "Observation", "Jumpy", "Books", "Level", "Fast", "Loud", "Wheel", "Abandoned", "Deliver", "Rock", "Rub", "Tame", "Muscle", "Frighten", "Sore", "Number", "Dress", "Lucky", "Love", "Roomy", "Rambunctious", "Tiger", "Group", "Flame", "Gullible", "Obtainable", "Trail", "Brake", "Famous", "Perform", "Idea", "Mix", "Graceful", "Cub", "Argument", "Male", "Trust", "Gigantic", "Pump", "Move", "Ear", "Paddle", "Tall", "Feigned", "Toad", "Public", "Delightful", "Test", "Sponge", "Regular", "Marry", "Grotesque", "Stop", "Walk", "Memorise", "Spectacular", "Giants", "Drawer", "Cloudy", "Pies", "Cheap", "Woozy", "Dinner", "Guide", "Rabid", "Statement", "Four", "Pipe", "Crate", "Paper", "Seemly", "Old", "Heal", "Base", "Marked", "Disturbed", "Shiny", "Boiling", "Wary", "Bone", "Play", "Copy", "Toys", "Mourn", "Support", "Haircut", "Downtown", "Closed", "Film", "Stiff", "Murky", "Frantic", "Juvenile", "Disagreeable", "Madly", "Unsuitable", "Nonstop", "Grab", "Wrong", "Melt", "Anxious", "Clip", "Weary", "Crow", "Refuse", "Frightened", "Fluffy", "Breezy", "Pizzas", "Right", "Tangy", "Toy", "Bizarre", "Concentrate", "Pocket", "Fork", "Push", "Quick", "Miniature", "Abusive", "Carry", "Heavenly", "Better", "Silent", "Few", "Versed", "Receipt", "Tug", "Matter", "Excuse", "Sore", "Practise", "Brown", "Clear", "Gamy", "Increase", "Subsequent", "Connect", "Careful", "Attraction", "Silk", "Vessel", "Plant", "Summer", "North", "Deeply", "Able", "Fresh", "Splendid", "True", "Bag", "Fixed", "Damaged", "Manage", "General", "Thoughtless", "Nappy", "Breakable", "Disagree", "Curious", "Learned", "Zippy", "Understood", "Fascinated", "Meaty", "Jaded", "Regret", "Switch", "House", "Torpid", "Neat", "String", "Top", "Literate", "Actually", "Things", "Girls", "Voiceless", "Delicious", "Check", "Aspiring", "Decorate", "Allow", "Oatmeal", "Massive", "Spiky", "Towering", "Horrible", "Many", "Education", "Scrape", "Moan", "Regret", "Head", "Decorous", "Weight", "Rain", "Hill", "Determined", "Smooth", "Lake", "Hideous", "Clever", "Average", "Discovery", "Squirrel", "Husky", "Flow", "Probable", "Illegal", "Imaginary", "Quill", "Start", "Laughable", "Temper", "Wool", "Smash", "Lopsided", "Shelf", "Premium", "Stem", "Zipper", "Used", "Receptive", "Hat", "Rush", "Example", "Knotty", "Heartbreaking", "Drip", "Part", "Succinct", "Amusement", "Sprout", "Late", "Scintillating", "Fairies", "Willing", "Unnatural", "Terrific", "Maniacal", "Glove", "Devilish", "Callous", "Liquid", "Mute", "Fry", "Tightfisted", "Accidental", "Coal", "Ancient", "Simplistic", "Tempt", "Shrug", "Tax", "Calendar", "Reaction", "Trade", "Drop", "Tickle", "Kindly", "Hop", "Town", "License", "Scold", "Obey", "Ambitious", "Book", "Itch", "Reminiscent", "Argue", "Cup", "Separate", "Meek", "Worthless", "Disillusioned", "Brick", "Innate", "Scare", "Macho", "Harbor", "Flowers", "Arm", "Advice", "Voyage", "Suffer", "Quixotic", "Dirty", "Thaw", "Malicious", "Impress", "Prevent", "Watch", "Stew", "Upset", "Green", "Adjustment", "Smart", "Land", "Caring", "Slow", "Purple", "Remove", "Nest", "Wash", "Attack", "Swift", "Low", "Squalid", "Labored", "Sticky", "Kindhearted", "Milk", "Bruise", "Bear", "Offer", "Even", "Juice", "Place", "End", "Flower", "Terrible", "Disgusting", "Veil", "Hard", "Whistle", "Exchange", "Surprise", "Fancy", "Pen", "Army", "Dazzling", "Harsh", "Knowledgeable", "Unhealthy", "Root", "Puny", "Oval", "Cows", "Juicy", "Daughter", "Dirt", "Low", "Slippery", "Agree", "Shoe", "Cattle", "Rebel", "Sparkle", "Adhesive", "Duck", "Warm", "Lowly", "Parsimonious", "Arrive", "Camp", "Join", "Thread", "Paste", "Drag", "Kind", "Impolite", "Steady", "Spoon", "Rose", "Curve", "Coach", "Sidewalk", "Panicky", "Rejoice", "Hand", "Settle", "Suspend", "Hope", "Foregoing", "Sound", "Preserve", "Scatter", "Carpenter", "Boast", "Good", "Poised", "Risk", "Nifty", "Beautiful", "Pinch", "Gruesome", "Alluring", "Amuse", "Sticks", "Request", "Unadvised", "Meddle", "Unpack", "Knit", "Smell", "Screeching", "Perfect", "Crazy", "Hapless", "Dolls", "Coach", "Cakes", "Gray", "Level", "Roasted", "Naughty", "Nation", "Bird", "Equable", "Stamp", "Button", "Quiet", "Butter", "Helpless", "Store", "Box", "Debonair", "Dispensable", "Desk", "Head", "Bolt", "Push", "Homely", "Picayune", "Demonic", "Rely", "Obscene", "Defeated", "Safe", "Fear", "Domineering", "Long", "Erect", "Produce", "Jellyfish", "End", "Rabbits", "Violet", "Sophisticated", "Scattered", "Swing", "Tart", "Government", "Silver", "Shame", "Wholesale", "Detail", "Minister", "Holistic", "Mate", "Fragile", "Lackadaisical", "Control", "Steadfast", "Ugliest", "Yellow", "Seat", "Future", "Engine", "Icy", "Gate", "Acidic", "Capricious", "Abaft", "Telephone", "Question", "False", "Sneaky", "Enormous", "Spray", "Exclusive", "Run", "Scene", "Inform", "Fail", "Uncle", "Ablaze", "Trousers", "Wanting", "Surround", "Grandmother", "Stop", "Slip", "Reply", "Vegetable", "Hulking", "Confused", "Sheet", "Coil", "Whisper", "Last", "Person", "Jeans", "Smoggy", "Gratis", "Search", "Partixel", "DrDrRoblox", "CodeNil", "Antyronio", "Peekay", "Karneval" }

local PracticeWords = {"Test", "Debug", "Fake", "Tryhard", "Learn", "Lesson", "Usage", "Action", "Discipline", "Drill", "Experience", "Study", "Training", "Assignment", "Homework", "Recitation", "Rehearsal", "Prepping"}

local IDRandom = Random.new()

Module.RaidID.Value = IDWords[IDRandom:NextInteger(1, #IDWords)] .. IDWords[IDRandom:NextInteger(1, #IDWords)] .. IDWords[IDRandom:NextInteger(1, #IDWords)]

function Module.StartRaid( )
	Module.Practice = Module.Practice or game.PrivateServerId ~= ""
	
	if Module.GameMode then
		if Module.Practice then
			local Pos = math.random(1, 3)
			if Pos == 1 then
				Module.RaidID.Value = "Practice" .. PracticeWords[IDRandom:NextInteger(1, #PracticeWords)] .. PracticeWords[IDRandom:NextInteger(1, #PracticeWords)]
			elseif Pos == 2 then
				Module.RaidID.Value = PracticeWords[IDRandom:NextInteger(1, #PracticeWords)] .. "Practice" .. PracticeWords[IDRandom:NextInteger(1, #PracticeWords)]
			else
				Module.RaidID.Value = PracticeWords[IDRandom:NextInteger(1, #PracticeWords)] .. PracticeWords[IDRandom:NextInteger(1, #PracticeWords)] .. "Practice"
			end
		end
		
		local Cur = tick( )
		
		Module.AwayGroup = Module.GetAwayGroup( )
		
		Module.RaidStart = Cur
		
		Module.CurRaidLimit = Module.RaidLimit
		
		Module.OfficialRaid.Value = true
		
		RaidTimerEvent:FireAllClients( Module.RaidStart, Module.CurRaidLimit, Module.GameMode.WinTime or Module.GameMode.WinPoints )
		
		RaidStarted:FireAllClients( Module.RaidID.Value, Module.AwayGroup )
		
		Module.TeamLog = { }
		
		for _, Plr in ipairs(Players:GetPlayers()) do
			
			Module.TeamLog[ tostring( Plr.UserId ) ] = { { Cur, Plr.Team  } }
			
			if Module.GracePeriod and Module.GracePeriod > 0 then
				
				HandleGrace( Plr, Cur )
				
			end
			
			if Module.RespawnPlayers ~= false and (Module.RespawnAllPlayers or Module.AwayTeams[ Plr.Team ]) then
				
				Plr:LoadCharacter( )
				
			end
			
		end
		
		for a = 1, #Module.CapturePoints do
			
			if not Module.CapturePoints[ a ].ManualActivation then
				
				if Module.CapturePoints[ a ].Required then
					
					local Active = true
					
					for b = 1, #Module.CapturePoints[ a ].Required do
						
						if not Module.CapturePoints[ a ].Required[ b ].Active then
							
							Active = false
							
							break
							
						end
						
					end
					
					if Active then
						
						Module.CapturePoints[ a ].Active = true
						
					end
					
				else
					
					if Module.CapturePoints[ a ].DefaultActive ~= nil then
						
						Module.CapturePoints[ a ].Active = Module.CapturePoints[ a ].DefaultActive
						
					else
						
						Module.CapturePoints[ a ].Active = true
						
					end
					
				end
				
			end
			
		end
		
		if not RunningGameLoop then
			
			coroutine.wrap( RunGameLoop )( )
			
		end
		
	end
	
end

function Module.EndRaid( Result )
	Module.Event_RaidEnded:Fire( Module.RaidID.Value, Module.AwayGroup, Result, Module.TeamLog, Module.RaidStart )
	
	RaidEnded:FireAllClients( Module.RaidID.Value, Module.AwayGroup, Result )
	
	local Practice = Module.Practice
	
	Module.ResetAll( )
	
	if not Practice and Result ~= "Forced" and Result ~= "Left" and Module.KickOnEnd ~= false then
		
		wait( 20 )
		
		for _, Plr in ipairs(Players:GetPlayers()) do
			
			if Module.AwayTeams[ Plr.Team ] then
				
				if Module.BanWhenWinOrLoss and VHMain then
					
					VHMain.ParseCmdStacks( nil, "permban/" .. Plr.UserId .. "/30m" )
					
				else
					
					Plr:Kick( "Raid is over, please rejoin to raid again" )
					
				end
				
			end
			
		end
		
	end
	
end

game:BindToClose( function ( ) if Module.RaidStart then Module.EndRaid( "Left" ) end end )

function Module.ResetAll( )
	
	Module.HomeMax, Module.AwayMax = nil, nil
	
	Module.Practice = nil
	
	Module.RallyMessage = nil
	
	Module.Forced = nil
	
	Module.RaidStart = nil
	
	Module.CurRaidLimit = nil
	
	Module.TeamLog = nil
	
	Module.AwayGroup = nil
	
	Module.RaidID.Value = IDWords[ IDRandom:NextInteger( 1, #IDWords ) ] .. IDWords[ IDRandom:NextInteger( 1, #IDWords ) ] .. IDWords[ IDRandom:NextInteger( 1, #IDWords ) ]
	
	RaidTimerEvent:FireAllClients( )
	
	Module.OfficialRaid.Value = false
	
	for _, CapturePoint in ipairs(Module.CapturePoints) do
		
		CapturePoint:Reset( )
		
	end
	
	Module.AwayWinAmount.Value = 0
	
	Module.HomeWinAmount.Value = 0
	
	Module.Event_ResetAll:Fire()
	
end

function Module.GetCountFor( Side, Plr )
	
	local Team = Side[ Plr.Team ]
	
	if Team then
		
		local CountsFor = Team.CountsFor
		
		for _, Counts in ipairs(Team) do
			
			if Counts.CountsFor then
				
				for _, Count in ipairs(Counts) do
					
					if HandleRbxAsync( false, Plr.IsInGroup, Plr, Count ) then
						
						return Counts.CountsFor
						
					end
					
				end
				
			end
			
		end
		
		return CountsFor
		
	end
	
	return 0
	
end

function Module.SetWinTimer( Val )
	
	if Module.AwayWinAmount.Value ~= Val then
		
		local Old = Module.AwayWinAmount.Value
		
		Module.AwayWinAmount.Value = Val
		
		Module.Event_WinChanged:Fire( Old )
		
	end
	
end

function Module.CountTeams( )
	
	local Home, Away = 0, 0
	
	for _, Plr in ipairs(Players:GetPlayers()) do
		
		Home = Home + Module.GetCountFor( Module.HomeTeams, Plr )
		
		Away = Away + Module.GetCountFor( Module.AwayTeams, Plr )
		
	end
	
	return Home, Away
	
end

local TimeCheck

function Module.OfficialCheck( Manual )
	
	local Home, Away = Module.CountTeams( )
	
	if Module.RaidStart then
		
		if Away == 0 and not Module.Forced then
			
			Module.EndRaid( "Left" )
			
		end
		
	else
		
		local Result
		
		if Manual == true or not Module.ManualStart then
			
			local InTime
			
			if Module.MinTime and Module.MaxTime then
				
				InTime = false
				
				local Time = os.date( "!*t" ).hour + ( os.date( "!*t" ).min / 60 )
				
				if Module.MaxTime > Module.MinTime then
					
					if Time >= Module.MinTime and Time < Module.MaxTime then
						
						InTime = true
						
					end
					
				elseif Time < Module.MaxTime or Time >= Module.MinTime then
					
					InTime = true
										
				end
				
			end
			
			if InTime == false then
				
				local MinTime, MaxTime = Module.MinTime, Module.MaxTime
				
				MinTime = math.floor( MinTime ) .. ":" .. math.floor( ( MinTime - math.floor( MinTime ) * 60 ) + 0.5 )
				
				MaxTime = math.floor( MaxTime ) .. ":" .. math.floor( ( MaxTime - math.floor( MaxTime ) * 60 ) + 0.5 )
				
				Result = "Must raid between the times of " .. MinTime .. " and " .. MaxTime
				
				if Module.MinTime and Module.MaxTime and not TimeCheck then
					
					TimeCheck = true
					
					coroutine.wrap( function ( )
						
						while wait( 1 ) and not Module.RaidStart do
							
							Module.OfficialCheck( )
							
						end
						
						TimeCheck = nil
						
					end )( )
					
				end
				
			elseif Away < Module.AwayRequired or Away == 0 then
				
				Result = "Must be at least " .. math.max( Module.AwayRequired, 1 ) .. " players on the away teams"
				
			elseif Home < Module.HomeRequired then
				
				Result = "Must be at least " .. Module.HomeRequired .. " players on the home teams"
				
			elseif Module.EqualTeams and ( Home ~= Away ) then
				
				Result = "Teams must be equal to start"
				
			else
				
				Module.StartRaid( )
						
			end
			
		end
		
		Module.Event_OfficialCheck:Fire( Home, Away, Result )
		
		return Result
		
	end
	
end

function PlayerAdded( Plr )
	
	local Found
	
	for Team, CountsFor in pairs( Module.HomeTeams ) do
		
		for _, Counts in ipairs(CountsFor) do
			
			for _, Count in ipairs(Counts) do
				
				if HandleRbxAsync( false, Plr.IsInGroup, Plr, Count ) then
					
					Plr.Team = Team
					
					Found = true
					
					break
					
				end
				
			end
			
		end
		
		if Found then break end
		
	end
	
	if not Found then
		
		for Team, CountsFor in pairs( Module.AwayTeams ) do
			
			for _, Counts in ipairs(CountsFor) do
				
				for _, Count in ipairs(Counts) do
					
					if HandleRbxAsync( false, Plr.IsInGroup, Plr, Count ) then
						
						Plr.Team = Team
						
						Found = true
						
						break
						
					end
					
				end
				
			end
			
			if Found then break end
			
		end
		
	end
	
	local Home, Away = Module.CountTeams( )
	
	if not Module.RaidStart and Module.AwayTeams[ Plr.Team ] then
		
		if MaxPlayers - Away < Module.HomeRequired then
			
			Plr:Kick( "You were kicked to make room for " .. ( Module.HomeRequired - ( MaxPlayers - Away ) ) .. " more " .. next( Module.HomeTeams ).Name )
			
		elseif Module.EqualTeams and Away > MaxPlayers / 2  then
			
			Plr:Kick( "You were kicked to make room for " .. ( MaxPlayers / 2 - Home ) .. " more " .. next( Module.HomeTeams ).Name )
			
		end
		
	end
	
	if Module.LockTeams and Module.OfficialRaid.Value then
		
		if Module.HomeTeams[ Plr.Team ] and Home > Away + 1 then
			
			Plr:Kick( next( Module.HomeTeams ).Name .. " is full, please wait for more " .. next( Module.AwayTeams ).Name )
		
		elseif Module.AwayTeams[ Plr.Team ] and Away > Home + 1 then
			
			Plr:Kick( next( Module.AwayTeams ).Name .. " is full, please wait for more " .. next( Module.HomeTeams ).Name )
			
		end
		
	end
	
	if Module.RaidStart then
		
		if Module.GracePeriod and Module.GracePeriod > 0 and tick( ) - Module.RaidStart < Module.GracePeriod then
				
			if Module.AwayTeams[ Plr.Team ] then
				
				HandleGrace( Plr )
				
			end
			
		end
		
		Module.TeamLog[ tostring( Plr.UserId ) ] = Module.TeamLog[ tostring( Plr.UserId ) ] or { }
		
		Module.TeamLog[ tostring( Plr.UserId ) ][ #Module.TeamLog[ tostring( Plr.UserId ) ] + 1 ] = { tick( ), Plr.Team  }
		
	end
	
	Module.OfficialCheck( )
	
	local Team = Plr.Team
	
	Plr:GetPropertyChangedSignal( "Team" ):Connect( function ( )
		
		if Module.RaidStart then
			
			if Module.LockTeams then
				
				local Home, Away = Module.CountTeams( )
				
				if Module.HomeTeams[ Plr.Team ] and ( Home > Away + 1 or ( not Module.EqualTeams or Home > MaxPlayers / 2 ) ) then
					
					Plr.Team = Team
					
					return
				
				elseif Module.AwayTeams[ Plr.Team ] and ( Away > Home + 1 or ( not Module.EqualTeams or Home > MaxPlayers / 2 ) ) then
					
					Plr.Team = Team
					
					return
					
				end
				
			end
			
			Module.TeamLog[ tostring( Plr.UserId ) ][ #Module.TeamLog[ tostring( Plr.UserId ) ] + 1 ] = { tick( ), Plr.Team }
			
		end
		
		Team = Plr.Team
		
		Module.OfficialCheck( )
		
	end )
	
end

Players.PlayerRemoving:Connect( function ( Plr )
	
	Module.OfficialCheck( )
	
	if Module.RaidStart then
		
		Module.TeamLog[ tostring( Plr.UserId ) ] = Module.TeamLog[ tostring( Plr.UserId ) ] or { }
		
		Module.TeamLog[ tostring( Plr.UserId ) ][ #Module.TeamLog[ tostring( Plr.UserId ) ] + 1 ] = { tick( ) }
		
	end
	
end )

Players.PlayerAdded:Connect( PlayerAdded )

function Module.OldFlagCompat( )
	
	local Message
	
	Module.OfficialRaid:GetPropertyChangedSignal( "Value" ):Connect( function ( )
		
		if Module.OfficialRaid.Value then
			
			if Message then Message:Destroy( ) end
			
			Message = Instance.new( "Message", workspace )
			
			Message.Text = Module.AwayGroup.Name .. " have started raiding"
			
			Debris:AddItem( Message, 5 )
			
		end
		
	end )
	
	Module.Event_CapturePointAdded.Event:Connect( function ( Num )
		
		local CapturePoint = Module.CapturePoints[ Num ]
		
		CapturePoint.Event_Captured.Event:Connect( function ( )
			
			local Hint = Instance.new( "Hint", workspace )
			
			Hint.Text = "The flag at the " .. CapturePoint.Name .. " is now owned by " .. next( CapturePoint.CurOwner ).Name
			
			Debris:AddItem( Hint, 5 )
			
		end )
		
	end )
	
	for _, CapturePoint in ipairs( Module.CapturePoints ) do
		
		CapturePoint.Event_Captured.Event:Connect( function ( )
			
			local Hint = Instance.new( "Hint", workspace )
			
			Hint.Text = "The flag at the " .. CapturePoint.Name .. " is now owned by " .. next( CapturePoint.CurOwner ).Name
			
			Debris:AddItem( Hint, 5 )
			
		end )
		
	end
	
	Module.Event_RaidEnded.Event:Connect( function ( ID, AwayGroup, Result )
		
		if Message then Message:Destroy( ) end
		
		Message = Instance.new( "Message", workspace )
		
		if Result ~= "Forced" and Result ~= "Left" then
			
			local Name
			
			if Result == "Lost" then
				
				Name = AwayGroup.Name
				
			else
				
				Name = Module.HomeGroup.Name
				
			end
			
			Message.Text = Name .. " has won! ID: " .. ID .. " - " .. AwayGroup.Name .. " get kicked in 20s"
			
			Debris:AddItem( Message, 20 )
			
			for a = 19, 0, -1 do
				
				wait( 1 )
				
				Message.Text = Name .. " has won! ID: " .. ID .. " - " .. AwayGroup.Name .. " get kicked in " .. a .. "s"
				
			end
			
		else
			
			local Txt = Result == "Left" and AwayGroup.Name .. " have left, raid over!" or Result == "Forced" and "An admin has force ended the raid!"
			
			Message.Text = Txt
			
			Debris:AddItem( Message, 5 )
			
		end
		
	end )
	
end

function Module.GetSidesNear( Point, Dist )
	
	local Home, Away = 0, 0
	
	for _, Plr in ipairs(Players:GetPlayers()) do
		
		local b = Plr
		
		if b.Character and b.Character:FindFirstChild( "Humanoid" ) and b.Character.Humanoid:GetState( ) ~= Enum.HumanoidStateType.Dead and b:DistanceFromCharacter( Point ) < Dist then
			
			if Module.HomeTeams[ b.Team ] then
				
				Home = Home + 1
			
			elseif Module.AwayTeams[ b.Team ]then
				
				Away = Away + 1
				
			end
			
		end
		
	end
	
	return Home, Away
	
end

function Module.SetGameMode(GameMode)
	if GameMode.WinPoints then
		Module.HomeWinAmount.Parent = RFolder
	else
		Module.HomeWinAmount.Parent = nil
	end
	
	if #Module.CapturePoints == 0 then
		for _, Plr in ipairs(Players:GetPlayers()) do
			PlayerAdded(Plr)
		end
	end
	
	Module.GameMode = GameMode
	setmetatable(Module, {__index = Module.GameMode})
	
	Module.ResetAll( )
end

Module.GameModeFunctions = {
	TimeBased = function(Time, Required)
		local HomeFullyOwnAll, HomeOwnAll, AwayFullyOwnAll = true, true, true
		for _, CapturePoint in ipairs(Required) do
			if CapturePoint.TimeBased and CapturePoint.Active then
				local TempHomeFullyOwnAll, TempHomeOwnAll, TempAwayFullyOwnAll = CapturePoint:TimeBased(HomeFullyOwnAll, HomeOwnAll, AwayFullyOwnAll)
				if type(TempHomeFullyOwnAll) == "string" then
					return TempHomeFullyOwnAll
				elseif TempHomeFullyOwnAll ~= nil then
					HomeFullyOwnAll = TempHomeFullyOwnAll
				end
				
				if TempHomeOwnAll ~= nil then
					HomeOwnAll = TempHomeOwnAll
				end
				
				if TempAwayFullyOwnAll ~= nil then
					AwayFullyOwnAll = TempAwayFullyOwnAll
				end
			end
		end
		
		if AwayFullyOwnAll then
			Module.SetWinTimer(Module.AwayWinAmount.Value + (Module.GameMode.WinSpeed * Time))
			
			if Module.AwayWinAmount.Value >= Module.GameMode.WinTime then
				return "Lost"
			end
		elseif HomeFullyOwnAll or HomeOwnAll or Module.GameMode.RollbackWithPartialAwayCap then
			if Module.RaidStart + Module.CurRaidLimit <= tick() then
				return "TimeLimit"
			end
			
			if (HomeFullyOwnAll or (Module.RollbackWithPartialCap and HomeOwnAll) or Module.GameMode.RollbackWithPartialAwayCap) and Module.AwayWinAmount.Value < Module.GameMode.WinTime and Module.AwayWinAmount.Value > 0 then
				if Module.GameMode.RollbackSpeed then
					Module.SetWinTimer(math.max(0, Module.AwayWinAmount.Value - (Module.GameMode.RollbackSpeed * Time)))
				else
					Module.SetWinTimer(0)
				end
			end
		end
	end,
	PointBased = function(Time, Required)
		local AwayAdd, HomeAdd = 0, 0
		for _, CapturePoint in ipairs(Required) do
			if CapturePoint.PointBased and CapturePoint.Active then
				local TempHomeAdd, TempAwayAdd = CapturePoint:PointBased()
				if TempHomeAdd then
					HomeAdd = HomeAdd + TempHomeAdd
				end
				if TempAwayAdd then
					AwayAdd = AwayAdd + TempAwayAdd
				end
			end
		end
		
		Module.AwayWinAmount.Value, Module.HomeWinAmount.Value = math.clamp(Module.AwayWinAmount.Value + (AwayAdd == 0 and -(Module.GameMode.AwayUnownedDrainPerSecond or 0) or AwayAdd) * Time, 0, Module.GameMode.WinPoints), math.clamp(Module.HomeWinAmount.Value + (HomeAdd == 0 and -(Module.GameMode.HomeUnownedDrainPerSecond or 0) or HomeAdd) * Time, 0, Module.GameMode.WinPoints)
		
		if Module.AwayWinAmount.Value ~= Module.HomeWinAmount.Value then
			if Module.RaidStart + Module.CurRaidLimit <= tick() then
				if Module.AwayWinAmount.Value > Module.HomeWinAmount.Value then
					return "Lost"
				else
					return "Won"
				end
			elseif Module.AwayWinAmount.Value >= Module.GameMode.WinPoints and ( not Module.GameMode.WinBy or ( Module.AwayWinAmount.Value - Module.HomeWinAmount.Value >= Module.GameMode.WinBy ) ) then
				return "Lost"
			elseif Module.HomeWinAmount.Value >= Module.GameMode.WinPoints and ( not Module.GameMode.WinBy or ( Module.HomeWinAmount.Value - Module.AwayWinAmount.Value >= Module.GameMode.WinBy ) ) then
				return "Won"
			end
		end
	end,
}

--[[ Time Based --

GameMode = {
	
	Function = Module.GameModeFunctions.TimeBased,
	
	WinTime = 60 * 25, -- 25 minutes holding all capturepoints to win the raid
	
	RollbackSpeed = 1, -- How much the win timer rolls back per second when home owns the points
	
	WinSpeed = 1, -- How much the win timer goes up per second when away owns the points
	
	ExtraTimeForCapture = 0, -- The amount of extra time added onto the raid timer when a point is captured/a payload reaches its end
	
	ExtraTimeForCheckpoint = 0, -- The amount of extra time added onto the raid timer when a payload reaches a checkpoint
	
},

-- Point Based --

GameMode = {
	
	Function = Module.GameModeFunctions.PointBased,
	
	WinPoints = 60, -- How many points a team needs to win
	
	HomePointsPerSecond = 1, -- How many points per second home team gets from a point
	
	AwayPwointsPerSecond = 1, -- How many points per second away team gets from a point
	
	HomeUnownedDrainPerSecond = 0, -- How many points home team loses per second if they own no points
	
	AwayUnownedDrainPerSecond = 0, -- How many points away team loses per second if they own no points
	
	WinBy = nil, -- To win, the team must have this many more points than the other team when over the WinPoints ( e.g. if this is 25 and away has 495, home must get 520 to win )
	
},]]

function Module.SetSpawns( SpawnClones, Model, Side )
	
	if SpawnClones then
		
		for k, Spawn in ipairs(SpawnClones) do
			
			Spawn:Destroy()
			
			SpawnClones[k] = nil
			
		end
		
	end
	
	for _, Kid in ipairs(Model:GetDescendants()) do
		
		if Kid:IsA( "SpawnLocation" ) then
			
			if CollectionService:HasTag( Kid, "HomeSpawn" ) then
				
				if Side == Module.HomeTeams then
					
					Kid.Enabled = true
					
				else
					
					Kid.Enabled = false
					
				end
				
			elseif CollectionService:HasTag( Kid, "AwaySpawn" ) then
				
				if Side == Module.AwayTeams then
					
					Kid.Enabled = true
					
				else
					
					Kid.Enabled = false
					
				end
				
			end
			
			local First
			
			for b, c in pairs( Side ) do
				
				if not First then
					
					First = true
					
					Kid.TeamColor = b.TeamColor
					
					Kid.BrickColor = b.TeamColor
					
				elseif Kid.Enabled then
					
					local Clone = Kid:Clone( )
					
					SpawnClones = SpawnClones or { }
					
					SpawnClones[ #SpawnClones + 1 ] = Clone
					
					Clone.Transparency = 1
					
					Clone.CanCollide = false
					
					Clone:ClearAllChildren( )
					
					Clone.TeamColor = b.TeamColor
					
					Clone.BrickColor = b.TeamColor
					
					Clone.Parent = Kid
					
				end
				
			end
			
		end
		
	end
	
end

local Captured = Instance.new( "RemoteEvent" )

Captured.Name = "Captured"

Captured.Parent = RFolder

Module.BidirectionalPointMetadata = setmetatable({
	
	Reset = function ( self )
		
		self.Active = nil
		
		self.CurOwner = self.StartOwner or Module.HomeTeams
		
		self:SetCapturingSide(self.CurOwner)
		
		self.ExtraTimeGiven = nil
		
		self:SetCaptureTimer( Module.GameMode.WinPoints and 0 or self.CaptureTime / 2, 0 )
		
		self:Captured( self.CurOwner )
		
		self.Event_Reset:Fire()
		
		return self
		
	end,
	
	Destroy = function(self)
		for _, v in pairs(self) do
			if typeof(v) == "Instance" and v:IsA("BindableEvent") then
				v:Destroy()
			elseif typeof(v) == "RBXScriptConnection" then
				v:Disconnect()
			end
		end
		
		self.Model.CapturePct:Destroy()
		
		for i, CapturePoint in ipairs(Module.CapturePoints) do
			if CapturePoint == self then
				Module.CapturePoints[i] = Module.CapturePoints[#Module.CapturePoints]
				Module.CapturePoints[#Module.CapturePoints] = nil
				break
			end
		end
	end,
	
	Require = function ( self, Required )
		
		self.Required = self.Required or { }
		
		self.Required[ #self.Required + 1 ] = Required
		
		return self
		
	end,
	
	RequireForWin = function ( self )
		
		Module.RequiredCapturePoints[ #Module.RequiredCapturePoints + 1 ] = self
		
		return self
		
	end,
	
	SetCapturingSide = function(self, Side)
		self.Event_CapturingSideChanged:Fire(next(Side))
		
		self.CapturingSide = Side
	end,
	
	SetCaptureTimer = function (self, Val, Speed)
		self.Event_CaptureChanged:Fire(Val, Speed)
		
		self.Model.CapturePct.Value = Val / (self.CaptureTime / 2)
		self.CaptureTimer = Val
	end,
	
	Captured = function ( self, Side )
		
		self.SpawnClones = Module.SetSpawns( self.SpawnClones, self.Model, Side )
		
		if Module.RaidStart and Side == (self.AwayOwned and Module.HomeTeams or Module.AwayTeams) and not self.ExtraTimeGiven and self.ExtraTimeForCapture then
			
			self.ExtraTimeGiven = true
			
			Module.CurRaidLimit = math.max( tick( ) - Module.RaidStart + self.ExtraTimeForCapture, Module.CurRaidLimit + self.ExtraTimeForCapture )
			
			RaidTimerEvent:FireAllClients( Module.RaidStart, Module.CurRaidLimit )
			
		end
		
		self.Event_Captured:Fire( next( Side ) )
		
		Captured:FireAllClients( self.Name, next( Side ) )
		
	end,
	
	AsFlag = function ( self, Dist )
		
		local StartCFs = { }
		
		self.Model.DescendantAdded:Connect( function ( Obj )
			
			if Obj:IsA( "BasePart" ) and Obj.Name:lower( ):find( "flag" ) then
				
				StartCFs[ Obj ] = Obj.CFrame
				
				local Event Event = Obj.AncestryChanged:Connect( function ( )
					
					StartCFs[ Obj ] = nil
					
					Event:Disconnect( )
					
				end )
				
			end
			
		end )
		
		for _, Kid in ipairs(self.Model:GetDescendants()) do
			
			if Kid:IsA( "BasePart" ) and Kid.Name:lower( ):find( "flag" ) then
				
				StartCFs[ Kid ] = Kid.CFrame
				
				local Event Event = Kid.AncestryChanged:Connect( function ( )
					
					StartCFs[ Kid ] = nil
					
					Event:Disconnect( )
					
				end )
				
			end
			
		end
		
		self.Event_CaptureChanged.Event:Connect( function ( Val )
			
			for a, b in pairs( StartCFs ) do
				
				a.BrickColor = next( self.CurOwner ).TeamColor
				
			end
			
			if self.Model:FindFirstChild( "Smoke", true ) then
				
				self.Model:FindFirstChild( "Smoke", true ).Color = next( self.CurOwner ).TeamColor.Color
				
			end
			
			if Val == self.CaptureTime / 2 then
				
				self.Model.Naming:GetChildren( )[ 1 ].Name = "Owned by " .. next( self.CurOwner ).Name
			
			elseif self.CapturingSide == self.CurOwner then
				
				self.Model.Naming:GetChildren( )[ 1 ].Name = next( self.CurOwner ).Name .. " now owns " .. math.ceil( ( Val / ( self.CaptureTime / 2 ) ) * 100 ) .. "% of the location"
				
			else
				
				self.Model.Naming:GetChildren( )[ 1 ].Name = next( self.CurOwner ).Name .. " owns " .. math.ceil( ( Val / ( self.CaptureTime / 2 ) ) * 100 ) .. "% of the location"
				
			end
			
			for a, b in pairs( StartCFs ) do
				
				TweenService:Create( a, TweenInfo.new( Module.GameTick, Enum.EasingStyle.Linear ), { CFrame = ( b - Vector3.new( 0, Dist * ( 1 - ( Val / ( self.CaptureTime / 2 ) ) ) ) ) } ):Play( )
				
			end
			
		end )
		
		self.Event_Captured.Event:Connect( function ( )
			
			if self.Model:FindFirstChild( "Smoke", true ) then
				
				self.Model:FindFirstChild( "Smoke", true ).Color = next( self.CurOwner ).TeamColor.Color
				
			end
			
			self.Model.Naming:GetChildren( )[ 1 ].Name = "Owned by " .. next( self.CurOwner ).Name
			
		end )
		
		Module.OfficialRaid:GetPropertyChangedSignal( "Value" ):Connect( function ( )
			
			local BrickTimer = self.Model:FindFirstChild( "BrickTimer", true )
			
			if BrickTimer then
				
				BrickTimer:GetChildren( )[ 1 ].Name = Module.OfficialRaid.Value and ( Module.AwayGroup.Name .. " do not own the main flag" ) or "No raid in progress" 
				
			end
			
		end )
	
		Module.Event_WinChanged.Event:Connect( function ( Old )
			
			local BrickTimer = self.Model:FindFirstChild( "BrickTimer", true )
			
			if BrickTimer then
				
				BrickTimer:GetChildren( )[ 1 ].Name = Module.AwayWinAmount.Value == 0 and ( Module.AwayGroup.Name .. " do not own the main flag" ) or ( Module.AwayGroup.Name .. " win in " .. FormatTime( math.floor( Module.GameMode.WinTime - Module.AwayWinAmount.Value ) ) )
				
			end
			
		end )
		
		if Module.GameMode then
			if self.Model:FindFirstChild( "Smoke", true ) then
				self.Model:FindFirstChild( "Smoke", true ).Color = next( self.CurOwner ).TeamColor.Color
			end
			
			self.Model.Naming:GetChildren( )[ 1 ].Name = "Owned by " .. next( self.CurOwner ).Name
			
			local BrickTimer = self.Model:FindFirstChild( "BrickTimer", true )
			if BrickTimer then
				BrickTimer:GetChildren( )[ 1 ].Name = Module.OfficialRaid.Value and ( Module.AwayGroup.Name .. " do not own the main flag" ) or "No raid in progress" 
			end
		end
		
		return self
		
	end,
	-- True = This point should ignore its Required points as e.g. it's already partially captured
	ShouldRequireCheck = function(self)
		return self.CurOwner == Module.HomeTeams and self.CaptureTimer == self.CaptureTime / 2
	end,
	-- True = This point doesn't satisfy the Required condition of any points that require it
	RequireCheck = function(self)
		return self.CurOwner ~= Module.AwayTeams or self.CaptureTimer ~= self.CaptureTime / 2
	end,
	-- True = Pass CaptureSpeed to the Tick (based on nearby enemy/allies)
	TickWithNear = true,
	-- Function that runs every game tick to compute the points state
	Tick = function(self, CaptureSpeed, Home, Away)
		if Home > Away then
			if self.CapturingSide ~= Module.HomeTeams then
				self:SetCapturingSide(Module.HomeTeams)
			end
			
			if Module.HomeTeams ~= self.CurOwner then
				self.BeingCaptured = true
			elseif self.Down then
				self.BeingCaptured = nil
			end
		elseif Away > Home then
			if self.CapturingSide ~= Module.AwayTeams then
				self:SetCapturingSide(Module.AwayTeams)
			end
			
			if Module.AwayTeams ~= self.CurOwner then
				self.BeingCaptured = true
			elseif self.Down then
				self.BeingCaptured = nil
			end
		end
		
		if CaptureSpeed ~= 0 then
			
			if self.BeingCaptured then
				-- the away team is near, capture
				if self.InstantCapture then
					
					self.CurOwner = self.CapturingSide
					
					self:SetCaptureTimer( self.CaptureTime / 2, CaptureSpeed )
					
					self.BeingCaptured = nil
					
					self:Captured( self.CurOwner )
					
				else
					
					if self.CaptureTimer ~= 0 and self.CurOwner ~= self.CapturingSide then
						
						self:SetCaptureTimer( math.max( 0, self.CaptureTimer - CaptureSpeed ), -CaptureSpeed )
						
						self.Down = true
						
					else
						-- the away team has held it for long enough, switch owner
						if self.CaptureTimer == 0 and self.Down then
							
							self.CurOwner = self.CapturingSide
							
							self.Down = false
							
						end
						-- the away team is now rebuilding it
						if self.CaptureTimer ~= ( self.CaptureTime / 2 ) then
							
							self:SetCaptureTimer( math.min( self.CaptureTime / 2, self.CaptureTimer + CaptureSpeed ), CaptureSpeed )
							
						else
							-- the away team has rebuilt it
							self.BeingCaptured = nil
							
							self:Captured( self.CurOwner )
							
						end
						
					end
					
				end
				-- Owner is rebuilding
			elseif self.CaptureTimer ~= ( self.CaptureTime / 2 ) then
				
				self:SetCaptureTimer( math.min( self.CaptureTime / 2, self.CaptureTimer + CaptureSpeed ), CaptureSpeed )
				
			end
		end
	end,
	-- Returns values for HomeFullyOwnAll, HomeOwnAll and AwayFullyOwnAll for the TimeBased gamemode
	TimeBased = function(self)
		if self.CurOwner == Module.AwayTeams then
			if self.CaptureTimer ~= self.CaptureTime / 2 then
				return false, false, false
			else
				return false, false, nil
			end
		else
			if self.CaptureTimer ~= self.CaptureTime / 2 then
				return false, nil, false
			else
				return nil, nil, false
			end
		end
	end,
	-- Returns how many points to add to Home and Away for this point per second
	PointBased = function(self)
		if self.CaptureTimer == self.CaptureTime / 2 then
			if self.CurOwner == Module.AwayTeams then
				return nil, self.AwayPointsPerSecond
			else
				return self.HomePointsPerSecond, nil
			end
		end
	end,
}, {__index = Module})

-- Table requires Dist = Number, CaptureTime = Number, MainPart = Instance, Model = Instance
function Module.BidirectionalPoint( CapturePoint )
	CapturePoint.CaptureTime = CapturePoint.CaptureTime or 1
	
	CapturePoint.Name = CapturePoint.Name or CapturePoint.Model.Name
	
	setmetatable( CapturePoint, { __index = Module.BidirectionalPointMetadata } )
	
	CapturePoint.Event_Captured = Instance.new("BindableEvent")
	CapturePoint.Event_CaptureChanged = Instance.new("BindableEvent")
	CapturePoint.Event_CapturingSideChanged = Instance.new("BindableEvent")
	CapturePoint.Event_Reset = Instance.new("BindableEvent")
	
	local Pct = Instance.new( "NumberValue" )
	
	Pct.Name = "CapturePct"
	
	Pct.Parent = CapturePoint.Model
	
	if Module.GameMode then
		CapturePoint:Reset()
	end
	
	Module.CapturePoints[ #Module.CapturePoints + 1 ] = CapturePoint
	
	Module.Event_CapturePointAdded:Fire( #Module.CapturePoints )
	
	return CapturePoint
	
end

local function GetWorldPos( Inst )
	
	return Inst:IsA( "Attachment" ) and Inst.WorldPosition or Inst.Position
	
end

function Module.OrderedPointsToPayload( StartPoint, Checkpoints, TurnPoints )
	
	local Ordered = { }
	
	for i, TurnPoint in ipairs(TurnPoints) do
		
		if TurnPoint ~= StartPoint and not table.find( Checkpoints, TurnPoint ) then
			
			Ordered[ #Ordered + 1 ] = TurnPoint
			
		end
		
		TurnPoints[i] = nil
		
	end
	
	for i, Checkpoint in ipairs(Checkpoints) do
		
		Ordered[ #Ordered + 1 ] = Checkpoint
		
		Checkpoints[ Checkpoint ] = true
		
		Checkpoints[ i ] = nil
		
	end
	
	table.sort( Ordered, function ( a, b ) return tonumber( a.Name ) < tonumber( b.Name ) end )
	
	local Total = 0
	
	for i, Checkpoint in ipairs(Ordered) do
		
		local Dist = ( GetWorldPos( Checkpoint ) - GetWorldPos( i == 1 and StartPoint or Ordered[ i - 1 ] ) ).magnitude
		
		Total = Total + Dist
		
		if Checkpoints[ Checkpoint ] then
			
			Checkpoints[ #Checkpoints + 1 ] = { Total, Checkpoint }
			
			Checkpoints[ Checkpoint ] = nil
			
		else
			
			TurnPoints[ #TurnPoints + 1 ] = { Total, Checkpoint }
			
		end
		
	end
	
	return Checkpoints, TurnPoints, Total
	
end

local CheckpointReached = Instance.new( "RemoteEvent" )

CheckpointReached.Name = "CheckpointReached"

CheckpointReached.Parent = RFolder

Module.UnidirectionalPointMetadata = setmetatable({
	
	Reset = function ( self )
		
		self.Active = nil
		
		self.Checkpoint = 0
		
		self.ExtraTimeGiven = nil
		
		self:SetCapturingSide(self.AwayOwned and Module.AwayTeams or Module.HomeTeams)
		
		self:SetCaptureTimer( 0, 0 )
		
		self:CheckpointReached( 0 )
		
		self.Event_Reset:Fire()
		
		return self
		
	end,
	
	Destroy = function(self)
		for _, v in pairs(self) do
			if typeof(v) == "Instance" and v:IsA("BindableEvent") then
				v:Destroy()
			elseif typeof(v) == "RBXScriptConnection" then
				v:Disconnect()
			end
		end
		
		self.Model.CapturePct:Destroy()
		
		for i, CapturePoint in ipairs(Module.CapturePoints) do
			if CapturePoint == self then
				Module.CapturePoints[i] = Module.CapturePoints[#Module.CapturePoints]
				Module.CapturePoints[#Module.CapturePoints] = nil
				break
			end
		end
	end,
	
	Require = function ( self, Required )
		
		self.Required = self.Required or { }
		
		self.Required[ #self.Required + 1 ] = Required
		
		return self
		
	end,
	
	RequireForWin = function ( self )
		
		Module.RequiredCapturePoints[ #Module.RequiredCapturePoints + 1 ] = self
		
		return self
		
	end,
	
	SetCapturingSide = function(self, Side)
		self.Event_CapturingSideChanged:Fire(next(Side))
		
		self.CapturingSide = Side
	end,
	
	SetCaptureTimer = function (self, Val, Speed)
		self.Event_CaptureChanged:Fire(Val, Speed)
		
		self.Model.CapturePct.Value = Val / self.CaptureTime
		self.CaptureTimer = Val
	end,
	
	CheckpointReached = function ( self, Checkpoint )
		
		if Checkpoint == 0 then
			
			for a = 1, #self.Checkpoints do
				
				local b = self.Checkpoints[ a ]
				
				if a == Checkpoint then
					
					local b = self.Checkpoints[ Checkpoint ]
					
					if typeof( b ) == "Instance" then
						
						local SpawnClones = self.SpawnClones and self.SpawnClones[ b ] or nil
						
						SpawnClones = Module.SetSpawns( SpawnClones, self.Model, self.AwayOwned and Module.AwayTeams or Module.HomeTeams )
						
						if SpawnClones then
							
							self.SpawnClones = self.SpawnClones or { }
							
							self.SpawnClones[ b ] = SpawnClones
							
						end
						
					end
					
				else
					
					if typeof( b ) == "Instance" then
						
						local SpawnClones = self.SpawnClones and self.SpawnClones[ b ] or nil
						
						SpawnClones = Module.SetSpawns( SpawnClones, self.Model, self.AwayOwned and Module.HomeTeams or Module.AwayTeams )
						
						if SpawnClones then
							
							self.SpawnClones = self.SpawnClones or { }
							
							self.SpawnClones[ b ] = SpawnClones
							
						end
						
					end
					
				end
				
			end
			
		else
			
			local b = self.Checkpoints[ Checkpoint ]
			
			if typeof( b ) == "Instance" then
				
				local SpawnClones = self.SpawnClones and self.SpawnClones[ b ] or nil
				
				SpawnClones = Module.SetSpawns( SpawnClones, self.Model, self.AwayOwned and Module.AwayTeams or Module.HomeTeams )
				
				if SpawnClones then
					
					self.SpawnClones = self.SpawnClones or { }
					
					self.SpawnClones[ b ] = SpawnClones
					
				end
				
			end
			
		end
		
		if Module.RaidStart then
			
			local ExtraTimeToGive
			
			if not self.Checkpoints[ Checkpoint + 1 ] and self.ExtraTimeForCapture then
				
				ExtraTimeToGive = self.ExtraTimeForCapture
				
			elseif self.ExtraTimeForCheckpoint then
				
				ExtraTimeToGive = self.ExtraTimeForCheckpoint
				
			end
			
			if ExtraTimeToGive then
				
				self.ExtraTimeGiven = self.ExtraTimeGiven or { }
				
				if not self.ExtraTimeGiven[ Checkpoint ] then
					
					self.ExtraTimeGiven[ Checkpoint ] = true
					
					Module.CurRaidLimit = math.max( tick( ) - Module.RaidStart + ExtraTimeToGive, Module.CurRaidLimit + ExtraTimeToGive )
					
					RaidTimerEvent:FireAllClients( Module.RaidStart, Module.CurRaidLimit )
					
				end
				
			end
			
		end
		
		if not self.Checkpoints[ Checkpoint + 1 ] then
			
			local Found, FoundSelf
			
			for a = 1, #Module.RequiredCapturePoints do
				
				if Module.RequiredCapturePoints[ a ] ~= self then
					
					if Module.RequiredCapturePoints[ a ].Required then
						
						for b = 1, #Module.RequiredCapturePoints[ a ].Required do
							
							if Module.RequiredCapturePoints[ a ].Required[ b ] == self then
								
								Found = true
								
								break
								
							end
							
						end
						
					end
					
				else
					
					FoundSelf = true
					
				end
				
			end
			
			if not FoundSelf or Found then
				
				self.Active = false
				
			end
			
			Captured:FireAllClients( self.Name, self.AwayOwned and next( Module.AwayTeams ) or next( Module.HomeTeams ) )
			
		else
			
			CheckpointReached:FireAllClients( self.Name, Checkpoint )
			
		end	
		
		self.Event_CheckpointReached:Fire( Checkpoint )
		
	end,
	
	AsPayload = function ( self, StartPoint, TurnPoints )
		
		local TurnPoint = 0
		
		for a = 1, #self.Checkpoints do
			
			TurnPoints[ #TurnPoints + 1 ] = self.Checkpoints[ a ]
			
		end
		
		table.sort( TurnPoints, function ( a, b )
			
			return a[ 1 ] < b[ 1 ]
			
		end )
		
		TurnPoints[ 0 ] = { 0, StartPoint }
		
		local StartCF = CFrame.new( GetWorldPos( StartPoint ), GetWorldPos( TurnPoints[ 1 ][ 2 ] ) )
		
		self.MainPart.CFrame = StartCF
		
		self.Event_CapturingSideChanged.Event:Connect(function(Side)
			Side = next(Module.AwayTeams) == Side and "AwayRotation" or "HomeRotation"
			for _, Obj in ipairs(self.Model:GetChildren()) do
				if CollectionService:HasTag( Obj, "PayloadRotate" ) then
					local Rotate = Obj:FindFirstChild(Side).Value
					TweenService:Create( Obj.Weld, TweenInfo.new( Obj.TweenTime.Value, Enum.EasingStyle.Linear ), { C1 = CFrame.new(Obj.Weld.C1.p) * CFrame.fromOrientation(math.rad(Rotate.X), math.rad(Rotate.Y), math.rad(Rotate.Z)) } ):Play( )
				end
			end
		end)
		
		self.Event_CaptureChanged.Event:Connect( function ( CaptureTimer, CaptureSpeed )
			
			if CaptureTimer == 0 and CaptureSpeed == 0 then
				
				TweenService:Create( self.MainPart, TweenInfo.new( 0 ), { CFrame = StartCF } ):Play( )
				
				TurnPoint = 0
				
				return
				
			end
			
			if self.MainPart:FindFirstChild( "PushSound" ) then
				
				if not self.MainPart.PushSound.Playing then
					
					self.MainPart.PushSound:Play( )
					
				end
				
				self.MainPart.PushSound.PlaybackSpeed = math.abs( math.max( CaptureSpeed / 2, 1.25 ) )
				
				delay( Module.GameTick + 0.1, function ( )
					
					if self.CaptureTimer == CaptureTimer then
						
						self.MainPart.PushSound:Stop( )
						
					end
					
				end )
				
			end
			
			local LastCF = self.MainPart.CFrame
			
			local TotalDist = 0
			
			local Targets = { }
			
			local MyCaptureTimer
			
			while MyCaptureTimer ~= CaptureTimer do
				
				MyCaptureTimer = CaptureTimer
				
				if MyCaptureTimer < TurnPoints[ TurnPoint ][ 1 ] then
					
					TurnPoint = TurnPoint - 1
					
					MyCaptureTimer = math.max( CaptureTimer, TurnPoints[ TurnPoint ][ 1 ] )
					
				elseif TurnPoints[ TurnPoint + 1 ] and MyCaptureTimer > TurnPoints[ TurnPoint + 1 ][ 1 ] then
					
					TurnPoint = TurnPoint + 1
					
					MyCaptureTimer = math.min( CaptureTimer, TurnPoints[ TurnPoint ][ 1 ] )
					
				end
				
				local Target
				
				if MyCaptureTimer == TurnPoints[ TurnPoint ][ 1 ] then
					
					if TurnPoint == 0 then
						
						Target = StartCF
						
					else
						
						local TurnPointPos, PrevTurnPointPos = GetWorldPos( TurnPoints[ TurnPoint ][ 2 ] ), GetWorldPos( TurnPoints[ TurnPoint - 1 ][ 2 ] )
						
						Target = CFrame.new( TurnPointPos, TurnPointPos + ( TurnPointPos - PrevTurnPointPos ) )
												
					end
					
				else
					
					local TurnPointPos, NextTurnPointPos = GetWorldPos( TurnPoints[ TurnPoint ][ 2 ] ), GetWorldPos( TurnPoints[ TurnPoint + 1 ][ 2 ] )
					
					Target = CFrame.new( TurnPointPos, NextTurnPointPos ) + ( NextTurnPointPos - TurnPointPos ) * ( MyCaptureTimer - TurnPoints[ TurnPoint ][ 1 ] ) / ( TurnPoints[ TurnPoint + 1 ][ 1 ] - TurnPoints[ TurnPoint ][ 1 ] )
					
				end
				
				local Dist = math.max( math.abs( ( LastCF.p - Target.p ).magnitude ), 1 )
				
				TotalDist = TotalDist + Dist
				
				LastCF = Target
				
				Targets[ #Targets + 1 ] = { Dist, Target }
				
			end
			
			for _, Kid in ipairs(self.Model:GetChildren()) do
				
				if CollectionService:HasTag( Kid, "PayloadWheel" ) then
					
					local Rotate = Kid.Rotate.Value * 22.25 * CaptureSpeed
					
					TweenService:Create( Kid.Weld, TweenInfo.new( Module.GameTick, Enum.EasingStyle.Linear ), { C1 = Kid.Weld.C1 * CFrame.fromOrientation( math.rad( Rotate.X ), math.rad( Rotate.Y ), math.rad( Rotate.Z ) ) } ):Play( )
					
				end
				
			end
			
			for i, Target in ipairs(Targets) do
				
				local Tween = TweenService:Create( self.MainPart, TweenInfo.new( Target[ 1 ] / TotalDist * Module.GameTick, Enum.EasingStyle.Linear ), { CFrame = Target[ 2 ] } )
				
				Tween:Play( )
				
				if i ~= #Targets then
					
					local State = Tween.Completed:Wait( )
					
					while State ~= Enum.PlaybackState.Completed do
						
						if State == Enum.PlaybackState.Cancelled then return end
						
						State = Tween.Completed:Wait( )
						
					end
					
				end
				
			end
			
		end )
		
		return self
		
	end,
	
	RequireCheck = function(self)
		return self.CaptureTimer ~= self.CaptureTime
	end,
	-- True = Point should have it's tick ran (If this function is nil it just uses self.Active)
	ShouldTick = function(self)
		return self.Active and self.CaptureTimer ~= self.CaptureTime
	end,
	TickWithNear = true,
	Tick = function(self, CaptureSpeed, Home, Away)
		if Home > Away then
			if self.CapturingSide ~= Module.HomeTeams then
				self:SetCapturingSide(Module.HomeTeams)
			end
		elseif Away > Home then
			if self.CapturingSide ~= Module.AwayTeams then
				self:SetCapturingSide(Module.AwayTeams)
			end
		end
		
		if CaptureSpeed ~= 0 then
			
			if self.CapturingSide ~= ( self.AwayOwned and Module.AwayTeams or Module.HomeTeams ) then
				
				local NextCheckpoint = self.Checkpoint + 1
				
				if self.Checkpoints[ NextCheckpoint ] and not self.Checkpoints[ NextCheckpoint ][ 3 ] and ( self.LowerLimitTimer == nil or self.CaptureTimer ~= self.LowerLimitTimer ) then
					
					local NewCaptureTimer = self.CaptureTimer + CaptureSpeed
					
					if self.TimerLimits then
						
						for b = 1, #self.TimerLimits do
							
							if self.TimerLimits[ b ][ 1 ] and NewCaptureTimer > self.TimerLimits[ b ][ 1 ] and ( self.TimerLimits[ b ][ 2 ] == nil or self.CaptureTimer < self.TimerLimits[ b ][ 2 ] ) then
								
								if self.CaptureTimer <= self.TimerLimits[ b ][ 1 ] then
									
									local Enabled = self.TimerLimits[ b ][ 3 ]
									
									if type( Enabled ) == "function" then
										
										Enabled = Enabled( )
										
									end
									
									if Enabled then
										
										NewCaptureTimer = self.TimerLimits[ b ][ 1 ]
										
									elseif not self.TimerLimits[ b ][ 5 ] and self.TimerLimits[ b ][ 4 ] then
										
										self.TimerLimits[ b ][ 5 ] = true
										
										self.TimerLimits[ b ][ 4 ]( true )
										
									end
									
								end
								
							elseif self.TimerLimits[ b ][ 5 ] and self.TimerLimits[ b ][ 4 ] then
								
								self.TimerLimits[ b ][ 5 ] = nil
								
								self.TimerLimits[ b ][ 4 ]( )
								
							end
							
						end
						
					end
					
					if NewCaptureTimer ~= self.CaptureTimer then
						
						NewCaptureTimer = math.min( NewCaptureTimer, self.CaptureTime )
						
						local OriginalCaptureTimer = NewCaptureTimer
						
						while self.Checkpoints[ NextCheckpoint ] and OriginalCaptureTimer >= self.Checkpoints[ NextCheckpoint ][ 1 ] do
							
							if self.Checkpoints[ NextCheckpoint ][ 3 ] then
								
								NewCaptureTimer = math.max( OriginalCaptureTimer, ( self.Checkpoints[ self.Checkpoint ] or { 0 } )[ 1 ] )
								
								break
								
							end
							
							self:CheckpointReached( NextCheckpoint )
							
							self.Checkpoint = NextCheckpoint
							
							NextCheckpoint = NextCheckpoint + 1
							
						end
						
						self:SetCaptureTimer( NewCaptureTimer, CaptureSpeed )
						
						self.WasMoving = true
						
					elseif self.WasMoving then
						
						self.WasMoving = nil
						
						self:SetCaptureTimer( self.CaptureTimer, 0 )
						
					end
					
				end
				
			elseif self.CaptureTimer ~= ( self.Checkpoints[ self.Checkpoint ] or { 0 } )[ 1 ] then
				
				local NewCaptureTimer = self.CaptureTimer - CaptureSpeed
				
				if self.TimerLimits then
					
					for a = 1, #self.TimerLimits do
						
						if self.TimerLimits[ a ][ 2 ] and NewCaptureTimer < self.TimerLimits[ a ][ 2 ] and ( self.TimerLimits[ a ][ 1 ] == nil or self.CaptureTimer > self.TimerLimits[ a ][ 1 ] ) then
							
							if self.CaptureTimer >= self.TimerLimits[ a ][ 2 ] then
								
								local Enabled = self.TimerLimits[ a ][ 3 ]
								
								if type( Enabled ) == "function" then
									
									Enabled = Enabled( )
									
								end
								
								if Enabled then
									
									NewCaptureTimer = self.TimerLimits[ a ][ 2 ]
									
								elseif not self.TimerLimits[ a ][ 5 ] and self.TimerLimits[ a ][ 4 ] then
									
									self.TimerLimits[ a ][ 5 ] = true
									
									self.TimerLimits[ a ][ 4 ]( true )
									
								end
								
							end
							
						elseif self.TimerLimits[ a ][ 5 ] and self.TimerLimits[ a ][ 4 ] then
							
							self.TimerLimits[ a ][ 5 ] = nil
							
							self.TimerLimits[ a ][ 4 ]( )
							
						end
						
					end
					
				end
				
				if NewCaptureTimer ~= self.CaptureTimer then
					
					self:SetCaptureTimer( math.max( NewCaptureTimer, ( self.Checkpoints[ self.Checkpoint ] or { 0 } )[ 1 ] ) , -CaptureSpeed )
					
					self.WasMoving = true
					
				elseif self.WasMoving then
					
					self.WasMoving = nil
					
					self:SetCaptureTimer( self.CaptureTimer, 0 )
					
				end
				
			end
			
		elseif self.WasMoving then
			
			self.WasMoving = nil
			
			self:SetCaptureTimer( self.CaptureTimer, 0 )
			
		end
	end,
	TimeBased = function(self)
		if not self.AwayOwned then
			if self.CaptureTimer ~= self.CaptureTime then
				if self.CapturingSide == Module.AwayTeams then
					return false, false, false
				elseif self.CaptureTimer ~= ( self.Checkpoints[ self.Checkpoint ] or { 0 } )[ 1 ] then
					return false, nil, false
				else
					return nil, nil, false
				end
			else
				return false, false, nil
			end
		elseif self.CaptureTimer == self.CaptureTime then
			return "Won"
		end
	end,
	PointBased = function(self)
		if self.CaptureTimer == self.CaptureTime then
			if self.AwayOwned then
				return nil, self.AwayPointsPerSecond
			else
				return self.HomePointsPerSecond, nil
			end
		end
	end,
}, {__index = Module})

-- Table requires Dist = Number, CaptureTime = Number, MainPart = Instance, Model = Instance
function Module.UnidirectionalPoint( CapturePoint )
	CapturePoint.Name = CapturePoint.Name or CapturePoint.Model.Name
	
	setmetatable( CapturePoint, { __index = Module.UnidirectionalPointMetadata } )
	
	CapturePoint.Event_CheckpointReached = Instance.new("BindableEvent")
	CapturePoint.Event_CaptureChanged = Instance.new("BindableEvent")
	CapturePoint.Event_CapturingSideChanged = Instance.new("BindableEvent")
	CapturePoint.Event_Reset = Instance.new("BindableEvent")
	
	CapturePoint.Checkpoints = CapturePoint.Checkpoints or { { CapturePoint.CaptureTime, CapturePoint.Model } }
	
	if CapturePoint.Checkpoints[ #CapturePoint.Checkpoints ][ 1 ] ~= CapturePoint.CaptureTime then
		
		CapturePoint.Checkpoints[ #CapturePoint.Checkpoints + 1 ] = { CapturePoint.CaptureTime }
		
	end
	
	local Pct = Instance.new( "NumberValue" )
	
	Pct.Name = "CapturePct"
	
	for a = 1, #CapturePoint.Checkpoints do
		
		local Pct2 = Instance.new( "NumberValue", Pct )
		
		Pct2.Name = "Checkpoint" .. a
		
		Pct2.Value = CapturePoint.Checkpoints[ a ][ 1 ] / CapturePoint.CaptureTime
		
	end
	
	Pct.Parent = CapturePoint.Model
	
	if Module.GameMode then
		CapturePoint:Reset()
	end
	
	Module.CapturePoints[ #Module.CapturePoints + 1 ] = CapturePoint
	
	Module.Event_CapturePointAdded:Fire( #Module.CapturePoints )
	
	return CapturePoint
	
end

local function WeldAttachments(Part1, Model)
	local P1Attachment = Part1:FindFirstChildOfClass("Attachment")
	local P2Attachment = Model:FindFirstChild(P1Attachment.Name, true)
	
	local Weld = Instance.new("Weld")
	Weld.Part0 = P2Attachment.Parent
	Weld.Part1 = Part1
	Weld.C0 = P2Attachment.CFrame
	Weld.C1 = P1Attachment.CFrame
	Weld.Parent = Part1
end

Module.CarryablePointMeta = setmetatable({
	Reset = function(self)
		self.Active = nil
		self.BeenCaptured = nil
		self.LastSafe = self.StartPos
		self.ExtraTimeGiven = nil
		self:SetCarrier(nil)
		self:Captured(self.AwayOwned and Module.AwayTeams or Module.HomeTeams)
		self:DoDisplay()
		self.Event_Reset:Fire()
		return self
	end,
	Destroy = function(self)
		for _, v in pairs(self) do
			if typeof(v) == "Instance" and v:IsA("BindableEvent") then
				v:Destroy()
			elseif typeof(v) == "RBXScriptConnection" then
				v:Disconnect()
			end
		end
		
		self.Pct:Destroy()
		self.Clone:Destroy()
		
		for i, CapturePoint in ipairs(Module.CapturePoints) do
			if CapturePoint == self then
				Module.CapturePoints[i] = Module.CapturePoints[#Module.CapturePoints]
				Module.CapturePoints[#Module.CapturePoints] = nil
				break
			end
		end
	end,
	Require = function(self, Required)
		self.Required = self.Required or {}
		self.Required[#self.Required + 1] = Required
		return self
	end,
	RequireForWin = function(self)
		Module.RequiredCapturePoints[#Module.RequiredCapturePoints + 1] = self
		return self
	end,
	Captured = function(self, Side)
		local HomeSide, AwaySide
		if self.AwayOwned then
			HomeSide, AwaySide = Module.AwayTeams, Module.HomeTeams
		else
			HomeSide, AwaySide = Module.HomeTeams, Module.AwayTeams
		end
		
		if Side == Module.AwaySide then
			self.BeenCaptured = true
			if Module.RaidStart and not self.ExtraTimeGiven and self.ExtraTimeForCapture then
				self.ExtraTimeGiven = true
				Module.CurRaidLimit = math.max( tick( ) - Module.RaidStart + self.ExtraTimeForCapture, Module.CurRaidLimit + self.ExtraTimeForCapture )
				RaidTimerEvent:FireAllClients( Module.RaidStart, Module.CurRaidLimit )
			end
			if self.ResetOnCapture then
				self.LastSafe = self.StartPos
				self:SetCarrier(nil)
			else
				self.LastSafe = self.TargetPos
				self:SetCarrier(nil)
			end
			
			if Module.GameMode.WinPoints then
				if Side == Module.AwayTeam then
					Module.AwayWinAmount.Value = math.clamp( Module.AwayWinAmount.Value + (self.AwayCapturePoints or 0), 0, Module.GameMode.WinPoints )
				else
					Module.HomeWinAmount.Value = math.clamp( Module.HomeWinAmount.Value + (self.HomeCapturePoints or 0), 0, Module.GameMode.WinPoints )
				end
			end
		else
			if Module.GameMode.WinPoints then
				if Side == Module.AwayTeam then
					Module.AwayWinAmount.Value = math.clamp( Module.AwayWinAmount.Value + (self.AwayReturnPoints or 0), 0, Module.GameMode.WinPoints )
				else
					Module.HomeWinAmount.Value = math.clamp( Module.HomeWinAmount.Value + (self.HomeReturnPoints or 0), 0, Module.GameMode.WinPoints )
				end
			end
		end
		
		if not self.ResetOnHomePickup then
			self.SpawnClones = Module.SetSpawns(self.SpawnClones, self.Model, Side)
		end
		
		if Module.RaidStart and Side == Module.AwaySide and self.ExtraTimeForCapture then
			Module.CurRaidLimit = math.max( tick( ) - Module.RaidStart + self.ExtraTimeForCapture, Module.CurRaidLimit + self.ExtraTimeForCapture )
			RaidTimerEvent:FireAllClients( Module.RaidStart, Module.CurRaidLimit )
		end
		
		self.Event_Captured:Fire(next(Side))
		Captured:FireAllClients(self.Name, next(Side))
	end,
	SetCarrier = function(self, Carrier)
		if Carrier then
			if self.DropGui then
				self.Gui = self.DropGui:Clone()
				self.Gui.Parent = Carrier.PlayerGui
				self.Gui.TextButton.MouseButton1Click:Connect(function()
					self:DoDisplay()
				end)
			end
			
			self.DiedEvent = Carrier.Character.Humanoid.Died:Connect(function()
				self:DoDisplay()
			end)
			
			if self.PreventTools then
				Carrier.Character.Humanoid:UnequipTools()
				
				self.ToolEvent = Carrier.Character.ChildAdded:Connect(function(Obj)
					if Obj:IsA("Tool") then
						wait()
						Carrier.Character.Humanoid:UnequipTools()
					end
				end)
			end
		else
			self:DoDisplay()
		end
		
		self.Event_CarrierChanged:Fire(Carrier)
		self.Carrier = Carrier
	end,
	DoDisplay = function(self)
		local Pos = self.LastSafe
		if self.Model.Handle:FindFirstChild("Weld") then
			self.Model.Handle.Weld:Destroy()
		end
		self.Model.Parent = workspace
		self.Model.Handle.CanCollide = false
		self.Model.Handle.Anchored = true
		local Orientation = self.Model.Handle:FindFirstChildOfClass("Attachment").CFrame:inverse()
		self.Model.Handle.CFrame = CFrame.new(Pos) * Orientation
		self.Pct.Value = self.LastSafe == self.StartPos and 0 or self.LastSafe == self.TargetPos and 1 or math.min(1 - ((self.Model.Handle.Position - self.Target.Position).magnitude - self.TargetDist) / self.TotalDist, 1)
		
		if self.RotateEvent then
			self.RotateEvent:Disconnect()
		end
		
		local MyRotateEvent = game["Run Service"].Heartbeat:Connect(function(Step)
			self.Model.Handle.CFrame = CFrame.new(Pos + Vector3.new(0, math.sin(tick() / 2) + 0.5, 0)) * CFrame.fromOrientation(0, math.rad((tick()%10/10) * 360), 0) * Orientation
		end)
		self.RotateEvent = MyRotateEvent
		
		wait(1)
		if MyRotateEvent == self.RotateEvent then
			self.PickupEvent = self.Model.Handle.Touched:Connect(function(Part)
				if self.PickupEvent and Module.RaidStart then
					local Plr = game.Players:GetPlayerFromCharacter(Part.Parent)
					if Plr and Part.Parent:FindFirstChild("Humanoid") and Part.Parent.Humanoid.Health > 0 then
						if ((self.AwayOwned and Module.HomeTeams or Module.AwayTeams)[Plr.Team] and self.LastSafe ~= self.TargetPos) or ((self.AwayOwned and Module.AwayTeams or Module.HomeTeams)[Plr.Team] and self.LastSafe ~= self.StartPos) then
							WeldAttachments(self.Model.Handle, Part.Parent)
							self.Model.Parent = Part.Parent
						end
					end
				end
			end)
			
			if self.ResetAfter and self.LastSafe ~= self.StartPos then
				if self.ResetAfter then
					wait(self.ResetAfter - 1)
				end
				
				if MyRotateEvent == self.RotateEvent then
					self.LastSafe = self.StartPos
					self.RotateEvent, self.PickupEvent = self.RotateEvent:Disconnect(), self.PickupEvent:Disconnect()
					self:DoDisplay()
				end
			end
		end
	end,
	RequireCheck = function(self)
		return not self.BeenCaptured
	end,
	Tick = function(self)
		if self.Carrier then
			self.Pct.Value = math.min(1 - ((self.Model.Handle.Position - self.Target.Position).magnitude - self.TargetDist) / self.TotalDist, 1)
			
			local HomeSide, AwaySide
			if self.AwayOwned then
				HomeSide, AwaySide = Module.AwayTeams, Module.HomeTeams
			else
				HomeSide, AwaySide = Module.HomeTeams, Module.AwayTeams
			end
			
			if HomeSide[self.Carrier.Team] and (self.Model.Handle.Position - self.Start.Position).magnitude <= self.StartDist then
				self.LastSafe = self.StartPos
				self:Captured(HomeSide)
				self:SetCarrier(nil)
			elseif AwaySide[self.Carrier.Team] and (self.Model.Handle.Position - self.Target.Position).magnitude <= self.TargetDist then
				self:Captured(AwaySide)
			elseif (not self.ResetAfter or self.ResetAfter > 1) and self.Carrier.Character and self.Carrier.Character:FindFirstChild("Humanoid") and self.Carrier.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				self.LastSafe = self.Model.Handle.Position
			end
		end
	end,
	TimeBased = function(self)
		if self.LastSafe ~= self.TargetPos then
			if self.LastSafe ~= self.StartPos then
				return false, nil, false
			else
				return nil, nil, false
			end
		else
			return nil, false, nil
		end
	end,
}, {__index = Module})

-- Table requires Model = Model, Target = Part, TargetDist = Number, Start = Part, StartDist = Number
function Module.CarryablePoint(CapturePoint)
	CapturePoint.Clone = CapturePoint.Model:Clone()
	CapturePoint.StartPos = CapturePoint.Start.Position + Vector3.new(0, 2, 0)
	CapturePoint.TargetPos = CapturePoint.Target.Position + Vector3.new(0, 2, 0)
	CapturePoint.TotalDist = (CapturePoint.Start.Position - CapturePoint.Target.Position).magnitude
	CapturePoint.Name = CapturePoint.Name or CapturePoint.Model.Name
	CapturePoint.Event_CarrierChanged = Instance.new("BindableEvent")
	CapturePoint.Event_Captured = Instance.new("BindableEvent")
	CapturePoint.Event_Reset = Instance.new("BindableEvent")
	
	CapturePoint.Pct = Instance.new("NumberValue")
	CapturePoint.Pct.Name = "CapturePct"
	CapturePoint.Pct.Parent = CapturePoint.Model
	
	setmetatable(CapturePoint, {__index = Module.CarryablePointMeta})
	
	CapturePoint.Model.AncestryChanged:Connect(function()
		if CapturePoint.DiedEvent then
			CapturePoint.DiedEvent, CapturePoint.Gui = CapturePoint.DiedEvent:Disconnect(), CapturePoint.Gui:Destroy()
			
			if CapturePoint.PreventTools then
				CapturePoint.ToolEvent = CapturePoint.ToolEvent:Disconnect()
			end
		end
		
		if not CapturePoint.Model:IsDescendantOf(workspace) then
			CapturePoint:SetCarrier(nil)
		elseif not CapturePoint.Model:FindFirstChild("Handle") then
			wait()
			CapturePoint.Clone:Clone():WaitForChild("Handle").Parent = CapturePoint.Model
			CapturePoint.Model.Handle.CFrame = CFrame.new(CapturePoint.StartPos)
			CapturePoint:SetCarrier(nil)
		elseif CapturePoint.Model.Parent ~= workspace then
			local Humanoid = CapturePoint.Model.Parent:FindFirstChildOfClass("Humanoid")
			if Humanoid then
				CapturePoint.RotateEvent = CapturePoint.RotateEvent:Disconnect()
				if CapturePoint.PickupEvent then
					CapturePoint.PickupEvent = CapturePoint.PickupEvent:Disconnect()
				end
				
				CapturePoint.Model.Handle.Anchored = false
				
				local Plr = Players:GetPlayerFromCharacter(Humanoid.Parent)
				if Plr and (Module.AwayTeams[Plr.Team] or Module.HomeTeams[Plr.Team]) then
					local Active
					if CapturePoint.ShouldTick then
						Active = CapturePoint:ShouldTick()
					else
						Active = CapturePoint.Active
					end
					
					if Module.RaidStart and Active and Module.CheckRequired(CapturePoint) then
						local HomeSide, AwaySide
						if CapturePoint.AwayOwned then
							HomeSide, AwaySide = Module.AwayTeams, Module.HomeTeams
						else
							HomeSide, AwaySide = Module.HomeTeams, Module.AwayTeams
						end
						
						if (HomeSide[Plr.Team] and (CapturePoint.ResetOnHomePickup or CapturePoint.LastSafe == CapturePoint.StartPos)) or (AwaySide[Plr.Team] and CapturePoint.LastSafe == CapturePoint.TargetPos) then
							wait()
							if CapturePoint.ResetOnHomePickup then
								CapturePoint:Captured(HomeSide)
							end
							CapturePoint.LastSafe = CapturePoint.StartPos
							CapturePoint:SetCarrier(nil)
						else
							CapturePoint:SetCarrier(Plr)
						end
					else
						wait()
						CapturePoint:SetCarrier(nil)
					end
				else
					wait()
					CapturePoint:SetCarrier(nil)
				end
			end
		end
	end)
	
	if Module.GameMode then
		CapturePoint:Reset()
	end
	
	Module.CapturePoints[#Module.CapturePoints + 1] = CapturePoint
	Module.Event_CapturePointAdded:Fire(#Module.CapturePoints)
	
	return CapturePoint
end

Module.DiscordCharacterLimit = 2000

Module.Event_OfficialCheck.Event:Connect( function ( Home, Away )
	
	if not Module.RallyMessage and Home < Module.HomeRequired and Away >= Module.AwayRequired * ( Module.RallyMessagePct or 0.5 ) then
		
		Module.RallyMessage = true
		
		if not Module.Practice and game.PrivateServerId == "" and Module.DiscordMessages and ( Module.AllowDiscordInStudio or not RunService:IsStudio( ) ) then

			local AwayGroup = Module.GetAwayGroup( )
			
			if AwayGroup.Id ~= Module.HomeGroup.Id then
				
				AwayGroup = AwayGroup.Id and ( "[" .. AwayGroup.Name .. "](<https://www.roblox.com/groups/" .. AwayGroup.Id .. "/a#!/about>)" ) or Module.AwayGroup.Name
				
				local HomeGroup = Module.HomeGroup and ( "[" .. Module.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. Module.HomeGroup.Id .. "/a#!/about>)" )
				
				local PlaceAcronym ="[" .. Module.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
				
				local PlaceName = "[" .. Module.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
				
				local Home, Away = { }, { }
				
				for _, Plr in ipairs(Players:GetPlayers()) do
					
					if Module.HomeTeams[ Plr.Team ] then
						
						Home[ #Home + 1 ] = "[" .. Plr.Name .. "](<https://www.roblox.com/users/" .. Plr.UserId .. "/profile>) - " .. HandleRbxAsync( "Guest", Plr.GetRoleInGroup, Plr, Module.HomeGroup.Id )
						
					elseif Module.AwayTeams[ Plr.Team ] then
						
						Away[ #Away + 1 ] = "[" .. Plr.Name .. "](<https://www.roblox.com/users/" .. Plr.UserId .. "/profile>)" .. ( AwayGroup.Id and ( " - " .. HandleRbxAsync( "Guest", Plr.GetRoleInGroup, Plr, AwayGroup.Id ) ) or "" )
						
					end
					
				end
				
				if #Home == 0 then Home[ 1 ] = "None" end
				
				if #Away == 0 then Away[ 1 ] = "None" end
				
				for a = 1, #Module.DiscordMessages do
					
					if Module.DiscordMessages[ a ].Rallying then
						
						local Msg = Module.DiscordMessages[ a ].Rallying:gsub( "%%%w*%%", { [ "%PlaceAcronym%" ] = PlaceAcronym, [ "%PlaceName%" ] = PlaceName, [ "%RaidID%" ] = Module.RaidID.Value, [ "%AwayGroup%" ] = AwayGroup, [ "%AwayList%" ] = table.concat( Away, ", " ), [ "%AwayListNewline%" ] = table.concat( Away, "\n" ), [ "%HomeGroup%" ] = HomeGroup, [ "%HomeList%" ] = table.concat( Home, ", " ), [ "%HomeListNewline%" ] = table.concat( Home, "\n" ) } )
						
						while true do
							
							local LastNewLine = #Msg <= Module.DiscordCharacterLimit and Module.DiscordCharacterLimit or Msg:sub( 1, Module.DiscordCharacterLimit ):match( "^.*()[\n]" )
							
							local Ran, Error = pcall( HttpService.PostAsync, HttpService, Module.DiscordMessages[ a ].Url, HttpService:JSONEncode{ avatar_url = Module.HomeGroup.EmblemUrl, username = Module.PlaceAcronym .. " Raid Bot", content = Msg:sub( 1, LastNewLine and LastNewLine - 1 or Module.DiscordCharacterLimit ) } )
							
							if not Ran then warn( Error ) end
							
							if #Msg <= ( LastNewLine or Module.DiscordCharacterLimit ) then break end
							
							Msg = Msg:sub( ( LastNewLine or Module.DiscordCharacterLimit ) + 1 )
							
						end
						
					end
					
				end
				
			end
			
		end
		
	end
	
end )

Module.OfficialRaid:GetPropertyChangedSignal( "Value" ):Connect( function ( )
	
	if not Module.OfficialRaid.Value then return end
	
	if not Module.Practice and Module.DiscordMessages and ( Module.AllowDiscordInStudio or not RunService:IsStudio( ) ) then
		
		local AwayGroup = Module.AwayGroup.Id and ( "[" .. Module.AwayGroup.Name .. "](<https://www.roblox.com/groups/" .. Module.AwayGroup.Id .. "/a#!/about>)" ) or Module.AwayGroup.Name
		
		local HomeGroup = Module.HomeGroup and ( "[" .. Module.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. Module.HomeGroup.Id .. "/a#!/about>)" )
		
		local PlaceAcronym ="[" .. Module.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local PlaceName = "[" .. Module.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local Home, Away = { }, { }
		
		for _, Plr in ipairs(Players:GetPlayers()) do
			
			if Module.HomeTeams[ Plr.Team ] then
				
				Home[ #Home + 1 ] = "[" .. Plr.Name .. "](<https://www.roblox.com/users/" .. Plr.UserId .. "/profile>) - " .. HandleRbxAsync( "Guest", Plr.GetRoleInGroup, Plr, Module.HomeGroup.Id )
				
			elseif Module.AwayTeams[ Plr.Team ] then
				
				Away[ #Away + 1 ] = "[" .. Plr.Name .. "](<https://www.roblox.com/users/" .. Plr.UserId .. "/profile>)" .. ( Module.AwayGroup.Id and ( " - " .. HandleRbxAsync( "Guest", Plr.GetRoleInGroup, Plr, Module.AwayGroup.Id ) ) or "" )
				
			end
			
		end
		
		if #Home == 0 then Home[ 1 ] = "None" end
		
		if #Away == 0 then Away[ 1 ] = "None" end
		
		for a = 1, #Module.DiscordMessages do
			
			if Module.DiscordMessages[ a ].Start then
				
				local Msg = Module.DiscordMessages[ a ].Start:gsub( "%%%w*%%", { [ "%PlaceAcronym%" ] = PlaceAcronym, [ "%PlaceName%" ] = PlaceName, [ "%RaidID%" ] = Module.RaidID.Value, [ "%AwayGroup%" ] = AwayGroup, [ "%AwayList%" ] = table.concat( Away, ", " ), [ "%AwayListNewline%" ] = table.concat( Away, "\n" ), [ "%HomeGroup%" ] = HomeGroup, [ "%HomeList%" ] = table.concat( Home, ", " ), [ "%HomeListNewline%" ] = table.concat( Home, "\n" ) } )
				
				while true do
					
					local LastNewLine = #Msg <= Module.DiscordCharacterLimit and Module.DiscordCharacterLimit or Msg:sub( 1, Module.DiscordCharacterLimit ):match( "^.*()[\n]" )
					
					local Ran, Error = pcall( HttpService.PostAsync, HttpService, Module.DiscordMessages[ a ].Url, HttpService:JSONEncode{ avatar_url = Module.HomeGroup.EmblemUrl, username = Module.PlaceAcronym .. " Raid Bot", content = Msg:sub( 1, LastNewLine and LastNewLine - 1 or Module.DiscordCharacterLimit ) } )
					
					if not Ran then warn( Error ) end
					
					if #Msg <= ( LastNewLine or Module.DiscordCharacterLimit ) then break end
					
					Msg = Msg:sub( ( LastNewLine or Module.DiscordCharacterLimit ) + 1 )
					
				end
				
			end
			
		end
		
	end
	
end )

Module.Event_RaidEnded.Event:Connect( function ( RaidID, AwayGroupTable, Result, TeamLog, RaidStart ) 
	
	if not Module.Practice and Module.DiscordMessages and ( Module.AllowDiscordInStudio or not RunService:IsStudio( ) ) then
		
		local EndTime = tick( )
		
		local AwayGroup = AwayGroupTable.Id and ( "[" .. AwayGroupTable.Name .. "](<https://www.roblox.com/groups/" .. AwayGroupTable.Id .. "/a#!/about>)" ) or AwayGroupTable.Name
		
		local HomeGroup = Module.HomeGroup and ( "[" .. Module.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. Module.HomeGroup.Id .. "/a#!/about>)" )
		
		local PlaceAcronym ="[" .. Module.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local PlaceName = "[" .. Module.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local Home, Away = { }, { }
		
		for UserId, Logs in pairs( TeamLog ) do
			
			local Teams = { }
			
			local Max
			
			if #Logs == 1 and Logs[ 1 ][ 1 ] == RaidStart then
				
				Teams[ Logs[ 1 ][ 2 ] ] = true
				
				Max = Logs[ 1 ][ 2 ]
				
			else
			
				for Key, Log in ipairs( Logs ) do
					
					if Log[ 2 ] then
						
						Teams[ Log[ 2 ] ] = Teams[ Log[ 2 ] ] or 0
						
						local Next = Logs[ Key + 1 ]
						
						Teams[ Log[ 2 ] ] = Teams[ Log[ 2 ] ] + ( Next and Next[ 1 ] or EndTime ) - Log[ 1 ]
						
						if not Max or Teams[ Max ] < Teams[ Log[ 2 ] ] then
							
							Max = Log[ 2 ]
							
						end
						
					end
					
				end
				
			end
			
			if Max then
				
				if Module.HomeTeams[ Max ] then
					
					local Role
					
					for _, Group in ipairs(GroupService:GetGroupsAsync(UserId)) do
						
						if Group.Id == Module.HomeGroup.Id then
							
							Role = Group.Role
							
							break
							
						end
						
					end
					
					local Time = " - helped for " .. ( Teams[ Max ] == true and "the entire raid" or FormatTime( Teams[ Max ] ) )
					
					Home[ #Home + 1 ] = "[" .. Players:GetNameFromUserIdAsync( UserId ) .. "](<https://www.roblox.com/users/" .. UserId .. "/profile>) - " .. ( Role or "Guest" ) .. Time
					
				elseif Module.AwayTeams[ Max ] then
					
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
					
					local Time = " - helped for " .. ( Teams[ Max ] == true and "the entire raid" or FormatTime( Teams[ Max ] ) )
					
					Away[ #Away + 1 ] = "[" .. Players:GetNameFromUserIdAsync( UserId ) .. "](<https://www.roblox.com/users/" .. UserId .. "/profile>) " .. ( Role and ( " - " .. ( Role or "Guest" ) ) or "" ) .. Time
					
				end
				
			end
			
		end
		
		if #Home == 0 then Home[ 1 ] = "None" end
		
		if #Away == 0 then Away[ 1 ] = "None" end
		
		local EmblemUrl = Result == "Lost" and AwayGroupTable.EmblemUrl or Module.HomeGroup.EmblemUrl
		
		for a = 1, #Module.DiscordMessages do
			
			if Module.DiscordMessages[ a ][ Result ] then
				
				local Msg = Module.DiscordMessages[ a ][ Result ]:gsub( "%%%w*%%", { [ "%PlaceAcronym%" ] = PlaceAcronym, [ "%PlaceName%" ] = PlaceName, [ "%RaidID%" ] = RaidID, [ "%RaidTime%" ] = FormatTime( EndTime - RaidStart ), [ "%AwayGroup%" ] = AwayGroup, [ "%AwayList%" ] = table.concat( Away, ", " ), [ "%AwayListNewline%" ] = table.concat( Away, "\n" ), [ "%HomeGroup%" ] = HomeGroup, [ "%HomeList%" ] = table.concat( Home, ", " ), [ "%HomeListNewline%" ] = table.concat( Home, "\n" ) } )
				
				while true do
					
					local LastNewLine = #Msg <= Module.DiscordCharacterLimit and Module.DiscordCharacterLimit or Msg:sub( 1, Module.DiscordCharacterLimit ):match( "^.*()[\n]" )
					
					local Ran, Error = pcall( HttpService.PostAsync, HttpService, Module.DiscordMessages[ a ].Url, HttpService:JSONEncode{ avatar_url = EmblemUrl, username = Module.PlaceAcronym .. " Raid Bot", content =  Msg:sub( 1, LastNewLine and LastNewLine - 1 or Module.DiscordCharacterLimit ) } )
					
					if not Ran then warn( Error ) end
					
					if #Msg <= ( LastNewLine or Module.DiscordCharacterLimit ) then break end
					
					Msg = Msg:sub( ( LastNewLine or Module.DiscordCharacterLimit ) + 1 )
					
				end
				
			end
			
		end
		
	end
	
end )

---------- VH

local VH_Func = function ( Main )
	
	VHMain = Main
	
	if Main.Config.ReservedFor then
		
		MaxPlayers = Players.MaxPlayers - ( Main.Config.ReservedSlots or 1 )
		
	end
	
	Main.Commands[ "ForceOfficial" ] = {
		
		Alias = { Main.TargetLib.AliasTypes.Toggle( 1, 6, "forceofficial", "forceraid" ) },
		
		Description = "Forces the raid official/unofficial",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = { { Func = Main.TargetLib.ArgTypes.Boolean, Default = Main.TargetLib.Defaults.Toggle, ToggleValue = function ( ) return Module.OfficialRaid.Value end } },
		
		Callback = function ( self, Plr, Cmd, Args, NextCmds, Silent )
			
			if Module.OfficialRaid.Value == Args[ 1 ] then return false, "Already " .. ( Args[ 1 ] and "official" or "unofficial" ) end
			
			if Args[ 1 ] then
				
				Module.Forced = true
				
				Module.StartRaid( )
				
			else
				
				Module.EndRaid( "Forced" )
				
			end
			
			return true
			
		end
		
	}
	
	Main.Commands[ "Official" ] = {
		
		Alias = { "official", "raid" },
		
		Description = "Makes the raid official",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = { },
		
		Callback = function ( self, Plr, Cmd, Args, NextCmds, Silent )
			
			if not Module.ManualStart then return false, "Raid will automatically start\nUse 'forceofficial/true' to force start the raid" end
			
			if Module.OfficialRaid.Value == true then return false, "Already official" end
			
			local Ran = Module.OfficialCheck( true )
			
			if Ran then
				
				return false, Ran
				
			end
			
			return true
			
		end
		
	}
	
	Main.Commands[ "PracticeOfficial" ] = {
		
		Alias = { "practiceofficial", "practiceraid", "pr" },
		
		Description = "Makes the raid official",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = { },
		
		Callback = function ( self, Plr, Cmd, Args, NextCmds, Silent )
			
			if Module.OfficialRaid.Value == true then return false, "Already official" end
			
			if not Module.GameMode then return false, "RaidLib hasn't loaded yet" end
			
			Module.Forced = true
			
			Module.Practice = true
			
			Module.StartRaid( )
			
			return true
			
		end
		
	}
	
end

if _G.VH_AddExternalCmds then
	_G.VH_AddExternalCmds(VH_Func)
else
	_G.VH_AddExternalCmdsQueue = _G.VH_AddExternalCmdsQueue or {}
	_G.VH_AddExternalCmdsQueue[script] = VH_Func
end

return Module