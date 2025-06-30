CREATE DATABASE opo;
USE opo;

CREATE TABLE StudentDetails (
    StudentId VARCHAR(20) PRIMARY KEY,
    StudentName VARCHAR(100) NOT NULL,
    GPA DECIMAL(3,2) NOT NULL,
    Branch VARCHAR(10) NOT NULL,
    Section CHAR(1) NOT NULL
);


CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(20) PRIMARY KEY,
    SubjectName VARCHAR(100) NOT NULL,
    MaxSeats INT NOT NULL,
    RemainingSeats INT NOT NULL
);


CREATE TABLE StudentPreference (
    StudentId VARCHAR(20),
    SubjectId VARCHAR(20),
    Preference INT NOT NULL CHECK (Preference BETWEEN 1 AND 5),
    PRIMARY KEY (StudentId, SubjectId),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    UNIQUE (StudentId, Preference) -- Ensures no duplicate preferences for same student
);


CREATE TABLE Allotments (
    SubjectId VARCHAR(20),
    StudentId VARCHAR(20),
    PRIMARY KEY (StudentId), 
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);


CREATE TABLE UnallotedStudents (
    StudentId VARCHAR(20) PRIMARY KEY,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

-- INSERTING VALUES

INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section) VALUES
('159103036', 'Mohit Agarwal', 8.9, 'CCE', 'A'),
('159103037', 'Rohit Agarwal', 5.2, 'CCE', 'A'),
('159103038', 'Shohit Garg', 7.1, 'CCE', 'B'),
('159103039', 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
('159103040', 'Mehreet Singh', 5.6, 'CCE', 'A'),
('159103041', 'Arjun Tehlan', 9.2, 'CCE', 'B');

INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats) VALUES
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);


INSERT INTO StudentPreference (StudentId, SubjectId, Preference) VALUES

('159103036', 'PO1491', 1),
('159103036', 'PO1492', 2),
('159103036', 'PO1493', 3),
('159103036', 'PO1494', 4),
('159103036', 'PO1495', 5),


('159103037', 'PO1491', 1),
('159103037', 'PO1493', 2),
('159103037', 'PO1492', 3),
('159103037', 'PO1495', 4),
('159103037', 'PO1494', 5),


('159103038', 'PO1492', 1),
('159103038', 'PO1491', 2),
('159103038', 'PO1494', 3),
('159103038', 'PO1493', 4),
('159103038', 'PO1495', 5),


('159103039', 'PO1491', 1),
('159103039', 'PO1494', 2),
('159103039', 'PO1492', 3),
('159103039', 'PO1493', 4),
('159103039', 'PO1495', 5),


('159103040', 'PO1493', 1),
('159103040', 'PO1492', 2),
('159103040', 'PO1491', 3),
('159103040', 'PO1494', 4),
('159103040', 'PO1495', 5),


('159103041', 'PO1491', 1),
('159103041', 'PO1492', 2),
('159103041', 'PO1494', 3),
('159103041', 'PO1493', 4),
('159103041', 'PO1495', 5);

-- allocate subjects to students based on GPA and preferences

DELIMITER //

CREATE PROCEDURE AllocateSubjects()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE current_student_id VARCHAR(20);
    DECLARE current_preference INT;
    DECLARE current_subject_id VARCHAR(20);
    DECLARE remaining_seats INT;
    DECLARE allocated BOOLEAN DEFAULT FALSE;
    
    
    DECLARE student_cursor CURSOR FOR 
        SELECT StudentId 
        FROM StudentDetails 
        ORDER BY GPA DESC;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    
    DELETE FROM Allotments;
    DELETE FROM UnallotedStudents;
    
  
    UPDATE SubjectDetails SET RemainingSeats = MaxSeats;
    
    
    OPEN student_cursor;
    
    student_loop: LOOP
        FETCH student_cursor INTO current_student_id;
        IF done THEN
            LEAVE student_loop;
        END IF;
        
        SET allocated = FALSE;
        SET current_preference = 1;
        
        
        preference_loop: WHILE current_preference <= 5 AND NOT allocated DO
            -- Get the subject for current preference
            SELECT SubjectId INTO current_subject_id
            FROM StudentPreference 
            WHERE StudentId = current_student_id 
            AND Preference = current_preference;
            

            SELECT RemainingSeats INTO remaining_seats
            FROM SubjectDetails 
            WHERE SubjectId = current_subject_id;
            
            IF remaining_seats > 0 THEN
             
                INSERT INTO Allotments (SubjectId, StudentId) 
                VALUES (current_subject_id, current_student_id);
                
              
                UPDATE SubjectDetails 
                SET RemainingSeats = RemainingSeats - 1 
                WHERE SubjectId = current_subject_id;
                
                SET allocated = TRUE;
            ELSE
             
                SET current_preference = current_preference + 1;
            END IF;
        END WHILE preference_loop;
        
        
        IF NOT allocated THEN
            INSERT INTO UnallotedStudents (StudentId) 
            VALUES (current_student_id);
        END IF;
        
    END LOOP student_loop;
    
    CLOSE student_cursor;
    
END //

DELIMITER ;

-- excecution

CALL AllocateSubjects();


SELECT 'ALLOCATION RESULTS' as Result;

SELECT 
    a.StudentId,
    sd.StudentName,
    sd.GPA,
    a.SubjectId,
    sub.SubjectName,
    sp.Preference as 'Allocated Preference'
FROM Allotments a
JOIN StudentDetails sd ON a.StudentId = sd.StudentId
JOIN SubjectDetails sub ON a.SubjectId = sub.SubjectId
JOIN StudentPreference sp ON a.StudentId = sp.StudentId AND a.SubjectId = sp.SubjectId
ORDER BY sd.GPA DESC;

SELECT 'UNALLOCATED STUDENTS' as Result;

SELECT 
    u.StudentId,
    sd.StudentName,
    sd.GPA
FROM UnallotedStudents u
JOIN StudentDetails sd ON u.StudentId = sd.StudentId
ORDER BY sd.GPA DESC;

SELECT 'SUBJECT UTILIZATION' as Result;

SELECT 
    SubjectId,
    SubjectName,
    MaxSeats,
    RemainingSeats,
    (MaxSeats - RemainingSeats) as AllocatedSeats,
    ROUND(((MaxSeats - RemainingSeats) / MaxSeats) * 100, 2) as 'Utilization %'
FROM SubjectDetails
ORDER BY SubjectId;

-- verification


SELECT 'ALLOCATION ORDER VERIFICATION' as Result;

SELECT 
    ROW_NUMBER() OVER (ORDER BY sd.GPA DESC) as AllocationOrder,
    a.StudentId,
    sd.StudentName,
    sd.GPA,
    a.SubjectId,
    sp.Preference
FROM Allotments a
JOIN StudentDetails sd ON a.StudentId = sd.StudentId
JOIN StudentPreference sp ON a.StudentId = sp.StudentId AND a.SubjectId = sp.SubjectId
ORDER BY sd.GPA DESC;


SELECT 'INVALID ALLOCATIONS CHECK' as Result;

SELECT COUNT(*) as InvalidAllocations
FROM Allotments a
WHERE NOT EXISTS (
    SELECT 1 FROM StudentPreference sp 
    WHERE sp.StudentId = a.StudentId 
    AND sp.SubjectId = a.SubjectId
);


SELECT 'PREFERENCE ANALYSIS' as Result;

SELECT 
    sp.Preference,
    COUNT(*) as TotalStudentsWithThisPreference,
    COUNT(a.StudentId) as StudentsAllocatedAtThisPreference,
    ROUND((COUNT(a.StudentId) / COUNT(*)) * 100, 2) as 'Success Rate %'
FROM StudentPreference sp
LEFT JOIN Allotments a ON sp.StudentId = a.StudentId AND sp.SubjectId = a.SubjectId
GROUP BY sp.Preference
ORDER BY sp.Preference;



