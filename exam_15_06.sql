1 -
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    username VARCHAR(30) NOT NULL UNIQUE,
    password VARCHAR(30) NOT NULL,
    email VARCHAR(50) NOT NULL,
    gender CHAR(1) NOT NULL CHECK (gender IN ('M', 'F')),
    age INTEGER NOT NULL CHECK (age BETWEEN 0 AND 2147483647),
    job_title VARCHAR(40) NOT NULL,
    ip VARCHAR(30) NOT NULL
);

CREATE TABLE addresses (
    id SERIAL PRIMARY KEY,
    street VARCHAR(30) NOT NULL,
    town VARCHAR(30) NOT NULL,
    country VARCHAR(30) NOT NULL,
    account_id INTEGER NOT NULL,
    CONSTRAINT fk_ad_ac
    FOREIGN KEY (account_id)
 	REFERENCES accounts(id)
 	ON DELETE CASCADE
 	ON UPDATE CASCADE
);

CREATE TABLE photos (
    id SERIAL PRIMARY KEY,
    description TEXT,
    capture_date TIMESTAMP NOT NULL,
    views INTEGER DEFAULT 0 NOT NULL CHECK (views >= 0)
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    content VARCHAR(255) NOT NULL,
    published_on TIMESTAMP NOT NULL,
    photo_id INTEGER NOT NULL,
    CONSTRAINT fk_cm_ph
        FOREIGN KEY (photo_id) 
	REFERENCES photos(id)
	 ON DELETE CASCADE
	 ON UPDATE CASCADE,
);

CREATE TABLE accounts_photos (
    account_id INTEGER NOT NULL,
    photo_id INTEGER NOT NULL,
    CONSTRAINT pk_acc_photos
    PRIMARY KEY (account_id, photo_id),
    CONSTRAINT fk_acc_ac
        FOREIGN KEY (account_id) 
	REFERENCES accounts(id)
	 ON DELETE CASCADE
	 ON UPDATE CASCADE,
    CONSTRAINT fk_acc_ph
        FOREIGN KEY (photo_id)
	 REFERENCES photos(id)
	 ON DELETE CASCADE
	 ON UPDATE CASCADE
);

CREATE TABLE likes (
    id SERIAL PRIMARY KEY,
    photo_id INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
	CONSTRAINT fk_photo
	    FOREIGN KEY (photo_id)
		REFERENCES photos(id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	CONSTRAINT fk_account
    	FOREIGN KEY (account_id)
		REFERENCES accounts(id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);
2 -
INSERT INTO 
	addresses (street, town, country, account_id)
SELECT 
	username, password, ip, age
FROM 
	accounts
WHERE 
	gender = 'F';

3 - 
UPDATE 
	addresses
SET 
	country = CASE
    WHEN country LIKE 'B%' THEN 'Blocked'
    WHEN country LIKE 'T%' THEN 'Test'
    WHEN country LIKE 'P%' THEN 'In Progress'
    ELSE country
END;

4 - 
DELETE FROM addresses
WHERE id % 2 = 0
AND street ILIKE '%r%';

5 - 
SELECT 
	username, gender, age
FROM 
	accounts
WHERE 
	age >= 18 AND LENGTH(username) > 9
ORDER BY 
	age DESC, username ASC;

6 - 
SELECT
 p.id AS photo_id,
 p.capture_date,
 p.description,
 COUNT(c.id) AS comments_count
FROM 
	photos as p
JOIN 
	comments as c ON p.id = c.photo_id
WHERE
	p.description IS NOT NULL
GROUP BY
	p.id, p.capture_date, p.description
ORDER BY 
	comments_count DESC, photo_id ASC
LIMIT 3;

7 - 
SELECT
	a.id || ' ' || a.username AS id_username, a.email
FROM 
	accounts as a
JOIN
	accounts_photos as ap ON a.id = ap.account_id
JOIN
	photos as p ON ap.photo_id = p.id
WHERE 
	a.id = p.id
ORDER BY 
	a.id ASC;

8 - 
SELECT 
	p.id AS photo_id,
        COUNT(DISTINCT l.id) AS likes_count,
        COUNT(DISTINCT c.id) AS comments_count
FROM 
	photos as p
LEFT JOIN 
	likes as l ON p.id = l.photo_id
LEFT JOIN 
	comments as c ON p.id = c.photo_id
GROUP BY 
	p.id
ORDER BY 
	likes_count DESC, comments_count DESC, photo_id ASC;

9 - 
SELECT 
	COALESCE(LEFT(description, 10) || '...', '...') AS summary,
       TO_CHAR(capture_date, 'DD.MM HH24:MI') AS date
FROM 
	photos
WHERE 
	EXTRACT(DAY FROM capture_date) = 10
ORDER BY 
	capture_date DESC;

10 - 
CREATE OR REPLACE FUNCTION udf_accounts_photos_count(account_username VARCHAR(30))
RETURNS INTEGER AS $$
DECLARE
    photo_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO photo_count
    FROM accounts AS a
    JOIN accounts_photos AS ap ON a.id = ap.account_id
    JOIN photos AS p ON ap.photo_id = p.id
    WHERE a.username = account_username;

    RETURN photo_count;
END;
$$ LANGUAGE plpgsql;

11 - 
CREATE OR REPLACE PROCEDURE udp_modify_account(
    address_street VARCHAR(30),
    address_town VARCHAR(30)
)
AS $$
BEGIN
    UPDATE accounts
    SET job_title = '(Remote) ' || job_title
    WHERE id IN (
        SELECT a.id
        FROM accounts AS a
        JOIN addresses AS ad ON a.id = ad.account_id
        WHERE ad.street = address_street
        AND ad.town = address_town
    );
END;
$$
LANGUAGE plpgsql;