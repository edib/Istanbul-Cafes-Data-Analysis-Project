
# 06 Decision Framework

Bu klasör, İstanbul Kafe Pazar Analizi projesinin **nihai karar üretim katmanını**
(Prescriptive Analytics) içerir.

Bu aşamada amaç; önceki katmanlarda üretilmiş tüm analitik çıktıları
(**talep, kalite, arz, rekabet**) tek bir **karar modelinde** birleştirerek,
gerçek hayatta kullanılabilir bir **önceliklendirme mekanizması** oluşturmaktır.

Bu klasörde üretilen çıktılar:
- keşifsel değildir,
- açıklayıcı (descriptive) değildir,
- karşılaştırmalı (analytical) değildir,

doğrudan **karar destek** niteliğindedir.

---

## Temel Karar Problemi

Bu katman şu soruya cevap vermek üzere tasarlanmıştır:

> **“İstanbul ilçeleri arasında, yeni bir kafe açmak için
> hangi ilçeler veri temelli olarak daha önceliklidir?”**

Bu soru:
- tek bir metrikle,
- sezgisel yorumlarla,
- yalnızca talep veya yalnızca rekabet bakılarak

cevaplanamaz.

Bu nedenle problem **çok kriterli bir karar problemi** olarak ele alınmıştır.

---

## Karar Modelinin Genel Mantığı

Model, her ilçe için aşağıdaki boyutları birlikte değerlendirir:

1. **Talep**  
2. **Mevcut kalite seviyesi**  
3. **Pazar doygunluğu (arz)**  
4. **Mekânsal rekabet sertliği**

Bu boyutlar:
- farklı ölçeklerde,
- farklı dağılımlara sahip,
- farklı yönlerde etki eden

değişkenlerdir.

Bu nedenle model şu prensiplere dayanır:

- Normalize et → karşılaştırılabilir yap  
- Ters et → cezalandırılması gereken faktörleri yansıt  
- Ağırlıklandır → iş önceliklerini modele yansıt  

---

##  Pipeline

Bu klasörde kullanılan **tekil ve nihai veri kaynağı zinciri** aşağıdaki gibidir:

```

clean.cafes
↓
mart.district_summary
↓
mart.cafe_competition_2km
↓
mart.v_district_opportunity_vs_competition
↓
mart.v_final_opening_decision
↓
mart.v_final_opening_decision_scored
↓
mart.v_final_opening_decision_labeled

```

---

## 1. Opportunity – Competition Analitik Haritası

###  View
```

mart.v_district_opportunity_vs_competition

```

Bu view, karar öncesi **analitik konumlandırma** sağlar.

### İçerdiği değişkenler:

| Değişken | Açıklama |
|--------|---------|
| `district` | İlçe adı |
| `opportunity_score` | İlçenin yapısal fırsat seviyesi |
| `avg_competition_2km` | Ortalama 2 km rekabet sertliği |
| `cafe_count` | Toplam kafe sayısı |

---

###  Ortalama Rekabet (2km)

Rekabet şu şekilde ölçülür:

- Her bir kafe için
- 2 km yarıçap içinde
- kaç rakip kafe bulunduğu hesaplanır

Bu mikro seviye ölçüm,
ilçe bazında **ortalama** alınarak makro seviyeye taşınır.

**Neden ortalama?**
- uç değerlerin etkisini azaltmak
- ilçenin genel rekabet profilini temsil etmek

---

## 2. Opportunity Score’un Hesaplanması

Opportunity score,
ilçenin **yeni giriş için ne kadar “boşluk” barındırdığını** ölçer.

Bu skor şu bileşenlerden oluşur:

###  Demand

```

total_reviews_norm

```

- Google review sayısı
- gerçek kullanıcı ilgisinin proxy’si olarak kullanılır
- normalize edilerek diğer değişkenlerle aynı ölçeğe getirilir

---

###  Quality

```

avg_rating_norm

```

- İlçedeki mevcut kalite seviyesi
- çok düşük kalite → talep sürdürülemez
- çok yüksek kalite + düşük arz → fırsat sinyali

---

###  Supply – Ters

```

1 - cafe_count_norm

```

- Kafe sayısı arttıkça fırsat azalır
- Bu nedenle **bilinçli olarak ters çevrilmiştir**

---

###  Opportunity Score Formülü

```

opportunity_score =
0.45 × total_reviews_norm
+0.45 × avg_rating_norm
+0.35 × (1 − cafe_count_norm)

```

Bu ağırlıklar:
- talep ve kaliteyi önceliklendirir
- arzı tek başına belirleyici olmaktan çıkarır

---

## 3. Karar Öncesi Feature Tablosu

###  View
```

mart.v_final_opening_decision

```

Bu tablo, **henüz karar üretmez**.

Sadece karar için gerekli tüm sinyalleri tek satırda toplar.

| Değişken | Anlam |
|-------|------|
| `opportunity_score` | Yapısal fırsat |
| `avg_competition_2km` | Rekabet sertliği |
| `cafe_count` | Doygunluk |
| `avg_rating` | Mevcut kalite |
| `active_traffic_grids` | Yaya hareketliliği (proxy) |

Bu tablo, karar modelinin **feature set’i**dir.

---

## 4. Nihai Karar Skoru (Decision Score)

### View
```

mart.v_final_opening_decision_scored

```

Bu aşamada model artık **karar üretir**.

---

###  Normalizasyon (Safe Min–Max)

Her değişken için:

```

(x - min(x)) / (max(x) - min(x))

```

Eğer bir değişkende tüm değerler eşitse:
- istatistiksel olarak **nötr değer (0.5)** atanır
- modelin çökmesi engellenir

---

###  Nihai Ağırlıklandırma

```

decision_score =
0.40 × opportunity_norm
+0.30 × (1 − competition_norm)
+0.20 × (1 − cafe_count_norm)
+0.10 × rating_norm

```

#### Ağırlıkların Mantığı

- Opportunity → ana itici güç
- Rekabet → en büyük risk faktörü
- Doygunluk → uzun vadeli sürdürülebilirlik
- Kalite → dengeleyici sinyal

Bu model **popülerliği değil**,  
**yatırım mantığını** ödüllendirir.

---

## 5. İş Dili Etiketleme

### View
```

mart.v_final_opening_decision_labeled

```
```

≥ 0.70 → STRONG OPENING CANDIDATE
≥ 0.60 → MEDIUM POTENTIAL
< 0.60 → LOW PRIORITY

```

Bu katman:
- analitik sonucu
- yöneticiler için okunabilir hâle getirir

---

##  Modelin Bilinçli Varsayımları

- Merkezi ilçeler cezalandırılabilir
- Düşük talep ama düşük rekabet bölgeleri yükselebilir
- Bu bir **risk–ödül modeli**dir

Bu, modelin hatası değil;
**bilinçli yatırım perspektifidir**.

---

##  Executive Seviyede Tek Cümle

> “Bu karar modeli, İstanbul ilçelerini talep, kalite, rekabet ve doygunluğu birlikte değerlendirerek, yeni kafe yatırımları için veri temelli bir önceliklendirme sunar.”

---




