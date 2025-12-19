# Dokumentasi Struktur Database

## Lokasi File Database

Semua definisi tabel database terletak di folder:
```
lib/database/
```

### File Utama

| File | Deskripsi |
|------|-----------|
| [database.dart](../lib/database/database.dart) | File utama yang mendefinisikan semua tabel dan konfigurasi Drift Database |
| [database.g.dart](../lib/database/database.g.dart) | File generated oleh Drift (auto-generated) |

---

## Daftar Tabel Database

### 1. **Users** (Tabel Pengguna)
**Lokasi:** [database.dart](../lib/database/database.dart#L14-L22)

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `id` | INTEGER | Primary Key, Auto Increment |
| `fullName` | TEXT (1-255) | Nama lengkap pengguna |
| `email` | TEXT (1-255) | Email unik pengguna |
| `phoneNumber` | TEXT (6-14) | Nomor telepon |
| `password` | TEXT (min 8) | Password (hashed dengan SHA256) |
| `storeName` | TEXT (1-255) | Nama toko (untuk seller) |
| `createdAt` | DATETIME | Tanggal pembuatan akun |

**DAO:** [user_dao.dart](../lib/database/user_dao.dart)

---

### 2. **Stores** (Tabel Toko)
**Lokasi:** [database.dart](../lib/database/database.dart#L25-L31)

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `id` | INTEGER | Primary Key, Auto Increment |
| `storeName` | TEXT (1-255) | Nama toko |
| `description` | TEXT | Deskripsi toko (nullable) |
| `ownerId` | INTEGER | Foreign Key ke Users (CASCADE DELETE) |
| `createdAt` | DATETIME | Tanggal pembuatan toko |

**DAO:** [store_dao.dart](../lib/database/store_dao.dart)

---

### 3. **Products** (Tabel Produk)
**Lokasi:** [database.dart](../lib/database/database.dart#L34-L47)

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `id` | INTEGER | Primary Key, Auto Increment |
| `name` | TEXT (1-255) | Nama produk |
| `model` | TEXT (1-255) | Model produk |
| `price` | REAL | Harga produk |
| `imagePath` | TEXT | Path atau URL gambar |
| `description` | TEXT | Deskripsi produk |
| `soldCount` | INTEGER | Jumlah terjual (default: 0) |
| `stock` | INTEGER | Stok produk (default: 0) |
| `category` | TEXT (1-100) | Kategori produk |
| `storeId` | INTEGER | Foreign Key ke Stores (CASCADE DELETE) |
| `createdAt` | DATETIME | Tanggal pembuatan produk |

**DAO:** [product_dao.dart](../lib/database/product_dao.dart)

---

### 4. **CartItems** (Tabel Keranjang Belanja)
**Lokasi:** [database.dart](../lib/database/database.dart#L50-L61)

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `id` | INTEGER | Primary Key, Auto Increment |
| `userId` | INTEGER | Foreign Key ke Users (CASCADE DELETE) |
| `productId` | INTEGER | Foreign Key ke Products (CASCADE DELETE) |
| `quantity` | INTEGER | Jumlah item (default: 1) |
| `addedAt` | DATETIME | Tanggal ditambahkan ke keranjang |

**Unique Constraint:** Kombinasi `userId` dan `productId` harus unik

**DAO:** [cart_dao.dart](../lib/database/cart_dao.dart)

---

### 5. **Wishlists** (Tabel Daftar Keinginan)
**Lokasi:** [database.dart](../lib/database/database.dart#L64-L75)

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `id` | INTEGER | Primary Key, Auto Increment |
| `userId` | INTEGER | Foreign Key ke Users (CASCADE DELETE) |
| `productId` | INTEGER | Foreign Key ke Products (CASCADE DELETE) |
| `addedAt` | DATETIME | Tanggal ditambahkan ke wishlist |

**Unique Constraint:** Kombinasi `userId` dan `productId` harus unik

**DAO:** [wishlist_dao.dart](../lib/database/wishlist_dao.dart)

---

### 6. **Addresses** (Tabel Alamat)
**Lokasi:** [database.dart](../lib/database/database.dart#L78-L93)

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `id` | INTEGER | Primary Key, Auto Increment |
| `userId` | INTEGER | Foreign Key ke Users (CASCADE DELETE) |
| `recipientName` | TEXT (1-255) | Nama penerima |
| `phoneNumber` | TEXT (6-20) | Nomor telepon penerima |
| `province` | TEXT (1-100) | Provinsi |
| `city` | TEXT (1-100) | Kota/Kabupaten |
| `district` | TEXT (1-100) | Kecamatan |
| `postalCode` | TEXT (1-10) | Kode pos |
| `streetAddress` | TEXT | Nama jalan, gedung, nomor rumah |
| `detailAddress` | TEXT | Detail alamat (nullable) |
| `isMainAddress` | BOOLEAN | Apakah alamat utama (default: false) |
| `isStoreAddress` | BOOLEAN | Apakah alamat toko (default: false) |
| `createdAt` | DATETIME | Tanggal pembuatan alamat |

**DAO:** [address_dao.dart](../lib/database/address_dao.dart)

---

### 7. **Orders** (Tabel Pesanan)
**Lokasi:** [database.dart](../lib/database/database.dart#L96-L112)

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `id` | INTEGER | Primary Key, Auto Increment |
| `buyerId` | INTEGER | Foreign Key ke Users (pembeli) |
| `sellerId` | INTEGER | Foreign Key ke Users (penjual) |
| `productId` | INTEGER | Foreign Key ke Products |
| `quantity` | INTEGER | Jumlah item yang dibeli |
| `priceAtPurchase` | REAL | Harga saat pembelian |
| `shippingType` | TEXT | Jenis pengiriman (e.g., "Reguler - JNE") |
| `status` | TEXT | Status pesanan (payment/packing/delivery/finished) |
| `paymentDeadline` | DATETIME | Batas waktu pembayaran (nullable) |
| `orderedAt` | DATETIME | Tanggal pemesanan |
| `paidAt` | DATETIME | Tanggal pembayaran (nullable) |
| `deliveredAt` | DATETIME | Tanggal pengiriman (nullable) |
| `finishedAt` | DATETIME | Tanggal selesai (nullable) |

**DAO:** [order_dao.dart](../lib/database/order_dao.dart)

---

## Entity Relationship Diagram (Relasi Tabel)

```
┌─────────────┐
│    Users    │
├─────────────┤
│ id (PK)     │───────┬──────────────────────────────────────────┐
│ fullName    │       │                                          │
│ email       │       │                                          │
│ phoneNumber │       │                                          │
│ password    │       │                                          │
│ storeName   │       │                                          │
│ createdAt   │       │                                          │
└─────────────┘       │                                          │
       │              │                                          │
       │ 1:N          │ 1:N                                      │
       ▼              │                                          │
┌─────────────┐       │                                          │
│   Stores    │       │                                          │
├─────────────┤       │                                          │
│ id (PK)     │───────│────────────────┐                         │
│ storeName   │       │                │                         │
│ description │       │                │                         │
│ ownerId(FK) │◄──────┘                │                         │
│ createdAt   │                        │                         │
└─────────────┘                        │                         │
                                       │ 1:N                     │
                                       ▼                         │
┌─────────────┐                ┌─────────────┐                   │
│  CartItems  │                │  Products   │                   │
├─────────────┤                ├─────────────┤                   │
│ id (PK)     │                │ id (PK)     │                   │
│ userId(FK)  │◄───────────────│ name        │                   │
│ productId   │◄───────────────│ model       │                   │
│ quantity    │                │ price       │                   │
│ addedAt     │                │ imagePath   │                   │
└─────────────┘                │ description │                   │
                               │ soldCount   │                   │
┌─────────────┐                │ stock       │                   │
│  Wishlists  │                │ category    │                   │
├─────────────┤                │ storeId(FK) │◄──────────────────│
│ id (PK)     │                │ createdAt   │                   │
│ userId(FK)  │◄───────────────└─────────────┘                   │
│ productId   │◄───────────────        │                         │
│ addedAt     │                        │                         │
└─────────────┘                        │                         │
                                       │                         │
┌─────────────┐                        │                         │
│ Addresses   │                ┌───────┴───────┐                 │
├─────────────┤                │    Orders     │                 │
│ id (PK)     │                ├───────────────┤                 │
│ userId(FK)  │◄───────────────│ id (PK)       │                 │
│ recipientNm │                │ buyerId(FK)   │◄────────────────┘
│ phoneNumber │                │ sellerId(FK)  │◄────────────────┐
│ province    │                │ productId(FK) │◄────────────────│
│ city        │                │ quantity      │                 │
│ district    │                │ priceAtPurch  │                 │
│ postalCode  │                │ shippingType  │                 │
│ streetAddr  │                │ status        │                 │
│ detailAddr  │                │ paymentDline  │                 │
│ isMainAddr  │                │ orderedAt     │                 │
│ isStoreAddr │                │ paidAt        │                 │
│ createdAt   │                │ deliveredAt   │                 │
└─────────────┘                │ finishedAt    │                 │
                               └───────────────┘                 │
                                                                 │
                               (buyerId, sellerId -> Users.id) ──┘
```

---

## Schema Version History

| Versi | Perubahan |
|-------|-----------|
| 1 | Initial schema dengan Users |
| 2 | Menambahkan tabel Stores |
| 3 | - |
| 4 | Menambahkan tabel Wishlists |
| 5 | Menambahkan tabel Addresses |
| 6 | Menambahkan tabel Orders |

---

## Helper Classes

### CartItemWithProduct
**Lokasi:** [database.dart](../lib/database/database.dart#L115-L122)

Digunakan untuk mengembalikan data keranjang beserta detail produknya.

```dart
class CartItemWithProduct {
  final CartItem cartItem;
  final Product product;
}
```

### OrderWithDetails
**Lokasi:** [order_dao.dart](../lib/database/order_dao.dart#L3-L15)

Digunakan untuk mengembalikan data pesanan beserta detail produk dan toko.

```dart
class OrderWithDetails {
  final Order order;
  final Product product;
  final String storeName;
  final String buyerName;
}
```
