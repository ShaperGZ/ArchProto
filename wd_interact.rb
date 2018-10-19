module ArchProto
  def self.open_interaction (reset=false)
    dialog=WD_Interact.singleton
    dialog.open
  end
end

class WD_Interact < ArchProto::HTMLDialogWrapper
  attr_accessor :subjectGP
  attr_accessor :subjectBB
  attr_accessor :subjectIT
  attr_accessor :dlg
  attr_accessor :state_checkboxes

  @@singleton=nil
  def self.singleton(reset=false)
    if @@singleton==nil or reset == true
      @@singleton=WD_Interact.create_or_get(WD_Interact,name)
    end
    return @@singleton
  end

  def self.create_or_get(name,reset)
    dialog=ArchProto::HTMLDialogWrapper.get(WD_Interact.name)
    if dialog == nil or reset
      name=WD_Interact.name
      dialog=WD_Interact.new(name)
    end
    return dialog
  end

  def initialize(name)
    super(name)
    @subjectGP=nil
    @subjectBB=nil
    @subjectIT=nil
    @dlg=nil
    @htl_rm=[]
  end

  def open(reset=false)
    return if @visible
    # Definitions.load()
    # @dlg = UI::HtmlDialog.new("AttributeInfo", true, "Information", 739, 641, 150, 300, true)
    p "@dlg==nil#{@dlg == nil} reset=#{reset}"
    if @dlg == nil or reset==true
      @dlg = UI::HtmlDialog.new({
                                    :scrollable => true,
                                    :resizable => true,
                                    :min_width => 150,
                                    :min_height => 300,
                                    :style => UI::HtmlDialog::STYLE_DIALOG
                                })
      #file = File.join(__dir__,"/dialogs/dialog_interact.html")
      file=ArchProto.get_file_path('dialog/dlg_proto.html')
      p "file=#{file}"
      @dlg.set_url(file)
    end

    @dlg.show
    @dlg.add_action_callback("checkbox_clicked"){|dialog,params|
      p " [!] checkbox clicked"
      params=params.split(",")
      params[1]=params[1]
      p params
      checkbox_value(*params)
    }
    # p 'wd.interact adding action callback'
    # @dlg.add_action_callback("updateAttr"){|dialog,params|update_attr(params)}
    # @dlg.add_action_callback("normal_mode"){|dialog,params|normal_mode()}
    # @dlg.add_action_callback("unit_mode"){|dialog,params|unit_mode()}
    # @dlg.add_action_callback("update_all"){|dialog,params|update_all(params)}
    # @dlg.add_action_callback("def_reload"){|dialog,params|def_reload(params)}
    @dlg.set_on_closed{close()}

    @visible=true

    #assign slection manuals
    # @dlg.execute_script("document.getElementById('id2').options.add(new Option('#{c}','#{c}'))")
    # fill_dgl_unit_prototypes()

    # onSelectionBulkChange(Sketchup.active_model.selection)
  end

  def close()
    @dlg == nil
    @visible = false
  end

  # gets the checkbox value if the value is passed
  # returns the checkbox value if the value is omitted
  def checkbox_value(id,value=nil)
    # p "checkbox_value(id=#{id} value=#{value}"
    @state_checkboxes=Hash.new if @state_checkboxes == nil
    if !@state_checkboxes.keys.include? id
      @state_checkboxes[id]=nil
    end
    return @state_checkboxes[id] if value==nil
    @state_checkboxes[id] = value
    p @state_checkboxes
    compositions=@state_checkboxes.clone
    p("composition.class=#{compositions.class} : #{compositions}")
    gp=@subjectGP
    gp.set_attribute("OperableStates","composition",compositions.to_a)
    @subjectBB.invalidate()
  end

  def onSelectionBulkChange(selection)
    p "onSelectionBulkChange"
    if selection.size != 1
      return
    end
    entity = selection[0]

    if entity.class != Sketchup::Group or entity.get_attribute("BuildingBlock","bd_ftfh") == nil
      p "selection is not a smart object"
      #_send_to_html("selection is not a smart object")
      return
    end

    p "selected a smart object #{entity}"

    @subjectGP=entity
    @subjectBB = Proto_Apt.create_or_get(entity, 'Params.csv', false)
    p "got @subjectBB=#{@subjectBB}"
    # @subjectIT=@subjectBB.get_updator_by_type(BH_Interact)
    # @subjectIT.set_dlg(@dlg)
    # @subjectIT.update_dialog_data()

    # id=ArchUtil.short_id(@subjectGP)
    # size=Op_Dimension.get_size(@subjectGP)
    # msg="'#{id} #{size}'"
    set_web_param(@subjectBB)
    # fill_dgl_unit_prototypes(false)
    #set_un_prototype()
  end


  def fill_dgl_unit_prototypes(fill_html=true)
    return if @subjectGP == nil
    # @htl_rm=[]
    # Definitions.defs.keys.each{|k|
    #  if k.include?("htl_rm_")
    #    p "recognizing #{k}"
    #    @htl_rm<<k
    #    @dlg.execute_script("document.getElementById('un_prototype').options.add(new Option('#{k}','#{k}'))")
    #  end
    # }
    # set_un_prototype()
    # #assign default
    # #
  end


  def execute_script(msg)
    @dlg.execute_script(msg)
  end

  def set_web_param(obj)
    gp=obj.gp

    comps=["double","L-shape","U-shape","O-shape"]
    checked=gp.get_attribute("OperableStates","composition")

    #checks=Hash.new
    checks=""
    comps.each{|k|
      flag="false"
      k=k.split('_')[0]
      checked.each{|c|
        if c[0].include? k
          flag="true";
          break;
        end
      } if checked != nil
      checks += "#{k}=>#{flag},"
    }
    msg="set_checkboxes('#{checks}')"
    p ">>>> #{msg}"
    execute_script msg

    # key=ArchUtil.short_id(gp)
    # value=Op_Dimension.get_size(gp)
    # msg="set_param('#{key}',#{value})"
    # # p "send message #{msg}"
    # @dlg.execute_script(msg)
  end

  def set_un_prototype()
    proto=@subjectGP.get_attribute("BuildingBlock","un_prototype")
    if proto == nil
      @subjectGP.set_attribute("BuildingBlock","un_prototype",@htl_rm[0]) if @subjectGP!=nil
    else
      #todo set html value
    end
  end

  def normal_mode()
    p 'switching to normal mode'
    return if @subjectGP==nil or @subjectBB ==nil
    generator=@subjectBB.get_updator_by_type(BH_Generator)
    generator.enable(Generators::Gen_Units,true,level="level2")
  end

  def unit_mode()
    p 'switching to unit mode'
    return if @subjectGP==nil or @subjectBB ==nil
    generator=@subjectBB.get_updator_by_type(BH_Generator)
    generator.enable(Generators::Gen_Units,false,level="level2")
  end

  def update_attr(params)
    # p "wd_interact.update_attr #{params}"
    trunks=params.split('|')
    key=trunks[0]
    value=_convert_num_param(trunks[1])

    gp=@subjectGP
    gp.set_attribute("BuildingBlock",key,value)

    # update size

    w=gp.get_attribute("BuildingBlock","bd_width")
    d=gp.get_attribute("BuildingBlock","bd_depth")
    h=gp.get_attribute("BuildingBlock","bd_height")

    size=[w,d,h]
    BH_Interact.set_bd_size(gp,size)
  end

  def update_all(params)
    # some of the params are string params while most others are numeric
    str_params={"un_prototype"=>[]}
    p "update all attr from wd message= #{params}"
    gp=@subjectGP
    trunks=params.split(',')
    trunks.each{|pair|
      pair_items=pair.split(':')
      key=pair_items[0]
      val=pair_items[1]

      if str_params.keys.include? key
        gp.set_attribute("BuildingBlock",key,val)
      else
        gp.set_attribute("BuildingBlock",key,_convert_num_param(val))
      end
    }

    w=gp.get_attribute("BuildingBlock","bd_width")
    d=gp.get_attribute("BuildingBlock","bd_depth")
    h=gp.get_attribute("BuildingBlock","bd_height")
    size=[w,d,h]
    update=BH_Interact.set_bd_size(gp,size)

    bd=@subjectBB
    bd.invalidate()
    # if not update
    #   bd=BuildingBlock.created_objects[gp]
    #   bd.invalidate(true)
    # end
  end


  def def_reload(param)
    p "loading definition..."
    Definitions.reload()
    p "def lodaded: #{Definitions.defs}"
  end

  def _convert_num_param(val)
    trunks=val.split(',')
    if trunks.size==1
      return val.to_f
    else
      result=[]
      trunks.each{|n| result<<n.to_f}
      return result
    end
  end
end