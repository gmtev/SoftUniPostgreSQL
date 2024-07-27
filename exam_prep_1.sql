1 -
CREATE TABLE owners (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    address VARCHAR(50)
);

CREATE TABLE animal_types (
    id SERIAL PRIMARY KEY,
    animal_type VARCHAR(30) NOT NULL
);

CREATE TABLE cages (
    id SERIAL PRIMARY KEY,
    animal_type_id INT NOT NULL,
    FOREIGN KEY (animal_type_id) REFERENCES animal_types(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE animals (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    birthdate DATE NOT NULL,
    owner_id INT,
    animal_type_id INT NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (animal_type_id) REFERENCES animal_types(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE volunteers_departments (
    id SERIAL PRIMARY KEY,
    department_name VARCHAR(30) NOT NULL
);

CREATE TABLE volunteers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    address VARCHAR(50),
    animal_id INT,
    department_id INT NOT NULL,
    FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (department_id) REFERENCES volunteers_departments(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE animals_cages (
    cage_id INT NOT NULL,
    animal_id INT NOT NULL,
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE CASCADE ON UPDATE CASCADE
);

2 -
INSERT INTO volunteers (name, phone_number, address, animal_id, department_id) VALUES
('Anita Kostova', '0896365412', 'Sofia, 5 Rosa str.', 15, 1),
('Dimitur Stoev', '0877564223', NULL, 42, 4),
('Kalina Evtimova', '0896321112', 'Silistra, 21 Breza str.', 9, 7),
('Stoyan Tomov', '0898564100', 'Montana, 1 Bor str.', 18, 8),
('Boryana Mileva', '0888112233', NULL, 31, 5);

INSERT INTO animals (name, birthdate, owner_id, animal_type_id) VALUES
('Giraffe', '2018-09-21', 21, 1),
('Harpy Eagle', '2015-04-17', 15, 3),
('Hamadryas Baboon', '2017-11-02', NULL, 1),
('Tuatara', '2021-06-30', 2, 4);

3 - 
UPDATE 
	animals
SET 
	owner_id = (SELECT id FROM owners WHERE name = 'Kaloqn Stoqnov')
WHERE 
	owner_id IS NULL;

4 - 
DELETE FROM 
	volunteers_departments
WHERE 
	department_name = 'Education program assistant';

5 - 
SELECT 
	v.name, v.phone_number, v.address, v.animal_id, v.department_id
FROM 
	volunteers v
ORDER BY 
	v.name ASC, v.animal_id ASC, v.department_id ASC;

6 - 
SELECT 
	a.name, at.animal_type, TO_CHAR(a.birthdate, 'DD.MM.YYYY') AS birthdate
FROM 
	animals a
JOIN 
	animal_types at 
	ON 
	a.animal_type_id = at.id
ORDER BY 
	a.name ASC;

7 - 
SELECT 
	o.name, COUNT(*) AS count_of_animals
FROM 
	owners o
JOIN 
	animals a 
	ON 
	o.id = a.owner_id
GROUP BY 
	o.name
ORDER BY 
	count_of_animals DESC, o.name ASC
LIMIT 5;

8 - 
SELECT 
       CONCAT(o.name, ' - ', a.name) AS owner_animal,
       o.phone_number,
       ac.cage_id
FROM 
	owners o
JOIN 
	animals a 
	ON o.id = a.owner_id
JOIN 
	animal_types at ON a.animal_type_id = at.id
JOIN 
	animals_cages ac ON a.id = ac.animal_id
JOIN 
	cages c ON ac.cage_id = c.id
WHERE 
	at.animal_type = 'Mammals'
ORDER BY 
	o.name ASC, a.name DESC;

9 - 
SELECT 
	v."name" AS "volunteers", 
	v.phone_number,
	SUBSTRING(
		v.address, POSITION('Sofia' IN v.address) + 7
	) AS "address"
FROM 
	volunteers AS v
JOIN 
	volunteers_departments AS vd 
	ON 
	v.department_id = vd.id
WHERE 
	vd.department_name = 'Education program assistant'
	AND 
	v.address LIKE '%Sofia%'
ORDER BY 
	volunteers;

10 - 
SELECT 
       a.name as animal,
       EXTRACT(YEAR FROM birthdate) AS birth_year,
       at.animal_type
FROM 
	animals as a
JOIN 
	animal_types at 
	ON 
	a.animal_type_id = at.id
WHERE 
	a.owner_id IS NULL
    	AND 
	at.animal_type != 'Birds'
    	AND 
	EXTRACT(YEAR FROM birthdate) > 2016
ORDER BY 
	name ASC;

11 -
CREATE OR REPLACE FUNCTION fn_get_volunteers_count_from_department(searched_volunteers_department VARCHAR(30))
RETURNS INTEGER AS $$
DECLARE
    volunteer_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO volunteer_count
    FROM volunteers v
    JOIN volunteers_departments vd ON v.department_id = vd.id
    WHERE vd.department_name = searched_volunteers_department;

    RETURN volunteer_count;
END;
$$ LANGUAGE plpgsql;

12 -
CREATE OR REPLACE PROCEDURE sp_animals_with_owners_or_not(
    IN animal_name VARCHAR(30),
    OUT owner_name VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(o.name, 'For adoption')
    INTO owner_name
    FROM animals a
    LEFT JOIN owners o ON a.owner_id = o.id
    WHERE a.name = animal_name;
END;
$$;