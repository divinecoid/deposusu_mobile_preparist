# Preparist API Documentation

This documentation is intended for mobile developers implementing the Preparist application.

## Base Configuration

- **Base URL**: `http://your-api-domain.com/api`
- **Authentication**: Bearer Token (Laravel Sanctum)
- **Headers**: 
  - `Accept: application/json`
  - `Authorization: Bearer {your_token}`

---

## 1. Dashboard Performance Stats
Mengambil statistik jumlah packingan per periode waktu.

- **Method**: `GET`
- **URL**: `/preparist/dashboard`
- **Response**:
```json
{
    "success": true,
    "performance": {
        "hour": 5,    // Packing per jam ini
        "day": 20,    // Packing hari ini
        "week": 140,  // Packing minggu ini
        "month": 500  // Packing bulan ini
    }
}
```

---

## 2. Order Packing List
Mengambil daftar order berdasarkan status.

- **Method**: `GET`
- **URL**: `/preparist/orders`
- **Query Params**:
  - `status`: (Optional) `onprocess` (default) atau `onpreparation`.
- **Response**:
```json
{
    "success": true,
    "data": {
        "current_page": 1,
        "data": [
            {
                "id": 1,
                "order_number": "ORD-123",
                "customer_name": "Anto",
                "status": "onprocess",
                "items": [
                    {
                        "id": 10,
                        "product": {
                            "name": "Susu Segar 1L",
                            "price": 20000
                        },
                        "quantity": 2,
                        "subtotal": 40000
                    }
                ],
                "total_amount": 40000,
                "created_at": "2026-02-15T10:00:00.000000Z"
            }
        ],
        "last_page": 5,
        "total": 75
    }
}
```

---

## 3. Start Preparation
Mengubah status order dari `onprocess` menjadi `onpreparation`. Panggil endpoint ini saat preparist mulai menyiapkan barang.

- **Method**: `POST`
- **URL**: `/preparist/orders/{id}/start`
- **Response**:
```json
{
    "success": true,
    "message": "Preparation started.",
    "order": {
        "id": 1,
        "status": "onpreparation"
    }
}
```

---

## 4. Finish Preparation (Submit)
Mengubah status order dari `onpreparation` menjadi `prepared`. Panggil endpoint ini saat packing selesai dilakukan.

- **Method**: `POST`
- **URL**: `/preparist/orders/{id}/finish`
- **Response**:
```json
{
    "success": true,
    "message": "Order successfully prepared.",
    "order": {
        "id": 1,
        "status": "prepared"
    }
}
```

---

## Error Responses

| Code | Message | Description |
|---|---|---|
| `401` | `Unauthenticated` | Token tidak valid atau habis masa berlakunya. |
| `400` | `Invalid status filter` | Filter status yang dikirim salah. |
| `400` | `Order is not in a state to be prepared` | Status order tidak sesuai untuk aksi tersebut. |
| `403` | `You are not the assigned preparist` | Order sedang dikerjakan oleh preparist lain. |
| `404` | `Not Found` | ID Order tidak ditemukan. |
