using backend.Controllers;
using backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using backend.DTOs;

namespace backend.Interfaces
{
    public interface IHistoryService
    {
        Task<IEnumerable<HistoryTrackResponse>> GetUserHistoriesAsync(string userId);
        Task UpdatePlayHistoryAsync(string userId, string trackId);
        Task DeleteHistoryAsync(string userId, string trackId);
        Task DeleteAll(string userId);
    }
}
