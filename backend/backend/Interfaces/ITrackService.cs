using backend.Controllers;
using backend.Models;
using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;
using backend.DTOs;

namespace backend.Interfaces
{
    public interface ITrackService
    {
        Task<Track> UploadTrackAsync(IFormFile file, string title, string? artistId, string[]? genre, string? cover);
        Task<List<TrackAdminView>> GetAllTrack();
        Task<Track?> GetByIdAsync(string id);
        Task<List<TrackThumbnail>> GetTopPlayedThumbnailsAsync(int limit = 20);
        Task<List<TrackThumbnail>> GetTopLikeThumbnailsAsync(int limit = 20);
        Task<List<TrackThumbnail>> GetRecommentTrack(List<string?> trackIds);
        Task<TrackMusic> GetMusicByIdAsync(string id);
        Task<string> UpdatePlayCount(string id);
        Task<TrackInfo> GetTrackInfo(string id);
        Task<List<Track>> GetTracksByArtistIdAsync(string artistId);
        Task<UserTracksResponse> GetUserTracksResponseAsync(string profileId);
        Task ApproveTrack(string id);
        Task ChangePublicStatus(string id);
        Task<bool> DeleteTrack(string trackId, string userId, string role);
        Task<bool> RestoreTrack(string trackId);
        Task<int> GetPendingTracksCountAsync();
    }
}
