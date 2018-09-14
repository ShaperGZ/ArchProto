$ObserverManager = Hash.new if $ObserverManager == nil

class ObserverManger
  def self.Add(gp, id)
    if $ObserverManager.key? gp
      $ObserverManager[gp] << id
    else
      $ObserverManager[gp] = []
    end
  end

  def self.RemoveAll(gp = nil)
    if gp != nil
      gps = [gp]
    else
      gps = $ObserverManager.keys.to_a
    end

    gps.each {|ent|
      if $ObserverManager.key? ent
        obs = $ObserverManager[ent]
        obs.each {|ob|
          ent.remove_observer(ob)
        }
      end
    }
  end
end


