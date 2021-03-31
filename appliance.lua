
appliances.appliance = {};
local appliance = appliances.appliance;

function appliance:new(def)
  def = def or {};
  for key, value in pairs(self) do
    if (type(value)~="function") and (def[key]==nil) then
      if (type(value)=="table") then
        def[key] = table.copy(value);
      else
        def[key] = value;
      end
    end
  end
  setmetatable(def, {__index = self});
  return def;
end

-- stacks
appliance.input_stack = "input";
appliance.input_stack_size = 1;
appliance.use_stack = "use_in";
appliance.use_stack_size = 1;
appliance.output_stack = "output";
appliance.output_stack_size = 4;

--
appliance.have_tubes = true;

-- is appliance connected to water?
local pipe_connections = {
  left = minetest.dir_to_facedir({x=0,y=0,z=-1}),
  right = minetest.dir_to_facedir({x=0,y=0,z=1}),
  top = nil,
  bottom = nil,
  front = minetest.dir_to_facedir({x=-1,y=0,z=0}),
  back = minetest.dir_to_facedir({x=1,y=0,z=0}),
}
appliance.need_water = false;
appliance.pipe_side = "top"; -- right, left, front, back, bottom
if appliances.have_pipeworks then
  local pipeworks_pipe_loaded = {
    ["pipeworks:pipe_1_loaded"] = true,
    ["pipeworks:pipe_2_loaded"] = true,
    ["pipeworks:pipe_3_loaded"] = true,
    ["pipeworks:pipe_4_loaded"] = true,
    ["pipeworks:pipe_5_loaded"] = true,
    ["pipeworks:pipe_6_loaded"] = true,
    ["pipeworks:pipe_7_loaded"] = true,
    ["pipeworks:pipe_8_loaded"] = true,
    ["pipeworks:pipe_9_loaded"] = true,
    ["pipeworks:pipe_10_loaded"] = true,
  };
  local pipeworks_pipe_with_facedir_loaded = {
    ["pipeworks:valve_on_loaded"] = true,
    ["pipeworks:entry_panel_loaded"] = true,
    ["pipeworks:flow_sensor_loaded"] = true,
    ["pipeworks:straight_pipe_loaded"] = true,
  };

  function appliance:have_water(pos)
    local node = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z});
    if node then
      if (pipeworks_pipe_loaded[node.name]) then
        return true;
      end
      if (pipeworks_pipe_with_facedir_loaded[node.name]) then
        if (minetest.facedir_to_dir(node.param2).y~=0) then
          return true;
        end
      end
    end
    return false;
  end
else
  function appliance:have_water(pos)
    if (minetest.find_node_near(pos, 1, "group:water", false)) then
      return true;
    else
      return false;
    end
  end
end

--[[
local power_data = {
  ["LV"] = {
      demand = 100,
      run_speed = 1,
      -- list of power_data to disable if this one is aviable
      -- used when power data is registered by function
      disable = {"mesecons","time"},
    },
  ["mesecons"] = {
      run_speed = 1,
      disable = {"LV","time"},
    },
  ["time"] = {
      run_speed = 1,
      disable = {"LV","mesecons"},
    },
}
--]]

appliance.power_data = nil; -- nil mean, power is not required
appliance.meta_infotext = "infotext";

local function disable_power_data(power_data, eu_data)
  if (eu_data~=nil) then
    if (eu_data.disable~=nil) then
      for _, key in pairs(eu_data.disable) do
        power_data[key] = nil;
      end
      eu_data.disable = nil;
    end
  end
  
end

function appliance:power_data_register(power_data)
  if appliances.have_technic then
    disable_power_data(power_data, power_data["LV"]);
    disable_power_data(power_data, power_data["MV"]);
    disable_power_data(power_data, power_data["HV"]);
  end
  if appliances.have_mesecons then
    disable_power_data(power_data, power_data["mesecons"]);
  end
  
  if true then
    disable_power_data(power_data, power_data["punch"]);
    disable_power_data(power_data, power_data["time"]);
  end
  self.power_data = power_data;
end

function appliance:is_powered(meta)
  if appliances.have_technic then
    -- check if node is powered LV
    local eu_data = self.power_data["LV"];
    if (eu_data~=nil) then
      local eu_demand = eu_data.demand;
      local eu_input = meta:get_int("LV_EU_input");
      if (eu_input>=eu_demand) then
        return eu_data.run_speed;
      end
    end
    -- check if node is powered MV
    local eu_data = self.power_data["MV"];
    if (eu_data~=nil) then
      local eu_demand = eu_data.demand;
      local eu_input = meta:get_int("MV_EU_input");
      if (eu_input>=eu_demand) then
        return eu_data.run_speed;
      end
    end
    -- check if node is powered HV
    local eu_data = self.power_data["HV"];
    if (eu_data~=nil) then
      local eu_demand = eu_data.demand;
      local eu_input = meta:get_int("HV_EU_input");
      if (eu_input>=eu_demand) then
        return eu_data.run_speed;
      end
    end
  end
  if appliances.have_mesecons then
    -- mesecon powered
    local eu_data = self.power_data["mesecons"];
    if (eu_data~=nil) then
      local is_powered = meta:get_int("is_powered");
      if (is_powered~=0) then
        return eu_data.run_speed;
      end
    end
  end
  if true then
    -- punch
    local eu_data = self.power_data["punch"];
    if (eu_data~=nil) then
      local is_punched = meta:get_int("is_punched");
      if (is_punched~=0) then
        return eu_data.run_speed;
      end
    end
    -- time only
    local eu_data = self.power_data["time"];
    if (eu_data~=nil) then
      return eu_data.run_speed;
    end
  end
  return 0;
end

function appliance:power_need(meta)
  local eu_data = self.power_data["LV"];
  if (eu_data~=nil) then
    meta:set_int("LV_EU_demand", eu_data.demand)
  end
  local eu_data = self.power_data["MV"];
  if (eu_data~=nil) then
    meta:set_int("MV_EU_demand", eu_data.demand)
  end
  local eu_data = self.power_data["HV"];
  if (eu_data~=nil) then
    meta:set_int("HV_EU_demand", eu_data.demand)
  end
end
function appliance:power_idle(meta)
  local eu_data = self.power_data["LV"];
  if (eu_data~=nil) then
    meta:set_int("LV_EU_demand", 0)
  end
  local eu_data = self.power_data["MV"];
  if (eu_data~=nil) then
    meta:set_int("MV_EU_demand", 0)
  end
  local eu_data = self.power_data["HV"];
  if (eu_data~=nil) then
    meta:set_int("HV_EU_demand", 0)
  end
end

-- recipe format
--[[
local recipes = {
  inputs = { -- record for every aviable input item
      ["input_item"] = {
          inputs = 1,
          outputs = {"output_item", {"multi_output1", "multi_output2"}}, -- list of one or more outputs, if more outputs, one record is selected
          require_usage = {["item"]=true}, -- nil, if every usage item can be used
          production_time = 160, -- time to product outputs
          consumption_step_size = 1, -- change usage consumption
        },
    },
  usages = {
      ["usage_item"] = {
          outputs = {"output_item", {"multi_output1", "multi_output2"}},
          consumption_time = 60, -- time to change usage item to outputs
          production_step_size = 1, -- speed of production output
        },
    }
}
--]] 
-- recipes automatizations
appliance.recipes = {
    inputs = {},
    usages = nil,
  }
appliance.have_input = true;
appliance.have_usage = true;
appliance.stoppable_production = true;
appliance.stoppable_consumption = true;

function appliance:recipe_register_input(input_name, input_def)
  if (self.input_stack_size <= 1) then
    self.recipes.inputs[input_name] = input_def;
  else
    local register = true;
    for index, value in pairs(input_def.inputs) do
      if ((index < 1) or ( index > self.input_stack_size)) then
        minetest.log("error", "Input definition is not compatible with size of input stack: "..dump(input_def));
        register = false;
        break;
      end
    end
    if register then
      table.insert(self.recipes.inputs, input_def);
    end
  end
end
function appliance:recipe_register_usage(usage_name, usage_def)
  if (not self.recipes.usages) then
    self.recipes.usages = {};
  end
  self.recipes.usages[usage_name] = usage_def;
end

function appliance:recipe_aviable_input(inventory)
  local input = nil;
  if (self.input_stack_size <= 1) then
    local input_stack = inventory:get_stack(self.input_stack, 1)
    local input_name = input_stack:get_name();
    input = self.recipes.inputs[input_name];
    if (input==nil) then
      return nil, nil
    end
    if (input_stack:get_count()<input.inputs) then
      return nil, nil
    end
  else
    for index, check in pairs(self.recipes.inputs) do
      local valid = true;
      for ch_i, ch_val in pairs(check.inputs) do
        local input_stack = inventory:get_stack(self.input_stack, ch_i);
        local check_stack = ItemStack(ch_val);
        if (input_stack:get_name()~=check_stack:get_name())  then
          valid = false;
          break;
        end
        if (input_stack:get_count() < check_stack:get_count()) then
          valid = false;
          break;
        end
      end
      if valid then
        input = check;
        break;
      end
    end
    
    if (input == nil) then
      return nil, nil
    end
  end
  
  local usage_name = nil;
  if (self.use_stack) then
    local usage_stack = inventory:get_stack(self.use_stack, 1)
    usage_name = usage_stack:get_name();
    
    if (input.require_usage~=nil) then
      if (not input.require_usage[usage_name]) then
        return nil, nil
      end
    end
  end
  
  local usage = nil;
  if self.recipes.usages then
    if (usage_name==nil) then
      return nil, nil
    end
    usage = self.recipes.usages[usage_name];
    if (usage==nil) then
      return nil, nil
    end
  end
  
  return input, usage
end

function appliance:recipe_select_output(outputs)
  local selection = {};
  if (#outputs>1) then
    selection = outputs[appliances.random:next(1, #outputs)];
  else
    selection = outputs[1];
  end
  
  if type(selection)=="table" then
    return selection;
  end
  
  return {selection};
end

function appliance:recipe_room_for_output(inventory, output)
  if #output>1 then
    local inv_list = table.copy(inventory:get_list(self.output_stack));
    for index = 1,#output do
      if (inventory:room_for_item(self.output_stack, output[index])~=true) then
        inventory:set_list(self.output_stack, inv_list);
        return false;
      end
      inventory:add_item(self.output_stack, output[index]);
    end
    inventory:set_list(self.output_stack, inv_list);
  else
    if (inventory:room_for_item(self.output_stack, output[1])~=true) then
      return false;
    end
  end
  
  return true;
end

function appliance:recipe_output_to_stack(inventory, output)
  for index = 1,#output do
    inventory:add_item(self.output_stack, output[index]);
  end
end

function appliance:recipe_output_to_stack_or_drop(pos, inventory, output)
  local drop_pos = nil;
  for index = 1,#output do
    local leftover = inventory:add_item(self.output_stack, output[index]);
    if (leftover:get_count()>0) then
      if (drop_pos==nil) then
        drop_pos = minetest.find_node_near(pos, 1, "air");
        if (drop_pos==nil) then
          drop_pos = pos;
        end
      end
      minetest.add_item(drop_pos, leftover);
    end
  end
end

function appliance:recipe_input_from_stack(inventory, input)
  if (self.input_stack_size <= 1) then
    local remove_stack = inventory:get_stack(self.input_stack, 1);
    remove_stack:set_count(input.inputs);
    inventory:remove_item(self.input_stack, remove_stack);
  else
    for rem_i, rem_val in pairs(input.inputs) do
      local remove_stack = inventory:get_stack(self.input_stack, rem_i);
      local item_stack = ItemStack(rem_val);
      if (item_stack:get_count()>0) then
        remove_stack:take_item(item_stack:get_count());
        inventory:set_stack(self.input_stack, rem_i, remove_stack);
      end
    end
  end
end

function appliance:recipe_usage_from_stack(inventory, usage)
  local remove_stack = inventory:get_stack(self.use_stack, 1);
  remove_stack:set_count(1);
  inventory:remove_item(self.use_stack, remove_stack);
end

function appliance:recipe_step_size(step_size)
  local int_step_size = math.floor(step_size);
  local rem_step_size = (step_size - int_step_size)*100;
  if (rem_step_size>=1) then
    if (rem_step_size<appliances.random:next(0,99)) then
      int_step_size = int_step_size + 1;
    end
  end
  return int_step_size;
end

function appliance:recipe_inventory_can_put(pos, listname, index, stack, player, recipes)
  if player then
    if minetest.is_protected(pos, player:get_player_name()) then
      return 0
    end
  end
  
  if listname == self.input_stack then
    if (self.input_stack_size <= 1) then
      return self.recipes.inputs[stack:get_name()] and
                  stack:get_count() or 0
    else
      local meta = minetest.get_meta(pos);
      local inventory = meta:get_inventory();
      
      for i, check in pairs(self.recipes.inputs) do
        local valid = true;
        for ch_i, ch_val in pairs(check.inputs) do
          local input_stack = inventory:get_stack(self.input_stack, ch_i);
          local input_name = input_stack:get_name();
          local check_stack = ItemStack(ch_val);
          if ((input_name~="") and (input_name~=check_stack:get_name())) then
            valid = false;
            break;
          end
        end
        if valid then
          local check_stack = check.inputs[index];
          if check_stack then
            check_stack = ItemStack(check_stack);
            if (stack:get_name()==check_stack:get_name()) then
              return stack:get_count();
            end
          end
        end
      end
      
      return 0;
    end
  end
  if listname == self.use_stack then
    return self.recipes.usages[stack:get_name()] and
                 stack:get_count() or 0
  end
  return 0
end

function appliance:recipe_inventory_can_take(pos, listname, index, stack, player)
  if player then
    if minetest.is_protected(pos, player:get_player_name()) then
      return 0
    end
  end
  local count = stack:get_count();
  local meta = minetest.get_meta(pos);
  if (listname==self.input_stack) then
    local production_time = meta:get_int("production_time") or 0
    if (production_time>0) then
      local input = self.recipes.inputs[stack:get_name()];
      if input then
        count = count-input.inputs;
        if (count<0) then count = 0; end
      else
        minetest.log("error", "Input item missing in recipes list.")
      end
    end
  elseif (listname==self.use_stack) then
    local consumption_time = meta:get_int("consumption_time") or 0
    if (consumption_time>0) then
      count = count - 1;
      if (count<0) then count = 0; end;
    end
  end
  
  return count;
end

-- tube can insert
function appliance:tube_can_insert (pos, node, stack, direction, owner)
  if self.recipes then
    local input = self.recipes.inputs[stack:get_name()];
    if input then
      return appliances.recipe_inventory_can_put(pos, self.input_stack, 1, stack, nil, recipes);
    end
    local usage = self.recipes.usages[stack:get_name()];
    if usage then
      return appliances.recipe_inventory_can_put(pos, self.use_stack, 1, stack, nil, recipes);
    end
  end
  return false;
end
function appliance:tube_insert (pos, node, stack, direction, owner)
  if self.recipes then
    local meta = minetest.get_meta(pos);
    local inv = meta:get_inventory();
    
    local input = self.recipes.inputs[stack:get_name()];
    if input then
      return inv:add_item(self.input_stack, stack);
    end
    local usages = self.recipes.usages[stack:get_name()];
    if usages then
      return inv:add_item(self.use_stack, stack);
    end
  end
  
  minetest.log("error", "Unexpected call of tube_insert function. Stack "..stack:to_string().." cannot be added to inventory.")
  
  return stack;
end

-- form spec

function appliance:get_formspec(meta, production_percent, consumption_percent)
  local progress = "";
  local input_list = "list[context;"..self.input_stack..";2,0.25;1,1;]";
  local use_list = "list[context;"..self.use_stack..";2,1.5;1,1;]";
  local use_listring = "listring[context;"..self.use_stack.."]" ..
                        "listring[current_player;main]";
  
  if self.have_usage then
    progress = "image[3.6,0.5;5.5,0.95;appliances_production_progress_bar.png^[transformR270]]";
    if production_percent then
      progress = "image[3.6,0.5;5.5,0.95;appliances_production_progress_bar.png^[lowpart:" ..
              (production_percent) ..
              ":appliances_production_progress_bar_full.png^[transformR270]]";
    end
    if consumption_percent then
      progress = progress.."image[3.6,1.35;5.5,0.95;appliances_consumption_progress_bar.png^[lowpart:" ..
              (consumption_percent) ..
              ":appliances_consumption_progress_bar_full.png^[transformR270]]";
    else
      progress = progress.."image[3.6,1.35;5.5,0.95;appliances_consumption_progress_bar.png^[transformR270]]";
    end
  else
    progress = "image[3.6,0.9;5.5,0.95;appliances_production_progress_bar.png^[transformR270]]";
    if production_percent then
      progress = "image[3.6,0.9;5.5,0.95;appliances_production_progress_bar.png^[lowpart:" ..
              (production_percent) ..
              ":appliances_production_progress_bar_full.png^[transformR270]]";
    end
    
    input_list = "list[context;"..self.input_stack..";2,0.8;1,1;]";
    use_list = "";
    use_listring = "";
  end
  
  
  local formspec =  "formspec_version[3]" .. "size[12.75,8.5]" ..
                    "background[-1.25,-1.25;15,10;appliances_appliance_formspec.png]" ..
                    progress..
                    "list[current_player;main;1.5,3;8,4;]" ..
                    input_list ..
                    use_list ..
                    "list[context;"..self.output_stack..";9.75,0.25;2,2;]" ..
                    "listring[current_player;main]" ..
                    "listring[context;"..self.input_stack.."]" ..
                    "listring[current_player;main]" ..
                    use_listring ..
                    "listring[context;"..self.output_stack.."]" ..
                    "listring[current_player;main]";
  return formspec;
end

function appliance:update_formspec(meta, production_time, production_goal, consumption_time, consumption_goal)
  local production_percent = 0;
  local consumption_percent = 0;
  if (production_time and production_goal) then
    production_percent = math.floor(production_time / production_goal * 100);
  end
  if (consumption_time and consumption_goal) then
    consumption_percent = math.floor(consumption_time / consumption_goal * 100);
  end
  meta:set_string("formspec", self:get_formspec(meta, production_percent, consumption_percent));
end

-- Inactive/Active 

function appliance:activate(pos, meta)
  local timer = minetest.get_node_timer(pos);
  if (not timer:is_started()) then
    timer:start(1)
    self:power_need(meta)
	  meta:set_string(self.meta_infotext, self.node_description.." - active")
  end
end

function appliance:deactivate(pos, meta)
  minetest.get_node_timer(pos):stop()
  self:update_formspec(meta, 0, 0, 0, 0)
  appliances.swap_node(pos, self.node_name_inactive);
  self:power_idle(meta)
	meta:set_string(self.meta_infotext, self.node_description.." - idle")
end
function appliance:running(pos, meta)
  appliances.swap_node(pos, self.node_name_active);
  self:power_need(meta)
	meta:set_string(self.meta_infotext, self.node_description.." - producting")
end
function appliance:waiting(pos, meta)
  appliances.swap_node(pos, self.node_name_inactive);
  self:power_idle(meta)
	meta:set_string(self.meta_infotext, self.node_description.." - waiting")
end
function appliance:no_power(pos, meta)
  appliances.swap_node(pos, self.node_name_inactive);
  self:power_need(meta)
  meta:set_string(self.meta_infotext, self.node_description.." - unpowered")
end

--
function appliance:need_wait(pos, meta, inv)
  -- have aviable production recipe?
  local use_input, use_usage = self:recipe_aviable_input(inv);
  if (use_input==nil) then
    return use_input, use_usage, true;
  end
  
  -- space for production outputs?
  if (#use_input.outputs==1) then
    local output = self:recipe_select_output(use_input.outputs);
    if (not self:recipe_room_for_output(inv, output)) then
      return use_input, use_usage, true;
    end
  end
  
  -- check for water pipe connection
  if (self.need_water) then
    if (self:have_water(pos)~=true) then
      return use_input, use_usage, true;
    end
  end
  
  return use_input, use_usage, false;
end
function appliance:have_power(pos, meta, inv)
  -- check if node is powered
  local speed = self:is_powered(meta)
  if (speed==0) then
    return speed, false;
  end
  return speed, true;
end

-- appliance node callbacks for mesecons
function appliance:cb_mesecons_effector_action_on(pos, node)
  minetest.get_meta(pos):set_int("is_powered", 1);
end
function appliance:cb_mesecons_effector_action_off(pos, node)
  minetest.get_meta(pos):set_int("is_powered", 0);
end

-- appliance node callbacks for pipeworks
function appliance:cb_tube_insert_object(pos, node, stack, direction, owner)
  local stack = appliance:tube_insert(pos, node, stack, direction, owner);
  
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory();
  local use_input, use_usage = appliance:recipe_aviable_input(inv)
  if use_input then
    self:activate(pos, meta);
  end
  
  return stack;
end
function appliance:cb_tube_can_insert(pos, node, stack, direction, owner)
  return appliance:tube_can_insert(pos, node, stack, direction, owner);
end

-- appliance node callbacks for technic
function appliance:cb_technic_run(pos, node)
  local meta = minetest.get_meta(pos);
  
  meta:set_string("infotext", meta:get_string("technic_info"));
end

-- appliance node callbacks
function appliance:cb_can_dig(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:is_empty(self.input_stack) and inv:is_empty(self.output_stack)
end

function appliance:cb_after_dig_node(pos, oldnode, oldmetadata, digger)
  if appliances.have_pipeworks then
    if self.need_water then
      pipeworks.scan_for_pipe_objects(pos);
    end
    if self.have_tubes then
      pipeworks.scan_for_tube_objects(pos);
    end
  end
  
  if self.have_usage then
    local stack = oldmetadata.inventory[self.use_stack][1];
    local consumption_time = tonumber(oldmetadata.fields["consumption_time"] or "0");
    if (consumption_time>0) then
      stack:take_item(1);
    end
    minetest.item_drop(stack, digger, pos)
  end
end
      
function appliance:cb_on_punch(pos, node, puncher, pointed_thing)
  local eu_data = self.power_data["punch"];
  if (eu_data~=nil) then
    local meta = minetest.get_meta(pos);
    meta:set_int("is_punched", 1);
  end
end

function appliance:cb_on_blast(pos)
  local drops = {}
  default.get_inventory_drops(pos, self.input_stack, drops)
  default.get_inventory_drops(pos, self.use_stack, drops)
  default.get_inventory_drops(pos, self.output_stack, drops)
  table.insert(drops, self.node_name_inactive)
  minetest.remove_node(pos)
  return drops
end

function appliance:interrupt_production(pos, meta, inv, use_input, use_usage, production_time, consumption_time)
  if (self.stoppable_production==false) then
    if (production_time>0) then
      if use_input.losts then
        local output = self:recipe_select_output(use_input.losts);
        self:recipe_output_to_stack_or_drop(pos, inv, output);
      end
      self:recipe_input_from_stack(inv, use_input);
      meta:set_int("production_time", 0);
      production_time = 0;
    end
  end
  
  if (self.stoppable_consumption==false) then
    if (consumption_time>0) then
      local output = self:recipe_select_output(use_usage.outputs); 
      if use_usage.losts then
        output = self:recipe_select_output(use_usage.losts);
      end
      self:recipe_output_to_stack_or_drop(pos, inv, output);
      self:recipe_usage_from_stack(inv, use_usage);
      meta:set_int("consumption_time", 0);
      consumption_time = 0;
    end
  end
      
  if use_usage then
    self:update_formspec(meta, production_time, use_input.production_time, consumption_time, use_usage.consumption_time)
  else
    self:update_formspec(meta, production_time, use_input.production_time, 0, 1)
  end
end

function appliance:after_timer_step(pos, meta, inv, production_time)
  local use_input, use_usage = self:recipe_aviable_input(inv)
  if use_input then
    self:running(pos, meta);
    return true
  else
    if (production_time) then
      self:waiting(pos, meta)
    else
      self:deactivate(pos, meta)
    end
    return false
  end
end

function appliance:cb_on_timer(pos, elapsed)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory();
  
  local production_time = meta:get_int("production_time") or 0;
  local consumption_time = meta:get_int("consumption_time") or 0;
  local sound_time = meta:get_int("sound_time") or 0;
  
  local use_input, use_usage, need_wait = self:need_wait(pos, meta, inv);
  if need_wait then
    if ((production_time>0) or (consumption_time>0)) then
      self:interrupt_production(pos, meta, inv, use_input, use_usage, production_time, consumption_time);
    end
    self:waiting(pos, meta);
    return true;
  end
  
  -- check if node is powered
  local speed, have_power = self:have_power(pos, meta, inv)
  if (not have_power) then
    self:interrupt_production(pos, meta, inv, use_input, use_usage, production_time, consumption_time);
    self:no_power(pos, meta);
    return true;
  end
  
  if (self.power_data["punch"]~=nil) then
    meta:set_int("is_punched", 0);
  end
  
  -- time update
  local production_step_size = 0;
  local consumption_step_size = 0;
  if self.recipes.usages then
    production_step_size = self:recipe_step_size(use_usage.production_step_size*speed);
    consumption_step_size = self:recipe_step_size(speed*use_input.consumption_step_size);
  else
    production_step_size = self:recipe_step_size(speed);
  end
  
  production_time = production_time + production_step_size;
  consumption_time = consumption_time + consumption_step_size;
  
  -- remove used item
  if use_usage then
    if (consumption_time>=use_usage.consumption_time) then
      local output = self:recipe_select_output(use_usage.outputs); 
      if (not self:recipe_room_for_output(inv, output)) then
        self:interrupt_production(pos, meta, inv, use_input, use_usage, production_time, consumption_time);
        self:waiting(pos, meta);
        return true;
      end
      self:recipe_output_to_stack(inv, output);
      self:recipe_usage_from_stack(inv, use_usage);
      consumption_time = 0;
      meta:set_int("consumption_time", 0);
    end
  end
  
  -- production done
  if (production_time>=use_input.production_time) then
    local output = self:recipe_select_output(use_input.outputs); 
    if (not self:recipe_room_for_output(inv, output)) then
      self:waiting(pos, meta);
      return true;
    end
    self:recipe_output_to_stack(inv, output);
    self:recipe_input_from_stack(inv, use_input);
    production_time = 0;
    meta:set_int("production_time", 0);
  end
  
  if use_usage then
    self:update_formspec(meta, production_time, use_input.production_time, consumption_time, use_usage.consumption_time)
    meta:set_int("production_time", production_time)
    meta:set_int("consumption_time", consumption_time)
  else
    self:update_formspec(meta, production_time, use_input.production_time, 0, 1)
    meta:set_int("production_time", production_time)
  end
  
  -- have aviable production recipe?
  local continue_timer = self:after_timer_step(pos, meta, inv, production_time);
  if (continue_timer==false) then
    self:interrupt_production(pos, meta, inv, use_input, use_usage, production_time, consumption_time);
  end
  return continue_timer;
end

function appliance:cb_allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
  return 0;
end

function appliance:cb_allow_metadata_inventory_put(pos, listname, index, stack, player)
  return self:recipe_inventory_can_put(pos, listname, index, stack, player);
end

function appliance:cb_allow_metadata_inventory_take(pos, listname, index, stack, player)
  return self:recipe_inventory_can_take(pos, listname, index, stack, player);
end

function appliance:cb_on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
  return;
end

function appliance:cb_on_metadata_inventory_put(pos, listname, index, stack, player)
  local meta = minetest.get_meta(pos)
  local timer = minetest.get_node_timer(pos)
  local inv = meta:get_inventory()
  
  -- have aviable production recipe?
  local use_input, use_usage = self:recipe_aviable_input(inv)
  if use_input then
    self:activate(pos, meta);
    return
  else
    self:deactivate(pos, meta)
  end
end

function appliance:cb_on_metadata_inventory_take(pos, listname, index, stack, player)
  local meta = minetest.get_meta(pos)
  local timer = minetest.get_node_timer(pos)
  local inv = meta:get_inventory()
  
  -- have aviable production recipe?
  local use_input, use_usage = self:recipe_aviable_input(inv)
  if use_input then
    self:activate(pos, meta);
    return
  else
    self:deactivate(pos, meta)
    return
  end
end

function appliance:cb_on_construct(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("formspec", self:get_formspec(meta, 0, 0))
  meta:set_string(self.meta_infotext, self.node_description)
  local inv = meta:get_inventory()
  
  if self.input_stack_size>0 then
    inv:set_size(self.input_stack, self.input_stack_size)
  end
  if self.use_stack_size>0 then
    if inv:get_size(self.use_stack)==0 then
      inv:set_size(self.use_stack, self.use_stack_size)
    end
  end
  if self.output_stack_size>0 then
    if inv:get_size(self.output_stack)==0 then
      inv:set_size(self.output_stack, self.output_stack_size)
    end
  end
end
    
function appliance:cb_after_place_node(pos, placer, itemstack, pointed_thing)
  if appliance.have_pipeworks then
    pipeworks.scan_for_pipe_objects(pos);
    pipeworks.scan_for_tube_objects(pos);
  end
  if (not appliance.have_mesecon) then
    minetest.get_meta(pos):set_int("is_powered", 1);
  end
end

-- register appliance
function appliance:register_nodes(shared_def, inactive_def, active_def)
  -- default connection of pipe on top
  -- default connection of tubes from sides
  -- default connection of power from back
  -- may be, late, this will be configurable
  
  local node_def_inactive = table.copy(shared_def);
  
  node_def_inactive.description = self.node_description;
  if (self.node_help) then
    node_def_inactive.description = self.node_description.."\n"..self.node_help;
  end
  node_def_inactive.short_description = self.node_description;
  
  local need_power = false;
  local technic_power = false;
  local mesecons_power = false;
  if self.power_data then
    need_power = true;
  end
  if appliances.have_technic then
    if self.power_data then
      if self.power_data["LV"] then
        node_def_inactive.groups.technic_machine = 1;
        node_def_inactive.groups.technic_lv = 1;
        technic_power = true;
      end
      if self.power_data["MV"] then
        node_def_inactive.groups.technic_machine = 1;
        node_def_inactive.groups.technic_mv = 1;
        technic_power = true;
      end
      if self.power_data["HV"] then
        node_def_inactive.groups.technic_machine = 1;
        node_def_inactive.groups.technic_hv = 1;
        technic_power = true;
      end
    end
  end
  if appliances.have_mesecons then
    if self.power_data then
      if self.power_data["no_technic"] then
        if (not appliances.have_technic) then
          mesecons_power = true;
        end
      end
      if self.power_data["mesecons"] then
        mesecons_power = true;
      end
    end
  end
  if technic_power then
    -- power connect (technic)
    node_def_inactive.connect_sides = {"back"};
    
    node_def_inactive.technic_run = function (pos, node)
        self:cb_technic_run(pos, node);
      end
    
    self.meta_infotext = "technic_info";
  end
  if mesecons_power then
    -- mesecon action
    node_def_inactive.mesecons =
      {
        effector = {
          action_on = function (pos, node)
            self:cb_mesecons_effector_action_off(pos, node);
          end,
          action_off = function (pos, node)
            self:cb_mesecons_effector_action_off(pos, node);
          end,
        }
      };
  end
  if self.need_water then
    -- pipe connect
    
    node_def_inactive.pipe_connections = {}; 
    node_def_inactive.pipe_connections[self.pipe_side] = true;
    node_def_inactive.pipe_connections[self.pipe_side.."_param2"] = pipe_connections[self.pipe_side];
  end
  if appliances.have_pipeworks then
    if self.have_tubes then
      node_def_inactive.groups.tubedevice = 1;
      node_def_inactive.groups.tubedevice_receiver = 1;
      node_def_inactive.tube =
        {
          insert_object = function(pos, node, stack, direction, owner)
            return self:cb_tube_insert_object(pos, node, stack, direction, owner);
            end,
          can_insert = function(pos, node, stack, direction, owner)
              return self:cb_tube_can_insert(pos, node, stack, direction, owner);
            end,
          connect_sides = {left = 1, right = 1}, 
          input_inventory = self.output_stack,
        };
    end
  end
  node_def_inactive.can_dig = function (pos, player)
      return self:cb_can_dig(pos, player);
    end
  node_def_inactive.after_dig_node = function (pos, oldnode, oldmetadata, digger)
      return self:cb_after_dig_node(pos, oldnode, oldmetadata, digger)
    end
  node_def_inactive.on_punch = function (pos, node, puncher, pointed_thing)
      return self:cb_on_punch(pos, node, puncher, pointed_thing);
    end
  node_def_inactive.on_blast = function (pos, intensity)
      return self:cb_on_blast(pos, intensity);
    end
  node_def_inactive.on_timer = function (pos, elapsed)
      return self:cb_on_timer(pos, elapsed);
    end
  node_def_inactive.allow_metadata_inventory_move = function (pos, from_list, from_index, to_list, to_index, count, player)
      return self.cb_allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player);
    end
  node_def_inactive.allow_metadata_inventory_put = function (pos, listname, index, stack, player)
      return self:cb_allow_metadata_inventory_put(pos, listname, index, stack, player);
    end
  node_def_inactive.allow_metadata_inventory_take = function (pos, listname, index, stack, player)
      return self:cb_allow_metadata_inventory_take(pos, listname, index, stack, player);
    end
  node_def_inactive.on_metadata_inventory_move = function (pos, from_list, from_index, to_list, to_index, count, player)
      return self.cb_on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player);
    end
  node_def_inactive.on_metadata_inventory_put = function (pos, listname, index, stack, player)
      return self:cb_on_metadata_inventory_put(pos, listname, index, stack, player);
    end
  node_def_inactive.on_metadata_inventory_take = function (pos, listname, index, stack, player)
      return self:cb_on_metadata_inventory_put(pos, listname, index, stack, player);
    end
  
  local node_def_active = table.copy(node_def_inactive);
  
  node_def_inactive.on_construct = function (pos)
      return self:cb_on_construct(pos);
    end
  node_def_inactive.after_place_node = function (pos, placer, itemstack, pointed_thing)
      return self:cb_after_place_node(pos, placer, itemstack, pointed_thing);
    end
  
  node_def_active.groups.not_in_creative_inventory = 1;
  
  if inactive_def then
    for key, value in pairs(inactive_def) do
      node_def_inactive[key] = value;
    end
  end
  if active_def then
    for key, value in pairs(active_def) do
      node_def_active[key] = value;
    end
  end
  
  minetest.register_node(self.node_name_inactive, node_def_inactive);
  minetest.register_node(self.node_name_active, node_def_active);
  
  if appliances.have_technic then
    if node_def_inactive.groups.technic_lv then
      technic.register_machine("LV", self.node_name_inactive, technic.receiver)
      technic.register_machine("LV", self.node_name_active, technic.receiver)
    end
    if node_def_inactive.groups.technic_mv then
      technic.register_machine("MV", self.node_name_inactive, technic.receiver)
      technic.register_machine("MV", self.node_name_active, technic.receiver)
    end
    if node_def_inactive.groups.technic_hv then
      technic.register_machine("HV", self.node_name_inactive, technic.receiver)
      technic.register_machine("HV", self.node_name_active, technic.receiver)
    end
  end
  
end

-- register recipes to unified_inventory
function appliance:register_recipes(inout_type, usage_type)
  if (self.input_stack_size<=1) then
    for input, recipe in pairs(self.recipes.inputs) do
      for _, outputs in pairs(recipe.outputs) do
        if (type(outputs)=="table") then
          outputs = outputs[1];
        end
        local item = ItemStack(input);
        item:set_count(recipe.inputs);
        appliances.register_craft({
            type = inout_type,
            output = ItemStack(outputs):to_string(),
            items = {item:to_string()},
          })
      end
    end
  else
    for input, recipe in pairs(self.recipes.inputs) do
      for _, outputs in pairs(recipe.outputs) do
        if (type(outputs)=="table") then
          outputs = outputs[1];
        end
        local items = {};
        for _, item in pairs(recipe.inputs) do
          table.insert(items, ItemStack(item):to_string());
        end
        appliances.register_craft({
            type = inout_type,
            output = ItemStack(outputs):to_string(),
            items = items,
            width = self.input_stack_width,
          })
      end
    end
  end
  
  if (self.have_usage) then
    for input, usage in pairs(self.recipes.usages) do
      for _, outputs in pairs(usage.outputs) do
        if (type(outputs)=="table") then
          outputs = outputs[1];
        end
        local item = ItemStack(input):to_string();
        appliances.register_craft({
            type = usage_type,
            output = self.node_name_inactive,
            items = {item},
          })
      end
    end
  end
end


