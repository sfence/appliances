
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

appliance.items_connect_sides = {"right", "left"}; -- right, left, front, back, top, bottom

appliance.liquid_connect_sides = {"top"}; -- right, left, front, back, top, bottom
function appliance:have_liquid(pos, meta)
  for supply_name, supply_data in pairs(self.liquid_data) do
    local supply = appliances.liquid_supplies[supply_name]
    if supply and supply.have_liquid then
      if (supply.have_liquid(self, supply_data, pos, meta)) then
        return true;
      end
    end
  end
  return false;
end

appliance.power_connect_sides = {"back"}; -- right, left, front, back, top, bottom

appliance.power_data = {};
appliance.liquid_data = {};
appliance.item_data = {};
appliance.control_data = {};

appliance.meta_infotext = "infotext";

local function disable_supply_data(supplies_data, supply_data)
  if (supply_data~=nil) then
    if (supply_data.disable~=nil) then
      for _,key in pairs(supply_data.disable) do
        supplies_data[key] = nil;
      end
      supply_data.disable = nil;
    end
  end
end
local function disable_supplies_data(supplies_data)
  for _,supply_data in pairs(supplies_data) do
    disable_supply_data(supplies_data, supply_data);
  end
  return supplies_data;
end

function appliance:power_data_register(power_data)
  self.power_data = disable_supplies_data(power_data);
end
function appliance:liquid_data_register(liquid_data)
  self.liquid_data = disable_supplies_data(liquid_data);
end
function appliance:item_data_register(item_data)
  self.item_data = disable_supplies_data(item_data);
end
function appliance:control_data_register(control_data)
  self.control_data = disable_supplies_data(control_data);
end

function appliance:is_powered(pos, meta)
  for supply_name, supply_data in pairs(self.power_data) do
    local supply = appliances.power_supplies[supply_name]
    if supply and supply.is_powered then
      local speed = supply.is_powered(self, supply_data, pos, meta)
      if (speed~=0) then
        return speed;
      end
    end
  end
  return 0;
end

function appliance:power_need(pos, meta)
  for supply_name, supply_data in pairs(self.power_data) do
    local supply = appliances.power_supplies[supply_name]
    if supply and supply.power_need then
      supply.power_need(self, supply_data, pos, meta)
    end
  end
end
function appliance:power_idle(pos, meta)
  for supply_name, supply_data in pairs(self.power_data) do
    local supply = appliances.power_supplies[supply_name]
    if supply and supply.power_idle then
      supply.power_idle(self, supply_data, pos, meta)
    end
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

appliance.have_control = false;

function appliance:recipe_register_input(input_name, input_def)
  if (not self.have_input) then
    minetest.log("error", "Input is disabled. Registration of input recipe cannot be finished.");
    return;
  end
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
  if (not self.have_usage) then
    minetest.log("error", "Usage is disabled. Registration of usage recipe cannot be finished.");
    return;
  end
  if (not self.recipes.usages) then
    self.recipes.usages = {};
  end
  self.recipes.usages[usage_name] = usage_def;
end

function appliance:recipe_aviable_input(inventory)
  local input = nil;
  if (self.have_input) then
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
  end
  
  local usage_name = nil;
  if (self.have_usage) then
    local usage_stack = inventory:get_stack(self.use_stack, 1)
    usage_name = usage_stack:get_name();
    
    if (input~=nil) and (input.require_usage~=nil) then
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

function appliance:recipe_inventory_can_put(pos, listname, index, stack, player)
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

function appliance:cb_activate(pos, meta)
end
function appliance:activate(pos, meta)
  local timer = minetest.get_node_timer(pos);
  if (not timer:is_started()) then
    timer:start(1)
    self:power_need(pos, meta)
	  meta:set_string(self.meta_infotext, self.node_description.." - active")
  end
  self:call_activate(pos, meta)
  self:cb_activate(pos, meta)
end
function appliance:cb_deactivate(pos, meta)
end
function appliance:deactivate(pos, meta)
  minetest.get_node_timer(pos):stop()
  self:update_formspec(meta, 0, 0, 0, 0)
  appliances.swap_node(pos, self.node_name_inactive);
  self:power_idle(pos, meta)
	meta:set_string(self.meta_infotext, self.node_description.." - idle")
  self:call_deactivate(pos, meta)
  self:cb_deactivate(pos, meta)
end
function appliance:cb_running(pos, meta)
end
function appliance:running(pos, meta)
  appliances.swap_node(pos, self.node_name_active);
  self:power_need(pos, meta)
	meta:set_string(self.meta_infotext, self.node_description.." - producting")
  self:call_running(pos, meta)
  self:cb_running(pos, meta)
end
function appliance:cb_waiting(pos, meta)
end
function appliance:waiting(pos, meta)
  appliances.swap_node(pos, self.node_name_inactive);
  self:power_idle(pos, meta)
	meta:set_string(self.meta_infotext, self.node_description.." - waiting")
  self:call_waiting(pos, meta)
  self:cb_waiting(pos, meta)
end
function appliance:cb_no_power(pos, meta)
end
function appliance:no_power(pos, meta)
  appliances.swap_node(pos, self.node_name_inactive);
  self:power_need(pos, meta)
  meta:set_string(self.meta_infotext, self.node_description.." - unpowered")
  self:call_no_power(pos, meta)
  self:cb_no_power(pos, meta)
end

--
function appliance:control_wait(pos, meta)
  for control_name, control_data in pairs(self.control_data) do
    local control = appliances.controls[control_name]
    if control and control.control_wait then
      if (control.control_wait(self, control_data, pos, meta)) then
        return true;
      end
    end
  end
  return false;
end
--
function appliance:need_wait(pos, meta, inv)
  -- use_input, use_usage, need_wait
  -- have aviable production recipe?
  local use_input, use_usage = self:recipe_aviable_input(inv);
  if ((use_input==nil) and self.have_input) or (use_usage==nil) and self.have_usage then
    return use_input, use_usage, true;
  end
  
  -- space for production outputs?
  if (use_input) and (#use_input.outputs==1) then
    local output = self:recipe_select_output(use_input.outputs);
    if (not self:recipe_room_for_output(inv, output)) then
      return use_input, use_usage, true;
    end
  end
  
  -- check for liquid connection
  if (self.need_liquid) then
    if (self:have_liquid(pos, meta)~=true) then
      return use_input, use_usage, true;
    end
  end
  
  -- check for control
  if (self.have_control) then
    return use_input, use_usage, self:control_wait(pos, meta);
  end
  
  return use_input, use_usage, false;
end
function appliance:have_power(pos, meta, inv)
  -- check if node is powered
  local speed = self:is_powered(pos, meta)
  if (speed==0) then
    return speed, false;
  end
  return speed, true;
end

-- appliance node callbacks
function appliance:cb_can_dig(pos)
  local meta = minetest.get_meta(pos)
  if (not self:call_can_dig(pos, meta)) then
    return false;
  end
  local inv = meta:get_inventory()
  return inv:is_empty(self.input_stack) and inv:is_empty(self.output_stack)
end

function appliance:cb_after_dig_node(pos, oldnode, oldmetadata, digger)
  self:call_after_dig_node(pos, oldnode, oldmetadata, digger)
  
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
  self:call_on_punch(pos, node, puncher, pointed_thing)
end

function appliance:cb_on_blast(pos, intensity)
  local drops = {}
  default.get_inventory_drops(pos, self.input_stack, drops)
  default.get_inventory_drops(pos, self.use_stack, drops)
  default.get_inventory_drops(pos, self.output_stack, drops)
  table.insert(drops, self.node_name_inactive)
  minetest.remove_node(pos)
  self:call_on_blast(pos, intensity)
  return drops
end

function appliance:interrupt_production(pos, meta, inv, use_input, use_usage, production_time, consumption_time)
  if (self.stoppable_production==false) then
    if (production_time>0) then
      if use_input then
        if use_input.losts then
          local output = self:recipe_select_output(use_input.losts);
          self:recipe_output_to_stack_or_drop(pos, inv, output);
        end
        self:recipe_input_from_stack(inv, use_input);
      end
      meta:set_int("production_time", 0);
      production_time = 0;
    end
  end
  
  if (self.stoppable_consumption==false) then
    if (consumption_time>0) then
      if use_usage then
        local output = self:recipe_select_output(use_usage.outputs); 
        if use_usage.losts then
          output = self:recipe_select_output(use_usage.losts);
        end
        self:recipe_output_to_stack_or_drop(pos, inv, output);
        self:recipe_usage_from_stack(inv, use_usage);
      end
      meta:set_int("consumption_time", 0);
      consumption_time = 0;
    end
  end
  
  local target_production_time = 1;
  local target_consumption_time = 1;
  if use_input then
    target_production_time = use_input.production_time;
  else
    production_time = 0;
  end
  if use_usage then
    target_consumption_time = use_usage.consumption_time;
  else
    consumption_time = 0;
  end
  
  self:update_formspec(meta, production_time, target_production_time, consumption_time, target_consumption_time);
end

function appliance:after_timer_step(pos, meta, inv, production_time)
  local use_input, use_usage = self:recipe_aviable_input(inv)
  if ((use_input~=nil) or (not self.have_input)) or ((use_usage~=nil) or (not self.have_usage)) then
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

function appliance:cb_on_production(pos, meta, use_input, use_usage)
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
    if ((use_input==nil) and self.have_input) or (use_usage==nil) and self.have_usage then
      self:deactivate(pos, meta);
      return false;
    else
      self:waiting(pos, meta);
    end
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
  if use_input and use_usage then
    production_step_size = self:recipe_step_size(use_usage.production_step_size*speed);
    consumption_step_size = self:recipe_step_size(speed*use_input.consumption_step_size);
  elseif use_input then
    production_step_size = self:recipe_step_size(speed);
  elseif use_usage then
    consumption_step_size = self:recipe_step_size(speed);
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
  if (use_input) then
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
  end
  
  if use_usage then
    if (use_input) then
      self:update_formspec(meta, production_time, use_input.production_time, consumption_time, use_usage.consumption_time)
      meta:set_int("production_time", production_time)
    else
      self:update_formspec(meta, 0, 3, consumption_time, use_usage.consumption_time)
    end
    meta:set_int("consumption_time", consumption_time)
  elseif (use_input) then
    self:update_formspec(meta, production_time, use_input.production_time, 0, 1)
    meta:set_int("production_time", production_time)
  end
  
  -- cb_on_production callback
  self:cb_on_production(pos, meta, use_input, use_usage);
  
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
  if ((use_input~=nil) or (not self.have_input)) or ((use_usage~=nil) or (not self.have_usage)) then
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
  self:call_on_construct(pos, meta)
end
    
function appliance:cb_after_place_node(pos, placer, itemstack, pointed_thing)
  self:call_after_place_node(pos, placer, itemstack, pointed_thing)
end

-- register appliance
function appliance:register_nodes(shared_def, inactive_def, active_def)
  -- default connection of pipe on top
  -- default connection of tubes from sides
  -- default connection of power from back
  -- may be, late, this will be configurable
  
  local node_def_inactive = table.copy(shared_def);
  
  -- fix data (supplies, controls)
  self.extensions_data = {}
  for power_name,power_data in pairs(self.power_data) do
    self.extensions_data[power_name] = power_data;
  end
  for liquid_name,liquid_data in pairs(self.liquid_data) do
    self.extensions_data[liquid_name] = liquid_data;
  end
  for item_name,item_data in pairs(self.item_data) do
    self.extensions_data[item_name] = item_data;
  end
  for control_name,control_data in pairs(self.control_data) do
    self.extensions_data[control_name] = control_data;
  end
  
  -- use .."" to prevent string object share
  node_def_inactive.description = self.node_description.."";
  if (self.node_help) then
    node_def_inactive.description = self.node_description.."\n"..self.node_help;
  end
  node_def_inactive.short_description = self.node_description.."";
  
  self:call_update_node_def(node_def_inactive)
  self:cb_after_update_node_def(node_def_inactive)
  
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
  
  self:call_update_node_inactive_def(node_def_inactive);
  self:cb_after_update_node_inactive_def(node_def_inactive)
  self:call_update_node_active_def(node_def_active);
  self:cb_after_update_node_active_def(node_def_inactive)
  
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
  
  self:call_after_register_node()
end

-- register recipes to unified_inventory/craftguide/i3
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

-- extensions callbacks
function appliance:call_activate(pos, meta)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.activate then
      extension.activate(self, extension_data, pos, meta)
    end
  end
end
function appliance:call_deactivate(pos, meta)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.deactivate then
      extension.deactivate(self, extension_data, pos, meta)
    end
  end
end
function appliance:call_running(pos, meta)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.running then
      extension.running(self, extension_data, pos, meta)
    end
  end
end
function appliance:call_waiting(pos, meta)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.waiting then
      extension.waiting(self, extension_data, pos, meta)
    end
  end
end
function appliance:call_no_power(pos, meta)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.no_power then
      extension.no_power(self, extension_data, pos, meta)
    end
  end
end

function appliance:call_update_node_def(node_def)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.update_node_def then
      extension.update_node_def(self, extension_data, node_def)
    end
  end
end
function appliance:cb_after_update_node_def(node_def)
end

function appliance:call_update_node_inactive_def(node_def)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.update_node_inactive_def then
      extension.update_node_inactive_def(self, extension_data, node_def)
    end
  end
end
function appliance:cb_after_update_node_inactive_def(node_def)
end

function appliance:call_update_node_active_def(node_def)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.update_node_active_def then
      extension.update_node_active_def(self, extension_data, node_def)
    end
  end
end
function appliance:cb_after_update_node_active_def(node_def)
end

function appliance:call_after_register_node()
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.after_register_node then
      extension.after_register_node(self, extension_data)
    end
  end
end

function appliance:call_on_construct(pos, meta)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.on_construct then
      extension.on_construct(self, extension_data, pos, meta)
    end
  end
end

function appliance:call_on_destruct(pos, meta)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.on_destruct then
      extension.on_destruct(self, extension_data, pos, meta)
    end
  end
end

function appliance:call_after_destruct(pos, oldnode)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.after_destruct then
      extension.after_destruct(self, extension_data, pos, oldnode)
    end
  end
end

function appliance:call_after_place_node(pos, placer, itemstack, pointed_thing)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.after_place_node then
      extension.after_place_node(self, extension_data, pos, placer, itemstack, pointed_thing)
    end
  end
end

function appliance:call_after_dig_node(pos, oldnode, oldmetadata, digger)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.after_dig_node then
      extension.after_dig_node(self, extension_data, pos, oldnode, oldmetadata, digger)
    end
  end
end

function appliance:call_can_dig(pos, player)
  local can_dig = true;
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.can_dig then
      if (not extension.can_dig(self, extension_data, pos, player)) then
        can_dig = false;
      end
    end
  end
  return can_dig;
end

function appliance:call_on_punch(pos, node, puncher, pointed_thing)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.on_punch then
      extension.on_punch(self, extension_data, pos, node, puncher, pointed_thing)
    end
  end
end

function appliance:call_on_blast(pos, intensity)
  for extension_name, extension_data in pairs(self.extensions_data) do
    local extension = appliances.all_extensions[extension_name]
    if extension and extension.on_blast then
      extension.on_blast(self, extension_data, pos, intensity)
    end
  end
end

