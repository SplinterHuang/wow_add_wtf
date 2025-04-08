local _, BigFootBot = ...
BigFootBot.token = {}

local T = BigFootBot.token
local U = BigFootBot.utils

local token_debug_print = false
local TIME_POINTS = {15, 35, 55} -- 获取数据的时间点

---------------------------------------------------------------------
-- 下次执行的倒计时
---------------------------------------------------------------------
local function GetNextUpdateCountdown()
    local t = date("*t", GetServerTime())
    if t.min >= TIME_POINTS[#TIME_POINTS] then
        -- 大于最后一个时间点
        return (60 - t.min) * 60 - t.sec + TIME_POINTS[1] * 60, t
    else
        for _, v in pairs(TIME_POINTS) do
            if t.min < v then
                return (v - t.min) * 60 - t.sec, t
            end
        end
    end
end

---------------------------------------------------------------------
-- 保存数据
---------------------------------------------------------------------
local timestamp

local function SaveTokenPrice()
    local price = C_WowTokenPublic.GetCurrentMarketPrice()
    if token_debug_print then
        print("UPDATE:", "[" .. timestamp .. "] = " .. price)
    end
    BigFootBotTokenDB[timestamp] = price
    timestamp = nil
end

local function RequestTokenPrice()
    -- 校验时间
    local t = date("*t", GetServerTime())
    for _, v in pairs(TIME_POINTS) do
        if t.min == v then
            t.sec = 0
            timestamp = time(t)
            break
        end
    end

    if timestamp and not InCombatLockdown() then -- 非战斗中
        if token_debug_print then
            print("UPDATE IN 10 SEC!!! ", string.format("%02d:%02d:%02d", t.hour, t.min, t.sec))
        end
        C_WowTokenPublic.UpdateMarketPrice() -- 请求数据
        C_Timer.After(10, SaveTokenPrice) -- 10秒后记录，而非监听 TOKEN_MARKET_PRICE_UPDATED 事件
    end

    -- 准备下次
    local timeDelayed, t = GetNextUpdateCountdown()
    if token_debug_print then
        print("NOW:", time(t), string.format("%02d:%02d:%02d", t.hour, t.min, t.sec), ", NEXT:", string.format("%dm%ds", floor(timeDelayed / 60), timeDelayed % 60))
    end
    C_Timer.After(GetNextUpdateCountdown(), RequestTokenPrice)
end

---------------------------------------------------------------------
-- 启用
---------------------------------------------------------------------
function T:StartTockenPriceUpdater()
    local timeDelayed, t = GetNextUpdateCountdown()
    if token_debug_print then
        print("NOW:", time(t), string.format("%02d:%02d:%02d", t.hour, t.min, t.sec), ", COUNTDOWN:", string.format("%dm%ds", floor(timeDelayed / 60), timeDelayed % 60))
    end
    C_Timer.After(timeDelayed, RequestTokenPrice)
end