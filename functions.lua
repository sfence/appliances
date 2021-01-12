
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

