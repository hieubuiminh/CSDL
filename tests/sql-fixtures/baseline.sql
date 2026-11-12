-- Synthetic lookup fixtures only. No production data.
INSERT INTO Nguyen_Nhan (MaNguyenNhan,TenNguyenNhan) VALUES
 ('NN-A','Nguyen nhan thu A'),('NN-B','Nguyen nhan thu B'),('NN-C','Nguyen nhan thu C');
INSERT INTO CSYT (MaCSYT,TenCSYT,DiaChi,SDT) VALUES
 ('CS-A','Co so thu A','Dia chi thu A',NULL),
 ('CS-B','Co so thu B','Dia chi thu B',NULL),
 ('CS-C','Co so thu C','Dia chi thu C',NULL);
INSERT INTO Noi_Mat (MaXaPhuong,TenXaPhuong) VALUES
 ('XA-A','Xa thu A'),('XA-B','Xa thu B'),('PH-C','Phuong thu C');
INSERT INTO UBND (MaUBND,TenUBND,CapHanhChinh,DiaChi,SDT) VALUES
 ('UB-A','UBND thu A','Phuong','Dia chi thu UBND',NULL);
INSERT INTO Can_Bo (MaCanBo,CCCD,HoTen,ChucVu,SDT,MaUBND) VALUES
 ('CB-A','990000000901','Can bo thu A','Ho tich',NULL,'UB-A');
