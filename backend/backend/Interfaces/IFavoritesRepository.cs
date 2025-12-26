using backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Interfaces
{
    public interface IFavoritesRepository
    {
        Task AddFavoriteAsync(Favorites favorite);
        Task RemoveFavoriteAsync(string userId, string trackId);
        Task<bool> IsFavoriteAsync(string userId, string trackId);
        Task<List<string>> GetFavoriteTrackIdsByUserAsync(string userId);
        Task<int> GetFavoriteCountByTrackAsync(string trackId);
        Task DeleteAllFavoritesByUserAsync(string userId);
    }
}
