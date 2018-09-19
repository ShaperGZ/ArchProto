$ObserverManager = Hash.new if $ObserverManager == nil

$nameMatch=[
    Sketchup::EntitiesObserver,
    Sketchup::InstanceObserver,
    Sketchup::EntityObserver,
    Sketchup::SelectionObserver
    ]
# $nameMatch=['a','b','c','d']



class ObserverManager
  def self.Print()
    print self.Format()
  end

  def self.Format()
    # name       | ens | ins | ent | sel |
    #-------------------------------------
    # selection  | 0   | 0   | 0   | 1   |
    # 321232     | 2   | 1   | 0   | 0   |
    # 432554     | 2   | 2   | 0   | 0   |
    #
    output ="┌"+"─"*35+"┬─────┬─────┬─────┬─────┐\n"
    output+="│#{name.ljust(35)}│ ens │ ins │ ent │ sel │\n"
    output+="├"+"─"*35+"┼─────"*4+"┤\n"
    # output+="-"*output.size + "\n"
    $ObserverManager.each{|k,v|
      txt = "│#{k.to_s.ljust(35)}│"
      counts=self.Count(v)
      counts.each{|c|
        txt += " #{c.to_s.ljust(2)}  │"
      }
      output += txt + "\n"
    }
    output +="└"+"─"*35+"┴─────┴─────┴─────┴─────┘\n"
    output += "\n"
    return output;
  end

  def self.Count(observers)
    counts=[0]*$nameMatch.size
    observers.each{|ob|
      for i in 0..$nameMatch.size-1
        typename=$nameMatch[i]
        if ob.is_a? typename
          counts[i]+=1
          break
        end
      end
    }
    return counts
  end

  def self.Add(subject,ob)
    if !$ObserverManager.key? subject
      $ObserverManager[subject] = []
    end
    $ObserverManager[subject] << ob
    subject.add_observer(ob)

    self.Print()
  end

  def self.Add_(gp, id)

    if !$ObserverManager.key? gp
      $ObserverManager[gp] = []
    end
    $ObserverManager[gp] << id
    self.Print()
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
    $ObserverManager = Hash.new
  end
end


