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
    const res_cliente = await pool.query('SELECT * FROM clientes');
    const res_reserva_habitaciones = await pool.query('SELECT * FROM reservas_habitaciones');
    const habitaciones = await pool.query('SELECT * FROM habitaciones');
    res.render('registrar_reservas', {
        data_cliente: res_cliente.rows,
        data_reserva_habitaciones: res_reserva_habitaciones.rows,
        data_habitaciones: habitaciones.rows
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

module.exports = {
    index,
    getClientes,
    registrarCliente,
    deleteCliente,
    reservaHabitacion,
    registrarReservaHabitacion,
    deleteReserva
};