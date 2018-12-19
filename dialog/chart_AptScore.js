var color = d3.scale.ordinal()
    .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]);

var colorLinear=d3.scale.linear()
    .domain([0.4,0.7,1.1])
    .range(["#A63B34","#FFE49B","#5187CB"]);

mydata=[
    {"name":12, "value":0.4, "flag":true, "weight":1},
    {"name":22, "value":0.85, "flag":false, "weight":1},
    {"name":32, "value":0.6, "flag":true, "weight":1},
    {"name":42, "value":0.9, "flag":true, "weight":1},
]

class IDP{
// IDP=function(svg=null, minV=0,maxV=1,data=[]){

    // this.radius=Math.min(this.width,this.height)/2;
    // console.log("i -- svg="+svg);
    // console.log("i -- innerRadius="+innerRadius);
    // console.log("i -- outerRadius="+outerRadius);
    // console.log("i -- data="+data);
    constructor(svg=null, minV=0,maxV=1,data=[]){
        if (svg == null){
            // console.log("Creating svg...");
            this.svg=IDP.create_svg(300,300);
        }
        else{
            // console.log("existing svg:"+svg);
            this.svg=svg;
        }
        // console.log("this.svg="+this.svg);

        this.width= parseInt(this.svg.attr("width"));
        this.height= parseInt(this.svg.attr("height"));
        this.radius=Math.min(this.width,this.height)/2;
        this.minV=minV;
        this.maxV=maxV;

        this.minR=this.minV*this.radius;
        if(maxV!=null)
            this.maxR=this.maxV*this.radius;
        else
            this.maxR=Math.min(this.width,this.height)/2;

        this.data=data;
        this.d_val=function(d){return d.value;};
        this.d_pie_val=function(d){return d.weight;};
        this.d_name=function(d){return d.name;};
        this.d_label=function(d){return d.data.name;};
        this.d_outerRadius=function(d){
            return d.data.value * this.radius
        };
        this.d_innerRadius=this.minR;
        this.d_data_color=function(d){
            var c=colorLinear(d.data.value)
            // console.log("color="+c+ "data.value="+d.data.value);
            return c;
        };
    }//end constructor

    d_outerRadiusCap(d){
        var val=d.data.value;
        console.log("val="+val+ " minV="+this.minV + " maxV="+this.maxV);
        if(val < this.minV){
            return this.minR;
        }
        else if (val > this.maxV){
            return this.maxR;
        }
        return val*this.radius;
    }

    d_text_translate(d){
        var centroid = this.arc.centroid(d);
        // console.log("centroid = "+centroid);
        return "translate("+this.arc.centroid(d)+")";
    }

    create(){
        var data=this.data;
        // 01 define arc generator
        this.arc = d3.svg.arc()
            .outerRadius(this.d_outerRadius)
            .innerRadius(this.d_innerRadius);

        // 02 generate layout
        this.pie = d3.layout.pie()
            .sort(null)
            .value(this.d_pie_val);

        // 03 create graphics inside the svg
        this.graphics=this.svg.append("g")
            .attr("transform","translate("+this.width/2+","+this.height/2+")");

        // binding data
        this.g=this.graphics.selectAll(".arc")
            .data(this.pie(data))
            .enter().append("g")
            .attr("class","arc")

        this.paths=this.g.append("path")
            .attr("d",this.arc)
            .style("fill", this.d_data_color)
            .style("stroke","white")
            .style("stroke-width",2);

        var self=this;
        // add text labels
        this.text=this.g.append("text")
            .attr("transform",function(d,i){
                var centroid = self.arc.centroid(d);
                if(isNaN(centroid[0])){
                    console.log('found Nan at i='+i+' d='+d.value );
                    return "translate(0,0)";

                }
                return "translate("+centroid+")";
            })
            .attr("dx","-5px")
            .attr("dy","5px")
            .style("text_anchor","middle")
            .style("font-size","10px")
            .style("fill","white")
            .text(this.d_label);

    };

    invalidate(data){
        this.graphics.remove();
        this.data=data;
        this.create();
        // this.g
        //     .data(this.pie(data))
        //     .selectAll("path")
        //     .attr("d",this.arc)
        //     .style("fill", this.d_data_color);
        //
        // this.text.text(this.d_label);
    };

}

class ChartAptScore{
    constructor(svg,data){
        this.minV=0;
        this.maxV=1;
        this.data=data;
        this.totalScore=0;

        this.width=parseInt(svg.attr("width"));
        this.height=parseInt(svg.attr("height"));
        this.radius = Math.min(this.width,this.height)/2
        var outerRadius = this.radius;
        var separator = outerRadius * 0.35;
        var centerR= outerRadius * 0.3;

        // main chart
        this.chart_main=new IDP(svg,this.minV,this.maxV,data);
        this.chart_main.d_label=function(d){
            var val=Math.round(d.data.value*100)/10
            return val
        };
        this.chart_main.radius = separator;
        this.chart_main.d_innerRadius=centerR;
        this.chart_main.d_outerRadius=function(d){
            var offset =  (outerRadius - separator) * d.data.value;
            return separator + offset;
        }

        // state chart
        this.chart_state=new IDP(svg,this.minV,this.maxV,data);
        this.chart_state.d_label="";
        this.chart_state.d_innerRadius=centerR;
        this.chart_state.d_outerRadius=separator;
        this.chart_state.d_data_color=function(d){if(d.data.flag) return "#6DBC2E"; return "#9C2D1B";};

        //overallscore chart
        var score=this.overall_score(data)

        // this.chart_overall=new IDP(svg,this.minV,this.maxV,[score]);
        // this.chart_overall.d_innerRadius=0;
        // this.chart_overall.d_outerRadius=function(d){
        //     // console.log(d.data);
        //     return d.data;
        // }

        //create
        this.chart_main.create();
        this.chart_state.create();
        //this.chart_overall.create();

        //create total score text
        this.calTotalScore(data);
        var offsetx=(this.width/2)-12;
        var offsety=(this.height/2+8);
        this.totalScoreText=svg.append("text")
            .attr("transform","translate("+offsetx+","+offsety+")")
            .style("font-size","18px")
            .style("font-family","Segoe UI black")
            .style("fill","gray")
            .text(this.totalScore);

    }

    calTotalScore(data){
        var totalWeight = 0
        this.totalScore=0
        self=this;
        data.forEach(function (d) {
            totalWeight += d.weight;
        })

        data.forEach(function (d) {
            self.totalScore+=d.value*(d.weight/totalWeight);
        })
        
        this.totalScore*=100;
        this.totalScore=Math.round(this.totalScore)
        this.totalScore/=10;
        weighted_score=this.totalScore
    }

    invalidate(data){
        this.chart_main.invalidate(data);
        this.chart_state.invalidate(data);
        var score=this.overall_score(data);
        // this.chart_overall.invalidate([score]);
        this.calTotalScore(data);
        this.totalScoreText.text(this.totalScore);
    }

    overall_score(data){
        var total=0;
        data.forEach(function(e){
            total+=e.value;
        })
        var score = total / data.length;
        return score;
    }
}

IDP.set_data_value=function(data,i,v){
    var orgVal=data[i].value
    if (v>=orgVal)
        data[i].flag=true;
    else
        data[i].flag=false;
    data[i].value=v;
}

IDP.create_svg=function(width=300,height=300){
    var svg=d3.select("body").select("div").append("svg")
        .attr("width",width)
        .attr("height",height);
    return svg
}


// Example:
//
// //creation
// svg=IDP.create_svg(300,300);
//
// chart1= new IDP(svg,20,140,mydata);
// chart1.d_outerRadius=function(d){return d.data.value/2 + 20;};
// chart1.create();
//
// chart2 = new IDP(svg,142,150,mydata);
// chart2.d_data_color=function(d){if(d.data.flag) return "#8BBC58"; return "#9C4831";};
// chart2.d_label="";
// chart2.create();
//
//
// svg2=IDP.create_svg(300,300);
// comp=new IDP_Composit(svg2,0,150,layers,mydata);
//
//


