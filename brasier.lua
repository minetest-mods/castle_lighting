if not minetest.get_modpath("fire") then return end

-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local brasier_nodebox = {
	type = "fixed",
	fixed = {
		{-0.25, 0, -0.25, 0.25, 0.125, 0.25}, -- base
		{-0.375, 0.125, -0.375, 0.375, 0.25, 0.375}, -- mid
		{-0.5, 0.25, -0.5, 0.5, 0.375, 0.5}, -- plat
		{-0.5, 0.375, 0.375, 0.5, 0.5, 0.5}, -- edge
		{-0.5, 0.375, -0.5, 0.5, 0.5, -0.375}, -- edge
		{0.375, 0.375, -0.375, 0.5, 0.5, 0.375}, -- edge
		{-0.5, 0.375, -0.375, -0.375, 0.5, 0.375}, -- edge
		{0.25, -0.5, -0.375, 0.375, 0.125, -0.25}, -- leg
		{-0.375, -0.5, 0.25, -0.25, 0.125, 0.375}, -- leg
		{0.25, -0.5, 0.25, 0.375, 0.125, 0.375}, -- leg
		{-0.375, -0.5, -0.375, -0.25, 0.125, -0.25}, -- leg
		{-0.125, -0.0625, -0.125, 0.125, 0, 0.125}, -- bottom_knob
	}
}

local brasier_burn = function(pos)
	local inv = minetest.get_inventory({type="node", pos=pos})
	local item = inv:get_stack("fuel", 1)
	local fuel_burned = minetest.get_craft_result({method="fuel", width=1, items={item:peek_item(1)}}).time
	local pos_above = {x=pos.x, y=pos.y+1, z=pos.z}
	local node_above = minetest.get_node(pos_above)
	if fuel_burned > 0 then
		item:set_count(item:get_count() - 1)
		inv:set_stack("fuel", 1, item)
		
		local timer = minetest.get_node_timer(pos)
		timer:start(fuel_burned * 60) -- one minute of flame per second of burn time, for balance.
		minetest.debug("burned a thing", item:get_name())
		
		if node_above.name == "air" then
			minetest.set_node(pos_above, {name = "fire:permanent_flame"})
		end
	else
		if node_above.name == "fire:permanent_flame" then
			minetest.set_node(pos_above, {name = "air"})
		end
	end
end

minetest.register_node("castle_lighting:brasier_floor", {
	description = S("Brasier"),
	tiles = {
		"castle_steel.png^(castle_coal_bed.png^[mask:castle_brasier_bed_mask.png)",
		"castle_steel.png",
		"castle_steel.png",
		"castle_steel.png",
		"castle_steel.png",
		"castle_steel.png",
		},
	drawtype = "nodebox",
	groups = {cracky=2},
	paramtype = "light",
	node_box = brasier_nodebox,
	selection_box ={
		type = "fixed",
		fixed = {
			{-0.375, -0.5, -0.375, 0.375, 0.25, 0.375}, -- mid
			{-0.5, 0.25, -0.5, 0.5, 0.5, 0.5}, -- plat
		}
	},
	
	on_construct = function(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		inv:set_size("fuel", 1)
		
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", 
			"size[8,5.3]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..
			"list[current_name;fuel;3.5,0;1,1;]" ..
			"list[current_player;main;0,1.15;8,1;]" ..
			"list[current_player;main;0,2.38;8,3;8]" ..
			"listring[current_name;main]" ..
			"listring[current_player;main]" ..
			default.get_hotbar_bg(0,1.15)
		)
	end,
	
	on_destruct = function(pos, oldnode)
		local pos_above = {x=pos.x, y=pos.y+1, z=pos.z}
		local node_above = minetest.get_node(pos_above)
		if node_above.name == "fire:permanent_flame" then
			minetest.set_node(pos_above, {name = "air"})
		end
	end,
	
	can_dig = function(pos, player)
		local inv = minetest.get_meta(pos):get_inventory()
		return inv:is_empty("fuel")
	end,
	
	-- Only allow fuel items to be placed in fuel
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "fuel" then
			if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
				return stack:get_count()
			else
				return 0
			end
		end
		return 0
	end,
	
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		brasier_burn(pos)
	end,
	
	on_timer = function(pos, elapsed)
		brasier_burn(pos)
	end,
})


minetest.register_craft({
	output = "castle_lighting:brasier_floor",
	recipe = {
		{"default:steel_ingot", "default:torch", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})