module ArchUtil
  class ColorScale
    attr_accessor :colors
    attr_accessor :domain

    def initialize(colors,domain)
      @colors=colors
      @domain=domain
    end

    def get(value)
      return ArchUtil.colorScale(@colors,@domain,value)
    end
  end

  def ArchUtil.colorScale(colors,domain,value,divisions=nil)
    # colors=[[r,g,b],[r,g,b]]
    # domain=[float,float]
    # value=float


    min=domain[0].to_f
    max=domain[-1].to_f

    return colors[-1] if value>=max
    return colors[0] if value<=min

    mag=max-min
    count=colors.size-1
    section_size=mag/count.to_f

    trim=value%section_size
    section=(value/section_size).floor
    # r,g,b
    # 0,2,4
    # i=3
    # section=(3/2).floor=1
    color1=colors[section]
    color2=colors[section+1]
    p "color1=#{color1} color2=#{color2} section=#{section} trim=#{trim}"
    t=trim/section_size.to_f
    return ArchUtil.get_color_t(color1,color2,t)
  end

  def ArchUtil.get_color_t(color1,color2,t)
    if !t or t<0 or t>1
      raise "t must in between 0 and 1, got #{t}"
    end
    newcolor=[]
    color1.size.times{|i|
      newcolor[i]=color1[i]+((color2[i]-color1[i])*t)
    }
    return newcolor
  end
end