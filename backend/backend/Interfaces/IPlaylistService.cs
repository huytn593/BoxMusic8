using backend.DTOs;
using Microsoft.AspNetCore.Http;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Interfaces
{
    public interface IPlaylistService
    {
        Task<List<PlaylistDto>> GetUserPlaylistsAsync(string userId);
        Task<PlaylistDetailDto?> GetPlaylistDetailAsync(string playlistId, string userId);
        Task<PlaylistDto> CreatePlaylistAsync(string userId, CreatePlaylistRequest request);
        Task<PlaylistDto> UpdatePlaylistAsync(string playlistId, string userId, UpdatePlaylistRequest request);
        Task DeletePlaylistAsync(string playlistId, string userId);
        Task AddTrackToPlaylistAsync(string playlistId, string userId, string trackId);
        Task RemoveTrackFromPlaylistAsync(string playlistId, string userId, string trackId);
        Task<UserPlaylistLimits> GetUserPlaylistLimitsAsync(string userId);
        Task<bool> CanAddTrackToPlaylistAsync(string playlistId, string userId, string trackId);
        Task<bool> CanCreatePlaylistAsync(string userId);
    }
} 