local Module = { } -- NO TOUCHY

Module.WinTime = 60 * 25 -- 25 minutes holding all terminals to win the raid

Module.HomeTeams = { } -- teams that can capture for the home group

Module.HomeRequired = 1 -- How many of the home teams are required for terminals to be taken

Module.AwayTeams = { } -- teams that can raid

Module.AwayRequired = 1 -- How many of the home teams are required for terminals to be taken

Module.RaidLimit = 60 * 60 * 2.5 -- How long a raid can go before raiders lose, 2.5 hours

Module.GracePeriod = 15

Module.BanWhenWinOrLoss = false -- Do raiders get banned when raid limit is reached or they win? ( Require Partixels admin )

Module.RollbackSpeed = 1

Module.WinSpeed = 1

-- NO TOUCHY --

Module.Terminals = { } -- NO TOUCHY

Module.RequiredTerminals = { } -- NO TOUCHY

Module.WinTimer = 0 -- NO TOUCHY

Module.LastCap = nil

Module.OfficialRaid = Instance.new( "BoolValue", script )

Module.OfficialRaid.Name = "OfficialRaid"

Module.Event_RaidStarted = script.RaidStarted

Module.Event_RaidLost = script.RaidLost

Module.Event_RaidEnded = script.RaidEnded

Module.Event_RaidWon = script.RaidWon

Module.Event_WinChanged = script.WinChanged

Module.Event_Term_Captured = script.Term_Captured

Module.Event_Term_CaptureChanged = script.Term_CaptureChanged

_G.OfficialRaid = Module.OfficialRaid

local ReplicatedStorage = game:GetService( "ReplicatedStorage" )

local RaidTimerEvent = Instance.new( "RemoteEvent" )

RaidTimerEvent.Name = "RaidTimerEvent"

RaidTimerEvent.OnServerEvent:Connect( function ( Plr )
	
	if Module.LastCap then
		
		RaidTimerEvent:FireClient( Plr, Module.LastCap, Module.RaidLimit )
		
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
	
	local Cur = tick( )
	
	Module.LastCap = Cur
	
	RaidTimerEvent:FireAllClients( Module.LastCap, Module.RaidLimit )
	
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
	
	for a = 1, #Module.Terminals do
		
		Module.Terminals[ a ].Active = true
		
	end
	
	Module.Event_RaidStarted:Fire( Module )
	
end

function Module.EndRaid( )
	
	Module.OfficialRaid.Value = false
	
	Module.Event_RaidEnded:Fire( Module )
	
	Module.ResetAll( )
	
end

function Module.RaidLoss( )
	
	Module.OfficialRaid.Value = false
	
	Module.Event_RaidLost:Fire( Module )
	
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

function Module.Won( Team )
	
	Module.OfficialRaid.Value = false
	
	Module.Event_RaidWon:Fire( Module, Team )
	
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
	
	Module.LastCap = nil
	
	RaidTimerEvent:FireAllClients( )
	
	Module.OfficialRaid.Value = false
	
	for a = 1, #Module.Terminals do
		
		Module.Term_Reset( Module.Terminals[ a ] )
		
	end
	
	Module.WinTimer = 0
	
end

function tableHasValue( Table, Value )
	
	for a = 1, #Table do
		
		if Table[ a ] == Value then
			
			return true
			
		end
		
	end
	
end

function Module.IsHomeTeam( Team, Plr )
	
	return tableHasValue( Module.HomeTeams, Team ) and 1
	
end

function Module.IsAwayTeam( Team, Plr )
	
	return tableHasValue( Module.AwayTeams, Team ) and 1
	
end

function Module.SetWinTimer( Val )
	
	if Module.WinTimer ~= Val then
		
		local Old = Module.WinTimer
		
		Module.WinTimer = Val
		
		Module.Event_WinChanged:Fire( Module, Old )
		
	end
	
end

function Module.CountTeams( )
	
	local Home, Away = 0, 0
	
	local Plrs = game.Players:GetPlayers( )
	
	for a = 1, #Plrs do
		
		Home = Home + ( Module.IsHomeTeam( Plrs[ a ].Team, Plrs[ a ] ) or 0 )
		
		Away = Away + ( Module.IsAwayTeam( Plrs[ a ].Team, Plrs[ a ] ) or 0 )
		
	end
	
	if not Module.OfficialRaid.Value then
		
		if Home >= Module.HomeRequired and Away >= Module.AwayRequired and Away ~= 0 then
			
			Module.StartRaid( )
			
		end
		
	else
		
		if Away < Module.AwayRequired or Away <= 0 then
			
			if not Module.Forced then
				
				Module.EndRaid( )
				
			end
			
		end
		
	end
	
end

local function FormatTime( Time )
	
	return ( "%.2d:%.2d:%.2d" ):format( Time / ( 60 * 60 ), Time / 60 % 60, Time % 60 )
	
end

local function SetFlagMessages( Msg )
	
	for a = 1, #Module.Terminals do
		
		local BrickTimer = Module.Terminals[ a ].Model:FindFirstChild( "BrickTimer", true )
		
		if BrickTimer then
			
			BrickTimer:GetChildren( )[ 1 ].Name = Msg
			
		end
		
	end
	
end

function Module.OldFlagCompat( Flag )
	
	local Message
	
	Module.Event_RaidStarted.Event:Connect( function ( Mod )
		
		if Message then Message:Destroy( ) end
		
		Message = Instance.new( "Message", workspace )
		
		Message.Text = "A raid has officialy started"
		
		game.Debris:AddItem( Message, 5 )
		
		SetFlagMessages( "Raiders do not own the main flag" )
		
	end )
	
	Module.Event_RaidEnded.Event:Connect( function ( Mod )
		
		if Message then Message:Destroy( ) end
		
		Message = Instance.new( "Message", workspace )
		
		Message.Text = "Raiders have left, raid over!"
		
		game.Debris:AddItem( Message, 5 )
		
		SetFlagMessages( "No raid in progress" )
		
	end )
	
	Module.Event_RaidLost.Event:Connect( function ( Mod )
		
		if Message then Message:Destroy( ) end
		
		Message = Instance.new( "Message", workspace )
		
		Message.Text = "Time limit for the raid has been reached! Raiders lose!"
		
		game.Debris:AddItem( Message, 5 )
		
		SetFlagMessages( "No raid in progress" )
		
	end )
	
	Module.Event_RaidWon.Event:Connect( function ( Mod, Team )
		
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
	
	Module.Event_WinChanged.Event:Connect( function ( Mod, Old )
		
		SetFlagMessages( Mod.WinTimer == 0 and "Raiders do not own the main flag" or ( Mod.AwayTeams[ 1 ].Name .. " wins in " .. FormatTime( math.floor( Mod.WinTime - Mod.WinTimer ) ) ) )
		
	end )
	
	SetFlagMessages( "No raid in progress" )
	
end

game.Players.PlayerAdded:Connect( function ( Plr )
	
	Module.CountTeams( )
	
	Plr.Changed:Connect( function ( ) Module.CountTeams( ) end )
	
end )

local Plrs = game.Players:GetPlayers( )

for a = 1, #Plrs do
	
	Module.CountTeams( )
	
	Plrs[ a ].Changed:Connect( function ( ) Module.CountTeams( ) end )
	
end

coroutine.wrap( function ( )
	
	while wait( 1 ) do
		
		do
			
			for a = 1, #Module.Terminals do
				
				local Term = Module.Terminals[ a ]
				
				if Term.Active then
					
					local Enemies, Allies = Module.GetTeamsNear( Term.MainPart.Position, Term.Dist )
					
					for a = 1, #Term.Required do
						
						if Term.Required[ a ].CurOwner ~= Module.AwayTeams[ 1 ] or Term.Required[ a ].CaptureTimer ~= Term.Required[ a ].CaptureTime / 2 then
							
							Enemies = 0
							
						end
						
					end
					
					if Allies > Enemies then
						
						Term.CapturingTeam = Module.HomeTeams[ 1 ]
						
						Term.CaptureSpeed = math.sqrt( Allies - Enemies )
						
						if not tableHasValue( Module.HomeTeams, Term.CurOwner ) then
							
							Term.BeingCaptured = true
							
						elseif Term.Down then
							
							Term.BeingCaptured = nil
							
						end
						
					elseif Enemies > Allies then
						
						Term.CapturingTeam = Module.AwayTeams[ 1 ]
						
						Term.CaptureSpeed = math.sqrt( Enemies - Allies )
						
						if not tableHasValue( Module.AwayTeams, Term.CurOwner ) then
							
							Term.BeingCaptured = true
							
						elseif Term.Down then
							
							Term.BeingCaptured = nil
							
						end
						
					else
						
						Term.CaptureSpeed = 0
						
					end
					-- Being captured
					if Term.BeingCaptured then
						-- Raider is near, capture
						if Term.CaptureTimer ~= 0 and Term.CurOwner ~= Term.CapturingTeam then
							
							Module.Term_SetCaptureTimer( Term, math.max( 0, Term.CaptureTimer - Term.CaptureSpeed ) )
							
							Term.Down = true
							
						else
							-- Raider has held it for long enough, switch owner
							if Term.CaptureTimer == 0 and Term.Down then
								
								Term.CurOwner = Term.CapturingTeam
								
								Term.Down = false
								
								Module.Term_SetCaptureTimer( Term, 0 )
								
							else
								-- Raider is now rebuilding it
								if Term.CaptureTimer ~= ( Term.CaptureTime / 2 ) then
									
									Module.Term_SetCaptureTimer( Term, math.min( Term.CaptureTime / 2, Term.CaptureTimer + Term.CaptureSpeed ) )
									
								else
									-- Raider has rebuilt it
									Term.BeingCaptured = nil
									
									Module.Term_Captured( Term, Term.CurOwner )
									
								end
								
							end
							
						end
						-- Owner is rebuilding
					elseif Term.CaptureTimer ~= ( Term.CaptureTime / 2 ) then
						
						Module.Term_SetCaptureTimer( Term, math.min( Term.CaptureTime / 2, Term.CaptureTimer + Term.CaptureSpeed ) )
						
					end
					
				else
					
					Term.CaptureSpeed = 0
					
				end
				
			end
			
		end
		
		local AllOwned = true
		
		local AllFullyOwned, Pause
		
		for a = 1, #Module.RequiredTerminals do
			
			local b = Module.RequiredTerminals[ a ]
			
			if b.Active then
				
				if not tableHasValue( Module.HomeTeams, b.CurOwner ) then
					
					if b.CurOwner == b.CapturingTeam and b.CaptureTimer == b.CaptureTime / 2 then
						
						AllOwned = false
						
					else
						
						Pause = true
						
					end
					
				else
					
					if b.CurOwner ~= b.CapturingTeam or b.CaptureTimer ~= b.CaptureTime / 2 then
						
						AllFullyOwned = false
						
					elseif AllFullyOwned == nil then
						
						AllFullyOwned = true
						
					end
					
				end
				
			end
			
		end
		
		if not Pause or Module.RollbackWithPartialCap or AllFullyOwned then
			
			if AllOwned then
				
				if Module.LastCap and Module.LastCap + Module.RaidLimit <= tick( ) then
					
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
					
					Module.Won( Module.AwayTeams[ 1 ] )
					
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
				
			else
				
				Home = Home + 1
				
			end
			
		end
		
	end
	
	return Away, Home
	
end

function Module.Term_Reset( Term )
	
	Term.Active = nil
	
	Term.CurOwner = Term.StartOwner or Module.HomeTeams[ 1 ]

	Term.CapturingTeam = Term.CurOwner
	
	Module.Term_SetCaptureTimer( Term, Term.CaptureTime / 2 )
	
	Module.Term_Captured( Term )
	
	return Term
	
end

function Module.Term_RequireTerm( Term, RequiredTerm )
	
	Term.Required[ #Term.Required + 1 ] = RequiredTerm
	
	return Term
	
end

function Module.Term_RequireForWin( Term )
	
	Module.RequiredTerminals[ #Module.RequiredTerminals + 1 ] = Term
	
	return Term
	
end

function Module.Term_SetCaptureTimer( Term, Val )
	
	Module.Event_Term_CaptureChanged:Fire( Term, Val )
	
	Term.CaptureTimer = Val
	
	return Term
	
end

---------------- TODO - DON'T ONLY COLOR TO FIRST TEAMS COLOR
function Module.Term_Captured( Term, Team )
	
	local Kids = Term.Model:GetDescendants( )
	
	for a = 1, #Kids do
		
		if Kids[ a ]:IsA( "SpawnLocation" ) then
			
			local Teams = ( Module.IsHomeTeam( Team ) and Module.HomeTeams or Module.AwayTeams )
			
			local Color = Teams[ a % #Teams + 1 ].TeamColor
			
			Kids[ a ].TeamColor = Color
			
			Kids[ a ].BrickColor = Color
			
		end
		
	end
	
	Module.Event_Term_Captured:Fire( Term, Team )
	
end

function Module.Term_AsFlag( Term, Dist )
	
	Term.Step = Dist and Dist / ( Term.CaptureTime / 2 ) or 1.35
	
	local StartCFs = { }
	
	Term.Model.DescendantAdded:Connect( function ( Obj )
		
		if Obj:IsA( "BasePart" ) and Obj.Name:lower( ):find( "flag" ) then
			
			StartCFs[ Obj ] = Obj.CFrame
			
			local Event Event = Obj.AncestryChanged:Connect( function ( )
				
				StartCFs[ Obj ] = nil
				
				Event:Disconnect( )
				
			end )
			
		end
		
	end )
	
	local Kids = Term.Model:GetDescendants( )
	
	for a = 1, #Kids do
		
		if Kids[ a ]:IsA( "BasePart" ) and Kids[ a ].Name:lower( ):find( "flag" ) then
			
			StartCFs[ Kids[ a ] ] = Kids[ a ].CFrame
			
			local Event Event = Kids[ a ].AncestryChanged:Connect( function ( )
				
				StartCFs[ Kids[ a ] ] = nil
				
				Event:Disconnect( )
				
			end )
			
		end
		
	end
	
	-- OLD FLAG COMPATABILITY --
	
	Module.Event_Term_CaptureChanged.Event:Connect( function ( elf, Val )
		
		if elf.Model ~= Term.Model then return end
		
		for a, b in pairs( StartCFs ) do
			
			a.BrickColor = Term.CurOwner.TeamColor
			
		end
		
		if Term.Model:FindFirstChild( "Smoke", true ) then
			
			Term.Model:FindFirstChild( "Smoke", true ).Color = Term.CurOwner.TeamColor.Color
			
		end
		
		if Term.CaptureTimer == Val then return end
		
		local CaptureSpeed = -( Term.CaptureTimer - Val )
		
		if CaptureSpeed == 0 then return end
		
		if Term.CapturingTeam == Term.CurOwner then
			
			Term.Model.Naming:GetChildren( )[ 1 ].Name = Term.CurOwner.Name .. " now owns " .. math.ceil( ( Val / ( Term.CaptureTime / 2 ) ) * 100 ) .. "% of the location"
			
		else
			
			Term.Model.Naming:GetChildren( )[ 1 ].Name = Term.CurOwner.Name .. " owns " .. math.ceil( ( Val / ( Term.CaptureTime / 2 ) ) * 100 ) .. "% of the location"
			
		end
		
		for a, b in pairs( StartCFs ) do
			
			game.TweenService:Create( a, TweenInfo.new( 1, Enum.EasingStyle.Quint ), { CFrame = ( b - Vector3.new( 0, Dist * ( 1 - ( Val / ( Term.CaptureTime / 2 ) ) ) ) ) } ):Play( )
			
		end
		
		if Val == Term.CaptureTime / 2 then
			
			Term.Model.Naming:GetChildren( )[ 1 ].Name = "Owned by " .. Term.CurOwner.Name
			
			local Kids = Term.Model:GetDescendants( )
			
			for a = 1, #Kids do
				
				if Kids[ a ]:IsA( "SpawnLocation" ) then
					
					Kids[ a ].TeamColor = Term.CurOwner.TeamColor
					
					Kids[ a ].BrickColor = Term.CurOwner.TeamColor
					
				end
				
			end
			
		end
		
	end )
	
	Module.Event_Term_Captured.Event:Connect( function ( elf )
		
		if elf.Model ~= Term.Model then return end
		
		if Term.Model:FindFirstChild( "Smoke", true ) then
			
			Term.Model:FindFirstChild( "Smoke", true ).Color = Term.CurOwner.TeamColor.Color
			
		end
		
		Term.Model.Naming:GetChildren( )[ 1 ].Name = "Owned by " .. Term.CurOwner.Name
		
		local Hint = Instance.new( "Hint", workspace )
		
		Hint.Text = "The flag at the " .. Term.Name .. " is now owned by " .. Term.CurOwner.Name
		
		game.Debris:AddItem( Hint, 5 )
		
	end )
		
	Module.Event_Term_Captured:Fire( Term )
	
	return Term
	
end

function Module.new( Name, Dist, CapTime, MainPart, Model, StartOwner )
	
	local Term = { }
	
	Term.Required = { }
	
	Term.Name = Name
	
	Term.Dist = Dist
	
	Term.CaptureTime = CapTime
	
	Term.StartOwner = StartOwner
	
	Term.CurOwner = StartOwner or Module.HomeTeams[ 1 ]

	Term.CapturingTeam = Term.CurOwner
	
	Term.MainPart = MainPart
	
	Term.Model = Model
	
	Term.requireTerm = Module.Term_RequireTerm
	
	Term.requireForWin = Module.Term_RequireForWin
	
	Term.AddSpawns = function ( Term ) warn( "Term:AddSpawns( ) no longer necessary - " .. Name ) return Term end
	
	Term.AsFlag = Module.Term_AsFlag
	
	Module.Terminals[ #Module.Terminals + 1 ] = Term
	
	Module.Term_SetCaptureTimer( Term, Term.CaptureTime / 2 )
	
	Module.Term_Captured( Term, Term.CurOwner )
	
	return Term
	
end

---------- VH

repeat wait( ) until _G.VH_AddExternalCmds

_G.VH_AddExternalCmds( function ( Main )
	
	Main.Commands[ "Official" ] = {
		
		Alias = { Main.TargetLib.AliasTypes.Toggle( 1, "official" ) },
		
		Description = "Makes the raid official/unofficial",
		
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
	
end )

return Module