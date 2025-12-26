namespace backend.DTOs
{
    public class PlaylistDto
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string? Cover { get; set; }
        public string? Description { get; set; }
        public bool IsPublic { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public int TrackCount { get; set; }
        public string? ImageBase64 { get; set; }
    }

    public class PlaylistDetailDto
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string? Cover { get; set; }
        public string? Description { get; set; }
        public bool IsPublic { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string? ImageBase64 { get; set; }
        public string UserId { get; set; }
        public List<PlaylistTrackDto> Tracks { get; set; } = new List<PlaylistTrackDto>();
    }

    public class PlaylistTrackDto
    {
        public string TrackId { get; set; }
        public string Title { get; set; }
        public string? ArtistName { get; set; }
        public string? ArtistId { get; set; }
        public bool IsPublic { get; set; }
        public string? ImageBase64 { get; set; }
        public DateTime AddedAt { get; set; }
        public int Order { get; set; }
    }

    public class CreatePlaylistRequest
    {
        public string Name { get; set; }
        public string? Description { get; set; }
        public bool IsPublic { get; set; } = true;
        public string? Cover { get; set; }
    }

    public class UpdatePlaylistRequest
    {
        public string Name { get; set; }
        public string? Description { get; set; }
        public bool IsPublic { get; set; }
        public string? Cover { get; set; }
    }

    public class AddTrackToPlaylistRequest
    {
        public string TrackId { get; set; }
    }

    public class UserPlaylistLimits
    {
        public int MaxPlaylists { get; set; }
        public int MaxTracksPerPlaylist { get; set; }
        public int CurrentPlaylists { get; set; }
        public string UserRole { get; set; }
    }

    #region Response Models
    public class ErrorResponse
    {
        public string Error { get; set; } = string.Empty;
    }

    public class MessageResponse
    {
        public string Message { get; set; } = string.Empty;
    }
    #endregion
}