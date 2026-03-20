# Curatorian Whitepaper
## Platform Komunitas untuk Setiap Kurator di Indonesia

**Versi:** 1.0
**Diterbitkan:** Maret 2026
**Penulis:** Chrisna Adhi
**Kontak:** hello@curatorian.id
**Website:** curatorian.id

---

> *"Sebuah koleksi yang tidak terkatalogisasi sama saja dengan tidak ada."*
>
> — Prinsip dasar ilmu perpustakaan

---

## DAFTAR ISI

1. [Ringkasan Eksekutif](#1-ringkasan-eksekutif)
2. [Masalah yang Kami Lihat](#2-masalah-yang-kami-lihat)
   - 2.1 [Lanskap GLAM di Indonesia](#21-lanskap-glam-di-indonesia)
   - 2.2 [Permasalahan yang Sudah Terdokumentasi](#22-permasalahan-yang-sudah-terdokumentasi)
   - 2.3 [Mengapa Solusi yang Ada Belum Cukup](#23-mengapa-solusi-yang-ada-belum-cukup)
3. [Solusinya: Curatorian](#3-solusinya-curatorian)
   - 3.1 [Apa Itu Curatorian](#31-apa-itu-curatorian)
   - 3.2 [Dua Fungsi Sekaligus](#32-dua-fungsi-sekaligus)
   - 3.3 [Siapa yang Membangun Ini dan Mengapa Itu Penting](#33-siapa-yang-membangun-ini-dan-mengapa-itu-penting)
4. [Siapa yang Kami Layani](#4-siapa-yang-kami-layani)
   - 4.1 [Kurator Perorangan](#41-kurator-perorangan)
   - 4.2 [Institusi Komunitas dan Nirlaba](#42-institusi-komunitas-dan-nirlaba)
   - 4.3 [Institusi Komersial](#43-institusi-komersial)
5. [Fitur Platform](#5-fitur-platform)
   - 5.1 [Manajemen Koleksi](#51-manajemen-koleksi)
   - 5.2 [Komunitas](#52-komunitas)
   - 5.3 [Platform Acara dan Webinar](#53-platform-acara-dan-webinar)
   - 5.4 [Papan Lowongan Kerja](#54-papan-lowongan-kerja)
   - 5.5 [Marketplace Tenaga Ahli dan Freelance](#55-marketplace-tenaga-ahli-dan-freelance)
   - 5.6 [Jaringan Bibliografi Bersama](#56-jaringan-bibliografi-bersama)
   - 5.7 [Pembuat Pameran Digital](#57-pembuat-pameran-digital)
   - 5.8 [Penggalangan Dana Institusi](#58-penggalangan-dana-institusi)
   - 5.9 [Manajer Program Membaca](#59-manajer-program-membaca)
   - 5.10 [Bursa Koleksi](#510-bursa-koleksi)
6. [Arsitektur Teknis](#6-arsitektur-teknis)
   - 6.1 [Prinsip Desain Sistem](#61-prinsip-desain-sistem)
   - 6.2 [Arsitektur Tiga Lapisan](#62-arsitektur-tiga-lapisan)
   - 6.3 [Strategi Database](#63-strategi-database)
   - 6.4 [Autentikasi dan Keamanan](#64-autentikasi-dan-keamanan)
   - 6.5 [Integritas Platform dan Verifikasi](#65-integritas-platform-dan-verifikasi)
   - 6.6 [Strategi Data Bibliografi](#66-strategi-data-bibliografi)
   - 6.7 [Tumpukan Teknologi](#67-tumpukan-teknologi)
7. [Filosofi Open Source](#7-filosofi-open-source)
   - 7.1 [Model Open Core](#71-model-open-core)
   - 7.2 [Apa yang Terbuka dan Apa yang Tidak](#72-apa-yang-terbuka-dan-apa-yang-tidak)
   - 7.3 [Mengapa Model Ini Cocok untuk GLAM Indonesia](#73-mengapa-model-ini-cocok-untuk-glam-indonesia)
8. [Model Bisnis dan Keberlanjutan](#8-model-bisnis-dan-keberlanjutan)
   - 8.1 [Filosofi](#81-filosofi)
   - 8.2 [Akses Penuh untuk Semua](#82-akses-penuh-untuk-semua)
   - 8.3 [Keanggotaan Penyokong](#83-keanggotaan-penyokong)
   - 8.4 [Donasi dan Apresiasi](#84-donasi-dan-apresiasi)
   - 8.5 [Jalan Menuju Keberlanjutan](#85-jalan-menuju-keberlanjutan)
9. [Lanskap Kompetitif](#9-lanskap-kompetitif)
10. [Peta Jalan Pengembangan](#10-peta-jalan-pengembangan)
    - 10.1 [Fase 1 — Fondasi](#101-fase-1--fondasi)
    - 10.2 [Fase 2 — Peluncuran Komunitas](#102-fase-2--peluncuran-komunitas)
    - 10.3 [Fase 3 — Ekspansi Platform](#103-fase-3--ekspansi-platform)
    - 10.4 [Fase 4 — Marketplace dan Pendalaman](#104-fase-4--marketplace-dan-pendalaman)
11. [Bergabunglah Bersama Kami](#11-bergabunglah-bersama-kami)

---

## 1. Ringkasan Eksekutif

Di seluruh penjuru Indonesia, ada puluhan ribu koleksi yang dijaga dengan penuh rasa cinta — taman bacaan masyarakat, perpustakaan sekolah, museum lokal, arsip masjid, pojok baca perusahaan, sampai koleksi buku pribadi yang dikumpulkan selama bertahun-tahun oleh orang-orang yang benar-benar peduli pada pengetahuan dan warisan budaya. Namun hampir semua koleksi itu hanya tercatat di buku tulis, register tangan, atau paling jauh — di kepala orang yang mengelolanya. Tidak terlihat oleh publik. Tidak bisa diakses oleh peneliti. Dan hampir mustahil dikelola secara sistematis oleh mereka yang merawatnya.

Alat yang tersedia untuk menjawab masalah ini, jujur saja, belum memadai. Software open source yang harus dipasang sendiri membutuhkan kemampuan teknis yang kebanyakan pengelola koleksi tidak miliki. Produk SaaS dari luar negeri mahal, tidak sesuai konteks Indonesia, dan tidak dirancang untuk jenis koleksi yang ada di sini. Spreadsheet tidak skalabel dan tidak bisa dibagikan dengan baik. Tidak ada satu pun produk yang dirancang untuk melayani seluruh spektrum kurator Indonesia — dari seseorang yang punya dua ratus buku pribadi sampai BUMN dengan kewajiban perpustakaan CSR.

**Curatorian** hadir untuk mengubah itu.

Siapa saja di Indonesia — kurator individual, pengelola Taman Bacaan Masyarakat (TBM), arsiparis museum, atau pustakawan perusahaan — bisa mendaftar di `curatorian.id`, membuat ruang koleksi mereka sendiri, dan punya katalog digital yang bisa diakses publik dalam tiga puluh menit. Tidak perlu server. Tidak perlu instalasi. Tidak perlu keahlian teknis apa pun. Dan gratis, selamanya, untuk institusi nirlaba dan komunitas.

Lebih dari sekadar pengelolaan koleksi, Curatorian adalah rumah profesional bagi para praktisi GLAM (Galleries, Libraries, Archives, Museums) Indonesia: sebuah komunitas dengan blog, sistem follow, dan pesan langsung; tempat untuk menyelenggarakan atau menghadiri acara dan webinar profesional; papan lowongan kerja di sektor GLAM; dan pada saatnya nanti, sebuah marketplace yang menghubungkan institusi yang butuh bantuan dengan profesional yang bisa membantu.

Platform ini dibangun di atas tiga lapisan software — sebagian open source, sebagian proprietary — oleh seorang pustakawan yang juga bisa menulis kode. Kombinasi yang jarang ada, dan itulah yang membuat setiap keputusan fitur berangkat dari pemahaman domain yang nyata, bukan dari kecanggihan teknis semata.

Model bisnisnya mengutamakan komunitas: gratis selamanya untuk perorangan dan nirlaba, berlangganan untuk institusi komersial, dan dijaga keberlanjutannya dalam jangka panjang melalui biaya platform dari acara, lowongan kerja, dan marketplace freelance. Curatorian tidak perlu memilih antara bermanfaat bagi komunitas atau layak secara finansial — model ini dirancang agar keduanya saling menghidupi.

Whitepaper ini menjelaskan masalahnya secara penuh, solusinya secara detail, arsitektur teknisnya, strategi open source-nya, model bisnisnya, dan peta jalan bagaimana platform ini akan tumbuh.

---

## 2. Masalah yang Kami Lihat

### 2.1 Lanskap GLAM di Indonesia

GLAM adalah singkatan dari *Galleries, Libraries, Archives, and Museums* — istilah yang digunakan untuk menyebut institusi dan individu yang bertanggung jawab atas pelestarian, pengorganisasian, dan akses terhadap koleksi budaya, sejarah, dan ilmiah. Di Indonesia, sektor ini sangat luas, tersebar merata ke seluruh wilayah, dan sangat kurang mendapat perhatian yang semestinya.

Bayangkan apa yang ada di seluruh nusantara:

- **Taman Bacaan Masyarakat (TBM):** Lebih dari 13.000 TBM terdaftar, dengan jumlah yang tidak terdaftar diperkirakan sama banyaknya. Banyak yang dioperasikan dari rumah, garasi, atau ruang sewa kecil. Mereka menjadi infrastruktur membaca utama bagi komunitas yang tidak punya akses ke perpustakaan formal.

- **Perpustakaan sekolah:** Permendikbud mewajibkan setiap sekolah terakreditasi untuk memiliki perpustakaan. Puluhan ribu perpustakaan sekolah ada sebagai hasilnya — sebagian besar kekurangan staf, kekurangan dana, dan dikelola oleh guru yang ditugaskan sekaligus, bukan pustakawan terlatih.

- **Museum dan arsip lokal:** Museum tingkat kabupaten, arsip budaya yang dikelola pemerintah daerah, koleksi sejarah komunitas, dan arsip spesialis (batik, wayang, naskah lokal) tersebar di setiap provinsi — hampir semuanya minim digitasi dan tidak punya kehadiran online.

- **Perpustakaan lembaga keagamaan:** Perpustakaan masjid, koleksi pesantren, dan program membaca berbasis keagamaan menyimpan koleksi teks keagamaan dan umum yang signifikan — seringkali tanpa katalog sama sekali.

- **Perpustakaan perusahaan dan CSR:** Regulasi Indonesia mendorong — dan untuk BUMN, secara efektif mewajibkan — program tanggung jawab sosial perusahaan yang mencakup fasilitas perpustakaan komunitas. Mulai dari satu rak buku di ruang istirahat sampai ruang baca khusus dengan ribuan judul.

- **Kurator individual:** Peneliti, akademisi, profesional, penggemar buku, dan pecinta budaya yang memiliki koleksi pribadi yang bermakna, terkurasi, dan saat ini tidak terlihat oleh siapa pun di luar lingkaran terdekat mereka.

Di semua konteks ini, polanya sama: koleksi ada, orang merawatnya dengan sepenuh hati, dan hampir tidak ada yang benar-benar terkatalogisasi, bisa diakses, atau terhubung satu sama lain.

### 2.2 Permasalahan yang Sudah Terdokumentasi

Permasalahan berikut terdokumentasi dari pengalaman langsung dan dari riset dalam komunitas praktisi GLAM Indonesia.

#### Kesenjangan Digital dan Infrastruktur

**Tidak ada database yang layak, masih bergantung pada catatan manual.**
Sebagian besar institusi GLAM Indonesia — terutama TBM, perpustakaan sekolah kecil, dan arsip lokal — masih mengandalkan catatan manual: buku besar tulisan tangan, kartu indeks, atau paling jauh sebuah spreadsheet yang tidak terstruktur. Mencari item tertentu berarti harus tahu kira-kira di mana letaknya. Inventarisasi hanya perkiraan. Pencarian tidak mungkin dilakukan. Koleksi yang dikelola seperti ini, dalam praktiknya, adalah koleksi yang tertutup.

**Infrastruktur teknologi yang tidak memadai.**
Anggaran yang terbatas untuk perangkat keras, perangkat lunak, dan koneksi internet menghalangi sebagian besar institusi untuk mengejar solusi digital — bahkan ketika mereka memahami kebutuhannya. Seorang pengelola TBM mungkin hanya punya smartphone dan paket data bersama. Meminta mereka mengkonfigurasi server PostgreSQL dan menginstal aplikasi web bukanlah harapan yang realistis.

**"Arsip mati" — koleksi yang tidak bisa diakses peneliti maupun publik.**
Koleksi yang tidak bisa ditemukan sama saja tidak ada bagi peneliti, mahasiswa, atau masyarakat umum yang tidak tahu harus mencarinya di mana. Dampaknya lebih dari sekadar masalah lokal: para peneliti yang mengkaji subjek budaya dan sejarah Indonesia pernah, dalam kasus yang terdokumentasi, pergi ke arsip-arsip di Belanda untuk mengakses materi Indonesia yang sebenarnya ada di Indonesia — tapi tidak bisa ditemukan.

**Koleksi yang tidak terdokumentasi semakin sulit dikelola seiring waktu.**
Setiap item baru yang masuk membuat koleksi yang tidak tercatat semakin susah dikelola. Pengelola baru yang mewarisi koleksi tanpa catatan harus mulai katalogisasi dari nol. Item hilang. Asal-usul benda terlupakan. Memori institusional sebuah koleksi sangat rapuh ketika hanya ada di kepala seseorang.

#### Kesenjangan Sumber Daya Manusia dan Kompetensi

**Kemampuan staf yang terbatas dalam pengelolaan informasi modern.**
Arsiparis, pustakawan, dan pengelola koleksi di lingkungan komunitas sering tidak punya pelatihan formal dalam alat digital, standar metadata, dan praktik preservasi yang sistematis. Banyak "pustakawan" perpustakaan sekolah adalah guru yang ditugaskan secara sambilan. Banyak pengelola TBM adalah anggota komunitas yang bersemangat, bukan profesional informasi. Alat yang tersedia untuk mereka harus lebih sederhana dari kemampuan yang mereka miliki saat ini.

**Kebingungan hak cipta yang meluas.**
Kesalahpahaman yang tersebar luas tentang hukum hak cipta dan lisensi terbuka membuat banyak institusi enggan membagikan koleksi mereka secara online sama sekali. Kekhawatiran itu bisa dimengerti, tapi kontraproduktif: institusi yang sebenarnya bisa membuat koleksinya bisa ditemukan memilih untuk tidak melakukannya karena tidak yakin apa yang boleh mereka lakukan secara hukum. Panduan praktis dan mudah dipahami tentang hak atas koleksi hampir tidak ada dalam praktik komunitas.

**Rendahnya kesadaran publik tentang nilai warisan budaya.**
Ketika masyarakat umum tidak memahami pentingnya pelestarian koleksi, sulit untuk membenarkan pendanaan, menarik sukarelawan, atau membangun dukungan donatur. Seorang pengelola TBM atau arsiparis lokal yang bekerja tanpa pengakuan publik atau dukungan institusional sedang berjuang menanjak — dan alat yang lebih baik saja tidak cukup untuk menyelesaikan ini, tapi visibilitas komunitas adalah bagian penting dari solusinya.

#### Hambatan Administratif dan Institusional

**Kekurangan dana yang kronis.**
Sektor komunitas GLAM Indonesia beroperasi dengan sumber daya yang sangat terbatas. Alat yang tersedia untuk institusi-institusi ini harus gratis atau sangat murah. Model berlangganan yang harganya disesuaikan dengan organisasi nirlaba Barat sama sekali tidak terjangkau bagi sebagian besar perpustakaan komunitas Indonesia.

**Silo informasi.**
Data koleksi hampir selalu tetap tersimpan di dalam tembok institusi. Tidak ada mekanisme yang mudah untuk berbagi catatan katalog antar institusi, membangun sumber daya bibliografi bersama, atau menemukan apa yang ada di koleksi terdekat. Setiap institusi secara mandiri mengkatalogisasi judul-judul Indonesia yang sama-sama populer — ratusan kali, di seluruh negeri. Redundansi ini adalah pemborosan yang sebuah platform terkoneksi bisa hilangkan.

**Ketakutan terhadap keterbukaan digital.**
Beberapa institusi enggan menaruh koleksi mereka secara online karena salah sangka bahwa akses online akan mengurangi pengunjung fisik. Ketakutan ini secara konsisten terbantahkan oleh penelitian di banyak negara dan jenis institusi: bisa ditemukan secara online justru mendorong keterlibatan fisik, bukan menjauhkannya. Mengatasi ketakutan ini membutuhkan edukasi sekaligus alat yang membuat kontrol privasi mudah dipahami dan diatur.

**Isolasi para praktisi.**
Seorang pengelola TBM di Bandung dan seorang pustakawan sekolah di Manado menghadapi tantangan yang hampir identik, tapi tidak punya infrastruktur bersama untuk belajar satu sama lain, bertanya, atau sekadar merasa tidak sendirian. Komunitas perpustakaan dan GLAM Indonesia punya organisasi profesional (IPI, ATPUSI) dan grup WhatsApp yang aktif, tapi belum punya rumah digital bersama yang menghubungkan pekerjaan sehari-hari mereka dengan pengembangan profesional dan koleksi mereka satu sama lain.

### 2.3 Mengapa Solusi yang Ada Belum Cukup

**SLiMS (Senayan Library Management System)** adalah sistem manajemen perpustakaan yang paling banyak digunakan di Indonesia. Gratis, open source, dan fungsional. Tapi SLiMS harus dipasang sendiri — tidak ada versi cloud. Menginstalnya membutuhkan konfigurasi web server, database MySQL, dan PHP. Merawatnya butuh perhatian teknis yang berkelanjutan. Bagi pengelola TBM atau pustakawan sekolah tanpa dukungan IT, ini adalah hambatan yang tidak bisa diatasi. SLiMS juga tidak punya lapisan komunitas, tidak ada mekanisme penemuan publik, dan tidak ada jalan untuk menjadi sesuatu selain sistem katalog.

**Produk SaaS dari luar negeri** seperti LibraryThing, TinyCat, dan Koha Cloud dirancang dengan baik dan kaya fitur. Tapi harganya untuk pasar Barat, antarmukanya dalam bahasa Inggris, dirancang untuk jenis koleksi dan konvensi katalogisasi Barat, dan dibangun tanpa konteks Indonesia. Tidak menerima pembayaran QRIS atau transfer bank. Tidak punya komunitas untuk praktisi Indonesia. Dan mereka tidak akan membangunnya untuk pasar yang tidak mereka prioritaskan.

**Spreadsheet dan grup WhatsApp** adalah incumben sesungguhnya. Sebagian besar koleksi kecil dikelola melalui kombinasi Google Sheets, kertas, dan komunikasi informal. "Sistem" ini gratis, familiar, dan tidak memerlukan kurva pembelajaran. Tapi juga tidak bisa dicari dengan efisien, tidak bisa dibagikan secara terstruktur, rentan rusak, dan tidak bisa tumbuh bersama koleksinya. Biaya peralihan dari spreadsheet ke sistem formal terasa tinggi — itulah mengapa onboarding Curatorian dirancang untuk menghasilkan halaman katalog publik yang berfungsi dalam tiga puluh menit dan menyediakan import CSV untuk memigrasikan data spreadsheet yang sudah ada dengan sesedikit mungkin gesekan.

**Tidak ada yang melayani seluruh spektrum.** Celah terdalam dalam lanskap yang ada adalah tidak adanya alat yang dirancang untuk keragaman kurator yang ada di Indonesia. Seorang profesor pensiun dengan 800 buku pribadi punya kebutuhan yang sangat berbeda dari perpustakaan CSR perusahaan — tapi keduanya butuh solusi katalog yang ter-host yang tidak memerlukan setup teknis. Tidak ada produk yang ada saat ini yang memikirkan spektrum ini secara bersamaan.

---

## 3. Solusinya: Curatorian

### 3.1 Apa Itu Curatorian

**Curatorian adalah platform berbasis komunitas yang di-hosting secara penuh, di mana setiap kurator di Indonesia — individu dengan dua ratus buku, pengelola Taman Bacaan Masyarakat, arsiparis museum, atau perusahaan dengan perpustakaan CSR — bisa mendigitalisasi koleksi mereka, mengelolanya secara profesional, terhubung dengan kurator lain, dan mengakses alat yang sebelumnya hanya tersedia untuk institusi dengan anggaran besar.**

Platform ini bisa diakses di `curatorian.id`. Pengguna mendaftar, membuat node (ruang koleksi mereka), dan mulai mengkatalogisasi. Tidak ada perangkat lunak yang perlu dipasang, tidak ada server yang perlu diurus, tidak ada database yang perlu dikonfigurasi. Berjalan di perangkat apa pun yang punya browser web — termasuk smartphone dengan data seluler.

Untuk institusi nirlaba dan komunitas, platform inti ini gratis, selamanya. Bukan masa percobaan, bukan tier yang sengaja dibatasi, bukan taktik pemasaran. Ini adalah keputusan desain yang disengaja, berakar pada ekonomi dan nilai-nilai komunitas GLAM Indonesia.

### 3.2 Dua Fungsi Sekaligus

Curatorian dengan sengaja menjadi dua hal sekaligus. Sifat ganda inilah yang menjadi keunggulan kompetitif utamanya.

**Fungsi Pertama — Alat Manajemen Koleksi.**
Sistem katalogisasi, sirkulasi, dan manajemen koleksi yang lengkap dan profesional. Masukkan item koleksi, lacak siapa yang meminjam apa, kelola anggota perpustakaan, buat laporan untuk donatur atau badan akreditasi, dan tampilkan halaman katalog yang bisa diakses publik. Ini adalah alasan langsung dan praktis mengapa seseorang mendaftar.

**Fungsi Kedua — Komunitas Profesional.**
Komunitas praktisi GLAM Indonesia. Ikuti kurator lain, publikasikan ke blog komunitas, hadiri atau selenggarakan acara dan webinar profesional, cari pekerjaan freelance, posting atau temukan lowongan kerja. Inilah mengapa orang bertahan, mengapa platform tumbuh dari mulut ke mulut, dan mengapa berpindah ke kompetitor lain pada akhirnya terasa mahal — bukan hanya soal migrasi data.

Tidak ada satu pun dari kedua lapisan ini yang bisa berdiri sendiri sebagai platform yang bertahan. Sistem manajemen koleksi tanpa komunitas hanyalah SLiMS lain — fungsional tapi tidak lekat. Komunitas tanpa alat koleksi hanyalah forum lain. Digabungkan, keduanya menciptakan sesuatu yang belum pernah ada sebelumnya untuk para praktisi GLAM Indonesia.

### 3.3 Siapa yang Membangun Ini dan Mengapa Itu Penting

Curatorian diinisiasi dan dibangun oleh **Chrisna Adhi**, seorang pustakawan sekaligus pengembang perangkat lunak di Universitas Padjadjaran (Unpad), Bandung.

Kombinasi ini — pustakawan yang bisa kode — lebih langka dari yang terdengar, dan sangat berpengaruh pada kualitas produk. Kebanyakan perangkat lunak perpustakaan dibangun oleh developer yang belajar tentang perpustakaan. Curatorian dibangun oleh pustakawan yang belajar mengembangkan software. Perbedaannya terlihat di setiap keputusan fitur: pilihan untuk membuat ISBN opsional (karena penerbit kecil Indonesia sering tidak mendaftarkan ISBN); integrasi sumber data bibliografi Indonesia di samping sumber internasional; pilihan Bahasa Indonesia sebagai bahasa utama untuk semua antarmuka; keputusan untuk membuat tier gratis benar-benar berfungsi penuh, bukan versi yang sengaja dikekang.

Versi pertama Curatorian lahir dari proyek nyata: membangun ulang infrastruktur manajemen perpustakaan yang terfragmentasi di Unpad — dua puluh database SLiMS terpisah di berbagai fakultas, disatukan menjadi satu aplikasi Phoenix dengan katalog bersama. Sistem itu sudah berjalan di produksi. Curatorian adalah langkah berikutnya: mengambil arsitektur yang sama dan membukanya untuk setiap kurator di Indonesia.

---

## 4. Siapa yang Kami Layani

Curatorian melayani tiga segmen pengguna utama dengan kebutuhan, motivasi, dan hubungan ekonomi yang berbeda terhadap platform.

### 4.1 Kurator Perorangan

Individu yang memiliki koleksi pribadi dan ingin mengkatalogisasi, mengorganisasi, dan membagikannya dengan cara yang layak. Kolektor buku. Pencinta film. Penggemar komik. Peneliti yang mengkatalogisasi perpustakaan referensi pribadi mereka. Orang-orang yang telah mengumpulkan sesuatu yang bermakna selama bertahun-tahun dan ingin mengelolanya lebih dari sekadar spreadsheet.

Pengguna ini butuh antarmuka katalogisasi yang indah dan minim hambatan; halaman profil publik yang memamerkan koleksi mereka; dan cara untuk menemukan orang lain yang berbagi minat yang sama. Mereka tidak tertarik membayar langganan bulanan untuk katalog pribadi. Kontribusi mereka ke platform bukan sebagai pembayar, tapi sebagai anggota komunitas — menghasilkan konten, membangun jaringan, dan menunjukkan nilai platform kepada pengguna institusional yang membayar.

Segmen kurator perorangan juga menyediakan jalur konversi yang penting: pengelola TBM sering mulai sebagai pengguna individual, menjelajahi platform secara pribadi sebelum mendaftarkan institusi mereka. Seorang pustakawan sekolah yang menemukan Curatorian melalui koleksi pribadinya mungkin kemudian memperkenalkannya ke sekolahnya.

### 4.2 Institusi Komunitas dan Nirlaba

Taman Bacaan Masyarakat, perpustakaan komunitas, perpustakaan sekolah, perpustakaan Unit Kegiatan Mahasiswa, arsip NGO, perpustakaan masjid dan pesantren, museum lokal kecil, program membaca di tingkat RT/RW, dan institusi apa pun yang mengelola koleksi untuk manfaat publik atau komunitas tanpa motif komersial.

Segmen ini adalah jantung budaya membaca Indonesia. Pengelola TBM menjalankan fasilitas mereka atas dasar misi, kepercayaan komunitas, dan tidak jarang pengorbanan pribadi. Mereka kekurangan dana secara kronis dan kurang terlayani secara teknis. Yang mereka butuhkan:

- Sistem katalog yang layak dengan biaya nol — ini tidak bisa dikompromikan
- Kehadiran publik yang membuat koleksi mereka terlihat dan bisa ditemukan
- Alat untuk menunjukkan dampak kepada donatur, pemerintah daerah, dan organisasi mitra
- Cukup sederhana sehingga sukarelawan tanpa latar belakang IT pun bisa mengelolanya
- Terhubung dengan TBM dan pustakawan lain untuk dukungan sesama dan berbagi pengetahuan

Fitur komunitas Curatorian bukan pelengkap untuk segmen ini — mereka adalah inti dari pengalaman. Seorang pengelola TBM ingin ngeblog tentang program membaca mereka, mengkaji pengelola yang sudah berpengalaman di kota lain, mendapat semangat dan saran, dan menemukan solidaritas dengan orang-orang yang menghadapi keterbatasan sumber daya yang sama. Curatorian adalah gerakan sosial sekaligus perangkat lunak.

Segmen ini berkontribusi pada keberlanjutan platform melalui donasi sukarela dan, yang lebih penting, melalui amplifikasi dari mulut ke mulut. Di komunitas pustakawan dan TBM Indonesia yang erat, rekomendasi tulus dari pengelola yang disegani bisa menjangkau ratusan pengguna potensial dalam semalam.

### 4.3 Institusi Komersial

Bisnis dan organisasi yang memelihara koleksi untuk alasan komersial, regulasi, atau positioning merek:

- **BUMN dan perusahaan besar** dengan kewajiban perpustakaan CSR
- **Kafe dan restoran** yang menjadikan koleksi buku sebagai bagian dari konsep mereka
- **Co-working space** dengan perpustakaan referensi untuk anggota
- **Boutique hotel** dengan ruang baca terkurasi
- **Sekolah dan universitas swasta** yang menginginkan katalog modern melampaui SLiMS
- **Kantor firma hukum, klinik, dan kantor profesional** dengan koleksi referensi spesialis
- **Pusat pengetahuan perusahaan** yang mengelola dokumentasi dan sumber daya internal

Institusi-institusi ini punya anggaran operasional, proses pengadaan yang lebih jelas, dan seseorang yang berwenang menyetujui langganan bulanan. Keputusan pembelian biasanya dibuat oleh satu atau dua orang tanpa siklus persetujuan institusional yang panjang — jauh lebih sederhana dibandingkan menjual ke sekolah negeri di mana tiga pemangku kepentingan harus setuju sebelum ada pengeluaran apa pun.

Kebutuhan mereka berpusat pada keandalan, kehadiran publik yang terlihat profesional, pelaporan yang bisa mereka tunjukkan kepada manajemen atau komite audit CSR, dan dukungan prioritas dalam Bahasa Indonesia. Mereka tidak butuh keahlian katalogisasi mendalam — mereka butuh sistem yang bisa dioperasikan staf non-pustakawan tanpa pelatihan panjang.

Segmen ini adalah sumber pendapatan komersial utama platform dan fondasi keberlanjutan finansial jangka panjangnya.

---

## 5. Fitur Platform

### 5.1 Manajemen Koleksi

Inti dari apa yang Curatorian lakukan. Setiap kurator di platform memiliki akses ke sistem manajemen koleksi yang lengkap dan profesional.

**Katalogisasi.** Item dibuat dengan metadata bibliografi yang fleksibel: judul, subjudul, penulis, penerbit, tahun, edisi, bahasa, kategori subjek, format fisik, kondisi, dan lokasi dalam ruang fisik. Sistem field yang bisa dikustomisasi (EAV — Entity-Attribute-Value) membuat platform yang sama bisa bekerja dengan baik untuk buku, objek museum, dokumen arsip, gulungan film, dan jenis koleksi apa pun lainnya. Skema datanya tidak mengistimewakan satu disiplin GLAM di atas yang lain.

**Pengambilan Metadata.** Saat mengkatalogisasi buku, pengguna bisa memasukkan identifikasi atau judul untuk mengambil data bibliografi dari sumber eksternal — Open Library, OpenAlex, dan Google Books — yang mengisi form secara otomatis dengan judul, penulis, penerbit, tahun, dan sampul buku. ISBN selalu opsional: banyak buku Indonesia dari penerbit kecil tidak memiliki ISBN, dan sistem bekerja sepenuhnya tanpa ISBN. Sumber data bibliografi Indonesia dan sumber tambahan lainnya akan diintegrasikan seiring platform berkembang.

**Beberapa Koleksi per Node.** Sebuah institusi bisa mengorganisasi item ke dalam beberapa koleksi bernama dalam node mereka — "Koleksi Umum," "Koleksi Referensi," "Koleksi Anak" — masing-masing dengan pengaturan privasi, aturan akses, dan tampilan katalog tersendiri.

**Sirkulasi.** Untuk institusi yang meminjamkan item kepada anggota: pembuatan pinjaman dengan tanggal jatuh tempo yang bisa dikonfigurasi, pemrosesan pengembalian dengan perhitungan denda otomatis, pencatatan pembayaran denda, keringanan denda, riwayat pinjaman per item dan per anggota, serta laporan keterlambatan. Data anggota mencakup nama, ID anggota, informasi kontak, tanggal pendaftaran, dan riwayat pinjaman. Data anggota dibatasi pada satu institusi — anggota perpustakaan sekolah A bukan otomatis anggota perpustakaan sekolah B.

**OPAC Publik.** Setiap node di Curatorian secara otomatis mendapat halaman katalog akses publik (*Online Public Access Catalog*) di `curatorian.id/[node-slug]/catalog`. Halaman ini bisa dicari berdasarkan judul, penulis, subjek, dan catatan; bisa difilter berdasarkan koleksi, bahasa, dan ketersediaan; bisa dibagikan dengan gambar pratinjau media sosial yang proper; dan bisa ditanamkan via iframe di website institusi sendiri. OPAC publik adalah produk paling terlihat dari penggunaan Curatorian — itulah yang donatur, peneliti, atau pemustaka lihat ketika mereka menemukan institusi tersebut secara online.

**Import CSV.** Institusi yang bermigrasi dari spreadsheet bisa mengimpor katalog yang sudah ada via CSV dengan pemetaan kolom dan pratinjau import. Format ekspor CSV SLiMS didukung dengan pemetaan kolom otomatis, mengurangi gesekan peralihan dari alat yang paling umum digunakan.

**Log Pengunjung.** Penghitung pengunjung sederhana untuk OPAC publik, memberi TBM dan perpustakaan komunitas data dampak yang bisa mereka bagikan ke pendonor dan organisasi mitra.

**Dasbor Analitik.** Setiap node memiliki akses ke dasbor yang menampilkan statistik koleksi, aktivitas sirkulasi, jumlah anggota, dan jumlah pengunjung OPAC dari waktu ke waktu. Metrik yang sederhana dan jujur — yang menjawab pertanyaan yang benar-benar ditanyakan oleh pengelola perpustakaan atau koordinator CSR.

### 5.2 Komunitas

Fitur komunitas profesional yang mengubah Curatorian dari sekadar alat menjadi sebuah platform.

**Profil Pengguna.** Setiap pengguna terdaftar punya halaman profil publik di `curatorian.id/@username` yang menampilkan nama, bio, afiliasi institusional, koleksi publik mereka, dan aktivitas komunitas. Kurator perorangan memamerkan koleksi mereka di sini. Pustakawan profesional mendaftar keahlian dan pengalaman mereka. Profil adalah identitas pengguna di platform.

**Profil Organisasi.** Setiap node punya halaman profil publik yang menampilkan nama institusi, deskripsi, lokasi, informasi kontak, dan katalog publik. Inilah cara TBM memperkenalkan diri ke dunia — satu URL yang bisa dibagikan dan berisi semua informasi yang dibutuhkan seseorang tentang koleksi dan cara mengaksesnya.

**Blog Komunitas.** Sistem publikasi di mana pengguna dan institusi bisa menulis dan menerbitkan artikel. Penggunaan yang dimaksud mencakup panduan praktis (teknik katalogisasi, dasar-dasar preservasi, hak cipta untuk koleksi), cerita dari lapangan (laporan program TBM, jurnal proyek digitasi), opini profesional, dan pengumuman acara. Konten ini membangun reputasi platform sebagai sumber daya profesional, menarik lalu lintas organik, dan menciptakan alasan untuk kembali ke platform selain manajemen koleksi.

**Sistem Follow.** Pengguna dan organisasi bisa saling mengkaji. Pengelola TBM baru bisa mengkaji yang sudah berpengalaman untuk belajar dari pengalaman yang dipublikasikan. Pustakawan bisa mengkaji asosiasi profesional dan institusi sejawat. Grafik follow cukup terlihat untuk menciptakan koneksi dan penemuan, cukup privat sehingga tidak terasa seperti pengawasan.

**Pesan Komunitas.** Pesan langsung dan grup antar pengguna platform. Percakapan dukungan sesama yang saat ini terjadi melalui WhatsApp — terpecah-pecah, sulit dicari, hilang ketika ganti ponsel — bisa terjadi di lingkungan yang tepat, persisten, dan bisa dicari.

**Profil Pembaca dan Kolektor Perorangan.** Curatorian bukan hanya untuk kurator institusional — ini juga rumah bagi siapa pun yang mencintai buku, materi arsip, atau koleksi apa pun. Pembaca dan kolektor individual bisa membangun profil publik di sekitar kehidupan membaca mereka: berbagi apa yang sedang mereka baca, menulis catatan dan refleksi tentang item di koleksi mereka, bercerita tentang penemuan baru, dan mendokumentasikan perjalanan mengumpulkan koleksi mereka. Platform ini menciptakan ruang untuk bertemu orang-orang dengan minat literasi yang sama, mengkaji kurator dengan selera serupa, dan berpartisipasi dalam komunitas yang menganggap serius hubungan personal dengan koleksi dan gagasan. Baik seseorang punya lima ratus buku atau hanya lima — hubungan mereka dengan benda-benda dan ide-ide itu layak untuk dibagikan.

### 5.3 Platform Acara dan Webinar

Sistem manajemen acara lengkap untuk komunitas profesional GLAM Indonesia.

Webinar, workshop, dan seri seminar adalah inti dari pengembangan profesional GLAM di Indonesia. IPI (Ikatan Pustakawan Indonesia), ATPUSI, asosiasi perpustakaan universitas, dan jaringan TBM semuanya menyelenggarakan acara rutin, yang saat ini diorganisir melalui kombinasi Google Form, blast WhatsApp, dan daftar hadir manual. Curatorian menyediakan platform asli untuk siklus hidup acara secara penuh.

**Bagi penyelenggara:** Buat acara dengan judul, deskripsi, format (online/offline/hybrid), tanggal, kapasitas, dan harga (gratis atau berbayar). Kelola pendaftaran dan daftar peserta. Lakukan check-in dengan QR di acara. Terbitkan sertifikat kehadiran dengan URL verifikasi. Hubungkan akun Zoom via OAuth untuk pembuatan rapat otomatis. Lihat analitik pendapatan dan kehadiran.

**Bagi peserta:** Jelajahi acara mendatang di `curatorian.id/events`. Daftar dengan satu form, bayar via Midtrans untuk acara berbayar. Terima tiket QR melalui email. Unduh sertifikat kehadiran setelah acara, dengan URL verifikasi (`curatorian.id/verify/[kode-sertifikat]`) yang bisa ditautkan dari CV atau profil LinkedIn.

**Biaya platform:** Persentase kecil dari pendapatan tiket acara berbayar. Acara gratis tidak dikenakan biaya apa pun.

### 5.4 Papan Lowongan Kerja

Papan lowongan kerja khusus untuk posisi di sektor GLAM Indonesia.

Lulusan baru Ilmu Perpustakaan dan Informasi, arsiparis freelance, dan profesional informasi tidak punya papan lowongan khusus sektor di Indonesia. LinkedIn terlalu mahal bagi institusi kecil untuk memasang iklan dan terlalu luas bagi pencari kerja untuk menyaringnya. Grup Facebook tidak terstruktur dan mudah hilang. Curatorian, dengan institusi dan profesional yang relevan sudah ada di dalamnya, adalah rumah alami untuk fungsi ini.

**Bagi institusi:** Posting posisi dengan detail lengkap — judul, jenis pekerjaan (penuh waktu/paruh waktu/sukarela/magang), lokasi, rentang gaji, persyaratan, dan metode lamaran. Institusi for-profit membayar biaya posting kecil; institusi nirlaba posting gratis.

**Bagi pencari kerja:** Jelajahi dan cari lowongan dengan filter untuk lokasi, jenis, dan kategori institusi. Lamar dalam platform atau ikuti tautan eksternal, bisa dikonfigurasi per lowongan.

**Biaya platform:** Biaya posting yang terjangkau untuk institusi for-profit. Gratis untuk institusi nirlaba dan komunitas.

### 5.5 Marketplace Tenaga Ahli dan Freelance

Platform pencocokan untuk pekerjaan proyek GLAM di Indonesia.

Banyak institusi punya kebutuhan manajemen koleksi yang tidak bisa mereka tangani dengan staf tetap: backlog katalogisasi dua ribu item yang belum diproses, hibah digitasi dengan tanpa keahlian teknis in-house, audit koleksi yang diperlukan untuk aplikasi akreditasi. Sementara itu, banyak profesional yang memenuhi syarat — lulusan LIS baru, arsiparis paruh waktu, katalogisator freelance — punya keahlian dan ketersediaan tapi tidak punya saluran untuk menemukan pekerjaan proyek semacam ini.

Marketplace ini menutup celah tersebut.

**Bagi profesional:** Buat profil yang mencantumkan keahlian (katalogisasi, digitasi, standar metadata seperti MARC 21 dan Dublin Core, preservasi, penilaian koleksi), tarif, portofolio, dan ketersediaan. Tawarkan paket layanan harga tetap dengan ruang lingkup dan waktu pengiriman yang terdefinisi. Contoh: *"Katalogisasi 500 buku dengan format standar — Rp 2.500.000, estimasi 2 minggu."*

**Bagi institusi:** Jelajahi profil freelancer dan daftar layanan. Posting permintaan proyek ke papan permintaan. Pesan dan bayar melalui platform dengan perlindungan escrow — dana ditahan sampai institusi mengkonfirmasi penyelesaian yang memuaskan.

**Biaya platform:** Komisi dari engagement yang diselesaikan. Ini adalah mesin pendapatan utama jangka panjang platform — biaya transaksi berganda seiring pertumbuhan jaringan dengan cara yang tidak bisa dilakukan biaya langganan.

### 5.6 Jaringan Bibliografi Bersama

Katalog lintas institusi yang dibangun dari rekaman koleksi semua node Curatorian yang ikut berpartisipasi.

Begitu cukup banyak institusi mengkatalogisasi koleksi mereka di Curatorian, platform itu sendiri menjadi sumber daya bibliografi — terutama berharga untuk materi Indonesia yang tidak terindeks dalam database internasional: penerbit lokal, teks berbahasa daerah, naskah yang belum diterbitkan, judul Indonesia yang sudah tidak dicetak lagi, dan materi pendidikan buatan komunitas.

Institusi mengikutsertakan item individual ke dalam jaringan. Rekaman yang diikutsertakan diagregasi ke dalam indeks lintas institusional yang bisa dicari. Pengguna Curatorian mana pun bisa mencari di semua koleksi yang diikutsertakan. Menemukan rekaman di jaringan, pengguna bisa menyalinnya ke koleksi mereka sendiri dalam satu klik — mengisi semua metadata yang tersedia dan membebaskan mereka dari memasukkan ulang data yang sudah ditangkap institusi lain.

Seiring waktu, Jaringan Bibliografi Bersama berpotensi menjadi database bibliografi berbahasa Indonesia paling komprehensif yang pernah ada — dibangun oleh komunitas, untuk komunitas, mencakup ekor panjang penerbitan Indonesia yang tidak ditangani database komersial mana pun.

Setiap rekaman yang dibagikan mencantumkan kredit ke institusi asal, membangun reputasi komunitas untuk rekaman katalog yang dirawat dengan baik dan memberi institusi alasan nyata untuk berpartisipasi dalam jaringan.

### 5.7 Pembuat Pameran Digital

Alat untuk membuat dan menerbitkan pameran digital tematik dari koleksi sebuah node.

Museum, arsip, dan perpustakaan mengkomunikasikan koleksi mereka paling kuat melalui presentasi naratif terkurasi — pameran yang menceritakan sebuah kisah melalui objek-objek pilihan, dengan konteks dan urutan. Koleksi batik dari berbagai daerah Jawa, disajikan dengan anotasi geografis dan narasi sejarah, jauh lebih menarik bagi publik dibandingkan daftar katalog mentah yang sama.

Institusi bisa membuat pameran dengan memilih item dari koleksi mereka, mengaturnya, menambahkan teks naratif dan keterangan per item, dan menerbitkannya di URL tersendiri. Pameran bisa dibagikan, bisa ditanamkan di website lain, dan tersedia secara permanen di `curatorian.id/[node-slug]/pameran/[slug]`.

### 5.8 Penggalangan Dana Institusi

Alat penggalangan dana yang memungkinkan institusi komunitas menerima donasi atau menjalankan kampanye dengan target tertentu.

TBM dan perpustakaan komunitas sering butuh dukungan finansial dari komunitas — untuk membeli buku, mendanai program membaca, atau membiayai proyek digitasi. Saat ini ini terjadi melalui penggalangan informal via WhatsApp atau platform eksternal yang tidak memberikan konteks tentang kerja institusi tersebut. Halaman penggalangan dana Curatorian terhubung ke katalog dan profil komunitas institusi, memberi donatur potensial konteks penuh sebelum berkontribusi.

Institusi bisa memelihara halaman donasi permanen atau menjalankan kampanye dengan target, tenggat waktu, dan pelacakan kemajuan yang spesifik. Donatur menerima lencana pendukung digital di profil Curatorian mereka.

**Biaya platform:** Persentase kecil dari dana yang terkumpul, untuk menutupi biaya transaksi.

### 5.9 Manajer Program Membaca

Alat terstruktur untuk menjalankan, melacak, dan melaporkan program membaca.

Program Gerakan Literasi, tantangan membaca, dan program buku klub adalah inti dari misi TBM dan perpustakaan sekolah. Program-program ini saat ini dikelola melalui lembar pendaftaran kertas dan pelacakan manual. Curatorian mengelola siklus hidup program secara penuh: pembuatan, pendaftaran peserta, log membaca individual, visualisasi kemajuan, sertifikat penyelesaian, dan halaman program publik untuk pelaporan kepada pendonor dan organisasi mitra.

### 5.10 Bursa Koleksi

Platform pertukaran antar sesama untuk mendonasikan dan meminta item koleksi fisik — antara institusi maupun individu.

Setiap perpustakaan dan koleksi mengalami evolusi yang wajar. Sebuah TBM yang dulunya berfokus pada buku bergambar anak-anak kini beralih ke program literasi orang dewasa, dan buku-buku bergambar itu tidak lagi melayani komunitasnya. Sebuah perpustakaan sekolah memiliki salinan ganda dari judul-judul yang banyak didonasikan dan tidak bisa dimanfaatkan. Seorang peneliti memiliki koleksi spesialis yang dikemas dalam kardus — yang akan sangat berharga bagi arsip universitas. Sementara itu, institusi lain punya daftar keinginan: mereka sedang membangun koleksi sejarah lokal dan aktif mencari donasi materi yang relevan.

Ketidaksesuaian ini — surplus di satu tempat, kebutuhan di tempat lain — saat ini tidak memiliki lapisan koordinasi. Diselesaikan melalui jaringan personal yang informal, atau tidak sama sekali.

Curatorian menyediakan infrastruktur pencocokannya. Institusi dan individu bisa menandai item yang sudah terkatalogisasi sebagai tersedia untuk didonasikan, dengan catatan singkat tentang kondisi dan kesesuaiannya. Mereka juga bisa menerbitkan daftar keinginan berisi item koleksi yang aktif mereka cari — judul tertentu, bidang subjek, atau format tertentu. Kedua sisi terlihat oleh komunitas dan bisa dicari di seluruh platform.

Platform ini adalah lapisan pencocokan dan visibilitas saja. Curatorian tidak menangani logistik, pengiriman, atau transfer legal — semua itu diatur langsung antara para pihak begitu kecocokan ditemukan. Nilainya ada pada memunculkan apa yang tersedia dan apa yang dibutuhkan dalam satu tempat, untuk pertama kalinya, di ribuan koleksi Indonesia.

Setiap pertukaran yang selesai dicatat sebagai kontribusi komunitas di profil kedua pihak — membangun rekam jejak kedermawanan dan timbal balik yang terlihat di dalam komunitas GLAM.

---

## 6. Arsitektur Teknis

### 6.1 Prinsip Desain Sistem

Setiap keputusan teknis dalam Curatorian dibimbing oleh lima prinsip.

**Hosting-first.** Seluruh platform di-hosting di cloud. Pengguna tidak pernah menyentuh server, memasang perangkat lunak, atau mengkonfigurasi database. Ini bukan fitur kenyamanan — ini adalah fondasi yang tidak bisa dikompromikan yang membuat Curatorian bisa diakses oleh seluruh spektrum kurator Indonesia.

**Core yang agnostik terhadap disiplin GLAM.** Model koleksi dirancang untuk bekerja sama baiknya untuk buku, objek museum, dokumen arsip, dan gulungan film. Platform tidak mengistimewakan disiplin GLAM mana pun. Sistem field EAV memungkinkan institusi mendefinisikan metadata yang tepat untuk jenis koleksi mereka.

**Isolasi data berbasis node.** Data koleksi setiap institusi terbatas pada node mereka. Institusi memiliki rekaman mereka dan bisa mengontrol siapa yang melihatnya. Berbagi lintas node (Jaringan Bibliografi Bersama) selalu ikut serta secara sukarela, tidak pernah otomatis.

**ISBN opsional.** Sistem bekerja sepenuhnya tanpa ISBN. Banyak buku Indonesia dari penerbit kecil tidak memiliki ISBN. Sistem apa pun yang mengharuskan ISBN akan gagal segera untuk sebagian besar koleksi Indonesia.

**Native Indonesia.** Antarmuka dalam Bahasa Indonesia. Tanggal, mata uang, dan referensi budaya bersifat lokal. Pembayaran menggunakan metode Indonesia (QRIS, transfer bank). Sumber bibliografi mencakup database khusus Indonesia. Ini bukan terjemahan produk asing — ini dibangun di Indonesia, untuk Indonesia.

### 6.2 Arsitektur Tiga Lapisan

Curatorian terdiri dari tiga lapisan perangkat lunak yang berbeda, masing-masing dengan tanggung jawab yang terdefinisi dan status open/proprietary yang jelas.

```
VOILE (open source, Apache 2.0)
  Library Elixir yang dikompilasi — inti mesin GLAM
  Menyediakan: katalogisasi, sirkulasi, manajemen anggota,
  manajemen node, field koleksi, transaksi
  Repository: github.com/curatorian/voile
        │
        │  dikompilasi ke dalam Curatorian sebagai dependensi mix.exs
        ↓
CURATORIAN (open source)
  Aplikasi Phoenix LiveView — platform publik
  Auth, komunitas, OPAC publik, semua rute baca
  DB: skema voile + public
  Repository: github.com/curatorian/curatorian
        │
        │  Autentikasi lintas aplikasi via Phoenix.Token
        ↓
ATRIUM (proprietary)
  Aplikasi Phoenix LiveView — dasbor manajemen
  Manajemen koleksi, billing, acara, marketplace
  DB: skema atrium
  Repository: privat
```

**Voile** adalah library core GLAM open source. Ini adalah dependensi Elixir yang dikompilasi — bukan server yang berjalan — yang menyediakan model data dan logika bisnis untuk koleksi, sirkulasi, manajemen anggota, dan struktur node. Siapa pun bisa membaca, mem-fork, dan menggunakan Voile di bawah ketentuan Apache 2.0.

**Curatorian** adalah aplikasi Phoenix yang menghadap publik: autentikasi pengguna, fitur komunitas (blog, pesan, sistem follow), halaman OPAC publik, dan semua rute read-only. Repositorinya publik di GitHub. Institusi yang punya kapasitas teknis bisa self-host ini secara gratis.

**Atrium** adalah dasbor manajemen proprietary: antarmuka manajemen koleksi, penagihan langganan, manajemen acara, papan lowongan kerja, marketplace, dan analitik. Ini adalah lapisan komersial yang menghasilkan pendapatan dan menopang operasional.

Secara eksternal, hanya nama **Curatorian** yang ada. Pengguna berinteraksi dengan Curatorian. Arsitektur internal — Voile dan Atrium — adalah detail implementasi yang tidak relevan bagi pengguna non-developer.

### 6.3 Strategi Database

Curatorian dan Atrium berbagi satu instance database PostgreSQL, dipisahkan ke dalam skema yang berbeda sesuai tanggung jawab masing-masing lapisan. Skema Voile menyimpan data GLAM inti: koleksi, item, catatan sirkulasi, data anggota, dan tabel referensi. Skema Atrium menyimpan data manajemen platform: langganan, acara, lowongan kerja, engagement marketplace, analitik, dan notifikasi.

Pemisahan skema memberikan batas logis yang bersih. Migrasi Atrium ada di repositori privat Atrium dan tidak pernah muncul di repositori Curatorian yang publik — batas open source dijaga di level kode.

Tidak ada constraint foreign key yang melintas batas skema. Referensi lintas skema disimpan sebagai nilai identifikasi biasa — menjaga pemisahan yang bersih sekaligus memungkinkan pola akses data yang dibutuhkan platform.

Tabel operasional dengan volume tinggi dirancang dengan skalabilitas sejak deployment pertama, menghindari kebutuhan restrukturisasi yang mahal seiring platform berkembang.

### 6.4 Autentikasi dan Keamanan

Autentikasi ditangani secara terpusat dalam aplikasi Curatorian. Dasbor manajemen memverifikasi identitas melalui token lintas aplikasi yang telah ditandatangani — bukan mengelola login secara independen — memastikan satu titik autentikasi yang konsisten bagi pengguna di seluruh bagian platform.

Semua akses data sensitif dibatasi sesuai node pengguna yang terautentikasi. Soft deletion digunakan di seluruh platform — tidak ada data pengguna yang dihapus secara permanen tanpa tindakan yang disengaja. Rate limiting diterapkan pada endpoint autentikasi sebelum peluncuran publik apa pun.

### 6.5 Integritas Platform dan Verifikasi

Platform komunitas yang terbuka dan mudah diakses juga menjadi target. Komunitas GLAM Indonesia berhak mendapatkan ruang yang bebas dari spam, manipulasi, dan aktor tidak bertanggung jawab — dan desain Curatorian mencerminkan tanggung jawab itu sejak deployment pertama.

**Masalah spam dan judi online.** Platform publik dengan domain `.id` yang memiliki otoritas SEO yang sah secara sistematis menjadi target operator judi yang mencari tautan balik. Ini adalah pengalaman langsung pada platform komunitas Indonesia lainnya. Curatorian dirancang untuk membuat dirinya tidak bernilai sebagai target manipulasi SEO sejak hari pertama.

Semua tautan eksternal yang diposting pengguna secara otomatis mendapat atribut `rel="nofollow ugc"` — menghilangkan nilai tautan balik yang memotivasi sebagian besar operasi spam. Profil yang belum terverifikasi dan konten yang baru dibuat tidak diindeks oleh mesin pencari sampai akun telah diverifikasi dan menunjukkan aktivitas nyata. Tidak ada nilai SEO, tidak ada motif spam.

**Verifikasi nomor telepon.** Pendaftaran akun memerlukan verifikasi OTP WhatsApp. Nomor telepon Indonesia adalah hambatan yang berarti — operasi spam luar negeri dan bot otomatis tidak bisa mendapatkannya dalam skala besar. Ini juga secara kultural sangat wajar: hampir semua orang dalam komunitas target Curatorian sudah menggunakan WhatsApp setiap hari. Verifikasi cepat, familiar, dan bukan hambatan bagi pengguna yang tulus.

**Karantina konten akun baru.** Node baru bisa langsung menggunakan platform — mengkatalogisasi koleksi dan mengelolanya secara internal — tetapi konten yang menghadap publik (bio profil, posting blog, tautan eksternal, listing bursa koleksi) tunduk pada jendela karantina singkat sebelum muncul di halaman yang diindeks publik. Ini menangkap posting otomatis tanpa merepotkan pengguna baru yang tulus.

**Daftar blokir domain berbahaya.** Daftar domain judi, spam, dan berbahaya yang terpelihara diperiksa terhadap semua field URL pada saat penulisan. Upaya memposting URL yang ditandai ditolak secara diam-diam dengan pesan validasi umum. Daftar ini diperbarui saat domain baru teridentifikasi.

**Field honeypot.** Form pendaftaran dan pengiriman berisi field tersembunyi yang tidak pernah dilihat atau diisi pengguna nyata. Bot otomatis yang membabi buta mengisi semua field form memicu penolakan diam-diam. Tidak ada gesekan CAPTCHA bagi pengguna manusia.

**Pelaporan komunitas.** Setiap pengguna terautentikasi bisa melaporkan profil, posting, atau listing sebagai mencurigakan. Konten yang dilaporkan disembunyikan sementara menunggu peninjauan — terlihat oleh pemilik akun, tidak terlihat oleh publik. Dalam komunitas yang erat dan berorientasi profesional ini, aktor jahat teridentifikasi dengan cepat.

**Verifikasi sebagai fondasi kepercayaan.** Verifikasi telepon berfungsi ganda: sebagai penghalang spam sekaligus sinyal kepercayaan. Akun terverifikasi dengan katalog aktif dan riwayat komunitas memiliki kredibilitas yang nyata. Lapisan verifikasi yang sama yang memblokir bot spam juga menjadi dasar sistem deklarasi mandiri untuk keanggotaan penyokong — sebuah institusi dengan nomor telepon nyata, katalog aktif, dan kehadiran komunitas telah menaruh sesuatu yang nyata.

### 6.6 Strategi Data Bibliografi

Ketika pustakawan memasukkan identifikasi atau mencari berdasarkan judul, Curatorian mengambil metadata bibliografi dari rantai sumber eksternal secara berurutan:

1. **Open Library** — tidak perlu API key, cakupan umum yang luas
2. **OpenAlex** — tidak perlu API key, cakupan akademik yang kuat
3. **Google Books** — cakupan populer yang luas
4. **Input manual** — selalu tersedia, selalu menjadi fallback

Sistem ini dirancang untuk mengakomodasi sumber tambahan — termasuk database khusus Indonesia — seiring platform berkembang dan kebutuhannya menjadi lebih jelas. Semua pengambilan data bersifat opsional: kurator selalu bisa memasukkan metadata secara manual, dan tidak ada fitur platform yang membutuhkan identifikasi untuk bisa berfungsi.

### 6.7 Tumpukan Teknologi

| Komponen | Teknologi | Alasan Pemilihan |
|----------|-----------|-----------------|
| Bahasa | Elixir 1.17+ / Erlang OTP 27+ | Konkurensi, toleransi kesalahan, real-time dalam skala; VM BEAM berjalan andal di hardware minimal |
| Framework | Phoenix 1.7+ / LiveView 1.0+ | UI real-time tanpa overhead framework JavaScript terpisah; sangat efisien |
| Database | PostgreSQL 14+ | Robust, kaya fitur, menangani strategi pemisahan skema dengan bersih |
| Frontend | Tailwind CSS + DaisyUI | Pengembangan UI yang cepat dan konsisten; tema Voile Library (terang) dan Voile Night (gelap) |
| Deployment | VPS Jakarta / fly.io Singapore | Jakarta untuk latensi; Singapore untuk tooling native Phoenix |
| DNS & CDN | Cloudflare | Manajemen DNS, proteksi DDoS, penyimpanan objek |
| Pembayaran | Midtrans | Gateway pembayaran Indonesia dengan QRIS, transfer bank, e-wallet |
| Email | Swoosh + Mailgun | Email transaksional; tier gratis cukup untuk tahap awal |
| Generasi PDF | ChromicPDF | PDF berbasis HTML/CSS untuk sertifikat, invoice, laporan; kontrol desain maksimal |
| Background Jobs | Oban | Pemrosesan job async yang andal berbasis database; generasi PDF, email, pemanasan cache |
| Sumber Bibliografi | Open Library, OpenAlex, Google Books | Rantai prioritas yang mencakup data bibliografi internasional; sumber tambahan akan ditambahkan seiring waktu |
| Penyimpanan Gambar | Cloudflare R2 | Penyimpanan objek kompatibel S3 untuk gambar sampul item koleksi |

Pilihan Elixir dan Phoenix adalah keputusan yang disengaja dan signifikan. VM BEAM — runtime yang mendasari Elixir — dirancang untuk sistem konkuren dan toleran kesalahan. Phoenix LiveView memungkinkan UI real-time dan kolaboratif (pencarian katalog langsung, pemindaian check-in real-time, pembaruan sirkulasi langsung) tanpa kompleksitas frontend JavaScript terpisah. Aplikasi Elixir dikompilasi menjadi rilis mandiri yang berjalan efisien di hardware yang sederhana.

---

## 7. Filosofi Open Source

### 7.1 Model Open Core

Curatorian beroperasi dengan model open core — model yang sama yang telah menopang proyek seperti GitLab, Plausible Analytics, Matomo, dan Metabase. Teknologi fondasinya open source. Lapisan komersial yang dibangun di atasnya bersifat proprietary.

Ini bukan kompromi antara keterbukaan dan kelangsungan komersial. Ini adalah desain yang melayani keduanya secara bersamaan.

### 7.2 Apa yang Terbuka dan Apa yang Tidak

**Open Source (Apache 2.0):**

*Voile* — library inti GLAM. Semua model data katalogisasi, logika sirkulasi, manajemen anggota, struktur node, dan definisi field koleksi. Ini adalah mesin yang menjalankan semua manajemen koleksi di Curatorian. Bisa digunakan secara independen dalam aplikasi Elixir apa pun di bawah ketentuan Apache 2.0.

*Curatorian* — aplikasi Phoenix yang menghadap publik. Autentikasi, fitur komunitas, OPAC publik, dan semua rute read-only. Repositorinya publik di GitHub. Institusi yang punya kapasitas teknis bisa self-host aplikasi ini bersama Voile.

**Proprietary:**

*Atrium* — dasbor manajemen. Antarmuka manajemen koleksi, penagihan langganan, manajemen acara, papan lowongan kerja, marketplace, analitik, dan alat administratif. Ini adalah lapisan komersial yang menghasilkan pendapatan, mendanai pengembangan, dan menopang platform sebagai layanan. Repositorinya privat.

Batas ini dijaga di level kode. Migrasi database Atrium ada di repositori Atrium yang privat dan tidak pernah muncul di repositori Curatorian yang publik, meskipun kedua aplikasi berbagi database PostgreSQL yang sama.

### 7.3 Mengapa Model Ini Cocok untuk GLAM Indonesia

**Kepercayaan dan kebebasan dari vendor lock-in.** Institusi Indonesia — terutama yang pernah terbakar oleh proyek perangkat lunak yang tiba-tiba menghilang — dengan tepat bersikap hati-hati terhadap sistem proprietary. Core open source berarti data katalog mereka selalu bisa diakses, model data terdokumentasi, dan mereka bisa bermigrasi ke konfigurasi self-hosted jika situasi berubah. Kepercayaan ini bukan retorika. Ini struktural dan bisa diverifikasi.

**Tier gratis yang sungguh-sungguh gratis.** Tier gratis bukan demo yang dikekang. Voile dan Curatorian bersama-sama menyediakan sistem manajemen koleksi yang lengkap dan fungsional yang bisa di-host sendiri oleh institusi mana pun tanpa biaya. Ketika Curatorian menawarkan fungsionalitas ini sebagai layanan hosted secara gratis, ia menawarkan nilai nyata, bukan umpan pemasaran. Inilah cara kepercayaan komunitas dibangun.

**Komunitas developer.** Open source menarik kontributor. Seorang developer-pustakawan yang membangun sesuatu di atas Voile meningkatkan platform untuk setiap institusi yang menggunakannya. Kontribusi komunitas mengurangi beban pengembangan solo seiring waktu dan membangun jenis keahlian yang terdistribusi dan beragam yang membuat perangkat lunak menjadi tangguh.

**Keberlanjutan melalui lapisan komersial.** Atrium yang proprietary mendanai pengembangan Voile dan Curatorian yang open source. Ini adalah siklus yang saling menguntungkan: semakin berharga core open source-nya, semakin menarik lapisan komersial yang ter-hosting; semakin sukses lapisan komersial, semakin banyak sumber daya yang tersedia untuk diinvestasikan kembali ke fondasi open source.

---

## 8. Model Bisnis dan Keberlanjutan

### 8.1 Filosofi

Curatorian dibangun di atas keyakinan sederhana: akses ke alat untuk melestarikan dan berbagi pengetahuan tidak seharusnya bergantung pada kemampuan membayar. Pengelola TBM yang menjalankan ruang baca dari rumahnya sendiri dan perpustakaan universitas dengan anggaran resmi sama-sama sedang melakukan pekerjaan yang penting. Platform ini seharusnya melayani keduanya secara penuh, tanpa perbedaan.

Komunitas GLAM Indonesia mempercayai alat yang dibangun oleh praktisi, diadopsi secara bebas, dan dikelola dengan jujur. Mereka dengan wajar curiga terhadap platform komersial yang memperlakukan komunitas sebagai segmen pasar. Curatorian mendapatkan kepercayaan dengan memberikan nilai nyata terlebih dahulu — dan menopang dirinya melalui kontribusi sukarela dan proporsional dari mereka yang mendapat manfaat dari platform dan memiliki kemampuan untuk berkontribusi.

Ini bukan filantropi dan ini bukan bisnis berlangganan. Ini adalah model kooperatif: platform ini milik komunitas yang dilayaninya, dan komunitas menopangnya secara kolektif, masing-masing sesuai kemampuannya.

### 8.2 Akses Penuh untuk Semua

Setiap fitur Curatorian tersedia bagi setiap pengguna, sejak hari pertama, selamanya. Tidak ada tingkatan fitur, tidak ada batas penggunaan, tidak ada fungsi yang dikunci di balik pembayaran. Kolektor buku perorangan dan BUMN dengan perpustakaan CSR seribu item memiliki akses ke alat yang identik.

Ini bukan model freemium dengan jalur upgrade tersembunyi. Ini adalah pilihan struktural yang disengaja: begitu akses menjadi bersyarat pada pembayaran, platform berhenti menjadi infrastruktur komunitas dan menjadi produk. Curatorian adalah infrastruktur.

Pertanyaan praktis — bagaimana infrastruktur menopang dirinya — dijawab bukan dengan membatasi akses, tetapi dengan membangun budaya kontribusi proporsional di antara mereka yang memiliki kapasitas untuk berkontribusi.

### 8.3 Keanggotaan Penyokong

Institusi komersial dan for-profit — bisnis, perpustakaan CSR perusahaan, sekolah swasta, co-working space — diundang untuk menjadi Anggota Penyokong. Keanggotaan penyokong adalah kontribusi, bukan pembelian. Ini tidak membuka fitur baru. Ini adalah pengakuan bahwa institusi mendapat manfaat dari platform dan memiliki anggaran untuk mendukung apa yang digunakan komunitas yang lebih luas secara gratis.

Jumlah kontribusi fleksibel dan diserahkan pada penilaian institusi. Yang penting adalah pengakuan publik: Anggota Penyokong mendapat lencana terlihat di profil node mereka — "Anggota Penyokong Curatorian" — yang menandakan dukungan mereka kepada komunitas. Dalam konteks di mana reputasi institusional penting — audit CSR, akreditasi, hubungan mitra — lencana ini adalah sinyal bermakna dari investasi dalam infrastruktur GLAM Indonesia.

Untuk institusi yang proses pengadaannya memerlukan dokumentasi formal, Curatorian menghasilkan invoice atau tanda terima kontribusi yang proper sesuai permintaan, dilabeli dengan jelas sebagai kontribusi keberlanjutan platform. Ini menghilangkan gesekan administrasi yang menghalangi institusi yang sebetulnya bersedia berkontribusi.

Anggota Penyokong juga mendapat suara yang lebih berbobot dalam pengembangan platform — akses ke forum kontributor di mana prioritas roadmap bisa diusulkan dan didiskusikan. Mereka tidak mengontrol platform, tetapi mereka didengar lebih langsung dari pengguna anonim. Ini adalah manfaat yang bermakna bagi institusi komersial yang mengandalkan pengembangan platform yang berkelanjutan.

### 8.4 Donasi dan Apresiasi

Di luar keanggotaan penyokong institusional, Curatorian mempertahankan lapisan donasi sukarela terbuka bagi individu dan organisasi dari jenis apa pun.

**Untuk individu.** Pengguna mana pun yang menemukan nilai nyata dalam platform bisa berkontribusi dalam jumlah berapa pun, kapan saja. Prompt donasi muncul di momen yang wajar — setelah mendaftar, setelah membuat laporan atau sertifikat, setelah menyelesaikan pertukaran koleksi — dibingkai tanpa tekanan: *"Curatorian gratis dan akan tetap gratis. Kalau mau bantu operasional, boleh donasi seiklasnya."* Kontributor mendapat lencana pendukung di profil mereka dan terdaftar secara publik di halaman pendukung Curatorian.

**Untuk organisasi yang memberikan kontribusi lebih besar.** Organisasi — perusahaan, yayasan, instansi pemerintah — yang ingin memberikan kontribusi signifikan bagi infrastruktur dan pengembangan Curatorian diakui secara publik dengan entri khusus di halaman pendukung Curatorian, menampilkan nama mereka, periode kontribusi, dan pernyataan singkat tentang mengapa mereka mendukung infrastruktur GLAM Indonesia. Ini berfungsi sebagai mekanisme transparansi CSR yang nyata: sebuah organisasi bisa menunjuk halaman pendukung Curatorian mereka sebagai bukti yang bisa diaudit atas investasi mereka dalam warisan budaya dan infrastruktur literasi komunitas Indonesia.

**Transparansi keuangan publik.** Curatorian menerbitkan dasbor operasional langsung yang menunjukkan biaya platform, apa yang telah diterima dalam kontribusi dan keanggotaan penyokong, dan bagaimana dana dialokasikan. Ini bukan persyaratan regulasi — ini adalah komitmen komunitas. Komunitas yang bisa melihat dengan tepat bagaimana kontribusinya digunakan mempercayai platform lebih dalam, dan kepercayaan itu lebih berharga dari model pendapatan apa pun.

**Lingkaran umpan balik.** Kontributor — baik donatur individual maupun anggota penyokong — diundang ke dalam hubungan yang lebih dekat dengan platform: akses awal ke fitur baru, saluran masukan langsung ke pengembang, dan pengakuan publik atas peran mereka dalam menjaga infrastruktur komunitas tetap berjalan. Inilah cara budaya kooperatif menopang dirinya: bukan melalui kewajiban, tetapi dengan membuat kontribusi terasa bermakna, terlihat, dan timbal balik.

### 8.5 Jalan Menuju Keberlanjutan

**Fase 1 — Kepercayaan komunitas terlebih dahulu.**
Semua fitur gratis. Operasional didanai oleh donasi sukarela. Tujuan fase ini adalah kepercayaan komunitas, bukan pendapatan. Basis node aktif yang puas lebih berharga pada tahap ini daripada tekanan kontribusi komersial lebih awal. Bukti sosial dalam komunitas GLAM adalah sinyal paling kuat yang tersedia.

**Fase 2 — Keanggotaan penyokong diperkenalkan.**
Begitu platform telah menunjukkan nilai nyata kepada cukup banyak node aktif, keanggotaan penyokong diperkenalkan untuk institusi komersial. Biaya acara dan lowongan kerja mulai seiring fitur-fitur tersebut diluncurkan. Pada saat ini komunitas sudah aktif sehingga institusi komersial baru melihat platform yang hidup dan legitim — bukan ruangan kosong.

**Fase 3 — Marketplace dan kedalaman.**
Komisi marketplace freelance menjadi sumber pendapatan yang signifikan. Kontribusi keanggotaan penyokong dan donasi tumbuh seiring komunitas. Pendapatan marketplace tumbuh dengan aktivitas jaringan. Pada titik ini platform sudah mandiri dan bisa berinvestasi dalam pertumbuhan dan fitur yang lebih dalam tanpa tekanan finansial mengkompromikan nilai-nilai komunitas.

Model ini dirancang untuk mencapai keberlanjutan operasional sebelum membutuhkan pendanaan luar yang signifikan. Kombinasi donasi sukarela, keanggotaan penyokong dari institusi komersial, dan pada akhirnya komisi marketplace menciptakan basis yang terdiversifikasi yang tidak bisa digoyahkan oleh satu kontributor — dan itulah ketahanan yang dibutuhkan infrastruktur komunitas.

---

## 9. Lanskap Kompetitif

### Alat yang Digunakan Orang Saat Ini

**Sistem manajemen perpustakaan Indonesia yang ada** — paling menonjol SLiMS (Senayan Library Management System) — adalah solusi yang paling dominan di perpustakaan sekolah dan akademik Indonesia. Fungsional, gratis, dan dikenal luas di komunitas pustakawan. Keterbatasan kritis: harus di-host sendiri. Tidak ada versi cloud. Menginstalnya membutuhkan konfigurasi web server, database, dan stack aplikasi yang harus dipasang dan dirawat secara lokal. Bagi pengelola TBM atau pustakawan sekolah tanpa dukungan IT, ini adalah hambatan yang tidak bisa diatasi. Sistem-sistem ini juga tidak punya lapisan komunitas, tidak ada mekanisme penemuan publik, dan tidak ada jalan untuk menjadi sesuatu selain sistem katalog.

Bahkan untuk institusi yang punya kapasitas teknis untuk menjalankannya, sistem self-hosted menimbulkan masalah struktural yang lebih dalam di lingkungan dengan operasional yang kompleks dan terdistribusi — seperti universitas dengan banyak fakultas, masing-masing dengan perpustakaannya sendiri, stafnya sendiri, dan konvensi katalogisasinya sendiri. Setiap fakultas memasang dan mengelola database independennya masing-masing. Hasilnya adalah fragmentasi: judul yang sama dikatalogisasi secara terpisah di puluhan instance, tidak ada katalog bersama, tidak ada tampilan manajemen terpadu, dan tidak ada cara untuk memahami koleksi secara keseluruhan. Inilah pengalaman langsung yang mendorong pembangunan sistem terpadu yang kini mendasari Curatorian — dua puluh database terpisah di Unpad, masing-masing secara teknis fungsional secara sendiri-sendiri, tidak ada yang terhubung, dan pengetahuan institusional terkunci di dalam masing-masing. Arsitektur berbasis node — di mana setiap fakultas atau unit beroperasi secara mandiri dalam satu sistem yang terintegrasi — adalah jawaban struktural atas fragmentasi ini. Itulah prinsip yang dibawa Curatorian ke setiap institusi yang bergabung.

**Produk SaaS dari luar negeri** seperti LibraryThing, TinyCat, dan Koha Cloud melayani pasar mereka dengan baik. Harganya untuk pasar Barat, antarmukanya dalam bahasa Inggris, dirancang untuk jenis koleksi dan konvensi katalogisasi Barat, dan dibangun tanpa konteks Indonesia. Tidak menerima QRIS atau transfer bank. Tidak punya komunitas untuk praktisi Indonesia. Dan mereka tidak akan membangunnya untuk pasar yang tidak mereka prioritaskan. Pasar yang mereka layani dan pasar yang Curatorian layani hampir tidak tumpang tindih.

**Alat dan platform lokal yang lebih baru** adalah kompetitor yang sah untuk katalogisasi dasar di beberapa segmen. Respons terhadap persaingan ini bukan perlombaan fitur — melainkan kedalaman platform yang tidak bisa dicapai oleh sistem katalog murni. Komunitas dengan acara, papan lowongan kerja, marketplace freelance, dan jaringan bibliografi bersama menciptakan switching cost yang jauh melampaui migrasi data.

**Spreadsheet dan grup WhatsApp** adalah status quo yang sesungguhnya bagi kebanyakan koleksi kecil di Indonesia. Merekalah produk yang paling perlu Curatorian gantikan. Pendekatannya bukan mengkritisi mereka tapi membuat transisi dari mereka selancar mungkin: import CSV menangani data spreadsheet yang sudah ada, dan alur onboarding menghasilkan katalog publik yang berfungsi dalam tiga puluh menit.

### Keunggulan Strategis

Fitur individual bisa direplikasi. Tiga hal tidak bisa direplikasi tanpa bertahun-tahun membangun komunitas:

**1. Jaringan Bibliografi Bersama.** Seiring lebih banyak institusi mengkatalogisasi koleksi mereka di Curatorian, nilai jaringan tumbuh untuk semua orang. Kompetitor yang mulai hari ini harus membangun platform dan katalog secara bersamaan. Curatorian membangun katalog sebagai produk sampingan dari membangun komunitas.

**2. Komunitas itu sendiri.** Blog yang aktif, kalender acara, papan lowongan, dan jaringan follow menciptakan alasan untuk hadir di platform yang tidak ada kaitannya dengan manajemen katalog. Berpindah berarti meninggalkan komunitas profesional, bukan sekadar memigrasikan database.

**3. Keahlian domain yang tertanam dalam produk.** Seorang pustakawan yang aktif berlatih dan membangun platform ini membuat keputusan yang luput dari pembuat yang murni teknis. Keahlian ini bukan klaim pemasaran — ini terlihat dalam setiap pilihan fitur, setiap field metadata, setiap teks antarmuka.

---

## 10. Peta Jalan Pengembangan

Peta jalan di bawah ini menggambarkan apa yang sedang dibangun, dalam urutan apa, dan mengapa. Fitur hanya dibangun ketika sinyal permintaan dikonfirmasi — baik karena merupakan fondasi platform, atau karena pengguna nyata telah memintanya. Disiplin ini bukan keterbatasan ambisi tapi perlindungan dari mode kegagalan yang umum: membangun untuk pengguna hipotetis. Sebagai proyek dengan pengembang tunggal, kecepatan setiap fase secara sengaja jujur: setiap fase ditutup ketika tujuannya benar-benar tercapai, bukan ketika tanggal kalender tiba.

### 10.1 Fase 1 — Fondasi

**Status: Sedang berlangsung.**

Tujuan fase ini adalah melengkapi produk layak minimum: kurator mana pun bisa mendaftar, mengkatalogisasi koleksi mereka, dan punya halaman publik yang berfungsi. Semua yang ada di fase ini adalah sesuatu yang pengguna nyata akan temui dalam tiga puluh menit pertama mereka.

**Manajemen koleksi** — Alur CRUD lengkap untuk item melalui dasbor Atrium, termasuk pengambilan metadata, gambar sampul, field metadata fleksibel, dan pengorganisasian koleksi.

**Sirkulasi dan manajemen anggota** — Pelacakan pinjaman, pemrosesan pengembalian, manajemen denda, dan data anggota untuk institusi yang meminjamkan kepada anggota.

**OPAC Publik** — Halaman katalog yang bisa diakses publik per node, bisa dicari, bisa dibagikan, dan bisa ditanamkan di website lain.

**Infrastruktur langganan** — Integrasi pembayaran Midtrans, tingkatan langganan, feature flags, generasi invoice, dan alur donasi sukarela.

**Infrastruktur server** — Deployment ke VPS region Jakarta dengan backup harian otomatis, rate limiting pada endpoint autentikasi, dan pemantauan error.

**Hasil akhir Fase 1:** Pengelola TBM di Bandung bisa mendaftar saat jam makan siang, mengkatalogisasi sepuluh buku pertama mereka, dan membagikan halaman katalog publik yang berfungsi ke komunitasnya — sebelum jam istirahat berakhir.

### 10.2 Fase 2 — Peluncuran Komunitas

**Tujuan: Jumlah node aktif yang bermakna, aktivitas komunitas yang nyata.**

**Alur onboarding** — Wizard pasca-pendaftaran, desain empty state yang bermakna, rangkaian email minggu pertama. Setiap node baru mendapat sambutan pribadi dari pendiri.

**Import CSV** — Migrasi dari spreadsheet dengan pemetaan kolom, pratinjau import, dan kompatibilitas dengan format yang umum digunakan.

**Analitik per node** — Dasbor penggunaan dan laporan ringkasan yang bisa diekspor untuk pelaporan akreditasi dan donatur.

**Tier berbayar Institusi** — Diluncurkan ketika node aktif gratis yang cukup telah menunjukkan nilai platform. Perbandingan fitur yang jelas, alur upgrade, dan onboarding yang dipimpin pendiri untuk pelanggan komersial pertama.

**Konten komunitas** — Publikasi rutin di blog Curatorian, jangkauan personal ke jaringan pustakawan dan TBM di Jawa Barat, keterlibatan di grup Facebook dan Telegram pustakawan Indonesia.

### 10.3 Fase 3 — Ekspansi Platform

**Tujuan: Jaringan node yang terus tumbuh, fitur platform pertama di luar manajemen koleksi.**

Fitur dalam fase ini dibatasi oleh permintaan — dibangun ketika permintaan pengguna tertentu dikonfirmasi, sesuai urutan permintaan datang.

**Platform acara dan webinar** — Dibangun ketika pengguna memintanya secara eksplisit. Manajemen siklus hidup acara lengkap dengan tiket, check-in QR, generasi sertifikat dan verifikasi, serta integrasi Zoom.

**Papan lowongan kerja** — Dibangun ketika pengguna memintanya secara eksplisit. Lowongan sektor GLAM dengan lamaran dalam platform, biaya posting untuk institusi komersial, dan posting gratis untuk nirlaba.

**Jaringan bibliografi bersama** — Ketika cukup banyak node aktif telah ikut berpartisipasi. Pencarian katalog lintas institusi dan katalogisasi salinan satu klik.

### 10.4 Fase 4 — Marketplace dan Pendalaman

**Tujuan: Jaringan node yang lebih luas, pendapatan marketplace pertama, platform mandiri secara finansial.**

**Marketplace freelance** — Ketika profil freelancer organik sudah ada dan institusi telah memposting permintaan proyek. Escrow penuh, pencocokan, konfirmasi penyelesaian, dan sistem rating.

**Pembuat pameran digital** — Ketika node museum dan galeri mulai aktif. Pembuatan dan publikasi pameran tematik.

**Penggalangan dana institusi** — Ketika jaringan TBM aktif dan ada institusi yang memintanya. Kampanye donasi dan pelacakan kemajuan.

**Manajer program membaca** — Ketika node TBM atau sekolah memintanya. Pembuatan program, log membaca, visualisasi kemajuan, dan sertifikat penyelesaian.

**Koordinasi pinjam antar perpustakaan** — Ketika cukup banyak node institusional di satu wilayah menyatakan minat.

**Akses API** — Akses integrasi pihak ketiga untuk pelanggan komersial.

**Riset ekspansi regional** — Ketika platform sudah stabil, menguntungkan, dan telah membuktikan model Indonesia. Malaysia dan Filipina adalah pasar berikutnya yang logis mengingat kedekatan bahasa dan karakteristik sektor GLAM yang serupa.

---

## 11. Bergabunglah Bersama Kami

Curatorian dibangun secara terbuka, dengan dokumentasi publik, di atas fondasi open source. Platform ini menjadi lebih kuat dengan lebih banyak perspektif, kontribusi, dan orang-orang yang peduli pada masalah yang sama.

### Untuk Kurator dan Praktisi GLAM

Daftar di `curatorian.id`. Buat node Anda. Katalogisasi item pertama. Bagikan koleksi Anda. Tulis sesuatu untuk blog komunitas. Ikuti kurator lain yang melakukan pekerjaan menarik. Ceritakan kepada kami apa yang Anda butuhkan yang belum ada di platform — setiap keputusan produk dibentuk oleh masukan pengguna nyata.

### Untuk Developer

Library inti Voile dan frontend Curatorian adalah repositori open source di GitHub. Jika Anda bekerja di Elixir, Phoenix, atau PostgreSQL dan peduli pada warisan budaya Indonesia, kami menyambut kontribusi. Mulai dari issue tracker. Baca dokumentasi teknis. Buka PR. Platform ini lebih baik untuk setiap orang terampil yang terlibat di dalamnya.

### Untuk Desainer

Sistem desain Curatorian — Voile Library (terang) dan Voile Night (gelap) — sudah terdokumentasi dan menggunakan sistem CSS custom property yang membuat kontribusi bisa dilakukan. Jika Anda berdesain di Figma atau punya pandangan tentang desain UI yang aksesibel, akademis, dan hangat untuk pasar Indonesia, hubungi kami.

### Untuk Pendidik dan Peneliti

Dosen ilmu perpustakaan dan informasi, peneliti humaniora digital, dan pendidik yang bekerja di sektor GLAM adalah mitra alami. Baik melalui kontribusi proyek mahasiswa, kolaborasi penelitian, atau adopsi institusional, ada jalan untuk keterlibatan akademis. Kami sangat tertarik pada penelitian tentang dampak platform katalogisasi komunitas terhadap akses informasi di komunitas Indonesia yang kurang terlayani.

### Untuk Institusi dan Organisasi

Jika institusi Anda mengelola koleksi — apa pun ukuran, jenis, atau anggarannya — Curatorian dibangun untuk Anda. Untuk institusi nirlaba dan komunitas, platform ini gratis dan akan tetap gratis. Untuk institusi komersial, biaya langganannya dirancang agar bisa dibenarkan dalam anggaran operasional perpustakaan yang realistis.

Jika organisasi Anda bekerja di sektor GLAM di Indonesia — asosiasi profesional seperti IPI dan ATPUSI, instansi pemerintah seperti Perpustakaan Nasional dan Dinas Perpustakaan, NGO yang bekerja di bidang literasi dan warisan budaya, atau mitra korporat yang tertarik dengan CSR dan preservasi digital — kami terbuka untuk percakapan tentang kolaborasi dan kemitraan.

---

## Kontak

**Platform:** curatorian.id
**Email:** hello@curatorian.id
**Repositori Voile:** github.com/curatorian/voile
**Repositori Curatorian:** github.com/curatorian/curatorian

---

*Whitepaper ini diterbitkan di bawah lisensi Creative Commons CC BY 4.0. Anda bebas berbagi dan mengadaptasinya dengan atribusi yang sesuai. Terakhir diperbarui: Maret 2026.*

*Curatorian adalah proyek yang terus berkembang. Dokumen ini mencerminkan platform sebagaimana adanya dan sebagaimana yang direncanakan. Umpan balik, koreksi, dan kontribusi untuk dokumen ini disambut di hello@curatorian.id.*
