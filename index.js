const express = require('express');
const app = express();
const port = process.env.PORT || 8080; // Flux usually targets 8080

app.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Hello World! This app was successfully deployed to the decentralized Web3 Flux Network via AlgoFlow!',
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`Test app listening on port ${port}`);
});
//test 1234
