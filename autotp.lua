local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local BACK_DISTANCE = 3 -- positive = behind
local HEIGHT_OFFSET = 0
local COOLDOWN = 0.2 -- small cooldown to prevent accidental spam

local active = false
local lastUsed = 0
local stopCurrent = false -- flag to cancel current attach

-- Get a random enemy player
local function getRandomEnemy()
	local enemies = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer
			and player.Team ~= LocalPlayer.Team
			and player.Character
			and player.Character:FindFirstChild("Humanoid")
			and player.Character.Humanoid.Health > 0 then
			
			table.insert(enemies, player)
		end
	end

	if #enemies > 0 then
		return enemies[math.random(1, #enemies)]
	end
	
	return nil
end

-- Loop attach behind enemies
local function attachLoop()
	if active then
		-- if already active, signal to stop current loop
		stopCurrent = true
		return
	end

	active = true
	stopCurrent = false
	
	while active do
		local character = LocalPlayer.Character
		if not character then break end
		
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			break
		end
		
		local target = getRandomEnemy()
		if not target then
			task.wait(0.5)
			continue
		end
		
		local targetChar = target.Character
		local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		local targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
		
		if not targetRoot or not targetHumanoid then
			continue
		end
		
		-- Attach to target until they die or Shift is pressed again
		repeat
			if stopCurrent or humanoid.Health <= 0 then
				stopCurrent = false
				break
			end
			
			local behindCFrame = targetRoot.CFrame * CFrame.new(0, HEIGHT_OFFSET, BACK_DISTANCE)
			root.CFrame = CFrame.new(
				behindCFrame.Position,
				behindCFrame.Position + targetRoot.CFrame.LookVector
			)
			
			task.wait(0.05)
		until targetHumanoid.Health <= 0
	end
	
	active = false
	stopCurrent = false
end

-- Detect Shift key
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		local now = tick()
		if now - lastUsed < COOLDOWN then return end
		
		lastUsed = now
		attachLoop() -- starts new attach or switches immediately
	end
end)
