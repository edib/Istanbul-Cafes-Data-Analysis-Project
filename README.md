# ☕ Istanbul Cafes Data Analysis Project

> **İstanbul'daki 14.879 cafe için uçtan uca veri toplama, temizleme, mekânsal analiz, fırsat modelleme ve karar destek sistemi.**

![SQL](https://img.shields.io/badge/SQL-PostgreSQL%20%2B%20PostGIS-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Google Cloud](https://img.shields.io/badge/Google_Places_API-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)
![Superset](https://img.shields.io/badge/Apache_Superset-Dashboard-20A6C9?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

**Geliştirici:** Esma Eren  
**Kapsam:** İstanbul, Türkiye — 14.879 Benzersiz Kafe  
**Teknolojiler:** Python · PostgreSQL · PostGIS · Apache Superset · Google Places API

---

## 📋 İçindekiler

| # | Katman | Açıklama | Detay |
|---|--------|----------|-------|
| 00 | [Veri Toplama](#-00---veri-toplama) | Google Places API ile Geo-Grid tarama | [→ Detay](00_data_collect/README.md) |
| 01 | [Veri Pipeline](#-01---veri-pipeline) | Raw → Clean → Mart dönüşümü | [→ Detay](01_data_pipeline/README.md) |
| 02 | [Keşifsel Analiz](#-02---keşifsel-analiz) | Descriptive & diagnostic analiz | [→ Detay](02_exploratory_analysis/02_exploratory_analysis.md) |
| 03 | [Mekânsal Rekabet Analizi](#-03---mekânsal-rekabet-analizi) | Arz dağılımı & 2km rekabet | [→ Detay](03_spatial_competition_analysis/spatial_competition_analysis.md) |
| 04 | [Talep ve Kalite Analizi](#-04---talep-ve-kalite-analizi) | Trafik proxy, rating güvenilirliği, fiyat–kalite | [→ Detay](04_demand_and_quality_analysis/README.md) |
| 05 | [Fırsat Modelleme](#-05---fırsat-modelleme) | Opportunity score & category gap | [→ Detay](05_opportunity_modeling/opportunity_modeling.md) |
| 06 | [Karar Çerçevesi](#-06---karar-çerçevesi) | Çok kriterli karar modeli (decision score) | [→ Detay](06_decision_framework/06_decision_framework.md) |
| 07 | [Dashboard & Raporlama](#-07---dashboard--raporlama) | Superset dashboard yorumlama | [→ Detay](07_dashboard_views/README.md) |
| 📖 | [Sözlük / Dictionary](#-sözlük--dictionary-index) | Kavram ve teknik terim açıklamaları | — |

---

## 🏗️ Proje Mimarisi

```
Google Places API
       │
       ▼
00_data_collect ──── Geo-Grid Nearby Search (14.879 cafe)
       │
       ▼
01_data_pipeline ─── Raw → Clean → Mart (PostGIS geometry)
       │
       ▼
02_exploratory ───── KPI, dağılım, veri doğrulama
       │
       ▼
03_spatial ────────── Harita dağılımı, 2km rekabet, ilçe baskısı
       │
       ▼
04_demand_quality ── Trafik proxy, rating-review ilişkisi, fiyat–kalite
       │
       ▼
05_opportunity ───── Opportunity score, category gap analizi
       │
       ▼
06_decision ──────── Final decision score + iş dili etiketleme
       │
       ▼
07_dashboard ─────── Superset ile 14 görsel, karar filtresi
```

---

## 🔍 00 — Veri Toplama

📄 **Detaylı Dokümantasyon:** [00_data_collect/README.md](00_data_collect/README.md)

### Denenen Yöntemler ve Sonuçları

| Faz | Yöntem | Sonuç | Neden Elendi |
|-----|--------|-------|--------------|
| 1 | OCR Tabanlı Scraping (Tesseract) | ❌ Başarısız | Düşük doğruluk, sabit olmayan yapı, place_id yok |
| 2 | Selenium UI Scraping | ❌ Başarısız | Anti-bot koruması, düşük performans, kırılgan HTML |
| 3 | TextSearch API | ❌ Yetersiz | Tek sorguda max 60 sonuç, %5 kapsam |
| **4** | **Geo-Grid Based Nearby Search** | ✅ **Başarılı** | **%100 kapsam, 14.879 tekil mekân** |

### Nihai Mimari: Geo-Grid Based Nearby Search

1. İstanbul sınırları belirlendi (Boundary Box)
2. Alan ~5.000 adet **1.500m yarıçaplı** hücreye bölündü
3. Her hücre merkezi için `/nearbysearch` API isteği gönderildi
4. `place_id` ile **deduplication** yapıldı

### Dosyalar

| Dosya | Açıklama |
|-------|----------|
| [grid_scan_collect.py](00_data_collect/grid_scan_collect.py) | Geo-Grid tarama motoru |
| [place_details_ultra.py](00_data_collect/place_details_ultra.py) | Detaylı veri zenginleştirme (30+ alan) |
| [place_id_collect.py](00_data_collect/place_id_collect.py) | TextSearch API ile place_id toplama (Faz 3) |

### Toplanan Veri: 30+ Özellik

Kimlik & lokasyon · Rating & durum · İletişim · Kategoriler · Çalışma saatleri · Erişilebilirlik

---

## 🔧 01 — Veri Pipeline

📄 **Detaylı Dokümantasyon:** [01_data_pipeline/README.md](01_data_pipeline/README.md)

### Katman Mimarisi

```
raw.istanbul_cafes_ultra_kopyasi
       │
       ▼
clean.cafes ──────────── String temizleme, tip sabitleme, PostGIS geometry
clean.cafe_types ─────── 1 cafe → N type (unnest)
       │
       ▼
mart.kpi_overview ────── Global KPI'lar
mart.district_summary ── İlçe bazlı özet
mart.cafe_competition_2km ── 2km yarıçap rekabet
```

### Uygulanan Dönüşümler

- **String Temizleme:** `BTRIM()` + `NULLIF(value, '')` → NULL/empty ayrımı ortadan kalkar
- **Tip Sabitleme:** `rating → double precision`, `user_ratings_total → integer`
- **PostGIS Geometry:** `ST_SetSRID(ST_MakePoint(lon, lat), 4326)` → WGS84 uyumlu
- **Indexleme:** GIST (geometry), B-tree (district, rating, reviews, price)
- **Normalizasyon:** `clean.cafe_types` → string_to_array + unnest ile 1:N yapı

### Dosyalar

| Dosya | Açıklama |
|-------|----------|
| [01_data_pipeline.sql](01_data_pipeline/01_data_pipeline.sql) | Tam SQL pipeline (raw → clean → mart) |
| [cafes.csv](01_data_pipeline/cafes.csv) | Clean cafes çıktısı |

---

## 📈 02 — Keşifsel Analiz

📄 **Detaylı Dokümantasyon:** [02_exploratory_analysis/02_exploratory_analysis.md](02_exploratory_analysis/02_exploratory_analysis.md)

### Temel Sorular

> Veri gerçek dünya dağılımlarıyla uyumlu mu?  
> Aykırı, dengesiz veya analizi bozabilecek yapılar var mı?

### Bulgular

| Analiz | Bulgu |
|--------|-------|
| **Pazar KPI'ları** | Cafe sayısı yüksek → rekabetçi ve doygun pazar. Rating ort. 4+ → pozitif bias olasılığı. %95+ operasyonel |
| **İlçe Dağılımı** | İlçeler arası yüksek varyans. Merkezi/turistik ilçelerde yoğunlaşma |
| **Rating Dağılımı** | 4.0–4.8 bandında yoğun kümelenme. Düşük rating'li cafe sayısı az |
| **Review Dağılımı** | Sağa çarpık (right-skewed). Log-transform ve güvenilirlik eşiği gerekli |
| **2km Rekabet** | Homojen değil. Bazı cafeler düşük, bazıları yüzlerce rakiple çevrili |

### Dosyalar

| Dosya | Açıklama |
|-------|----------|
| [exploratory.sql](02_exploratory_analysis/exploratory.sql) | Keşifsel SQL sorguları |
| [cafes.csv](02_exploratory_analysis/cafes.csv) | Analiz verisi |
| [district_summary.csv](02_exploratory_analysis/district_summary.csv) | İlçe özet tablosu |
| [cafe_competition_2km.csv](02_exploratory_analysis/cafe_competition_2km.csv) | 2km rekabet verisi |

---

## 🗺️ 03 — Mekânsal Rekabet Analizi

📄 **Detaylı Dokümantasyon:** [03_spatial_competition_analysis/spatial_competition_analysis.md](03_spatial_competition_analysis/spatial_competition_analysis.md)

### Üretilen Metrikler

| Metrik | Formül | Açıklama |
|--------|--------|----------|
| **Mekânsal Dağılım** | `ST_Y(geom)`, `ST_X(geom)` | Tüm cafelerin harita koordinatları |
| **2km Rekabet** | `COUNT(*) - 1` within `ST_DWithin(2000m)` | Her cafe'nin 2km'deki rakip sayısı |
| **İlçe Rekabet Baskısı** | `AVG(competitors_within_2km)` | İlçe bazında ortalama rekabet |

### Rekabet Bantları

| Bant | Aralık |
|------|--------|
| Düşük | 0–49 |
| Orta-Düşük | 50–99 |
| Orta | 100–149 |
| Yüksek | 150–249 |
| Çok Yüksek | 250+ |

### Temel Bulgu

> İstanbul'da cafe rekabeti **homojen değil**. Sahil ve merkez akslar aşırı yoğun, iç bölgelerde kopukluk mevcut.

### Dosyalar

| Dosya | Açıklama |
|-------|----------|
| [spatial_competition.sql](03_spatial_competition_analysis/sql/spatial_competition.sql) | Mekânsal rekabet SQL'leri |

---

## 📊 04 — Talep ve Kalite Analizi

📄 **Detaylı Dokümantasyon:** [04_demand_and_quality_analysis/README.md](04_demand_and_quality_analysis/README.md)

### Üç Temel Analiz

#### 1. Pedestrian Activity Proxy (Trafik Heatmap)
- İstanbul → **500m × 500m grid** hücreleri
- `heat_weight = (10 × cafe_count) + (0.1 × total_reviews)`
- Cafe yoğunluğu + kullanıcı etkileşimi = talep proxy'si

#### 2. Rating–Review İlişkisi
- `LOG(1 + user_ratings_total)` → sağa çarpık dağılım düzeltmesi
- **Yüksek rating + düşük yorum** = kırılgan kalite → Bayesian rating gerekli
- **Yüksek review + orta rating** = güçlü ve güvenilir

#### 3. Price–Quality Value Index
- `value_score = rating × LOG(1 + reviews) / price_weight`
- Cheap → 1.0 | Mid → 1.2 | Expensive → 1.5
- Orta segment genellikle en dengeli

### Dosyalar

| Dosya | Açıklama |
|-------|----------|
| [v_traffic_heatmap_final.csv](04_demand_and_quality_analysis/v_traffic_heatmap_final.csv) | Grid bazlı trafik proxy |
| [v_scatter_cafe_rating_reviews.csv](04_demand_and_quality_analysis/v_scatter_cafe_rating_reviews.csv) | Rating–review scatter verisi |
| [v_price_value_index.csv](04_demand_and_quality_analysis/v_price_value_index.csv) | Fiyat–kalite indeksi |

---

## 🎯 05 — Fırsat Modelleme

📄 **Detaylı Dokümantasyon:** [05_opportunity_modeling/opportunity_modeling.md](05_opportunity_modeling/opportunity_modeling.md)

### Opportunity Score Formülü

```
opportunity_score = 0.45 × total_reviews_norm
                  + 0.45 × avg_rating_norm
                  + 0.35 × (1 − cafe_count_norm)
```

| Bileşen | Ağırlık | Yön | Anlam |
|---------|---------|-----|-------|
| Talep (total_reviews) | 0.45 | Pozitif | Kullanıcı etkileşimi yüksek mi? |
| Kalite (avg_rating) | 0.45 | Pozitif | Mevcut ekosistem güçlü mü? |
| Arz (cafe_count) | 0.35 | **Negatif (ters)** | Cafe sayısı ↑ → fırsat ↓ |

### Category Gap Analizi

Her ilçe × konsept çifti için:

```
gap_score = global_type_share − district_type_share
```

- `gap_score > 0` → ilçe bu konseptte **eksik temsil ediliyor**
- `gap_score < 0` → ilçe bu konseptte **zaten güçlü**

### Dosyalar

| Dosya | Açıklama |
|-------|----------|
| [opportunity_modeling.sql](05_opportunity_modeling/opportunity_modeling.sql) | Opportunity score + gap analizi SQL |

---

## ⚖️ 06 — Karar Çerçevesi

📄 **Detaylı Dokümantasyon:** [06_decision_framework/06_decision_framework.md](06_decision_framework/06_decision_framework.md)

### Decision Score Formülü

```
decision_score = 0.40 × opportunity_norm
               + 0.30 × (1 − competition_norm)
               + 0.20 × (1 − cafe_count_norm)
               + 0.10 × rating_norm
```

| Bileşen | Ağırlık | Anlam |
|---------|---------|-------|
| Fırsat (opportunity) | 0.40 | Ana itici güç |
| Rekabet (competition) | 0.30 | En büyük risk faktörü (ters) |
| Doygunluk (cafe_count) | 0.20 | Uzun vadeli sürdürülebilirlik (ters) |
| Kalite (rating) | 0.10 | Dengeleyici sinyal |

### İş Dili Etiketleri

| Skor Aralığı | Etiket |
|---------------|--------|
| ≥ 0.70 | 🟢 **STRONG OPENING CANDIDATE** |
| ≥ 0.60 | 🟡 **MEDIUM POTENTIAL** |
| < 0.60 | 🔴 **LOW PRIORITY** |

### SQL View Zinciri

```
clean.cafes → mart.district_summary → mart.cafe_competition_2km
    → mart.v_district_opportunity_vs_competition
    → mart.v_final_opening_decision
    → mart.v_final_opening_decision_scored
    → mart.v_final_opening_decision_labeled
```

### Dosyalar

| Dosya | Açıklama |
|-------|----------|
| [decision_framework.sql](06_decision_framework/decision_framework.sql) | Karar modeli SQL'leri |

---

## 📋 07 — Dashboard & Raporlama

📄 **Detaylı Dokümantasyon:** [07_dashboard_views/07_dashboard_views.md](07_dashboard_views/07_dashboard_views.md)

### Dashboard Görselleri (14 Panel)

| # | Görsel | Ne Ölçüyor |
|---|--------|------------|
| 1 | Market Overview KPI'ları | Pazar ölçeği ve genel kalite |
| 2 | Cafes by District | İlçe bazında arz eşitsizliği |
| 3 | Rating Distribution | Rating bantlarının dağılımı |
| 4 | All Cafes – Spatial Distribution | Coğrafi kümelenme |
| 5 | 2km Competition Distribution | Rekabet seviye dağılımı |
| 6 | Avg 2km Competition by District | İlçe DNA'sı |
| 7 | Pedestrian Activity Proxy | Yaya aktivite heatmap'i |
| 8 | Rating vs Review Scatter | Kalite güvenilirliği |
| 9 | Top 50 Cafes (Bayesian) | Ağırlıklı sıralama |
| 10 | Price–Quality Value Index | Fiyat segmenti değer analizi |
| 11 | Top Districts by Opportunity | Fırsat skoru sıralaması |
| 12 | Opportunity vs Competition Map | Stratejik konumlandırma |
| 13 | Category Gap Heatmap | İlçe × konsept boşlukları |
| 14 | Final Decision Matrix | Nihai karar skoru ve etiketler |

### Dashboard'un 5 Ana Mesajı

1. İstanbul'da cafe açmak **lokasyon problemidir**
2. Rating tek başına **hiçbir şey anlatmaz**
3. Rekabet korkulacak değil, **yanlış yerde tehlikelidir**
4. Trafik + rekabet + kalite **birlikte okunmalıdır**
5. Bu dashboard **nihai karar değil**, akıllı eleme aracıdır

---

## 🛠️ Teknoloji Stack

| Katman | Teknoloji |
|--------|-----------|
| Veri Toplama | Python 3.9+, Google Places API (Nearby Search + Place Details) |
| Veritabanı | PostgreSQL + PostGIS |
| Mekânsal Analiz | PostGIS (`ST_DWithin`, `ST_Buffer`, `ST_Contains`, `ST_MakePoint`) |
| Görselleştirme | Apache Superset |
| Veri İşleme | SQL (Window Functions, CTE, Lateral Join) |

---

## 📁 Proje Yapısı

```
Istanbul-Cafes-Data-Analysis-Project/
│
├── README.md                              ← Bu dosya
│
├── 00_data_collect/                       ← Veri toplama scriptleri
│   ├── readme.md
│   ├── grid_scan_collect.py
│   ├── place_details_ultra.py
│   └── place_id_collect.py
│
├── 01_data_pipeline/                      ← Raw → Clean → Mart
│   ├── README.md
│   ├── 01_data_pipeline.sql
│   └── cafes.csv
│
├── 02_exploratory_analysis/               ← Keşifsel analiz
│   ├── 02_exploratory_analysis.md
│   ├── exploratory.sql
│   ├── cafes.csv
│   ├── district_summary.csv
│   └── cafe_competition_2km.csv
│
├── 03_spatial_competition_analysis/       ← Mekânsal rekabet
│   ├── spatial_competition_analysis.md
│   └── sql/
│       └── spatial_competition.sql
│
├── 04_demand_and_quality_analysis/        ← Talep & kalite
│   ├── README.md
│   ├── v_traffic_heatmap_final.csv
│   ├── v_scatter_cafe_rating_reviews.csv
│   └── v_price_value_index.csv
│
├── 05_opportunity_modeling/               ← Fırsat modelleme
│   ├── opportunity_modeling.md
│   └── opportunity_modeling.sql
│
├── 06_decision_framework/                 ← Karar çerçevesi
│   ├── 06_decision_framework.md
│   └── decision_framework.sql
│
└── 07_dashboard_views/                    ← Dashboard yorumlama
    └── 07_dashboard_views.md
```

---

## 📊 Proje İstatistikleri

| Metrik | Değer |
|--------|-------|
| Toplam Kafe | 14.879 |
| İlçe Sayısı | 27+ |
| Veri Alanı | 30+ özellik/cafe |
| SQL View Sayısı | 15+ |
| Dashboard Panel Sayısı | 14 |
| Denenen Yöntem Sayısı | 4 |

---

## 🔑 Temel Çıktılar

1. **Veri:** İstanbul'daki tüm cafelerin 30+ özellikli, temiz, mekânsal olarak doğru dataseti
2. **Metrikler:** 2km rekabet, trafik proxy, Bayesian rating, opportunity score, decision score
3. **Model:** Talep × Kalite × Arz × Rekabet birleşimli çok kriterli karar modeli
4. **Dashboard:** 14 panelli interaktif Superset dashboard'u
5. **Karar:** İlçe bazında STRONG / MEDIUM / LOW önceliklendirme + konsept gap analizi

---

## 📖 Sözlük / Dictionary Index

Projede kullanılan temel kavram ve tekniklerin açıklamalarını içeren referans dokümanları:

| Terim | Açıklama | Doküman |
|-------|----------|---------|
| **Nearby Search (Hücresel Tarama)** | Google Places API ile Geo-Grid tabanlı mekân tarama yöntemi. Alanı küçük hücrelere bölüp her birini ayrı ayrı tarayarak %100 kapsam sağlar. | [nearbysearch.md](nearbysearch.md) |
