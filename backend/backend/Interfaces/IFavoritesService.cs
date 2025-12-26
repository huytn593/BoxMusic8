using backend.Controllers;
using System.Collections.Generic;
using System.Threading.Tasks;
using backend.DTOs;


namespace backend.Interfaces
{
    public interface IFavoritesService
    {
        Task<bool> ToggleFavoriteAsync(string userId, string trackId);
        Task<List<FavoriteTracksResponse>> GetFavoriteTrackByUserAsync(string userId);
        Task<bool> IsTrackFavoritedAsync(string userId, string trackId);
        Task<int> GetTrackFavoriteCountAsync(string trackId);
        Task DeleteAllFavoritesAsync(string userId);
    }
}
