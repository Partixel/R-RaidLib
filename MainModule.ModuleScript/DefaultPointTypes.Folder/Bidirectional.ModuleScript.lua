local TweenService = game:GetService("TweenService")

return function(RaidLib)
	RaidLib.BidirectionalPointMetadata = setmetatable({
		
		Reset = function(self)
			
			self.Active = nil
			
			self.CurOwner = self.StartOwner or RaidLib.HomeTeams
			
			self:SetCapturingSide(self.CurOwner)
			
			self.ExtraTimeGiven = nil
			
			self:SetCaptureTimer(RaidLib.GameMode.WinPoints and 0 or self.CaptureTime / 2, 0)
			
			self.Down = self.CaptureTimer == 0
			
			self:Captured(self.CurOwner)
			
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
			
			self.Model.CapturePct.Value = Val / (self.CaptureTime / 2)
			self.CaptureTimer = Val
		end,
		
		Captured = function(self, Side)
			
			self.SpawnClones = RaidLib.SetSpawns(self.SpawnClones, self.Model, Side)
			
			if RaidLib.RaidStart and Side == (self.AwayOwned and RaidLib.HomeTeams or RaidLib.AwayTeams) and not self.ExtraTimeGiven then
				self.ExtraTimeGiven = true
				if self.ExtraTimeForCapture then
					RaidLib.AddTimeToRaidLimit(self.ExtraTimeForCapture)
				elseif self.SetTimeForCapture then
					RaidLib.SetRaidLimit(self.SetTimeForCapture)
				end
			end
			
			self.Event_Captured:Fire((next(Side)))
			
			RaidLib.Captured:FireAllClients(self.Name, (next(Side)))
			
		end,
		
		AsFlag = function(self, Dist)
			
			local StartCFs = {}
			
			self.Model.DescendantAdded:Connect(function(Obj)
				
				if Obj:IsA("BasePart") and Obj.Name:lower():find("flag") then
					
					StartCFs[Obj] = Obj.CFrame
					
					local Event Event = Obj.AncestryChanged:Connect(function()
						
						StartCFs[Obj] = nil
						
						Event:Disconnect()
						
					end)
					
				end
				
			end)
			
			for _, Kid in ipairs(self.Model:GetDescendants()) do
				
				if Kid:IsA("BasePart") and Kid.Name:lower():find("flag") then
					
					StartCFs[Kid] = Kid.CFrame
					
					local Event Event = Kid.AncestryChanged:Connect(function()
						
						StartCFs[Kid] = nil
						
						Event:Disconnect()
						
					end)
					
				end
				
			end
			
			self.Event_CaptureChanged.Event:Connect(function(Val)
				
				for a, b in pairs(StartCFs) do
					
					a.BrickColor = next(self.CurOwner).TeamColor
					
				end
				
				if self.Model:FindFirstChild("Smoke", true) then
					
					self.Model:FindFirstChild("Smoke", true).Color = next(self.CurOwner).TeamColor.Color
					
				end
				
				if Val == self.CaptureTime / 2 then
					
					self.Model.Naming:GetChildren()[1].Name = "Owned by " .. next(self.CurOwner).Name
				
				elseif self.CapturingSide == self.CurOwner then
					
					self.Model.Naming:GetChildren()[1].Name = next(self.CurOwner).Name .. " now owns " .. math.ceil((Val / (self.CaptureTime / 2)) * 100) .. "% of the location"
					
				else
					
					self.Model.Naming:GetChildren()[1].Name = next(self.CurOwner).Name .. " owns " .. math.ceil((Val / (self.CaptureTime / 2)) * 100) .. "% of the location"
					
				end
				
				for a, b in pairs(StartCFs) do
					
					TweenService:Create(a, TweenInfo.new(RaidLib.GameTick, Enum.EasingStyle.Linear), {CFrame = (b - Vector3.new(0, Dist * (1 - (Val / (self.CaptureTime / 2)))))}):Play()
					
				end
				
			end)
			
			self.Event_Captured.Event:Connect(function()
				
				if self.Model:FindFirstChild("Smoke", true) then
					
					self.Model:FindFirstChild("Smoke", true).Color = next(self.CurOwner).TeamColor.Color
					
				end
				
				self.Model.Naming:GetChildren()[1].Name = "Owned by " .. next(self.CurOwner).Name
				
			end)
			
			RaidLib.OfficialRaid:GetPropertyChangedSignal("Value"):Connect(function()
				
				local BrickTimer = self.Model:FindFirstChild("BrickTimer", true)
				
				if BrickTimer then
					
					BrickTimer:GetChildren()[1].Name = RaidLib.OfficialRaid.Value and (RaidLib.AwayGroup.Name .. " do not own the main flag") or "No raid in progress" 
					
				end
				
			end)
		
			RaidLib.Event_WinChanged.Event:Connect(function(Old)
				
				local BrickTimer = self.Model:FindFirstChild("BrickTimer", true)
				
				if BrickTimer then
					
					BrickTimer:GetChildren()[1].Name = RaidLib.AwayWinAmount.Value == 0 and (RaidLib.AwayGroup.Name .. " do not own the main flag") or (RaidLib.AwayGroup.Name .. " win in " .. RaidLib.FormatTime(math.floor(RaidLib.GameMode.WinTime - RaidLib.AwayWinAmount.Value)))
					
				end
				
			end)
			
			if RaidLib.GameMode then
				if self.Model:FindFirstChild("Smoke", true) then
					self.Model:FindFirstChild("Smoke", true).Color = next(self.CurOwner).TeamColor.Color
				end
				
				self.Model.Naming:GetChildren()[1].Name = "Owned by " .. next(self.CurOwner).Name
				
				local BrickTimer = self.Model:FindFirstChild("BrickTimer", true)
				if BrickTimer then
					BrickTimer:GetChildren()[1].Name = RaidLib.OfficialRaid.Value and (RaidLib.AwayGroup.Name .. " do not own the main flag") or "No raid in progress" 
				end
			end
			
			return self
			
		end,
		-- True = This point should ignore its Required points as e.g. it's already partially captured
		ShouldRequireCheck = function(self)
			return self.CurOwner == RaidLib.HomeTeams and self.CaptureTimer == self.CaptureTime / 2
		end,
		-- True = This point doesn't satisfy the Required condition of any points that require it
		RequireCheck = function(self)
			return self.CurOwner ~= RaidLib.AwayTeams or self.CaptureTimer ~= self.CaptureTime / 2
		end,
		-- True = Pass CaptureSpeed to the Tick (based on nearby enemy/allies)
		TickWithNear = true,
		-- Function that runs every game tick to compute the points state
		Tick = function(self, CaptureSpeed, Home, Away)
			if Home > Away then
				if self.CapturingSide ~= RaidLib.HomeTeams then
					self:SetCapturingSide(RaidLib.HomeTeams)
				end
				
				if RaidLib.HomeTeams ~= self.CurOwner then
					self.BeingCaptured = true
				elseif self.Down then
					self.BeingCaptured = nil
				end
			elseif Away > Home then
				if self.CapturingSide ~= RaidLib.AwayTeams then
					self:SetCapturingSide(RaidLib.AwayTeams)
				end
				
				if RaidLib.AwayTeams ~= self.CurOwner then
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
						
						self:SetCaptureTimer(self.CaptureTime / 2, CaptureSpeed)
						
						self.BeingCaptured = nil
						
						self:Captured(self.CurOwner)
						
					else
						
						if self.CaptureTimer ~= 0 and self.CurOwner ~= self.CapturingSide then
							
							self.Down = true
							
							self:SetCaptureTimer(math.max(0, self.CaptureTimer - CaptureSpeed), -CaptureSpeed)
							
						else
							-- the away team has held it for long enough, switch owner
							if self.CaptureTimer == 0 and self.Down then
								
								self.CurOwner = self.CapturingSide
								
								self.Down = nil
								
							end
							-- the away team is now rebuilding it
							if self.CaptureTimer ~= (self.CaptureTime / 2) then
								
								self:SetCaptureTimer(math.min(self.CaptureTime / 2, self.CaptureTimer + CaptureSpeed), CaptureSpeed)
								
							else
								-- the away team has rebuilt it
								self.BeingCaptured = nil
								
								self:Captured(self.CurOwner)
								
							end
							
						end
						
					end
					-- Owner is rebuilding
				elseif self.CaptureTimer ~= (self.CaptureTime / 2) then
					
					self:SetCaptureTimer(math.min(self.CaptureTime / 2, self.CaptureTimer + CaptureSpeed), CaptureSpeed)
					
				end
			end
		end,
		-- Returns values for HomeFullyOwnAll, HomeOwnAll and AwayFullyOwnAll for the TimeBased gamemode
		TimeBased = function(self)
			if self.CurOwner == RaidLib.AwayTeams then
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
				if self.CurOwner == RaidLib.AwayTeams then
					return nil, self.AwayPointsPerSecond
				else
					return self.HomePointsPerSecond, nil
				end
			end
		end,
	}, {__index = RaidLib})
	
	-- Table requires Dist = Number, CaptureTime = Number, MainPart = Instance, Model = Instance
	return function(CapturePoint)
		CapturePoint.CaptureTime = CapturePoint.CaptureTime or 1
		
		CapturePoint.Name = CapturePoint.Name or CapturePoint.Model.Name
		
		setmetatable(CapturePoint, {__index = RaidLib.BidirectionalPointMetadata})
		
		CapturePoint.Event_Captured = Instance.new("BindableEvent")
		CapturePoint.Event_CaptureChanged = Instance.new("BindableEvent")
		CapturePoint.Event_CapturingSideChanged = Instance.new("BindableEvent")
		CapturePoint.Event_Reset = Instance.new("BindableEvent")
		
		local Pct = Instance.new("NumberValue")
		
		Pct.Name = "CapturePct"
		
		Pct.Parent = CapturePoint.Model
		
		if RaidLib.GameMode then
			CapturePoint:Reset()
		end
		
		RaidLib.CapturePoints[#RaidLib.CapturePoints + 1] = CapturePoint
		
		RaidLib.Event_CapturePointAdded:Fire(#RaidLib.CapturePoints)
		
		return CapturePoint
	end
end