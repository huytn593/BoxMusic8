using backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Interfaces
{
    public interface IPlaylistRepository
    {
        Task<List<Playlist>> GetByUserIdAsync(string userId);
        Task<Playlist?> GetByIdAsync(string id);
        Task<Playlist> CreateAsync(Playlist playlist);
        Task UpdateAsync(string id, Playlist playlist);
        Task DeleteAsync(string id);
        Task<int> GetPlaylistCountByUserIdAsync(string userId);
        Task<bool> ExistsAsync(string id);
        Task<List<PlaylistTrack>> GetTracksByPlaylistIdAsync(string playlistId);
        Task<PlaylistTrack?> GetPlaylistTrackAsync(string playlistId, string trackId);
        Task AddTrackToPlaylistAsync(PlaylistTrack playlistTrack);
        Task RemoveTrackFromPlaylistAsync(string playlistId, string trackId);
        Task<int> GetTrackCountByPlaylistIdAsync(string playlistId);
        Task UpdateTrackOrderAsync(string playlistId, string trackId, int newOrder);
    }
} 