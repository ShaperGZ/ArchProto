class BH_Apt_Area < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    #p 'f=initialized constrain face'
    super(gp,host)
    _reset_values
  end

  def _reset_values
    @area_ttl=0
    @area_occupy=0
    @area_corridor=0
    @area_evac_vert=0
    @efficency=0

  end

  def invalidate()
    _reset_values
    composition=@host.get_updator_by_type(BH_Apt_Composition)
    evacuation=@host.get_updator_by_type(BH_Evacuation)
    abs_geo=composition.abstract_geometries
    abs_geo+=evacuation.abstract_geometries
    for g in abs_geo
      if g.name[0]=='O'
        @area_occupy+=g.area
      end
      if g.name[0]=='C'
        @area_corridor+=g.area
      end
      if g.name=='MK_STAIR'
        @area_evac_vert+=(3.m*7.m)
      end
    end

    @area_evac_vert+=6.m * 7.m
    @area_ttl=@area_occupy+@area_corridor
    numerator=@area_occupy-@area_evac_vert
    @efficency=numerator/@area_ttl

    fc_base=1500
    fc_remain=@area_ttl%fc_base
    @fc_score=fc_remain/fc_base

    @gp.set_attribute("PrototypeScores","FireCompartment",@fc_score)
    @gp.set_attribute("PrototypeScores","Efficiency",@efficency)

    p @efficency
  end
end

