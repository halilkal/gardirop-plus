# Gardırop+ DEMO (Flutter)

Bu paket **çalışan bir APK** içermez; ancak **Flutter projesi kaynak dosyalarını** içerir. 
Bu dosyaları kullanarak kendi bilgisayarınızda veya CI (GitHub Actions) ile APK üretebilirsiniz.

## İçerik
- lib/main.dart : Basit uygulama (fotoğraf ekleme, kategori seçme, basit kombin önerisi)
- pubspec.yaml : bağımlılıklar  

## Yerel olarak APK oluşturma (kısa)
1. Bilgisayarınıza Flutter kurun: https://flutter.dev
2. Terminalde proje klasörüne gidin (bu dosyaları kaydettiğiniz yer)
3. Platform dosyalarını oluşturun (sadece ilk sefer):
   ```
   flutter create .
   ```
4. Bağımlılıkları indir:
   ```
   flutter pub get
   ```
5. Android için APK üret:
   ```
   flutter build apk --release
   ```
   veya geliştirici modu için:
   ```
   flutter run
   ```

## GitHub Actions ile otomatik APK oluşturma
Repo'ya koyup `.github/workflows/android.yml` ile otomatik build ayarlayabilirsiniz.
Örnek workflow dosyası repo içinde mevcuttur.

## Notlar
- Bu demo basit bir MVP'dir. Üretim için manifest düzenlemeleri, izin izahları, proguard, imzalama ve mağaza gereksinimleri gerekir.
- iOS için TestFlight yapımı ayrı ayar gerektirir (Apple Developer hesabı).

Ben sizin için bu projeyi hazır hale getirdim. Eğer isterseniz, ben CI job'u kurma, mağaza meta verilerini hazırlama, veya tam prod yapılandırma adımlarında rehberlik ederim.
