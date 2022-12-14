local m_ui = minetest.get_modpath('unified_inventory')
local ui = unified_inventory

-- warp function
local function warp(player, warp_point, item_cost)

    local player_name = player:get_player_name()

    if warp_point == nil then
        minetest.chat_send_player(player_name,"Invalid or un-set warp point.")
        return
    end

    -- prevent warp if the destination is protected by another player
    if minetest.is_protected(warp_point, player_name) then
        minetest.chat_send_player(player:get_player_name(), "Can't warp there-- waypoint is protected by another player!")
        return
    end

    -- ensure player can afford the warp
    local inv = minetest.get_inventory({type = "player", name = player_name})
    if not inv:contains_item("main", ItemStack(item_cost)) then
        minetest.chat_send_player(player_name,"You don't have any of that gemstone!")
        return
    end

    -- collect payment for the warp
    inv:remove_item("main", ItemStack(item_cost))
    player:get_inventory():set_list("main", inv:get_list("main")) -- record state


    -- do the warp
    minetest.log("action", "[gemwarp] " .. player_name .. " gemwarped to (" .. warp_point.x .. ", " .. warp_point.y .. ", " .. warp_point.z .. ")")
    player:set_pos(warp_point)

end




local function get_waypoint_data(player)
    local player_name = player:get_player_name()

    -- Get directly from metadata
    local waypoints = player:get_meta():get("ui_waypoints")
    waypoints = waypoints and minetest.parse_json(waypoints) or {}
    waypoints.data = waypoints.data or {}

    return waypoints.data
end


-- formspec function
local function get_formspec(name, waypoints)
    local heading
    local rows = {}
    local is_waypoints_empty = true

    heading = 'size[8,8;]'..
        "label[0.375,0.5;Gem Warp]"

    for i = 1, #waypoints do
        if waypoints[i] ~= nil and waypoints[i]['world_pos'] ~= nil then 
            is_waypoints_empty = false
            local name = waypoints[i]['name'] or "Waypoint "..i
            rows[i] = 
                'label[1,'..(i*0.95+0.25)..';'..name..']'..
                'image_button[3.8,'..(i*0.95)..';0.5,0.5;ameythst.png;warp_'..i..'_amethyst; ]'..
                'image_button[4.6,'..(i*0.95)..';0.5,0.5;ruby.png;warp_'..i..'_ruby; ]'..
                'image_button[5.4,'..(i*0.95)..';0.5,0.5;emerald.png;warp_'..i..'_emerald; ]'..
                'image_button[6.2,'..(i*0.95)..';0.5,0.5;sapphire.png;warp_'..i..'_sapphire; ]'..
                'tooltip[warp_'..i..'_amethyst;Warp to '..name..' using 1 Amethyst]'..
                'tooltip[warp_'..i..'_ruby;Warp to '..name..' using 1 Ruby]'..
                'tooltip[warp_'..i..'_emerald;Warp to '..name..' using 1 Emerald]'..
                'tooltip[warp_'..i..'_sapphire;Warp to '..name..' using 1 Sapphire]'
        else
            rows[i] = ''
        end
    end

    if is_waypoints_empty then
        rows[1] = "label[2.5,3;You don't have any waypoints to warp to.\nCreate a waypoint to get started.]"
    end

    return heading..table.concat(rows)
end



-- when pressing buttons
minetest.register_on_player_receive_fields(function(player, formname, fields)

    if formname ~= "" then return end

    local data = get_waypoint_data(player)

    local is_handled = false


    for i = 1, #data do
        if data[i] ~= nil and data[i]['world_pos'] ~= nil then
            if data[i]['world_pos'] == nil then
                minetest.log('warning', 'Player '..player:get_player_name()..' does not have waypoint '..i..' data. How is this happening? Investigation needed! (see https://github.com/insanity54/gemwarp/issues/4)')
                is_handled = false
            end

            local world_pos = data[i]['world_pos']
            if fields['warp_'..i..'_amethyst'] ~= nil then
                warp(player, world_pos, 'amethyst:amethyst_ingot')
                is_handled = true
            end

            if fields['warp_'..i..'_ruby'] ~= nil then
                warp(player, world_pos, 'ruby:ruby')
                is_handled = true
            end

            if fields['warp_'..i..'_emerald'] ~= nil then
                warp(player, world_pos, 'emerald:emerald')
                is_handled = true
            end

            if fields['warp_'..i..'_sapphire'] ~= nil then
                warp(player, world_pos, 'sapphire:sapphire')
                is_handled = true
            end
        end
    end

    if is_handled then
        return true
    else
        return false
    end
end)




-- unified inventory button
if m_ui then
    unified_inventory.register_button('gemwarp', {
        type = 'image',
        image = 'warp_button.png',
        tooltip = 'Gem Warp'
    })
    unified_inventory.register_page("gemwarp", {
        get_formspec = function(player, perplayer_formspec)
            local name = player:get_player_name()
            local wp_info_x = ui.style_full.form_header_x + 1.25
            local wp_info_y = ui.style_full.form_header_y + 0.5
            local fy = perplayer_formspec.formspec_y
            local waypoints = get_waypoint_data(player)
            local formspec = get_formspec(name, waypoints)..ui.style_full.standard_inv_bg
            return {formspec=formspec}
    end
})
end