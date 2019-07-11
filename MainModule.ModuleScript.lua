local ReplicatedStorage, CollectionService, TweenService, Debris, Players, GroupService, HttpService = game:GetService( "ReplicatedStorage" ), game:GetService( "CollectionService" ), game:GetService( "TweenService" ), game:GetService( "Debris" ), game:GetService( "Players" ), game:GetService( "GroupService" ), game:GetService( "HttpService" )

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
	
	-- Lone Domination --
	
	GameMode = { WinTime = 60 * 25, -- 25 minutes holding all capturepoints to win the raid
		
		RollbackSpeed = 1, -- How much the win timer rolls back per second when home owns the points
		
		WinSpeed = 1, -- How much the win timer goes up per second when away owns the points
		
		ExtraTimeForCapture = 0, -- The amount of extra time added onto the raid timer when a point is captured/a payload reaches its end
		
		ExtraTimeForCheckpoint = 0, -- The amount of extra time added onto the raid timer when a payload reaches a checkpoint
		
	},
	
	--[[ Domination --
	
	GameMode = { WinPoints = 60, -- How many points a team needs to win
		
		HomePointsPerSecond = 1, -- How many points per second home team gets from a point
		
		AwayPointsPerSecond = 1, -- How many points per second away team gets from a point
		
		HomeUnownedDrainPerSecond = 0, -- How many points home team loses per second if they own no points
		
		AwayUnownedDrainPerSecond = 0, -- How many points away team loses per second if they own no points
		
		WinBy = nil, -- To win, the team must have this many more points than the other team when over the WinPoints ( e.g. if this is 25 and away has 495, home must get 520 to win )
		
	},]]
	
	-- NO TOUCHY --
	
	GameTick = 1,
	
	CapturePoints = { },
	
	RequiredCapturePoints = { },
	
	Event_RaidEnded = Instance.new( "BindableEvent" ),
	
	Event_WinChanged = Instance.new( "BindableEvent" ),
	
	Event_OfficialCheck = Instance.new( "BindableEvent" )
	
}

local DiscordCharacterLimit = 2000

local VHMain

local MaxPlayers = Players.MaxPlayers

Module.OfficialRaid = Instance.new( "BoolValue" )
	
Module.OfficialRaid.Name = "OfficialRaid"

Module.OfficialRaid.Parent = ReplicatedStorage

Module.RaidID = Instance.new( "StringValue" )
	
Module.RaidID.Name = "RaidID"

Module.RaidID.Parent = ReplicatedStorage

Module.AwayWinAmount = Instance.new( "NumberValue" )
	
Module.AwayWinAmount.Name = "AwayWinAmount"

Module.AwayWinAmount.Parent = ReplicatedStorage

Module.HomeWinAmount = Instance.new( "NumberValue" )
	
Module.HomeWinAmount.Name = "HomeWinAmount"

local RaidStarted = Instance.new( "RemoteEvent" )

RaidStarted.Name = "RaidStarted"

RaidStarted.Parent = ReplicatedStorage

local RaidEnded = Instance.new( "RemoteEvent" )

RaidEnded.Name = "RaidEnded"

RaidEnded.Parent = ReplicatedStorage

local RaidTimerEvent = Instance.new( "RemoteEvent" )

RaidTimerEvent.Name = "RaidTimerEvent"

RaidTimerEvent.OnServerEvent:Connect( function ( Plr )
	
	if Module.RaidStart then
		
		RaidTimerEvent:FireClient( Plr, Module.RaidStart, Module.CurRaidLimit )
		
	end
	
end )

RaidTimerEvent.Parent = ReplicatedStorage

Module.PlaceName = game:GetService( "MarketplaceService" ):GetProductInfo( game.PlaceId ).Name:gsub( "%b()", "" ):gsub("%b[]", "" ):gsub("^%s*(.+)%s*$", "%1") 

Module.PlaceAcronym = Module.PlaceName:sub( 1, 1 ):upper( ) .. Module.PlaceName:sub( 2 ):gsub( ".", { a = "", e = "", i = "", o = "", u = "" } ):gsub( " (.?)", function ( a ) return a:upper( ) end )

Module.DefaultAwayEmblemUrl = "https://i.imgur.com/cYesNvI.png"

local function FormatTime( Time )
	
	return ( "%.2d:%.2d:%.2d" ):format( Time / ( 60 * 60 ), Time / 60 % 60, Time % 60 )
	
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

local RunningGameLoop

local function RunGameLoop( )
	
	RunningGameLoop = true
	
	local Time = wait( 0.1 )
	
	while Module.RaidStart do
		
		for a = 1, #Module.CapturePoints do
			
			local CapturePoint = Module.CapturePoints[ a ]
			
			local Active = CapturePoint.Active
			
			if not CapturePoint.Bidirectional and CapturePoint.CaptureTimer == CapturePoint.CaptureTime then
				
				Active = false
				
			elseif CapturePoint.Required then
				
				for a = 1, #CapturePoint.Required do
					
					if CapturePoint.Required[ a ].Bidirectional then
						
						if CapturePoint.Required[ a ].CurOwner ~= Module.AwayTeams or CapturePoint.Required[ a ].CaptureTimer ~= CapturePoint.Required[ a ].CaptureTime / 2 then
							
							Active = false
							
							break
							
						end
						
					elseif CapturePoint.Required[ a ].CaptureTimer ~= CapturePoint.Required[ a ].CaptureTime then
						
						Active = false
						
						break
						
					end
					
				end
				
			end
			
			if Active then
				
				local Home, Away = Module.GetSidesNear( CapturePoint.MainPart.Position, CapturePoint.Dist )
				
				local CaptureSpeed = 0
				
				if Home > Away then
					
					CaptureSpeed = math.min( Home - Away, CapturePoint.MaxPlrMultiplier or Module.MaxPlrMultiplier ) ^ 0.5 * ( CapturePoint.CaptureSpeed or Module.CaptureSpeed )
					
					CapturePoint.CapturingSide = Module.HomeTeams
					
					if CapturePoint.Bidirectional then
						
						if Module.HomeTeams ~= CapturePoint.CurOwner then
							
							CapturePoint.BeingCaptured = true
							
						elseif CapturePoint.Down then
							
							CapturePoint.BeingCaptured = nil
							
						end
					
					end
					
				elseif Away > Home then
					
					CaptureSpeed = math.min( Away - Home, CapturePoint.MaxPlrMultiplier or Module.MaxPlrMultiplier ) ^ 0.5 * ( CapturePoint.CaptureSpeed or Module.CaptureSpeed ) * ( CapturePoint.AwayCaptureSpeed or Module.AwayCaptureSpeed )
					
					CapturePoint.CapturingSide = Module.AwayTeams
					
					if CapturePoint.Bidirectional then
						
						if Module.AwayTeams ~= CapturePoint.CurOwner then
							
							CapturePoint.BeingCaptured = true
							
						elseif CapturePoint.Down then
							
							CapturePoint.BeingCaptured = nil
							
						end
						
					end
					
				end
				
				if CaptureSpeed ~= 0 then
					
					CaptureSpeed = CaptureSpeed * Time
					
					if CapturePoint.Bidirectional then
						
						if CapturePoint.BeingCaptured then
							-- the away team is near, capture
							if CapturePoint.InstantCapture then
								
								CapturePoint.CurOwner = CapturePoint.CapturingSide
								
								CapturePoint:SetCaptureTimer( CapturePoint.CaptureTime / 2, CaptureSpeed )
								
								CapturePoint.BeingCaptured = nil
								
								CapturePoint:Captured( CapturePoint.CurOwner )
								
							else
								
								if CapturePoint.CaptureTimer ~= 0 and CapturePoint.CurOwner ~= CapturePoint.CapturingSide then
									
									CapturePoint:SetCaptureTimer( math.max( 0, CapturePoint.CaptureTimer - CaptureSpeed ), -CaptureSpeed )
									
									CapturePoint.Down = true
									
								else
									-- the away team has held it for long enough, switch owner
									if CapturePoint.CaptureTimer == 0 and CapturePoint.Down then
										
										CapturePoint.CurOwner = CapturePoint.CapturingSide
										
										CapturePoint.Down = false
										
										CapturePoint:SetCaptureTimer( 0, 0 )
										
									end
									-- the away team is now rebuilding it
									if CapturePoint.CaptureTimer ~= ( CapturePoint.CaptureTime / 2 ) then
										
										CapturePoint:SetCaptureTimer( math.min( CapturePoint.CaptureTime / 2, CapturePoint.CaptureTimer + CaptureSpeed ), CaptureSpeed )
										
									else
										-- the away team has rebuilt it
										CapturePoint.BeingCaptured = nil
										
										CapturePoint:Captured( CapturePoint.CurOwner )
										
									end
									
								end
								
							end
							-- Owner is rebuilding
						elseif CapturePoint.CaptureTimer ~= ( CapturePoint.CaptureTime / 2 ) then
							
							CapturePoint:SetCaptureTimer( math.min( CapturePoint.CaptureTime / 2, CapturePoint.CaptureTimer + CaptureSpeed ), CaptureSpeed )
							
						end
						
					elseif CapturePoint.CapturingSide ~= ( CapturePoint.AwayOwned and Module.AwayTeams or Module.HomeTeams ) then
						
						local NextCheckpoint = CapturePoint.Checkpoint + 1
						
						if CapturePoint.Checkpoints[ NextCheckpoint ] and not CapturePoint.Checkpoints[ NextCheckpoint ][ 3 ] and ( CapturePoint.LowerLimitTimer == nil or CapturePoint.CaptureTimer ~= CapturePoint.LowerLimitTimer ) then
							
							local NewCaptureTimer = CapturePoint.CaptureTimer + CaptureSpeed
							
							if CapturePoint.TimerLimits then
								
								for b = 1, #CapturePoint.TimerLimits do
									
									if CapturePoint.TimerLimits[ b ][ 1 ] and NewCaptureTimer > CapturePoint.TimerLimits[ b ][ 1 ] and ( CapturePoint.TimerLimits[ b ][ 2 ] == nil or CapturePoint.CaptureTimer < CapturePoint.TimerLimits[ b ][ 2 ] ) then
										
										if CapturePoint.CaptureTimer <= CapturePoint.TimerLimits[ b ][ 1 ] then
											
											local Enabled = CapturePoint.TimerLimits[ b ][ 3 ]
											
											if type( Enabled ) == "function" then
												
												Enabled = Enabled( )
												
											end
											
											if Enabled then
												
												NewCaptureTimer = CapturePoint.TimerLimits[ b ][ 1 ]
												
											elseif not CapturePoint.TimerLimits[ b ][ 5 ] and CapturePoint.TimerLimits[ b ][ 4 ] then
												
												CapturePoint.TimerLimits[ b ][ 5 ] = true
												
												CapturePoint.TimerLimits[ b ][ 4 ]( true )
												
											end
											
										end
										
									elseif CapturePoint.TimerLimits[ b ][ 5 ] and CapturePoint.TimerLimits[ b ][ 4 ] then
										
										CapturePoint.TimerLimits[ b ][ 5 ] = nil
										
										CapturePoint.TimerLimits[ b ][ 4 ]( )
										
									end
									
								end
								
							end
							
							if NewCaptureTimer ~= CapturePoint.CaptureTimer then
								
								NewCaptureTimer = math.min( NewCaptureTimer, CapturePoint.CaptureTime )
								
								local OriginalCaptureTimer = NewCaptureTimer
								
								while CapturePoint.Checkpoints[ NextCheckpoint ] and OriginalCaptureTimer >= CapturePoint.Checkpoints[ NextCheckpoint ][ 1 ] do
									
									if CapturePoint.Checkpoints[ NextCheckpoint ][ 3 ] then
										
										NewCaptureTimer = math.max( OriginalCaptureTimer, ( CapturePoint.Checkpoints[ CapturePoint.Checkpoint ] or { 0 } )[ 1 ] )
										
										break
										
									end
									
									CapturePoint:CheckpointReached( NextCheckpoint )
									
									CapturePoint.Checkpoint = NextCheckpoint
									
									NextCheckpoint = NextCheckpoint + 1
									
								end
								
								CapturePoint:SetCaptureTimer( NewCaptureTimer, CaptureSpeed )
								
							end
							
						end
						
					elseif CapturePoint.CaptureTimer ~= ( CapturePoint.Checkpoints[ CapturePoint.Checkpoint ] or { 0 } )[ 1 ] then
						
						local NewCaptureTimer = CapturePoint.CaptureTimer - CaptureSpeed
						
						if CapturePoint.TimerLimits then
							
							for a = 1, #CapturePoint.TimerLimits do
								
								if CapturePoint.TimerLimits[ a ][ 2 ] and NewCaptureTimer < CapturePoint.TimerLimits[ a ][ 2 ] and ( CapturePoint.TimerLimits[ a ][ 1 ] == nil or CapturePoint.CaptureTimer > CapturePoint.TimerLimits[ a ][ 1 ] ) then
									
									if CapturePoint.CaptureTimer >= CapturePoint.TimerLimits[ a ][ 2 ] then
										
										local Enabled = CapturePoint.TimerLimits[ a ][ 3 ]
										
										if type( Enabled ) == "function" then
											
											Enabled = Enabled( )
											
										end
										
										if Enabled then
											
											NewCaptureTimer = CapturePoint.TimerLimits[ a ][ 2 ]
											
										elseif not CapturePoint.TimerLimits[ a ][ 5 ] and CapturePoint.TimerLimits[ a ][ 4 ] then
											
											CapturePoint.TimerLimits[ a ][ 5 ] = true
											
											CapturePoint.TimerLimits[ a ][ 4 ]( true )
											
										end
										
									end
									
								elseif CapturePoint.TimerLimits[ a ][ 5 ] and CapturePoint.TimerLimits[ a ][ 4 ] then
									
									CapturePoint.TimerLimits[ a ][ 5 ] = nil
									
									CapturePoint.TimerLimits[ a ][ 4 ]( )
									
								end
								
							end
							
						end
						
						CapturePoint:SetCaptureTimer( math.max( NewCaptureTimer, ( CapturePoint.Checkpoints[ CapturePoint.Checkpoint ] or { 0 } )[ 1 ] ) , -CaptureSpeed )
						
					end
					
				end
				
			end
			
		end
		
		local Required = ( #Module.RequiredCapturePoints == 0 and #Module.CapturePoints == 1 ) and Module.CapturePoints or Module.RequiredCapturePoints
		
		if Module.GameMode.WinTime then
			
			local HomeFullyOwnAll, HomeOwnAll, AwayFullyOwnAll = true, true, true
			
			for a = 1, #Required do
				
				local b = Required[ a ]
				
				if b.Active then
					
					if b.Bidirectional then
						
						if b.CurOwner == Module.AwayTeams then
							
							HomeOwnAll = false
							
							HomeFullyOwnAll = false
							
							if b.CaptureTimer ~= b.CaptureTime / 2 then
								
								AwayFullyOwnAll = false
								
							end
							
						else
							
							AwayFullyOwnAll = false
							
							if b.CaptureTimer ~= b.CaptureTime / 2 then
								
								HomeFullyOwnAll = false
								
							end
							
						end
						
					elseif not b.AwayOwned then
						
						if b.CaptureTimer ~= b.CaptureTime then
							
							AwayFullyOwnAll = false
							
							if b.CapturingSide == Module.AwayTeams then
								
								HomeOwnAll = false
								
								HomeFullyOwnAll = false
								
							elseif b.CaptureTimer ~= ( b.Checkpoints[ b.Checkpoint ] or { 0 } )[ 1 ] then
								
								HomeFullyOwnAll = false
								
							end
							
						else
							
							HomeFullyOwnAll = false
							
							HomeOwnAll = false
							
						end
						
					elseif b.CaptureTimer == b.CaptureTime then
						
						Module.EndRaid( "Won" )
						
					end
					
				end
				
			end
			
			if AwayFullyOwnAll then
				
				Module.SetWinTimer( Module.AwayWinAmount.Value + ( Module.GameMode.WinSpeed * Time ) )
				
				if Module.AwayWinAmount.Value >= Module.GameMode.WinTime then
					
					Module.EndRaid( "Lost" )
					
				end
				
			elseif HomeFullyOwnAll or HomeOwnAll then
				
				if Module.RaidStart + Module.CurRaidLimit <= tick( ) then
					
					Module.EndRaid( "TimeLimit" )
					
				end
				
				if ( HomeFullyOwnAll or ( Module.RollbackWithPartialCap and HomeOwnAll ) ) and Module.AwayWinAmount.Value < Module.GameMode.WinTime and Module.AwayWinAmount.Value > 0 then
					
					if Module.GameMode.RollbackSpeed then
						
						Module.SetWinTimer( math.max( 0, Module.AwayWinAmount.Value - ( Module.GameMode.RollbackSpeed * Time ) ) )
						
					else
						
						Module.SetWinTimer( 0 )
						
					end
					
				end
				
			end
			
		elseif Module.GameMode.WinPoints then
			
			local AwayAdd, HomeAdd = 0, 0
			
			for a = 1, #Required do
				
				local b = Required[ a ]
				
				if b.Active then
					
					if b.Bidirectional then
						
						if b.CaptureTimer == b.CaptureTime / 2 then
							
							if b.CurOwner == Module.AwayTeams then
								
								AwayAdd = AwayAdd + ( b.AwayPointsPerSecond or Module.GameMode.AwayPointsPerSecond )
								
							else
								
								HomeAdd = HomeAdd + ( b.HomePointsPerSecond or Module.GameMode.HomePointsPerSecond )
								
							end
							
						end
						
					elseif b.CaptureTimer == b.CaptureTime then
						
						if b.AwayOwned then
							
							AwayAdd = AwayAdd + ( b.AwayPointsPerSecond or Module.GameMode.AwayPointsPerSecond )
							
						else
							
							HomeAdd = HomeAdd + ( b.HomePointsPerSecond or Module.GameMode.HomePointsPerSecond )
							
						end
						
					end
					
				end
				
			end
			
			if AwayAdd == 0 then AwayAdd = -( Module.GameMode.AwayUnownedDrainPerSecond or 0 ) end
			
			if HomeAdd == 0 then HomeAdd = -( Module.GameMode.HomeUnownedDrainPerSecond or 0 ) end
			
			Module.AwayWinAmount.Value = math.clamp( Module.AwayWinAmount.Value + AwayAdd * Time, 0, Module.GameMode.WinPoints )
			
			Module.HomeWinAmount.Value = math.clamp( Module.HomeWinAmount.Value + HomeAdd * Time, 0, Module.GameMode.WinPoints )
			
			if Module.AwayWinAmount.Value ~= Module.HomeWinAmount.Value then
				
				if Module.RaidStart + Module.CurRaidLimit <= tick( ) then
					
					if Module.AwayWinAmount.Value > Module.HomeWinAmount.Value then
						
						Module.EndRaid( "Lost" )
						
					else
						
						Module.EndRaid( "Won" )
						
					end
					
				elseif Module.AwayWinAmount.Value >= Module.GameMode.WinPoints and ( not Module.GameMode.WinBy or ( Module.AwayWinAmount.Value - Module.HomeWinAmount.Value >= Module.GameMode.WinBy ) ) then
					
					Module.EndRaid( "Lost" )
					
				elseif Module.HomeWinAmount.Value >= Module.GameMode.WinPoints and ( not Module.GameMode.WinBy or ( Module.HomeWinAmount.Value - Module.AwayWinAmount.Value >= Module.GameMode.WinBy ) ) then
					
					Module.EndRaid( "Won" )
					
				end
				
			end
			
		end
		
		Time = wait( Module.GameTick )
		
	end
	
	RunningGameLoop = nil
	
end

local function GetAwayGroup( )
	
	local Highest
	
	local AllGroups = { }
	
	local Away = 0
	
	local Plrs = Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		if Module.AwayTeams[ Plrs[ a ].Team ] then
			
			local Groups = GroupService:GetGroupsAsync( Plrs[ a ].UserId )
			
			for b = 1, #Groups do
				
				AllGroups[ Groups[ b ].Id ] = ( AllGroups[ Groups[ b ].Id ] or 0 ) + ( Groups[ b ].IsPrimary and 2 or 1 )
				
				if not Highest or AllGroups[ Groups[ b ].Id ] > AllGroups[ Highest ] then
					
					Highest = Groups[ b ].Id
					
				end
				
			end
			
		end
		
	end
	
	if not Highest or AllGroups[ Highest ] <= Away * 0.35 then
		
		return { Name = ( Module.DefaultAwayName or next( Module.AwayTeams ).Name ), EmblemUrl = Module.DefaultAwayEmblemUrl or "", EmblemId = Module.DefaultAwayEmblemId or "", Id = Module.DefaultAwayId or 0 }
		
	end
	
	return Highest
	
end

function Module.GroupPagesToArray( Pages )
	
	local Array = { }
	
	while true do
		
		local Page = Pages:GetCurrentPage( )
		
		for a = 1, #Page do
			
			Array[ #Array + 1 ] = Page[ a ].Id
			
		end
		
		if Pages.isFinished then break end
		
		Pages:AdvanceToNextPageAsync( )
		
	end
	
	return Array
	
end

local IDWords = { "Roblox", "Robloxian", "TRA", "Observation", "Jumpy", "Books", "Level", "Fast", "Loud", "Wheel", "Abandoned", "Deliver", "Rock", "Rub", "Tame", "Muscle", "Frighten", "Sore", "Number", "Dress", "Lucky", "Love", "Roomy", "Rambunctious", "Tiger", "Group", "Flame", "Gullible", "Obtainable", "Trail", "Brake", "Famous", "Perform", "Idea", "Mix", "Graceful", "Cub", "Argument", "Male", "Trust", "Gigantic", "Pump", "Move", "Ear", "Paddle", "Tall", "Feigned", "Toad", "Public", "Delightful", "Test", "Sponge", "Regular", "Marry", "Grotesque", "Stop", "Walk", "Memorise", "Spectacular", "Giants", "Drawer", "Cloudy", "Pies", "Cheap", "Woozy", "Dinner", "Guide", "Rabid", "Statement", "Four", "Pipe", "Crate", "Paper", "Seemly", "Old", "Heal", "Base", "Marked", "Disturbed", "Shiny", "Boiling", "Wary", "Bone", "Play", "Copy", "Toys", "Mourn", "Support", "Haircut", "Downtown", "Closed", "Film", "Stiff", "Murky", "Frantic", "Juvenile", "Disagreeable", "Madly", "Unsuitable", "Nonstop", "Grab", "Wrong", "Melt", "Anxious", "Clip", "Weary", "Crow", "Refuse", "Frightened", "Fluffy", "Breezy", "Pizzas", "Right", "Tangy", "Toy", "Bizarre", "Concentrate", "Pocket", "Fork", "Push", "Quick", "Miniature", "Abusive", "Carry", "Heavenly", "Better", "Silent", "Few", "Versed", "Receipt", "Tug", "Matter", "Excuse", "Sore", "Practise", "Brown", "Clear", "Gamy", "Increase", "Subsequent", "Connect", "Careful", "Attraction", "Silk", "Vessel", "Plant", "Summer", "North", "Deeply", "Able", "Fresh", "Splendid", "True", "Bag", "Fixed", "Damaged", "Manage", "General", "Thoughtless", "Nappy", "Breakable", "Disagree", "Curious", "Learned", "Zippy", "Understood", "Fascinated", "Meaty", "Jaded", "Regret", "Switch", "House", "Torpid", "Neat", "String", "Top", "Literate", "Actually", "Things", "Girls", "Voiceless", "Delicious", "Check", "Aspiring", "Decorate", "Allow", "Oatmeal", "Massive", "Spiky", "Towering", "Horrible", "Many", "Education", "Scrape", "Moan", "Regret", "Head", "Decorous", "Weight", "Rain", "Hill", "Determined", "Smooth", "Lake", "Hideous", "Clever", "Average", "Discovery", "Squirrel", "Husky", "Flow", "Probable", "Illegal", "Imaginary", "Quill", "Start", "Laughable", "Temper", "Wool", "Smash", "Lopsided", "Shelf", "Premium", "Stem", "Zipper", "Used", "Receptive", "Hat", "Rush", "Example", "Knotty", "Heartbreaking", "Drip", "Part", "Succinct", "Amusement", "Sprout", "Late", "Scintillating", "Fairies", "Willing", "Unnatural", "Terrific", "Maniacal", "Glove", "Devilish", "Callous", "Liquid", "Mute", "Fry", "Tightfisted", "Accidental", "Coal", "Ancient", "Simplistic", "Tempt", "Shrug", "Tax", "Calendar", "Reaction", "Trade", "Drop", "Tickle", "Kindly", "Hop", "Town", "License", "Scold", "Obey", "Ambitious", "Book", "Itch", "Reminiscent", "Argue", "Cup", "Separate", "Meek", "Worthless", "Disillusioned", "Brick", "Innate", "Scare", "Macho", "Harbor", "Flowers", "Arm", "Advice", "Voyage", "Suffer", "Quixotic", "Dirty", "Thaw", "Malicious", "Impress", "Prevent", "Watch", "Stew", "Upset", "Green", "Adjustment", "Smart", "Land", "Caring", "Slow", "Purple", "Remove", "Nest", "Wash", "Attack", "Swift", "Low", "Squalid", "Labored", "Sticky", "Kindhearted", "Milk", "Bruise", "Bear", "Offer", "Even", "Juice", "Place", "End", "Flower", "Terrible", "Disgusting", "Veil", "Hard", "Whistle", "Exchange", "Surprise", "Fancy", "Pen", "Army", "Dazzling", "Harsh", "Knowledgeable", "Unhealthy", "Root", "Puny", "Oval", "Cows", "Juicy", "Daughter", "Dirt", "Low", "Slippery", "Agree", "Shoe", "Cattle", "Rebel", "Sparkle", "Adhesive", "Duck", "Warm", "Lowly", "Parsimonious", "Arrive", "Camp", "Join", "Thread", "Paste", "Drag", "Kind", "Impolite", "Steady", "Spoon", "Rose", "Curve", "Coach", "Sidewalk", "Panicky", "Rejoice", "Hand", "Settle", "Suspend", "Hope", "Foregoing", "Sound", "Preserve", "Scatter", "Carpenter", "Boast", "Good", "Poised", "Risk", "Nifty", "Beautiful", "Pinch", "Gruesome", "Alluring", "Amuse", "Sticks", "Request", "Unadvised", "Meddle", "Unpack", "Knit", "Smell", "Screeching", "Perfect", "Crazy", "Hapless", "Dolls", "Coach", "Cakes", "Gray", "Level", "Roasted", "Naughty", "Nation", "Bird", "Equable", "Stamp", "Button", "Quiet", "Butter", "Helpless", "Store", "Box", "Debonair", "Dispensable", "Desk", "Head", "Bolt", "Push", "Homely", "Picayune", "Demonic", "Rely", "Obscene", "Defeated", "Safe", "Fear", "Domineering", "Long", "Erect", "Produce", "Jellyfish", "End", "Rabbits", "Violet", "Sophisticated", "Scattered", "Swing", "Tart", "Government", "Silver", "Shame", "Wholesale", "Detail", "Minister", "Holistic", "Mate", "Fragile", "Lackadaisical", "Control", "Steadfast", "Ugliest", "Yellow", "Seat", "Future", "Engine", "Icy", "Gate", "Acidic", "Capricious", "Abaft", "Telephone", "Question", "False", "Sneaky", "Enormous", "Spray", "Exclusive", "Run", "Scene", "Inform", "Fail", "Uncle", "Ablaze", "Trousers", "Wanting", "Surround", "Grandmother", "Stop", "Slip", "Reply", "Vegetable", "Hulking", "Confused", "Sheet", "Coil", "Whisper", "Last", "Person", "Jeans", "Smoggy", "Gratis", "Search" }

local IDRandom = Random.new( )

Module.RaidID.Value = IDWords[ IDRandom:NextInteger( 1, #IDWords ) ] .. IDWords[ IDRandom:NextInteger( 1, #IDWords ) ] .. IDWords[ IDRandom:NextInteger( 1, #IDWords ) ]

function Module.StartRaid( )
	
	local Cur = tick( )
	
	Module.AwayGroup = GetAwayGroup( )
	
	Module.RaidStart = Cur
	
	Module.CurRaidLimit = Module.RaidLimit
	
	Module.OfficialRaid.Value = true
	
	RaidTimerEvent:FireAllClients( Module.RaidStart, Module.CurRaidLimit, Module.GameMode.WinTime or Module.GameMode.WinPoints )
	
	RaidStarted:FireAllClients( Module.RaidID.Value, Module.AwayGroup )
	
	Module.TeamLog = { }
	
	local Plrs = Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		Module.TeamLog[ tostring( Plrs[ a ].UserId ) ] = { { Cur, Plrs[ a ].Team  } }
		
		if Module.GracePeriod and Module.GracePeriod > 0 then
			
			HandleGrace( Plrs[ a ], Cur )
			
		end
		
		if Module.RespawnAllPlayers or Module.AwayTeams[ Plrs[ a ].Team ] then
			
			Plrs[ a ]:LoadCharacter( )
			
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

function Module.EndRaid( Result )
	
	Module.Event_RaidEnded:Fire( Module.RaidID.Value, Module.AwayGroup, Result, Module.TeamLog, Module.RaidStart )
	
	RaidEnded:FireAllClients( Module.RaidID.Value, Module.AwayGroup, Result )
	
	Module.ResetAll( )
	
	if Result ~= "Forced" and Result ~= "Left" then
		
		wait( 20 )
		
		local Plrs = Players:GetPlayers( )
		
		for a = 1, #Plrs do
			
			if Module.AwayTeams[ Plrs[ a ].Team ] then
				
				if Module.BanWhenWinOrLoss and VHMain then
					
					VHMain.ParseCmdStacks( nil, "permban/" .. Plrs[ a ].UserId .. "/30m" )
					
				else
					
					Plrs[ a ]:Kick( "Raid is over, please rejoin to raid again" )
					
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
	
	for a = 1, #Module.CapturePoints do
		
		Module.CapturePoints[ a ]:Reset( )
		
	end
	
	Module.AwayWinAmount.Value = 0
	
	Module.HomeWinAmount.Value = 0
	
end

function Module.TableHasValue( Table, Value )
	
	for a = 1, #Table do
		
		if Table[ a ] == Value then
			
			return 1
			
		end
		
	end
	
end

function Module.GetCountFor( Side, Plr )
	
	local Team = Side[ Plr.Team ]
	
	if Team then
		
		local CountsFor = Team.CountsFor
		
		for b = 1, #Team do
			
			if Team[ b ].CountsFor then
				
				for c = 1, #Team[ b ] do
					
					if Plr:IsInGroup( Team[ b ][ c ] ) then
						
						return Team[ b ].CountsFor
						
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
	
	local Plrs = Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		Home = Home + Module.GetCountFor( Module.HomeTeams, Plrs[ a ] )
		
		Away = Away + Module.GetCountFor( Module.AwayTeams, Plrs[ a ] )
		
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
		
		if Module.MinTime and Module.MaxTime and not TimeCheck then
			
			spawn( function ( )
				
				while wait( 1 ) and not Module.RaidStart do
					
					Module.OfficialCheck( )
					
				end
				
			end )
			
		end
		
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
		
	end
	
end

function PlayerAdded( Plr )
	
	local Found
	
	for a, b in pairs( Module.HomeTeams ) do
		
		for c = 1, #b do
			
			for d = 1, #b[ c ] do
				
				if Plr:IsInGroup( b[ c ][ d ] ) then
					
					Plr.Team = a
					
					Found = true
					
					break
					
				end
				
			end
			
		end
		
		if Found then break end
		
	end
	
	if not Found then
		
		for a, b in pairs( Module.AwayTeams ) do
			
			for c = 1, #b do
				
				for d = 1, #b[ c ] do
					
					if Plr:IsInGroup( b[ c ][ d ] ) then
						
						Plr.Team = a
						
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

Players.PlayerRemoving:Connect( Module.OfficialCheck )

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
	
	local Plrs = Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		local b = Plrs[ a ]
		
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

function Module.SetSpawns( SpawnClones, Model, Side )
	
	if SpawnClones then
		
		for a = 1, #SpawnClones do
			
			SpawnClones[ a ]:Destroy( )
			
			SpawnClones[ a ] = nil
			
		end
		
	end
	
	local Kids = Model:GetDescendants( )
	
	for a = 1, #Kids do
		
		if Kids[ a ]:IsA( "SpawnLocation" ) then
			
			if CollectionService:HasTag( Kids[ a ], "HomeSpawn" ) then
				
				if Side == Module.HomeTeams then
					
					Kids[ a ].Enabled = true
					
				else
					
					Kids[ a ].Enabled = false
					
				end
				
			elseif CollectionService:HasTag( Kids[ a ], "AwaySpawn" ) then
				
				if Side == Module.AwayTeams then
					
					Kids[ a ].Enabled = true
					
				else
					
					Kids[ a ].Enabled = false
					
				end
				
			end
			
			local First
			
			for b, c in pairs( Side ) do
				
				if not First then
					
					First = true
					
					Kids[ a ].TeamColor = b.TeamColor
					
					Kids[ a ].BrickColor = b.TeamColor
					
				elseif Kids[ a ].Enabled then
					
					local Clone = Kids[ a ]:Clone( )
					
					SpawnClones = SpawnClones or { }
					
					SpawnClones[ #SpawnClones + 1 ] = Clone
					
					Clone.Transparency = 1
					
					Clone.CanCollide = false
					
					Clone:ClearAllChildren( )
					
					Clone.TeamColor = b.TeamColor
					
					Clone.BrickColor = b.TeamColor
					
					Clone.Parent = Kids[ a ]
					
				end
				
			end
			
		end
		
	end
	
end

local function UpdateFlag( CapturePoint )
	
	if CapturePoint.Model:FindFirstChild( "Smoke", true ) then
		
		CapturePoint.Model:FindFirstChild( "Smoke", true ).Color = next( CapturePoint.CurOwner ).TeamColor.Color
		
	end
	
	CapturePoint.Model.Naming:GetChildren( )[ 1 ].Name = "Owned by " .. next( CapturePoint.CurOwner ).Name
	
	local Hint = Instance.new( "Hint", workspace )
	
	Hint.Text = "The flag at the " .. CapturePoint.Name .. " is now owned by " .. next( CapturePoint.CurOwner ).Name
	
	Debris:AddItem( Hint, 5 )
	
end

local Captured = Instance.new( "RemoteEvent" )

Captured.Name = "Captured"

Captured.Parent = ReplicatedStorage

Module.BidirectionalPointMetadata = {
	
	Bidirectional = true,
	
	Reset = function ( self )
		
		self.Active = nil
		
		self.CurOwner = self.StartOwner or Module.HomeTeams
	
		self.CapturingSide = self.CurOwner
		
		self.ExtraTimeGiven = nil
		
		self:SetCaptureTimer( Module.GameMode.WinPoints and 0 or self.CaptureTime / 2, 0 )
		
		self:Captured( self.CurOwner )
		
		return self
		
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
	
	SetCaptureTimer = function ( self, Val, Speed )
		
		self.Model.CapturePct.Value = Val / ( self.CaptureTime / 2 )
		
		self.Event_CaptureChanged:Fire( Val, Speed )
		
		self.CaptureTimer = Val
		
		return self
		
	end,
	
	Captured = function ( self, Side )
		
		self.SpawnClones = Module.SetSpawns( self.SpawnClones, self.Model, Side )
		
		if Module.RaidStart and Side == Module.AwaySide and not self.ExtraTimeGiven and ( self.ExtraTimeForCapture or Module.GameMode.ExtraTimeForCapture )  then
			
			self.ExtraTimeGiven = true
			
			Module.CurRaidLimit = math.max( tick( ) - Module.RaidStart + ( self.ExtraTimeForCapture or Module.GameMode.ExtraTimeForCapture ), Module.CurRaidLimit + ( self.ExtraTimeForCapture or Module.GameMode.ExtraTimeForCapture ) )
			
			RaidTimerEvent:FireAllClients( Module.RaidStart, Module.CurRaidLimit )
			
		end
		
		self.Event_Captured:Fire( next( Side ), nil )
		
		Captured:FireAllClients( self.Name, next( Side ), nil )
		
	end,
	
	AsFlag = function ( self, Dist )
		
		self.Step = Dist and Dist / ( self.CaptureTime / 2 ) or 1.35
		
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
		
		local Kids = self.Model:GetDescendants( )
		
		for a = 1, #Kids do
			
			if Kids[ a ]:IsA( "BasePart" ) and Kids[ a ].Name:lower( ):find( "flag" ) then
				
				StartCFs[ Kids[ a ] ] = Kids[ a ].CFrame
				
				local Event Event = Kids[ a ].AncestryChanged:Connect( function ( )
					
					StartCFs[ Kids[ a ] ] = nil
					
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
			
			UpdateFlag( self )
			
		end )
			
		UpdateFlag( self )
		
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
		
		local BrickTimer = self.Model:FindFirstChild( "BrickTimer", true )
		
		if BrickTimer then
			
			BrickTimer:GetChildren( )[ 1 ].Name = Module.OfficialRaid.Value and ( Module.AwayGroup.Name .. " do not own the main flag" ) or "No raid in progress" 
			
		end
		
		return self
		
	end
	
}

-- Table requires Dist = Number, CaptureTime = Number, MainPart = Instance, Model = Instance
function Module.BidirectionalPoint( CapturePoint )
	
	if Module.GameMode.WinPoints then
		
		Module.HomeWinAmount.Parent = ReplicatedStorage
		
	else
		
		Module.HomeWinAmount.Parent = nil
		
	end
	
	if #Module.CapturePoints == 0 then
		
		local Plrs = Players:GetPlayers( )
		
		for a = 1, #Plrs do
			
			PlayerAdded( Plrs[ a ] )
			
		end
		
	end
	
	CapturePoint.CaptureTime = CapturePoint.CaptureTime or 1
	
	CapturePoint.Name = CapturePoint.Name or CapturePoint.Model.Name
	
	setmetatable( CapturePoint, { __index = Module.BidirectionalPointMetadata } )
	
	CapturePoint.Event_Captured = Instance.new( "BindableEvent" )
	
	CapturePoint.Event_CaptureChanged = Instance.new( "BindableEvent" )
	
	local Pct = Instance.new( "NumberValue" )
	
	Pct.Name = "CapturePct"
	
	Pct.Parent = CapturePoint.Model
	
	CapturePoint:Reset( )
	
	Module.CapturePoints[ #Module.CapturePoints + 1 ] = CapturePoint
	
	return CapturePoint
	
end

local function GetWorldPos( Inst )
	
	return Inst:IsA( "Attachment" ) and Inst.WorldPosition or Inst.Position
	
end

function Module.OrderedPointsToPayload( StartPoint, Checkpoints, TurnPoints )
	
	local Ordered = { }
	
	for a = 1, #TurnPoints do
		
		if TurnPoints[ a ] ~= StartPoint and not Module.TableHasValue( Checkpoints, TurnPoints[ a ] ) then
			
			Ordered[ #Ordered + 1 ] = TurnPoints[ a ]
			
		end
		
		TurnPoints[ a ] = nil
		
	end
	
	for a = 1, #Checkpoints do
		
		Ordered[ #Ordered + 1 ] = Checkpoints[ a ]
		
		Checkpoints[ Checkpoints[ a ] ] = true
		
		Checkpoints[ a ] = nil
		
	end
	
	table.sort( Ordered, function ( a, b ) return tonumber( a.Name ) < tonumber( b.Name ) end )
	
	local Total = 0
	
	for a = 1, #Ordered do
		
		local Dist = ( GetWorldPos( Ordered[ a ] ) - GetWorldPos( a == 1 and StartPoint or Ordered[ a - 1 ] ) ).magnitude
		
		Total = Total + Dist
		
		if Checkpoints[ Ordered[ a ] ] then
			
			Checkpoints[ #Checkpoints + 1 ] = { Total, Ordered[ a ] }
			
			Checkpoints[ Ordered[ a ] ] = nil
			
		else
			
			TurnPoints[ #TurnPoints + 1 ] = { Total, Ordered[ a ] }
			
		end
		
	end
	
	return Checkpoints, TurnPoints, Total
	
end

local CheckpointReached = Instance.new( "RemoteEvent" )

CheckpointReached.Name = "CheckpointReached"

CheckpointReached.Parent = ReplicatedStorage

Module.UnidirectionalPointMetadata = {
	
	Reset = function ( self )
		
		self.Active = nil
		
		self.Checkpoint = 0
		
		self.ExtraTimeGiven = nil
		
		self.CapturingSide = self.AwayOwned and Module.AwayTeams or Module.HomeTeams
		
		self:SetCaptureTimer( 0, 0 )
		
		self:CheckpointReached( 0 )
		
		return self
		
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
	
	SetCaptureTimer = function ( self, Val, Speed )
		
		self.Model.CapturePct.Value = Val / self.CaptureTime
		
		self.Event_CaptureChanged:Fire( Val, Speed )
		
		self.CaptureTimer = Val
		
		return self
		
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
			
			if not self.Checkpoints[ Checkpoint + 1 ] and ( self.ExtraTimeForCapture or Module.GameMode.ExtraTimeForCapture ) then
				
				ExtraTimeToGive = self.ExtraTimeForCapture or Module.GameMode.ExtraTimeForCapture
				
			elseif self.ExtraTimeForCheckpoint or Module.GameMode.ExtraTimeForCheckpoint then
				
				ExtraTimeToGive = self.ExtraTimeForCheckpoint or Module.GameMode.ExtraTimeForCheckpoint
				
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
			
			local Kids = self.Model:GetChildren( )
			
			for a = 1, #Kids do
				
				if CollectionService:HasTag( Kids[ a ], "PayloadWheel" ) then
					
					local Rotate = Kids[ a ].Rotate.Value * 22.25 * CaptureSpeed
					
					TweenService:Create( Kids[ a ].Weld, TweenInfo.new( Module.GameTick, Enum.EasingStyle.Linear ), { C1 = Kids[ a ].Weld.C1 * CFrame.fromOrientation( math.rad( Rotate.X ), math.rad( Rotate.Y ), math.rad( Rotate.Z ) ) } ):Play( )
					
				end
				
			end
			
			for a = 1, #Targets do
				
				local Tween = TweenService:Create( self.MainPart, TweenInfo.new( Targets[ a ][ 1 ] / TotalDist * Module.GameTick, Enum.EasingStyle.Linear ), { CFrame = Targets[ a ][ 2 ] } )
				
				Tween:Play( )
				
				if a ~= #Targets then
					
					local State = Tween.Completed:Wait( )
					
					while State ~= Enum.PlaybackState.Completed do
						
						if State == Enum.PlaybackState.Cancelled then return end
						
						State = Tween.Completed:Wait( )
						
					end
					
				end
				
			end
			
		end )
		
		return self
		
	end
	
}

-- Table requires Dist = Number, CaptureTime = Number, MainPart = Instance, Model = Instance
function Module.UnidirectionalPoint( CapturePoint )
	
	if Module.GameMode.WinPoints then
		
		Module.HomeWinAmount.Parent = ReplicatedStorage
		
	else
		
		Module.HomeWinAmount.Parent = nil
		
	end
	
	if #Module.CapturePoints == 0 then
		
		local Plrs = Players:GetPlayers( )
		
		for a = 1, #Plrs do
			
			PlayerAdded( Plrs[ a ] )
			
		end
		
	end
	
	CapturePoint.Name = CapturePoint.Name or CapturePoint.Model.Name
	
	setmetatable( CapturePoint, { __index = Module.UnidirectionalPointMetadata } )
	
	CapturePoint.Event_CheckpointReached = Instance.new( "BindableEvent" )
	
	CapturePoint.Event_CaptureChanged = Instance.new( "BindableEvent" )
	
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
	
	CapturePoint:Reset( )
	
	Module.CapturePoints[ #Module.CapturePoints + 1 ] = CapturePoint
	
	return CapturePoint
	
end

Module.Event_OfficialCheck.Event:Connect( function ( Home, Away )
	
	if not Module.RallyMessage and Home < Module.HomeRequired and Away >= Module.AwayRequired * ( Module.RallyMessagePct or 0.5 ) then
		
		Module.RallyMessage = true
		
		if not Module.Practice and Module.DiscordMessages and ( Module.AllowDiscordInStudio or not game:GetService("RunService"):IsStudio( ) ) then

			local AwayGroup = GetAwayGroup( )
			
			AwayGroup = AwayGroup.Id and ( "[" .. AwayGroup.Name .. "](<https://www.roblox.com/groups/" .. AwayGroup.Id .. "/a#!/about>)" ) or Module.AwayGroup.Name
			
			local HomeGroup = Module.HomeGroup and ( "[" .. Module.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. Module.HomeGroup.Id .. "/a#!/about>)" )
			
			local PlaceAcronym ="[" .. Module.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
			
			local PlaceName = "[" .. Module.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
			
			local Home, Away = { }, { }
			
			local Plrs = Players:GetPlayers( )
			
			for a = 1, #Plrs do
				
				if Module.HomeTeams[ Plrs[ a ].Team ] then
					
					Home[ #Home + 1 ] = "[" .. Plrs[ a ].Name .. "](<https://www.roblox.com/users/" .. Plrs[ a ].UserId .. "/profile>) - " .. Plrs[ a ]:GetRoleInGroup( Module.HomeGroup.Id )
					
				elseif Module.AwayTeams[ Plrs[ a ].Team ] then
					
					Away[ #Away + 1 ] = "[" .. Plrs[ a ].Name .. "](<https://www.roblox.com/users/" .. Plrs[ a ].UserId .. "/profile>)" .. ( AwayGroup.Id and ( " - " .. Plrs[ a ]:GetRoleInGroup( AwayGroup.Id ) ) or "" )
					
				end
				
			end
			
			if #Home == 0 then Home[ 1 ] = "None" end
			
			if #Away == 0 then Away[ 1 ] = "None" end
			
			for a = 1, #Module.DiscordMessages do
				
				if Module.DiscordMessages[ a ].Rallying then
					
					local Msg = Module.DiscordMessages[ a ].Rallying:gsub( "%%%w*%%", { [ "%PlaceAcronym%" ] = PlaceAcronym, [ "%PlaceName%" ] = PlaceName, [ "%RaidID%" ] = Module.RaidID.Value, [ "%AwayGroup%" ] = AwayGroup, [ "%AwayList%" ] = table.concat( Away, ", " ), [ "%AwayListNewline%" ] = table.concat( Away, "\n" ), [ "%HomeGroup%" ] = HomeGroup, [ "%HomeList%" ] = table.concat( Home, ", " ), [ "%HomeListNewline%" ] = table.concat( Home, "\n" ) } )
					
					while true do
						
						local LastNewLine = #Msg <= DiscordCharacterLimit and DiscordCharacterLimit or Msg:sub( 1, DiscordCharacterLimit ):match( "^.*()[\n]" )
						
						local Ran, Error = pcall( HttpService.PostAsync, HttpService, Module.DiscordMessages[ a ].Url, HttpService:JSONEncode{ avatar_url = Module.HomeGroup.EmblemUrl, username = Module.PlaceAcronym .. " Raid Bot", content = Msg:sub( 1, LastNewLine and LastNewLine - 1 or DiscordCharacterLimit ) } )
						
						if not Ran then warn( Error ) end
						
						if #Msg <= ( LastNewLine or DiscordCharacterLimit ) then break end
						
						Msg = Msg:sub( ( LastNewLine or DiscordCharacterLimit ) + 1 )
						
					end
					
				end
				
			end
			
		end
		
	end
	
end )

Module.OfficialRaid:GetPropertyChangedSignal( "Value" ):Connect( function ( )
	
	if not Module.OfficialRaid.Value then return end
	
	if not Module.Practice and Module.DiscordMessages and ( Module.AllowDiscordInStudio or not game:GetService("RunService"):IsStudio( ) ) then
		
		local Plrs = Players:GetPlayers( )
		
		local AwayGroup = Module.AwayGroup.Id and ( "[" .. Module.AwayGroup.Name .. "](<https://www.roblox.com/groups/" .. Module.AwayGroup.Id .. "/a#!/about>)" ) or Module.AwayGroup.Name
		
		local HomeGroup = Module.HomeGroup and ( "[" .. Module.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. Module.HomeGroup.Id .. "/a#!/about>)" )
		
		local PlaceAcronym ="[" .. Module.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local PlaceName = "[" .. Module.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local Home, Away = { }, { }
		
		for a = 1, #Plrs do
			
			if Module.HomeTeams[ Plrs[ a ].Team ] then
				
				Home[ #Home + 1 ] = "[" .. Plrs[ a ].Name .. "](<https://www.roblox.com/users/" .. Plrs[ a ].UserId .. "/profile>) - " .. Plrs[ a ]:GetRoleInGroup( Module.HomeGroup.Id )
				
			elseif Module.AwayTeams[ Plrs[ a ].Team ] then
				
				Away[ #Away + 1 ] = "[" .. Plrs[ a ].Name .. "](<https://www.roblox.com/users/" .. Plrs[ a ].UserId .. "/profile>)" .. ( Module.AwayGroup.Id and ( " - " .. Plrs[ a ]:GetRoleInGroup( Module.AwayGroup.Id ) ) or "" )
				
			end
			
		end
		
		if #Home == 0 then Home[ 1 ] = "None" end
		
		if #Away == 0 then Away[ 1 ] = "None" end
		
		for a = 1, #Module.DiscordMessages do
			
			if Module.DiscordMessages[ a ].Start then
				
				local Msg = Module.DiscordMessages[ a ].Start:gsub( "%%%w*%%", { [ "%PlaceAcronym%" ] = PlaceAcronym, [ "%PlaceName%" ] = PlaceName, [ "%RaidID%" ] = Module.RaidID.Value, [ "%AwayGroup%" ] = AwayGroup, [ "%AwayList%" ] = table.concat( Away, ", " ), [ "%AwayListNewline%" ] = table.concat( Away, "\n" ), [ "%HomeGroup%" ] = HomeGroup, [ "%HomeList%" ] = table.concat( Home, ", " ), [ "%HomeListNewline%" ] = table.concat( Home, "\n" ) } )
				
				while true do
					
					local LastNewLine = #Msg <= DiscordCharacterLimit and DiscordCharacterLimit or Msg:sub( 1, DiscordCharacterLimit ):match( "^.*()[\n]" )
					
					local Ran, Error = pcall( HttpService.PostAsync, HttpService, Module.DiscordMessages[ a ].Url, HttpService:JSONEncode{ avatar_url = Module.HomeGroup.EmblemUrl, username = Module.PlaceAcronym .. " Raid Bot", content = Msg:sub( 1, LastNewLine and LastNewLine - 1 or DiscordCharacterLimit ) } )
					
					if not Ran then warn( Error ) end
					
					if #Msg <= ( LastNewLine or DiscordCharacterLimit ) then break end
					
					Msg = Msg:sub( ( LastNewLine or DiscordCharacterLimit ) + 1 )
					
				end
				
			end
			
		end
		
	end
	
end )

Module.Event_RaidEnded.Event:Connect( function ( RaidID, AwayGroupTable, Result, TeamLog, RaidStart ) 
	
	if not Module.Practice and Module.DiscordMessages and ( Module.AllowDiscordInStudio or not game:GetService("RunService"):IsStudio( ) ) then
		
		local EndTime = tick( )
		
		local AwayGroup = AwayGroupTable.Id and ( "[" .. AwayGroupTable.Name .. "](<https://www.roblox.com/groups/" .. AwayGroupTable.Id .. "/a#!/about>)" ) or AwayGroupTable.Name
		
		local HomeGroup = Module.HomeGroup and ( "[" .. Module.HomeGroup.Name .. "](<https://www.roblox.com/groups/" .. Module.HomeGroup.Id .. "/a#!/about>)" )
		
		local PlaceAcronym ="[" .. Module.PlaceAcronym .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local PlaceName = "[" .. Module.PlaceName .. "](<https://www.roblox.com/games/" .. game.PlaceId .. "/>)"
		
		local Home, Away = { }, { }
		
		local Plrs = Players:GetPlayers( )
		
		for a = 1, #Plrs do
			
			local Time = 0
			
			local TeamLog = TeamLog[ tostring( Plrs[ a ].UserId ) ]
			
			for b = 1, #TeamLog do
				
				if TeamLog[ b ][ 2 ] == Plrs[ a ].Team then
					
					Time = Time + ( TeamLog[ b + 1 ] or { EndTime } )[ 1 ] - TeamLog[ b ][ 1 ]
					
				end
				
			end
			
			TeamLog[ tostring( Plrs[ a ].UserId ) ] = nil
			
			if Module.HomeTeams[ Plrs[ a ].Team ] then
				
				Home[ #Home + 1 ] = "[" .. Plrs[ a ].Name .. "](<https://www.roblox.com/users/" .. Plrs[ a ].UserId .. "/profile>) - " .. Plrs[ a ]:GetRoleInGroup( Module.HomeGroup.Id ) .. ( Time == 0 and "" or " - helped for " .. FormatTime( Time ) )
				
			elseif Module.AwayTeams[ Plrs[ a ].Team ] then
				
				Away[ #Away + 1 ] = "[" .. Plrs[ a ].Name .. "](<https://www.roblox.com/users/" .. Plrs[ a ].UserId .. "/profile>)" .. ( AwayGroupTable.Id and ( " - " .. Plrs[ a ]:GetRoleInGroup( AwayGroupTable.Id ) ) or "" ) .. ( Time == 0 and "" or " - helped for " .. FormatTime( Time ) )
				
			end
			
		end
		
		for a, b in pairs( TeamLog ) do
			
			if not Players:GetPlayerByUserId( a ) then
				
				local Teams = { }
				
				local Max
				
				for c = 1, #b do
					
					Teams[ b[ c ] ] = Teams[ b[ c ] ] or { 0, b[ c ][ 2 ] }
					
					Teams[ b[ c ] ][ 1 ] = Teams[ b[ c ] ][ 1 ] + ( b[ c + 1 ] or { EndTime } )[ 1 ] - b[ c ][ 1 ]
					
					if not Max or Max[ 1 ] < Teams[ b[ c ] ][ 1 ] then
						
						Max = Teams[ b[ c ] ]
						
					end
					
				end
				
				if Max then
					
					if Module.HomeTeams[ Max[ 2 ] ] then
						
						local Role
						
						local Groups = GroupService:GetGroupsAsync( a )
						
						for c = 1, #Groups do
							
							if Groups[ c ].Id == Module.HomeGroup.Id then
								
								Role = Groups[ c ].Role
								
								break
								
							end
							
						end
						
						local Time = " - helped for " .. FormatTime( Max[ 1 ] )
						
						Home[ #Home + 1 ] = "[" .. Players:GetNameFromUserIdAsync( a ) .. "](<https://www.roblox.com/users/" .. a .. "/profile>) - " .. ( Role or "Guest" ) .. Time
						
					elseif Module.AwayTeams[ Max[ 2 ] ] then
						
						local Role
						
						if AwayGroupTable.Id then
							
							local Groups = GroupService:GetGroupsAsync( a )
							
							for c = 1, #Groups do
								
								if Groups[ c ].Id == AwayGroupTable.Id then
									
									Role = Groups[ c ].Role
									
									break
									
								end
								
							end
							
							Role = Role or "Guest"
							
						end
						
						local Time = " - helped for " .. FormatTime( Max[ 1 ] )
						
						Away[ #Away + 1 ] = "[" .. Players:GetNameFromUserIdAsync( a ) .. "](<https://www.roblox.com/users/" .. a .. "/profile>) " .. ( Role and ( " - " .. ( Role or "Guest" ) ) or "" ) .. Time
						
					end
					
				end
				
			end
			
		end
		
		if #Home == 0 then Home[ 1 ] = "None" end
		
		if #Away == 0 then Away[ 1 ] = "None" end
		
		local EmblemUrl = Result == "Won" and AwayGroupTable.EmblemUrl or Module.HomeGroup.EmblemUrl
		
		for a = 1, #Module.DiscordMessages do
			print( "disc message " .. a .. " out of " .. #Module.DiscordMessages )
			if Module.DiscordMessages[ a ][ Result ] then
				
				local Msg = Module.DiscordMessages[ a ][ Result ]:gsub( "%%%w*%%", { [ "%PlaceAcronym%" ] = PlaceAcronym, [ "%PlaceName%" ] = PlaceName, [ "%RaidID%" ] = RaidID, [ "%RaidTime%" ] = FormatTime( EndTime - RaidStart ), [ "%AwayGroup%" ] = AwayGroup, [ "%AwayList%" ] = table.concat( Away, ", " ), [ "%AwayListNewline%" ] = table.concat( Away, "\n" ), [ "%HomeGroup%" ] = HomeGroup, [ "%HomeList%" ] = table.concat( Home, ", " ), [ "%HomeListNewline%" ] = table.concat( Home, "\n" ) } )
				print( Msg )
				while true do
					
					local LastNewLine = #Msg <= DiscordCharacterLimit and DiscordCharacterLimit or Msg:sub( 1, DiscordCharacterLimit ):match( "^.*()[\n]" )
					
					local Ran, Error = pcall( HttpService.PostAsync, HttpService, Module.DiscordMessages[ a ].Url, HttpService:JSONEncode{ avatar_url = EmblemUrl, username = Module.PlaceAcronym .. " Raid Bot", content = Msg:sub( 1, LastNewLine and LastNewLine - 1 or DiscordCharacterLimit ) } )
					
					if not Ran then warn( Error ) end
					
					if #Msg <= ( LastNewLine or DiscordCharacterLimit ) then break end
					
					Msg = Msg:sub( ( LastNewLine or DiscordCharacterLimit ) + 1 )
					
				end
				print"Finished running message"
			end
			
		end
		
	end
	
end )

---------- VH

repeat wait( ) until _G.VH_AddExternalCmds

_G.VH_AddExternalCmds( function ( Main )
	
	VHMain = Main
	
	if Main.Config.ReservedFor then
		
		MaxPlayers = Players.MaxPlayers - ( Main.Config.ReservedSlots or 1 )
		
	end
	
	Main.Commands[ "ForceOfficial" ] = {
		
		Alias = { Main.TargetLib.AliasTypes.Toggle( 1, 6, "forceofficial" ) },
		
		Description = "Forces the raid official/unofficial",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = { { Func = Main.TargetLib.ArgTypes.Boolean, Default = Main.TargetLib.Defaults.Toggle, ToggleValue = function ( ) return Module.OfficialRaid.Value end }, Main.TargetLib.ArgTypes.Boolean },
		
		Callback = function ( self, Plr, Cmd, Args, NextCmds, Silent )
			
			if Module.OfficialRaid.Value == Args[ 1 ] then return false, "Already " .. ( Args[ 1 ] and "official" or "unofficial" ) end
			
			if Args[ 1 ] then
				
				Module.Forced = true
				
				Module.Practice = Args[ 2 ]
				
				Module.StartRaid( )
				
			else
				
				Module.EndRaid( "Forced" )
				
			end
			
			return true
			
		end
		
	}
	
	Main.Commands[ "Official" ] = {
		
		Alias = { "official" },
		
		Description = "Makes the raid official",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		ArgTypes = { Main.TargetLib.ArgTypes.Boolean },
		
		Callback = function ( self, Plr, Cmd, Args, NextCmds, Silent )
			
			if not Module.ManualStart then return false, "Raid will automatically start\nUse 'forceofficial/true' to force start the raid" end
			
			if Module.OfficialRaid.Value == true then return false, "Already official" end
			
			Module.Practice = Args[ 2 ]
			
			local Ran = Module.OfficialCheck( true )
			
			if Ran then
				
				return false, Ran
				
			end
			
			return true
			
		end
		
	}
	
end )

return Module
