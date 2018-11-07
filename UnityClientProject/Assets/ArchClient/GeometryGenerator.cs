using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using SGGeometry;
using UnityEngine;
using ArchUtil;

public class GeometryGenerator
{
    bool invalidated = false;
    Dictionary<string, Meshable> creator=new Dictionary<string, Meshable>();
    Dictionary<string, Meshable> existing = new Dictionary<string, Meshable>();
    List<string> destroyer=new List<string>();
    bool _enableUpdate = true;
    //Dictionary<string, ShapeObject> shapes=new Dictionary<string, ShapeObject>();
    List<ShapeObject> shapes = new List<ShapeObject>();

    

    public void set(string id,Meshable m)
    {
        Debug.Log("adding "+id+":"+m+"to creator");
        creator[id] = m;
        invalidated = true;
    }

    public void delete(string id)
    {
        if (!destroyer.Contains(id))
            destroyer.Add(id);
        invalidated = true;
    }
    public void EnbleUpdate(bool flag)
    {
        _enableUpdate = flag;
    }
    public void updateExistingList()
    {
        //create or update geometries
        foreach (var item in creator)
        {
            string key = item.Key;
            Meshable meshable = item.Value;
            existing[key] = meshable;
        }
        creator.Clear();

        //delete gemetries
        foreach (var item in destroyer)
        {
            string key = item;
            if (existing.Keys.Contains(key))
            {
                existing.Remove(key);
            }
        }
        destroyer.Clear();
    }
    public void updateShapeObjects()
    {
        int diff = shapes.Count - existing.Count;
        // remove extract shape objects
        if (diff > 0)
        {
            for (int i = 0; i < diff; i++)
            {
                GameObject.Destroy(shapes[0]);
                shapes.RemoveAt(0);
            }
        }
        // create new to match existing.count = shapes.count
        else if (diff < 0)
        {
            for (int i = 0; i < Math.Abs(diff); i++)
            {
                ShapeObject shp = ShapeObject.CreateBasic();
                shapes.Add(shp);
            }
        }
        // update one to one
        Meshable[] meshables = existing.Values.ToArray<Meshable>();
        for (int i = 0; i < existing.Count; i++)
        {
            shapes[i].SetMeshable(meshables[i]);
            shapes[i].SetMaterial(MaterialManager.get(meshables[i].color));
        }
    }
    public void Update()
    {
        // always update the existing list from creator and desroyer
        updateExistingList();

        // only update the shapeobjects list if there are changes made to the existing list
        if (!_enableUpdate || !invalidated) return;
        updateShapeObjects();
        invalidated = false;
    }

    //public void Update2()
    //{
    //    if (!_enableUpdate || !invalidated) return;

    //    // create or update geometries
    //    foreach (var item in creator)
    //    {
    //        string key = item.Key;
    //        Meshable meshable = item.Value;

    //        if (!shapes.Keys.Contains(key))
    //        {
    //            ShapeObject shp = ShapeObject.CreateBasic();
    //            shapes[key] = shp;
    //        }
    //        shapes[key].SetMeshable(meshable);
    //    }
    //    creator.Clear();
        

    //    //delete gemetries
    //    foreach(var item in destroyer)
    //    {
    //        string key = item;
    //        if (shapes.Keys.Contains(key))
    //        {
    //            GameObject.Destroy(shapes[key]);
    //            shapes.Remove(key);
    //        }
    //    }
    //    destroyer.Clear();

    //    invalidated = false;
    //}
}

