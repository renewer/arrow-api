ApiServer = require 'apiserver'
request = require 'request'

config =
  foursquare:
    apiurl: "https://api.foursquare.com/v2/"
    token: "JYBSAF3BGP33BECMOQJAPTYCHFNS0MDSQS5Y3KPWLU5FGKSD"

apiserver = new ApiServer()
apiserver.listen(3000, onListen)

onListen = (err) ->
  if err
    console.error('Something terrible happened: %s', err.message)
  else
    console.log('Successful bound to port %s', this.port)
    setTimeout(apiserver.close(onClose), 5000)

onClose = () -> console.log('port unbound correctly')

arrowModule =
  get: (req, resp) ->
    console.log req
    apiquery = config.foursquare.apiurl + 'venues/trending?ll=' +
      req.querystring.lat + ',' + req.querystring.lng +
      '&radius=500&limit=10&oauth_token=' + config.foursquare.token + '&v=20120519'
    request(apiquery, (error, response, body) ->
      resp.serveJSON(JSON.parse body))

apiserver.addModule('1', 'arrow', arrowModule)
