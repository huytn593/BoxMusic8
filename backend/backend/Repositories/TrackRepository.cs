using backend.DTOs;
using backend.Interfaces;
using backend.Models;
using Microsoft.Extensions.Options;
using MongoDB.Bson;
using MongoDB.Driver;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.Repositories
{
    public class TrackRepository : ITrackRepository
    {
        private readonly IMongoCollection<Track> _tracks;

        public TrackRepository(IMongoDatabase database)
        {
            _tracks = database.GetCollection<Track>("tracks");
        }

        public async Task<List<Track>> GetAllAsync() =>
            await _tracks.Find(_ => true).ToListAsync();

        public async Task<List<Track>> GetNotDeletedAsync() =>
            await _tracks.Find(t => t.IsDeleted == false).ToListAsync();

        public async Task<Track?> GetByIdAsync(string id) =>
            await _tracks.Find(t => t.Id == id).FirstOrDefaultAsync();

        public async Task<List<Track>> GetByArtistIdAsync(string artistId) =>
            await _tracks.Find(t => t.ArtistId == artistId && t.IsApproved == true && t.IsDeleted == false).ToListAsync();


        public async Task<List<Track>> SearchByTitleAsync(string keyword) =>
            await _tracks.Find(t => t.Title.ToLower().Contains(keyword.ToLower()) && t.IsApproved == true && t.IsDeleted == false).ToListAsync();

        public async Task CreateAsync(Track track) =>
            await _tracks.InsertOneAsync(track);

        public async Task UpdateAsync(string id, Track track) =>
            await _tracks.ReplaceOneAsync(t => t.Id == id, track);

        public async Task DeleteAsync(string id)
        {
            await _tracks.DeleteOneAsync(t => t.Id == id);

        }

        public async Task IncrementPlayCountAsync(string id)
        {
            var update = Builders<Track>.Update.Inc(t => t.PlayCount, 1);
            await _tracks.UpdateOneAsync(t => t.Id == id, update);
        }

        public async Task IncrementLikeCountAsync(string id)
        {
            var update = Builders<Track>.Update.Inc(t => t.LikeCount, 1);
            await _tracks.UpdateOneAsync(t => t.Id == id, update);
        }

        public async Task<List<Track>> GetTopPlayedTracksAsync(int limit = 20)
        {
            var filter = Builders<Track>.Filter.And(
                Builders<Track>.Filter.Eq(t => t.IsApproved, true),
                Builders<Track>.Filter.Eq(t => t.IsDeleted, false)
            );
            var sort = Builders<Track>.Sort.Descending(t => t.PlayCount);
            return await _tracks.Find(filter)
                                .Sort(sort)
                                .Limit(limit)
                                .ToListAsync();
        }

        public async Task<List<Track>> GetTopLikeTracksAsync(int limit = 20)
        {
            // Tối ưu: Dùng MongoDB aggregation pipeline để filter và sort trực tiếp trong database
            // Thay vì load tất cả tracks vào memory
            var pipeline = new BsonDocument[]
            {
                // Match: chỉ lấy tracks hợp lệ và có tổng > 100
                new BsonDocument("$match", new BsonDocument
                {
                    { "is_approved", true },
                    { "is_deleted", false },
                    { "$expr", new BsonDocument("$gt", new BsonArray
                        {
                            new BsonDocument("$add", new BsonArray 
                            { 
                                "$play_count", 
                                "$like_count" 
                            }),
                            100
                        })
                    }
                }),
                // Sort theo like_count giảm dần
                new BsonDocument("$sort", new BsonDocument("like_count", -1)),
                // Limit số lượng
                new BsonDocument("$limit", limit)
            };

            var results = await _tracks.Aggregate<Track>(pipeline).ToListAsync();
            return results;
        }

        public async Task<List<Track>> GetRecommendTrack(List<string?> trackIds)
        {
            var filter = Builders<Track>.Filter.And(
                Builders<Track>.Filter.In(t => t.Id, trackIds),
                Builders<Track>.Filter.Eq(t => t.IsApproved, true),
                Builders<Track>.Filter.Eq(t => t.IsDeleted, false)
            );
            return await _tracks.Find(filter)
                                .Limit(20)
                                .ToListAsync();
        }

        public async Task IncreaseLikeCountAsync(string trackId)
        {
            var filter = Builders<Track>.Filter.Eq(t => t.Id, trackId);
            var update = Builders<Track>.Update.Inc(t => t.LikeCount, 1);
            await _tracks.UpdateOneAsync(filter, update);
        }

        public async Task DecreaseLikeCountAsync(string trackId)
        {
            var filter = Builders<Track>.Filter.Eq(t => t.Id, trackId);
            var update = Builders<Track>.Update.Inc(t => t.LikeCount, -1);
            await _tracks.UpdateOneAsync(filter, update);
        }

        public async Task<List<Track>> SearchByTitleOrArtistAsync(string keyword)
        {
            var lowerKeyword = keyword.ToLower();

            var textFilter = Builders<Track>.Filter.Or(
                Builders<Track>.Filter.Regex(t => t.Title, new MongoDB.Bson.BsonRegularExpression(lowerKeyword, "i")),
                Builders<Track>.Filter.Regex(t => t.ArtistId, new MongoDB.Bson.BsonRegularExpression(lowerKeyword, "i"))
            );

            var approvalFilter = Builders<Track>.Filter.Eq(t => t.IsApproved, true);
            var notDeletedFilter = Builders<Track>.Filter.Eq(t => t.IsDeleted, false);

            var finalFilter = Builders<Track>.Filter.And(textFilter, approvalFilter, notDeletedFilter);

            return await _tracks.Find(finalFilter).ToListAsync();
        }

        public async Task<List<Track>> GetApprovedTracksByArtistIdAsync(string artistId)
        {
            var filter = Builders<Track>.Filter.And(
                Builders<Track>.Filter.Eq(t => t.ArtistId, artistId),
                Builders<Track>.Filter.Eq(t => t.IsApproved, true),
                Builders<Track>.Filter.Eq(t => t.IsDeleted, false)
            );
            return await _tracks.Find(filter).ToListAsync();
        }

        public async Task<List<EmbeddingTrackDto>> GetEmbedding(List<string> ids)
        {
            var tracks = await _tracks
                .Find(t => ids.Contains(t.Id) && t.IsApproved == true && t.IsDeleted == false && t.Embedding != null)
                .ToListAsync();

            return tracks.Select(track => new EmbeddingTrackDto
            {
                Id = track.Id,
                Embedding = track.Embedding
            }).ToList();
        }

        public async Task<List<Track>> GetAllValidWithEmbedding()
        {
            var filter = Builders<Track>.Filter.And(
                Builders<Track>.Filter.Eq(t => t.IsApproved, true),
                Builders<Track>.Filter.Eq(t => t.IsDeleted, false),
                Builders<Track>.Filter.Ne(t => t.Embedding, null),
                Builders<Track>.Filter.Exists(t => t.Embedding, true)
            );

            return await _tracks.Find(filter).ToListAsync();
        }

        public async Task<List<Track>> GetManyByIdsAsync(List<string> ids)
        {
            if (ids == null || ids.Count == 0)
                return new List<Track>();

            var filter = Builders<Track>.Filter.In(t => t.Id, ids);
            return await _tracks.Find(filter).ToListAsync();
        }

        public async Task<List<Track>> GetTracksByGenresAsync(List<string> genres, int limit = 20, List<string>? excludeTrackIds = null)
        {
            if (genres == null || genres.Count == 0)
                return new List<Track>();

            // Tối ưu: Tạo filter cho từng genre (case-insensitive) và combine với OR
            // Giới hạn số lượng tracks load bằng cách tăng limit trước khi filter
            var genreFilters = genres.Select(genre => 
                Builders<Track>.Filter.Regex(
                    t => t.Genres, 
                    new MongoDB.Bson.BsonRegularExpression($"^{System.Text.RegularExpressions.Regex.Escape(genre)}$", "i")
                )
            ).ToArray();

            var baseFilters = new List<FilterDefinition<Track>>
            {
                Builders<Track>.Filter.Eq(t => t.IsApproved, true),
                Builders<Track>.Filter.Eq(t => t.IsDeleted, false),
                Builders<Track>.Filter.Ne(t => t.Genres, null),
                Builders<Track>.Filter.Or(genreFilters) // Có ít nhất một genre match
            };

            if (excludeTrackIds != null && excludeTrackIds.Count > 0)
            {
                baseFilters.Add(Builders<Track>.Filter.Nin(t => t.Id, excludeTrackIds));
            }

            var baseFilter = Builders<Track>.Filter.And(baseFilters);
            var sort = Builders<Track>.Sort.Descending(t => t.PlayCount);

            // Load với limit lớn hơn một chút để đảm bảo có đủ sau khi filter case-insensitive
            // Sau đó filter lại trong memory để đảm bảo chính xác
            var tracks = await _tracks
                .Find(baseFilter)
                .Sort(sort)
                .Limit(limit * 2) // Load nhiều hơn một chút để đảm bảo đủ sau khi filter
                .ToListAsync();

            // Filter lại trong memory để đảm bảo case-insensitive matching chính xác
            var matchedTracks = tracks
                .Where(t => t.Genres != null && t.Genres.Any(g => 
                    !string.IsNullOrEmpty(g) && genres.Any(searchGenre => 
                        string.Equals(g, searchGenre, StringComparison.OrdinalIgnoreCase)
                    )
                ))
                .OrderByDescending(t => t.PlayCount)
                .Take(limit)
                .ToList();

            return matchedTracks;
        }

    }
}
