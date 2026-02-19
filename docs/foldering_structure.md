lib/
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── theme/
│   └── di/                 # dependency injection
│
├── core/                   # shared, reusable
│   ├── constants/
│   ├── utils/
│   ├── extensions/
│   ├── errors/
│   ├── network/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   │
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── bloc/ or provider/
│   │
│   ├── dashboard/
│   └── order/
│
└── main.dart