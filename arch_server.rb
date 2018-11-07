require 'sketchup.rb'
require 'socket'

def _get_abs_geo_size(geo)
    s=[1,1,1]
    for i in 0..2
        s[i]=geo.size[i] * geo.reflection[i]
    end
    return s
end

class Encriptor
    def Encriptor.enable_update(flag)
        ArchServer.puts("ENABLE_UPDATE|#{flag}")
    end

    def Encriptor.deleteRange(geos)
        message = "DELETE_RANGE|"
        for i in 0..geos.size-1
            geo=geos[i]
            message +="#{geo.guid}"
            message +="," if i<geos.size-1
        end
        ArchServer.puts(message);
    end

    def Encriptor.delete(entity)
        puts entity.guid
        message = "DELETE|"+entity.guid
        ArchServer.puts(message)
    end

    def Encriptor.set_color(color)
        # sample data
        # 'SET_COLOR|225,100,0'
        message="SET_COLOR|#{color.to_s[1..-2]}"
        ArchServer.puts(message)
    end

    def Encriptor.abs_box(box)
        # sample data:
        # 'ABS_BOX|guid|pos|size|rotation
        # 'ABS_BOX|a23f56hd123|0,0,0|10,10,5|30'

        size=_get_abs_geo_size(box).to_s[1..-2]

        boxpos=box.position
        # the position has to be converted to meters first
        pos=[0,0,0]
        for i in 0..2
            pos[i]=boxpos[i].to_m
        end
        pos=pos.to_s[1..-2]
        size=size.gsub('m','')
        pos=pos.gsub('m','')
        msg="ABS_BOX|#{box.guid}|#{pos}|#{size}|#{box.rotation}"
        p msg
        ArchServer.puts(msg)
    end
end

class Server
    attr_accessor :tcpserver
    attr_accessor :client
    def connect(ip,port)
        @tcpserver= TCPServer.open(ip, port)
    end

    def waitClient
        puts "等待客户端连接。。。"
        @client = @tcpserver.accept
        puts "客户端连接成功！"
    end

    def reConnect
        puts "重新连接"
        #close()
        waitClient()
    end

    def sendMessage(s)
        if !@client.closed?
            @client.puts "    "+s+"!"
        end
    end

    def recieveMessage()
        puts "等待接收。。。"
        m = @client.gets.chomp
        puts m
        puts "接收完成！"
    end

    def close()
        @client.close
        @tcpserver.close
    end
end

class ArchServer
    def ArchServer.create(port=8088)
        $archserver=Server.new
        $archserver.connect("127.0.0.1", port)
        ArchServer.wait()
    end
    def ArchServer.wait()
        $archserver.waitClient()
    end
    def ArchServer.close()
        $archserver.close
    end
    def ArchServer.puts(s)
        $archserver.sendMessage(s)
    end
    def ArchServer.reset()
        ArchServer.close()
        ArchServer.create()
    end
    def ArchServer.valid?()
        return false if $archserver==nil
        return false if $archserver.tcpserver==nil or $archserver.client==nil
        return false if $archserver.tcpserver.closed? or $archserver.client.closed?
        return true
    end
end

def ArchServerTest()
    # run this function after creating a server by:
    # 1: run ArchServer.create
    # 2: run Unity Client
    # 3: when connection is established
    # 4: run ArchServerTestCode()

    box1=MeshUtil::AttrBox.new()
    box2=MeshUtil::AttrBox.new()
    box2.rotation=60
    box2.position=[10,10,0]

    Encriptor.set_color([255,100,0])
    Encriptor.abs_box box1
    Encriptor.set_color([255,100,100])
    Encriptor.abs_box box2
end