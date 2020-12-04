--[[
RaidLib.SetGameMode{
	Function = RaidLib.GameModeFunctions.TimeBased,
	WinTime = 60 * 25, -- 25 minutes holding all capturepoints to win the raid
	RollbackSpeed = 1, -- How much the win timer rolls back per second when home owns the points
	WinSpeed = 1, -- How much the win timer goes up per second when away owns the points
	ExtraTimeForCapture = 0, -- The amount of extra time added onto the raid timer when a point is captured/a payload reaches its end
	ExtraTimeForCheckpoint = 0, -- The amount of extra time added onto the raid timer when a payload reaches a checkpoint
	SetTimeForCapture = nil, -- The amount of extra time added onto the raid timer when a point is captured/a payload reaches its end
	SetTimeForCheckpoint = nil, -- The amount of extra time added onto the raid timer when a payload reaches a checkpoint
}
]]

return function(RaidLib, Time, Required)
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
		RaidLib.OvertimeLeewayStart = nil
		
		RaidLib.SetWinTimer(RaidLib.AwayWinAmount.Value + (RaidLib.GameMode.WinSpeed * Time))
		
		if RaidLib.AwayWinAmount.Value >= RaidLib.GameMode.WinTime then
			return "Lost"
		end
	elseif HomeFullyOwnAll or HomeOwnAll or RaidLib.GameMode.RollbackWithPartialAwayCap then
		if RaidLib.RaidStart + RaidLib.CurRaidLimit <= tick() then
			if RaidLib.OvertimeLeeway then
				RaidLib.OvertimeLeewayStart = RaidLib.OvertimeLeewayStart or tick()
				if tick() >= RaidLib.OvertimeLeewayStart + RaidLib.OvertimeLeeway then
					return "TimeLimit"
				end
			else
				return "TimeLimit"
			end
		end
		
		if (HomeFullyOwnAll or (RaidLib.RollbackWithPartialCap and HomeOwnAll) or RaidLib.GameMode.RollbackWithPartialAwayCap) and RaidLib.AwayWinAmount.Value < RaidLib.GameMode.WinTime and RaidLib.AwayWinAmount.Value > 0 then
			if RaidLib.GameMode.RollbackSpeed then
				RaidLib.SetWinTimer(math.max(0, RaidLib.AwayWinAmount.Value - (RaidLib.GameMode.RollbackSpeed * Time)))
			else
				RaidLib.SetWinTimer(0)
			end
		end
	else
		RaidLib.OvertimeLeewayStart = nil
	end
end