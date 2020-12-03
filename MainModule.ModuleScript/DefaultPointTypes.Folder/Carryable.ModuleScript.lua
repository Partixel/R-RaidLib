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

return function(Module)
	Module.CarryablePointMeta = setmetatable({
		Reset = function(self)
			self.Active = nil
			self.BeenCaptured = nil
			self.LastSafe = self.StartPos
			self.ExtraTimeGiven = nil
			self:SetCarrier(nil)
			self:Captured(self.AwayOwned and Module.AwayTeams or Module.HomeTeams)
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
			
			self.Pct:Destroy()
			self.Clone:Destroy()
			
			if Destroy then
				self.Model:Destroy()
			end
			
			for i, CapturePoint in ipairs(Module.CapturePoints) do
				if CapturePoint == self then
					Module.CapturePoints[i] = Module.CapturePoints[#Module.CapturePoints]
					Module.CapturePoints[#Module.CapturePoints] = nil
					break
				end
			end
		end,
		RequireForCapture = function(self, Required)
			self.RequiredForCapture = self.RequiredForCapture or {}
			self.RequiredForCapture[#self.RequiredForCapture + 1] = Required
			return self
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
			
			if Side == AwaySide then
				self.BeenCaptured = true
				if Module.RaidStart and not self.ExtraTimeGiven then
					self.ExtraTimeGiven = true
					if self.ExtraTimeForCapture then
						Module.AddTimeToRaidLimit(self.ExtraTimeForCapture)
					elseif self.SetTimeForCapture then
						Module.SetRaidLimit(self.SetTimeForCapture)
					end
				end
				
				if self.ResetOnCapture then
					self.LastSafe = self.StartPos
					self:SetCarrier(nil)
				else
					self.LastSafe = self.TargetPos
					self:SetCarrier(nil)
				end
				
				if Module.GameMode.WinPoints then
					if Side == Module.AwayTeams then
						Module.AwayWinAmount.Value = math.clamp(Module.AwayWinAmount.Value + (self.AwayCapturePoints or 0), 0, Module.GameMode.WinPoints)
					else
						Module.HomeWinAmount.Value = math.clamp(Module.HomeWinAmount.Value + (self.HomeCapturePoints or 0), 0, Module.GameMode.WinPoints)
					end
				end
			else
				if self.ResetOnHomePickup then
					self.LastSafe = self.StartPos
					self:SetCarrier(nil)
				end
				
				if Module.GameMode.WinPoints then
					if Side == Module.AwayTeams then
						Module.AwayWinAmount.Value = math.clamp(Module.AwayWinAmount.Value + (self.AwayReturnPoints or 0), 0, Module.GameMode.WinPoints)
					else
						Module.HomeWinAmount.Value = math.clamp(Module.HomeWinAmount.Value + (self.HomeReturnPoints or 0), 0, Module.GameMode.WinPoints)
					end
				end
			end
			
			if not self.ResetOnHomePickup then
				self.SpawnClones = Module.SetSpawns(self.SpawnClones, self.Model, Side)
			end
			
			if Module.RaidStart and Side == AwaySide then
				if self.ExtraTimeForCapture then
					Module.AddTimeToRaidLimit(self.ExtraTimeForCapture)
				elseif self.SetTimeForCapture then
					Module.SetRaidLimit(self.SetTimeForCapture)
				end
			end
			
			self.Event_Captured:Fire((next(Side)))
			Module.Captured:FireAllClients(self.Name, (next(Side)))
		end,
		SetCarrier = function(self, Carrier)
			if Carrier then
				if self.Carrier then
					if self.Model.Handle:FindFirstChild("Weld") then
						self.Model.Handle.Weld:Destroy()
					end
				else
					self.RotateEvent = self.RotateEvent:Disconnect()
					self.PickupEvent = self.PickupEvent:Disconnect()
				end
				
				WeldAttachments(self.Model.Handle, Carrier.Character)
				self.Model.Handle.Anchored = false
				self.Model.Parent = Carrier.Character
				
				if self.DropGui then
					self.Gui = self.DropGui:Clone()
					self.Gui.Parent = Carrier.PlayerGui
					self.Gui.TextButton.MouseButton1Click:Connect(function()
						self:SetCarrier(nil)
					end)
				end
				
				self.DiedEvent = Carrier.Character.Humanoid.Died:Connect(function()
					self:SetCarrier(nil)
				end)
				
				if self.WalkSpeedModifier then
					self.WSMod = Instance.new("NumberValue")
					
					self.WSMod.Name = "WalkSpeedModifier"
					
					self.WSMod.Value = self.WalkSpeedModifier
					
					self.WSMod.Parent = Carrier.Character.Humanoid
				end
				
				if self.JumpPowerModifier then
					self.JPMod = Instance.new("NumberValue")
					
					self.JPMod.Name = "JumpPowerModifier"
					
					self.JPMod.Value = self.JumpPowerModifier
					
					self.JPMod.Parent = Carrier.Character.Humanoid
				end
				
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
				if self.Carrier then
					if self.WSMod then
						self.WSMod = self.WSMod:Destroy()
					end
					
					if self.JPMod then
						self.JPMod = self.JPMod:Destroy()
					end
					
					if self.Gui then
						self.Gui = self.Gui:Destroy()
					end
					
					self.DiedEvent = self.DiedEvent:Disconnect()
					
					if self.PreventTools then
						self.ToolEvent = self.ToolEvent:Disconnect()
					end
					
					local Weld = self.Model.Handle:FindFirstChild("Weld")
					
					while Weld do
						Weld:Destroy()
						Weld = self.Model.Handle:FindFirstChild("Weld")
					end
				end
				
				coroutine.wrap(self.DoDisplay)(self)
			end
			
			self.Event_CarrierChanged:Fire(Carrier)
			self.Carrier = Carrier
		end,
		DoDisplay = function(self)
			local Pos = self.LastSafe
			self.Model.Parent = workspace
			self.Model.Handle.CanCollide = false
			self.Model.Handle.Anchored = true
			local Orientation = self.Model.Handle:FindFirstChildOfClass("Attachment").CFrame:inverse()
			self.Model.Handle.CFrame = CFrame.new(Pos) * Orientation
			self.Pct.Value = self.LastSafe == self.StartPos and 0 or self.LastSafe == self.TargetPos and 1 or math.min(1 - ((self.Model.Handle.Position - self.Target.Position).magnitude - self.TargetDist) / self.TotalDist, 1)
			
			if self.RotateEvent then
				self.RotateEvent:Disconnect()
			end
			if self.PickupEvent then
				self.PickupEvent:Disconnect()
			end
			
			local MyRotateEvent = game["Run Service"].Heartbeat:Connect(function(Step)
				self.Model.Handle.CFrame = CFrame.new(Pos + Vector3.new(0, math.sin(tick() / 2) + 0.5, 0)) * CFrame.fromOrientation(0, math.rad((tick()%10/10) * 360), 0) * Orientation
			end)
			self.RotateEvent = MyRotateEvent
			
			wait(1)
			if MyRotateEvent == self.RotateEvent then
				self.PickupEvent = self.Model.Handle.Touched:Connect(function(Part)
					if Part.Name == "HumanoidRootPart" then
						local Active
						if self.ShouldTick then
							Active = self:ShouldTick()
						else
							Active = self.Active
						end
						
						if Module.RaidStart and Active and Module.CheckRequired(self) then
							local Plr = game.Players:GetPlayerFromCharacter(Part.Parent)
							if Plr and Part.Parent:FindFirstChild("Humanoid") and Part.Parent.Humanoid.Health > 0 then
								if ((self.AwayOwned and Module.HomeTeams or Module.AwayTeams)[Plr.Team] and self.LastSafe ~= self.TargetPos) then
									self:SetCarrier(Plr)
								elseif ((self.AwayOwned and Module.AwayTeams or Module.HomeTeams)[Plr.Team] and self.LastSafe ~= self.StartPos and not self.PreventHomePickup) then
									if self.ResetOnHomePickup then
										self.RotateEvent, self.PickupEvent = self.RotateEvent:Disconnect(), self.PickupEvent:Disconnect()
										self:Captured(self.AwayOwned and Module.AwayTeams or Module.HomeTeams)
									else
										self:SetCarrier(Plr)
									end
								end
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
						Pos = self.LastSafe
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
					local Required = true
					for _, Point in ipairs(self.RequiredForCapture or {}) do
						if Point.LastSafe ~= Point.StartPos then
							Required = false
							break
						end
					end
					
					if Required then
						self:Captured(AwaySide)
					end
				elseif (not self.ResetAfter or self.ResetAfter > 1) and self.Carrier.Character and self.Carrier.Character:FindFirstChild("Humanoid") and self.Carrier.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
					self.LastSafe = self.Model.Handle.Position
				end
			end
		end,
		TimeBased = function(self)
			if self.BeenCaptured then
				return false, false, nil
			elseif self.LastSafe == self.StartPos then
				return nil, nil, false
			else
				return false, false, false
			end
		end,
	}, {__index = Module})
	
	-- Table requires Model = Model, Target = Part, TargetDist = Number, Start = Part, StartDist = Number
	return function(CapturePoint)
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
		
		CapturePoint.AncestryChangedEvent = CapturePoint.Model.AncestryChanged:Connect(function()
			if not CapturePoint.Model:IsDescendantOf(workspace) or not CapturePoint.Model:FindFirstChild("Handle") then
				if not CapturePoint.Model:FindFirstChild("Handle") then
					local Kids = CapturePoint.Clone:Clone()
					for _, Kid in ipairs(Kids:GetChildren()) do
						Kid.Parent = CapturePoint.Model
					end
					CapturePoint.Model.Handle.CFrame = CFrame.new(CapturePoint.StartPos)
				end
				wait()
				CapturePoint:SetCarrier(nil)
			end
		end)
		
		if Module.GameMode then
			CapturePoint:Reset()
		end
		
		Module.CapturePoints[#Module.CapturePoints + 1] = CapturePoint
		Module.Event_CapturePointAdded:Fire(#Module.CapturePoints)
		
		return CapturePoint
	end
end