
-- PA logica del Sistema Hotel

 -- PA para registrar un cliente (insert en T clientes)
 
CREATE OR REPLACE FUNCTION registrar_cliente(nombre text, apellido text, telefono int, email text, direccion text, pais text) 
RETURNS void AS 
$$
BEGIN

insert into clientes values (default, nombre, apellido,  validar_telefono(telefono), email, direccion, pais);
END
$$
LANGUAGE plpgsql;

select registrar_cliente('chin-no', 'hong', 70207967, 'e@gmail.com', null, 'Nueva Zelanda');

-- validar nombre y apellido

CREATE OR REPLACE FUNCTION validateNombreyApelldo()
RETURNS TRIGGER AS $$
BEGIN
	IF (new.nombre !~ '^[A-Za-z]') THEN
		raise exception 'el nombre tiene numeros o simbolos raros';
	ELSEIF (new.apellido_paterno !~ '^[A-Za-z]') THEN
		raise exception 'el apellido tiene numeros o simbolos raros';
	ELSE
		RETURN NEW;
	END IF;
END
$$
LANGUAGE plpgsql

CREATE TRIGGER validateNombreyApelldo_cliente AFTER INSERT OR DELETE
ON clientes FOR EACH ROW EXECUTE PROCEDURE validateNombreyApelldo();


-- validar telefono

CREATE OR REPLACE FUNCTION validar_telefono(telefono integer)
RETURNS TEXT AS
$$
DECLARE
telefono_en_texto TEXT := telefono::TEXT;
telefono_return TEXT;
BEGIN
	
	telefono_return :=  '(' || substring(telefono_en_texto,1,3) || ') ' || substring(telefono_en_texto,4,3) || '-' || substring(telefono_en_texto,7); 
	return telefono_return;

END
$$
LANGUAGE plpgsql;

select validar_telefono(1234567890);

-- trigger para insertar codigo de telefono 

CREATE OR REPLACE FUNCTION trigger_poner_codigo_telefono()
RETURNS TRIGGER as 
$$
DECLARE 
codigo_telefono_cliente TEXT := (SELECT nacionalidades.codigo_telefono FROM nacionalidades 
					  join clientes  on clientes.pais = nacionalidades.pais WHERE cliente_id = new.cliente_id);
					  
telefono_con_codigo TEXT := codigo_telefono_cliente || new.telefono;

BEGIN
	
	UPDATE clientes SET telefono = telefono_con_codigo WHERE cliente_id = new.cliente_id;
	
	RETURN new;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_poner_codigo_telefono
 AFTER INSERT ON clientes
 FOR EACH ROW
 EXECUTE PROCEDURE trigger_poner_codigo_telefono();
 
 -- validar correo
 CREATE OR REPLACE FUNCTION validateEmail()
RETURNS TRIGGER AS $$
BEGIN
	IF (new.email !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9-]+[.][A-Za-z]+$') THEN
		raise exception 'el correo no cumple con el formato';
	ELSE
		RETURN NEW;
	END IF;
END
$$
LANGUAGE plpgsql

CREATE TRIGGER validateEmail_cliente AFTER INSERT OR DELETE
ON clientes FOR EACH ROW EXECUTE PROCEDURE validateEmail();
 
-- Funcion para insertar reserva_habitaciones

CREATE OR REPLACE FUNCTION registrar_reservas_habitaciones
(var_cliente_id int, var_numero_habitacion int, var_fecha_entrada date, var_fecha_salida date) 
RETURNS VOID as 
$$  
BEGIN
	
	IF var_fecha_entrada < current_date then raise exception 'esa fecha ya paso';
	
	ELSEIF var_fecha_salida <= var_fecha_entrada 
	then raise exception 'la fecha de salida es anterior que la de entrada o es el mismo dia';
	
	ELSEIF var_fecha_entrada = (SELECT fecha_entrada from reservas_habitaciones 
								 WHERE fecha_entrada = var_fecha_entrada AND numero_habitacion = var_numero_habitacion) 
								 THEN raise exception 'esa habitacione ya esta ocupada';	
								 
	ELSE 
	
	insert into reservas_habitaciones(reserva_id, fecha_entrada, fecha_salida, cliente_id, numero_habitacion) 
	values (DEFAULT, var_fecha_entrada, var_fecha_salida,var_cliente_id,var_numero_habitacion);
	
	END IF;
	
END
$$
LANGUAGE plpgsql;


-- trigger para insertar el precio de la habitacion en reserva_habitacion

CREATE OR REPLACE FUNCTION insertar_precio_en_reservas_habitaciones()
RETURNS TRIGGER as 
$$
DECLARE 
precio_habitacion_extraido numeric := (SELECT TH.precio_habitacion FROM habitaciones H 
							 JOIN tipo_habitaciones TH ON H.nombre_tipo_habitacion = TH.nombre
							 WHERE H.numero_habitacion = new.numero_habitacion);
BEGIN
	
	UPDATE reservas_habitaciones SET precio_habitacion = precio_habitacion_extraido WHERE numero_habitacion = new.numero_habitacion;
	
	RETURN new;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER insertar_precio_en_reservas_habitaciones
 AFTER INSERT ON reservas_habitaciones
 FOR EACH ROW
 EXECUTE PROCEDURE insertar_precio_en_reservas_habitaciones();
 
 
 -- check_in
CREATE OR REPLACE FUNCTION check_in
(var_reserva_id int, var_check_in date, servicios int[]) 
RETURNS VOID as 
$$
DECLARE 
var_fecha_entrada_reserva date := (select fecha_entrada from reservas_habitaciones RH WHERE RH.reserva_id = var_reserva_id);
var_cuenta_cliente_id int ;
var_precio_servicio numeric;

BEGIN
	IF var_check_in < var_fecha_entrada_reserva OR var_check_in > var_fecha_entrada_reserva THEN raise exception 'NO TIENE UNA RESERVA';
	
	ELSEIF (select exists (SELECT * FROM cuentas_clientes WHERE reserva_id = var_reserva_id)) AND var_fecha_entrada_reserva = var_check_in
	THEN raise exception 'ya hizo un check-in con esta reserva'; 
	
	ELSE INSERT INTO cuentas_clientes(cuenta_cliente_id, check_in, pagado, reserva_id) 
	VALUES (default, var_check_in, false, var_reserva_id);
	END IF;
	
	-- registrar servicios en la tabla servicios_consumidos
	
	FOR i IN array_lower(servicios,1) .. array_upper(servicios,1) LOOP
	var_cuenta_cliente_id := (SELECT cuenta_cliente_id FROM cuentas_clientes WHERE reserva_id = var_reserva_id);
	var_precio_servicio := (SELECT precio FROM servicios S WHERE S.servicio_id = servicios[i]);
	INSERT INTO servicios_consumidos(cuentas_clientes_id,servicio_id,precio_servicio) VALUES(var_cuenta_cliente_id, servicios[i],     var_precio_servicio);
	END LOOP;
	
END
$$
LANGUAGE plpgsql;

-- SELECT check_in(2, '2020-11-24', array[1,2,3,4,5]);

-- check_out
CREATE OR REPLACE FUNCTION check_out
(var_reserva_id int, var_check_out date) 
RETURNS VOID as 
$$
DECLARE 

fecha_entrada_reserva date := (select fecha_entrada from reservas_habitaciones RH WHERE RH.reserva_id = var_reserva_id);
fecha_salida_reserva date := (select fecha_salida from reservas_habitaciones RH WHERE RH.reserva_id = var_reserva_id);

precio_habitacion numeric := (select precio_habitacion from reservas_habitaciones RH WHERE RH.reserva_id = var_reserva_id);

monto_servicios numeric := (SELECT SUM(precio_servicio) 
							FROM public.servicios_consumidos SC JOIN public.cuentas_clientes CC 
							ON SC.cuentas_clientes_id = CC.cuenta_cliente_id WHERE CC.reserva_id = var_reserva_id);
							
monto_total numeric;

BEGIN
	
	IF fecha_salida_reserva < fecha_entrada_reserva then raise exception 'Esto no es posible';
	ELSE
	monto_total := (((fecha_salida_reserva-fecha_entrada_reserva)*precio_habitacion)+ monto_servicios);
	UPDATE cuentas_clientes SET check_out=var_check_out, monto = monto_total, pagado = true WHERE reserva_id = var_reserva_id;
	END IF; 
	
END
$$
LANGUAGE plpgsql;

SELECT check_out(2, '2020-11-21');


-- Reportes

-- mostrar habitaciones disponibles entre tal fecha y tal fecha

CREATE OR REPLACE FUNCTION mostrar_habitaciones_disponibles(entrada DATE, salida DATE)
RETURNS TABLE(numero INT,tipo TEXT,camas TEXT, terraza boolean, precio NUMERIC) AS
$$
DECLARE
fila RECORD;
BEGIN
    FOR fila IN SELECT H.numero_habitacion, H.nombre_tipo_habitacion, RH.fecha_entrada,RH.fecha_salida,T.camas, T.balcon,T.precio_habitacion FROM habitaciones H  
		LEFT JOIN reservas_habitaciones RH on H.numero_habitacion = RH.numero_habitacion AND ((entrada BETWEEN RH.fecha_entrada AND rh.fecha_salida) OR 
										          (salida BETWEEN rh.fecha_entrada AND rh.fecha_salida))
		JOIN  tipo_habitaciones T ON T.nombre = H.nombre_tipo_habitacion ORDER BY 1 asc
		LOOP
	numero:=fila.numero_habitacion;
	tipo:=fila.nombre_tipo_habitacion;
	camas:= fila.camas;
	terraza := fila.balcon;
	precio:= fila.precio_habitacion;
	RETURN NEXT;
    END LOOP;
END
$$
LANGUAGE plpgsql;

select * from mostrar_habitaciones_disponibles(current_date, '2020-11-30');

-- mostra habitaciones reservadas

CREATE OR REPLACE FUNCTION habitaciones_reservadas(entrada DATE, salida DATE)
RETURNS TABLE(numero INT,tipo TEXT,camas TEXT, reservada TEXT, balcon boolean, precio NUMERIC) AS
$$
DECLARE
fila RECORD;
BEGIN
    FOR fila IN SELECT H.numero_habitacion, H.nombre_tipo_habitacion,RH.fecha_entrada,RH.fecha_salida,T.camas, T.balcon,T.precio_habitacion FROM habitaciones H  
		LEFT JOIN reservas_habitaciones RH on H.numero_habitacion=RH.numero_habitacion AND ((entrada BETWEEN rh.fecha_entrada AND rh.fecha_salida) OR 
										          (salida BETWEEN rh.fecha_entrada AND rh.fecha_salida))
		JOIN  tipo_habitaciones T ON T.nombre = H. nombre_tipo_habitacion ORDER BY 1 asc
		LOOP
	numero:=fila.numero_habitacion;
	tipo:=fila. nombre_tipo_habitacion;
	camas:= fila.camas;
	balcon := fila.balcon;
	precio:= fila.precio_habitacion;
	IF (entrada between fila.fecha_entrada and fila.fecha_salida) OR (salida between fila.fecha_entrada and fila.fecha_salida) THEN
		reservada:='SI';
	ELSE 
		reservada:='NO';
	END IF;
	RETURN NEXT;
    END LOOP;
END
$$
LANGUAGE plpgsql;

select * from habitaciones_reservadas(current_date, current_date+3);

-- mostrar cliente y el gasto total que ha realizado en el hotel
CREATE OR REPLACE FUNCTION gasto_cliente()
RETURNS TABLE(v_codigo INT,v_nombre TEXT,v_servicios TEXT,v_monto INT) AS
$$
DECLARE 
fila_RH RECORD;
fila_g RECORD;
BEGIN
    FOR fila_RH IN  SELECT cliente_id FROM reservas_habitaciones  GROUP BY (cliente_id) LOOP
	v_codigo:=fila_RH.cliente_id;
	v_nombre:=(select nombre||' '||apellido_paterno from clientes where cliente_id=fila_RH.cliente_id);
	
        v_monto:=(select monto FROM cuentas_clientes cc);
			
	v_servicios :=(select string_agg(distinct s.nombre,' - ')from servicios s 
				    JOIN servicios_consumidos sc  on sc.servicio_id = s.servicio_id );
        RETURN NEXT;
    END LOOP;
END
$$
LANGUAGE plpgsql;

SELECT * FROM gasto_cliente();


-- logs 
-- log de todas las tablas
CREATE TABLE logs (
	id_log TEXT,
	origen TEXT,
	operacion TEXT,
	fecha TIMESTAMP,
	usuario TEXT,
	ip INET
);

CREATE OR REPLACE FUNCTION log_hotel() 
RETURNS TRIGGER AS
$$
BEGIN
    IF (TG_OP='INSERT' OR TG_OP='UPDATE') THEN
	IF(TG_TABLE_NAME = 'clientes') THEN
	  INSERT INTO logs VALUES ( NEW.cliente_id::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
	ELSEIF(TG_TABLE_NAME = 'cuentas_clientes') THEN
          INSERT INTO logs VALUES ( NEW.cuenta_cliente_id::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER,(select inet_client_addr()));
        
        ELSIF(TG_TABLE_NAME = 'habitaciones') THEN
	  INSERT INTO logs VALUES ( NEW.numero_habitacion::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
	ELSIF(TG_TABLE_NAME = 'nacionalidades') THEN
	  INSERT INTO logs VALUES ( NEW.pais::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));

        ELSIF(TG_TABLE_NAME = 'reservas_habitaciones') THEN
	  INSERT INTO logs VALUES ( NEW.reserva_id::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	
	ELSIF(TG_TABLE_NAME = 'servicios') THEN
	  INSERT INTO logs VALUES ( NEW.id_servicios::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
	ELSIF(TG_TABLE_NAME = 'servicios_consumidos') THEN
	  INSERT INTO logs VALUES ( NEW.servicios_consumidos_id::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
	ELSIF(TG_TABLE_NAME = 'tipo_habitaciones') THEN
	  INSERT INTO logs VALUES ( NEW.nombre::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	
	END IF;
	RETURN NEW;
    END IF;
    
    IF (TG_OP='DELETE') THEN
	
        IF(TG_TABLE_NAME = 'clientes') THEN
	  INSERT INTO logs VALUES ( OLD.cliente_id::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
	ELSEIF(TG_TABLE_NAME = 'cuentas_clientes') THEN
          INSERT INTO logs VALUES ( OLD.cuenta_cliente_id::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER,(select inet_client_addr()));
        
        ELSIF(TG_TABLE_NAME = 'habitaciones') THEN
	  INSERT INTO logs VALUES ( OLD.numero_habitacion::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
	ELSIF(TG_TABLE_NAME = 'nacionalidades') THEN
	  INSERT INTO logs VALUES ( OLD.pais::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
        ELSIF(TG_TABLE_NAME = 'reservas_habitaciones') THEN
	  INSERT INTO logs VALUES ( OLD.reserva_id::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	
	ELSIF(TG_TABLE_NAME = 'servicios') THEN
	  INSERT INTO logs VALUES ( OLD.id_servicios::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
	ELSIF(TG_TABLE_NAME = 'servicios_consumidos') THEN
	  INSERT INTO logs VALUES ( OLD.servicios_consumidos_id::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	 
	ELSIF(TG_TABLE_NAME = 'tipo_habitaciones') THEN
	  INSERT INTO logs VALUES ( OLD.nombre::TEXT, TG_TABLE_NAME, TG_OP, CURRENT_TIMESTAMP, CURRENT_USER, (select inet_client_addr()));
	
	END IF;
    RETURN OLD;
   END IF;
END;
$$ 
LANGUAGE 'plpgsql';

CREATE TRIGGER tg_hotel_clientes AFTER INSERT OR DELETE
ON clientes FOR EACH ROW EXECUTE PROCEDURE log_hotel();


CREATE TRIGGER tg_hotel_cuentas_clientes AFTER INSERT OR DELETE
ON  cuentas_clientes FOR EACH ROW EXECUTE PROCEDURE log_hotel();


CREATE TRIGGER tg_hotel_habitaciones AFTER INSERT OR DELETE
ON habitaciones FOR EACH ROW EXECUTE PROCEDURE log_hotel();


CREATE TRIGGER tg_hotel_nacionalidades AFTER INSERT OR DELETE
ON nacionalidades FOR EACH ROW EXECUTE PROCEDURE log_hotel();


CREATE TRIGGER tg_hotel_reservas_habitaciones AFTER INSERT OR DELETE
ON reservas_habitaciones FOR EACH ROW EXECUTE PROCEDURE log_hotel();


CREATE TRIGGER tg_hotel_servicios AFTER INSERT OR DELETE
ON servicios FOR EACH ROW EXECUTE PROCEDURE log_hotel();


CREATE TRIGGER tg_hotel_servicios_consumidos AFTER INSERT OR DELETE
ON servicios_consumidos FOR EACH ROW EXECUTE PROCEDURE log_hotel();

CREATE TRIGGER tg_hotel_tipo_habitaciones AFTER INSERT OR DELETE
ON tipo_habitaciones FOR EACH ROW EXECUTE PROCEDURE log_hotel();