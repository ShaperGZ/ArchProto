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
      d=d.m
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
          b.attributes['true_position']=b.position.clone
          b.position-= Geom::Vector3d.new(1.5.m,1.5.m,0)
          b.size=[3.m,3.m,3.m]

          b.attributes['parent_start']=geo.position
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
  def initialize(gp,host)
    super(gp,host)
    @efficiency=0
  end

  def invalidate()

    bh_composition=@host.get_updator_by_type(BH_Apt_Composition)
    composition=bh_composition.composition
    abs_geo=bh_composition.abstract_geometries
    circulations=[]
    segments=[]

    circulation_w = host.attr('crd_width')
    bd_width = host.attr('bd_width')
    bd_depth = host.attr('bd_depth')
    bd_height = host.attr('bd_height')

    un_width = host.attr('un_width')
    un_depth = host.attr('un_depth')

    offset=un_depth.m
    p "-------------------------------------"

    # get corridors in order
    corridors_ordered_names=['C2','C1','C3','C4']
    ordered_cs=[]
    for k in corridors_ordered_names
      for g in abs_geo
        if g.name.include? k
          ordered_cs<<g
          break
        end
      end
    end

    for g in ordered_cs
      if g.name=='C1'
        b=MeshUtil::AttrBox.new()
        b.position=g.position+ Geom::Vector3d.new(offset,0,0)
        b.size=g.size
        b.size[0]-=(offset*2)
        b.rotation=g.rotation
        b.reflection=g.reflection
        b.name='C1trim'
        g=b
      end

      # p "g=#{g.name}.pos=#{g.position}"
      circulations<<g
      segments<< Evacuation::Segment.new(g)
      # @abstract_geometries<<gen_bays(g)
    end

    poly=Evacuation::Poly.new(segments)
    length=poly.length.to_m
    numE=(length/30).ceil
    numE=2 if numE<2
    @efficiency=(30.0-length%30.0)/30.0
    # p "poly.length=#{length} numE=#{numE} efficiency=#{@efficiency}"

    # create abstract geometries
    @abstract_geometries=[]
    h_offset=Geom::Vector3d.new(0,0,bd_height.m)
    dist=0
    for i in 0..numE-1
      dist+=15
      g=poly.geo_at_dist(dist)
      if g.is_a? MeshUtil::AttrGeo
        # p "added g.pos=#{g.position} dist=#{dist}"
        g.position+=h_offset
        @abstract_geometries<<g
      end
      dist+=15
    end

    #add geometries to model
    _add_all_abs_to_one

    for ag in @abstract_geometries
      s1=ag.attributes['parent_start']+h_offset
      e1=ag.attributes['true_position']+h_offset
      s2=e1
      e2=ag.attributes['parent_end']+h_offset
      d_offset=ag.vects[1]
      d_offset.length*=-30.m
      # p "s1:#{s1},e1:#{e1}-----s2:#{s2},e2:#{e2}"

      g=@concrete_geometries[0]
      #TODO: unkown bug in add dimension arguments
      # begin
      #   g.entities.add_dimension_linear(s1,e1,d_offset)
      #   g.entities.add_dimension_linear(s2,e2,d_offset)
      # rescue

      # end
    end

  end
end