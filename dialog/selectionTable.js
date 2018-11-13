function init(){
    container=document.getElementById("selection_table")
    add_table(container)
}

function add_table(dom)
{
    var table=document.createElement("table")
    var tbody=document.createElement("tb")
    var row=document.createElement("tr")
    dom.appendChild(table)
    table.appendChild(tbody)

    // unit selection
    var row1=document.createElement("tr")
    var td_span=document.createElement("td")
    var td_select=document.createElement("td")
    row1.appendChild(td_span)
    row1.appendChild(td_select)

    tbody.appendChild(row1)

    var name="unit type"
    var span=document.createElement("span")
    span.className="contents"
    span.innerHTML = name
    td_span.appendChild(span)

    var selection=document.createElement("select")
    selection.className="contents"
    var options=['u1asd','u2asdasd','u3asdasd']
    options.forEach(function(opt){
        var option = document.createElement("option")
        option.value=opt;
        option.innerHTML=opt;
        selection.appendChild(option)
    })
    td_select.appendChild(selection)
}

function read_selection_contents(){
    //read the parameters from file
}



init()