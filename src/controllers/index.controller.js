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
const getclientes = async (req, res) => {
    const query = 'SELECT * FROM clientes';
    const response = pool.query(query, (error, result) => {
        if (error) {
            throw error;
        }
        res.render('registrar_cliente', { date_clientes: result.rows });
    });
};

const registrar_cliente = async(req, res) => {
    const { nombre, apellido, telefono, email, direccion, pais} = req.body;
    const response = await pool.query('SELECT registrar_cliente($1, $2, $3, $4, $5, $6)', 
    [nombre, apellido, telefono, email, direccion, pais]);
    res.redirect('/cliente');
};

module.exports = {
    index,
    getclientes,
    registrar_cliente
};