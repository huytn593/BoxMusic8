using backend.Controllers;
using backend.Models;
using backend.DTOs;

namespace backend.Interfaces
{
    public interface INotificationService
    {
        Task SendNotification(List<string> receiverId, string title, string content);
        Task<List<NotificationDto>> GetByReceiverId(string receiverId);
        Task MarkAsViewed(string id);
        Task DeleteAllOfReceiver(string receiverId);
    }
}
