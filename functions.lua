
-- help function for swap appliance node
-- typicaly between active and inactive appliance
function appliances.swap_node(pos, name)
  local node = minetest.get_node(pos);
  if (node.name == name) then 
    return
  end
  node.name = name;
  minetest.swap_node(pos, node);
end

appliances.random = PcgRandom(os.time());

--
-- {
--   description = "", -- description text
--   icon = "", -- path to icon file, can be nil
--   width = 1, -- width of recipe (unified only)
--   height = 1, -- height of recipe (unified only)
--   dynamic_display_size = nil, -- unified callback only
-- }
--
function appliances.register_craft_type(type_name, type_def)
  if appliances.have_unified then
    unified_inventory.register_craft_type(type_name, {
        description = type_def.description,
        icon = type_def.icon,
        width = type_def.width,
        height = type_def.height,
        dynamic_display_size = type_def.dynamic_display_size,
      })
  end
  if appliances.have_craftguide then
    craftguide.register_craft_type(type_name, {
        description = type_def.description,
        icon = type_def.icon,
      })
  end
  if appliances.have_i3 then
    minetest.register_on_mods_loaded(function()
        i3.register_craft_type(type_name, {
            description = type_def.description,
            icon = type_def.icon,
          })
      end)
  end
end

--
-- {
--   type = "", -- type name
--   output = "", -- item string
--   items = {""}, -- input items
-- }
--
function appliances.register_craft(craft_def)
  if appliances.have_unified then
    unified_inventory.register_craft({
        type = craft_def.type,
        output = craft_def.output,
        items = craft_def.items,
      })
  end
  if appliances.have_craftguide or appliances.have_i3 then
    local items = craft_def.items;
    if craft_def.width then
      items = {};
      local line = "";
      for index, item in pairs(craft_def.items) do
        if (line~="") then
          line = line..",";
        end
        line = line..item;
        if ((index%craft_def.width)==0) then
          table.insert(items, line);
          line = "";
        end
      end
      if (line~="") then
        table.insert(items, line);
      end
    end
    
    if appliances.have_craftguide then
      craftguide.register_craft({
          type = craft_def.type,
          result = craft_def.output,
          items = items,
        })
    end
    if appliances.have_i3 then
      minetest.register_on_mods_loaded(function()
          i3.register_craft({
              type = craft_def.type,
              result = craft_def.output,
              items = items,
            })
        end)
    end
  end
end
  
