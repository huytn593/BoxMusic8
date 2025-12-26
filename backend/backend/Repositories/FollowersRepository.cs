using backend.Interfaces;
using backend.Models;
using MongoDB.Driver;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;

namespace backend.Repositories
{
    public class FollowersRepository : IFollowersRepository
    {
        private readonly IMongoCollection<Followers> _followers;

        public FollowersRepository(IMongoDatabase database)
        {
            _followers = database.GetCollection<Followers>("followers");
        }

        public async Task FollowAsync(string followerId, string followingId)
        {
            // Kiểm tra xem đã follow chưa để tránh duplicate key error
            var isAlreadyFollowing = await IsFollowingAsync(followerId, followingId);
            if (isAlreadyFollowing)
            {
                return; // Đã follow rồi, không cần làm gì
            }

            var follower = new Followers 
            { 
                Id = $"{followerId}_{followingId}",
                FollowerId = followerId, 
                FollowingId = followingId 
            };
            await _followers.InsertOneAsync(follower);
        }

        public async Task UnfollowAsync(string followerId, string followingId)
        {
            var id = $"{followerId}_{followingId}";
            await _followers.DeleteOneAsync(f => f.Id == id);
        }

        public async Task<bool> IsFollowingAsync(string followerId, string followingId)
        {
            var id = $"{followerId}_{followingId}";
            var count = await _followers.CountDocumentsAsync(f => f.Id == id);
            return count > 0;
        }

        public async Task<List<string>> GetFollowingListAsync(string followerId)
        {
            var filter = Builders<Followers>.Filter.Eq(f => f.FollowerId, followerId);
            var followers = await _followers.Find(filter).ToListAsync();
            return followers.Select(f => f.FollowingId).ToList();
        }
    }
} 