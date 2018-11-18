module ArchUtil
  def selected_g()
    g=Sketchup.active_model.selection[0]
    return g
  end

  def selected_bb()
    g=selected_g
    bb=Proto_Apt.created_bojects(g)
    return bb
  end

  def set_entrance(cnumber)
    g.selected_g
    g.set_attribute("OperableStates","entrance_number",cnumber)
    bb=selected_bb
    bb.invalidate()
  end
end



