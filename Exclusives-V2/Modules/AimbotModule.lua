
-- Disconnect old aimbot connection
if _G.ezhubaimbot then _G.ezhubaimbot:Disconnect() end

-- Aimbot Vars

local aimbotSettings = {
	enabled = false,
	showfov = true,
	freeforall = true,
	radius = 150,
	wallcheck = false,
	headshot = true,
	rightmouse = true,
	keybind = Enum.KeyCode.E,
	smoothness = 2
}

local players = game:GetService("Players");
local client = players.LocalPlayer;
local inputService = game:GetService("UserInputService");
local aim = false;

-------------------------------------------------------------------------------------------------

-- Aimbot funcs
-- The following settings are places outside of the original aimbotSettings
-- table as they ned to access content inside it.

aimbotSettings.getMousePos = function(aimbotSettings)
	return inputService:GetMouseLocation() - Vector2.new(0, 36);
end

aimbotSettings.matchesFreeForAllConditions = function(aimbotSettings, targetPlayer)
	if aimbotSettings.freeforall == false then
		if client.Team == targetPlayer.Team then
			return false;
		else
			return true;
		end
	else
		return true;
	end
end

aimbotSettings.notObstructing = function(aimbotSettings, destination, ignore)
	if aimbotSettings.wallcheck then
		local parts = workspace.CurrentCamera:GetPartsObscuringTarget({destination}, ignore);
		for i,v in pairs(parts) do
			if v:IsA("BasePart") and v.Transparency <= 2.5 then
				return false;
			end
		end
	end
	return true;
end

aimbotSettings.worldToScreen = function(aimbotSettings, pos)
	return workspace.CurrentCamera:WorldToScreenPoint(pos);
end

aimbotSettings.getClosestToCursor = function(aimbotSettings)
	local mousePos = aimbotSettings.getMousePos(aimbotSettings);
	local radius = aimbotSettings.radius;
	local closest = math.huge;
	local target = nil;
	for _, v in pairs(game:GetService("Players"):GetPlayers()) do
		if aimbotSettings.matchesFreeForAllConditions(aimbotSettings, v) then
			if v and v.Character and v.Character:FindFirstChild("Head") and v ~= game.Players.LocalPlayer then
				local point, onScreen = aimbotSettings.worldToScreen(aimbotSettings, v.Character.Head.Position);
				if onScreen and aimbotSettings.notObstructing(aimbotSettings, v.Character.Head.Position, {
					client.Character,
					v.Character,
                    workspace.CurrentCamera
				}) then
					local distance = (Vector2.new(point.X, point.Y) - mousePos).magnitude;
					if distance < math.min(radius, closest) then
						closest = distance;
						target = v;
					end
				end
			end
		end
	end
	return target;
end

aimbotSettings.aimAtCallback = function(aimbotSettings, target)
	if aimbotSettings.headshot then
		return aimbotSettings.worldToScreen(aimbotSettings, target.Character.Head.Position);
	else
		return aimbotSettings.worldToScreen(aimbotSettings, target.Character.HumanoidRootPart.Position);
	end
end

-------------------------------------------------------------------------------------------------

if _G.Circle then _G.Circle:Remove(); end
_G.Circle = Drawing.new("Circle");
_G.Circle.Radius = 150;
_G.Circle.NumSides = 20;
_G.Circle.Color = Color3.fromRGB(255,0,0);
_G.Circle.Thickness = 1;
_G.Circle.Position = aimbotSettings.getMousePos(aimbotSettings) + Vector2.new(0, 36);

inputService.InputBegan:Connect(function(key)
	if aimbotSettings.rightmouse and key.UserInputType == Enum.UserInputType.MouseButton2 then
		aim = true;
	elseif key.KeyCode == aimbotSettings.keybind and not aimbotSettings.rightmouse then
		aim = true;
	end
end)

inputService.InputEnded:Connect(function(key)
	if aimbotSettings.rightmouse and key.UserInputType == Enum.UserInputType.MouseButton2 then
		aim = false;
	elseif key.KeyCode == aimbotSettings.keybind and not aimbotSettings.rightmouse then
		aim = false;
	end
end)

local updateAimbot = Instance.new("BindableEvent");
coroutine.wrap(function()
	while wait() do
		updateAimbot:Fire();
	end
end)();

_G.ezhubaimbot = updateAimbot.Event:Connect(function()
	_G.Circle.Position = aimbotSettings.getMousePos(aimbotSettings) + Vector2.new(0, 36);
	if aimbotSettings.enabled and aimbotSettings.showfov then
		_G.Circle.Visible = true;
	else
		_G.Circle.Visible = false;
	end

	if aimbotSettings.radius ~= _G.Circle.Radius then _G.Circle.Radius = aimbotSettings.radius; end
	if aimbotSettings.enabled == false or aim == false then
		return;
	end

	local target = aimbotSettings.getClosestToCursor(aimbotSettings);
	if target then
		local aimAt, visible = aimbotSettings.aimAtCallback(aimbotSettings, target);
		if aimAt and aimAt.X and aimAt.Y then
			mousemoverel(
			(aimAt.X - aimbotSettings.getMousePos(aimbotSettings).X) / aimbotSettings.smoothness,
			(aimAt.Y - aimbotSettings.getMousePos(aimbotSettings).Y) / aimbotSettings.smoothness
			- 2);	-- The 2 pixels is just a little bit of bullet compensation (I could not be bothered making a proper system)
		end
	end

end)

_G.change = function(p, v)
	aimbotSettings[p] = v;
end

return aimbotSettings;
