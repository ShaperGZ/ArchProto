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
    attr_accessor :name

    def initialize()
      @container=nil
      @inputs=[]
      @outputs=[]
      @unused=[]
      @in_names=[]
      @out_names=[]
      @params=nil
      @name='UNRule'
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


    def Rule._extract_geo(g)
      if g.is_a? Sketchup::Entity
        t=g.transformation
        ms=ArchUtil.Transformation_scale_3d([t.xscale,t.yscale,t.zscale])
        mesh=Geom::PolygonMesh.new()
        p "=============="
        g.entities.each{|e|
          if e.is_a? Sketchup::Face
            verts=e.vertices
            pts=[]
            e.vertices.each{|v|
              pp=v.position.clone
              p=ms*v.position
              # p "#{pp} ---> #{p} "
              p "#{pp[0].to_m} -> #{p[0].to_m}"
              pts<<p
            }
            mesh.add_polygon(pts)
          end
        }
        p '---------------'
        # localbbox=Geom::BoundingBox.new()
        # localbbox.add mesh.points
        # mesh.points.each{|pt| p pt[0].to_m}
        # trans=g.transformation
        # mesh.transform! trans
        geo=MeshUtil::AttrComposit.new
        geo.add mesh
        geo.position=g.bounds.min
        return geo
      elsif g.is_a? MeshUtil::AttrGeo
        p "->attrGeo"
        return g
      end
      p "shape_grammar.rb _extract_geo(g) g must be a Ssetchup::Entity or MeshUtil::AttrGeo"
      raise ScriptError

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

    # p "pre modify divs=#{divs}"
    divs=SG._modify_divs(divs,ttl,repeat)
    normal=geometry.vects[axis]
    mesh=geometry.mesh
    inverse=Geom::Vector3d.new(*geometry.position)
    inverse.reverse!
    mesh.transform! Geom::Transformation.translation(inverse)
    # p "post modify divs=#{divs}"
    geos=[]
    current=0
    for i in 0..divs.size-1
      d=divs[i]+current
      offset_vect=Geom::Vector3d.new(*normal)
      offset_vect.length=d.m
      # p "d=#{offset_vect.length.to_m}m"
      pos=Geom::Point3d.new(*offset_vect)
      # pos=geometry.position+offset_vect
      pln=[pos,normal]
      p "d=#{d} pos.x=#{pos[0].to_m}"
      # p "mesh=#{mesh} size=#{mesh.points.size}"
      left,right,cap=MeshUtil.split_mesh(pln,mesh,true)
      # p "left=#{left}, right=#{right}"

      mesh=right
      current=d

      geo=MeshUtil::AttrComposit.new()
      if true
      # if left.points.size>=4
      #   geo.add left, geometry.position
        geo.add left
        geo.position=geometry.position
        geo.reflection=geometry.reflection
        geo.rotation=geometry.rotation
        geo.base_vect=basevect
        geos<<geo
      end

      if i==divs.size-1 and right.points.size>=3
        geo=MeshUtil::AttrComposit.new()
        if true
        # if right.points.size>=4
        #   geo.add right,pos
          geo.add right, pos
          geo.position=geometry.position+offset_vect
          geo.reflection=geometry.reflection
          geo.rotation=geometry.rotation
          geo.base_vect=basevect
          geos<<geo
        end
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
end

module SGRules

  class Grammar < SG::Rule
    attr_accessor :rules
    attr_accessor :container
    def initialize()
      super()
      @container=nil
      @rules=[]
      @name='UNGrammar'
    end
    def Grammar.create(geos=nil)
      if geos==nil
        geos=[]
        gps=Sketchup.active_model.selection
        for g in gps
          geos<<g
        end
      end

      grammar=Grammar.new()
      grammar.inputs+=geos
      return grammar
    end

    def add(rule)
      @rules<<rule
    end

    def execute(start=0)
      last_output=[]
      for i in start..@rules.size-1
        rule=@rules[i]
        if i==0
          rule.inputs=inputs
        else
          rule.inputs=last_output
        end
        rule.execute()
        p "exe[#{i}]#{rule.name} ins:#{rule.inputs.size} outs:#{rule.outputs.size}"
        rule.outputs.each{|o|
          p "o.name=#{o.name}"
        }
        last_output=rule.outputs
      end
      @outputs=last_output
    end

    def update_model()
      if @container==nil
        @container=Sketchup.active_model.entities.add_group()
      end

      @container.entities.clear!
      MeshUtil.add_geos_to_model(@outputs,@container,0)
    end
  end

  class Split < SG::Rule
    attr_accessor :axis
    def initialize(in_names,out_names,divs,axis=0,repeat=Repeat::None)
      super()
      @axis=axis
      # sample 1 dive input : 'r0.3,0.4'
      #               output: param:[0.3,0.4] mode:'ratio'
      #               ratio mode starts with 'r'
      #
      # sample 2 dive input : '30,40'
      #               output: param:[30,40] mode:'length'
      #
      # mode can be 'length' or 'ratio'
      @params,@mode=_interpret_divs(divs)
      @in_names=in_names.split(',')
      @out_names=out_names.split(',')
      @repeat=repeat
      @axis=axis
      @name='Split'
    end

    def mode()
      return @mode
    end

    def execute()
      return if @inputs==nil or @inputs.size==0 or @params==nil
      repeat=@repeat
      @outputs=[]
      count=0
      for g in @inputs
        # p "<g.class=#{g.class} g.name=#{g.name}"
        g=self._extract_geo(g)
        # p ">g.class=#{g.class} g.name=#{g.name}"
        # p "[#{count}]:#{g.mesh.points}"
        # p "#{g.class}, #{g.name}: pos:#{g.position} size:#{g.size}"
        if @in_names.include? g.name or @in_names.size==0
          if @mode=='length'
            geos=SG.split_length(g,@params,@axis,repeat)
          elsif @mode =='ratio'
            # p "split ratio divs=#{@params}"
            geos=SG.split_ratio(g,@params,@axis,repeat)
          else
            p "undefined mode:#{@mode}"
            raise ScriptError
          end
          @outputs+=geos if geos!=nil and geos.size>0
        else
          @unused<<g
        end
      end
      assign_names()
      @outputs+=@unused
    end

    def _interpret_divs(strdivs)
      divs=[]
      mode='length'
      if strdivs[0]=='r'
        mode='ratio'
        strdivs=strdivs[1..-1]
      end

      trunks=strdivs.split(',')
      trunks.each{|s|
        divs<<s.to_f
      }
      return divs,mode
    end


  end
end

class SGInvalidator
  attr_accessor :states
  attr_accessor :grammars
  attr_accessor :subjects
  def initialize()
    @subjects=[]
    @states=Hash.new
    @grammars=[]
  end

  def clear_grammars()
    @grammars=[]
  end
  def add_grammar(g)
    @grammars<<g
  end

  def add(ent)
    @states[ent]={}
  end

  def add_range(ents)
    for e in ents
      add(e)
    end
  end

  def invalidate()
    sels=Sketchup.active_model.selection.to_a
    for s in sels
      if is_ent_invalidated(s)
        p "sg invalidator"
        for g in @grammars
          g.execute if g.inputs.include? s
        end
      end
    end # for s
  end

  def is_ent_invalidated(ent)
    return false if @states.key? ent
    t=ent.transformation

    if  t.xscale!=@states[ent]['xscale'] or
        t.yscale!=@states[ent]['yscale'] or
        t.zscale!=@states[ent]['zscale']
      flag=true
    else
      flag=false
    end
    p "flag=#{flag}"
    @states[ent]['xscale']=t.xscale
    @states[ent]['yscale']=t.yscale
    @states[ent]['zscale']=t.zscale

    return flag
  end

end

def sgtest
  # $sgi=SGInvalidator.new
  # $custom_invalidator=[$sgi]

  $g=SGRules::Grammar.create()
  $g.add(SGRules::Split.new('','A,B','r0.3,0.4'))
  # $g.add(SGRules::Split.new('B','C,B','r0.5',1))
  $g.execute()
  $g.update_model()

  # $sgi.add_grammar $g
  # $sgi.add_range($g.inputs)
  nil
end