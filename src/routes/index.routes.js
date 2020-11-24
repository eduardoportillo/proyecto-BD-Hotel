const { Router } = require('express');
const router = Router();

const { registrar_cliente, getclientes } = require('../controllers/index.controller');

router.get('/get-cliente', getclientes);
router.post('/registrar-cliente', registrar_cliente);

module.exports = router;