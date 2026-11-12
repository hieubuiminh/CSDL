-- Synthetic existing data for the original wide-column schema.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
INSERT INTO Nguyen_Nhan VALUES ('NN-LEG','Nguyen nhan thu nghiem');
INSERT INTO CSYT VALUES ('CS-LEG','Co so thu nghiem','Dia chi thu nghiem','0000000000');
INSERT INTO Noi_Mat VALUES ('XA-LEG','Xa thu nghiem');
INSERT INTO UBND VALUES ('UB-LEG','UBND thu nghiem','Phuong','Dia chi thu nghiem','0000000000');
INSERT INTO Can_Bo VALUES ('CB-LEG','990000000901','Can bo thu nghiem','Ho tich','0000000000','UB-LEG');
INSERT INTO Cong_Dan VALUES
 ('990000000101','Nguoi thu 1','1950-01-01','Nam','Que thu','Kinh','0000000000','Đã mất'),
 ('990000000102','Nguoi thu 2','1960-01-01','Nữ','Que thu','Kinh','0000000000','Đang sống'),
 ('990000000103','Nguoi thu 3','1970-01-01','Nam','Que thu','Kinh','0000000000','Đang sống'),
 ('990000000104','Nguoi thu 4','1980-01-01','Nữ','Que thu','Kinh','0000000000','Đang sống'),
 ('990000000105','Nguoi khai thu','1990-01-01','Khác','Que thu','Kinh','0000000000','Đang sống');
INSERT INTO Giay_Bao_Tu VALUES
 ('GBT-LEG-1','2026-08-02','2026-08-01 12:00:00','Noi thu','Mo ta giu nguyen','NN-LEG','XA-LEG','CS-LEG'),
 ('GBT-LEG-2','2026-08-02','2026-08-01 12:00:00','Noi thu','Mo ta giu nguyen','NN-LEG','XA-LEG','CS-LEG'),
 ('GBT-LEG-3','2026-08-02','2026-08-01 12:00:00','Noi thu','Mo ta giu nguyen','NN-LEG','XA-LEG','CS-LEG'),
 ('GBT-LEG-4','2026-08-02','2026-08-01 12:00:00','Noi thu','Mo ta giu nguyen','NN-LEG','XA-LEG','CS-LEG');
INSERT INTO Ho_So_Khai_Tu VALUES
 ('KT-LEG-1','2026-08-03','Con','Đã hoàn tất','GBT-LEG-1','990000000101','990000000105','CB-LEG'),
 ('KT-LEG-2','2026-08-03','Con','Đã tiếp nhận','GBT-LEG-2','990000000102','990000000105','CB-LEG'),
 ('KT-LEG-3','2026-08-03','Con','Đang xử lý','GBT-LEG-3','990000000103','990000000105','CB-LEG'),
 ('KT-LEG-4','2026-08-03','Con','Từ chối','GBT-LEG-4','990000000104','990000000105','CB-LEG');
INSERT INTO An_Tang VALUES ('AT-LEG','Hỏa táng','Nghia trang giu nguyen','2026-08-04','KT-LEG-1');
