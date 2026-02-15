
## Full Dashboard Interpretation & Insight Report


<img width="1435" height="709" alt="Ekran Resmi 2026-02-15 23 23 28" src="https://github.com/user-attachments/assets/e298b4ef-2db7-424c-81b6-b7577214b36c" />
<img width="1438" height="708" alt="Ekran Resmi 2026-02-15 23 23 51" src="https://github.com/user-attachments/assets/e9aba9cf-e323-4f09-9cd6-d64c528f7860" />
<img width="1440" height="786" alt="Ekran Resmi 2026-02-15 23 25 55" src="https://github.com/user-attachments/assets/f36bfc1e-4cbe-44e9-816f-b17e22873df4" />

Bu doküman, İstanbul cafe analiz dashboard’unda yer alan **tüm tabloları ve görselleri** kapsar.
Amaç, her görselin **neden üretildiğini**, **hangi analitik boşluğu doldurduğunu** ve
**hangi yanlış kararları engellemek için var olduğunu** açıklamaktır.

Bu dashboard bir “gösterim aracı” değil,
**çok adımlı bir karar filtresidir**.

---

## 1. Market Overview KPI’ları
<img width="908" height="84" alt="Ekran Resmi 2026-02-15 23 26 56" src="https://github.com/user-attachments/assets/e0024163-d929-414c-864c-14c3f5762ec5" />

**Tablolar / Kartlar**

* Total Cafes
* Avg Rating
* High Rating Cafes
* Avg Reviews
* Operational Businesses


### İçgörü

* Pazar büyük → rekabet kaçınılmaz
* Ortalama rating yüksek → rating ayırt edici değil
* Operasyonel oran yüksek → veri güvenilir


## 2. Total Number of Cafes by District
<img width="721" height="370" alt="Ekran Resmi 2026-02-15 23 27 50" src="https://github.com/user-attachments/assets/aa4f937a-17fe-43d9-92e0-9aed7f142f99" />

### Ne ölçüyor?

İlçe bazında **toplam cafe arzı**
Bu tablo **mekânsal eşitsizliği** göstermek için var.

### İçgörü

* Arz homojen değil
* Bazı ilçeler yapısal olarak doygun
* Bazı ilçelerde “az cafe” durumu **talep eksikliği** göstergesi olabilir

### Yanlış okuma riski

> “Cafe az → fırsat”. Bu tablo cafe açmak için **tek başına yorumlanamaz**.

---

## 3. Rating Distribution (Fine-Grain)
<img width="514" height="345" alt="Ekran Resmi 2026-02-15 23 28 40" src="https://github.com/user-attachments/assets/279d3df4-f8a6-49d2-8187-95f03c533365" />

### Ne ölçüyor?

Rating’lerin detaylı bantlara ayrılmış dağılımını ölçmek için kullanıldı.

### İçgörü

* Düşük rating’li cafe çok az
* Sistem “kötüleri” zaten eliyor
* 4.0–4.8 bandı aşırı kalabalık

### Sonuç

> Rating **filtre değil**, sadece giriş koşulu.

---

## 4. All Cafes – Spatial Distribution
<img width="1168" height="487" alt="Ekran Resmi 2026-02-15 23 30 44" src="https://github.com/user-attachments/assets/a3928c9a-d38a-4c2c-b29b-d73c0dab8d23" />

### Ne ölçüyor?

Cafelerin gerçek coğrafi konumları
Arzın **harita üzerindeki kümelenmesini** görmek için oluşturuldu.

### İçgörü

* Sahil + merkez aksları aşırı yoğun
* İç bölgelerde kopukluk var
* Bu görsel, trafik analizinin ön koşuludur

---

## 5. 2km Competition Distribution
<img width="789" height="714" alt="Ekran Resmi 2026-02-15 23 31 43" src="https://github.com/user-attachments/assets/d0f0ac15-d776-463c-9808-b9988b21a8c0" />

### Ne ölçüyor?

Her cafe için 2km yarıçapta rakip sayısı
Rekabetin **sayısal dağılımını** görmek için kullnaıldı.

### İçgörü

* Çoğunluk yüksek rekabet bandında
* Düşük rekabet istisna, norm değil

### Analitik sonuç

> Rekabet kaçınılmaz → önemli olan **hangi rekabet seviyesiyle bir cafe işletileceği kararı**

---

## 6. Average 2km Competition by District
<img width="1432" height="316" alt="Ekran Resmi 2026-02-15 23 33 10" src="https://github.com/user-attachments/assets/d2ee4a44-6bc5-4684-bb2f-94d9dc6af523" />

### Ne ölçüyor?

İlçelerde **ortalama yapısal rekabet**

### Neden var?

Tek tek cafe yerine **ilçe DNA’sını** görmek için kullanıldı.

### İçgörü

* Bazı ilçeler yapısal olarak baskılı
* Bu ilçelerde başarı “ortalama işletme” ile mümkün değil

---

## 7.Pedestrian Activity Proxy (Traffic Heatmap)
<img width="1043" height="729" alt="Ekran Resmi 2026-02-15 23 35 48" src="https://github.com/user-attachments/assets/7de5e2aa-465d-4ac9-a116-898d097dfcfd" />

### Ne ölçüyor?

Gerçek trafik verisi yerine:

* cafe yoğunluğu
* review hacmi
* mekânsal kümelenme

üzerinden türetilmiş **yaya aktivite proxy’si**

### Neden var?

“Cafe var” ≠ “insan geçiyor”

### İçgörü

* Yüksek cafe yoğunluğu her zaman yüksek trafik değil
* Bazı yüksek trafik alanları görece düşük rekabet içeriyor

> Bu dashboard’un **ilk gerçek fırsat filtresi** burasıdır.

---

## 8. Relationship Between Cafe Ratings and Review Volume (Scatter)
<img width="681" height="711" alt="Ekran Resmi 2026-02-15 23 36 43" src="https://github.com/user-attachments/assets/2c2ffc0f-4fcd-4fe1-bebf-9cfa6b571dd9" />

### Ne ölçüyor?

* X: review hacmi (log)
* Y: rating
* Renk: rating bandı

### Neden var?

Rating’in **görünürlükten bağımsız olmadığını** göstermek için.

### İçgörü

* Düşük review + yüksek rating = kırılgan
* Yüksek review + orta rating = güçlü

### Analitik sonuç

> Bu grafik, **Bayesian rating ihtiyacını** gerekçelendirir.

---

## 9. Top 50 Cafes (Bayesian & Weighted Score)
<img width="685" height="453" alt="Ekran Resmi 2026-02-15 23 37 59" src="https://github.com/user-attachments/assets/d984dd85-33de-4d99-b8bb-c0bb6d4d7206" />

### Ne ölçüyor?

* Bayesian rating
* Ağırlıklı skor
* İlçe bilgisi

### Neden var?

“Kim kazanıyor?” sorusuna cevap vermek için.

### İçgörü

* En iyi cafeler sadece yüksek rating’li değil
* Süreklilik ve görünürlük kritik

---

## 10. Price–Quality Value Index by Price Segment
<img width="934" height="502" alt="Ekran Resmi 2026-02-15 23 38 50" src="https://github.com/user-attachments/assets/5cc442b7-f330-4098-a2e8-7dad9682cb4e" />

### Ne ölçüyor?

Fiyat segmentine göre **algılanan değer**

### Neden var?

Ucuz = kötü
Pahalı = iyi
varsayımını test etmek için.

### İçgörü

* Orta segment çoğu zaman en dengeli
* Pahalı segmentte değer kaybı görülebiliyor

---

## 11.Top Districts by Opportunity Score
<img width="833" height="731" alt="Ekran Resmi 2026-02-15 23 39 44" src="https://github.com/user-attachments/assets/6ee5acfd-32de-4a63-9418-d9c70daf7de6" />

### Ne ölçüyor?

İlçe bazında **fırsat skoru**

### Neden var?

Ham metrikleri **tek sayıya indirgemek** için.

### İçgörü

* Bazı ilçeler rekabetine rağmen öne çıkıyor
* Bu skor “neden” sorusu için diğer tablolara geri götürür

---

## 12. Opportunity vs Competition Decision Map
<img width="597" height="531" alt="Ekran Resmi 2026-02-15 23 40 26" src="https://github.com/user-attachments/assets/e37419b3-48de-4bff-9950-fe1ee0f85d05" />

### Ne ölçüyor?

* X: ortalama rekabet
* Y: fırsat skoru

### Neden var?

Stratejik konumlama için.

### İçgörü

* En değerli alan: **orta rekabet + yüksek fırsat**
* Düşük rekabet + düşük fırsat = tuzak

---

## 13. District Category Gap Heatmap
<img width="601" height="564" alt="Ekran Resmi 2026-02-15 23 41 00" src="https://github.com/user-attachments/assets/33a2c194-8ff6-4824-96cf-0e7f96ebe257" />

### Ne ölçüyor?

İlçe × işletme türü bazında **arz–talep boşluğu**

### Neden var?

“Cafe açalım mı?” değil

> ekstra hangi ürün sunulabilir sorusu için.





## 14. Final Decision Matrix — Sonuç
<img width="622" height="265" alt="Ekran Resmi 2026-02-13 14 55 58" src="https://github.com/user-attachments/assets/d921638e-eaf1-480a-8f53-a0669c8d6fc4" />

### Ne Yapıyor?

Tüm metrikleri normalize ederek:

* decision_score
* decision_label ürettim.

### Etiket Mantığı

* STRONG OPENING CANDIDATE
* MEDIUM POTENTIAL
* LOW PRIORITY

### En Önemli Not

Bu tablo:

* “Kesin aç” demez
* “Saha çalışmasına nereden başla” der

---

##   Dashboard Main Topics

1. İstanbul’da cafe açmak **lokasyon problemidir**
2. Rating tek başına **hiçbir şey anlatmaz**
3. Rekabet korkulacak değil, **yanlış yerde tehlikelidir**
4. Trafik + rekabet + kalite **birlikte okunmalıdır**
5. Bu dashboard **nihai karar değil**, akıllı eleme aracıdır

---
