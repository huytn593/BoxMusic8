namespace backend.DTOs
{
    public class CommentDetail
    {
        public string CommentId { get; set; }
        public string UserId { get; set; }
        public string UserName { get; set; }
        public string ImageBase64 { get; set; }
        public string Contents { get; set; }
        public DateTime CreateAt { get; set; }
    }

    public class AddCommentRequest
    {
        public string TrackId { get; set; }
        public string Content { get; set; }
    }
}
