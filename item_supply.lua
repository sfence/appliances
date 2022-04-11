

appliances.item_supplies = {}

function appliances.add_item_supply(supply_name, item_supply)
  if appliances.all_extensions[supply_name] then
    minetest.log("error", "Another appliances mod extension with name \""..supply_name.."\" is already registered.")
    return ;
  end
  appliances.item_supplies[supply_name] = item_supply;
  appliances.all_extensions[supply_name] = item_supply;
end

-- pipeworks
if appliances.have_pipeworks then
  -- tube can insert
  local appliance = appliances.appliance
  function appliance:tube_can_insert (pos, node, stack, direction, owner)
    if minetest.is_protected(pos, owner or "") then
      return false
    end
    if self.recipes then
      if self.have_input then
        if (self.input_stack_size <= 1) then
          local can_insert = self:recipe_inventory_can_put(pos, self.input_stack, 1, stack, owner);
          if (can_insert~=0) then
            return can_insert;
          end
        else
          for index = 1,self.input_stack_size do
            local can_insert = self:recipe_inventory_can_put(pos, self.input_stack, index, stack, owner);
            if (can_insert~=0) then
              return can_insert;
            end
          end
        end
      end
      if self.have_usage then
        return self:recipe_inventory_can_put(pos, self.use_stack, 1, stack, owner);
      end
    end
    return false;
  end
  function appliance:tube_insert (pos, node, stack, direction, owner)
    if minetest.is_protected(pos, owner or "") then
      return stack
    end
    if self.recipes then
      local meta = minetest.get_meta(pos);
      local inv = meta:get_inventory();
      
      if self.have_input then
        if (self.input_stack_size <= 1) then
          local can_insert = self:recipe_inventory_can_put(pos, self.input_stack, 1, stack, owner);
          if can_insert~=0 then
            return inv:add_item(self.input_stack, stack);
          end
        else
          for index = 1,self.input_stack_size do
            local can_insert = self:recipe_inventory_can_put(pos, self.input_stack, index, stack, owner);
            if (can_insert~=0) then
              local input_stack = inv:get_stack(self.input_stack,index);
              local remind = input_stack:add_item(stack);
              inv:set_stack(self.input_stack,index, input_stack);
              return remind;
            end
          end
        end
      end
      if self.have_usage then
        return inv:add_item(self.use_stack, stack);
      end
    end
    
    minetest.log("error", "Unexpected call of tube_insert function. Stack "..stack:to_string().." cannot be added to inventory.")
    
    return stack;
  end
  -- appliance node callbacks for pipeworks
  function appliance:cb_tube_insert_object(pos, node, stack, direction, owner)
    local stack = self:tube_insert(pos, node, stack, direction, owner);
    
    local meta = minetest.get_meta(pos);
    local inv = meta:get_inventory();
    local use_input, use_usage = self:recipe_aviable_input(inv)
    if use_input then
      self:activate(pos, meta);
    end
    
    return stack;
  end
  function appliance:cb_tube_can_insert(pos, node, stack, direction, owner)
    return self:tube_can_insert(pos, node, stack, direction, owner);
  end
  local item_supply = 
    {
      update_node_def = function (self, supply_data, node_def)
          node_def.groups.tubedevice = 1;
          node_def.groups.tubedevice_receiver = 1;
          node_def.tube =
            {
              insert_object = function(pos, node, stack, direction, owner)
                return self:cb_tube_insert_object(pos, node, stack, direction, owner);
                end,
              can_insert = function(pos, node, stack, direction, owner)
                  return self:cb_tube_can_insert(pos, node, stack, direction, owner);
                end,
              connect_sides = {}, 
              input_inventory = self.output_stack,
            };
          for _,side in pairs(self.items_connect_sides)do
            node_def.tube.connect_sides[side] = 1
          end
        end,
      after_dig_node = function(self, liquid_data, pos)
          pipeworks.scan_for_tube_objects(pos);
        end,
      after_place_node = function(self, liquid_data, pos)
          pipeworks.scan_for_tube_objects(pos);
        end,
    };
  appliances.add_item_supply("tube_item", item_supply)
end

