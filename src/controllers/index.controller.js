const { Pool } = require('pg');

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    password: '8450706183',
    database: 'hotel_proyecto_final_bd',
    port: '5432' 
});

const index = async (req, res) => {
    return res.render('index');
};


// metodos para tabla clientes
const getClientes = async (req, res) => {
    const query = 'SELECT * FROM clientes';
    const paises = await pool.query('SELECT pais from nacionalidades');
    const response = pool.query(query, (error, result) => {
        if (error) {
            throw error;
        }
        res.render('registrar_cliente', { 
            date_clientes: result.rows,
            data_paises: paises.rows
        });
    });
};

const registrarCliente = async(req, res) => {
    const { nombre, apellido, telefono, email, direccion, pais} = req.body;
    const response = await pool.query('SELECT registrar_cliente($1, $2, $3, $4, $5, $6)', 
    [nombre, apellido, telefono, email, direccion, pais]);
    res.redirect('/cliente');
};

const deleteCliente = async (req, res) => {
    const { id } = req.params;
    await pool.query('DELETE FROM clientes where cliente_id = $1', [id]);
    res.redirect('/cliente');
};

// metodo para tabla reserva_habitacion

const reservaHabitacion = async (req, res) => {
    const res_cliente = await pool.query('SELECT * FROM reservas_habitaciones RH join clientes C on C.cliente_id = RH.cliente_id');
    const get_clientes = await pool.query('SELECT * FROM clientes');
    const res_reserva_habitaciones = await pool.query('SELECT * FROM reservas_habitaciones order by reserva_id ASC');
    const habitaciones = await pool.query('select * from habitaciones H JOIN tipo_habitaciones TH ON H.nombre_tipo_habitacion = TH.nombre');
    res.render('registrar_reservas', {
        data_cliente: res_cliente.rows,
        data_reserva_habitaciones: res_reserva_habitaciones.rows,
        data_habitaciones: habitaciones.rows,
        data_get_clientes: get_clientes.rows
    })
};

const registrarReservaHabitacion = async (req, res) => {
    const { var_cliente_id, var_numero_habitacion, var_fecha_entrada, var_fecha_salida } = req.body;
    const query = await pool.query('SELECT registrar_reservas_habitaciones($1,$2,$3,$4)', 
    [var_cliente_id, var_numero_habitacion, var_fecha_entrada, var_fecha_salida]);
    res.redirect('/reserva_habitaciones');
};

const deleteReserva = async (req, res) => {
    const { reserva_id } = req.params;
    await pool.query('DELETE from reservas_habitaciones	where reserva_id = $1', [reserva_id]);
    res.redirect('/reserva_habitaciones');
};

// metodos para tabla consumo

const check_in = async (req, res) => {
    const reserva_habitaciones = await pool.query('SELECT reserva_id ,nombre, apellido_paterno FROM reservas_habitaciones RH join clientes C on RH.cliente_id = C.cliente_id');

    const servicios = await pool.query('select * from servicios');

    const cuentas_clientes = await pool.query('select * from cuentas_clientes order by cuenta_cliente_id asc');

    res.render('check_in-check_out', {
        data_reserva_habitaciones: reserva_habitaciones.rows,
        data_servicios: servicios.rows,
        data_cuentas_clientes: cuentas_clientes.rows
    })
};

const insertar_check_in = async (req, res) => {
    const servicios = [];
    const {var_reserva_id, var_check_in, servicios_resividos} = req.body;

    for (let i = 0; i < servicios_resividos.length; i++) {
        servicios.push(parseInt(servicios_resividos[i]));
    }

    const insert_check_in = await pool.query('select check_in($1, $2, $3)', [var_reserva_id, var_check_in, servicios]);

    res.redirect('/chek-in_check-out');
};

const insert_check_out = async (req, res) => {

    const {var_reserva_id,  var_check_out} = req.body;
    const insert_check_out = await pool.query('SELECT check_out($1, $2)', [var_reserva_id, var_check_out]);

    res.redirect('/chek-in_check-out');
};

// tabla log

const tabla_log = async (req, res) => {
    const tabla_log = await pool.query('select * from logs');
    res.render('tabla_log', {
        data_tabla_log: tabla_log.rows
    })
};

module.exports = {
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
};