-------- Slice & Dice Pizza Restaurant — Database Schema --------

-- Order of creation: parent tables first, junction tables last
-- Order of deletion: junction tables first, parent tables last

-------- drop tables -----------

DROP TABLE IF EXISTS order_drinks;
DROP TABLE IF EXISTS pizza_toppings;
DROP TABLE IF EXISTS order_pizzas;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS drinks;
DROP TABLE IF EXISTS toppings;
DROP TABLE IF EXISTS pizzas;
DROP TABLE IF EXISTS customers;

-------- tier 1 — main tables (no foreign keys) ------

CREATE TABLE customers (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  TEXT    NOT NULL,
  email TEXT    NOT NULL UNIQUE,
  phone TEXT
);

CREATE TABLE pizzas (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  base_price REAL NOT NULL CHECK (base_price >= 0)
);

CREATE TABLE toppings (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  extra_cost REAL NOT NULL DEFAULT 0 CHECK (extra_cost >= 0)
);

CREATE TABLE drinks (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  TEXT NOT NULL,
  price REAL NOT NULL CHECK (price >= 0)
);

-------- tier 2 — order tables (reference tier 1) --------

CREATE TABLE orders (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER  NOT NULL,
  order_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status      TEXT     NOT NULL DEFAULT 'pending',
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-------- tier 3 — junction tables (resolve N:M) --------

-------- orders <-> pizzas (N:M) --------
-- price_at_time stores a snapshot of the price when the order was placed — so old orders stay accurate even if menu prices change later

CREATE TABLE order_pizzas (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id      INTEGER NOT NULL,
  pizza_id      INTEGER NOT NULL,
  quantity      INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  price_at_time REAL    NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (pizza_id) REFERENCES pizzas(id)
);

-------- order_pizzas <-> toppings (N:M) --------
-- linked to order_pizzas so toppings are tied to a specific pizza in its specific order 

CREATE TABLE pizza_toppings (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  order_pizza_id INTEGER NOT NULL,
  topping_id     INTEGER NOT NULL,
  price_at_time  REAL    NOT NULL,
  FOREIGN KEY (order_pizza_id) REFERENCES order_pizzas(id),
  FOREIGN KEY (topping_id)     REFERENCES toppings(id)
);

-------- orders <-> drinks (N:M) --------
-- separated from order_pizzas cause they dont have toppings 

CREATE TABLE order_drinks (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id      INTEGER NOT NULL,
  drink_id      INTEGER NOT NULL,
  quantity      INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  price_at_time REAL    NOT NULL,
  FOREIGN KEY (order_id)  REFERENCES orders(id),
  FOREIGN KEY (drink_id)  REFERENCES drinks(id)
);

---------------  menu --------------------------

INSERT INTO pizzas (name, base_price)
VALUES
  ('Margherita',       45.00),
  ('Pepperoni',        52.00),
  ('Veggie Supreme',   48.00),
  ('BBQ Chicken',      55.00),
  ('Four Cheese',      50.00);


INSERT INTO toppings (name, extra_cost)
VALUES
  ('Olives',           2.00),
  ('Mushrooms',        3.00),
  ('Pepperoni',        5.00),
  ('Extra Cheese',     4.00),
  ('Sun-dried Tomato', 3.50),
  ('Jalapeños',        2.50);


INSERT INTO drinks (name, price)
VALUES
  ('Cola',             12.00),
  ('Sprite',           12.00),
  ('Orange Juice',     14.00),
  ('Water',             8.00),
  ('Iced Tea',         11.00);

--------------- test order placing  ----------------------

INSERT INTO customers VALUES (1,'Dana','dana@mail.com','050-1234567');
INSERT INTO orders VALUES (1,1,'2026-05-31 12:00:00','confirmed');
INSERT INTO order_pizzas VALUES (1,1,1,2,45.00);
INSERT INTO pizza_toppings VALUES (1,1,1,2.00);
INSERT INTO order_drinks VALUES (1,1,1,2,12.00);

-------------- test query -----------------------

SELECT c.name, p.name AS pizza, t.name AS topping, d.name AS drink
FROM customers c
JOIN orders o ON c.id = o.customer_id
JOIN order_pizzas op ON o.id = op.order_id
JOIN pizzas p ON op.pizza_id = p.id
JOIN pizza_toppings pt ON op.id = pt.order_pizza_id
JOIN toppings t ON pt.topping_id = t.id
JOIN order_drinks od ON o.id = od.order_id
JOIN drinks d ON od.drink_id = d.id;
