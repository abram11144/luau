repeat task.wait(0.25) until game:IsLoaded()
if workspace.DistributedGameTime < 3 then
    task.wait(3 - workspace.DistributedGameTime)
end

local Players = game:GetService("Players")
repeat task.wait(0.25) until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════
local GITHUB_USER   = "abram11144"
local GITHUB_REPO   = "luau"
local GITHUB_BRANCH = "main"
local GITHUB_PATH   = "Main.luau"

local SourceURL = string.format(
    "https://raw.githubusercontent.com/abram11144/luau/refs/heads/main/Main.luau",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH, GITHUB_PATH
)

local function FetchMain()
    local ok, src = pcall(game.HttpGet, game, SourceURL)
    if ok and type(src) == "string" and #src > 100 then return src end
    return nil
end

local Source = FetchMain()
if not Source then
    return LocalPlayer:Kick("Cannot fetch Main.luau.\nURL: " .. SourceURL)
end

-- ═══════════════════════════════════════════════════════════
-- ⭐ ЭТАП 1: ACTOR BYPASS (работает на Madium без fflag)
-- ═══════════════════════════════════════════════════════════
for _, Table in ipairs({
    {getdeletedactors or get_deleted_actors, run_on_actor or runonactor},
    {getactors or get_actors, run_on_actor or runonactor},
    {getactorthreads or get_actor_threads,
        run_on_thread or runonthread or run_on_actor_thread or runonactorthread},
}) do
    local Get, Run = Table[1], Table[2]
    if Get and Run then
        local ok, Items = pcall(Get)
        if ok and type(Items) == "table" and Items[1] then
            -- Уходим в actor: Main.luau выполнится в главном потоке
            -- → getgc(true) увидит полный GC без DebugRunParallelLuaOnMainThread
            if pcall(Run, Items[1], Source) then
                return
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ⭐ ЭТАП 2: а вдруг getgc уже видит модули без флага?
-- ═══════════════════════════════════════════════════════════
local Getgc = getgc or get_gc
if Getgc then
    local ok, list = pcall(Getgc, true)
    if ok and type(list) == "table" then
        for _, v in next, list do
            if type(v) == "table" and rawget(v, "ScreenCull") and rawget(v, "NetworkClient") then
                -- Модули уже видны — грузим напрямую
                return loadstring(Source)()
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ⭐ ЭТАП 3: fflag как последний шанс (на PC-эках работает)
-- ═══════════════════════════════════════════════════════════
local Getff = getfflag or get_fflag
local Setff = setfflag or set_fflag
local FLAG  = "DebugRunParallelLuaOnMainThread"

local fflagWorks = false
if Getff and Setff then
    local ok, val = pcall(Getff, FLAG)
    if ok then
        fflagWorks = true
        if string.lower(tostring(val)) == "true" then
            return loadstring(Source)()
        end
    end
end

if fflagWorks then
    -- Флаг существует, но выключен → включаем и телепортимся
    pcall(Setff, FLAG, "True")

    local Queue = queueonteleport or queue_on_teleport
    if Queue then
        pcall(Queue, string.format([[
            repeat task.wait(0.25) until game:IsLoaded()
            if workspace.DistributedGameTime < 3 then
                task.wait(3 - workspace.DistributedGameTime)
            end
            local ok, src = pcall(game.HttpGet, game, %q)
            if ok and type(src) == "string" and #src > 100 then
                loadstring(src)()
            end
        ]], SourceURL))
    end

    task.delay(0.35, function()
        local TS = game:GetService("TeleportService")
        for _ = 1, 5 do
            if pcall(TS.Teleport, TS, game.PlaceId) then return end
            task.wait(0.5)
        end
        LocalPlayer:Kick("Teleport failed.\ndiscord.gg/DsGCKtxxEN")
    end)
    return
end

-- ═══════════════════════════════════════════════════════════
-- ⭐ ЭТАП 4: ничего не сработало → объясняем почему
-- ═══════════════════════════════════════════════════════════
LocalPlayer:Kick(
    "PhantomWare не может запуститься на этом экзекуторе.\n\n" ..
    "Причина: Madium не поддерживает:\n" ..
    "  • run_on_actor / getactors (для обхода fflag)\n" ..
    "  • DebugRunParallelLuaOnMainThread (для полного getgc)\n\n" ..
    "Решения:\n" ..
    "  1. Установи PC-экзекутор: Wave, Solara, AWP, Synapse.\n" ..
    "  2. Или платный мобильный: Delta iOS, Codex.\n" ..
    "  3. Или запроси поддержку в Discord Madium.\n\n" ..
    "discord.gg/DsGCKtxxEN"
)
