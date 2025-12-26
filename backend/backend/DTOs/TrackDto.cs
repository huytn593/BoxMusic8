using System.ComponentModel.DataAnnotations;

namespace backend.DTOs
{
    #region Úp load nhạc
    public class UploadTrackRequest
    {
        [Required]
        public IFormFile File { get; set; }

        [Required]
        public string Title { get; set; }

        public string? ArtistId { get; set; }

        public string? Album { get; set; }

        public string[]? Genre { get; set; }

        public string? Cover { get; set; }
    }

    public class UploadTrackResponse
    {
        public string Id { get; set; }
        public string Filename { get; set; }
        public string Title { get; set; }
        public string? ArtistId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
    #endregion

    #region Danh sách nhạc
    public class TrackThumbnail
    {
        public string Id { get; set; }
        public bool IsPublic { get; set; }
        public string Title { get; set; }
        public string ImageBase64 { get; set; }
    }
    #endregion

    #region Phát nhạc

    public class TrackMusic
    {
        public string AudioUrl { get; set; }
    }

    public class TrackDetail
    {
        public string AudioUrl { get; set; }
        public int LikeCount { get; set; }
        public int PlayCount { get; set; }
        public bool IsPublic { get; set; }
    }
    #endregion

    #region Chi tiết nhạc
    public class TrackInfo
    {
        public string TrackId { get; set; }
        public string Title { get; set; }
        public string UploaderName { get; set; }
        public string UploaderId { get; set; }
        public string[] Genres { get; set; }
        public bool IsPublic { get; set; }
        public string ImageBase64 { get; set; }
        public DateTime LastUpdate { get; set; }
        public int PlaysCount { get; set; }
        public int LikesCount { get; set; }

    }
    #endregion

    #region Danh sách nhạc admin
    public class TrackAdminView
    {
        public string TrackId { get; set; }
        public string Title { get; set; }
        public string UploaderName { get; set; }
        public string UploaderId { get; set; }
        public string[] Genres { get; set; }
        public bool IsPublic { get; set; }
        public bool isApproved { get; set; }
        public bool isDeleted { get; set; }
        public DateTime lastUpdate { get; set; }
        public string ImageBase64 { get; set; }
    }
    #endregion
}
