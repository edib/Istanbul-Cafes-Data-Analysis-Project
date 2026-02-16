
# Spatial Competition Analysis

Bu klasörde, İstanbul’daki cafe pazarında **mekânsal arz ve rekabet yapısını**
hem **görsel (dashboard)** hem de **hesaplama (SQL)** seviyesinde inceliyorum.

Amaç:

- Cafelerin **nerelerde yoğunlaştığını**
- Her bir cafe’nin **yakın çevresinde ne kadar rekabet altında olduğunu**
- Bu mikro rekabetin **ilçe bazında nasıl bir baskıya dönüştüğünü**

net ve ölçülebilir şekilde ortaya koymaktır.

Bu aşamada:
- talep ölçümü yapılmaz,
- trafik veya hareket verisi kullanılmaz,
- karar veya öneri üretilmez.

Sadece **arz + konum + rekabet** ele alınır.

---

## Kullanılan Tablolar / View’lar

Bu klasördeki tüm görseller ve hesaplamalar,
aşağıdaki mevcut tablolar üzerinden üretilmiştir:

- `mart.map_points`
- `mart.map_points_lat_lon`
- `mart.cafe_competition_2km`
- `mart.v_competition_distribution`
- `mart.v_avg_competition_by_district`

Bu tabloların tamamı,
önceki veri hazırlama katmanlarında
geometri bilgisi üretilmiş ve temizlenmiş verilerdir.

---

## Görsel 1 — All Cafes: Spatial Distribution (Map)

<img width="904" height="512" alt="All Cafes Spatial Distribution" src="https://github.com/user-attachments/assets/01df0aaa-9369-42c8-9213-85657b701f12" />

### Ne anlatıyor? 

Bu harita, İstanbul’daki tüm cafelerin
**coğrafi dağılımını ve kümelenme eğilimlerini** gösterir.

Henüz rekabet ölçülmez.
Ama cafelerin hangi bölgelerde yoğunlaştığı
ilk bakışta anlaşılır.

Bu nedenle bu görsel,
sonraki rekabet analizlerinin **referans zemini** olarak kullanılır.

---

### Teknik olarak ne yapıldı?

Bu görselde **istatistiksel bir hesaplama yoktur**.

SQL tarafında yapılan işlem,
mevcut geometri bilgisinden
harita için gerekli koordinatların çıkarılmasıdır:

```

latitude  = ST_Y(geom)
longitude = ST_X(geom)

```

Bu işlem:
- yeni bir metrik üretmez,
- veri dağılımını değiştirmez,
- sadece görselleştirme için format dönüşümüdür.

---

## Görsel 2 — 2km Competition Distribution

<img width="790" height="462" alt="2km Competition Distribution" src="https://github.com/user-attachments/assets/79c14664-7a2d-4db8-b090-ed000de00b70" />

### Ne anlatıyor? 

Bu grafik, cafelerin
**genel olarak ne seviyede rekabet altında olduğunu**
dağılım olarak gösterir.

Yani soru şudur:

> “İstanbul’daki cafelerin çoğu düşük mü,
> orta mı, yoksa aşırı rekabet altında mı?”

---

### Rekabet metriği nasıl hesaplandı?

Her cafe için aşağıdaki metrik kullanılmıştır:

```

competitors_within_2km

```

Bu metrik, bir cafe’nin
**2000 metre yarıçapı içinde bulunan diğer cafe sayısını**
ifade eder.

---

### Kullanılan formül

```

# competitors_within_2km

COUNT(cafes within 2000 meters) - 1

```

---

### Formülün mantığı

1. Cafe merkez nokta olarak alınır.
2. `ST_DWithin(geom::geography, 2000)` ile
   2000 metre içindeki tüm cafeler bulunur.
3. Cafe’nin kendisi de bu kapsama girdiği için
   sonuçtan **1 çıkarılır**.

Bu çıkarım yapılmazsa,
her cafe kendi kendisinin rakibi olarak sayılmış olur.

---

### Neden `geography` ve neden 2 km?

- `geography` tipi,
  mesafenin **metre cinsinden doğru** hesaplanmasını sağlar.
- 2 km,
  İstanbul’da mahalle / semt ölçeğinde
  rekabet hissini temsil eden
  orta ölçekli bir varsayımdır.

Bu seçim:
- analitik bir varsayımdır,
- karar veya eşik değildir.

---

### Band’leme neden var?

Rekabet değerleri,
okunabilirliği artırmak için
aşağıdaki aralıklara ayrılarak gösterilmiştir:

- `0–49`
- `50–99`
- `100–149`
- `150–249`
- `250+`

Bu band’leme:
- skor veya ağırlık içermez,
- yalnızca dağılımı daha net görmeyi sağlar.

---

## Görsel 3 — Average 2km Competition by District

<img width="1427" height="307" alt="Average Competition by District" src="https://github.com/user-attachments/assets/48d68e0b-2189-4512-98c9-59e86075fe75" />

### Ne anlatıyor? 

Bu görsel, her ilçede
**ortalama bir cafe’nin kaç rakiple karşı karşıya olduğunu**
gösterir.

Yani mikro ölçekte hesaplanan rekabet,
ilçe seviyesinde özetlenmiştir.

---

### Teknik olarak nasıl hesaplandı?

Kullanılan formül:

```

# avg_competition_2km

AVG(competitors_within_2km)

```

---

### Formülün mantığı

1. İlçe içindeki tüm cafelerin
   `competitors_within_2km` değerleri alınır.
2. Bu değerlerin ilçe bazında ortalaması hesaplanır.

Bu metrik:
- ilçe genelinde **tipik bir cafe’nin**
  maruz kaldığı rekabet seviyesini temsil eder.

---

### Nasıl yorumlanır?

- Ortalama yüksek → **arz baskısı yüksek**
- Ortalama düşük → **rekabet görece daha zayıf**

Bu metrik tek başına “fırsat” anlamına gelmez.
Talep ve kalite analizleriyle birlikte
değerlendirildiğinde anlam kazanır.

---

## Metodolojik Sınırlamalar

Bu analiz bazı bilinçli varsayımlar içerir:

- İstanbul sınırına yakın cafeler,
  sınır dışındaki rakipleri göremez.
- İlçe bilgisi,
  ham verideki `district` alanına bağlıdır.
- `geom IS NULL` olan kayıtlar analize dahil edilmemiştir.
- Ortalama değerler,
  uç gözlemlerden etkilenebilir.

Bu sınırlamalar,
sonraki katmanlarda
farklı metriklerin birlikte kullanılmasıyla dengelenir.

---

## Çıktı

Bu klasörün sonunda:

- cafe arzının mekânsal dağılımı,
- mikro ölçekte rekabet şiddeti,
- ilçe bazında rekabet baskısı

netleştirilmiştir.

Bu çıktılar,
talep ve fırsat analizleri için
temel girdi olarak kullanılır.
```

---

