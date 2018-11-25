class DataRecorder
  attr_accessor :host
  attr_accessor :gp
  attr_accessor :excel_conduit
  attr_accessor :dlg
  attr_accessor :worksheet
  attr_accessor :workbook

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

    workbook='DataRecorder.xlsx'
    connect_excel(workbook)

  end

  def DataRecorder.create_from_selection()
    g=Sketchup.active_model.selection[0]
    dr=DataRecorder.new(g)
    return dr
  end

  def connect_excel(workbook)
    @excel_conduit = ArchUtil::ExcelConduit.new()
    @excel_conduit.connect_dynamic(workbook)
    @workbook=@excel_conduit.work_book
  end



  def iter_dimension(rangex=[30,150],rangey=[30,100],stepx=3,stepy=3,sheet='Sheet1')
    # SKETCHUP_CONSOLE.hide

    xcount=((rangex[1]-rangex[0])/stepx).to_i
    ycount=((rangey[1]-rangey[0])/stepy).to_i

    ttl_max=xcount*ycount

    count=0
    $drtimer=UI.start_timer(0.1,true){
      begin
        if count>=ttl_max
          UI.stop_timer($drtimer)
          SKETCHUP_CONSOLE.show
        end

        itrX = count % xcount
        itrY = (count / xcount).floor
        itrX+=1
        itrY+=1


        i=count
        w=rangex[0]+(itrX*stepx)
        d=rangey[0]+(itrY*stepy)
        size=[w,d,30]

        index=ArchUtil.get_excel_cell_index(itrX,itrY)
        worksheet=@excel_conduit.work_book.WorkSheets(sheet)
        p "i=#{i} x=#{itrX} y=#{itrY} index=#{index}"


        Op_Dimension.set_bd_size(@gp,size)
        Sketchup.active_model.start_operation("invalidate",true)
        o=@host.invalidate()
        Sketchup.active_model.commit_operation



        #get score
        score=0
        scores=@gp.attribute_dictionary("PrototypeScores").to_a
        for s in scores
          score += s[1][0]
        end
        p ">>>>>>SCORE=#{score}"
        worksheet.Range(index).Value=score.to_s

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
