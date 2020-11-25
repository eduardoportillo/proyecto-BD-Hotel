const { Pool } = require('pg');
const { json } = require('express');

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    password: '8450706183',
    database: 'hotel_proyecto_final_bd',
    port: '5432' 
});


// PA registrar_clientes

const getclientes = async (req, res) => {
    const response = await pool.query('SELECT * FROM clientes');
    return res.status(200).json(response.rows);
};

const registrar_cliente = async(req, res) => {
    const { nombre, apellido, telefono, email, direccion, pais} = req.body;
    const response = await pool.query('SELECT registrar_cliente($1, $2, $3, $4, $5, $6)', 
    [nombre, apellido, telefono, email, direccion, pais]);
    res.status(200).json();
};


module.exports = {

    getclientes,
    registrar_cliente
    
};