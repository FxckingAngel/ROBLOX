local shared      = _G.KS_Shared or error("KS_Shared missing")
local CoreGui     = shared.CoreGui
local UserInputService = shared.UserInputService
local Players     = shared.Players

local KS_ModelViewer = { Gui = nil, Target = nil }

local function makeDraggable(header, frame)
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function createGui()
    if KS_ModelViewer.Gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "KoroneModelViewer"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Enabled        = false
    gui.Parent         = CoreGui

    local main = Instance.new("Frame")
    main.AnchorPoint      = Vector2.new(0.5, 0.5)
    main.Position         = UDim2.new(0.5, 0, 0.5, 0)
    main.Size             = UDim2.new(0, 360, 0, 260)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    main.BorderSizePixel  = 0
    main.Parent           = gui
    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 10)
    mc.Parent       = main

    local top = Instance.new("Frame")
    top.Size             = UDim2.new(1, 0, 0, 30)
    top.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
    top.BorderSizePixel  = 0
    top.Parent           = main
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 10)
    tc.Parent       = top

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size             = UDim2.new(1, -60, 1, 0)
    title.Position         = UDim2.new(0, 10, 0, 0)
    title.Font             = Enum.Font.SourceSansSemibold
    title.TextSize         = 18
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.TextColor3       = Color3.new(1, 1, 1)
    title.Text             = "🧊 3D Model Viewer"
    title.Parent           = top

    local btnClose = Instance.new("TextButton")
    btnClose.Size             = UDim2.new(0, 26, 0, 22)
    btnClose.Position         = UDim2.new(1, -30, 0.5, -11)
    btnClose.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
    btnClose.BorderSizePixel  = 0
    btnClose.Font             = Enum.Font.SourceSansBold
    btnClose.Text             = "X"
    btnClose.TextSize         = 16
    btnClose.TextColor3       = Color3.new(1, 1, 1)
    btnClose.Parent           = top
    local bcc = Instance.new("UICorner")
    bcc.CornerRadius = UDim.new(0, 6)
    bcc.Parent       = btnClose

    local viewport = Instance.new("ViewportFrame")
    viewport.AnchorPoint      = Vector2.new(0.5, 0.5)
    viewport.Position         = UDim2.new(0.5, 0, 0.5, 10)
    viewport.Size             = UDim2.new(1, -20, 1, -50)
    viewport.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    viewport.BorderSizePixel  = 0
    viewport.Parent           = main
    local vc = Instance.new("UICorner")
    vc.CornerRadius = UDim.new(0, 8)
    vc.Parent       = viewport

    local cam = Instance.new("Camera")
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    local function setTarget(inst)
        for _, c in ipairs(viewport:GetChildren()) do
            if c:IsA("BasePart") or c:IsA("Model") then
                c:Destroy()
            end
        end
        if not inst then return end
        local clone = inst:Clone()
        clone.Parent = viewport

        local cf, size = clone:GetBoundingBox()
        local radius   = size.Magnitude
        cam.CFrame     = cf * CFrame.new(0, 0, radius * 1.5)
        cam.Focus      = cf
    end

    KS_ModelViewer.SetTarget = setTarget

    btnClose.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    makeDraggable(top, main)
    KS_ModelViewer.Gui  = gui
    KS_ModelViewer.View = viewport
end

function KS_ModelViewer.Open(inst)
    createGui()
    KS_ModelViewer.Gui.Enabled = true
    KS_ModelViewer.SetTarget(inst or workspace)
end

_G.KS_ModelViewer = KS_ModelViewer
