WITH
-- Sales and Sales Details
SalesDetails AS (
    SELECT
        s.SatisID,
        s.MusteriID,
        s.PersonelID,
        s.SatisTarihi,
        s.OdemeTarihi,
        s.SevkTarihi,
        s.ShipVia,
        s.NakliyeUcreti,
        s.SevkAdi,
        s.SevkAdresi,
        s.SevkSehri,
        s.SevkBolgesi,
        s.SevkPostaKodu,
        s.SevkUlkesi,
        sd.UrunID,
        sd.BirimFiyati,
        sd.Miktar,
        sd.?ndirim,
        (sd.BirimFiyati * sd.Miktar * (1 - sd.?ndirim)) AS SatirToplami
    FROM
        Satislar s
        INNER JOIN [Satis Detaylari] sd ON s.SatisID = sd.SatisID
),

-- Products, Categories and Suppliers Information
ProductDetails AS (
    SELECT
        u.UrunID,
        u.UrunAdi,
        u.TedarikciID,
        u.KategoriID,
        u.BirimdekiMiktar,
        u.BirimFiyati,
        u.HedefStokDuzeyi,
        u.YeniSatis,
        u.EnAzYenidenSatisMikatari,
        u.Sonlandi,
        k.KategoriAdi,
        k.Tanimi AS KategoriTanimi,
        k.Resim AS KategoriResim,
        t.SirketAdi AS TedarikciSirket,
        t.MusteriAdi AS TedarikciMusteriAdi,
        t.MusteriUnvani AS TedarikciUnvan,
        t.Adres AS TedarikciAdres,
        t.Sehir AS TedarikciSehir,
        t.Bolge AS TedarikciBolge,
        t.PostaKodu AS TedarikciPostaKodu,
        t.Ulke AS TedarikciUlke,
        t.Telefon AS TedarikciTelefon,
        t.Faks AS TedarikciFaks,
        t.WebSayfasi AS TedarikciWebSayfasi
    FROM
        Urunler u
        INNER JOIN Kategoriler k ON u.KategoriID = k.KategoriID
        INNER JOIN Tedarikciler t ON u.TedarikciID = t.TedarikciID
),

-- Employees, Territories and Regions Information
EmployeeDetails AS (
    SELECT
        p.PersonelID,
        p.SoyAdi,
        p.Adi,
        p.Unvan,
        p.UnvanEki,
        p.DogumTarihi,
        p.IseBaslamaTarihi,
        p.Adres,
        p.Sehir,
        p.Bolge,
        p.PostaKodu,
        p.Ulke,
        p.EvTelefonu,
        p.Extension,
        p.Fotograf,
        p.Notlar,
        p.BagliCalistigiKisi,
        p.FotografPath,
        b.TerritoryID,
        b.TerritoryTanimi,
        bg.BolgeID,
        bg.BolgeTanimi
    FROM
        Personeller p
        INNER JOIN PersonelBolgeler pb ON p.PersonelID = pb.PersonelID
        INNER JOIN Bolgeler b ON pb.TerritoryID = b.TerritoryID
        INNER JOIN Bolge bg ON b.BolgeID = bg.BolgeID
),

-- Customers and Demographics Information
CustomerInfo AS (
    SELECT
        m.MusteriID,
        m.SirketAdi,
        m.MusteriAdi,
        m.MusteriUnvani,
        m.Adres,
        m.Sehir,
        m.Bolge,
        m.PostaKodu,
        m.Ulke,
        m.Telefon,
        m.Faks,
        md.MusteriDesc
    FROM
        Musteriler m
        LEFT JOIN MusteriMusteriDemo mmd ON m.MusteriID = mmd.MusteriID
        LEFT JOIN MusteriDemographics md ON mmd.MusteriTypeID = md.MusteriTypeID
),

-- Shippers Information
ShipperDetails AS (
    SELECT
        NakliyeciID,
        SirketAdi AS NakliyeciSirket,
        Telefon AS NakliyeciTelefon
    FROM
        Nakliyeciler
),

-- Order Summary
OrderSummary AS (
    SELECT
        SatisID,
        MusteriID,
        SUM(SatirToplami) AS ToplamSiparisTutari,
        COUNT(DISTINCT UrunID) AS UrunSayisi
    FROM
        SalesDetails
    GROUP BY
        SatisID, MusteriID
),

-- Regional Sales Analysis
RegionalSales AS (
    SELECT
        ed.BolgeTanimi,
        COUNT(DISTINCT sd.SatisID) AS SiparisSayisi,
        SUM(sd.SatirToplami) AS ToplamSatis
    FROM
        SalesDetails sd
        INNER JOIN EmployeeDetails ed ON sd.PersonelID = ed.PersonelID
    GROUP BY
        ed.BolgeTanimi
)

-- Final Report: Comprehensive Sales Analysis with Related Details
SELECT
    sd.SatisID,
    ci.SirketAdi,
    ci.MusteriAdi,
    ci.MusteriUnvani,
    ci.Adres,
    ci.Sehir,
    ci.Bolge,
    ci.PostaKodu,
    ci.Ulke,
    ci.Telefon,
    ci.Faks,
    ed.Adi + ' ' + ed.SoyAdi AS PersonelAdSoyad,
    ed.Unvan,
    ed.UnvanEki,
    ed.BolgeTanimi,
    pd.UrunAdi,
    pd.BirimdekiMiktar,
    pd.BirimFiyati,
    pd.HedefStokDuzeyi,
    pd.YeniSatis,
    pd.EnAzYenidenSatisMikatari,
    pd.Sonlandi,
    pd.KategoriAdi,
    pd.TedarikciSirket,
    sh.NakliyeciSirket,
    sh.NakliyeciTelefon,
    sd.Miktar,
    sd.?ndirim,
    sd.SatirToplami,
    os.ToplamSiparisTutari,
    os.UrunSayisi,
    rs.SiparisSayisi AS BolgeselSiparisSayisi,
    rs.ToplamSatis AS BolgeselToplamSatis,
    sd.SatisTarihi,
    sd.OdemeTarihi,
    sd.SevkTarihi,
    sd.NakliyeUcreti
FROM
    SalesDetails sd
    INNER JOIN CustomerInfo ci ON sd.MusteriID = ci.MusteriID
    INNER JOIN EmployeeDetails ed ON sd.PersonelID = ed.PersonelID
    INNER JOIN ProductDetails pd ON sd.UrunID = pd.UrunID
    INNER JOIN ShipperDetails sh ON sd.ShipVia = sh.NakliyeciID
    INNER JOIN OrderSummary os ON sd.SatisID = os.SatisID
    INNER JOIN RegionalSales rs ON ed.BolgeTanimi = rs.BolgeTanimi
ORDER BY
    sd.SatisID;