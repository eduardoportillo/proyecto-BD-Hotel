const { Router } = require('express');
const router = Router();

const { index, getClientes, registrarCliente, deleteCliente, reserva_habitacion} = require('../controllers/index.controller');

router.get('/', index);
router.get('/cliente', getClientes);
router.post('/registrar_cliente', registrarCliente);
router.get('/delete/:id', deleteCliente);

router.get('/reserva_habitaciones', reserva_habitacion);

module.exports = router;