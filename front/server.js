const express = require('express')
const app = express()
const port = 8000

app.use(express.static('dist'));
app.listen(port, '0.0.0.0', () => {
  console.log(`front app listening at http://0.0.0.0:${port}`)
})
