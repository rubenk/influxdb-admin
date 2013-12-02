$(function() {
  parent.influxdb.query("SELECT COUNT(message) FROM posts WHERE time > now() - 365d GROUP BY time(24h);", function(points) {
    var data = points.map(function(point) {
      return { x: point.time / 1000, y: point.count };
    }).reverse();

    var graph = new Rickshaw.Graph({
      element: document.querySelector("#chart"),
      width: 1100,
      height: 400,
      renderer: 'line',
      series: [{ data: data, color: 'steelblue' }]
    });

    var xAxis = new Rickshaw.Graph.Axis.Time({ graph: graph });
    var yAxis = new Rickshaw.Graph.Axis.Y({
      graph: graph,
      orientation: 'left',
      element: document.getElementById('y_axis')
    });

    xAxis.render();
    yAxis.render();
    graph.render();
  });
});
