using backend.Interfaces;
using backend.Models;
using MongoDB.Driver;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Repositories
{
    public class PlaylistRepository : IPlaylistRepository
    {
        private readonly IMongoCollection<Playlist> _playlists;
        private readonly IMongoCollection<PlaylistTrack> _playlistTracks;

        public PlaylistRepository(IMongoDatabase database)
        {
            _playlists = database.GetCollection<Playlist>("playlists");
            _playlistTracks = database.GetCollection<PlaylistTrack>("playlist_tracks");
        }

        public async Task<List<Playlist>> GetByUserIdAsync(string userId)
        {
            return await _playlists.Find(p => p.UserId == userId).ToListAsync();
        }

        public async Task<Playlist?> GetByIdAsync(string id)
        {
            return await _playlists.Find(p => p.Id == id).FirstOrDefaultAsync();
        }

        public async Task<Playlist> CreateAsync(Playlist playlist)
        {
            await _playlists.InsertOneAsync(playlist);
            return playlist;
        }

        public async Task UpdateAsync(string id, Playlist playlist)
        {
            await _playlists.ReplaceOneAsync(p => p.Id == id, playlist);
        }

        public async Task DeleteAsync(string id)
        {
            await _playlists.DeleteOneAsync(p => p.Id == id);
            // Xóa tất cả tracks trong playlist
            await _playlistTracks.DeleteManyAsync(pt => pt.PlaylistId == id);
        }

        public async Task<int> GetPlaylistCountByUserIdAsync(string userId)
        {
            return (int)await _playlists.CountDocumentsAsync(p => p.UserId == userId);
        }

        public async Task<bool> ExistsAsync(string id)
        {
            return await _playlists.CountDocumentsAsync(p => p.Id == id) > 0;
        }

        public async Task<List<PlaylistTrack>> GetTracksByPlaylistIdAsync(string playlistId)
        {
            return await _playlistTracks.Find(pt => pt.PlaylistId == playlistId)
                .SortBy(pt => pt.Order)
                .ToListAsync();
        }

        public async Task<PlaylistTrack?> GetPlaylistTrackAsync(string playlistId, string trackId)
        {
            var id = $"{playlistId}_{trackId}";
            return await _playlistTracks.Find(pt => pt.Id == id).FirstOrDefaultAsync();
        }

        public async Task AddTrackToPlaylistAsync(PlaylistTrack playlistTrack)
        {
            playlistTrack.Id = $"{playlistTrack.PlaylistId}_{playlistTrack.TrackId}";
            
            var maxOrder = await _playlistTracks.Find(pt => pt.PlaylistId == playlistTrack.PlaylistId)
                .SortByDescending(pt => pt.Order)
                .Limit(1)
                .FirstOrDefaultAsync();
            
            playlistTrack.Order = maxOrder?.Order + 1 ?? 0;
            await _playlistTracks.InsertOneAsync(playlistTrack);
        }

        public async Task RemoveTrackFromPlaylistAsync(string playlistId, string trackId)
        {
            var id = $"{playlistId}_{trackId}";
            await _playlistTracks.DeleteOneAsync(pt => pt.Id == id);
        }

        public async Task<int> GetTrackCountByPlaylistIdAsync(string playlistId)
        {
            return (int)await _playlistTracks.CountDocumentsAsync(pt => pt.PlaylistId == playlistId);
        }

        public async Task UpdateTrackOrderAsync(string playlistId, string trackId, int newOrder)
        {
            var id = $"{playlistId}_{trackId}";
            var update = Builders<PlaylistTrack>.Update.Set(pt => pt.Order, newOrder);
            await _playlistTracks.UpdateOneAsync(pt => pt.Id == id, update);
        }
    }
} 