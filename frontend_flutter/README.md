# MusicBox Flutter App

Ứng dụng nghe nhạc MusicBox được migrate từ React sang Flutter/Dart để chạy trên Android.

## Cấu hình IP và Port

### File cấu hình: `config.dev.json`

File này cho phép mỗi developer dễ dàng đổi IP và port của backend:

```json
{
  "API_HOST": "172.20.10.2",
  "API_PORT": "5270",
  "SWAGGER_URL": "http://172.20.10.2:5270/swagger/index.html",
  "USE_EMULATOR": false,
  "EMULATOR_HOST": "10.0.2.2"
}
```

**Để đổi IP/Port:**
1. Mở file `config.dev.json`
2. Thay đổi `API_HOST` và `API_PORT` theo IP và port của bạn
3. Cập nhật `SWAGGER_URL` tương ứng
4. Lưu file và chạy lại app

**Lưu ý quan trọng về USE_EMULATOR:**
- **KHÔNG CẦN** sửa `USE_EMULATOR` trong file config mỗi lần đổi giữa emulator và device thật
- Scripts tự động set `USE_EMULATOR` qua `--dart-define`:
  - `run_emulator.bat` → tự động set `USE_EMULATOR=true`
  - `run_device.bat` → tự động set `USE_EMULATOR=false`
- Chỉ cần chạy đúng script tương ứng:
  - Emulator: chạy `run_emulator.bat`
  - Device thật: chạy `run_device.bat`

### Default Config

Default config được set trong `lib/src/core/config/config_service.dart`:
- Default IP: `172.20.10.2`
- Default Port: `5270`

## Chạy ứng dụng

### Trên Android Emulator

**Cách đơn giản nhất (khuyến nghị):**
```bash
run_emulator.bat
```

Script này tự động:
- Set `USE_EMULATOR=true` (không cần sửa file config)
- Set port 5270
- Emulator sẽ tự động dùng `10.0.2.2` để truy cập localhost của máy host

**Chạy thủ công (nếu cần):**
```bash
flutter run --dart-define=USE_EMULATOR=true --dart-define=API_PORT=5270
```

### Trên Android Device thật (USB)

**Cách đơn giản nhất (khuyến nghị):**
```bash
run_device.bat
```

Script này tự động:
- Set `USE_EMULATOR=false` (không cần sửa file config)
- Setup ADB reverse port forwarding (port 5270)
- Set IP và port từ config
- Chạy Flutter app với config cho device thật

**Chạy thủ công (nếu cần):**
```bash
adb reverse tcp:5270 tcp:5270
flutter run --dart-define=API_HOST=172.20.10.2 --dart-define=API_PORT=5270 --dart-define=USE_EMULATOR=false
```

**Lưu ý:** 
- Đảm bảo device và máy tính cùng mạng WiFi, hoặc dùng ADB reverse port forwarding
- **KHÔNG CẦN** sửa file `config.dev.json` mỗi lần đổi giữa emulator và device - scripts tự động xử lý

## Tính năng đã migrate

### Authentication
- ✅ Đăng nhập / Đăng ký
- ✅ Quên mật khẩu / Reset mật khẩu
- ✅ OTP verification
- ✅ JWT token management
- ✅ Session timeout handling

### Music Player
- ✅ Play/Pause/Next/Previous
- ✅ Playlist management
- ✅ History tracking
- ✅ Play count tracking
- ✅ VIP track access control

### Tracks
- ✅ Browse tracks (Top played, Top liked)
- ✅ Track detail
- ✅ Upload track
- ✅ Track management (Admin)
- ✅ Track approval (Admin)
- ✅ Track public/private toggle
- ✅ Delete track

### Profile
- ✅ View profile
- ✅ Edit profile
- ✅ Change avatar
- ✅ Change password
- ✅ Email verification
- ✅ Address management

### Playlists
- ✅ Create playlist
- ✅ Edit playlist
- ✅ Delete playlist
- ✅ Add/Remove tracks from playlist
- ✅ Playlist limits (VIP feature)

### Favorites
- ✅ Add/Remove favorites
- ✅ View favorites list
- ✅ Delete all favorites

### Comments
- ✅ View comments
- ✅ Add comment
- ✅ Delete comment

### Followers
- ✅ Follow/Unfollow users
- ✅ View following list
- ✅ Check following status

### History
- ✅ View play history
- ✅ Delete history track
- ✅ Delete all history

### Search
- ✅ Search tracks, artists, playlists

### Notifications
- ✅ View notifications
- ✅ Mark as viewed

### Payment
- ✅ Upgrade account (VNPay)
- ✅ Payment result handling
- ✅ Revenue chart (Admin)

### Admin Features
- ✅ Track management
- ✅ Track approval
- ✅ Revenue statistics

## API Endpoints

Tất cả API endpoints được định nghĩa trong `lib/src/core/constants/api_constants.dart`.

### Storage Paths

Files được lưu trong backend storage:
- Avatars: `backend/storage/avatar`
- Cover images: `backend/storage/cover_images`
- Playlist covers: `backend/storage/playlist_cover`
- Tracks: `backend/storage/tracks`

## Cấu trúc thư mục

```
lib/
├── main.dart                    # Entry point
├── src/
│   ├── app.dart                 # App widget
│   ├── core/                    # Core utilities
│   │   ├── config/              # Configuration
│   │   ├── constants/           # API constants
│   │   ├── network/             # API client
│   │   ├── storage/             # Token storage
│   │   └── utils/               # Utilities
│   ├── data/
│   │   ├── models/              # Data models
│   │   └── repositories/        # API repository
│   ├── features/                 # Feature screens
│   │   ├── admin/               # Admin screens
│   │   ├── auth/                # Auth screens
│   │   ├── home/                 # Home screens
│   │   ├── library/              # Library screens
│   │   ├── payment/              # Payment screens
│   │   ├── profile/              # Profile screens
│   │   ├── search/               # Search screen
│   │   ├── track/                # Track detail
│   │   └── upload/               # Upload screen
│   ├── music_player/             # Music player
│   ├── router/                   # App routing
│   └── widgets/                  # Reusable widgets
```

## Dependencies

Xem `pubspec.yaml` để biết danh sách dependencies đầy đủ.

## Troubleshooting

### Không kết nối được backend

1. **Emulator:**
   - Đảm bảo `USE_EMULATOR=true`
   - Backend đang chạy trên máy host
   - Port forwarding đúng

2. **Device thật:**
   - Đảm bảo device và máy tính cùng mạng WiFi
   - Hoặc dùng ADB reverse: `adb reverse tcp:5270 tcp:5270`
   - Kiểm tra IP trong `config.dev.json`

### Lỗi authentication

- Kiểm tra token storage
- Clear app data và đăng nhập lại
- Kiểm tra backend JWT settings

### Lỗi file upload

- Kiểm tra permissions trong AndroidManifest.xml
- Kiểm tra file size limits
- Kiểm tra network connectivity

## Development Notes

- App sử dụng Riverpod cho state management
- GoRouter cho navigation
- Dio cho HTTP requests
- Just Audio cho audio playback
- SharedPreferences cho local storage
