ApiServer = require 'apiserver'
request = require 'request'

Number.prototype.toDeg = () ->
  this * 180 / Math.PI;

config =
  foursquare:
    apiurl: "https://api.foursquare.com/v2/"
    token: "JYBSAF3BGP33BECMOQJAPTYCHFNS0MDSQS5Y3KPWLU5FGKSD"
  location:
    lat: "51.5221090051861"
    lng: "-0.10929599404335"
  radius: 1000
  limit: 10

apiserver = new ApiServer()
apiserver.listen(3000, onListen)

onListen = (err) ->
  if err
    console.error('Something terrible happened: %s', err.message)
  else
    console.log('Successful bound to port %s', this.port)
    setTimeout(apiserver.close(onClose), 5000)

onClose = () -> console.log('port unbound correctly')

# Extract latitude, longitude and current number of checkins from foursquare response
parseApiResp = (data) ->
  console.log data
  ({lat: r.location.lat, lng: r.location.lng, count: r.hereNow.count} for r in data.response.venues)

# Compute geographical center weighted by number of checkins
computeCenter = (data) ->
  console.log data
  wlng = 0
  wlat = 0
  wcount = 0
  for r in data
    wlat += r.lat * r.count
    wlng += r.lng * r.count
    wcount += r.count
  console.log wlat, wlng, wcount
  {lat: wlat/wcount, lng: wlng/wcount}

# http://www.movable-type.co.uk/scripts/latlong.html
computeBearing = (ll1, ll2) ->
  console.log ll1
  console.log ll2
  dLon = ll2.lng - ll1.lng
  lat1 = ll1.lat
  lat2 = ll2.lat
  console.log dLon, lat1, lat2
  y = Math.sin(dLon) * Math.cos(lat2)
  x = Math.cos(lat1) * Math.sin(lat2) -
    Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon)
  Math.atan2(y, x).toDeg()

arrowModule =
  get: (req, resp) ->
    #console.log req
    ll =
      lat: req.querystring.lat || config.location.lat
      lng: req.querystring.lng || config.location.lng
    radius = req.querystring.radius || config.radius
    limit = req.querystring.limit || config.limit
    apiquery = config.foursquare.apiurl + 'venues/trending?ll=' + ll.lat + ',' + ll.lng +
      '&radius=' + radius + '&limit=' + limit + '&oauth_token=' + config.foursquare.token + '&v=20120519'
    request apiquery, (error, response, body) ->
      resp.serveJSON computeBearing ll, computeCenter parseApiResp JSON.parse body

apiserver.addModule('1', 'arrow', arrowModule)
