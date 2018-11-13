var select_tbody
var selects

function init(){
    container=document.getElementById("selection_table")
    add_table(container)
    add_select('unit_type',['aa','bb','cc']);
}

function add_table(dom)
{
    var table=document.createElement("table")
    select_tbody=document.createElement("tb")
    var row=document.createElement("tr")
    dom.appendChild(table)
    table.appendChild(select_tbody)
}

function add_select_item(title,item){
    id='sl'+title
    sel=document.getElementById(id)
    sel.options.add(new Option(item,item))
}
function add_select(title,options,defaultValue=null){
    //create containers
    var row=document.createElement("tr")
    var td_span=document.createElement("td")
    var td_select=document.createElement("td")
    row.appendChild(td_span)
    row.appendChild(td_select)
    select_tbody.appendChild(row)

    //fill contents with actual dom elements
    var span=document.createElement("span")
    span.className="contents"
    span.innerHTML = title
    td_span.appendChild(span)

    var select=document.createElement("select")
    select.className="contents"
    select.id='sl_'+title
    options.forEach(function(opt){
        select.options.add(new Option(opt,opt))
    })
    select.onchange=function(){
        // console.log("name="+name);
        console.log("value="+select.value);
        console.log("id="+select.id);
        strdata=select.id+';'+select.value
        var msg='skp:selection_changed@'+strdata;
        window.location=msg;
    }



    td_select.appendChild(select)
    // selects.push(select)

    if (defaultValue!=null)
        select.value=defaultValue;
    return select
}

function clear_select_table(){
    var count=select_tbody.childElementCount;
    for (var i=0;i<count;i++){
        // console.log(i);
        select_tbody.removeChild(select_tbody.childNodes[0]);
    }
}


function read_selection_contents(){
    //read the parameters from file
}



init()