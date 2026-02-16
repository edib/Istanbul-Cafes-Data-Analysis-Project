Google Places API'nin **`nearbysearch`** (Yakınındakileri Ara) uç noktasıyla yapılan bir "Hücresel Tarama", belirli bir coğrafi alanı küçük karelere (hücrelere) bölüp her noktanın röntgenini çekmek gibidir.

Bu yöntemle elde edilen veriler, bir işletme veya bölge hakkında şu kritik **iş zekası (business intelligence)** bilgilerini sağlar:

### 1. Mekansal Dağılım ve Kümelenme Verileri

* **İşletme Yoğunluğu:** Belirli bir koordinat etrafındaki kafe, restoran veya mağaza sayısı. Bu, hangi bölgelerin "doygun" olduğunu, hangilerinin "bakir" kaldığını gösterir.
* **Kategori Bazlı Haritalama:** Sadece "kafe" değil, "kitap kafe", "vegan restoran" gibi alt türlerin hangi sokaklarda kümelendiğini görmenizi sağlar.

### 2. Rekabet ve Performans Verileri

* **Puanlama (Rating) Analizi:** Rakiplerin ortalama puanları. Örneğin; "X bölgesindeki kafelerin ortalama puanı 4.2 ama Y bölgesindekiler 3.8" gibi bir kıyaslama sunar.
* **Yorum Sayısı (User Ratings Total):** Bir mekanın ne kadar popüler olduğunun (trafik hacminin) dolaylı bir göstergesidir. Çok yorum alan bölge, yüksek yaya trafiği demektir.

### 3. Ekonomik Segmentasyon (Fiyat Seviyesi)

* **Price Level:** API, mekanları `0` (ücretsiz) ile `4` (çok pahalı) arasında sınıflandırır. Bu veri, o bölgedeki halkın veya ziyaretçilerin **alım gücü** hakkında doğrudan bilgi verir. "Lüks tüketim bu mahallede mi yoğunlaşıyor?" sorusuna yanıt olur.

### 4. Operasyonel Durum Bilgisi

* **Açılış-Kapanış Saatleri:** Bölgedeki gece hayatı veya sabah trafiği potansiyelini anlamak için kullanılır.
* **Hizmet Seçenekleri:** "Paket servis var mı?", "Açık alan var mı?" gibi detaylar, bölgedeki tüketici alışkanlıklarını (örneğin paket servisin çok yaygın olduğu bir bölge) ortaya koyar.

---

### Bu Veri Ne Tür "Business" Raporlarına Dönüşür?

1. **Yer Seçimi Raporu (Site Selection):** Yeni bir şube açılacaksa, en az rakip ve en yüksek potansiyele sahip hücreyi (koordinatı) matematiksel olarak belirler.
2. **Yatırım Fizibilitesi:** Bölgedeki ortalama fiyat seviyesi ve doluluk (yorum sayısı üzerinden) tahmini yapılarak, yatırımın geri dönüş süresi hesaplanır.
3. **Bölgesel Pazarlama Stratejisi:** Eğer belirli bir bölgedeki mekanların puanları düşükse, "buradaki müşteri hizmetten memnun değil, kaliteli bir hizmetle burayı ele geçirebiliriz" stratejisi geliştirilir.

### Teknik Not: Neden "Hücresel" Tarama Yapılır?

Google Places API, tek bir aramada maksimum 60 sonuç döndürür. İstanbul gibi yoğun bir yerde tek bir merkezden arama yaparsanız binlerce mekanı kaçırırsınız. Alanı küçük hücrelere bölüp her hücrenin merkezinde arama yapmak, **hiçbir veriyi kaçırmadan tüm şehri haritalandırmayı** sağlar.