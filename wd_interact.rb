module ArchProto
  def self.open_interaction (reset=false)
    dialog=WD_Interact.singleton
    dialog.open reset
  end
end

class WD_Interact < ArchProto::HTMLDialogWrapper
  attr_accessor :subjectGP
  attr_accessor :subjectBB
  attr_accessor :subjectIT
  attr_accessor :dlg
  attr_accessor :state_checkboxes

  def self.singleton(reset=false)
    begin
      if @@singleton==nil or reset == true
        @@singleton=WD_Interact.create_or_get(WD_Interact,name)
      end
    rescue
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
    if @dlg == nil or reset==true
      @dlg = UI::HtmlDialog.new({
                                    :scrollable => true,
                                    :resizable => true,
                                    :min_width => 300,
                                    :min_height => 800,
                                    :style => UI::HtmlDialog::STYLE_DIALOG
                                })
      #file = File.join(__dir__,"/dialogs/dialog_interact.html")
      file=ArchProto.get_file_path('dialog/dlg_proto.html')
      p "file=#{file}"
      @dlg.set_url(file)
      @dlg.show
      @dlg.add_action_callback("set_gp_attributes"){|dialog,param|
        p 'execute callback: set_gp_attributes'
        wd=WD_Interact.singleton
        gp=wd.subjectGP
        bb=wd.subjectBB

        table="BuildingBlock"
        update_table_from_string_params(table,param)
      }
      @dlg.add_action_callback("set_check_boxes"){|dialog,params|
        p 'execute callback: set_check_boxes'
        p "set_check_boxes params:#{params}"
        wd=WD_Interact.singleton
        gp=wd.subjectGP
        vals=[]
        params=params.split(',')
        for p in params
          k,v=p.split('=>')
          if v=='true' or v=='True'
            v=true
          else
            v=false
          end
          vals<<[k,v]
        end
        p vals
        gp.set_attribute("OperableStates","composition",vals)
        invalidate_model
      }
      @dlg.add_action_callback("update_model_table"){|dialog,params|
        p 'execute callback: update_model_table'
        key,vals=params.split('|')
        update_table_from_string_params(key,vals)
      }
      @dlg.add_action_callback("log"){|dialog,text|
        p '-[LOG FROM UI]-:'+text
      }
      @dlg.add_action_callback("set_view_mode_norm"){|dialog,params| set_view_mode_normal}
      @dlg.add_action_callback("set_view_mode_ornt"){|dialog,params| set_view_mode_orientation}
      @dlg.add_action_callback("set_view_mode_unit"){|dialog,params| set_view_mode_unit}


    elsif !@dlg.visible?
      @dlg.show
    end
  end

  def close()
    p "dialog close action"
    @dlg == nil
    @visible = false
  end

  def formatValue(v)
    if v.include? ','
      v.gsub('"','')
      v.gsub('[','')
      v.gsub(']','')
      items=v.split(',')
      arrV=[]
      items.each{|i|
        arrV<< i.to_f
      }
      v=arrV
    else
      v=v.to_f
    end
    return v
  end

  def invalidate_model()
    wd=WD_Interact.singleton
    gp=wd.subjectGP
    bb=wd.subjectBB

    sizex=gp.get_attribute("BuildingBlock","bd_width")
    sizey=gp.get_attribute("BuildingBlock","bd_depth")
    sizez=gp.get_attribute("BuildingBlock","bd_height")
    size=[sizex,sizey,sizez]
    Op_Dimension.set_bd_size(gp,size)
    bb.invalidate()
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
    # @subjectBB.invalidate()
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
    set_web_param(@subjectBB)
  end

  def execute_script(msg)
    @dlg.execute_script(msg)
  end

  def update_table_from_string_params(table,params)
    p "wd_interact.update_table_from_string_aparams"
    wd=WD_Interact.singleton
    gp=wd.subjectGP

    vals=params.split(';')
    vals.each{|p|
      k,v=p.split('=>')
      v=formatValue(v)
      gp.set_attribute(table,k,v)
    }
    invalidate_model
  end

  def set_view_mode_normal()

  end

  def set_view_mode_orientation()

  end

  def set_view_mode_unit()

  end

  def set_web_param(obj)
    gp=obj.gp

    # /////////////////////////
    # set the UI check box states
    # /////////////////////////
    comps=["double","L-shape","U-shape","O-shape"]
    checked=gp.get_attribute("OperableStates","composition")

    #checks=Hash.new
    checks=""
    comps.each{|k|
      flag="false"
      k=k.split('_')[0]
      checked.each{|c|
        if c[0].include? k and c[1]
          flag="true";
          break;
        end
      } if checked != nil
      checks += "#{k}=>#{flag},"
    }
    msg="set_checkboxes('#{checks}')"
    p ">>>> #{msg}"
    execute_script msg

    # /////////////////////////
    # update BuildingBox Table
    # /////////////////////////
    set_web_attribute_table(@subjectGP)

    # ////////////////////////
    # update score
    # ///////////////////////
    scores=gp.attribute_dictionary("PrototypeScores").to_a
    update_web_scores(scores)
  end

  def set_web_attribute_table(gp)
    strDataBB=ArchUtil.attribute_dictionary_to_s(gp,"BuildingBlock")
    msg="regenAttributeTable('#{strDataBB}')"
    execute_script msg
  end

  def set_gp_attributes(strdata)
    #TODO: for strdata from HTML dialog
    trunks=strdata.split(';')
    data={}
    trunks.each{|i|
      k,v=i.split("=>")
      data[k]=v
    }

    size=[data['bd_width'],data['bd_depth'],data['bd_height']]
    Op_Dimension.set_bd_size(@subjectGP,size)
    @subjectBB.invalidate()
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

  def update_web_scores(dataArr)
    # sample source data:
    # [ ["Efficiency",0.8], ...]
    # ---------------------------
    # sample target data:
    # "Efficiency=>0.8, ..."
    #
    txtData=""
    txtDataDscr=""
    dataArr.each{|d|
      k=d[0]
      v=d[1][0]
      s=d[1][1]
      txtData+= "#{k}=>#{v},"
      txtDataDscr+="#{k}=>#{s},"
    }

    msg="setScoreValues('#{txtData}')"

    execute_script msg

    msg="setScoreDescriptions('#{txtDataDscr}')"
    execute_script msg

    #set score descriptions


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