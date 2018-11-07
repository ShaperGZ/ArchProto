using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Entry : MonoBehaviour {

    private Client _client;
    private MessageInterpretor _interpretor;
    private bool _connected = false;
    private GeometryGenerator _generator;

    // Use this for initialization
    void Start () {
        // create client and connect to server
        Debug.Log("creating client");
        _client = new Client();
        _client.onRecieveCallbacks += OnRecieveData;
        _connected = _client.ConnectServer();
        
        //generator to create geometries
        _generator = new GeometryGenerator();

        //set interprtretor
        SetInterpretor(new AbsGeoInterpretor(_generator));

    }
 
    private void Close()
    {
        _client.Close();
    }
    void SetInterpretor(MessageInterpretor itr)
    {
        _interpretor = itr;
    }
    void OnRecieveData(string data)
    {
        Debug.Log("received data" + data);
        _interpretor.Interpret(data);
    }
	// Update is called once per frame
	void Update () {
        //if (!_connected) _client.ConnectServer();
        if(_generator != null)
            _generator.Update();
	}
    private void OnDestroy()
    {
        if (_client != null)
        {
            print("disconnecting from server");
            _client.Close();
        }
    }
    private void OnDisable()
    {
        if (_client != null)
        {
            print("disconnecting from server");
            _client.Close();
        }
    }
}
