const { Router } = require('express');
const router = Router();

const { index, getclientes, registrar_cliente} = require('../controllers/index.controller');

router.get('/', index);
router.get('/cliente', getclientes);
router.post('/registrar_cliente', registrar_cliente);

module.exports = router;