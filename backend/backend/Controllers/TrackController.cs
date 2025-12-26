using backend.Interfaces;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.AspNetCore.StaticFiles;
using SharpCompress.Common;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using backend.DTOs;
using System.Linq;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TrackController : ControllerBase
    {
        private readonly ITrackService _trackService;
        private readonly ITrackRecommendationService _trackRecommendationService;
        private readonly IHistoryService _historyService;
        private readonly ITrackRepository _trackRepository;

        public TrackController(ITrackService trackService, ITrackRecommendationService trackRecommendationService, IHistoryService historyService, ITrackRepository trackRepository)
        {
            _trackService = trackService;
            _trackRecommendationService = trackRecommendationService;
            _historyService = historyService;
            _trackRepository = trackRepository;
        }

        [Authorize]
        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadTrack([FromForm] UploadTrackRequest request)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                var userRole = User.FindFirstValue(ClaimTypes.Role);

                var inserted = await _trackService.UploadTrackAsync(
                    request.File,
                    request.Title,
                    userRole == "admin" ? null : userId,
                    request.Genre,
                    request.Cover
                );

                return Ok("Đã thêm");
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception)
            {
                return StatusCode(500, new { error = "Đã xảy ra lỗi khi upload." });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetTrackById(string id)
        {
            var track = await _trackService.GetByIdAsync(id);
            if (track == null || track.IsDeleted)
                return NotFound(new { error = "Không tìm thấy bài hát." });

            return Ok(track);
        }

        [HttpGet("top-played")]
        public async Task<IActionResult> GetTopPlayedTracks()
        {
            var result = await _trackService.GetTopPlayedThumbnailsAsync();
            return Ok(result);
        }

        [HttpGet("top-like")]
        public async Task<IActionResult> GetTopLikeTracks()
        {
            var result = await _trackService.GetTopLikeThumbnailsAsync();
            return Ok(result);
        }


        [HttpGet("audio/{id}")]
        public async Task<IActionResult> GetTrackAudio(string id)
        {
            var trackDetail = await _trackService.GetMusicByIdAsync(id);
            if (trackDetail == null)
            {
                return NotFound(new Dictionary<string, string>
                {
                    { "error", "Không tìm thấy bài hát hoặc file mp3 không tồn tại." }
                });
            }


            var filePath = trackDetail.AudioUrl;
            if (!System.IO.File.Exists(filePath))
            {
                return NotFound(new Dictionary<string, string>
                {
                    { "error", "File mp3 không tồn tại." }
                });
            }

            var provider = new FileExtensionContentTypeProvider();
            if (!provider.TryGetContentType(filePath, out var contentType))
            {
                contentType = "application/octet-stream";
            }

            var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read);
            return File(stream, contentType, enableRangeProcessing: true);
        }

        [HttpGet("track-info/{id}")]
        public async Task<IActionResult> GetTrackDetail(string id)
        {
            var trackDetail = await _trackService.GetByIdAsync(id);
            if (trackDetail != null && !trackDetail.IsDeleted)
            {
                var apiAudioUrl = "http://localhost:5270/api/Track/audio/" + id;
                return Ok(new TrackDetail()
                {
                    AudioUrl = apiAudioUrl,
                    LikeCount = trackDetail.LikeCount,
                    PlayCount = trackDetail.PlayCount,
                    IsPublic = trackDetail.IsPublic,
                });
            }
            else
            {
                return Ok("Không tìm thấy nhạc");
            }
        }

        [HttpPut("play-count/{id}")]
        public async Task<IActionResult> UpdatePlayCount(string id)
        {
            var result = await _trackService.UpdatePlayCount(id);
            if (result == "Success")
            {
                return Ok(result);
            }
            else
            {
                return BadRequest(result);
            }
        }

        [HttpGet("track-detail/{id}")]
        public async Task<IActionResult> GetTrackInfomation(string id)
        {
            var result = await _trackService.GetTrackInfo(id);
            if (result == null)
            {
                return Ok("Không tìm thấy !");
            }
            else
            {
                return Ok(result);
            }
        }

        [HttpGet("all-track")]
        public async Task<IActionResult> GetAllTrack()
        {
            var result = await _trackService.GetAllTrack();
            return Ok(result);
        }

        [Authorize]
        [HttpGet("pending-count")]
        public async Task<IActionResult> GetPendingTracksCount()
        {
            var userRole = User.FindFirstValue(ClaimTypes.Role);
            if (userRole != "admin")
            {
                return Unauthorized("Chỉ admin mới có quyền xem số bài hát chờ duyệt");
            }

            var count = await _trackService.GetPendingTracksCountAsync();
            return Ok(new { count });
        }

        [HttpPut("approve/{id}")]
        public async Task<IActionResult> ApproveTrack(string id)
        {
            await _trackService.ApproveTrack(id);
            return Ok("Thành công");
        }

        [HttpPut("public/{id}")]
        public async Task<IActionResult> PublicTrack(string id)
        {
            await _trackService.ChangePublicStatus(id);
            return Ok("Thành công");
        }

        [Authorize]
        [HttpDelete("delete/{trackId}")]
        public async Task<IActionResult> DeleteTrack(string trackId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var userRole = User.FindFirstValue(ClaimTypes.Role);

            var result = await _trackService.DeleteTrack(trackId, userId, userRole);
            if (result)
            {
                return Ok("Đã xóa");
            }
            else
            {
                return Unauthorized("Không có quyền xóa nhạc này");
            }
        }

        [Authorize]
        [HttpPut("restore/{trackId}")]
        public async Task<IActionResult> RestoreTrack(string trackId)
        {
            var userRole = User.FindFirstValue(ClaimTypes.Role);
            
            // Chỉ admin mới có quyền restore
            if (userRole != "admin")
            {
                return Unauthorized("Chỉ admin mới có quyền mở khóa nhạc");
            }

            var result = await _trackService.RestoreTrack(trackId);
            if (result)
            {
                return Ok("Đã mở khóa");
            }
            else
            {
                return BadRequest("Không tìm thấy nhạc hoặc nhạc chưa bị vô hiệu hóa");
            }
        }

        [Authorize]
        [HttpGet("recommend-track/{userId}")]
        public async Task<IActionResult> GetRecommendTrack(string userId)
        {
            var histories = await _historyService.GetUserHistoriesAsync(userId);
            var historyList = histories.ToList();
            
            if (historyList.Count == 0)
            {
                // Nếu không có lịch sử, trả về top tracks
                var topTracks = await _trackService.GetTopPlayedThumbnailsAsync(20);
                return Ok(topTracks);
            }

            // Lấy TẤT CẢ trackIds từ lịch sử để loại trừ (không gợi ý lại các bài đã nghe)
            var allHistoryTrackIds = historyList
                                         .Select(h => h.trackId)
                                         .Distinct()
                                         .ToList();

            // Lấy top 10 bài đã nghe (theo thứ tự mới nhất) - sẽ hiển thị đầu tiên
            var top10HistoryTrackIds = historyList
                                         .Take(10)
                                         .Select(h => h.trackId)
                                         .ToList();

            // Lấy top 10 tracks từ lịch sử (dùng cho embedding)
            var top10TrackIds = historyList.Take(10)
                                         .Select(h => h.trackId)
                                         .ToList();

            // Tối ưu: Batch load tất cả tracks từ lịch sử thay vì loop từng cái
            var allHistoryTrackIdsList = allHistoryTrackIds.ToList();
            var allHistoryTracks = await _trackRepository.GetManyByIdsAsync(allHistoryTrackIdsList);
            var tracksDict = allHistoryTracks.ToDictionary(t => t.Id, t => t);

            // Lấy tracks có genres để phân tích
            var tracksWithGenres = allHistoryTracks
                .Where(t => t.Genres != null && t.Genres.Length > 0)
                .ToList();

            // Đếm số lần xuất hiện của mỗi genre (chỉ từ tracks có genres)
            var genreCounts = new Dictionary<string, int>();
            foreach (var track in tracksWithGenres)
            {
                if (track.Genres != null)
                {
                    foreach (var genre in track.Genres)
                    {
                        if (!string.IsNullOrEmpty(genre))
                        {
                            var genreLower = genre.ToLowerInvariant();
                            genreCounts[genreLower] = genreCounts.GetValueOrDefault(genreLower, 0) + 1;
                        }
                    }
                }
            }

            // Lấy top genres (genres xuất hiện nhiều nhất)
            var topGenres = genreCounts
                .OrderByDescending(g => g.Value)
                .Take(3) // Lấy top 3 genres
                .Select(g => g.Key)
                .ToList();

            List<string> recommendedTrackIds = new List<string>();

            // Bước 1: Thêm 10 bài đã nghe (tối đa 10 bài)
            recommendedTrackIds.AddRange(top10HistoryTrackIds.Take(10));

            // Bước 2: Gợi ý 20 bài mới theo genres (loại trừ TẤT CẢ bài đã nghe)
            List<string> newTrackIds = new List<string>();
            if (topGenres.Count > 0)
            {
                var genreBasedTracks = await _trackRepository.GetTracksByGenresAsync(
                    topGenres, 
                    limit: 20, 
                    excludeTrackIds: allHistoryTrackIds // Exclude tất cả bài đã nghe
                );
                newTrackIds.AddRange(genreBasedTracks.Select(t => t.Id));
            }

            // Bước 3: Nếu chưa đủ 20 bài mới, bổ sung bằng embedding
            if (newTrackIds.Count < 20 && top10TrackIds.Count > 0)
            {
                var embeddingBasedIds = await _trackRecommendationService.GetSimilarTrackIdsAsync(
                    top10TrackIds, 
                    20 - newTrackIds.Count
                );
                // Loại bỏ các track đã có trong genre-based và TẤT CẢ bài đã nghe
                foreach (var id in embeddingBasedIds)
                {
                    if (!newTrackIds.Contains(id) && !allHistoryTrackIds.Contains(id))
                    {
                        newTrackIds.Add(id);
                    }
                    if (newTrackIds.Count >= 20) break;
                }
            }

            // Giới hạn 20 bài mới
            newTrackIds = newTrackIds.Take(20).ToList();

            // Kết hợp: 10 bài đã nghe + 20 bài mới = 30 bài tổng cộng
            recommendedTrackIds.AddRange(newTrackIds);

            // Tổng cộng tối đa 30 bài (10 đã nghe + 20 mới)
            recommendedTrackIds = recommendedTrackIds.Take(30).ToList();

            if (recommendedTrackIds.Count == 0)
            {
                // Fallback: trả về top tracks
                var topTracks = await _trackService.GetTopPlayedThumbnailsAsync(20);
                return Ok(topTracks);
            }

            return Ok(await _trackService.GetRecommentTrack(recommendedTrackIds));
        }
    }
}
