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
    abs_geo_comp=composition.abstract_geometries
    abs_geo_evac=evacuation.abstract_geometries

    for g in abs_geo_comp
      # p "#{g.name}: #{g.area.to_m.to_m}"
      if g.name[0]=='O'
        @area_occupy+=g.area.to_m.to_m
      end
      if g.name[0]=='C'
        @area_corridor+=g.area.to_m.to_m
      end
    end
    for g in abs_geo_evac
      if g.name[0]=='C'
        @area_evac_vert+=(3*7)
      end
    end

    @area_evac_vert+=(6 * 7)
    @area_ttl=@area_occupy+@area_corridor
    numerator=@area_occupy-@area_evac_vert
    @efficency=numerator/@area_ttl
    eff_dscr="#{numerator.round}/#{@area_ttl.round}"

    fc_base=1500
    fc_remain=@area_ttl%fc_base
    @fc_score=fc_remain/fc_base
    firecomp_dscr="#{@area_ttl.round(2)/fc_base} compartments @1500sqm each"

    # p "area_ttl = #{@area_ttl}"
    floors=(@host.attr('bd_height')/3).round
    gfa=floors * @area_ttl
    WD_Interact.singleton.set_web_area(gfa.round)
    @gp.set_attribute("BuildingBlock","GFA",gfa)
    @gp.set_attribute("BuildingBlock","BaseFloorArea",@area_ttl)
    @gp.set_attribute("PrototypeScores","FireCompt",[@fc_score,firecomp_dscr])
    @gp.set_attribute("PrototypeScores","Efficiency",[@efficency,eff_dscr])

  end
end


