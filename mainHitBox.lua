local HitBox = {
	OverlapParameters = nil,
}

HitBox.__index = HitBox
local Players = game:GetService("Players")

local function CreateHitBox(self)
	local size
	local ToolCFrame

	if not self.OverlapParameters then
		self.OverlapParameters = OverlapParams.new()
		self.OverlapParameters.FilterDescendantsInstances = {self._tool}
		self.OverlapParameters.FilterType = Enum.RaycastFilterType[self._FilterType]
	end

	if self._tool:IsA("Model") then size = self._tool:GetExtentsSize() ToolCFrame = self._tool:GetPivot() else size = self._tool.Size ToolCFrame = self._tool.CFrame end

	local GetPartsInBox = workspace:GetPartBoundsInBox(ToolCFrame, size, self.OverlapParameters)	

	return GetPartsInBox
end

local function CheckFilteredTable(self, Humanoid, instance)
	local SetFilter = false

	for _, filteredParts in self._FilterTable do
		if Humanoid then
			if Humanoid == filteredParts or instance == filteredParts then
				SetFilter = true
				break
			end
		else
			if instance == filteredParts then
				SetFilter = true
				break
			end
		end
	end

	return SetFilter
end

function HitBox.new(tool, Size, BoxCFrame)
	if not tool then	if not Size and not BoxCFrame then return end end

	local size = tool or Size
	local ToolCFrame = tool or BoxCFrame

	local metaTable = setmetatable({
		_canAttack = true,
		_tool = tool,
		_FilterType = "Exclude",
		OnHitEvent = Instance.new("BindableEvent", game.ReplicatedStorage),
		_FilterTable = {}
	}, HitBox)

	return metaTable
end

function HitBox:GetTouchingParts()
	return CreateHitBox(self)
end

function HitBox:OnHit()
	pcall(function()
		self.OnHitEvent:Fire(CreateHitBox(self))
	end)
end

function HitBox:SetFilterType(FilterType)
	self._FilterType = FilterType
end

function HitBox:GetAllHumanoids(WaitForDelay)
	local GetPartsInBox = CreateHitBox(self)
	local Clear = false
	local SetFilter = false
	local AllHumanoids = {}

	local function FindAllHumanoids()
		for _, instance in GetPartsInBox do
			local Humanoid = instance.Parent:FindFirstChild("Humanoid")

			if CheckFilteredTable(self, Humanoid, instance) then continue end

			if not Humanoid then continue end  

			if #AllHumanoids == 0 then 
				table.insert(AllHumanoids, Humanoid)
			else
				for _, humanoids in AllHumanoids do
					if humanoids ~= Humanoid then continue end
					Clear = true
					break
				end

				if not Clear then
					table.insert(AllHumanoids, Humanoid)
				end

				Clear = false
			end
		end

		return AllHumanoids
	end		

	if WaitForDelay then
		repeat task.wait() until self._canAttack 

		return FindAllHumanoids()
	else
		return FindAllHumanoids()
	end
end

function HitBox:GetFirstHumanoid(WaitForDelay)
	local GetPartsInBox = CreateHitBox(self)

	local function GetHumanoid()
		for _, instance in GetPartsInBox do
			local Humanoid = instance.Parent:FindFirstChild("Humanoid")
			if CheckFilteredTable(self, Humanoid, instance) then continue end
			if Humanoid then return Humanoid end
		end
	end

	if WaitForDelay then
		repeat task.wait() until self._canAttack

		return GetHumanoid()
	else
		return GetHumanoid()	
	end
end

function HitBox:AddDelay(DelayTime, func)
	task.spawn(function()
		self._canAttack = false
		task.wait(DelayTime)
		self._canAttack = true
		if func then func() end
	end)	
end

function HitBox:FindSpecificClass(Class)
	local GetPartInBox = CreateHitBox(self)
	local AllSpecificInstances = {}
	local FirstInstance

	for _, instance in GetPartInBox do
		if instance.ClassName ~= Class then continue end
		if not FirstInstance then FirstInstance = instance end
		table.insert(AllSpecificInstances, instance)
	end

	return FirstInstance, AllSpecificInstances
end

function HitBox:AddToFilter(instance)
	table.insert(self._FilterTable, instance)
end

function HitBox:RemoveFromFilter(instance, instanceIndex)
	task.spawn(function()
		for index, filteredInstance in self._FilterTable do
			if instance == filteredInstance or instanceIndex == index then 
				table.remove(self._FilterTable, index)
				break
			end
		end
	end)
end

function HitBox:GetFilterTable()
	return self._FilterTable
end

function HitBox:CheckFilters(humanoids)
	local clear = false

	for i, v in self._FilterTable do
		if v == humanoids then
			clear = true
		end
	end

	return clear
end

return HitBox
