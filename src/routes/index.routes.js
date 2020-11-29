const { Router } = require('express');
const router = Router();

const { index, getClientes, registrarCliente, deleteCliente} = require('../controllers/index.controller');

router.get('/', index);
router.get('/cliente', getClientes);
router.post('/registrar_cliente', registrarCliente);
router.get('/delete/:id', deleteCliente);

module.exports = router;