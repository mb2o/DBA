function draw_nodes(svg, nodesArray, edgesArray) {
    var nodesDict = {};
    nodesArray.forEach( x => nodesDict[x.text] = x);

    //edge
    let lines = svg.selectAll('line')
                   .data(edgesArray)
                   .enter()
                   .append('line');
    update_lines( lines, nodesDict );
    
    // node
    let nodes = svg.selectAll('circle')
                   .data(nodesArray)
                   .enter()
                   .append('circle');
    update_nodes( nodes );
}

function redraw_nodes(svg, nodesArray, edgesArray) {
    let nodesDict = {};
    nodesArray.forEach( x => nodesDict[x.text] = x);

    // edges
    let lines = svg.selectAll('line')
                   .data(edgesArray);
    update_lines( lines, nodesDict );
    
    // node
    let nodes = svg.selectAll('circle')
                   .data(nodesArray);
    update_nodes( nodes );

    if (showLabels) {
        // label
        let labels = svg.selectAll('text')
                        .data(nodesArray);
        update_labels( labels );
    }
}

function update_nodes (nodes) {
    nodes.attrs({
        cx: d => scale * d.x + translatex,
        cy: d => scale * d.y + translatey,
        r: d => 2,
        fill: '#333'
    });
}

function update_labels (labels) {
    labels.text(d => d.text)
    .attrs({
      x: (d) => scale * d.x + translatex + 6,
      y: (d) => scale * d.y + translatey + 3
    });
}

function update_lines ( lines, nodesDict ) {
    lines.attrs({
        x1: e => scale * nodesDict[e.first].x + translatex,
        y1: e => scale * nodesDict[e.first].y + translatey,
        x2: e => scale * nodesDict[e.second].x + translatex,
        y2: e => scale * nodesDict[e.second].y + translatey,
        style: "stroke:#999;stroke-width:1"
    });
}

var showLabels = false;

function toggle_labels() {
    showLabels = !showLabels;
    if (showLabels) {
        document.getElementById('labels_button').innerHTML = "Hide Labels";
        let labels = svg.selectAll('text')
                        .data(nodesArray)
                        .enter()
                        .append('text');
        update_labels(labels);
    } else {
        document.getElementById('labels_button').innerHTML = "Show Labels";
        svg.selectAll('text')
           .remove();        
    }        
}