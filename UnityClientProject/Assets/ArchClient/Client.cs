using myNet;
using UnityEngine;
using System.Threading;
using System;

public delegate void OnRecieve(string data);

public class Client
{
    public OnRecieve onRecieveCallbacks;
    public ClientSocket mSocket;
    public Thread thread;

    public Client()
    {
        Debug.Log("create client");
        mSocket = new ClientSocket();
    }

    public bool ConnectServer(int port = 8088, string IP= "127.0.0.1")
    {
        Debug.Log("attemp to connect to " + IP.ToString() + ":" + port.ToString());
        mSocket.ConnectServer(IP, port);
        
        if (mSocket.IsConnected)
        {
            //开启线程 等待接收消息
            ThreadStart threadStart = new ThreadStart(Recieve);
            thread = new Thread(threadStart);
            thread.Start();
            return true;
        }
        return false;
    }

    public void Close()
    {
        Debug.Log("断开线程");
        if (thread != null)
        {
            thread.Abort();
        }
    }

    string lastData;
    public void Recieve()
    {
        while (true)
        {
            Debug.Log("等待接收消息。。。");
            string data = mSocket.RecieveMessage();        
            string Newdata = data.Substring(0, data.IndexOf('!'));
            if (Newdata == lastData)
            {
                continue;
            }
            lastData = Newdata;
            if (Newdata != null)
            {
                onRecieveCallbacks(Newdata);
            }
            else
            {
                Debug.Log("与服务器断开连接！");        //服务器端关闭此Client时
                break;
            }
            Debug.Log("接收完成");
          
        }     
    }
}
