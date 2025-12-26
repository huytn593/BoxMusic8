using backend.Interfaces;
using backend.Models;
using Microsoft.Extensions.Configuration;
using MongoDB.Driver;
using System.Collections.Generic;
using System.Threading.Tasks;
using backend.Controllers;

namespace backend.Repositories
{
    public class HistoryRepository : IHistoryRepository
    {
        private readonly IMongoCollection<Histories> _collection;
        private readonly IMongoCollection<Track> _trackCollection;

        public HistoryRepository(IMongoDatabase database)
        {
            _collection = database.GetCollection<Histories>("histories");
            _trackCollection = database.GetCollection<Track>("tracks");
        }

        public async Task<IEnumerable<Histories>> GetAllAsync()
        {
            return await _collection.Find(_ => true).ToListAsync();
        }

        public async Task<IEnumerable<Histories>> GetByUserIdAsync(string userId)
        {
            return await _collection
                .Find(h => h.UserId == userId)
                .SortByDescending(h => h.LastPlay)
                .ToListAsync();
        }

        public async Task AddOrUpdateAsync(Histories history)
        {
            var filter = Builders<Histories>.Filter.Eq(h => h.Id, history.Id);
            var update = Builders<Histories>.Update
                .Set(h => h.LastPlay, history.LastPlay)
                .SetOnInsert(h => h.UserId, history.UserId)
                .SetOnInsert(h => h.TrackId, history.TrackId);

            await _collection.UpdateOneAsync(filter, update, new UpdateOptions { IsUpsert = true });
        }

        public async Task DeleteAsync(string userId, string trackId)
        {
            var id = $"{userId}_{trackId}";
            await _collection.DeleteOneAsync(h => h.Id == id);
        }

        public async Task DeleteAllAsync(string userId)
        {
            await _collection.DeleteManyAsync(h => h.UserId == userId);
        }
    }
}
