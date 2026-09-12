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
HAVING
    AVG(products.price * sales.quantity) < (
        SELECT AVG(all_products.price * all_sales.quantity)
        FROM sales AS all_sales
        INNER JOIN products AS all_products
            ON all_sales.product_id = all_products.product_id
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

-- Количество покупателей в возрастных группах 16-25, 26-40 и старше 40.
WITH age_groups AS (
    SELECT
        CASE
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age > 40 THEN '40+'
        END AS age_category
    FROM customers
)

SELECT
    age_category,
    COUNT(*) AS age_count
FROM age_groups
WHERE age_category IS NOT NULL
GROUP BY age_category
ORDER BY age_category;

-- Уникальные покупатели и выручка по месяцам, в хронологическом порядке.
-- Выручка округляется вниз после суммирования всех продаж месяца.
SELECT
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY TO_CHAR(sales.sale_date, 'YYYY-MM')
ORDER BY selling_month;

-- Покупатели, чья первая покупка была акционной: цена товара равна нулю.
-- Сначала выбирается первая продажа из всех покупок, затем проверяется цена.
-- При совпадении дат первая продажа определяется по sales_id.
WITH first_purchases AS (
    SELECT
        customer_id,
        product_id,
        sales_person_id,
        sale_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY sale_date, sales_id
        ) AS purchase_number
    FROM sales
)

SELECT
    CONCAT(customers.first_name, ' ', customers.last_name) AS customer,
    TO_CHAR(first_purchases.sale_date, 'YYYY-MM-DD') AS sale_date,
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller
FROM first_purchases
INNER JOIN customers ON first_purchases.customer_id = customers.customer_id
INNER JOIN employees
    ON first_purchases.sales_person_id = employees.employee_id
INNER JOIN products ON first_purchases.product_id = products.product_id
WHERE first_purchases.purchase_number = 1 AND products.price = 0
ORDER BY customers.customer_id;
