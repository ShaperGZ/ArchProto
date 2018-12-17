require 'mesh_util'
class Repeat
  None=111
  Last=112
  Entire=113
end
$sg_created_objects=[] if $sg_created_objects == nil



module SG
  class SGUI
    def SGUI.create(grammar)
      SGUI.open(grammar)
      UI.start_timer(1,false){
        SGUI.create_ui
      }

    end

    def SGUI.open(grammar)

      if grammar==nil
        p "there is no selected grammar to open sgui"
        return
      end

      # if $sgui!=nil
      #   $sgui.close
      # end
      $sgui_subject=grammar
      $sgui=UI::HtmlDialog.new({
                                   :scrollable => true,
                                   :resizable => true,
                                   :min_width => 500,
                                   :min_height => 100,
                                   :style => UI::HtmlDialog::STYLE_DIALOG
                               })
      file=ArchProto.get_file_path('dialog/sg_ui.html')
      $sgui.set_url(file)
      $sgui.show()
      $sgui.add_action_callback("set_rule_params"){|dialog,param|
        # sample param:
        # '1|Flip|In:B;Out:B;axis:0;repeat:111'
        index,rname,params=param.split('|')
        p "input string = #{param}"
        p "index=#{index} rname=#{rname} params=#{params}"

        index=index.to_i
        g=$sgui_subject
        rule=g.rules[index]
        rule.set_params(params)
        g.execute()
        g.update_model()
      }
    end

    def SGUI.create_ui()
      return if $sgui_subject==nil

      creationStr=''
      counter=0
      g=$sgui_subject
      g.rules.each{|r|
        creationStr+='/' if counter>0
        creationStr+=r.format()
        counter+=1
      }


      msg="create_ui('#{creationStr}')"
      p "creation string = #{msg}"
      $sgui.execute_script(msg)
    end
  end

  class Rule
    attr_accessor :inputs
    attr_accessor :outputs
    # attr_accessor :unused
    attr_accessor :invalidated
    attr_accessor :in_names
    attr_accessor :out_names
    attr_accessor :params
    attr_accessor :name
    attr_accessor :container
    attr_accessor :containers

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
      @divs=nil
      @name='UNRule'
    end

    def execute()
    end

    def assign_names(outputs)
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
        g=g.create_sgo
      end
      return g
    end

    def format()
      txt="#{@name}|In:#{@in_names.to_s};Out:#{@out_names.to_s};#{format_params()}"
      txt.gsub! '"',''
      txt.gsub! '[',''
      txt.gsub! ']',''
      return txt
    end

    def format_params()
      return ''
    end
  end

  class RuleTemplateStd<SG::Rule
    def initialize(in_names,out_names)
      super(in_names,out_names)
    end

    def execute_geo(g)
      #override this method
    end

    def execute()
      @outputs=[]
      @unused=[]
      for g in @inputs
        geoOutput=[]
        if @in_names.include? g.name or @in_names.size==0
          g=SG::Rule._extract_geo(g)
          execute_geo(g)
          geoOutput<<g
        else
          @unused<<g
        end
        assign_names(geoOutput)
        @outputs+=geoOutput if geoOutput.size>0
      end
      @outputs+=@unused
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
    ttl=geometry.size[axis].to_m.abs
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
    # p "divs=#{divs}"
    return SG.split_length(geometry,divs,axis)
  end

  def SG.split_length(geometry,divs,axis=0,repeat=Repeat::None,inverse_dir=false)
    # Split a abstract geometry into geometries
    # Params:
    # +geometry+:: abstract geometry
    # +divs+:: array of float spacifies length of each division

    # we split the msh with the unitized base_mesh
    # so the sizes are all 1
    pF,pR,pS=geometry.reflection_rotation_scale()
    actualsize=pS
    reflection=geometry.reflection
    ttl=actualsize[axis].abs.to_m
    basevect=geometry.base_vects[axis].normalize
    basevect.length=geometry.reflection[axis]
    geos=[]

    # p "pre modify divs=#{divs}, ttl=#{ttl}"
    divs=SG._modify_divs(divs,ttl,repeat)
    # p "post modify divs=#{divs}"
    # scale the div base on nomalized size
    for i in 0..divs.size-1
      divs[i]/=ttl
    end
    # p "post normalize divs=#{divs}"
    normal=basevect
    origin=Geom::Point3d.new(0,0,0)
    af=geometry.reflection
    mesh=geometry.base_mesh
    current=0
    normal.length=af[axis]
    for i in 0..divs.size-1
      d=divs[i]+current
      offset_vect=Geom::Vector3d.new(*normal)
      offset_vect.length=d
      pos=Geom::Point3d.new(*offset_vect)
      pln=[pos,normal]
      left,right,cap=MeshUtil.split_mesh(pln,mesh,true)
      mesh=right
      current=d

      geo=SG.__split_length_add_geo(left,geometry,normal,axis)
      geos<<geo if geo!=nil

      if i==divs.size-1 and current<1 and right !=nil and right.points.size>=3
        geo=SG.__split_length_add_geo(right,geometry,normal,axis)
        geos<<geo if geo!=nil
      end
    end
    # p "<<at split_length"
    # geos.each{|g|
    #   p g.size[0].to_m.round
    # }
    # p ">>"
    return geos
  end

  def SG.__split_length_add_geo(mesh,geometry,normal,axis)
    # this method is used within split_length
    # mesh:     the splited mesh, left or right
    # geometry: the original geometry being splitted
    # normal:   the normal of the splitting plane
    return nil if mesh==nil or mesh.points.size<3

    pF,pR,pS=geometry.reflection_rotation_scale()
    actualsize=pS
    bound=Geom::BoundingBox.new
    bound.add(mesh.points)
    size=[bound.width,bound.height,bound.depth]
    pos=bound.min
    # p "bound.pos=#{pos}"
    # 因为切割用的是unit mesh，把尺寸放大回原几何体比例
    3.times{|i|
      size[i] *= actualsize[i]
      pos[i]  *= actualsize[i]
    }
    geo=SGObject.new()
    geo.set_base_mesh mesh
    grot=geometry.rotation
    posoffset=Geom::Vector3d.new(*pos)
    # posoffset.length *= pF[axis]*-1 if posoffset.length!=0
    posoffset = Geom::Transformation.rotation(geometry.position,[0,0,1],grot.degrees) * posoffset

    # posoffset.length=posoffset.length.abs*reflection[axis] if posoffset.length!=0
    pos=geometry.position+posoffset
    # p "pos=#{pos} g.pos=#{geometry.position} posoffset=#{posoffset} reflection[#{axis}]=#{reflection[axis]}"
    geo._update_transform(size,grot,pos)
    geo.set_anchor_reflection_values_only(geometry.reflection)
    return geo
  end

  def SG.split_ratio(geometry,divs,axis=0,repeat=Repeat::None,inverse=false)
    size=geometry.size
    return [geometry] if size==nil

    ttl=size[axis].abs.to_m
    for i in 0..divs.size-1
      divs[i]*=ttl
    end
    return SG.split_length(geometry,divs,axis,repeat,inverse)
  end

  def SG.flip_axis(geometry,flipArray=[-1,1,1])
    af=geometry.reflection.clone
    3.times{|i| af[i]*=flipArray[i]}
    geometry.reflection=af
    # geometry.anchor_flip(flipArray)
    return geometry
  end

  def SG.anchor_rotate(geometry,rtimes)
    geometry.anchor_rotate(rtimes)
    return geometry

  end
end

module SGRules

  class Grammar < SG::Rule
    attr_accessor :rules
    attr_accessor :container
    attr_accessor :mode #0 add to single mode, 1 add to individual models
    def initialize()
      super()
      @container=nil
      @rules=[]
      @mode=0
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

    def update_individual_model()
      @containers=[] if @containers==nil
      diff = @containers.size-@outputs.size

      if diff>0
        del_count=0
        diff.times{
          g=@containers[-1]
          g.erase!
          @containers.delete(g)
          del_count+=1
        }
        p "deleted #{del_count} groups"
      end
      prect_count=@containers.size
      for i in 0..@outputs.size-1
        output=@outputs[i]
        if i<@containers.size
          if @containers[i].valid?
            output.add_individual_model(@containers[i])
          else
            @containers[i]=output.add_individual_model()
          end
        else
          @containers <<output.add_individual_model()
        end
      end
      p "outputs:#{@outputs.size} pre con:#{prect_count} post con:#{@containers.size} "

    end

    def update_model()
      # Sketchup.active_model.start_operation('add model',true,false,true)

      if @container==nil or !@container.valid?
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

  class RotAxis<SG::RuleTemplateStd
    def initialize(in_names,out_names,rtimes)
      super(in_names,out_names)
      @rtimes=rtimes
    end

    def execute_geo(g)
      g.anchor_rotation(@rtimes)
    end
  end

  class FlipAxis<SG::RuleTemplateStd
    def initialize(in_names,out_names,fliparray)
      super(in_names,out_names)
      @fliparray=fliparray
    end

    def execute_geo(g)
      SG.flip_axis(g,@fliparray)
    end

    # def execute()
    #   @outputs=[]
    #   @unused=[]
    #   for g in @inputs
    #     geoOutput=[]
    #     g=SG::Rule._extract_geo(g)
    #     if @in_names.include? g.name or @in_names.size==0
    #       SG.flip_axis(g,@fliparray)
    #       geoOutput<<g
    #     else
    #       @unused<<g
    #     end
    #     assign_names(geoOutput)
    #     @outputs+=geoOutput if geoOutput.size>0
    #   end
    #
    #   @outputs+=@unused
    #   # p "FlipAxis outputs count=#{@outputs.size}"
    # end
  end

  class Remove<SG::Rule
    def initialize(in_names)
      super(in_names,nil)
    end

    def execute
      @outputs=[]

      for g in @inputs
        if !@in_names.include? g.name
          @outputs<<g
        end
      end
    end
  end

  class SplitEqual<SG::Rule
    def initialize(in_names,out_names,div,axis,stretch=true)
      super(in_names,out_names)
      @div=div
      @stretch=stretch
      @axis=axis
      @name='SplitEq'
    end

    def format_params()
      # sample param:
      # 'divs:r0.3,0.5,0.2;axis:0;repeat:111'
      params="div:#{@div};axis:#{@axis};stretch:#{@stretch}"
      return params
    end

    def set_params(paramStr)
      p "seting param:#{paramStr}"
      paramsStrs=paramStr.split(';')
      in_names=paramsStrs[0].split(':')[1]
      if in_names==nil
        @in_names=''
      else
        @in_names=in_names.split(',')
      end

      out_names=paramsStrs[1].split(':')[1].split(',')
      @div=paramsStrs[2].split(':')[1].to_f
      @axis=paramsStrs[3].split(':')[1].to_i
      if paramsStrs[4].split(':')[1]=='true'
        @stretch=true
      else
        @stretch=false
      end
    end




    def execute()
      @unused=[]
      @outputs=[]

      return if @inputs==nil or @inputs.size==0 or @div==nil

      for g in @inputs
        g=SG::Rule._extract_geo(g)
        if @in_names.include? g.name or @in_names.size==0
          geos=SG.split_equal(g, @div, @stretch, @axis)
          assign_names(geos)
          @outputs+=geos if geos!=nil and geos.size>0
        else
          @unused<<g
        end
      end

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
      @divstring=divs
      @divs,@mode=_interpret_divs(divs)
      # @in_names=in_names.split(',')
      # @out_names=out_names.split(',')
      @repeat=repeat
      @axis=axis
      @name='Split'
      @inverse=inverse
    end

    def format_params()
      # sample param:
      # 'divs:r0.3,0.5,0.2;axis:0;repeat:111'
      divsStr=@divs.to_s
      divsStr='r'+divsStr if @mode=='ratio'
      params="divs:#{divsStr};axis:#{@axis};repeat:#{@repeat}"

      return params
    end

    def set_params(paramStr)
      paramsStrs=paramStr.split(';')
      in_names=paramsStrs[0].split(':')[1]
      if in_names==nil
        @in_names=''
      else
        @in_names=in_names.split(',')
      end
      @out_names=paramsStrs[1].split(':')[1].split(',')
      divsStr=paramsStrs[2].split(':')[1]
      @divs,@mode=_interpret_divs(divsStr)
      @axis=paramsStrs[3].split(':')[1].to_i
      @repeat=paramsStrs[4].split(':')[1].to_i
    end


    def mode()
      return @mode
    end

    def execute()
      return if @inputs==nil or @inputs.size==0 or @divs==nil
      repeat=@repeat
      inverse=@inverse
      @outputs=[]
      @unused=[]
      count=0
      for g in @inputs
        g=SG::Rule._extract_geo(g)
        if @in_names.include? g.name or @in_names.size==0
          if @mode=='length'
            geos=SG.split_length(g, @divs.clone, @axis, repeat, inverse)
          elsif @mode =='ratio'
            # p "split ratio divs=#{@params}"
            geos=SG.split_ratio(g, @divs.clone, @axis, repeat, inverse)
          else
            p "undefined mode:#{@mode}"
            raise ScriptError
          end
          if geos!=nil and geos.size!=nil and geos.size>0
            assign_names(geos)
            # txt="#{g.name}: "
            # geos.each{|g|
            #   txt+="n:#{g.name} s:#{g.size[0].to_m.round}"
            # }
            # p txt
            @outputs+=geos
          end
        else
          @unused<<g
        end
        count+=1
      end

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
        p "sgi invalidating: #{s}"
        for g in @grammars
          invalidated_grammars<<g if g.inputs.include? s and  !invalidated_grammars.include? g
          # g.execute if g.inputs.include? s
        end
      end
    end # for s

    for g in invalidated_grammars
      g.execute
      g.update_model
      # g.update_individual_model
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

def sgtest1
  sel=Sketchup.active_model.selection
  for g in sel
    sgo=g.create_sgo
    # splits=SG.split_length(sgo,[0.2,0.4])
    splits=SG.split_ratio(sgo,[0.5])
    for g in splits
      g.add_individual_model()

    end
  end
end

def sgtest
  $sgi=SGInvalidator.new

  $g1=SGRules::Grammar.create()
  $g1.add(SGRules::FlipAxis.new('','A',[1,-1,1]))
  # $g1.add(SGRules::Split.new('A','B,A','r0.5',0))
  $g1.add(SGRules::SplitEqual.new('A','A,B',4,0,true))
  $g1.add(SGRules::FlipAxis.new('B','A',[-1,1,1]))
  $g1.add(SGRules::Split.new('A','cord,A','1',0,Repeat::None))
  $g1.add(SGRules::Split.new('A','bath,main','3',1,Repeat::None,true))
  # $g1.execute()
  # $g1.update_model()

  $g2=SGRules::Grammar.create()
  # $g2.add(SGRules::FlipAxis.new('','A',[1,-1,1]))
  $g2.add(SGRules::Split.new('','A,B','r0.5',0,Repeat::None))
  $g2.add(SGRules::RotAxis.new('B','A',-1))
  $g2.add(SGRules::Split.new('A','C,D','r0.3',1))
  # $g2.add(SGRules::Split.new('A','cord,A','1',0,Repeat::None))


  $g3=SGRules::Grammar.create()
  $g3.add(SGRules::RotAxis.new('','A',1))

  $g4=SGRules::Grammar.create()
  $g4.add(SGRules::SplitEqual.new('','A,B',4,0,true))
  $g4.add(SGRules::Split.new('B','C,D','r0.3',1,Repeat::None))
  # SG::SGUI.open($g4)
  # SG::SGUI.create_ui()


  $sgi.add_grammar $g4
  $sgi.add_range($g4.inputs)
  $sgi.invalidate

  $sgi.reset_timer

  nil
end

def printreflection
  sel=Sketchup.active_model.selection
  for g in sel
    sgo=g.create_sgo
    af=sgo.reflection.clone
    tf=sgo.trans_reflection.clone
    mf=[1,1,1]
    3.times{|i| mf[i]=af[i]*tf[i]}

    sgo.reflection=[1,-1,1]
    raf=sgo.reflection.clone
    rtf=sgo.trans_reflection.clone
    rmf=[1,1,1]
    3.times{|i| mf[i]=af[i]*tf[i]}


    p "af:#{af},tf:#{tf},mult#{mf} | raf:#{raf}, rtf:#{rtf}, rmulf:#{rmf}"
  end
end
