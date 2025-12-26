using backend.Controllers;
using backend.Interfaces;
using backend.Models;
using backend.DTOs;
using Microsoft.AspNetCore.SignalR;
using backend.Hubs;


namespace backend.Services
{
    public class NotificationService : INotificationService
    {
        private readonly INotificationRepository _repository;
        private readonly IHubContext<NotificationHub> _hubContext;

        public NotificationService(INotificationRepository repository, IHubContext<NotificationHub> hubContext)
        {
            _repository = repository;
            _hubContext = hubContext;
        }

        public async Task SendNotification(List<string> receiverIds, string title, string content)
        {
            var notifications = receiverIds.Select(id => new Notifications
            {
                ReceiverId = id,
                Title = title,
                Content = content,
                IsViewed = false,
                CreateAt = DateTime.UtcNow
            }).ToList();

            await _repository.CreateAsync(notifications);

            // Gửi real-time notification qua SignalR
            foreach (var notification in notifications)
            {
                var notificationDto = new NotificationDto
                {
                    Id = notification.Id.ToString(),
                    ReceiverId = notification.ReceiverId,
                    Title = notification.Title,
                    Content = notification.Content,
                    IsViewed = notification.IsViewed,
                    CreateAt = notification.CreateAt
                };

                await _hubContext.Clients.Group($"user_{notification.ReceiverId}")
                    .SendAsync("ReceiveNotification", notificationDto);
            }
        }

        public async Task<List<NotificationDto>> GetByReceiverId(string receiverId)
        {
            var list = await _repository.GetByReceiverIdAsync(receiverId);

            return list.Select(n => new NotificationDto
            {
                Id = n.Id.ToString(),
                ReceiverId = n.ReceiverId,
                Title = n.Title,
                Content = n.Content,
                IsViewed = n.IsViewed,
                CreateAt = n.CreateAt
            }).ToList();
        }


        public async Task MarkAsViewed(string id)
        {
            await _repository.MarkAsViewedAsync(id);
        }

        public async Task DeleteAllOfReceiver(string receiverId)
        {
            var notifications = await _repository.GetByReceiverIdAsync(receiverId);
            var tasks = notifications.Select(n => _repository.DeleteAsync(n.Id));
            await Task.WhenAll(tasks);
        }
    }
}
