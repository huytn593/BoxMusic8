namespace backend.DTOs
{
    public class TrackListItemDto
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string[] Genres { get; set; }
        public string CoverImage { get; set; }
        public bool IsPublic { get; set; }
        public bool IsApproved { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string ArtistId { get; set; }
        public string ArtistName { get; set; }
    }

    public class TrackSearchDto
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string ArtistName { get; set; }
        public int LikeCount { get; set; }
        public int PlayCount { get; set; }
        public bool IsPublic { get; set; }
        public string? ImageBase64 { get; set; }
        public string? AudioUrl { get; set; }
    }
}
