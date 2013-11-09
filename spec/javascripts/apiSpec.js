describe("InfluxDB", function() {
  var api;

  beforeEach(function() {
    db = new InfluxDB("localhost", 8086, "root", "root");
    successCallback = jasmine.createSpy("success");
  })

  describe("#url", function() {
    it("should build a properly formatted url", function() {
      var url = db.url("foo")
      expect(url).toEqual("http://localhost:8086/foo?username=root&password=root")
    })
  })

  describe("#createDatabase", function() {
    it("should create a new database", function () {

      request = db.createDatabase("test", successCallback)
      waitsFor(function() {
        return successCallback.callCount > 0;
      }, 100);
      expect(successCallback).toHaveBeenCalled();
    })
  })

  describe("#readPoint", function() {
    it("should read a point from the database", function () {
      db.readPoint()
    })
  })

  describe("#writePoint", function() {
    it("should write a point into the database", function () {
      db.writePoint("foo", {a: 1, b: 2})
    })
  })

  it("should be truthy", function() {
    expect(db.test()).toEqual(true);
  })
});
