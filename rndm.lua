



-- meow :3 good day 




local NAME = "rndm.lua" 

local math_floor, math_ceil = math.floor, math.ceil
local string_sub = string.sub

local WHITE = Color3.new(1, 1, 1)
local ACCENT = Color3.fromRGB(108, 100, 212)
local C_TEXT = Color3.fromRGB(238, 237, 248)
local C_MUTED = Color3.fromRGB(152, 150, 182)
local C_GOOD = Color3.fromRGB(110, 231, 160)
local C_FAIR = Color3.fromRGB(245, 196, 92)
local C_BAD = Color3.fromRGB(245, 104, 120)

local function has(lib, name)
    return type(lib) == "table" and type(lib[name]) == "function"
end

local clock
if has(globals, "realtime") then
    clock = globals.realtime
elseif type(os) == "table" and type(os.clock) == "function" then
    clock = os.clock
else
    clock = tick
end

local function service(name)
    local ok, result = pcall(function() return game:GetService(name) end)
    if ok then return result end
    return nil
end

local Players = service("Players")
local TextService = service("TextService")
local LP = Players and Players.LocalPlayer

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function pickFont(name)
    local ok, font = pcall(function() return Enum.Font[name] end)
    if ok and font ~= nil then return font end
    return Enum.Font.SourceSansBold
end
local FONT_BLACK = pickFont("GothamBlack")
local FONT_MEDIUM = pickFont("GothamMedium")
local FONT_BOLD = pickFont("GothamBold")

local function viewport()
    local ok, w, h = pcall(function()
        local size = workspace.CurrentCamera.ViewportSize
        return size.X, size.Y
    end)
    if ok and type(w) == "number" and type(h) == "number" and w > 100 and h > 100 then
        return w, h
    end
    return 1920, 1080
end

local function measure(text, size, font)
    if TextService then
        local ok, x = pcall(function()
            return TextService:GetTextSize(text, size, font, Vector2.new(4096, 4096)).X
        end)
        if ok and type(x) == "number" and x > 0 then return x end
    end
    return math_floor(size * 0.62 * #text + 0.5)
end

-- animation helpers
local Anim = { list = {}, n = 0 }

local function ease(id, t)
    if id == 2 then
        local u = 1 - t
        return 1 - u * u * u
    elseif id == 3 then
        local u = 1 - t
        return 1 - u * u * u * u * u
    elseif id == 7 then
        return 1 - 2 ^ (-10 * t)
    elseif id == 8 then
        if t < 0.5 then return 16 * t * t * t * t * t end
        local u = -2 * t + 2
        return 1 - u * u * u * u * u * 0.5
    elseif id == 9 then
        return t * t * t * t
    end
    return t
end

function Anim.new(value)
    return { v = value, a = value, b = value, t0 = 0, d = 0, e = 1, on = false, dirty = true }
end

function Anim.to(o, target, duration, easeId, delay, now)
    o.a = o.v
    o.b = target
    o.d = duration
    o.e = easeId or 3
    o.t0 = (now or clock()) + (delay or 0)
    if not o.on then
        o.on = true
        Anim.n = Anim.n + 1
        Anim.list[Anim.n] = o
    end
end

function Anim.set(o, value)
    o.v = value
    o.a = value
    o.b = value
    o.d = 0
    o.t0 = 0
    o.dirty = true
end

function Anim.step(now)
    local list, n = Anim.list, Anim.n
    local i = 1
    while i <= n do
        local o = list[i]
        local t = now - o.t0
        if t >= o.d then
            o.v = o.b
            o.on = false
            o.dirty = true
            list[i] = list[n]
            list[n] = nil
            n = n - 1
        else
            if t > 0 then
                o.v = o.a + (o.b - o.a) * ease(o.e, t / o.d)
                o.dirty = true
            end
            i = i + 1
        end
    end
    Anim.n = n
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function mount(gui)
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if ok then
        local okParent, parent = pcall(function() return gui.Parent end)
        if okParent and parent ~= nil then return end
    end
    pcall(function()
        local playerGui = LP ~= nil and LP:FindFirstChildOfClass("PlayerGui") or nil
        if playerGui ~= nil then gui.Parent = playerGui end
    end)
end

-- loading screen
local Intro = {
    active = false, t0 = 0, stage = 0, x0 = 0, x1 = 0, slotW = 0,
    aDim = Anim.new(0), aLift = Anim.new(1), aOpen = Anim.new(0), aSub = Anim.new(0),
    aLine = Anim.new(0), aLineA = Anim.new(0),
}

function Intro.build()
    local T = Intro
    local _, sh = viewport()
    local scale = clamp(sh / 900, 0.6, 2.4)
    local F = math_floor(100 * scale + 0.5)
    if F < 40 then F = 40 end
    local first, rest = string_sub(NAME, 1, 1), string_sub(NAME, 2)
    local H = math_ceil(F * 1.26)

    local gui = new("ScreenGui", {
        Name = "RndmIntro", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 10000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    if gui == nil then return end
    T.gui = gui
    mount(gui)

    T.dim = new("Frame", {
        Name = "Dim", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(9, 9, 14),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, gui)

    local mask = new("Frame", {
        Name = "Mask", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 40, 0, H), BackgroundTransparency = 1, ClipsDescendants = true,
    }, gui)
    T.lift = new("Frame", {
        Name = "Lift", Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    }, mask)
    local word = new("Frame", {
        Name = "Word", Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 40, 1, 0),
        BackgroundTransparency = 1, ClipsDescendants = false,
    }, T.lift)

    T.glow = {}
    local unit = F / 100
    local layers = { { 7, 0.9 }, { 4.5, 0.82 }, { 2.5, 0.66 } }
    for i = 1, #layers do
        local L = layers[i]
        local copy = new("TextLabel", {
            Name = "Glow", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, F, 1, 0),
            BackgroundTransparency = 1, Font = FONT_BLACK, TextSize = F,
            Text = first, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 1,
        }, word)
        if copy ~= nil then
            local stroke = new("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = ACCENT,
                Thickness = L[1] * unit, Transparency = 1,
            }, copy)
            if stroke ~= nil then
                T.glow[#T.glow + 1] = { stroke = stroke, base = L[2] }
            end
        end
    end

    local head = new("TextLabel", {
        Name = "First", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, F, 1, 0),
        BackgroundTransparency = 1, Font = FONT_BLACK, TextSize = F,
        Text = first, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 2,
    }, word)
    local slot = new("Frame", {
        Name = "Slot", Position = UDim2.new(0, F, 0, 0), Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1, ClipsDescendants = true,
    }, word)
    local tail = new("TextLabel", {
        Name = "Rest", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, F * 4, 1, 0),
        BackgroundTransparency = 1, Font = FONT_BLACK, TextSize = F,
        Text = rest, TextColor3 = C_TEXT, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, slot)

    if T.lift == nil or word == nil or slot == nil or head == nil or tail == nil then
        T.gui = nil
        pcall(function() gui:Destroy() end)
        return
    end

    local function advance(label, text, fallback)
        local w = nil
        local ok = pcall(function()
            label.Text = text
            w = label.TextBounds.X
        end)
        if ok and type(w) == "number" and w > 1 and w == w then return math_ceil(w + 1) end
        local m = measure(text, F, FONT_BLACK)
        if type(m) == "number" and m > 1 then return math_ceil(m + 1) end
        return fallback
    end
    local wP = advance(head, first, math_ceil(F * 0.62))
    local wR = advance(tail, rest, math_ceil(F * 0.62 * #rest))
    local W = wP + wR

    pcall(function()
        head.Size = UDim2.new(0, wP, 1, 0)
        slot.Position = UDim2.new(0, wP, 0, 0)
        slot.Size = UDim2.new(0, 0, 1, 0)
        tail.Size = UDim2.new(0, wR + 4, 1, 0)
        word.Size = UDim2.new(0, W + 4, 1, 0)
        mask.Size = UDim2.new(0, W + 8, 0, H)
    end)

    T.lineW = math_floor(W * 0.6)
    T.line = new("Frame", {
        Name = "Line", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, math_floor(F * 0.5)),
        Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = ACCENT, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, gui)
    if T.line ~= nil then
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, T.line)
    end

    local user = "player"
    pcall(function() if LP ~= nil and type(LP.Name) == "string" then user = LP.Name end end)
    T.subBase = math_floor(H / 2) + 8
    T.sub = new("TextLabel", {
        Name = "Welcome", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, T.subBase + 6),
        Size = UDim2.new(0, 400, 0, 24), BackgroundTransparency = 1, Font = FONT_MEDIUM,
        TextSize = clamp(math_floor(F * 0.17 + 0.5), 12, 24), Text = string.lower("welcome, " .. user),
        TextColor3 = C_MUTED, TextTransparency = 1,
    }, gui)

    T.word = word
    T.slot = slot
    T.wP = wP
    T.x0 = -wP / 2
    T.x1 = -W / 2
    T.slotW = wR
end

function Intro.cleanup()
    local T = Intro
    T.active = false
    if T.gui ~= nil then
        pcall(function() T.gui:Destroy() end)
        T.gui = nil
    end
    local hook = T.onDone
    if hook ~= nil then
        T.onDone = nil
        pcall(hook)
    end
end

function Intro.start()
    local ok = pcall(Intro.build)
    local T = Intro
    if not ok or T.gui == nil or T.slot == nil or T.word == nil then
        Intro.cleanup()
        return
    end
    T.active = true
    T.stage = 0
    T.t0 = clock() + 0.1
end

function Intro.render(now)
    local T = Intro
    local t = now - T.t0
    local stage = T.stage

    if stage == 0 then
        if t >= 0 then
            T.stage = 1
            Anim.to(T.aDim, 0.7, 0.45, 2, 0, now)
            Anim.to(T.aLift, 0, 0.7, 7, 0.05, now)
        end
    elseif stage == 1 then
        if t >= 0.95 then
            T.stage = 2
            Anim.to(T.aOpen, 1, 0.7, 8, 0, now)
            Anim.to(T.aSub, 1, 0.5, 2, 0.35, now)
            Anim.to(T.aLine, 1, 0.7, 3, 0.1, now)
            Anim.to(T.aLineA, 1, 0.25, 2, 0.1, now)
        end
    elseif stage == 2 then
        if t >= 2.55 then
            T.stage = 3
            Anim.set(T.aOpen, 1)
            Anim.to(T.aLift, -1, 0.45, 9, 0, now)
            Anim.to(T.aSub, 0, 0.3, 2, 0, now)
            Anim.to(T.aLineA, 0, 0.35, 2, 0, now)
            Anim.to(T.aDim, 0, 0.5, 2, 0.05, now)
        end
    elseif t >= 3.2 then
        Intro.cleanup()
        return
    end

    local a = T.aDim
    if a.dirty then
        a.dirty = false
        local dim = T.dim
        if dim ~= nil then pcall(function() dim.BackgroundTransparency = 1 - a.v end) end
    end
    a = T.aLift
    if a.dirty then
        a.dirty = false
        local lift = T.lift
        if lift ~= nil then pcall(function() lift.Position = UDim2.new(0, 0, a.v, 0) end) end
    end
    local line = T.line
    if line ~= nil then
        local g, f = T.aLine, T.aLineA
        if g.dirty or f.dirty then
            g.dirty = false
            f.dirty = false
            pcall(function()
                line.Size = UDim2.new(0, math_floor(T.lineW * g.v + 0.5), 0, 2)
                line.BackgroundTransparency = 1 - 0.85 * f.v
            end)
        end
    end
    a = T.aSub
    if a.dirty then
        a.dirty = false
        local sub = T.sub
        if sub ~= nil then
            pcall(function()
                sub.TextTransparency = 1 - a.v
                sub.Position = UDim2.new(0.5, 0, 0.5, T.subBase + (1 - a.v) * 6)
            end)
        end
    end
    local open = clamp(T.aOpen.v, 0, 1)
    local x = T.x0 + (T.x1 - T.x0) * open
    if T.word ~= nil then
        pcall(function() T.word.Position = UDim2.new(0.5, math_floor(x + 0.5), 0, 0) end)
    end
    if T.slot ~= nil then
        pcall(function() T.slot.Size = UDim2.new(0, math_floor(T.slotW * open + 0.5), 1, 0) end)
    end

    local gl = T.glow
    if gl ~= nil and #gl > 0 then
        local g = 0
        if T.stage >= 2 then
            local rise = clamp((t - 1.0) / 0.5, 0, 1)
            local pulse = math.sin(clamp((t - 1.0) / 1.2, 0, 1) * math.pi)
            g = rise * (0.5 + 0.5 * pulse)
            if T.stage >= 3 then g = g * (1 - clamp((t - 2.55) / 0.3, 0, 1)) end
        end
        if g ~= T.glowV then
            T.glowV = g
            for i = 1, #gl do
                local f = gl[i]
                pcall(function() f.stroke.Transparency = 1 - (1 - f.base) * g end)
            end
        end
    end
end

-- Weapon lookup is declared here so the watermark can use the same helper
-- as the resolver, which assigns it later in the script.
local safe_get_weapon

-- watermark (top right)
local WM_TEXT = NAME

local Watermark = {
    alpha = Anim.new(0), on = false, fade = {}, frames = 0, time = 0, nextRefresh = 0,
    reloadStartedAt = nil, reloadWeaponName = nil,
}

function Watermark.build()
    local W = Watermark
    local gui = new("ScreenGui", {
        Name = "RndmWatermark", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 60, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    if gui == nil then return end
    W.gui = gui
    mount(gui)

    local bar = new("Frame", {
        Name = "Bar", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12),
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = Color3.fromRGB(14, 14, 18), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false,
    }, gui)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, bar)
    W.stroke = new("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.fromRGB(50, 48, 80),
        Thickness = 1, Transparency = 1,
    }, bar)
    new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, bar)

    local fade = W.fade
    local function add(inst, prop, base)
        local n = #fade
        fade[n + 1] = inst
        fade[n + 2] = prop
        fade[n + 3] = base
    end
    add(bar, "BackgroundTransparency", 0.1)
    add(W.stroke, "Transparency", 0.2)

    local content = new("Frame", {
        Name = "Content", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
    }, bar)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    }, content)

    local name = new("TextLabel", {
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
        Font = FONT_MEDIUM, TextSize = 13, Text = WM_TEXT, TextColor3 = C_TEXT, TextTransparency = 1, LayoutOrder = 1,
    }, content)
    add(name, "TextTransparency", 0)

    local function stat(order, withDot)
        local divider = new("Frame", {
            Size = UDim2.new(0, 1, 0, 14), BackgroundColor3 = C_MUTED, BackgroundTransparency = 1,
            BorderSizePixel = 0, LayoutOrder = order,
        }, content)
        add(divider, "BackgroundTransparency", 0.7)
        local holder = new("Frame", {
            BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
            LayoutOrder = order + 1,
        }, content)
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5),
        }, holder)
        local dot = nil
        if withDot then
            dot = new("Frame", {
                Size = UDim2.new(0, 6, 0, 6), BackgroundColor3 = C_FAIR, BackgroundTransparency = 1,
                BorderSizePixel = 0, LayoutOrder = 1,
            }, holder)
            new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
            add(dot, "BackgroundTransparency", 0)
        end
        local value = new("TextLabel", {
            BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
            Font = FONT_MEDIUM, TextSize = 12, Text = "", TextColor3 = C_MUTED, TextTransparency = 1, LayoutOrder = 2,
        }, holder)
        add(value, "TextTransparency", 0)
        return dot, value
    end
    W.fpsDot, W.fpsLabel = stat(10, true)
    W.pingDot, W.pingLabel = stat(20, true)
    local _, timeLabel = stat(30, false)
    W.timeLabel = timeLabel
    timeLabel.Text = "v2"
    timeLabel.TextColor3 = ACCENT

    W.reloadLabel = new("TextLabel", {
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0), Font = FONT_MEDIUM, TextSize = 12,
        Text = "", TextColor3 = C_FAIR, TextTransparency = 1, LayoutOrder = 40,
    }, content)
    add(W.reloadLabel, "TextTransparency", 0)
    W.bar = bar
end

function Watermark.refresh()
    local W = Watermark
    local fps = 0
    if W.time > 0 then fps = math_floor(W.frames / W.time + 0.5) end
    W.frames = 0
    W.time = 0
    W.fpsLabel.Text = fps .. " fps"
    W.fpsDot.BackgroundColor3 = fps >= 55 and C_GOOD or (fps >= 30 and C_FAIR or C_BAD)

    local ping = -1
    if has(client, "latency") then
        local ok, s = pcall(client.latency)
        if ok and type(s) == "number" and s >= 0 then ping = math_floor(s * 1000 + 0.5) end
    end
    if ping < 0 then
        W.pingLabel.Text = "n/a"
        W.pingDot.BackgroundColor3 = C_FAIR
    else
        W.pingLabel.Text = ping .. " ms"
        W.pingDot.BackgroundColor3 = ping <= 90 and C_GOOD or (ping <= 180 and C_FAIR or C_BAD)
    end
end

function Watermark.show(now)
    local W = Watermark
    if W.bar == nil then return end
    W.on = true
    W.nextRefresh = 0
    W.bar.Visible = true
    Anim.to(W.alpha, 1, 0.4, 2, 0, now)
end

function Watermark.render(now, dt)
    local W = Watermark
    if W.bar == nil then return end
    local a = W.alpha
    if a.dirty then
        a.dirty = false
        local v = a.v
        local f = W.fade
        for i = 1, #f, 3 do
            f[i][f[i + 1]] = 1 - (1 - f[i + 2]) * v
        end
    end
    if not W.on then return end

    -- Track the live reload state and show elapsed time for the active weapon.
    -- The script exposes a reload boolean, but no per-weapon reload duration,
    -- so an elapsed timer is accurate without guessing a countdown.
    if W.reloadLabel ~= nil and type(weapon) == "table" and type(weapon.is_reloading) == "function" then
        local ok, reloading = pcall(weapon.is_reloading)
        if ok and reloading == true then
            if W.reloadStartedAt == nil then
                W.reloadStartedAt = now
                local active = safe_get_weapon and safe_get_weapon() or nil
                W.reloadWeaponName = active and active.name and tostring(active.name) or nil
            end
            local elapsed = math.max(0, now - W.reloadStartedAt)
            local weaponText = W.reloadWeaponName and (" · " .. W.reloadWeaponName) or ""
            W.reloadLabel.Text = string.format("RELOADING %.1fs%s", elapsed, weaponText)
        else
            W.reloadStartedAt = nil
            W.reloadWeaponName = nil
            W.reloadLabel.Text = ""
        end
    end

    W.frames = W.frames + 1
    W.time = W.time + dt
    if now >= W.nextRefresh then
        W.nextRefresh = now + 0.5
        W.refresh()
    end
end

function Watermark.cleanup()
    local W = Watermark
    W.on = false
    if W.gui ~= nil then
        pcall(function() W.gui:Destroy() end)
        W.gui = nil
        W.bar = nil
    end
end

-- Reload lengths are learned per weapon from completed reloads.
-- This avoids inventing reload durations that the weapon API does not expose.
local learnedReloadDurations = {}

-- reload indicator (center of screen)
local Indicators = {
    gui = nil,
    reload = nil,
    canReload = type(weapon) == "table" and type(weapon.is_reloading) == "function",
    nextCheck = 0,
    reloadStartedAt = nil,
    reloadWeaponName = nil,
}

function Indicators.build()
    local I = Indicators
    local gui = new("ScreenGui", {
        Name = "RndmIndicators", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    if gui == nil then return end
    I.gui = gui
    mount(gui)

    local root = new("Frame", {
        Name = "Indicators",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.5, 24),
        Size = UDim2.fromOffset(200, 40),
        BackgroundTransparency = 1,
    }, gui)

    new("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 2),
    }, root)

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 17),
        BackgroundTransparency = 1,
        Font = FONT_BOLD,
        TextSize = 15,
        Text = "random",
        TextColor3 = ACCENT,
        TextStrokeTransparency = 0.6,
    }, root)

    I.reload = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundTransparency = 1,
        Font = FONT_BOLD,
        TextSize = 11,
        TextScaled = false,
        Text = "RELOADING",
        TextColor3 = C_FAIR,
        TextStrokeTransparency = 0.6,
        Visible = false,
    }, root)
end

function Indicators.render(now)
    local I = Indicators
    if I.reload == nil or not I.canReload then return end
    if now < I.nextCheck then return end
    I.nextCheck = now + 0.07

    local ok, reloading = pcall(weapon.is_reloading)
    if ok and reloading == true then
        if I.reloadStartedAt == nil then
            I.reloadStartedAt = now
            local active = safe_get_weapon and safe_get_weapon() or nil
            I.reloadWeaponName = active and active.name and tostring(active.name) or nil
        end
        local elapsed = math.max(0, now - I.reloadStartedAt)
        local key = I.reloadWeaponName or "__unknown_weapon"
        local duration = learnedReloadDurations[key]
        if duration ~= nil then
            local remaining = math.max(0, duration - elapsed)
            I.reload.Text = string.format("RELOADING %.1fs", remaining)
        else
            I.reload.Text = "RELOADING · learning"
        end
        I.reload.Visible = true
    else
        if I.reloadStartedAt ~= nil then
            local elapsed = math.max(0, now - I.reloadStartedAt)
            if elapsed >= 0.15 and elapsed <= 10 then
                local key = I.reloadWeaponName or "__unknown_weapon"
                learnedReloadDurations[key] = elapsed
            end
        end
        I.reloadStartedAt = nil
        I.reloadWeaponName = nil
        I.reload.Text = "RELOADING"
        I.reload.Visible = false
    end
end

function Indicators.cleanup()
    local I = Indicators
    if I.gui ~= nil then
        pcall(function() I.gui:Destroy() end)
        I.gui = nil
        I.reload = nil
    end
end

-- remove leftovers from previous runs
pcall(function()
    local targets = { "RndmIntro", "RndmWatermark", "RndmIndicators", "PhobiaIntro", "PhobiaWatermark", "PhobiaIndicators" }
    local function wipe(parent)
        if not parent then return end
        for _, name in ipairs(targets) do
            local old = parent:FindFirstChild(name)
            if old then pcall(function() old:Destroy() end) end
        end
    end
    wipe(game:GetService("CoreGui"))
    if LP then
        wipe(LP:FindFirstChildOfClass("PlayerGui"))
    end
end)

local dead = false
local lastPaint = nil

local function onPaint()
    if dead then return end
    local now = clock()
    local dt = now - (lastPaint or now)
    lastPaint = now
    if dt <= 0 or dt > 1 then dt = 0.016 end

    local ok = pcall(function()
        Anim.step(now)
        if Intro.active then
            if now - Intro.t0 > 8 then
                Intro.cleanup()
            else
                Intro.render(now)
            end
        end
        Watermark.render(now, dt)
        Indicators.render(now)
    end)
    if not ok and Intro.active then Intro.cleanup() end
end

local function onShutdown()
    dead = true
    Intro.onDone = nil
    Intro.cleanup()
    Watermark.cleanup()
    Indicators.cleanup()
end

pcall(Watermark.build)
pcall(Indicators.build)
Intro.onDone = function() Watermark.show(clock()) end
Intro.start()

client.set_event_callback("paint", onPaint)
client.set_event_callback("shutdown", onShutdown)








task.delay(3.4, function()
    local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local my_tab = menu.new_tab("Resolver", "rbxassetid://10734975692")
local rage_sec = my_tab:new_section("Rage & Resolver", "Left")
local hud_sec = my_tab:new_section("Visuals", "Right")

-- ================= RESOLVER SETTINGS =================
local rage_enable = rage_sec:new_toggle("Enable Lua Resolver", true)
local auto_disable_native = rage_sec:new_toggle("Auto-Disable In-Game Resolver", true)
local disable_me  = rage_sec:new_toggle("Disable if Local Jump/Move", false)
local fd_detect   = rage_sec:new_toggle("Exact Fake Duck API", true)
local dmg_check   = rage_sec:new_toggle("Damage-Validated Hits", true)
local hold_ticks  = rage_sec:new_slider("Hold Angle on Shot", 0, 10, 3, 0, " ticks")
local lethal_safe = rage_sec:new_toggle("Lethal Safepoint", true)
local lethal_dist = rage_sec:new_slider("Lethal Distance", 10, 100, 40, 0, " studs")
local anti_brute  = rage_sec:new_toggle("Defeat Anti-Bruteforce", true)
local random_jitter = rage_sec:new_toggle("Defeat Random Jitter", true)
local free_stand  = rage_sec:new_toggle("Detect Freestanding", true)
local use_hitbox_res = rage_sec:new_toggle("Hitbox Resolver (ChatGPT)", true)
local track_movement = rage_sec:new_toggle("Track Enemy Movement", true)
local track_air      = rage_sec:new_toggle("Track Enemy In-Air", true)
local target_sel     = rage_sec:new_combobox("Target Selection", {"Near crosshair", "Highest damage", "Best hitchance", "Cycle"}, "Best hitchance")

-- [PEEKER CONFIG] Beta Resolver is ON
local show_hud = hud_sec:new_toggle("Show HVH HUD", true)
local use_beta_res = hud_sec:new_toggle("Enable Beta Resolver", true) 
local res_lock = hud_sec:new_combobox("Method Lock", {"Auto", "predict", "mode", "mean", "memory", "modded", "box", "chatgpt", "exploit"}, "Auto")
local res_explore = hud_sec:new_slider("Exploration %", 0, 100, 30, 0, "%")
local res_fallback = hud_sec:new_slider("Brute fallback after", 0, 5, 2, 0, " misses")
local adapt_hc = hud_sec:new_toggle("Adapt Hitchance", true) 
local base_hc = hud_sec:new_slider("Base Hitchance", 1, 100, 65, 0, "%")

-- ================= ADV RESOLVER CORE STATE =================
local function key_for(player_or_slot)
    if not player_or_slot then return "0" end
    if type(player_or_slot) == "userdata" and player_or_slot.Name then return player_or_slot.Name
    elseif type(player_or_slot) == "number" then local ok, info = pcall(entity.get_info, player_or_slot); if ok and info and info.name then return info.name end end
    return tostring(player_or_slot)
end

local target_state = {}
local is_disabled_for_movement = false

local function state_for(key)
    local s = target_state[key]
    if not s then
        s = {
            miss = 0, soft_miss = 0, hit = 0, fallback_misses = 0, fallback_active = false,
            last_activity = 0, last_miss_time = 0, shot_lock_until = 0, last_lby = 0, lby_change = 0, 
            spin_counter = 0, jitter_counter = 0, last_lby_delta = 0, last_offset = 0, last_angle = nil, 
            angle_score = {}, last_hit_sign = nil, jitter_score = 0, last_mag = nil, aa_off = false,
            last_pos = nil, fake_duck = false, stage = 1, is_air = false, is_moving = false, is_crouching = false,
            is_freestanding = false, is_lethal = false,
            last_sent_yaw = nil, last_sent_offset = nil, last_sent_baim = nil, last_sent_safe = nil, last_sent_pitch = nil, last_sent_lock = nil, aa_type_str = "Static",
            hist = {}, steps = {}, phist = {}, scores = {}, last_good = {},
            method = nil, need_choose = true, ctx = "stand", class = "UNKNOWN", period = nil,
            cur = 0, stable = nil, offs = {}, tried = {},
            prev_eye = nil, prev_pitch = nil, prev_delta = nil, hc_bonus = 0,
            cache = { hits = 0, misses = 0, buckets = {}, shots = {} },
            pp = { acc = { persist = 0.3, period = 0.3, markov = 0.3 }, preds = {}, trans = {}, q1 = nil, q2 = nil, best = nil, scored = 0 },
            hb = { sums = { [1] = { c = 0, s = 0, n = 0 }, [-1] = { c = 0, s = 0, n = 0 } }, sign = 1, shift = 0, R = 0, ok = false }
        }
        target_state[key] = s
    end
    return s
end

local BRUTE_ANGLES = { 58, -58, 0, 86, -86, 45, -45 }
local resolver_stats = { shots_fired = 0, hits = 0, misses = 0, res_hits = 0, res_misses = 0, total = 0, spread_misses = 0, occ_misses = 0, death_local_misses = 0, death_target_misses = 0 }
local killstreak = 0

safe_get_weapon = function()
    local ok, wep = pcall(function() return weapon.get_active() end)
    if ok and wep then return wep end
    return nil
end

local function wrap180(a) a = a % 360; if a > 180 then a = a - 360 end; if a < -180 then a = a + 360 end; return a end
local function norm(a) return (a + 180) % 360 - 180 end
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function push(list, v, cap) list[#list+1] = v; if #list > cap then table.remove(list, 1) end end
local function avg(list, from) from = from or 1; local s, c = 0, 0; for i = from, #list do s += list[i]; c += 1 end; return (c > 0) and (s / c) or 0 end
local function stddev(list) if #list < 2 then return 0 end; local m = avg(list); local s = 0; for _, v in ipairs(list) do s += (v - m) ^ 2 end; return math.sqrt(s / #list) end
local function mode_bucket(list, w) local counts, sums = {}, {}; local bestk, bestc = nil, 0; for _, v in ipairs(list) do local k = math.floor((v + 180) / w); counts[k] = (counts[k] or 0) + 1; sums[k] = (sums[k] or 0) + v; if counts[k] > bestc then bestc = counts[k]; bestk = k end end; if not bestk then return 0 end; return sums[bestk] / counts[bestk] end

local function get_desync_mag(info) if not info then return 0 end; if info.desync_delta and math.abs(info.desync_delta) > 0 then return math.abs(info.desync_delta) end; if info.twist_deg and math.abs(info.twist_deg) > 0 then return math.abs(info.twist_deg) end; return 0 end
local function score_for(s, angle) return s.angle_score[math.floor(angle + 0.5)] or 0 end
local function bump_score(s, angle, delta) local k = math.floor(angle + 0.5); s.angle_score[k] = math.max(-15, math.min(25, (s.angle_score[k] or 0) + delta)) end

-- ================= CLAUDE.WIN HELPER FUNCTIONS =================
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local PRED_TOL, PRED_MIN_ACC = 18, 0.45
local function qbucket(v) return math.floor((v + 180) / 20) end
local function best_period(h)
    local n = #h; local bp, be = nil, 1e9
    for p = 2, 10 do
        if n >= p * 2 + 1 then
            local err, cnt = 0, 0
            for i = n, math.max(p + 1, n - 11), -1 do err += math.abs(norm(h[i] - h[i - p])); cnt += 1 end
            err = err / cnt
            if err < be then be, bp = err, p end
        end
    end
    return bp, be
end

local function learn_sample(state, v)
    local pp = state.pp
    local scored = false
    for name, pv in pairs(pp.preds) do pp.acc[name] = pp.acc[name] * 0.85 + ((math.abs(norm(pv - v)) < PRED_TOL) and 1 or 0) * 0.15; scored = true end
    if scored then pp.scored += 1 end
    local qv = qbucket(v)
    if pp.q1 and pp.q2 then
        local k = pp.q2 .. "," .. pp.q1
        local row = pp.trans[k]; if not row then row = {}; pp.trans[k] = row end
        local c = row[qv]; if not c then c = { n = 0, sum = 0 }; row[qv] = c end
        c.n += 1; c.sum += v
    end
    pp.q2, pp.q1 = pp.q1, qv
    local preds = { persist = v }
    local bp, be = best_period(state.hist)
    if bp and be < 12 then preds.period = state.hist[#state.hist + 1 - bp] end
    if pp.q1 and pp.q2 then
        local row = pp.trans[pp.q2 .. "," .. pp.q1]
        if row then
            local bn, bsum = 0, 0
            for _, c in pairs(row) do if c.n > bn then bn, bsum = c.n, c.sum end end
            if bn >= 2 then preds.markov = bsum / bn end
        end
    end
    pp.preds = preds
    local best, besta = nil, -1
    for _, name in ipairs({ "period", "markov", "persist" }) do if preds[name] and pp.acc[name] > besta then best, besta = name, pp.acc[name] end end
    pp.best = best
end

local function classify(state)
    local h = state.hist
    if #h < 6 then return "UNKNOWN" end
    local pos, neg = 0, 0
    for _, s in ipairs(state.steps) do if s > 6 then pos += 1 elseif s < -6 then neg += 1 end end
    if #state.steps >= 6 and math.max(pos, neg) >= #state.steps * 0.75 then return "SPIN" end
    if stddev(h) < 6 then return "STATIC" end
    local bp, be = best_period(h)
    if bp and be < 12 then return "PERIODIC" end
    return "RANDOM"
end

local function hb_vec(enemy, name) local ok, v = pcall(entity.get_player_hitbox_position, enemy, name); if ok and v then return v end; return nil end
local function hb_line_axis(enemy, left_name, right_name)
    local l, r = hb_vec(enemy, left_name), hb_vec(enemy, right_name)
    if not l or not r then return nil end
    local lx, lz = l.X or l.x, l.Z or l.z; local rx, rz = r.X or r.x, r.Z or r.z
    if not (lx and lz and rx and rz) then return nil end
    local dx, dz = rx - lx, rz - lz; local span = math.sqrt(dx * dx + dz * dz)
    if span < 0.2 then return nil end
    return math.deg(atan2(dz, dx)), span
end

local function hb_fused_axis(enemy)
    local arm, arm_span = hb_line_axis(enemy, "left_arm", "right_arm")
    local leg, leg_span = hb_line_axis(enemy, "left_leg", "right_leg")
    if arm and leg then
        local diff = norm(leg - arm)
        if diff > 90 then diff = diff - 180 elseif diff < -90 then diff = diff + 180 end
        local wa, wl = math.min(arm_span, 2), math.min(leg_span, 2); local total = wa + wl
        if total > 0 then return norm(arm + diff * (wl / total)), math.min(arm_span, leg_span) end
    end
    return arm or leg, arm_span or leg_span
end

local function hb_calibrate(state, axis, feet)
    local hb = state.hb
    for _, sg in ipairs({ 1, -1 }) do
        local a = math.rad(feet - sg * axis); local t = hb.sums[sg]
        t.c = t.c * 0.998 + math.cos(a); t.s = t.s * 0.998 + math.sin(a); t.n = t.n * 0.998 + 1
    end
    local best, bR = 1, -1
    for _, sg in ipairs({ 1, -1 }) do
        local t = hb.sums[sg]; local R = (t.n > 0) and (math.sqrt(t.c * t.c + t.s * t.s) / t.n) or 0
        if R > bR then best, bR = sg, R end
    end
    local t = hb.sums[best]; hb.sign, hb.R = best, bR; hb.shift = math.deg(atan2(t.s, t.c)); hb.ok = (t.n >= 25 and bR >= 0.6)
end

local V12_CANDS = {}
local function v12_key(ang) return string.format("%.0f", ang) end
local function v12_score(v, ang) return v.scores[v12_key(ang)] or 0 end
local function v12_bump(v, ang, d) local k = v12_key(ang); v.scores[k] = math.max(-15, math.min(25, (v.scores[k] or 0) + d)) end

local function v12_offset(state, info, anim, eye, delta)
    local v = state.v12
    if not v then v = { stage = 1, scores = {}, last_angle = nil, last_lby = 0, lby_change = -99, rmag = nil }; state.v12 = v end
    if not info then return nil end
    local now_s = globals.tickcount() / 64; local speed = info.speed or 0; local air = info.is_in_air and true or false
    local yaw = info.yaw or eye; local lby = info.lby; local tw = info.twist_deg; local pitch = info.pitch or 0
    local mag = 0; local have_mag = false
    if info.desync_delta then mag = math.abs(info.desync_delta); have_mag = true end
    if tw and math.abs(tw) > mag then mag = math.abs(tw); have_mag = true end
    if not have_mag then mag = math.abs(delta) end
    if mag < 5 or (math.abs(pitch) < 2 and mag < 15) then v.last_angle = 0; return 0 end
    if lby then
        if v.last_lby ~= 0 and math.abs(norm(lby - v.last_lby)) > 3 then v.lby_change = now_s end
        v.last_lby = lby
        if now_s - v.lby_change < 0.2 then v.last_angle = norm(lby - yaw); return v.last_angle end
    end
    if tw and math.abs(tw) >= 3 and speed <= 1.5 and not air then v.last_angle = tw; return tw end
    if anim and anim.torso_yaw and anim.eye_angles_y and speed >= 2 then
        local d = norm(anim.torso_yaw - anim.eye_angles_y)
        if math.abs(d) < 90 then v.last_angle = d; return d end
    end
    local base = lby and norm(lby - eye) or 0; if air then base = 0 end
    local n = 0; local function add(a) n += 1; V12_CANDS[n] = norm(a) end
    if tw and math.abs(math.abs(tw) - 90) < 10 then add(90); add(-90) end
    add(base); add(base + mag); add(base - mag); add(base + mag * 0.5); add(base - mag * 0.5)
    if mag > 5 then local hi = math.floor(mag); v.rmag = v.rmag or math.random(math.min(15, hi - 1), hi); add(base + v.rmag); add(base - v.rmag) end
    if mag >= 60 then add(86); add(-86) elseif mag >= 40 then add(58); add(-58) end
    for i = 1, n do for j = i + 1, n do if v12_score(v, V12_CANDS[j]) > v12_score(v, V12_CANDS[i]) then V12_CANDS[i], V12_CANDS[j] = V12_CANDS[j], V12_CANDS[i] end end end
    local off = V12_CANDS[((v.stage or 1) - 1) % n + 1]; v.last_angle = off; return off
end

local function compute_offsets(enemy, state, anim, eye, delta, info)
    local o = {}
    local h = state.hist
    local bp, be = best_period(h)
    state.period = (bp and be < 12) and bp or nil
    local pp = state.pp
    if pp.best and pp.preds[pp.best] and pp.acc[pp.best] >= PRED_MIN_ACC then o.predict = clamp(pp.preds[pp.best], -86, 86) end
    if #h >= 4 then
        local recent = {}
        for i = math.max(1, #h - 15), #h do recent[#recent + 1] = h[i] end
        o.mode = clamp(mode_bucket(recent, 20), -86, 86)
        o.mean = clamp(avg(h, math.max(1, #h - 5)), -86, 86)
    end
    local mem = state.last_good[state.ctx]
    if mem ~= nil then o.memory = mem end
    local axis = hb_line_axis(enemy, "left_arm", "right_arm")
    local fused_axis, fused_span = hb_fused_axis(enemy)
    local still = info and (info.speed or 0) < 2 and not info.is_in_air
    local calibration_axis = fused_axis or axis
    if calibration_axis and still and anim and anim.goal_feet_yaw then hb_calibrate(state, calibration_axis, anim.goal_feet_yaw) end
    if axis and state.hb.ok then
        local d = norm(norm(state.hb.sign * axis + state.hb.shift) - eye)
        o.box = (math.abs(d) > 5) and clamp(d, -86, 86) or 0
    end
    if fused_axis and state.hb.ok then
        local raw = norm(norm(state.hb.sign * fused_axis + state.hb.shift) - eye)
        local cg = state.chatgpt_state
        if not cg then cg = { offset = nil, samples = 0 }; state.chatgpt_state = cg end
        if cg.offset ~= nil then local change = norm(raw - cg.offset); local alpha = (fused_span and fused_span > 0.8) and 0.55 or 0.30; raw = norm(cg.offset + change * alpha) end
        cg.offset = raw; cg.samples = math.min(cg.samples + 1, 100000)
        o.chatgpt = (math.abs(raw) > 5) and clamp(raw, -86, 86) or 0
    end
    local v12o = v12_offset(state, info, anim, eye, delta)
    if v12o ~= nil then o.exploit = clamp(v12o, -86, 86) end
    local c = state.cache
    if c then
        local bk, bv = nil, 0
        for k, b in pairs(c.buckets) do if b.h >= 1 then local v = (b.h + 0.5) / (b.h + b.x + 1); if v > bv then bk, bv = k, v end end end
        if bk and bv >= 0.5 then o.modded = clamp(c.buckets[bk].sum / c.buckets[bk].h, -86, 86) end
    end
    return o
end

local METHODS = {"predict", "mode", "mean", "memory", "modded", "box", "chatgpt", "exploit"}
local CLASS_BIAS = { STATIC = { box = 0.06, exploit = 0.03, mean = 0.02 }, SPIN = { mean = 0.05, box = 0.03 }, PERIODIC = { predict = 0.10 }, RANDOM = { mode = 0.08, exploit = 0.04, mean = 0.02 }, UNKNOWN = { box = 0.05, exploit = 0.03 } }
local PRIOR = {}

local function scores_for(state, ctx) local sc = state.scores[ctx]; if not sc then sc = {}; for _, m in ipairs(METHODS) do sc[m] = { h = 0, x = 0 } end; state.scores[ctx] = sc end; return sc end
local function prior_for(cls, m) local c = PRIOR[cls]; if not c then c = {}; for _, mm in ipairs(METHODS) do c[mm] = { h = 0, x = 0 } end; PRIOR[cls] = c end; return c[m] end

local function choose(state, lock, explore_pct)
    if lock ~= "Auto" and state.offs[lock] ~= nil then return lock end
    local sc = scores_for(state, state.ctx); local N = 0; for _, m in ipairs(METHODS) do N += sc[m].h + sc[m].x end
    local expl = explore_pct / 100; local best, bestv = nil, -1e9
    for i, m in ipairs(METHODS) do
        if state.offs[m] ~= nil then
            local s = sc[m]; local n = s.h + s.x; local rate = (s.h + 1) / (n + 2)
            local pr = prior_for(state.class, m); local prate = (pr.h + 1) / (pr.h + pr.x + 2)
            local v = 0.7 * rate + 0.3 * prate + expl * 0.3 * math.sqrt(math.log(N + 2) / (n + 1)) + ((CLASS_BIAS[state.class] or {})[m] or 0) - 0.001 * i
            if v > bestv then best, bestv = m, v end
        end
    end
    return best or "mean"
end

local function record(state, hit)
    local m = state.method; if not m or state.noaa then return end
    local sc = scores_for(state, state.ctx)
    for _, s in pairs(sc) do s.h *= 0.9; s.x *= 0.9 end
    local pr = prior_for(state.class, m)
    if hit then sc[m].h += 1; pr.h += 1 else sc[m].x += 1; pr.x += 1 end
    state.need_choose = true
end

local function bucket_of(off) return math.floor((off + 90) / 15) end
local function cache_result(key, state, result, reason)
    local c = state.cache; local off = state.shot and state.shot.off or state.cur
    local b = c.buckets[bucket_of(off)]; if not b then b = { h = 0, x = 0, sum = 0 }; c.buckets[bucket_of(off)] = b end
    for _, ob in pairs(c.buckets) do ob.h *= 0.95; ob.x *= 0.95; ob.sum *= 0.95 end
    if result == "hit" then c.hits += 1; b.h += 1; b.sum += off
    elseif reason == "resolver" then c.misses += 1; b.x += 1 end
    state.shot = nil
end

-- =====================================================
-- VORTEX STATE
-- =====================================================
local S = { rng = 123456789, side = false, burst_left = 0, last_flip = 0, force_until = 0, dsy_tick = 0, dsy_real = 63, dsy_fake = -63, jit_tick = 0, jit_step = 0, jit_dir = 1, cur_wep = "?" }
local vortex_stats = { shots_fired = 0, hits = 0, misses = 0, res_hits = 0, per_weapon = {}, miss_reasons = {}, spread_misses = 0, occ_misses = 0, death_local_misses = 0, death_target_misses = 0 }
local hc_active, last_hc = false, nil
local cfg = {} -- Stand AA config, shared with Vortex priority gate
local LOCAL_ANTIAIM_ENABLED = false -- Global kill switch: keep every local AA override disabled.

-- ================= VORTEX UI =================
local vtab     = menu.new_tab("anti aim", "rbxassetid://10734975692")
local inv_sec  = vtab:new_section("Inverter Spam", "Left")
local dsy_sec  = vtab:new_section("Desync Randomizer", "Left")
local wep_sec  = vtab:new_section("Per-Weapon AA", "Right")
local vhud_sec = vtab:new_section("HUD", "Right")
local ext_sec  = vtab:new_section("Extras", "Right")
local brk_sec  = vtab:new_section("Breaker & Anti-Solver", "Right")

local inv_on        = inv_sec:new_toggle("Enable Inverter Spam", false) 
local inv_mode      = inv_sec:new_combobox("Mode", {"Passive","Reactive","Burst","Adaptive"}, "Adaptive")
local inv_pass_rate = inv_sec:new_slider("Passive flip rate", 1, 20, 3, 0, "t")
local inv_burst_len = inv_sec:new_slider("Burst length", 2, 32, 14, 0, "t")
local inv_idle_rate = inv_sec:new_slider("Adaptive idle rate", 1, 32, 8, 0, "t")
local inv_force_key = inv_sec:new_keybind("Manual flip key", "Toggle", "F")

-- [PEEKER CONFIG] Max desync, Asymmetric
local dsy_on          = dsy_sec:new_toggle("Enable Desync Randomizer", false)
local dsy_mode        = dsy_sec:new_combobox("Apply mode", {"Explicit","Limits", "Asymmetric", "Opposite"}, "Asymmetric")
local dsy_random_side = dsy_sec:new_toggle("Randomize side too", true)
local dsy_min         = dsy_sec:new_slider("Min angle", 0, 86, 86, 0, "°")
local dsy_max         = dsy_sec:new_slider("Max angle", 0, 86, 86, 0, "°")
local dsy_rate        = dsy_sec:new_slider("Re-randomize every", 1, 64, 2, 0, "t") 

-- [PEEKER CONFIG] Skitter Jitter
local dsy_jit_mode    = dsy_sec:new_combobox("Jitter Type", {"Sine", "Skitter", "Off"}, "Skitter")
local dsy_jit_range   = dsy_sec:new_slider("Jitter range", 0, 40, 45, 0, "°")
local dsy_jit_speed   = dsy_sec:new_slider("Jitter speed", 1, 16, 3, 0, "t")

local brk_on   = brk_sec:new_toggle("Enable Resolver Breaker", false)
local brk_gap  = brk_sec:new_slider("Gap from brute angles", 8, 25, 20, 0, "°")
local as_on    = brk_sec:new_toggle("Enable Anti-Solver", false)
local as_low   = brk_sec:new_slider("Decoy low desync", 0, 30, 12, 0, "°")
local as_secs  = brk_sec:new_slider("Avoid hit angle for", 2, 30, 15, 0, " s")

local vhud_on          = vhud_sec:new_toggle("Show HUD", true)
local vhud_x           = vhud_sec:new_slider("HUD X", 0, 1920, 1056, 0)
local vhud_y           = vhud_sec:new_slider("HUD Y", 0, 1080, 594, 0)
local vhud_show_stats  = vhud_sec:new_toggle("Show stats", true)
local vhud_show_misses = vhud_sec:new_toggle("Show miss breakdown", true)
local vhud_show_wep    = vhud_sec:new_toggle("Show per-weapon hit%", true)

local ext_air_aa       = ext_sec:new_toggle("Air AA", false)
local ext_low_hp_aa    = ext_sec:new_toggle("Low HP AA", false)

-- =====================================================
-- [BREAKER & ANTI-SOLVER LOGIC]
-- =====================================================
local BRUTE_MAGS = {0, 58, 86}
local function gap_ok(m, gap) for _, b in ipairs(BRUTE_MAGS) do if math.abs(m - b) < gap then return false end end; return true end
local function safe_mag(gap, panic) if panic then return math.random(10, 86) end; for _ = 1, 16 do local m = math.random(gap, 86); if gap_ok(m, gap) then return m end end; return gap end

local as_hist, as_recent, as_burn = {}, {}, {}
local as_flip, as_cur = false, nil
local function as_bucket(v) return math.floor((v + 90) / 15) end
local function as_mean() local s = 0; for _, v in ipairs(as_hist) do s += v end; return (#as_hist > 0) and (s / #as_hist) or 0 end
local function as_mode() local c, best, bc = {}, 0, 0; for _, v in ipairs(as_hist) do local b = as_bucket(v); c[b] = (c[b] or 0) + 1; if c[b] > bc then bc = c[b]; best = b * 15 - 90 + 7.5 end end; return best end
local function as_pick(now)
    local gap = math.floor(brk_gap:get()); local mean, mode = as_mean(), as_mode(); as_flip = not as_flip
    local best, bs = nil, -1e9
    for _ = 1, 6 do
        local side = (math.random() < 0.5) and 1 or -1; local mag
        if math.random() < 0.4 then mag = safe_mag(gap, false) elseif as_flip then mag = math.random(70, 86) else mag = math.random(0, math.floor(as_low:get())) end
        local v = side * mag; local sc = math.abs(v - mean) + math.abs(v - mode) * 0.5 + math.random() * 10
        if (as_burn[as_bucket(v)] or 0) > now then sc -= 400 end
        if sc > bs then bs = sc; best = { side = side, mag = mag, v = v } end
    end
    as_hist[#as_hist + 1] = best.v; if #as_hist > 12 then table.remove(as_hist, 1) end
    as_recent[#as_recent + 1] = best.v; if #as_recent > 3 then table.remove(as_recent, 1) end
    return best
end
local function as_burn_recent(now) local untilt = now + math.floor(as_secs:get()) * 64; for _, v in ipairs(as_recent) do local b = as_bucket(v); for d = -1, 1 do as_burn[b + d] = untilt end end end
local last_hp = nil
local function poll_hit()
    local ok, lp = pcall(entity.get_local_player); if not ok or not lp then return false end
    local ok2, hp = pcall(entity.get_player_health, lp); if not ok2 or type(hp) ~= "number" then return false end
    local hit = last_hp ~= nil and hp < last_hp and hp > 0; last_hp = hp; return hit
end

-- =====================================================
-- MISC TAB
-- =====================================================
local misc_tab = menu.new_tab("Misc", "rbxassetid://10734975692")
local speed_sec = misc_tab:new_section("Speed Indicator", "Left")
local show_speed_indicator = speed_sec:new_toggle("Show Speed Indicator", true)

-- ================= BETTER VIEW =================
-- Reapplies the selected map-geometry style every 50 seconds while enabled.
local better_view_sec = misc_tab:new_section("Better View", "Right")
local better_view_enabled = better_view_sec:new_toggle("Enable Better View", true)
local better_view_transparency = better_view_sec:new_slider("Transparency", 0, 1, 0.75, 2)
local better_view_color = better_view_sec:new_colorpicker("ForceField Color", Color3.fromHex("#5200FF"))

local better_view_last_run = 0
local better_view_last_map = nil
local function better_view_apply_style(obj, target_color, transparency)
    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.ForceField
        obj.Transparency = transparency
        obj.Color = target_color
        if obj:IsA("MeshPart") then
            pcall(function() obj.TextureID = "" end)
        end
    elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
        obj:Destroy()
    end
end

local function better_view_apply_target(target, target_color, transparency)
    if not target then return end
    better_view_apply_style(target, target_color, transparency)
    for _, descendant in ipairs(target:GetDescendants()) do
        better_view_apply_style(descendant, target_color, transparency)
    end
end

local function better_view_refresh()
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local target_color = better_view_color:get()
    local transparency = math.clamp(better_view_transparency:get(), 0, 1)

    local dust = map:FindFirstChild("DustII")
    local geometry = dust and dust:FindFirstChild("Geometry")
    local minecraft2 = geometry and geometry:FindFirstChild("minecraft2")
    if minecraft2 then
        local children = minecraft2:GetChildren()
        local indexed = children[325]
        better_view_apply_target(indexed and indexed:FindFirstChild("Porta B "), target_color, transparency)
        better_view_apply_target(children[360], target_color, transparency)
    end

    local mirage = map:FindFirstChild("Mirage")
    local mirage_geometry = mirage and mirage:FindFirstChild("Geometry")
    if mirage_geometry then
        local mirage_children = mirage_geometry:GetChildren()
        better_view_apply_target(mirage_children[597], target_color, transparency)
        better_view_apply_target(mirage_children[599], target_color, transparency)
        better_view_apply_target(mirage_children[940], target_color, transparency)
        better_view_apply_target(mirage_children[1108], target_color, transparency)
        better_view_apply_target(mirage_children[1995], target_color, transparency)
        better_view_apply_target(mirage_children[911], target_color, transparency)
        better_view_apply_target(mirage_children[1562], target_color, transparency)
        better_view_apply_target(mirage_children[1558], target_color, transparency)
        better_view_apply_target(mirage_children[770], target_color, transparency)
        better_view_apply_target(mirage_children[843], target_color, transparency)
        better_view_apply_target(mirage_children[609], target_color, transparency)
        local special_target = mirage_children[108]
        -- Use the same Better View material, color, and slider transparency for all parts inside .b.
        better_view_apply_target(special_target and special_target:FindFirstChild("b"), target_color, transparency)
    end
end

task.spawn(function()
    while not dead do
        if better_view_enabled:get() then
            local now = clock()
            local current_map = workspace:FindFirstChild("Map")
            if current_map ~= better_view_last_map or now - better_view_last_run >= 1 then
                better_view_last_map = current_map
                better_view_last_run = now
                pcall(better_view_refresh)
            end
        else
            better_view_last_run = 0
        end
        task.wait(0.25)
    end
end)
-- ================= AVATAR SKIN CHANGER =================
-- JSON appearance codes; original avatar is re-fetched from LocalPlayer.UserId.
local avatar_http = service("HttpService")
local avatar_props = {
    "Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso",
    "LeftArm", "RightArm", "LeftLeg", "RightLeg",
    "HatAccessory", "HairAccessory", "FaceAccessory", "NeckAccessory",
    "ShouldersAccessory", "FrontAccessory", "BackAccessory", "WaistAccessory",
    "HeightScale", "WidthScale", "DepthScale", "HeadScale",
    "BodyTypeScale", "ProportionScale", "ClimbAnimation", "FallAnimation",
    "IdleAnimation", "JumpAnimation", "RunAnimation", "SwimAnimation", "WalkAnimation"
}
local avatar_colors = {
    "HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor",
    "LeftLegColor", "RightLegColor"
}
local skin_sec = misc_tab:new_section("Model Changer", "Right")
local skin_enabled = skin_sec:new_toggle("Enable Model Changer", false)
local headless_toggle = skin_sec:new_toggle("Headless", false)
local skin_user_id = skin_sec:new_textbox("Custom User", "Roblox username or numeric UserId", "")
local skin_json = ""
local skin_code = { get = function() return skin_json end, set = function(_, value) skin_json = value end }
local skin_cfg_box = skin_sec:new_textbox("Avatar CFG (JSON)", "Paste or edit avatar JSON here", "")

-- Presets are selected from the dropdown below. The Local preset is
-- generated at load time from the executing player's own Roblox avatar.
local avatar_preset_data = {
    ["classic noob"] = [=[{"SwimAnimation":0,"Face":0,"ProportionScale":0,"username":"sdaaaaaaasf","ClimbAnimation":0,"FrontAccessory":"","FaceAccessory":"","RightArmColor":[0.5058823823928833,0.5058823823928833,0.5058823823928833],"HairAccessory":"","RightArm":0,"Head":0,"FallAnimation":0,"TorsoColor":[0.5058823823928833,0.5058823823928833,0.5058823823928833],"DepthScale":1,"LeftArm":0,"HeightScale":1,"LeftLeg":0,"RightLegColor":[0.5058823823928833,0.5058823823928833,0.5058823823928833],"LeftLegColor":[0.5058823823928833,0.5058823823928833,0.5058823823928833],"WidthScale":1,"BodyTypeScale":0,"BackAccessory":"","LeftArmColor":[0.5058823823928833,0.5058823823928833,0.5058823823928833],"GraphicTShirt":0,"accessories":[{"IsLayered":false,"AccessoryType":"Hat","AssetId":5703665149}],"HeadColor":[0.5058823823928833,0.5058823823928833,0.5058823823928833],"WalkAnimation":0,"HatAccessory":"5703665149","RunAnimation":0,"JumpAnimation":0,"ShouldersAccessory":"","Torso":0,"NeckAccessory":"","userId":12066577198,"IdleAnimation":0,"Shirt":82515121207791,"HeadScale":1,"Pants":81482965904268,"RightLeg":0,"WaistAccessory":""}]=],
    ["job"] = [=[{"SwimAnimation":0,"Face":0,"ProportionScale":0.20000000298023225,"username":"sdaaaaaaasf","ClimbAnimation":0,"FrontAccessory":"","FaceAccessory":"92073781907156","RightArmColor":[0.9764705896377564,0.9764705896377564,0.9764705896377564],"HairAccessory":"","RightArm":0,"Head":0,"FallAnimation":0,"TorsoColor":[0.9764705896377564,0.9764705896377564,0.9764705896377564],"DepthScale":0.949999988079071,"LeftArm":0,"HeightScale":0.8999999761581421,"LeftLeg":0,"RightLegColor":[0.9764705896377564,0.9764705896377564,0.9764705896377564],"LeftLegColor":[0.9764705896377564,0.9764705896377564,0.9764705896377564],"WidthScale":0.8999999761581421,"BodyTypeScale":0.5,"BackAccessory":"","LeftArmColor":[0.9764705896377564,0.9764705896377564,0.9764705896377564],"GraphicTShirt":0,"accessories":[{"IsLayered":false,"AccessoryType":"Face","AssetId":92073781907156}],"HeadColor":[0.9764705896377564,0.9764705896377564,0.9764705896377564],"WalkAnimation":0,"HatAccessory":"","RunAnimation":0,"JumpAnimation":0,"ShouldersAccessory":"","Torso":0,"NeckAccessory":"","userId":12066577198,"IdleAnimation":0,"Shirt":86784871506852,"HeadScale":0.949999988079071,"Pants":105703334970312,"RightLeg":0,"WaistAccessory":""}]=],
    ["Pink"] = [=[{"SwimAnimation":119459207557848,"Face":0,"ProportionScale":0,"username":"sdaaaaaaasf","ClimbAnimation":100847329856258,"FrontAccessory":"","FaceAccessory":"","RightArmColor":[0,0,0],"HairAccessory":"128426333111348","RightArm":109212056131285,"Head":84595712136250,"FallAnimation":116630804595823,"TorsoColor":[0,0,0],"DepthScale":1,"LeftArm":135418661519228,"HeightScale":1,"LeftLeg":98949908575590,"RightLegColor":[1,1,1],"LeftLegColor":[0,0,0],"WidthScale":1,"BodyTypeScale":0,"BackAccessory":"83132050171168,71291246117995","LeftArmColor":[0,0,0],"GraphicTShirt":0,"accessories":[{"IsLayered":false,"AccessoryType":"Back","AssetId":83132050171168},{"IsLayered":false,"AccessoryType":"Back","AssetId":71291246117995},{"IsLayered":false,"AccessoryType":"Hair","AssetId":128426333111348},{"IsLayered":false,"AccessoryType":"Hat","AssetId":117475562207805},{"IsLayered":false,"AccessoryType":"Hat","AssetId":17225320544},{"IsLayered":false,"AccessoryType":"Hat","AssetId":91674562765889},{"IsLayered":false,"AccessoryType":"Hat","AssetId":133467730854076},{"IsLayered":false,"AccessoryType":"Neck","AssetId":106067586439689},{"IsLayered":false,"AccessoryType":"Neck","AssetId":6998001216},{"IsLayered":false,"AccessoryType":"Waist","AssetId":97152461151344}],"HeadColor":[0,0,0],"WalkAnimation":125685092185096,"HatAccessory":"117475562207805,17225320544,91674562765889,133467730854076","RunAnimation":127798602689390,"JumpAnimation":137416280852988,"ShouldersAccessory":"","Torso":48474356,"NeckAccessory":"106067586439689,6998001216","userId":12066577198,"IdleAnimation":0,"Shirt":125826853581300,"HeadScale":1,"Pants":104908372282584,"RightLeg":77155731237408,"WaistAccessory":"97152461151344"}]=],
    ["Black"] = [=[{"SwimAnimation":0,"Face":0,"ProportionScale":0,"username":"sdaaaaaaasf","ClimbAnimation":0,"FrontAccessory":"","FaceAccessory":"17554904945,126331974594830","RightArmColor":[0,0,0],"HairAccessory":"16199722680,13840873383,17637705854","RightArm":0,"Head":0,"FallAnimation":0,"TorsoColor":[0,0,0],"DepthScale":0.800000011920929,"LeftArm":0,"HeightScale":1,"LeftLeg":0,"RightLegColor":[0,0,0],"LeftLegColor":[0,0,0],"WidthScale":0.800000011920929,"BodyTypeScale":0,"BackAccessory":"11704563407","LeftArmColor":[0,0,0],"GraphicTShirt":0,"accessories":[{"IsLayered":false,"AccessoryType":"Back","AssetId":11704563407},{"IsLayered":false,"AccessoryType":"Face","AssetId":17554904945},{"IsLayered":false,"AccessoryType":"Face","AssetId":126331974594830},{"IsLayered":false,"AccessoryType":"Hair","AssetId":16199722680},{"IsLayered":false,"AccessoryType":"Hair","AssetId":17637705854},{"IsLayered":false,"AccessoryType":"Hair","AssetId":13840873383},{"IsLayered":false,"AccessoryType":"Hat","AssetId":79542478825317},{"IsLayered":false,"AccessoryType":"Hat","AssetId":11492263747},{"IsLayered":false,"AccessoryType":"Neck","AssetId":118870553647469},{"IsLayered":false,"AccessoryType":"Neck","AssetId":107411267663272}],"HeadColor":[0,0,0],"WalkAnimation":0,"HatAccessory":"79542478825317,11492263747","RunAnimation":0,"JumpAnimation":0,"ShouldersAccessory":"","Torso":48474356,"NeckAccessory":"118870553647469,107411267663272","userId":12066577198,"IdleAnimation":0,"Shirt":15616500452,"HeadScale":1,"Pants":11787340410,"RightLeg":0,"WaistAccessory":""}]=],
    ["Shark"] = [=[{"SwimAnimation":0,"Face":0,"ProportionScale":0,"username":"sdaaaaaaasf","ClimbAnimation":0,"FrontAccessory":"","FaceAccessory":"109055093266943","RightArmColor":[0.9725490212440491,0.9725490212440491,0.9725490212440491],"HairAccessory":"13840873383,13779142261,17637705854,16199722680,15089852977","RightArm":0,"Head":0,"FallAnimation":0,"TorsoColor":[0.9725490212440491,0.9725490212440491,0.9725490212440491],"DepthScale":0.800000011920929,"LeftArm":0,"HeightScale":1,"LeftLeg":0,"RightLegColor":[0.9725490212440491,0.9725490212440491,0.9725490212440491],"LeftLegColor":[0.9725490212440491,0.9725490212440491,0.9725490212440491],"WidthScale":0.800000011920929,"BodyTypeScale":0,"BackAccessory":"124619267017864","LeftArmColor":[0.9725490212440491,0.9725490212440491,0.9725490212440491],"GraphicTShirt":0,"accessories":[{"IsLayered":false,"AccessoryType":"Back","AssetId":124619267017864},{"IsLayered":false,"AccessoryType":"Face","AssetId":109055093266943},{"IsLayered":false,"AccessoryType":"Hair","AssetId":13779142261},{"IsLayered":false,"AccessoryType":"Hair","AssetId":13840873383},{"IsLayered":false,"AccessoryType":"Hair","AssetId":17637705854},{"IsLayered":false,"AccessoryType":"Hair","AssetId":16199722680},{"IsLayered":false,"AccessoryType":"Hair","AssetId":15089852977},{"IsLayered":false,"AccessoryType":"Hat","AssetId":137519086744741},{"IsLayered":false,"AccessoryType":"Hat","AssetId":104122578333783}],"HeadColor":[0.9725490212440491,0.9725490212440491,0.9725490212440491],"WalkAnimation":0,"HatAccessory":"137519086744741,104122578333783","RunAnimation":0,"JumpAnimation":0,"ShouldersAccessory":"","Torso":48474356,"NeckAccessory":"","userId":12066577198,"IdleAnimation":0,"Shirt":11818550339,"HeadScale":1,"Pants":8729847520,"RightLeg":0,"WaistAccessory":""}]=],
    ["aku_cursed0"] = [=[{"SwimAnimation":619537096,"Face":0,"ProportionScale":0,"username":"aku_cursed0","ClimbAnimation":619535091,"FrontAccessory":"16318705188","FaceAccessory":"17734433677","RightArmColor":[0.6313725709915161,0.7686274647712708,0.5490196347236633],"HairAccessory":"","RightArm":0,"Head":14488197116,"FallAnimation":619535616,"TorsoColor":[0.6313725709915161,0.7686274647712708,0.5490196347236633],"DepthScale":0.8500000238418579,"LeftArm":0,"HeightScale":0.949999988079071,"LeftLeg":115913397983281,"RightLegColor":[0.6313725709915161,0.7686274647712708,0.5490196347236633],"LeftLegColor":[0.6313725709915161,0.7686274647712708,0.5490196347236633],"WidthScale":0.699999988079071,"BodyTypeScale":0,"BackAccessory":"","LeftArmColor":[0.6313725709915161,0.7686274647712708,0.5490196347236633],"GraphicTShirt":0,"accessories":[{"IsLayered":false,"AccessoryType":"Shoulder","AssetId":3240543366},{"IsLayered":false,"AccessoryType":"Hat","AssetId":15200579454},{"AssetId":15728271241,"Order":13,"IsLayered":true,"Puffiness":1,"AccessoryType":"Hair"},{"IsLayered":false,"AccessoryType":"Front","AssetId":16318705188},{"IsLayered":false,"AccessoryType":"Face","AssetId":17734433677},{"AssetId":83894930070746,"Order":6,"IsLayered":true,"Puffiness":1,"AccessoryType":"Pants"}],"HeadColor":[0.6313725709915161,0.7686274647712708,0.5490196347236633],"WalkAnimation":619537468,"HatAccessory":"15200579454","RunAnimation":619536621,"JumpAnimation":619536283,"ShouldersAccessory":"3240543366","Torso":109135035435136,"NeckAccessory":"","userId":7839164878,"IdleAnimation":619535834,"Shirt":99765888867489,"HeadScale":0.949999988079071,"Pants":126426592205098,"RightLeg":100234186631845,"WaistAccessory":""}]=],
    ["pretendlikeyouhearme"] = [=[{"SwimAnimation":2510240941,"Face":0,"ProportionScale":0.5,"username":"pretendlikeyouhearme","ClimbAnimation":5319931619,"FrontAccessory":"","FaceAccessory":"11568711453","RightArmColor":[0.46666666865348816,0.4627451002597809,0.4745098054409027],"HairAccessory":"","RightArm":0,"Head":14488197116,"FallAnimation":754636589,"TorsoColor":[0.46666666865348816,0.4627451002597809,0.4745098054409027],"DepthScale":1,"LeftArm":0,"HeightScale":0.949999988079071,"LeftLeg":0,"RightLegColor":[0.46666666865348816,0.4627451002597809,0.4745098054409027],"LeftLegColor":[0.46666666865348816,0.4627451002597809,0.4745098054409027],"WidthScale":1,"BodyTypeScale":0,"BackAccessory":"","LeftArmColor":[0.46666666865348816,0.4627451002597809,0.4745098054409027],"GraphicTShirt":0,"accessories":[{"IsLayered":false,"AccessoryType":"Face","AssetId":11568711453},{"IsLayered":false,"AccessoryType":"Shoulder","AssetId":14928353936},{"AssetId":102659157896264,"Order":13,"IsLayered":true,"Puffiness":1,"AccessoryType":"Hair"},{"AssetId":129108086892367,"Order":13,"IsLayered":true,"Puffiness":1,"AccessoryType":"Hair"},{"IsLayered":false,"AccessoryType":"Hat","AssetId":138542382349571}],"HeadColor":[0.46666666865348816,0.4627451002597809,0.4745098054409027],"WalkAnimation":619537468,"HatAccessory":"138542382349571","RunAnimation":619536621,"JumpAnimation":1113752285,"ShouldersAccessory":"14928353936","Torso":0,"NeckAccessory":"","userId":2565223507,"IdleAnimation":0,"Shirt":103909513771828,"HeadScale":1,"Pants":96769873739323,"RightLeg":0,"WaistAccessory":""}]=],
    ["Furry"] = [=[{"SwimAnimation":0,"Face":0,"ProportionScale":0,"username":"daxxonpawz","ClimbAnimation":0,"FrontAccessory":"","FaceAccessory":"","RightArmColor":[0.9490196108818054,0.9529411792755127,0.9529411792755127],"HairAccessory":"","RightArm":0,"Head":10638267973,"FallAnimation":0,"TorsoColor":[0.9490196108818054,0.9529411792755127,0.9529411792755127],"DepthScale":1,"LeftArm":0,"HeightScale":1,"LeftLeg":0,"RightLegColor":[0.4313725531107872,0.6000000238418579,0.7921568751335144],"LeftLegColor":[0.4313725531107872,0.6000000238418579,0.7921568751335144],"WidthScale":1,"BodyTypeScale":0,"BackAccessory":"","LeftArmColor":[0.9490196108818054,0.9529411792755127,0.9529411792755127],"GraphicTShirt":0,"accessories":[{"IsLayered":false,"AccessoryType":"Waist","AssetId":12899703533},{"IsLayered":false,"AccessoryType":"Hat","AssetId":13473801131}],"HeadColor":[0.9490196108818054,0.9529411792755127,0.9529411792755127],"WalkAnimation":0,"HatAccessory":"13473801131","RunAnimation":0,"JumpAnimation":0,"IdleAnimation":0,"Torso":48474356,"NeckAccessory":"","userId":11291493435,"LeftLeg":0,"Shirt":17551423754,"HeadScale":1,"Pants":17551407534,"RightLeg":0,"WaistAccessory":"12899703533"}]=],
}
-- A normal dropdown (like the weapon-group selector), not a separate toggle/button.
local preset_picker = skin_sec:new_combobox("Avatar Presets", {"Furry", "Pink", "Black", "Shark", "classic noob", "job", "aku_cursed0", "pretendlikeyouhearme", "local"}, "Furry")
local function skin_load_selected_preset()
    local selected = preset_picker:get()
    local preset_json = avatar_preset_data[selected]

    if selected == "local" then
        local ok, result = pcall(function()
            if not LP then error("Local player not available") end
            local desc = Players:GetHumanoidDescriptionFromUserId(LP.UserId)
            local data = { userId = LP.UserId, username = LP.Name }
            for _, key in ipairs(avatar_props) do
                local valid, value = pcall(function() return desc[key] end)
                if valid and value ~= nil then data[key] = value end
            end
            for _, key in ipairs(avatar_colors) do
                local valid, value = pcall(function() return desc[key] end)
                if valid and value then data[key] = { value.R, value.G, value.B } end
            end
            local valid, accessories = pcall(function() return desc:GetAccessories(true) end)
            if valid and accessories then
                data.accessories = {}
                for _, item in ipairs(accessories) do
                    local entry = {
                        AssetId = item.AssetId,
                        IsLayered = item.IsLayered,
                        Order = item.Order,
                        Puffiness = item.Puffiness
                    }
                    if item.AccessoryType then entry.AccessoryType = item.AccessoryType.Name end
                    table.insert(data.accessories, entry)
                end
            end
            return avatar_http:JSONEncode(data)
        end)
        if not ok then
            warn("[Skin Changer] Could not load local preset:", result)
            return
        end
        preset_json = result
    end

    if not preset_json then
        warn("[Skin Changer] Preset not found: " .. tostring(selected))
        return
    end
    skin_code:set(preset_json)
    pcall(function() skin_cfg_box:set(preset_json) end)
    database.write("rndm_avatar_json", preset_json)
    client.log("[Skin Changer] Loaded preset: " .. tostring(selected))
end

local skin_changed = false
local skin_hidden_parts = {}
local skin_hidden_decals = {}
local skin_cache_skin = nil
local skin_next_scan = 0
local skin_in_first_person = false

local function skin_clear_first_person()
    for part, original in pairs(skin_hidden_parts) do
        pcall(function() part.LocalTransparencyModifier = original end)
    end
    for decal, original in pairs(skin_hidden_decals) do
        pcall(function() decal.Transparency = original end)
    end
    skin_hidden_parts = {}
    skin_hidden_decals = {}
    skin_cache_skin = nil
    skin_next_scan = 0
end

-- Cache the head and accessory parts; never hide the weapon or the entire body.
local function skin_scan_first_person(visual)
    if skin_cache_skin ~= visual then skin_clear_first_person() end
    skin_cache_skin = visual
    local head = visual:FindFirstChild("Head")
    if head then
        if skin_hidden_parts[head] == nil then
            skin_hidden_parts[head] = head.LocalTransparencyModifier
        end
        for _, child in ipairs(head:GetDescendants()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                if skin_hidden_decals[child] == nil then
                    skin_hidden_decals[child] = child.Transparency
                end
            end
        end
    end
    for _, item in ipairs(visual:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Accoutrement") then
            for _, child in ipairs(item:GetDescendants()) do
                if child:IsA("BasePart") then
                    if skin_hidden_parts[child] == nil then
                        skin_hidden_parts[child] = child.LocalTransparencyModifier
                    end
                elseif child:IsA("Decal") or child:IsA("Texture") then
                    if skin_hidden_decals[child] == nil then
                        skin_hidden_decals[child] = child.Transparency
                    end
                end
            end
        end
    end
end

local function skin_first_person_update()
    if not skin_enabled:get() or not skin_changed then
        if skin_in_first_person or next(skin_hidden_parts) or next(skin_hidden_decals) then
            skin_in_first_person = false
            skin_clear_first_person()
        end
        return
    end

    local character = LP and LP.Character
    local visual = character and character:FindFirstChild("VisualSkin")
    local camera = workspace.CurrentCamera
    -- The outer character's Collide part is not animated with the head.
    -- This game's custom camera doesn't reliably place Camera.Focus at the player.
    local reference = character and character:FindFirstChild("Collide")
    if not reference and visual then
        reference = visual:FindFirstChild("HumanoidRootPart")
    end
    if not visual or not reference or not camera then return end

    local ok, distance = pcall(function()
        return (camera.CFrame.Position - reference.Position).Magnitude
    end)
    if not ok then return end

    -- Hysteresis: ignore camera sway near the first/third-person boundary.
    -- Character reference sits below the eye, unlike Camera.Focus.
    if skin_in_first_person then
        if distance > 5 then skin_in_first_person = false end
    elseif distance < 3.5 then
        skin_in_first_person = true
    end

    if not skin_in_first_person then
        if next(skin_hidden_parts) or next(skin_hidden_decals) then
            skin_clear_first_person()
        end
        return
    end

    local now = clock()
    if skin_cache_skin ~= visual or now >= skin_next_scan then
        skin_scan_first_person(visual)
        skin_next_scan = now + 0.5
    end
    for part in pairs(skin_hidden_parts) do
        pcall(function() part.LocalTransparencyModifier = 1 end)
    end
    for decal in pairs(skin_hidden_decals) do
        pcall(function() decal.Transparency = 1 end)
    end
end

local function skin_humanoid()
    local character = LP and LP.Character
    local visual = character and character:FindFirstChild("VisualSkin")
    return visual and visual:FindFirstChild("Humanoid")
end

-- Hide only the VisualSkin head (and its face decals) while Headless is enabled.
-- Keep original values so disabling the toggle or shutting down restores the avatar.
local headless_originals = {}
local function headless_restore()
    for instance, original in pairs(headless_originals) do
        pcall(function() instance.Transparency = original end)
    end
    headless_originals = {}
end

local function headless_update()
    if not headless_toggle:get() then
        if next(headless_originals) then headless_restore() end
        return
    end

    local character = LP and LP.Character
    local visual = character and character:FindFirstChild("VisualSkin")
    local head = visual and visual:FindFirstChild("Head")
    if not head then return end

    if headless_originals[head] == nil then
        headless_originals[head] = head.Transparency
    end
    pcall(function() head.Transparency = 1 end)

    for _, child in ipairs(head:GetDescendants()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            if headless_originals[child] == nil then
                headless_originals[child] = child.Transparency
            end
            pcall(function() child.Transparency = 1 end)
        end
    end
end

headless_toggle:set_callback(function(enabled)
    if enabled then headless_update() else headless_restore() end
end)

local function skin_restore()
    skin_clear_first_person()
    if not skin_changed then return end
    local humanoid = skin_humanoid()
    if not humanoid or not LP then return end
    local ok, err = pcall(function()
        local original = Players:GetHumanoidDescriptionFromUserId(LP.UserId)
        humanoid:ApplyDescriptionReset(original)
    end)
    if ok then
        skin_changed = false
        client.log("[Skin Changer] Original avatar restored")
    else
        warn("[Skin Changer] Restore failed:", err)
    end
end

local function skin_export()
    local entered = tostring(skin_user_id:get() or "")
    entered = entered:match("^%s*(.-)%s*$")
    if entered == "" then
        warn("[Skin Changer] Enter a Roblox username or UserId")
        return
    end

    local ok, result = pcall(function()
        -- Accept either a numeric UserId or a Roblox username.
        local id = tonumber(entered)
        if not id then
            id = Players:GetUserIdFromNameAsync(entered)
        end
        if not id then error("Could not resolve username to a UserId") end

        local desc = Players:GetHumanoidDescriptionFromUserId(id)
        local data = { userId = id, username = entered }
        for _, key in ipairs(avatar_props) do
            local valid, value = pcall(function() return desc[key] end)
            if valid and value ~= nil then data[key] = value end
        end
        for _, key in ipairs(avatar_colors) do
            local valid, value = pcall(function() return desc[key] end)
            if valid and value then data[key] = { value.R, value.G, value.B } end
        end
        local valid, accessories = pcall(function() return desc:GetAccessories(true) end)
        if valid and accessories then
            data.accessories = {}
            for _, item in ipairs(accessories) do
                local entry = {
                    AssetId = item.AssetId,
                    IsLayered = item.IsLayered,
                    Order = item.Order,
                    Puffiness = item.Puffiness
                }
                if item.AccessoryType then entry.AccessoryType = item.AccessoryType.Name end
                table.insert(data.accessories, entry)
            end
        end
        return avatar_http:JSONEncode(data)
    end)
    if not ok then warn("[Skin Changer] Export failed:", result); return end
    skin_code:set(result)
    database.write("rndm_avatar_json", result)
    print("[Skin Changer] Avatar JSON:", result)
end

local function skin_apply(force)
    if not force and not skin_enabled:get() then return end
    skin_clear_first_person()
    local humanoid = skin_humanoid()
    if not humanoid then warn("[Skin Changer] VisualSkin Humanoid not found"); return end
    local json_text = skin_code:get()
    if not json_text or json_text == "" then return end
    local ok, err = pcall(function()
        local data = avatar_http:JSONDecode(json_text)
        if type(data) ~= "table" then error("Avatar JSON must be an object") end
        -- Start from a clean base instead of retaining parts of the previously applied skin.
        local desc = Players:GetHumanoidDescriptionFromUserId(LP.UserId)
        for _, key in ipairs(avatar_props) do
            if data[key] ~= nil then desc[key] = data[key] end
        end
        for _, key in ipairs(avatar_colors) do
            local c = data[key]
            if type(c) == "table" and #c >= 3 then
                desc[key] = Color3.new(c[1], c[2], c[3])
            end
        end
        if type(data.accessories) == "table" then
            local accessories = {}
            for _, a in ipairs(data.accessories) do
                if a.AssetId and a.AccessoryType then
                    table.insert(accessories, {
                        AssetId = a.AssetId,
                        AccessoryType = Enum.AccessoryType[a.AccessoryType],
                        IsLayered = a.IsLayered,
                        Order = a.Order,
                        Puffiness = a.Puffiness
                    })
                end
            end
            desc:SetAccessories(accessories, true)
        end
        humanoid:ApplyDescriptionReset(desc)
    end)
    if not ok then warn("[Skin Changer] Apply failed:", err); return end
    skin_changed = true
    database.write("rndm_avatar_json", json_text)
    client.log("[Skin Changer] Avatar applied")
end

skin_enabled:set_callback(function(on)
    if on then
        skin_apply()
    else
        skin_restore()
    end
end)

-- Keep preset application synchronous, matching the original first-person flow.
preset_picker:set_callback(function()
    skin_load_selected_preset()
    pcall(function() skin_enabled:set(true) end)
    skin_apply(true)
end)

local function skin_apply_custom_user()
    local raw = tostring(skin_user_id:get() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if raw == "" then warn("[Model Changer] Enter a username or UserId"); return end
    local ok, result = pcall(function()
        local user_id = tonumber(raw)
        if not user_id then user_id = Players:GetUserIdFromNameAsync(raw) end
        local desc = Players:GetHumanoidDescriptionFromUserId(user_id)
        local data = { userId = user_id, username = raw }
        for _, key in ipairs(avatar_props) do
            local valid, value = pcall(function() return desc[key] end)
            if valid and value ~= nil then data[key] = value end
        end
        for _, key in ipairs(avatar_colors) do
            local valid, value = pcall(function() return desc[key] end)
            if valid and value then data[key] = { value.R, value.G, value.B } end
        end
        local valid, accessories = pcall(function() return desc:GetAccessories(true) end)
        if valid and accessories then
            data.accessories = {}
            for _, item in ipairs(accessories) do
                local entry = { AssetId = item.AssetId, IsLayered = item.IsLayered, Order = item.Order, Puffiness = item.Puffiness }
                if item.AccessoryType then entry.AccessoryType = item.AccessoryType.Name end
                table.insert(data.accessories, entry)
            end
        end
        return avatar_http:JSONEncode(data)
    end)
    if not ok then warn("[Model Changer] Could not fetch user avatar:", result); return end
    skin_code:set(result)
    pcall(function() skin_cfg_box:set(result) end)
    pcall(function() skin_enabled:set(true) end)
    skin_apply(true)
end
local function skin_extract_preset_cfg()
    skin_load_selected_preset()
    local value = skin_code:get() or ""
    skin_cfg_box:set(value)
    client.log("[Model Changer] Selected preset CFG extracted to the editor")
end

local function skin_extract_user_cfg()
    local raw = tostring(skin_user_id:get() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if raw == "" then warn("[Model Changer] Enter a username or UserId first"); return end
    local ok, result = pcall(function()
        local user_id = tonumber(raw)
        if not user_id then user_id = Players:GetUserIdFromNameAsync(raw) end
        local desc = Players:GetHumanoidDescriptionFromUserId(user_id)
        local data = { userId = user_id, username = raw }
        for _, key in ipairs(avatar_props) do
            local valid, value = pcall(function() return desc[key] end)
            if valid and value ~= nil then data[key] = value end
        end
        for _, key in ipairs(avatar_colors) do
            local valid, value = pcall(function() return desc[key] end)
            if valid and value then data[key] = { value.R, value.G, value.B } end
        end
        local valid, accessories = pcall(function() return desc:GetAccessories(true) end)
        if valid and accessories then
            data.accessories = {}
            for _, item in ipairs(accessories) do
                local entry = { AssetId = item.AssetId, IsLayered = item.IsLayered,
                    Order = item.Order, Puffiness = item.Puffiness }
                if item.AccessoryType then entry.AccessoryType = item.AccessoryType.Name end
                table.insert(data.accessories, entry)
            end
        end
        return avatar_http:JSONEncode(data)
    end)
    if not ok then warn("[Model Changer] User CFG extraction failed:", result); return end
    skin_code:set(result)
    skin_cfg_box:set(result)
    database.write("rndm_avatar_json", result)
    client.log("[Model Changer] User CFG extracted to the editor")
end

local function skin_apply_cfg_editor()
    local value = tostring(skin_cfg_box:get() or "")
    if value == "" then warn("[Model Changer] CFG editor is empty"); return end
    skin_code:set(value)
    pcall(function() skin_enabled:set(true) end)
    skin_apply(true)
end

skin_sec:new_button("Extract Preset CFG", skin_extract_preset_cfg)
skin_sec:new_button("Extract User CFG", skin_extract_user_cfg)
skin_sec:new_button("Apply CFG From Editor", skin_apply_cfg_editor)
skin_sec:new_button("Apply Avatar", skin_apply_custom_user)
client.set_event_callback("paint", skin_first_person_update)
client.set_event_callback("paint", headless_update)
client.set_event_callback("shutdown", function()
    headless_restore()
    skin_restore()
end)

-- ================= CUSTOM CLANTAG WITH INDEPENDENT SPEEDS =================
local clantag_sec = misc_tab:new_section("Random Clantag", "Left")
local default_text = "rndm lua"
local clantag_presets = {
    ["rndm lua"] = "rndm lua",
    ["overtonight"] = "overtonight",
    ["meow :3"] = "meow :3"
}
local clantag_preset_picker = clantag_sec:new_combobox("Clantag Preset", {"rndm lua", "overtonight", "meow :3", "Custom"}, "rndm lua")
local dots_style_toggle = clantag_sec:new_toggle("Dots Style (off = Normal)", false)
-- The editor is only shown for the Custom preset; custom text is kept separately from presets.
local text_box = clantag_sec:new_textbox("Clantag Text", "Enter custom text", "")
local speed_slider = clantag_sec:new_slider("Typing Speed (s)", 0.01, 0.30, 0.30, 2, "s")
local delete_slider = clantag_sec:new_slider("Deleting Speed (s)", 0.01, 0.30, 0.15, 2, "s")
local delay_slider = clantag_sec:new_slider("End Hold (Frames)", 1, 20, 5, 0, "f")

local active_clantag_text = default_text

local function apply_clantag(text)
    text = tostring(text or active_clantag_text or default_text)
    if text == "" then text = default_text end
    active_clantag_text = text

    local frames = {}
    local length = #text
    local use_dots_style = dots_style_toggle:get() == true
    local type_spd = tonumber(speed_slider:get()) or 0.30
    local del_spd = tonumber(delete_slider:get()) or 0.15
    local base_spd = math.max(0.01, math.min(type_spd, del_spd))
    local type_ratio = math.max(1, math.ceil(type_spd / base_spd))
    local del_ratio = math.max(1, math.ceil(del_spd / base_spd))

    if use_dots_style then
        -- Keep the tag at a constant length: progressively mask trailing letters with dots.
        for hidden = 0, length do
            local frame = text:sub(1, length - hidden) .. string.rep(".", hidden)
            for _ = 1, type_ratio do table.insert(frames, frame) end
        end
        for _ = 1, math.floor(tonumber(delay_slider:get()) or 5) do
            table.insert(frames, string.rep(".", length))
        end
        for hidden = length - 1, 0, -1 do
            local frame = text:sub(1, length - hidden) .. string.rep(".", hidden)
            for _ = 1, del_ratio do table.insert(frames, frame) end
        end
    else
        for i = 1, length do
            local frame = text:sub(1, i)
            for _ = 1, type_ratio do table.insert(frames, frame) end
        end
        for _ = 1, math.floor(tonumber(delay_slider:get()) or 5) do
            table.insert(frames, text)
        end
        for i = length - 1, 1, -1 do
            local frame = text:sub(1, i)
            for _ = 1, del_ratio do table.insert(frames, frame) end
        end
        table.insert(frames, "")
    end

    local ok, err = pcall(function()
        clantag.set_frames(frames, base_spd)
    end)
    if not ok then warn("[Random Clantag] Apply failed:", err) end
end

local function get_selected_clantag_text()
    local selected = clantag_preset_picker:get()
    local preset_text = clantag_presets[selected]
    if preset_text then
        active_clantag_text = preset_text
        return preset_text
    end
    local custom = text_box:get()
    if custom == nil or tostring(custom) == "" then custom = default_text end
    active_clantag_text = tostring(custom)
    return active_clantag_text
end

local function update_custom_editor_visibility()
    local is_custom = tostring(clantag_preset_picker:get() or "") == "Custom"
    pcall(function() text_box:set_visible(is_custom) end)
end

local clantag_toggle = clantag_sec:new_toggle("Enable Custom Clantag", true, function(enabled)
    if enabled then
        apply_clantag(get_selected_clantag_text())
    else
        clantag.reset()
    end
end)

text_box:set_callback(function(value)
    if value ~= nil then
        active_clantag_text = tostring(value)
        if tostring(clantag_preset_picker:get() or "") == "Custom" and clantag_toggle:get() then
            apply_clantag(active_clantag_text)
        end
    end
end)

-- Poll the combobox every second instead of relying on its callback.
-- Only restart the clantag when the selected preset actually changes.
local last_clantag_selection = tostring(clantag_preset_picker:get() or "rndm lua")
local last_dots_style = dots_style_toggle:get() == true
local next_clantag_check = 0

local function check_clantag_selection()
    local now = clock()
    if now < next_clantag_check then return end
    next_clantag_check = now + 1

    local ok, selected = pcall(function()
        return clantag_preset_picker:get()
    end)
    if not ok or selected == nil then return end

    selected = tostring(selected)
    local dots_enabled = dots_style_toggle:get() == true
    update_custom_editor_visibility()
    if selected ~= last_clantag_selection or dots_enabled ~= last_dots_style then
        last_clantag_selection = selected
        last_dots_style = dots_enabled
        local selected_text = get_selected_clantag_text()
        if clantag_toggle:get() then
            apply_clantag(selected_text)
        end
    end
end

client.set_event_callback("paint", check_clantag_selection)

-- Initialize visibility and clantag from the current selection.
update_custom_editor_visibility()
clantag_preset_picker:set_callback(function()
    update_custom_editor_visibility()
    if clantag_toggle:get() then apply_clantag(get_selected_clantag_text()) end
end)
get_selected_clantag_text()
if clantag_toggle:get() then apply_clantag(active_clantag_text) end

client.set_event_callback("shutdown", function()
    clantag.reset()
end)

-- ================= PEEK ADVISOR =================
local peek_sec   = misc_tab:new_section("Peek Advisor", "Left")
local peek_on    = peek_sec:new_toggle("Enable Peek Advisor", true)
local peek_y     = peek_sec:new_slider("Offset Y", 40, 200, 55, 0, "px")
local peek_tsize = peek_sec:new_slider("Text size", 10, 20, 13, 0, "px")
local peek_extra = peek_sec:new_slider("Safety margin", 0, 8, 2, 0, "t")

local peek_intel, peek_n, peek_nearest = {}, 0, nil
local function pk_wrap(a) return ((a + 180) % 360) - 180 end

local function pk_new_rec()
    return { side = 0, last_flip = 0, flips = 0, ints = {},
             def_count = 0, last_def = 0, last_yaw = nil,
             des_now = 0, ema_des = 0, aimerr = 180 }
end

local function pk_update(rec, e, mypos, now)
    local okp, pos = pcall(entity.get_player_position, e)
    if not okp or not pos then return end
    local oka, pitch, yaw = pcall(entity.get_player_angles_deg, e)
    local okn, anim        = pcall(entity.get_anim_state, e)

    if okn and anim and anim.eye_angles_y and anim.goal_feet_yaw then
        local des = pk_wrap(anim.goal_feet_yaw - anim.eye_angles_y)
        rec.des_now = des
        rec.ema_des = rec.ema_des * 0.97 + math.abs(des) * 0.03
        local side = (des > 10 and 1) or (des < -10 and -1) or 0
        if side ~= 0 then
            if rec.side == 0 then
                rec.last_flip = now
            elseif side ~= rec.side then
                rec.ints[#rec.ints + 1] = now - rec.last_flip
                if #rec.ints > 12 then table.remove(rec.ints, 1) end
                rec.flips    = rec.flips + 1
                rec.last_flip = now
            end
            rec.side = side
        end
    end

    if oka and yaw and rec.last_yaw and math.abs(pk_wrap(yaw - rec.last_yaw)) > 120 then
        rec.def_count = rec.def_count + 1
        rec.last_def  = now
    end
    if oka then rec.last_yaw = yaw end

    if oka and yaw then
        local to_me = mypos - pos
        local flat  = Vector3.new(to_me.X, 0, to_me.Z)
        if flat.Magnitude > 0.01 then
            local d   = math.rad(yaw)
            local dir = Vector3.new(math.sin(d), 0, math.cos(d))
            local c   = math.clamp(dir:Dot(flat.Unit), -1, 1)
            rec.aimerr = math.deg(math.acos(c))
        end
    end
end

local function pk_pattern(rec)
    local n = #rec.ints
    if n < 4 then return "learning", nil end
    local sum = 0
    for i = 1, n do sum = sum + rec.ints[i] end
    local mean = sum / n
    local var  = 0
    for i = 1, n do var = var + (rec.ints[i] - mean) ^ 2 end
    local std  = math.sqrt(var / n)
    local label
    if     mean <= 2.3 then label = "jitter"
    elseif std  <= 1.2 then label = "fixed " .. math.floor(mean + 0.5) .. "t"
    else                     label = "variable" end
    local next_in = math.max(0, math.floor(mean - (peek_n - rec.last_flip) + 0.5))
    return label, next_in
end

events.on_tick(function()
    peek_n = peek_n + 1
    local ok, lp = pcall(entity.get_local_player)
    if not ok or not lp then peek_nearest = nil; return end
    local okp, mypos = pcall(entity.get_player_position, lp)
    if not okp or not mypos then peek_nearest = nil; return end
    local ok_en, enemies = pcall(entity.get_enemies)
    if not ok_en or type(enemies) ~= "table" then peek_nearest = nil; return end

    local best
    for _, e in ipairs(enemies) do
        local aok, a = pcall(entity.is_alive, e)
        if aok and a then
            local pok, p = pcall(entity.get_player_position, e)
            if pok and p then
                local d = (p - mypos).Magnitude
                if not best or d < best.d then best = { e = e, d = d } end
            end
        end
    end

    if best then
        local rec = peek_intel[best.e]
        if not rec then rec = pk_new_rec(); peek_intel[best.e] = rec end
        pk_update(rec, best.e, mypos, peek_n)
        peek_nearest = rec
    else
        peek_nearest = nil
    end
end)

-- Ezyk-style scoring: optional view-angle check is kept off by default,
-- matching the reference script's default. Existing GUI controls are unchanged.
local PK_VIEW_CHECK = false
local PK_LOOK_AWAY_ANGLE = 25
local PK_DEFENSIVE_COOLDOWN = 64

local function pk_verdict()
    local rec = peek_nearest
    if not rec then return "NO TARGET", C_MUTED end

    local label, next_in = pk_pattern(rec)
    local score = 0
    local reasons = {}

    -- 1) View-angle check (disabled by default, as in Ezyk).
    if PK_VIEW_CHECK then
        if rec.aimerr > PK_LOOK_AWAY_ANGLE then
            score = score + 1
            reasons[#reasons + 1] = "not looking at you"
        else
            score = score - 1
            reasons[#reasons + 1] = "aiming at you"
        end
    end

    -- 2) Recent defensive burst: wait for the cooldown to expire.
    local since_def = peek_n - rec.last_def
    if rec.def_count > 0 and since_def < PK_DEFENSIVE_COOLDOWN then
        score = score - 1
        reasons[#reasons + 1] = "defensive " .. since_def .. "t ago"
    end

    -- 3) Check whether the current side is expected to remain stable
    -- long enough for latency plus the configured safety margin.
    local ok_lat, lat = pcall(client.latency)
    local ok_ti, ti = pcall(globals.tickinterval)
    local lat_ticks = (ok_lat and type(lat) == "number" and ok_ti and type(ti) == "number" and ti > 0)
        and (lat / ti) or 4
    local need = lat_ticks + peek_extra:get()

    if label == "jitter" then
        score = score - 1
        reasons[#reasons + 1] = "per-tick jitter (no stable window)"
    elseif next_in then
        if next_in > need then
            score = score + 1
            reasons[#reasons + 1] = string.format("side stable ~%dt (need %.0f)", next_in, need)
        else
            score = score - 1
            reasons[#reasons + 1] = string.format("flip in ~%dt (need %.0f)", next_in, need)
        end
    else
        reasons[#reasons + 1] = "pattern still learning"
    end

    -- Ezyk's default threshold: GOOD with one positive factor, OK at zero.
    if score >= (PK_VIEW_CHECK and 2 or 1) then
        return "PEEK: GOOD", C_GOOD
    elseif score >= 0 then
        return "PEEK: OK", C_FAIR
    end
    return "PEEK: WAIT", C_BAD
end

local peek_gui = new("ScreenGui", {
    Name = "RndmPeekAdv", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 49, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
mount(peek_gui)

local peek_label = new("TextLabel", {
    AnchorPoint            = Vector2.new(0.5, 0),
    Position               = UDim2.new(0.5, 0, 0.5, peek_y:get()),
    Size                   = UDim2.fromOffset(400, 18),
    BackgroundTransparency = 1,
    Font                   = FONT_BOLD,
    TextSize               = peek_tsize:get(),
    Text                   = "",
    TextColor3             = C_MUTED,
    TextStrokeTransparency = 0.6,
    TextXAlignment         = Enum.TextXAlignment.Center,
    Visible                = false,
}, peek_gui)

client.set_event_callback("paint", function()
    if not peek_on:get() then peek_label.Visible = false; return end
    local word, col = pk_verdict()
    peek_label.Text       = word
    peek_label.TextColor3 = col
    peek_label.TextSize   = peek_tsize:get()
    peek_label.Position   = UDim2.new(0.5, 0, 0.5, peek_y:get())
    peek_label.Visible    = true
end)

client.set_event_callback("shutdown", function()
    if peek_gui then pcall(function() peek_gui:Destroy() end) end
end)

-- ================= MERGED EVENTS =================
client.set_event_callback("aim_fire", function(e)
    resolver_stats.shots_fired = resolver_stats.shots_fired + 1
    local target = e and e.target
    if target then local s = state_for(key_for(target)); s.shot_lock_until = globals.tickcount() + hold_ticks:get(); s.shot = { off = s.cur, method = s.method } end
    vortex_stats.shots_fired = vortex_stats.shots_fired + 1
    local w = safe_get_weapon(); if w and w.name then S.cur_wep = w.name end
    if inv_mode:get() == "Burst" then S.burst_left = math.floor(inv_burst_len:get()) end
    if rage.is_double_tap_charged() then aa.unchoke(); rage.shift_ticks(14) end
end)

client.set_event_callback("aim_hit", function(e)
    resolver_stats.hits = resolver_stats.hits + 1; resolver_stats.res_hits = resolver_stats.res_hits + 1; resolver_stats.total = resolver_stats.total + 1
    vortex_stats.hits = vortex_stats.hits + 1; vortex_stats.res_hits = vortex_stats.res_hits + 1
    local name = S.cur_wep or "?"
    local st = vortex_stats.per_weapon[name] or { h = 0, m = 0 }
    st.h = st.h + 1; vortex_stats.per_weapon[name] = st

    local target = e and e.target
    if target then
        local state = state_for(key_for(target)); state.miss = 0; state.stage = 1; state.fallback_misses = 0; state.fallback_active = false
        state.tried = {}; state.last_good[state.ctx] = state.cur
        if state.shot and state.shot.method == "exploit" then v12_bump(state, state.shot.off, 2) end
        cache_result(key_for(target), state, "hit", nil); record(state, true); state.shot = nil
    end
    if e and e.health_remaining and e.health_remaining <= 0 then killstreak = killstreak + 1; cached_kills = (cached_kills or 0) + 1 end
end)

client.set_event_callback("aim_miss", function(e)
    resolver_stats.misses = resolver_stats.misses + 1; resolver_stats.total = resolver_stats.total + 1; vortex_stats.misses = vortex_stats.misses + 1
    local target = e and e.target; local reason = tostring((e and e.reason) or "unknown"):lower()
    
    vortex_stats.miss_reasons[reason] = (vortex_stats.miss_reasons[reason] or 0) + 1
    local name = S.cur_wep or "?"
    local st = vortex_stats.per_weapon[name] or { h = 0, m = 0 }
    st.m = st.m + 1; vortex_stats.per_weapon[name] = st

    local is_spread = string.find(reason, "spread") ~= nil
    if is_spread then resolver_stats.spread_misses = resolver_stats.spread_misses + 1; vortex_stats.spread_misses = vortex_stats.spread_misses + 1; return end

    local is_resolver = string.find(reason, "resolv") ~= nil
    local is_occ = string.find(reason, "occl") ~= nil
    local is_death = string.find(reason, "death") ~= nil

    if is_resolver then
        resolver_stats.res_misses = resolver_stats.res_misses + 1
        if target then
            local s = state_for(key_for(target)); s.miss = s.miss + 1; s.stage = (s.stage or 1) + 1; s.tried = s.tried or {}; push(s.tried, s.cur, 8)
            cache_result(key_for(target), s, "miss", reason); record(s, false)
        end
    elseif is_occ then resolver_stats.occ_misses = resolver_stats.occ_misses + 1; vortex_stats.occ_misses = vortex_stats.occ_misses + 1
    elseif is_death then
        if string.find(reason, "local") ~= nil then resolver_stats.death_local_misses = resolver_stats.death_local_misses + 1; vortex_stats.death_local_misses = vortex_stats.death_local_misses + 1
        else resolver_stats.death_target_misses = resolver_stats.death_target_misses + 1; vortex_stats.death_target_misses = vortex_stats.death_target_misses + 1 end
    else resolver_stats.spread_misses = resolver_stats.spread_misses + 1; vortex_stats.spread_misses = vortex_stats.spread_misses + 1 end
end)

-- ================= 64 HZ TICK LOOP (MAIN RESOLVER) =================
events.on_tick(function(tick_count)
    if auto_disable_native:get() then
        local ok, is_enabled = pcall(function() return rage.is_resolver_enabled() end)
        if ok and is_enabled then pcall(function() rage.set_resolver_enabled(false) end) end
    end
    if not rage_enable:get() then plist.reset_all(); rage.reset(); return end
    pcall(function() rage.override_enabled(true) end); pcall(function() rage.override_target_selection(target_sel:get()) end)

    local wep = safe_get_weapon(); local wep_name = wep and string.lower(tostring(wep.name)) or ""
    local is_deagle = wep_name:find("deagle") or wep_name:find("desert"); local is_scout = wep_name:find("ssg") or wep_name:find("scout")
    local lp = entity.get_local_player(); local lp_info = lp and entity.get_info(lp)
    local is_lp_air = not not (lp_info and (lp_info.is_in_air or (lp_info.velocity and math.abs(lp_info.velocity.Y) > 2)))
    local is_lp_moving = ((lp_info and lp_info.speed) or 0) > 1.5

    if not is_scout and not is_deagle then
        pcall(function() rage.override_hitboxes({ "head", "chest", "pelvis" }) end)
        pcall(function() rage.set_hitbox_config("chest", { min_damage = 30, hitchance = 80, multipoint = true }) end)
    else
        pcall(function() rage.set_hitbox_config("head", { min_damage = 1, hitchance = 100, multipoint = false }) end)
    end

    if disable_me:get() and (is_lp_air or is_lp_moving) then
        if not is_disabled_for_movement then plist.reset_all(); rage.reset(); is_disabled_for_movement = true end
        return
    else is_disabled_for_movement = false end

    local now = globals.tickcount(); local active_tgt = rage.get_target()
    if active_tgt and active_tgt.player then
        local tgt = active_tgt.player; local key = key_for(tgt); local s = state_for(key); local info = entity.get_info(tgt)
        if info then
            local ok_anim, anim = pcall(entity.get_anim_state, tgt)
            local eye = (anim and anim.eye_angles_y) or info.yaw or 0; local feet = (anim and anim.goal_feet_yaw) or eye
            local delta = norm(feet - eye)
            
            if use_beta_res:get() then
                if s.prev_eye then push(s.steps, norm(eye - s.prev_eye), 8) end
                s.prev_eye = eye
                if s.prev_delta == nil or math.abs(norm(delta - s.prev_delta)) > 0.5 then push(s.hist, delta, 24); s.prev_delta = delta; learn_sample(s, delta) end
                
                if now % 3 == 0 then s.class = classify(s) end
                s.offs = compute_offsets(tgt, s, anim, eye, delta, info)
                
                local method = choose(s, res_lock:get(), res_explore:get())
                s.method = method
                local offset = s.offs[method] or 0
                
                -- FIXED: s.misses -> s.miss
                if s.miss >= res_fallback:get() then
                    local cands = {s.offs.modded, s.offs.box, s.offs.chatgpt, s.offs.exploit, -s.offs.box, -s.offs.chatgpt, 0, 58, -58, 86, -86}
                    local pick = nil
                    for _, cnd in ipairs(cands) do
                        if cnd then local seen = false; for _, t in ipairs(s.tried) do if math.abs(norm(cnd - t)) < 12 then seen = true; break end end; if not seen then pick = cnd; break end end
                    end
                    offset = clamp(pick or 0, -86, 86)
                end
                s.cur = offset; s.last_offset = offset; s.aa_type_str = s.class
            else
                local lby = info.lby; local twist_deg = info.twist_deg
                if ok_anim and anim then lby = anim.goal_feet_yaw; twist_deg = wrap180(anim.eye_angles_y - anim.goal_feet_yaw) end
                local target_info = { lby = lby, twist_deg = twist_deg, is_crouching = info.is_crouching, yaw = info.yaw, pitch = info.pitch, speed = info.speed, position = info.position, velocity = info.velocity, is_in_air = info.is_in_air, desync_delta = info.desync_delta }
                s.aa_type_str = analyze_aa(s, target_info)
                
                local is_fd = detect_fake_duck(s, target_info, tgt, now)
                local is_spin = s.spin_counter > 8
                s.is_air = track_air:get() and (target_info.is_in_air or (target_info.velocity and math.abs(target_info.velocity.Y) > 2))
                s.is_moving = target_info.speed and target_info.speed > 1.2
                
                local cands, mag, aa_off, is_freestanding = candidate_list(s, target_info, is_fd, is_spin, anim, tgt)
                s.is_freestanding = is_freestanding; maybe_reset(s, mag)
                
                if aa_off then
                    offset = 0
                    s.aa_off = true
                else
                    s.aa_off = false
                    if s.is_moving then offset = 0
                    elseif is_fd or is_freestanding then offset = brute_offset(s, cands)
                    elseif is_spin then offset = brute_offset(s, {cands[1], cands[2], cands[3], cands[4] or 0})
                    else
                        offset = lby_break_offset(s, target_info, now) or twist_offset(target_info) or brute_offset(s, cands)
                    end
                end
                -- Always publish the value selected this tick; don't leave a stale yaw override behind.
                s.cur = offset
            end
            
            if s.last_sent_yaw ~= true then plist.set(tgt, "Force body yaw", true); s.last_sent_yaw = true end
            if s.last_sent_offset ~= s.cur then plist.set(tgt, "Override yaw offset", s.cur); s.last_sent_offset = s.cur end
        end
    end
end)

-- ================= VORTEX TICK (FIXED AA) =================
events.on_tick(function(tick_count)
    local now = globals.tickcount()
    if poll_hit() and as_on:get() then as_burn_recent(now) end

    -- Stand AA has priority: suppress all Vortex AA overrides while it is enabled.
    if LOCAL_ANTIAIM_ENABLED and (not cfg.enabled or not cfg.enabled:get()) then
    -- Leave pitch control to the Stand AA builder below.
    -- Keep the existing Vortex fake-lag behavior without overriding pitch.
    pcall(function()
        aa.override_fake_lag(true)
        aa.override_fake_lag_limit(14)
    end)

    -- Skitter Mode Logic
    if dsy_jit_mode:get() == "Skitter" then
        local r = math.floor(dsy_jit_range:get() / 2)
        local opts = {-r, 0, r}; local c = {}
        for _, x in ipairs(opts) do if x ~= S.jit_step then c[#c + 1] = x end end
        if #c > 0 then
            S.jit_step = c[math.random(1, #c)]
        else
            S.jit_step = 0
        end
    else
        if dsy_jit_speed then
            S.jit_tick = S.jit_tick + 1
            if S.jit_tick >= math.floor(dsy_jit_speed:get()) then
                S.jit_tick = 0; S.jit_step = S.jit_step + S.jit_dir
                local half = math.floor(dsy_jit_range:get() / 2)
                if S.jit_step >= half or S.jit_step <= -half then S.jit_dir = -S.jit_dir end
            end
        end
    end

    if brk_on:get() then
        local brk_L, brk_R = safe_mag(math.floor(brk_gap:get()), false), safe_mag(math.floor(brk_gap:get()), false)
        -- FIXED: Added inverter flip
        pcall(function() 
            aa.override_body_yaw(true)
            aa.override_desync_limits(brk_L, brk_R) 
            aa.override_inverter(math.random(0, 1) == 1) 
        end)
    elseif as_on:get() then
        -- FIXED: Update every tick, not every 16
        as_cur = as_pick(now)
        pcall(function() 
            aa.override_body_yaw(true)
            aa.override_desync_limits(as_cur.mag, as_cur.mag)
            aa.override_inverter(as_cur.side > 0) 
        end)
    else
        local d = math.floor(dsy_max:get())
        local m = dsy_mode:get()
        aa.override_body_yaw(true)
        if m == "Static" or m == "Opposite" then aa.override_desync_limits(d, d)
        elseif m == "Random" then local v = math.random(math.floor(d * 0.5), d); aa.override_desync_limits(v, v)
        else aa.override_desync_limits(d, math.random(math.floor(d * 0.4), d)) end
        pcall(function() aa.override_inverter(math.random(0, 1) == 1) end)
    end

    end -- Vortex AA priority gate

    -- Hitchance Adaptation
    if adapt_hc:get() then
        local t = rage.get_target()
        local bonus = 0
        if t then
            local st = state_for(key_for(t.player) or key_for(t.slot))
            if st then bonus = st.hc_bonus end
        end
        local hc = clamp(base_hc:get() + bonus, 1, 100)
        if hc ~= last_hc then rage.override_hitchance(hc); last_hc = hc end
        hc_active = true
    elseif hc_active then
        rage.reset(); hc_active = false; last_hc = nil
    end
end)

-- ================= DRAWING (RESTORED) =================
local COLOR_TEXT_WHITE = Color3.fromRGB(255, 255, 255)
local COLOR_PURPLE_ACCENT = Color3.fromRGB(150, 70, 210) 
local COLOR_PURPLE_DARK = Color3.fromRGB(20, 20, 25)       

local baseX, baseY = 30, 350; local spacing = 24
local ind_res = Drawing.new("Text"); ind_res.Size = 16; ind_res.Font = Drawing.Fonts.Plex; ind_res.Outline = true
ind_res.Position = Vector2.new(baseX, baseY); ind_res.Text = "RESOLVER: SCANNING"; ind_res.Color = COLOR_TEXT_WHITE
local aa_type_text = Drawing.new("Text"); aa_type_text.Size = 16; aa_type_text.Font = Drawing.Fonts.Plex; aa_type_text.Outline = true
aa_type_text.Position = Vector2.new(baseX, baseY + 20); aa_type_text.Text = "AA: None"; aa_type_text.Color = Color3.fromRGB(255, 100, 100)

local logger = {}
logger.bg = Drawing.new("Square"); logger.title = Drawing.new("Text"); logger.title.Text = "PURE RESOLVER LOGGER"; logger.title.Color = COLOR_TEXT_WHITE 
logger.hit = Drawing.new("Text"); logger.hit.Text = "HIT 0%"; logger.miss = Drawing.new("Text"); logger.miss.Text = "MISS 0%"
logger.bar_bg = Drawing.new("Square"); logger.bar_fill = Drawing.new("Square"); logger.stats = Drawing.new("Text"); logger.stats.Text = "Hits: 0 Misses: 0 Total: 0"
logger.res_hit = Drawing.new("Text"); logger.res_hit.Text = "Resolver hits: 0"; logger.res_miss = Drawing.new("Text"); logger.res_miss.Text = "Resolver misses: 0"
logger.spread_miss = Drawing.new("Text"); logger.spread_miss.Text = "Spread Misses: 0"; logger.death_local = Drawing.new("Text"); logger.death_local.Text = "Death Local Miss: 0"
logger.death_target = Drawing.new("Text"); logger.death_target.Text = "Death Target Miss: 0"; logger.occ_miss = Drawing.new("Text"); logger.occ_miss.Text = "Occlusion Misses: 0"
logger.shots_fired = Drawing.new("Text"); logger.shots_fired.Text = "Shots Fired: 0"

local lx, ly = baseX, baseY + spacing + 40; local lw, lh = 300, 240
logger.bg.Size = Vector2.new(lw, lh); logger.bg.Position = Vector2.new(lx, ly); logger.bg.Color = COLOR_PURPLE_DARK; logger.bg.Transparency = 0.3 
logger.bg.Visible = false
if logger.bg.BorderColor ~= nil then logger.bg.BorderColor = COLOR_PURPLE_DARK end
if logger.bg.Thickness ~= nil then logger.bg.Thickness = 0 end

logger.title.Size = 16; logger.title.Font = Drawing.Fonts.Plex; logger.title.Position = Vector2.new(lx + 15, ly + 15); logger.title.Visible = false
logger.hit.Size = 16; logger.hit.Font = Drawing.Fonts.Plex; logger.hit.Color = COLOR_PURPLE_ACCENT; logger.hit.Position = Vector2.new(lx + 15, ly + 45); logger.hit.Visible = false
logger.miss.Size = 16; logger.miss.Font = Drawing.Fonts.Plex; logger.miss.Color = COLOR_TEXT_WHITE; logger.miss.Position = Vector2.new(lx + 160, ly + 45); logger.miss.Visible = false
logger.bar_bg.Size = Vector2.new(lw - 30, 8); logger.bar_bg.Position = Vector2.new(lx + 15, ly + 75); logger.bar_bg.Color = Color3.fromRGB(50, 30, 70); logger.bar_bg.Visible = false
logger.bar_fill.Size = Vector2.new(lw - 30, 8); logger.bar_fill.Position = Vector2.new(lx + 15, ly + 75); logger.bar_fill.Color = COLOR_PURPLE_ACCENT; logger.bar_fill.Visible = false

local function setup_text(name, color, offset)
    logger[name].Size = 15; logger[name].Font = Drawing.Fonts.Plex; logger[name].Color = color; logger[name].Position = Vector2.new(lx + 15, ly + offset); logger[name].Visible = false
end
setup_text("stats", COLOR_TEXT_WHITE, 90); setup_text("res_hit", COLOR_PURPLE_ACCENT, 108); setup_text("res_miss", COLOR_PURPLE_ACCENT, 126)
setup_text("spread_miss", COLOR_TEXT_WHITE, 144); setup_text("death_local", COLOR_TEXT_WHITE, 162); setup_text("death_target", COLOR_TEXT_WHITE, 180)
setup_text("occ_miss", COLOR_TEXT_WHITE, 198); setup_text("shots_fired", COLOR_TEXT_WHITE, 216)

local killstrike_text = Drawing.new("Text"); killstrike_text.Text = "KILLSTRIKE : 0"; killstrike_text.Size = 20; killstrike_text.Font = Drawing.Fonts.Plex
killstrike_text.Outline = true; killstrike_text.Visible = true; killstrike_text.Position = Vector2.new(0, 150)
local speed_text = Drawing.new("Text"); speed_text.Size = 16; speed_text.Font = Drawing.Fonts.Plex; speed_text.Outline = true
speed_text.Color = Color3.fromRGB(255, 255, 255); speed_text.Center = true; speed_text.Visible = false
local rank_stats_text = Drawing.new("Text"); rank_stats_text.Size = 18; rank_stats_text.Font = Drawing.Fonts.Plex; rank_stats_text.Outline = true
rank_stats_text.Color = Color3.fromRGB(255, 255, 255); rank_stats_text.Center = true; rank_stats_text.Visible = true; rank_stats_text.Text = "Calculating..."

local vhud_lines = {}
for i = 1, 15 do local o = Drawing.new("Text"); o.Text = ""; o.Size = 13; o.Outline = true; o.Visible = false; vhud_lines[i] = o end
local choke_last_tick, choke_last_val, last_hud_update = 0, 0, 0

local function fmt_pct(h, m)
    h, m = tonumber(h) or 0, tonumber(m) or 0; local total = h + m
    if total <= 0 then return "-", 0, 0 end
    local pct = math.floor((h * 100) / total); if pct < 0 then pct = 0 end; if pct > 100 then pct = 100 end
    return tostring(pct) .. "%", total, pct
end
local function push_line(lines, text, col) lines[#lines+1] = { text = text, color = col } end

local cached_rank, cached_kills, cached_kills_needed = "Unranked", 0, 0
local function getRankAndKills()
    local Leaderboards = ReplicatedStorage:FindFirstChild("Leaderboards")
    if not Leaderboards then return cached_kills, cached_rank, cached_kills_needed end
    local Top100Kills = Leaderboards:FindFirstChild("Top100Kills"); local decodedJSON = nil
    if Top100Kills and Top100Kills.Value and Top100Kills.Value ~= "" and Top100Kills.Value ~= "[]" then
        local success, result = pcall(function() return HttpService:JSONDecode(Top100Kills.Value) end)
        if success and type(result) == "table" then decodedJSON = result end
    end
    if decodedJSON then
        for i, entry in ipairs(decodedJSON) do
            if tonumber(entry.userId) == LocalPlayer.UserId then
                local myKills = tonumber(entry.kills) or 0; local myRank = "#" .. i; local killsToNext = 0
                if i > 1 then local nextPlayerKills = tonumber(decodedJSON[i - 1].kills) or 0; killsToNext = math.max(0, nextPlayerKills - myKills + 1) end
                cached_kills = myKills; cached_rank = myRank; cached_kills_needed = killsToNext
                return myKills, myRank, killsToNext
            end
        end
    end
    local myStat = Leaderboards:FindFirstChild(tostring(LocalPlayer.UserId))
    local myKills = (myStat and myStat:GetAttribute("Kills")) or LocalPlayer:GetAttribute("Kills") or cached_kills
    if myKills > cached_kills then cached_kills = myKills end
    return cached_kills, cached_rank, cached_kills_needed
end

task.spawn(function()
    while task.wait(5) do
        local ok, currentKills, currentRank, killsToNext = pcall(getRankAndKills)
        if ok then
            local text = string.format("%s : %s", currentRank, currentKills)
            if killsToNext > 0 then text = text .. string.format(" (%d)", killsToNext) end
            if rank_stats_text.Text ~= text then rank_stats_text.Text = text end
        end
    end
end)

events.on_tick(function(tick_count)
    if not vhud_on:get() then for i = 1, #vhud_lines do vhud_lines[i].Visible = false end; return end
    if tick_count - last_hud_update < 4 then return end; last_hud_update = tick_count
    local C3 = Color3; local COLOR_TEXT_GRAY = C3.fromRGB(180, 180, 180); local COLOR_PURPLE_ACCENT = C3.fromRGB(150, 70, 210); local lines = {}

    if inv_on:get() then
        local mode = inv_mode:get():upper(); local side = S.side and "RIGHT" or "LEFT"; local burst = S.burst_left > 0 and (" | " .. S.burst_left) or ""
        push_line(lines, "INV " .. mode .. " [" .. side .. "]" .. burst, S.burst_left > 0 and C3.fromRGB(255, 100, 100) or C3.fromRGB(80, 200, 255))
    else push_line(lines, "INV: OFF", COLOR_TEXT_GRAY) end

    if dsy_on:get() then
        local jit = dsy_jit_mode:get() == "Skitter" and S.jit_step or 0
        push_line(lines, string.format("DSY %+d/%+d  jit %+d", math.floor(S.dsy_real), math.floor(S.dsy_fake), math.floor(jit)), C3.fromRGB(80, 255, 120))
    else push_line(lines, "DSY: OFF", COLOR_TEXT_GRAY) end

    local ok_choke, choked = pcall(function() return aa.get_choked_ticks() end)
    if not ok_choke or type(choked) ~= "number" or choked ~= choked or choked < 0 then choked = 0 end
    choked = math.floor(choked)
    if choked > 0 then choke_last_tick = tick_count; choke_last_val = choked end

    if (tick_count - choke_last_tick) > 5 then
        local ok_target, target = pcall(function() return aa.get_choke_target() end)
        if ok_target and type(target) == "number" and target > 0 then
            push_line(lines, string.format("CHOKE: %d/14 (idle)", target), COLOR_TEXT_GRAY)
        else
            push_line(lines, "CHOKE: idle", COLOR_TEXT_GRAY)
        end
    else
        local val = choke_last_val
        local col = val >= 12 and C3.fromRGB(255, 100, 100) or val > 6 and C3.fromRGB(255, 180, 60) or COLOR_TEXT_GRAY
        push_line(lines, string.format("CHOKE: %d/14", val), col)
    end

    local w = safe_get_weapon()
    if w and w.name then push_line(lines, string.format("WEP %-14s %d/%d", tostring(w.name), w.ammo or 0, w.reserve or 0), COLOR_TEXT_GRAY) end

    if vhud_show_stats:get() then
        local pct_str, total, pct_num = fmt_pct(vortex_stats.hits, vortex_stats.misses); local col = COLOR_TEXT_GRAY
        if total > 0 then col = pct_num >= 70 and C3.fromRGB(80, 255, 120) or pct_num >= 40 and C3.fromRGB(255, 200, 80) or C3.fromRGB(255, 100, 100) end
        push_line(lines, string.format("Hits: %d Misses: %d Total: %d", vortex_stats.hits, vortex_stats.misses, vortex_stats.hits + vortex_stats.misses), col)
        local res_miss_count = 0
        for r, count in pairs(vortex_stats.miss_reasons) do if string.find(r, "resolv") then res_miss_count = res_miss_count + count end end
        push_line(lines, string.format("Resolver hits: %d", vortex_stats.res_hits), COLOR_PURPLE_ACCENT)
        push_line(lines, string.format("Resolver misses: %d", res_miss_count), COLOR_PURPLE_ACCENT)
        push_line(lines, string.format("Spread Misses: %d", vortex_stats.spread_misses), COLOR_TEXT_GRAY)
        push_line(lines, string.format("Death Local Miss: %d", vortex_stats.death_local_misses), COLOR_TEXT_GRAY)
        push_line(lines, string.format("Death Target Miss: %d", vortex_stats.death_target_misses), COLOR_TEXT_GRAY)
        push_line(lines, string.format("Occlusion Misses: %d", vortex_stats.occ_misses), COLOR_TEXT_GRAY)
        push_line(lines, string.format("Shots Fired: %d", vortex_stats.shots_fired), COLOR_TEXT_GRAY)

        if vhud_show_wep:get() then
            local st = vortex_stats.per_weapon[S.cur_wep]
            if st and (st.h + st.m) > 0 then
                local wpct_str = fmt_pct(st.h, st.m)
                push_line(lines, string.format("  %-12s %4s (%d/%d)", S.cur_wep, wpct_str, st.h, st.h + st.m), COLOR_TEXT_GRAY)
            end
        end
    end

    local x, y = vhud_x:get(), vhud_y:get()
    for i, o in ipairs(vhud_lines) do
        local line = lines[i]
        if line then
            if o.Text ~= line.text then o.Text = line.text end
            o.Position = Vector2.new(x, y + (i - 1) * 17); o.Color = line.color; o.Visible = true
        else o.Visible = false end
    end
end)

client.set_event_callback("paint", function()
    local me = entity.get_local_player(); local sw, sh = render.screen_size()
    if show_speed_indicator:get() and me and entity.is_alive(me) then
        local spd = movement.get_speed(me) or 0; local st = "Stand"; pcall(function() st = movement.get_state(me) end)
        speed_text.Text = string.format("%d  (%s)", math.floor(spd), tostring(st)); speed_text.Position = Vector2.new(sw / 2, sh * 0.72); speed_text.Visible = true
    else speed_text.Visible = false end


    rank_stats_text.Visible = true; rank_stats_text.Position = Vector2.new(960, 82)

    if show_hud:get() then
        if rage_enable:get() then
            local cur = rage.get_target()
            if cur and cur.player then
                local state = state_for(key_for(cur.player)); local ang = state.cur or 0
                local mname = use_beta_res:get() and tostring(state.method):upper() or "STD"
                ind_res.Text = string.format("RES [%s]: %d° | MISS: %d", mname, ang, state.miss); ind_res.Color = COLOR_TEXT_WHITE; ind_res.Visible = true
                aa_type_text.Text = "AA: " .. tostring(state.aa_type_str); aa_type_text.Visible = true
            else ind_res.Text = "RESOLVER: SCANNING"; ind_res.Color = COLOR_TEXT_WHITE; ind_res.Visible = true; aa_type_text.Text = "AA: None"; aa_type_text.Visible = true end
        else ind_res.Visible = false; aa_type_text.Visible = false end
    else ind_res.Visible = false; aa_type_text.Visible = false end

    local show = show_hud:get()
    logger.bg.Visible = show; logger.title.Visible = show; logger.hit.Visible = show; logger.miss.Visible = show
    logger.bar_bg.Visible = show; logger.bar_fill.Visible = show; logger.stats.Visible = show; logger.res_hit.Visible = show; logger.res_miss.Visible = show
    logger.spread_miss.Visible = show; logger.death_local.Visible = show; logger.death_target.Visible = show; logger.occ_miss.Visible = show; logger.shots_fired.Visible = show

    if show then
        local hit_pct = resolver_stats.total > 0 and math.floor((resolver_stats.hits / resolver_stats.total) * 100) or 0
        local forced_misses = math.max(0, resolver_stats.total - resolver_stats.hits); local forced_miss_pct = resolver_stats.total > 0 and math.floor((forced_misses / resolver_stats.total) * 100) or 0
        logger.hit.Text = string.format("HIT %d%%", hit_pct); logger.miss.Text = string.format("MISS %d%%", forced_miss_pct); logger.stats.Text = string.format("Hits: %d Misses: %d Total: %d", resolver_stats.hits, forced_misses, resolver_stats.total)
        logger.res_hit.Text = string.format("Resolver hits: %d", resolver_stats.res_hits); logger.res_miss.Text = string.format("Resolver misses: %d", resolver_stats.res_misses)
        logger.spread_miss.Text = string.format("Spread Misses: %d", resolver_stats.spread_misses); logger.death_local.Text = string.format("Death Local Miss: %d", resolver_stats.death_local_misses)
        logger.death_target.Text = string.format("Death Target Miss: %d", resolver_stats.death_target_misses); logger.occ_miss.Text = string.format("Occlusion Misses: %d", resolver_stats.occ_misses); logger.shots_fired.Text = string.format("Shots Fired: %d", resolver_stats.shots_fired)
        logger.bar_fill.Size = Vector2.new((lw - 30) * (hit_pct / 100), 8)
    end

    if show_hud:get() then
        killstrike_text.Text = string.format("KILLSTRIKE : %d", killstreak); local text_size = render.measure_text(killstrike_text.Text, 20)
        killstrike_text.Position = Vector2.new((sw / 2) - (text_size.X / 2), 150); local t = globals.realtime()
        killstrike_text.Color = Color3.fromRGB(math.floor(math.sin(t * 2) * 127 + 128), math.floor(math.sin(t * 2 + 2) * 127 + 128), math.floor(math.sin(t * 2 + 4) * 127 + 128))
        killstrike_text.Visible = true
    else killstrike_text.Visible = false end
end)

client.set_event_callback("shutdown", function()
    if auto_disable_native:get() then pcall(function() rage.set_resolver_enabled(true) end) end
    plist.reset_all(); rage.reset(); target_state = {}
    for _, obj in pairs(logger) do if obj and obj.Remove then pcall(obj.Remove, obj) end end
    ind_res:Remove(); aa_type_text:Remove(); killstrike_text:Remove(); speed_text:Remove(); rank_stats_text:Remove()
    pcall(aa.reset)
    for _, o in ipairs(vhud_lines) do if o and o.Remove then pcall(o.Remove, o) end end
    pcall(render3d.clear)
end)

client.log("[vortex + adv resolver] V17.6 FIXED AA Loaded.")


-- ================= STAND AA ADD-ON =================
-- =========================================================================
-- EXACT STAND TAB EXTRACTION (From AA Builder)
-- =========================================================================

local PITCH_MODES = {
    "Disabled", "Down", "Up", "Zero", "Semi-Down", "Custom", "Jitter", "Random", "Sway", "Flick"
}

local DESYNC_MODES = {
    "Static", "Jitter", "Random", "Sway", "Switch", "Micro-Jitter", "LBY Breaker",
    "Explicit", "Explicit Jitter", "Explicit Random", "Explicit 3-Way", "Explicit 5-Way",
    "Dual Jitter", "Real Jitter", "Desync Spin", "Ping-Pong Spin", "Independent Sway",
    "Explicit LBY Flick", "Chaos Desync"
}

-- Create the UI Tab
local sec_state = vtab:new_section("Anti Aim", "Left")

-- UI Elements (Defaults set to your requested values)
cfg.enabled = sec_state:new_toggle("Enable Stand AA (Priority)", false)
cfg.pitch_mode = sec_state:new_combobox("Pitch Mode", PITCH_MODES, "Disabled")
cfg.pitch_custom = sec_state:new_slider("Pitch Value", -89, 89, -89, 0, "°")
cfg.pitch_delay = sec_state:new_slider("Pitch Delay", 1, 32, 32, 0, "t")
cfg.pitch_randomize = sec_state:new_slider("Pitch Delay Randomize", 0, 16, 0, 0, "t")
cfg.pitch_hold1 = sec_state:new_slider("Pitch Angle 1 Hold", 0.5, 32, 0.5, 0, "t")
cfg.pitch_hold2 = sec_state:new_slider("Pitch Angle 2 Hold", 1, 32, 1, 0, "t")

cfg.yaw_base = sec_state:new_combobox("Yaw Base", { "Camera", "World" }, "Camera")
cfg.yaw_add = sec_state:new_slider("Yaw Offset", -180, 180, -180, 0, "°")
cfg.yaw_delay = sec_state:new_slider("Yaw Delay", 1, 32, 1, 0, "t")
cfg.yaw_randomize = sec_state:new_slider("Yaw Delay Randomize", 0, 16, 0, 0, "t")
cfg.yaw_hold = sec_state:new_slider("Yaw Hold Ticks", 1, 32, 1, 0, "t")

cfg.yaw_mod = sec_state:new_combobox("Yaw Modifier", { "Disabled", "Center", "Random", "Spin", "3-Way", "5-Way", "Jitter" }, "Disabled")
cfg.mod_range = sec_state:new_slider("Modifier Range", -180, 180, 0, 0, "°")
cfg.mod_delay = sec_state:new_slider("Modifier Delay", 1, 32, 1, 0, "t")
cfg.mod_randomize = sec_state:new_slider("Modifier Delay Randomize", 0, 16, 0, 0, "t")
cfg.mod_hold1 = sec_state:new_slider("Modifier Angle 1 Hold", 1, 32, 1, 0, "t")
cfg.mod_hold2 = sec_state:new_slider("Modifier Angle 2 Hold", 1, 32, 1, 0, "t")

cfg.body_yaw = sec_state:new_toggle("Enable Desync", false)
cfg.desync_mode = sec_state:new_combobox("Desync Mode", DESYNC_MODES, "Static")
cfg.inverter = sec_state:new_toggle("Invert Side", false)
cfg.desync_delay = sec_state:new_slider("Desync Delay", 1, 32, 1, 0, "t")
cfg.desync_randomize = sec_state:new_slider("Desync Delay Randomize", 0, 16, 0, 0, "t")
cfg.desync_hold1 = sec_state:new_slider("Desync Side 1 Hold", 1, 32, 1, 0, "t")
cfg.desync_hold2 = sec_state:new_slider("Desync Side 2 Hold", 1, 32, 1, 0, "t")
cfg.desync_left = sec_state:new_slider("Left Limit", 0, 86, 60, 0, "°")
cfg.desync_right = sec_state:new_slider("Right Limit", 0, 86, 60, 0, "°")
cfg.desync_range = sec_state:new_slider("Desync Jitter Range", 0, 86, 26, 0, "°")
cfg.desync_real = sec_state:new_slider("Explicit Real Angle", -86, 86, -58, 0, "°")
cfg.desync_fake = sec_state:new_slider("Explicit Fake Angle", -86, 86, 58, 0, "°")
cfg.desync_spin_speed = sec_state:new_slider("Desync Spin Speed", 1, 50, 10, 0, "°/t")

cfg.fake_lag = sec_state:new_toggle("Enable Fake Lag", false)
cfg.fake_lag_limit = sec_state:new_slider("Fake Lag Choke", 1, 14, 14, 0, "t")
cfg.fake_lag_var = sec_state:new_slider("Fake Lag Variability", 0, 100, 0, 0, "%")

cfg.brute_enable = sec_state:new_toggle("Enable Anti-Bruteforce", false)
cfg.brute_mode = sec_state:new_combobox("Anti-Brute Mode", { "Invert Side", "Yaw Phase", "Full Invert" }, "Invert Side")
cfg.brute_yaw_angle = sec_state:new_slider("Anti-Brute Yaw Offset", -180, 180, 90, 0, "°")
cfg.brute_max_stages = sec_state:new_slider("Anti-Brute Stages", 2, 5, 2, 0)
cfg.brute_timer = sec_state:new_slider("Anti-Brute Reset Timer", 0, 128, 32, 0, "t")

-- Runtime tracking for Stand
local rt = {
    cached_pitch = nil, pitch_jitter_flag = false, pitch_next_switch = 0,
    cached_yaw = 0, yaw_next_switch = 0,
    cached_mod_val = 0, mod_side = false, mod_stage = 0, mod_next_switch = 0,
    cached_inverter = false, desync_side = false, desync_next_switch = 0,
    desync_cached_left = 60, desync_cached_right = 60, desync_spin_angle = 0,
    desync_spin_dir = 1, desync_stage = 0, desync_cached_real = -58, desync_cached_fake = 58,
    lby_flick = false,
    brute_stage = 0, brute_inverted = false, brute_yaw_offset = 0, brute_expire_tick = 0
}

-- Helper Functions
local function calc_duration(base_ticks, randomize_ticks)
    local b = math.max(1, base_ticks)
    local r = math.max(0, randomize_ticks or 0)
    if r > 0 then
        local delta = math.random(-r, r)
        return math.max(1, b + delta)
    end
    return b
end

local function trigger_anti_bruteforce(tick, reason)
    if not cfg.enabled:get() or not cfg.brute_enable:get() then return false end
    if tick - last_brute_trigger_tick < 4 then return false end
    
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return false end
    
    last_brute_trigger_tick = tick
    local max_stages = math.max(2, cfg.brute_max_stages:get())
    rt.brute_stage = ((rt.brute_stage or 0) + 1) % max_stages
    rt.brute_inverted = not rt.brute_inverted
    
    local timer = cfg.brute_timer:get()
    rt.brute_expire_tick = (timer > 0) and (tick + timer) or (tick + 999999)
    
    local b_mode = cfg.brute_mode:get()
    local b_yaw = cfg.brute_yaw_angle:get()
    
    if b_mode == "Yaw Phase" or b_mode == "Full Invert" then
        rt.brute_yaw_offset = (rt.brute_stage % 2 == 1) and b_yaw or -b_yaw
    else
        rt.brute_yaw_offset = 0
    end
    return true
end

-- Bullet impact & player hurt event listeners (Anti-Bruteforce)
pcall(function()
    client.set_event_callback("bullet_impact", function(e)
        local lp = entity.get_local_player()
        if not lp or not entity.is_alive(lp) then return end
        local my_head = entity.get_player_hitbox_position(lp, "head") or entity.get_player_position(lp)
        if my_head and e and e.point then
            local dist = (e.point - my_head).Magnitude
            if dist <= 18 then
                trigger_anti_bruteforce(globals.tickcount(), string.format("Bullet Impact (%.1fst)", dist))
            end
        end
    end)
end)

pcall(function()
    client.set_event_callback("player_hurt", function(e)
        local lp = entity.get_local_player()
        if not lp or not entity.is_alive(lp) then return end
        if e and (e.victim == lp or e.target == lp) then
            trigger_anti_bruteforce(globals.tickcount(), "Player Hurt")
        end
    end)
end)

-- The EXACT AA Builder apply_aa Function
local function apply_aa(tick)
    local lp = entity.get_local_player()
    
    -- Anti-Bruteforce expiration check
    if rt.brute_expire_tick and rt.brute_expire_tick > 0 and tick >= rt.brute_expire_tick then
        rt.brute_stage = 0; rt.brute_inverted = false; rt.brute_yaw_offset = 0; rt.brute_expire_tick = 0
    end

    -- 1. Pitch with its OWN delay, hold and randomization
    local p_mode = cfg.pitch_mode:get()
    local p_rand = cfg.pitch_randomize:get()
    local p_hold1 = cfg.pitch_hold1:get()
    local p_hold2 = cfg.pitch_hold2:get()

    if p_mode == "Disabled" then
        aa.override_pitch(nil)
    elseif p_mode == "Down" then aa.override_pitch(-89)
    elseif p_mode == "Up" then aa.override_pitch(89)
    elseif p_mode == "Zero" then aa.override_pitch(0)
    elseif p_mode == "Semi-Down" then aa.override_pitch(-45)
    elseif p_mode == "Custom" then aa.override_pitch(cfg.pitch_custom:get())
    elseif p_mode == "Sway" then aa.override_pitch(math.floor(math.sin(tick * 0.15) * 89))
    else
        if tick >= rt.pitch_next_switch then
            if p_mode == "Jitter" then
                rt.pitch_jitter_flag = not rt.pitch_jitter_flag
                local base_hold = rt.pitch_jitter_flag and p_hold1 or p_hold2
                rt.pitch_next_switch = tick + calc_duration(base_hold, p_rand)
                rt.cached_pitch = rt.pitch_jitter_flag and 89 or -89
            elseif p_mode == "Random" then
                rt.pitch_next_switch = tick + calc_duration(cfg.pitch_delay:get(), p_rand)
                rt.cached_pitch = math.random(-89, 89)
            elseif p_mode == "Flick" then
                rt.pitch_jitter_flag = not rt.pitch_jitter_flag
                local base_hold = rt.pitch_jitter_flag and p_hold1 or (cfg.pitch_delay:get() * 3)
                rt.pitch_next_switch = tick + calc_duration(base_hold, p_rand)
                rt.cached_pitch = rt.pitch_jitter_flag and 89 or -89
            end
        end
        if rt.cached_pitch ~= nil then aa.override_pitch(rt.cached_pitch) end
    end

    -- 2. Yaw Base
    local base = string.lower(cfg.yaw_base:get())
    if tick >= rt.yaw_next_switch then
        rt.yaw_next_switch = tick + calc_duration(cfg.yaw_hold:get(), cfg.yaw_randomize:get())
        rt.cached_yaw = cfg.yaw_add:get()
    end

    -- 3. Yaw Modifier
    local mod = cfg.yaw_mod:get()
    local mod_range = cfg.mod_range:get()
    local m_rand = cfg.mod_randomize:get()
    local m_hold1 = cfg.mod_hold1:get()
    local m_hold2 = cfg.mod_hold2:get()
    local m_delay = cfg.mod_delay:get()

    if mod == "Disabled" then rt.cached_mod_val = 0
    elseif mod == "Jitter" then
        if tick >= rt.mod_next_switch then
            rt.mod_side = not rt.mod_side
            local base_hold = (m_hold1 > 1 or m_hold2 > 1) and (rt.mod_side and m_hold1 or m_hold2) or m_delay
            rt.mod_next_switch = tick + calc_duration(base_hold, m_rand)
            rt.cached_mod_val = rt.mod_side and mod_range or -mod_range
        end
    elseif mod == "Center" then
        if tick >= rt.mod_next_switch then
            rt.mod_side = not rt.mod_side
            local base_hold = (m_hold1 > 1 or m_hold2 > 1) and (rt.mod_side and m_hold1 or m_hold2) or m_delay
            rt.mod_next_switch = tick + calc_duration(base_hold, m_rand)
            rt.cached_mod_val = rt.mod_side and mod_range or 0
        end
    elseif mod == "3-Way" then
        if tick >= rt.mod_next_switch then
            rt.mod_stage = ((rt.mod_stage or 0) + 1) % 3
            rt.mod_next_switch = tick + calc_duration(m_delay, m_rand)
            if rt.mod_stage == 0 then rt.cached_mod_val = -mod_range
            elseif rt.mod_stage == 1 then rt.cached_mod_val = 0
            else rt.cached_mod_val = mod_range end
        end
    elseif mod == "5-Way" then
        if tick >= rt.mod_next_switch then
            rt.mod_stage = ((rt.mod_stage or 0) + 1) % 5
            rt.mod_next_switch = tick + calc_duration(m_delay, m_rand)
            local half = math.floor(mod_range / 2)
            if rt.mod_stage == 0 then rt.cached_mod_val = -mod_range
            elseif rt.mod_stage == 1 then rt.cached_mod_val = -half
            elseif rt.mod_stage == 2 then rt.cached_mod_val = 0
            elseif rt.mod_stage == 3 then rt.cached_mod_val = half
            else rt.cached_mod_val = mod_range end
        end
    elseif mod == "Random" then
        if tick >= rt.mod_next_switch then
            rt.mod_next_switch = tick + calc_duration(m_delay, m_rand)
            local r_abs = math.abs(mod_range)
            rt.cached_mod_val = r_abs > 0 and math.random(-r_abs, r_abs) or 0
        end
    elseif mod == "Spin" then
        if tick >= rt.mod_next_switch then
            rt.mod_next_switch = tick + calc_duration(m_delay, m_rand)
            local spin_step = math.abs(mod_range) > 0 and mod_range or 15
            rt.cached_mod_val = (rt.cached_mod_val + spin_step + 180) % 360 - 180
        end
    else rt.cached_mod_val = 0 end

    -- Anti-Bruteforce Yaw Offset
    local brute_yaw = 0
    if cfg.brute_enable:get() then
        local b_mode = cfg.brute_mode:get()
        if b_mode == "Yaw Phase" or b_mode == "Full Invert" then brute_yaw = rt.brute_yaw_offset or 0 end
    end

    local active_side = cfg.inverter:get()
    
    if cfg.brute_enable:get() and rt.brute_inverted then
        local b_mode = cfg.brute_mode:get()
        if b_mode == "Invert Side" or b_mode == "Full Invert" then
            active_side = not active_side
            rt.desync_side = not rt.desync_side
        end
    end

    local final_yaw = rt.cached_yaw + (rt.cached_mod_val or 0) + brute_yaw
    final_yaw = (final_yaw + 180) % 360 - 180
    aa.override_yaw(final_yaw, base)
    aa.override_yaw_modifier("Disabled")
    if aa.override_yaw_offset then aa.override_yaw_offset(0) end

    -- 4. Desync Modes
    local desync_enabled = cfg.body_yaw:get()
    aa.override_body_yaw(desync_enabled)
    
    if desync_enabled then
        local mode = cfg.desync_mode:get()
        local d_delay = cfg.desync_delay:get()
        local d_rand = cfg.desync_randomize:get()
        local d_hold1 = cfg.desync_hold1:get()
        local d_hold2 = cfg.desync_hold2:get()
        local lim_l = cfg.desync_left:get()
        local lim_r = cfg.desync_right:get()
        local d_range = cfg.desync_range:get()

        if mode == "Static" then
            pcall(function() aa.override_desync(nil, nil) end)
            aa.override_inverter(active_side)
            aa.override_desync_limits(lim_l, lim_r)
        elseif mode == "Jitter" then
            if tick >= rt.desync_next_switch then
                rt.desync_side = not rt.desync_side
                local base_hold = (d_hold1 > 1 or d_hold2 > 1) and (rt.desync_side and d_hold1 or d_hold2) or d_delay
                rt.desync_next_switch = tick + calc_duration(base_hold, d_rand)
            end
            pcall(function() aa.override_desync(nil, nil) end)
            local min_l = math.max(15, lim_l - d_range)
            local min_r = math.max(15, lim_r - d_range)
            local cur_l = rt.desync_side and lim_l or min_l
            local cur_r = rt.desync_side and min_r or lim_r
            aa.override_inverter(rt.desync_side)
            aa.override_desync_limits(cur_l, cur_r)
        elseif mode == "Random" then
            if tick >= rt.desync_next_switch then
                rt.desync_next_switch = tick + calc_duration(d_delay, d_rand)
                rt.desync_side = (math.random(1, 2) == 1)
                local min_l = math.max(15, lim_l - d_range)
                local min_r = math.max(15, lim_r - d_range)
                rt.desync_cached_left = math.random(min_l, math.max(min_l, lim_l))
                rt.desync_cached_right = math.random(min_r, math.max(min_r, lim_r))
            end
            pcall(function() aa.override_desync(nil, nil) end)
            aa.override_inverter(rt.desync_side)
            aa.override_desync_limits(rt.desync_cached_left, rt.desync_cached_right)
        elseif mode == "Sway" then
            pcall(function() aa.override_desync(nil, nil) end)
            local sway_speed = math.max(0.02, 0.2 / math.max(1, d_delay))
            local sway_pct = (math.sin(tick * sway_speed) + 1) * 0.5
            local min_l = math.max(15, lim_l - d_range)
            local min_r = math.max(15, lim_r - d_range)
            aa.override_inverter(active_side)
            aa.override_desync_limits(math.floor(min_l + (lim_l - min_l) * sway_pct), math.floor(min_r + (lim_r - min_r) * sway_pct))
        elseif mode == "Switch" then
            if tick >= rt.desync_next_switch then
                rt.desync_side = not rt.desync_side
                local base_hold = (d_hold1 > 1 or d_hold2 > 1) and (rt.desync_side and d_hold1 or d_hold2) or d_delay
                rt.desync_next_switch = tick + calc_duration(base_hold, d_rand)
            end
            pcall(function() aa.override_desync(nil, nil) end)
            aa.override_inverter(rt.desync_side)
            aa.override_desync_limits(lim_l, lim_r)
        elseif mode == "Micro-Jitter" then
            if tick >= rt.desync_next_switch then
                rt.desync_side = not rt.desync_side
                rt.desync_next_switch = tick + calc_duration(d_delay, d_rand)
            end
            pcall(function() aa.override_desync(nil, nil) end)
            local micro_delta = math.min(30, math.max(5, d_range))
            aa.override_inverter(active_side)
            aa.override_desync_limits(rt.desync_side and lim_l or math.max(15, lim_l - micro_delta), rt.desync_side and math.max(15, lim_r - micro_delta) or lim_r)
        elseif mode == "LBY Breaker" then
            if tick >= rt.desync_next_switch then
                rt.lby_flick = not rt.lby_flick
                local hold_time = (d_hold1 > 1) and d_hold1 or math.max(4, d_delay * 3)
                rt.desync_next_switch = tick + (rt.lby_flick and 1 or calc_duration(hold_time, d_rand))
            end
            pcall(function() aa.override_desync(nil, nil) end)
            if rt.lby_flick then
                aa.override_inverter(not active_side)
                aa.override_desync_limits(86, 86)
            else
                aa.override_inverter(active_side)
                aa.override_desync_limits(lim_l, lim_r)
            end
        elseif mode == "Explicit" then
            local r_ang = cfg.desync_real:get()
            local f_ang = cfg.desync_fake:get()
            if active_side then aa.override_desync(-r_ang, -f_ang) else aa.override_desync(r_ang, f_ang) end
        elseif mode == "Explicit Jitter" then
            if tick >= rt.desync_next_switch then
                rt.desync_side = not rt.desync_side
                local base_hold = (d_hold1 > 1 or d_hold2 > 1) and (rt.desync_side and d_hold1 or d_hold2) or d_delay
                rt.desync_next_switch = tick + calc_duration(base_hold, d_rand)
            end
            local r_ang = cfg.desync_real:get()
            local cur_f = rt.desync_side and cfg.desync_fake:get() or -cfg.desync_fake:get()
            if active_side then aa.override_desync(-r_ang, -cur_f) else aa.override_desync(r_ang, cur_f) end
        elseif mode == "Explicit Random" then
            if tick >= rt.desync_next_switch then
                rt.desync_next_switch = tick + calc_duration(d_delay, d_rand)
                local f_abs = math.max(15, math.abs(cfg.desync_fake:get()))
                rt.desync_cached_fake = math.random(-f_abs, f_abs)
            end
            local r_ang = cfg.desync_real:get()
            local cur_f = rt.desync_cached_fake or cfg.desync_fake:get()
            if active_side then aa.override_desync(-r_ang, -cur_f) else aa.override_desync(r_ang, cur_f) end
        elseif mode == "Explicit 3-Way" then
            if tick >= rt.desync_next_switch then
                rt.desync_stage = ((rt.desync_stage or 0) + 1) % 3
                rt.desync_next_switch = tick + calc_duration(d_delay, d_rand)
                local f_base = cfg.desync_fake:get()
                rt.desync_cached_fake = rt.desync_stage == 0 and -f_base or (rt.desync_stage == 1 and 0 or f_base)
            end
            local r_ang = cfg.desync_real:get()
            local cur_f = rt.desync_cached_fake or cfg.desync_fake:get()
            if active_side then aa.override_desync(-r_ang, -cur_f) else aa.override_desync(r_ang, cur_f) end
        elseif mode == "Explicit 5-Way" then
            if tick >= rt.desync_next_switch then
                rt.desync_stage = ((rt.desync_stage or 0) + 1) % 5
                rt.desync_next_switch = tick + calc_duration(d_delay, d_rand)
                local f_base = cfg.desync_fake:get()
                local half = math.floor(f_base / 2)
                if rt.desync_stage == 0 then rt.desync_cached_fake = -f_base
                elseif rt.desync_stage == 1 then rt.desync_cached_fake = -half
                elseif rt.desync_stage == 2 then rt.desync_cached_fake = 0
                elseif rt.desync_stage == 3 then rt.desync_cached_fake = half
                else rt.desync_cached_fake = f_base end
            end
            local r_ang = cfg.desync_real:get()
            local cur_f = rt.desync_cached_fake or cfg.desync_fake:get()
            if active_side then aa.override_desync(-r_ang, -cur_f) else aa.override_desync(r_ang, cur_f) end
        elseif mode == "Dual Jitter" then
            if tick >= rt.desync_next_switch then
                rt.desync_side = not rt.desync_side
                local base_hold = (d_hold1 > 1 or d_hold2 > 1) and (rt.desync_side and d_hold1 or d_hold2) or d_delay
                rt.desync_next_switch = tick + calc_duration(base_hold, d_rand)
            end
            local r_ang, f_ang = cfg.desync_real:get(), cfg.desync_fake:get()
            local cur_r = rt.desync_side and r_ang or -r_ang
            local cur_f = rt.desync_side and f_ang or -f_ang
            if active_side then aa.override_desync(-cur_r, -cur_f) else aa.override_desync(cur_r, cur_f) end
        elseif mode == "Real Jitter" then
            if tick >= rt.desync_next_switch then
                rt.desync_side = not rt.desync_side
                local base_hold = (d_hold1 > 1 or d_hold2 > 1) and (rt.desync_side and d_hold1 or d_hold2) or d_delay
                rt.desync_next_switch = tick + calc_duration(base_hold, d_rand)
            end
            local r_ang, f_ang = cfg.desync_real:get(), cfg.desync_fake:get()
            local cur_r = rt.desync_side and r_ang or -r_ang
            if active_side then aa.override_desync(-cur_r, -f_ang) else aa.override_desync(cur_r, f_ang) end
        elseif mode == "Desync Spin" then
            if tick >= rt.desync_next_switch then
                rt.desync_next_switch = tick + calc_duration(d_delay, d_rand)
                local next_angle = (rt.desync_spin_angle or 0) + cfg.desync_spin_speed:get()
                if next_angle > 86 then next_angle = -86 + (next_angle - 86) elseif next_angle < -86 then next_angle = 86 + (next_angle + 86) end
                rt.desync_spin_angle = next_angle
            end
            local r_ang, f_ang = cfg.desync_real:get(), math.floor(rt.desync_spin_angle or 0)
            if active_side then aa.override_desync(-r_ang, -f_ang) else aa.override_desync(r_ang, f_ang) end
        elseif mode == "Ping-Pong Spin" then
            if tick >= rt.desync_next_switch then
                rt.desync_next_switch = tick + calc_duration(d_delay, d_rand)
                rt.desync_spin_dir = rt.desync_spin_dir or 1
                local next_angle = (rt.desync_spin_angle or 0) + (cfg.desync_spin_speed:get() * rt.desync_spin_dir)
                if next_angle >= 86 then next_angle = 86; rt.desync_spin_dir = -1
                elseif next_angle <= -86 then next_angle = -86; rt.desync_spin_dir = 1 end
                rt.desync_spin_angle = next_angle
            end
            local r_ang, f_ang = cfg.desync_real:get(), math.floor(rt.desync_spin_angle or 0)
            if active_side then aa.override_desync(-r_ang, -f_ang) else aa.override_desync(r_ang, f_ang) end
        elseif mode == "Independent Sway" then
            local sway_speed = math.max(0.02, 0.2 / math.max(1, d_delay))
            local sway_val = math.sin(tick * sway_speed)
            local r_ang = math.floor(cfg.desync_real:get() * sway_val)
            local f_ang = math.floor(cfg.desync_fake:get() * -sway_val)
            if math.abs(r_ang - f_ang) < 25 then f_ang = (cfg.desync_fake:get() >= 0) and 35 or -35 end
            if active_side then aa.override_desync(-r_ang, -f_ang) else aa.override_desync(r_ang, f_ang) end
        elseif mode == "Explicit LBY Flick" then
            if tick >= rt.desync_next_switch then
                rt.lby_flick = not rt.lby_flick
                local hold_time = (d_hold1 > 1) and d_hold1 or math.max(4, d_delay * 3)
                rt.desync_next_switch = tick + (rt.lby_flick and 1 or calc_duration(hold_time, d_rand))
            end
            local r_ang, f_ang = cfg.desync_real:get(), cfg.desync_fake:get()
            local cur_f = rt.lby_flick and (f_ang >= 0 and -86 or 86) or f_ang
            if active_side then aa.override_desync(-r_ang, -cur_f) else aa.override_desync(r_ang, cur_f) end
        elseif mode == "Chaos Desync" then
            if tick >= rt.desync_next_switch then
                rt.desync_next_switch = tick + calc_duration(d_delay, d_rand)
                local r_rnd = math.random(25, 86) * (math.random(1, 2) == 1 and 1 or -1)
                local f_rnd = r_rnd > 0 and math.random(-86, -20) or math.random(20, 86)
                rt.desync_cached_real = r_rnd
                rt.desync_cached_fake = f_rnd
            end
            local cur_r, cur_f = rt.desync_cached_real or cfg.desync_real:get(), rt.desync_cached_fake or cfg.desync_fake:get()
            if active_side then aa.override_desync(-cur_r, -cur_f) else aa.override_desync(cur_r, cur_f) end
        end
    else
        pcall(function() aa.override_desync(nil, nil) end)
    end

    -- 5. Fake Lag
    local lag_enabled = cfg.fake_lag:get()
    aa.override_fake_lag(lag_enabled)
    if lag_enabled then
        aa.override_fake_lag_limit(cfg.fake_lag_limit:get())
        aa.override_fake_lag_variability(cfg.fake_lag_var:get())
    end
end

-- 64 Hz Client Simulation Tick Hook
events.on_tick(function(tick)
    if not cfg.enabled:get() then
        pcall(function() aa.reset() end)
        return
    end

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        aa.reset()
        return
    end

    local cur_health = entity.get_player_health(lp)
    if cur_health and last_local_health and cur_health < last_local_health and cur_health > 0 then
        trigger_anti_bruteforce(tick, string.format("Damage Taken (-%d hp)", math.floor(last_local_health - cur_health)))
    end
    last_local_health = cur_health

    -- Apply Stand AA
    apply_aa(tick)
end)

client.set_event_callback("shutdown", function()
    pcall(function() aa.reset() end)
end)
end) -- end delayed Vortex initialization (keeps vtab/cfg in scope)







