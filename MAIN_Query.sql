                                          /*	Question Set 1 - Easy */

/* 1. Who is the senior most employee based on job title? */

SELECT title, last_name, first_name
FROM employee
ORDER BY levels DESC
LIMIT 1

/* 2. Which countries have the most Invoices? */

SELECT COUNT(*) AS c, billing_country
FROM INVOICE
GROUP BY billing_country
ORDER BY c DESC 

/* 3. What are top 3 values of total invoice? */

SELECT total
FROM INVOICE
ORDER BY total DESC
LIMIT 3

/* 4. Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals */

SELECT billing_city, SUM(total) AS t
FROM INVOICE
GROUP BY billing_city
ORDER BY t DESC
LIMIT 1

/* 5. Who is the best customer? The customer who has spent the most money will be 
declared the best customer. Write a query that returns the person who has spent the 
most money */

SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer
JOIN INVOICE ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total_spending DESC
LIMIT 1


                                          /* Question Set 2 – Moderate */

/* 1. Write query to return the email, first name, last name, & Genre of all Rock Music 
listeners. Return your list ordered alphabetically by email starting with A */

SELECT DISTINCT email, last_name, first_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email

/* 2. Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT artist.artist_id, artist.name, COUNT(track.track_id) AS no_of_tracks
FROM artist
JOIN album ON artist.artist_id = album.artist_id
JOIN track ON album.album_id = track.album_id
WHERE track.track_id IN(
	SELECT track.track_id 
	FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
GROUP BY artist.artist_id
ORDER BY no_of_tracks DESC
LIMIT 10

/* 3. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs 
listed first. */

SELECT track_id, name, milliseconds 
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds)
	FROM track
)
ORDER BY milliseconds DESC


                                          /* Question Set 3 - Advance */

/* 1. Find how much amount spent by each customer on artists? Write a query to return customer 
name, artist name and total spent */

WITH best_selling_artist AS (
	SELECT artist.artist_id, artist.name as artist_name, 
	SUM(invoice_line.unit_price * invoice_line.quantity) as total_sales
	FROM invoice_line
	JOIN track ON invoice_line.track_id = track.track_id
	JOIN album ON track.album_id = album.album_id
	JOIN artist ON album.artist_id = artist.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
)
SELECT c.customer_id, c.last_name, c.first_name, bsa.artist_name, 
SUM(il.unit_price * il.quantity) as amount_spent
FROM customer c
JOIN invoice ON c.customer_id = invoice.customer_id
JOIN invoice_line il ON invoice.invoice_id = il.invoice_id
JOIN track ON il.track_id = track.track_id
JOIN album ON track.album_id = album.album_id
JOIN best_selling_artist bsa ON album.artist_id = bsa.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC

/* 2. We want to find out the most popular music Genre for each country. We determine the most 
popular genre as the genre with the highest amount of purchases. Write a query that returns each 
country along with the top Genre. For countries where the maximum number of purchases is shared 
return all Genres. */

-- Method I: Using Common Table Expression (CTE) --

WITH popular_genre AS (
	SELECT COUNT(il.quantity) AS purchases, c.country, g.name, g.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS row_no
	FROM invoice_line il
	JOIN invoice ON invoice.invoice_id = il.invoice_id
	JOIN customer c ON c.customer_id = invoice.customer_id
	JOIN track ON track.track_id = il.track_id
	JOIN genre g ON g.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre where row_no <= 1

-- Method 2: Using Recursion --

WITH RECURSIVE popular_genre AS (
	SELECT COUNT(*) AS purchases, c.country, g.name, g.genre_id
	FROM invoice_line il
	JOIN invoice ON invoice.invoice_id = il.invoice_id
	JOIN customer c ON c.customer_id = invoice.customer_id
	JOIN track ON track.track_id = il.track_id
	JOIN genre g ON g.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC
),
max_popular_genre AS (
	SELECT MAX(purchases) AS max_purchases, country FROM popular_genre
	GROUP BY 2
	ORDER BY 2 ASC
)
SELECT popular_genre.* FROM popular_genre 
JOIN max_popular_genre ON popular_genre.country = max_popular_genre.country
WHERE popular_genre.purchases = max_popular_genre.max_purchases 

/* 3. Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

WITH top_customers AS (
	SELECT i.billing_country, c.first_name, c.last_name, c.customer_id, SUM(i.total),
	ROW_NUMBER() OVER (PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS row_no
	FROM invoice i
	JOIN customer c ON c.customer_id = i.customer_id
	GROUP BY 1,4
	ORDER BY 1 ASC, 5 DESC
)
SELECT * FROM top_customers where row_no = 1

