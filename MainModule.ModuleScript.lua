local ReplicatedStorage, CollectionService = game:GetService( "ReplicatedStorage" ), game:GetService( "CollectionService" )

local Module = {
	
	WinTime = 60 * 25, -- 25 minutes holding all capturepoints to win the raid
	
	RaidLimit = 60 * 60 * 2.5, -- How long a raid can go before raiders lose, 2.5 hours
	
	HomeTeams = { }, -- Teams that can capture for the home group
	
	HomeRequired = 1, -- How many of the home teams are required for capturepoints to be taken
	
	AwayTeams = { }, -- Teams that can raid
	
	AwayRequired = 1, -- How many of the home teams are required for capturepoints to be taken
	
	EqualTeams = false, -- If true, raid will only be started if teams are equal
	
	LockTeams = false, -- If true, teams will be limited to the same size when people leave
	
	ManualStart = false, -- If true, raid can only be started by command
	
	AllowOvertime = true, -- If true, raid won't end once RaidLimit is reached until raiders don't own any required capture points
	
	GracePeriod = 15, -- Raiders won't be able to move when the raid starts for this period of time
	
	BanWhenWinOrLoss = false, -- Do raiders get banned when raid limit is reached or they win? ( Require V-Handle admin )
	
	ExtraTimeForCapture = 0, -- The amount of extra time added onto the raid timer when a point is captured/a payload reaches its end
	
	ExtraTimeForCheckpoint = 0, -- The amount of extra time added onto the raid timer when a payload reaches a checkpoint
	
	HomeCaptureSpeed = 1,
	
	AwayCaptureSpeed = 1,
	
	RollbackSpeed = 1,
	
	WinSpeed = 1,
	
	-- NO TOUCHY --
	
	CapturePoints = { },
	
	RequiredCapturePoints = { },
	
	WinTimer = 0,
	
	Event_RaidStarted = script.RaidStarted,
	
	Event_RaidLost = script.RaidLost,
	
	Event_RaidEnded = script.RaidEnded,
	
	Event_RaidWon = script.RaidWon,
	
	Event_WinChanged = script.WinChanged
	
}

Module.OfficialRaid = Instance.new( "BoolValue" )
	
Module.OfficialRaid.Name = "OfficialRaid"

Module.OfficialRaid.Parent = script

_G.OfficialRaid = Module.OfficialRaid

local RaidTimerEvent = Instance.new( "RemoteEvent" )

RaidTimerEvent.Name = "RaidTimerEvent"

RaidTimerEvent.OnServerEvent:Connect( function ( Plr )
	
	if Module.RaidStart then
		
		RaidTimerEvent:FireClient( Plr, Module.RaidStart, Module.RaidLimit )
		
	end
	
end )

RaidTimerEvent.Parent = game.ReplicatedStorage

local function HandleGrace( Plr, Cur )
	
	local Event, Event3, Event4
	
	if tableHasValue( Module.AwayTeams, Plr.Team ) then
		
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
		
		if tableHasValue( Module.AwayTeams, Plr.Team ) then
			
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

function Module.StartRaid( )
	
	if Module.LockTeams then
		
		Module.HomeMax, Module.AwayMax = Module.CountTeams( )
		
	end
	
	local Cur = tick( )
	
	Module.RaidStart = Cur
	
	RaidTimerEvent:FireAllClients( Module.RaidStart, Module.RaidLimit )
	
	Module.OfficialRaid.Value = true
	
	if Module.GracePeriod > 0 then
		
		local Event = game.Players.PlayerAdded:Connect( function ( Plr )
			
			if tableHasValue( Module.AwayTeams, Plr.Team ) then
				
				HandleGrace( Plr )
				
			end
			
		end )
		
		delay( Module.GracePeriod, function ( ) Event:Disconnect( ) end )
		
	end
	
	local Plrs = game.Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		if Module.GracePeriod > 0 then
			
			HandleGrace( Plrs[ a ], Cur )
			
		end
		
		if tableHasValue( Module.AwayTeams, Plrs[ a ].Team ) then
			
			Plrs[ a ]:LoadCharacter( )
			
			wait( 0.1 )
			
		end
		
	end
	
	for a = 1, #Module.CapturePoints do
		
		Module.CapturePoints[ a ].Active = true
		
	end
	
	Module.Event_RaidStarted:Fire( )
	
end

function Module.EndRaid( )
	
	Module.OfficialRaid.Value = false
	
	Module.Event_RaidEnded:Fire( )
	
	Module.ResetAll( )
	
end

function Module.RaidLoss( )
	
	Module.OfficialRaid.Value = false
	
	Module.Event_RaidLost:Fire( )
	
	Module.ResetAll( )
	
	wait( 5 )
	
	local Plrs = game.Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		if tableHasValue( Module.AwayTeams, Plrs[ a ].Team ) then
			
			if Module.BanWhenWinOrLoss and ReplicatedStorage:FindFirstChild( "VHMain" ) and ReplicatedStorage.VHMain:FindFirstChild( "Events" ) and ReplicatedStorage.VHMain:FindFirstChild( "RunServerCommand" ) then
				
				ReplicatedStorage.VHMain.RunServerCommand:Fire( "permban/" .. Plrs[ a ].UserId .. "/30m" )
				
			else
				
				Plrs[ a ]:Kick( )
				
			end
			
		end
		
	end
	
end

function Module.RaidWon( Team )
	
	Module.OfficialRaid.Value = false
	
	Module.Event_RaidWon:Fire( Team )
	
	Module.ResetAll( )
	
	wait( 20 )
	
	local Plrs = game.Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		if tableHasValue( Module.AwayTeams, Plrs[ a ].Team ) then
			
			if Module.BanWhenWinOrLoss and ReplicatedStorage:FindFirstChild( "VHMain" ) and ReplicatedStorage.VHMain:FindFirstChild( "Events" ) and ReplicatedStorage.VHMain:FindFirstChild( "RunServerCommand" ) then
				
				ReplicatedStorage.VHMain.RunServerCommand:Fire( "permban/" .. Plrs[ a ].UserId .. "/30m" )
				
			else
				
				Plrs[ a ]:Kick( )
				
			end
			
		end
		
	end
	
end

function Module.ResetAll( )
	
	Module.Forced = nil
	
	Module.RaidStart = nil
	
	RaidTimerEvent:FireAllClients( )
	
	Module.OfficialRaid.Value = false
	
	for a = 1, #Module.CapturePoints do
		
		Module.CapturePoints[ a ]:Reset( )
		
	end
	
	Module.WinTimer = 0
	
end

function tableHasValue( Table, Value )
	
	for a = 1, #Table do
		
		if Table[ a ] == Value then
			
			return 1
			
		end
		
	end
	
end

function Module.IsHomeTeam( Team )
	
	return tableHasValue( Module.HomeTeams, Team )
	
end

function Module.IsAwayTeam( Team )
	
	return tableHasValue( Module.AwayTeams, Team )
	
end

function Module.SetWinTimer( Val )
	
	if Module.WinTimer ~= Val then
		
		local Old = Module.WinTimer
		
		Module.WinTimer = Val
		
		Module.Event_WinChanged:Fire( Old )
		
	end
	
end

function Module.CountTeams( )
	
	local Home, Away = 0, 0
	
	local Plrs = game.Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		Home = Home + ( Module.IsHomeTeam( Plrs[ a ].Team, Plrs[ a ] ) or 0 )
		
		Away = Away + ( Module.IsAwayTeam( Plrs[ a ].Team, Plrs[ a ] ) or 0 )
		
	end
	
	return Home, Away
	
end

function Module.RaidChanged( )
	
	local Home, Away = Module.CountTeams( )
	
	if Module.OfficialRaid.Value then
		
		if Away == 0 and not Module.Forced then
			
			Module.EndRaid( )
			
		end
		
	else
		
		if Home < Module.HomeRequired then
			
			return "Must be at least " .. Module.HomeRequired .. " players on the home teams"
			
		end
		
		if Away < Module.AwayRequired or Away == 0 then
			
			return "Must be at least " .. math.max( Module.AwayRequired, 1 ) .. " players on the away teams"
			
		end
		
		if Module.EqualTeams and ( Home ~= Away ) then
			
			return "Teams must be equal to start"
			
		end
		
		Module.StartRaid( )
		
	end
	
end

local function FormatTime( Time )
	
	return ( "%.2d:%.2d:%.2d" ):format( Time / ( 60 * 60 ), Time / 60 % 60, Time % 60 )
	
end

local function SetFlagMessages( Msg )
	
	for a = 1, #Module.CapturePoints do
		
		local BrickTimer = Module.CapturePoints[ a ].Model:FindFirstChild( "BrickTimer", true )
		
		if BrickTimer then
			
			BrickTimer:GetChildren( )[ 1 ].Name = Msg
			
		end
		
	end
	
end

function Module.OldFlagCompat( Flag )
	
	local Message
	
	Module.Event_RaidStarted.Event:Connect( function ( )
		
		if Message then Message:Destroy( ) end
		
		Message = Instance.new( "Message", workspace )
		
		Message.Text = "A raid has officialy started"
		
		game.Debris:AddItem( Message, 5 )
		
		SetFlagMessages( "Raiders do not own the main flag" )
		
	end )
	
	Module.Event_RaidEnded.Event:Connect( function ( )
		
		if Message then Message:Destroy( ) end
		
		Message = Instance.new( "Message", workspace )
		
		Message.Text = "Raiders have left, raid over!"
		
		game.Debris:AddItem( Message, 5 )
		
		SetFlagMessages( "No raid in progress" )
		
	end )
	
	Module.Event_RaidLost.Event:Connect( function ( )
		
		if Message then Message:Destroy( ) end
		
		Message = Instance.new( "Message", workspace )
		
		Message.Text = "Time limit for the raid has been reached! Raiders lose!"
		
		game.Debris:AddItem( Message, 5 )
		
		SetFlagMessages( "No raid in progress" )
		
	end )
	
	Module.Event_RaidWon.Event:Connect( function ( Team )
		
		local Message = Instance.new( "Message", workspace )
		
		local Id = os.time( ) + ( math.random( ) / 10 )
		
		Message.Text = Team.Name .. " has won! ID: " .. Id .. " - Raiders get kicked in 20s"
		
		game.Debris:AddItem( Message, 20 )
		
		SetFlagMessages( "Raiders do not own the main flag" )
		
		for a = 19, 0, -1 do
			
			wait( 1 )
			
			Message.Text = Team .. " has won! ID: " .. Id .. " - Raiders get kicked in " .. a .. "s"
			
		end
		
	end )
	
	Module.Event_WinChanged.Event:Connect( function ( Old )
		
		SetFlagMessages( Module.WinTimer == 0 and "Raiders do not own the main flag" or ( Module.AwayTeams[ 1 ].Name .. " wins in " .. FormatTime( math.floor( Module.WinTime - Module.WinTimer ) ) ) )
		
	end )
	
	SetFlagMessages( "No raid in progress" )
	
end

function PlayerAdded( Plr )
	
	if Module.LockTeams and Module.OfficialRaid.Value then
		
		local Home, Away = Module.CountTeams( )
		
		if ( Module.IsAwayTeam( Plr.Team ) and Away > Module.AwayMax ) or ( Module.IsHomeTeam( Plr.Team ) and Home > Module.HomeMax ) then
			
			Plr:Kick( "Team is full" )
			
			return
			
		end
		
	end
	
	if not Module.ManualStart then
		
		Module.RaidChanged( )
		
	end
	
	local Team = Plr.Team
	
	Plr:GetPropertyChangedSignal( "Team" ):Connect( function ( )
		
		if Module.LockTeams and Module.OfficialRaid.Value then
			
			local Home, Away = Module.CountTeams( )
			
			if ( Module.IsAwayTeam( Plr.Team ) and Away > Module.AwayMax ) or ( Module.IsHomeTeam( Plr.Team ) and Home > Module.HomeMax ) then
				
				Plr.Team = Team
				
				return
				
			end
			
		end
		
		Team = Plr.Team
		
		if not Module.ManualStart then
			
			Module.RaidChanged( )
			
		end
		
	end )
	
end

game.Players.PlayerRemoving:Connect( function ( Plr )
	
	Module.RaidChanged( )
	
end )

game.Players.PlayerAdded:Connect( PlayerAdded )

local Plrs = game.Players:GetPlayers( )

for a = 1, #Plrs do
	
	PlayerAdded( Plrs[ a ] )
	
end

coroutine.wrap( function ( )
	
	while wait( 1 ) do
		
		if Module.AllowOvertime == false and Module.RaidStart and Module.RaidStart + Module.RaidLimit <= tick( ) then
			
			Module.RaidLoss( )
			
		end
		
		for a = 1, #Module.CapturePoints do
			
			local CapturePoint = Module.CapturePoints[ a ]
			
			local Active = CapturePoint.Active
			
			if not CapturePoint.Bidirectional and CapturePoint.CaptureTimer == CapturePoint.CaptureTime then
				
				Active = false
				
			end
			
			if Active then
				
				local Enemies, Allies = Module.GetTeamsNear( CapturePoint.MainPart.Position, CapturePoint.Dist )
				
				if CapturePoint.Required then
					
					for a = 1, #CapturePoint.Required do
						
						if CapturePoint.Required[ a ].CurOwner ~= Module.AwayTeams[ 1 ] or CapturePoint.Required[ a ].CaptureTimer ~= CapturePoint.Required[ a ].CaptureTime / 2 then
							
							Enemies = 0
							
						end
						
					end
					
				end
				
				local CaptureSpeed = 0
				
				if Allies > Enemies then
					
					CaptureSpeed = ( Allies - Enemies ) ^ 0.5 * ( CapturePoint.HomeCaptureSpeed or Module.HomeCaptureSpeed )
					
					CapturePoint.CapturingTeam = Module.HomeTeams[ 1 ]
					
					if CapturePoint.Bidirectional then
						
						if Module.HomeTeams[ 1 ] ~= CapturePoint.CurOwner then
							
							CapturePoint.BeingCaptured = true
							
						elseif CapturePoint.Down then
							
							CapturePoint.BeingCaptured = nil
							
						end
					
					end
					
				elseif Enemies > Allies then
					
					CaptureSpeed = ( Enemies - Allies ) ^ 0.5 * ( CapturePoint.AwayCaptureSpeed or Module.AwayCaptureSpeed )
					
					CapturePoint.CapturingTeam = Module.AwayTeams[ 1 ]
					
					if CapturePoint.Bidirectional then
						
						if Module.AwayTeams[ 1 ] ~= CapturePoint.CurOwner then
							
							CapturePoint.BeingCaptured = true
							
						elseif CapturePoint.Down then
							
							CapturePoint.BeingCaptured = nil
							
						end
						
					end
					
				end
				
				if CaptureSpeed ~= 0 then
					
					if CapturePoint.Bidirectional then
						
						if CapturePoint.BeingCaptured then
							-- Raider is near, capture
							if CapturePoint.CaptureTimer ~= 0 and CapturePoint.CurOwner ~= CapturePoint.CapturingTeam then
								
								CapturePoint:SetCaptureTimer( math.max( 0, CapturePoint.CaptureTimer - CaptureSpeed ) )
								
								CapturePoint.Down = true
								
							else
								-- Raider has held it for long enough, switch owner
								if CapturePoint.CaptureTimer == 0 and CapturePoint.Down then
									
									CapturePoint.CurOwner = CapturePoint.CapturingTeam
									
									CapturePoint.Down = false
									
									CapturePoint:SetCaptureTimer( 0 )
									
								else
									-- Raider is now rebuilding it
									if CapturePoint.CaptureTimer ~= ( CapturePoint.CaptureTime / 2 ) then
										
										CapturePoint:SetCaptureTimer( math.min( CapturePoint.CaptureTime / 2, CapturePoint.CaptureTimer + CaptureSpeed ) )
										
									else
										-- Raider has rebuilt it
										CapturePoint.BeingCaptured = nil
										
										CapturePoint:Captured( CapturePoint.CurOwner )
										
									end
									
								end
								
							end
							-- Owner is rebuilding
						elseif CapturePoint.CaptureTimer ~= ( CapturePoint.CaptureTime / 2 ) then
							
							CapturePoint:SetCaptureTimer( math.min( CapturePoint.CaptureTime / 2, CapturePoint.CaptureTimer + CaptureSpeed ) )
							
						end
						
					elseif CapturePoint.CapturingTeam ~= ( CapturePoint.AwayOwned and Module.AwayTeams[ 1 ] or Module.HomeTeams[ 1 ] ) then
						
						CapturePoint:SetCaptureTimer( math.min( CapturePoint.CaptureTimer + CaptureSpeed, CapturePoint.CaptureTime ) )
						
						if CapturePoint.CaptureTimer >= CapturePoint.NextCheckpoint then
							
							CapturePoint:CheckpointReached( CapturePoint.NextCheckpoint )
							
							CapturePoint.Checkpoint = CapturePoint.NextCheckpoint
							
							CapturePoint.NextCheckpoint = CapturePoint:GetNextCheckpoint( )
							
						end
						
					elseif CapturePoint.CaptureTimer ~= ( CapturePoint.Checkpoint or 0 ) then
						
						CapturePoint:SetCaptureTimer( math.max( CapturePoint.CaptureTimer - CaptureSpeed, CapturePoint.Checkpoint or 0 ) )
						
					end
					
				end
				
			end
			
		end
		
		local AllOwned = true
		
		local AllFullyOwned, Pause
		
		local Required = ( #Module.RequiredCapturePoints == 0 and #Module.CapturePoints == 1 ) and Module.CapturePoints or Module.RequiredCapturePoints
		
		for a = 1, #Required do
			
			local b = Required[ a ]
			
			if b.Active then
				
				if b.Bidirectional then
					
					if b.CurOwner == Module.HomeTeams[ 1 ] then
						
						if b.CurOwner ~= b.CapturingTeam or b.CaptureTimer ~= b.CaptureTime / 2 then
							
							AllFullyOwned = false
							
						elseif AllFullyOwned == nil then
							
							AllFullyOwned = true
							
						end
						
					else
						
						if b.CurOwner == b.CapturingTeam and b.CaptureTimer == b.CaptureTime / 2 then
							
							AllOwned = false
							
						else
							
							Pause = true
							
						end
					
					end
					
				else
					
					if b.AwayOwned then
						
						if b.CaptureTimer == b.CaptureTime then
							
							Module.RaidLoss( )
							
							AllFullyOwned = false
							
						elseif AllFullyOwned == nil then
							
							AllFullyOwned = true
							
						end
						
					elseif b.CaptureTimer == b.CaptureTime then
					
						AllFullyOwned = false
						
						AllOwned = false
						
					elseif AllFullyOwned == nil then
						
						AllFullyOwned = true
						
					end
					
				end
				
			end
			
		end
		
		if not Pause or Module.RollbackWithPartialCap or AllFullyOwned then
			
			if AllOwned then
				
				if Module.RaidStart and Module.RaidStart + Module.RaidLimit <= tick( ) then
					
					Module.RaidLoss( )
					
				end
				
				if Module.WinTimer < Module.WinTime and Module.WinTimer > 0 then
					
					-- Friendly owns it
					if Module.RollbackSpeed then
						
						Module.SetWinTimer( math.max( 0, Module.WinTimer - Module.RollbackSpeed ) )
						
					elseif AllFullyOwned then
						
						Module.SetWinTimer( 0 )
						
					end
					
				end
				
			else
				-- Enemy owns it
				Module.SetWinTimer( Module.WinTimer + Module.WinSpeed )
				
				if Module.WinTimer >= Module.WinTime then
					
					Module.RaidWon( Module.AwayTeams[ 1 ] )
					
				end
				
			end
		
		end
		
	end
	
end )( )

function Module.GetTeamsNear( Point, Dist )
	
	local Away, Home = 0, 0
	
	local Plrs = game.Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		local b = Plrs[ a ]
		
		if b.Character and b.Character:FindFirstChild( "Humanoid" ) and b.Character.Humanoid:GetState( ) ~= Enum.HumanoidStateType.Dead and b:DistanceFromCharacter( Point ) < Dist then
			
			if Module.IsAwayTeam( Plrs[ a ].Team, Plrs[ a ] ) then
				
				Away = Away + 1
				
			elseif Module.IsHomeTeam( Plrs[ a ].Team, Plrs[ a ] ) then
				
				Home = Home + 1
				
			end
			
		end
		
	end
	
	return Away, Home
	
end

function Module.SetSpawns( SpawnClones, Model, Teams )
	
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
				
				if Teams == Module.HomeTeams then
					
					Kids[ a ].Enabled = true
					
				else
					
					Kids[ a ].Enabled = false
					
				end
				
			elseif CollectionService:HasTag( Kids[ a ], "AwaySpawn" ) then
				
				if Teams == Module.AwayTeams then
					
					Kids[ a ].Enabled = true
					
				else
					
					Kids[ a ].Enabled = false
					
				end
				
			end
			
			for b = 1, #Teams do
				
				if b == 1 then
					
					Kids[ a ].TeamColor = Teams[ b ].TeamColor
					
					Kids[ a ].BrickColor = Teams[ b ].TeamColor
					
				elseif Kids[ a ].Enabled then
					
					local Clone = Kids[ a ]:Clone( )
					
					SpawnClones = SpawnClones or { }
					
					SpawnClones[ #SpawnClones + 1 ] = Clone
					
					Clone.Transparency = 1
					
					Clone.CanCollide = false
					
					Clone:ClearAllChildren( )
					
					Clone.TeamColor = Teams[ b ].TeamColor
					
					Clone.BrickColor = Teams[ b ].TeamColor
					
					Clone.Parent = Kids[ a ]
					
				end
				
			end
			
		end
		
	end
	
end

local function UpdateFlag( CapturePoint )
	
	if CapturePoint.Model:FindFirstChild( "Smoke", true ) then
		
		CapturePoint.Model:FindFirstChild( "Smoke", true ).Color = CapturePoint.CurOwner.TeamColor.Color
		
	end
	
	CapturePoint.Model.Naming:GetChildren( )[ 1 ].Name = "Owned by " .. CapturePoint.CurOwner.Name
	
	local Hint = Instance.new( "Hint", workspace )
	
	Hint.Text = "The flag at the " .. CapturePoint.Name .. " is now owned by " .. CapturePoint.CurOwner.Name
	
	game.Debris:AddItem( Hint, 5 )
	
end

Module.BidirectionalPointMetadata = {
	
	Bidirectional = true,
	
	Reset = function ( self )
		
		self.Active = nil
		
		self.CurOwner = self.StartOwner or Module.HomeTeams[ 1 ]
	
		self.CapturingTeam = self.CurOwner
		
		self:SetCaptureTimer( self.CaptureTime / 2 )
		
		self:Captured( )
		
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
	
	SetCaptureTimer = function ( self, Val )
		
		self.Event_CaptureChanged:Fire( Val )
		
		self.CaptureTimer = Val
		
		return self
		
	end,
	
	Captured = function ( self, Team )
		
		self.SpawnClones = Module.SetSpawns( self.SpawnClones, self.Model, Module.IsHomeTeam( Team ) and Module.HomeTeams or Module.AwayTeams )
		
		if Module.RaidStart then
			
			local RaidStart = Module.RaidStart
			
			Module.RaidStart = Module.RaidStart + ( self.ExtraTimeForCapture or Module.ExtraTimeForCapture )
			
			if RaidStart ~= Module.RaidStart then
				
				RaidTimerEvent:FireAllClients( Module.RaidStart, Module.RaidLimit )
				
			end
			
		end
		
		self.Event_Captured:Fire( Team )
		
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
				
				a.BrickColor = self.CurOwner.TeamColor
				
			end
			
			if self.Model:FindFirstChild( "Smoke", true ) then
				
				self.Model:FindFirstChild( "Smoke", true ).Color = self.CurOwner.TeamColor.Color
				
			end
			
			if Val == self.CaptureTime / 2 then
				
				self.Model.Naming:GetChildren( )[ 1 ].Name = "Owned by " .. self.CurOwner.Name
			
			elseif self.CapturingTeam == self.CurOwner then
				
				self.Model.Naming:GetChildren( )[ 1 ].Name = self.CurOwner.Name .. " now owns " .. math.ceil( ( Val / ( self.CaptureTime / 2 ) ) * 100 ) .. "% of the location"
				
			else
				
				self.Model.Naming:GetChildren( )[ 1 ].Name = self.CurOwner.Name .. " owns " .. math.ceil( ( Val / ( self.CaptureTime / 2 ) ) * 100 ) .. "% of the location"
				
			end
			
			for a, b in pairs( StartCFs ) do
				
				game.TweenService:Create( a, TweenInfo.new( 1, Enum.EasingStyle.Quint ), { CFrame = ( b - Vector3.new( 0, Dist * ( 1 - ( Val / ( self.CaptureTime / 2 ) ) ) ) ) } ):Play( )
				
			end
			
		end )
		
		self.Event_Captured.Event:Connect( function ( )
			
			UpdateFlag( self )
			
		end )
			
		UpdateFlag( self )
		
		return self
		
	end
	
}

-- Table requires Name = String, Dist = Number, CaptureTime = Number, MainPart = Instance, Model = Instance
function Module.BidirectionalPoint( CapturePoint )
	
	setmetatable( CapturePoint, { __index = Module.BidirectionalPointMetadata } )
	
	CapturePoint.Event_Captured = Instance.new( "BindableEvent" )
	
	CapturePoint.Event_CaptureChanged = Instance.new( "BindableEvent" )
	
	Module.CapturePoints[ #Module.CapturePoints + 1 ] = CapturePoint
	
	CapturePoint:Reset( )
	
	return CapturePoint
	
end

Module.NewCapturePoint = Module.BidirectionalPoint

Module.UnidirectionalPointMetadata = {
	
	Reset = function ( self )
		
		self.Active = nil
		
		self.Checkpoint = nil
		
		self.NextCheckpoint = self:GetNextCheckpoint( )
		
		self.CapturingTeam = self.AwayOwned and Module.AwayTeams[ 1 ] or Module.HomeTeams[ 1 ]
		
		self:SetCaptureTimer( 0 )
		
		self:CheckpointReached( )
		
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
	
	SetCaptureTimer = function ( self, Val )
		
		self.Event_CaptureChanged:Fire( Val )
		
		self.CaptureTimer = Val
		
		return self
		
	end,
	
	GetNextCheckpoint = function ( self )
		
		local Next = self.CaptureTime
		
		if self.Checkpoints then
			
			for a, b in pairs( self.Checkpoints ) do
				
				if a > ( self.Checkpoint or 0 ) and a < Next then
					
					Next = a
					
				end
				
			end
			
		end
		
		return Next
		
	end,
	
	CheckpointReached = function ( self, Checkpoint )
		
		if self.Checkpoints then
			
			for a, b in pairs( self.Checkpoints )do
				
				if a <= ( Checkpoint or 0 ) then
					
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
			
		end
		
		if Module.RaidStart then
			
			local RaidStart = Module.RaidStart
			
			if Checkpoint == self.CaptureTime then
				
				Module.RaidStart = Module.RaidStart + ( self.ExtraTimeForCapture or Module.ExtraTimeForCapture )
				
			else
				
				Module.RaidStart = Module.RaidStart + ( self.ExtraTimeForCheckpoint or Module.ExtraTimeForCheckpoint )
				
			end
			
			if RaidStart ~= Module.RaidStart then
				
				RaidTimerEvent:FireAllClients( Module.RaidStart, Module.RaidLimit )
				
			end
			
		end
		
		self.Event_Checkpoint_Reached:Fire( Checkpoint )
		
	end
	
}

-- Table requires Name = String, Dist = Number, CaptureTime = Number, MainPart = Instance, Model = Instance
function Module.UnidirectionalPoint( CapturePoint )
	
	setmetatable( CapturePoint, { __index = Module.UnidirectionalPointMetadata } )
	
	CapturePoint.Event_Checkpoint_Reached = Instance.new( "BindableEvent" )
	
	CapturePoint.Event_CaptureChanged = Instance.new( "BindableEvent" )
	
	Module.CapturePoints[ #Module.CapturePoints + 1 ] = CapturePoint
	
	CapturePoint:Reset( )
	
	return CapturePoint
	
end

---------- VH

repeat wait( ) until _G.VH_AddExternalCmds

_G.VH_AddExternalCmds( function ( Main )
	
	Main.Commands[ "ForceOfficial" ] = {
		
		Alias = { Main.TargetLib.AliasTypes.Toggle( 1, 6, "forceofficial" ) },
		
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
				
				Module.EndRaid( )
				
			end
			
			return true
			
		end
		
	}
	
	Main.Commands[ "Official" ] = {
		
		Alias = { "official" },
		
		Description = "Makes the raid official",
		
		CanRun = "$moderator, $debugger",
		
		Category = "raid",
		
		Callback = function ( self, Plr, Cmd, Args, NextCmds, Silent )
			
			if not Module.ManualStart then return false, "Raid will automatically start\nUse 'forceofficial/true' to force start the raid" end
			
			if Module.OfficialRaid.Value == true then return false, "Already official" end
			
			local Ran = Module.RaidChanged( )
			
			if Ran then
				
				return false, Ran
				
			end
			
			return true
			
		end
		
	}
	
end )

return Module