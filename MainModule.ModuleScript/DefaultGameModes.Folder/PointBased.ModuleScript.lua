--[[
RaidLib.SetGameMode{
	
	Function = Module.GameModeFunctions.PointBased,
	
	WinPoints = 60, -- How many points a team needs to win
	
	HomePointsPerSecond = 1, -- How many points per second home team gets from a point
	
	AwayPointsPerSecond = 1, -- How many points per second away team gets from a point
	
	HomeUnownedDrainPerSecond = 0, -- How many points home team loses per second if they own no points
	
	AwayUnownedDrainPerSecond = 0, -- How many points away team loses per second if they own no points
	
	WinBy = nil, -- To win, the team must have this many more points than the other team when over the WinPoints (e.g. if this is 25 and away has 495, home must get 520 to win)
	
}
]]

return function(RaidLib, Time, Required)
	local HomeAdd, AwayAdd = 0, 0
	for _, CapturePoint in ipairs(Required) do
		if CapturePoint.PointBased and CapturePoint.Active then
			local TempHomeAdd, TempAwayAdd = CapturePoint:PointBased()
			HomeAdd, AwayAdd = HomeAdd + (TempHomeAdd or 0), AwayAdd + (TempAwayAdd or 0)
		end
	end
	
	RaidLib.AwayWinAmount.Value, RaidLib.HomeWinAmount.Value = math.clamp(RaidLib.AwayWinAmount.Value + (AwayAdd == 0 and -(RaidLib.GameMode.AwayUnownedDrainPerSecond or 0) or AwayAdd) * Time, 0, RaidLib.GameMode.WinPoints), math.clamp(RaidLib.HomeWinAmount.Value + (HomeAdd == 0 and -(RaidLib.GameMode.HomeUnownedDrainPerSecond or 0) or HomeAdd) * Time, 0, RaidLib.GameMode.WinPoints)
	
	if RaidLib.AwayWinAmount.Value ~= RaidLib.HomeWinAmount.Value then
		if RaidLib.RaidStart + RaidLib.CurRaidLimit <= tick() then
			if RaidLib.AwayWinAmount.Value > RaidLib.HomeWinAmount.Value then
				return "Lost"
			else
				return "Won"
			end
		elseif RaidLib.AwayWinAmount.Value >= RaidLib.GameMode.WinPoints and (not RaidLib.GameMode.WinBy or (RaidLib.AwayWinAmount.Value - RaidLib.HomeWinAmount.Value >= RaidLib.GameMode.WinBy)) then
			return "Lost"
		elseif RaidLib.HomeWinAmount.Value >= RaidLib.GameMode.WinPoints and (not RaidLib.GameMode.WinBy or (RaidLib.HomeWinAmount.Value - RaidLib.AwayWinAmount.Value >= RaidLib.GameMode.WinBy)) then
			return "Won"
		end
	end
end