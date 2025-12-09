pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-------------------------------------
-- game state
-------------------------------------
state = "menu" -- can be: menu, player_select, char_select game

player_count = 2
max_players = 4

-- hand sprite index
hand_sprite = 0

hand = { x = 0, y = 0 }
selected = 1

-- dice shared for now
dice = {
    { x = 40, y = 40, value = 1 },
    { x = 60, y = 40, value = 1 },
    { x = 80, y = 40, value = 1 }
}

-- players (index 1 = human)
players = {}
current_player = 1
char_select_config = {
    selected_player = 1,
    chosen_character_idx = 1
}

characters = {
    { name = "warrior", sprite = 16 },
    { name = "mage", sprite = 18 },
    { name = "rogue", sprite = 20 },
    { name = "cleric", sprite = 22 }
}
-------------------------------------
function init_players()
    players = {}
    characterCounter = 1
    for i = 1, player_count do
        add(players, { ai = false, score = 0, character = characters[characterCounter] })
        characterCounter += 1
    end
    -- fill remaining as ai
    for i = player_count + 1, max_players do
        add(players, { ai = true, score = 0, character = characters[characterCounter] })
        characterCounter += 1
    end
end
-------------------------------------

function _init()
    update_hand_pos()
end

-------------------------------------
-- helpers
-------------------------------------

function update_hand_pos()
    local d = dice[selected]
    hand.x = d.x - 10
    hand.y = d.y
end

function roll_dice()
    for d in all(dice) do
        d.value = flr(rnd(6)) + 1
    end
end

function total_value()
    local t = 0
    for d in all(dice) do
        t += d.value
    end
    return t
end

function ai_take_turn()
    -- super simple ai: roll once
    roll_dice()
end

function hcenter(s)
    -- screen center minus the
    -- string length times the
    -- pixels in a char's width,
    -- cut in half
    return 64 - #s * 2
end

function vcenter(s)
    -- screen center minus the
    -- string height in pixels,
    -- cut in half
    return 61
end

function print_center(s, y, color)
    print(s, hcenter(s), y, color)
end

-------------------------------------
-- state: main menu
-------------------------------------
function update_menu()
    if btnp(➡️) then
        state = "player_select"
    end
end

function draw_menu()
    cls(5)
    print_center("dice and bones", 40, 7)
    print_center("press ➡️ to start", 60, 11)
end

-------------------------------------
-- state: player selection
-------------------------------------
function update_player_select()
    if btnp(⬇️) then
        player_count = max(2, player_count - 1) -- minimum 2 players
    end
    if btnp(⬆️) then
        player_count = min(max_players, player_count + 1) -- maximum 4 players
    end

    if btnp(➡️) then
        init_players()
        state = "char_select"
    end
end

function draw_player_select()
    cls(5)
    print_center("select players", 20, 7)
    print_center("use ⬆️/⬇️", 32, 6)
    print_center("players: " .. player_count, 50, 10)
    print_center("press ➡️ to continue", 90, 11)
end

-------------------------------------
-- state: char select
-------------------------------------
function update_char_select()
    if btnp(⬇️) then
        char_select_config.chosen_character_idx = max(1, char_select_config.chosen_character_idx - 1)
    end
    if btnp(⬆️) then
        char_select_config.chosen_character_idx = min(#characters, char_select_config.chosen_character_idx + 1)
    end
    players[char_select_config.selected_player].character = characters[char_select_config.chosen_character_idx]

    if btnp(➡️) then
        if char_select_config.selected_player < player_count then
            char_select_config.selected_player += 1
        elseif char_select_config.selected_player >= player_count then
            state = "game"
        end
    end

    if btnp(⬅️) then
        if char_select_config.selected_player > 1 then
            char_select_config.selected_player -= 1
        end
    end
end

function draw_char_select()
    cls(5)
    print("select character for player " .. char_select_config.selected_player, 20, 20, 7)
    print("use ⬆️/⬇️", 30, 32, 6)
    -- display character sprites for each player in a row
    interval = 28
    x = 16
    for i = 1, player_count do
        local char = players[i].character
        if i == char_select_config.selected_player then
            rectfill(x + 8, 44, x + 10, 46, 7)
        end
        if char then
            spr(char.sprite, x, 50, 2, 2, 0, 0, 1, 1)
            print(char.name, x, 70, 10)
        end
        x += interval
    end
    if char_select_config.selected_player < player_count then
        print("press ➡️ to continue", 16, 90, 11)
    else
        print("press ➡️ to start", 16, 90, 11)
    end
end

-------------------------------------
-- state: actual game
-------------------------------------
function update_game()
    local p = players[current_player]

    if p.ai then
        ai_take_turn()
        -- scoring for demo
        p.score += total_value()
        next_player()
        return
    end

    -- human player control
    if btnp(0) then
        selected = max(1, selected - 1) update_hand_pos()
    end
    if btnp(1) then
        selected = min(#dice, selected + 1) update_hand_pos()
    end

    -- roll
    if btnp(4) then
        roll_dice()
        p.score += total_value()
        next_player()
    end
end

function next_player()
    current_player += 1
    if current_player > max_players then
        current_player = 1
    end
end

function draw_game()
    cls(5)

    -- dice
    for d in all(dice) do
        rectfill(d.x, d.y, d.x + 8, d.y + 8, 7)
        print(d.value, d.x + 2, d.y + 2, 0)
    end

    -- hand
    spr(hand_sprite, hand.x, hand.y)

    -- scores
    for i, p in ipairs(players) do
        local label = p.ai and "ai" or "p" .. i
        print(label .. ":" .. p.score, 5, 5 + (i - 1) * 7, p.ai and 8 or 11)
    end

    print("current: " .. current_player, 90, 5, 10)
    print("❎ roll", 45, 110, 7)
end

-------------------------------------
-- main update + draw
-------------------------------------
function _update()
    if state == "menu" then
        update_menu()
    elseif state == "player_select" then
        update_player_select()
    elseif state == "char_select" then
        update_char_select()
    elseif state == "game" then
        update_game()
    end
end

function _draw()
    if state == "menu" then
        draw_menu()
    elseif state == "player_select" then
        draw_player_select()
    elseif state == "char_select" then
        draw_char_select()
    elseif state == "game" then
        draw_game()
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000cc00000000000040000070700000aaa000060000000000000000000000000000000000000000000000000000000000000000000000
0000000000440000000000cc00000000000046000747470000000006666600000000000000000000000000000000000000000000000000000000000000000000
00000000044660000000007c00000000000446000040400000000066666660aa0000000000000000000000000000000000000000000000000000000000000000
000000004466660000000c77000000000044060005555500a066006666666a000000000000000000000000000000000000000000000000000000000000000000
00000004406d666000000cc7000000000040060005555500a0666066666660000000000000000000000000000000000000000000000000000000000000000000
00000044000dd66600000ccc0000000000400600055550000a666066666660000000000000000000000000000000000000000000000000000000000000000000
00000440000d666000000ccc000000000040060005555000006d6066666660000000000000000000000000000000000000000000000000000000000000000000
000044000000666000000cccc00000000040066000555000006d6666666660aa0000000000000000000000000000000000000000000000000000000000000000
00004000000666000000c777c00000000040006000555000006d6666666660000000000000000000000000000000000000000000000000000000000000000000
00040000000000000000c77cc00000000040006000555500006dd666666660000000000000000000000000000000000000000000000000000000000000000000
0044000000000000000ccc77c000000000400060005555000066dd66666660000000000000000000000000000000000000000000000000000000000000000000
0440000000000000000ccccccccccc000040066000555500a0006666666660000000000000000000000000000000000000000000000000000000000000000000
440000000000000000cccccccc000ccc004006000055500000006666666660aa0000000000000000000000000000000000000000000000000000000000000000
0000000000000000ccc0000000000000004446000055500000a006666666600a0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000460000000000aaa00666666600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000040000000000000000666660000000000000000000000000000000000000000000000000000000000000000000000
