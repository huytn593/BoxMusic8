namespace backend.DTOs
{
    public class FavoriteToggleResponse
    {
        public string TrackId { get; set; }
        public bool Favorited { get; set; }
    }

    public class FavoriteCheckResponse
    {
        public bool Favorited { get; set; }
    }

    public class FavoriteTracksResponse
    {
        public string trackId { get; set; }
        public string title { get; set; }
        public bool isPublic { get; set; }
        public string cover { get; set; }
        public string filename { get; set; }
        public string artistId { get; set; }
        public string imageBase64 { get; set; }
    }
}
