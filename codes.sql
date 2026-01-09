---QUESTION 1
WITH
    UmumiPortfel AS (
        SELECT
           ROUND(AVG(FAIZ_DERECESI),2) AS Umumi_Orta_Faiz,
            SUM(KREDIT_MEBLEGI) AS Umumi_Kredit_Meblegi
        FROM Kreditler
    ),
    PopulyarKredit AS (
        SELECT
            KREDIT_NOVU,
            COUNT(KREDIT_NOVU) AS Kredit_Sayi
        FROM Kreditler
        GROUP BY KREDIT_NOVU
        ORDER BY COUNT(KREDIT_NOVU) DESC
        FETCH FIRST 1 ROW ONLY
    )
SELECT
    UP.Umumi_Orta_Faiz,
    UP.Umumi_Kredit_Meblegi,
    PK.KREDIT_NOVU AS En_Populyar_Kredit_Novu
FROM UmumiPortfel UP, PopulyarKredit PK;

---QUESTION 2
select m.ad,m.soyad,m.fincode,kr.risk_kateqoriyasi, sum(k.kredit_meblegi) as umumi_mebleg
from musteriler m
inner join kreditler k on m.musteri_id=k.musteri_id 
inner join odenisler o on o.kredit_id=k.kredit_id
inner join kreditriskmelumatlari kr on k.kredit_id=kr.kredit_id
where o.status='Gecikib' 
group by m.ad,m.soyad,m.fincode,kr.risk_kateqoriyasi
order by 
case when kr.risk_kateqoriyasi = 'Yüksək' then 1 else 2 end,
sum(k.kredit_meblegi) desc;





---QUESTION 3
WITH RegionDeyerleri AS (
SELECT 
    REGEXP_SUBSTR(m.unvan, '^[^,]+')  AS region_siyahisi, 
    ROUND(AVG(K.KREDIT_MEBLEGI),2) AS orta_kredit_meblegi,
    ROUND(AVG(K.FAIZ_DERECESI),2) AS orta_faiz_derecesi
FROM MUSTERILER m INNER JOIN KREDITLER k ON m.musteri_id=k.Musteri_id 
group by
    REGEXP_SUBSTR(m.unvan, '^[^,]+') 
),
 YuksekRiskli AS (
 select REGEXP_SUBSTR(m.unvan, '^[^,]+') AS region_siyahisi,ROUND((COUNT(DISTINCT CASE WHEN kr.RISK_KATEQORIYASI = 'Yüksək' THEN m.musteri_id ELSE NULL END) * 100.0) / COUNT(DISTINCT m.MUSTERI_ID),2) as yr_musteri_faizi
 from kreditriskmelumatlari kr
 inner join kreditler k on kr.kredit_id=k.kredit_id
 inner join musteriler m on k.musteri_id=m.musteri_id
 group by REGEXP_SUBSTR(m.unvan, '^[^,]+') 
 )
 select RD.region_siyahisi,
 RD.orta_kredit_meblegi,
 RD.orta_faiz_derecesi,
 YR.yr_musteri_faizi 
 FROM RegionDeyerleri RD JOIN YuksekRiskli YR ON RD.region_siyahisi = YR.region_siyahisi
 order by yr_musteri_faizi DESC;
 
 
 ---QUESTION 4
 select k.kredit_id,k.kredit_meblegi,
 SUM(o.odenis_meblegi) as umumi_odenilmis_mebleg,
 k.kredit_meblegi-SUM(coalesce(o.odenis_meblegi,0)) as qaliq_mebleg ,
 Count(case when o.status='Gecikib' THEN 1 END) as gecikmis_odenis_sayi,
 Count(o.odenis_id) as umumi_odenis_sayi,
 Case when count(o.odenis_id) = 0 then 0
 else (cast(count(case when o.status = 'Gecikib' then 1 end) as decimal)*100.0 / Count(o.odenis_id))
 end as potensial_defolt_risk
 from kreditler k 
 left join odenisler o
 on k.kredit_id=o.kredit_id 
 group by
  k.kredit_id,k.kredit_meblegi
  order by potensial_defolt_risk desc 
  fetch first 5 rows only;
  
 ---QUESTION 5
 SELECT 
  CASE 
    WHEN AYLIQ_GELIR_MELUMATI <= 500 THEN '0-500' 
    WHEN AYLIQ_GELIR_MELUMATI BETWEEN 501 AND 1000 THEN '500-1000'
    WHEN AYLIQ_GELIR_MELUMATI BETWEEN 1001 AND 2000 THEN '1000-2000'
    ELSE '2000+' END AS AYLIQ_GELIRLER, ROUND(AVG(RISK_SKORU),2) AS ORTALAMA_SKOR,
  COUNT(CASE WHEN RISK_KATEQORIYASI = 'Yüksək' THEN 1 END) AS YUKSEK_RQ_SAYI
  FROM KREDITRISKMELUMATLARI
  GROUP BY 
 CASE 
    WHEN AYLIQ_GELIR_MELUMATI <= 500 THEN '0-500'
    WHEN AYLIQ_GELIR_MELUMATI BETWEEN 501 AND 1000 THEN '500-1000'
    WHEN AYLIQ_GELIR_MELUMATI BETWEEN 1001 AND 2000 THEN '1000-2000'
    ELSE '2000+'
    END
  ORDER BY YUKSEK_RQ_SAYI DESC;
  
---QUESTION 6
WITH KreditOdenisMelumatlari AS (
    SELECT
        k.MUSTERI_ID,
        k.KREDIT_ID,
        k.KREDIT_MEBLEGI,
        k.BITME_TARIXI,
        SUM(o.ODENIS_MEBLEGI) AS Odenilmis_Cemi,
        MAX(o.ODENIS_TARIXI) AS Son_Odenis_Tarixi
    FROM Kreditler k
    LEFT JOIN Odenisler o 
        ON k.KREDIT_ID = o.KREDIT_ID
    GROUP BY
        k.MUSTERI_ID,
        k.KREDIT_ID,
        k.KREDIT_MEBLEGI,
        k.BITME_TARIXI
),

KreditOdenisStatuslari AS (
    SELECT
        k.MUSTERI_ID,
        k.KREDIT_ID,
        k.KREDIT_MEBLEGI,
        SUM(o.ODENIS_MEBLEGI) AS Odenilmis_Cemi,
        MAX(CASE 
              WHEN o.STATUS = 'Gecikib' THEN 1 
              ELSE 0 
            END) AS Gecikme_Var_mi
    FROM Kreditler k
    LEFT JOIN Odenisler o 
        ON k.KREDIT_ID = o.KREDIT_ID
    GROUP BY
        k.MUSTERI_ID,
        k.KREDIT_ID,
        k.KREDIT_MEBLEGI
),

AktivKreditMusterileri AS (
    SELECT DISTINCT
        k.MUSTERI_ID
    FROM KreditOdenisMelumatlari k
    WHERE
        k.KREDIT_MEBLEGI > NVL(k.Odenilmis_Cemi, 0)
        AND k.BITME_TARIXI > SYSDATE
        AND k.Son_Odenis_Tarixi >= ADD_MONTHS(SYSDATE, -6)
),

PotensialTekrarMusteriler AS (
    SELECT DISTINCT
        k.MUSTERI_ID
    FROM KreditOdenisStatuslari k
    WHERE
        k.KREDIT_MEBLEGI <= NVL(k.Odenilmis_Cemi, 0)
        AND NOT EXISTS (
            SELECT 1
            FROM KreditOdenisStatuslari x
            WHERE x.MUSTERI_ID = k.MUSTERI_ID
              AND x.Gecikme_Var_mi = 1
        )
)

SELECT
    'Aktiv Kredit Müştəriləri' AS Seqment,
    COUNT(DISTINCT a.MUSTERI_ID) AS Musteri_Sayi,
    TRUNC(AVG((SYSDATE - m.DOGUM_TARIXI) / 365.25)) AS Orta_Yas
FROM AktivKreditMusterileri a
JOIN Musteriler m 
    ON a.MUSTERI_ID = m.MUSTERI_ID

UNION ALL

SELECT
    'Potensial Təkrar Müştərilər' AS Seqment,
    COUNT(DISTINCT p.MUSTERI_ID) AS Musteri_Sayi,
    TRUNC(AVG((SYSDATE - m.DOGUM_TARIXI) / 365.25)) AS Orta_Yas
FROM PotensialTekrarMusteriler p
JOIN Musteriler m 
    ON p.MUSTERI_ID = m.MUSTERI_ID;


  
