class Switchers

end

class SW_Composition < Switchers
  # input a group, and from the group determine what updator to return
  def get(gp)
    # size
    profile=ArchProto.profiles['sw_composition']
    bd_width=gp.get_attribute("BuildingBlock","bd_width")
    bd_depth=gp.get_attribute("BuildingBlock","bd_depth")
    un_depth=gp.get_attribute("BuildingBlock","un_depth")
    un_width=gp.get_attribute("BuildingBlock","un_width")
    p_un_width=gp.get_attribute("BuildingBlock","p_un_width")
    p_un_depth=gp.get_attribute("BuildingBlock","p_un_depth")
    crd_width = gp.get_attribute("BuildingBlock","crd_width")
    infinity=10000000


    availables=[]
    b=binding

    for i in 1..profile.size
      line=profile[i]
      break if line==nil
      if line.size==5
        subject=eval(line[0])

        max=eval(line[1],b)
        min=eval(line[2],b)

        addi=line[3]
        if addi=='nil'
          addi=true
        else
          addi=availables.include? addi
        end
        #p "i=#{i},  min=#{min} < subject=#{subject} < max=#{max}, addi=#{addi} avail=#{line[4]}"
        if subject>min and subject<=max and addi
          availables<<line[4]
        end
      end # if line.size
    end # for i

    # p "availables=#{availables}"
    return availables

  end
end