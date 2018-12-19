module Evacuation
  class Poly
    def initialize(segments)
      @segments=segments
      @length=0
      segments.each{|s| @length+=s.length}
    end
    def length
      return @length
    end
    def point_at(t)

    end
    def geo_at_dist(d)
      # d is the distance from the begining of a poly
      d=d.m
      # total is use to keep track of segment lengths
      total=0

      for seg in @segments
        nextdist = total + seg.length
        if nextdist >= d
          trim = d - total
          b=MeshUtil::AttrBox.new
          geo = seg.abstract_geometry
          xvect = geo.vects[0]
          xvect.length = trim
          pos = geo.position + xvect
          b.position = pos
          b.rotation=geo.rotation
          b.attributes['true_position']=pos.clone
          # b.position-= Geom::Vector3d.new(1.5.m,1.5.m,0)
          b.size=[3.m,3.m,3.m]
          b.name='MK_STAIR'
          b.attributes['parent_start']=geo.position
          b.attributes['d']=d
          # the real distance in a segment is (d-total) since total is the sum of previous segment lengths
          b.attributes['percentage_in_segment']=(d-total)/seg.length
          b.attributes['parent_name']=geo.name
          xvect=geo.vects[0]
          xvect.length=geo.size[0]
          b.attributes['parent_end']=geo.position+xvect
          return b
        end
        total+=seg.length
      end
      return nil
    end

  end
  class Segment
    attr_accessor :length
    attr_accessor :abstract_geometry
    def initialize(abs_geo)
      @length = abs_geo.size[0]
      @abstract_geometry = abs_geo
    end

  end
  class Corridor
    def initialize(abs_geo)
      @segments = [Evacuation::Segment.new(abs_geo)]
    end

    def segments

    end
  end
end

class BH_Evacuation < Arch::BlockUpdateBehaviour
  attr_accessor :str_cores
  attr_accessor :lft_cores

  def initialize(gp,host)
    super(gp,host)
    @efficiency=0
    @lft_cores=[]
    @str_cores=[]
  end

  def grid_position(position)
    un_width=@host.attr("un_width")
    bh_bays=@host.get_updator_by_type(BH_Bays)
    grid=bh_bays.basic_floor_grid
    p "bh_bays=#{bh_bays} grid=#{grid}"
    for cluster in grid.clusters.values
      p "cluster=#{cluster.name} units count=#{cluster.units.size}"
      for unit in cluster.units
        d=unit.geometry.position.distance(position)
        p " >>>>> NOT FOUND d=#{d} position=#{position} return:#{unit.geometry.position}"
        if d<(un_width)
          p " >>>>> FOUND d=#{d} position=#{position} return:#{unit.geometry.position}"
          return unit.geometry.position
        end
      end
    end
    return position
  end

  def invalidate()

    bh_composition=@host.get_updator_by_type(BH_Apt_Composition)

    # this gets dict list of bool
    # keys are:["double","L-shape","U-shape","O-shape"]
    # p "composition is #{bh_composition}"
    shapes=bh_composition.composition()
    # comp_abs_geo=bh_composition.abstract_geometries
    comp_abs_geo=[]
    for ag in bh_composition.abstract_geometries
      nag=ag.clone
      comp_abs_geo<<nag
    end
    circulations=[]
    segments=[]

    circulation_w = host.attr('crd_width')
    bd_width = host.attr('bd_width')
    bd_depth = host.attr('bd_depth')
    bd_height = host.attr('bd_height')

    un_width = host.attr('un_width')
    un_depth = host.attr('un_depth')

    offset=un_depth.m
    # p "-------------------------------------"

    # 1 get corridors in order from abstract geometries in composition
    corridors_ordered_names=['C2','C1','C3','C4']
    ordered_cs=[]
    for k in corridors_ordered_names
      for g in comp_abs_geo
        if g.name.include? k
          ordered_cs<<g
          break
        end
      end
    end


    # p "ordered_cs #{ordered_cs}"
    # 2 add all corridors to segments[] to create a poly
    # however, c1 must be trimed in 'L','U',
    # c4 will be trimed in 'O' format
    for g in ordered_cs
      geo=g
      if g.name=='C1'
        # determine compositon type
        if (shapes['L-shape'] || shapes['U-shape'] || shapes['O-shape'])
          b=MeshUtil::AttrBox.new()
          b.position=g.position+ Geom::Vector3d.new(offset,0,0)
          b.size=g.size
          if(shapes['L-shape'])
            b.size[0]-=(offset)
          else
            b.size[0]-=(offset*2)
          end
          b.rotation=g.rotation
          b.reflection=g.reflection
          b.name='C1trim'
          geo=b
        end
      elsif g.name=='C4'
        b=MeshUtil::AttrBox.new()
        b.position=g.position+ Geom::Vector3d.new(offset,0,0)
        b.size=g.size
        b.size[0]-=(offset*2)
        b.rotation=g.rotation
        b.reflection=g.reflection
        b.name='C1trim'
        geo=b
      end

      # p "g=#{g.name}.pos=#{g.position}"
      geo.name=g.name
      circulations<<geo
      segments<< Evacuation::Segment.new(geo)
      # @abstract_geometries<<gen_bays(g)
    end

    # p "segments=#{segments}"
    segments.each{|s| p s.length}
    poly=Evacuation::Poly.new(segments)
    length=poly.length.to_m
    numE=(length/30).ceil
    numE=2 if numE<2
    remain=length%30
    @efficiency=(30.0-remain)/30.0
    eff_dscr="#{remain.round(2)}m wasted ttl:#{length.round(2)}"
    @gp.set_attribute("PrototypeScores","VertlEvac",[@efficiency,eff_dscr])
    # p "poly.length=#{length} numE=#{numE} efficiency=#{@efficiency}"


    # 3 create abstract geometries
    @abstract_geometries=[]
    h_offset=Geom::Vector3d.new(0,0,bd_height.m)
    dist=0
    for i in 0..numE-1
      dist+=15
      g=poly.geo_at_dist(dist)
      if g.is_a? MeshUtil::AttrGeo
        # p "added g.pos=#{g.position} dist=#{dist}"
        # g.position=grid_position(g.position)
        g.position+=h_offset
        @abstract_geometries<<g
      end
      dist+=15
    end



    # 4 entrace_name is a corridor name such as 'C1' or 'C4'
    # the default value is C1, there no UI to update this value
    # a command is provided in arch_util_apdx_helper as 'set_entrance(int)'
    entrance_name='C'+@gp.get_attribute("OperableStates","entrance_number").to_s

    # 5 find the marker closest to the defined entrance
    pool=[]
    closest=@abstract_geometries[0]
    closest_p=1
    @lft_cores=[]
    @str_cores=[]

    for g in @abstract_geometries
      str_cores<<g
      if g.attributes['parent_name']==entrance_name
        # the percentage is between 0 and 1, the following formular is to find the value closeset to 0.5(middle)
        percentage=(g.attributes['percentage_in_segment']-0.5).abs
        if percentage<closest_p
          closest_p=percentage
          closest=g
        end
        pool<<g
      end
    end

    #enlarge the lift core to visualize
    closest.size[0]*=3

    @lft_cores<<closest
    for c in @lft_cores
      @str_cores.delete(c)
    end




    #add geometries to model
    _add_all_abs_to_one

    # failed code for dimension
    # for ag in @abstract_geometries
    #   s1=ag.attributes['parent_start']+h_offset
    #   e1=ag.attributes['true_position']+h_offset
    #   s2=e1
    #   e2=ag.attributes['parent_end']+h_offset
    #   d_offset=ag.vects[1]
    #   d_offset.length*=-30.m
    #   # p "s1:#{s1},e1:#{e1}-----s2:#{s2},e2:#{e2}"
    #
    #   g=@concrete_geometries[0]
    #   #TODO: unkown bug in add dimension arguments
    #   # begin
    #   #   g.entities.add_dimension_linear(s1,e1,d_offset)
    #   #   g.entities.add_dimension_linear(s2,e2,d_offset)
    #   # rescue
    #
    #   # end
    # end

    for c in @concrete_geometries
      c.material='red'
    end

  end


  def convert_definition_to_absgeo(definition,h)
    absgeos=[]
    definition.entities.each{|e|
      ents=[]
      color='white'
      if e.is_a? Sketchup::Group
        ents=e.entities
      elsif e.is_a? Sketchup::ComponentInstance
        ents=e.definition.entities
      else
        continue
      end

      if e.name.include? 'str'
        color='dargkred'
      elsif e.name.include? 'lft'
        color='gold'
      elsif e.name.include? 'srv'
        color='gray'
      end


      poly=_get_up_facing_face(ents)
      ext=MeshUtil::AttrExtrusion.new(poly,h)
      ext.color=color
      absgeos<ext
    }
    return absgeos
  end

  def _get_up_facing_face(ents)
    for e in ents
      if e.is_a? Sketchup::Face and e.normal.z==-1
        verts=e.vertices
        verts.reverse!
        pts=[]
        for v in verts
          pts<<v.position
        end
        return pts
      end
      return nil
    end
  end
end