require 'mesh_util'
class Repeat
  None=112
  Last=111
  Entire=222
end
$sg_created_objects=[] if $sg_created_objects == nil



module SG
  class Rule
    attr_accessor :inputs
    attr_accessor :outputs
    # attr_accessor :unused
    attr_accessor :invalidated
    attr_accessor :in_names
    attr_accessor :out_names
    attr_accessor :params


    def initialize()
      @container=nil
      @inputs=[]
      @outputs=[]
      @unused=[]
      @in_names=[]
      @out_names=[]
      @params=nil
    end

    def execute()
    end

    def assign_names()
      return if @out_names.size==0
      index=0
      for i in 0..outputs.size-1
        g=outputs[i]
        name_index=index% @out_names.size
        g.name=@out_names[name_index]
        index+=1
      end
    end

  end






  def SG._modify_divs(divs,ttl,repeat=Repeat::None)
    # modify the given div array base on the actual total length to be divided and repeat pattern
    # sample:
    #   divs=[3,3,4]
    #   ttl=7
    #   ndivs=[3,3]

    ndivs=[divs[0]]
    current=divs[0]
    index=0
    while current < ttl
      index+=1
      if index<divs.size
        d=divs[index]
      else
        if repeat==Repeat::Last
          d=divs[-1]
        elsif repeat == Repeat::Entire
          i=index%divs.size
          d=divs[i]
        else
          break
        end
      end
      ndivs<<d if d!=nil
      current+=d if d!=nil
    end
    return ndivs
  end

  def SG.split_length(geometry,divs,axis=0,repeat=Repeat::None)
    # Split a abstract geometry into geometries
    # Params:
    # +geometry+:: abstract geometry
    # +divs+:: array of float spacifies length of each division

    ttl=geometry.size[axis].to_m
    basevect=geometry.vects[0]

    p "pre modify divs=#{divs}"
    divs=SG._modify_divs(divs,ttl,repeat)
    normal=geometry.vects[axis]
    mesh=geometry.mesh
    p "post modify divs=#{divs}"
    geos=[]
    current=0
    for i in 0..divs.size-1
      d=divs[i]+current
      offset_vect=Geom::Vector3d.new(*normal)
      offset_vect.length=d.m
      p "d=#{offset_vect.length.to_m}m"
      pos=Geom::Point3d.new(*geometry.position)
      pos+=offset_vect
      pln=[pos,normal]
      p "mesh=#{mesh} size=#{mesh.points.size}"
      left,right,cap=MeshUtil.split_mesh(pln,mesh,true)
      p "left=#{left}, right=#{right}"

      mesh=right
      current=d

      geo=MeshUtil::AttrComposit.new()
      geo.add left,geometry.position
      geo.position=geometry.position
      geo.reflection=geometry.reflection
      geo.rotation=geometry.rotation
      geo.base_vect=basevect
      geos<<geo

      if i==divs.size-1 and right.points.size>=3
        geo=MeshUtil::AttrComposit.new()
        geo.add right,pos
        geo.position=pos
        geo.reflection=geometry.reflection
        geo.rotation=geometry.rotation
        geo.base_vect=basevect
        geos<<geo
      end
    end
    return geos
  end



  def SG.split_ratio(geometry,divs,axis=0,repeat=Repeat::None)
    ttl=geometry.size[axis].to_m
    for i in 0..divs.size-1
      divs[i]*=ttl
    end
    SG.split_length(geometry,divs,axis,repeat)
  end

  def SG.split(geometry,str,axis=0)
    divs=str.split(',')
    ttl=geometry.size[axis].to_m
    divs=[]

    #sample str: [6,5,3r,3.5r,4,2.5]
    #
  end

end

module SGRules

  class Grammar < SG::Rule
    attr_accessor :rules
    def initialize()
      super()
      @rules=[]
    end
    def add(rule)
      @rules<<rule
    end
    def execute(start=0)
      last_output=[]
      for i in start..@rules.size-1
        rule=@rules[i]
        if start==0
          rule.inputs=inputs
        else
          rule.inputs=@rules[i-1].outputs
        end
        rule.execute()
        last_output=rule.outputs
      end
      @outputs=last_output
    end

  end

  class Split < SG::Rule
    attr_accessor :axis
    def initialize(divs,in_names,out_names,axis,repeat=Repeat::None)
      super()
      @axis=axis
      @params=divs
      @in_names=in_names
      @out_names=out_names
    end

    def execute()
      return if geos==nil or geos.size==0 or @params=nil
      @outputs=[]
      for g in geos
        if @in_names.include? g.name
          geos=SG.split_length(g,@params,axis,repeat)
          @outputs+=geos if geos!=nil and geos.size>0
        else
          @unused<<g
        end
      end
      assign_names()
      @outputs+=@unused
    end
  end



end