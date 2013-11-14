adminApp = angular.module "adminApp", []

adminApp.controller "AdminIndexCtrl", ["$scope", "$location", "$q", ($scope, $location, $q) ->
  $scope.host = $location.search()["host"] || $location.host()
  $scope.port = $location.search()["port"] || if $scope.host == "sandbox.influxdb.org" then 9061 else 8086
  $scope.database = $location.search()["database"]
  $scope.username = $location.search()["username"]
  $scope.password = $location.search()["password"]
  $scope.authenticated = false
  $scope.isClusterAdmin = false
  $scope.isDatabaseAdmin = false
  $scope.databases = []
  $scope.admins = []
  $scope.data = []
  $scope.readQuery = null
  $scope.writeSeriesName = null
  $scope.writeValues = null
  $scope.successMessage = "OK"
  $scope.alertMessage = "Error"
  $scope.authMessage = ""
  $scope.selectedPane = "databases"

  $scope.newAdminUsername = null
  $scope.newAdminPassword = null

  influx = null
  master = null

  master = new InfluxDB($scope.host, $scope.port, "root", "root")

  $scope.authenticateAsClusterAdmin = () ->
    influx = new InfluxDB($scope.host, $scope.port, $scope.username, $scope.password)
    $q.when(influx.authenticateClusterAdmin()).then (response) ->
      $scope.authenticated = true
      $scope.isClusterAdmin = true
      $scope.isDatabaseAdmin = false
      $scope.getDatabases()
      $scope.getClusterAdmins()
      $location.search({})
    , (response) ->
      $scope.authError(response.responseText)

  $scope.authenticateAsDatabaseAdmin = () ->
    influx = new InfluxDB($scope.host, $scope.port, $scope.username, $scope.password, $scope.database)
    $q.when(influx.authenticateDbUser()).then (response) ->
      $scope.authenticated = true
      $location.search({})
    , (response) ->
      $scope.authError(response.responseText)

  $scope.getDatabases = () ->
    $q.when(influx.getDatabases()).then (response) ->
      $scope.databases = response

  $scope.getClusterAdmins = () ->
    $q.when(influx.getClusterAdmins()).then (response) ->
      $scope.admins = response

  $scope.createClusterAdmin = () ->
    $q.when(influx.createClusterAdmin($scope.newAdminUsername, $scope.newAdminPassword)).then (response) ->
      $scope.newAdminUsername = null
      $scope.newAdminPassword = null
      $scope.getClusterAdmins()

  $scope.createDatabase = () ->
    $q.when(influx.createDatabase($scope.newDatabaseName)).then (response) ->
      $scope.newDatabaseName = null
      $scope.getDatabases()

  $scope.deleteDatabase = (name) ->
    $q.when(influx.deleteDatabase(name)).then (response) ->
      $scope.getDatabases()

  $scope.writeData = () ->
    unless $scope.writeSeriesName
      $scope.error("Time Series Name is required.")
      return

    try
      values = JSON.parse($scope.writeValues)
    catch
      $scope.alertMessage = "Unable to parse JSON."
      $("span#writeFailure").show().delay(1500).fadeOut(500)
      return

    $q.when(influx.writePoint($scope.writeSeriesName, values)).then (response) ->
      $scope.success("200 OK")

  $scope.readData = () ->
    $scope.data = []

    $q.when(influx._readPoint($scope.readQuery)).then (response) ->
      data = response
      data.forEach (datum) ->
        $scope.data.push
          name: datum.name
          columns: datum.columns
          points: datum.points
          graphs: $scope.filteredColumns(datum).map (column) ->
            $scope.columnPoints(datum, column)

  $scope.authError = (msg) ->
    $scope.authMessage = msg
    $("span#authFailure").show().delay(1500).fadeOut(500)

  $scope.error = (msg) ->
    $scope.alertMessage = msg
    $("span#writeFailure").show().delay(1500).fadeOut(500)

  $scope.success = (msg) ->
    $scope.successMessage = msg
    $("span#writeSuccess").show().delay(1500).fadeOut(500)

  $scope.filteredColumns = (datum) ->
    datum.columns.filter (d) -> d != "time" && d != "sequence_number"

  $scope.columnPoints = (datum, column) ->
    index = datum.columns.indexOf(column)
    datum.points.map (row) ->
      time: new Date(row[0])
      value: row[index]

  if $scope.username && $scope.password && $scope.database
    $scope.authenticate()
]

adminApp.directive "lineChart", [() ->
  restrict: "E",
  replace: false,
  scope:
    data: "=data",
  link: (scope, element, attrs) ->
    console.log scope.data

    margin = parseInt(attrs.margin) || 20
    barHeight = parseInt(attrs.barHeight) || 20
    barPadding = parseInt(attrs.barPadding) || 5

    scope.render = (data) ->
      console.log data
      return if (!data)

      margin = {top: 0, right: 0, bottom: 30, left: 50}
      width = 1086 - margin.left - margin.right
      height = 200 - margin.top - margin.bottom

      x = d3.time.scale().range([0, width])
      y = d3.scale.linear().range([height, 0])
      xAxis = d3.svg.axis().scale(x).orient("bottom")
      yAxis = d3.svg.axis().scale(y).orient("left").ticks(5)
      line = d3.svg.line().x((d) -> x(d.time)).y((d) -> y(d.value))

      svg = d3.select(element[0]).append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

      x.domain(d3.extent(data, (d) -> d.time ))
      y.domain(d3.extent(data, (d) -> d.value ))

      svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis)

      svg.append("g")
        .attr("class", "y axis")
        .call(yAxis)

      svg.append("path")
        .datum(data)
        .attr("class", "line")
        .attr("d", line)

    scope.render(scope.data)

]
