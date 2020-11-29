const { Router } = require('express');
const router = Router();

const { 
        index, 
        getClientes, 
        registrarCliente, 
        deleteCliente, 
        reservaHabitacion, 
        registrarReservaHabitacion
    } = require('../controllers/index.controller');

router.get('/', index);
router.get('/cliente', getClientes);
router.post('/registrar_cliente', registrarCliente);
router.get('/delete/:id', deleteCliente);

router.get('/reserva_habitaciones', reservaHabitacion);
router.post('/registrar_reserva_habitacion', registrarReservaHabitacion);

module.exports = router;