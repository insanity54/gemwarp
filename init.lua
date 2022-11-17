local m_ui = minetest.get_modpath('unified_inventory')
local ui = unified_inventory

-- warp function
local function warp(player, warp_point, item_cost)

    local player_name = player:get_player_name()
    -- warp_point = vector.new(warp_point)

    if warp_point == nil then
        minetest.chat_send_player(player_name,"Invalid or un-set warp point.")
        return
    end

    local inv = minetest.get_inventory({type = "player", name = player_name})
    if not inv:contains_item("main", ItemStack(item_cost)) then
        minetest.chat_send_player(player_name,"You don't have any of that gemstone!")
        return
    end

    inv:remove_item("main", ItemStack(item_cost))
    player:get_inventory():set_list("main", inv:get_list("main")) -- record state
    
    player:set_pos(warp_point)

    -- remove warp point if another player protected destination
    minetest.after(2, function(pos, player, warp_point) 
        if minetest.is_protected(pos, player:get_player_name()) then
            minetest.chat_send_player(player:get_player_name(), "Can't warp there-- waypoint is protected by another player!")
        end
    end, pos, player, warp_point)
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

    heading = 'size[8,8;]'..
        "label[0.375,0.5;Gem Warp]"

    for i = 1, #waypoints do
        local name = waypoints[i]['name'] or "Waypoint "..i
        rows[i] = 
            'label[1,'..(i*0.95+0.25)..';'..name..']'..
            'image_button[3.8,'..(i*0.95)..';0.5,0.5;ameythst.png;warp_'..i..'_amethyst;]'..
            'image_button[4.6,'..(i*0.95)..';0.5,0.5;ruby.png;warp_'..i..'_ruby;]'..
            'image_button[5.4,'..(i*0.95)..';0.5,0.5;emerald.png;warp_'..i..'_emerald;]'..
            'image_button[6.2,'..(i*0.95)..';0.5,0.5;sapphire.png;warp_'..i..'_sapphire;]'..
            'tooltip[warp_'..i..'_amethyst;Warp to '..name..' using 1 Amethyst]'..
            'tooltip[warp_'..i..'_ruby;Warp to '..name..' using 1 Ruby]'..
            'tooltip[warp_'..i..'_emerald;Warp to '..name..' using 1 Emerald]'..
            'tooltip[warp_'..i..'_sapphire;Warp to '..name..' using 1 Sapphire]'
    end

    return heading..table.concat(rows)
end



-- when pressing buttons
minetest.register_on_player_receive_fields(function(player, formname, fields)

    if formname ~= "" then return end

    local data = get_waypoint_data(player)



    for i = 1, #data do
        local world_pos = data[i]['world_pos']
        if fields['warp_'..i..'_amethyst'] ~= nil then
            warp(player, world_pos, 'amethyst:amethyst_ingot')
            return true
        end

        if fields['warp_'..i..'_ruby'] ~= nil then
            warp(player, world_pos, 'ruby:ruby')
            return true
        end

        if fields['warp_'..i..'_sapphire'] ~= nil then
            warp(player, world_pos, 'sapphire:sapphire')
            return true
        end

        if fields['warp_'..i..'_emerald'] ~= nil then
            warp(player, world_pos, 'emerald:emerald')
            return true
        end
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