class TableSpanInput{
    constructor(parent){
        this.parent=parent;
        this.table=document.createElement("table");
        this.tb=document.createElement("tb");
        this.table.appendChild(this.tb);
        this.parent.appendChild(this.table);
        this.classContent="contents";
        this.table.className=this.classContent;
        this.textSizeContent=8;
        this.rows=[]
    }

    addRows(data){
        self=this;
        data.forEach(function(d,i){
            self.addRow(d,i);
        })
    }

    addRow(rowObj,rowIndex){
        // console.log("add row d:"+rowObj.name+","+rowObj.value);
        var d=rowObj;
        var name=d.name;
        var value=d.value
        var span=document.createElement("span")
        span.innerHTML=name
        // span.class=this.classContent;
        span.className = this.classContent;


        var input=document.createElement("input")
        input.type="text"

        var className=this.classContent
        if(previousData!=null){
            var compare=previousData[rowIndex].value;
            // console.log("comparing "+compare+" vs "+value)
            if (compare!=value){
                className="changedContents"
            }
        }
        input.className=className;
        input.value=value
        input.width=50
        input.id="tb_"+name;
        self=this;
        input.onkeydown=function(key){
            if (key.keyCode == "13"){
                value=input.value;
                self.onValueChange(name,value);
            }
        }
        var tr=document.createElement("tr");

        this.addCell(span,tr,100);
        this.addCell(input,tr,100);

        this.tb.appendChild(tr);
        this.rows.push(tr);
    }

    addCell(domObj,row,width=50){
        var td=document.createElement("td");
        td.appendChild(domObj);
        td.width=width;
        row.appendChild(td);
    }

    onValueChange(name,value){
        var txt="onValueChanged name:"+name+" value:"+value;
        console.log(txt);
    }

    clearRows(){
        var count=this.tb.childElementCount;
        for (var i=0;i<count;i++){
            // console.log(i);
            this.tb.removeChild(this.tb.childNodes[0]);
        }
    }
}


// data=[
//     {"name":"bd_ftfh", "value":"6,3"},
//     {"name":"un_width","value":"3"},
//     {"name":"un_depth","value":"9"},
// ]


