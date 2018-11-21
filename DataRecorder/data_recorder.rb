class DataRecorder
  attr_accessor :host
  attr_accessor :gp
  attr_accessor :excel_conduit
  attr_accessor :dlg

  def initialize(obj)
    if obj.is_a? Sketchup::Group
      @gp=obj
      @host=Proto_Apt.created_objects[@gp]
    else
      if obj.is_a? Proto_Apt
        @host=obj
        @gp=obj.gp
      end
    end

    workbook='DataRecord.xlsx'
    connect_excel(workbook)
    open
  end

  def DataRecorder.create_from_selection()
    g=Sketchup.active_model.selection[0]
    dr=DataRecorder.new(g)
    return dr
  end

  def connect_excel(workbook)
    @excel_conduit = ArchUtil::ExcelConduit.new()
    @excel_conduit.connect_dynamic(workbook,sheet='InstanceData')
  end

  def open
    dlg=UI::HtmlDialog.new()
    path=ArchProto.get_file_path('DataRecorder/DataRecorder.html')
    dlg.set_url(path)
    dlg.show
    dlg.add_action_callback("resize_bd"){|dialog,param|
      resize_bd(param)
    }
    @dlg=dlg
    return dlg
  end

  def resize_bd(param)
    p "on resize_bd param=#{param}"
    params=param.split(',')
    p "params=#{params}"
    size=[1,1,1]
    for i in 0..2
      size[i]=params[i].to_f
    end
    p "size=#{size}"
    Op_Dimension.set_bd_size(@gp,size)
    @host.invalidate()
  end

  def iter_test()
    SKETCHUP_CONSOLE.hide

    count=0
    $drtimer=UI.start_timer(0.1,true){
      begin
        if count>40
          UI.stop_timer($drtimer)
          SKETCHUP_CONSOLE.show
        end

        i=count
        w=30+(i*3)
        size=[w,30,30]
        Op_Dimension.set_bd_size(@gp,size)
        Sketchup.active_model.start_operation("invalidate",true)
        o=@host.invalidate()
        Sketchup.active_model.commit_operation

        count+=1
      rescue
        p $!.message
        p $!.backtrace
        UI.stop_timer($drtimer)
        SKETCHUP_CONSOLE.show
      end
    }
  end

end

$dr=DataRecorder.create_from_selection
