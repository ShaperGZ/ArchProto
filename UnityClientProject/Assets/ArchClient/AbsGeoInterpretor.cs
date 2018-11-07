using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SGGeometry;

public class AbsGeoInterpretor : MessageInterpretor {

    public Color currentColor = new Color( 200, 200, 200 );

    public AbsGeoInterpretor(GeometryGenerator generator) : base(generator)
    {
    }

    public override void Interpret(string data)
    {
        base.Interpret(data);
        Debug.Log(data);


        string[] trunks = data.Split('|');
        Debug.Log(trunks[0]);
        if (trunks[0] == "ABS_BOX")
        {
            Debug.Log("key matched");
            updateBox(trunks);
        }
        else if (trunks[0] == "DELETE_RANGE")
        {
            deleteRange(trunks);
        }
        else if (trunks[0] == "ENABLE_UPDATE")
        {
            enableUpdate(trunks);
        }
        else if (trunks[0] == "SET_COLOR")
        {
            setColor(trunks);
        }
        else
        {
            Debug.Log(trunks[0] + " no matched command found: " + trunks[1]);
        }
    }
    public void setColor(string[] dataString)
    {
        string[] strs = dataString[1].Split(',');
        float r = float.Parse(strs[0]) / 255f;
        float g = float.Parse(strs[1]) / 255f;
        float b = float.Parse(strs[2]) / 255f;
        currentColor = new Color(r, g, b);
    }
    public void enableUpdate(string[] dataString)
    {
        bool flag;
        if (dataString[1] == "true") flag = true;
        else flag = false;
        _generator.EnbleUpdate(flag);
    }
    public void deleteRange(string[] dataStrings)
    {
        string[] ids = dataStrings[1].Split(',');
        for(int i = 0; i < ids.Length; i++)
        {
            Debug.Log("deleteing " + ids[i]);
            _generator.delete(ids[i]);
            
        }
    }
    public void updateBox(string[] dataStrings)
    {
        foreach(string s in dataStrings)
            Debug.Log(s);
        string id = dataStrings[1];
        Vector3 pos = ParseVector(dataStrings[2]);
        Vector3 size = ParseVector(dataStrings[3]);
        float rotation = float.Parse(dataStrings[4]);
        Debug.Log("flag5");
        Debug.Log("pos=" + pos);

        Quaternion q = Quaternion.Euler(0, rotation, 0);
        
        Matrix4x4 mr = Matrix4x4.Rotate(q);
        Matrix4x4 mt = Matrix4x4.Translate(pos);

        Vector3[] pts = new Vector3[4];
        pts[0] = new Vector3();
        pts[1] = new Vector3(size[0],0,0);
        pts[2] = new Vector3(size[0], 0, size[1]);
        pts[3] = new Vector3(0, 0, size[1]);

        Debug.Log("base pts：");
        foreach (var p in pts) Debug.Log(p);

        //for(int i=0;i<4;i++)
        //{
        //    Vector3 p = pts[i];
        //    p = mr * p;
        //    p = mt * p;
        //}
        //Debug.Log("trans pts：");
        //foreach (var p in pts) Debug.Log(p);
        Extrusion etx = new Extrusion(pts,size[2]);
        //etx.Transform(mr);
        //etx.Transform(mt);
        Debug.Log(mt);
        Matrix4x4 m = mr * mt;
        etx.Transform(m);
        etx.Translate(pos);
        etx.color = currentColor;

        _generator.set(id, etx);
        
    }

    
}
