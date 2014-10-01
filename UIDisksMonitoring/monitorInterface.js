
window.onload = function()
{
    var monitoredFolders = fileToArray("monitoredFolders");
    var monitorTable = document.getElementById('monitorTable');
    
    var table = '';
    table += '<table>';
    var realIndex = 0;
    for (i = 0 ; i < monitoredFolders.length ; i++)
    {
        if (monitoredFolders[i][0] == "") continue;
        if (realIndex % 2 == 0) table += '<tr>' 
        table += '<td id="monitorBox_'+realIndex+'"></td>' 
        if (realIndex % 2 != 0) table += '</tr>' 
        realIndex++;
    }
    table += '</table>';
    monitorTable.innerHTML += table;
        
    realIndex = 0;
    for (i = 0 ; i < monitoredFolders.length ; i++)
    {
        if (monitoredFolders[i][0] == "") continue;
        addMonitorBlock(realIndex,monitoredFolders[i]);
        realIndex++;
    }
        
};


fileToArray = function(id)
{
    var inputFileContent = document.getElementById(id).contentDocument.body.firstChild.innerHTML;
    return CSVToArray(inputFileContent,",");
}

addMonitorBlock = function(id,data)
{
    var tag = data[0];
    var monitorBox = document.getElementById('monitorBox_'+id);
    monitorBox.innerHTML += '<div class="boxOutter"><div class="boxInner">'+
                             '<iframe style="display:none;" id='+tag+'_currentUse src="data/currentUse/'+tag+'.usage" onload="loadMonitorCurrentUse(\''+tag+'\');"></iframe>'+
                             '<iframe style="display:none;" id='+tag+'_history    src="data/historySummary/'+tag+'.history" onload="loadMonitorHistory(\''+tag+'\');"></iframe>'+
                             '<table height=100% width=100%>'+
                             '<tr>'+
                             '<td>'+
                             '<div class="legend" width="100%">'+
                             '    <h3 class="legendHeader">'+tag+'</h3>'+
                             '    </ul>'+
                             '</div>'+
                             '</td>'+
                             '<td>'+
                             '<center><h4 class="legendSubheader" style="font-size:24px;">Current usage</h4>'+
                             '<h4 class="legendSubheader" id="legendSubheader_'+tag+'"></h4></center>'+
                             '</td>'+
                             '<td>'+
                             '<center><h4 class="legendSubheader" style="font-size:24px;">Free space history</h4></center>'+
                             '</td>'+
                             '</tr>'+
                             '<tr>'+
                             '<td width=30%>'+
                             '<div class="legend" width="100%">'+
                             '    <ul class="legendContent" id="legendContent_'+tag+'">'+
                             '    </ul>'+
                             '</div>'+
                             '</td>'+
                             '<td width="40%" height="100%">'+
                             '    <canvas id="doughnut-canvas_'+tag+'" width="100%" height="70%"></canvas>'+
                             '</td>'+
                             '<td width="30%" height="100%">'+
                             '    <canvas id="graph-canvas_'+tag+'" width="100%" height="70%"></canvas>'+
                             '</td>'+
                             '</tr>'+
                             '</table>'+
                             '</div></div>';
}

loadMonitorCurrentUse = function(tag)
{
    // Read and parse data

    var currentUseData = fileToArray(tag+"_currentUse");
    var total = 0;
    var free = 0;
    var unknown = 0; 
    var userArray = new Array();
    var userArrayIndex = 0;
    for  (i = 0 ; i < currentUseData.length ; i++)
    {
        if (currentUseData[i][0] == "") continue;
        currentUseData[i][1] = parseFloat(currentUseData[i][1]);
        total += currentUseData[i][1];

             if (currentUseData[i][0] == "free")    free    = currentUseData[i][1];
        else if (currentUseData[i][0] == "unknown") unknown = currentUseData[i][1];
        else { userArray[userArrayIndex] = currentUseData[i]; userArrayIndex++; } 
        
    }

    userArray.sort(sortUserUsage);

    // Compute and print status of disk

    var statusString;
    var statusColor;

         if (free / total > 0.10) { statusString = "OK";      statusColor = "#55BB77"; }
    else if (free / total > 0.05) { statusString = "Warning"; statusColor = "#DD9944"; }
    else                          { statusString = "Full";    statusColor = "#ff0000"; }

    var legendSubheader = document.getElementById("legendSubheader_"+tag);
    legendSubheader.innerHTML += '(Status : <span style="color:'+statusColor+';">'+statusString+'</span>)';

    // Write legend entries

    var legendContent = document.getElementById("legendContent_"+tag);
    for (i = 0 ; i < Math.min(userArray.length,5) ; i++)
    {
        userName  = userArray[i][0];
        userColor = stringToColor(userName+"derp");
        userSize  = userArray[i][1];
        legendContent.innerHTML += '<li class="legendEntry"><span class="legendColorBox" style="background-color:'+userColor+';"></span>'+userName+' ('+parseInt(100 * userSize / total)+'%)</li>';
    }
    var othersSize = 0;
    for (i = Math.min(userArray.length,5) ; i < userArray.length ; i++)
    {
        othersSize += userArray[i][1];
    }
    legendContent.innerHTML += '<li class="legendEntry"><span class="legendColorBox" style="background-color:'+stringToColor("others")+';"></span>others ('+parseInt(100 * othersSize / total)+'%)</li>';
    legendContent.innerHTML += '<li class="legendEntry"><span class="legendColorBox" style="background-color:#333;"></span>unknown ('+parseInt(100 * unknown / total)+'%)</li>';
    legendContent.innerHTML += '<li class="legendEntry"><span class="legendColorBox" style="background-color:#fff;"></span>free ('+parseInt(100 * free / total)+'%)</li>';

    // Create and fill doughnut data
    
    var doughnutData = new Array();
    var doughnutIndex = 0;
    doughnutData[doughnutIndex] = { value: free,       color: "#fff",                  highlight: "#fff",                  label: "free"    }; doughnutIndex++;
    doughnutData[doughnutIndex] = { value: unknown,    color: "#333",                  highlight: "#333",                  label: "unknown" }; doughnutIndex++;
    doughnutData[doughnutIndex] = { value: othersSize, color: stringToColor("others"), highlight: stringToColor("others"), label: "others"  }; doughnutIndex++;
    for (i = Math.min(userArray.length,5)-1 ; i >= 0 ; i--)
    {
        userName  = userArray[i][0];
        userColor = stringToColor(userName+"derp");
        userSize  = userArray[i][1];
        doughnutData[doughnutIndex] = { value: userSize, color: userColor, highlight:userColor, label: userName }; doughnutIndex++;
    }


    var canvas = document.getElementById("doughnut-canvas_"+tag).getContext("2d");
    window.doughnut = new Chart(canvas).Doughnut(doughnutData, {tooltipTemplate : "<%if (label){%><%=label%>: <%}%><%= value %> G", animation: false, segmentStrokeColor : "#000",  segmentStrokeWidth : 1, responsive : true});


}

sortUserUsage = function(a,b)
{
    return (a[1] < b[1]);
}

loadMonitorHistory = function(tag)
{
    var historyData = fileToArray(tag+"_history");
    
    var dateLabels     = new Array();
    var dateFreespace  = new Array();

    var index = 0;
    for  (i = 0 ; i < historyData.length ; i++)
    {
        if (historyData[i][0] == "") continue;
        dateLabels[index]    = historyData[i][0];
        dateFreespace[index] = parseInt(historyData[i][1]);
        index++;
    }

    var lineChartData = 
    {
        labels : dateLabels,
        datasets : [ 
            {
                label: "Free space quantity",
                fillColor : "rgba(151,187,205,0.0)",
                strokeColor : "rgba(151,187,205,1)",
                pointColor : "rgba(151,187,205,1)",
                pointStrokeColor : "#fff",
                pointHighlightFill : "#fff",
                pointHighlightStroke : "rgba(151,187,205,1)",
                data : dateFreespace
            } 
        ]
    }
     
    var canvas  = document.getElementById("graph-canvas_"+tag).getContext("2d");
    window.line = new Chart(canvas).Line(lineChartData, {animation: false,  responsive: true});
}
