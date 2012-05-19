ApiServer = require 'apiserver'

apiserver = new ApiServer()
apiserver.listen(3000, onListen)

onListen = (err) ->
  if err
    console.error('Something terrible happened: %s', err.message)
  else
    console.log('Successful bound to port %s', this.port)
    setTimeout(apiserver.close(onClose), 5000)

onClose = () -> console.log('port unbound correctly')
