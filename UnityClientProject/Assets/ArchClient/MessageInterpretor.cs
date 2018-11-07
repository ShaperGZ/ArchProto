using UnityEngine;
using System.Collections;
using System.Threading;
using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

public class MessageInterpretor
{
    public GeometryGenerator _generator;
    public MessageInterpretor(GeometryGenerator generator)
    {
        _generator = generator;
    }
    public virtual void Interpret(string data)
    {
    }

    public Vector3 ParseVector(string vectStr)
    {
        Vector3 vect = new Vector3();
        string[] strs = vectStr.Split(',');

        vect[0] = float.Parse(strs[0]);
        vect[1] = float.Parse(strs[2]);
        vect[2] = float.Parse(strs[1]);

        Debug.Log("parsed to " + vect);
        return vect;
    }

}
