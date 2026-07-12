--- Tiny declarative instance builder shared by the window and overlay
--- elements. `UI.new(class, props, children)` cuts the `Instance.new` +
--- property-assignment boilerplate down to one call, and the helpers
--- ([[UI.corner]], [[UI.stroke]], [[UI.padding]], [[UI.gradient]]) cover the
--- decoration instances every element repeats.
--- @section Support
--- @client

local UI = {}

--- Creates an instance, assigns `props`, parents `children` to it, and
--- (last) applies `props.Parent` so children exist before the tree is live.
--- @param className the Roblox class, e.g. "Frame"
--- @param props a map of properties; `Parent` is applied after children
--- @param children an array of instances to parent to the new instance
function UI.new(className: string, props: { [string]: any }?, children: { Instance }?): Instance
	local instance = Instance.new(className)
	if props then
		for key, value in props do
			if key ~= "Parent" then
				(instance :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

--- A UICorner with the given radius (default 8px).
function UI.corner(radius: UDim?): UICorner
	return UI.new("UICorner", { CornerRadius = radius or UDim.new(0, 8) }) :: UICorner
end

--- A UIStroke in the given colour, thickness, and transparency.
function UI.stroke(color: Color3, thickness: number?, transparency: number?): UIStroke
	return UI.new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}) :: UIStroke
end

--- A uniform UIPadding of `all` pixels on every side.
function UI.padding(all: number): UIPadding
	local px = UDim.new(0, all)
	return UI.new("UIPadding", {
		PaddingTop = px, PaddingBottom = px, PaddingLeft = px, PaddingRight = px,
	}) :: UIPadding
end

--- A vertical or horizontal UIListLayout with a pixel gap.
function UI.list(fillDirection: Enum.FillDirection, gap: number?): UIListLayout
	return UI.new("UIListLayout", {
		FillDirection = fillDirection,
		Padding = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}) :: UIListLayout
end

--- A vertical two-stop UIGradient, handy for subtle window backdrops.
function UI.gradient(top: Color3, bottom: Color3, rotation: number?): UIGradient
	return UI.new("UIGradient", {
		Color = ColorSequence.new(top, bottom),
		Rotation = rotation or 90,
	}) :: UIGradient
end

return UI
