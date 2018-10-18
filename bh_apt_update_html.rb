class BH_Apt_UpdateHTML < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    #p 'f=initialized constrain face'
    super(gp,host)
  end

  def invalidate()
    wd=WD_Interact.singleton

  end
end