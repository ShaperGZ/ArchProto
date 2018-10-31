class BH_Update_Web_Scores < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    super(gp,host)
  end

  def invalidate()
    wd=WD_Interact.singleton
    scores=@gp.attribute_dictionary("PrototypeScores").to_a
    wd.update_web_scores(scores)
    wd.set_web_attribute_table(@gp)

  end
end