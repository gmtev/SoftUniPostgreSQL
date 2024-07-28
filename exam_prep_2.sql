1 -
CREATE TABLE addresses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(10) NOT NULL
);

CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL
);

CREATE TABLE drivers (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    age INTEGER CHECK (age > 0) NOT NULL,
    rating NUMERIC(3, 2) DEFAULT 5.5
);

CREATE TABLE cars (
    id SERIAL PRIMARY KEY,
    make VARCHAR(20) NOT NULL,
    model VARCHAR(20),
    year INTEGER DEFAULT 0 CHECK (year > 0) NOT NULL,
    mileage INTEGER DEFAULT 0 CHECK (mileage > 0),
    condition CHAR(1) NOT NULL,
    category_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    from_address_id INTEGER NOT NULL,
    start TIMESTAMP NOT NULL,
    bill NUMERIC(10, 2) DEFAULT 10 CHECK (bill > 0),
    car_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    FOREIGN KEY (from_address_id) REFERENCES addresses(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS cars_drivers (
  car_id INT NOT NULL,
  driver_id INT NOT NULL,
  CONSTRAINT fk_cars_drivers_cars
	FOREIGN KEY (car_id) 
	REFERENCES cars("id")
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  CONSTRAINT fk_cars_drivers_drivers
	FOREIGN KEY (driver_id) 
	REFERENCES drivers("id")
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

2 -
INSERT INTO clients (full_name, phone_number)
SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    CONCAT('(088) 9999', id * 2) AS phone_number
FROM 
    drivers
WHERE 
    id BETWEEN 10 AND 20;

3 - 
UPDATE cars
SET condition = 'C'
WHERE (mileage >= 800000 OR mileage IS NULL)
    AND year <= 2010
    AND make != 'Mercedes-Benz';

4 - 
DELETE FROM clients
WHERE id NOT IN (
    SELECT DISTINCT client_id
    FROM courses
)
AND LENGTH(full_name) > 3;

5 -
SELECT make, model, condition
FROM cars
ORDER BY id ASC;

6- 
SELECT 
    d.first_name, 
    d.last_name, 
    c.make, 
    c.model, 
    c.mileage
FROM 
    drivers d
JOIN 
    cars_drivers cd ON d.id = cd.driver_id
JOIN 
    cars c ON cd.car_id = c.id
WHERE 
    c.mileage IS NOT NULL
ORDER BY 
    c.mileage DESC, 
    d.first_name ASC;

7 - 
SELECT 
    c.id,
    c.make,
	c.mileage,
    COUNT(cs.id) AS count_of_courses,
    ROUND(AVG(cs.bill), 2) AS average_bill
FROM 
    cars as c
LEFT JOIN 
    courses as cs ON c.id = cs.car_id
GROUP BY 
    c.id, c.make, c.model
HAVING 
    COUNT(cs.id) != 2
ORDER BY 
    count_of_courses DESC, 
    c.id ASC;

8 - 
SELECT 
    cl.full_name,
    COUNT(DISTINCT cs.car_id) AS count_of_cars,
    SUM(cs.bill) AS total_sum
FROM 
    clients cl
JOIN 
    courses cs ON cl.id = cs.client_id
WHERE 
    SUBSTRING(cl.full_name, 2, 1) = 'a'
GROUP BY 
    cl.full_name
HAVING 
    COUNT(DISTINCT cs.car_id) > 1
ORDER BY 
    cl.full_name;

9 - 
SELECT 
    a.name AS address,
    CASE
        WHEN EXTRACT(HOUR FROM cs.start) BETWEEN 6 AND 20 THEN 'Day'
        ELSE 'Night'
    END AS day_time,
    cs.bill,
    cl.full_name,
    ca.make,
    ca.model,
    cat.name AS category_name
FROM 
    courses cs
JOIN 
    addresses a ON cs.from_address_id = a.id
JOIN 
    clients cl ON cs.client_id = cl.id
JOIN 
    cars ca ON cs.car_id = ca.id
JOIN 
    categories cat ON ca.category_id = cat.id
ORDER BY 
    cs.id;

10 - 
CREATE OR REPLACE FUNCTION fn_courses_by_client(phone_num VARCHAR(20))
RETURNS INTEGER AS $$
DECLARE
    course_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO course_count
    FROM courses c
    JOIN clients cl ON c.client_id = cl.id
    WHERE cl.phone_number = phone_num;

    RETURN course_count;
END;
$$ LANGUAGE plpgsql;

11 -
CREATE TABLE search_results (
    id SERIAL PRIMARY KEY,
    address_name VARCHAR(50),
    full_name VARCHAR(100),
    level_of_bill VARCHAR(20),
    make VARCHAR(30),
    condition CHAR(1),
    category_name VARCHAR(50)
);

CREATE OR REPLACE PROCEDURE sp_courses_by_address(address_name VARCHAR(100))
LANGUAGE plpgsql
AS $$
BEGIN
    -- Clear previous results
    TRUNCATE TABLE search_results;

    -- Insert new results
    INSERT INTO search_results (address_name, full_name, level_of_bill, make, condition, category_name)
    SELECT
        a.name AS address_name,
        cl.full_name AS full_name,
        CASE
            WHEN cs.bill <= 20 THEN 'Low'
            WHEN cs.bill <= 30 THEN 'Medium'
            ELSE 'High'
        END AS level_of_bill,
        ca.make AS make,
        ca.condition AS condition,
        cat.name AS category_name
    FROM
        addresses a
    JOIN
        courses cs ON a.id = cs.from_address_id
    JOIN
        clients cl ON cs.client_id = cl.id
    JOIN
        cars ca ON cs.car_id = ca.id
    JOIN
        categories cat ON ca.category_id = cat.id
    WHERE
        a.name = address_name
    ORDER BY
        ca.make,
        cl.full_name;

END;
$$;