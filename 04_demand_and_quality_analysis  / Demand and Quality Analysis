
# Demand and Quality Analysis  


Bu klasör, önceki adımda hesaplanan **arz ve rekabet baskısından bağımsız olarak**,  
İstanbul’daki cafe pazarında:

- **insan hareketliliğinin (talep) nerelerde yoğunlaştığını**  
- **kalite algısının (rating) ne kadar güvenilir olduğunu**  
- **fiyat–kalite dengesinin hangi segmentlerde güçlü olduğunu**

SQL seviyesinde hesaplanan metrikler üzerinden analiz eder.

Bu katman:
- **rekabet ölçmez**
- **fırsat skoru üretmez**
- ancak **karar vermek için gerekli “ayağı var mı?” ve “kalitesi güvenilir mi?” sorularını** cevaplar.

---

## Bu Klasörde Yer Alan Görseller

###  Pedestrian Activity Proxy (Cafe-Based Heatmap)  
 _Cafe yoğunluğu ve kullanıcı etkileşimi üzerinden üretilmiş talep proxy’si_

<img width="869" height="510" alt="Ekran Resmi 2026-02-13 13 24 40" src="https://github.com/user-attachments/assets/ac549837-c41c-4a12-9b42-63d274f25c4f" />


---

###  Relationship Between Cafe Ratings and Review Volume  
 _Kalite (rating) ile görünürlük (review hacmi) ilişkisi_
<img width="910" height="514" alt="Ekran Resmi 2026-02-13 13 25 21" src="https://github.com/user-attachments/assets/a95fe90c-93ee-4a94-9f49-cdd7a6c9dfd9" />



### Price–Quality Value Index by Price Segment  
 _Fiyat segmentlerine göre kalite / değer dengesi_
<img width="867" height="508" alt="Ekran Resmi 2026-02-13 13 25 49" src="https://github.com/user-attachments/assets/a108b209-748c-4b74-9d26-904738000a3e" />


---

## 1. Pedestrian Activity Proxy (Cafe-Based)
<img width="869" height="510" alt="Ekran Resmi 2026-02-13 13 24 40" src="https://github.com/user-attachments/assets/ac549837-c41c-4a12-9b42-63d274f25c4f" />

### Bu görselleştirmeyi neden ürettim?

Bu çalışmada gerçek yaya trafiği verisine doğrudan erişim olmadığı için,  
**“İnsanlar şehirde nerelerde bulunuyor olabilir?”** sorusuna  
**açıklanabilir bir proxy model** ile cevap üretmek istedim.

Bu nedenle:
- Cafe’leri **sosyal çekim noktası**
- Cafe yoğunluğu ve kullanıcı etkileşimini **talep göstergesi**

olarak ele aldım.

Bu harita:
-  gerçek trafik ölçümü değildir  
- bilinçli olarak **proxy (dolaylı gösterge)**’dir  

---

### Kullanılan dataset

```sql
viz.v_traffic_heatmap_final
````

Superset tarafında:

* herhangi bir hesaplama yapılmaz
* yalnızca `lat`, `lon`, `heat_weight` alanları görselleştirilir

Tüm modelleme **SQL katmanında** tamamlanmıştır.

---

### Grid yaklaşımı (neden nokta değil?)

Ham cafe verisi noktasaldır.
Ancak nokta verisiyle yoğunluk analizi yapmak analitik olarak sağlıklı değildir.

Bu nedenle İstanbul alanı:

> **500m × 500m kare grid’lere bölünmüştür**

Grid üretiminde:

* geometri `EPSG:3857`’ye dönüştürülmüş
* `ST_Extent` ile bounding box çıkarılmış
* `generate_series` ile düzenli grid oluşturulmuştur

Her grid:

* küçük bir şehir alanını temsil eder
* modelin temel analiz birimidir

---

### Grid başına hesaplanan değerler

Her grid hücresi için:

* `cafe_count` → grid içindeki cafe sayısı
* `total_reviews` → bu cafelere ait toplam kullanıcı yorumu

Bu hesaplama:

```sql
ST_Contains(grid_geom, cafe_geom)
```

mekânsal ilişkisiyle yapılmıştır.

---

### Heatmap’te kullanılan `heat_weight` formülü

```sql
CASE
  WHEN cafe_count = 0 THEN 0
  ELSE
      (10 * cafe_count)
    + (0.1 * total_reviews)
END AS heat_weight
```

---

### Formülün analitik mantığı

**Cafe sayısı (`cafe_count`)**

* insanların bilerek gittiği sosyal noktaları temsil eder
* bu yüzden **yüksek ağırlık (×10)** verilmiştir

**Toplam review sayısı (`total_reviews`)**

* geçmişteki kullanıcı etkileşimini temsil eder
* ancak aşırı büyük değerlere ulaşabildiği için
* **0.1 katsayısı ile ölçeklenmiştir**

Bu, klasik bir **feature scaling** yaklaşımıdır.

**Cafe olmayan grid’ler**

```sql
WHEN cafe_count = 0 THEN 0
```

Cafe yoksa bu proxy anlamsızdır.
Bu nedenle bilinçli olarak sıfırlanmıştır.

---

### Bu harita ne anlatır?

* Kırmızı alanlar → sosyal aktivite potansiyeli yüksek
* Soluk alanlar → cafe ve etkileşim zayıf

Bu görsel:

* mikro lokasyon analizi
* saha önceliklendirme
* talep–arz birleşimi için temel girdi

olarak kullanılır.

---

## 2. Relationship Between Cafe Ratings and Review Volume
<img width="910" height="514" alt="Ekran Resmi 2026-02-13 13 25 21" src="https://github.com/user-attachments/assets/a95fe90c-93ee-4a94-9f49-cdd7a6c9dfd9" />

### Bu görseli neden oluşturdum?

Bu grafiğin amacı şudur:

> **“Yüksek rating gerçekten güvenilir kalite mi, yoksa düşük örneklem yanılgısı mı?”**

Rating’i tek başına okumak istatistiksel olarak yanıltıcıdır.
Bu nedenle rating ile **yorum hacmini birlikte** görmek istedim.

---

### Kullanılan dataset

```sql
mart.v_scatter_cafe_rating_reviews
```

Bu view doğrudan şu mantıkla üretilmiştir:

```sql
LOG(1 + user_ratings_total) AS user_ratings_log
```

---

### Neden log dönüşümü?

`user_ratings_total` dağılımı:

* aşırı sağa çarpık
* çok az cafe çok fazla yoruma sahip

Log dönüşümü:

* küçük değerleri korur
* büyük değerleri sıkıştırır
* ilişkiyi okunabilir hale getirir

Bu **istatistiksel normalizasyon**dur, görsel hile değildir.

---

### Ekseni ve segmentler

* **X ekseni:** `user_ratings_log` → görünürlük / bilinirlik
* **Y ekseni:** `rating` → ham kalite algısı
* **Renk:** `rating_band_fine` → görsel ayrıştırma

---

### Bu scatter neyi gösterir?

* **Yüksek rating + düşük yorum** → belirsiz kalite
* **Orta-yüksek rating + yüksek yorum** → güvenilir kalite
* **Düşük rating + yüksek yorum** → operasyonel problem sinyali

Bu grafik şunu kanıtlar:

> **Rating, yorum hacmiyle birlikte okunmadıkça güvenilir değildir.**

Bu nedenle Bayesian rating ve weighted score hesapları **zorunlu hale gelir**.

---

## 3. Price–Quality Value Index by Price Segment
<img width="867" height="508" alt="Ekran Resmi 2026-02-13 13 25 49" src="https://github.com/user-attachments/assets/a108b209-748c-4b74-9d26-904738000a3e" />


### Bu analiz neden gerekli?

Bu adımda şu soruya cevap aradım:

> **“Ucuz mu daha değerli, pahalı mı gerçekten karşılığını veriyor?”**

Yani:

* fiyat segmenti
* kalite
* kullanıcı güvenilirliği

birlikte değerlendirildi.

---

### Fiyat segmentasyonu

```sql
CASE
  WHEN price_level = 1 THEN 'Cheap'
  WHEN price_level = 2 THEN 'Mid'
  WHEN price_level IN (3,4) THEN 'Expensive'
END
```

---

### Kullanılan temel metrikler

* `rating`
* `user_ratings_total`
* `LOG(1 + user_ratings_total)` → güvenilirlik ölçeği

Yalnızca:

```text
review_reliability = 'Reliable'
```

olan cafeler dahil edilmiştir.

---

### Price–Quality Value Score formülü

```sql
rating * LOG(1 + user_ratings_total) / price_weight
```

Price weight:

* Cheap → 1.0
* Mid → 1.2
* Expensive → 1.5

---

### Formülün mantığı

* Yüksek rating → kalite
* Yüksek review → güvenilirlik
* Yüksek fiyat → beklenti artışı

Bu nedenle:

* pahalı cafe daha iyi olmak zorunda
* ucuz cafe aynı rating ile daha avantajlıdır

---

### Bu görsel ne anlatır?

* Ucuz segment → genellikle **yüksek değer / fiyat**
* Orta segment → dengeli
* Pahalı segment → kalite farkı net değilse zayıf kalır

Bu analiz:

* fiyatlandırma stratejisi
* yeni şube pozisyonlama
* rekabetten bağımsız kalite okuması

için kullanılır.

---

## Bu Klasörün Net Çıktısı

Bu katman sonunda:

* Talep proxy’si hesaplandı
* Kalite algısının güvenilirliği test edildi
* Fiyat–kalite dengesi ölçüldü

Bu çıktılar, **final opening decision** modelinde
arz ve rekabet metrikleriyle **bilinçli şekilde birleştirilmiştir**.

---

