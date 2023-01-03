/*Data structure https://ucarecdn.com/bad26356-5e34-4945-a9d4-0748686a6b54/
Data samples https://ucarecdn.com/09eb90ce-ce66-446b-8337-e391caabff1c/ */


/*Select all orders made by Pavel Baranov (order id, books, price, amount), sorted by order id, then by title. Pavel Baranov client_id = 1 */
SELECT buy_book.buy_id, book.title, book.price, buy_book.amount
FROM buy_book
    INNER JOIN buy ON buy_book.buy_id=buy.buy_id
    INNER JOIN book ON buy_book.book_id=book.book_id
    INNER JOIN client ON buy.client_id=client.client_id
WHERE client.client_id = 1
ORDER BY buy_id, title;


/*Count the number of times each book has been ordered, for the book output its author (you need to count how many orders each book appears in).  Output the author's surname and initials, the book title, the last column should be called Количество. Sort the result first by author's surname, then by book title. */
SELECT author.name_author, book.title, count(buy_book.amount) AS Количество
FROM author
    INNER JOIN book ON author.author_id = book.author_id
    LEFT JOIN buy_book ON book.book_id = buy_book.book_id
GROUP BY author.name_author, book.title
ORDER BY author.name_author, book.title;


/*Output the cities where the customers who placed orders in the online shop live. Enter the number of orders in each city, call this column Количество. Output the information in descending order by number of orders and then in alphabetical order by city name.*/
SELECT name_city, count(client.client_id) AS Количество
FROM 
    client
    INNER JOIN buy ON client.client_id = buy.client_id
    INNER JOIN city ON client.city_id = city.city_id
GROUP BY name_city
ORDER BY Количество DESC, name_city;


/*Output the numbers of all paid orders and the dates on which they were paid.*/
SELECT buy_id, date_step_end
FROM buy_step
    INNER JOIN step ON step.step_id = buy_step.step_id
WHERE buy_step.step_id = 1 AND date_step_end IS NOT NULL;


/*Output information about each order: its number, who generated it (user name) and its cost (sum of the number of books ordered and their price), sorted by order number. Name the last column Стоимость.*/
SELECT buy.buy_id, name_client, sum(buy_book.amount * book.price) AS Стоимость 
FROM buy
    INNER JOIN client ON buy.client_id = client.client_id
    INNER JOIN buy_book ON buy.buy_id = buy_book.buy_id 
    INNER JOIN book ON book.book_id = buy_book.book_id
GROUP BY buy.buy_id, name_client
ORDER BY buy.buy_id;


/*Display the order numbers (buy_id) and the stages they are currently at. If the order has been delivered - do not display information about it. Sort the information by increasing buy_id.*/
SELECT buy_id, name_step
FROM buy_step
    INNER JOIN step USING(step_id)
WHERE date_step_beg IS NOT NULL AND date_step_end IS NULL;


/*The city table for each city shows the number of days the order can be delivered to that city (only the "Transport" stage is considered). For those orders that have passed the transportation stage, output the number of days it took for the order to be actually delivered to the city. Also, if the order was delivered late, specify the number of days it was delayed. Otherwise, output 0. Include the order number (buy_id) in the output as well as the calculated columns Number of days and Delay. Output the information sorted by order number.*/
SELECT buy_step.buy_id, DATEDIFF(date_step_end, date_step_beg) AS Количество_дней, IF(DATEDIFF(date_step_end, date_step_beg) > days_delivery, DATEDIFF(date_step_end, date_step_beg) - days_delivery, 0) AS Опоздание
FROM buy_step
    INNER JOIN buy USING(buy_id)
    INNER JOIN client USING(client_id)
    INNER JOIN city USING(city_id)
WHERE buy_step.step_id = 3 AND date_step_end IS NOT NULL;


/*Output the genre (or genres) in which the most copies of books were ordered, indicate this number. Name the last column Количество.*/
SELECT name_genre, sum(buy_book.amount) AS  Количество
FROM buy_book
    INNER JOIN book USING (book_id)
    INNER JOIN genre USING (genre_id)
GROUP BY name_genre
HAVING Количество = 
(SELECT max(Количество)
FROM 
    (SELECT name_genre, sum(buy_book.amount) AS Количество
    FROM buy_book
        INNER JOIN book USING (book_id)
        INNER JOIN genre USING (genre_id)
    GROUP BY name_genre) AS query);     


/*Compare the monthly revenue from book sales for the current year and the previous year. To do this, output the year, month, amount of revenue sorted first by months, then by years. Column names: Год, Месяц, Сумма */
SELECT YEAR(date_step_end) AS Год, MONTHNAME(date_step_end) AS Месяц, sum(buy_book.amount*price) AS Сумма
FROM
    buy_book
    INNER JOIN buy_step USING (buy_id)
    INNER JOIN book USING (book_id)
WHERE buy_step.step_id = 1  AND date_step_end IS NOT NULL
GROUP BY Год, Месяц
UNION ALL 
SELECT YEAR(date_payment) AS Год, MONTHNAME(date_payment) AS Месяц, sum(amount*price) AS Сумма
FROM buy_archive
GROUP BY Год, Месяц
ORDER BY Месяц, Год;


/*For each individual book, you need to output information about the number of copies sold and their value for 2020 and 2019 . The calculated columns are called Quantity and Amount. Sort the information in descending order of value.*/
SELECT title, sum(Количество) AS Количество, sum(Сумма) AS Сумма
FROM 
    (SELECT title, sum(buy_archive.amount) AS Количество, sum(buy_archive.amount*buy_archive.price) AS Сумма
    FROM 
        buy_archive 
        INNER JOIN book USING(book_id)
    GROUP BY title
    UNION 
    SELECT title, sum(buy_book.amount) AS Количество, sum(buy_book.amount * price) AS Сумма
    FROM 
        buy_book 
        INNER JOIN book USING(book_id)
        INNER JOIN buy_step USING(buy_id)
    WHERE step_id = 1 AND date_step_end IS NOT NULL 
    GROUP BY title) query_1
GROUP BY title
ORDER BY Сумма DESC;


/*Include a new person in the client table. His name is Popov Ilya, his email is popov@test and he lives in Moscow.*/
INSERT INTO client (name_client, city_id, email)
SELECT "Попов Илья", city_id, "popov@test"
FROM city
WHERE name_city = "Москва";


/*Create a new order for Ilya Popov. His comment for the order is 'Contact me about delivery'.*/
INSERT INTO buy (buy_description, client_id) 
SELECT "Связаться со мной по вопросу доставки", client_id
FROM client
WHERE name_client = "Попов Илья";


/*Add order number 5 to the buy_book table. This order should contain two copies of Pasternak's "Lyrics" and one copy of Bulgakov's "White Guard".*/
INSERT INTO buy_book (buy_id, book_id, amount)
SELECT 5, book_id, 2 
FROM book
WHERE title = "Лирика";
    
INSERT INTO buy_book (buy_id, book_id, amount)
SELECT 5, book_id, 1 
FROM book
WHERE title = "Белая гвардия";

#Alternative solution
INSERT INTO buy_book (buy_id, book_id, amount)
VALUES (5, (SELECT book_id FROM book WHERE title = "Лирика"), 2);

INSERT INTO buy_book (buy_id, book_id, amount)
VALUES (5, (SELECT book_id FROM book WHERE title = "Белая гвардия"), 1); 


/*Reduce the number of those books in stock that were included in order number 5.*/
UPDATE book, buy_book
SET book.amount = book.amount - buy_book.amount
WHERE book.book_id = buy_book.book_id AND buy_book.buy_id = 5;


/*Create an invoice (buy_pay table) to pay for the order with number 5, including the name of the books, their author, price, number of books ordered and cost. Name the last column Cost. Enter the information in the table sorted by book title.*/
CREATE TABLE buy_pay AS 
SELECT title, name_author, price, buy_book.amount, price * buy_book.amount AS Стоимость
FROM 
    book
    INNER JOIN buy_book USING (book_id)
    INNER JOIN author USING (author_id)
WHERE buy_book.buy_id = 5
ORDER BY title;
SELECT * FROM buy_pay;


/*Create a total invoice (buy_pay table) to pay for the order with order number 5. Where to include the order number, the number of books in the order (column name Quantity) and its total cost (column name Total). Use ONE query for the solution.*/
CREATE TABLE buy_pay AS 
SELECT buy_id, sum(Количество) AS Количество, sum(Стоимость) AS Итого
FROM (
    SELECT buy_id, title, name_author, price, buy_book.amount AS Количество, price * buy_book.amount AS Стоимость
    FROM 
        book
        INNER JOIN buy_book USING (book_id)
        INNER JOIN author USING (author_id)
    WHERE buy_book.buy_id = 5
    ORDER BY title) query_1
GROUP BY buy_id
HAVING buy_id = 5;


/*In the buy_step table for order number 5, include all steps from the step table that this order must complete. Enter Null in the date_step_beg and date_step_end columns of all entries.*/
INSERT INTO buy_step (buy_id, step_id)
SELECT 5, step_id 
    FROM (SELECT DISTINCT(step_id)
        FROM step) q;
SELECT * FROM buy_step;


/*In the buy_step table, enter the date 12.04.2020 for the order number 5.*/
UPDATE buy_step
SET date_step_beg = "2020.04.12"
WHERE buy_id = 5 AND step_id = 1;


/*Complete the "Payment" step for order number 5 by entering date 13.04.2020 in the date_step_end column and start the next step ("Packing") by entering the same date in the date_step_beg column for this step.*/
UPDATE buy_step
SET date_step_end= "2020.04.13"
WHERE buy_id = 5 AND step_id = 1;
UPDATE buy_step
SET date_step_beg = "2020.04.13"
WHERE buy_id = 5 AND step_id = 2;