class BH_ReadAttrToMemory < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    super(gp,host)
  end

  def onClose(e)
    super(e)
    # invalidate
  end

  def onChangeEntity(e, invalidated)
    return if not invalidated[2]
    super(e, invalidated)
    invalidate
  end

  def invalidate()
    p 'adding attr to memory'
    @host.read_attributes_to_memory()
  end
end