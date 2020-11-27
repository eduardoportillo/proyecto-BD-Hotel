CREATE DATABASE hotel_proyecto_final_bd;

\c hotel_proyecto_final_bd;

CREATE TABLE public.clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre text NOT NULL,
    apellido_paterno text NOT NULL,
    telefono text NOT NULL,
    email text NOT NULL,
    direccion text,
    pais text NOT NULL
);


CREATE TABLE public.cuentas_clientes (
    cuenta_cliente_id SERIAL PRIMARY KEY,
    check_in date NOT NULL,
    check_out date,
    monto numeric,
    pagado boolean NOT NULL,
    reserva_id integer,
    --servicios_consumidos_id integer
);


CREATE TABLE public.habitaciones (
    numero_habitacion SERIAL NOT NULL PRIMARY KEY,
    piso integer NOT NULL,
    nombre_tipo_habitacion text
);


CREATE TABLE public.nacionalidades (
    pais text NOT NULL PRIMARY KEY,
    codigo_telefono TEXT NOT NULL
);


CREATE TABLE public.reservas_habitaciones (
    reserva_id SERIAL NOT NULL PRIMARY KEY,
    fecha_entrada date NOT NULL,
    fecha_salida date NOT NULL,
    precio_habitacion numeric(8,2),
    cliente_id integer,
    numero_habitacion integer
);



CREATE TABLE public.servicios (
    servicio_id SERIAL NOT NULL PRIMARY KEY,
    nombre text NOT NULL,
    precio numeric(8,2) NOT NULL,
    descripcion text
);


CREATE TABLE public.servicios_consumidos (
    servicios_consumidos_id SERIAL NOT NULL PRIMARY KEY,
    cuentas_clientes_id integer,
    servicio_id integer,
    precio_servicio numeric NOT NULL
);


CREATE TABLE public.tipo_habitaciones (
    nombre text NOT NULL PRIMARY KEY,
    camas text NOT NULL,
    balcon boolean NOT NULL,
    precio_habitacion numeric(8,2)
);


-- llaves foraneas

ALTER TABLE clientes ADD  FOREIGN KEY (pais) REFERENCES nacionalidades(pais);

ALTER TABLE reservas_habitaciones ADD  FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id);

ALTER TABLE reservas_habitaciones ADD  FOREIGN KEY (numero_habitacion) REFERENCES habitaciones(numero_habitacion);

ALTER TABLE habitaciones ADD  FOREIGN KEY (nombre_tipo_habitacion) REFERENCES tipo_habitaciones(nombre);

ALTER TABLE cuentas_clientes ADD  FOREIGN KEY (reserva_id) REFERENCES reservas_habitaciones(reserva_id);

ALTER TABLE servicios_consumidos ADD  FOREIGN KEY (cuentas_clientes_id) REFERENCES cuentas_clientes(cuenta_cliente_id);

ALTER TABLE servicios_consumidos ADD  FOREIGN KEY (servicio_id) REFERENCES servicios(servicio_id);

