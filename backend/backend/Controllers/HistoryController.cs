using backend.Interfaces;
using backend.Models;
using backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Security.Claims;
using System.Threading.Tasks;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HistoryController : ControllerBase
    {
        private readonly IHistoryService _historyService;

        public HistoryController(IHistoryService historyService)
        {
            _historyService = historyService;
        }

        [Authorize]
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetUserHistories(string userId)
        {
            var histories = await _historyService.GetUserHistoriesAsync(userId);
            return Ok(histories);
        }

        [Authorize]
        [HttpPost("play/{trackId}")]
        public async Task<IActionResult> UpdatePlay(string trackId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId))
                return Unauthorized("User not authenticated");

            await _historyService.UpdatePlayHistoryAsync(userId, trackId);
            return Ok("Play history updated");
        }


        [Authorize]
        [HttpDelete("delete/{trackId}")]
        public async Task<IActionResult> DeleteHistory(string trackId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            await _historyService.DeleteHistoryAsync(userId, trackId);
            return Ok("History deleted");
        }

        [Authorize]
        [HttpDelete("delete-all")]
        public async Task<IActionResult> DeleteAllHistory()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            await _historyService.DeleteAll(userId);
            return Ok("History deleted");
        }
    }
}
