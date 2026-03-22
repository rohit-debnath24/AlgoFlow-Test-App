const express = require('express');
const app = express();
const port = process.env.PORT || 8080; // Flux usually targets 8080

app.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Hogya hogyaaa dobara!',
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`Test app listening on port ${port}`);
});
//test 1-init github
//test 2
//test-2
// test-3: final deployment check

//check test
//test-4
//test-5
// Final deployment verification push
