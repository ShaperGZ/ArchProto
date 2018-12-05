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

    def initialize(in_names=nil,out_names=nil)
      if in_names!=nil
        @in_names=in_names.split(',')
      else
        @in_names=[]
      end

      if out_names!=nil
        @out_names=out_names.split(',')
      else
        @out_names=[]
      end

      @container=nil
      @inputs=[]
      @outputs=[]
      @unused=[]
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
        g=g.extract_geo
      end
      return g
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

  def SG.split_equal(geometry,div,stretch=true,axis=0)
    size=geometry.size
    return [geometry] if size==nil
    ttl=geometry.size[axis].to_m
    if stretch
      count=(ttl/div).round
      if count>0
        w=ttl/count
        divs=[w]*(count)
        # p "count=#{count} w=#{w} divs=#{divs}"
      else
        divs=nil
        # p "count=#{count} divs=nil"
      end
    else
      count=(ttl/div).floor
      if count>0
        remain=ttl%div
        divs=[div]*count
        divs<<remain
      else
        divs=nil
      end

      if divs==nil or divs.size==0
        return [geometry]
      end
    end
    p "divs=#{divs}"
    return SG.split_length(geometry,divs,axis)
  end

  def SG.split_length(geometry,divs,axis=0,repeat=Repeat::None,inverse_dir=false)
    # Split a abstract geometry into geometries
    # Params:
    # +geometry+:: abstract geometry
    # +divs+:: array of float spacifies length of each division

    ttl=geometry.size[axis].to_m
    basevect=geometry.vects[0]

    # p "pre modify divs=#{divs}"
    divs=SG._modify_divs(divs,ttl,repeat)
    normal=geometry.vects[axis]
    geopos=geometry.position.clone
    if inverse_dir
      geopos+=normal
      normal.reverse!
    end

    mesh=geometry.mesh
    inverse=Geom::Vector3d.new(*geopos)
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
      # p "d=#{d} pos.x=#{pos[0].to_m}"
      # p "mesh=#{mesh} size=#{mesh.points.size}"
      left,right,cap=MeshUtil.split_mesh(pln,mesh,true)
      # p "left=#{left}, right=#{right}"

      mesh=right
      current=d

      # m_rot=Geom::Transformation.rotation([0,0,0],[0,0,1],-geometry.rotation)

      geo=MeshUtil::AttrComposit.new()
      if true
      # if left.points.size>=4
      #   geo.add left, geometry.position
        # mesh.transform! m_rot
        geo.add left
        geo.position=geometry.position
        geo.reflection=geometry.reflection
        geo.rotation=geometry.rotation
        # geo.base_vect=basevect
        geos<<geo
      end

      if i==divs.size-1 and right.points.size>=3
        geo=MeshUtil::AttrComposit.new()
        if true
        # if right.points.size>=4
        #   geo.add right,pos
          # mesh.transform! m_rot
          geo.add right, pos
          geo.position=geometry.position+offset_vect
          geo.reflection=geometry.reflection
          geo.rotation=geometry.rotation
          # geo.base_vect=basevect
          geos<<geo
        end
      end
    end
    return geos
  end

  def SG.split_ratio(geometry,divs,axis=0,repeat=Repeat::None,inverse=false)
    size=geometry.size
    return [geometry] if size==nil

    ttl=size[axis].to_m
    for i in 0..divs.size-1
      divs[i]*=ttl
    end
    SG.split_length(geometry,divs,axis,repeat,inverse)
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
          geos<<g if g.is_a? Sketchup::Group
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
      @outputs=[]
      last_output=[]
      for i in start..@rules.size-1
        rule=@rules[i]
        if i==0
          rule.inputs=@inputs.clone
        else
          rule.inputs=last_output
        end
        rule.execute()
        # p "exe[#{i}]#{rule.name} ins:#{rule.inputs.size} outs:#{rule.outputs.size}"
        # rule.outputs.each{|o|
        #   # p "o.name=#{o.name}"
        # }
        # p "#{rule.in_names}->#{rule.out_names}"
        # p "exe[#{i}] inputs:#{rule.inputs.size} outputs:#{rule.outputs.size}"
        # p "inputs:"
        # for i in 0..rule.inputs.size-1
        #   p "inputs[#{i}]:#{rule.inputs[i].name}"
        # end
        # p "outputs:"
        # for i in 0..rule.outputs.size-1
        #   p "outputs[#{i}]:#{rule.outputs[i].name}"
        # end

        last_output=rule.outputs
      end
      @outputs=last_output
      nil
    end

    def update_model()

      # Sketchup.active_model.start_operation('add model',true,false,true)

      if @container==nil
        @container=Sketchup.active_model.entities.add_group()
      end
      # p "grammar.input.size=#{$g.inputs.size} output.size=#{$g.outputs.size}"
      # p "1 pre clear container=#{@container} ents.size=#{@container.entities.size}"
      @container.entities.clear!
      # p "2 post clear container=#{@container} ents.size=#{@container.entities.size}"

      MeshUtil.add_geos_to_model(@outputs,@container,0)

      # Sketchup.active_model.commit_operation
      # p "3 post add_model container=#{@container} ents.size=#{@container.entities.size}"
    end
  end

  class SplitEqual<SG::Rule
    def initialize(int_names,out_names,div,axis,stretch=true)
      super(int_names,out_names)
      @params=div
      @stretch=stretch
      @axis=axis
    end

    def execute()
      @unused=[]
      @outputs=[]

      return if @inputs==nil or @inputs.size==0 or @params==nil

      for g in @inputs
        g=SG::Rule._extract_geo(g)
        if @in_names.include? g.name or @in_names.size==0
          geos=SG.split_equal(g,@params,@stretch,@axis)
          @outputs+=geos if geos!=nil and geos.size>0
        else
          @unused<<g
        end
      end

      assign_names()
      @outputs+=@unused
    end
  end

  class Split < SG::Rule
    attr_accessor :axis
    def initialize(in_names,out_names,divs,axis=0,repeat=Repeat::None,inverse=false)
      super(in_names,out_names)
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
      # @in_names=in_names.split(',')
      # @out_names=out_names.split(',')
      @repeat=repeat
      @axis=axis
      @name='Split'
      @inverse=inverse
    end

    def mode()
      return @mode
    end

    def execute()
      return if @inputs==nil or @inputs.size==0 or @params==nil
      repeat=@repeat
      inverse=@inverse
      @outputs=[]
      @unused=[]
      count=0
      for g in @inputs
        g=SG::Rule._extract_geo(g)
        if @in_names.include? g.name or @in_names.size==0
          if @mode=='length'
            geos=SG.split_length(g,@params.clone,@axis,repeat,inverse)
          elsif @mode =='ratio'
            # p "split ratio divs=#{@params}"
            geos=SG.split_ratio(g,@params.clone,@axis,repeat,inverse)
          else
            p "undefined mode:#{@mode}"
            raise ScriptError
          end

          # p "g:#{g.name} is splited into #{geos.size} geos"
          @outputs+=geos if geos!=nil and geos.size!=nil and geos.size>0
        else
          @unused<<g
        end
        # p "[#{count}]: g.class=#{g.class} g.name=#{g.name} outs.size=#{@outputs.size} @unused.size=#{@unused}"
        count+=1
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

  def reset_timer()
    begin
      stop_timer
    rescue
    end

    $sgi_timer=UI.start_timer(0.01,true){
      begin
        invalidate
      rescue

      end
    }
  end

  def stop_timer()
    UI.stop_timer($sgi_timer)
  end

  def invalidate(forced=false)
    sels=Sketchup.active_model.selection.to_a
    invalidated_grammars=[]
    for s in sels
      if is_ent_invalidated(s) or forced
        # p "sg invalidator"
        for g in @grammars
          invalidated_grammars<<g if g.inputs.include? s and  !invalidated_grammars.include? g
          # g.execute if g.inputs.include? s
        end
      end
    end # for s

    for g in invalidated_grammars
      g.execute
      g.update_model
    end
    nil
  end

  def is_ent_invalidated(ent)
    # p "states contains #{ent}:#{@states.key? ent}"
    return false if !@states.key? ent
    t=ent.transformation

    if  t.xscale!=@states[ent]['xscale'] or
        t.yscale!=@states[ent]['yscale'] or
        t.zscale!=@states[ent]['zscale']
      # p "flag=true"
      flag=true
    else
      # p "flag=false"
      flag=false
    end
    # p "flag=#{flag}"
    @states[ent]['xscale']=t.xscale
    @states[ent]['yscale']=t.yscale
    @states[ent]['zscale']=t.zscale

    return flag
  end

end

def teset_extract
  sel=Sketchup.active_model.selection
  geos=[]
  for geo in geos

  end
end


def sgtest
  $sgi=SGInvalidator.new

  $g=SGRules::Grammar.create()
  $g.add(SGRules::SplitEqual.new('','A,B,C',4.5,0,true))
  $g.add(SGRules::Split.new('A','bath,main','3',1,Repeat::None,true))
  $g.add(SGRules::Split.new('B','main1,main2','r0.5',1))
  $g.add(SGRules::Split.new('C','main3,main4','r0.3',1))
  # $g.add(SGRules::Split.new('A','A','r0.5',2))
  # $g.execute()
  # $g.update_model()

  $sgi.add_grammar $g
  $sgi.add_range($g.inputs)
  $sgi.invalidate
  $sgi.reset_timer
  nil
end

