namespace backend.DTOs
{
    public class NotificationDto
    {
        public string Id { get; set; }
        public string ReceiverId { get; set; }
        public string Title { get; set; }
        public string Content { get; set; }
        public bool IsViewed { get; set; }
        public DateTime CreateAt { get; set; }
    }
}
