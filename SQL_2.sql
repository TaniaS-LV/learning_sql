/* Schema  https://ucarecdn.com/e4669333-8898-434f-b1a5-4fa88b39ae02/ */

/*1. Display the students who took the discipline "Database Fundamentals", indicate the date of the attempt and the result. Output the information in descending order of test results.*/
SELECT name_student, date_attempt, result 
FROM 
    (SELECT student_id, date_attempt, result
    FROM attempt
    WHERE EXISTS (
        SELECT * FROM student WHERE student.student_id  = attempt.student_id AND subject_id = 2)) query 
INNER JOIN student USING (student_id)
ORDER BY result DESC


/* Alternative */
SELECT name_student, date_attempt, result
FROM student
    INNER JOIN attempt USING (student_id)
    INNER JOIN subject USING (subject_id)
WHERE subject_id = 2
ORDER BY result DESC;


/*2. Output how many attempts students made in each discipline, as well as the average result of attempts, rounded to 2 decimal places. The result of an attempt is the percentage of correct answers to the test questions, which is recorded in the result column.  Include in the result the name of the discipline, as well as the calculated columns Number and Average. Output the information in descending order of the average results.*/
SELECT name_subject, count(attempt_id) AS Количество, round(avg(result),2) AS Среднее 
FROM attempt
    RIGHT JOIN subject USING (subject_id) 
GROUP BY name_subject
ORDER BY Среднее DESC;


/*3. Output the students (different students) who have the maximal results of their attempts. Sort the information in alphabetical order by the last name of the student.*/
SELECT name_student, result 
FROM student
    INNER JOIN attempt USING (student_id)
WHERE result = (
    SELECT MAX(result) 
    FROM attempt)
ORDER BY name_student;


/*4.If a student has made multiple attempts at the same course, print the difference in days between the first and last attempt. Include in the result the student's first and last name, the name of the discipline, and the calculated column Interval. Output the information in ascending order of the difference. Students who made one attempt at a discipline should not be counted.*/
SELECT name_student, name_subject, Интервал
FROM 
    (SELECT student_id, subject_id, count(date_attempt), min(date_attempt), max(date_attempt), datediff(max(date_attempt), min(date_attempt)) AS Интервал
    FROM attempt
    GROUP BY student_id, subject_id
    HAVING count(date_attempt) >1) q
    INNER JOIN student USING (student_id)
    INNER JOIN subject USING (subject_id)
ORDER BY Интервал;


/*5.Students can be tested in one or more disciplines (not necessarily all of them). Output the discipline and the number of unique students (column name Number) that were tested in it. Sort the information first by decreasing number and then by discipline name. Include in the result the disciplines in which students have not yet been tested, in this case specify the number of students 0.*/
SELECT name_subject, COUNT(DISTINCT(student_id)) AS Количество
FROM
    subject
    LEFT JOIN attempt USING (subject_id)
GROUP BY name_subject
ORDER BY Количество DESC, name_subject;


/*6. Randomly select 3 questions from the "Database Fundamentals" discipline. Include the question_id and name_question columns in the result.*/
SELECT question_id, name_question
FROM question
    WHERE EXISTS (SELECT * FROM subject WHERE question.subject_id = subject.subject_id AND name_subject = "Основы баз данных")
ORDER BY RAND()
LIMIT 3;


/*7. Output the questions that were included in the test for Semenov Ivan on the discipline "SQL basics" 2020-05-17 (the attempt_id value for this attempt is 7). Specify what answer the student gave and whether it is correct or not (output True or False). Include in the result the question, the answer and the calculated column Result.*/
SELECT name_question, name_answer, IF(is_correct=0, "Неверно", "Верно") AS Результат
FROM 
    question
    INNER JOIN testing USING (question_id)
    INNER JOIN answer USING (answer_id)
WHERE attempt_id = 7;


/*8. Calculate the results of the test. Calculate the result of an attempt as the number of correct answers divided by 3 (the number of questions in each attempt) and multiplied by 100. Round up the result to two decimal places. Print the student's last name, the subject, the date, and the result. Name the last column Result. Sort the information first by the student's last name, then by decreasing date of attempt. */
SELECT name_student, name_subject, date_attempt, round(sum(is_correct)/3 * 100,2) AS Результат
FROM 
    attempt
    INNER JOIN testing USING (attempt_id)
    INNER JOIN student USING (student_id) 
    INNER JOIN subject USING (subject_id) 
    INNER JOIN question USING (question_id)
    INNER JOIN answer USING (answer_id)
GROUP BY name_student, name_subject, date_attempt
ORDER BY name_student, date_attempt DESC


/*9. For each question, print the percentage of successful solutions, that is, the ratio of the number of correct answers to the total number of answers, rounded to 2 decimal places. Also print the name of the subject to which the question applies and the total number of answers to that question. Include the name of the course, the questions it asks for (label the column Question), and the two calculated columns Total_responses and Success rate. Sort the information first by discipline name, then in descending order of success, and then alphabetically by question text.
Because question texts can be long, trim them to 30 characters, and add a ellipsis "...". */
SELECT name_subject, CONCAT(LEFT(name_question, 30), "...") AS Вопрос, Всего_ответов, Успешность
FROM 
    (SELECT t.question_id, COUNT(attempt_id) AS Всего_ответов, ROUND(SUM(a.is_correct)/ COUNT(attempt_id) * 100,2) AS Успешность
    FROM testing t
        INNER JOIN answer a USING (answer_id)  
    GROUP BY t.question_id) q
    INNER JOIN question ON q.question_id = question.question_id 
    INNER JOIN subject USING (subject_id)
ORDER BY name_subject, Успешность DESC, Вопрос


/*10.Include a new attempt in the attempt table for student Baranov Pavel in Database Fundamentals. Set the current date as the date of the attempt.*/
INSERT INTO attempt (student_id, subject_id, date_attempt, result)
VALUES (1, 2, NOW(), null );
SELECT * FROM attempt;


/*11.Randomly select three questions (query) for the discipline the student who was last in the attempt table is going to be tested on, and add them to the testing table. Get the id of the last attempt as the maximum id from the attempt table.*/
INSERT INTO testing (attempt_id, question_id)
SELECT a.attempt_id, b.question_id
FROM 
(SELECT MAX(attempt_id) AS attempt_id
FROM attempt) a 
CROSS JOIN (
SELECT question_id
    FROM question
    WHERE subject_id = 
        (SELECT subject_id
        FROM attempt
        WHERE attempt_id = (
            SELECT MAX(attempt_id)
            FROM attempt))
    ORDER BY RAND()
    LIMIT 3 ) b ;
SELECT * FROM testing; 


/*12. The student has been tested (i.e. all his answers are in the testing table), then the result (query) needs to be calculated and entered in the attempt table for the corresponding attempt (last in the table attempt).  The result of the attempt should be calculated as the number of correct answers divided by 3 (the number of questions in each attempt) and multiplied by 100. Round up the result to a whole number.*/
UPDATE attempt
SET result = 
    (SELECT round(sum(is_correct)/3 * 100,0) AS Результат
    FROM 
        testing t
        INNER JOIN answer a USING (answer_id)
    WHERE t.attempt_id = 8
    GROUP BY t.attempt_id)
WHERE attempt_id = (
    SELECT * FROM (
    SELECT MAX(attempt_id) FROM attempt) AS q 
); 
SELECT * FROM attempt;


/*13.Remove from the attempt table all attempts made before 1 May 2020. Also delete all questions corresponding to these attempts from the testing table.*/
DELETE FROM attempt
WHERE date_attempt < '2020-05-01';
