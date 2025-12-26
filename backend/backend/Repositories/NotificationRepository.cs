using backend.Interfaces;
using backend.Models;
using Microsoft.Extensions.Configuration;
using MongoDB.Driver;

namespace backend.Repositories
{
    public class NotificationRepository : INotificationRepository
    {
        private readonly IMongoCollection<Notifications> _notificationCollection;

        public NotificationRepository(IMongoDatabase database)
        {
            _notificationCollection = database.GetCollection<Notifications>("notifications");
        }

        public async Task<List<Notifications>> GetAllAsync()
        {
            return await _notificationCollection.Find(_ => true).ToListAsync();
        }

        public async Task<List<Notifications>> GetByReceiverIdAsync(string receiverId)
        {
            return await _notificationCollection
                .Find(n => n.ReceiverId == receiverId)
                .SortByDescending(n => n.CreateAt)
                .ToListAsync();
        }

        public async Task<Notifications?> GetByIdAsync(string id)
        {
            return await _notificationCollection.Find(n => n.Id == id).FirstOrDefaultAsync();
        }

        public async Task CreateAsync(List<Notifications> notifications)
        {
            await _notificationCollection.InsertManyAsync(notifications);
        }

        public async Task UpdateAsync(string id, Notifications updatedNotification)
        {
            await _notificationCollection.ReplaceOneAsync(n => n.Id == id, updatedNotification);
        }

        public async Task DeleteAsync(string id)
        {
            await _notificationCollection.DeleteManyAsync(n => n.ReceiverId == id);
        }

        public async Task MarkAsViewedAsync(string id)
        {
            var update = Builders<Notifications>.Update.Set(n => n.IsViewed, true);
            await _notificationCollection.UpdateOneAsync(n => n.Id == id, update);
        }
    }
}
