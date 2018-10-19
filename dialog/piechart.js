var width = 100,
    height = 100,
    radius = Math.min(width, height) / 2;

var datavar= {
    "age":[10,30,50,60],
    "population":[100,200,300,400]
}

var datajson = [
    {age:10,population:100},
    {age:20,population:200},
    {age:40,population:300},
    {age:80,population:400}
]

var color = d3.scale.ordinal()
    .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]);

var arc = d3.svg.arc()
    .outerRadius(radius - 10)
    .innerRadius(radius - 35);

var pie = d3.layout.pie()
    .sort(null)
    .value(function(d) { return d.population; });

var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height)
    .append("g")
    .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");


var g = svg.selectAll(".arc")
    .data(pie(datajson))
    .enter().append("g")
    .attr("class", "arc");

g.append("path")
    .attr("d",arc)
    .style("fill",function(d) {return radius-5;});

function update_plot(){
    g.data(pie(datajson));

}
//
// arc.outerRadius(function(d){
//     console.log(d.data);
//     return radius-(1-d.data.population/10);
// });
// -------------------------------------------
// d3.csv("data.csv", type, function(error, data) {
//     if (error) throw error;
//
//     var g = svg.selectAll(".arc")
//         .data(pie(data))
//         .enter().append("g")
//         .attr("class", "arc");
//
//     arc.outerRadius(function (d) { return radius-(1-(d.data.population/14106543))*30});
//
//     g.append("path")
//         .attr("d", arc)
//         .style("fill", function(d) { return color(d.data.age); });
//
//     g.append("text")
//         .attr("transform", function(d) { return "translate(" + arc.centroid(d) + ")"; })
//         .attr("dy", ".35em")
//         .text(function(d) { return d.data.age; });
// });

function type(d) {
    d.population = +d.population;
    return d;
}