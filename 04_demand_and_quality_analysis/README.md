# 📊 Demand and Quality Analysis

Bu klasör, İstanbul cafe pazarında **talep (demand)**, **kalite güvenilirliği** ve **fiyat–kalite dengesi** analizlerini içerir.

---

## Amaç

Önceki adımda hesaplanan arz ve rekabet baskısından bağımsız olarak:

- İnsan hareketliliğinin (talep) nerelerde yoğunlaştığını
- Kalite algısının (rating) ne kadar güvenilir olduğunu
- Fiyat–kalite dengesinin hangi segmentlerde güçlü olduğunu

SQL seviyesinde hesaplanan metrikler üzerinden analiz eder.

> Bu katman rekabet ölçmez, fırsat skoru üretmez.  
> Ancak **"ayağı var mı?"** ve **"kalitesi güvenilir mi?"** sorularını cevaplar.

---

## Analizler

### 1. Pedestrian Activity Proxy (Cafe-Based Heatmap)

- İstanbul alanı **500m × 500m grid'lere** bölünmüştür
- Her grid için `cafe_count` ve `total_reviews` hesaplanmıştır
- `heat_weight = (10 × cafe_count) + (0.1 × total_reviews)` formülü uygulanmıştır
- Gerçek yaya trafiği verisi yerine **proxy model** kullanılmıştır

**Çıktı:** [v_traffic_heatmap_final.csv](v_traffic_heatmap_final.csv)

### 2. Rating vs Review Volume (Scatter Analizi)

- Rating ve yorum hacmi ilişkisi incelenmiştir
- `LOG(1 + user_ratings_total)` dönüşümü uygulanmıştır (sağa çarpık dağılım)
- **Yüksek rating + düşük yorum** → belirsiz kalite
- **Orta-yüksek rating + yüksek yorum** → güvenilir kalite

**Çıktı:** [v_scatter_cafe_rating_reviews.csv](v_scatter_cafe_rating_reviews.csv)

### 3. Price–Quality Value Index

- Fiyat segmentasyonu: Cheap (1), Mid (2), Expensive (3-4)
- `value_score = rating × LOG(1 + user_ratings_total) / price_weight`
- Ucuz segment genellikle en yüksek değer/fiyat oranına sahip

**Çıktı:** [v_price_value_index.csv](v_price_value_index.csv)

---

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `v_traffic_heatmap_final.csv` | Grid bazlı trafik proxy verileri |
| `v_scatter_cafe_rating_reviews.csv` | Rating–review scatter plot verisi |
| `v_price_value_index.csv` | Fiyat–kalite değer indeksi |

---

## Temel Bulgular

- Yüksek cafe yoğunluğu her zaman yüksek trafik anlamına gelmiyor
- Rating, yorum hacmiyle birlikte okunmadıkça güvenilir değil → Bayesian rating gerekli
- Orta fiyat segmenti çoğu zaman en dengeli performansı gösteriyor
- Pahalı segmentte kalite farkı net değilse değer kaybı oluşuyor
