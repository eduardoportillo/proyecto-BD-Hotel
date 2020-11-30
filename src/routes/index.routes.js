const { Router } = require('express');
const router = Router();

const { 
        index, 
        getClientes, 
        registrarCliente, 
        deleteCliente, 
        reservaHabitacion, 
        registrarReservaHabitacion,
        deleteReserva,
        check_in,
        insertar_check_in,
        insert_check_out,
        tabla_log
    } = require('../controllers/index.controller');

router.get('/', index);

router.get('/cliente', getClientes);
router.post('/registrar_cliente', registrarCliente);
router.get('/delete_cliente/:id', deleteCliente);

router.get('/reserva_habitaciones', reservaHabitacion);
router.post('/registrar_reserva_habitacion', registrarReservaHabitacion);
router.get('/delete_reserva_habitacion/:reserva_id', deleteReserva);

router.get('/chek-in_check-out', check_in);
router.post('/insertar-check-in', insertar_check_in);
router.post('/insertar-check-out', insert_check_out);

router.get('/tabla_log', tabla_log);

module.exports = router;