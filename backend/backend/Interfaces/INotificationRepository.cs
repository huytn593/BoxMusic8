using backend.Models;

namespace backend.Interfaces
{
    public interface INotificationRepository
    {
        Task<List<Notifications>> GetAllAsync();
        Task<List<Notifications>> GetByReceiverIdAsync(string receiverId);
        Task<Notifications?> GetByIdAsync(string id);
        Task CreateAsync(List<Notifications> notifications);
        Task UpdateAsync(string id, Notifications updatedNotification);
        Task DeleteAsync(string id);
        Task MarkAsViewedAsync(string id);
    }
}
