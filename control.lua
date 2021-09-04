
appliances.controls = {}

function appliances.add_control(control_name, control_def)
  if appliances.all_extensions[control_name] then
    minetest.log("error", "Another appliances mod extension with name \""..control_name.."\" is already registered.")
    return ;
  end
  appliances.item_supplies[control_name] = control_def;
  appliances.all_extensions[control_name] = control_def;
end

-- mesecons
if appliances.have_mesecons then
  local control = 
    {
      
    };
end

-- digilines? 
