
module ArchProto
  class HTMLDialogWrapper
    # 这个静态变量管理所有创建过的窗口
    @@created_objects=Hash.new
    def HTMLDialogWrapper.created_objects
      @@created_objects
    end

    def HTMLDialogWrapper.get(name)
      if @@created_objects.key?(name)
        #TODO: 检查拿出来的dialog是否正确
        # 如果不正确就要return nil
        return @@created_objects[name]
      end
      return nil
    end

    def HTMLDialogWrapper.set(name,dialog)
      if @@created_objects.key?(name)
        obv=@@created_objects[name]
        obv.close
        begin
          Sketchup.active_model.selection.remove_observer(obv)
        rescue
          p 'nothing to remove'
        end
      end
      @@created_objects[name] = dialog
    end

    #查询一个窗口是否被创建过
    def HTMLDialogWrapper.created?(dialog)
      # TODO: 检查是否还正确
      # 如果不正确就删除item
      return @@created_objects.include?dialog
    end

    # 创建时会加入到静态数据列已做管理
    def initialize(name)
      @name=name
      # dangerous recursion
      # ArchProto::WebDialogWrapper.set(name, self)
      @@created_objects[name] = self
      if $SELECTION_OBSERVER_SINGLE != nil
        flag=Sketchup.active_model.selection.remove_observer($SELECTION_OBSERVER_SINGLE)
      end
      p "remove existing selection observer:#{flag}"
      $SELECTION_OBSERVER_SINGLE = WebDialogSelectionObserver.new(self)
      Sketchup.active_model.selection.add_observer( $SELECTION_OBSERVER_SINGLE )
      # ObserverManager.Add(Sketchup.active_model.selection,WebDialogSelectionObserver.new(self))
      # do somthing
    end

    #----------------- instance ----------------------

    # 切换显隐叫toggle
    @visible=false
    def toggle()
      @visible = !@visible
    end

    # 继承时无需写super,因为需要按需判断和设置@visible状态
    def open()
      @visible=true
    end

    # 继承时无需写super,因为需要按需判断和设置@visible状态
    def close()
      #override
      @visible=false
    end


    def onSelectionCleared(selection)
      close
    end

    def onSelectionBulkChange(selection)
    end
  end # end class

  class WebDialogSelectionObserver < Sketchup::SelectionObserver
    def initialize(dialog)
      @host=dialog
    end

    def onSelectionCleared(selection)
      return if @host == nil
      @host.onSelectionCleared(selection)
    end

    def onSelectionBulkChange(selection)
      return if @host == nil
      @host.onSelectionBulkChange(selection)
    end


  end

end
