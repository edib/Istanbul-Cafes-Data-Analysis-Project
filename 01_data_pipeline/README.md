
# Data Preparation Layer

Bu klasör, İstanbul cafe verisinin **ham kaynaktan analitik kullanıma hazır hale getirilmesini** kapsar.

Bu aşamanın **tek amacı**:

> Veriyi temizlemek, tip güvenli hale getirmek ve
> tüm downstream analizler için **tek ve güvenilir bir temel** oluşturmaktır.


---

## Kapsam

Bu pipeline aşağıdaki dönüşümleri içerir:

* `raw → clean → mart` katmanları
* string normalizasyonu
* veri tipi sabitleme
* geometry (PostGIS) üretimi
* analizlerde kullanılan temel mart tabloları

---

## 1. Raw Layer

### Kaynak Tablo

```text
raw.istanbul_cafes_ultra_kopyasi
```

Bu tablo, Google Places kaynaklı ham cafe verisini içerir.

Ham veride gözlenen problemler:

* boş string (`''`) değerler
* tip tutarsızlıkları
* geometry bulunmaması
* serbest metin alanlarında gürültü

Bu nedenle **doğrudan analize uygun değildir**.

---

## 2. Clean Layer

### 2.1 `clean.cafes`

Bu pipeline’ın **en kritik çıktısıdır**.

Tüm downstream analizler **yalnızca bu tabloyu** referans alır.

#### Uygulanan Temizlikler

**String alanlar**

* `BTRIM()` → baş/son boşluk temizliği
* `NULLIF(value, '')` → empty string → NULL

Amaç:

> NULL ve boş string ayrımını tamamen ortadan kaldırmak

**Veri tipleri**

* `rating` → `double precision`
* `user_ratings_total` → `integer`
* `price_level` → `integer`
* id ve metin alanları → `text`

Bu sayede:

* agregasyonlar
* istatistiksel hesaplar
* karşılaştırmalar

deterministik hale gelir.

---

### 2.2 Geometry Üretimi (PostGIS)

Latitude / longitude alanlarından WGS84 uyumlu geometry üretilmiştir:

```sql
ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
```

Bu tercih:

* gerçek dünya mesafeleriyle çalışmayı sağlar
* `ST_DWithin`, `ST_Buffer` gibi fonksiyonların doğru çalışmasını garanti eder

 Geometry olmayan kayıtlar **bilinçli olarak dışlanmıştır**.

---

### 2.3 Indexleme

Performans ve stabilite için aşağıdaki indexler tanımlanmıştır:

* `GIST(geom)` → mekânsal sorgular
* `district` → ilçe bazlı analizler
* `rating`, `user_ratings_total`, `price_level` → filtreleme ve agregasyonlar

Bu indexler özellikle:

* rekabet hesapları
* grid / buffer analizleri

için kritiktir.

---

## 3. Türetilmiş Clean Tablo

### 3.1 `clean.cafe_types`

Cafe’lerin `types` alanı:

* string olarak tutulduğu için
* çoklu değer içerdiği için

analiz edilebilir değildir.

Bu nedenle:

* `string_to_array`
* `unnest`
* lateral join

kullanılarak **1 cafe – N type** yapısı üretilmiştir.

Bu tablo:

* kategori bazlı arz analizlerinde
* opportunity gap hesaplarında

kullanılır.

---

## 4. Mart Layer (Temel Analitik Tablolar)

Bu klasörde **sadece temel ve tekrar kullanılan** mart tabloları yer alır.

### 4.1 `mart.kpi_overview`

Global ölçekte:

* toplam cafe sayısı
* ortalama rating
* yüksek rating’li cafe sayısı
* operasyonel oran

gibi **dashboard üst seviye KPI’larının** kaynağıdır.
 İlçe kırılımı YOKTUR — bilinçli tercihtir.

---

### 4.2 `mart.district_summary`

İlçe bazında:

* cafe_count
* avg_rating
* total_reviews
* avg_price_level

üretilmiştir.

Ayrıca:

* min–max normalization
* arz / talep / kalite bileşenleri

kullanılarak:

* `district_score`
* `opportunity_score`

hesaplanmıştır.

 Bu skorlar **karar değildir**,
sadece **karar modellerine girdi** olarak kullanılır.

---

### 4.3 `mart.cafe_competition_2km`

Her bir cafe için:

* 2 km yarıçap içinde
* kendisi hariç
* kaç rakip cafe olduğu

PostGIS `ST_DWithin` kullanılarak hesaplanmıştır.

Bu tablo:

* mikro rekabet ölçümü
* ilçe bazlı rekabet ortalamaları

için **tek kaynaktır**.

---

### 4.4 `mart.grid_heatmap_500m`

İstanbul genelinde:

* 500m x 500m grid
* cafe yoğunluğu
* review yoğunluğu

hesaplanmıştır.

Bu tablo:

* harita heatmap’leri
* trafik / hareket proxy’leri

için temel yapı taşını oluşturur.

---

## 5. Bilinçli Olarak Bu Aşamada Yapılmayanlar

Bu pipeline’da **özellikle yapılmamıştır**:

* karar skoru üretimi
* model ağırlık optimizasyonu
* dashboard görselleştirmeleri
* trafik / ulaşım entegrasyonu

Bu konular **sonraki klasörlerde** ele alınır.

---

## 6. Çıktı ve Garanti

Bu klasörün sonunda elde edilen veri:

* tip güvenli
* mekânsal olarak doğru
* tekrar üretilebilir
* downstream analizlere hazır

durumdadır.

Bu nedenle:

> Sonraki tüm analizler, bu katmanın **doğru olduğunu varsayar**.

---


