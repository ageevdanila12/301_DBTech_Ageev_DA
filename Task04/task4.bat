#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sqlite3 -box movies_rating.db "SELECT DISTINCT u1.name AS user1, u2.name AS user2, m.title FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON r1.user_id = u1.id JOIN users u2 ON r2.user_id = u2.id JOIN movies m ON r1.movie_id = m.id LIMIT 100;"
echo ""

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sqlite3 -box movies_rating.db "SELECT m.title, u.name, r.rating, strftime('%Y-%m-%d', r.timestamp, 'unixepoch') AS date FROM ratings r JOIN users u ON r.user_id = u.id JOIN movies m ON r.movie_id = m.id GROUP BY r.user_id ORDER BY r.timestamp DESC LIMIT 10;"
echo ""

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sqlite3 -box movies_rating.db "WITH avg_ratings AS (SELECT movie_id, AVG(rating) as avg_r FROM ratings GROUP BY movie_id), max_avg AS (SELECT MAX(avg_r) as m FROM avg_ratings), min_avg AS (SELECT MIN(avg_r) as m FROM avg_ratings) SELECT m.title, m.year, CASE WHEN ar.avg_r = (SELECT m FROM max_avg) THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем' FROM movies m JOIN avg_ratings ar ON m.id = ar.movie_id WHERE ar.avg_r = (SELECT m FROM max_avg) OR ar.avg_r = (SELECT m FROM min_avg) ORDER BY m.year ASC, m.title ASC;"
echo ""

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sqlite3 -box movies_rating.db "SELECT COUNT(*) as count_ratings, AVG(r.rating) as avg_rating FROM ratings r JOIN users u ON r.user_id = u.id WHERE u.gender = 'female' AND r.timestamp BETWEEN strftime('%s', '2010-01-01') AND strftime('%s', '2012-12-31 23:59:59');"
echo ""

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sqlite3 -box movies_rating.db "SELECT m.title, m.year, AVG(r.rating) as avg_rating, RANK() OVER (ORDER BY AVG(r.rating) DESC) as rank FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id ORDER BY m.year ASC, m.title ASC LIMIT 20;"
echo ""

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sqlite3 -box movies_rating.db "SELECT SUBSTR(name, INSTR(name, ' ') + 1) || ' ' || SUBSTR(name, 1, INSTR(name, ' ') - 1) || '|' || register_date AS 'Фамилия Имя|Дата регистрации' FROM users ORDER BY register_date DESC LIMIT 10;"
echo ""

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10. Должен получиться один столбец."
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sqlite3 -box movies_rating.db "WITH RECURSIVE multiplication(a, b) AS (SELECT 1, 1 UNION ALL SELECT CASE WHEN b < 10 THEN a ELSE a + 1 END, CASE WHEN b < 10 THEN b + 1 ELSE 1 END FROM multiplication WHERE a <= 10) SELECT a || 'x' || b || '=' || (a * b) AS result FROM multiplication WHERE a <= 10;"
echo ""

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies (каждый жанр в отдельной строке)."
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sqlite3 -box movies_rating.db "WITH RECURSIVE split_genres(movie_id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT movie_id, SUBSTR(rest, 1, INSTR(rest, '|') - 1), SUBSTR(rest, INSTR(rest, '|') + 1) FROM split_genres WHERE rest != '') SELECT DISTINCT genre FROM split_genres WHERE genre != '' ORDER BY genre;"
echo ""