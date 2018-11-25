require 'win32ole'
$excel
$workbook
module ArchUtil
  class ExcelConduit
    attr_accessor :excel
    attr_accessor :work_book
    attr_accessor :work_sheet
    @excel=nil
    @work_book=nil
    @work_sheet=nil
    @work_sheets=nil
    def initialize()
    end

    def connect_dynamic(workbook)
      # sample usage
      # excel_conduit = ArchUtil::ExcelConduit.new()
      # workbook='PlayGround.xlsx'
      # excel_conduit.connect_dynamic(workbook,sheet='InstanceData')
      # excel_conduit.connect_dynamic(workbook,sheet='StaticData')
      begin
        p "Trying to connect to workbook: #{workbook}"
        @excel = WIN32OLE.connect("excel.application")
        $excel=@excel
        p "@excel=#{@excel}"
        @work_book = @excel.Workbooks(workbook)
        $workbook=@work_book
        p "@work_book=#{@work_book} "
        #@work_sheet = @work_book.WorkSheets(sheet)
        #p "已连接到#{@work_sheet}"
      rescue
        p $ERROR_INFO
       p "failed to connect to excel #{workbook}"
      end



    end

    def update_matrix(data, sheet, clear_size_h=80,clear_size_w=8)  #更新整个execel
      if !@work_sheet.key? sheet or @work_sheet[sheet]==nil
        p "excel is not connected to a work sheet: #{sheet}"
        return
      end
      work_sheet=@work_sheet
      p "work sheet = #{work_sheet}"
      count=0
      if data!=nil and data.size>0
        row_indices=[*?a..?z]
        count=data.keys.size
        data_width=data[data.keys[0]].size
      end

      # iterate row
      for i in 1..clear_size_h
        # guid is the first item in a row
        if count >0 and (i-1) < count
          key=data.keys[i-1]
          if key==nil
            p "!key == nil ; data=#{data}"
            return
          end
          if key.class == Sketchup::Group
            work_sheet.Range("a"+i.to_s).Value= key.guid.to_s
          else
            work_sheet.Range("a"+i.to_s).Value= key
          end

          # iterate columns on each row
          for j in 0..data_width-1
            if j< row_indices.size
              index=row_indices[j]
              if i<=count
                value=data[key][j]
              else
                value=""
              end
              work_sheet.Range(index+i.to_s).Value= value
            end # end if j<
          end # end for j

        else
          #p 'else'
          work_sheet.Range("#{i}0:#{i}").Value=""
        end # end for i-1

      end # end for i
    end #end def


  end # end class ExcelConduit

  def ArchUtil.get_excel_col_index(x)
    x-=1
    alphabets=[*?a..?z]
    prefix=(x/alphabets.size).floor-1

    index=''
    if prefix>=0
      index+=alphabets[prefix]
      prefix-=alphabets.size
      while prefix>alphabets.size
        index+=alphabets[prefix]
        prefix-=alphabets.size
      end
    end
    suffix=x%alphabets.size
    index+=alphabets[suffix]
    return index
  end

  def ArchUtil.get_excel_cell_index(x,y)

    index=self.get_excel_col_index(x).to_s+y.to_s
    return index
  end
end