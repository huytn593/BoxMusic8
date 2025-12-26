namespace backend.DTOs
{

    public class HistoryTrackResponse
    {
        public string trackId { get; set; }
        public string title { get; set; }
        public bool isPublic { get; set; }
        public DateTime? lastPlay { get; set; }
        public string imageBase64 { get; set; }
    }

}
