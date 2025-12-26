using backend.DTOs;
using backend.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class PlaylistController : ControllerBase
    {
        private readonly IPlaylistService _playlistService;

        public PlaylistController(IPlaylistService playlistService)
        {
            _playlistService = playlistService;
        }

        // GET: api/playlist/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetUserPlaylists(string userId)
        {
            try
            {
                var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (currentUserId != userId)
                    return Forbid();

                var playlists = await _playlistService.GetUserPlaylistsAsync(userId);
                return Ok(playlists);
            }
            catch (Exception ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
        }

        // GET: api/playlist/{playlistId}
        [HttpGet("{playlistId}")]
        public async Task<IActionResult> GetPlaylistDetail(string playlistId)
        {
            try
            {
                var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                var playlist = await _playlistService.GetPlaylistDetailAsync(playlistId, currentUserId);
                
                if (playlist == null)
                    return NotFound(new ErrorResponse { Error = "Không tìm thấy playlist hoặc không có quyền truy cập." });

                return Ok(playlist);
            }
            catch (Exception ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
        }

        // POST: api/playlist
        [HttpPost]
        public async Task<IActionResult> CreatePlaylist([FromBody] CreatePlaylistRequest request)
        {
            try
            {
                var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                var playlist = await _playlistService.CreatePlaylistAsync(currentUserId, request);
                return CreatedAtAction(nameof(GetPlaylistDetail), new { playlistId = playlist.Id }, playlist);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ErrorResponse { Error = "Đã xảy ra lỗi khi tạo playlist." });
            }
        }

        // PUT: api/playlist/{playlistId}
        [HttpPut("{playlistId}")]
        public async Task<IActionResult> UpdatePlaylist(string playlistId, [FromBody] UpdatePlaylistRequest request)
        {
            try
            {
                var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                var playlist = await _playlistService.UpdatePlaylistAsync(playlistId, currentUserId, request);
                return Ok(playlist);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ErrorResponse { Error = "Đã xảy ra lỗi khi cập nhật playlist." });
            }
        }

        // DELETE: api/playlist/{playlistId}
        [HttpDelete("{playlistId}")]
        public async Task<IActionResult> DeletePlaylist(string playlistId)
        {
            try
            {
                var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                await _playlistService.DeletePlaylistAsync(playlistId, currentUserId);
                return Ok(new MessageResponse { Message = "Đã xóa playlist thành công." });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ErrorResponse { Error = "Đã xảy ra lỗi khi xóa playlist." });
            }
        }

        // POST: api/playlist/{playlistId}/tracks
        [HttpPost("{playlistId}/tracks")]
        public async Task<IActionResult> AddTrackToPlaylist(string playlistId, [FromBody] AddTrackToPlaylistRequest request)
        {
            try
            {
                var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                await _playlistService.AddTrackToPlaylistAsync(playlistId, currentUserId, request.TrackId);
                return Ok(new MessageResponse { Message = "Đã thêm bài hát vào playlist thành công." });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ErrorResponse { Error = "Đã xảy ra lỗi khi thêm bài hát vào playlist." });
            }
        }

        // DELETE: api/playlist/{playlistId}/tracks/{trackId}
        [HttpDelete("{playlistId}/tracks/{trackId}")]
        public async Task<IActionResult> RemoveTrackFromPlaylist(string playlistId, string trackId)
        {
            try
            {
                var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                await _playlistService.RemoveTrackFromPlaylistAsync(playlistId, currentUserId, trackId);
                return Ok(new MessageResponse { Message = "Đã xóa bài hát khỏi playlist thành công." });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ErrorResponse { Error = "Đã xảy ra lỗi khi xóa bài hát khỏi playlist." });
            }
        }

        // GET: api/playlist/limits/{userId}
        [HttpGet("limits/{userId}")]
        public async Task<IActionResult> GetUserPlaylistLimits(string userId)
        {
            try
            {
                var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (currentUserId != userId)
                    return Forbid();

                var limits = await _playlistService.GetUserPlaylistLimitsAsync(userId);
                return Ok(limits);
            }
            catch (Exception ex)
            {
                return BadRequest(new ErrorResponse { Error = ex.Message });
            }
        }
    }    
} 