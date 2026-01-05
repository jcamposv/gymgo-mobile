# GymGo Mobile

Aplicación móvil oficial de GymGo - Tu gimnasio en tu bolsillo.

## Requisitos

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- iOS 12.0+ / Android 5.0+

## Configuración

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Configurar fuentes (opcional)

Descarga la fuente Inter desde [Google Fonts](https://fonts.google.com/specimen/Inter) y colócala en `assets/fonts/`:

- Inter-Regular.ttf
- Inter-Medium.ttf
- Inter-SemiBold.ttf
- Inter-Bold.ttf

O puedes usar la fuente del sistema eliminando las referencias en `pubspec.yaml`.

### 3. Ejecutar la aplicación

```bash
# Desarrollo
flutter run

# iOS
flutter run -d ios

# Android
flutter run -d android
```

## Estructura del proyecto

```
lib/
├── core/
│   ├── config/          # Configuración (Supabase, env)
│   ├── router/          # Navegación con go_router
│   ├── theme/           # Design system (colores, tipografía)
│   └── utils/           # Utilidades generales
├── features/
│   ├── auth/            # Autenticación
│   │   ├── data/        # Repositorios
│   │   ├── domain/      # Estados y excepciones
│   │   └── presentation/
│   │       ├── providers/   # Riverpod providers
│   │       ├── screens/     # Pantallas
│   │       └── widgets/     # Widgets específicos
│   └── home/            # Dashboard principal
└── shared/
    ├── ui/
    │   ├── components/  # Componentes reutilizables
    │   └── widgets/     # Widgets compartidos
    ├── providers/       # Providers globales
    └── extensions/      # Extensiones de Dart
```

## Arquitectura

- **Estado**: Riverpod
- **Navegación**: go_router con auth guards
- **Backend**: Supabase (autenticación y datos)
- **UI**: Design system personalizado (dark theme + lime accents)

## Features implementadas

### Auth MVP
- [x] Login con email/password
- [x] Forgot Password (envío de enlace)
- [x] Reset Password
- [x] Persistencia de sesión
- [x] Auth guards en navegación
- [x] Logout

### UI Components
- [x] GymGoTextField
- [x] GymGoPasswordField
- [x] GymGoPrimaryButton / SecondaryButton / TextButton
- [x] GymGoCard / GradientCard
- [x] GymGoHeader
- [x] GymGoLogo
- [x] GymGoToast
- [x] GymGoLoading (spinner, shimmer, overlay)

## Próximas features

- [ ] Member Dashboard completo
- [ ] Workouts (rutinas)
- [ ] Measurements (medidas corporales)
- [ ] Classes (reservaciones)
- [ ] Profile (perfil de usuario)

## Deep Links (para reset password)

### iOS (Universal Links)
Configurar en `ios/Runner/Runner.entitlements`:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:your-domain.com</string>
</array>
```

### Android (App Links)
Configurar en `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="gymgo" android:host="auth" />
</intent-filter>
```

## Licencia

Propiedad de GymGo. Todos los derechos reservados.
