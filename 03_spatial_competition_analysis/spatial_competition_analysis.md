
# 03_spatial_competition_analysis


Bu klasör, İstanbul’daki cafe pazarında **mekânsal arz baskısını (spatial supply pressure)** analiz eder.

Amaç; cafelerin **nerede yoğunlaştığını**, **mikro ölçekte ne kadar rekabet altında olduklarını** ve bu rekabetin **ilçe düzeyinde nasıl bir baskıya dönüştüğünü** ortaya koymaktır.

---

## Kullanılan Tablolar / View’lar

- `mart.map_points`  
- `mart.map_points_lat_lon`  
- `mart.cafe_competition_2km`  
- `mart.v_competition_distribution`  
- `mart.v_avg_competition_by_district`

Bu tabloların tamamı, önceki pipeline katmanında üretilmiş **temiz ve geometriye sahip** veriler üzerinden çalışır.

---

## Görsel 1 — All Cafes: Spatial Distribution (Map)
<img width="904" height="512" alt="Ekran Resmi 2026-02-13 12 52 35" src="https://github.com/user-attachments/assets/01df0aaa-9369-42c8-9213-85657b701f12" />


### Sorduğu soru
> İstanbul’da cafeler mekânsal olarak nerelerde yoğunlaşıyor?

### Neden bu görsel var?
Bu harita, tüm rekabet analizlerinin **referans zeminidir**.

- Henüz rekabet ölçülmez  
- Sadece **yoğunlaşma ve kümelenme** görülür  
- Rekabetin potansiyel olarak **nerelerde sertleşebileceği** sezgisel biçimde anlaşılır  

Bu nedenle bu görsel, sonraki tüm analizlerin “başlangıç fotoğrafı”dır.

### Teknik notlar
- Chart type: `deck.gl Scatterplot`
- Dataset: `mart.map_points_lat_lon`
- Latitude / Longitude: `latitude`, `longitude`
- Opsiyonel renk: `rating_band`

---

## Görsel 2 — 2km Competition Distribution
<img width="790" height="462" alt="Ekran Resmi 2026-02-13 12 53 31" src="https://github.com/user-attachments/assets/79c14664-7a2d-4db8-b090-ed000de00b70" />


### Sorduğu soru
> Cafeler genel olarak düşük mü, orta mı, yoksa aşırı rekabet altında mı?

### Rekabet metriği nasıl tanımlandı?

Her cafe için:

- Merkez: cafe noktası (`geom`)
- Yarıçap: **2000 metre**
- Ölçüm: bu yarıçap içinde bulunan **diğer cafe sayısı**

```text
competitors_within_2km = (2km içindeki tüm cafeler) - 1
````

`-1` çıkarılır çünkü sorgu cafe’nin kendisini de kapsar.

### Neden 2 km?

* İstanbul’da mahalle–semt erişimini temsil eder
* 500 m fazla lokal, 5 km fazla geniş olur
* 2 km, “rekabet hissini” veren orta ölçekli bir varsayımdır

Bu bir **analitik varsayım**dır; karar değil.

### Neden band’leme yapıldı?

Rekabeti okunabilir hale getirmek için bucket’lara ayrıldı:

* `0–49`   → düşük rekabet
* `50–99`  → orta
* `100–149`→ yoğun
* `150–249`→ çok yoğun
* `250+`   → aşırı doygun

Bu sayede:

> “İstanbul’daki cafelerin ne kadarı aşırı rekabet altında?”
> sorusu net biçimde cevaplanabilir.

---

## Görsel 3 — Average 2km Competition by District
<img width="1427" height="307" alt="Ekran Resmi 2026-02-13 12 54 55" src="https://github.com/user-attachments/assets/48d68e0b-2189-4512-98c9-59e86075fe75" />


### Sorduğu soru

> İlçe bazında ortalama bir cafe kaç rakiple karşı karşıya?

### Nasıl hesaplandı?

```text
AVG(competitors_within_2km)  → district level
```

Yani:

* İlçe içindeki tüm cafelerin 2km rekabet değerleri
* İlçe bazında ortalaması alındı

### Analitik yorum

* Ortalama yüksek → **arz baskısı yüksek**
* Ortalama düşük → **rekabet görece zayıf**

Bu tek başına “fırsat” anlamına gelmez.
Talep ve kaliteyle **birleştiğinde** anlam kazanır (sonraki katmanlar).

---

## Metodolojik Sınırlamalar

Bu analiz bilinçli varsayımlar içerir:

* **Edge effect:** İstanbul sınırına yakın cafeler dış rakipleri görmez
* **District label doğruluğu:** Ham verideki ilçe bilgisine bağlıdır
* **Geom eksikleri:** `geom IS NULL` kayıtlar bilinçli olarak dışlanmıştır
* **Ortalama etkisi:** Aşırı değerler ortalamayı etkileyebilir

Bu sınırlamalar, sonraki katmanlarda **çoklu metrik birleşimiyle** dengelenir.

---

## Bu Klasörün Çıktısı

Bu aşamanın sonunda şunlar netleşir:

* Cafe arzının mekânsal dağılımı
* Mikro ölçekte rekabetin şiddeti
* İlçe bazında rekabet baskısı profili

Bu çıktılar, **talep / kalite / fırsat** analizleri için temel girdidir.

---
