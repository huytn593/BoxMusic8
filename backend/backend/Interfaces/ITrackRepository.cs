using backend.Models;
using MongoDB.Driver;
using System.Collections.Generic;
using System.Threading.Tasks;
using backend.Controllers;
using backend.DTOs;

namespace backend.Interfaces
{
    public interface ITrackRepository
    {
        Task<List<Track>> GetAllAsync();
        Task<List<Track>> GetNotDeletedAsync();

        Task<Track?> GetByIdAsync(string id);
        Task<List<Track>> GetByArtistIdAsync(string artistId);

        Task<List<Track>> SearchByTitleAsync(string keyword);
        Task<List<Track>> SearchByTitleOrArtistAsync(string keyword);

        Task CreateAsync(Track track);
        Task UpdateAsync(string id, Track track);
        Task DeleteAsync(string id);

        Task IncrementPlayCountAsync(string id);
        Task IncrementLikeCountAsync(string id);

        Task<List<Track>> GetTopPlayedTracksAsync(int limit = 20);
        Task<List<Track>> GetTopLikeTracksAsync(int limit = 20);
        Task<List<Track>> GetRecommendTrack(List<string?> trackIds);

        Task IncreaseLikeCountAsync(string trackId);
        Task DecreaseLikeCountAsync(string trackId);

        Task<List<Track>> GetApprovedTracksByArtistIdAsync(string artistId);

        Task<List<EmbeddingTrackDto>> GetEmbedding(List<string> ids);
        Task<List<Track>> GetAllValidWithEmbedding();
        Task<List<Track>> GetTracksByGenresAsync(List<string> genres, int limit = 20, List<string>? excludeTrackIds = null);
        Task<List<Track>> GetManyByIdsAsync(List<string> ids);

    }
}
