-- Подсчитывает общее количество покупателей в таблице customers.
SELECT COUNT(*) AS customers_count
FROM customers;

-- Десять продавцов с наибольшей выручкой: сделки и сумма продаж.
-- Выручка округляется вниз после суммирования цены, умноженной на количество.
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY employees.employee_id, employees.first_name, employees.last_name
ORDER BY SUM(products.price * sales.quantity) DESC, seller
LIMIT 10;

-- Продавцы со средней выручкой за сделку ниже средней по всем сделкам.
-- Сравнение выполняется до округления. Результат округляется вниз.
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    FLOOR(AVG(products.price * sales.quantity)) AS average_income
FROM sales
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY employees.employee_id, employees.first_name, employees.last_name
HAVING AVG(products.price * sales.quantity) < (
    SELECT AVG(products.price * sales.quantity)
    FROM sales
    INNER JOIN products ON sales.product_id = products.product_id
)
ORDER BY AVG(products.price * sales.quantity), seller;

-- Выручка каждого продавца по дням недели, округленная вниз.
-- Английские названия без пробелов. ISO-порядок от понедельника до воскресенья.
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    LOWER(TO_CHAR(sales.sale_date, 'FMDay')) AS day_of_week,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY
    employees.employee_id,
    employees.first_name,
    employees.last_name,
    EXTRACT(ISODOW FROM sales.sale_date),
    TO_CHAR(sales.sale_date, 'FMDay')
ORDER BY EXTRACT(ISODOW FROM sales.sale_date), seller;
