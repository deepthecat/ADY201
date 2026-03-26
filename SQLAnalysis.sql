-- =======================================================
-- PROJECT: STUDENT MENTAL HEALTH ANALYSIS
-- GIAI ĐOẠN 1: CLEANING, MAPPING & FEATURE ENGINEERING
-- =======================================================
/* 
Mục tiêu: Tạo ra bảng student_data_cleaned để dùng cho phân tích
*/
Use mental_health_student
Go 


-- 1. Xóa bảng cũ nếu tồn tại
IF OBJECT_ID('student_data_cleaned', 'U') IS NOT NULL 
    DROP TABLE student_data_cleaned;

-- 2. Mapping dữ liệu thô sang số 
WITH mapped_data AS (
    SELECT 
        Record_Time, -- Giả định đây là cột Timestamp đã đổi tên
        
        -- Mapping Năm học
        CASE 
            WHEN Year  LIKE 'First%' THEN 1
            WHEN Year LIKE 'Second%' THEN 2
            WHEN Year LIKE 'Third%' THEN 3
            ELSE 4 END AS Year,

        -- Mapping Giới tính
        CASE WHEN Gender = 'Male' THEN 0
             ELSE 1 END AS Gender,

        -- Mapping Tần suất (0-4)
        CASE 
            WHEN Difficulty_Falling_Asleep LIKE 'Never%' THEN 0
            WHEN Difficulty_Falling_Asleep LIKE 'Rarely%' THEN 1
            WHEN Difficulty_Falling_Asleep LIKE 'Sometimes%' THEN 2
            WHEN Difficulty_Falling_Asleep LIKE 'Often%' THEN 3
            ELSE 4 END AS Difficulty_Falling_Asleep,
        
        -- Mapping Giờ ngủ (Lấy giá trị số)
        CASE Sleep_Hours_Total
            WHEN 'Less than 4 hours' THEN 3
            WHEN '4-5 hours' THEN 4.5
            WHEN '5-6 hours' THEN 5.5
            WHEN '6-7 hours' THEN 6.5
            WHEN '7-8 hours' THEN 7.5
            ELSE 8.5 END AS Sleep_Hours_Total,

        -- Mapping Tần suất (0-4)
        CASE 
            WHEN Waking_Up_During_Night LIKE 'Never%' THEN 0
            WHEN Waking_Up_During_Night LIKE 'Rarely%' THEN 1
            WHEN Waking_Up_During_Night LIKE 'Sometimes%' THEN 2
            WHEN  Waking_Up_During_Night LIKE 'Often%' THEN 3
            ELSE 4 END AS  Waking_Up_During_Night,


        -- Mapping Chất lượng (1-5)
        CASE Overall_Sleep_Quality
            WHEN 'Very poor' THEN 1 
            WHEN 'Poor' THEN 2 
            WHEN 'Average' THEN 3 
            WHEN 'Good' THEN 4 
            ELSE 5 END AS Overall_Sleep_Quality,

        -- Mapping Tác động & Stress (0-4)
        CASE Sleep_Impact_on_Concentration WHEN 'Never' THEN 0 
                                           WHEN 'Rarely' THEN 1 
                                           WHEN 'Sometimes' THEN 2 
                                           WHEN 'Often' THEN 3 
                                           ELSE 4 END AS Sleep_Impact_on_Concentration,

        CASE Daytime_Fatigue WHEN 'Never' THEN 0 
                             WHEN 'Rarely' THEN 1 
                             WHEN 'Sometimes' THEN 2 
                             WHEN 'Often' THEN 3 
                             ELSE 4 END AS Daytime_Fatigue,

        CASE 
            WHEN Sleep_Impact_on_Attendance LIKE 'Never%' THEN 0
            WHEN Sleep_Impact_on_Attendance LIKE 'Rarely%' THEN 1
            WHEN Sleep_Impact_on_Attendance LIKE 'Sometimes%' THEN 2
            WHEN  Sleep_Impact_on_Attendance LIKE 'Often%' THEN 3
            ELSE 4 END AS Sleep_Impact_on_Attendance,

        CASE 
            WHEN Sleep_Impact_on_Deadlines LIKE 'No%' THEN 0
            WHEN Sleep_Impact_on_Deadlines LIKE 'Minor%' THEN 1
            WHEN Sleep_Impact_on_Deadlines LIKE 'Moderate%' THEN 2
            WHEN  Sleep_Impact_on_Deadlines LIKE 'Major%' THEN 3
            ELSE 4 END AS Sleep_Impact_on_Deadlines,

        -- Các biến thói quen khác (0-4)
        CASE WHEN Phone_Usage_Before_Sleep LIKE 'Never%' THEN 0 
             WHEN Phone_Usage_Before_Sleep LIKE 'Rarely%' THEN 1 
             WHEN Phone_Usage_Before_Sleep LIKE 'Sometimes%' THEN 2 
             WHEN Phone_Usage_Before_Sleep LIKE 'Often%' THEN 3 
             ELSE 4 END AS Phone_Usage_Before_Sleep,

        CASE WHEN Caffeine_Intake LIKE 'Never%' THEN 0
             WHEN caffeine_intake LIKE 'Rarely%' THEN 1 
             WHEN caffeine_intake LIKE 'Sometimes%' THEN 2 
             WHEN caffeine_intake LIKE 'Often%' THEN 3 
             ELSE 4 END AS Caffeine_Intake,

        CASE WHEN Exercise_Frequency LIKE 'Never%' THEN 0 
             WHEN Exercise_Frequency LIKE 'Rarely%' THEN 1 
             WHEN Exercise_Frequency LIKE 'Sometimes%' THEN 2 
             WHEN Exercise_Frequency LIKE 'Often%' THEN 3 
             ELSE 4 END AS Exercise_Frequency,
    
        CASE Academic_Stress_Level WHEN 'No stress' THEN 0 
                                   WHEN 'Low stress' THEN 1 
                                   WHEN 'Moderate stress' THEN 2 
                                   WHEN 'High stress' THEN 3 
                                   ELSE 4 END AS Academic_Stress_Level,
        
        -- Mapping GPA (1-5)
        CASE GPA_Rating WHEN 'Poor' THEN 1 
                        WHEN 'Below Average' THEN 2 
                        WHEN 'Average' THEN 3 
                        WHEN 'Good' THEN 4 
                        ELSE 5 END AS GPA_Rating


    FROM raw_student_data
),

feature_engineering AS (
    -- Bước 2: Tạo các chỉ số mới dựa trên mapped_data
    SELECT *,
        (Sleep_Impact_on_Deadlines * Sleep_Impact_on_Concentration) AS Academic_Burnout_Score,
        (Phone_Usage_Before_Sleep * Difficulty_Falling_Asleep) AS Sleep_Hygiene_Risk
    FROM mapped_data
)
-- Bước 3: Lưu dữ liệu đã làm sạch vào bảng mới để dùng cho Stage 4
SELECT * INTO student_data_cleaned -- Tạo bảng thật để truy vấn cho nhanh
FROM feature_engineering
WHERE 
    -- A. Loại bỏ các dòng thiếu dữ liệu quan trọng (GPA và Stress)
    Academic_Stress_Level IS NOT NULL 
    AND GPA_Rating IS NOT NULL
    
    -- B. Loại bỏ các dữ liệu mâu thuẫn (Validation)
    AND NOT (Sleep_Hygiene_Risk >= 16 AND Overall_Sleep_Quality >= 4) -- Thói quen cực xấu nhưng ngủ vẫn rất tốt
    AND NOT (Sleep_Hours_Total <= 3.5 AND Daytime_Fatigue <= 1)      -- Ngủ cực ít nhưng không thấy mệt
    AND NOT (Academic_Burnout_Score >= 16 AND Academic_Stress_Level <= 1); -- Burnout cao nhưng không stress

-----------------------------------------------------
-- KIỂM TRA KẾT QUẢ GIAI ĐOẠN 1
-----------------------------------------------------

-- Xem dữ liệu đã sạch
SELECT TOP 10 * FROM student_data_cleaned;

-- Đếm tổng số dòng còn lại sau khi làm sạch
SELECT 
    (SELECT COUNT(*) FROM raw_student_data) AS Raw_Count,
    (SELECT COUNT(*) FROM student_data_cleaned) AS Cleaned_Count,
    ((SELECT COUNT(*) FROM raw_student_data) - (SELECT COUNT(*) FROM student_data_cleaned)) AS Rows_Removed;
GO


-- =======================================================
-- PROJECT: STUDENT MENTAL HEALTH ANALYSIS
-- GIAI ĐOẠN 2: PHÂN TÍCH DỮ LIỆU (EXPLORATORY DATA ANALYSIS)
-- =======================================================

---------------------------------------------------------
-- 1. TỔNG QUAN VỀ GIẤC NGỦ VÀ HỌC TẬP (OVERALL VIEW)
---------------------------------------------------------
-- Xem trung bình các chỉ số theo Năm học (Year)
SELECT 
    Year,
    COUNT(*) AS Total_Students,
    ROUND(AVG(Sleep_Hours_Total), 2) AS Avg_Sleep_Hours,
    ROUND(AVG(Academic_Stress_Level * 1.0), 2) AS Avg_Stress_Level,
    ROUND(AVG(GPA_Rating * 1.0), 2) AS Avg_GPA
FROM student_data_cleaned
GROUP BY Year
ORDER BY Year;

---------------------------------------------------------
-- 2. PHÂN TÍCH MỐI QUAN HỆ GIỮA GIỜ NGỦ VÀ GPA
---------------------------------------------------------
-- Sinh viên ngủ ít có GPA thấp hơn sinh viên ngủ đủ không?
SELECT 
    CASE 
        WHEN Sleep_Hours_Total < 5 THEN 'Extremely Low (<5h)'
        WHEN Sleep_Hours_Total BETWEEN 5 AND 7 THEN 'Moderate (5-7h)'
        ELSE 'Healthy (>7h)'
    END AS Sleep_Group,
    COUNT(*) AS Student_Count,
    ROUND(AVG(GPA_Rating * 1.0), 2) AS Avg_GPA,
    ROUND(AVG(Academic_Stress_Level * 1.0), 2) AS Avg_Stress
FROM student_data_cleaned
GROUP BY 
    CASE 
        WHEN Sleep_Hours_Total < 5 THEN 'Extremely Low (<5h)'
        WHEN Sleep_Hours_Total BETWEEN 5 AND 7 THEN 'Moderate (5-7h)'
        ELSE 'Healthy (>7h)'
    END
ORDER BY Avg_GPA DESC;

---------------------------------------------------------
-- 3. TÁC ĐỘNG CỦA THÓI QUEN DÙNG ĐIỆN THOẠI (SLEEP HYGIENE)
---------------------------------------------------------
-- Rủi ro từ thói quen dùng điện thoại ảnh hưởng thế nào đến chất lượng giấc ngủ
SELECT 
    Sleep_Hygiene_Risk,
    ROUND(AVG(Overall_Sleep_Quality * 1.0), 2) AS Avg_Sleep_Quality,
    ROUND(AVG(Difficulty_Falling_Asleep * 1.0), 2) AS Avg_Difficulty_Falling_Asleep,
    COUNT(*) AS Student_Count
FROM student_data_cleaned
GROUP BY Sleep_Hygiene_Risk
HAVING COUNT(*) > 5 -- Chỉ lấy các nhóm có số lượng mẫu đáng kể
ORDER BY Sleep_Hygiene_Risk DESC;

---------------------------------------------------------
-- 4. PHÂN TÍCH CHI TIẾT VỀ SỰ KIỆT SỨC (ACADEMIC BURNOUT)
---------------------------------------------------------
-- Mối liên hệ giữa Burnout Score và việc nghỉ học (Attendance)
SELECT 
    Academic_Burnout_Score,
    ROUND(AVG(Sleep_Impact_on_Attendance * 1.0), 2) AS Avg_Absence_Rate,
    ROUND(AVG(GPA_Rating * 1.0), 2) AS Avg_GPA
FROM student_data_cleaned
WHERE Academic_Burnout_Score > 0
GROUP BY Academic_Burnout_Score
ORDER BY Academic_Burnout_Score;

---------------------------------------------------------
-- 5. TÌM KIẾM CÁC "OUTLIERS" (TRƯỜNG HỢP ĐẶC BIỆT)
---------------------------------------------------------
-- Những sinh viên có GPA cao (Good/Excellent) nhưng mức stress cực cao
SELECT 
    Record_Time,
    Year,
    Sleep_Hours_Total,
    Academic_Stress_Level,
    GPA_Rating,
    Academic_Burnout_Score
FROM student_data_cleaned
WHERE GPA_Rating >= 4 AND Academic_Stress_Level >= 3
ORDER BY Academic_Burnout_Score DESC;
GO