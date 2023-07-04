local HitBox = {
	OverlapParameters = nil,
}

--Single Inheritance
HitBox.__index = HitBox
local Players = game:GetService("Players")

local function CreateHitBox(self):{}
	local size
	local ToolCFrame

	--Setting OverlapParameters To Filter
	if not self.OverlapParameters then
		self.OverlapParameters = OverlapParams.new()
		self.OverlapParameters.FilterDescendantsInstances = {self._tool}
		self.OverlapParameters.FilterType = Enum.RaycastFilterType[self._FilterType]
	end
	
	--Switch Methods Based On Class
	if self._tool:IsA("Model") then 
		size = self._tool:GetExtentsSize() ToolCFrame = self._tool:GetPivot() 
	else 
		size = self._tool.Size ToolCFrame = self._tool.CFrame 
	end
	
	--Create A Box To Handle Hit Detection
	local GetPartsInBox = workspace:GetPartBoundsInBox(ToolCFrame, size, self.OverlapParameters)	

	return GetPartsInBox
end

--Identify If A Object Has Been Hit

local function CheckFilteredTable(self, Humanoid, instance):boolean
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

local function FindAllHumanoids(self):{}
	local Clear = false
	local GetPartsInBox = CreateHitBox(self)

	local AllHumanoids = {}
	
	--Loops Through Hit Objects
	for _, instance in GetPartsInBox do
		local Humanoid = instance.Parent:FindFirstChild("Humanoid")
		
		--If Its Already Been Found Then Skip		
		
		if CheckFilteredTable(self, Humanoid, instance) then continue end
		
		--If There Is No Humanoid Then Skip
		
		if not Humanoid then continue end  
		
		if #AllHumanoids == 0 then 
			table.insert(AllHumanoids, Humanoid)
		else
			for _, humanoids in AllHumanoids do --Loop Through All Humanoids Found
				if humanoids ~= Humanoid then continue end
				
				--If It Has Found It Then Dont Insert The Humanoid
				Clear = true
				break
			end

			if not Clear then
				--If Not Found The Insert It Into The Humanoids Table
				table.insert(AllHumanoids, Humanoid)
			end

			Clear = false
		end
	end

	return AllHumanoids
end		

--Create A Constructer For The Hitbox
function HitBox.new(tool)
	local metaTable = setmetatable({
		_canAttack = true,
		_tool = tool,
		_FilterType = "Exclude",
		OnHitEvent = Instance.new("BindableEvent", game.ReplicatedStorage),
		_FilterTable = {},
	}, HitBox)

	return metaTable
end

function HitBox:GetTouchingParts():{}
	--Return EveryPart The Hitbox Has Interacted With
	return CreateHitBox(self)
end

function HitBox:OnHit()
	local ContactParts = CreateHitBox(self)
	local AllHumanoids = FindAllHumanoids(self)
	
	--Fire A BindableEvent When The Hitbox Has Hit Something
	if AllHumanoids or ContactParts then
		self.OnHitEvent:Fire(ContactParts, AllHumanoids)
	end
end

function HitBox:SetFilterType(FilterType : string)
	--Set the FilterType For The Hitbox
	self._FilterType = FilterType
end

function HitBox:GetAllHumanoids(WaitForDelay : boolean):{}
	--Return All Humanoids	
	
	if WaitForDelay then
		--Add A Optional Delay
		repeat task.wait() until self._canAttack 

		return FindAllHumanoids(self)
	else
		return FindAllHumanoids(self)
	end
end

function HitBox:GetFirstHumanoid(WaitForDelay):Humanoid
	--Get The First Humanoid That Was Found
	local GetPartsInBox = CreateHitBox(self)
	
	local function GetHumanoid()
		for _, instance in GetPartsInBox do
			local Humanoid = instance.Parent:FindFirstChild("Humanoid")
			--Look For A Humanoid That Has Not Been Found
			if CheckFilteredTable(self, Humanoid, instance) then continue end
			if Humanoid then return Humanoid end
		end
	end
	
	if WaitForDelay then
		repeat task.wait() until self._canAttack
		--Add A Optional Delay
		return GetHumanoid()
	else
		return GetHumanoid()	
	end
end

function HitBox:AddDelay(DelayTime : number, func)
	--Delay Function To Handle The Hitbox Delays
	task.spawn(function()
		self._canAttack = false
		task.wait(DelayTime)
		self._canAttack = true
		--After The Delay Has Finished Optionally Call A Function
		if func then func() end
	end)	
end

function HitBox:FindSpecificClass(Class : string)
	--Look For A Specific Class Only
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
	--Add To FilterTable So The Hitbox Does Not Pick These Up
	table.insert(self._FilterTable, instance)
end

function HitBox:RemoveFromFilter(instance : Instance, instanceIndex : number?)
	--Remove Instance From The Filter Table
	task.spawn(function()
		for index, filteredInstance in self._FilterTable do
			if instance == filteredInstance or instanceIndex == index then
				--If the Instance Or InstanceIndex Is In The Table Then Remove It
				table.remove(self._FilterTable, index)
				break
			end
		end
	end)
end

function HitBox:GetFilterTable():{}
	--Return The FilterTable
	return self._FilterTable
end

function HitBox:CheckFilters(instance): boolean
	local clear = false
	
	--Check If A Object Is In The Filter Table
	for i, v in self._FilterTable do
		if v == instance then
			clear = true
		end
	end

	return clear
end

return HitBox
