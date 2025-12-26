using backend.Interfaces;
using backend.Models;
using MongoDB.Driver;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.Repositories
{
    public class FavoritesRepository : IFavoritesRepository
    {
        private readonly IMongoCollection<Favorites> _favorites;

        public FavoritesRepository(IMongoDatabase database)
        {
            _favorites = database.GetCollection<Favorites>("favorites");
        }

        public async Task AddFavoriteAsync(Favorites favorite)
        {
            await _favorites.InsertOneAsync(favorite);
        }

        public async Task RemoveFavoriteAsync(string userId, string trackId)
        {
            var filter = Builders<Favorites>.Filter.Eq(f => f.UserId, userId) &
                         Builders<Favorites>.Filter.Eq(f => f.TrackId, trackId);
            await _favorites.DeleteOneAsync(filter);
        }

        public async Task<bool> IsFavoriteAsync(string userId, string trackId)
        {
            var filter = Builders<Favorites>.Filter.Eq(f => f.UserId, userId) &
                         Builders<Favorites>.Filter.Eq(f => f.TrackId, trackId);
            var count = await _favorites.CountDocumentsAsync(filter);
            return count > 0;
        }

        public async Task<List<string>> GetFavoriteTrackIdsByUserAsync(string userId)
        {
            var filter = Builders<Favorites>.Filter.Eq(f => f.UserId, userId);
            var result = await _favorites.Find(filter).ToListAsync();
            return result.Select(f => f.TrackId).ToList();
        }

        public async Task<int> GetFavoriteCountByTrackAsync(string trackId)
        {
            var filter = Builders<Favorites>.Filter.Eq(f => f.TrackId, trackId);
            return (int)await _favorites.CountDocumentsAsync(filter);
        }

        public async Task DeleteAllFavoritesByUserAsync(string userId)
        {
            var filter = Builders<Favorites>.Filter.Eq(f => f.UserId, userId);
            await _favorites.DeleteManyAsync(filter);
        }
    }
}
