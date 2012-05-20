ApiServer = require 'apiserver'
request = require 'request'
where = require 'where'

Number.prototype.toDeg = () ->
  this * 180 / Math.PI;

config =
  foursquare:
    apiurl: "https://api.foursquare.com/v2/"
    token: "JYBSAF3BGP33BECMOQJAPTYCHFNS0MDSQS5Y3KPWLU5FGKSD"
  location:
    lat: 51.5221090051861
    lng: -0.10929599404335
  radius: 1000
  limit: 10

apiserver = new ApiServer()
apiserver.listen(3000, onListen)

onListen = (err) ->
  if err
    console.error('Something terrible happened: %s', err.message)
  else
    console.log('Successful bound to port %s', @port)
    setTimeout(apiserver.close(onClose), 5000)

onClose = () -> console.log('port unbound correctly')

# Extract latitude, longitude and current number of checkins from foursquare response
parseApiResp = (data) ->
  console.log "top venue: #{data.response.venues[0]}"
  ({lat: r.location.lat, lng: r.location.lng, count: r.hereNow.count} for r in data.response.venues)

# Compute geographical center weighted by number of checkins
computeCenter = (data) ->
  console.log "trending venues: #{data}"
  wlng = 0
  wlat = 0
  wcount = 0
  for r in data
    wlat += r.lat * r.count
    wlng += r.lng * r.count
    wcount += r.count
  new where.Point wlat/wcount, wlng/wcount

arrowModule =
  get: (req, resp) ->
    here = new where.Point req.querystring.lat || config.location.lat, req.querystring.lng || config.location.lng
    console.log "here: #{here.lat}, #{here.lon}"
    radius = req.querystring.radius || config.radius
    limit = req.querystring.limit || config.limit
    apiquery = config.foursquare.apiurl + 'venues/trending?ll=' + here.lat + ',' + here.lon +
      '&radius=' + radius + '&limit=' + limit + '&oauth_token=' + config.foursquare.token + '&v=20120519'
    request apiquery, (error, response, body) ->
      center = computeCenter parseApiResp JSON.parse body
      res =
        bearing: here.bearingTo center
        direction: here.directionTo center
      resp.serveJSON res

apiserver.addModule('1', 'arrow', arrowModule)
