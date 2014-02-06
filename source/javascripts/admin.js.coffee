adminApp = angular.module "adminApp", ["ngCookies"]

adminApp.config ["$locationProvider", ($locationProvider) ->
  $locationProvider.html5Mode(true)
  $locationProvider.hashPrefix('!')
]

adminApp.controller "AdminIndexCtrl", ["$scope", "$location", "$q", "$cookieStore", ($scope, $location, $q, $cookieStore) ->
  $scope.host = $location.search()["host"] || $location.host()
  $scope.port = $location.search()["port"] || if $scope.host == "sandbox.influxdb.org" then 9061 else 8086
  $scope.database = $location.search()["database"] || $cookieStore.get("database")
  $scope.username = $location.search()["username"] || $cookieStore.get("username")
  $scope.password = $location.search()["password"] || $cookieStore.get("password")
  $scope.authenticated = false
  $scope.databases = []
  $scope.admins = []
  $scope.data = []
  $scope.readQuery = null
  $scope.writeSeriesName = null
  $scope.writeValues = null
  $scope.successMessage = "OK"
  $scope.alertMessage = "Error"
  $scope.authMessage = ""
  $scope.queryMessage = ""
  $scope.selectedPane = "databases"
  $scope.newDbUser = {}
  $scope.interfaces = []
  $scope.databaseUsers = []

  $scope.newAdminUsername = null
  $scope.newAdminPassword = null

  window.influxdb = null

  $scope.getHashParams = () ->
    $location.search()

  $scope.setHashParams = (params) ->
    $location.search(params)

  $scope.getInterfaces = () ->
    $q.when(window.influxdb.getInterfaces()).then (response) ->
      $scope.interfaces = response

  $scope.humanize = (title) ->
    title.replace(/_/g, ' ').replace /(\w+)/g, (match) ->
      match.charAt(0).toUpperCase() + match.slice(1);

  $scope.setCurrentInterface = (i) ->
    $("iframe").prop("src", "/interfaces/#{i}")
    $scope.selectedPane = "data"

  $scope.authenticateAsClusterAdmin = () ->
    window.influxdb = new InfluxDB
      host: $scope.host
      port: $scope.port
      username: $scope.username
      password: $scope.password

    $q.when(window.influxdb.authenticateClusterAdmin()).then (response) ->
      $scope.getInterfaces()
      $scope.authenticated = true
      $scope.isClusterAdmin = true
      $scope.isDatabaseAdmin = false
      $scope.getDatabases()
      $scope.getClusterAdmins()
      $scope.selectedPane = "databases"
      $cookieStore.put("username", $scope.username)
      $cookieStore.put("password", $scope.password)

      $location.search({})
    , (response) ->
      $scope.authError(response.responseText)

  $scope.authenticateAsDatabaseAdmin = () ->
    window.influxdb = new InfluxDB
      host: $scope.host
      port: $scope.port
      username: $scope.username
      password: $scope.password
      database: $scope.database

    $q.when(window.influxdb.authenticateDatabaseUser($scope.database)).then (response) ->
      $scope.getInterfaces()
      $scope.authenticated = true
      $scope.isDatabaseAdmin = true
      $scope.isClusterAdmin = false
      $scope.selectedPane = "data"
      $scope.setCurrentInterface("default")
      $location.search({})
    , (response) ->
      $scope.authError(response.responseText)

  $scope.storeAuthenticatedCredentials = () ->
    $cookieStore.put("username", $scope.username)
    $cookieStore.put("password", $scope.password)
    $cookieStore.put("database", $scope.database)
    $cookieStore.put("host", $scope.host)
    $cookieStore.put("port", $scope.port)

  $scope.getDatabases = () ->
    $q.when(window.influxdb.getDatabases()).then (response) ->
      $scope.databases = response

  $scope.getClusterAdmins = () ->
    $q.when(window.influxdb.getClusterAdmins()).then (response) ->
      $scope.admins = response

  $scope.createClusterAdmin = () ->
    $q.when(window.influxdb.createClusterAdmin($scope.newAdminUsername, $scope.newAdminPassword)).then (response) ->
      $scope.newAdminUsername = null
      $scope.newAdminPassword = null
      $scope.getClusterAdmins()

  $scope.createDatabase = () ->
    $q.when(window.influxdb.createDatabase($scope.newDatabaseName)).then (response) ->
      $scope.newDatabaseName = null
      $scope.getDatabases()

  $scope.createDatabaseUser = () ->
    $q.when(window.influxdb.createUser($scope.selectedDatabase, $scope.newDbUser.username, $scope.newDbUser.password)).then (response) ->
      $scope.newDbUser = {}
      $scope.getDatabaseUsers()

  $scope.deleteDatabase = (name) ->
    $q.when(window.influxdb.deleteDatabase(name)).then (response) ->
      $scope.getDatabases()

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

  $scope.getDatabaseUsers = () ->
    $q.when(window.influxdb.getDatabaseUsers($scope.selectedDatabase)).then (response) ->
      $scope.databaseUsers = response

  $scope.showDatabase = (database) ->
    $scope.selectedDatabase = database.name
    $scope.getDatabaseUsers()
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
