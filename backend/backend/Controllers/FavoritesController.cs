using backend.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using backend.DTOs;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FavoritesController : ControllerBase
    {
        private readonly IFavoritesService _favoritesService;

        public FavoritesController(IFavoritesService favoritesService)
        {
            _favoritesService = favoritesService;
        }

        // Toggle yêu thích (like/unlike)
        [HttpPost("toggle/{trackId}")]
        public async Task<IActionResult> ToggleFavorite(string trackId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var isNowFavorited = await _favoritesService.ToggleFavoriteAsync(userId, trackId);

            var response = new FavoriteToggleResponse
            {
                TrackId = trackId,
                Favorited = isNowFavorited
            };

            return Ok(response);
        }

        // Lấy danh sách trackId mà user đã like
        [HttpGet("my-tracks")]
        public async Task<IActionResult> GetMyFavoriteTracks()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var track = await _favoritesService.GetFavoriteTrackByUserAsync(userId);

            return Ok(track);
        }

        // Kiểm tra bài hát có đang được user yêu thích không
        [HttpGet("check/{trackId}")]
        public async Task<IActionResult> CheckIfTrackIsFavorited(string trackId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var isFavorited = await _favoritesService.IsTrackFavoritedAsync(userId, trackId);

            var response = new FavoriteCheckResponse
            {
                Favorited = isFavorited
            };

            return Ok(response);
        }

        [HttpDelete("delete-all")]
        public async Task<IActionResult> DeleteAllFavorites()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();
            await _favoritesService.DeleteAllFavoritesAsync(userId);
            return Ok("All favorites deleted");
        }
    }
}
