-- Eðer tablolar varsa sil
IF OBJECT_ID('dbo.Siparis_Detay','U') IS NOT NULL DROP TABLE dbo.Siparis_Detay;
IF OBJECT_ID('dbo.Siparis','U') IS NOT NULL DROP TABLE dbo.Siparis;
IF OBJECT_ID('dbo.Urun','U') IS NOT NULL DROP TABLE dbo.Urun;
IF OBJECT_ID('dbo.Kategori','U') IS NOT NULL DROP TABLE dbo.Kategori;
IF OBJECT_ID('dbo.Satici','U') IS NOT NULL DROP TABLE dbo.Satici;
IF OBJECT_ID('dbo.Musteri','U') IS NOT NULL DROP TABLE dbo.Musteri;
GO

--Musteri Tablosu
CREATE TABLE Musteri(
    musteri_id INT IDENTITY PRIMARY KEY,
    musteri_ad NVARCHAR(50) NOT NULL,
    musteri_soyad NVARCHAR(50) NOT NULL,
    musteri_email NVARCHAR(255) UNIQUE NOT NULL,
    musteri_sehir NVARCHAR(50),
    musteri_kayit_tarihi DATETIME2 DEFAULT SYSUTCDATETIME()
);

--Satici Tablosu
CREATE TABLE Satici(
    satici_id INT IDENTITY PRIMARY KEY,
    satici_ad NVARCHAR(100) NOT NULL,
    satici_adres NVARCHAR(255)
);

--Kategori Tablosu
CREATE TABLE Kategori(
    kategori_id INT IDENTITY PRIMARY KEY,
    kategori_ad NVARCHAR(100) NOT NULL UNIQUE
);

--Urun Tablosu
CREATE TABLE Urun(
    urun_id INT IDENTITY PRIMARY KEY,
    urun_ad NVARCHAR(150) NOT NULL,
    urun_fiyat DECIMAL(10,2) NOT NULL CHECK(urun_fiyat>=0),
    urun_stok INT NOT NULL CHECK(urun_stok>=0),
    kategori_id INT NOT NULL,
    satici_id INT NOT NULL,
    CONSTRAINT FK_Urun_Kategori FOREIGN KEY (kategori_id) REFERENCES Kategori(kategori_id),
    CONSTRAINT FK_Urun_Satici FOREIGN KEY (satici_id) REFERENCES Satici(satici_id)
);

--Siparis Tablosu
CREATE TABLE Siparis(
    siparis_id INT IDENTITY PRIMARY KEY,
    musteri_id INT NOT NULL,
    siparis_tarih DATETIME2 DEFAULT SYSUTCDATETIME(),
    siparis_toplam_tutar DECIMAL(12,2) NOT NULL CHECK(siparis_toplam_tutar>=0),
    siparis_odeme_turu NVARCHAR(50),
    CONSTRAINT FK_Siparis_Musteri FOREIGN KEY (musteri_id) REFERENCES Musteri(musteri_id) ON DELETE CASCADE
);

--Siparis_Detay Tablosu
CREATE TABLE Siparis_Detay(
    siparis_detay_id INT IDENTITY PRIMARY KEY,
    siparis_id INT NOT NULL,
    urun_id INT NOT NULL,
    adet INT  NOT NULL CHECK(adet>0),
    birim_fiyat DECIMAL(10,2) NOT NULL CHECK(birim_fiyat>=0),
    CONSTRAINT FK_Detay_Siparis FOREIGN KEY (siparis_id) REFERENCES Siparis(siparis_id) ON DELETE CASCADE,
    CONSTRAINT FK_Detay_Urun FOREIGN KEY (urun_id) REFERENCES Urun(urun_id)
);

-- Indexler
CREATE NONCLUSTERED INDEX IX_Urun_Kategori ON Urun(kategori_id);
CREATE NONCLUSTERED INDEX IX_Urun_Satici ON Urun(satici_id);
CREATE NONCLUSTERED INDEX IX_Siparis_Musteri ON Siparis(musteri_id);

-- Örnek Veriler
INSERT INTO Musteri(musteri_ad, musteri_soyad, musteri_email, musteri_sehir)
VALUES
('Ayse','Yilmaz','ayse.y@example.com','Istanbul'),
('Mehmet','Kara','mehmet.k@example.com','Ankara'),
('Zeynep','Demir','zeynep.d@example.com','Izmir'),
('Ali','Cetin','ali.c@example.com','Istanbul'),
('Ece','Sari','ece.s@example.com','Bursa');

INSERT INTO Satici(satici_ad, satici_adres)
VALUES
('TrendySat','Istanbul/Avcilar'),
('ModaPazar','Ankara/Cankaya'),
('TeknoDunya','Izmir/Karsiyaka');

INSERT INTO Kategori(kategori_ad)
VALUES
('Elektronik'),
('Giyim'),
('Ev & Yasam');

INSERT INTO Urun(urun_ad, urun_fiyat, urun_stok, kategori_id, satici_id)
VALUES
('Kablosuz Kulaklik', 599.90, 50, 1, 3),
('Kot Pantolon', 249.50, 100, 2, 2),
('Mutfak Seti', 129.99, 30, 3, 1),
('Laptop 14"', 12999.00, 10, 1, 3),
('Tisort', 89.90, 200, 2, 2),
('Kahve Makinesi', 899.00, 15, 3, 1);

INSERT INTO Siparis(musteri_id, siparis_tarih, siparis_toplam_tutar, siparis_odeme_turu)
VALUES
(1, '2025-09-20', 699.89, 'Kredi Kartý'),
(2, '2025-09-21', 12999.00, 'Kapýda Ödeme'),
(1, '2025-09-22', 339.80, 'Kredi Kartý'),
(4, '2025-09-23', 249.50, 'Kredi Kartý');

INSERT INTO Siparis_Detay(siparis_id, urun_id, adet, birim_fiyat)
VALUES
(1, 1, 1, 599.90),
(1, 3, 1, 99.99),
(2, 4, 1, 12999.00),
(3, 5, 2, 89.90),
(4, 2, 1, 249.50);

--TEMEL SORGULAR
--En çok sipariþ veren 5 müþteri.
SELECT TOP 5 
    M.musteri_ad,
    M.musteri_soyad,
    COUNT(S.siparis_id) AS siparis_sayisi
FROM Musteri M
JOIN Siparis S ON M.musteri_id = S.musteri_id
GROUP BY M.musteri_ad, M.musteri_soyad
ORDER BY siparis_sayisi DESC;

-- En çok satýlan ürünler
SELECT 
    U.urun_ad,
    SUM(SD.adet) AS toplam_adet_satis
FROM Urun U
JOIN Siparis_Detay SD ON U.urun_id = SD.urun_id
GROUP BY U.urun_ad
ORDER BY toplam_adet_satis DESC;

--En yüksek cirosu olan satýcýlar
SELECT 
    S.satici_ad,
    SUM(SD.adet * SD.birim_fiyat) AS toplam_ciro
FROM Satici S
JOIN Urun U ON S.satici_id = U.satici_id
JOIN Siparis_Detay SD ON U.urun_id = SD.urun_id
GROUP BY S.satici_ad
ORDER BY toplam_ciro DESC;

--AGGREGATE & GROUP BY
--Þehirlere göre müþteri sayýsý
SELECT 
    musteri_sehir,
    COUNT(*) AS musteri_sayisi
FROM Musteri
GROUP BY musteri_sehir
ORDER BY musteri_sayisi DESC;

--Kategori bazlý toplam satýþlar 
SELECT 
    K.kategori_ad,
    SUM(SD.adet * SD.birim_fiyat) AS toplam_satis
FROM Kategori K
JOIN Urun U ON K.kategori_id = U.kategori_id
JOIN Siparis_Detay SD ON U.urun_id = SD.urun_id
GROUP BY K.kategori_ad
ORDER BY toplam_satis DESC;

--Aylara göre sipariþ sayýsý
SELECT 
    FORMAT(siparis_tarih, 'yyyy-MM') AS ay,
    COUNT(*) AS siparis_sayisi
FROM Siparis
GROUP BY FORMAT(siparis_tarih, 'yyyy-MM')
ORDER BY ay;


--JOIN'ler
---	Sipariþlerde müþteri bilgisi + ürün bilgisi + satýcý bilgisi
SELECT 
    S.siparis_id,
    M.musteri_ad,
    M.musteri_soyad,
    U.urun_ad,
    Sa.satici_ad,
    SD.adet,
    SD.birim_fiyat,
    (SD.adet * SD.birim_fiyat) AS toplam_tutar
FROM Siparis S
JOIN Musteri M ON S.musteri_id = M.musteri_id
JOIN Siparis_Detay SD ON S.siparis_id = SD.siparis_id
JOIN Urun U ON SD.urun_id = U.urun_id
JOIN Satici Sa ON U.satici_id = Sa.satici_id
ORDER BY S.siparis_id;

--Hiç satýlmamýþ ürünler
SELECT 
    U.urun_id,
    U.urun_ad
FROM Urun U
LEFT JOIN Siparis_Detay SD ON U.urun_id = SD.urun_id
WHERE SD.urun_id IS NULL;

--Hiç sipariþ vermemiþ müþteriler
SELECT 
    M.musteri_id,
    M.musteri_ad,
    M.musteri_soyad
FROM Musteri M
LEFT JOIN Siparis S ON M.musteri_id = S.musteri_id
WHERE S.musteri_id IS NULL;
