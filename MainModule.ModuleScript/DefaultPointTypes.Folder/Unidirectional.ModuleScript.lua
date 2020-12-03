local TweenService, CollectionService = game:GetService("TweenService"), game:GetService("CollectionService")

return function(RaidLib)
	
	RaidLib.UnidirectionalPointMetadata = setmetatable({
		
		Reset = function(self)
			
			self.Active = nil
			
			self.Checkpoint = 0
			
			self.ExtraTimeGiven = nil
			
			self:SetCapturingSide(self.AwayOwned and RaidLib.AwayTeams or RaidLib.HomeTeams)
			
			self:SetCaptureTimer(0, 0)
			
			self:CheckpointReached(0)
			
			self.Event_Reset:Fire()
			
			return self
			
		end,
		
		Destroy = function(self, Destroy)
			for _, v in pairs(self) do
				if typeof(v) == "Instance" and v:IsA("BindableEvent") then
					v:Destroy()
				elseif typeof(v) == "RBXScriptConnection" then
					v:Disconnect()
				end
			end
			
			if Destroy then
				self.Model:Destroy()
			else
				self.Model.CapturePct:Destroy()
			end
			
			for i, CapturePoint in ipairs(RaidLib.CapturePoints) do
				if CapturePoint == self then
					RaidLib.CapturePoints[i] = RaidLib.CapturePoints[#RaidLib.CapturePoints]
					RaidLib.CapturePoints[#RaidLib.CapturePoints] = nil
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
			
			RaidLib.RequiredCapturePoints[#RaidLib.RequiredCapturePoints + 1] = self
			
			return self
			
		end,
		
		SetCapturingSide = function(self, Side)
			self.Event_CapturingSideChanged:Fire((next(Side)))
			
			self.CapturingSide = Side
		end,
		
		SetCaptureTimer = function(self, Val, Speed)
			self.Event_CaptureChanged:Fire(Val, Speed)
			
			self.Model.CapturePct.Value = Val / self.CaptureTime
			self.CaptureTimer = Val
		end,
		
		CheckpointReached = function(self, Checkpoint)
			
			if Checkpoint == 0 then
				
				for a = 1, #self.Checkpoints do
					
					local b = self.Checkpoints[a]
					
					if a == Checkpoint then
						
						local b = self.Checkpoints[Checkpoint]
						
						if typeof(b) == "Instance" then
							
							local SpawnClones = self.SpawnClones and self.SpawnClones[b] or nil
							
							SpawnClones = RaidLib.SetSpawns(SpawnClones, self.Model, self.AwayOwned and RaidLib.AwayTeams or RaidLib.HomeTeams)
							
							if SpawnClones then
								
								self.SpawnClones = self.SpawnClones or {}
								
								self.SpawnClones[b] = SpawnClones
								
							end
							
						end
						
					else
						
						if typeof(b) == "Instance" then
							
							local SpawnClones = self.SpawnClones and self.SpawnClones[b] or nil
							
							SpawnClones = RaidLib.SetSpawns(SpawnClones, self.Model, self.AwayOwned and RaidLib.HomeTeams or RaidLib.AwayTeams)
							
							if SpawnClones then
								
								self.SpawnClones = self.SpawnClones or {}
								
								self.SpawnClones[b] = SpawnClones
								
							end
							
						end
						
					end
					
				end
				
			else
				
				local b = self.Checkpoints[Checkpoint]
				
				if typeof(b) == "Instance" then
					
					local SpawnClones = self.SpawnClones and self.SpawnClones[b] or nil
					
					SpawnClones = RaidLib.SetSpawns(SpawnClones, self.Model, self.AwayOwned and RaidLib.AwayTeams or RaidLib.HomeTeams)
					
					if SpawnClones then
						
						self.SpawnClones = self.SpawnClones or {}
						
						self.SpawnClones[b] = SpawnClones
						
					end
					
				end
				
			end
			
			if RaidLib.RaidStart then
				local Set, ExtraTimeToGive
				if not self.Checkpoints[Checkpoint + 1] and self.ExtraTimeForCapture then
					ExtraTimeToGive = self.ExtraTimeForCapture
				elseif not self.Checkpoints[Checkpoint + 1] and self.SetTimeForCapture then
					ExtraTimeToGive = self.SetTimeForCapture
					Set = true
				elseif self.ExtraTimeForCheckpoint then
					ExtraTimeToGive = self.ExtraTimeForCheckpoint
				elseif self.SetTimeForCheckpoint then
					ExtraTimeToGive = self.SetTimeForCheckpoint
					Set = true
				end
				
				if ExtraTimeToGive then
					self.ExtraTimeGiven = self.ExtraTimeGiven or {}
					if not self.ExtraTimeGiven[Checkpoint] then
						self.ExtraTimeGiven[Checkpoint] = true
						if Set then
							RaidLib.SetRaidLimit(ExtraTimeToGive)
						else
							RaidLib.AddTimeToRaidLimit(ExtraTimeToGive)
						end
					end
				end
			end
			
			if not self.Checkpoints[Checkpoint + 1] then
				
				local Found, FoundSelf
				
				for a = 1, #RaidLib.RequiredCapturePoints do
					
					if RaidLib.RequiredCapturePoints[a] ~= self then
						
						if RaidLib.RequiredCapturePoints[a].Required then
							
							for b = 1, #RaidLib.RequiredCapturePoints[a].Required do
								
								if RaidLib.RequiredCapturePoints[a].Required[b] == self then
									
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
				
				RaidLib.Captured:FireAllClients(self.Name, self.AwayOwned and (next(RaidLib.AwayTeams) or next(RaidLib.HomeTeams)))
				
			else
				
				RaidLib.CheckpointReached:FireAllClients(self.Name, Checkpoint)
				
			end	
			
			self.Event_CheckpointReached:Fire(Checkpoint)
			
		end,
		
		AsPayload = function(self, StartPoint, TurnPoints)
			
			local TurnPoint = 0
			
			for a = 1, #self.Checkpoints do
				
				TurnPoints[#TurnPoints + 1] = self.Checkpoints[a]
				
			end
			
			table.sort(TurnPoints, function(a, b)
				
				return a[1] < b[1]
				
			end)
			
			TurnPoints[0] = {0, StartPoint}
			
			local StartCF = CFrame.new(RaidLib.GetWorldPos(StartPoint), RaidLib.GetWorldPos(TurnPoints[1][2]))
			
			self.MainPart.CFrame = StartCF
			
			self.Event_CapturingSideChanged.Event:Connect(function(Side)
				Side = next(RaidLib.AwayTeams) == Side and "AwayRotation" or "HomeRotation"
				for _, Obj in ipairs(self.Model:GetChildren()) do
					if CollectionService:HasTag(Obj, "PayloadRotate") then
						local Rotate = Obj:FindFirstChild(Side).Value
						TweenService:Create(Obj.Weld, TweenInfo.new(Obj.TweenTime.Value, Enum.EasingStyle.Linear), {C1 = CFrame.new(Obj.Weld.C1.p) * CFrame.fromOrientation(math.rad(Rotate.X), math.rad(Rotate.Y), math.rad(Rotate.Z))}):Play()
					end
				end
			end)
			
			self.Event_CaptureChanged.Event:Connect(function(CaptureTimer, CaptureSpeed)
				
				if CaptureTimer == 0 and CaptureSpeed == 0 then
					
					TweenService:Create(self.MainPart, TweenInfo.new(0), {CFrame = StartCF}):Play()
					
					TurnPoint = 0
					
					return
					
				end
				
				if self.MainPart:FindFirstChild("PushSound") then
					
					if not self.MainPart.PushSound.Playing then
						
						self.MainPart.PushSound:Play()
						
					end
					
					self.MainPart.PushSound.PlaybackSpeed = math.abs(math.max(CaptureSpeed / 2, 1.25))
					
					delay(RaidLib.GameTick + 0.1, function()
						
						if self.CaptureTimer == CaptureTimer then
							
							self.MainPart.PushSound:Stop()
							
						end
						
					end)
					
				end
				
				local LastCF = self.MainPart.CFrame
				
				local TotalDist = 0
				
				local Targets = {}
				
				local MyCaptureTimer
				
				while MyCaptureTimer ~= CaptureTimer do
					
					MyCaptureTimer = CaptureTimer
					
					if MyCaptureTimer < TurnPoints[TurnPoint][1] then
						
						TurnPoint = TurnPoint - 1
						
						MyCaptureTimer = math.max(CaptureTimer, TurnPoints[TurnPoint][1])
						
					elseif TurnPoints[TurnPoint + 1] and MyCaptureTimer > TurnPoints[TurnPoint + 1][1] then
						
						TurnPoint = TurnPoint + 1
						
						MyCaptureTimer = math.min(CaptureTimer, TurnPoints[TurnPoint][1])
						
					end
					
					local Target
					
					if MyCaptureTimer == TurnPoints[TurnPoint][1] then
						
						if TurnPoint == 0 then
							
							Target = StartCF
							
						else
							
							local TurnPointPos, PrevTurnPointPos = RaidLib.GetWorldPos(TurnPoints[TurnPoint][2]), RaidLib.GetWorldPos(TurnPoints[TurnPoint - 1][2])
							
							Target = CFrame.new(TurnPointPos, TurnPointPos + (TurnPointPos - PrevTurnPointPos))
													
						end
						
					else
						
						local TurnPointPos, NextTurnPointPos = RaidLib.GetWorldPos(TurnPoints[TurnPoint][2]), RaidLib.GetWorldPos(TurnPoints[TurnPoint + 1][2])
						
						Target = CFrame.new(TurnPointPos, NextTurnPointPos) + (NextTurnPointPos - TurnPointPos) * (MyCaptureTimer - TurnPoints[TurnPoint][1]) / (TurnPoints[TurnPoint + 1][1] - TurnPoints[TurnPoint][1])
						
					end
					
					local Dist = math.max(math.abs((LastCF.p - Target.p).magnitude), 1)
					
					TotalDist = TotalDist + Dist
					
					LastCF = Target
					
					Targets[#Targets + 1] = {Dist, Target}
					
				end
				
				for _, Kid in ipairs(self.Model:GetChildren()) do
					
					if CollectionService:HasTag(Kid, "PayloadWheel") then
						
						local Rotate = Kid.Rotate.Value * 22.25 * CaptureSpeed
						
						TweenService:Create(Kid.Weld, TweenInfo.new(RaidLib.GameTick, Enum.EasingStyle.Linear), {C1 = Kid.Weld.C1 * CFrame.fromOrientation(math.rad(Rotate.X), math.rad(Rotate.Y), math.rad(Rotate.Z))}):Play()
						
					end
					
				end
				
				for i, Target in ipairs(Targets) do
					
					local Tween = TweenService:Create(self.MainPart, TweenInfo.new(Target[1] / TotalDist * RaidLib.GameTick, Enum.EasingStyle.Linear), {CFrame = Target[2]})
					
					Tween:Play()
					
					if i ~= #Targets then
						
						local State = Tween.Completed:Wait()
						
						while State ~= Enum.PlaybackState.Completed do
							
							if State == Enum.PlaybackState.Cancelled then return end
							
							State = Tween.Completed:Wait()
							
						end
						
					end
					
				end
				
			end)
			
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
				if self.CapturingSide ~= RaidLib.HomeTeams then
					self:SetCapturingSide(RaidLib.HomeTeams)
				end
			elseif Away > Home then
				if self.CapturingSide ~= RaidLib.AwayTeams then
					self:SetCapturingSide(RaidLib.AwayTeams)
				end
			end
			
			if CaptureSpeed ~= 0 then
				
				if self.CapturingSide ~= (self.AwayOwned and RaidLib.AwayTeams or RaidLib.HomeTeams) then
					
					local NextCheckpoint = self.Checkpoint + 1
					
					if self.Checkpoints[NextCheckpoint] and not self.Checkpoints[NextCheckpoint][3] and (self.LowerLimitTimer == nil or self.CaptureTimer ~= self.LowerLimitTimer) then
						
						local NewCaptureTimer = self.CaptureTimer + CaptureSpeed
						
						if self.TimerLimits then
							
							for b = 1, #self.TimerLimits do
								
								if self.TimerLimits[b][1] and NewCaptureTimer > self.TimerLimits[b][1] and (self.TimerLimits[b][2] == nil or self.CaptureTimer < self.TimerLimits[b][2]) then
									
									if self.CaptureTimer <= self.TimerLimits[b][1] then
										
										local Enabled = self.TimerLimits[b][3]
										
										if type(Enabled) == "function" then
											
											Enabled = Enabled()
											
										end
										
										if Enabled then
											
											NewCaptureTimer = self.TimerLimits[b][1]
											
										elseif not self.TimerLimits[b][5] and self.TimerLimits[b][4] then
											
											self.TimerLimits[b][5] = true
											
											self.TimerLimits[b][4](true)
											
										end
										
									end
									
								elseif self.TimerLimits[b][5] and self.TimerLimits[b][4] then
									
									self.TimerLimits[b][5] = nil
									
									self.TimerLimits[b][4]()
									
								end
								
							end
							
						end
						
						if NewCaptureTimer ~= self.CaptureTimer then
							
							NewCaptureTimer = math.min(NewCaptureTimer, self.CaptureTime)
							
							local OriginalCaptureTimer = NewCaptureTimer
							
							while self.Checkpoints[NextCheckpoint] and OriginalCaptureTimer >= self.Checkpoints[NextCheckpoint][1] do
								
								if self.Checkpoints[NextCheckpoint][3] then
									
									NewCaptureTimer = math.max(OriginalCaptureTimer, (self.Checkpoints[self.Checkpoint] or {0})[1])
									
									break
									
								end
								
								self:CheckpointReached(NextCheckpoint)
								
								self.Checkpoint = NextCheckpoint
								
								NextCheckpoint = NextCheckpoint + 1
								
							end
							
							self:SetCaptureTimer(NewCaptureTimer, CaptureSpeed)
							
							self.WasMoving = true
							
						elseif self.WasMoving then
							
							self.WasMoving = nil
							
							self:SetCaptureTimer(self.CaptureTimer, 0)
							
						end
						
					end
					
				elseif self.CaptureTimer ~= (self.Checkpoints[self.Checkpoint] or {0})[1] then
					
					local NewCaptureTimer = self.CaptureTimer - CaptureSpeed
					
					if self.TimerLimits then
						
						for a = 1, #self.TimerLimits do
							
							if self.TimerLimits[a][2] and NewCaptureTimer < self.TimerLimits[a][2] and (self.TimerLimits[a][1] == nil or self.CaptureTimer > self.TimerLimits[a][1]) then
								
								if self.CaptureTimer >= self.TimerLimits[a][2] then
									
									local Enabled = self.TimerLimits[a][3]
									
									if type(Enabled) == "function" then
										
										Enabled = Enabled()
										
									end
									
									if Enabled then
										
										NewCaptureTimer = self.TimerLimits[a][2]
										
									elseif not self.TimerLimits[a][5] and self.TimerLimits[a][4] then
										
										self.TimerLimits[a][5] = true
										
										self.TimerLimits[a][4](true)
										
									end
									
								end
								
							elseif self.TimerLimits[a][5] and self.TimerLimits[a][4] then
								
								self.TimerLimits[a][5] = nil
								
								self.TimerLimits[a][4]()
								
							end
							
						end
						
					end
					
					if NewCaptureTimer ~= self.CaptureTimer then
						
						self:SetCaptureTimer(math.max(NewCaptureTimer, (self.Checkpoints[self.Checkpoint] or {0})[1]) , -CaptureSpeed)
						
						self.WasMoving = true
						
					elseif self.WasMoving then
						
						self.WasMoving = nil
						
						self:SetCaptureTimer(self.CaptureTimer, 0)
						
					end
					
				end
				
			elseif self.WasMoving then
				
				self.WasMoving = nil
				
				self:SetCaptureTimer(self.CaptureTimer, 0)
				
			end
		end,
		TimeBased = function(self)
			if not self.AwayOwned then
				if self.CaptureTimer ~= self.CaptureTime then
					if self.CapturingSide == RaidLib.AwayTeams then
						return false, false, false
					elseif self.CaptureTimer ~= (self.Checkpoints[self.Checkpoint] or {0})[1] then
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
	}, {__index = RaidLib})
	
	-- Table requires Dist = Number, CaptureTime = Number, MainPart = Instance, Model = Instance
	return function(CapturePoint)
		CapturePoint.Name = CapturePoint.Name or CapturePoint.Model.Name
		
		setmetatable(CapturePoint, {__index = RaidLib.UnidirectionalPointMetadata})
		
		CapturePoint.Event_CheckpointReached = Instance.new("BindableEvent")
		CapturePoint.Event_CaptureChanged = Instance.new("BindableEvent")
		CapturePoint.Event_CapturingSideChanged = Instance.new("BindableEvent")
		CapturePoint.Event_Reset = Instance.new("BindableEvent")
		
		CapturePoint.Checkpoints = CapturePoint.Checkpoints or {{CapturePoint.CaptureTime, CapturePoint.Model}}
		
		if CapturePoint.Checkpoints[#CapturePoint.Checkpoints][1] ~= CapturePoint.CaptureTime then
			
			CapturePoint.Checkpoints[#CapturePoint.Checkpoints + 1] = {CapturePoint.CaptureTime}
			
		end
		
		local Pct = Instance.new("NumberValue")
		
		Pct.Name = "CapturePct"
		
		for a = 1, #CapturePoint.Checkpoints do
			
			local Pct2 = Instance.new("NumberValue", Pct)
			
			Pct2.Name = "Checkpoint" .. a
			
			Pct2.Value = CapturePoint.Checkpoints[a][1] / CapturePoint.CaptureTime
			
		end
		
		Pct.Parent = CapturePoint.Model
		
		if RaidLib.GameMode then
			CapturePoint:Reset()
		end
		
		RaidLib.CapturePoints[#RaidLib.CapturePoints + 1] = CapturePoint
		
		RaidLib.Event_CapturePointAdded:Fire(#RaidLib.CapturePoints)
		
		return CapturePoint
		
	end
end