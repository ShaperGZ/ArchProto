$ObserverManager = Hash.new if $ObserverManager == nil

$nameMatch=[
    Sketchup::EntitiesObserver,
    Sketchup::EntityObserver,
    Sketchup::InstanceObserver,
    Sketchup::SelectionObserver
    ]


class ObserverManger
  def self.Print()
    print self.Format()
  end

  def self.Format()
    # name       | ens | ent | ins | sel |
    #-------------------------------------
    # selection  | 0   | 0   | 0   | 1   |
    # 321232     | 2   | 1   | 0   | 0   |
    # 432554     | 2   | 2   | 0   | 0   |
    #

    output=""
    $ObserverManager.each{|k,v|
      txt = "#{k} "
      counts=self.Count(v)
      counts.each{|c|
        txt += " | #{c} "
      }
      output += txt + "\n"
    }
    return output;
  end

  def self.Count(observers)
    counts=[0]*nameMatch.size
    observers.each{|ob|
      i=$nameMatch.index(ob.class)
      if i>=0 and i<$nameMatch.size
          counts[i]+=1
      end
    }
    return counts
  end

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


