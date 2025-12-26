using backend.DTOs;
using backend.Interfaces;
using backend.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace backend.Services
{
    public class PlaylistService : IPlaylistService
    {
        private readonly IPlaylistRepository _playlistRepository;
        private readonly ITrackRepository _trackRepository;
        private readonly IUserRepository _userRepository;
        private readonly string _playlistCoverPath = Path.Combine(Directory.GetCurrentDirectory(), "storage", "playlist_cover");

        public PlaylistService(IPlaylistRepository playlistRepository, ITrackRepository trackRepository, IUserRepository userRepository)
        {
            _playlistRepository = playlistRepository;
            _trackRepository = trackRepository;
            _userRepository = userRepository;
            
            if (!Directory.Exists(_playlistCoverPath))
                Directory.CreateDirectory(_playlistCoverPath);
        }

        public async Task<List<PlaylistDto>> GetUserPlaylistsAsync(string userId)
        {
            var playlists = await _playlistRepository.GetByUserIdAsync(userId);
            var result = new List<PlaylistDto>();

            foreach (var playlist in playlists)
            {
                var trackCount = await _playlistRepository.GetTrackCountByPlaylistIdAsync(playlist.Id);
                string? base64Image = await GetPlaylistCoverBase64Async(playlist.Cover);

                result.Add(new PlaylistDto
                {
                    Id = playlist.Id,
                    Name = playlist.Name,
                    Cover = playlist.Cover,
                    Description = playlist.Description,
                    IsPublic = playlist.IsPublic,
                    CreatedAt = playlist.CreatedAt,
                    UpdatedAt = playlist.UpdatedAt,
                    TrackCount = trackCount,
                    ImageBase64 = base64Image
                });
            }

            return result;
        }

        public async Task<PlaylistDetailDto?> GetPlaylistDetailAsync(string playlistId, string userId)
        {
            var playlist = await _playlistRepository.GetByIdAsync(playlistId);
            if (playlist == null || (playlist.UserId != userId && !playlist.IsPublic))
                return null;

            var playlistTracks = await _playlistRepository.GetTracksByPlaylistIdAsync(playlistId);
            var tracks = new List<PlaylistTrackDto>();

            foreach (var playlistTrack in playlistTracks)
            {
                var track = await _trackRepository.GetByIdAsync(playlistTrack.TrackId);
                if (track != null)
                {
                    string? base64Image = null;
                    if (!string.IsNullOrEmpty(track.Cover))
                    {
                        var coverPath = Path.Combine(Directory.GetCurrentDirectory(), "storage", "cover_images", track.Cover);
                        if (File.Exists(coverPath))
                        {
                            var imageBytes = await File.ReadAllBytesAsync(coverPath);
                            var extension = Path.GetExtension(track.Cover).ToLower().TrimStart('.');
                            var mimeType = extension switch
                            {
                                "jpg" or "jpeg" => "image/jpeg",
                                "png" => "image/png",
                                "webp" => "image/webp",
                                _ => "application/octet-stream"
                            };
                            base64Image = $"data:{mimeType};base64,{Convert.ToBase64String(imageBytes)}";
                        }
                    }

                    // Lấy thông tin artist
                    Users? artist = null;
                    if (!string.IsNullOrEmpty(track.ArtistId))
                    {
                        artist = await _userRepository.GetByIdAsync(track.ArtistId);
                    }

                    tracks.Add(new PlaylistTrackDto
                    {
                        TrackId = track.Id,
                        Title = track.Title,
                        ArtistName = artist?.Name,
                        ArtistId = track.ArtistId,
                        IsPublic = track.IsPublic,
                        ImageBase64 = base64Image,
                        AddedAt = playlistTrack.AddedAt,
                        Order = playlistTrack.Order
                    });
                }
            }

            string? playlistCoverBase64 = await GetPlaylistCoverBase64Async(playlist.Cover);

            return new PlaylistDetailDto
            {
                Id = playlist.Id,
                Name = playlist.Name,
                Cover = playlist.Cover,
                Description = playlist.Description,
                IsPublic = playlist.IsPublic,
                CreatedAt = playlist.CreatedAt,
                UpdatedAt = playlist.UpdatedAt,
                ImageBase64 = playlistCoverBase64,
                UserId = playlist.UserId,
                Tracks = tracks
            };
        }

        public async Task<PlaylistDto> CreatePlaylistAsync(string userId, CreatePlaylistRequest request)
        {
            // Kiểm tra giới hạn playlist - kiểm tra trực tiếp để có thông báo lỗi chi tiết hơn
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null)
                throw new InvalidOperationException("Người dùng không tồn tại.");

            var currentPlaylists = await _playlistRepository.GetPlaylistCountByUserIdAsync(userId);
            var (maxPlaylists, _) = GetLimitsByRole(user.Role);

            if (currentPlaylists >= maxPlaylists)
            {
                var roleDisplay = user.Role?.ToLowerInvariant() switch
                {
                    "vip" => "VIP",
                    "premium" => "Premium",
                    "admin" => "Admin",
                    _ => "Normal"
                };
                throw new InvalidOperationException($"Bạn đã đạt giới hạn số playlist cho phép. Gói {roleDisplay} được tạo tối đa {maxPlaylists} playlists. Bạn hiện có {currentPlaylists} playlists.");
            }

            string? savedCoverFileName = null;
            if (!string.IsNullOrEmpty(request.Cover))
            {
                try
                {
                    var base64Data = request.Cover.Split(',').Last();
                    var bytes = Convert.FromBase64String(base64Data);

                    savedCoverFileName = $"{Guid.NewGuid()}.jpg";
                    var imageFullPath = Path.Combine(_playlistCoverPath, savedCoverFileName);
                    await File.WriteAllBytesAsync(imageFullPath, bytes);
                }
                catch
                {
                    throw new ArgumentException("Cover ảnh không hợp lệ.");
                }
            }
            else
            {
                // Sử dụng ảnh mặc định
                savedCoverFileName = "default-music.jpg";
            }

            var playlist = new Playlist
            {
                Name = request.Name,
                UserId = userId,
                Cover = savedCoverFileName,
                Description = request.Description,
                IsPublic = request.IsPublic,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _playlistRepository.CreateAsync(playlist);

            return new PlaylistDto
            {
                Id = playlist.Id,
                Name = playlist.Name,
                Cover = playlist.Cover,
                Description = playlist.Description,
                IsPublic = playlist.IsPublic,
                CreatedAt = playlist.CreatedAt,
                UpdatedAt = playlist.UpdatedAt,
                TrackCount = 0,
                ImageBase64 = await GetPlaylistCoverBase64Async(playlist.Cover)
            };
        }

        public async Task<PlaylistDto> UpdatePlaylistAsync(string playlistId, string userId, UpdatePlaylistRequest request)
        {
            var playlist = await _playlistRepository.GetByIdAsync(playlistId);
            if (playlist == null || playlist.UserId != userId)
                throw new InvalidOperationException("Không có quyền chỉnh sửa playlist này.");

            string? savedCoverFileName = playlist.Cover;
            if (!string.IsNullOrEmpty(request.Cover) && request.Cover != playlist.Cover)
            {
                try
                {
                    var base64Data = request.Cover.Split(',').Last();
                    var bytes = Convert.FromBase64String(base64Data);

                    savedCoverFileName = $"{Guid.NewGuid()}.jpg";
                    var imageFullPath = Path.Combine(_playlistCoverPath, savedCoverFileName);
                    await File.WriteAllBytesAsync(imageFullPath, bytes);

                    // Xóa ảnh cũ nếu không phải ảnh mặc định
                    if (playlist.Cover != "default-music.jpg")
                    {
                        var oldImagePath = Path.Combine(_playlistCoverPath, playlist.Cover);
                        if (File.Exists(oldImagePath))
                            File.Delete(oldImagePath);
                    }
                }
                catch
                {
                    throw new ArgumentException("Cover ảnh không hợp lệ.");
                }
            }

            playlist.Name = request.Name;
            playlist.Description = request.Description;
            playlist.IsPublic = request.IsPublic;
            playlist.Cover = savedCoverFileName;
            playlist.UpdatedAt = DateTime.UtcNow;

            await _playlistRepository.UpdateAsync(playlistId, playlist);

            var trackCount = await _playlistRepository.GetTrackCountByPlaylistIdAsync(playlistId);
            return new PlaylistDto
            {
                Id = playlist.Id,
                Name = playlist.Name,
                Cover = playlist.Cover,
                Description = playlist.Description,
                IsPublic = playlist.IsPublic,
                CreatedAt = playlist.CreatedAt,
                UpdatedAt = playlist.UpdatedAt,
                TrackCount = trackCount,
                ImageBase64 = await GetPlaylistCoverBase64Async(playlist.Cover)
            };
        }

        public async Task DeletePlaylistAsync(string playlistId, string userId)
        {
            var playlist = await _playlistRepository.GetByIdAsync(playlistId);
            if (playlist == null || playlist.UserId != userId)
                throw new InvalidOperationException("Không có quyền xóa playlist này.");

            // Xóa ảnh cover nếu không phải ảnh mặc định
            if (playlist.Cover != "default-music.jpg")
            {
                var imagePath = Path.Combine(_playlistCoverPath, playlist.Cover);
                if (File.Exists(imagePath))
                    File.Delete(imagePath);
            }

            await _playlistRepository.DeleteAsync(playlistId);
        }

        public async Task AddTrackToPlaylistAsync(string playlistId, string userId, string trackId)
        {
            var playlist = await _playlistRepository.GetByIdAsync(playlistId);
            if (playlist == null || playlist.UserId != userId)
                throw new InvalidOperationException("Không có quyền thêm bài hát vào playlist này.");

            if (!await CanAddTrackToPlaylistAsync(playlistId, userId, trackId))
                throw new InvalidOperationException("Vui lòng nâng cấp tài khoản !");

            var existingTrack = await _playlistRepository.GetPlaylistTrackAsync(playlistId, trackId);
            if (existingTrack != null)
                throw new InvalidOperationException("Bài hát đã có trong playlist.");

            var playlistTrack = new PlaylistTrack
            {
                PlaylistId = playlistId,
                TrackId = trackId,
                AddedAt = DateTime.UtcNow
            };

            await _playlistRepository.AddTrackToPlaylistAsync(playlistTrack);
        }

        public async Task RemoveTrackFromPlaylistAsync(string playlistId, string userId, string trackId)
        {
            var playlist = await _playlistRepository.GetByIdAsync(playlistId);
            if (playlist == null || playlist.UserId != userId)
                throw new InvalidOperationException("Không có quyền xóa bài hát khỏi playlist này.");

            await _playlistRepository.RemoveTrackFromPlaylistAsync(playlistId, trackId);
        }

        public async Task<UserPlaylistLimits> GetUserPlaylistLimitsAsync(string userId)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null)
                throw new InvalidOperationException("Người dùng không tồn tại.");

            var currentPlaylists = await _playlistRepository.GetPlaylistCountByUserIdAsync(userId);
            var (maxPlaylists, maxTracksPerPlaylist) = GetLimitsByRole(user.Role);

            return new UserPlaylistLimits
            {
                MaxPlaylists = maxPlaylists,
                MaxTracksPerPlaylist = maxTracksPerPlaylist,
                CurrentPlaylists = currentPlaylists,
                UserRole = user.Role
            };
        }

        public async Task<bool> CanAddTrackToPlaylistAsync(string playlistId, string userId, string trackId)
        {
            var playlist = await _playlistRepository.GetByIdAsync(playlistId);
            if (playlist == null || playlist.UserId != userId)
                return false;

            var track = await _trackRepository.GetByIdAsync(trackId);
            if (track == null || !track.IsApproved)
                return false;

            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null)
                return false;

            // Kiểm tra quyền truy cập bài hát theo role
            if (!CanAccessTrackByRole(user.Role, track.IsPublic))
                return false;

            // Kiểm tra giới hạn số bài hát trong playlist
            var trackCount = await _playlistRepository.GetTrackCountByPlaylistIdAsync(playlistId);
            var (_, maxTracksPerPlaylist) = GetLimitsByRole(user.Role);

            return trackCount < maxTracksPerPlaylist;
        }

        public async Task<bool> CanCreatePlaylistAsync(string userId)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null)
                return false;

            var currentPlaylists = await _playlistRepository.GetPlaylistCountByUserIdAsync(userId);
            var (maxPlaylists, _) = GetLimitsByRole(user.Role);

            // Log để debug (chỉ trong development)
            #if DEBUG
            Console.WriteLine($"[PlaylistService] User {userId} - Role: {user.Role}, Current: {currentPlaylists}, Max: {maxPlaylists}, CanCreate: {currentPlaylists < maxPlaylists}");
            #endif

            return currentPlaylists < maxPlaylists;
        }

        private (int maxPlaylists, int maxTracksPerPlaylist) GetLimitsByRole(string role)
        {
            // Chuyển role về lowercase để so sánh không phân biệt hoa thường
            var roleLower = role?.ToLowerInvariant() ?? "normal";
            
            return roleLower switch
            {
                "normal" => (5, 10), // Giới hạn 5 playlists, tối đa 10 bài hát/playlist
                "vip" => (10, 20), // Giới hạn 10 playlists, tối đa 20 bài hát/playlist
                "premium" => (int.MaxValue, int.MaxValue), // Không giới hạn playlist và bài hát
                "admin" => (int.MaxValue, int.MaxValue), // Không giới hạn
                _ => (5, 10) // Mặc định giới hạn 5 playlists, 10 bài hát/playlist (như normal)
            };
        }

        private bool CanAccessTrackByRole(string userRole, bool trackIsPublic)
        {
            // Chuyển role về lowercase để so sánh không phân biệt hoa thường
            var roleLower = userRole?.ToLowerInvariant() ?? "normal";
            
            return roleLower switch
            {
                "normal" => trackIsPublic, // Chỉ được thêm nhạc thường
                "vip" => true, // Được thêm cả nhạc thường và VIP
                "premium" => true, // Không giới hạn
                "admin" => true, // Admin có toàn quyền
                _ => trackIsPublic
            };
        }

        private async Task<string?> GetPlaylistCoverBase64Async(string? coverFileName)
        {
            if (string.IsNullOrEmpty(coverFileName))
                return null;

            var coverPath = Path.Combine(_playlistCoverPath, coverFileName);
            if (!File.Exists(coverPath))
                return null;

            try
            {
                var imageBytes = await File.ReadAllBytesAsync(coverPath);
                var extension = Path.GetExtension(coverFileName).ToLower().TrimStart('.');
                var mimeType = extension switch
                {
                    "jpg" or "jpeg" => "image/jpeg",
                    "png" => "image/png",
                    "webp" => "image/webp",
                    _ => "application/octet-stream"
                };
                return $"data:{mimeType};base64,{Convert.ToBase64String(imageBytes)}";
            }
            catch
            {
                return null;
            }
        }
    }
} 