
#  Opportunity Modeling

Bu klasör, İstanbul’daki cafe pazarında **fırsat (opportunity)** kavramını
çoklu metrikleri birleştirerek **analitik olarak modelleyen** katmandır.

Bu aşamada amaç:

- “Nerede çok cafe var?” değil  
- **“Nerede yeni bir cafe açmak daha rasyonel?”** sorusuna cevap vermektir.

Bu klasör iki ana çıktıyı içerir:

1. İlçe bazında **Opportunity Score** sıralaması  
2. İlçe × konsept bazında **Category Gap (eksiklik) analizi**

---

## Kullanılan Tablolar (Single Source of Truth)

- `mart.district_summary`
- `mart.opportunity_gaps`  
  (sadece cafe / restaurant / bakery / meal_takeaway filtrelenmiş hali)

Bu tablolar **ham veri değildir**;  
önceki katmanlarda temizlenmiş ve türetilmiş veriler üzerinden oluşturulmuş
**mart seviye analitik tablolardır**.

---

#  Görsel 1 — Top Districts by Opportunity Score


<img width="577" height="450" alt="Ekran Resmi 2026-02-13 13 56 40" src="https://github.com/user-attachments/assets/acff404d-ee83-4c02-89fe-fa6b1d14c90c" />

---

## 1) Görselleştirmenin Kaynağı

**Superset dataset:**

```

mart.district_summary

```

Bu tabloda:

- Her ilçe **tek satır** ile temsil edilir
- Superset’te metrik olarak `AVG(opportunity_score)` seçilmiştir
- Ancak her ilçe tek satır olduğu için bu fiilen:

```

opportunity_score

````

anlamına gelir.

Bu durum Superset’in aggregation zorunluluğundan kaynaklanır, **model hatası değildir**.

---

## 2) `mart.district_summary` Nasıl Üretildi?

Tablo, `clean.cafes` üzerinden **iki aşamalı** olarak oluşturulmuştur.

### Aşama 1 — İlçe Bazında Ham Özet

```sql
SELECT
    district,
    COUNT(*) AS cafe_count,
    AVG(rating) AS avg_rating,
    COUNT(*) FILTER (WHERE rating >= 4.5) AS high_quality_count,
    AVG(price_level) AS avg_price_level,
    SUM(user_ratings_total) AS total_reviews,
    AVG(user_ratings_total) AS avg_reviews
FROM clean.cafes
GROUP BY district;
````

Bu aşamada elde edilen metrikler:

| Kolon              | Anlam                                |
| ------------------ | ------------------------------------ |
| cafe_count         | İlçedeki toplam cafe sayısı          |
| avg_rating         | İlçedeki genel kalite seviyesi       |
| high_quality_count | 4.5+ rating’li cafe sayısı           |
| total_reviews      | İlçedeki toplam kullanıcı etkileşimi |
| avg_reviews        | Cafe başına ortalama etkileşim       |

Bu metrikler **henüz doğrudan karşılaştırılamaz**, çünkü ölçekleri farklıdır.

---

## 3) Normalizasyon (İstatistiksel Temel)

Farklı ölçeklerdeki metrikleri karşılaştırabilmek için
**min–max normalization** uygulanmıştır.

### Kullanılan formül

```
x_norm = (x − min(x)) / (max(x) − min(x))
```

SQL karşılığı:

```sql
(x - MIN(x) OVER())
/ (MAX(x) OVER() - MIN(x) OVER())
```

### Normalize edilen metrikler

| Orijinal Metrik | Normalize Kolon    |
| --------------- | ------------------ |
| avg_rating      | avg_rating_norm    |
| total_reviews   | total_reviews_norm |
| cafe_count      | cafe_count_norm    |

**İstatistiksel anlamı:**

* Tüm metrikler 0–1 aralığına çekilir
* Ölçek farkı yüzünden bir metrik diğerini baskılayamaz
* Ağırlıklandırma anlamlı hale gelir

---

## 4) Opportunity Score Formülü

### Nihai formül

```
opportunity_score =
    0.45 × total_reviews_norm
  + 0.45 × avg_rating_norm
  + 0.35 × (1 − cafe_count_norm)
```

---

## 5) Formülün Mantığı

Bu skor **“en popüler ilçe”yi değil**,
**“yeni cafe açmak için daha rasyonel ilçe”yi** bulmak için tasarlanmıştır.

### Pozitif bileşenler

* **Talep (Demand)**
  `total_reviews_norm`
  → Kullanıcı etkileşimi yüksek mi?

* **Kalite (Quality)**
  `avg_rating_norm`
  → Mevcut cafe ekosistemi güçlü mü?

### Negatif (ters) bileşen

* **Arz (Supply – ters)**
  `1 − cafe_count_norm`
  → Cafe sayısı arttıkça fırsat azalır

Bu bilinçli bir tercihtir:

> Çok kaliteli ve çok popüler ama doymuş pazarlar
> yatırım açısından daha risklidir.

---

## 6) Görsel Nasıl Okunmalı?

* Y-axis: İlçeler
* X-axis: Opportunity Score
* Sıralama: DESC
* Top N (10 ilçe)

Grafik şu soruya cevap verir:

> “Bugünkü verilerle bakıldığında,
> İstanbul’da yeni bir cafe açmak için
> **fırsat bileşimi en güçlü ilçeler hangileri?**”

---

## 7) Yanlış Yorumlanmaması Gereken Nokta

Bu grafik:

 “En popüler ilçeler”
 “En çok cafe olan yerler”
 “En iyi cafeler burada”

**DEĞİLDİR.**

Bu grafik **fırsat–arz–talep dengesi** grafiğidir.

---

#  Görsel 2 — District Category Gap Heatmap

<img width="1137" height="538" alt="Ekran Resmi 2026-02-13 13 57 44" src="https://github.com/user-attachments/assets/68f6d2e8-bb9b-403e-84e4-56ad4eaedf5d" />

---

## 8) Görselin Amacı

Bu heatmap şu soruya cevap verir:

> “Seçilen ilçede, hangi cafe konsepti
> şehir geneline kıyasla eksik temsil ediliyor?”

Bu analiz, fırsat skorundan sonra gelen **ikinci karar katmanıdır**:

* Önce: “Hangi ilçe?”
* Sonra: **“Hangi konsept?”**

---

## 9) Kullanılan Veri Mantığı

Her satır:

```
1 district × 1 type_token
```

### Temel hesaplamalar

#### İlçe içi type payı

```
district_type_share = cafe_count / district_total
```

#### Şehir geneli type payı

```
global_type_share =
    SUM(cafe_count for same type)
/   SUM(district_total)
```

#### Gap Score (eksiklik skoru)

```
gap_score = global_type_share − district_type_share
```

* `gap_score > 0` → ilçe bu konseptte **eksik**
* `gap_score < 0` → ilçe bu konseptte **zaten güçlü**

Superset’te bilinçli olarak:

```
gap_score > 0
```

filtresi uygulanmıştır.

---

## 10) Heatmap Ayarlarının Anlamı

* X-axis: `type_token`
* Y-axis: `district`
* Metric: `SUM(gap_score)`
* Normalize across: `heatmap`

Bu ayar:

> “En büyük konsept boşlukları nerede?”
> sorusunu netleştirir.

---

## 11) Bu Görsel Nasıl Yorumlanır?

* Koyu hücre → ilgili ilçede o konsept şehir ortalamasına göre eksik
* Bir ilçede tek koyu hücre → **net konsept boşluğu**
* Birden fazla koyu hücre → **konsept çeşitliliği zayıf**

Bu analiz:

* fırsat skorunu **aksiyona dönüştürür**
* “ilçe + konsept” kararını mümkün kılar

---

## 12) Bu Klasörün Çıktısı

Bu aşamanın sonunda:

* İlçe bazında fırsat önceliği belirlenir
* Her ilçe için konsept boşlukları görünür hale gelir
* Karar artık sezgisel değil, **ölçülebilir** olur

---
